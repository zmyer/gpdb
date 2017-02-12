/*-------------------------------------------------------------------------
 *
 * vacuum.h
 *	  header file for postgres vacuum cleaner and statistics analyzer
 *
 *
 * Portions Copyright (c) 1996-2008, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * $PostgreSQL: pgsql/src/include/commands/vacuum.h,v 1.75.2.2 2009/11/10 18:00:44 alvherre Exp $
 *
 *-------------------------------------------------------------------------
 */
#ifndef VACUUM_H
#define VACUUM_H

#include "access/htup.h"
#include "catalog/pg_statistic.h"
#include "catalog/pg_type.h"
#include "nodes/parsenodes.h"
#include "storage/buf.h"
#include "storage/lock.h"
#include "utils/rel.h"
#include "utils/tqual.h"


/*----------
 * ANALYZE builds one of these structs for each attribute (column) that is
 * to be analyzed.	The struct and subsidiary data are in anl_context,
 * so they live until the end of the ANALYZE operation.
 *
 * The type-specific typanalyze function is passed a pointer to this struct
 * and must return TRUE to continue analysis, FALSE to skip analysis of this
 * column.	In the TRUE case it must set the compute_stats and minrows fields,
 * and can optionally set extra_data to pass additional info to compute_stats.
 * minrows is its request for the minimum number of sample rows to be gathered
 * (but note this request might not be honored, eg if there are fewer rows
 * than that in the table).
 *
 * The compute_stats routine will be called after sample rows have been
 * gathered.  Aside from this struct, it is passed:
 *		fetchfunc: a function for accessing the column values from the
 *				   sample rows
 *		samplerows: the number of sample tuples
 *		totalrows: estimated total number of rows in relation
 * The fetchfunc may be called with rownum running from 0 to samplerows-1.
 * It returns a Datum and an isNull flag.
 *
 * compute_stats should set stats_valid TRUE if it is able to compute
 * any useful statistics.  If it does, the remainder of the struct holds
 * the information to be stored in a pg_statistic row for the column.  Be
 * careful to allocate any pointed-to data in anl_context, which will NOT
 * be CurrentMemoryContext when compute_stats is called.
 *----------
 */
typedef struct VacAttrStats *VacAttrStatsP;

typedef Datum (*AnalyzeAttrFetchFunc) (VacAttrStatsP stats, int rownum,
												   bool *isNull);

typedef struct VacAttrStats
{
	/*
	 * These fields are set up by the main ANALYZE code before invoking the
	 * type-specific typanalyze function.
	 */
	Form_pg_attribute attr;		/* copy of pg_attribute row for column */
	Form_pg_type attrtype;		/* copy of pg_type row for column */
	char		relstorage;		/* pg_class.relstorage for table */
	MemoryContext anl_context;	/* where to save long-lived data */

	/*
	 * These fields must be filled in by the typanalyze routine, unless it
	 * returns FALSE.
	 */
	void		(*compute_stats) (VacAttrStatsP stats,
											  AnalyzeAttrFetchFunc fetchfunc,
											  int samplerows,
											  double totalrows);
	int			minrows;		/* Minimum # of rows wanted for stats */
	void	   *extra_data;		/* for extra type-specific data */

	/*
	 * These fields are to be filled in by the compute_stats routine. (They
	 * are initialized to zero when the struct is created.)
	 */
	bool		stats_valid;
	float4		stanullfrac;	/* fraction of entries that are NULL */
	int4		stawidth;		/* average width of column values */
	float4		stadistinct;	/* # distinct values */
	int2		stakind[STATISTIC_NUM_SLOTS];
	Oid			staop[STATISTIC_NUM_SLOTS];
	int			numnumbers[STATISTIC_NUM_SLOTS];
	float4	   *stanumbers[STATISTIC_NUM_SLOTS];
	int			numvalues[STATISTIC_NUM_SLOTS];
	Datum	   *stavalues[STATISTIC_NUM_SLOTS];

	/*
	 * These fields are private to the main ANALYZE code and should not be
	 * looked at by type-specific functions.
	 */
	int			tupattnum;		/* attribute number within tuples */
	HeapTuple  *rows;			/* access info for std fetch function */
	TupleDesc	tupDesc;
	Datum	   *exprvals;		/* access info for index fetch function */
	bool	   *exprnulls;
	int			rowstride;
} VacAttrStats;

typedef struct VacuumStatsContext
{
	MemoryContext ctx;
	Relation onerel;
	List *updated_stats;
	VacAttrStats **vac_stats;
} VacuumStatsContext;

/*
 * VPgClassStats is used to hold the stats information that are stored in
 * pg_class. It is sent from QE to QD in a special libpq message , when a
 * QE runs VACUUM on a table.
 */
typedef struct VPgClassStats
{
	Oid			relid;
	BlockNumber rel_pages;
	double		rel_tuples;
	BlockNumber empty_end_pages;
} VPgClassStats;

/* GUC parameters */
extern PGDLLIMPORT int default_statistics_target;		/* PGDLLIMPORT for
														 * PostGIS */
extern PGDLLIMPORT double analyze_relative_error;
extern int	vacuum_freeze_min_age;


/* in commands/vacuum.c */
extern void vacuum(VacuumStmt *vacstmt, List *relids,
	   BufferAccessStrategy bstrategy, bool for_wraparound, bool isTopLevel);
extern void vac_open_indexes(Relation relation, LOCKMODE lockmode,
				 int *nindexes, Relation **Irel);
extern void vac_close_indexes(int nindexes, Relation *Irel, LOCKMODE lockmode);
extern void vac_update_relstats(Oid relid,
					BlockNumber num_pages,
					double num_tuples,
					bool hasindex,
					TransactionId frozenxid);
extern void vac_update_relstats_from_list(Relation rel,
							  BlockNumber num_pages, double num_tuples,
							  bool hasindex, TransactionId frozenxid,
										  List *updated_stats);
extern void vacuum_set_xid_limits(int freeze_min_age, bool sharedRel,
					  TransactionId *oldestXmin,
					  TransactionId *freezeLimit);
extern void vac_update_datfrozenxid(void);
extern bool vac_is_partial_index(Relation indrel);
extern void vacuum_delay_point(void);

extern bool vacuumStatement_IsTemporary(Relation onerel);

extern bool vacuumStatement_IsInAppendOnlyDropPhase(VacuumStmt *vacstmt);
extern bool vacummStatement_IsInAppendOnlyCleanupPhase(VacuumStmt *vacstmt);
extern bool vacuumStatement_IsInAppendOnlyPreparePhase(VacuumStmt* vacstmt);
extern bool vacuumStatement_IsInAppendOnlyCompactionPhase(VacuumStmt* vacstmt);
extern bool vacuumStatement_IsInAppendOnlyPseudoCompactionPhase(VacuumStmt* vacstmt);

/* in commands/vacuumlazy.c */
extern bool lazy_vacuum_rel(Relation onerel, VacuumStmt *vacstmt,
				BufferAccessStrategy bstrategy, List *updated_stats);
extern void vacuum_appendonly_rel(Relation aorel, VacuumStmt *vacstmt);
extern void vacuum_appendonly_fill_stats(Relation aorel, Snapshot snapshot,
										 BlockNumber *rel_pages, double *rel_tuples,
										 bool *relhasindex);
extern int vacuum_appendonly_indexes(Relation aoRelation, VacuumStmt *vacstmt, List* updated_stats);
extern void vacuum_aocs_rel(Relation aorel, void *vacrelstats, bool isVacFull);

/* in commands/analyze.c */
extern void analyze_rel(Oid relid, VacuumStmt *vacstmt,
			BufferAccessStrategy bstrategy);
extern void analyzeStatement(VacuumStmt *vacstmt, List *relids, BufferAccessStrategy start, bool isTopLevel);
//extern void analyzeStmt(VacuumStmt *vacstmt, List *relids);

#endif   /* VACUUM_H */
