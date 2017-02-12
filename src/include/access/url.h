/*-------------------------------------------------------------------------
 *
 * url.h
 *    routines for external table access to urls.
 *    to the qExec processes.
 *
 * Copyright (c) 2005-2008, Greenplum inc
 *
 * src/include/access/url.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef URL_H
#define URL_H

#ifdef USE_CURL
#include <curl/curl.h>
#endif

#include "access/extprotocol.h"

#include "commands/copy.h"

enum fcurl_type_e 
{ 
	CFTYPE_NONE = 0, 
	CFTYPE_FILE = 1, 
	CFTYPE_CURL = 2, 
	CFTYPE_EXEC = 3, 
	CFTYPE_CUSTOM = 4 
};

#ifdef USE_CURL
typedef struct curlctl_t {
	
	CURL *handle;
	char *curl_url;
	struct curl_slist *x_httpheader;
	
	struct 
	{
		char* ptr;	   /* malloc-ed buffer */
		int   max;
		int   bot, top;
	} in;

	struct 
	{
		char* ptr;	   /* malloc-ed buffer */
		int   max;
		int   bot, top;
	} out;

	int still_running;          /* Is background url fetch still in progress */
	int for_write;				/* 'f' when we SELECT, 't' when we INSERT    */
	int error, eof;				/* error & eof flags */
	int gp_proto;
	char *http_response;
	
	struct 
	{
		int   datalen;  /* remaining datablock length */
	} block;
} curlctl_t;
#endif

typedef struct URL_FILE
{
	enum fcurl_type_e type;     /* type of handle */
	char *url;
	int64 seq_number;

	union {
		struct {
			struct fstream_t*fp;
		} file;

#ifdef USE_CURL
		curlctl_t curl;
#endif

		struct {
			int 	pid;
			int 	pipes[2]; /* only out and err needed */
			char*	shexec;
		} exec;
		
		struct {
			FmgrInfo   *protocol_udf;
			ExtProtocol extprotocol;
			MemoryContext protcxt;
		} custom;
		
	} u;
} URL_FILE;

typedef struct extvar_t
{
	char* GP_MASTER_HOST;
	char* GP_MASTER_PORT;
	char* GP_DATABASE;
	char* GP_USER;
	char* GP_SEG_PG_CONF;   /*location of the segments pg_conf file*/
	char* GP_SEG_DATADIR;   /*location of the segments datadirectory*/
	char GP_DATE[9];		/* YYYYMMDD */
	char GP_TIME[7];		/* HHMMSS */
	char GP_XID[TMGIDSIZE];		/* global transaction id */
	char GP_CID[10];		/* command id */
	char GP_SN[10];		/* scan number */
	char GP_SEGMENT_ID[6];  /*segments content id*/
	char GP_SEG_PORT[10];
	char GP_SESSION_ID[10];  /* session id */
 	char GP_SEGMENT_COUNT[6]; /* total number of (primary) segs in the system */
 	char GP_CSVOPT[13]; /* "m.x...q...h." former -q, -h and -x options for gpfdist.*/

 	/* Hadoop Specific env var */
 	char* GP_HADOOP_CONN_JARDIR;
 	char* GP_HADOOP_CONN_VERSION;
 	char* GP_HADOOP_HOME;

 	/* EOL vars */
 	char* GP_LINE_DELIM_STR;
 	char GP_LINE_DELIM_LENGTH[8];
} extvar_t;


/* an EXECUTE string will always be prefixed like this */
#define EXEC_URL_PREFIX "execute:"

/* exported functions */
extern URL_FILE *url_fopen(char *url, bool forwrite, extvar_t *ev, CopyState pstate, int *response_code, const char **response_string);
extern void url_fclose(URL_FILE *file, bool failOnError, const char *relname);
extern bool url_feof(URL_FILE *file, int bytesread);
extern bool url_ferror(URL_FILE *file, int bytesread, char *ebuf, int ebuflen);
extern size_t url_fread(void *ptr, size_t size, URL_FILE *file, CopyState pstate);
extern size_t url_fwrite(void *ptr, size_t size, URL_FILE *file, CopyState pstate);
extern void url_fflush(URL_FILE *file, CopyState pstate);


extern URL_FILE *url_curl_fopen(char *url, bool forwrite, extvar_t *ev, CopyState pstate, int *response_code, const char **response_string);
extern void url_curl_fclose(URL_FILE *file, bool failOnError, const char *relname);
extern bool url_curl_feof(URL_FILE *file, int bytesread);
extern bool url_curl_ferror(URL_FILE *file, int bytesread, char *ebuf, int ebuflen);
extern size_t url_curl_fread(void *ptr, size_t size, URL_FILE *file, CopyState pstate);
extern size_t url_curl_fwrite(void *ptr, size_t size, URL_FILE *file, CopyState pstate);
extern void url_curl_fflush(URL_FILE *file, CopyState pstate);

extern URL_FILE *url_file_fopen(char *url, bool forwrite, extvar_t *ev, CopyState pstate, int *response_code, const char **response_string);
extern void url_file_fclose(URL_FILE *file, bool failOnError, const char *relname);
extern bool url_file_feof(URL_FILE *file, int bytesread);
extern bool url_file_ferror(URL_FILE *file, int bytesread, char *ebuf, int ebuflen);
extern size_t url_file_fread(void *ptr, size_t size, URL_FILE *file, CopyState pstate);

extern URL_FILE *url_execute_fopen(char *url, bool forwrite, extvar_t *ev, CopyState pstate, int *response_code, const char **response_string);
extern void url_execute_fclose(URL_FILE *file, bool failOnError, const char *relname);
extern bool url_execute_feof(URL_FILE *file, int bytesread);
extern bool url_execute_ferror(URL_FILE *file, int bytesread, char *ebuf, int ebuflen);
extern size_t url_execute_fread(void *ptr, size_t size, URL_FILE *file, CopyState pstate);
extern size_t url_execute_fwrite(void *ptr, size_t size, URL_FILE *file, CopyState pstate);

extern URL_FILE *url_custom_fopen(char *url, bool forwrite, extvar_t *ev, CopyState pstate, int *response_code, const char **response_string);
extern void url_custom_fclose(URL_FILE *file, bool failOnError, const char *relname);
extern bool url_custom_feof(URL_FILE *file, int bytesread);
extern bool url_custom_ferror(URL_FILE *file, int bytesread, char *ebuf, int ebuflen);
extern size_t url_custom_fread(void *ptr, size_t size, URL_FILE *file, CopyState pstate);
extern size_t url_custom_fwrite(void *ptr, size_t size, URL_FILE *file, CopyState pstate);


extern URL_FILE *alloc_url_file(const char *url);


extern int readable_external_table_timeout;
#endif
