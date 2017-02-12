/*-------------------------------------------------------------------------
 *
 * execUtils.h
 *
 * Copyright (c) 2005-2008, Greenplum inc
 *
 *-------------------------------------------------------------------------
 */
#ifndef _EXECUTILS_H_
#define _EXECUTILS_H_

#include "executor/execdesc.h"

struct EState;
struct QueryDesc;

extern void InitSliceTable(struct EState *estate, int nMotions, int nSubplans);
extern Slice *getCurrentSlice(struct EState *estate, int sliceIndex);
extern bool sliceRunsOnQD(Slice *slice);
extern bool sliceRunsOnQE(Slice *slice);
extern int sliceCalculateNumSendingProcesses(Slice *slice);

extern void InitRootSlices(QueryDesc *queryDesc);
extern void AssignGangs(QueryDesc *queryDesc);
extern void ReleaseGangs(QueryDesc *queryDesc);

#ifdef USE_ASSERT_CHECKING
struct PlannedStmt;
extern void AssertSliceTableIsValid(SliceTable *st, struct PlannedStmt *pstmt);
#endif

#endif
