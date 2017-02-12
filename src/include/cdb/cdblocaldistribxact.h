/*-------------------------------------------------------------------------
 *
 * cdblocaldistribxact.h
 *
 * Copyright (c) 2007-2008, Greenplum inc
 *
 *-------------------------------------------------------------------------
 */
#ifndef CDBLOCALDISTRIBXACT_H
#define CDBLOCALDISTRIBXACT_H

#include "storage/lock.h"

typedef enum
{
	LOCALDISTRIBXACT_STATE_NONE = 0,
	LOCALDISTRIBXACT_STATE_ACTIVE,
	LOCALDISTRIBXACT_STATE_COMMITDELIVERY,
	LOCALDISTRIBXACT_STATE_COMMITTED,
	LOCALDISTRIBXACT_STATE_ABORTDELIVERY,
	LOCALDISTRIBXACT_STATE_ABORTED,
	LOCALDISTRIBXACT_STATE_PREPARED,
	LOCALDISTRIBXACT_STATE_COMMITPREPARED,
	LOCALDISTRIBXACT_STATE_ABORTPREPARED
} LocalDistribXactState;

/*
 * Local information in the database instance (master or segment) on
 * a distributed transaction.
 */
typedef struct LocalDistribXactData
{
	/*
	 * Current distributed transaction state.
	 */
	LocalDistribXactState		state;

	/*
	 * Distributed xid and the master's restart timestamp.
	 */
	DistributedTransactionTimeStamp	distribTimeStamp;
	DistributedTransactionId 		distribXid;

} LocalDistribXactData;

extern void LocalDistribXact_StartOnMaster(
	DistributedTransactionTimeStamp	newDistribTimeStamp,
	DistributedTransactionId 		newDistribXid,
	TransactionId					*newLocalXid,
	LocalDistribXactData			*masterLocalDistribXactRef);

extern void LocalDistribXact_StartOnSegment(
	DistributedTransactionTimeStamp	newDistribTimeStamp,
	DistributedTransactionId 		newDistribXid,
	TransactionId					*newLocalXid);

extern void LocalDistribXact_ChangeState(PGPROC *proc,
	LocalDistribXactState		newState);

extern char* LocalDistribXact_DisplayString(PGPROC *proc);

extern bool LocalDistribXactCache_CommittedFind(
	TransactionId						localXid,
	DistributedTransactionTimeStamp		distribTransactionTimeStamp,
	DistributedTransactionId			*distribXid);

extern void LocalDistribXactCache_AddCommitted(
	TransactionId						localXid,
	DistributedTransactionTimeStamp		distribTransactionTimeStamp,
	DistributedTransactionId			distribXid);

extern void LocalDistribXactCache_ShowStats(char *nameStr);

#endif   /* CDBLOCALDISTRIBXACT_H */
