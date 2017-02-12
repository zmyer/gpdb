/*-------------------------------------------------------------------------
 *
 * inval.h
 *	  POSTGRES cache invalidation dispatcher definitions.
 *
 *
 * Portions Copyright (c) 1996-2008, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * $PostgreSQL: pgsql/src/include/utils/inval.h,v 1.41.2.1 2008/03/13 18:00:39 tgl Exp $
 *
 *-------------------------------------------------------------------------
 */
#ifndef INVAL_H
#define INVAL_H

#include "access/htup.h"
#include "utils/rel.h"


typedef void (*SyscacheCallbackFunction) (Datum arg, int cacheid, ItemPointer tuplePtr);
typedef void (*RelcacheCallbackFunction) (Datum arg, Oid relid);


extern void AcceptInvalidationMessages(void);

extern void AtStart_Inval(void);

extern void AtSubStart_Inval(void);

extern void AtEOXact_Inval(bool isCommit);

extern void AtEOSubXact_Inval(bool isCommit);

extern void AtPrepare_Inval(void);

extern void PostPrepare_Inval(void);

extern void CommandEndInvalidationMessages(void);

extern void BeginNonTransactionalInvalidation(void);

extern void EndNonTransactionalInvalidation(void);

extern void CacheInvalidateHeapTuple(Relation relation, HeapTuple tuple);

extern void CacheInvalidateRelcache(Relation relation);

extern void CacheInvalidateRelcacheByTuple(HeapTuple classTuple);

extern void CacheInvalidateRelcacheByRelid(Oid relid);

extern void CacheRegisterSyscacheCallback(int cacheid,
							  SyscacheCallbackFunction func,
							  Datum arg);

extern void CacheRegisterRelcacheCallback(RelcacheCallbackFunction func,
							  Datum arg);

extern void inval_twophase_postcommit(TransactionId xid, uint16 info,
						  void *recdata, uint32 len);

/* Enum for system cache invalidation mode */
typedef enum SysCacheFlushForce
{
	SysCacheFlushForce_Off = 0,
	SysCacheFlushForce_NonRecursive,
	SysCacheFlushForce_Recursive,
	SysCacheFlushForce_Max				/* must always be last */
} SysCacheFlushForce;

#define SysCacheFlushForce_IsValid(subclass) \
	(subclass >= SysCacheFlushForce_Off && subclass < SysCacheFlushForce_Max)

/* GUCs */
extern int gp_test_system_cache_flush_force; /* session GUC, forces system cache invalidation on each access */

#endif   /* INVAL_H */
