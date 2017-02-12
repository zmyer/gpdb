/*-------------------------------------------------------------------------
 *
 * transam.h
 *	  postgres transaction access method support code
 *
 *
 * Portions Copyright (c) 1996-2008, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * $PostgreSQL: pgsql/src/include/access/transam.h,v 1.64 2008/01/01 19:45:56 momjian Exp $
 *
 *-------------------------------------------------------------------------
 */
#ifndef TRANSAM_H
#define TRANSAM_H

#include "catalog/pg_magic_oid.h"
#include "access/xlogdefs.h"


/* ----------------
 *		Special transaction ID values
 *
 * BootstrapTransactionId is the XID for "bootstrap" operations, and
 * FrozenTransactionId is used for very old tuples.  Both should
 * always be considered valid.
 *
 * FirstNormalTransactionId is the first "normal" transaction id.
 * Note: if you need to change it, you must change pg_class.h as well.
 * ----------------
 */
#define InvalidTransactionId		((TransactionId) 0)
#define BootstrapTransactionId		((TransactionId) 1)
#define FrozenTransactionId			((TransactionId) 2)
#define FirstNormalTransactionId	((TransactionId) 3)
#define MaxTransactionId			((TransactionId) 0xFFFFFFFF)

/* ----------------
 *		transaction ID manipulation macros
 * ----------------
 */
#define TransactionIdIsValid(xid)		((xid) != InvalidTransactionId)
#define TransactionIdIsNormal(xid)		((xid) >= FirstNormalTransactionId)
#define TransactionIdEquals(id1, id2)	((id1) == (id2))
#define TransactionIdStore(xid, dest)	(*(dest) = (xid))
#define StoreInvalidTransactionId(dest) (*(dest) = InvalidTransactionId)

/* advance a transaction ID variable, handling wraparound correctly */
#define TransactionIdAdvance(dest)	\
	do { \
		(dest)++; \
		if ((dest) < FirstNormalTransactionId) \
			(dest) = FirstNormalTransactionId; \
	} while(0)

/* back up a transaction ID variable, handling wraparound correctly */
#define TransactionIdRetreat(dest)	\
	do { \
		(dest)--; \
	} while ((dest) < FirstNormalTransactionId)

#define NUM_RECENT_RELFILENODES		100

/*
 * VariableCache is a data structure in shared memory that is used to track
 * OID and XID assignment state.  For largely historical reasons, there is
 * just one struct with different fields that are protected by different
 * LWLocks.
 *
 * Note: xidWrapLimit and limit_datname are not "active" values, but are
 * used just to generate useful messages when xidWarnLimit or xidStopLimit
 * are exceeded.
 */
typedef struct VariableCacheData
{
	/*
	 * These fields are protected by OidGenLock.
	 */
	Oid			nextOid;		/* next OID to assign */
	uint32		oidCount;		/* OIDs available before must do XLOG work */

	/* cache of recently used relfilenodes, for UseOidForRelFileNode() */
	Oid			recentRelfilenodes[NUM_RECENT_RELFILENODES];
	int			nextRecentRelfilenode;

	/*
	 * These fields are protected by XidGenLock.
	 */
	TransactionId nextXid;		/* next XID to assign */

	TransactionId oldestXid;	/* cluster-wide minimum datfrozenxid */
	TransactionId xidVacLimit;	/* start forcing autovacuums here */
	TransactionId xidWarnLimit; /* start complaining here */
	TransactionId xidStopLimit; /* refuse to advance nextXid beyond here */
	TransactionId xidWrapLimit; /* where the world ends */
	NameData	limit_datname;	/* database that needs vacuumed first */

	/*
	 * These fields are protected by ProcArrayLock.
	 */
	TransactionId latestCompletedXid;	/* newest XID that has committed or
										 * aborted */
} VariableCacheData;

typedef VariableCacheData *VariableCache;


/* ----------------
 *		extern declarations
 * ----------------
 */

/* in transam/varsup.c */
extern VariableCache ShmemVariableCache;

extern int xid_stop_limit;
extern int xid_warn_limit;


/*
 * prototypes for functions in transam/transam.c
 */
extern bool TransactionIdDidCommit(TransactionId transactionId);
extern bool TransactionIdDidAbort(TransactionId transactionId);
extern void TransactionIdCommit(TransactionId transactionId);
extern void TransactionIdAsyncCommit(TransactionId transactionId, XLogRecPtr lsn);
extern void TransactionIdAbort(TransactionId transactionId);
extern void TransactionIdSubCommit(TransactionId transactionId);
extern void TransactionIdCommitTree(int nxids, TransactionId *xids);
extern void TransactionIdAsyncCommitTree(int nxids, TransactionId *xids, XLogRecPtr lsn);
extern void TransactionIdAbortTree(int nxids, TransactionId *xids);
extern bool TransactionIdPrecedes(TransactionId id1, TransactionId id2);
extern bool TransactionIdPrecedesOrEquals(TransactionId id1, TransactionId id2);
extern bool TransactionIdFollows(TransactionId id1, TransactionId id2);
extern bool TransactionIdFollowsOrEquals(TransactionId id1, TransactionId id2);
extern TransactionId TransactionIdLatest(TransactionId mainxid,
					int nxids, const TransactionId *xids);
extern XLogRecPtr TransactionIdGetCommitLSN(TransactionId xid);

/* in transam/varsup.c */
extern TransactionId GetNewTransactionId(bool isSubXact, bool setProcXid);
extern TransactionId ReadNewTransactionId(void);
extern void SetTransactionIdLimit(TransactionId oldest_datfrozenxid,
					  Name oldest_datname);
extern Oid	GetNewObjectId(void);
extern bool UseOidForRelFileNode(Oid oid);

#endif   /* TRAMSAM_H */
