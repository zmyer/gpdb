// Required by building CPP dynamic library via Makefile of GPDB.
#define PGDLLIMPORT "C"

extern "C" {
#include "postgres.h"

#include "access/extprotocol.h"
#include "access/xact.h"
#include "catalog/pg_exttable.h"
#include "catalog/pg_proc.h"
#include "fmgr.h"
#include "funcapi.h"
#include "port.h"  //for pg_strncasecmp
#include "utils/array.h"
#include "utils/builtins.h"
#include "utils/memutils.h"
}

#include "gpreader.h"
#include "gpwriter.h"

/* Do the module magic dance */
PG_MODULE_MAGIC;
PG_FUNCTION_INFO_V1(s3_export);
PG_FUNCTION_INFO_V1(s3_import);

extern "C" {
Datum s3_export(PG_FUNCTION_ARGS);
Datum s3_import(PG_FUNCTION_ARGS);
}

string s3extErrorMessage;

/*
 * To detect the query interruption event (triggered by user), we should
 * consider both QueryCancelPending variable and transaction status. Here
 * QueryCancelPending is not sufficient because it will be reset before the
 * extprotocol last call, then it is hard to distinguish normal exit/finish
 * from abnormal transaction abort.
 *
 * IsAbortInProgress() can also be reset by GPDB while downloading file, we
 * must save the state
 */
static bool queryCancelFlag = false;
bool S3QueryIsAbortInProgress(void) {
    bool queryIsBeingCancelled = QueryCancelPending || IsAbortInProgress();

    // We need a thread-safe way to query and set queryCancelFlag.
    // queryCancelFlag is set to TRUE for the first time when cancel signal is
    // detected. If cancel signal is already captured, value will not be
    // swapped and queryIsCancelledAlready is true.
    bool queryIsCancelledAlready =
        !__sync_bool_compare_and_swap(&queryCancelFlag, false, queryIsBeingCancelled);

    return queryIsBeingCancelled || queryIsCancelledAlready;
}

void *S3Alloc(size_t size) {
    return palloc(size);
}

/*
 * MemoryContext will be free automatically when query is completed or aborted.
 * So no need to call pfree() again unless it is really needed inside query execution.
 * Otherwise might free already cleaned memory context for failed query.
 *
 * Currently download/upload buffer are using memory from MemoryContext.
 */
void S3Free(void *p) {
    // pfree(p);
}

/*
 * Set up the thread signal mask, we don't want to run our signal handlers
 * in downloading and uploading threads.
 */
void MaskThreadSignals() {
    sigset_t sigs;

    if (pthread_equal(main_tid, pthread_self())) {
        S3ERROR("thread_mask is called from main thread!");
        return;
    }

    sigemptyset(&sigs);

    /* make our thread to ignore these signals (which should allow that they be
     * delivered to the main thread) */
    sigaddset(&sigs, SIGHUP);
    sigaddset(&sigs, SIGINT);
    sigaddset(&sigs, SIGTERM);
    sigaddset(&sigs, SIGALRM);
    sigaddset(&sigs, SIGUSR1);
    sigaddset(&sigs, SIGUSR2);

    pthread_sigmask(SIG_BLOCK, &sigs, NULL);
}

/*
 * Detect data format
 * used to set file extension on S3 in gpwriter.
 */
static const char *getFormatStr(FunctionCallInfo fcinfo) {
    Relation rel = EXTPROTOCOL_GET_RELATION(fcinfo);
    ExtTableEntry *exttbl = GetExtTableEntry(rel->rd_id);
    char fmtcode = exttbl->fmtcode;

    if (fmttype_is_text(fmtcode)) return "txt";
    if (fmttype_is_csv(fmtcode)) return "csv";
    if (fmttype_is_avro(fmtcode)) return "avro";
    if (fmttype_is_parquet(fmtcode)) return "parquet";
    return S3_DEFAULT_FORMAT;
}

bool hasHeader = false;

char eolString[EOL_CHARS_MAX_LEN + 1] = "\n";  // LF by default

static void parseFormatOpts(FunctionCallInfo fcinfo) {
    Relation rel = EXTPROTOCOL_GET_RELATION(fcinfo);
    ExtTableEntry *exttbl = GetExtTableEntry(rel->rd_id);

    const char fmtcode = exttbl->fmtcode;
    const char *fmtopts = exttbl->fmtopts;

    // only TEXT and CSV have detailed options
    if (fmttype_is_csv(fmtcode) || fmttype_is_text(fmtcode)) {
        if (strstr(fmtopts, "header") != NULL) {
            hasHeader = true;
        } else {
            hasHeader = false;
        }

        // detect end-of-line terminator
        const char *newline_str = strstr(fmtopts, "newline");
        eolString[0] = '\n';
        eolString[1] = '\0';

        if (newline_str != NULL) {
            const char *first = strchr(newline_str, '\'');
            const char *second = strchr(first + 1, '\'');
            size_t len = second - first - 1;
            char newline[EOL_STRING_MAX_LEN + 1];
            len = len > EOL_STRING_MAX_LEN ? EOL_STRING_MAX_LEN : len;  // defensive line

            strncpy(newline, first + 1, len);
            newline[len] = '\0';
            if (pg_strcasecmp(newline, "crlf") == 0) {
                eolString[0] = '\r';
                eolString[1] = '\n';
                eolString[2] = '\0';
            } else if (pg_strcasecmp(newline, "cr") == 0) {
                eolString[0] = '\r';
                eolString[1] = '\0';
            } else if (pg_strcasecmp(newline, "lf") == 0) {
                eolString[0] = '\n';
                eolString[1] = '\0';
            } else {  // should never come here
                ereport(ERROR, (0, errmsg("invalid value for NEWLINE (%s), "
                                          "valid options are: 'LF', 'CRLF', 'CR'",
                                          newline)));
            }
        }
    }
}

/*
 * Import data into GPDB.
 * invoked by GPDB, be careful with C++ exceptions.
 */
Datum s3_import(PG_FUNCTION_ARGS) {
    /* Must be called via the external table format manager */
    if (!CALLED_AS_EXTPROTOCOL(fcinfo))
        elog(ERROR, "extprotocol_import: not called by external protocol manager");

    /* Get our internal description of the protocol */
    GPReader *gpreader = (GPReader *)EXTPROTOCOL_GET_USER_CTX(fcinfo);

    /* last call. destroy reader */
    if (EXTPROTOCOL_IS_LAST_CALL(fcinfo)) {
        if (!reader_cleanup(&gpreader)) {
            ereport(ERROR,
                    (0, errmsg("Failed to cleanup S3 extension: %s", s3extErrorMessage.c_str())));
        }

        thread_cleanup();

        EXTPROTOCOL_SET_USER_CTX(fcinfo, NULL);
        PG_RETURN_INT32(0);
    }

    /* first call. do any desired init */
    if (gpreader == NULL) {
        queryCancelFlag = false;
        const char *url_with_options = EXTPROTOCOL_GET_URL(fcinfo);

        // has HEADER? and newline EOL?
        parseFormatOpts(fcinfo);

        thread_setup();

        gpreader = reader_init(url_with_options);
        if (!gpreader) {
            ereport(ERROR, (0, errmsg("Failed to init S3 extension (segid = %d, "
                                      "segnum = %d), please check your "
                                      "configurations and network connection: %s",
                                      s3ext_segid, s3ext_segnum, s3extErrorMessage.c_str())));
        }

        EXTPROTOCOL_SET_USER_CTX(fcinfo, gpreader);
    }

    char *data_buf = EXTPROTOCOL_GET_DATABUF(fcinfo);
    int32 data_len = EXTPROTOCOL_GET_DATALEN(fcinfo);

    if (!reader_transfer_data(gpreader, data_buf, data_len)) {
        ereport(ERROR,
                (0, errmsg("s3_import: could not read data: %s", s3extErrorMessage.c_str())));
    }
    PG_RETURN_INT32(data_len);
}

/*
 * Export data out of GPDB.
 * invoked by GPDB, be careful with C++ exceptions.
 */
Datum s3_export(PG_FUNCTION_ARGS) {
    /* Must be called via the external table format manager */
    if (!CALLED_AS_EXTPROTOCOL(fcinfo))
        elog(ERROR, "extprotocol_import: not called by external protocol manager");

    /* Get our internal description of the protocol */
    GPWriter *gpwriter = (GPWriter *)EXTPROTOCOL_GET_USER_CTX(fcinfo);

    /* last call. destroy writer */
    if (EXTPROTOCOL_IS_LAST_CALL(fcinfo)) {
        if (!writer_cleanup(&gpwriter)) {
            ereport(ERROR,
                    (0, errmsg("Failed to cleanup S3 extension: %s", s3extErrorMessage.c_str())));
        }

        thread_cleanup();

        EXTPROTOCOL_SET_USER_CTX(fcinfo, NULL);
        PG_RETURN_INT32(0);
    }

    /* first call. do any desired init */
    if (gpwriter == NULL) {
        queryCancelFlag = false;
        const char *url_with_options = EXTPROTOCOL_GET_URL(fcinfo);
        const char *format = getFormatStr(fcinfo);

        thread_setup();

        gpwriter = writer_init(url_with_options, format);
        if (!gpwriter) {
            ereport(ERROR, (0, errmsg("Failed to init S3 extension (segid = %d, "
                                      "segnum = %d), please check your "
                                      "configurations and network connection: %s",
                                      s3ext_segid, s3ext_segnum, s3extErrorMessage.c_str())));
        }

        EXTPROTOCOL_SET_USER_CTX(fcinfo, gpwriter);
    }

    char *data_buf = EXTPROTOCOL_GET_DATABUF(fcinfo);
    int32 data_len = EXTPROTOCOL_GET_DATALEN(fcinfo);

    if (!writer_transfer_data(gpwriter, data_buf, data_len)) {
        ereport(ERROR,
                (0, errmsg("s3_export: could not write data: %s", s3extErrorMessage.c_str())));
    }

    PG_RETURN_INT32(data_len);
}
