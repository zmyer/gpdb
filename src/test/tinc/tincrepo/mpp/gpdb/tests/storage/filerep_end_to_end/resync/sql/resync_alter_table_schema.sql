-- start_ignore
SET gp_create_table_random_default_distribution=off;
-- end_ignore
--
-- RESYNC ALTER Schema name
--

--
-- HEAP TABLE - SET TO NEW SCHEMA
--

CREATE TABLE old_schema.resync_heap_alter_table_schema1(
 text_col text,
 bigint_col bigint,
 char_vary_col character varying(30),
 numeric_col numeric,
 int_col int4,
 float_col float4,
 int_array_col int[],
 before_rename_col int4,
 change_datatype_col numeric,
 a_ts_without timestamp without time zone,
 b_ts_with timestamp with time zone,
 date_column date,
 col_set_default numeric)DISTRIBUTED RANDOMLY;


insert into old_schema.resync_heap_alter_table_schema1 select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{1}',i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002',i from generate_series(1,10)i;

CREATE TABLE old_schema.resync_heap_alter_table_schema2(
 text_col text,
 bigint_col bigint,
 char_vary_col character varying(30),
 numeric_col numeric,
 int_col int4,
 float_col float4,
 int_array_col int[],
 before_rename_col int4,
 change_datatype_col numeric,
 a_ts_without timestamp without time zone,
 b_ts_with timestamp with time zone,
 date_column date,
 col_set_default numeric)DISTRIBUTED RANDOMLY;


insert into old_schema.resync_heap_alter_table_schema2 select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{1}',i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002',i from generate_series(1,10)i;


CREATE TABLE old_schema.resync_heap_alter_table_schema3(
 text_col text,
 bigint_col bigint,
 char_vary_col character varying(30),
 numeric_col numeric,
 int_col int4,
 float_col float4,
 int_array_col int[],
 before_rename_col int4,
 change_datatype_col numeric,
 a_ts_without timestamp without time zone,
 b_ts_with timestamp with time zone,
 date_column date,
 col_set_default numeric)DISTRIBUTED RANDOMLY;


insert into old_schema.resync_heap_alter_table_schema3 select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{1}',i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002',i from generate_series(1,10)i;



--
-- ALTER TABLE TO NEW SCHEMA
--
ALTER TABLE old_schema.sync1_heap_alter_table_schema6 SET SCHEMA new_schema;
ALTER TABLE old_schema.ck_sync1_heap_alter_table_schema5 SET SCHEMA new_schema;
ALTER TABLE old_schema.ct_heap_alter_table_schema3 SET SCHEMA new_schema;
ALTER TABLE old_schema.resync_heap_alter_table_schema1 SET SCHEMA new_schema;

--
-- AO TABLE - SET TO NEW SCHEMA
--

CREATE TABLE old_schema.resync_ao_alter_table_schema1(
 text_col text,
 bigint_col bigint,
 char_vary_col character varying(30),
 numeric_col numeric,
 int_col int4,
 float_col float4,
 int_array_col int[],
 before_rename_col int4,
 change_datatype_col numeric,
 a_ts_without timestamp without time zone,
 b_ts_with timestamp with time zone,
 date_column date,
 col_set_default numeric)DISTRIBUTED RANDOMLY;


insert into old_schema.resync_ao_alter_table_schema1 select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{1}',i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002',i from generate_series(1,10)i;

CREATE TABLE old_schema.resync_ao_alter_table_schema2(
 text_col text,
 bigint_col bigint,
 char_vary_col character varying(30),
 numeric_col numeric,
 int_col int4,
 float_col float4,
 int_array_col int[],
 before_rename_col int4,
 change_datatype_col numeric,
 a_ts_without timestamp without time zone,
 b_ts_with timestamp with time zone,
 date_column date,
 col_set_default numeric)DISTRIBUTED RANDOMLY;


insert into old_schema.resync_ao_alter_table_schema2 select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{1}',i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002',i from generate_series(1,10)i;


CREATE TABLE old_schema.resync_ao_alter_table_schema3(
 text_col text,
 bigint_col bigint,
 char_vary_col character varying(30),
 numeric_col numeric,
 int_col int4,
 float_col float4,
 int_array_col int[],
 before_rename_col int4,
 change_datatype_col numeric,
 a_ts_without timestamp without time zone,
 b_ts_with timestamp with time zone,
 date_column date,
 col_set_default numeric)DISTRIBUTED RANDOMLY;


insert into old_schema.resync_ao_alter_table_schema3 select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{1}',i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002',i from generate_series(1,10)i;


--
-- ALTER TABLE TO NEW SCHEMA
--
ALTER TABLE old_schema.sync1_ao_alter_table_schema6 SET SCHEMA new_schema;
ALTER TABLE old_schema.ck_sync1_ao_alter_table_schema5 SET SCHEMA new_schema;
ALTER TABLE old_schema.ct_ao_alter_table_schema3 SET SCHEMA new_schema;
ALTER TABLE old_schema.resync_ao_alter_table_schema1 SET SCHEMA new_schema;

--
-- CO TABLE - SET TO NEW SCHEMA
--

CREATE TABLE old_schema.resync_co_alter_table_schema1(
 text_col text,
 bigint_col bigint,
 char_vary_col character varying(30),
 numeric_col numeric,
 int_col int4,
 float_col float4,
 int_array_col int[],
 before_rename_col int4,
 change_datatype_col numeric,
 a_ts_without timestamp without time zone,
 b_ts_with timestamp with time zone,
 date_column date,
 col_set_default numeric)DISTRIBUTED RANDOMLY;


insert into old_schema.resync_co_alter_table_schema1 select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{1}',i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002',i from generate_series(1,10)i;

CREATE TABLE old_schema.resync_co_alter_table_schema2(
 text_col text,
 bigint_col bigint,
 char_vary_col character varying(30),
 numeric_col numeric,
 int_col int4,
 float_col float4,
 int_array_col int[],
 before_rename_col int4,
 change_datatype_col numeric,
 a_ts_without timestamp without time zone,
 b_ts_with timestamp with time zone,
 date_column date,
 col_set_default numeric)DISTRIBUTED RANDOMLY;


insert into old_schema.resync_co_alter_table_schema2 select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{1}',i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002',i from generate_series(1,10)i;


CREATE TABLE old_schema.resync_co_alter_table_schema3(
 text_col text,
 bigint_col bigint,
 char_vary_col character varying(30),
 numeric_col numeric,
 int_col int4,
 float_col float4,
 int_array_col int[],
 before_rename_col int4,
 change_datatype_col numeric,
 a_ts_without timestamp without time zone,
 b_ts_with timestamp with time zone,
 date_column date,
 col_set_default numeric)DISTRIBUTED RANDOMLY;


insert into old_schema.resync_co_alter_table_schema3 select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{1}',i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002',i from generate_series(1,10)i;

--
-- ALTER TABLE TO NEW SCHEMA
--
ALTER TABLE old_schema.sync1_co_alter_table_schema6 SET SCHEMA new_schema;
ALTER TABLE old_schema.ck_sync1_co_alter_table_schema5 SET SCHEMA new_schema;
ALTER TABLE old_schema.ct_co_alter_table_schema3 SET SCHEMA new_schema;
ALTER TABLE old_schema.resync_co_alter_table_schema1 SET SCHEMA new_schema;


