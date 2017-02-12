-- All GPDB-added functions are here, instead of pg_proc.h. pg_proc.h should
-- kept as close as possible to the upstream version, to make merging easier.
--
-- This file is translated into DATA rows by catullus.pl. See
-- README.add_catalog_function for instructions on how to run it.

 CREATE FUNCTION float4_decum(_float8, float4) RETURNS _float8 LANGUAGE internal IMMUTABLE STRICT AS 'float4_decum' WITH (OID=6024, DESCRIPTION="aggregate inverse transition function");
 CREATE FUNCTION float4_avg_accum(bytea, float4) RETURNS bytea LANGUAGE internal IMMUTABLE STRICT AS 'float4_avg_accum' WITH (OID=3106, DESCRIPTION="aggregate transition function");
 CREATE FUNCTION float4_avg_decum(bytea, float4) RETURNS bytea LANGUAGE internal IMMUTABLE STRICT AS 'float4_avg_decum' WITH (OID=3107, DESCRIPTION="aggregate inverse transition function");
 CREATE FUNCTION float8_decum(_float8, float8) RETURNS _float8 LANGUAGE internal IMMUTABLE STRICT AS 'float8_decum' WITH (OID=6025, DESCRIPTION="aggregate inverse transition function");
 CREATE FUNCTION float8_avg_accum(bytea, float8) RETURNS bytea LANGUAGE internal IMMUTABLE STRICT AS 'float8_avg_accum' WITH (OID=3108, DESCRIPTION="aggregate transition function");
 CREATE FUNCTION float8_avg_decum(bytea, float8) RETURNS bytea LANGUAGE internal IMMUTABLE STRICT AS 'float8_avg_decum' WITH (OID=3109, DESCRIPTION="aggregate inverse transition function");
 CREATE FUNCTION btgpxlogloccmp(gpxlogloc, gpxlogloc) RETURNS int4 LANGUAGE internal IMMUTABLE STRICT AS 'btgpxlogloccmp' WITH (OID=7081, DESCRIPTION="btree less-equal-greater");

-- MPP -- array_add -- special for prospective customer 
 CREATE FUNCTION array_add(_int4, _int4) RETURNS _int4 LANGUAGE internal IMMUTABLE STRICT AS 'array_int4_add' WITH (OID=6012, DESCRIPTION="itemwise add two integer arrays");

 CREATE FUNCTION array_agg_transfn(internal, anyelement) RETURNS internal LANGUAGE internal IMMUTABLE AS 'array_agg_transfn' WITH (OID=6096, DESCRIPTION="array_agg transition function");

 CREATE FUNCTION array_agg_finalfn(internal) RETURNS anyarray LANGUAGE internal IMMUTABLE AS 'array_agg_finalfn' WITH (OID=6097, DESCRIPTION="array_agg final function");

 CREATE FUNCTION array_agg(anyelement) RETURNS anyarray LANGUAGE internal IMMUTABLE AS 'aggregate_dummy' WITH (OID=6098, DESCRIPTION="concatenate aggregate input into an array", proisagg="t");

 CREATE FUNCTION string_agg_transfn(internal, text) RETURNS internal LANGUAGE internal IMMUTABLE AS 'string_agg_transfn' WITH (OID=3534, DESCRIPTION="string_agg(text) transition function");

 CREATE FUNCTION string_agg_delim_transfn(internal, text, text) RETURNS internal LANGUAGE internal IMMUTABLE AS 'string_agg_delim_transfn' WITH (OID=3535, DESCRIPTION="string_agg(text, text) transition function");

 CREATE FUNCTION string_agg_finalfn(internal) RETURNS text LANGUAGE internal IMMUTABLE AS 'string_agg_finalfn' WITH (OID=3536, DESCRIPTION="string_agg final function");

 CREATE FUNCTION string_agg(text) RETURNS text LANGUAGE internal IMMUTABLE AS 'aggregate_dummy' WITH (OID=3537, DESCRIPTION="concatenate aggregate input into an string", proisagg="t");

 CREATE FUNCTION string_agg(text, text) RETURNS text LANGUAGE internal IMMUTABLE AS 'aggregate_dummy' WITH (OID=3538, DESCRIPTION="concatenate aggregate input into an string with delimiter", proisagg="t");

 CREATE FUNCTION current_query() RETURNS text LANGUAGE internal VOLATILE AS 'current_query' WITH (OID=820, DESCRIPTION="returns the currently executing query");

 CREATE FUNCTION int8dec(int8) RETURNS int8 LANGUAGE internal IMMUTABLE STRICT AS 'int8dec' WITH (OID=3546);


 CREATE FUNCTION interval_interval_div("interval", "interval") RETURNS float8 LANGUAGE internal IMMUTABLE STRICT AS 'interval_interval_div' WITH (OID=6115, DESCRIPTION="divide");

 CREATE FUNCTION interval_interval_mod("interval", "interval") RETURNS "interval" LANGUAGE internal IMMUTABLE STRICT AS 'interval_interval_mod' WITH (OID=6116, DESCRIPTION="modulus");

-- System-view support functions 
 CREATE FUNCTION pg_get_partition_def(oid) RETURNS text LANGUAGE internal STABLE STRICT AS 'pg_get_partition_def' WITH (OID=5024);

 CREATE FUNCTION pg_get_partition_def(oid, bool) RETURNS text LANGUAGE internal STABLE STRICT AS 'pg_get_partition_def_ext' WITH (OID=5025, DESCRIPTION="partition configuration for a given relation");

 CREATE FUNCTION pg_get_partition_def(oid, bool, bool) RETURNS text LANGUAGE internal STABLE STRICT AS 'pg_get_partition_def_ext2' WITH (OID=5034, DESCRIPTION="partition configuration for a given relation");

 CREATE FUNCTION pg_get_partition_rule_def(oid) RETURNS text LANGUAGE internal STABLE STRICT AS 'pg_get_partition_rule_def' WITH (OID=5027);

 CREATE FUNCTION pg_get_partition_rule_def(oid, bool) RETURNS text LANGUAGE internal STABLE STRICT AS 'pg_get_partition_rule_def_ext' WITH (OID=5028, DESCRIPTION="partition configuration for a given rule");

 CREATE FUNCTION pg_get_partition_template_def(oid, bool, bool) RETURNS text LANGUAGE internal STABLE STRICT AS 'pg_get_partition_template_def' WITH (OID=5037, DESCRIPTION="ALTER statement to recreate subpartition templates for a give relation");

 CREATE FUNCTION pg_get_keywords(OUT word text, OUT catcode "char", OUT catdesc text) RETURNS SETOF pg_catalog.record LANGUAGE internal STABLE STRICT AS 'pg_get_keywords' WITH (OID=821, DESCRIPTION="list of SQL keywords");

 CREATE FUNCTION pg_typeof("any") RETURNS regtype LANGUAGE internal STABLE AS 'pg_typeof' WITH (OID=822, DESCRIPTION="returns the type of the argument");

 CREATE FUNCTION numeric_dec("numeric") RETURNS "numeric" LANGUAGE internal IMMUTABLE STRICT AS 'numeric_dec' WITH (OID=6997, DESCRIPTION="increment by one");


-- Sequences and time series
 CREATE FUNCTION interval_bound(numeric, numeric) RETURNS numeric LANGUAGE internal IMMUTABLE STRICT AS 'numeric_interval_bound' WITH (OID=2991, DESCRIPTION="boundary of the interval containing the given value");

 CREATE FUNCTION interval_bound(numeric, numeric, int4) RETURNS numeric LANGUAGE internal IMMUTABLE AS 'numeric_interval_bound_shift' WITH (OID=2992, DESCRIPTION="boundary of the interval containing the given value");

 CREATE FUNCTION interval_bound(numeric, numeric, int4, numeric) RETURNS numeric LANGUAGE internal IMMUTABLE AS 'numeric_interval_bound_shift_rbound' WITH (OID=2993, DESCRIPTION="boundary of the interval containing the given value");

 CREATE FUNCTION interval_bound(timestamp, "interval") RETURNS timestamp LANGUAGE internal IMMUTABLE STRICT AS 'timestamp_interval_bound' WITH (OID=2994, DESCRIPTION="boundary of the interval containing the given value");

 CREATE FUNCTION interval_bound(timestamp, "interval", int4) RETURNS timestamp LANGUAGE internal IMMUTABLE AS 'timestamp_interval_bound_shift' WITH (OID=2995, DESCRIPTION="boundary of the interval containing the given value");

 CREATE FUNCTION interval_bound(timestamp, "interval", int4, timestamp) RETURNS timestamp LANGUAGE internal IMMUTABLE AS 'timestamp_interval_bound_shift_reg' WITH (OID=2996, DESCRIPTION="boundary of the interval containing the given value");

 CREATE FUNCTION interval_bound(timestamptz, "interval") RETURNS timestamptz LANGUAGE internal IMMUTABLE STRICT AS 'timestamptz_interval_bound' WITH (OID=2997, DESCRIPTION="boundary of the interval containing the given value");

 CREATE FUNCTION interval_bound(timestamptz, "interval", int4) RETURNS timestamptz LANGUAGE internal IMMUTABLE AS 'timestamptz_interval_bound_shift' WITH (OID=2998, DESCRIPTION="boundary of the interval containing the given value");

 CREATE FUNCTION interval_bound(timestamptz, "interval", int4, timestamptz) RETURNS timestamptz LANGUAGE internal IMMUTABLE AS 'timestamptz_interval_bound_shift_reg' WITH (OID=2999, DESCRIPTION="boundary of the interval containing the given value");


-- Aggregate-related functions 
 CREATE FUNCTION numeric_avg_accum(bytea, "numeric") RETURNS bytea LANGUAGE internal IMMUTABLE STRICT AS 'numeric_avg_accum' WITH (OID=3102, DESCRIPTION="aggregate transition function");

 CREATE FUNCTION numeric_decum(_numeric, "numeric") RETURNS _numeric LANGUAGE internal IMMUTABLE STRICT AS 'numeric_decum' WITH (OID=7309, DESCRIPTION="aggregate inverse transition function");

 CREATE FUNCTION numeric_avg_decum(bytea, "numeric") RETURNS bytea LANGUAGE internal IMMUTABLE STRICT AS 'numeric_avg_decum' WITH (OID=3103, DESCRIPTION="aggregate inverse transition function");

 CREATE FUNCTION int2_decum(_numeric, int2) RETURNS _numeric LANGUAGE internal IMMUTABLE STRICT AS 'int2_decum' WITH (OID=7306, DESCRIPTION="aggregate inverse transition function");

 CREATE FUNCTION int4_decum(_numeric, int4) RETURNS _numeric LANGUAGE internal IMMUTABLE STRICT AS 'int4_decum' WITH (OID=7307, DESCRIPTION="aggregate inverse transition function");

 CREATE FUNCTION int8_decum(_numeric, int8) RETURNS _numeric LANGUAGE internal IMMUTABLE STRICT AS 'int8_decum' WITH (OID=7308, DESCRIPTION="aggregate inverse transition function");

 CREATE FUNCTION int2_invsum(int8, int2) RETURNS int8 LANGUAGE internal IMMUTABLE AS 'int2_invsum' WITH (OID=7008, DESCRIPTION="SUM(int2) inverse transition function");

 CREATE FUNCTION int4_invsum(int8, int4) RETURNS int8 LANGUAGE internal IMMUTABLE AS 'int4_invsum' WITH (OID=7009, DESCRIPTION="SUM(int4) inverse transition function");

 CREATE FUNCTION int8_invsum("numeric", int8) RETURNS "numeric" LANGUAGE internal IMMUTABLE AS 'int8_invsum' WITH (OID=7010, DESCRIPTION="SUM(int8) inverse transition function");

 CREATE FUNCTION interval_decum(_interval, "interval") RETURNS _interval LANGUAGE internal IMMUTABLE STRICT AS 'interval_decum' WITH (OID=6038, DESCRIPTION="aggregate inverse transition function");

 CREATE FUNCTION int8_avg_accum(bytea, int8) RETURNS bytea LANGUAGE internal IMMUTABLE STRICT AS 'int8_avg_accum' WITH (OID=3100, DESCRIPTION="AVG(int8) transition function");

 CREATE FUNCTION int2_avg_decum(bytea, int2) RETURNS bytea LANGUAGE internal IMMUTABLE STRICT AS 'int2_avg_decum' WITH (OID=6019, DESCRIPTION="AVG(int2) transition function");

 CREATE FUNCTION int4_avg_decum(bytea, int4) RETURNS bytea LANGUAGE internal IMMUTABLE STRICT AS 'int4_avg_decum' WITH (OID=6020, DESCRIPTION="AVG(int4) transition function");

 CREATE FUNCTION int8_avg_decum(bytea, int8) RETURNS bytea LANGUAGE internal IMMUTABLE STRICT AS 'int8_avg_decum' WITH (OID=3101, DESCRIPTION="AVG(int8) transition function");


 CREATE FUNCTION pg_partition_oid_transfn(internal, oid, record) RETURNS internal LANGUAGE internal IMMUTABLE AS 'pg_partition_oid_transfn' WITH (OID=6099, DESCRIPTION="pg_partition_oid transition function");

 CREATE FUNCTION pg_partition_oid_finalfn(internal) RETURNS _oid LANGUAGE internal IMMUTABLE AS 'pg_partition_oid_finalfn' WITH (OID=6100, DESCRIPTION="pg_partition_oid final function");

 CREATE FUNCTION pg_partition_oid(oid, record) RETURNS _oid LANGUAGE internal IMMUTABLE AS 'aggregate_dummy' WITH (OID=6112, proisagg="t");
-- #define PG_PARTITION_OID_OID 6112

 CREATE FUNCTION pg_stat_get_backend_waiting_reason(int4) RETURNS text LANGUAGE internal STABLE STRICT AS 'pg_stat_get_backend_waiting_reason' WITH (OID=2897, DESCRIPTION="Statistics: Reason backend is waiting for");

 CREATE FUNCTION pg_stat_get_queue_num_exec(oid) RETURNS int8 LANGUAGE internal STABLE STRICT AS 'pg_stat_get_queue_num_exec' WITH (OID=6031, DESCRIPTION="Statistics: Number of queries that executed in queue");

 CREATE FUNCTION pg_stat_get_queue_num_wait(oid) RETURNS int8 LANGUAGE internal STABLE STRICT AS 'pg_stat_get_queue_num_wait' WITH (OID=6032, DESCRIPTION="Statistics: Number of queries that waited in queue");

 CREATE FUNCTION pg_stat_get_queue_elapsed_exec(oid) RETURNS int8 LANGUAGE internal STABLE STRICT AS 'pg_stat_get_queue_elapsed_exec' WITH (OID=6033, DESCRIPTION="Statistics:  Elapsed seconds for queries that executed in queue");

 CREATE FUNCTION pg_stat_get_queue_elapsed_wait(oid) RETURNS int8 LANGUAGE internal STABLE STRICT AS 'pg_stat_get_queue_elapsed_wait' WITH (OID=6034, DESCRIPTION="Statistics:  Elapsed seconds for queries that waited in queue");

 CREATE FUNCTION pg_stat_get_backend_session_id(int4) RETURNS int4 LANGUAGE internal STABLE STRICT AS 'pg_stat_get_backend_session_id' WITH (OID=6039, DESCRIPTION="Statistics: Greenplum session id of backend");

 CREATE FUNCTION pg_renice_session(int4, int4) RETURNS int4 LANGUAGE internal VOLATILE STRICT AS 'pg_renice_session' WITH (OID=6042, DESCRIPTION="change priority of all the backends for a given session id");

 CREATE FUNCTION pg_stat_get_activity(IN pid int4, OUT datid oid, OUT procpid int4, OUT usesysid oid, OUT application_name text, OUT current_query text, OUT waiting bool, OUT xact_start timestamptz, OUT query_start timestamptz, OUT backend_start timestamptz, OUT client_addr inet, OUT client_port int4, OUT sess_id int4, OUT waiting_reason text) RETURNS SETOF pg_catalog.record LANGUAGE internal VOLATILE AS 'pg_stat_get_activity' WITH (OID=6071, DESCRIPTION="statistics: information about currently active backends");

 CREATE FUNCTION pg_stat_get_wal_senders(OUT pid int4, OUT state text, OUT sent_location text, OUT write_location text, OUT flush_location text, OUT replay_location text, OUT sync_priority int4, OUT sync_state text) RETURNS SETOF pg_catalog.record LANGUAGE internal STABLE AS 'pg_stat_get_wal_senders' WITH (OID=3099, DESCRIPTION="statistics: information about currently active replication");

 CREATE FUNCTION pg_terminate_backend(int4) RETURNS bool LANGUAGE internal VOLATILE STRICT AS 'pg_terminate_backend' WITH (OID=6118, DESCRIPTION="terminate a server process");

 CREATE FUNCTION pg_resqueue_status() RETURNS SETOF record LANGUAGE internal VOLATILE STRICT AS 'pg_resqueue_status' WITH (OID=6030, DESCRIPTION="Return resource queue information");

 CREATE FUNCTION pg_resqueue_status_kv() RETURNS SETOF record LANGUAGE internal VOLATILE STRICT AS 'pg_resqueue_status_kv' WITH (OID=6069, DESCRIPTION="Return resource queue information");

 CREATE FUNCTION pg_file_read(text, int8, int8) RETURNS text LANGUAGE internal VOLATILE STRICT AS 'pg_read_file' WITH (OID=6045, DESCRIPTION="Read text from a file");

 CREATE FUNCTION pg_logfile_rotate() RETURNS bool LANGUAGE internal VOLATILE STRICT AS 'pg_rotate_logfile' WITH (OID=6046, DESCRIPTION="Rotate log file");

 CREATE FUNCTION pg_file_write(text, text, bool) RETURNS int8 LANGUAGE internal VOLATILE STRICT AS 'pg_file_write' WITH (OID=6047, DESCRIPTION="Write text to a file");

 CREATE FUNCTION pg_file_rename(text, text, text) RETURNS bool LANGUAGE internal VOLATILE AS 'pg_file_rename' WITH (OID=6048, DESCRIPTION="Rename a file");

 CREATE FUNCTION pg_file_unlink(text) RETURNS bool LANGUAGE internal VOLATILE STRICT AS 'pg_file_unlink' WITH (OID=6049, DESCRIPTION="Delete (unlink) a file");

 CREATE FUNCTION pg_logdir_ls() RETURNS SETOF record LANGUAGE internal VOLATILE STRICT AS 'pg_logdir_ls' WITH (OID=6050, DESCRIPTION="ls the log dir");

 CREATE FUNCTION pg_file_length(text) RETURNS int8 LANGUAGE internal VOLATILE STRICT AS 'pg_file_length' WITH (OID=6051, DESCRIPTION="Get the length of a file (via stat)");

-- Aggregates (moved here from pg_aggregate for 7.3) 

 CREATE FUNCTION max(gpxlogloc) RETURNS gpxlogloc LANGUAGE internal IMMUTABLE AS 'aggregate_dummy' WITH (OID=3332, proisagg="t");

 CREATE FUNCTION min(gpxlogloc) RETURNS gpxlogloc LANGUAGE internal IMMUTABLE AS 'aggregate_dummy' WITH (OID=3333, proisagg="t");

-- MPP Aggregate -- array_sum -- special for prospective customer. 
 CREATE FUNCTION array_sum(_int4) RETURNS _int4 LANGUAGE internal IMMUTABLE AS 'aggregate_dummy' WITH (OID=6013, proisagg="t");

-- Window functions (similar to aggregates) 
 CREATE FUNCTION row_number() RETURNS int8 LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7000, proiswin="t");
-- #define ROW_NUMBER_OID 7000
-- #define ROW_NUMBER_TYPE 20

 CREATE FUNCTION rank() RETURNS int8 LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7001, proiswin="t");

 CREATE FUNCTION dense_rank() RETURNS int8 LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7002, proiswin="t");

 CREATE FUNCTION percent_rank() RETURNS float8 LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7003, proiswin="t");

 CREATE FUNCTION cume_dist() RETURNS float8 LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7004, proiswin="t");
-- #define CUME_DIST_OID 7004

 CREATE FUNCTION ntile(int4) RETURNS int8 LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7005, proiswin="t");

 CREATE FUNCTION ntile(int8) RETURNS int8 LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7006, proiswin="t");

 CREATE FUNCTION ntile("numeric") RETURNS int8 LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7007, proiswin="t");

--  XXX for now, window functions with arguments, just cite numeric = 1700, need to overload. 
 CREATE FUNCTION first_value(bool) RETURNS bool LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7017, proiswin="t");

 CREATE FUNCTION first_value("char") RETURNS "char" LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7018, proiswin="t");

 CREATE FUNCTION first_value(cidr) RETURNS cidr LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7019, proiswin="t");

 CREATE FUNCTION first_value(circle) RETURNS circle LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7020, proiswin="t");

 CREATE FUNCTION first_value(float4) RETURNS float4 LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7021, proiswin="t");

 CREATE FUNCTION first_value(float8) RETURNS float8 LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7022, proiswin="t");

 CREATE FUNCTION first_value(inet) RETURNS inet LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7023, proiswin="t");

 CREATE FUNCTION first_value("interval") RETURNS "interval" LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7024, proiswin="t");

 CREATE FUNCTION first_value(line) RETURNS line LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7025, proiswin="t");

 CREATE FUNCTION first_value(lseg) RETURNS lseg LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7026, proiswin="t");

 CREATE FUNCTION first_value(macaddr) RETURNS macaddr LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7027, proiswin="t");

 CREATE FUNCTION first_value(int2) RETURNS int2 LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7028, proiswin="t");

 CREATE FUNCTION first_value(int4) RETURNS int4 LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7029, proiswin="t");

 CREATE FUNCTION first_value(int8) RETURNS int8 LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7030, proiswin="t");

 CREATE FUNCTION first_value(money) RETURNS money LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7031, proiswin="t");

 CREATE FUNCTION first_value(name) RETURNS name LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7032, proiswin="t");

 CREATE FUNCTION first_value("numeric") RETURNS "numeric" LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7033, proiswin="t");

 CREATE FUNCTION first_value(oid) RETURNS oid LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7034, proiswin="t");

 CREATE FUNCTION first_value(path) RETURNS path LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7035, proiswin="t");

 CREATE FUNCTION first_value(point) RETURNS point LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7036, proiswin="t");

 CREATE FUNCTION first_value(polygon) RETURNS polygon LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7037, proiswin="t");

 CREATE FUNCTION first_value(reltime) RETURNS reltime LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7038, proiswin="t");

 CREATE FUNCTION first_value(text) RETURNS text LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7039, proiswin="t");

 CREATE FUNCTION first_value(tid) RETURNS tid LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7040, proiswin="t");

 CREATE FUNCTION first_value("time") RETURNS "time" LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7041, proiswin="t");

 CREATE FUNCTION first_value("timestamp") RETURNS "timestamp" LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7042, proiswin="t");

 CREATE FUNCTION first_value(timestamptz) RETURNS timestamptz LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7043, proiswin="t");

 CREATE FUNCTION first_value(timetz) RETURNS timetz LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7044, proiswin="t");

 CREATE FUNCTION first_value(varbit) RETURNS varbit LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7045, proiswin="t");

 CREATE FUNCTION first_value("varchar") RETURNS "varchar" LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7046, proiswin="t");

 CREATE FUNCTION first_value(xid) RETURNS xid LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7047, proiswin="t");

 CREATE FUNCTION first_value(bytea) RETURNS bytea LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7232, proiswin="t");

 CREATE FUNCTION first_value("bit") RETURNS "bit" LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7256, proiswin="t");

 CREATE FUNCTION first_value(box) RETURNS box LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7272, proiswin="t");

 CREATE FUNCTION first_value(anyarray) RETURNS anyarray LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7288, proiswin="t");

 CREATE FUNCTION last_value(int4) RETURNS int4 LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7012, proiswin="t");

 CREATE FUNCTION last_value(int2) RETURNS int2 LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7013, proiswin="t");

 CREATE FUNCTION last_value(int8) RETURNS int8 LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7014, proiswin="t");

 CREATE FUNCTION last_value("numeric") RETURNS "numeric" LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7015, proiswin="t");

 CREATE FUNCTION last_value(text) RETURNS text LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7016, proiswin="t");

 CREATE FUNCTION last_value(bool) RETURNS bool LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7063, proiswin="t");

 CREATE FUNCTION last_value("char") RETURNS "char" LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7072, proiswin="t");

 CREATE FUNCTION last_value(cidr) RETURNS cidr LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7073, proiswin="t");

 CREATE FUNCTION last_value(circle) RETURNS circle LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7048, proiswin="t");

 CREATE FUNCTION last_value(float4) RETURNS float4 LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7049, proiswin="t");

 CREATE FUNCTION last_value(float8) RETURNS float8 LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7050, proiswin="t");

 CREATE FUNCTION last_value(inet) RETURNS inet LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7051, proiswin="t");

 CREATE FUNCTION last_value("interval") RETURNS "interval" LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7052, proiswin="t");

 CREATE FUNCTION last_value(line) RETURNS line LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7053, proiswin="t");

 CREATE FUNCTION last_value(lseg) RETURNS lseg LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7054, proiswin="t");

 CREATE FUNCTION last_value(macaddr) RETURNS macaddr LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7055, proiswin="t");

 CREATE FUNCTION last_value(money) RETURNS money LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7056, proiswin="t");

 CREATE FUNCTION last_value(name) RETURNS name LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7057, proiswin="t");

 CREATE FUNCTION last_value(oid) RETURNS oid LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7058, proiswin="t");

 CREATE FUNCTION last_value(path) RETURNS path LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7059, proiswin="t");

 CREATE FUNCTION last_value(point) RETURNS point LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7060, proiswin="t");

 CREATE FUNCTION last_value(polygon) RETURNS polygon LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7061, proiswin="t");

 CREATE FUNCTION last_value(reltime) RETURNS reltime LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7062, proiswin="t");

 CREATE FUNCTION last_value(tid) RETURNS tid LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7064, proiswin="t");

 CREATE FUNCTION last_value("time") RETURNS "time" LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7065, proiswin="t");

 CREATE FUNCTION last_value("timestamp") RETURNS "timestamp" LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7066, proiswin="t");

 CREATE FUNCTION last_value(timestamptz) RETURNS timestamptz LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7067, proiswin="t");

 CREATE FUNCTION last_value(timetz) RETURNS timetz LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7068, proiswin="t");

 CREATE FUNCTION last_value(varbit) RETURNS varbit LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7069, proiswin="t");

 CREATE FUNCTION last_value("varchar") RETURNS "varchar" LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7070, proiswin="t");

 CREATE FUNCTION last_value(xid) RETURNS xid LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7071, proiswin="t");

 CREATE FUNCTION last_value(bytea) RETURNS bytea LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7238, proiswin="t");

 CREATE FUNCTION last_value("bit") RETURNS "bit" LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7258, proiswin="t");

 CREATE FUNCTION last_value(box) RETURNS box LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7274, proiswin="t");

 CREATE FUNCTION last_value(anyarray) RETURNS anyarray LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7290, proiswin="t");

 CREATE FUNCTION lag(bool, int8, bool) RETURNS bool LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7675, proiswin="t");

 CREATE FUNCTION lag(bool, int8) RETURNS bool LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7491, proiswin="t");

 CREATE FUNCTION lag(bool) RETURNS bool LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7493, proiswin="t");

 CREATE FUNCTION lag("char", int8, "char") RETURNS "char" LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7495, proiswin="t");

 CREATE FUNCTION lag("char", int8) RETURNS "char" LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7497, proiswin="t");

 CREATE FUNCTION lag("char") RETURNS "char" LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7499, proiswin="t");

 CREATE FUNCTION lag(cidr, int8, cidr) RETURNS cidr LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7501, proiswin="t");

 CREATE FUNCTION lag(cidr, int8) RETURNS cidr LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7503, proiswin="t");

 CREATE FUNCTION lag(cidr) RETURNS cidr LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7505, proiswin="t");

 CREATE FUNCTION lag(circle, int8, circle) RETURNS circle LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7507, proiswin="t");

 CREATE FUNCTION lag(circle, int8) RETURNS circle LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7509, proiswin="t");

 CREATE FUNCTION lag(circle) RETURNS circle LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7511, proiswin="t");

 CREATE FUNCTION lag(float4, int8, float4) RETURNS float4 LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7513, proiswin="t");

 CREATE FUNCTION lag(float4, int8) RETURNS float4 LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7515, proiswin="t");

 CREATE FUNCTION lag(float4) RETURNS float4 LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7517, proiswin="t");

 CREATE FUNCTION lag(float8, int8, float8) RETURNS float8 LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7519, proiswin="t");

 CREATE FUNCTION lag(float8, int8) RETURNS float8 LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7521, proiswin="t");

 CREATE FUNCTION lag(float8) RETURNS float8 LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7523, proiswin="t");

 CREATE FUNCTION lag(inet, int8, inet) RETURNS inet LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7525, proiswin="t");

 CREATE FUNCTION lag(inet, int8) RETURNS inet LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7527, proiswin="t");

 CREATE FUNCTION lag(inet) RETURNS inet LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7529, proiswin="t");

 CREATE FUNCTION lag("interval", int8, "interval") RETURNS "interval" LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7531, proiswin="t");

 CREATE FUNCTION lag("interval", int8) RETURNS "interval" LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7533, proiswin="t");

 CREATE FUNCTION lag("interval") RETURNS "interval" LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7535, proiswin="t");

 CREATE FUNCTION lag(line, int8, line) RETURNS line LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7537, proiswin="t");

 CREATE FUNCTION lag(line, int8) RETURNS line LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7539, proiswin="t");

 CREATE FUNCTION lag(line) RETURNS line LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7541, proiswin="t");

 CREATE FUNCTION lag(lseg, int8, lseg) RETURNS lseg LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7543, proiswin="t");

 CREATE FUNCTION lag(lseg, int8) RETURNS lseg LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7545, proiswin="t");

 CREATE FUNCTION lag(lseg) RETURNS lseg LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7547, proiswin="t");

 CREATE FUNCTION lag(macaddr, int8, macaddr) RETURNS macaddr LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7549, proiswin="t");

 CREATE FUNCTION lag(macaddr, int8) RETURNS macaddr LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7551, proiswin="t");

 CREATE FUNCTION lag(macaddr) RETURNS macaddr LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7553, proiswin="t");

 CREATE FUNCTION lag(int2, int8, int2) RETURNS int2 LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7555, proiswin="t");

 CREATE FUNCTION lag(int2, int8) RETURNS int2 LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7557, proiswin="t");

 CREATE FUNCTION lag(int2) RETURNS int2 LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7559, proiswin="t");

 CREATE FUNCTION lag(int4, int8, int4) RETURNS int4 LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7561, proiswin="t");

 CREATE FUNCTION lag(int4, int8) RETURNS int4 LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7563, proiswin="t");

 CREATE FUNCTION lag(int4) RETURNS int4 LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7565, proiswin="t");

 CREATE FUNCTION lag(int8, int8, int8) RETURNS int8 LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7567, proiswin="t");

 CREATE FUNCTION lag(int8, int8) RETURNS int8 LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7569, proiswin="t");

 CREATE FUNCTION lag(int8) RETURNS int8 LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7571, proiswin="t");

 CREATE FUNCTION lag(money, int8, money) RETURNS money LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7573, proiswin="t");

 CREATE FUNCTION lag(money, int8) RETURNS money LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7575, proiswin="t");

 CREATE FUNCTION lag(money) RETURNS money LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7577, proiswin="t");

 CREATE FUNCTION lag(name, int8, name) RETURNS name LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7579, proiswin="t");

 CREATE FUNCTION lag(name, int8) RETURNS name LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7581, proiswin="t");

 CREATE FUNCTION lag(name) RETURNS name LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7583, proiswin="t");

 CREATE FUNCTION lag("numeric", int8, "numeric") RETURNS "numeric" LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7585, proiswin="t");

 CREATE FUNCTION lag("numeric", int8) RETURNS "numeric" LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7587, proiswin="t");

 CREATE FUNCTION lag("numeric") RETURNS "numeric" LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7589, proiswin="t");

 CREATE FUNCTION lag(oid, int8, oid) RETURNS oid LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7591, proiswin="t");

 CREATE FUNCTION lag(oid, int8) RETURNS oid LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7593, proiswin="t");

 CREATE FUNCTION lag(oid) RETURNS oid LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7595, proiswin="t");

 CREATE FUNCTION lag(path, int8, path) RETURNS path LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7597, proiswin="t");

 CREATE FUNCTION lag(path, int8) RETURNS path LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7599, proiswin="t");

 CREATE FUNCTION lag(path) RETURNS path LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7601, proiswin="t");

 CREATE FUNCTION lag(point, int8, point) RETURNS point LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7603, proiswin="t");

 CREATE FUNCTION lag(point, int8) RETURNS point LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7605, proiswin="t");

 CREATE FUNCTION lag(point) RETURNS point LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7607, proiswin="t");

 CREATE FUNCTION lag(polygon, int8, polygon) RETURNS polygon LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7609, proiswin="t");

 CREATE FUNCTION lag(polygon, int8) RETURNS polygon LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7611, proiswin="t");

 CREATE FUNCTION lag(polygon) RETURNS polygon LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7613, proiswin="t");

 CREATE FUNCTION lag(reltime, int8, reltime) RETURNS reltime LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7615, proiswin="t");

 CREATE FUNCTION lag(reltime, int8) RETURNS reltime LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7617, proiswin="t");

 CREATE FUNCTION lag(reltime) RETURNS reltime LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7619, proiswin="t");

 CREATE FUNCTION lag(text, int8, text) RETURNS text LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7621, proiswin="t");

 CREATE FUNCTION lag(text, int8) RETURNS text LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7623, proiswin="t");

 CREATE FUNCTION lag(text) RETURNS text LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7625, proiswin="t");

 CREATE FUNCTION lag(tid, int8, tid) RETURNS tid LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7627, proiswin="t");

 CREATE FUNCTION lag(tid, int8) RETURNS tid LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7629, proiswin="t");

 CREATE FUNCTION lag(tid) RETURNS tid LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7631, proiswin="t");

 CREATE FUNCTION lag("time", int8, "time") RETURNS "time" LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7633, proiswin="t");

 CREATE FUNCTION lag("time", int8) RETURNS "time" LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7635, proiswin="t");

 CREATE FUNCTION lag("time") RETURNS "time" LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7637, proiswin="t");

 CREATE FUNCTION lag("timestamp", int8, "timestamp") RETURNS "timestamp" LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7639, proiswin="t");

 CREATE FUNCTION lag("timestamp", int8) RETURNS "timestamp" LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7641, proiswin="t");

 CREATE FUNCTION lag("timestamp") RETURNS "timestamp" LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7643, proiswin="t");

 CREATE FUNCTION lag(timestamptz, int8, timestamptz) RETURNS timestamptz LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7645, proiswin="t");

 CREATE FUNCTION lag(timestamptz, int8) RETURNS timestamptz LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7647, proiswin="t");

 CREATE FUNCTION lag(timestamptz) RETURNS timestamptz LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7649, proiswin="t");

 CREATE FUNCTION lag(timetz, int8, timetz) RETURNS timetz LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7651, proiswin="t");

 CREATE FUNCTION lag(timetz, int8) RETURNS timetz LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7653, proiswin="t");

 CREATE FUNCTION lag(timetz) RETURNS timetz LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7655, proiswin="t");

 CREATE FUNCTION lag(varbit, int8, varbit) RETURNS varbit LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7657, proiswin="t");

 CREATE FUNCTION lag(varbit, int8) RETURNS varbit LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7659, proiswin="t");

 CREATE FUNCTION lag(varbit) RETURNS varbit LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7661, proiswin="t");

 CREATE FUNCTION lag("varchar", int8, "varchar") RETURNS "varchar" LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7663, proiswin="t");

 CREATE FUNCTION lag("varchar", int8) RETURNS "varchar" LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7665, proiswin="t");

 CREATE FUNCTION lag("varchar") RETURNS "varchar" LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7667, proiswin="t");

 CREATE FUNCTION lag(xid, int8, xid) RETURNS xid LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7669, proiswin="t");

 CREATE FUNCTION lag(xid, int8) RETURNS xid LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7671, proiswin="t");

 CREATE FUNCTION lag(xid) RETURNS xid LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7673, proiswin="t");

 CREATE FUNCTION lag(anyarray, int8, anyarray) RETURNS anyarray LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7211, proiswin="t");

 CREATE FUNCTION lag(anyarray, int8) RETURNS anyarray LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7212, proiswin="t");

 CREATE FUNCTION lag(anyarray) RETURNS anyarray LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7213, proiswin="t");

 CREATE FUNCTION lag(bytea) RETURNS bytea LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7226, proiswin="t");

 CREATE FUNCTION lag(bytea, int8) RETURNS bytea LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7228, proiswin="t");

 CREATE FUNCTION lag(bytea, int8, bytea) RETURNS bytea LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7230, proiswin="t");

 CREATE FUNCTION lag("bit") RETURNS "bit" LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7250, proiswin="t");

 CREATE FUNCTION lag("bit", int8) RETURNS "bit" LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7252, proiswin="t");

 CREATE FUNCTION lag("bit", int8, "bit") RETURNS "bit" LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7254, proiswin="t");

 CREATE FUNCTION lag(box) RETURNS box LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7266, proiswin="t");

 CREATE FUNCTION lag(box, int8) RETURNS box LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7268, proiswin="t");

 CREATE FUNCTION lag(box, int8, box) RETURNS box LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7270, proiswin="t");

 CREATE FUNCTION lead(int4, int8, int4) RETURNS int4 LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7011, proiswin="t");

 CREATE FUNCTION lead(int4, int8) RETURNS int4 LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7074, proiswin="t");

 CREATE FUNCTION lead(int4) RETURNS int4 LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7075, proiswin="t");

 CREATE FUNCTION lead(bool, int8, bool) RETURNS bool LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7310, proiswin="t");

 CREATE FUNCTION lead(bool, int8) RETURNS bool LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7312, proiswin="t");

 CREATE FUNCTION lead(bool) RETURNS bool LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7314, proiswin="t");

 CREATE FUNCTION lead("char", int8, "char") RETURNS "char" LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7316, proiswin="t");

 CREATE FUNCTION lead("char", int8) RETURNS "char" LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7318, proiswin="t");

 CREATE FUNCTION lead("char") RETURNS "char" LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7320, proiswin="t");

 CREATE FUNCTION lead(cidr, int8, cidr) RETURNS cidr LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7322, proiswin="t");

 CREATE FUNCTION lead(cidr, int8) RETURNS cidr LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7324, proiswin="t");

 CREATE FUNCTION lead(cidr) RETURNS cidr LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7326, proiswin="t");

 CREATE FUNCTION lead(circle, int8, circle) RETURNS circle LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7328, proiswin="t");

 CREATE FUNCTION lead(circle, int8) RETURNS circle LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7330, proiswin="t");

 CREATE FUNCTION lead(circle) RETURNS circle LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7332, proiswin="t");

 CREATE FUNCTION lead(float4, int8, float4) RETURNS float4 LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7334, proiswin="t");

 CREATE FUNCTION lead(float4, int8) RETURNS float4 LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7336, proiswin="t");

 CREATE FUNCTION lead(float4) RETURNS float4 LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7338, proiswin="t");

 CREATE FUNCTION lead(float8, int8, float8) RETURNS float8 LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7340, proiswin="t");

 CREATE FUNCTION lead(float8, int8) RETURNS float8 LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7342, proiswin="t");

 CREATE FUNCTION lead(float8) RETURNS float8 LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7344, proiswin="t");

 CREATE FUNCTION lead(inet, int8, inet) RETURNS inet LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7346, proiswin="t");

 CREATE FUNCTION lead(inet, int8) RETURNS inet LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7348, proiswin="t");

 CREATE FUNCTION lead(inet) RETURNS inet LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7350, proiswin="t");

 CREATE FUNCTION lead("interval", int8, "interval") RETURNS "interval" LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7352, proiswin="t");

 CREATE FUNCTION lead("interval", int8) RETURNS "interval" LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7354, proiswin="t");

 CREATE FUNCTION lead("interval") RETURNS "interval" LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7356, proiswin="t");

 CREATE FUNCTION lead(line, int8, line) RETURNS line LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7358, proiswin="t");

 CREATE FUNCTION lead(line, int8) RETURNS line LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7360, proiswin="t");

 CREATE FUNCTION lead(line) RETURNS line LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7362, proiswin="t");

 CREATE FUNCTION lead(lseg, int8, lseg) RETURNS lseg LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7364, proiswin="t");

 CREATE FUNCTION lead(lseg, int8) RETURNS lseg LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7366, proiswin="t");

 CREATE FUNCTION lead(lseg) RETURNS lseg LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7368, proiswin="t");

 CREATE FUNCTION lead(macaddr, int8, macaddr) RETURNS macaddr LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7370, proiswin="t");

 CREATE FUNCTION lead(macaddr, int8) RETURNS macaddr LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7372, proiswin="t");

 CREATE FUNCTION lead(macaddr) RETURNS macaddr LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7374, proiswin="t");

 CREATE FUNCTION lead(int2, int8, int2) RETURNS int2 LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7376, proiswin="t");

 CREATE FUNCTION lead(int2, int8) RETURNS int2 LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7378, proiswin="t");

 CREATE FUNCTION lead(int2) RETURNS int2 LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7380, proiswin="t");

 CREATE FUNCTION lead(int8, int8, int8) RETURNS int8 LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7382, proiswin="t");

 CREATE FUNCTION lead(int8, int8) RETURNS int8 LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7384, proiswin="t");

 CREATE FUNCTION lead(int8) RETURNS int8 LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7386, proiswin="t");

 CREATE FUNCTION lead(money, int8, money) RETURNS money LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7388, proiswin="t");

 CREATE FUNCTION lead(money, int8) RETURNS money LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7390, proiswin="t");

 CREATE FUNCTION lead(money) RETURNS money LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7392, proiswin="t");

 CREATE FUNCTION lead(name, int8, name) RETURNS name LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7394, proiswin="t");

 CREATE FUNCTION lead(name, int8) RETURNS name LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7396, proiswin="t");

 CREATE FUNCTION lead(name) RETURNS name LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7398, proiswin="t");

 CREATE FUNCTION lead("numeric", int8, "numeric") RETURNS "numeric" LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7400, proiswin="t");

 CREATE FUNCTION lead("numeric", int8) RETURNS "numeric" LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7402, proiswin="t");

 CREATE FUNCTION lead("numeric") RETURNS "numeric" LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7404, proiswin="t");

 CREATE FUNCTION lead(oid, int8, oid) RETURNS oid LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7406, proiswin="t");

 CREATE FUNCTION lead(oid, int8) RETURNS oid LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7408, proiswin="t");

 CREATE FUNCTION lead(oid) RETURNS oid LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7410, proiswin="t");

 CREATE FUNCTION lead(path, int8, path) RETURNS path LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7412, proiswin="t");

 CREATE FUNCTION lead(path, int8) RETURNS path LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7414, proiswin="t");

 CREATE FUNCTION lead(path) RETURNS path LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7416, proiswin="t");

 CREATE FUNCTION lead(point, int8, point) RETURNS point LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7418, proiswin="t");

 CREATE FUNCTION lead(point, int8) RETURNS point LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7420, proiswin="t");

 CREATE FUNCTION lead(point) RETURNS point LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7422, proiswin="t");

 CREATE FUNCTION lead(polygon, int8, polygon) RETURNS polygon LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7424, proiswin="t");

 CREATE FUNCTION lead(polygon, int8) RETURNS polygon LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7426, proiswin="t");

 CREATE FUNCTION lead(polygon) RETURNS polygon LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7428, proiswin="t");

 CREATE FUNCTION lead(reltime, int8, reltime) RETURNS reltime LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7430, proiswin="t");

 CREATE FUNCTION lead(reltime, int8) RETURNS reltime LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7432, proiswin="t");

 CREATE FUNCTION lead(reltime) RETURNS reltime LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7434, proiswin="t");

 CREATE FUNCTION lead(text, int8, text) RETURNS text LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7436, proiswin="t");

 CREATE FUNCTION lead(text, int8) RETURNS text LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7438, proiswin="t");

 CREATE FUNCTION lead(text) RETURNS text LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7440, proiswin="t");

 CREATE FUNCTION lead(tid, int8, tid) RETURNS tid LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7442, proiswin="t");

 CREATE FUNCTION lead(tid, int8) RETURNS tid LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7444, proiswin="t");

 CREATE FUNCTION lead(tid) RETURNS tid LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7446, proiswin="t");

 CREATE FUNCTION lead("time", int8, "time") RETURNS "time" LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7448, proiswin="t");

 CREATE FUNCTION lead("time", int8) RETURNS "time" LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7450, proiswin="t");

 CREATE FUNCTION lead("time") RETURNS "time" LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7452, proiswin="t");

 CREATE FUNCTION lead("timestamp", int8, "timestamp") RETURNS "timestamp" LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7454, proiswin="t");

 CREATE FUNCTION lead("timestamp", int8) RETURNS "timestamp" LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7456, proiswin="t");

 CREATE FUNCTION lead("timestamp") RETURNS "timestamp" LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7458, proiswin="t");

 CREATE FUNCTION lead(timestamptz, int8, timestamptz) RETURNS timestamptz LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7460, proiswin="t");

 CREATE FUNCTION lead(timestamptz, int8) RETURNS timestamptz LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7462, proiswin="t");

 CREATE FUNCTION lead(timestamptz) RETURNS timestamptz LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7464, proiswin="t");

 CREATE FUNCTION lead(timetz, int8, timetz) RETURNS timetz LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7466, proiswin="t");

 CREATE FUNCTION lead(timetz, int8) RETURNS timetz LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7468, proiswin="t");

 CREATE FUNCTION lead(timetz) RETURNS timetz LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7470, proiswin="t");

 CREATE FUNCTION lead(varbit, int8, varbit) RETURNS varbit LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7472, proiswin="t");

 CREATE FUNCTION lead(varbit, int8) RETURNS varbit LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7474, proiswin="t");

 CREATE FUNCTION lead(varbit) RETURNS varbit LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7476, proiswin="t");

 CREATE FUNCTION lead("varchar", int8, "varchar") RETURNS "varchar" LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7478, proiswin="t");

 CREATE FUNCTION lead("varchar", int8) RETURNS "varchar" LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7480, proiswin="t");

 CREATE FUNCTION lead("varchar") RETURNS "varchar" LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7482, proiswin="t");

 CREATE FUNCTION lead(xid, int8, xid) RETURNS xid LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7484, proiswin="t");

 CREATE FUNCTION lead(xid, int8) RETURNS xid LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7486, proiswin="t");

 CREATE FUNCTION lead(xid) RETURNS xid LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7488, proiswin="t");

 CREATE FUNCTION lead(anyarray, int8, anyarray) RETURNS anyarray LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7214, proiswin="t");

 CREATE FUNCTION lead(anyarray, int8) RETURNS anyarray LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7215, proiswin="t");

 CREATE FUNCTION lead(anyarray) RETURNS anyarray LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7216, proiswin="t");

 CREATE FUNCTION lead(bytea) RETURNS bytea LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7220, proiswin="t");

 CREATE FUNCTION lead(bytea, int8) RETURNS bytea LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7222, proiswin="t");

 CREATE FUNCTION lead(bytea, int8, bytea) RETURNS bytea LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7224, proiswin="t");

 CREATE FUNCTION lead("bit") RETURNS "bit" LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7244, proiswin="t");

 CREATE FUNCTION lead("bit", int8) RETURNS "bit" LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7246, proiswin="t");

 CREATE FUNCTION lead("bit", int8, "bit") RETURNS "bit" LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7248, proiswin="t");

 CREATE FUNCTION lead(box) RETURNS box LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7260, proiswin="t");

 CREATE FUNCTION lead(box, int8) RETURNS box LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7262, proiswin="t");

 CREATE FUNCTION lead(box, int8, box) RETURNS box LANGUAGE internal IMMUTABLE AS 'window_dummy' WITH (OID=7264, proiswin="t");

---

 CREATE FUNCTION generate_series("timestamp", "timestamp", "interval") RETURNS SETOF "timestamp" LANGUAGE internal VOLATILE STRICT AS 'generate_series_timestamp' WITH (OID=6113, DESCRIPTION="non-persistent series generator");

 CREATE FUNCTION generate_series("timestamptz", "timestamptz", "interval") RETURNS SETOF "timestamptz" LANGUAGE internal VOLATILE STRICT AS 'generate_series_timestamptz' WITH (OID=6114, DESCRIPTION="non-persistent series generator");


-- Greenplum Analytic functions
 CREATE FUNCTION matrix_transpose(anyarray) RETURNS anyarray LANGUAGE internal IMMUTABLE STRICT AS 'matrix_transpose' WITH (OID=3200, DESCRIPTION="transpose a two dimensional matrix");

 CREATE FUNCTION matrix_multiply(_int2, _int2) RETURNS _int8 LANGUAGE internal IMMUTABLE STRICT AS 'matrix_multiply' WITH (OID=3201, DESCRIPTION="perform matrix multiplication on two matrices");

 CREATE FUNCTION matrix_multiply(_int4, _int4) RETURNS _int8 LANGUAGE internal IMMUTABLE STRICT AS 'matrix_multiply' WITH (OID=3202, DESCRIPTION="perform matrix multiplication on two matrices");

 CREATE FUNCTION matrix_multiply(_int8, _int8) RETURNS _int8 LANGUAGE internal IMMUTABLE STRICT AS 'matrix_multiply' WITH (OID=3203, DESCRIPTION="perform matrix multiplication on two matrices");

 CREATE FUNCTION matrix_multiply(_float8, _float8) RETURNS _float8 LANGUAGE internal IMMUTABLE STRICT AS 'matrix_multiply' WITH (OID=3204, DESCRIPTION="perform matrix multiplication on two matrices");

 CREATE FUNCTION matrix_multiply(_int8, int8) RETURNS _int8 LANGUAGE internal IMMUTABLE STRICT AS 'int8_matrix_smultiply' WITH (OID=3205, DESCRIPTION="multiply a matrix by a scalar value");

 CREATE FUNCTION matrix_multiply(_float8, float8) RETURNS _float8 LANGUAGE internal IMMUTABLE STRICT AS 'float8_matrix_smultiply' WITH (OID=3206, DESCRIPTION="multiply a matrix by a scalar value");

 CREATE FUNCTION matrix_add(_int2, _int2) RETURNS _int2 LANGUAGE internal IMMUTABLE STRICT AS 'matrix_add' WITH (OID=3208, DESCRIPTION="perform matrix addition on two conformable matrices");

 CREATE FUNCTION matrix_add(_int4, _int4) RETURNS _int4 LANGUAGE internal IMMUTABLE STRICT AS 'matrix_add' WITH (OID=3209, DESCRIPTION="perform matrix addition on two conformable matrices");

 CREATE FUNCTION matrix_add(_int8, _int8) RETURNS _int8 LANGUAGE internal IMMUTABLE STRICT AS 'matrix_add' WITH (OID=3210, DESCRIPTION="perform matrix addition on two conformable matrices");

 CREATE FUNCTION matrix_add(_float8, _float8) RETURNS _float8 LANGUAGE internal IMMUTABLE STRICT AS 'matrix_add' WITH (OID=3211, DESCRIPTION="perform matrix addition on two conformable matrices");

 CREATE FUNCTION int2_matrix_accum(_int8, _int2) RETURNS _int8 LANGUAGE internal IMMUTABLE AS 'matrix_add' WITH (OID=3212, DESCRIPTION="perform matrix addition on two conformable matrices");

 CREATE FUNCTION int4_matrix_accum(_int8, _int4) RETURNS _int8 LANGUAGE internal IMMUTABLE AS 'matrix_add' WITH (OID=3213, DESCRIPTION="perform matrix addition on two conformable matrices");

 CREATE FUNCTION int8_matrix_accum(_int8, _int8) RETURNS _int8 LANGUAGE internal IMMUTABLE STRICT AS 'matrix_add' WITH (OID=3214, DESCRIPTION="perform matrix addition on two conformable matrices");

 CREATE FUNCTION float8_matrix_accum(_float8, _float8) RETURNS _float8 LANGUAGE internal IMMUTABLE STRICT AS 'matrix_add' WITH (OID=3215, DESCRIPTION="perform matrix addition on two conformable matrices");

 CREATE FUNCTION sum(_int2) RETURNS _int8 LANGUAGE internal IMMUTABLE AS 'aggregate_dummy' WITH (OID=3216, proisagg="t");

 CREATE FUNCTION sum(_int4) RETURNS _int8 LANGUAGE internal IMMUTABLE AS 'aggregate_dummy' WITH (OID=3217, proisagg="t");

 CREATE FUNCTION sum(_int8) RETURNS _int8 LANGUAGE internal IMMUTABLE AS 'aggregate_dummy' WITH (OID=3218, proisagg="t");

 CREATE FUNCTION sum(_float8) RETURNS _float8 LANGUAGE internal IMMUTABLE AS 'aggregate_dummy' WITH (OID=3219, proisagg="t");

-- 3220 - reserved for sum(numeric[]) 
 CREATE FUNCTION int4_pivot_accum(_int4, _text, text, int4) RETURNS _int4 LANGUAGE internal IMMUTABLE AS 'int4_pivot_accum' WITH (OID=3225);

 CREATE FUNCTION pivot_sum(_text, text, int4) RETURNS _int4 LANGUAGE internal IMMUTABLE AS 'aggregate_dummy' WITH (OID=3226, proisagg="t");

 CREATE FUNCTION int8_pivot_accum(_int8, _text, text, int8) RETURNS _int8 LANGUAGE internal IMMUTABLE AS 'int8_pivot_accum' WITH (OID=3227);

 CREATE FUNCTION pivot_sum(_text, text, int8) RETURNS _int8 LANGUAGE internal IMMUTABLE AS 'aggregate_dummy' WITH (OID=3228, proisagg="t");

 CREATE FUNCTION float8_pivot_accum(_float8, _text, text, float8) RETURNS _float8 LANGUAGE internal IMMUTABLE AS 'float8_pivot_accum' WITH (OID=3229);

 CREATE FUNCTION pivot_sum(_text, text, float8) RETURNS _float8 LANGUAGE internal IMMUTABLE AS 'aggregate_dummy' WITH (OID=3230, proisagg="t");

 CREATE FUNCTION unnest(anyarray) RETURNS SETOF anyelement LANGUAGE internal IMMUTABLE STRICT AS 'unnest' WITH (OID=3240);

-- 3241-324? reserved for unpivot, see pivot.c 

-- 3250 = nb_classification class 
-- 3251 = nb_classification type 

 CREATE FUNCTION nb_classify_accum(nb_classification, _text, int8, _int8, _int8) RETURNS nb_classification LANGUAGE internal IMMUTABLE AS 'nb_classify_accum' WITH (OID=3252);

 CREATE FUNCTION nb_classify_combine(nb_classification, nb_classification) RETURNS nb_classification LANGUAGE internal IMMUTABLE AS 'nb_classify_combine' WITH (OID=3253);

 CREATE FUNCTION nb_classify_final(nb_classification) RETURNS text LANGUAGE internal IMMUTABLE STRICT AS 'nb_classify_final' WITH (OID=3254);

 CREATE FUNCTION nb_classify(_text, int8, _int8, _int8) RETURNS text LANGUAGE internal IMMUTABLE AS 'aggregate_dummy' WITH (OID=3255, proisagg="t");

 CREATE FUNCTION nb_classify_probabilities(nb_classification) RETURNS _float8 LANGUAGE internal IMMUTABLE STRICT AS 'nb_classify_probabilities' WITH (OID=3267);

 CREATE FUNCTION nb_probabilities(_text, int8, _int8, _int8) RETURNS _float8 LANGUAGE internal IMMUTABLE AS 'aggregate_dummy' WITH (OID=3268, proisagg="t");

 CREATE FUNCTION pinv(_float8) RETURNS _float8 LANGUAGE internal IMMUTABLE STRICT AS 'pseudoinverse' WITH (OID=3256);

 CREATE FUNCTION float8_mregr_accum(_float8, float8, _float8) RETURNS _float8 LANGUAGE internal IMMUTABLE STRICT AS 'float8_mregr_accum' WITH (OID=3257);

 CREATE FUNCTION float8_mregr_combine(_float8, _float8) RETURNS _float8 LANGUAGE internal IMMUTABLE STRICT AS 'float8_mregr_combine' WITH (OID=3258);

 CREATE FUNCTION float8_mregr_coef(_float8) RETURNS _float8 LANGUAGE internal IMMUTABLE STRICT AS 'float8_mregr_coef' WITH (OID=3259);

 CREATE FUNCTION float8_mregr_r2(_float8) RETURNS float8 LANGUAGE internal IMMUTABLE STRICT AS 'float8_mregr_r2' WITH (OID=3260);

 CREATE FUNCTION mregr_coef(float8, _float8) RETURNS _float8 LANGUAGE internal IMMUTABLE STRICT AS 'aggregate_dummy' WITH (OID=3261, proisagg="t");

 CREATE FUNCTION mregr_r2(float8, _float8) RETURNS float8 LANGUAGE internal IMMUTABLE STRICT AS 'aggregate_dummy' WITH (OID=3262, proisagg="t");

 CREATE FUNCTION float8_mregr_tstats(_float8) RETURNS _float8 LANGUAGE internal IMMUTABLE STRICT AS 'float8_mregr_tstats' WITH (OID=3263);

 CREATE FUNCTION mregr_tstats(float8, _float8) RETURNS _float8 LANGUAGE internal IMMUTABLE AS 'aggregate_dummy' WITH (OID=3264, proisagg="t");

 CREATE FUNCTION float8_mregr_pvalues(_float8) RETURNS _float8 LANGUAGE internal IMMUTABLE STRICT AS 'float8_mregr_pvalues' WITH (OID=3265);

 CREATE FUNCTION mregr_pvalues(float8, _float8) RETURNS _float8 LANGUAGE internal IMMUTABLE AS 'aggregate_dummy' WITH (OID=3266, proisagg="t");

 CREATE FUNCTION gpaotidin(cstring) RETURNS gpaotid LANGUAGE internal IMMUTABLE STRICT AS 'gpaotidin' WITH (OID=3302, DESCRIPTION="I/O");

 CREATE FUNCTION gpaotidout(gpaotid) RETURNS cstring LANGUAGE internal IMMUTABLE STRICT AS 'gpaotidout' WITH (OID=3303, DESCRIPTION="I/O");

 CREATE FUNCTION gpaotidrecv(internal) RETURNS gpaotid LANGUAGE internal IMMUTABLE STRICT AS 'gpaotidrecv' WITH (OID=3304, DESCRIPTION="I/O");

 CREATE FUNCTION gpaotidsend(gpaotid) RETURNS bytea LANGUAGE internal IMMUTABLE STRICT AS 'gpaotidsend' WITH (OID=3305, DESCRIPTION="I/O");

 CREATE FUNCTION gpxloglocin(cstring) RETURNS gpxlogloc LANGUAGE internal IMMUTABLE STRICT AS 'gpxloglocin' WITH (OID=3312, DESCRIPTION="I/O");

 CREATE FUNCTION gpxloglocout(gpxlogloc) RETURNS cstring LANGUAGE internal IMMUTABLE STRICT AS 'gpxloglocout' WITH (OID=3313, DESCRIPTION="I/O");

 CREATE FUNCTION gpxloglocrecv(internal) RETURNS gpxlogloc LANGUAGE internal IMMUTABLE STRICT AS 'gpxloglocrecv' WITH (OID=3314, DESCRIPTION="I/O");

 CREATE FUNCTION gpxloglocsend(gpxlogloc) RETURNS bytea LANGUAGE internal IMMUTABLE STRICT AS 'gpxloglocsend' WITH (OID=3315, DESCRIPTION="I/O");

 CREATE FUNCTION gpxlogloclarger(gpxlogloc, gpxlogloc) RETURNS gpxlogloc LANGUAGE internal IMMUTABLE STRICT AS 'gpxlogloclarger' WITH (OID=3318, DESCRIPTION="I/O");

 CREATE FUNCTION gpxloglocsmaller(gpxlogloc, gpxlogloc) RETURNS gpxlogloc LANGUAGE internal IMMUTABLE STRICT AS 'gpxloglocsmaller' WITH (OID=3319, DESCRIPTION="I/O");

 CREATE FUNCTION gpxlogloceq(gpxlogloc, gpxlogloc) RETURNS bool LANGUAGE internal IMMUTABLE STRICT AS 'gpxlogloceq' WITH (OID=3331, DESCRIPTION="I/O");

 CREATE FUNCTION gpxloglocne(gpxlogloc, gpxlogloc) RETURNS bool LANGUAGE internal IMMUTABLE STRICT AS 'gpxloglocne' WITH (OID=3320, DESCRIPTION="I/O");

 CREATE FUNCTION gpxlogloclt(gpxlogloc, gpxlogloc) RETURNS bool LANGUAGE internal IMMUTABLE STRICT AS 'gpxlogloclt' WITH (OID=3321, DESCRIPTION="I/O");

 CREATE FUNCTION gpxloglocle(gpxlogloc, gpxlogloc) RETURNS bool LANGUAGE internal IMMUTABLE STRICT AS 'gpxloglocle' WITH (OID=3322, DESCRIPTION="I/O");

 CREATE FUNCTION gpxloglocgt(gpxlogloc, gpxlogloc) RETURNS bool LANGUAGE internal IMMUTABLE STRICT AS 'gpxloglocgt' WITH (OID=3323, DESCRIPTION="I/O");

 CREATE FUNCTION gpxloglocge(gpxlogloc, gpxlogloc) RETURNS bool LANGUAGE internal IMMUTABLE STRICT AS 'gpxloglocge' WITH (OID=3324, DESCRIPTION="I/O");

-- Greenplum MPP exposed internally-defined functions. 
 CREATE FUNCTION gp_backup_launch(text, text, text, text, text) RETURNS text LANGUAGE internal VOLATILE AS 'gp_backup_launch__' WITH (OID=6003, DESCRIPTION="launch mpp backup on outboard Postgres instances");

 CREATE FUNCTION gp_restore_launch(text, text, text, text, text, text, int4, bool) RETURNS text LANGUAGE internal VOLATILE AS 'gp_restore_launch__' WITH (OID=6004, DESCRIPTION="launch mpp restore on outboard Postgres instances");

 CREATE FUNCTION gp_read_backup_file(text, text, regproc) RETURNS text LANGUAGE internal VOLATILE AS 'gp_read_backup_file__' WITH (OID=6005, DESCRIPTION="read mpp backup file on outboard Postgres instances");

 CREATE FUNCTION gp_write_backup_file(text, text, text) RETURNS text LANGUAGE internal VOLATILE AS 'gp_write_backup_file__' WITH (OID=6006, DESCRIPTION="write mpp backup file on outboard Postgres instances");

 CREATE FUNCTION gp_pgdatabase() RETURNS SETOF record LANGUAGE internal VOLATILE AS 'gp_pgdatabase__' WITH (OID=6007, DESCRIPTION="view mpp pgdatabase state");

 CREATE FUNCTION numeric_amalg(_numeric, _numeric) RETURNS _numeric LANGUAGE internal IMMUTABLE STRICT AS 'numeric_amalg' WITH (OID=6008, DESCRIPTION="aggregate preliminary function");

 CREATE FUNCTION numeric_avg_amalg(bytea, bytea) RETURNS bytea LANGUAGE internal IMMUTABLE STRICT AS 'numeric_avg_amalg' WITH (OID=3104, DESCRIPTION="aggregate preliminary function");

 CREATE FUNCTION int8_avg_amalg(bytea, bytea) RETURNS bytea LANGUAGE internal IMMUTABLE STRICT AS 'int8_avg_amalg' WITH (OID=6009, DESCRIPTION="aggregate preliminary function");

 CREATE FUNCTION float8_amalg(_float8, _float8) RETURNS _float8 LANGUAGE internal IMMUTABLE STRICT AS 'float8_amalg' WITH (OID=6010, DESCRIPTION="aggregate preliminary function");

 CREATE FUNCTION float8_avg_amalg(bytea, bytea) RETURNS bytea LANGUAGE internal IMMUTABLE STRICT AS 'float8_avg_amalg' WITH (OID=3111, DESCRIPTION="aggregate preliminary function");

 CREATE FUNCTION interval_amalg(_interval, _interval) RETURNS _interval LANGUAGE internal IMMUTABLE STRICT AS 'interval_amalg' WITH (OID=6011, DESCRIPTION="aggregate preliminary function");

 CREATE FUNCTION numeric_demalg(_numeric, _numeric) RETURNS _numeric LANGUAGE internal IMMUTABLE STRICT AS 'numeric_demalg' WITH (OID=6015, DESCRIPTION="aggregate inverse preliminary function");

 CREATE FUNCTION numeric_avg_demalg(bytea, bytea) RETURNS bytea LANGUAGE internal IMMUTABLE STRICT AS 'numeric_avg_demalg' WITH (OID=3105, DESCRIPTION="aggregate inverse preliminary function");

 CREATE FUNCTION int8_avg_demalg(bytea, bytea) RETURNS bytea LANGUAGE internal IMMUTABLE STRICT AS 'int8_avg_demalg' WITH (OID=6016, DESCRIPTION="aggregate preliminary function");

 CREATE FUNCTION float8_demalg(_float8, _float8) RETURNS _float8 LANGUAGE internal IMMUTABLE STRICT AS 'float8_demalg' WITH (OID=6017);

 CREATE FUNCTION float8_avg_demalg(bytea, bytea) RETURNS bytea LANGUAGE internal IMMUTABLE STRICT AS 'float8_avg_demalg' WITH (OID=3110, DESCRIPTION="aggregate inverse preliminary function");

 CREATE FUNCTION interval_demalg(_interval, _interval) RETURNS _interval LANGUAGE internal IMMUTABLE STRICT AS 'interval_demalg' WITH (OID=6018, DESCRIPTION="aggregate preliminary function");

 CREATE FUNCTION float8_regr_amalg(_float8, _float8) RETURNS _float8 LANGUAGE internal IMMUTABLE STRICT AS 'float8_regr_amalg' WITH (OID=6014);

 CREATE FUNCTION int8(tid) RETURNS int8 LANGUAGE internal IMMUTABLE STRICT AS 'tidtoi8' WITH (OID=6021, DESCRIPTION="convert tid to int8");
-- #define CDB_PROC_TIDTOI8    6021

 CREATE FUNCTION gp_execution_segment() RETURNS SETOF int4 LANGUAGE internal VOLATILE AS 'mpp_execution_segment' WITH (OID=6022, DESCRIPTION="segment executing function");
-- #define MPP_EXECUTION_SEGMENT_OID 6022
-- #define MPP_EXECUTION_SEGMENT_TYPE 23

 CREATE FUNCTION pg_highest_oid() RETURNS oid LANGUAGE internal VOLATILE STRICT READS SQL DATA AS 'pg_highest_oid' WITH (OID=6023, DESCRIPTION="Highest oid used so far");

 CREATE FUNCTION gp_distributed_xacts() RETURNS SETOF record LANGUAGE internal VOLATILE AS 'gp_distributed_xacts__' WITH (OID=6035, DESCRIPTION="view mpp distributed transaction state");

 CREATE FUNCTION gp_distributed_xid() RETURNS xid LANGUAGE internal VOLATILE STRICT AS 'gp_distributed_xid' WITH (OID=6037, DESCRIPTION="Current distributed transaction id");

 CREATE FUNCTION gp_transaction_log() RETURNS SETOF record LANGUAGE internal VOLATILE AS 'gp_transaction_log' WITH (OID=6043, DESCRIPTION="view logged local transaction status");

 CREATE FUNCTION gp_distributed_log() RETURNS SETOF record LANGUAGE internal VOLATILE AS 'gp_distributed_log' WITH (OID=6044, DESCRIPTION="view logged distributed transaction status");

 CREATE FUNCTION gp_changetracking_log(IN filetype int4, OUT segment_id int2, OUT dbid int2, OUT space oid, OUT db oid, OUT rel oid, OUT xlogloc gpxlogloc, OUT blocknum int4, OUT persistent_tid tid, OUT persistent_sn int8) RETURNS SETOF pg_catalog.record LANGUAGE internal VOLATILE AS 'gp_changetracking_log' WITH (OID=6435, DESCRIPTION="view logged change tracking records");

 CREATE FUNCTION gp_execution_dbid() RETURNS int4 LANGUAGE internal VOLATILE AS 'gp_execution_dbid' WITH (OID=6068, DESCRIPTION="dbid executing function");

-- Greenplum MPP window function implementation
 CREATE FUNCTION row_number_immed(internal) RETURNS int8 LANGUAGE internal IMMUTABLE STRICT AS 'row_number_immed' WITH (OID=7100, DESCRIPTION="window immediate function");

 CREATE FUNCTION rank_immed(internal) RETURNS int8 LANGUAGE internal IMMUTABLE STRICT AS 'rank_immed' WITH (OID=7101, DESCRIPTION="window immediate function");

 CREATE FUNCTION dense_rank_immed(internal) RETURNS int8 LANGUAGE internal IMMUTABLE STRICT AS 'dense_rank_immed' WITH (OID=7102, DESCRIPTION="window immediate function");

 CREATE FUNCTION lag_bool(internal, bool, int8, bool) RETURNS bool LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7490, proiswin="t");

 CREATE FUNCTION lag_bool(internal, bool, int8) RETURNS bool LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7492, proiswin="t");

 CREATE FUNCTION lag_bool(internal, bool) RETURNS bool LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7494, proiswin="t");

 CREATE FUNCTION lag_char(internal, "char", int8, "char") RETURNS "char" LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7496, proiswin="t");

 CREATE FUNCTION lag_char(internal, "char", int8) RETURNS "char" LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7498, proiswin="t");

 CREATE FUNCTION lag_char(internal, "char") RETURNS "char" LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7500, proiswin="t");

 CREATE FUNCTION lag_cidr(internal, cidr, int8, cidr) RETURNS cidr LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7502, proiswin="t");

 CREATE FUNCTION lag_cidr(internal, cidr, int8) RETURNS cidr LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7504, proiswin="t");

 CREATE FUNCTION lag_cidr(internal, cidr) RETURNS cidr LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7506, proiswin="t");

 CREATE FUNCTION lag_circle(internal, circle, int8, circle) RETURNS circle LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7508, proiswin="t");

 CREATE FUNCTION lag_circle(internal, circle, int8) RETURNS circle LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7510, proiswin="t");

 CREATE FUNCTION lag_circle(internal, circle) RETURNS circle LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7512, proiswin="t");

 CREATE FUNCTION lag_float4(internal, float4, int8, float4) RETURNS float4 LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7514, proiswin="t");

 CREATE FUNCTION lag_float4(internal, float4, int8) RETURNS float4 LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7516, proiswin="t");

 CREATE FUNCTION lag_float4(internal, float4) RETURNS float4 LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7518, proiswin="t");

 CREATE FUNCTION lag_float8(internal, float8, int8, float8) RETURNS float8 LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7520, proiswin="t");

 CREATE FUNCTION lag_float8(internal, float8, int8) RETURNS float8 LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7522, proiswin="t");

 CREATE FUNCTION lag_float8(internal, float8) RETURNS float8 LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7524, proiswin="t");

 CREATE FUNCTION lag_inet(internal, inet, int8, inet) RETURNS inet LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7526, proiswin="t");

 CREATE FUNCTION lag_inet(internal, inet, int8) RETURNS inet LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7528, proiswin="t");

 CREATE FUNCTION lag_inet(internal, inet) RETURNS inet LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7530, proiswin="t");

 CREATE FUNCTION lag_interval(internal, "interval", int8, "interval") RETURNS "interval" LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7532, proiswin="t");

 CREATE FUNCTION lag_interval(internal, "interval", int8) RETURNS "interval" LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7534, proiswin="t");

 CREATE FUNCTION lag_interval(internal, "interval") RETURNS "interval" LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7536, proiswin="t");

 CREATE FUNCTION lag_line(internal, line, int8, line) RETURNS line LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7538, proiswin="t");

 CREATE FUNCTION lag_line(internal, line, int8) RETURNS line LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7540, proiswin="t");

 CREATE FUNCTION lag_line(internal, line) RETURNS line LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7542, proiswin="t");

 CREATE FUNCTION lag_lseg(internal, lseg, int8, lseg) RETURNS lseg LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7544, proiswin="t");

 CREATE FUNCTION lag_lseg(internal, lseg, int8) RETURNS lseg LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7546, proiswin="t");

 CREATE FUNCTION lag_lseg(internal, lseg) RETURNS lseg LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7548, proiswin="t");

 CREATE FUNCTION lag_macaddr(internal, macaddr, int8, macaddr) RETURNS macaddr LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7550, proiswin="t");

 CREATE FUNCTION lag_macaddr(internal, macaddr, int8) RETURNS macaddr LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7552, proiswin="t");

 CREATE FUNCTION lag_macaddr(internal, macaddr) RETURNS macaddr LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7554, proiswin="t");

 CREATE FUNCTION lag_smallint(internal, int2, int8, int2) RETURNS int2 LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7556, proiswin="t");

 CREATE FUNCTION lag_smallint(internal, int2, int8) RETURNS int2 LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7558, proiswin="t");

 CREATE FUNCTION lag_smallint(internal, int2) RETURNS int2 LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7560, proiswin="t");

 CREATE FUNCTION lag_int4(internal, int4, int8, int4) RETURNS int4 LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7562, proiswin="t");

 CREATE FUNCTION lag_int4(internal, int4, int8) RETURNS int4 LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7564, proiswin="t");

 CREATE FUNCTION lag_int4(internal, int4) RETURNS int4 LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7566, proiswin="t");

 CREATE FUNCTION lag_int8(internal, int8, int8, int8) RETURNS int8 LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7568, proiswin="t");

 CREATE FUNCTION lag_int8(internal, int8, int8) RETURNS int8 LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7570, proiswin="t");

 CREATE FUNCTION lag_int8(internal, int8) RETURNS int8 LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7572, proiswin="t");

 CREATE FUNCTION lag_money(internal, money, int8, money) RETURNS money LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7574, proiswin="t");

 CREATE FUNCTION lag_money(internal, money, int8) RETURNS money LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7576, proiswin="t");

 CREATE FUNCTION lag_money(internal, money) RETURNS money LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7578, proiswin="t");

 CREATE FUNCTION lag_name(internal, name, int8, name) RETURNS name LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7580, proiswin="t");

 CREATE FUNCTION lag_name(internal, name, int8) RETURNS name LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7582, proiswin="t");

 CREATE FUNCTION lag_name(internal, name) RETURNS name LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7584, proiswin="t");

 CREATE FUNCTION lag_numeric(internal, "numeric", int8, "numeric") RETURNS "numeric" LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7586, proiswin="t");

 CREATE FUNCTION lag_numeric(internal, "numeric", int8) RETURNS "numeric" LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7588, proiswin="t");

 CREATE FUNCTION lag_numeric(internal, "numeric") RETURNS "numeric" LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7590, proiswin="t");

 CREATE FUNCTION lag_oid(internal, oid, int8, oid) RETURNS oid LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7592, proiswin="t");

 CREATE FUNCTION lag_oid(internal, oid, int8) RETURNS oid LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7594, proiswin="t");

 CREATE FUNCTION lag_oid(internal, oid) RETURNS oid LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7596, proiswin="t");

 CREATE FUNCTION lag_path(internal, path, int8, path) RETURNS path LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7598, proiswin="t");

 CREATE FUNCTION lag_path(internal, path, int8) RETURNS path LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7600, proiswin="t");

 CREATE FUNCTION lag_path(internal, path) RETURNS path LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7602, proiswin="t");

 CREATE FUNCTION lag_point(internal, point, int8, point) RETURNS point LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7604, proiswin="t");

 CREATE FUNCTION lag_point(internal, point, int8) RETURNS point LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7606, proiswin="t");

 CREATE FUNCTION lag_point(internal, point) RETURNS point LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7608, proiswin="t");

 CREATE FUNCTION lag_polygon(internal, polygon, int8, polygon) RETURNS polygon LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7610, proiswin="t");

 CREATE FUNCTION lag_polygon(internal, polygon, int8) RETURNS polygon LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7612, proiswin="t");

 CREATE FUNCTION lag_polygon(internal, polygon) RETURNS polygon LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7614, proiswin="t");

 CREATE FUNCTION lag_reltime(internal, reltime, int8, reltime) RETURNS reltime LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7616, proiswin="t");

 CREATE FUNCTION lag_reltime(internal, reltime, int8) RETURNS reltime LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7618, proiswin="t");

 CREATE FUNCTION lag_reltime(internal, reltime) RETURNS reltime LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7620, proiswin="t");

 CREATE FUNCTION lag_text(internal, text, int8, text) RETURNS text LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7622, proiswin="t");

 CREATE FUNCTION lag_text(internal, text, int8) RETURNS text LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7624, proiswin="t");

 CREATE FUNCTION lag_text(internal, text) RETURNS text LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7626, proiswin="t");

 CREATE FUNCTION lag_tid(internal, tid, int8, tid) RETURNS tid LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7628, proiswin="t");

 CREATE FUNCTION lag_tid(internal, tid, int8) RETURNS tid LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7630, proiswin="t");

 CREATE FUNCTION lag_tid(internal, tid) RETURNS tid LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7632, proiswin="t");

 CREATE FUNCTION lag_time(internal, "time", int8, "time") RETURNS "time" LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7634, proiswin="t");

 CREATE FUNCTION lag_time(internal, "time", int8) RETURNS "time" LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7636, proiswin="t");

 CREATE FUNCTION lag_time(internal, "time") RETURNS "time" LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7638, proiswin="t");

 CREATE FUNCTION lag_timestamp(internal, "timestamp", int8, "timestamp") RETURNS "timestamp" LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7640, proiswin="t");

 CREATE FUNCTION lag_timestamp(internal, "timestamp", int8) RETURNS "timestamp" LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7642, proiswin="t");

 CREATE FUNCTION lag_timestamp(internal, "timestamp") RETURNS "timestamp" LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7644, proiswin="t");

 CREATE FUNCTION lag_timestamptz(internal, timestamptz, int8, timestamptz) RETURNS timestamptz LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7646, proiswin="t");

 CREATE FUNCTION lag_timestamptz(internal, timestamptz, int8) RETURNS timestamptz LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7648, proiswin="t");

 CREATE FUNCTION lag_timestamptz(internal, timestamptz) RETURNS timestamptz LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7650, proiswin="t");

 CREATE FUNCTION lag_timetz(internal, timetz, int8, timetz) RETURNS timetz LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7652, proiswin="t");

 CREATE FUNCTION lag_timetz(internal, timetz, int8) RETURNS timetz LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7654, proiswin="t");

 CREATE FUNCTION lag_timetz(internal, timetz) RETURNS timetz LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7656, proiswin="t");

 CREATE FUNCTION lag_varbit(internal, varbit, int8, varbit) RETURNS varbit LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7658, proiswin="t");

 CREATE FUNCTION lag_varbit(internal, varbit, int8) RETURNS varbit LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7660, proiswin="t");

 CREATE FUNCTION lag_varbit(internal, varbit) RETURNS varbit LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7662, proiswin="t");

 CREATE FUNCTION lag_varchar(internal, "varchar", int8, "varchar") RETURNS "varchar" LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7664, proiswin="t");

 CREATE FUNCTION lag_varchar(internal, "varchar", int8) RETURNS "varchar" LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7666, proiswin="t");

 CREATE FUNCTION lag_varchar(internal, "varchar") RETURNS "varchar" LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7668, proiswin="t");

 CREATE FUNCTION lag_xid(internal, xid, int8, xid) RETURNS xid LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7670, proiswin="t");

 CREATE FUNCTION lag_xid(internal, xid, int8) RETURNS xid LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7672, proiswin="t");

 CREATE FUNCTION lag_xid(internal, xid) RETURNS xid LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7674, proiswin="t");

 CREATE FUNCTION lag_any(internal, anyarray, int8, anyarray) RETURNS anyarray LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7208, proiswin="t");

 CREATE FUNCTION lag_any(internal, anyarray, int8) RETURNS anyarray LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7209, proiswin="t");

 CREATE FUNCTION lag_any(internal, anyarray) RETURNS anyarray LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7210, proiswin="t");

 CREATE FUNCTION lag_bytea(internal, bytea) RETURNS bytea LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7227, proiswin="t");

 CREATE FUNCTION lag_bytea(internal, bytea, int8) RETURNS bytea LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7229, proiswin="t");

 CREATE FUNCTION lag_bytea(internal, bytea, int8, bytea) RETURNS bytea LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7231, proiswin="t");

 CREATE FUNCTION lag_bit(internal, "bit") RETURNS "bit" LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7251, proiswin="t");

 CREATE FUNCTION lag_bit(internal, "bit", int8) RETURNS "bit" LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7253, proiswin="t");

 CREATE FUNCTION lag_bit(internal, "bit", int8, "bit") RETURNS "bit" LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7255, proiswin="t");

 CREATE FUNCTION lag_box(internal, box) RETURNS box LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7267, proiswin="t");

 CREATE FUNCTION lag_box(internal, box, int8) RETURNS box LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7269, proiswin="t");

 CREATE FUNCTION lag_box(internal, box, int8, box) RETURNS box LANGUAGE internal IMMUTABLE STRICT AS 'lag_generic' WITH (OID=7271, proiswin="t");

 CREATE FUNCTION lead_int(internal, int4, int8, int4) RETURNS int4 LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7106, proiswin="t");

 CREATE FUNCTION lead_int(internal, int4, int8) RETURNS int4 LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7104, proiswin="t");

 CREATE FUNCTION lead_int(internal, int4) RETURNS int4 LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7105, proiswin="t");

 CREATE FUNCTION lead_bool(internal, bool, int8, bool) RETURNS bool LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7311, proiswin="t");

 CREATE FUNCTION lead_bool(internal, bool, int8) RETURNS bool LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7313, proiswin="t");

 CREATE FUNCTION lead_bool(internal, bool) RETURNS bool LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7315, proiswin="t");

 CREATE FUNCTION lead_char(internal, "char", int8, "char") RETURNS "char" LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7317, proiswin="t");

 CREATE FUNCTION lead_char(internal, "char", int8) RETURNS "char" LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7319, proiswin="t");

 CREATE FUNCTION lead_char(internal, "char") RETURNS "char" LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7321, proiswin="t");

 CREATE FUNCTION lead_cidr(internal, cidr, int8, cidr) RETURNS cidr LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7323, proiswin="t");

 CREATE FUNCTION lead_cidr(internal, cidr, int8) RETURNS cidr LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7325, proiswin="t");

 CREATE FUNCTION lead_cidr(internal, cidr) RETURNS cidr LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7327, proiswin="t");

 CREATE FUNCTION lead_circle(internal, circle, int8, circle) RETURNS circle LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7329, proiswin="t");

 CREATE FUNCTION lead_circle(internal, circle, int8) RETURNS circle LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7331, proiswin="t");

 CREATE FUNCTION lead_circle(internal, circle) RETURNS circle LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7333, proiswin="t");

 CREATE FUNCTION lead_float4(internal, float4, int8, float4) RETURNS float4 LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7335, proiswin="t");

 CREATE FUNCTION lead_float4(internal, float4, int8) RETURNS float4 LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7337, proiswin="t");

 CREATE FUNCTION lead_float4(internal, float4) RETURNS float4 LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7339, proiswin="t");

 CREATE FUNCTION lead_float8(internal, float8, int8, float8) RETURNS float8 LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7341, proiswin="t");

 CREATE FUNCTION lead_float8(internal, float8, int8) RETURNS float8 LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7343, proiswin="t");

 CREATE FUNCTION lead_float8(internal, float8) RETURNS float8 LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7345, proiswin="t");

 CREATE FUNCTION lead_inet(internal, inet, int8, inet) RETURNS inet LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7347, proiswin="t");

 CREATE FUNCTION lead_inet(internal, inet, int8) RETURNS inet LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7349, proiswin="t");

 CREATE FUNCTION lead_inet(internal, inet) RETURNS inet LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7351, proiswin="t");

 CREATE FUNCTION lead_interval(internal, "interval", int8, "interval") RETURNS "interval" LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7353, proiswin="t");

 CREATE FUNCTION lead_interval(internal, "interval", int8) RETURNS "interval" LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7355, proiswin="t");

 CREATE FUNCTION lead_interval(internal, "interval") RETURNS "interval" LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7357, proiswin="t");

 CREATE FUNCTION lead_line(internal, line, int8, line) RETURNS line LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7359, proiswin="t");

 CREATE FUNCTION lead_line(internal, line, int8) RETURNS line LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7361, proiswin="t");

 CREATE FUNCTION lead_line(internal, line) RETURNS line LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7363, proiswin="t");

 CREATE FUNCTION lead_lseg(internal, lseg, int8, lseg) RETURNS lseg LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7365, proiswin="t");

 CREATE FUNCTION lead_lseg(internal, lseg, int8) RETURNS lseg LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7367, proiswin="t");

 CREATE FUNCTION lead_lseg(internal, lseg) RETURNS lseg LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7369, proiswin="t");

 CREATE FUNCTION lead_macaddr(internal, macaddr, int8, macaddr) RETURNS macaddr LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7371, proiswin="t");

 CREATE FUNCTION lead_macaddr(internal, macaddr, int8) RETURNS macaddr LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7373, proiswin="t");

 CREATE FUNCTION lead_macaddr(internal, macaddr) RETURNS macaddr LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7375, proiswin="t");

 CREATE FUNCTION lead_smallint(internal, int2, int8, int2) RETURNS int2 LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7377, proiswin="t");

 CREATE FUNCTION lead_smallint(internal, int2, int8) RETURNS int2 LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7379, proiswin="t");

 CREATE FUNCTION lead_smallint(internal, int2) RETURNS int2 LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7381, proiswin="t");

 CREATE FUNCTION lead_int8(internal, int8, int8, int8) RETURNS int8 LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7383, proiswin="t");

 CREATE FUNCTION lead_int8(internal, int8, int8) RETURNS int8 LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7385, proiswin="t");

 CREATE FUNCTION lead_int8(internal, int8) RETURNS int8 LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7387, proiswin="t");

 CREATE FUNCTION lead_money(internal, money, int8, money) RETURNS money LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7389, proiswin="t");

 CREATE FUNCTION lead_money(internal, money, int8) RETURNS money LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7391, proiswin="t");

 CREATE FUNCTION lead_money(internal, money) RETURNS money LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7393, proiswin="t");

 CREATE FUNCTION lead_name(internal, name, int8, name) RETURNS name LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7395, proiswin="t");

 CREATE FUNCTION lead_name(internal, name, int8) RETURNS name LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7397, proiswin="t");

 CREATE FUNCTION lead_name(internal, name) RETURNS name LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7399, proiswin="t");

 CREATE FUNCTION lead_numeric(internal, "numeric", int8, "numeric") RETURNS "numeric" LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7401, proiswin="t");

 CREATE FUNCTION lead_numeric(internal, "numeric", int8) RETURNS "numeric" LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7403, proiswin="t");

 CREATE FUNCTION lead_numeric(internal, "numeric") RETURNS "numeric" LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7405, proiswin="t");

 CREATE FUNCTION lead_oid(internal, oid, int8, oid) RETURNS oid LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7407, proiswin="t");

 CREATE FUNCTION lead_oid(internal, oid, int8) RETURNS oid LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7409, proiswin="t");

 CREATE FUNCTION lead_oid(internal, oid) RETURNS oid LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7411, proiswin="t");

 CREATE FUNCTION lead_path(internal, path, int8, path) RETURNS path LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7413, proiswin="t");

 CREATE FUNCTION lead_path(internal, path, int8) RETURNS path LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7415, proiswin="t");

 CREATE FUNCTION lead_path(internal, path) RETURNS path LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7417, proiswin="t");

 CREATE FUNCTION lead_point(internal, point, int8, point) RETURNS point LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7419, proiswin="t");

 CREATE FUNCTION lead_point(internal, point, int8) RETURNS point LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7421, proiswin="t");

 CREATE FUNCTION lead_point(internal, point) RETURNS point LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7423, proiswin="t");

 CREATE FUNCTION lead_polygon(internal, polygon, int8, polygon) RETURNS polygon LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7425, proiswin="t");

 CREATE FUNCTION lead_polygon(internal, polygon, int8) RETURNS polygon LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7427, proiswin="t");

 CREATE FUNCTION lead_polygon(internal, polygon) RETURNS polygon LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7429, proiswin="t");

 CREATE FUNCTION lead_reltime(internal, reltime, int8, reltime) RETURNS reltime LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7431, proiswin="t");

 CREATE FUNCTION lead_reltime(internal, reltime, int8) RETURNS reltime LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7433, proiswin="t");

 CREATE FUNCTION lead_reltime(internal, reltime) RETURNS reltime LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7435, proiswin="t");

 CREATE FUNCTION lead_text(internal, text, int8, text) RETURNS text LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7437, proiswin="t");

 CREATE FUNCTION lead_text(internal, text, int8) RETURNS text LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7439, proiswin="t");

 CREATE FUNCTION lead_text(internal, text) RETURNS text LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7441, proiswin="t");

 CREATE FUNCTION lead_tid(internal, tid, int8, tid) RETURNS tid LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7443, proiswin="t");

 CREATE FUNCTION lead_tid(internal, tid, int8) RETURNS tid LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7445, proiswin="t");

 CREATE FUNCTION lead_tid(internal, tid) RETURNS tid LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7447, proiswin="t");

 CREATE FUNCTION lead_time(internal, "time", int8, "time") RETURNS "time" LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7449, proiswin="t");

 CREATE FUNCTION lead_time(internal, "time", int8) RETURNS "time" LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7451, proiswin="t");

 CREATE FUNCTION lead_time(internal, "time") RETURNS "time" LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7453, proiswin="t");

 CREATE FUNCTION lead_timestamp(internal, "timestamp", int8, "timestamp") RETURNS "timestamp" LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7455, proiswin="t");

 CREATE FUNCTION lead_timestamp(internal, "timestamp", int8) RETURNS "timestamp" LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7457, proiswin="t");

 CREATE FUNCTION lead_timestamp(internal, "timestamp") RETURNS "timestamp" LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7459, proiswin="t");

 CREATE FUNCTION lead_timestamptz(internal, timestamptz, int8, timestamptz) RETURNS timestamptz LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7461, proiswin="t");

 CREATE FUNCTION lead_timestamptz(internal, timestamptz, int8) RETURNS timestamptz LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7463, proiswin="t");

 CREATE FUNCTION lead_timestamptz(internal, timestamptz) RETURNS timestamptz LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7465, proiswin="t");

 CREATE FUNCTION lead_timetz(internal, timetz, int8, timetz) RETURNS timetz LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7467, proiswin="t");

 CREATE FUNCTION lead_timetz(internal, timetz, int8) RETURNS timetz LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7469, proiswin="t");

 CREATE FUNCTION lead_timetz(internal, timetz) RETURNS timetz LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7471, proiswin="t");

 CREATE FUNCTION lead_varbit(internal, varbit, int8, varbit) RETURNS varbit LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7473, proiswin="t");

 CREATE FUNCTION lead_varbit(internal, varbit, int8) RETURNS varbit LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7475, proiswin="t");

 CREATE FUNCTION lead_varbit(internal, varbit) RETURNS varbit LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7477, proiswin="t");

 CREATE FUNCTION lead_varchar(internal, "varchar", int8, "varchar") RETURNS "varchar" LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7479, proiswin="t");

 CREATE FUNCTION lead_varchar(internal, "varchar", int8) RETURNS "varchar" LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7481, proiswin="t");

 CREATE FUNCTION lead_varchar(internal, "varchar") RETURNS "varchar" LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7483, proiswin="t");

 CREATE FUNCTION lead_xid(internal, xid, int8, xid) RETURNS xid LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7485, proiswin="t");

 CREATE FUNCTION lead_xid(internal, xid, int8) RETURNS xid LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7487, proiswin="t");

 CREATE FUNCTION lead_xid(internal, xid) RETURNS xid LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7489, proiswin="t");

 CREATE FUNCTION lead_any(internal, anyarray, int8, anyarray) RETURNS anyarray LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7217, proiswin="t");

 CREATE FUNCTION lead_any(internal, anyarray, int8) RETURNS anyarray LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7218, proiswin="t");

 CREATE FUNCTION lead_any(internal, anyarray) RETURNS anyarray LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7219, proiswin="t");

 CREATE FUNCTION lead_bytea(internal, bytea) RETURNS bytea LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7221, proiswin="t");

 CREATE FUNCTION lead_bytea(internal, bytea, int8) RETURNS bytea LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7223, proiswin="t");

 CREATE FUNCTION lead_bytea(internal, bytea, int8, bytea) RETURNS bytea LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7225, proiswin="t");

 CREATE FUNCTION lead_bit(internal, "bit") RETURNS "bit" LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7245, proiswin="t");

 CREATE FUNCTION lead_bit(internal, "bit", int8) RETURNS "bit" LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7247, proiswin="t");

 CREATE FUNCTION lead_bit(internal, "bit", int8, "bit") RETURNS "bit" LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7249, proiswin="t");

 CREATE FUNCTION lead_box(internal, box) RETURNS box LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7261, proiswin="t");

 CREATE FUNCTION lead_box(internal, box, int8) RETURNS box LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7263, proiswin="t");

 CREATE FUNCTION lead_box(internal, box, int8, box) RETURNS box LANGUAGE internal IMMUTABLE STRICT AS 'lead_generic' WITH (OID=7265, proiswin="t");

 CREATE FUNCTION first_value_bool(internal, bool) RETURNS bool LANGUAGE internal IMMUTABLE STRICT AS 'first_value_generic' WITH (OID=7111, proiswin="t");

 CREATE FUNCTION first_value_char(internal, "char") RETURNS "char" LANGUAGE internal IMMUTABLE STRICT AS 'first_value_generic' WITH (OID=7112, proiswin="t");

 CREATE FUNCTION first_value_cidr(internal, cidr) RETURNS cidr LANGUAGE internal IMMUTABLE STRICT AS 'first_value_generic' WITH (OID=7113, proiswin="t");

 CREATE FUNCTION first_value_circle(internal, circle) RETURNS circle LANGUAGE internal IMMUTABLE STRICT AS 'first_value_generic' WITH (OID=7114, proiswin="t");

 CREATE FUNCTION first_value_float4(internal, float4) RETURNS float4 LANGUAGE internal IMMUTABLE STRICT AS 'first_value_generic' WITH (OID=7115, proiswin="t");

 CREATE FUNCTION first_value_float8(internal, float8) RETURNS float8 LANGUAGE internal IMMUTABLE STRICT AS 'first_value_generic' WITH (OID=7116, proiswin="t");

 CREATE FUNCTION first_value_inet(internal, inet) RETURNS inet LANGUAGE internal IMMUTABLE STRICT AS 'first_value_generic' WITH (OID=7117, proiswin="t");

 CREATE FUNCTION first_value_interval(internal, "interval") RETURNS "interval" LANGUAGE internal IMMUTABLE STRICT AS 'first_value_generic' WITH (OID=7118, proiswin="t");

 CREATE FUNCTION first_value_line(internal, line) RETURNS line LANGUAGE internal IMMUTABLE STRICT AS 'first_value_generic' WITH (OID=7119, proiswin="t");

 CREATE FUNCTION first_value_lseg(internal, lseg) RETURNS lseg LANGUAGE internal IMMUTABLE STRICT AS 'first_value_generic' WITH (OID=7120, proiswin="t");

 CREATE FUNCTION first_value_macaddr(internal, macaddr) RETURNS macaddr LANGUAGE internal IMMUTABLE STRICT AS 'first_value_generic' WITH (OID=7121, proiswin="t");

 CREATE FUNCTION first_value_smallint(internal, int2) RETURNS int2 LANGUAGE internal IMMUTABLE STRICT AS 'first_value_generic' WITH (OID=7122, proiswin="t");

 CREATE FUNCTION first_value_int4(internal, int4) RETURNS int4 LANGUAGE internal IMMUTABLE STRICT AS 'first_value_generic' WITH (OID=7123, proiswin="t");

 CREATE FUNCTION first_value_int8(internal, int8) RETURNS int8 LANGUAGE internal IMMUTABLE STRICT AS 'first_value_generic' WITH (OID=7124, proiswin="t");

 CREATE FUNCTION first_value_money(internal, money) RETURNS money LANGUAGE internal IMMUTABLE STRICT AS 'first_value_generic' WITH (OID=7125, proiswin="t");

 CREATE FUNCTION first_value_name(internal, name) RETURNS name LANGUAGE internal IMMUTABLE STRICT AS 'first_value_generic' WITH (OID=7126, proiswin="t");

 CREATE FUNCTION first_value_numeric(internal, "numeric") RETURNS "numeric" LANGUAGE internal IMMUTABLE STRICT AS 'first_value_generic' WITH (OID=7127, proiswin="t");

 CREATE FUNCTION first_value_oid(internal, oid) RETURNS oid LANGUAGE internal IMMUTABLE STRICT AS 'first_value_generic' WITH (OID=7128, proiswin="t");

 CREATE FUNCTION first_value_path(internal, path) RETURNS path LANGUAGE internal IMMUTABLE STRICT AS 'first_value_generic' WITH (OID=7129, proiswin="t");

 CREATE FUNCTION first_value_point(internal, point) RETURNS point LANGUAGE internal IMMUTABLE STRICT AS 'first_value_generic' WITH (OID=7130, proiswin="t");

 CREATE FUNCTION first_value_polygon(internal, polygon) RETURNS polygon LANGUAGE internal IMMUTABLE STRICT AS 'first_value_generic' WITH (OID=7131, proiswin="t");

 CREATE FUNCTION first_value_reltime(internal, reltime) RETURNS reltime LANGUAGE internal IMMUTABLE STRICT AS 'first_value_generic' WITH (OID=7132, proiswin="t");

 CREATE FUNCTION first_value_text(internal, text) RETURNS text LANGUAGE internal IMMUTABLE STRICT AS 'first_value_generic' WITH (OID=7133, proiswin="t");

 CREATE FUNCTION first_value_tid(internal, tid) RETURNS tid LANGUAGE internal IMMUTABLE STRICT AS 'first_value_generic' WITH (OID=7134, proiswin="t");

 CREATE FUNCTION first_value_time(internal, "time") RETURNS "time" LANGUAGE internal IMMUTABLE STRICT AS 'first_value_generic' WITH (OID=7135, proiswin="t");

 CREATE FUNCTION first_value_timestamp(internal, "timestamp") RETURNS "timestamp" LANGUAGE internal IMMUTABLE STRICT AS 'first_value_generic' WITH (OID=7136, proiswin="t");

 CREATE FUNCTION first_value_timestamptz(internal, timestamptz) RETURNS timestamptz LANGUAGE internal IMMUTABLE STRICT AS 'first_value_generic' WITH (OID=7137, proiswin="t");

 CREATE FUNCTION first_value_timetz(internal, timetz) RETURNS timetz LANGUAGE internal IMMUTABLE STRICT AS 'first_value_generic' WITH (OID=7138, proiswin="t");

 CREATE FUNCTION first_value_varbit(internal, varbit) RETURNS varbit LANGUAGE internal IMMUTABLE STRICT AS 'first_value_generic' WITH (OID=7139, proiswin="t");

 CREATE FUNCTION first_value_varchar(internal, "varchar") RETURNS "varchar" LANGUAGE internal IMMUTABLE STRICT AS 'first_value_generic' WITH (OID=7140, proiswin="t");

 CREATE FUNCTION first_value_xid(internal, xid) RETURNS xid LANGUAGE internal IMMUTABLE STRICT AS 'first_value_generic' WITH (OID=7141, proiswin="t");

 CREATE FUNCTION first_value_bytea(internal, bytea) RETURNS bytea LANGUAGE internal IMMUTABLE STRICT AS 'first_value_generic' WITH (OID=7233, proiswin="t");

 CREATE FUNCTION first_value_bit(internal, "bit") RETURNS "bit" LANGUAGE internal IMMUTABLE STRICT AS 'first_value_generic' WITH (OID=7257, proiswin="t");

 CREATE FUNCTION first_value_box(internal, box) RETURNS box LANGUAGE internal IMMUTABLE STRICT AS 'first_value_generic' WITH (OID=7273, proiswin="t");

 CREATE FUNCTION first_value_any(internal, anyarray) RETURNS anyarray LANGUAGE internal IMMUTABLE STRICT AS 'first_value_generic' WITH (OID=7289, proiswin="t");

 CREATE FUNCTION last_value_int(internal, int4) RETURNS int4 LANGUAGE internal IMMUTABLE STRICT AS 'last_value_generic' WITH (OID=7103, proiswin="t");

 CREATE FUNCTION last_value_smallint(internal, int2) RETURNS int2 LANGUAGE internal IMMUTABLE STRICT AS 'last_value_generic' WITH (OID=7107, proiswin="t");

 CREATE FUNCTION last_value_bigint(internal, int8) RETURNS int8 LANGUAGE internal IMMUTABLE STRICT AS 'last_value_generic' WITH (OID=7108, proiswin="t");

 CREATE FUNCTION last_value_numeric(internal, "numeric") RETURNS "numeric" LANGUAGE internal IMMUTABLE STRICT AS 'last_value_generic' WITH (OID=7109, proiswin="t");

 CREATE FUNCTION last_value_text(internal, text) RETURNS text LANGUAGE internal IMMUTABLE STRICT AS 'last_value_generic' WITH (OID=7110, proiswin="t");

 CREATE FUNCTION last_value_bool(internal, bool) RETURNS bool LANGUAGE internal IMMUTABLE STRICT AS 'last_value_generic' WITH (OID=7165, proiswin="t");

 CREATE FUNCTION last_value_char(internal, "char") RETURNS "char" LANGUAGE internal IMMUTABLE STRICT AS 'last_value_generic' WITH (OID=7166, proiswin="t");

 CREATE FUNCTION last_value_cidr(internal, cidr) RETURNS cidr LANGUAGE internal IMMUTABLE STRICT AS 'last_value_generic' WITH (OID=7167, proiswin="t");

 CREATE FUNCTION last_value_circle(internal, circle) RETURNS circle LANGUAGE internal IMMUTABLE STRICT AS 'last_value_generic' WITH (OID=7168, proiswin="t");

 CREATE FUNCTION last_value_float4(internal, float4) RETURNS float4 LANGUAGE internal IMMUTABLE STRICT AS 'last_value_generic' WITH (OID=7142, proiswin="t");

 CREATE FUNCTION last_value_float8(internal, float8) RETURNS float8 LANGUAGE internal IMMUTABLE STRICT AS 'last_value_generic' WITH (OID=7143, proiswin="t");

 CREATE FUNCTION last_value_inet(internal, inet) RETURNS inet LANGUAGE internal IMMUTABLE STRICT AS 'last_value_generic' WITH (OID=7144, proiswin="t");

 CREATE FUNCTION last_value_interval(internal, "interval") RETURNS "interval" LANGUAGE internal IMMUTABLE STRICT AS 'last_value_generic' WITH (OID=7145, proiswin="t");

 CREATE FUNCTION last_value_line(internal, line) RETURNS line LANGUAGE internal IMMUTABLE STRICT AS 'last_value_generic' WITH (OID=7146, proiswin="t");

 CREATE FUNCTION last_value_lseg(internal, lseg) RETURNS lseg LANGUAGE internal IMMUTABLE STRICT AS 'last_value_generic' WITH (OID=7147, proiswin="t");

 CREATE FUNCTION last_value_macaddr(internal, macaddr) RETURNS macaddr LANGUAGE internal IMMUTABLE STRICT AS 'last_value_generic' WITH (OID=7148, proiswin="t");

 CREATE FUNCTION last_value_money(internal, money) RETURNS money LANGUAGE internal IMMUTABLE STRICT AS 'last_value_generic' WITH (OID=7149, proiswin="t");

 CREATE FUNCTION last_value_name(internal, name) RETURNS name LANGUAGE internal IMMUTABLE STRICT AS 'last_value_generic' WITH (OID=7150, proiswin="t");

 CREATE FUNCTION last_value_oid(internal, oid) RETURNS oid LANGUAGE internal IMMUTABLE STRICT AS 'last_value_generic' WITH (OID=7151, proiswin="t");

 CREATE FUNCTION last_value_path(internal, path) RETURNS path LANGUAGE internal IMMUTABLE STRICT AS 'last_value_generic' WITH (OID=7152, proiswin="t");

 CREATE FUNCTION last_value_point(internal, point) RETURNS point LANGUAGE internal IMMUTABLE STRICT AS 'last_value_generic' WITH (OID=7153, proiswin="t");

 CREATE FUNCTION last_value_polygon(internal, polygon) RETURNS polygon LANGUAGE internal IMMUTABLE STRICT AS 'last_value_generic' WITH (OID=7154, proiswin="t");

 CREATE FUNCTION last_value_reltime(internal, reltime) RETURNS reltime LANGUAGE internal IMMUTABLE STRICT AS 'last_value_generic' WITH (OID=7155, proiswin="t");

 CREATE FUNCTION last_value_tid(internal, tid) RETURNS tid LANGUAGE internal IMMUTABLE STRICT AS 'last_value_generic' WITH (OID=7157, proiswin="t");

 CREATE FUNCTION last_value_time(internal, "time") RETURNS "time" LANGUAGE internal IMMUTABLE STRICT AS 'last_value_generic' WITH (OID=7158, proiswin="t");

 CREATE FUNCTION last_value_timestamp(internal, "timestamp") RETURNS "timestamp" LANGUAGE internal IMMUTABLE STRICT AS 'last_value_generic' WITH (OID=7159, proiswin="t");

 CREATE FUNCTION last_value_timestamptz(internal, timestamptz) RETURNS timestamptz LANGUAGE internal IMMUTABLE STRICT AS 'last_value_generic' WITH (OID=7160, proiswin="t");

 CREATE FUNCTION last_value_timetz(internal, timetz) RETURNS timetz LANGUAGE internal IMMUTABLE STRICT AS 'last_value_generic' WITH (OID=7161, proiswin="t");

 CREATE FUNCTION last_value_varbit(internal, varbit) RETURNS varbit LANGUAGE internal IMMUTABLE STRICT AS 'last_value_generic' WITH (OID=7162, proiswin="t");

 CREATE FUNCTION last_value_varchar(internal, "varchar") RETURNS "varchar" LANGUAGE internal IMMUTABLE STRICT AS 'last_value_generic' WITH (OID=7163, proiswin="t");

 CREATE FUNCTION last_value_xid(internal, xid) RETURNS xid LANGUAGE internal IMMUTABLE STRICT AS 'last_value_generic' WITH (OID=7164, proiswin="t");

 CREATE FUNCTION last_value_bytea(internal, bytea) RETURNS bytea LANGUAGE internal IMMUTABLE STRICT AS 'last_value_generic' WITH (OID=7239, proiswin="t");

 CREATE FUNCTION last_value_bit(internal, "bit") RETURNS "bit" LANGUAGE internal IMMUTABLE STRICT AS 'last_value_generic' WITH (OID=7259, proiswin="t");

 CREATE FUNCTION last_value_box(internal, box) RETURNS box LANGUAGE internal IMMUTABLE STRICT AS 'last_value_generic' WITH (OID=7275, proiswin="t");

 CREATE FUNCTION last_value_any(internal, anyarray) RETURNS anyarray LANGUAGE internal IMMUTABLE STRICT AS 'last_value_generic' WITH (OID=7291, proiswin="t");

 CREATE FUNCTION cume_dist_prelim(internal) RETURNS int8 LANGUAGE internal IMMUTABLE STRICT AS 'cume_dist_prelim' WITH (OID=7204, DESCRIPTION="window preliminary function");
-- #define CUME_DIST_PRELIM_OID 7204
-- #define CUME_DIST_PRELIM_TYPE 20

 CREATE FUNCTION ntile_prelim_int(internal, int4) RETURNS _int8 LANGUAGE internal IMMUTABLE STRICT AS 'ntile_prelim_int' WITH (OID=7205, DESCRIPTION="window preliminary function");

 CREATE FUNCTION ntile_prelim_bigint(internal, int8) RETURNS _int8 LANGUAGE internal IMMUTABLE STRICT AS 'ntile_prelim_bigint' WITH (OID=7206, DESCRIPTION="window preliminary function");

 CREATE FUNCTION ntile_prelim_numeric(internal, "numeric") RETURNS _int8 LANGUAGE internal IMMUTABLE STRICT AS 'ntile_prelim_numeric' WITH (OID=7207, DESCRIPTION="window preliminary function");

 CREATE FUNCTION percent_rank_final(int8, int8) RETURNS float8 LANGUAGE internal IMMUTABLE STRICT AS 'percent_rank_final' WITH (OID=7303, DESCRIPTION="window final function");

 CREATE FUNCTION cume_dist_final(int8, int8) RETURNS float8 LANGUAGE internal IMMUTABLE STRICT AS 'cume_dist_final' WITH (OID=7304, DESCRIPTION="window final function");

 CREATE FUNCTION ntile_final(_int8, int8) RETURNS int8 LANGUAGE internal IMMUTABLE STRICT AS 'ntile_final' WITH (OID=7305, DESCRIPTION="window final function");

 CREATE FUNCTION get_ao_distribution(IN reloid oid, OUT segmentid int4, OUT tupcount int8) RETURNS SETOF pg_catalog.record LANGUAGE internal VOLATILE READS SQL DATA AS 'get_ao_distribution_oid' WITH (OID=7169, DESCRIPTION="show append only table tuple distribution across segment databases");

 CREATE FUNCTION get_ao_distribution(IN relname text, OUT segmentid int4, OUT tupcount int8) RETURNS SETOF pg_catalog.record LANGUAGE internal VOLATILE READS SQL DATA AS 'get_ao_distribution_name' WITH (OID=7170, DESCRIPTION="show append only table tuple distribution across segment databases");

 CREATE FUNCTION get_ao_compression_ratio(oid) RETURNS float8 LANGUAGE internal VOLATILE STRICT READS SQL DATA AS 'get_ao_compression_ratio_oid' WITH (OID=7171, DESCRIPTION="show append only table compression ratio");

 CREATE FUNCTION get_ao_compression_ratio(text) RETURNS float8 LANGUAGE internal VOLATILE STRICT READS SQL DATA AS 'get_ao_compression_ratio_name' WITH (OID=7172, DESCRIPTION="show append only table compression ratio");

 CREATE FUNCTION gp_update_ao_master_stats(oid) RETURNS int8 LANGUAGE internal VOLATILE MODIFIES SQL DATA AS 'gp_update_ao_master_stats_oid' WITH (OID=7173, DESCRIPTION="append only tables utility function");

 CREATE FUNCTION gp_update_ao_master_stats(text) RETURNS int8 LANGUAGE internal VOLATILE MODIFIES SQL DATA AS 'gp_update_ao_master_stats_name' WITH (OID=7174, DESCRIPTION="append only tables utility function");

 CREATE FUNCTION gp_persistent_build_db(bool) RETURNS int4 LANGUAGE internal VOLATILE AS 'gp_persistent_build_db' WITH (OID=7178, DESCRIPTION="populate the persistent tables and gp_relation_node for the current database");

 CREATE FUNCTION gp_persistent_build_all(bool) RETURNS int4 LANGUAGE internal VOLATILE AS 'gp_persistent_build_all' WITH (OID=7179, DESCRIPTION="populate the persistent tables and gp_relation_node for the whole database instance");

 CREATE FUNCTION gp_persistent_reset_all() RETURNS int4 LANGUAGE internal VOLATILE AS 'gp_persistent_reset_all' WITH (OID=7180, DESCRIPTION="Remove the persistent tables and gp_relation_node for the whole database instance");

 CREATE FUNCTION gp_persistent_repair_delete(int4, tid) RETURNS int4 LANGUAGE internal VOLATILE AS 'gp_persistent_repair_delete' WITH (OID=7181, DESCRIPTION="Remove an entry specified by TID from a persistent table for the current database instance");

 CREATE FUNCTION xmlexists(text, xml) RETURNS bool LANGUAGE internal IMMUTABLE STRICT AS 'xmlexists' WITH (OID=2985, DESCRIPTION="test XML value against XPath expression");

 CREATE FUNCTION xpath_exists(text, xml, _text) RETURNS bool LANGUAGE internal IMMUTABLE STRICT AS 'xpath_exists' WITH (OID=2986, DESCRIPTION="test XML value against XPath expression, with namespace support");

 CREATE FUNCTION xpath_exists(text, xml) RETURNS bool LANGUAGE sql IMMUTABLE STRICT AS $$select pg_catalog.xpath_exists($1, $2, '{}'::pg_catalog.text[])$$ WITH (OID=3049, DESCRIPTION="test XML value against XPath expression");

 CREATE FUNCTION xml_is_well_formed(text) RETURNS bool LANGUAGE internal IMMUTABLE STRICT AS 'xml_is_well_formed' WITH (OID=2988, DESCRIPTION="determine if a string is well formed XML");

 CREATE FUNCTION xml_is_well_formed_document(text) RETURNS bool LANGUAGE internal IMMUTABLE STRICT AS 'xml_is_well_formed_document' WITH (OID=2989, DESCRIPTION="determine if a string is well formed XML document");

 CREATE FUNCTION xml_is_well_formed_content(text) RETURNS bool LANGUAGE internal IMMUTABLE STRICT AS 'xml_is_well_formed_content' WITH (OID=2990, DESCRIPTION="determine if a string is well formed XML content");


-- the bitmap index access method routines
 CREATE FUNCTION bmgettuple(internal, internal) RETURNS bool LANGUAGE internal VOLATILE STRICT AS 'bmgettuple' WITH (OID=3050, DESCRIPTION="bitmap(internal)");

 CREATE FUNCTION bmgetmulti(internal, internal) RETURNS internal LANGUAGE internal VOLATILE STRICT AS 'bmgetmulti' WITH (OID=3051, DESCRIPTION="bitmap(internal)");

 CREATE FUNCTION bminsert(internal, internal, internal, internal, internal, internal) RETURNS bool LANGUAGE internal VOLATILE STRICT AS 'bminsert' WITH (OID=3001, DESCRIPTION="bitmap(internal)");

 CREATE FUNCTION bmbeginscan(internal, internal, internal) RETURNS internal LANGUAGE internal VOLATILE STRICT AS 'bmbeginscan' WITH (OID=3002, DESCRIPTION="bitmap(internal)");

 CREATE FUNCTION bmrescan(internal, internal) RETURNS void LANGUAGE internal VOLATILE STRICT AS 'bmrescan' WITH (OID=3003, DESCRIPTION="bitmap(internal)");

 CREATE FUNCTION bmendscan(internal) RETURNS void LANGUAGE internal VOLATILE STRICT AS 'bmendscan' WITH (OID=3004, DESCRIPTION="bitmap(internal)");

 CREATE FUNCTION bmmarkpos(internal) RETURNS void LANGUAGE internal VOLATILE STRICT AS 'bmmarkpos' WITH (OID=3005, DESCRIPTION="bitmap(internal)");

 CREATE FUNCTION bmrestrpos(internal) RETURNS void LANGUAGE internal VOLATILE STRICT AS 'bmrestrpos' WITH (OID=3006, DESCRIPTION="bitmap(internal)");

 CREATE FUNCTION bmbuild(internal, internal, internal) RETURNS internal LANGUAGE internal VOLATILE STRICT AS 'bmbuild' WITH (OID=3007, DESCRIPTION="bitmap(internal)");

 CREATE FUNCTION bmbulkdelete(internal, internal, internal, internal) RETURNS internal LANGUAGE internal VOLATILE STRICT AS 'bmbulkdelete' WITH (OID=3008, DESCRIPTION="bitmap(internal)");

 CREATE FUNCTION bmvacuumcleanup(internal, internal) RETURNS internal LANGUAGE internal VOLATILE STRICT AS 'bmvacuumcleanup' WITH (OID=3009);

 CREATE FUNCTION bmcostestimate(internal, internal, internal, internal, internal, internal, internal, internal) RETURNS void LANGUAGE internal VOLATILE STRICT AS 'bmcostestimate' WITH (OID=3010, DESCRIPTION="bitmap(internal)");

 CREATE FUNCTION bmoptions(_text, bool) RETURNS bytea LANGUAGE internal STABLE STRICT AS 'bmoptions' WITH (OID=3011, DESCRIPTION="btree(internal)");

-- AOCS functions.

 CREATE FUNCTION aocsvpinfo_decode(varbit, int4, int4) RETURNS int8 LANGUAGE internal IMMUTABLE STRICT AS 'aocsvpinfo_decode' WITH (OID=9900);

-- raises deprecation error
 CREATE FUNCTION gp_deprecated() RETURNS void LANGUAGE internal IMMUTABLE AS 'gp_deprecated' WITH (OID=9997, DESCRIPTION="raises function deprecation error");

-- A convenient utility
 CREATE FUNCTION pg_objname_to_oid(text) RETURNS oid LANGUAGE internal IMMUTABLE STRICT AS 'pg_objname_to_oid' WITH (OID=9998, DESCRIPTION="convert an object name to oid");

-- Fault injection
 CREATE FUNCTION gp_fault_inject(int4, int8) RETURNS int8 LANGUAGE internal VOLATILE STRICT AS 'gp_fault_inject' WITH (OID=9999, DESCRIPTION="Greenplum fault testing only");

-- Analyze related
 CREATE FUNCTION gp_statistics_estimate_reltuples_relpages_oid(oid) RETURNS _float4 LANGUAGE internal VOLATILE STRICT AS 'gp_statistics_estimate_reltuples_relpages_oid' WITH (OID=5032, DESCRIPTION="Return reltuples/relpages information for relation.");

-- Backoff related
 CREATE FUNCTION gp_adjust_priority(int4, int4, int4) RETURNS int4 LANGUAGE internal VOLATILE STRICT AS 'gp_adjust_priority_int' WITH (OID=5040, DESCRIPTION="change weight of all the backends for a given session id");

 CREATE FUNCTION gp_adjust_priority(int4, int4, text) RETURNS int4 LANGUAGE internal VOLATILE STRICT AS 'gp_adjust_priority_value' WITH (OID=5041, DESCRIPTION="change weight of all the backends for a given session id");

 CREATE FUNCTION gp_list_backend_priorities() RETURNS SETOF record LANGUAGE internal VOLATILE AS 'gp_list_backend_priorities' WITH (OID=5042, DESCRIPTION="list priorities of backends");


-- elog related
 CREATE FUNCTION gp_elog(text) RETURNS void LANGUAGE internal IMMUTABLE STRICT AS 'gp_elog' WITH (OID=5044, DESCRIPTION="Insert text into the error log");

 CREATE FUNCTION gp_elog(text, bool) RETURNS void LANGUAGE internal IMMUTABLE STRICT AS 'gp_elog' WITH (OID=5045, DESCRIPTION="Insert text into the error log");

-- Segment and master administration functions, see utils/gp/segadmin.c
 CREATE FUNCTION gp_add_master_standby(text, text, _text) RETURNS int2 LANGUAGE internal VOLATILE AS 'gp_add_master_standby' WITH (OID=5046, DESCRIPTION="Perform the catalog operations necessary for adding a new standby");

 CREATE FUNCTION gp_add_master_standby(text, text, _text, int4) RETURNS int2 LANGUAGE internal VOLATILE AS 'gp_add_master_standby_port' WITH (OID=5038, DESCRIPTION="Perform the catalog operations necessary for adding a new standby");

 CREATE FUNCTION gp_remove_master_standby() RETURNS bool LANGUAGE internal VOLATILE AS 'gp_remove_master_standby' WITH (OID=5047, DESCRIPTION="Remove a master standby from the system catalog");

 CREATE FUNCTION gp_add_segment_mirror(int2, text, text, int4, int4, _text) RETURNS int2 LANGUAGE internal VOLATILE AS 'gp_add_segment_mirror' WITH (OID=5048, DESCRIPTION="Perform the catalog operations necessary for adding a new segment mirror");

 CREATE FUNCTION gp_remove_segment_mirror(int2) RETURNS bool LANGUAGE internal VOLATILE AS 'gp_remove_segment_mirror' WITH (OID=5049, DESCRIPTION="Remove a segment mirror from the system catalog");

 CREATE FUNCTION gp_add_segment(text, text, int4, _text) RETURNS int2 LANGUAGE internal VOLATILE AS 'gp_add_segment' WITH (OID=5050, DESCRIPTION="Perform the catalog operations necessary for adding a new primary segment");

 CREATE FUNCTION gp_remove_segment(int2) RETURNS bool LANGUAGE internal VOLATILE AS 'gp_remove_segment' WITH (OID=5051, DESCRIPTION="Remove a primary segment from the system catalog");

 CREATE FUNCTION gp_prep_new_segment(_text) RETURNS bool LANGUAGE internal VOLATILE AS 'gp_prep_new_segment' WITH (OID=5052, DESCRIPTION="Convert a cloned master catalog for use as a segment");

 CREATE FUNCTION gp_activate_standby() RETURNS bool LANGUAGE internal VOLATILE AS 'gp_activate_standby' WITH (OID=5053, DESCRIPTION="Activate a standby");

-- We cheat in the following two functions: they are technically volatile but
-- we can only dispatch them if they're immutable :(.


 CREATE FUNCTION gp_add_segment_persistent_entries(int2, int2, _text) RETURNS bool LANGUAGE internal IMMUTABLE AS 'gp_add_segment_persistent_entries' WITH (OID=5054, DESCRIPTION="Persist object nodes on a segment");

 CREATE FUNCTION gp_remove_segment_persistent_entries(int2, int2) RETURNS bool LANGUAGE internal IMMUTABLE AS 'gp_remove_segment_persistent_entries' WITH (OID=5055, DESCRIPTION="Remove persistent object node references at a segment");

-- persistent table repair functions

 CREATE FUNCTION gp_add_persistent_filespace_node_entry(tid, oid, int2, text, int2, text, int2, int8, int2, int4, int4, int8) RETURNS bool LANGUAGE internal VOLATILE AS 'gp_add_persistent_filespace_node_entry' WITH (OID=5056, DESCRIPTION="Add a new entry to gp_persistent_filespace_node");

 CREATE FUNCTION gp_add_persistent_tablespace_node_entry(tid, oid, oid, int2, int8, int2, int4, int4, int8) RETURNS bool LANGUAGE internal VOLATILE AS 'gp_add_persistent_tablespace_node_entry' WITH (OID=5057, DESCRIPTION="Add a new entry to gp_persistent_tablespace_node");

 CREATE FUNCTION gp_add_persistent_database_node_entry(tid, oid, oid, int2, int8, int2, int4, int4, int8) RETURNS bool LANGUAGE internal VOLATILE AS 'gp_add_persistent_database_node_entry' WITH (OID=5058, DESCRIPTION="Add a new entry to gp_persistent_database_node");

 CREATE FUNCTION gp_add_persistent_relation_node_entry(tid, oid, oid, oid, int4, int2, int2, int8, int2, int2, bool, int8, gpxlogloc, int4, int8, int8, int4, int4, int8) RETURNS bool LANGUAGE internal VOLATILE AS 'gp_add_persistent_relation_node_entry' WITH (OID=5059, DESCRIPTION="Add a new entry to gp_persistent_relation_node");

 CREATE FUNCTION gp_add_global_sequence_entry(tid, int8) RETURNS bool LANGUAGE internal VOLATILE AS 'gp_add_global_sequence_entry' WITH (OID=5060, DESCRIPTION="Add a new entry to gp_global_sequence");

 CREATE FUNCTION gp_add_relation_node_entry(tid, oid, oid, int4, int8, tid, int8) RETURNS bool LANGUAGE internal VOLATILE AS 'gp_add_relation_node_entry' WITH (OID=5061, DESCRIPTION="Add a new entry to gp_relation_node");

 CREATE FUNCTION gp_update_persistent_filespace_node_entry(tid, oid, int2, text, int2, text, int2, int8, int2, int4, int4, int8) RETURNS bool LANGUAGE internal VOLATILE AS 'gp_update_persistent_filespace_node_entry' WITH (OID=5062, DESCRIPTION="Update an entry in gp_persistent_filespace_node");

 CREATE FUNCTION gp_update_persistent_tablespace_node_entry(tid, oid, oid, int2, int8, int2, int4, int4, int8) RETURNS bool LANGUAGE internal VOLATILE AS 'gp_update_persistent_tablespace_node_entry' WITH (OID=5063, DESCRIPTION="Update an entry in gp_persistent_tablespace_node");

 CREATE FUNCTION gp_update_persistent_database_node_entry(tid, oid, oid, int2, int8, int2, int4, int4, int8) RETURNS bool LANGUAGE internal VOLATILE AS 'gp_update_persistent_database_node_entry' WITH (OID=5064, DESCRIPTION="Update an entry in gp_persistent_database_node");

 CREATE FUNCTION gp_update_persistent_relation_node_entry(tid, oid, oid, oid, int4, int2, int2, int8, int2, int2, bool, int8, gpxlogloc, int4, int8, int8, int4, int4, int8) RETURNS bool LANGUAGE internal VOLATILE AS 'gp_update_persistent_relation_node_entry' WITH (OID=5065, DESCRIPTION="Update an entry in gp_persistent_relation_node");

 CREATE FUNCTION gp_update_global_sequence_entry(tid, int8) RETURNS bool LANGUAGE internal VOLATILE AS 'gp_update_global_sequence_entry' WITH (OID=5066, DESCRIPTION="Update an entry in gp_global_sequence");

 CREATE FUNCTION gp_update_relation_node_entry(tid, oid, oid, int4, int8, tid, int8) RETURNS bool LANGUAGE internal VOLATILE AS 'gp_update_relation_node_entry' WITH (OID=5067, DESCRIPTION="Update an entry in gp_relation_node");

 CREATE FUNCTION gp_delete_persistent_filespace_node_entry(tid) RETURNS bool LANGUAGE internal VOLATILE AS 'gp_delete_persistent_filespace_node_entry' WITH (OID=5068, DESCRIPTION="Remove an entry from gp_persistent_filespace_node");

 CREATE FUNCTION gp_delete_persistent_tablespace_node_entry(tid) RETURNS bool LANGUAGE internal VOLATILE AS 'gp_delete_persistent_tablespace_node_entry' WITH (OID=5069, DESCRIPTION="Remove an entry from gp_persistent_tablespace_node");

 CREATE FUNCTION gp_delete_persistent_database_node_entry(tid) RETURNS bool LANGUAGE internal VOLATILE AS 'gp_delete_persistent_database_node_entry' WITH (OID=5070, DESCRIPTION="Remove an entry from gp_persistent_database_node");

 CREATE FUNCTION gp_delete_persistent_relation_node_entry(tid) RETURNS bool LANGUAGE internal VOLATILE AS 'gp_delete_persistent_relation_node_entry' WITH (OID=5071, DESCRIPTION="Remove an entry from gp_persistent_relation_node");

 CREATE FUNCTION gp_delete_global_sequence_entry(tid) RETURNS bool LANGUAGE internal VOLATILE AS 'gp_delete_global_sequence_entry' WITH (OID=5072, DESCRIPTION="Remove an entry from gp_global_sequence");

 CREATE FUNCTION gp_delete_relation_node_entry(tid) RETURNS bool LANGUAGE internal VOLATILE AS 'gp_delete_relation_node_entry' WITH (OID=5073, DESCRIPTION="Remove an entry from gp_relation_node");

 CREATE FUNCTION gp_persistent_relation_node_check() RETURNS SETOF gp_persistent_relation_node LANGUAGE internal VOLATILE AS 'gp_persistent_relation_node_check' WITH (OID=5074, DESCRIPTION="physical filesystem information");

CREATE FUNCTION gp_dbspecific_ptcat_verification() RETURNS bool LANGUAGE internal VOLATILE AS 'gp_dbspecific_ptcat_verification' WITH (OID=5075, DESCRIPTION="perform database specific PersistentTables-Catalog verification");

CREATE FUNCTION gp_nondbspecific_ptcat_verification() RETURNS bool LANGUAGE internal VOLATILE AS 'gp_nondbspecific_ptcat_verification' WITH (OID=5080, DESCRIPTION="perform non-database specific PersistentTables-Catalog verification");

 CREATE FUNCTION cosh(float8) RETURNS float8 LANGUAGE internal IMMUTABLE AS 'dcosh' WITH (OID=3539, DESCRIPTION="Hyperbolic cosine function");

 CREATE FUNCTION sinh(float8) RETURNS float8 LANGUAGE internal IMMUTABLE AS 'dsinh' WITH (OID=3540, DESCRIPTION="Hyperbolic sine function");

 CREATE FUNCTION tanh(float8) RETURNS float8 LANGUAGE internal IMMUTABLE AS 'dtanh' WITH (OID=3541, DESCRIPTION="Hyperbolic tangent function");

 CREATE FUNCTION anytable_in(cstring) RETURNS anytable LANGUAGE internal IMMUTABLE STRICT AS 'anytable_in' WITH (OID=3054, DESCRIPTION="anytable type serialization input function");

 CREATE FUNCTION anytable_out(anytable) RETURNS cstring LANGUAGE internal IMMUTABLE STRICT AS 'anytable_out' WITH (OID=3055, DESCRIPTION="anytable type serialization output function");

 CREATE FUNCTION gp_quicklz_constructor(internal, internal, bool) RETURNS internal LANGUAGE internal VOLATILE AS 'quicklz_constructor' WITH (OID=5076, DESCRIPTION="quicklz constructor");

 CREATE FUNCTION gp_quicklz_destructor(internal) RETURNS void LANGUAGE internal VOLATILE AS 'quicklz_destructor' WITH(OID=5077, DESCRIPTION="quicklz destructor");

 CREATE FUNCTION gp_quicklz_compress(internal, int4, internal, int4, internal, internal) RETURNS void LANGUAGE internal IMMUTABLE AS 'quicklz_compress' WITH(OID=5078, DESCRIPTION="quicklz compressor");

 CREATE FUNCTION gp_quicklz_decompress(internal, int4, internal, int4, internal, internal) RETURNS void LANGUAGE internal IMMUTABLE AS 'quicklz_decompress' WITH(OID=5079, DESCRIPTION="quicklz decompressor");

 CREATE FUNCTION gp_quicklz_validator(internal) RETURNS void LANGUAGE internal IMMUTABLE AS 'quicklz_validator' WITH(OID=9925, DESCRIPTION="quicklz compression validator");

 CREATE FUNCTION gp_zlib_constructor(internal, internal, bool) RETURNS internal LANGUAGE internal VOLATILE AS 'zlib_constructor' WITH (OID=9910, DESCRIPTION="zlib constructor");

 CREATE FUNCTION gp_zlib_destructor(internal) RETURNS void LANGUAGE internal VOLATILE AS 'zlib_destructor' WITH(OID=9911, DESCRIPTION="zlib destructor");

 CREATE FUNCTION gp_zlib_compress(internal, int4, internal, int4, internal, internal) RETURNS void LANGUAGE internal IMMUTABLE AS 'zlib_compress' WITH(OID=9912, DESCRIPTION="zlib compressor");

 CREATE FUNCTION gp_zlib_decompress(internal, int4, internal, int4, internal, internal) RETURNS void LANGUAGE internal IMMUTABLE AS 'zlib_decompress' WITH(OID=9913, DESCRIPTION="zlib decompressor");

 CREATE FUNCTION gp_zlib_validator(internal) RETURNS void LANGUAGE internal IMMUTABLE AS 'zlib_validator' WITH(OID=9924, DESCRIPTION="zlib compression validator");

 CREATE FUNCTION gp_rle_type_constructor(internal, internal, bool) RETURNS internal LANGUAGE internal VOLATILE AS 'rle_type_constructor' WITH (OID=9914, DESCRIPTION="Type specific RLE constructor");

 CREATE FUNCTION gp_rle_type_destructor(internal) RETURNS void LANGUAGE internal VOLATILE AS 'rle_type_destructor' WITH(OID=9915, DESCRIPTION="Type specific RLE destructor");

 CREATE FUNCTION gp_rle_type_compress(internal, int4, internal, int4, internal, internal) RETURNS void LANGUAGE internal IMMUTABLE AS 'rle_type_compress' WITH(OID=9916, DESCRIPTION="Type specific RLE compressor");

 CREATE FUNCTION gp_rle_type_decompress(internal, int4, internal, int4, internal, internal) RETURNS void LANGUAGE internal IMMUTABLE AS 'rle_type_decompress' WITH(OID=9917, DESCRIPTION="Type specific RLE decompressor");

 CREATE FUNCTION gp_rle_type_validator(internal) RETURNS void LANGUAGE internal IMMUTABLE AS 'rle_type_validator' WITH(OID=9923, DESCRIPTION="Type speific RLE compression validator");

 CREATE FUNCTION gp_dummy_compression_constructor(internal, internal, bool) RETURNS internal LANGUAGE internal VOLATILE AS 'dummy_compression_constructor' WITH (OID=3064, DESCRIPTION="Dummy compression destructor");

 CREATE FUNCTION gp_dummy_compression_destructor(internal) RETURNS internal LANGUAGE internal VOLATILE AS 'dummy_compression_destructor' WITH (OID=3065, DESCRIPTION="Dummy compression destructor");

 CREATE FUNCTION gp_dummy_compression_compress(internal, int4, internal, int4, internal, internal) RETURNS internal LANGUAGE internal VOLATILE AS 'dummy_compression_compress' WITH (OID=3066, DESCRIPTION="Dummy compression compressor");

 CREATE FUNCTION gp_dummy_compression_decompress(internal, int4, internal, int4, internal, internal) RETURNS internal LANGUAGE internal VOLATILE AS 'dummy_compression_decompress' WITH (OID=3067, DESCRIPTION="Dummy compression decompressor");

 CREATE FUNCTION gp_dummy_compression_validator(internal) RETURNS internal LANGUAGE internal VOLATILE AS 'dummy_compression_validator' WITH (OID=3068, DESCRIPTION="Dummy compression validator");

 CREATE FUNCTION linear_interpolate( anyelement, anyelement, int8, anyelement, int8 ) RETURNS int8 LANGUAGE internal IMMUTABLE STRICT AS 'linterp_int64' WITH (OID=6072, DESCRIPTION="linear interpolation: x, x0,y0, x1,y1"); 

 CREATE FUNCTION linear_interpolate( anyelement, anyelement, int4, anyelement, int4 ) RETURNS int4 LANGUAGE internal IMMUTABLE STRICT AS 'linterp_int32' WITH (OID=6073, DESCRIPTION="linear interpolation: x, x0,y0, x1,y1"); 

 CREATE FUNCTION linear_interpolate( anyelement, anyelement, int2, anyelement, int2 ) RETURNS int2 LANGUAGE internal IMMUTABLE STRICT AS 'linterp_int16' WITH (OID=6074, DESCRIPTION="linear interpolation: x, x0,y0, x1,y1"); 

 CREATE FUNCTION linear_interpolate( anyelement, anyelement, float8, anyelement, float8 ) RETURNS float8 LANGUAGE internal IMMUTABLE STRICT AS 'linterp_float8' WITH (OID=6075, DESCRIPTION="linear interpolation: x, x0,y0, x1,y1"); 

 CREATE FUNCTION linear_interpolate( anyelement, anyelement, float4, anyelement, float4 ) RETURNS float4 LANGUAGE internal IMMUTABLE STRICT AS 'linterp_float4' WITH (OID=6076, DESCRIPTION="linear interpolation: x, x0,y0, x1,y1"); 

 CREATE FUNCTION linear_interpolate( anyelement, anyelement, date, anyelement, date ) RETURNS date LANGUAGE internal IMMUTABLE STRICT AS 'linterp_DateADT' WITH (OID=6077, DESCRIPTION="linear interpolation: x, x0,y0, x1,y1"); 

 CREATE FUNCTION linear_interpolate( anyelement, anyelement, time, anyelement, time ) RETURNS time LANGUAGE internal IMMUTABLE STRICT AS 'linterp_TimeADT' WITH (OID=6078, DESCRIPTION="linear interpolation: x, x0,y0, x1,y1"); 

 CREATE FUNCTION linear_interpolate( anyelement, anyelement, timestamp, anyelement, timestamp ) RETURNS timestamp LANGUAGE internal IMMUTABLE STRICT AS 'linterp_Timestamp' WITH (OID=6079, DESCRIPTION="linear interpolation: x, x0,y0, x1,y1"); 

 CREATE FUNCTION linear_interpolate( anyelement, anyelement, timestamptz, anyelement, timestamptz ) RETURNS timestamptz LANGUAGE internal IMMUTABLE STRICT AS 'linterp_TimestampTz' WITH (OID=6080, DESCRIPTION="linear interpolation: x, x0,y0, x1,y1"); 

 CREATE FUNCTION linear_interpolate( anyelement, anyelement, "interval", anyelement, "interval" ) RETURNS "interval" LANGUAGE internal IMMUTABLE STRICT AS 'linterp_Interval' WITH (OID=6081, DESCRIPTION="linear interpolation: x, x0,y0, x1,y1"); 

 CREATE FUNCTION linear_interpolate( anyelement, anyelement, "numeric", anyelement, "numeric" ) RETURNS "numeric" LANGUAGE internal IMMUTABLE STRICT AS 'linterp_Numeric' WITH (OID=6082, DESCRIPTION="linear interpolation: x, x0,y0, x1,y1"); 

 CREATE FUNCTION lead_lag_frame_maker(internal) RETURNS internal LANGUAGE internal VOLATILE STRICT AS 'lead_lag_frame_maker' WITH (OID=5081);

 CREATE FUNCTION gp_dump_query_oids(text) RETURNS text LANGUAGE internal VOLATILE STRICT AS 'gp_dump_query_oids' WITH (OID = 6086, DESCRIPTION="List function and relation OIDs that a query depends on, as a JSON object");

 CREATE FUNCTION disable_xform(text) RETURNS text LANGUAGE internal IMMUTABLE STRICT AS 'disable_xform' WITH (OID=6087, DESCRIPTION="disables transformations in the optimizer");

 CREATE FUNCTION enable_xform(text) RETURNS text LANGUAGE internal IMMUTABLE STRICT AS 'enable_xform' WITH (OID=6088, DESCRIPTION="enables transformations in the optimizer");

 CREATE FUNCTION gp_opt_version() RETURNS text LANGUAGE internal IMMUTABLE STRICT AS 'gp_opt_version' WITH (OID=6089, DESCRIPTION="Returns the optimizer and gpos library versions");
 
 
  -- functions for the complex data type
 CREATE FUNCTION complex_in(cstring) RETURNS complex LANGUAGE internal IMMUTABLE STRICT AS 'complex_in' WITH (OID=3991, DESCRIPTION="I/O");
 
 CREATE FUNCTION complex_out(complex) RETURNS cstring LANGUAGE internal IMMUTABLE STRICT AS 'complex_out' WITH (OID=3548, DESCRIPTION="I/O");
 
 CREATE FUNCTION complex_recv(internal) RETURNS complex LANGUAGE internal IMMUTABLE STRICT AS 'complex_recv' WITH (OID=3549, DESCRIPTION="I/O");
 
 CREATE FUNCTION complex_send(complex) RETURNS bytea LANGUAGE internal IMMUTABLE STRICT AS 'complex_send' WITH (OID=3550, DESCRIPTION="I/O");

 CREATE FUNCTION complex(float8, float8) RETURNS complex LANGUAGE internal IMMUTABLE STRICT AS 'construct_complex' WITH (OID=3551, DESCRIPTION="constructs a complex number with given real part and imaginary part");
 
 CREATE FUNCTION complex_trig(float8, float8) RETURNS complex LANGUAGE internal IMMUTABLE STRICT AS 'construct_complex_trig' WITH (OID=3552, DESCRIPTION="constructs a complex number with given magnitude and phase");
 
 CREATE FUNCTION re(complex) RETURNS float8 LANGUAGE internal IMMUTABLE STRICT AS 'complex_re' WITH (OID=3553, DESCRIPTION="returns the real part of the argument");
 
 CREATE FUNCTION im(complex) RETURNS float8 LANGUAGE internal IMMUTABLE STRICT AS 'complex_im' WITH (OID=3554, DESCRIPTION="returns the imaginary part of the argument");
 
 CREATE FUNCTION radians(complex) RETURNS float8 LANGUAGE internal IMMUTABLE STRICT AS 'complex_arg' WITH (OID=3555, DESCRIPTION="returns the phase of the argument");
 
 CREATE FUNCTION complexabs(complex) RETURNS float8 LANGUAGE internal IMMUTABLE STRICT AS 'complex_mag' WITH (OID=3556, DESCRIPTION="returns the magnitude of the argument");
  
 CREATE FUNCTION abs(complex) RETURNS float8 LANGUAGE internal IMMUTABLE STRICT AS 'complex_mag' WITH (OID=3557, DESCRIPTION="returns the magnitude of the argument");
 
 CREATE FUNCTION conj(complex) RETURNS complex LANGUAGE internal IMMUTABLE STRICT AS 'complex_conj' WITH (OID=3558, DESCRIPTION="returns the conjunction of the argument");
 
 CREATE FUNCTION hashcomplex(complex) RETURNS int4 LANGUAGE internal IMMUTABLE STRICT AS 'complex_hash' WITH (OID=3559, DESCRIPTION="hash");
 
 CREATE FUNCTION complex_eq(complex, complex) RETURNS bool  LANGUAGE internal IMMUTABLE STRICT AS 'complex_eq' WITH (OID=3560, DESCRIPTION="equal");
 
 CREATE FUNCTION complex_ne(complex, complex) RETURNS bool  LANGUAGE internal IMMUTABLE STRICT AS 'complex_ne' WITH (OID=3561, DESCRIPTION="not equal");
 
 CREATE FUNCTION complex_pl(complex, complex) RETURNS complex LANGUAGE internal IMMUTABLE STRICT AS 'complex_pl' WITH (OID=3562, DESCRIPTION="plus");
 
 CREATE FUNCTION complex_up(complex) RETURNS complex LANGUAGE internal IMMUTABLE STRICT AS 'complex_up' WITH (OID=3563, DESCRIPTION="unary plus");
 
 CREATE FUNCTION complex_mi(complex, complex) RETURNS complex LANGUAGE internal IMMUTABLE STRICT AS 'complex_mi' WITH (OID=3564, DESCRIPTION="minus");
 
 CREATE FUNCTION complex_um(complex) RETURNS complex LANGUAGE internal IMMUTABLE STRICT AS 'complex_um' WITH (OID=3565, DESCRIPTION="unary minus");
 
 CREATE FUNCTION complex_mul(complex, complex) RETURNS complex LANGUAGE internal IMMUTABLE STRICT AS 'complex_mul' WITH (OID=3566, DESCRIPTION="multiply");
 
 CREATE FUNCTION complex_div(complex, complex) RETURNS complex LANGUAGE internal IMMUTABLE STRICT AS 'complex_div' WITH (OID=3567, DESCRIPTION="divide");
 
 CREATE FUNCTION complex_power(complex, complex) RETURNS complex LANGUAGE internal IMMUTABLE STRICT AS 'complex_pow' WITH (OID=3568, DESCRIPTION="exponentiation (x^y)");
 
 CREATE FUNCTION complex_sqrt(complex) RETURNS complex LANGUAGE internal IMMUTABLE STRICT AS 'complex_sqrt' WITH (OID=3569, DESCRIPTION="squre root");
 
 CREATE FUNCTION complex_cbrt(complex) RETURNS complex LANGUAGE internal IMMUTABLE STRICT AS 'complex_cbrt' WITH (OID=3570, DESCRIPTION="cube root");
 
 CREATE FUNCTION degrees(complex) RETURNS float8 LANGUAGE internal IMMUTABLE STRICT AS 'complex_degrees' WITH (OID=3571, DESCRIPTION="phase to degrees");
 
 CREATE FUNCTION exp(complex) RETURNS complex LANGUAGE internal IMMUTABLE STRICT AS 'complex_exp' WITH (OID=3572, DESCRIPTION="natural exponential (e^x)");
 
 CREATE FUNCTION ln(complex) RETURNS complex LANGUAGE internal IMMUTABLE STRICT AS 'complex_ln' WITH (OID=3573, DESCRIPTION="natural logarithm");
 
 CREATE FUNCTION log(complex) RETURNS complex LANGUAGE internal IMMUTABLE STRICT AS 'complex_log10' WITH (OID=3574, DESCRIPTION="base 10 logarithm");
 
 CREATE FUNCTION log(complex, complex) RETURNS complex LANGUAGE internal IMMUTABLE STRICT AS 'complex_log' WITH (OID=3575, DESCRIPTION="logarithm base arg1 of arg2");
 
 CREATE FUNCTION acos(complex) RETURNS complex LANGUAGE internal IMMUTABLE STRICT AS 'complex_acos' WITH (OID=3576, DESCRIPTION="acos");
 
 CREATE FUNCTION asin(complex) RETURNS complex LANGUAGE internal IMMUTABLE STRICT AS 'complex_asin' WITH (OID=3577, DESCRIPTION="asin");
 
 CREATE FUNCTION atan(complex) RETURNS complex LANGUAGE internal IMMUTABLE STRICT AS 'complex_atan' WITH (OID=3578, DESCRIPTION="atan");
 
 CREATE FUNCTION cos(complex) RETURNS complex LANGUAGE internal IMMUTABLE STRICT AS 'complex_cos' WITH (OID=3579, DESCRIPTION="cos");
 
 CREATE FUNCTION cot(complex) RETURNS complex LANGUAGE internal IMMUTABLE STRICT AS 'complex_cot' WITH (OID=3580, DESCRIPTION="cot");
 
 CREATE FUNCTION sin(complex) RETURNS complex LANGUAGE internal IMMUTABLE STRICT AS 'complex_sin' WITH (OID=3581, DESCRIPTION="sin");
 
 CREATE FUNCTION tan(complex) RETURNS complex LANGUAGE internal IMMUTABLE STRICT AS 'complex_tan' WITH (OID=3582, DESCRIPTION="tan");
 
 CREATE FUNCTION dotproduct(_complex, _complex) RETURNS complex LANGUAGE internal IMMUTABLE STRICT AS 'complex_dot_product' WITH (OID=3583, DESCRIPTION="dot product");
 
 CREATE FUNCTION float82complex(float8) RETURNS complex LANGUAGE internal IMMUTABLE STRICT AS 'float82complex' WITH (OID=3584, DESCRIPTION="(internal) type cast from float8 to complex");
 
 CREATE FUNCTION float42complex(float4) RETURNS complex LANGUAGE internal IMMUTABLE STRICT AS 'float42complex' WITH (OID=3585, DESCRIPTION="(internal) type cast from float4 to complex");
 
 CREATE FUNCTION int82complex(int8) RETURNS complex LANGUAGE internal IMMUTABLE STRICT AS 'int82complex' WITH (OID=3586, DESCRIPTION="(internal) type cast from int8 to complex");
 
 CREATE FUNCTION int42complex(int4) RETURNS complex LANGUAGE internal IMMUTABLE STRICT AS 'int42complex' WITH (OID=3587, DESCRIPTION="(internal) type cast from int4 to complex");
 
 CREATE FUNCTION int22complex(int2) RETURNS complex LANGUAGE internal IMMUTABLE STRICT AS 'int22complex' WITH (OID=3588, DESCRIPTION="(internal) type cast from int2 to complex");
 
 CREATE FUNCTION power(complex, complex) RETURNS complex LANGUAGE internal IMMUTABLE STRICT AS 'complex_pow' WITH (OID=3589, DESCRIPTION="exponentiation (x^y)");
 
 CREATE FUNCTION sqrt(complex) RETURNS complex LANGUAGE internal IMMUTABLE STRICT AS 'complex_sqrt' WITH (OID=3590, DESCRIPTION="squre root");
 
 CREATE FUNCTION cbrt(complex) RETURNS complex LANGUAGE internal IMMUTABLE STRICT AS 'complex_cbrt' WITH (OID=3591, DESCRIPTION="cube root"); 
 
 CREATE FUNCTION numeric2point("numeric") RETURNS complex LANGUAGE internal IMMUTABLE STRICT AS 'numeric2complex' WITH (OID=3592, DESCRIPTION="(internal) type cast from numeric to complex");
 
 CREATE FUNCTION complex_lt(complex, complex) RETURNS bool  LANGUAGE internal IMMUTABLE STRICT AS 'complex_lt' WITH (OID=3593, DESCRIPTION="less than");
 
 CREATE FUNCTION complex_gt(complex, complex) RETURNS bool  LANGUAGE internal IMMUTABLE STRICT AS 'complex_gt' WITH (OID=3594, DESCRIPTION="greater than");
 
 CREATE FUNCTION complex_lte(complex, complex) RETURNS bool  LANGUAGE internal IMMUTABLE STRICT AS 'complex_lte' WITH (OID=3595, DESCRIPTION="less than or equal");
 
 CREATE FUNCTION complex_gte(complex, complex) RETURNS bool  LANGUAGE internal IMMUTABLE STRICT AS 'complex_gte' WITH (OID=3596, DESCRIPTION="greater than or equal");

 -- functions for external table
 CREATE FUNCTION pg_options_to_table(IN options_array _text, OUT option_name text, OUT option_value text) RETURNS SETOF pg_catalog.record LANGUAGE internal IMMUTABLE STRICT AS 'pg_options_to_table' WITH (OID=2022, DESCRIPTION="convert generic options array to name/value table");
