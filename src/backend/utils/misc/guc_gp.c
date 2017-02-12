/*--------------------------------------------------------------------
 * guc_gp.c
 *
 * Additional Greenplum-specific GUCs are defined in this file, to
 * avoid adding so much stuff to guc.c. This makes it easier to diff
 * and merge with upstream.
 *
 * Portions Copyright (c) 2005-2010, Greenplum inc
 * Copyright (c) 2000-2009, PostgreSQL Global Development Group
 *
 * IDENTIFICATION
 *	  src/backend/utils/misc/guc_gp.c
 *
 *--------------------------------------------------------------------
 */
#include "postgres.h"

#include "access/reloptions.h"
#include "access/transam.h"
#include "access/url.h"
#include "access/xlog_internal.h"
#include "cdb/cdbappendonlyam.h"
#include "cdb/cdbdisp.h"
#include "cdb/cdbfilerep.h"
#include "cdb/cdbsreh.h"
#include "cdb/cdbvars.h"
#include "cdb/memquota.h"
#include "commands/vacuum.h"
#include "miscadmin.h"
#include "libpq/password_hash.h"
#include "optimizer/planmain.h"
#include "optimizer/cost.h"
#include "pgstat.h"
#include "postmaster/syslogger.h"
#include "replication/walsender.h"
#include "storage/bfz.h"
#include "storage/proc.h"
#include "utils/guc_tables.h"
#include "utils/inval.h"
#include "utils/resscheduler.h"
#include "utils/vmem_tracker.h"

#ifdef USE_CONNECTEMC
#include "emcconnect/api.h"
#endif

/*
 * These constants are copied from guc.c. They should not bitrot when we
 * merge guc.c with upstream, as these are natural constants that never
 * change. guc.c might acquire more of these, though. In that case, we'll
 * just copy the new ones too, as needed.
 */
#define KB_PER_MB (1024)
#define KB_PER_GB (1024*1024)

#define MS_PER_S 1000
#define S_PER_MIN 60
#define MS_PER_MIN (1000 * 60)
#define MIN_PER_H 60
#define S_PER_H (60 * 60)
#define MS_PER_H (1000 * 60 * 60)
#define MIN_PER_D (60 * 24)
#define S_PER_D (60 * 60 * 24)
#define MS_PER_D (1000 * 60 * 60 * 24)

static bool defunct_bool = false;
static double defunct_double = 0;

/*
 * Assign/Show hook functions defined in this module
 */
static const char *assign_hashagg_compress_spill_files(const char *newval, bool doit, GucSource source);
static const char *assign_gp_workfile_compress_algorithm(const char *newval, bool doit, GucSource source);
static const char *assign_gp_workfile_type_hashjoin(const char *newval, bool doit, GucSource source);
static const char *assign_debug_persistent_print_level(const char *newval,
									bool doit, GucSource source);
static const char *assign_debug_persistent_recovery_print_level(const char *newval,
											 bool doit, GucSource source);
static const char *assign_debug_persistent_store_print_level(const char *newval,
										  bool doit, GucSource source);
static const char *assign_debug_database_command_print_level(const char *newval,
										  bool doit, GucSource source);
static const char *assign_optimizer_log_failure(const char *newval,
							 bool doit, GucSource source);
static const char *assign_optimizer_minidump(const char *newval,
						  bool doit, GucSource source);
static bool assign_optimizer(bool newval, bool doit, GucSource source);
static bool assign_codegen(bool newval, bool doit, GucSource source);
static const char *assign_codegen_optimization_level(const char *newval,
                                                     bool doit, GucSource source);
static const char *assign_optimizer_cost_model(const char *newval,
							bool doit, GucSource source);
static const char *assign_gp_workfile_caching_loglevel(const char *newval,
									bool doit, GucSource source);
static const char *assign_gp_sessionstate_loglevel(const char *newval,
								bool doit, GucSource source);
static const char *assign_time_slice_report_level(const char *newval, bool doit,
							   GucSource source);
static const char *assign_deadlock_hazard_report_level(const char *newval, bool doit,
									GucSource source);
static const char *assign_system_cache_flush_force(const char *newval, bool doit,
								GucSource source);
static const char *assign_gp_idf_deduplicate(const char *newval, bool doit,
						  GucSource source);
static const char *assign_explain_memory_verbosity(const char *newval, bool doit, GucSource source);
static bool assign_dispatch_log_stats(bool newval, bool doit, GucSource source);

static const char *assign_debug_dtm_action(const char *newval,
						bool doit, GucSource source);
static const char *assign_debug_dtm_action_target(const char *newval,
							   bool doit, GucSource source);
static const char *assign_debug_dtm_action_protocol(const char *newval,
								 bool doit, GucSource source);
static const char *assign_gp_log_format(const char *value, bool doit,
					 GucSource source);

#ifdef USE_CONNECTEMC
static const char *assign_connectemc_mode(const char *newval, bool doit, GucSource source);
#endif

/* Helper function for guc setter */
extern const char *gpvars_assign_gp_resqueue_priority_default_value(const char *newval,
												 bool doit,
								   GucSource source __attribute__((unused)));

static const char *assign_password_hash_algorithm(const char *newval,
							   bool doit, GucSource source);
static const char *assign_gp_default_storage_options(
							const char *newval, bool doit, GucSource source);

extern bool enable_partition_rules;

extern bool gp_hash_index;

/* GUC lists for gp_guc_list_show().  (List of struct config_generic) */
List	   *gp_guc_list_for_explain;
List	   *gp_guc_list_for_no_plan;

char	   *Debug_dtm_action_sql_command_tag;
char	   *Debug_dtm_action_str;
char	   *Debug_dtm_action_target_str;
char	   *Debug_dtm_action_protocol_str;

bool		Debug_print_full_dtm = false;
bool		Debug_print_snapshot_dtm = false;
bool		Debug_print_qd_mirroring = false;
bool		Debug_permit_same_host_standby = false;
bool		Debug_print_semaphore_detail = false;
bool		Debug_disable_distributed_snapshot = false;
bool		Debug_abort_after_distributed_prepared = false;
bool		Debug_abort_after_segment_prepared = false;
bool		Debug_print_tablespace = false;
bool		Debug_print_server_processes = false;
bool		Debug_print_control_checkpoints = false;
bool		Debug_appendonly_print_insert = false;
bool		Debug_appendonly_print_insert_tuple = false;
bool		Debug_appendonly_print_scan = false;
bool		Debug_appendonly_print_scan_tuple = false;
bool		Debug_appendonly_print_delete = false;
bool		Debug_appendonly_print_update = false;
bool		Debug_appendonly_print_update_tuple = false;
bool		Debug_appendonly_print_storage_headers = false;
bool		Debug_appendonly_print_verify_write_block = false;
bool		Debug_appendonly_use_no_toast = false;
bool		Debug_appendonly_print_blockdirectory = false;
bool		Debug_appendonly_print_read_block = false;
bool		Debug_appendonly_print_append_block = false;
bool		Debug_appendonly_print_segfile_choice = false;
bool        test_AppendOnlyHash_eviction_vs_just_marking_not_inuse = false;
int			Debug_appendonly_bad_header_print_level = ERROR;
bool		Debug_appendonly_print_datumstream = false;
bool		Debug_appendonly_print_visimap = false;
bool		Debug_appendonly_print_compaction = false;
bool		Debug_gp_relation_node_fetch_wait_for_debugging = false;
bool		gp_crash_recovery_abort_suppress_fatal = false;
bool		gp_persistent_statechange_suppress_error = false;
bool		Debug_bitmap_print_insert = false;
bool		Test_appendonly_override = false;
bool		Test_print_direct_dispatch_info = false;
bool		gp_test_orientation_override = false;
bool		gp_permit_persistent_metadata_update = false;
bool		gp_permit_relation_node_change = false;
int			Test_compresslevel_override = 0;
int			Test_blocksize_override = 0;
int			Test_safefswritesize_override = 0;
bool		Master_mirroring_administrator_disable = false;
int			gp_max_local_distributed_cache = 1024;
bool		gp_appendonly_verify_block_checksums = true;
bool		gp_appendonly_verify_write_block = false;
bool		gp_appendonly_verify_eof = true;
bool		gp_appendonly_compaction = true;
int			gp_appendonly_compaction_threshold = 0;
bool		gp_heap_require_relhasoids_match = true;
bool		Debug_appendonly_rezero_quicklz_compress_scratch = false;
bool		Debug_appendonly_rezero_quicklz_decompress_scratch = false;
bool		Debug_appendonly_guard_end_quicklz_scratch = false;
bool		gp_local_distributed_cache_stats = false;
bool		Debug_xlog_insert_print = false;
bool		debug_xlog_record_read = false;
bool		Debug_persistent_print = false;
int			Debug_persistent_print_level = LOG;
bool		Debug_persistent_recovery_print = true;
int			Debug_persistent_recovery_print_level = LOG;
bool		Disable_persistent_recovery_logging = false;
bool		Debug_persistent_store_print = false;
int			Debug_persistent_store_print_level = LOG;
bool		Debug_persistent_bootstrap_print = false;
bool		persistent_integrity_checks = true;
bool		disable_persistent_diagnostic_dump = false;
bool		debug_persistent_ptcat_verification = false;
bool		debug_print_persistent_checks = false;
bool		Debug_bulk_load_bypass_wal = true;
bool		Debug_persistent_appendonly_commit_count_print = false;
bool		Debug_cancel_print = false;
bool		Debug_datumstream_write_print_small_varlena_info = false;
bool		Debug_datumstream_write_print_large_varlena_info = false;
bool		Debug_datumstream_read_check_large_varlena_integrity = false;
bool		Debug_datumstream_block_read_check_integrity = false;
bool		Debug_datumstream_block_write_check_integrity = false;
bool		Debug_datumstream_read_print_varlena_info = false;
bool		Debug_datumstream_write_use_small_initial_buffers = false;
bool		gp_temporary_files_filespace_repair = false;
bool		gp_create_table_random_default_distribution = true;
bool		gp_allow_non_uniform_partitioning_ddl = true;
bool		gp_enable_exchange_default_partition = false;
int			dtx_phase2_retry_count = 0;

bool		log_dispatch_stats = false;

int			explain_memory_verbosity = 0;
char	   *memory_profiler_run_id = "none";
char	   *memory_profiler_dataset_id = "none";
char	   *memory_profiler_query_id = "none";
int			memory_profiler_dataset_size = 0;
bool		gp_dump_memory_usage = FALSE;


#define VERIFY_CHECKPOINT_INTERVAL_DEFAULT 180
int			verify_checkpoint_interval =
VERIFY_CHECKPOINT_INTERVAL_DEFAULT;

bool		Debug_rle_type_compression = false;
bool		rle_type_compression_stats = false;

bool		Debug_database_command_print = false;
int			Debug_database_command_print_level = LOG;
#define GP_MAX_DATABASES_DEFAULT 16
int			gp_max_databases = GP_MAX_DATABASES_DEFAULT;
#define GP_MAX_TABLESPACES_DEFAULT 16
int			gp_max_tablespaces = GP_MAX_TABLESPACES_DEFAULT;
#define GP_MAX_FILESPACES_DEFAULT 8
int			gp_max_filespaces = GP_MAX_FILESPACES_DEFAULT;
bool		gp_initdb_mirrored = false;
bool		gp_before_persistence_work = false;
bool		gp_before_filespace_setup = false;
bool		gp_startup_integrity_checks = true;
bool		gp_change_tracking = true;
bool		gp_persistent_repair_global_sequence = false;
bool		gp_validate_pt_info_relcache = false;
bool		Debug_print_xlog_relation_change_info = false;
bool		Debug_print_xlog_relation_change_info_skip_issues_only = false;
bool		Debug_print_xlog_relation_change_info_backtrace_skip_issues = false;

bool		Debug_filerep_crc_on = true;
bool		Debug_filerep_print = false;
bool		Debug_filerep_gcov = false;
bool		Debug_filerep_config_print = false;
bool		Debug_filerep_verify_performance_print = false;
bool		Debug_filerep_memory_log_flush = false;
bool		filerep_mirrorvalidation_during_resync = false;
bool		log_filerep_to_syslogger = false;

/* WAL based replication debug GUCs */
bool		debug_walrepl_snd = false;
bool		debug_walrepl_syncrep = false;
bool		debug_walrepl_rcv = false;
bool		debug_basebackup = false;

/* Latch mechanism debug GUCs */
bool		debug_latch = false;

bool		gp_crash_recovery_suppress_ao_eof = false;
bool		gp_keep_all_xlog = false;
int			keep_wal_segments = 0;
int			ddboost_buf_size = 512 * 1024;

#define DEBUG_DTM_ACTION_PRIMARY_DEFAULT true
bool		Debug_dtm_action_primary = DEBUG_DTM_ACTION_PRIMARY_DEFAULT;

bool		gp_log_optimization_time = false;

int			Debug_delay_prepare_broadcast_ms = 0;
int			Debug_delay_commit_broadcast_ms = 0;
int			Debug_delay_abort_broadcast_ms = 0;

int			Debug_dtm_action = DEBUG_DTM_ACTION_NONE;

#define DEBUG_DTM_ACTION_TARGET_DEFAULT DEBUG_DTM_ACTION_TARGET_NONE

int			Debug_dtm_action_target = DEBUG_DTM_ACTION_TARGET_DEFAULT;

#define DEBUG_DTM_ACTION_PROTOCOL_DEFAULT DTX_PROTOCOL_COMMAND_COMMIT_PREPARED

int			Debug_dtm_action_protocol = DEBUG_DTM_ACTION_PROTOCOL_DEFAULT;

#define DEBUG_DTM_ACTION_DELAY_MS_DEFAULT 5000
#define DEBUG_DTM_ACTION_SEGMENT_DEFAULT 1
#define DEBUG_DTM_ACTION_NESTINGLEVEL_DEFAULT 0

int			Debug_dtm_action_delay_ms = DEBUG_DTM_ACTION_DELAY_MS_DEFAULT;
int			Debug_dtm_action_segment = DEBUG_DTM_ACTION_SEGMENT_DEFAULT;
int			Debug_dtm_action_nestinglevel = DEBUG_DTM_ACTION_NESTINGLEVEL_DEFAULT;

/* Enable check for compatibility of encoding and locale in createdb */
bool		gp_encoding_check_locale_compatibility;

int			gp_connection_send_timeout;

int			gp_filerep_tcp_keepalives_idle;
int			gp_filerep_tcp_keepalives_interval;
int			gp_filerep_tcp_keepalives_count;

int			WalSendClientTimeout = 30000;		/* 30 seconds. */

char	   *data_directory;

char	   *gp_email_smtp_server;
char	   *gp_email_smtp_userid;
char	   *gp_email_smtp_password;
char	   *gp_email_from;
char	   *gp_email_to;
int			gp_email_connect_timeout;
int			gp_email_connect_failures;
int			gp_email_connect_avoid_duration;

#if USE_SNMP
char	   *gp_snmp_community;
char	   *gp_snmp_monitor_address;
char	   *gp_snmp_use_inform_or_trap;
char	   *gp_snmp_debug_log;
#endif

char	   *gp_connectemc_mode;
#ifdef USE_CONNECTEMC
EmcConnectModeType_t gp_emcconnect_transport;
#endif

static char *gp_log_gang_str;
static char *gp_log_fts_str;
static char *gp_log_interconnect_str;
static char *gp_interconnect_type_str;
static char *gp_interconnect_fc_method_str;

/*
 * These variables are all dummies that don't do anything, except in some
 * cases provide the value for SHOW to display.  The real state is elsewhere
 * and is kept in sync by assign_hooks.
 */
static char *gp_hashagg_compress_spill_files_str;
static char *gp_workfile_compress_algorithm_str;
static char *gp_workfile_type_hashjoin_str;
static char *optimizer_log_failure_str;
static char *optimizer_minidump_str;
static char *optimizer_cost_model_str;
static char *Debug_persistent_print_level_str;
static char *Debug_persistent_recovery_print_level_str;
static char *Debug_persistent_store_print_level_str;
static char *Debug_database_command_print_level_str;
static char *gp_log_format_string;
static char *gp_workfile_caching_loglevel_str;
static char *gp_sessionstate_loglevel_str;
static char *explain_memory_verbosity_str;

/* Backoff-related GUCs */
bool		gp_enable_resqueue_priority;
int			gp_resqueue_priority_local_interval;
int			gp_resqueue_priority_sweeper_interval;
int			gp_resqueue_priority_inactivity_timeout;
int			gp_resqueue_priority_grouping_timeout;
double		gp_resqueue_priority_cpucores_per_segment;
char	   *gp_resqueue_priority_default_value;
bool		gp_debug_resqueue_priority = false;

/* Perfmon segment GUCs */
int			gp_perfmon_segment_interval;
static char *gpperfmon_log_alert_level_str;

/* Perfmon debug GUC */
bool		gp_perfmon_print_packet_info;

/* Simulator of Exceptions (SimEx) GUCs */
bool		gp_simex_init;
bool		gp_simex_run;
int			gp_simex_class;
double		gp_simex_rand;

/* time slice enforcement */
bool		gp_test_time_slice;
int			gp_test_time_slice_interval;
int			gp_test_time_slice_report_level = ERROR;
static char *gp_test_time_slice_report_level_str;

/* database-lightweight lock hazard detection */
bool		gp_test_deadlock_hazard;
int			gp_test_deadlock_hazard_report_level = ERROR;
static char *gp_test_deadlock_hazard_report_level_str;

/* query cancellation GUC */
bool		gp_cancel_query_print_log;
int			gp_cancel_query_delay_time;
bool		vmem_process_interrupt = false;

/* partitioning GUC */
bool		gp_partitioning_dynamic_selection_log;
int			gp_max_partition_level;

/* Upgrade & maintenance GUCs */
bool		gp_maintenance_mode;
bool		gp_maintenance_conn;
bool		allow_segment_DML;
bool		gp_allow_rename_relation_without_lock = false;

/* ignore EXCLUDE clauses in window spec for backwards compatibility */
bool		gp_ignore_window_exclude = false;

/* Hadoop Integration GUCs */
char	   *gp_hadoop_connector_jardir;
char	   *gp_hadoop_connector_version = "";	/* old GUC; now it's a global
												 * var. */
char	   *gp_hadoop_target_version;
char	   *gp_hadoop_home;

/* Time based authentication GUC */
char	   *gp_auth_time_override_str = NULL;

/* Password hashing */
char	   *password_hash_algorithm_str = "MD5";
PasswdHashAlg password_hash_algorithm = PASSWORD_HASH_MD5;

/* system cache invalidation mode*/
int			gp_test_system_cache_flush_force = SysCacheFlushForce_Off;
static char *gp_test_system_cache_flush_force_str;

/* include file/line information to stack traces */
bool		gp_log_stack_trace_lines;


/*
 * If set to true, we will silently insert into the correct leaf
 * part even if the user specifies a wrong leaf part as a insert target
 */
bool		dml_ignore_target_partition_check = false;

char	   *gp_idf_deduplicate_str;

bool		fts_diskio_check = false;

/* Planner gucs */
bool		gp_enable_hashjoin_size_heuristic = false;
bool		gp_enable_fallback_plan = true;
bool		gp_enable_predicate_propagation = false;
bool		gp_enable_multiphase_agg = true;
bool		gp_enable_preunique = TRUE;
bool		gp_eager_preunique = FALSE;
bool		gp_enable_sequential_window_plans = FALSE;
bool		gp_hashagg_streambottom = true;
bool		gp_enable_agg_distinct = true;
bool		gp_enable_dqa_pruning = true;
bool		gp_eager_dqa_pruning = FALSE;
bool		gp_eager_one_phase_agg = FALSE;
bool		gp_eager_two_phase_agg = FALSE;
bool		gp_enable_groupext_distinct_pruning = true;
bool		gp_enable_groupext_distinct_gather = true;
bool		gp_dynamic_partition_pruning = true;
bool		gp_log_dynamic_partition_pruning = false;
bool		gp_cte_sharing = false;
bool		gp_enable_relsize_collection = false;

/* ORCA related gucs */
bool		optimizer_control = true;
bool		optimizer;
bool		optimizer_log;
bool		optimizer_partition_selection_log;
bool		optimizer_minidump;
int			optimizer_cost_model;
bool		optimizer_print_query;
bool		optimizer_print_plan;
bool		optimizer_print_xform;
bool		optimizer_metadata_caching;
int		optimizer_mdcache_size;
bool		optimizer_disable_xform_result_printing;
bool		optimizer_print_memo_after_exploration;
bool		optimizer_print_memo_after_implementation;
bool		optimizer_print_memo_after_optimization;
bool		optimizer_print_job_scheduler;
bool		optimizer_print_expression_properties;
bool		optimizer_print_group_properties;
bool		optimizer_print_optimization_context;
bool		optimizer_print_optimization_stats;
bool		optimizer_local;
int			optimizer_retries;
/* array of xforms disable flags */
bool		optimizer_xforms[OPTIMIZER_XFORMS_COUNT] = {[0 ... OPTIMIZER_XFORMS_COUNT - 1] = false};
char	   *optimizer_search_strategy_path = NULL;
char	   *gp_idf_deduplicate_str;
bool		optimizer_extract_dxl_stats;
bool		optimizer_extract_dxl_stats_all_nodes;
bool		optimizer_disable_missing_stats_collection;
bool		optimizer_dpe_stats;
bool		optimizer_enable_indexjoin;
bool		optimizer_enable_motions_masteronly_queries;
bool		optimizer_enable_motions;
bool		optimizer_enable_motion_broadcast;
bool		optimizer_enable_motion_gather;
bool		optimizer_enable_motion_redistribute;
bool		optimizer_enable_sort;
bool		optimizer_enable_materialize;
bool		optimizer_enable_partition_propagation;
bool		optimizer_enable_partition_selection;
bool		optimizer_enable_outerjoin_rewrite;
bool		optimizer_enable_space_pruning;
bool		optimizer_prefer_multistage_agg;
bool		optimizer_enable_multiple_distinct_aggs;
bool		optimizer_prefer_expanded_distinct_aggs;
bool		optimizer_prune_computed_columns;
bool		optimizer_push_requirements_from_consumer_to_producer;
bool		optimizer_direct_dispatch;
bool		optimizer_enable_hashjoin_redistribute_broadcast_children;
bool		optimizer_enable_broadcast_nestloop_outer_child;
bool		optimizer_enforce_subplans;
bool		optimizer_enable_assert_maxonerow;
bool		optimizer_enumerate_plans;
bool		optimizer_sample_plans;
int			optimizer_plan_id;
int			optimizer_samples_number;
int			optimizer_log_failure;
double		optimizer_cost_threshold;
double		optimizer_nestloop_factor;
double		optimizer_sort_factor;
bool		optimizer_cte_inlining;
int			optimizer_cte_inlining_bound;
double		optimizer_damping_factor_filter;
double		optimizer_damping_factor_join;
double		optimizer_damping_factor_groupby;
int			optimizer_segments;
int			optimizer_join_arity_for_associativity_commutativity;
int			optimizer_penalize_broadcast_threshold;
int         optimizer_array_expansion_threshold;
int         optimizer_join_order_threshold;
bool		optimizer_analyze_root_partition;
bool		optimizer_analyze_midlevel_partition;
bool		optimizer_enable_constant_expression_evaluation;
bool		optimizer_use_external_constant_expression_evaluation_for_ints;
bool		optimizer_enable_bitmapscan;
bool		optimizer_enable_outerjoin_to_unionall_rewrite;
bool		optimizer_apply_left_outer_to_union_all_disregarding_stats;
bool		optimizer_enable_ctas;
bool		optimizer_remove_order_below_dml;
bool		optimizer_static_partition_selection;
bool		optimizer_enable_partial_index;
bool		optimizer_dml_triggers;
bool		optimizer_dml_constraints;
bool		optimizer_enable_master_only_queries;
bool		optimizer_multilevel_partitioning;
bool		optimizer_enable_derive_stats_all_groups;
bool		optimizer_explain_show_status;
bool		optimizer_prefer_scalar_dqa_multistage_agg;
bool 		optimizer_parallel_union;
bool		optimizer_array_constraints;

/**
 * GUCs related to code generation.
 **/
bool		init_codegen;
bool		codegen;
bool		codegen_validate_functions;
bool		codegen_exec_variable_list;
bool		codegen_slot_getattr;
bool		codegen_exec_eval_expr;
bool		codegen_advance_aggregate;
int		codegen_varlen_tolerance;
int		codegen_optimization_level;
static char 	*codegen_optimization_level_str = NULL;

/* System Information */
static int	gp_server_version_num;
static char *gp_server_version_string;

/* Security */
bool		gp_reject_internal_tcp_conn = true;

/*
 * Default storage options GUC.  Value is comma-separated name=value
 * pairs.  E.g. "appendonly=true,orientation=column"
 */
char	   *gp_default_storage_options = NULL;

int			writable_external_table_bufsize = 64;

IndexCheckType gp_indexcheck_insert = INDEX_CHECK_NONE;
IndexCheckType gp_indexcheck_vacuum = INDEX_CHECK_NONE;

struct config_bool ConfigureNamesBool_gp[] =
{
	{
		{"maintenance_mode", PGC_POSTMASTER, CUSTOM_OPTIONS,
			gettext_noop("Maintenance Mode"),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_maintenance_mode,
		false, NULL, NULL
	},

	{
		{"gp_maintenance_conn", PGC_BACKEND, CUSTOM_OPTIONS,
			gettext_noop("Maintenance Connection"),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_maintenance_conn,
		false, NULL, NULL
	},

	{
		{"allow_segment_DML", PGC_USERSET, CUSTOM_OPTIONS,
			gettext_noop("Allow DML on segments"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&allow_segment_DML,
		false, NULL, NULL
	},
	{
		{"gp_allow_rename_relation_without_lock", PGC_USERSET, CUSTOM_OPTIONS,
			gettext_noop("Allow ALTER TABLE RENAME without AccessExclusiveLock"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_allow_rename_relation_without_lock,
		false, NULL, NULL
	},
	{
		{"enable_groupagg", PGC_USERSET, QUERY_TUNING_METHOD,
			gettext_noop("Enables the planner's use of grouping aggregation plans."),
			NULL
		},
		&enable_groupagg,
		true, NULL, NULL
	},
	{
		{"gp_enable_hashjoin_size_heuristic", PGC_USERSET, QUERY_TUNING_METHOD,
			gettext_noop("In hash join plans, the smaller of the two inputs "
						 "(as estimated) is used to build the hash table."),
			gettext_noop("If false, either input could be used to build the "
					  "hash table; the choice depends on the estimated hash "
						 "join cost, which the planner computes for both "
						 "alternatives.  Has no effect on outer or adaptive "
						 "joins."),
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_enable_hashjoin_size_heuristic,
		false, NULL, NULL
	},
	{
		{"gp_enable_fallback_plan", PGC_USERSET, QUERY_TUNING_METHOD,
			gettext_noop("Plan types which are not enabled may be used when a "
						 "query would be infeasible without them."),
			gettext_noop("If false, planner rejects queries that cannot be "
						 "satisfied using only the enabled plan types.")
		},
		&gp_enable_fallback_plan,
		true, NULL, NULL
	},
	{
		{"gp_enable_direct_dispatch", PGC_USERSET, QUERY_TUNING_METHOD,
			gettext_noop("Enable dispatch for single-row-insert targetted mirror-pairs."),
			gettext_noop("Don't involve the whole cluster if it isn't needed.")
		},
		&gp_enable_direct_dispatch,
		true, NULL, NULL
	},
	{
		{"gp_enable_predicate_propagation", PGC_USERSET, QUERY_TUNING_OTHER,
			gettext_noop("When two expressions are equivalent (such as with "
					  "equijoined keys) then the planner applies predicates "
						 "on one expression to the other expression."),
			gettext_noop("If false, planner does not copy predicates.")
		},
		&gp_enable_predicate_propagation,
		true, NULL, NULL
	},
	{
		{"gp_workfile_checksumming", PGC_USERSET, QUERY_TUNING_OTHER,
			gettext_noop("Enable checksumming on the executor work files in order to "
				"catch possible faulty writes caused by your disk drivers."),
			NULL,
			GUC_GPDB_ADDOPT
		},
		&gp_workfile_checksumming,
		true, NULL, NULL
	},
	{
		{"force_bitmap_table_scan", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Forces bitmap table scan instead of bitmap heap/ao/aoco scan."),
			NULL,
			GUC_GPDB_ADDOPT | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&force_bitmap_table_scan,
		false, NULL, NULL
	},
	{
		{"gp_workfile_faultinject", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Fault inject a torn page to an executor workfile."),
			gettext_noop("Used to simulate a failure and test workfile checksumming."),
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_GPDB_ADDOPT
		},
		&gp_workfile_faultinject,
		false, NULL, NULL
	},
	{
		{"memory_protect_buffer_pool", PGC_POSTMASTER, DEVELOPER_OPTIONS,
			gettext_noop("Enables memory protection of the buffer pool"),
			gettext_noop("Turn on memory protection of the buffer pool "
					"to detect invalid accesses to the buffer pool memory."),
			GUC_NOT_IN_SAMPLE | GUC_NO_SHOW_ALL
		},
		&memory_protect_buffer_pool, false, NULL, NULL
	},
	{
		{"debug_print_prelim_plan", PGC_USERSET, LOGGING_WHAT,
			gettext_noop("Prints the preliminary execution plan to server log."),
			NULL
		},
		&Debug_print_prelim_plan,
		false, NULL, NULL
	},
	{
		{"debug_print_slice_table", PGC_USERSET, LOGGING_WHAT,
			gettext_noop("Prints the slice table to server log."),
			NULL
		},
		&Debug_print_slice_table,
		false, NULL, NULL
	},
	{
		{"log_dispatch_stats", PGC_SUSET, STATS_MONITORING,
			gettext_noop("Writes dispatcher performance statistics to the server log."),
			NULL,
			GUC_GPDB_ADDOPT
		},
		&log_dispatch_stats,
		false, assign_dispatch_log_stats, NULL
	},

	{
		{"enable_agg_restructure", PGC_USERSET, QUERY_TUNING_METHOD,
			gettext_noop("Deprecated: use gp_enable_multiphase_agg."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&defunct_bool,
		true, NULL, NULL
	},

	{
		/* MPP-9772, MPP-9773: remove support for CREATE INDEX CONCURRENTLY */
		{"gp_create_index_concurrently", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Allow concurrent index creation."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_create_index_concurrently,
		false, NULL, NULL
	},

	{
		{"gp_enable_multiphase_agg", PGC_USERSET, QUERY_TUNING_METHOD,
			gettext_noop("Enables the planner's use of two- or three-stage parallel aggregation plans."),
			gettext_noop("Allows partial aggregation before motion.")
		},
		&gp_enable_multiphase_agg,
		true, NULL, NULL
	},

	{
		{"gp_enable_hash_partitioned_tables", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Enable hash partitioned tables."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_enable_hash_partitioned_tables,
		false, NULL, NULL
	},

	{
		{"gp_setwith_alter_storage", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Let SET WITH alter the storage options."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_setwith_alter_storage,
		false, NULL, NULL
	},

	{
		{"gp_enable_preunique", PGC_USERSET, QUERY_TUNING_METHOD,
			gettext_noop("Enable 2-phase duplicate removal."),
			gettext_noop("If true, planner may choose to remove duplicates in "
						 "two phases--before and after redistribution.")
		},
		&gp_enable_preunique,
		true, NULL, NULL
	},

	{
		{"gp_eager_preunique", PGC_USERSET, QUERY_TUNING_METHOD,
			gettext_noop("Experimental feature: 2-phase duplicate removal - cost override."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_eager_preunique,
		false, NULL, NULL
	},

	{
		{"gp_enable_sequential_window_plans", PGC_USERSET, QUERY_TUNING_METHOD,
			gettext_noop("Experimental feature: Enable non-parallel window plans."),
			gettext_noop("The planner will evaluate window functions associated with separate "
			   "window specifications sequentially rather that in parallel.")
		},
		&gp_enable_sequential_window_plans,
		true, NULL, NULL
	},

	{
		{"gp_enable_agg_distinct", PGC_USERSET, QUERY_TUNING_METHOD,
			gettext_noop("Enable 2-phase aggregation to compute a single distinct-qualified aggregate."),
			NULL,
		},
		&gp_enable_agg_distinct,
		true, NULL, NULL
	},

	{
		{"gp_enable_agg_distinct_pruning", PGC_USERSET, QUERY_TUNING_METHOD,
			gettext_noop("Enable 3-phase aggregation and join to compute distinct-qualified aggregates."),
			NULL,
		},
		&gp_enable_dqa_pruning,
		true, NULL, NULL
	},

	{
		{"gp_enable_groupext_distinct_pruning", PGC_USERSET, QUERY_TUNING_METHOD,
			gettext_noop("Enable 3-phase aggregation and join to compute distinct-qualified aggregates"
						 " on grouping extention queries."),
			NULL,
		},
		&gp_enable_groupext_distinct_pruning,
		true, NULL, NULL
	},

	{
		{"gp_enable_groupext_distinct_gather", PGC_USERSET, QUERY_TUNING_METHOD,
			gettext_noop("Enable gathering data to a single node to compute distinct-qualified aggregates"
						 " on grouping extention queries."),
			NULL,
		},
		&gp_enable_groupext_distinct_gather,
		true, NULL, NULL
	},

	{
		{"gp_eager_agg_distinct_pruning", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Prefer 3-phase aggregation [and join] to compute distinct-qualified aggregates."),
			gettext_noop("The planner will prefer to use 3-phase aggregation and join to compute "
				"distinct-qualified aggregates whenever enabled and possible"
						 "regardless of cost estimates."),
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_eager_dqa_pruning,
		false, NULL, NULL
	},

	{
		{"gp_eager_one_phase_agg", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Prefer 1-phase aggregation."),
			gettext_noop("The planner will prefer to use 1-phase aggregation whenever possible"
						 "regardless of cost estimates."),
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_eager_one_phase_agg,
		false, NULL, NULL
	},

	{
		{"gp_eager_two_phase_agg", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Prefer 2-phase aggregation."),
			gettext_noop("The planner will prefer to use 2-phase aggregation whenever"
					   "enabled and possible regardless of cost estimates."),
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_eager_two_phase_agg,
		false, NULL, NULL
	},

	{
		{"gp_dev_notice_agg_cost", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Trace aggregate costing decisions as NOTICEs."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_dev_notice_agg_cost,
		false, NULL, NULL
	},

	{
		{"gp_enable_explain_allstat", PGC_USERSET, CLIENT_CONN_OTHER,
			gettext_noop("Experimental feature: dump stats for all segments in EXPLAIN ANALYZE."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_enable_explain_allstat,
		false, NULL, NULL
	},

	{
		{"gp_dump_memory_usage", PGC_USERSET, CLIENT_CONN_OTHER,
			gettext_noop("Save memory usage in each segment."),
			NULL,
			GUC_GPDB_ADDOPT | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_dump_memory_usage,
		false, NULL, NULL
	},

	{
		{"gp_enable_sort_limit", PGC_USERSET, QUERY_TUNING_METHOD,
			gettext_noop("Enable LIMIT operation to be performed while sorting."),
			gettext_noop("Sort more efficiently when plan requires the first <n> rows at most.")
		},
		&gp_enable_sort_limit,
		true, NULL, NULL
	},

	{
		{"gp_enable_sort_distinct", PGC_USERSET, QUERY_TUNING_METHOD,
			gettext_noop("Enable duplicate removal to be performed while sorting."),
			gettext_noop("Reduces data handling when plan calls for removing duplicates from sorted rows.")
		},
		&gp_enable_sort_distinct,
		true, NULL, NULL
	},

	{
		{"gp_parquet_insert_sort", PGC_USERSET, RESOURCES_MEM,
			gettext_noop("Enable sorting of tuples during insertion in parquet partitioned tables."),
			gettext_noop("Reduces memory usage required for insertion by keeping on part open at a time"),
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_GPDB_ADDOPT

		},
		&gp_parquet_insert_sort,
		true, NULL, NULL
	},

	{
		{"gp_enable_mk_sort", PGC_USERSET, QUERY_TUNING_METHOD,
			gettext_noop("Enable multi-key sort."),
			gettext_noop("A faster sort."),
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_GPDB_ADDOPT

		},
		&gp_enable_mk_sort,
		true, NULL, NULL
	},

	{
		{"gp_enable_motion_mk_sort", PGC_USERSET, QUERY_TUNING_METHOD,
			gettext_noop("Enable multi-key sort in sorted motion recv."),
			gettext_noop("A faster sort for recv motion"),
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_GPDB_ADDOPT

		},
		&gp_enable_motion_mk_sort,
		true, NULL, NULL
	},


#ifdef USE_ASSERT_CHECKING
	{
		{"gp_mk_sort_check", PGC_USERSET, QUERY_TUNING_METHOD,
			gettext_noop("Extensive check mk_sort"),
			gettext_noop("Expensive debug checking"),
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_GPDB_ADDOPT
		},
		&gp_mk_sort_check,
		false, NULL, NULL
	},
#endif

	{
		{"gp_hashagg_streambottom", PGC_USERSET, QUERY_TUNING_METHOD,
			gettext_noop("Stream the bottom stage of two stage hashagg"),
			gettext_noop("Avoid spilling at the bottom stage of two stage hashagg"),
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_hashagg_streambottom,
		true, NULL, NULL
	},

	{
		{"gp_enable_motion_deadlock_sanity", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Enable verbose check at planning time."),
			NULL,
			GUC_NO_RESET_ALL | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_enable_motion_deadlock_sanity,
		false, NULL, NULL
	},

	{
		{"gp_adjust_selectivity_for_outerjoins", PGC_USERSET, QUERY_TUNING_METHOD,
			gettext_noop("Adjust selectivity of null tests over outer joins."),
			NULL,
			GUC_NOT_IN_SAMPLE
		},
		&gp_adjust_selectivity_for_outerjoins,
		true, NULL, NULL
	},

	{
		{"gp_selectivity_damping_for_scans", PGC_USERSET, QUERY_TUNING_METHOD,
			gettext_noop("Damping of selectivities for clauses over the same base relation."),
			NULL,
			GUC_NOT_IN_SAMPLE | GUC_NO_SHOW_ALL
		},
		&gp_selectivity_damping_for_scans,
		true, NULL, NULL
	},

	{
		{"gp_selectivity_damping_for_joins", PGC_USERSET, QUERY_TUNING_METHOD,
			gettext_noop("Damping of selectivities in join clauses."),
			NULL,
			GUC_NOT_IN_SAMPLE | GUC_NO_SHOW_ALL
		},
		&gp_selectivity_damping_for_joins,
		false, NULL, NULL
	},

	{
		{"gp_selectivity_damping_sigsort", PGC_USERSET, QUERY_TUNING_METHOD,
			gettext_noop("Sort selectivities by ascending significance, i.e. smallest first"),
			NULL,
			GUC_NOT_IN_SAMPLE | GUC_NO_SHOW_ALL
		},
		&gp_selectivity_damping_sigsort,
		true, NULL, NULL
	},

	{
		{"gp_crash_recovery_abort_suppress_fatal", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Warning about crash recovery abort transaction issue"),
			NULL,
			GUC_NOT_IN_SAMPLE | GUC_NO_SHOW_ALL
		},
		&gp_crash_recovery_abort_suppress_fatal,
		false, NULL, NULL
	},
	{
		{"gp_persistent_statechange_suppress_error", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Warning about persistent state-change issue"),
			NULL,
			GUC_NOT_IN_SAMPLE | GUC_NO_SHOW_ALL
		},
		&gp_persistent_statechange_suppress_error,
		false, NULL, NULL
	},
	{
		{"gp_select_invisible", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Use dummy snapshot for MVCC visibility calculation."),
			NULL,
			GUC_NOT_IN_SAMPLE | GUC_NO_SHOW_ALL | GUC_GPDB_ADDOPT
		},
		&gp_select_invisible,
		false, NULL, NULL
	},

	{
		{"gp_enable_slow_writer_testmode", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Slow down writer gangs -- to facilitate race-condition testing."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_enable_slow_writer_testmode,
		false, NULL, NULL
	},

	{
		{"gp_fts_probe_pause", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Stop active probes."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_fts_probe_pause,
		false, gpvars_assign_gp_fts_probe_pause, NULL
	},

	{
		{"gp_fts_transition_parallel", PGC_POSTMASTER, GP_ARRAY_TUNING,
			gettext_noop("Activate parallel segment transition."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_fts_transition_parallel,
		true, NULL, NULL
	},

	{
		{"gp_debug_pgproc", PGC_POSTMASTER, DEVELOPER_OPTIONS,
			gettext_noop("Print debug info relevant to PGPROC."),
			NULL /* long description */ ,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_debug_pgproc,
		false, NULL, NULL
	},

	{
		{"gp_appendonly_verify_block_checksums", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Verify the append-only block checksum when reading."),
			NULL,
			GUC_NOT_IN_SAMPLE | GUC_NO_SHOW_ALL
		},
		&gp_appendonly_verify_block_checksums,
		true, NULL, NULL
	},

	{
		{"gp_appendonly_verify_write_block", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Verify the append-only block as it is being written."),
			NULL,
			GUC_NOT_IN_SAMPLE | GUC_NO_SHOW_ALL
		},
		&gp_appendonly_verify_write_block,
		false, NULL, NULL
	},

	{
		{"gp_appendonly_verify_eof", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Verify append-only eof integrity before writing."),
			NULL,
			GUC_NOT_IN_SAMPLE | GUC_NO_SHOW_ALL
		},
		&gp_appendonly_verify_eof,
		true, NULL, NULL
	},

	{
		{"gp_appendonly_compaction", PGC_SUSET, APPENDONLY_TABLES,
			gettext_noop("Perform append-only compaction instead of eof truncation on vacuum."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NOT_IN_SAMPLE | GUC_NO_SHOW_ALL
		},
		&gp_appendonly_compaction,
		true, NULL, NULL
	},

	{
		{"gp_heap_require_relhasoids_match", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Issue an error on discovery of a mismatch between relhasoids and a tuple header."),
			NULL,
			GUC_NOT_IN_SAMPLE | GUC_NO_SHOW_ALL
		},
		&gp_heap_require_relhasoids_match,
		true, NULL, NULL
	},

	{
		{"debug_appendonly_rezero_quicklz_compress_scratch", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Zero the QuickLZ scratch buffer before each append-only block that is being compressed."),
			NULL,
			GUC_NOT_IN_SAMPLE | GUC_NO_SHOW_ALL
		},
		&Debug_appendonly_rezero_quicklz_compress_scratch,
		false, NULL, NULL
	},

	{
		{"debug_appendonly_guard_end_quicklz_scratch", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Put a guard area of all zeroes after the QuickLZ scratch buffers and verify it is still zero before and after compress and decompress operations."),
			NULL,
			GUC_NOT_IN_SAMPLE | GUC_NO_SHOW_ALL
		},
		&Debug_appendonly_guard_end_quicklz_scratch,
		false, NULL, NULL
	},

	{
		{"debug_appendonly_rezero_quicklz_decompress_scratch", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Zero the QuickLZ scratch buffer before each append-only block that is being decompressed."),
			NULL,
			GUC_NOT_IN_SAMPLE | GUC_NO_SHOW_ALL
		},
		&Debug_appendonly_rezero_quicklz_decompress_scratch,
		false, NULL, NULL
	},

	{
		{"gp_cost_hashjoin_chainwalk", PGC_USERSET, QUERY_TUNING_COST,
			gettext_noop("Enable the cost for walking the chain in the hash join"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_cost_hashjoin_chainwalk,
		false, NULL, NULL
	},

	{
		{"gp_set_read_only", PGC_SUSET, GP_ARRAY_CONFIGURATION,
			gettext_noop("Sets the system read only"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_set_read_only,
		false, NULL, NULL
	},

	{
		{"gp_set_proc_affinity", PGC_POSTMASTER, RESOURCES_KERNEL,
			gettext_noop("On postmaster startup, attempt to bind postmaster to a processor"),
			NULL
		},
		&gp_set_proc_affinity,
		false, NULL, NULL
	},

	{
		{"gp_is_writer", PGC_BACKEND, GP_WORKER_IDENTITY,
			gettext_noop("True in a worker process which can directly update its local database segment."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE
		},
		&Gp_is_writer,
		false, NULL, NULL
	},

	{
		{"gp_write_shared_snapshot", PGC_USERSET, UNGROUPED,
			gettext_noop("Forces the writer gang to set the shared snapshot."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NO_RESET_ALL | GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE
		},
		&Gp_write_shared_snapshot,
		false, assign_gp_write_shared_snapshot, NULL
	},

	{
		{"gp_reraise_signal", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Do we attempt to dump core when a serious problem occurs."),
			NULL,
			GUC_NO_RESET_ALL
		},
		&gp_reraise_signal,
		true, NULL, NULL
	},

	{
		{"gp_backup_directIO", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Enable direct IO dump"),
			NULL
		},
		&gp_backup_directIO,
		false, NULL, NULL
	},

	{
		{"gp_external_enable_exec", PGC_POSTMASTER, EXTERNAL_TABLES,
			gettext_noop("Enable selecting from an external table with an EXECUTE clause."),
			NULL
		},
		&gp_external_enable_exec,
		true, NULL, NULL
	},

	{
		{"gp_enable_fast_sri", PGC_USERSET, QUERY_TUNING_OTHER,
			gettext_noop("Enable single-slice single-row inserts."),
			NULL
		},
		&gp_enable_fast_sri,
		true, NULL, NULL
	},

	{
		{"gp_interconnect_full_crc", PGC_USERSET, QUERY_TUNING_OTHER,
			gettext_noop("Sanity check incoming data stream."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_GPDB_ADDOPT
		},
		&gp_interconnect_full_crc,
		false, NULL, NULL
	},

	{
		{"gp_interconnect_log_stats", PGC_USERSET, QUERY_TUNING_OTHER,
			gettext_noop("Emit statistics from the UDP-IC at the end of every statement."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_GPDB_ADDOPT
		},
		&gp_interconnect_log_stats,
		false, NULL, NULL
	},

	{
		{"gp_interconnect_cache_future_packets", PGC_USERSET, GP_ARRAY_TUNING,
			gettext_noop("Control whether future packets are cached."),
			NULL,
		},
		&gp_interconnect_cache_future_packets,
		true, NULL, NULL
	},

	{
		{"gp_external_grant_privileges", PGC_POSTMASTER, EXTERNAL_TABLES,
			gettext_noop("Enable non superusers to create http or gpfdist external tables."),
			NULL
		},
		&gp_external_grant_privileges,
		false, NULL, NULL
	},

	{
		{"resource_scheduler", PGC_POSTMASTER, RESOURCES_MGM,
			gettext_noop("Enable resource scheduling."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&ResourceScheduler,
		true, NULL, NULL
	},
	{
		{"resource_select_only", PGC_POSTMASTER, RESOURCES_MGM,
			gettext_noop("Enable resource locking of SELECT only."),
			NULL
		},
		&ResourceSelectOnly,
		false, NULL, NULL
	},
	{
		{"resource_cleanup_gangs_on_wait", PGC_USERSET, RESOURCES_MGM,
			gettext_noop("Enable idle gang cleanup before resource lockwait."),
			NULL
		},
		&ResourceCleanupIdleGangs,
		true, NULL, NULL
	},

	{
		{"gp_debug_resqueue_priority", PGC_USERSET, RESOURCES_MGM,
			gettext_noop("Print out debugging information about backoff calls."),
			NULL,
			GUC_NO_SHOW_ALL
		},
		&gp_debug_resqueue_priority,
		false, NULL, NULL
	},

	{
		{"debug_print_full_dtm", PGC_SUSET, LOGGING_WHAT,
			gettext_noop("Prints full DTM information to server log."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_print_full_dtm,
		false, NULL, NULL
	},

	{
		{"debug_print_snapshot_dtm", PGC_SUSET, LOGGING_WHAT,
			gettext_noop("Prints snapshot DTM information to server log."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_print_snapshot_dtm,
		false, NULL, NULL
	},

	{
		{"debug_print_qd_mirroring", PGC_SUSET, LOGGING_WHAT,
			gettext_noop("Prints QD mirroring information to server log."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_print_qd_mirroring,
		false, NULL, NULL
	},

	{
		{"debug_permit_same_host_standby", PGC_SUSET, LOGGING_WHAT,
			gettext_noop("Permits QD mirroring standby to exist on same host as primary."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_permit_same_host_standby,
		false, NULL, NULL
	},

	{
		{"Debug_print_semaphore_detail", PGC_SUSET, LOGGING_WHAT,
			gettext_noop("Print semaphore detailed information."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_print_semaphore_detail,
		false, NULL, NULL
	},

	{
		{"debug_disable_distributed_snapshot", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Disables distributed snapshots."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_disable_distributed_snapshot,
		false, NULL, NULL
	},

	{
		{"debug_abort_after_distributed_prepared", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Cause an abort after all segments are prepared but before the distributed commit is written."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_abort_after_distributed_prepared,
		false, NULL, NULL
	},

	{
		{"debug_abort_after_segment_prepared", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Cause an abort after segment has written prepared XLOG record."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_abort_after_segment_prepared,
		false, NULL, NULL
	},

	{
		{"debug_print_tablespace", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Print TABLESPACE debugging information."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_print_tablespace,
		false, NULL, NULL
	},

	{
		{"debug_appendonly_print_blockdirectory", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Print log messages for append-only block directory."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_appendonly_print_blockdirectory,
		false, NULL, NULL
	},

	{
		{"Debug_appendonly_print_read_block", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Print log messages for append-only reads."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_appendonly_print_read_block,
		false, NULL, NULL
	},

	{
		{"Debug_appendonly_print_append_block", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Print log messages for append-only writes."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_appendonly_print_append_block,
		false, NULL, NULL
	},

	{
		{"debug_appendonly_print_visimap", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Print log messages for append-only visibility bitmap information."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_appendonly_print_visimap,
		false, NULL, NULL
	},

	{
		{"debug_appendonly_print_compaction", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Print log messages about append-only visibility compactions."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_appendonly_print_compaction,
		false, NULL, NULL
	},

	{
		{"debug_appendonly_print_insert", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Print log messages for append-only insert."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_appendonly_print_insert,
		false, NULL, NULL
	},

	{
		{"debug_appendonly_print_insert_tuple", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Print log messages for append-only insert tuples (caution -- generates a lot of log!)."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_appendonly_print_insert_tuple,
		false, NULL, NULL
	},

	{
		{"debug_appendonly_print_scan", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Print log messages for append-only scan."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_appendonly_print_scan,
		false, NULL, NULL
	},

	{
		{"debug_appendonly_print_scan_tuple", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Print log messages for append-only scan tuples (caution -- generates a lot of log!)."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_appendonly_print_scan_tuple,
		false, NULL, NULL
	},

	{
		{"debug_appendonly_print_delete", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Print log messages for append-only delete."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_appendonly_print_delete,
		false, NULL, NULL
	},

	{
		{"debug_appendonly_print_update", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Print log messages for append-only update."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_appendonly_print_update,
		false, NULL, NULL
	},

	{
		{"debug_appendonly_print_update_tuple", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Print log messages for append-only update tuples (caution -- generates a lot of log!)."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_appendonly_print_update_tuple,
		false, NULL, NULL
	},

	{
		{"debug_appendonly_print_storage_headers", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Print log messages for append-only storage headers."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_appendonly_print_storage_headers,
		false, NULL, NULL
	},

	{
		{"debug_appendonly_print_verify_write_block", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Print log messages for append-only verify block during write."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_appendonly_print_verify_write_block,
		false, NULL, NULL
	},

	{
		{"debug_appendonly_use_no_toast", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Use no toast for an append-only table.  Store the large row inline."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_appendonly_use_no_toast,
		false, NULL, NULL
	},

	{
		{"debug_appendonly_print_segfile_choice", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Print log messages for append-only writers about their choice for AO segment file."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_appendonly_print_segfile_choice,
		false, NULL, NULL
	},

	{
		{"test_AppendOnlyHash_eviction_vs_just_marking_not_inuse", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Helps to test evicting the entry for AppendOnlyHash as soon as its usage is done instead of just marking it not inuse."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&test_AppendOnlyHash_eviction_vs_just_marking_not_inuse,
		false, NULL, NULL
	},

	{
		{"debug_appendonly_print_datumstream", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Print log messages for append-only datum stream content."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_appendonly_print_datumstream,
		false, NULL, NULL
	},

	{
		{"debug_gp_relation_node_fetch_wait_for_debugging", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Wait for debugger attach for MPP-16395 RelationFetchGpRelationNodeForXLog issue."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_gp_relation_node_fetch_wait_for_debugging,
		false, NULL, NULL
	},

	{
		{"debug_xlog_insert_print", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Print XLOG Insert record debugging information."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_xlog_insert_print,
		false, NULL, NULL
	},

	{
		{"debug_xlog_record_read", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Print debug information for xlog record read."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&debug_xlog_record_read,
		false, NULL, NULL
	},

	{
		{"debug_persistent_print", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Print persistent file-system object debugging information."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_persistent_print,
		false, NULL, NULL
	},

	{
		{"debug_persistent_recovery_print", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Print persistent recovery debugging information."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_persistent_recovery_print,
		false, NULL, NULL
	},

	{
		{"Disable_persistent_recovery_logging", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("By default important persistent recovery information is logged, setting this GUC allows to disable it if required"),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Disable_persistent_recovery_logging,
		true, NULL, NULL
	},

	{
		{"debug_persistent_store_print", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Print persistent file-system object store debugging information."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_persistent_store_print,
		false, NULL, NULL
	},

	{
		{"debug_persistent_bootstrap_print", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Print persistent store debugging information during bootstrap."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_persistent_bootstrap_print,
		false, NULL, NULL
	},

	{
		{"persistent_integrity_checks", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("When set enables all set of integrity checks for persistent tables."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&persistent_integrity_checks,
		false, NULL, NULL
	},

	{
		{"disable_persistent_diagnostic_dump", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("When set disables printing full PT on erros."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&disable_persistent_diagnostic_dump,
		true, NULL, NULL
	},

	{
		{"debug_persistent_ptcat_verification", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("When set, it enables all set of cross catalog consistency integrity checks for persistent tables in Startup pass 4."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&debug_persistent_ptcat_verification,
		false, NULL, NULL
	},

	{
		{"debug_print_persistent_checks", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("When set enables printing of logs in integrity checks for persistent tables module."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&debug_print_persistent_checks,
		false, NULL, NULL
	},

	{
		{"Debug_bulk_load_bypass_wal", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Use new bulk load bypass WAL logic."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_bulk_load_bypass_wal,
		true, NULL, NULL
	},

	{
		{"debug_persistent_appendonly_commit_count_print", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Print persistent Append-Only resync commit count information."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_persistent_appendonly_commit_count_print,
		true, NULL, NULL
	},

	{
		{"debug_cancel_print", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Print cancel detail information."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_cancel_print,
		false, NULL, NULL
	},

	{
		{"debug_datumstream_write_print_small_varlena_info", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Print datum stream write small varlena information."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_datumstream_write_print_small_varlena_info,
		false, NULL, NULL
	},

	{
		{"debug_datumstream_write_print_large_varlena_info", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Print datum stream write large varlena information."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_datumstream_write_print_large_varlena_info,
		false, NULL, NULL
	},

	{
		{"debug_datumstream_read_check_large_varlena_integrity", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Check datum stream large object integrity."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_datumstream_read_check_large_varlena_integrity,
		false, NULL, NULL
	},

	{
		{"debug_datumstream_block_read_check_integrity", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Check datum stream block read integrity."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_datumstream_block_read_check_integrity,
		false, NULL, NULL
	},

	{
		{"debug_datumstream_block_write_check_integrity", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Check datum stream block write integrity."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_datumstream_block_write_check_integrity,
		false, NULL, NULL
	},

	{
		{"debug_datumstream_read_print_varlena_info", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Print datum stream read varlena information."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_datumstream_read_print_varlena_info,
		false, NULL, NULL
	},

	{
		{"debug_datumstream_write_use_small_initial_buffers", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Use small datum stream write buffers to stress growing logic."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_datumstream_write_use_small_initial_buffers,
		false, NULL, NULL
	},

	{
		{"debug_database_command_print", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Print database command debugging information."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_database_command_print,
		false, NULL, NULL
	},

	{
		{"gp_initdb_mirrored", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Indicate we are initializing a mirrored cluster during initdb."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_initdb_mirrored,
		false, NULL, NULL
	},

	{
		{"gp_before_persistence_work", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Indicate we are initializing / upgrading and do not want to do persistence work yet."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_before_persistence_work,
		false, NULL, NULL
	},

	{
		{"gp_before_filespace_setup", PGC_POSTMASTER, DEVELOPER_OPTIONS,
			gettext_noop("Indicates that the gp_persistent_filespace_node table is not setup and should not be used for lookups."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_before_filespace_setup,
		false, NULL, NULL
	},

	{
		{"gp_startup_integrity_checks", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Perform integrity checks after performing startup but before allowing connections in."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_startup_integrity_checks,
		true, NULL, NULL
	},

	{
		{"debug_print_xlog_relation_change_info", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Print relation change information"),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_print_xlog_relation_change_info,
		false, NULL, NULL
	},

	{
		{"debug_print_xlog_relation_change_info_skip_issues_only", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Print relation change information only when there is a skip issue"),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_print_xlog_relation_change_info_skip_issues_only,
		false, NULL, NULL
	},

	{
		{"debug_print_xlog_relation_change_info_backtrace_skip_issues", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Print relation change information backtrace when there is a skip issue"),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_print_xlog_relation_change_info_backtrace_skip_issues,
		false, NULL, NULL
	},

	{
		{"test_appendonly_override", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("For testing purposes, change the default of the appendonly create table option."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Test_appendonly_override,
		false, NULL, NULL
	},

	{
		{"test_print_direct_dispatch_info", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("For testing purposes, print information about direct dispatch decisions."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Test_print_direct_dispatch_info,
		false, NULL, NULL
	},

	{
		{"debug_bitmap_print_insert", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Print log messages for bitmap index insert routines (caution-- generate a lot of logs!)"),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_bitmap_print_insert,
		false, NULL, NULL
	},

	{
		{"gp_test_orientation_override", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("For testing purposes, change the default of the orientation to column."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_GPDB_ADDOPT
		},
		&gp_test_orientation_override,
		false, NULL, NULL
	},

	{
		{"gp_permit_persistent_metadata_update", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Permit updates to persistent metadata tables."),
			gettext_noop("For system repair by experts."),
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_GPDB_ADDOPT
		},
		&gp_permit_persistent_metadata_update,
		false, NULL, NULL
	},

	{
		{"gp_permit_relation_node_change", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Permit updates to gp_relation_node tables."),
			gettext_noop("For system repair by experts."),
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_GPDB_ADDOPT
		},
		&gp_permit_relation_node_change,
		false, NULL, NULL
	},

	{
		{"master_mirroring_administrator_disable", PGC_POSTMASTER, GP_ARRAY_CONFIGURATION,
			gettext_noop("Used by gpstart to indicate the standby master was not started by the administrator."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Master_mirroring_administrator_disable,
		false, NULL, NULL
	},

	{
		{"debug_dtm_action_primary", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Specify if the primary or mirror segment is the target of the debug DTM action."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_dtm_action_primary,
		DEBUG_DTM_ACTION_PRIMARY_DEFAULT, NULL, NULL
	},

	{
		{"gp_disable_tuple_hints", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Specify if reader should set hint bits on tuples."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_GPDB_ADDOPT
		},
		&gp_disable_tuple_hints,
		true, NULL, NULL
	},
	{
		{"debug_print_server_processes", PGC_SUSET, LOGGING_WHAT,
			gettext_noop("Prints server process management to server log."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_print_server_processes,
		false, NULL, NULL
	},

	{
		{"debug_print_control_checkpoints", PGC_SUSET, LOGGING_WHAT,
			gettext_noop("Prints pg_control file checkpoint changes to server log."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_print_control_checkpoints,
		false, NULL, NULL
	},

	{
		{"gp_local_distributed_cache_stats", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Prints local-distributed cache statistics at end of commit / prepare."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_local_distributed_cache_stats,
		false, NULL, NULL
	},

	{
		{"enable_partition_rules", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Enable creation of RULEs to implement partitioning"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&enable_partition_rules,
		false, NULL, NULL
	},

	{
		{"gp_enable_gpperfmon", PGC_POSTMASTER, UNGROUPED,
			gettext_noop("Enable gpperfmon monitoring."),
			NULL,
		},
		&gp_enable_gpperfmon,
		false, gpvars_assign_gp_enable_gpperfmon, NULL
	},

	{
		{"gp_enable_alter_table_inherit_cols", PGC_USERSET, UNGROUPED,
			gettext_noop("Enable extended 'ALTER TABLE child INHERIT parent' syntax."),
			gettext_noop("The extended syntax adds an optional '( column_list )' identifying columns "
						 "to be marked as fully-inherited from parent."),
			GUC_NO_SHOW_ALL | GUC_NO_RESET_ALL | GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE
		},
		&gp_enable_alter_table_inherit_cols,
		false, NULL, NULL
	},

	{
		{"gp_mapreduce_define", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Prepare mapreduce object creation"),	/* turn off statement
																 * logging */
			NULL,
			GUC_NO_SHOW_ALL | GUC_NO_RESET_ALL | GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE | GUC_GPDB_ADDOPT
		},
		&gp_mapreduce_define,
		false, NULL, NULL
	},

	{
		{"coredump_on_memerror", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Generate core dump on memory error."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_GPDB_ADDOPT
		},
		&coredump_on_memerror,
		false, NULL, NULL
	},
	{
		{"log_autostats", PGC_SUSET, LOGGING_WHAT,
			gettext_noop("Logs details of auto-stats issued ANALYZEs."),
			NULL
		},
		&log_autostats,
		true, NULL, NULL
	},
	{
		{"gp_statistics_pullup_from_child_partition", PGC_USERSET, QUERY_TUNING_METHOD,
			gettext_noop("This guc enables the planner to utilize statistics from partitions in planning queries on the parent."),
			NULL
		},
		&gp_statistics_pullup_from_child_partition,
		true, NULL, NULL
	},
	{
		{"gp_statistics_use_fkeys", PGC_USERSET, QUERY_TUNING_METHOD,
			gettext_noop("This guc enables the planner to utilize statistics derived from foreign key relationships."),
			NULL
		},
		&gp_statistics_use_fkeys,
		true, NULL, NULL
	},

	{
		{"gp_eager_hashtable_release", PGC_USERSET, DEPRECATED_OPTIONS,
			gettext_noop("This guc determines if a hash-join eagerly releases its hash table."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_GPDB_ADDOPT
		},
		&gp_eager_hashtable_release,
		true, NULL, NULL
	},
	{
		{"gp_resqueue_priority", PGC_POSTMASTER, RESOURCES_MGM,
			gettext_noop("Enables priority scheduling."),
			NULL
		},
		&gp_enable_resqueue_priority,
		true, NULL, NULL
	},
	{
		{"gp_hash_index", PGC_SUSET, UNGROUPED,
			gettext_noop("Specify whether hash indexes can be used. Deprecated and has no effect."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_hash_index,
		false, gpvars_assign_gp_hash_index, NULL
	},

	{
		{"gp_change_tracking", PGC_SUSET, UNGROUPED,
			gettext_noop("Allows disabling change tracking."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_change_tracking,
		true, NULL, NULL
	},

	{
		{"gp_persistent_repair_global_sequence", PGC_SUSET, UNGROUPED,
			gettext_noop("Repair a global sequence number to use the maximum scanned value."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_persistent_repair_global_sequence,
		false, NULL, NULL
	},

	{
		{"gp_validate_pt_info_relcache", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Validate persistent TID and serial number in relcache entry."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_validate_pt_info_relcache,
		false, NULL, NULL
	},

	{
		{"filerep_crc_on", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("enable adler 32 crc in filerep"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_filerep_crc_on,
		false, NULL, NULL
	},
	{
		{"debug_rle_type_compression", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("enable extensive debugging information for rle_type compression"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_rle_type_compression,
		false, NULL, NULL
	},

	{
		{"rle_type_compression_stats", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("show compression ratio stats for rle_type compression"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&rle_type_compression_stats,
		false, NULL, NULL
	},

	{
		{"debug_filerep_print", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("enable filerep logs"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_filerep_print,
		false, NULL, NULL
	},

	{
		{"log_filerep_to_syslogger", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("log all filerep related log messages to the server log files"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&log_filerep_to_syslogger,
		true, NULL, NULL
	},

	{
		{"debug_filerep_gcov", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("workaround for filerep gcov issue"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_filerep_gcov,
		false, NULL, NULL
	},

	{
		{"debug_filerep_config_print", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("enable filerep config logs"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_filerep_config_print,
		true, NULL, NULL
	},

	{
		{"debug_filerep_verify_performance_print", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("enable filerep verify performance tracing"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_filerep_verify_performance_print,
		false, NULL, NULL
	},

	{
		{"debug_filerep_memory_log_flush", PGC_SIGHUP, DEVELOPER_OPTIONS,
			gettext_noop("enable filerep config logs"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_filerep_memory_log_flush,
		false, NULL, NULL
	},

	{
		{"filerep_mirrorvalidation_during_resync", PGC_POSTMASTER, DEVELOPER_OPTIONS,
			gettext_noop("Setting enables checking for file existence for all relations on mirror during incremental resynchronization"),
			NULL,
			GUC_NO_SHOW_ALL
		},
		&filerep_mirrorvalidation_during_resync,
		false, NULL, NULL
	},

	{
		{"debug_walrepl_snd", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Print debug messages for WAL sender in WAL based replication (Master Mirroring)."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&debug_walrepl_snd,
		false, NULL, NULL
	},

	{
		{"debug_walrepl_syncrep", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Print debug messages for synchronous behavior in WAL based replication (Master Mirroring)."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&debug_walrepl_syncrep,
		false, NULL, NULL
	},

	{
		{"debug_walrepl_rcv", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Print debug messages for WAL receiver in WAL based replication (Master Mirroring)."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&debug_walrepl_rcv,
		false, NULL, NULL
	},

	{
		{"debug_basebackup", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Print debug messages for basebackup mechanism (Master Mirroring)."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&debug_basebackup,
		false, NULL, NULL
	},

	{
		{"debug_latch", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Print debug messages for latch mechanism."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&debug_latch,
		false, NULL, NULL
	},

	{
		{"gp_crash_recovery_suppress_ao_eof", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Warning about crash recovery append only eof issue"),
			NULL,
			GUC_NOT_IN_SAMPLE | GUC_NO_SHOW_ALL
		},
		&gp_crash_recovery_suppress_ao_eof,
		false, NULL, NULL
	},

	{
		{"gp_encoding_check_locale_compatibility", PGC_POSTMASTER, CLIENT_CONN_LOCALE,
			gettext_noop("Enable check for compatibility of encoding and locale in createdb"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_encoding_check_locale_compatibility,
		true, NULL, NULL
	},

	{
		{"gp_temporary_files_filespace_repair", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Change the filespace inconsistency to a warning"),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_temporary_files_filespace_repair,
		false, NULL, NULL
	},

	/* for pljava */
	{
		{"pljava_release_lingering_savepoints", PGC_SUSET, CUSTOM_OPTIONS,
			gettext_noop("If true, lingering savepoints will be released on function exit; if false, they will be rolled back"),
			NULL,
			GUC_GPDB_ADDOPT | GUC_NOT_IN_SAMPLE | GUC_SUPERUSER_ONLY
		},
		&pljava_release_lingering_savepoints,
		false, NULL, NULL
	},
	{
		{"pljava_debug", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Stop the backend to attach a debugger"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_SUPERUSER_ONLY
		},
		&pljava_debug,
		false, NULL, NULL
	},

	/* for SimEx */
	{
		{"gp_simex_init", PGC_POSTMASTER, GP_ERROR_HANDLING,
			gettext_noop("Initialize exception simulation - used to set up simulation at startup"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_simex_init,
		false, NULL, NULL
	},

	{
		{"gp_simex_run", PGC_USERSET, GP_ERROR_HANDLING,
			gettext_noop("Run exception simulation - used to control starting/stopping simulation at runtime"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_GPDB_ADDOPT
		},
		&gp_simex_run,
		false, NULL, NULL
	},

	{
		{"gp_keep_all_xlog", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Do not remove old xlog files."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_keep_all_xlog,
		false, NULL, NULL
	},

	{
		{"gp_test_time_slice", PGC_USERSET, GP_ERROR_HANDLING,
			gettext_noop("Check for time slice violation between checks for interrupts"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_GPDB_ADDOPT
		},
		&gp_test_time_slice,
		false, NULL, NULL
	},

	{
		{"gp_test_deadlock_hazard", PGC_USERSET, GP_ERROR_HANDLING,
			gettext_noop("Check if a lightweight lock is already held when requesting a database lock"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_GPDB_ADDOPT
		},
		&gp_test_deadlock_hazard,
		false, NULL, NULL
	},

	{
		{"gp_cancel_query_print_log", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Print out debugging info for a canceled query"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_GPDB_ADDOPT
		},
		&gp_cancel_query_print_log,
		false, NULL, NULL
	},

	{
		{"gp_partitioning_dynamic_selection_log", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Print out debugging info for GPDB dynamic partition selection"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_GPDB_ADDOPT
		},
		&gp_partitioning_dynamic_selection_log,
		false, NULL, NULL
	},

	{
		{"gp_perfmon_print_packet_info", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Print out debugging info for a Perfmon packet"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_GPDB_ADDOPT
		},
		&gp_perfmon_print_packet_info,
		false, NULL, NULL
	},

	{
		{"gp_log_stack_trace_lines", PGC_USERSET, LOGGING_WHAT,
			gettext_noop("Control if file/line information is included in stack traces"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_GPDB_ADDOPT
		},
		&gp_log_stack_trace_lines,
		true, NULL, NULL
	},

	{

		{"gp_log_resqueue_memory", PGC_USERSET, LOGGING_WHAT,
			gettext_noop("Prints out messages related to resource queue's memory management."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_GPDB_ADDOPT
		},
		&gp_log_resqueue_memory,
		false, NULL, NULL
	},

	{
		{"gp_resqueue_print_operator_memory_limits", PGC_USERSET, LOGGING_WHAT,
			gettext_noop("Prints out the memory limit for operators (in explain) assigned by resource queue's "
						 "memory management."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_GPDB_ADDOPT
		},
		&gp_resqueue_print_operator_memory_limits,
		false, NULL, NULL
	},

	{
		{"gp_dynamic_partition_pruning", PGC_USERSET, QUERY_TUNING_METHOD,
			gettext_noop("This guc enables plans that can dynamically eliminate scanning of partitions."),
			NULL
		},
		&gp_dynamic_partition_pruning,
		true, NULL, NULL
	},

	{
		{"gp_cte_sharing", PGC_USERSET, QUERY_TUNING_METHOD,
			gettext_noop("This guc enables sharing of plan fragments for common table expressions."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_cte_sharing,
		false, NULL, NULL
	},

	{
		{"gp_enable_relsize_collection", PGC_USERSET, QUERY_TUNING_METHOD,
			gettext_noop("This guc enables relsize collection when stats are not present. If disabled and stats are not present a default "
					     "value is used."),
			NULL
		},
		&gp_enable_relsize_collection,
		false, NULL, NULL
	},

	{
		{"gp_log_dynamic_partition_pruning", PGC_USERSET, LOGGING_WHAT,
			gettext_noop("This guc enables debug messages related to dynamic partition pruning."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_log_dynamic_partition_pruning,
		false, NULL, NULL
	},

	{
		{"gp_ignore_window_exclude", PGC_USERSET, COMPAT_OPTIONS_PREVIOUS,
			gettext_noop("Ignore EXCLUDE in window frame specifications."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_ignore_window_exclude,
		false, NULL, NULL
	},

	{
		{"gp_create_table_random_default_distribution", PGC_USERSET, COMPAT_OPTIONS,
			gettext_noop("Set the default distribution of a table to RANDOM."),
			NULL,
			GUC_NOT_IN_SAMPLE
		},
		&gp_create_table_random_default_distribution,
		false, NULL, NULL
	},

	{
		{"gp_allow_non_uniform_partitioning_ddl", PGC_USERSET, COMPAT_OPTIONS,
			gettext_noop("Allow DDL that will create multi-level partition table with non-uniform hierarchy."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_allow_non_uniform_partitioning_ddl,
		true, NULL, NULL
	},

	{
		{"gp_enable_exchange_default_partition", PGC_USERSET, COMPAT_OPTIONS,
			gettext_noop("Allow DDL that will exchange default partitions."),
			NULL
		},
		&gp_enable_exchange_default_partition,
		false, NULL, NULL
	},

	{
		{"optimizer", PGC_USERSET, QUERY_TUNING_METHOD,
			gettext_noop("Enable the new optimizer."),
			NULL
		},
		&optimizer,
		false, assign_optimizer, NULL
	},

	{
		{"optimizer_log", PGC_USERSET, LOGGING_WHAT,
			gettext_noop("Log optimizer messages."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_log,
		true, NULL, NULL
	},

	{
		{"optimizer_partition_selection_log", PGC_USERSET, LOGGING_WHAT,
			gettext_noop("Log optimizer partition selection."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_GPDB_ADDOPT
		},
		&optimizer_partition_selection_log,
		false, NULL, NULL
	},

	{
		{"optimizer_print_query", PGC_USERSET, LOGGING_WHAT,
			gettext_noop("Prints the optimizer's input query expression tree."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_print_query,
		false, NULL, NULL
	},

	{
		{"optimizer_print_plan", PGC_USERSET, LOGGING_WHAT,
			gettext_noop("Prints the plan expression tree produced by the optimizer."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_print_plan,
		false, NULL, NULL
	},

	{
		{"optimizer_print_xform", PGC_USERSET, LOGGING_WHAT,
			gettext_noop("Prints optimizer transformation information."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_print_xform,
		false, NULL, NULL
	},

	{
		{"optimizer_metadata_caching", PGC_USERSET, QUERY_TUNING_METHOD,
			gettext_noop("This guc enables the optimizer to cache and reuse metadata."),
			NULL
		},
		&optimizer_metadata_caching,
		true, NULL, NULL
	},

	{
		{"optimizer_disable_missing_stats_collection", PGC_USERSET, LOGGING_WHAT,
			gettext_noop("Disable collecting of columns with missing statistics."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_disable_missing_stats_collection,
		false, NULL, NULL
	},

	{
		{"optimizer_disable_xform_result_printing", PGC_USERSET, LOGGING_WHAT,
			gettext_noop("Disable printing the input and output of optimizer transformations."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_disable_xform_result_printing,
		false, NULL, NULL
	},

	{
		{"optimizer_print_memo_after_exploration", PGC_USERSET, LOGGING_WHAT,
			gettext_noop("Print optimizer memo structure after the exploration phase."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_print_memo_after_exploration,
		false, NULL, NULL
	},

	{
		{"optimizer_print_memo_after_implementation", PGC_USERSET, LOGGING_WHAT,
			gettext_noop("Print optimizer memo structure after the implementation phase."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_print_memo_after_implementation,
		false, NULL, NULL
	},

	{
		{"optimizer_print_memo_after_optimization", PGC_USERSET, LOGGING_WHAT,
			gettext_noop("Print optimizer memo structure after optimization."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_print_memo_after_optimization,
		false, NULL, NULL
	},

	{
		{"optimizer_print_job_scheduler", PGC_USERSET, LOGGING_WHAT,
			gettext_noop("Print the jobs in the scheduler on each job completion."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_print_job_scheduler,
		false, NULL, NULL
	},

	{
		{"optimizer_print_expression_properties", PGC_USERSET, LOGGING_WHAT,
			gettext_noop("Print expression properties."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_print_expression_properties,
		false, NULL, NULL
	},

	{
		{"optimizer_print_group_properties", PGC_USERSET, LOGGING_WHAT,
			gettext_noop("Print group properties."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_print_group_properties,
		false, NULL, NULL
	},

	{
		{"optimizer_print_optimization_context", PGC_USERSET, LOGGING_WHAT,
			gettext_noop("Print the optimization context."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_print_optimization_context,
		false, NULL, NULL
	},
	{
		{"gp_reject_internal_tcp_connection", PGC_POSTMASTER,
			DEVELOPER_OPTIONS,
			gettext_noop("Permit internal TCP connections to the master."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_reject_internal_tcp_conn,
		true, NULL, NULL
	},

	{
		{"optimizer_print_optimization_stats", PGC_USERSET, LOGGING_WHAT,
			gettext_noop("Print optimization stats."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_print_optimization_stats,
		false, NULL, NULL
	},

	{
		{"optimizer_extract_dxl_stats", PGC_USERSET, LOGGING_WHAT,
			gettext_noop("Extract plan stats in dxl."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_extract_dxl_stats,
		false, NULL, NULL
	},
	{
		{"optimizer_extract_dxl_stats_all_nodes", PGC_USERSET, LOGGING_WHAT,
			gettext_noop("Extract plan stats for all physical dxl nodes."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_extract_dxl_stats_all_nodes,
		false, NULL, NULL
	},
	{
		{"optimizer_dpe_stats", PGC_USERSET, LOGGING_WHAT,
			gettext_noop("Enable statistics derivation for partitioned tables with dynamic partition elimination."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_dpe_stats,
		false, NULL, NULL
	},
	{
		{"optimizer_enable_indexjoin", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Enable index nested loops join plans in the optimizer."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_enable_indexjoin,
		true, NULL, NULL
	},
	{
		{"optimizer_enable_motions_masteronly_queries", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Enable plans with Motion operators in the optimizer for queries with no distributed tables."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_enable_motions_masteronly_queries,
		false, NULL, NULL
	},
	{
		{"optimizer_enable_motions", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Enable plans with Motion operators in the optimizer."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_enable_motions,
		true, NULL, NULL
	},
	{
		{"optimizer_enable_motion_broadcast", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Enable plans with Motion Broadcast operators in the optimizer."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_enable_motion_broadcast,
		true, NULL, NULL
	},
	{
		{"optimizer_enable_motion_gather", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Enable plans with Motion Gather operators in the optimizer."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_enable_motion_gather,
		true, NULL, NULL
	},
	{
		{"optimizer_enable_motion_redistribute", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Enable plans with Motion Redistribute operators in the optimizer."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_enable_motion_redistribute,
		true, NULL, NULL
	},
	{
		{"optimizer_enable_sort", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Enable plans with Sort operators in the optimizer."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_enable_sort,
		true, NULL, NULL
	},
	{
		{"optimizer_enable_materialize", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Enable plans with Materialize operators in the optimizer."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_enable_materialize,
		true, NULL, NULL
	},
	{
		{"optimizer_enable_partition_propagation", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Enable plans with Partition Propagation operators in the optimizer."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_enable_partition_propagation,
		true, NULL, NULL
	},
	{
		{"optimizer_enable_partition_selection", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Enable plans with Partition Selection operators in the optimizer."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_enable_partition_selection,
		true, NULL, NULL
	},
	{
		{"optimizer_enable_outerjoin_rewrite", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Enable outer join to inner join rewrite in the optimizer."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_enable_outerjoin_rewrite,
		true, NULL, NULL
	},
	{
		{"optimizer_direct_dispatch", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Enable direct dispatch in the optimizer."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_direct_dispatch,
		true, NULL, NULL
	},
	{
		{"optimizer_control", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Allow/disallow turning the optimizer on or off."),
			NULL
		},
		&optimizer_control,
		true, NULL, NULL
	},
	{
		{"optimizer_enable_space_pruning", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Enable space pruning in the optimizer."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_enable_space_pruning,
		true, NULL, NULL
	},

	{
		{"optimizer_enable_master_only_queries", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Process master only queries via the optimizer."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_enable_master_only_queries,
		false, NULL, NULL
	},

	{
		{"optimizer_multilevel_partitioning", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Enable optimization of queries on multilevel partitioned tables."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_multilevel_partitioning,
		true, NULL, NULL
	},

	{
		{"optimizer_enable_derive_stats_all_groups", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Enable stats derivation for all groups after exploration."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_enable_derive_stats_all_groups,
		false, NULL, NULL
	},

	{
		{"optimizer_explain_show_status", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Display optimizer version information in explain messages."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_explain_show_status,
		true, NULL, NULL
	},

	{
		{"optimizer_prefer_multistage_agg", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Prefer multistage aggregates in the optimizer."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_prefer_multistage_agg,
		true, NULL, NULL
	},

	{
		{"optimizer_enable_multiple_distinct_aggs", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Enable plans with multiple distinct aggregates in the optimizer."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_enable_multiple_distinct_aggs,
		false, NULL, NULL
	},

	{
		{"optimizer_prefer_expanded_distinct_aggs", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Prefer plans that expand multiple distinct aggregates into join of single distinct aggregate in the optimizer."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_prefer_expanded_distinct_aggs,
		true, NULL, NULL
	},

	{
		{"optimizer_prune_computed_columns", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Prune unused computed columns when pre-processing query"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_prune_computed_columns,
		true, NULL, NULL
	},

	{
		{"optimizer_push_requirements_from_consumer_to_producer", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Optimize CTE producer plan on requirements enforced on top of CTE consumer in the optimizer."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_push_requirements_from_consumer_to_producer,
		true, NULL, NULL
	},

	{
		{"optimizer_enable_hashjoin_redistribute_broadcast_children", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Enable hash join plans with, Redistribute outer child and Broadcast inner child, in the optimizer."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_enable_hashjoin_redistribute_broadcast_children,
		false, NULL, NULL
	},
	{
		{"optimizer_enable_broadcast_nestloop_outer_child", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Enable nested loops join plans with replicated outer child in the optimizer."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_enable_broadcast_nestloop_outer_child,
		true, NULL, NULL
	},
	{
		{"optimizer_enforce_subplans", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Enforce correlated execution in the optimizer"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_enforce_subplans,
		false, NULL, NULL
	},
	{
		{"optimizer_enable_assert_maxonerow", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Enable Assert MaxOneRow plans to check number of rows at runtime."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_enable_assert_maxonerow,
		true, NULL, NULL
	},
	{
		{"optimizer_enumerate_plans", PGC_USERSET, LOGGING_WHAT,
			gettext_noop("Enable plan enumeration"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_enumerate_plans,
		false, NULL, NULL
	},

	{
		{"optimizer_sample_plans", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Enable plan sampling"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_sample_plans,
		false, NULL, NULL
	},

	{
		{"optimizer_cte_inlining", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Enable CTE inlining"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_cte_inlining,
		false, NULL, NULL
	},

	{
		{"optimizer_analyze_root_partition", PGC_USERSET, STATS_ANALYZE,
			gettext_noop("Enable statistics collection on root partitions during ANALYZE"),
			NULL
		},
		&optimizer_analyze_root_partition,
		false, NULL, NULL
	},

	{
		{"optimizer_analyze_midlevel_partition", PGC_USERSET, STATS_ANALYZE,
			gettext_noop("Enable statistics collection on intermediate partitions during ANALYZE"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_analyze_midlevel_partition,
		false, NULL, NULL
	},

	{
		{"optimizer_enable_constant_expression_evaluation", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Enable constant expression evaluation in the optimizer"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_enable_constant_expression_evaluation,
		true, NULL, NULL
	},

	{
		{"optimizer_use_external_constant_expression_evaluation_for_ints", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Use external constant expression evaluation in the optimizer for all integer types"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_use_external_constant_expression_evaluation_for_ints,
		false, NULL, NULL
	},

	{
		{"optimizer_enable_bitmapscan", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Enable bitmap plans in the optimizer"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_enable_bitmapscan,
		true, NULL, NULL
	},

	{
		{"optimizer_enable_outerjoin_to_unionall_rewrite", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Enable rewriting Left Outer Join to UnionAll"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_enable_outerjoin_to_unionall_rewrite,
		false, NULL, NULL
	},

	{
		{"optimizer_apply_left_outer_to_union_all_disregarding_stats", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Always apply Left Outer Join to Inner Join UnionAll Left Anti Semi Join without looking at stats."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_apply_left_outer_to_union_all_disregarding_stats,
		false, NULL, NULL
	},

	{
		{"optimizer_enable_ctas", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Enable CTAS plans in the optimizer"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_enable_ctas,
		true, NULL, NULL
	},

	{
		{"optimizer_remove_order_below_dml", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Remove OrderBy below a DML operation"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_remove_order_below_dml,
		false, NULL, NULL
	},

	{
		{"optimizer_static_partition_selection", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Enable static partition selection"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_static_partition_selection,
		true, NULL, NULL
	},

	{
		{"optimizer_enable_partial_index", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Enable heterogeneous index plans."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_enable_partial_index,
		true, NULL, NULL
	},

	{
		{"optimizer_dml_triggers", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Support DML with triggers."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_dml_triggers,
		false, NULL, NULL
	},

	{
		{"optimizer_dml_constraints", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Support DML with CHECK constraints and NOT NULL constraints."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_dml_constraints,
		true, NULL, NULL
	},

	{
		{"gp_log_optimization_time", PGC_USERSET, LOGGING_WHAT,
			gettext_noop("Writes time spent producing a plan to the server log"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_log_optimization_time,
		false, NULL, NULL
	},

	{
		{"gp_reject_internal_tcp_connection", PGC_POSTMASTER,
			DEVELOPER_OPTIONS,
			gettext_noop("Permit internal TCP connections to the master."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_reject_internal_tcp_conn,
		true, NULL, NULL
	},

	{
		{"fts_diskio_check", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Controls if FTS should perform disk IO checks on primary segments as part of probe"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&fts_diskio_check,
		true, NULL, NULL
	},

	{
		{"dml_ignore_target_partition_check", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Ignores checking whether the user provided correct partition during a direct insert to a leaf partition"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_GPDB_ADDOPT
		},
		&dml_ignore_target_partition_check,
		false, NULL, NULL
	},

	{
		{"optimizer_prefer_scalar_dqa_multistage_agg", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Prefer multistage aggregates for scalar distinct qualified aggregate in the optimizer."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_prefer_scalar_dqa_multistage_agg,
		true, NULL, NULL
	},

	{
		{"optimizer_parallel_union", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Enable parallel execution for UNION/UNION ALL queries."),
			NULL,
			GUC_NOT_IN_SAMPLE
		},
		&optimizer_parallel_union,
		false, NULL, NULL
	},

	{
		{"optimizer_array_constraints", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Allows the optimizer's constraint framework to derive array constraints."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_array_constraints,
		false, NULL, NULL
	},

	{
		{"init_codegen", PGC_POSTMASTER, DEVELOPER_OPTIONS,
			gettext_noop("Enable just-in-time code generation."),
			NULL,
			GUC_NOT_IN_SAMPLE
		},
		&init_codegen,
#ifdef USE_CODEGEN
		true,
#else
		false,
#endif
		assign_codegen, NULL
	},

	{
		{"codegen", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Perform just-in-time code generation."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_GPDB_ADDOPT
		},
		&codegen,
		false,
		assign_codegen, NULL
	},

	{
		{"codegen_validate_functions", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Perform verify for generated functions to catch any error before compiling"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&codegen_validate_functions,
#if defined(USE_ASSERT_CHECKING) && defined(USE_CODEGEN)
		true, 	/* true by default on debug builds. */
#else
		false,
#endif
		assign_codegen, NULL
	},
	{
		{"codegen_exec_variable_list", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Enable codegen for ExecVariableList"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_GPDB_ADDOPT
		},
		&codegen_exec_variable_list,
#ifdef USE_CODEGEN
		true,
#else
		false,
#endif
		assign_codegen, NULL
	},
	{
		{"codegen_slot_getattr", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Enable codegen for slot_get_attr"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_GPDB_ADDOPT
		},
		&codegen_slot_getattr,
#ifdef USE_CODEGEN
		true,
#else
		false,
#endif
		assign_codegen, NULL
	},
	{
		{"codegen_exec_eval_expr", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Enable codegen for ExecEvalExpr"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_GPDB_ADDOPT
		},
		&codegen_exec_eval_expr,
#ifdef USE_CODEGEN
		true,
#else
		false,
#endif
		assign_codegen, NULL
	},
	{
		{"codegen_advance_aggregate", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Enable codegen for AdvanceAggregate"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_GPDB_ADDOPT
		},
		&codegen_advance_aggregate,
#ifdef USE_CODEGEN
		true,
#else
		false,
#endif
		assign_codegen, NULL
	},

	{
		{"vmem_process_interrupt", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Checks for interrupts before reserving VMEM"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_GPDB_ADDOPT
		},
		&vmem_process_interrupt,
		false, NULL, NULL
	},

	/* End-of-list marker */
	{
		{NULL, 0, 0, NULL, NULL}, NULL, false, NULL, NULL
	}
};

struct config_int ConfigureNamesInt_gp[] =
{
	/* maximum read/write I/O size for DD Boost is 1MB */
	{
		{"ddboost_buf_size", PGC_SIGHUP, DEVELOPER_OPTIONS,
			gettext_noop("size of ddboost dump/restore buffer"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&ddboost_buf_size,
		524288, 65536, 1048576, NULL, NULL
	},

	{
		{"readable_external_table_timeout", PGC_USERSET, EXTERNAL_TABLES,
			gettext_noop("Cancel the query if no data read within N seconds."),
			gettext_noop("A value of 0 turns off the timeout."),
			GUC_UNIT_S | GUC_NOT_IN_SAMPLE
		},
		&readable_external_table_timeout,
		0, 0, INT_MAX, NULL, NULL
	},

	{
		{"writable_external_table_bufsize", PGC_USERSET, EXTERNAL_TABLES,
			gettext_noop("Buffer size in kilo bytes for writable external table before writing data to gpfdist."),
			gettext_noop("Valid value is between 32K and 128M: [32, 131072]."),
			GUC_UNIT_KB | GUC_NOT_IN_SAMPLE
		},
		&writable_external_table_bufsize,
		64, 32, 131072, NULL, NULL
	},

	{
		{"gp_cancel_query_delay_time", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("The time in milliseconds to delay a query cancellation."),
			NULL,
			GUC_UNIT_MS | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_GPDB_ADDOPT
		},
		&gp_cancel_query_delay_time,
		0, 0, INT_MAX, NULL, NULL
	},

	{
		{"gp_max_local_distributed_cache", PGC_POSTMASTER, RESOURCES_MEM,
			gettext_noop("Sets the number of local-distributed transactions to cache for optimizing visibility processing by backends."),
			NULL
		},
		&gp_max_local_distributed_cache,
		1024, 0, INT_MAX, NULL, NULL
	},

	{
		{"gp_max_databases", PGC_POSTMASTER, RESOURCES_MEM,
			gettext_noop("Sets the maximum number of databases."),
			NULL
		},
		&gp_max_databases,
		GP_MAX_DATABASES_DEFAULT, 8, 256, NULL, NULL
	},

	{
		{"gp_max_tablespaces", PGC_POSTMASTER, RESOURCES_MEM,
			gettext_noop("Sets the maximum number of tablespaces."),
			NULL
		},
		&gp_max_tablespaces,
		GP_MAX_TABLESPACES_DEFAULT, 8, 2048, NULL, NULL
	},

	{
		{"gp_max_filespaces", PGC_POSTMASTER, RESOURCES_MEM,
			gettext_noop("Sets the maximum number of filespaces."),
			NULL
		},
		&gp_max_filespaces,
		GP_MAX_FILESPACES_DEFAULT, 8, 256, NULL, NULL
	},

	{
		{"debug_dtm_action_delay_ms", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Sets the debug DTM action delay in milliseconds."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_UNIT_MS
		},
		&Debug_dtm_action_delay_ms,
		DEBUG_DTM_ACTION_DELAY_MS_DEFAULT, 0, INT_MAX / 1000, NULL, NULL
	},

	{
		{"debug_dtm_action_segment", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Sets the debug DTM action segment."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_dtm_action_segment,
		DEBUG_DTM_ACTION_SEGMENT_DEFAULT, 0, 1000, NULL, NULL
	},

	{
		{"debug_dtm_action_nestinglevel", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Sets the debug DTM action transaction nesting level."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_dtm_action_nestinglevel,
		DEBUG_DTM_ACTION_NESTINGLEVEL_DEFAULT, 0, 1000, NULL, NULL
	},

	{
		{"test_compresslevel_override", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("For testing purposes, the override value for compresslevel when non-default."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Test_compresslevel_override,
		DEFAULT_COMPRESS_LEVEL, 0, 9, NULL, NULL
	},

	{
		{"test_blocksize_override", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("For testing purposes, the override value for append only blocksize when non-default."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Test_blocksize_override,
		DEFAULT_APPENDONLY_BLOCK_SIZE, MIN_APPENDONLY_BLOCK_SIZE, MAX_APPENDONLY_BLOCK_SIZE, NULL, NULL
	},

	{
		{"test_safefswritesize_override", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("For testing purposes, the override value for append only safefswritesize when non-default."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_GPDB_ADDOPT
		},
		&Test_safefswritesize_override,
		DEFAULT_FS_SAFE_WRITE_SIZE, 0, INT_MAX, NULL, NULL
	},

	{
		{"gp_safefswritesize", PGC_BACKEND, RESOURCES,
			gettext_noop("Minimum FS safe write size."),
			NULL
		},
		&gp_safefswritesize,
		DEFAULT_FS_SAFE_WRITE_SIZE, 0, INT_MAX, NULL, NULL
	},

	{
		{"planner_work_mem", PGC_USERSET, RESOURCES_MEM,
			gettext_noop("Sets the maximum memory to be used for query workspaces, "
						 "used in the planner only."),
			gettext_noop("The planner considers this much memory may be used by each internal "
						 "sort operation and hash table before switching to "
						 "temporary disk files."),
			GUC_UNIT_KB | GUC_GPDB_ADDOPT | GUC_NOT_IN_SAMPLE | GUC_NO_SHOW_ALL
		},
		&planner_work_mem,
		32768, 2 * BLCKSZ / 1024, MAX_KILOBYTES, NULL, NULL
	},

	{
		{"max_work_mem", PGC_SUSET, DEPRECATED_OPTIONS,
			gettext_noop("Sets the maximum value for work_mem setting."),
			NULL,
			GUC_UNIT_KB | GUC_GPDB_ADDOPT
		},
		&max_work_mem,
		1024000, 8 * BLCKSZ / 1024, MAX_KILOBYTES, NULL, NULL
	},

	{
		{"statement_mem", PGC_USERSET, RESOURCES_MEM,
			gettext_noop("Sets the memory to be reserved for a statement."),
			NULL,
			GUC_UNIT_KB | GUC_GPDB_ADDOPT
		},
		&statement_mem,
#ifdef USE_ASSERT_CHECKING
		/** Allow lower values for testing */
		128000, 50, INT_MAX, gpvars_assign_statement_mem, NULL
#else
		128000, 1000, INT_MAX, gpvars_assign_statement_mem, NULL
#endif
	},

	{
		{"max_statement_mem", PGC_SUSET, RESOURCES_MEM,
			gettext_noop("Sets the maximum value for statement_mem setting."),
			NULL,
			GUC_UNIT_KB | GUC_GPDB_ADDOPT
		},
		&max_statement_mem,
		2048000, 32768, INT_MAX, NULL, NULL
	},

	{
		{"gp_vmem_limit_per_query", PGC_POSTMASTER, RESOURCES_MEM,
			gettext_noop("Sets the maximum allowed memory per-statement on each segment."),
			NULL,
			GUC_UNIT_KB | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_vmem_limit_per_query,
		0, 0, INT_MAX / 2, NULL, NULL
	},

	{
		{"gp_max_plan_size", PGC_SUSET, RESOURCES_MEM,
			gettext_noop("Sets the maximum size of a plan to be dispatched."),
			NULL,
			GUC_UNIT_KB
		},
		&gp_max_plan_size,
		0, 0, MAX_KILOBYTES, NULL, NULL
	},

	{
		{"gp_max_partition_level", PGC_SUSET, PRESET_OPTIONS,
			gettext_noop("Sets the maximum number of levels allowed when creating a partitioned table."),
			gettext_noop("Use 0 for no limit."),
			GUC_GPDB_ADDOPT | GUC_SUPERUSER_ONLY | GUC_NOT_IN_SAMPLE
		},
		&gp_max_partition_level,
		0, 0, INT_MAX, NULL, NULL
	},

	{
		{"gp_appendonly_compaction_threshold", PGC_USERSET, APPENDONLY_TABLES,
			gettext_noop("Threshold of the ratio of dirty data in a segment file over which the file"
						 " will be compacted during lazy vacuum."),
			NULL
		},
		&gp_appendonly_compaction_threshold,
		10, 0, 100, NULL, NULL
	},

	{
		{"gp_workfile_max_entries", PGC_POSTMASTER, RESOURCES,
			gettext_noop("Sets the maximum number of entries that can be stored in the workfile directory"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_workfile_max_entries,
		8192, 32, INT_MAX, NULL, NULL
	},

	{
		{"gp_workfile_limit_files_per_query", PGC_USERSET, RESOURCES,
			gettext_noop("Maximum number of workfiles allowed per query per segment."),
			gettext_noop("0 for no limit. Current query is terminated when limit is exceeded."),
			GUC_GPDB_ADDOPT
		},
		&gp_workfile_limit_files_per_query,
		100000, 0, INT_MAX, NULL, NULL,
	},

	{
		{"gp_vmem_idle_resource_timeout", PGC_USERSET, CLIENT_CONN_OTHER,
			gettext_noop("Sets the time a session can be idle (in milliseconds) before we release gangs on the segment DBs to free resources."),
			gettext_noop("A value of 0 turns off the timeout."),
			GUC_UNIT_MS | GUC_GPDB_ADDOPT
		},
		&IdleSessionGangTimeout,
#ifdef USE_ASSERT_CHECKING
		600000, 0, INT_MAX, NULL, NULL	/* 10 minutes by default on debug
										 * builds. */
#else
		18000, 0, INT_MAX, NULL, NULL
#endif
	},

	{
		{"xid_stop_limit", PGC_POSTMASTER, WAL,
			gettext_noop("Sets the number of XIDs before XID wraparound at which we will no longer allow the system to be started."),
			NULL,
			GUC_NOT_IN_SAMPLE | GUC_NO_SHOW_ALL
		},
		&xid_stop_limit,
		1000000000, 10000000, INT_MAX, NULL, NULL
	},
	{
		{"xid_warn_limit", PGC_POSTMASTER, WAL,
			gettext_noop("Sets the number of XIDs before xid_stop_limit at which we will begin emitting warnings regarding XID wraparound."),
			NULL,
			GUC_NOT_IN_SAMPLE | GUC_NO_SHOW_ALL
		},
		&xid_warn_limit,
		500000000, 10000000, INT_MAX, NULL, NULL
	},
	{
		{"gp_dbid", PGC_POSTMASTER, PRESET_OPTIONS,
			gettext_noop("The dbid used by this server."),
			NULL,
			GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE
		},
		&GpIdentity.dbid,
		UNINITIALIZED_GP_IDENTITY_VALUE, INT_MIN, INT_MAX, NULL, NULL
	},

	{
		{"gp_contentid", PGC_POSTMASTER, PRESET_OPTIONS,
			gettext_noop("The contentid used by this server."),
			NULL,
			GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE
		},
		&GpIdentity.segindex,
		UNINITIALIZED_GP_IDENTITY_VALUE, INT_MIN, INT_MAX, NULL, NULL
	},

	{
		{"gp_num_contents_in_cluster", PGC_POSTMASTER, PRESET_OPTIONS,
			gettext_noop("Sets the number of segments in the cluster."),
			NULL,
			GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE
		},
		&GpIdentity.numsegments,
		UNINITIALIZED_GP_IDENTITY_VALUE, INT_MIN, INT_MAX, NULL, NULL
	},

	{
		{"gp_standby_dbid", PGC_POSTMASTER, PRESET_OPTIONS,
			gettext_noop("Sets DBID of standby master."),
			NULL,
			GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE
		},
		&GpStandbyDbid,
		0, INT_MIN, 32767, NULL, NULL
	},

	{
		{"gp_max_csv_line_length", PGC_USERSET, EXTERNAL_TABLES,
			gettext_noop("Maximum allowed length of a csv input data row in bytes"),
			NULL,
		},
		&gp_max_csv_line_length,
		1 * 1024 * 1024, 32 * 1024, 4 * 1024 * 1024, NULL, NULL
	},

	/*
	 * Solaris doesn't support setting SO_SNDTIMEO, so setting this won't work
	 * on Solaris (MPP-22526)
	 */
	{
		{"gp_connection_send_timeout", PGC_SIGHUP, CLIENT_CONN_OTHER,
			gettext_noop("Timeout for sending data to unresponsive clients (seconds)"),
			gettext_noop("A value of 0 uses the system default."),
		},
		&gp_connection_send_timeout,
		3600, 0, INT_MAX, NULL, NULL
	},

	{
		{"gp_filerep_tcp_keepalives_idle", PGC_USERSET, GP_ARRAY_TUNING,
			gettext_noop("Seconds between issuing TCP keepalives for FileRep connection."),
			gettext_noop("A value of 0 uses the system default."),
			GUC_UNIT_S
		},
		&gp_filerep_tcp_keepalives_idle,
		60, 0, INT_MAX, NULL, NULL
	},

	{
		{"gp_filerep_tcp_keepalives_interval", PGC_USERSET, GP_ARRAY_TUNING,
			gettext_noop("Seconds between TCP keepalive retransmits for FileRep connection."),
			gettext_noop("A value of 0 uses the system default."),
			GUC_UNIT_S
		},
		&gp_filerep_tcp_keepalives_interval,
		30, 0, INT_MAX, NULL, NULL
	},

	{
		{"gp_filerep_tcp_keepalives_count", PGC_USERSET, GP_ARRAY_TUNING,
			gettext_noop("Maximum number of TCP keepalive retransmits for FileRep connection."),
			gettext_noop("This controls the number of consecutive keepalive retransmits that can be "
						 "lost before a connection is considered dead. A value of 0 uses the "
						 "system default."),
		},
		&gp_filerep_tcp_keepalives_count,
		2, 0, INT_MAX, NULL, NULL
	},


	{
		{"max_resource_queues", PGC_POSTMASTER, RESOURCES_MGM,
			gettext_noop("Maximum number of resource queues."),
			NULL
		},
		&MaxResourceQueues,
		9, 0, INT_MAX, NULL, NULL
	},

	{
		{"max_resource_portals_per_transaction", PGC_POSTMASTER, RESOURCES_MGM,
			gettext_noop("Maximum number of resource queues."),
			NULL
		},
		&MaxResourcePortalsPerXact,
		64, 0, INT_MAX, NULL, NULL
	},

	{
		{"max_appendonly_tables", PGC_POSTMASTER, APPENDONLY_TABLES,
			gettext_noop("Maximum number of different (unrelated) append only tables that can participate in writing data concurrently."),
			NULL
		},
		&MaxAppendOnlyTables,
		2048, 0, INT_MAX, NULL, NULL
	},

	{
		{"gp_external_max_segs", PGC_USERSET, EXTERNAL_TABLES,
			gettext_noop("Maximum number of segments that connect to a single gpfdist URL."),
			NULL
		},
		&gp_external_max_segs,
		64, 1, INT_MAX, NULL, NULL
	},

	{
		{"gp_max_packet_size", PGC_BACKEND, GP_ARRAY_TUNING,
			gettext_noop("Sets the max packet size for the Interconnect."),
			NULL,
			GUC_GPDB_ADDOPT
		},
		&Gp_max_packet_size,
		DEFAULT_PACKET_SIZE, MIN_PACKET_SIZE, MAX_PACKET_SIZE, NULL, NULL
	},

	{
		{"gp_interconnect_queue_depth", PGC_USERSET, GP_ARRAY_TUNING,
			gettext_noop("Sets the maximum size of the receive queue for each connection in the UDP interconnect"),
			NULL,
			GUC_GPDB_ADDOPT
		},
		&Gp_interconnect_queue_depth,
		4, 1, 4096, NULL, NULL
	},

	{
		{"gp_interconnect_snd_queue_depth", PGC_USERSET, GP_ARRAY_TUNING,
			gettext_noop("Sets the maximum size of the send queue for each connection in the UDP interconnect"),
			NULL,
			GUC_GPDB_ADDOPT
		},
		&Gp_interconnect_snd_queue_depth,
		2, 1, 4096, NULL, NULL
	},

	{
		{"gp_interconnect_timer_period", PGC_USERSET, GP_ARRAY_TUNING,
			gettext_noop("Sets the timer period (in ms) for UDP interconnect"),
			NULL,
			GUC_UNIT_MS | GUC_GPDB_ADDOPT
		},
		&Gp_interconnect_timer_period,
		5, 1, 100, NULL, NULL
	},

	{
		{"gp_interconnect_timer_checking_period", PGC_USERSET, GP_ARRAY_TUNING,
			gettext_noop("Sets the timer checking period (in ms) for UDP interconnect"),
			NULL,
			GUC_UNIT_MS | GUC_GPDB_ADDOPT
		},
		&Gp_interconnect_timer_checking_period,
		20, 1, 100, NULL, NULL
	},

	{
		{"gp_interconnect_default_rtt", PGC_USERSET, GP_ARRAY_TUNING,
			gettext_noop("Sets the default rtt (in ms) for UDP interconnect"),
			NULL,
			GUC_UNIT_MS | GUC_GPDB_ADDOPT
		},
		&Gp_interconnect_default_rtt,
		20, 1, 1000, NULL, NULL
	},

	{
		{"gp_interconnect_min_rto", PGC_USERSET, GP_ARRAY_TUNING,
			gettext_noop("Sets the min rto (in ms) for UDP interconnect"),
			NULL,
			GUC_UNIT_MS | GUC_GPDB_ADDOPT
		},
		&Gp_interconnect_min_rto,
		20, 1, 1000, NULL, NULL
	},

	{
		{"gp_interconnect_transmit_timeout", PGC_USERSET, GP_ARRAY_TUNING,
			gettext_noop("Timeout (in seconds) on interconnect to transmit a packet"),
			gettext_noop("Used by Interconnect to timeout packet transmission."),
			GUC_UNIT_S | GUC_GPDB_ADDOPT
		},
		&Gp_interconnect_transmit_timeout,
		3600, 1, 7200, NULL, NULL
	},

	{
		{"gp_interconnect_min_retries_before_timeout", PGC_USERSET, GP_ARRAY_TUNING,
			gettext_noop("Sets the min retries before reporting a transmit timeout in the interconnect."),
			NULL,
			GUC_GPDB_ADDOPT
		},
		&Gp_interconnect_min_retries_before_timeout,
		100, 1, 4096, NULL, NULL
	},

	{
		{"gp_udp_bufsize_k", PGC_BACKEND, GP_ARRAY_TUNING,
			gettext_noop("Sets recv buf size of UDP interconnect, for testing."),
			NULL,
			GUC_GPDB_ADDOPT
		},
		&Gp_udp_bufsize_k,
		0, 0, 32768, NULL, NULL
	},

#ifdef USE_ASSERT_CHECKING
	{
		{"gp_udpic_dropseg", PGC_USERSET, GP_ARRAY_TUNING,
			gettext_noop("Specifies a segment to which the dropacks, and dropxmit settings will be applied, for testing. (The default is to apply the dropacks and dropxmit settings to all segments)"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_GPDB_ADDOPT
		},
		&gp_udpic_dropseg,
		UNDEF_SEGMENT, UNDEF_SEGMENT, INT_MAX, NULL, NULL
	},

	{
		{"gp_udpic_dropacks_percent", PGC_USERSET, GP_ARRAY_TUNING,
			gettext_noop("Sets the percentage of correctly-received acknowledgment packets to synthetically drop, for testing. (affected by gp_udpic_dropseg)"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_GPDB_ADDOPT
		},
		&gp_udpic_dropacks_percent,
		0, 0, 100, NULL, NULL
	},

	{
		{"gp_udpic_dropxmit_percent", PGC_USERSET, GP_ARRAY_TUNING,
			gettext_noop("Sets the percentage of correctly-received data packets to synthetically drop, for testing. (affected by gp_udpic_dropseg)"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_GPDB_ADDOPT
		},
		&gp_udpic_dropxmit_percent,
		0, 0, 100, NULL, NULL
	},

	{
		{"gp_udpic_fault_inject_percent", PGC_USERSET, GP_ARRAY_TUNING,
			gettext_noop("Sets the percentage of fault injected into system calls, for testing. (affected by gp_udpic_dropseg)"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_GPDB_ADDOPT
		},
		&gp_udpic_fault_inject_percent,
		0, 0, 100, NULL, NULL
	},

	{
		{"gp_udpic_fault_inject_bitmap", PGC_USERSET, GP_ARRAY_TUNING,
			gettext_noop("Sets the bitmap for faults injection, for testing. (affected by gp_udpic_dropseg)"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_GPDB_ADDOPT
		},
		&gp_udpic_fault_inject_bitmap,
		0, 0, INT_MAX, NULL, NULL
	},

	{
		{"gp_udpic_network_disable_ipv6", PGC_USERSET, GP_ARRAY_TUNING,
			gettext_noop("Sets the address info hint to disable the ipv6, for testing. (affected by gp_udpic_dropseg)"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_GPDB_ADDOPT
		},
		&gp_udpic_network_disable_ipv6,
		0, 0, 1, NULL, NULL
	},

#endif
	{
		{"gp_interconnect_hash_multiplier", PGC_SUSET, GP_ARRAY_TUNING,
			gettext_noop("Sets the number of hash buckets used by the UDP interconnect to track connections (the number of buckets is given by the product of the segment count and the hash multipliers)."),
			NULL,
		},
		&Gp_interconnect_hash_multiplier,
		2, 1, 256, NULL, NULL
	},

	{
		{"gp_command_count", PGC_INTERNAL, CLIENT_CONN_OTHER,
			gettext_noop("Shows the number of commands received from the client in this session."),
			NULL,
			GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE
		},
		&gp_command_count,
		0, 0, INT_MAX, NULL, NULL
	},

	{
		{"gp_connections_per_thread", PGC_BACKEND, GP_ARRAY_TUNING,
			gettext_noop("Sets the number of client connections handled in each thread."),
			NULL,
			GUC_GPDB_ADDOPT
		},
		&gp_connections_per_thread,
		0, 0, INT_MAX, assign_gp_connections_per_thread, show_gp_connections_per_thread
	},

	{
		{"gp_subtrans_warn_limit", PGC_POSTMASTER, RESOURCES,
			gettext_noop("Sets the warning limit on number of subtransactions in a transaction."),
			NULL,
			GUC_NOT_IN_SAMPLE
		},
		&gp_subtrans_warn_limit,
		16777216, 0, INT_MAX, NULL, NULL
	},

	{
		{"gp_cached_segworkers_threshold", PGC_USERSET, GP_ARRAY_TUNING,
			gettext_noop("Sets the maximum number of segment workers to cache between statements."),
			NULL,
			GUC_NOT_IN_SAMPLE
		},
		&gp_cached_gang_threshold,
		5, 0, INT_MAX, NULL, NULL
	},


	{
#ifdef USE_ASSERT_CHECKING
		{"gp_debug_linger", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Number of seconds for QD/QE process to linger upon fatal internal error."),
			gettext_noop("Allows an opportunity to debug the backend process before it terminates."),
			GUC_NOT_IN_SAMPLE | GUC_NO_RESET_ALL | GUC_UNIT_S | GUC_GPDB_ADDOPT
		},
		&gp_debug_linger,
		120, 0, 3600, NULL, NULL
#else
		{"gp_debug_linger", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Number of seconds for QD/QE process to linger upon fatal internal error."),
			gettext_noop("Allows an opportunity to debug the backend process before it terminates."),
			GUC_NOT_IN_SAMPLE | GUC_NO_RESET_ALL | GUC_UNIT_S | GUC_GPDB_ADDOPT
		},
		&gp_debug_linger,
		0, 0, 3600, NULL, NULL
#endif
	},

	{
		{"gp_segment", PGC_BACKEND, GP_WORKER_IDENTITY,
			gettext_noop("Segment id of the segment db which is local to this worker process."),
			gettext_noop("-1 for a session's entry process (qDisp) or a worker on the entry db."),
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE
		},
		&Gp_segment,
		-999, INT_MIN, INT_MAX, NULL, NULL
	},

	{
		{"gp_qd_port", PGC_BACKEND, GP_WORKER_IDENTITY,
			gettext_noop("Shows the Master Postmaster port."),
			gettext_noop("0 for a session's entry process (qDisp)"),
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE
		},
		&qdPostmasterPort,
		0, INT_MIN, INT_MAX, NULL, NULL
	},


	{
		{"gp_sort_flags", PGC_USERSET, QUERY_TUNING_OTHER,
			gettext_noop("Experimental feature: Generic sort flags."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_sort_flags,
		10000, 0, INT_MAX, NULL, NULL
	},

	{
		{"gp_sort_max_distinct", PGC_USERSET, QUERY_TUNING_OTHER,
			gettext_noop("Experimental feature: max number of distinct values for sort."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_sort_max_distinct,
		20000, 0, INT_MAX, NULL, NULL
	},

	{
		{"gp_interconnect_setup_timeout", PGC_USERSET, GP_ARRAY_TUNING,
			gettext_noop("Timeout (in seconds) on interconnect setup that occurs at query start"),
			gettext_noop("Used by Interconnect to timeout the setup of the communication fabric."),
			GUC_UNIT_S | GUC_GPDB_ADDOPT
		},
		&interconnect_setup_timeout,
		7200, 0, 7200, NULL, NULL
	},

	{
		{"gp_snapshotadd_timeout", PGC_USERSET, GP_ARRAY_TUNING,
			gettext_noop("Timeout (in seconds) on setup of new connection snapshot"),
			gettext_noop("Used by the transaction manager."),
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_UNIT_S | GUC_GPDB_ADDOPT
		},
		&gp_snapshotadd_timeout,
		10, 0, INT_MAX, NULL, NULL
	},

	{
		{"gp_segment_connect_timeout", PGC_USERSET, GP_ARRAY_TUNING,
			gettext_noop("Maximum time (in seconds) allowed for a new worker process to start or a mirror to respond."),
			gettext_noop("0 indicates 'wait forever'."),
			GUC_UNIT_S
		},
		&gp_segment_connect_timeout,
		180, 0, INT_MAX, NULL, NULL
	},

	{
		{"verify_checkpoint_interval", PGC_POSTMASTER, DEVELOPER_OPTIONS,
			gettext_noop("set the online verification checkpoint interval (seconds)"),
			gettext_noop("0 means do not checkpoint"),
			GUC_UNIT_S | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&verify_checkpoint_interval,
		VERIFY_CHECKPOINT_INTERVAL_DEFAULT, 0, 1800, NULL, NULL
	},

	{
		{"gp_fts_probe_retries", PGC_POSTMASTER, GP_ARRAY_TUNING,
			gettext_noop("Number of retries for FTS to complete probing a segment."),
			gettext_noop("Used by the fts-probe process."),
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_fts_probe_retries,
		5, 0, 100, NULL, NULL
	},

	{
		{"gp_fts_probe_timeout", PGC_USERSET, GP_ARRAY_TUNING,
			gettext_noop("Maximum time (in seconds) allowed for FTS to complete probing a segment."),
			gettext_noop("Used by the fts-probe process."),
			GUC_UNIT_S
		},
		&gp_fts_probe_timeout,
		20, 0, 3600, NULL, NULL
	},

	{
		{"gp_fts_probe_interval", PGC_POSTMASTER, GP_ARRAY_TUNING,
			gettext_noop("A complete probe of all segments starts each time a timer with this period expires."),
			gettext_noop("Used by the fts-probe process. "),
			GUC_UNIT_S
		},
		&gp_fts_probe_interval,
		60, 10, 3600, NULL, NULL
	},

	{
		{"gp_fts_probe_threadcount", PGC_POSTMASTER, GP_ARRAY_TUNING,
			gettext_noop("Use this number of threads for probing the segments."),
			gettext_noop("The number of threads to create at each probe interval expiration."),
			GUC_NOT_IN_SAMPLE
		},
		&gp_fts_probe_threadcount,
		16, 1, 128, NULL, NULL
	},

	{
		{"gp_fts_transition_retries", PGC_POSTMASTER, GP_ARRAY_TUNING,
			gettext_noop("The number of retries for FTS to request a segment state transition."),
			NULL,
			GUC_NOT_IN_SAMPLE | GUC_NO_SHOW_ALL
		},
		&gp_fts_transition_retries,
		5, 1, 100, NULL, NULL
	},

	{
		{"gp_fts_transition_timeout", PGC_POSTMASTER, GP_ARRAY_TUNING,
			gettext_noop("Timeout (in seconds) for FTS to request a segment state transition."),
			NULL,
			GUC_NOT_IN_SAMPLE | GUC_NO_SHOW_ALL | GUC_UNIT_S
		},
		&gp_fts_transition_timeout,
		3600, 1, 36000, NULL, NULL
	},

	{
		{"gp_gang_creation_retry_count", PGC_USERSET, GP_ARRAY_TUNING,
			gettext_noop("After a gang-creation fails, retry the number of times if failure is retryable."),
			gettext_noop("A value of zero disables retries."),
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_gang_creation_retry_count,
		5, 0, 128, NULL, NULL
	},

	{
		{"gp_gang_creation_retry_timer", PGC_USERSET, GP_ARRAY_TUNING,
			gettext_noop("Wait this many milliseconds between gang-creation-retries."),
			NULL,
			GUC_UNIT_MS | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_gang_creation_retry_timer,
		2000, 100, 120000, NULL, NULL
	},

	{
		{"gp_session_id", PGC_BACKEND, CLIENT_CONN_OTHER,
			gettext_noop("Global ID used to uniquely identify a particular session in an Greenplum Database array"),
			NULL,
			GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE
		},
		&gp_session_id,
		-1, INT_MIN, INT_MAX, NULL, NULL
	},

	{
		{"gp_segments_for_planner", PGC_USERSET, QUERY_TUNING_COST,
			gettext_noop("If >0, number of segment dbs for the planner to assume in its cost and size estimates."),
			gettext_noop("If 0, estimates are based on the actual number of segment dbs.")
		},
		&gp_segments_for_planner,
		0, 0, INT_MAX, NULL, NULL
	},

	{
		{"gp_hashjoin_tuples_per_bucket", PGC_USERSET, GP_ARRAY_TUNING,
			gettext_noop("Target density of hashtable used by Hashjoin during execution"),
			gettext_noop("A smaller value will tend to produce larger hashtables, which increases join performance"),
			GUC_NOT_IN_SAMPLE | GUC_GPDB_ADDOPT
		},
		&gp_hashjoin_tuples_per_bucket,
		5, 1, 25, NULL, NULL
	},

	{
		{"gp_hashjoin_metadata_memory_percent", PGC_USERSET, GP_ARRAY_TUNING,
			gettext_noop("Percentage of the operator memory allowed to store hashtable metadata. Set to 0 for unlimited amount of metadata memory."),
			gettext_noop("A small value can cause certain queries to fail, a large or unbounded value can cause the system to run out of memory"),
			GUC_NOT_IN_SAMPLE | GUC_NO_SHOW_ALL | GUC_GPDB_ADDOPT
		},
		&gp_hashjoin_metadata_memory_percent,
		20, 0, INT_MAX, NULL, NULL
	},

	{
		{"gp_hashagg_groups_per_bucket", PGC_USERSET, GP_ARRAY_TUNING,
			gettext_noop("Target density of hashtable used by Hashagg during execution"),
			gettext_noop("A smaller value will tend to produce larger hashtables, which increases agg performance"),
			GUC_NOT_IN_SAMPLE | GUC_NO_SHOW_ALL | GUC_GPDB_ADDOPT
		},
		&gp_hashagg_groups_per_bucket,
		5, 1, 25, NULL, NULL
	},

	{
		{"gp_hashagg_default_nbatches", PGC_USERSET, QUERY_TUNING_METHOD,
			gettext_noop("Default number of batches for hashagg's (re-)spilling phases"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_GPDB_ADDOPT
		},
		&gp_hashagg_default_nbatches,
		32, 4, 1000000, NULL, NULL
	},

	{
		{"gp_hashjoin_bloomfilter", PGC_USERSET, GP_ARRAY_TUNING,
			gettext_noop("Use bloomfilter in hash join"),
			gettext_noop("Use bloomfilter may speed up hashtable probing"),
			GUC_NOT_IN_SAMPLE | GUC_NO_SHOW_ALL | GUC_GPDB_ADDOPT
		},
		&gp_hashjoin_bloomfilter,
		1, 0, 1, NULL, NULL
	},

	{
		{"gp_motion_slice_noop", PGC_USERSET, GP_ARRAY_TUNING,
			gettext_noop("Make motion nodes in certain slices noop"),
			gettext_noop("Make motion nodes noop, to help analyze performace"),
			GUC_NOT_IN_SAMPLE | GUC_NO_SHOW_ALL | GUC_GPDB_ADDOPT
		},
		&gp_motion_slice_noop,
		0, 0, INT_MAX, NULL, NULL
	},

#ifdef ENABLE_LTRACE
	{
		{"gp_ltrace_flag", PGC_USERSET, GP_ARRAY_TUNING,
			gettext_noop("Linux Tracing flag"),
			gettext_noop("Linux Tracing flag"),
			GUC_NOT_IN_SAMPLE | GUC_NO_SHOW_ALL | GUC_GPDB_ADDOPT
		},
		&gp_ltrace_flag,
		0, 0, INT_MAX, NULL, NULL
	},
#endif

	{
		{"gp_reject_percent_threshold", PGC_USERSET, GP_ERROR_HANDLING,
			gettext_noop("Reject limit in percent starts calculating after this number of rows processed"),
			NULL
		},
		&gp_reject_percent_threshold,
		300, 0, INT_MAX, NULL, NULL
	},

	{
		{"gp_gpperfmon_send_interval", PGC_USERSET, LOGGING_WHAT,
			gettext_noop("Interval in seconds between sending messages to gpperfmon."),
			NULL,
			GUC_GPDB_ADDOPT
		},
		&gp_gpperfmon_send_interval,
		1, 1, 3600, gpvars_assign_gp_gpperfmon_send_interval, NULL
	},

	{
		{"wal_send_client_timeout", PGC_SIGHUP, GP_ARRAY_TUNING,
			gettext_noop("The time in milliseconds for a backend process to wait on the WAL Send server to finish a request to the QD mirroring standby."),
			NULL,
			GUC_UNIT_MS | GUC_NOT_IN_SAMPLE | GUC_NO_SHOW_ALL
		},
		&WalSendClientTimeout,
		30000, 100, INT_MAX / 1000, NULL, NULL
	},

	{
		{"gpperfmon_port", PGC_POSTMASTER, UNGROUPED,
			gettext_noop("Sets the port number of gpperfmon."),
			NULL,
		},
		&gpperfmon_port,
		8888, 1024, 65535, NULL, NULL
	},

	{
		{"gp_vmem_protect_limit", PGC_POSTMASTER, RESOURCES_MEM,
			gettext_noop("Virtual memory limit (in MB) of Greenplum memory protection."),
			NULL,
		},
		&gp_vmem_protect_limit,
#ifdef __darwin__
		0,
#else
		8192,
#endif
		0, INT_MAX / 2, NULL, NULL
	},

	{
		{"runaway_detector_activation_percent", PGC_POSTMASTER, RESOURCES_MEM,
			gettext_noop("The runaway detector activates if the used vmem exceeds this percentage of the vmem quota. Set to 100 to disable runaway detection."),
			NULL,
		},
		&runaway_detector_activation_percent,
		90, 0, 100, NULL, NULL
	},

	{
		{"gp_vmem_protect_segworker_cache_limit", PGC_POSTMASTER, RESOURCES_MEM,
			gettext_noop("Max virtual memory limit (in MB) for a segworker to be cachable."),
			NULL,
		},
		&gp_vmem_protect_gang_cache_limit,
		500, 1, INT_MAX / 2, NULL, NULL
	},

	{
		{"gp_autostats_on_change_threshold", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Threshold for number of tuples added to table by CTAS or Insert-to to trigger autostats in on_change mode. See gp_autostats_mode."),
			NULL
		},
		&gp_autostats_on_change_threshold,
		INT_MAX, 0, INT_MAX, NULL, NULL
	},

	{
		{"gp_distinct_grouping_sets_threshold", PGC_USERSET, QUERY_TUNING_METHOD,
			gettext_noop("Threshold for the number of grouping sets whose distinct-qualified "
						 "aggregate computation will be rewritten based on the multi-phrase aggregation. "
						 "The rest of grouping sets in the same query will not be rewritten."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_distinct_grouping_sets_threshold,
		32, 0, 1024, NULL, NULL
	},

	{
		{"gp_statistics_blocks_target", PGC_USERSET, STATS_ANALYZE,
			gettext_noop("The number of blocks to be sampled to estimate reltuples/relpages for heap tables."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_statistics_blocks_target,
		25, 1, 1000, NULL, NULL
	},
	{
		{"gp_resqueue_priority_local_interval", PGC_POSTMASTER, RESOURCES_MGM,
			gettext_noop("A measure of how often a backend process must consider backing off."),
			NULL,
			GUC_NO_SHOW_ALL
		},
		&gp_resqueue_priority_local_interval,
		100000, 500, INT_MAX, NULL, NULL
	},
	{
		{"gp_resqueue_priority_sweeper_interval", PGC_POSTMASTER, RESOURCES_MGM,
			gettext_noop("Frequency (in ms) at which sweeper process re-evaluates CPU shares."),
			NULL
		},
		&gp_resqueue_priority_sweeper_interval,
		1000, 500, 15000, NULL, NULL
	},
	{
		{"gp_resqueue_priority_inactivity_timeout", PGC_POSTMASTER, RESOURCES_MGM,
			gettext_noop("If a backend does not report progress in this time (in ms), it is deemed inactive."),
			NULL,
			GUC_NO_SHOW_ALL
		},
		&gp_resqueue_priority_inactivity_timeout,
		2000, 500, INT_MAX, NULL, NULL
	},
	{
		{"gp_resqueue_priority_grouping_timeout", PGC_POSTMASTER, RESOURCES_MGM,
			gettext_noop("A backend gives up on finding a better group leader after this timeout (in ms)."),
			NULL,
			GUC_NO_SHOW_ALL
		},
		&gp_resqueue_priority_grouping_timeout,
		1000, 1000, INT_MAX, NULL, NULL
	},

	{
		{"gp_perfmon_segment_interval", PGC_POSTMASTER, STATS,
			gettext_noop("Interval (in ms) between sending segment statistics to perfmon."),
			NULL,
			GUC_NO_SHOW_ALL
		},
		&gp_perfmon_segment_interval,
		1000, 500, INT_MAX, NULL, NULL
	},

	{
		{"filerep_message_body_length", PGC_POSTMASTER, DEVELOPER_OPTIONS,
			gettext_noop("size (in bytes) for filerep message body."),
			NULL,
			GUC_NO_SHOW_ALL
		},
		&file_rep_message_body_length,
		32768, 32768, 262144, NULL, NULL
	},

	{
		{"filerep_buffer_size", PGC_POSTMASTER, DEVELOPER_OPTIONS,
			gettext_noop("size (in bytes) for filerep shared memory"),
			NULL,
			GUC_NO_SHOW_ALL
		},
		&file_rep_buffer_size,
		2097152, 1048576, 16777216, NULL, NULL
	},

	{
		{"filerep_ack_buffer_size", PGC_POSTMASTER, DEVELOPER_OPTIONS,
			gettext_noop("size (in bytes) for filerep ack shared memory"),
			NULL,
			GUC_NO_SHOW_ALL
		},
		&file_rep_ack_buffer_size,
		524288, 131072, 1048576, NULL, NULL
	},

	{
		{"filerep_min_data_before_flush", PGC_POSTMASTER, DEVELOPER_OPTIONS,
			gettext_noop("size (in bytes) that a filerep buffer must reach before the client flushes the data"),
			NULL,
			GUC_NO_SHOW_ALL
		},
		&file_rep_min_data_before_flush,
		128 * 1024, 8 * 1024, 16 * 1024 * 1024, NULL, NULL
	},

	{
		{"filerep_socket_timeout", PGC_POSTMASTER, DEVELOPER_OPTIONS,
			gettext_noop("Timeout (in seconds) if we cannot write to socket (the socket is blocking)"),
			NULL,
			GUC_NO_SHOW_ALL
		},
		&file_rep_socket_timeout,
		10, 0, 300, NULL, NULL
	},

	{
		{"gp_blockdirectory_entry_min_range", PGC_USERSET, GP_ARRAY_TUNING,
			gettext_noop("Minimal range in bytes one block directory entry covers."),
			gettext_noop("Used to reduce the size of a block directory."),
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_GPDB_ADDOPT
		},
		&gp_blockdirectory_entry_min_range,
		0, 0, INT_MAX, NULL, NULL
	},

	{
		{"gp_blockdirectory_minipage_size", PGC_USERSET, GP_ARRAY_TUNING,
			gettext_noop("Number of entries one row in a block directory table contains."),
			gettext_noop("Use smaller value in non-bulk load cases."),
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_GPDB_ADDOPT
		},
		&gp_blockdirectory_minipage_size,
		NUM_MINIPAGE_ENTRIES, 1, NUM_MINIPAGE_ENTRIES, NULL, NULL
	},


	{
		{"gp_segworker_relative_priority", PGC_POSTMASTER, RESOURCES_MGM,
			gettext_noop("Priority for the segworkers relative to the postmaster's priority."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_segworker_relative_priority,
		PRIO_MAX,
		0, PRIO_MAX, NULL, NULL
	},

	{
		{"gp_workfile_bytes_to_checksum", PGC_USERSET, GP_ARRAY_TUNING,
			gettext_noop("The number of bytes to be checksummed in every WORKFILE_SAFEWRITE_SIZE bytes."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_GPDB_ADDOPT
		},
		&gp_workfile_bytes_to_checksum,
		16, 0, WORKFILE_SAFEWRITE_SIZE, NULL, NULL
	},

	/* for pljava */
	{
		{"pljava_statement_cache_size", PGC_SUSET, CUSTOM_OPTIONS,
			gettext_noop("Size of the prepared statement MRU cache"),
			NULL,
			GUC_GPDB_ADDOPT | GUC_NOT_IN_SAMPLE | GUC_SUPERUSER_ONLY
		},
		&pljava_statement_cache_size,
		0, 0, 512, NULL, NULL
	},

	/* for SimEx */
	{
		{"gp_simex_class", PGC_POSTMASTER, GP_ERROR_HANDLING,
			gettext_noop("Simulated Exceptional Situation class."),
			gettext_noop("Sets the ES class to be simulated. Default value is 0 (Out-Of-Memory)."),
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_simex_class,
		0, 0, INT_MAX, NULL, NULL
	},

	{
		{"gp_test_time_slice_interval", PGC_USERSET, GP_ERROR_HANDLING,
			gettext_noop("Maximum interval in ms between successive checks for interrupts."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_GPDB_ADDOPT
		},
		&gp_test_time_slice_interval,
		1000, 1, 10000, NULL, NULL
	},

	{
		{"gp_resqueue_memory_policy_auto_fixed_mem", PGC_USERSET, RESOURCES_MEM,
			gettext_noop("Sets the fixed amount of memory reserved for non-memory intensive operators in the AUTO policy."),
			NULL,
			GUC_UNIT_KB | GUC_GPDB_ADDOPT | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_resqueue_memory_policy_auto_fixed_mem,
		100, 50, INT_MAX, NULL, NULL
	},

	{
		{"gp_backup_directIO_read_chunk_mb", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Size of read Chunk buffer in directIO dump (in MB)"),
			NULL,
		},
		&gp_backup_directIO_read_chunk_mb,
		20, 1, 200, NULL, NULL
	},

	{
		{"gp_email_connect_timeout", PGC_SUSET, LOGGING,
			gettext_noop("Sets the amount of time (in secs) after which SMTP sockets would timeout"),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NOT_IN_SAMPLE
		},
		&gp_email_connect_timeout,
		15, 10, 120, NULL, NULL
	},
	{
		{"gp_email_connect_failures", PGC_SUSET, LOGGING,
			gettext_noop("Sets the number of consecutive connect failures before declaring SMTP server as unavailable"),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NOT_IN_SAMPLE
		},
		&gp_email_connect_failures,
		5, 3, 100, NULL, NULL
	},
	{
		{"gp_email_connect_avoid_duration", PGC_SUSET, LOGGING,
			gettext_noop("Sets the amount of time (in secs) to avoid connecting to SMTP server"),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NOT_IN_SAMPLE
		},
		&gp_email_connect_avoid_duration,
		7200, 300, 86400, NULL, NULL
	},

	{
		{"optimizer_plan_id", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Choose a plan alternative"),
			NULL,
			GUC_GPDB_ADDOPT | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_plan_id,
		0, 0, INT_MAX, NULL, NULL
	},

	{
		{"optimizer_samples_number", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Set the number of plan samples"),
			NULL,
			GUC_GPDB_ADDOPT | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_samples_number,
		1000, 1, INT_MAX, NULL, NULL
	},

	{
		{"optimizer_cte_inlining_bound", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Set the CTE inlining cutoff"),
			NULL,
			GUC_GPDB_ADDOPT | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_cte_inlining_bound,
		0, 0, INT_MAX, NULL, NULL
	},

	{
		{"optimizer_segments", PGC_USERSET, QUERY_TUNING_METHOD,
			gettext_noop("Number of segments to be considered by the optimizer during costing, or 0 to take the actual number of segments."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_segments,
		0, 0, INT_MAX, NULL, NULL
	},

	{
		{"optimizer_array_expansion_threshold", PGC_USERSET, QUERY_TUNING_METHOD,
			gettext_noop("Item limit for expansion of arrays in WHERE clause to disjunctive form."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_array_expansion_threshold,
		25, 0, INT_MAX, NULL, NULL
	},

	{
		{"optimizer_join_order_threshold", PGC_USERSET, QUERY_TUNING_METHOD,
			gettext_noop("Maximum number of join children to use dynamic programming based join ordering algorithm."),
			NULL
		},
		&optimizer_join_order_threshold,
		10, 0, INT_MAX, NULL, NULL
	},

	{
		{"optimizer_join_arity_for_associativity_commutativity", PGC_USERSET, QUERY_TUNING_METHOD,
			gettext_noop("Maximum number of children n-ary-join have without disabling commutativity and associativity transform"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_join_arity_for_associativity_commutativity,
		INT_MAX, 0, INT_MAX, NULL, NULL
	},

	{
		{"optimizer_penalize_broadcast_threshold", PGC_USERSET, QUERY_TUNING_METHOD,
			gettext_noop("Maximum number of rows of a relation that can be broadcasted without penalty."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_penalize_broadcast_threshold,
		10000000, 0, INT_MAX, NULL, NULL
	},

	{
		{"optimizer_mdcache_size", PGC_USERSET, RESOURCES_MEM,
			gettext_noop("Sets the size of MDCache."),
			NULL,
			GUC_UNIT_KB | GUC_GPDB_ADDOPT
		},
		&optimizer_mdcache_size,
		0, 0, INT_MAX, NULL, NULL
	},

	{
		{"memory_profiler_dataset_size", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Set the size in GB"),
			NULL,
			GUC_GPDB_ADDOPT | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&memory_profiler_dataset_size,
		0, 0, INT_MAX, NULL, NULL
	},
	{
		{"repl_catchup_within_range", PGC_SUSET, WAL_REPLICATION,
			gettext_noop("Sets the maximum number of xlog segments allowed to lag"
					  " when the backends can start blocking despite the WAL"
					   " sender being in catchup phase. (Master Mirroring)"),
			NULL,
			GUC_SUPERUSER_ONLY
		},
		&repl_catchup_within_range,
		1, 0, XLogSegsPerFile, NULL, NULL
	},
	{
		{"gp_initial_bad_row_limit", PGC_USERSET, EXTERNAL_TABLES,
			gettext_noop("Stops processing when number of the first bad rows exceeding this value"),
			NULL,
			GUC_GPDB_ADDOPT
		},
		&gp_initial_bad_row_limit,
		1000, 0, INT_MAX, NULL, NULL
	},

	{
		{"log_count_recovered_files_batch", PGC_POSTMASTER, DEVELOPER_OPTIONS,
			gettext_noop("Logs the total number of files shipped to the mirror after every batch of size specified by this value"),
			NULL,
			GUC_NOT_IN_SAMPLE,
		},
		&log_count_recovered_files_batch,
		1000, 0, INT_MAX, NULL, NULL
	},

	{
		{"gp_indexcheck_insert", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Validate that a unique index does not already have the new tid during insert."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_GPDB_ADDOPT
		},
		(int *) &gp_indexcheck_insert,
		INDEX_CHECK_NONE, 0, INDEX_CHECK_ALL, NULL, NULL
	},

	{
		{"gp_indexcheck_vacuum", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Validate index after lazy vacuum."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_GPDB_ADDOPT
		},
		(int *) &gp_indexcheck_vacuum,
		INDEX_CHECK_NONE, 0, INDEX_CHECK_ALL, NULL, NULL
	},

	{
		{"codegen_varlen_tolerance", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Minimum number of initial fixed length attributes in the table to generate code for deforming tuples."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_GPDB_ADDOPT
		},
		&codegen_varlen_tolerance,
#ifdef USE_CODEGEN
		5,
#else
		0,
#endif
		0, INT_MAX, NULL, NULL
	},

	{
		{"dtx_phase2_retry_count", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Maximum number of retries during two phase commit after which master PANICs."),
			NULL,
			GUC_SUPERUSER_ONLY |  GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_GPDB_ADDOPT
		},
		&dtx_phase2_retry_count,
		2, 0, 10, NULL, NULL
	},

	{
		/* Can't be set in postgresql.conf */
		{"gp_server_version_num", PGC_INTERNAL, PRESET_OPTIONS,
			gettext_noop("Shows the Greenplum server version as an integer."),
			NULL,
			GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE
		},
		&gp_server_version_num,
		GP_VERSION_NUM, GP_VERSION_NUM, GP_VERSION_NUM, NULL, NULL
	},

	/* End-of-list marker */
	{
		{NULL, 0, 0, NULL, NULL}, NULL, 0, 0, 0, NULL, NULL
	}
};

struct config_real ConfigureNamesReal_gp[] =
{
	{
		{"cursor_tuple_fraction", PGC_USERSET, QUERY_TUNING_OTHER,
			gettext_noop("Sets the planner's estimate of the fraction of "
						 "a cursor's rows that will be retrieved."),
			NULL
		},
		&cursor_tuple_fraction,
		DEFAULT_CURSOR_TUPLE_FRACTION, 0.0, 1.0, NULL, NULL
	},

	{
		{"gp_workfile_limit_per_segment", PGC_POSTMASTER, RESOURCES,
			gettext_noop("Maximum disk space (in KB) used for workfiles per segment."),
			gettext_noop("0 for no limit. Current query is terminated when limit is exceeded."),
			GUC_UNIT_KB
		},
		&gp_workfile_limit_per_segment,
		0, 0, SIZE_MAX / 1024, NULL, NULL,
	},

	{
		{"gp_workfile_limit_per_query", PGC_USERSET, RESOURCES,
			gettext_noop("Maximum disk space (in KB) used for workfiles per query per segment."),
			gettext_noop("0 for no limit. Current query is terminated when limit is exceeded."),
			GUC_GPDB_ADDOPT | GUC_UNIT_KB
		},
		&gp_workfile_limit_per_query,
		0, 0, SIZE_MAX / 1024, NULL, NULL,
	},

	{
		{"gp_motion_cost_per_row", PGC_USERSET, QUERY_TUNING_COST,
			gettext_noop("Sets the planner's estimate of the cost of "
						 "moving a row between worker processes."),
			gettext_noop("If >0, the planner uses this value -- instead of double the "
					"cpu_tuple_cost -- for Motion operator cost estimation.")
		},
		&gp_motion_cost_per_row,
		0, 0, DBL_MAX, NULL, NULL
	},

	{
		{"gp_hashagg_rewrite_limit", PGC_USERSET, QUERY_TUNING_OTHER,
			gettext_noop("(Obsolete) Planner will not choose hashed aggregation if "
						 "expected number of extra passes exceeds limit."),
			NULL,
			GUC_NOT_IN_SAMPLE | GUC_NO_SHOW_ALL
		},
		&defunct_double,
		2.0, 1.0, 100.0, NULL, NULL
	},

	{
		{"gp_analyze_relative_error", PGC_USERSET, STATS_ANALYZE,
			gettext_noop("target relative error fraction for row sampling during analyze"),
			NULL
		},
		&analyze_relative_error,
		0.25, 0, 1.0, NULL, NULL
	},

	{
		{"gp_selectivity_damping_factor", PGC_USERSET, QUERY_TUNING_METHOD,
			gettext_noop("Factor used in selectivity damping."),
			gettext_noop("Values 1..N, 1 = basic damping, greater values emphasize damping"),
			GUC_NOT_IN_SAMPLE | GUC_NO_SHOW_ALL
		},
		&gp_selectivity_damping_factor,
		1.0, 1.0, DBL_MAX, NULL, NULL
	},

	{
		{"gp_statistics_ndistinct_scaling_ratio_threshold", PGC_USERSET, STATS_ANALYZE,
			gettext_noop("If the ratio of number of distinct values of an attribute to the number of rows is greater than this value, it is assumed that ndistinct will scale with table size."),
			NULL,
			GUC_NOT_IN_SAMPLE | GUC_NO_SHOW_ALL
		},
		&gp_statistics_ndistinct_scaling_ratio_threshold,
		0.10, 0.001, 1.0, NULL, NULL
	},

	{
		{"gp_statistics_sampling_threshold", PGC_USERSET, STATS_ANALYZE,
			gettext_noop("Only tables larger than this size will be sampled."),
			NULL,
			GUC_NOT_IN_SAMPLE | GUC_NO_SHOW_ALL
		},
		&gp_statistics_sampling_threshold,
		20000.0, 0.0, DBL_MAX, NULL, NULL
	},

	{
		{"gp_resqueue_priority_cpucores_per_segment", PGC_POSTMASTER, RESOURCES_MGM,
			gettext_noop("Number of processing units associated with a segment."),
			NULL
		},
		&gp_resqueue_priority_cpucores_per_segment,
		4.0, 0.1, 512.0, NULL, NULL
	},

	{
		{"gp_simex_rand", PGC_USERSET, GP_ERROR_HANDLING,
			gettext_noop("Propability of injecting an Exceptional Situation in SimEx."),
			gettext_noop("Controls randomized ES simulation."),
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_GPDB_ADDOPT
		},
		&gp_simex_rand,
		100.0, 0.001, 100.0, NULL, NULL
	},

	{
		{"optimizer_damping_factor_filter", PGC_USERSET, QUERY_TUNING_METHOD,
			gettext_noop("select predicate damping factor in optimizer, 1.0 means no damping"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_damping_factor_filter,
		0.75, 0.0, 1.0, NULL, NULL
	},

	{
		{"optimizer_damping_factor_join", PGC_USERSET, QUERY_TUNING_METHOD,
			gettext_noop("join predicate damping factor in optimizer, 1.0 means no damping"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_damping_factor_join,
		0.01, 0.0, 1.0, NULL, NULL
	},
	{
		{"optimizer_damping_factor_groupby", PGC_USERSET, QUERY_TUNING_METHOD,
			gettext_noop("groupby operator damping factor in optimizer, 1.0 means no damping"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_damping_factor_groupby,
		0.75, 0.0, 1.0, NULL, NULL
	},

	{
		{"optimizer_cost_threshold", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("set the threshold for plan smapling relative to the cost of best plan, 0.0 means unbounded"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_cost_threshold,
		0.0, 0.0, INT_MAX, NULL, NULL
	},

	{
		{"optimizer_nestloop_factor", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("set the nestloop join cost factor in the optimizer"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_nestloop_factor,
		1024.0, 1.0, DBL_MAX, NULL, NULL
	},

	{
		{"optimizer_sort_factor",PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("set the sort cost factor in the optimizer, 1.0 means same as default, > 1.0 means more costly than default, < 1.0 means means less costly than default"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_sort_factor,
		1.0, 0.0, DBL_MAX, NULL, NULL
	},

	/* End-of-list marker */
	{
		{NULL, 0, 0, NULL, NULL}, NULL, 0.0, 0.0, 0.0, NULL, NULL
	}
};

struct config_string ConfigureNamesString_gp[] =
{
	{
		{"gp_hashagg_compress_spill_files", PGC_USERSET, DEPRECATED_OPTIONS,
			gettext_noop("Specify if spill files in HashAggregate should be compressed."),
			gettext_noop("Valid values are \"NONE\"(or \"NOTHING\"), \"ZLIB\"."),
			GUC_GPDB_ADDOPT | GUC_NOT_IN_SAMPLE | GUC_NO_SHOW_ALL
		},
		&gp_hashagg_compress_spill_files_str,
		"none", assign_hashagg_compress_spill_files, NULL
	},

	{
		{"gp_workfile_compress_algorithm", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Specify the compression algorithm that work files in the query executor use."),
			gettext_noop("Valid values are \"NONE\", \"ZLIB\"."),
			GUC_GPDB_ADDOPT
		},
		&gp_workfile_compress_algorithm_str,
		"none", assign_gp_workfile_compress_algorithm, NULL
	},

	{
		{"gp_workfile_type_hashjoin", PGC_USERSET, QUERY_TUNING_OTHER,
			gettext_noop("Specify the type of work files to use for executing hash join plans."),
			gettext_noop("Valid values are \"BFZ\", \"BUFFILE\"."),
			GUC_GPDB_ADDOPT | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_workfile_type_hashjoin_str,
		"bfz", assign_gp_workfile_type_hashjoin, NULL
	},

	{
		{"gpperfmon_log_alert_level", PGC_USERSET, LOGGING,
			gettext_noop("Specify the log alert level used by gpperfmon."),
			gettext_noop("Valid values are 'none', 'warning', 'error', 'fatal', 'panic'.")
		},
		&gpperfmon_log_alert_level_str,
		"none", gpvars_assign_gp_gpperfmon_log_alert_level, gpvars_show_gp_gpperfmon_log_alert_level
	},

	{
		{"explain_memory_verbosity", PGC_USERSET, RESOURCES_MEM,
			gettext_noop("Experimental feature: show memory account usage in EXPLAIN ANALYZE."),
			gettext_noop("Valid values are SUPPRESS, SUMMARY, and DETAIL."),
			GUC_GPDB_ADDOPT
		},
		&explain_memory_verbosity_str,
		"suppress", assign_explain_memory_verbosity, NULL
	},

	{
		{"memory_profiler_run_id", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Set the unique run ID for memory profiling"),
			gettext_noop("Any string is acceptable"),
			GUC_GPDB_ADDOPT | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&memory_profiler_run_id,
		"none", NULL, NULL
	},

	{
		{"memory_profiler_dataset_id", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Set the dataset ID for memory profiling"),
			gettext_noop("Any string is acceptable"),
			GUC_GPDB_ADDOPT | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&memory_profiler_dataset_id,
		"none", NULL, NULL
	},

	{
		{"memory_profiler_query_id", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Set the query ID for memory profiling"),
			gettext_noop("Any string is acceptable"),
			GUC_GPDB_ADDOPT | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&memory_profiler_query_id,
		"none", NULL, NULL
	},

	{
		{"optimizer_log_failure", PGC_USERSET, LOGGING_WHEN,
			gettext_noop("Sets which optimizer failures are logged."),
			gettext_noop("Valid values are unexpected, expected, all"),
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_log_failure_str,
		"all", assign_optimizer_log_failure, NULL
	},

	{
		{"optimizer_minidump", PGC_USERSET, LOGGING_WHEN,
			gettext_noop("Generate optimizer minidump."),
			gettext_noop("Valid values are onerror, always"),
		},
		&optimizer_minidump_str,
		"onerror", assign_optimizer_minidump, NULL
	},

	{
		{"optimizer_cost_model", PGC_USERSET, LOGGING_WHEN,
			gettext_noop("Set optimizer cost model."),
			gettext_noop("Valid values are legacy, calibrated"),
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_cost_model_str,
		"calibrated", assign_optimizer_cost_model, NULL
	},
	{
		{"gp_workfile_caching_loglevel", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Sets the logging level for workfile caching debugging messages"),
			gettext_noop("Valid values are DEBUG5, DEBUG4, DEBUG3, DEBUG2, "
						 "DEBUG1, LOG, NOTICE, WARNING, and ERROR. Each level includes all the "
						 "levels that follow it. The later the level, the fewer messages are "
						 "sent."),
			GUC_GPDB_ADDOPT | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_workfile_caching_loglevel_str,
		"debug1", assign_gp_workfile_caching_loglevel, NULL
	},

	{
		{"gp_sessionstate_loglevel", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Sets the logging level for session state debugging messages"),
			gettext_noop("Valid values are DEBUG5, DEBUG4, DEBUG3, DEBUG2, "
						 "DEBUG1, LOG, NOTICE, WARNING, and ERROR. Each level includes all the "
						 "levels that follow it. The later the level, the fewer messages are "
						 "sent."),
			GUC_GPDB_ADDOPT | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_sessionstate_loglevel_str,
		"debug1", assign_gp_sessionstate_loglevel, NULL
	},

	{
		{"debug_persistent_print_level", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Sets the persistent relation debug message levels that are logged."),
			gettext_noop("Valid values are DEBUG5, DEBUG4, DEBUG3, DEBUG2, DEBUG1, "
			"INFO, NOTICE, WARNING, ERROR, LOG, FATAL, and PANIC. Each level "
						 "includes all the levels that follow it."),
			GUC_GPDB_ADDOPT | GUC_NO_SHOW_ALL
		},
		&Debug_persistent_print_level_str,
		"debug1", assign_debug_persistent_print_level, NULL
	},

	{
		{"debug_persistent_recovery_print_level", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Sets the persistent recovery debug message levels that are logged."),
			gettext_noop("Valid values are DEBUG5, DEBUG4, DEBUG3, DEBUG2, DEBUG1, "
			"INFO, NOTICE, WARNING, ERROR, LOG, FATAL, and PANIC. Each level "
						 "includes all the levels that follow it."),
			GUC_GPDB_ADDOPT | GUC_NO_SHOW_ALL
		},
		&Debug_persistent_recovery_print_level_str,
		"debug1", assign_debug_persistent_recovery_print_level, NULL
	},

	{
		{"debug_persistent_store_print_level", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Sets the persistent relation store debug message levels that are logged."),
			gettext_noop("Valid values are DEBUG5, DEBUG4, DEBUG3, DEBUG2, DEBUG1, "
			"INFO, NOTICE, WARNING, ERROR, LOG, FATAL, and PANIC. Each level "
						 "includes all the levels that follow it."),
			GUC_GPDB_ADDOPT | GUC_NO_SHOW_ALL
		},
		&Debug_persistent_store_print_level_str,
		"debug1", assign_debug_persistent_store_print_level, NULL
	},

	{
		{"debug_database_command_error_level", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Sets the database command debug message levels that are logged."),
			gettext_noop("Valid values are DEBUG5, DEBUG4, DEBUG3, DEBUG2, DEBUG1, "
			"INFO, NOTICE, WARNING, ERROR, LOG, FATAL, and PANIC. Each level "
						 "includes all the levels that follow it."),
			GUC_GPDB_ADDOPT | GUC_NO_SHOW_ALL
		},
		&Debug_database_command_print_level_str,
		"log", assign_debug_database_command_print_level, NULL
	},

	{
		{"gp_session_role", PGC_BACKEND, GP_WORKER_IDENTITY,
			gettext_noop("Reports the default role for the session."),
			gettext_noop("Valid values are DISPATCH, EXECUTE, and UTILITY."),
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE
		},
		&gp_session_role_string,
		"dispatch", assign_gp_session_role, show_gp_session_role
	},

	{
		{"gp_role", PGC_SUSET, CLIENT_CONN_OTHER,
			gettext_noop("Sets the role for the session."),
			gettext_noop("Valid values are DISPATCH, EXECUTE, and UTILITY."),
			GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE
		},
		&gp_role_string,
		"dispatch", assign_gp_role, show_gp_role
	},

	{
		{"gp_fault_action", PGC_POSTMASTER, DEFUNCT_OPTIONS,
			gettext_noop("Sets the fault action for fault tolerance management."),
			gettext_noop("Valid values are CONTINUE, READONLY, and SHUTDOWN."),
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_fault_action_string,
		"continue", NULL, NULL
	},

	{
		{"gp_log_gang", PGC_USERSET, LOGGING_WHAT,
			gettext_noop("Sets the verbosity of logged messages pertaining to worker process creation and management."),
			gettext_noop("Valid values are \"off\", \"terse\", \"verbose\" and \"debug\"."),
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_log_gang_str,
		"terse", gpvars_assign_gp_log_gang, gpvars_show_gp_log_gang
	},

	{
		{"gp_log_fts", PGC_SIGHUP, LOGGING_WHAT,
			gettext_noop("Sets the verbosity of logged messages pertaining to fault probing."),
			gettext_noop("Valid values are \"off\", \"terse\", \"verbose\" and \"debug\"."),
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_log_fts_str,
		"terse", gpvars_assign_gp_log_fts, gpvars_show_gp_log_fts
	},

	{
		{"gp_log_interconnect", PGC_USERSET, LOGGING_WHAT,
			gettext_noop("Sets the verbosity of logged messages pertaining to connections between worker processes."),
			gettext_noop("Valid values are \"off\", \"terse\", \"verbose\" and \"debug\"."),
			GUC_GPDB_ADDOPT | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_log_interconnect_str,
		"terse", gpvars_assign_gp_log_interconnect, gpvars_show_gp_log_interconnect
	},

	{
		{"gp_interconnect_type", PGC_USERSET, GP_ARRAY_TUNING,
			gettext_noop("Sets the protocol used for inter-node communication."),
			gettext_noop("Only support \"udpifc\" for now."),
			GUC_GPDB_ADDOPT | GUC_NO_SHOW_ALL | GUC_DISALLOW_IN_FILE
		},
		&gp_interconnect_type_str,
		"udpifc", gpvars_assign_gp_interconnect_type, gpvars_show_gp_interconnect_type
	},

	{
		{"gp_interconnect_fc_method", PGC_USERSET, GP_ARRAY_TUNING,
			gettext_noop("Sets the flow control method used for UDP interconnect."),
			gettext_noop("Valid values are \"capacity\" and \"loss\"."),
			GUC_GPDB_ADDOPT
		},
		&gp_interconnect_fc_method_str,
		"loss", gpvars_assign_gp_interconnect_fc_method, gpvars_show_gp_interconnect_fc_method
	},

	{
		{"gp_qd_hostname", PGC_BACKEND, GP_WORKER_IDENTITY,
			gettext_noop("Shows the QD Hostname. Blank when run on the QD"),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE
		},
		&qdHostname,
		"", NULL, NULL
	},

	{
		{"debug_dtm_action", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Sets the debug DTM action."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_dtm_action_str,
		"none", assign_debug_dtm_action, NULL
	},

	{
		{"debug_dtm_action_target", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Sets the debug DTM action target."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_dtm_action_target_str,
		"none", assign_debug_dtm_action_target, NULL
	},

	{
		{"debug_dtm_action_protocol", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Sets the debug DTM action protocol."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_dtm_action_protocol_str,
		"none", assign_debug_dtm_action_protocol, NULL
	},

	{
		{"debug_dtm_action_sql_command_tag", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Sets the debug DTM action sql command tag."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&Debug_dtm_action_sql_command_tag,
		"", NULL, NULL
	},
	{
		{"gp_autostats_mode", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Sets the autostats mode."),
			gettext_noop("Valid values are NONE, ON_CHANGE, ON_NO_STATS. ON_CHANGE requires setting gp_autostats_on_change_threshold.")
		},
		&gp_autostats_mode_string,
		"none", gpvars_assign_gp_autostats_mode, gpvars_show_gp_autostats_mode
	},
	{
		{"gp_autostats_mode_in_functions", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Sets the autostats mode for statements in procedural language functions."),
			gettext_noop("Valid values are NONE, ON_CHANGE, ON_NO_STATS. ON_CHANGE requires setting gp_autostats_on_change_threshold.")
		},
		&gp_autostats_mode_in_functions_string,
		"none", gpvars_assign_gp_autostats_mode_in_functions, gpvars_show_gp_autostats_mode_in_functions
	},
	{
		{"gp_resqueue_priority_default_value", PGC_POSTMASTER, RESOURCES_MGM,
			gettext_noop("Default weight when one cannot be associated with a statement."),
			NULL,
			GUC_NO_SHOW_ALL
		},
		&gp_resqueue_priority_default_value,
		"MEDIUM", gpvars_assign_gp_resqueue_priority_default_value, NULL
	},

	{
		{"gp_email_smtp_server", PGC_SUSET, LOGGING,
			gettext_noop("Sets the SMTP server and port used to send email alerts."),
			NULL,
			GUC_SUPERUSER_ONLY
		},
		&gp_email_smtp_server,
		"localhost:25", NULL, NULL
	},
	{
		{"gp_email_smtp_userid", PGC_SUSET, LOGGING,
			gettext_noop("Sets the userid used for the SMTP server, if required."),
			NULL,
			GUC_SUPERUSER_ONLY
		},
		&gp_email_smtp_userid,
		"", NULL, NULL
	},
	{
		{"gp_email_smtp_password", PGC_SUSET, LOGGING,
			gettext_noop("Sets the password used for the SMTP server, if required."),
			NULL,
			GUC_SUPERUSER_ONLY
		},
		&gp_email_smtp_password,
		"", NULL, NULL
	},
	{
		{"gp_email_from", PGC_SUSET, LOGGING,
			gettext_noop("Sets email address of the sender of email alerts (our email id)."),
			NULL,
			GUC_SUPERUSER_ONLY
		},
		&gp_email_from,
		"", NULL, NULL
	},
	{
		{"gp_email_to", PGC_SUSET, LOGGING,
			gettext_noop("Sets email address(es) to send alerts to.  May be multiple email addresses separated by semi-colon."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_LIST_INPUT
		},
		&gp_email_to,
		"", NULL, NULL
	},

#if USE_SNMP
	{
		{"gp_snmp_community", PGC_SUSET, LOGGING,
			gettext_noop("Sets SNMP community name to send alerts (inform or trap messages) to."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_LIST_INPUT
		},
		&gp_snmp_community,
		"public", NULL, NULL
	},
	{
		{"gp_snmp_monitor_address", PGC_SUSET, LOGGING,
			gettext_noop("Sets the network address to send SNMP alerts (inform or trap messages) to."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_LIST_INPUT
		},
		&gp_snmp_monitor_address,
		"", NULL, NULL
	},
	{
		{"gp_snmp_use_inform_or_trap", PGC_SUSET, LOGGING,
			gettext_noop("If 'inform', we send alerts as SNMP v2c inform messages, if 'trap', we use SNMP v2 trap messages.."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_LIST_INPUT
		},
		&gp_snmp_use_inform_or_trap,
		"trap", NULL, NULL
	},
	{
		{"gp_snmp_debug_log", PGC_SUSET, DEVELOPER_OPTIONS,
			gettext_noop("Logs snmp activity to this file for debugging purposes."),
			NULL,
			GUC_SUPERUSER_ONLY | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_snmp_debug_log,
		"", NULL, NULL
	},

#endif

#ifdef USE_CONNECTEMC
	{
		{"gp_connectemc_mode", PGC_POSTMASTER, LOGGING,
			gettext_noop("control connectemc functionality"),
			gettext_noop("If 'on' send connectemc messages and log them locally, if 'local' log connectemc message locally only, if 'remote' send connectemc messages only, if 'off', no connectemc messages"),
			GUC_SUPERUSER_ONLY
		},
		&gp_connectemc_mode,
		"on", assign_connectemc_mode, NULL
	},
#endif

	/* for pljava */
	{
		{"pljava_vmoptions", PGC_SUSET, CUSTOM_OPTIONS,
			gettext_noop("Options sent to the JVM when it is created"),
			NULL,
			GUC_GPDB_ADDOPT | GUC_NOT_IN_SAMPLE | GUC_SUPERUSER_ONLY
		},
		&pljava_vmoptions,
		"", NULL, NULL
	},
	{
		{"pljava_classpath", PGC_SUSET, CUSTOM_OPTIONS,
			gettext_noop("classpath used by the the JVM"),
			NULL,
			GUC_GPDB_ADDOPT | GUC_NOT_IN_SAMPLE 
		},
		&pljava_classpath,
		"", NULL, NULL
	},

	{
		{"gp_resqueue_memory_policy", PGC_SUSET, RESOURCES_MGM,
			gettext_noop("Sets the policy for memory allocation of queries."),
			gettext_noop("Valid values are NONE, AUTO, EAGER_FREE.")
		},
		&gp_resqueue_memory_policy_str,
		"none", gpvars_assign_gp_resqueue_memory_policy, gpvars_show_gp_resqueue_memory_policy
	},

	{
		{"gp_test_time_slice_report_level", PGC_USERSET, LOGGING_WHEN,
			gettext_noop("Sets the message level for time slice violation reports."),
			gettext_noop("Valid values are NOTICE, WARNING, ERROR, FATAL and PANIC."),
			GUC_GPDB_ADDOPT | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_test_time_slice_report_level_str,
		"error", assign_time_slice_report_level, NULL
	},

	{
		{"gp_test_deadlock_hazard_report_level", PGC_USERSET, LOGGING_WHEN,
			gettext_noop("Sets the message level for deadlock hazard reports."),
			gettext_noop("Valid values are NOTICE, WARNING, ERROR, FATAL and PANIC."),
			GUC_GPDB_ADDOPT | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_test_deadlock_hazard_report_level_str,
		"error", assign_deadlock_hazard_report_level, NULL
	},

	{
		{"gp_test_system_cache_flush_force", PGC_USERSET, GP_ERROR_HANDLING,
			gettext_noop("Force invalidation of system caches on each access"),
			gettext_noop("Valid values are OFF, PLAIN and RECURSIVE."),
			GUC_GPDB_ADDOPT | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_test_system_cache_flush_force_str,
		"off", assign_system_cache_flush_force, NULL
	},

	{
		{"gp_hadoop_connector_jardir", PGC_USERSET, CUSTOM_OPTIONS,
			gettext_noop("The directory of the Hadoop connector JAR, relative to $GPHOME."),
			NULL,
			GUC_GPDB_ADDOPT | GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_hadoop_connector_jardir,
		"lib//hadoop", NULL, NULL
	},

	{
		{"gp_hadoop_target_version", PGC_USERSET, CUSTOM_OPTIONS,
			gettext_noop("The distro/version of Hadoop that external table is connecting to."),
			gettext_noop("See release notes or gppkg readme for details."),
			GUC_GPDB_ADDOPT
		},
		&gp_hadoop_target_version,
		"gphd-1.1", NULL, NULL
	},

	{
		{"gp_hadoop_home", PGC_USERSET, CUSTOM_OPTIONS,
			gettext_noop("The location where Hadoop is installed in each segment."),
			NULL,
			GUC_GPDB_ADDOPT
		},
		&gp_hadoop_home,
		"", NULL, NULL
	},

	{
		{"gp_auth_time_override", PGC_SIGHUP, DEVELOPER_OPTIONS,
			gettext_noop("The timestamp used for enforcing time constraints."),
			gettext_noop("For testing purposes only."),
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&gp_auth_time_override_str,
		"", NULL, NULL
	},

	{
		{"password_hash_algorithm", PGC_SUSET, CONN_AUTH_SECURITY,
			gettext_noop("The cryptograph hash algorithm to apply to passwords before storing them."),
			gettext_noop("Valid values are MD5 or SHA-256."),
			GUC_SUPERUSER_ONLY
		},
		&password_hash_algorithm_str,
		"MD5", assign_password_hash_algorithm, NULL
	},

	{
		{"gp_idf_deduplicate", PGC_USERSET, QUERY_TUNING_METHOD,
			gettext_noop("Sets the mode to control inverse distribution function's de-duplicate strategy."),
			gettext_noop("Valid values are AUTO, NONE, and FORCE.")
		},
		&gp_idf_deduplicate_str,
		"auto", assign_gp_idf_deduplicate, NULL
	},

	{
		{"optimizer_search_strategy_path", PGC_USERSET, QUERY_TUNING_METHOD,
			gettext_noop("Sets the search strategy used by gp optimizer."),
			NULL,
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE
		},
		&optimizer_search_strategy_path,
		"default", NULL, NULL
	},

	{
		{"gp_default_storage_options", PGC_USERSET, APPENDONLY_TABLES,
			gettext_noop("Default options for appendonly storage."),
			NULL,
			GUC_NOT_IN_SAMPLE | GUC_GPDB_ADDOPT
		},
		&gp_default_storage_options, "", assign_gp_default_storage_options, NULL
	},

	{
		{"gp_log_format", PGC_POSTMASTER, LOGGING_WHERE,
			gettext_noop("Sets the format for log files."),
			gettext_noop("Valid values are TEXT, CSV.")
		},
		&gp_log_format_string,
		"csv", assign_gp_log_format, NULL
	},

	{
		{"codegen_optimization_level", PGC_USERSET, DEVELOPER_OPTIONS,
			gettext_noop("Sets optimizer level to use when compiling generated code."),
			gettext_noop("Valid values are none, less, default, aggressive."),
			GUC_NO_SHOW_ALL | GUC_NOT_IN_SAMPLE | GUC_GPDB_ADDOPT
		},
		&codegen_optimization_level_str,
#ifdef USE_CODEGEN
		"default",
#else
		"",
#endif
		assign_codegen_optimization_level, NULL
	},

	{
		/* Can't be set in postgresql.conf */
		{"gp_server_version", PGC_INTERNAL, PRESET_OPTIONS,
			gettext_noop("Shows the Greenplum server version."),
			NULL,
			GUC_REPORT | GUC_NOT_IN_SAMPLE | GUC_DISALLOW_IN_FILE
		},
		&gp_server_version_string,
		GP_VERSION, NULL, NULL
	},

	/* End-of-list marker */
	{
		{NULL, 0, 0, NULL, NULL}, NULL, NULL, NULL, NULL
	}
};

static const char *
assign_gp_log_format(const char *value, bool doit, GucSource source)
{
	int			log_format = 0;

	if (pg_strcasecmp(value, "text") == 0)
		log_format = 0;
	else if (pg_strcasecmp(value, "csv") == 0)
		log_format = 1;
	else
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				 errmsg("unrecognized \"gp_log_format\" key word: \"%s\"",
						value)));
	if (doit)
		gp_log_format = log_format;

	return value;
}


static const char *
assign_debug_dtm_action_protocol(const char *newval,
								 bool doit, GucSource source)
{
	if (pg_strcasecmp(newval, "none") == 0)
	{
		if (doit)
			Debug_dtm_action_protocol = DTX_PROTOCOL_COMMAND_NONE;
	}
	else if (pg_strcasecmp(newval, "abort_no_prepared") == 0)
	{
		if (doit)
			Debug_dtm_action_protocol = DTX_PROTOCOL_COMMAND_ABORT_NO_PREPARED;
	}
	else if (pg_strcasecmp(newval, "prepare") == 0)
	{
		if (doit)
			Debug_dtm_action_protocol = DTX_PROTOCOL_COMMAND_PREPARE;
	}
	else if (pg_strcasecmp(newval, "abort_some_prepared") == 0)
	{
		if (doit)
			Debug_dtm_action_protocol = DTX_PROTOCOL_COMMAND_ABORT_SOME_PREPARED;
	}
	else if (pg_strcasecmp(newval, "commit_prepared") == 0)
	{
		if (doit)
			Debug_dtm_action_protocol = DTX_PROTOCOL_COMMAND_COMMIT_PREPARED;
	}
	else if (pg_strcasecmp(newval, "abort_prepared") == 0)
	{
		if (doit)
			Debug_dtm_action_protocol = DTX_PROTOCOL_COMMAND_ABORT_PREPARED;
	}
	else if (pg_strcasecmp(newval, "retry_commit_prepared") == 0)
	{
		if (doit)
			Debug_dtm_action_protocol = DTX_PROTOCOL_COMMAND_RETRY_COMMIT_PREPARED;
	}
	else if (pg_strcasecmp(newval, "retry_abort_prepared") == 0)
	{
		if (doit)
			Debug_dtm_action_protocol = DTX_PROTOCOL_COMMAND_RETRY_ABORT_PREPARED;
	}
	else if (pg_strcasecmp(newval, "recovery_commit_prepared") == 0)
	{
		if (doit)
			Debug_dtm_action_protocol = DTX_PROTOCOL_COMMAND_RECOVERY_COMMIT_PREPARED;
	}
	else if (pg_strcasecmp(newval, "recovery_abort_prepared") == 0)
	{
		if (doit)
			Debug_dtm_action_protocol = DTX_PROTOCOL_COMMAND_RECOVERY_ABORT_PREPARED;
	}
	else if (pg_strcasecmp(newval, "subtransaction_begin") == 0)
	{
		if (doit)
			Debug_dtm_action_protocol = DTX_PROTOCOL_COMMAND_SUBTRANSACTION_BEGIN_INTERNAL;
	}
	else if (pg_strcasecmp(newval, "subtransaction_release") == 0)
	{
		if (doit)
			Debug_dtm_action_protocol = DTX_PROTOCOL_COMMAND_SUBTRANSACTION_RELEASE_INTERNAL;
	}
	else if (pg_strcasecmp(newval, "subtransaction_rollback") == 0)
	{
		if (doit)
			Debug_dtm_action_protocol = DTX_PROTOCOL_COMMAND_SUBTRANSACTION_ROLLBACK_INTERNAL;
	}
	else
		return NULL;			/* fail */
	return newval;				/* OK */
}

static const char *
assign_debug_persistent_print_level(const char *newval,
									bool doit, GucSource source)
{
	return (assign_msglvl(&Debug_persistent_print_level, newval, doit, source));
}

static const char *
assign_debug_persistent_recovery_print_level(const char *newval,
											 bool doit, GucSource source)
{
	return (assign_msglvl(&Debug_persistent_recovery_print_level, newval, doit, source));
}

static const char *
assign_debug_persistent_store_print_level(const char *newval,
										  bool doit, GucSource source)
{
	return (assign_msglvl(&Debug_persistent_store_print_level, newval, doit, source));
}

static const char *
assign_debug_database_command_print_level(const char *newval,
										  bool doit, GucSource source)
{
	return (assign_msglvl(&Debug_database_command_print_level, newval, doit, source));
}

static const char *
assign_gp_workfile_caching_loglevel(const char *newval,
									bool doit, GucSource source)
{
	return (assign_msglvl(&gp_workfile_caching_loglevel, newval, doit, source));
}

static const char *
assign_gp_sessionstate_loglevel(const char *newval,
								bool doit, GucSource source)
{
	return (assign_msglvl(&gp_sessionstate_loglevel, newval, doit, source));
}

static const char *
assign_optimizer_log_failure(const char *val, bool assign, GucSource source)
{
	if (pg_strcasecmp(val, "all") == 0 && assign)
	{
		optimizer_log_failure = OPTIMIZER_ALL_FAIL;
	}
	else if (pg_strcasecmp(val, "unexpected") == 0 && assign)
	{
		optimizer_log_failure = OPTIMIZER_UNEXPECTED_FAIL;
	}
	else if (pg_strcasecmp(val, "expected") == 0 && assign)
	{
		optimizer_log_failure = OPTIMIZER_EXPECTED_FAIL;
	}
	else
	{
		return NULL;			/* fail */
	}

	return val;
}

static const char*
assign_codegen_optimization_level(const char *val, bool assign, GucSource source) {
#ifndef USE_CODEGEN
	if (val && pg_strcasecmp(val, "") != 0)
		ereport(ERROR,
			(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				errmsg("Code generation is not supported by this build")));
#else

	if (pg_strcasecmp(val, "none") == 0 && assign)
	{
		codegen_optimization_level = CODEGEN_OPTIMIZATION_LEVEL_NONE;
	}
	else if (pg_strcasecmp(val, "less") == 0 && assign)
	{
		codegen_optimization_level = CODEGEN_OPTIMIZATION_LEVEL_LESS;
	}
	else if (pg_strcasecmp(val, "default") == 0 && assign)
	{
		codegen_optimization_level = CODEGEN_OPTIMIZATION_LEVEL_DEFAULT;
	}
	else if (pg_strcasecmp(val, "aggressive") == 0 && assign)
	{
		codegen_optimization_level = CODEGEN_OPTIMIZATION_LEVEL_AGGRESSIVE;
	}
	else
	{
		return NULL;      /* fail */
	}
#endif

	return val;
}


static const char *
assign_optimizer_minidump(const char *val, bool assign, GucSource source)
{
	if (pg_strcasecmp(val, "onerror") == 0 && assign)
	{
		optimizer_minidump = OPTIMIZER_MINIDUMP_FAIL;
	}
	else if (pg_strcasecmp(val, "always") == 0 && assign)
	{
		optimizer_minidump = OPTIMIZER_MINIDUMP_ALWAYS;
	}
	else
	{
		return NULL;			/* fail */
	}

	return val;
}

static const char *
assign_optimizer_cost_model(const char *val, bool assign, GucSource source)
{
	if (pg_strcasecmp(val, "legacy") == 0 && assign)
	{
		optimizer_cost_model = OPTIMIZER_GPDB_LEGACY;
	}
	else if (pg_strcasecmp(val, "calibrated") == 0 && assign)
	{
		optimizer_cost_model = OPTIMIZER_GPDB_CALIBRATED;
	}
	else
	{
		return NULL;			/* fail */
	}
	return val;
}

static const char *
assign_time_slice_report_level(const char *newval, bool doit, GucSource source)
{
	return (assign_msglvl(&gp_test_time_slice_report_level, newval, doit, source));
}

static const char *
assign_deadlock_hazard_report_level(const char *newval, bool doit, GucSource source)
{
	return (assign_msglvl(&gp_test_deadlock_hazard_report_level, newval, doit, source));
}

static const char *
assign_explain_memory_verbosity(const char *newval, bool doit, GucSource source)
{
	if (pg_strcasecmp(newval, "suppress") == 0)
	{
		if (doit)
			explain_memory_verbosity = EXPLAIN_MEMORY_VERBOSITY_SUPPRESS;
	}
	else if (pg_strcasecmp(newval, "summary") == 0)
	{
		if (doit)
			explain_memory_verbosity = EXPLAIN_MEMORY_VERBOSITY_SUMMARY;
	}
	else if (pg_strcasecmp(newval, "detail") == 0)
	{
		if (doit)
			explain_memory_verbosity = EXPLAIN_MEMORY_VERBOSITY_DETAIL;
	}
	else
	{
		printf("Unknown memory verbosity.");
		return NULL;
	}

	return newval;
}

static const char *
assign_system_cache_flush_force(const char *newval, bool doit, GucSource source)
{
	if (pg_strcasecmp(newval, "off") == 0)
	{
		if (doit)
			gp_test_system_cache_flush_force = SysCacheFlushForce_Off;
	}
	else if (pg_strcasecmp(newval, "recursive") == 0)
	{
		if (doit)
			gp_test_system_cache_flush_force = SysCacheFlushForce_Recursive;
	}
	else if (pg_strcasecmp(newval, "plain") == 0)
	{
		if (doit)
			gp_test_system_cache_flush_force = SysCacheFlushForce_NonRecursive;
	}
	else
	{
		return NULL;
	}

	return newval;
}

static const char *
assign_password_hash_algorithm(const char *newval, bool doit, GucSource source)
{
	if (pg_strcasecmp(newval, "MD5") == 0)
	{
		if (doit)
			password_hash_algorithm = PASSWORD_HASH_MD5;
	}
	else if (pg_strcasecmp(newval, "SHA-256") == 0)
	{
		if (doit)
			password_hash_algorithm = PASSWORD_HASH_SHA_256;
	}
	else
		return NULL;

	return newval;
}

static const char *
assign_gp_idf_deduplicate(const char *newval, bool doit, GucSource source)
{
	if (pg_strcasecmp(newval, "auto") == 0 ||
		pg_strcasecmp(newval, "none") == 0 ||
		pg_strcasecmp(newval, "force") == 0)
	{
		return newval;
	}
	return NULL;
}


static const char *
assign_hashagg_compress_spill_files(const char *newval, bool doit, GucSource source)
{
	int			i;
	const char *val = newval;

	if (pg_strcasecmp(newval, "nothing") == 0)
		val = "none";

	i = bfz_string_to_compression(val);
	if (i == -1)
		return NULL;			/* fail */
	if (doit)
		gp_hashagg_compress_spill_files = i;
	return newval;				/* OK */
}

static const char *
assign_gp_workfile_compress_algorithm(const char *newval, bool doit, GucSource source)
{
	int			i = bfz_string_to_compression(newval);

	if (i == -1)
		return NULL;			/* fail */
	if (doit)
		gp_workfile_compress_algorithm = i;
	return newval;				/* OK */
}

static const char *
assign_gp_workfile_type_hashjoin(const char *newval, bool doit, GucSource source)
{
	ExecWorkFileType newtype = BFZ;

	if (!pg_strcasecmp(newval, "bfz"))
	{
		newtype = BFZ;
	}
	else if (!pg_strcasecmp(newval, "buffile"))
	{
		newtype = BUFFILE;
	}
	else
		return NULL;
	if (doit)
		gp_workfile_type_hashjoin = newtype;

	return newval;
}

static bool
assign_optimizer(bool newval, bool doit, GucSource source)
{
#ifndef USE_ORCA
	if (newval)
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				 errmsg("ORCA is not supported by this build")));
#endif

	if (!optimizer_control)
	{
		if (source >= PGC_S_INTERACTIVE)
		{
			ereport(ERROR,
					(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
					 errmsg("cannot change the value of \"optimizer\"")));
		}

		/* source == PGC_S_OVERRIDE means do it anyway, eg at xact abort */
		if (source != PGC_S_OVERRIDE)
		{
			return false;
		}
	}

	return true;
}

static bool
assign_codegen(bool newval, bool doit, GucSource source)
{
#ifndef USE_CODEGEN
	if (newval)
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				 errmsg("Code generation is not supported by this build")));
#endif

	return true;
}

static bool
assign_dispatch_log_stats(bool newval, bool doit, GucSource source)
{
	if (newval &&
		(log_parser_stats || log_planner_stats || log_executor_stats || log_statement_stats))
	{
		if (source >= PGC_S_INTERACTIVE)
			ereport(ERROR,
					(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
					 errmsg("cannot enable \"log_dispatch_stats\" when "
							"\"log_statement_stats\", "
							"\"log_parser_stats\", \"log_planner_stats\", "
							"or \"log_executor_stats\" is true")));
		/* source == PGC_S_OVERRIDE means do it anyway, eg at xact abort */
		else if (source != PGC_S_OVERRIDE)
			return false;
	}
	return true;
}

#ifdef USE_CONNECTEMC
static const char *
assign_connectemc_mode(const char *newval, bool doit, GucSource source)
{
	if (pg_strcasecmp(newval, "on") == 0)
	{
		if (doit)
		{
			gp_emcconnect_transport = EMCCONNECT_MODE_TYPE_ON;
		}
	}
	else if (pg_strcasecmp(newval, "local") == 0)
	{
		if (doit)
		{
			gp_emcconnect_transport = EMCCONNECT_MODE_TYPE_LOCAL;
		}
	}
	else if (pg_strcasecmp(newval, "remote") == 0)
	{
		if (doit)
		{
			gp_emcconnect_transport = EMCCONNECT_MODE_TYPE_REMOTE;
		}
	}
	else if (pg_strcasecmp(newval, "off") == 0)
	{
		if (doit)
		{
			gp_emcconnect_transport = EMCCONNECT_MODE_TYPE_OFF;
		}
	}
	else
		return NULL;			/* fail */
	return newval;				/* OK */
}
#endif


static const char *
assign_debug_dtm_action(const char *newval,
						bool doit, GucSource source)
{
	if (pg_strcasecmp(newval, "none") == 0)
	{
		if (doit)
			Debug_dtm_action = DEBUG_DTM_ACTION_NONE;
	}
	else if (pg_strcasecmp(newval, "delay") == 0)
	{
		if (doit)
			Debug_dtm_action = DEBUG_DTM_ACTION_DELAY;
	}
	else if (pg_strcasecmp(newval, "fail_begin_command") == 0)
	{
		if (doit)
			Debug_dtm_action = DEBUG_DTM_ACTION_FAIL_BEGIN_COMMAND;
	}
	else if (pg_strcasecmp(newval, "fail_end_command") == 0)
	{
		if (doit)
			Debug_dtm_action = DEBUG_DTM_ACTION_FAIL_END_COMMAND;
	}
	else if (pg_strcasecmp(newval, "panic_begin_command") == 0)
	{
		if (doit)
			Debug_dtm_action = DEBUG_DTM_ACTION_PANIC_BEGIN_COMMAND;
	}
	else
		return NULL;			/* fail */
	return newval;				/* OK */
}

static const char *
assign_debug_dtm_action_target(const char *newval,
							   bool doit, GucSource source)
{
	if (pg_strcasecmp(newval, "none") == 0)
	{
		if (doit)
			Debug_dtm_action_target = DEBUG_DTM_ACTION_TARGET_NONE;
	}
	else if (pg_strcasecmp(newval, "protocol") == 0)
	{
		if (doit)
			Debug_dtm_action_target = DEBUG_DTM_ACTION_TARGET_PROTOCOL;
	}
	else if (pg_strcasecmp(newval, "sql") == 0)
	{
		if (doit)
			Debug_dtm_action_target = DEBUG_DTM_ACTION_TARGET_SQL;
	}
	else
		return NULL;			/* fail */
	return newval;				/* OK */
}

/*
 * Malloc a new string representing current storage_opts.
 */
static char *
storageOptToString(void)
{
	StringInfoData buf;
	char	   *ret;
	const StdRdOptions *ao_opts = currentAOStorageOptions();

	initStringInfo(&buf);
	appendStringInfo(&buf, "%s=%s", SOPT_APPENDONLY,
					 ao_opts->appendonly ? "true" : "false");
	appendStringInfo(&buf, ",%s=%d,", SOPT_BLOCKSIZE,
					 ao_opts->blocksize);
	if (ao_opts->compresstype)
	{
		appendStringInfo(&buf, "%s=%s,", SOPT_COMPTYPE,
						 ao_opts->compresstype);
	}
	else
	{
		appendStringInfo(&buf, "%s=none,", SOPT_COMPTYPE);
	}

	/*
	 * MPP-14504: we seem to allow compresslevel > 0 even when compression is
	 * disabled.
	 */
	if (ao_opts->compresslevel > 0)
	{
		appendStringInfo(&buf, "%s=%d,", SOPT_COMPLEVEL,
						 ao_opts->compresslevel);
	}
	appendStringInfo(&buf, "%s=%s,", SOPT_CHECKSUM,
					 ao_opts->checksum ? "true" : "false");
	appendStringInfo(&buf, "%s=%s", SOPT_ORIENTATION,
					 ao_opts->columnstore ? "column" : "row");
	ret = strdup(buf.data);
	if (ret == NULL)
		elog(ERROR, "out of memory");
	pfree(buf.data);
	return ret;
}

/*
 * Parse new value of storage options.  Update both, the GUC and
 * global ao_storage_opts object.
 */
static const char *
assign_gp_default_storage_options(const char *newval,
								  bool doit, GucSource source)
{
	if (source == PGC_S_DEFAULT || newval[0] == '\0')
	{
		/*
		 * Reset/init case, newval = "none".
		 */
		if (doit)
			resetDefaultAOStorageOpts();
	}
	else
	{
		PG_TRY();
		{
			/* Value of "appendonly" option if one is specified. */
			bool		aovalue = false;
			StdRdOptions *newopts = (StdRdOptions *)
			palloc0(sizeof(StdRdOptions));
			Datum		newopts_datum = parseAOStorageOpts(newval, &aovalue);

			/*
			 * Perform identical validations as in case of options specified
			 * in a WITH() clause.
			 */
			resetAOStorageOpts(newopts);
			parse_validate_reloptions(newopts, newopts_datum,
									   /* validate */ true, RELKIND_RELATION);
			validateAppendOnlyRelOptions(
										 newopts->appendonly,
										 newopts->blocksize,
										 gp_safefswritesize,
										 newopts->compresslevel,
										 newopts->compresstype,
										 newopts->checksum,
										 RELKIND_RELATION,
										 newopts->columnstore);

			/*
			 * All validations succeeded, it is safe to udpate global
			 * appendonly storage options.
			 */
			if (doit)
			{
				newopts->appendonly = aovalue;
				setDefaultAOStorageOpts(newopts);
			}
		}
		PG_CATCH();
		{
			if (source >= PGC_S_INTERACTIVE)
				PG_RE_THROW();
			else
			{
				/*
				 * We are in the middle of backend / postmaster startup.  The
				 * configured value is bad, proceed with factory defaults.
				 */
				elog(WARNING, "Unable to set gp_default_storage_options to '%s'",
					 newval);
				resetDefaultAOStorageOpts();
			}
		}
		PG_END_TRY();
	}
	return doit ? storageOptToString() : newval;
}
