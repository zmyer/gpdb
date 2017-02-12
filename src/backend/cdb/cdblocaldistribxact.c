/*-------------------------------------------------------------------------
 *
 * cdblocaldistribxact.c
 *
 * Maintains state of current distributed transactions on each (local)
 * database instance.  Driven by added GP code in the xact.c module.
 *
 * Also support a cache of recently seen committed transactions found by the
 * visibility routines for better performance.  Used to avoid reading the
 * distributed log SLRU files too frequently.
 *
 * Copyright (c) 2007-2008, Greenplum inc
 *
 *-------------------------------------------------------------------------
 */

#include "postgres.h"
#include "miscadmin.h"
#include "access/transam.h"
#include "access/twophase.h"
#include "cdb/cdblocaldistribxact.h"
#include "cdb/cdbvars.h"
#include "storage/proc.h"
#include "cdb/cdbshareddoublylinked.h"
#include "utils/hsearch.h"
#include "miscadmin.h"
#include "utils/memutils.h"
#include "cdb/cdbdoublylinked.h"
#include "cdb/cdbpersistentstore.h"

// *****************************************************************************

static char*
LocalDistribXactStateToString(LocalDistribXactState	state)
{
	switch (state)
	{
	case LOCALDISTRIBXACT_STATE_ACTIVE:
		return "Active";

	case LOCALDISTRIBXACT_STATE_COMMITDELIVERY:
		return "Commit Delivery";

	case LOCALDISTRIBXACT_STATE_COMMITTED:
		return "Committed";

	case LOCALDISTRIBXACT_STATE_ABORTDELIVERY:
		return "Abort Delivery";

	case LOCALDISTRIBXACT_STATE_ABORTED:
		return "Aborted";

	case LOCALDISTRIBXACT_STATE_PREPARED:
		return "Prepared";

	case LOCALDISTRIBXACT_STATE_COMMITPREPARED:
		return "Commit Prepared";

	case LOCALDISTRIBXACT_STATE_ABORTPREPARED:
		return "Abort Prepared";

	default:
		return "Unknown";
	}
}

// *****************************************************************************

/*
 * NOTE: The ProcArrayLock must already be held.
 */
void
LocalDistribXact_StartOnMaster(
	DistributedTransactionTimeStamp	newDistribTimeStamp,
	DistributedTransactionId 		newDistribXid,
	TransactionId					*newLocalXid,
	LocalDistribXactData			*masterLocalDistribXactRef)
{
	LocalDistribXactData *ele = masterLocalDistribXactRef;
	TransactionId	localXid;

	Assert(newDistribTimeStamp != 0);
	Assert(newDistribXid != InvalidDistributedTransactionId);
	Assert(newLocalXid != NULL);
	Assert(masterLocalDistribXactRef != NULL);

	localXid = GetNewTransactionId(false, false);
								// NOT subtrans, DO NOT Set PROC struct xid;

	ele->distribTimeStamp = newDistribTimeStamp;
	ele->distribXid = newDistribXid;
	ele->state = LOCALDISTRIBXACT_STATE_ACTIVE;

	MyProc->xid = localXid;
	*newLocalXid = localXid;
}

void
LocalDistribXact_StartOnSegment(
	DistributedTransactionTimeStamp	newDistribTimeStamp,
	DistributedTransactionId 		newDistribXid,
	TransactionId					*newLocalXid)
{
	LocalDistribXactData *ele = &MyProc->localDistribXactData;
	TransactionId	localXid;

	MIRRORED_LOCK_DECLARE;

	Assert(newDistribTimeStamp != 0);
	Assert(newDistribXid != InvalidDistributedTransactionId);
	Assert(newLocalXid != NULL);

	MIRRORED_LOCK;
	LWLockAcquire(ProcArrayLock, LW_EXCLUSIVE);

	localXid = GetNewTransactionId(false, false);
								// NOT subtrans, DO NOT Set PROC struct xid;

	ele->distribTimeStamp = newDistribTimeStamp;
	ele->distribXid = newDistribXid;
	ele->state = LOCALDISTRIBXACT_STATE_ACTIVE;

	MyProc->xid = localXid;
	*newLocalXid = localXid;

	LWLockRelease(ProcArrayLock);
	MIRRORED_UNLOCK;
}

void
LocalDistribXact_ChangeState(PGPROC *proc,
							 LocalDistribXactState newState)
{
	LocalDistribXactState		oldState;
	DistributedTransactionId distribXid;

	Assert(proc->localDistribXactData.state != LOCALDISTRIBXACT_STATE_NONE);

	oldState = proc->localDistribXactData.state;
	distribXid = proc->localDistribXactData.distribXid;

	/*
	 * Validate current state given new state.
	 */
	switch (newState)
	{
	case LOCALDISTRIBXACT_STATE_COMMITDELIVERY:
	case LOCALDISTRIBXACT_STATE_ABORTDELIVERY:
	case LOCALDISTRIBXACT_STATE_PREPARED:
		if (oldState != LOCALDISTRIBXACT_STATE_ACTIVE)
			elog(PANIC,
			     "Expected distributed transaction xid = %u to local element to be in state \"Active\" and "
			     "found state \"%s\"",
			     distribXid,
			     LocalDistribXactStateToString(oldState));
		break;

	case LOCALDISTRIBXACT_STATE_COMMITPREPARED:
	case LOCALDISTRIBXACT_STATE_ABORTPREPARED:
		if (oldState != LOCALDISTRIBXACT_STATE_PREPARED)
			elog(PANIC,
			     "Expected distributed transaction xid = %u to local element to be in state \"Prepared\" and "
			     "found state \"%s\"",
			     distribXid,
			     LocalDistribXactStateToString(oldState));
		break;

	case LOCALDISTRIBXACT_STATE_COMMITTED:
		if (oldState != LOCALDISTRIBXACT_STATE_ACTIVE &&
			oldState != LOCALDISTRIBXACT_STATE_COMMITDELIVERY)
			elog(PANIC,
			     "Expected distributed transaction xid = %u to local element to be in state \"Active\" or \"Commit Delivery\" and "
			     "found state \"%s\"",
			     distribXid,
			     LocalDistribXactStateToString(oldState));
		break;

	case LOCALDISTRIBXACT_STATE_ABORTED:
		if (oldState != LOCALDISTRIBXACT_STATE_ACTIVE &&
			oldState != LOCALDISTRIBXACT_STATE_ABORTDELIVERY)
			elog(PANIC,
			     "Expected distributed transaction xid = %u to local element to be in state \"Active\" or \"Abort Delivery\" and "
			     "found state \"%s\"",
			     distribXid,
			     LocalDistribXactStateToString(oldState));
		break;

	case LOCALDISTRIBXACT_STATE_ACTIVE:
		elog(PANIC, "Unexpected distributed to local transaction new state: '%s'",
			LocalDistribXactStateToString(newState));
		break;

	default:
		elog(PANIC, "Unrecognized distributed to local transaction state: %d",
			(int) newState);
	}

	proc->localDistribXactData.state = newState;

	elog((Debug_print_full_dtm ? LOG : DEBUG5),
		 "Moved distributed transaction xid = %u (local xid = %u) from \"%s\" to \"%s\"",
		 distribXid,
		 proc->xid,
		 LocalDistribXactStateToString(oldState),
		 LocalDistribXactStateToString(newState));
}

#define MAX_LOCAL_DISTRIB_DISPLAY_BUFFER 100
static char LocalDistribDisplayBuffer[MAX_LOCAL_DISTRIB_DISPLAY_BUFFER];

char*
LocalDistribXact_DisplayString(PGPROC *proc)
{
	int 				snprintfResult;

	snprintfResult =
		snprintf(
			LocalDistribDisplayBuffer,
			MAX_LOCAL_DISTRIB_DISPLAY_BUFFER,
		    "distributed transaction {timestamp %u, xid %u} for local xid %u",
		    proc->localDistribXactData.distribTimeStamp,
		    proc->localDistribXactData.distribXid,
		    proc->xid);

	Assert(snprintfResult >= 0);
	Assert(snprintfResult < MAX_LOCAL_DISTRIB_DISPLAY_BUFFER);

	return LocalDistribDisplayBuffer;
}

// *****************************************************************************

/* Memory context for long-lived local-distributed commit pairs. */
static MemoryContext LocalDistribCacheMemCxt = NULL;

/* Hash table for the long-lived local-distributed commit pairs. */
static HTAB	   		*LocalDistribCacheHtab;

/*
 * A cached local-distributed transaction pair.
 *
 * We also cache just local-only transactions, so in that case distribXid
 * will be InvalidDistributedTransactionId.
 */
typedef struct LocalDistribXactCacheEntry
{
	/*
	 * Distributed and local xids.
	 */
	TransactionId 					localXid;
										/* MUST BE FIRST: Hash table key. */

	DistributedTransactionId 		distribXid;

	int64							visits;

	DoubleLinks						lruDoubleLinks;
										/* list link for LRU */

}	LocalDistribXactCacheEntry;

/*
 * Globals for local-distributed cache.
 */
static struct LocalDistribXactCache
{
	int32			count;

	DoublyLinkedHead 		lruDoublyLinkedHead;

	int64		hitCount;
	int64		totalCount;
	int64		addCount;
	int64		removeCount;

}	LocalDistribXactCache = {0,{NULL,NULL},0,0,0,0};


bool
LocalDistribXactCache_CommittedFind(
	TransactionId						localXid,
	DistributedTransactionTimeStamp		distribTransactionTimeStamp,
	DistributedTransactionId			*distribXid)
{
	LocalDistribXactCacheEntry*	entry;
	bool						found;

	// Before doing anything, see if we are enabled.
	if (gp_max_local_distributed_cache == 0)
		return false;

	if (LocalDistribCacheMemCxt == NULL)
	{
		HASHCTL		hash_ctl;

		/* Create the memory context where cross-transaction state is stored */
		LocalDistribCacheMemCxt = AllocSetContextCreate(TopMemoryContext,
											  "Local-distributed commit cache context",
											  ALLOCSET_DEFAULT_MINSIZE,
											  ALLOCSET_DEFAULT_INITSIZE,
											  ALLOCSET_DEFAULT_MAXSIZE);

		Assert(LocalDistribCacheHtab == NULL);

		/* Create the hashtable proper */
		MemSet(&hash_ctl, 0, sizeof(hash_ctl));
		hash_ctl.keysize = sizeof(TransactionId);
		hash_ctl.entrysize = sizeof(LocalDistribXactCacheEntry);
		hash_ctl.hash = tag_hash;
		hash_ctl.hcxt = LocalDistribCacheMemCxt;
		LocalDistribCacheHtab = hash_create("Local-distributed commit cache",
									 25,	/* start small and extend */
									 &hash_ctl,
									 HASH_ELEM | HASH_FUNCTION | HASH_CONTEXT);

		MemSet(&LocalDistribXactCache, 0, sizeof(LocalDistribXactCache));
		DoublyLinkedHead_Init(&LocalDistribXactCache.lruDoublyLinkedHead);

	}

	entry = (LocalDistribXactCacheEntry*) hash_search(
													LocalDistribCacheHtab,
													&localXid,
													HASH_FIND,
													&found);

	if (found)
	{
		/*
		 * Maintain LRU ordering.
		 */
		DoubleLinks_Remove(
					offsetof(LocalDistribXactCacheEntry, lruDoubleLinks),
					&LocalDistribXactCache.lruDoublyLinkedHead,
					entry);
		DoublyLinkedHead_AddFirst(
						offsetof(LocalDistribXactCacheEntry, lruDoubleLinks),
						&LocalDistribXactCache.lruDoublyLinkedHead,
						entry);

		*distribXid = entry->distribXid;

		entry->visits++;

		LocalDistribXactCache.hitCount++;
	}

	LocalDistribXactCache.totalCount++;

	return found;
}

void
LocalDistribXactCache_AddCommitted(
	TransactionId						localXid,
	DistributedTransactionTimeStamp		distribTransactionTimeStamp,
	DistributedTransactionId			distribXid)
{
	LocalDistribXactCacheEntry*	entry;
	bool						found;

	// Before doing anything, see if we are enabled.
	if (gp_max_local_distributed_cache == 0)
		return;

	Assert (LocalDistribCacheMemCxt != NULL);
	Assert (LocalDistribCacheHtab != NULL);

	if (LocalDistribXactCache.count >= gp_max_local_distributed_cache)
	{
		LocalDistribXactCacheEntry*	lastEntry;
		LocalDistribXactCacheEntry*	removedEntry;

		Assert(LocalDistribXactCache.count == gp_max_local_distributed_cache);

		/*
		 * Remove oldest.
		 */
		lastEntry = (LocalDistribXactCacheEntry*)
							DoublyLinkedHead_RemoveLast(
											offsetof(LocalDistribXactCacheEntry, lruDoubleLinks),
											&LocalDistribXactCache.lruDoublyLinkedHead);
		Assert(lastEntry != NULL);

		removedEntry = (LocalDistribXactCacheEntry*)
			hash_search(LocalDistribCacheHtab, &lastEntry->localXid,
						HASH_REMOVE, NULL);
		Assert(lastEntry == removedEntry);

		LocalDistribXactCache.count--;

		LocalDistribXactCache.removeCount++;
	}

	/* Now we can add entry to hash table */
	entry = (LocalDistribXactCacheEntry*) hash_search(
													LocalDistribCacheHtab,
													&localXid,
													HASH_ENTER,
													&found);
	if (found)
	{
		elog(ERROR, "Add should not have found local xid = %x", localXid);
	}

	DoubleLinks_Init(&entry->lruDoubleLinks);
	DoublyLinkedHead_AddFirst(
					offsetof(LocalDistribXactCacheEntry, lruDoubleLinks),
					&LocalDistribXactCache.lruDoublyLinkedHead,
					entry);

	entry->localXid = localXid;
	entry->distribXid = distribXid;
	entry->visits = 1;

	LocalDistribXactCache.count++;

	LocalDistribXactCache.addCount++;

}

void
LocalDistribXactCache_ShowStats(char *nameStr)
{
		elog(LOG, "%s: Local-distributed cache counts "
			 "(hits " INT64_FORMAT ", total " INT64_FORMAT ", adds " INT64_FORMAT ", removes " INT64_FORMAT ")",
			 nameStr,
			 LocalDistribXactCache.hitCount,
			 LocalDistribXactCache.totalCount,
			 LocalDistribXactCache.addCount,
			 LocalDistribXactCache.removeCount);
}
