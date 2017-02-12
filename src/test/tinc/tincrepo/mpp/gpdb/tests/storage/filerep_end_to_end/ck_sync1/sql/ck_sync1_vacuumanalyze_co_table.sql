-- start_ignore
SET gp_create_table_random_default_distribution=off;
-- end_ignore
CREATE TABLE ck_sync1_co_vacuumanalyze1(
text_col text,
bigint_col bigint,
char_vary_col character varying(30),
numeric_col numeric,
int_col int4,
float_col float4,
int_array_col int[],
drop_col numeric,
before_rename_col int4,
change_datatype_col numeric,
a_ts_without timestamp without time zone,
b_ts_with timestamp with time zone,
date_column date) with ( appendonly='true', orientation='column')  distributed randomly;

INSERT INTO ck_sync1_co_vacuumanalyze1 values ('0_zero', 0, '0_zero', 0, 0, 0, '{0}', 0, 0, 0, '2004-10-19 10:23:54', '2004-10-19 10:23:54+02', '1-1-2000');
INSERT INTO ck_sync1_co_vacuumanalyze1 values ('1_zero', 1, '1_zero', 1, 1, 1, '{1}', 1, 1, 1, '2005-10-19 10:23:54', '2005-10-19 10:23:54+02', '1-1-2001');
INSERT INTO ck_sync1_co_vacuumanalyze1 values ('2_zero', 2, '2_zero', 2, 2, 2, '{2}', 2, 2, 2, '2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002');
INSERT INTO ck_sync1_co_vacuumanalyze1 select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{3}',i,i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002' from generate_series(3,100)i;



ALTER TABLE ck_sync1_co_vacuumanalyze1 ADD COLUMN added_col character varying(30) default 'test_value';
ALTER TABLE ck_sync1_co_vacuumanalyze1 DROP COLUMN drop_col ;
ALTER TABLE ck_sync1_co_vacuumanalyze1 RENAME COLUMN before_rename_col TO after_rename_col;
ALTER TABLE ck_sync1_co_vacuumanalyze1 ALTER COLUMN change_datatype_col TYPE int4;
ALTER TABLE ck_sync1_co_vacuumanalyze1 set with ( reorganize='true') distributed by (int_col);




INSERT INTO ck_sync1_co_vacuumanalyze1 values ('1_zero', 1, '1_zero', 1, 1, 1, '{1}',  1, 1, '2005-10-19 10:23:54', '2005-10-19 10:23:54+02', '1-1-2001');
INSERT INTO ck_sync1_co_vacuumanalyze1 values ('2_zero', 2, '2_zero', 2, 2, 2, '{2}',  2, 2, '2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002');
INSERT INTO ck_sync1_co_vacuumanalyze1 values ('3_zero', 3, '3_zero', 0, 0, 0, '{0}',  0, 0, '2004-10-19 10:23:54', '2004-10-19 10:23:54+02', '1-1-2000');





CREATE TABLE ck_sync1_co_vacuumanalyze2(
text_col text,
bigint_col bigint,
char_vary_col character varying(30),
numeric_col numeric,
int_col int4,
float_col float4,
int_array_col int[],
drop_col numeric,
before_rename_col int4,
change_datatype_col numeric,
a_ts_without timestamp without time zone,
b_ts_with timestamp with time zone,
date_column date) with ( appendonly='true', orientation='column')  distributed randomly;

INSERT INTO ck_sync1_co_vacuumanalyze2 values ('0_zero', 0, '0_zero', 0, 0, 0, '{0}', 0, 0, 0, '2004-10-19 10:23:54', '2004-10-19 10:23:54+02', '1-1-2000');
INSERT INTO ck_sync1_co_vacuumanalyze2 values ('1_zero', 1, '1_zero', 1, 1, 1, '{1}', 1, 1, 1, '2005-10-19 10:23:54', '2005-10-19 10:23:54+02', '1-1-2001');
INSERT INTO ck_sync1_co_vacuumanalyze2 values ('2_zero', 2, '2_zero', 2, 2, 2, '{2}', 2, 2, 2, '2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002');
INSERT INTO ck_sync1_co_vacuumanalyze2 select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{3}',i,i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002' from generate_series(3,100)i;



ALTER TABLE ck_sync1_co_vacuumanalyze2 ADD COLUMN added_col character varying(30) default 'test_value';
ALTER TABLE ck_sync1_co_vacuumanalyze2 DROP COLUMN drop_col ;
ALTER TABLE ck_sync1_co_vacuumanalyze2 RENAME COLUMN before_rename_col TO after_rename_col;
ALTER TABLE ck_sync1_co_vacuumanalyze2 ALTER COLUMN change_datatype_col TYPE int4;
ALTER TABLE ck_sync1_co_vacuumanalyze2 set with ( reorganize='true') distributed by (int_col);




INSERT INTO ck_sync1_co_vacuumanalyze2 values ('1_zero', 1, '1_zero', 1, 1, 1, '{1}',  1, 1, '2005-10-19 10:23:54', '2005-10-19 10:23:54+02', '1-1-2001');
INSERT INTO ck_sync1_co_vacuumanalyze2 values ('2_zero', 2, '2_zero', 2, 2, 2, '{2}',  2, 2, '2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002');
INSERT INTO ck_sync1_co_vacuumanalyze2 values ('3_zero', 3, '3_zero', 0, 0, 0, '{0}',  0, 0, '2004-10-19 10:23:54', '2004-10-19 10:23:54+02', '1-1-2000');





CREATE TABLE ck_sync1_co_vacuumanalyze3(
text_col text,
bigint_col bigint,
char_vary_col character varying(30),
numeric_col numeric,
int_col int4,
float_col float4,
int_array_col int[],
drop_col numeric,
before_rename_col int4,
change_datatype_col numeric,
a_ts_without timestamp without time zone,
b_ts_with timestamp with time zone,
date_column date) with ( appendonly='true', orientation='column')  distributed randomly;

INSERT INTO ck_sync1_co_vacuumanalyze3 values ('0_zero', 0, '0_zero', 0, 0, 0, '{0}', 0, 0, 0, '2004-10-19 10:23:54', '2004-10-19 10:23:54+02', '1-1-2000');
INSERT INTO ck_sync1_co_vacuumanalyze3 values ('1_zero', 1, '1_zero', 1, 1, 1, '{1}', 1, 1, 1, '2005-10-19 10:23:54', '2005-10-19 10:23:54+02', '1-1-2001');
INSERT INTO ck_sync1_co_vacuumanalyze3 values ('2_zero', 2, '2_zero', 2, 2, 2, '{2}', 2, 2, 2, '2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002');
INSERT INTO ck_sync1_co_vacuumanalyze3 select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{3}',i,i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002' from generate_series(3,100)i;



ALTER TABLE ck_sync1_co_vacuumanalyze3 ADD COLUMN added_col character varying(30) default 'test_value';
ALTER TABLE ck_sync1_co_vacuumanalyze3 DROP COLUMN drop_col ;
ALTER TABLE ck_sync1_co_vacuumanalyze3 RENAME COLUMN before_rename_col TO after_rename_col;
ALTER TABLE ck_sync1_co_vacuumanalyze3 ALTER COLUMN change_datatype_col TYPE int4;
ALTER TABLE ck_sync1_co_vacuumanalyze3 set with ( reorganize='true') distributed by (int_col);




INSERT INTO ck_sync1_co_vacuumanalyze3 values ('1_zero', 1, '1_zero', 1, 1, 1, '{1}',  1, 1, '2005-10-19 10:23:54', '2005-10-19 10:23:54+02', '1-1-2001');
INSERT INTO ck_sync1_co_vacuumanalyze3 values ('2_zero', 2, '2_zero', 2, 2, 2, '{2}',  2, 2, '2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002');
INSERT INTO ck_sync1_co_vacuumanalyze3 values ('3_zero', 3, '3_zero', 0, 0, 0, '{0}',  0, 0, '2004-10-19 10:23:54', '2004-10-19 10:23:54+02', '1-1-2000');




CREATE TABLE ck_sync1_co_vacuumanalyze4(
text_col text,
bigint_col bigint,
char_vary_col character varying(30),
numeric_col numeric,
int_col int4,
float_col float4,
int_array_col int[],
drop_col numeric,
before_rename_col int4,
change_datatype_col numeric,
a_ts_without timestamp without time zone,
b_ts_with timestamp with time zone,
date_column date) with ( appendonly='true', orientation='column')  distributed randomly;

INSERT INTO ck_sync1_co_vacuumanalyze4 values ('0_zero', 0, '0_zero', 0, 0, 0, '{0}', 0, 0, 0, '2004-10-19 10:23:54', '2004-10-19 10:23:54+02', '1-1-2000');
INSERT INTO ck_sync1_co_vacuumanalyze4 values ('1_zero', 1, '1_zero', 1, 1, 1, '{1}', 1, 1, 1, '2005-10-19 10:23:54', '2005-10-19 10:23:54+02', '1-1-2001');
INSERT INTO ck_sync1_co_vacuumanalyze4 values ('2_zero', 2, '2_zero', 2, 2, 2, '{2}', 2, 2, 2, '2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002');
INSERT INTO ck_sync1_co_vacuumanalyze4 select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{3}',i,i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002' from generate_series(3,100)i;



ALTER TABLE ck_sync1_co_vacuumanalyze4 ADD COLUMN added_col character varying(30) default 'test_value';
ALTER TABLE ck_sync1_co_vacuumanalyze4 DROP COLUMN drop_col ;
ALTER TABLE ck_sync1_co_vacuumanalyze4 RENAME COLUMN before_rename_col TO after_rename_col;
ALTER TABLE ck_sync1_co_vacuumanalyze4 ALTER COLUMN change_datatype_col TYPE int4;
ALTER TABLE ck_sync1_co_vacuumanalyze4 set with ( reorganize='true') distributed by (int_col);




INSERT INTO ck_sync1_co_vacuumanalyze4 values ('1_zero', 1, '1_zero', 1, 1, 1, '{1}',  1, 1, '2005-10-19 10:23:54', '2005-10-19 10:23:54+02', '1-1-2001');
INSERT INTO ck_sync1_co_vacuumanalyze4 values ('2_zero', 2, '2_zero', 2, 2, 2, '{2}',  2, 2, '2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002');
INSERT INTO ck_sync1_co_vacuumanalyze4 values ('3_zero', 3, '3_zero', 0, 0, 0, '{0}',  0, 0, '2004-10-19 10:23:54', '2004-10-19 10:23:54+02', '1-1-2000');




CREATE TABLE ck_sync1_co_vacuumanalyze5(
text_col text,
bigint_col bigint,
char_vary_col character varying(30),
numeric_col numeric,
int_col int4,
float_col float4,
int_array_col int[],
drop_col numeric,
before_rename_col int4,
change_datatype_col numeric,
a_ts_without timestamp without time zone,
b_ts_with timestamp with time zone,
date_column date) with ( appendonly='true', orientation='column')  distributed randomly;

INSERT INTO ck_sync1_co_vacuumanalyze5 values ('0_zero', 0, '0_zero', 0, 0, 0, '{0}', 0, 0, 0, '2004-10-19 10:23:54', '2004-10-19 10:23:54+02', '1-1-2000');
INSERT INTO ck_sync1_co_vacuumanalyze5 values ('1_zero', 1, '1_zero', 1, 1, 1, '{1}', 1, 1, 1, '2005-10-19 10:23:54', '2005-10-19 10:23:54+02', '1-1-2001');
INSERT INTO ck_sync1_co_vacuumanalyze5 values ('2_zero', 2, '2_zero', 2, 2, 2, '{2}', 2, 2, 2, '2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002');
INSERT INTO ck_sync1_co_vacuumanalyze5 select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{3}',i,i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002' from generate_series(3,100)i;



ALTER TABLE ck_sync1_co_vacuumanalyze5 ADD COLUMN added_col character varying(30) default 'test_value';
ALTER TABLE ck_sync1_co_vacuumanalyze5 DROP COLUMN drop_col ;
ALTER TABLE ck_sync1_co_vacuumanalyze5 RENAME COLUMN before_rename_col TO after_rename_col;
ALTER TABLE ck_sync1_co_vacuumanalyze5 ALTER COLUMN change_datatype_col TYPE int4;
ALTER TABLE ck_sync1_co_vacuumanalyze5 set with ( reorganize='true') distributed by (int_col);




INSERT INTO ck_sync1_co_vacuumanalyze5 values ('1_zero', 1, '1_zero', 1, 1, 1, '{1}',  1, 1, '2005-10-19 10:23:54', '2005-10-19 10:23:54+02', '1-1-2001');
INSERT INTO ck_sync1_co_vacuumanalyze5 values ('2_zero', 2, '2_zero', 2, 2, 2, '{2}',  2, 2, '2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002');
INSERT INTO ck_sync1_co_vacuumanalyze5 values ('3_zero', 3, '3_zero', 0, 0, 0, '{0}',  0, 0, '2004-10-19 10:23:54', '2004-10-19 10:23:54+02', '1-1-2000');




CREATE TABLE ck_sync1_co_vacuumanalyze6(
text_col text,
bigint_col bigint,
char_vary_col character varying(30),
numeric_col numeric,
int_col int4,
float_col float4,
int_array_col int[],
drop_col numeric,
before_rename_col int4,
change_datatype_col numeric,
a_ts_without timestamp without time zone,
b_ts_with timestamp with time zone,
date_column date) with ( appendonly='true', orientation='column')  distributed randomly;

INSERT INTO ck_sync1_co_vacuumanalyze6 values ('0_zero', 0, '0_zero', 0, 0, 0, '{0}', 0, 0, 0, '2004-10-19 10:23:54', '2004-10-19 10:23:54+02', '1-1-2000');
INSERT INTO ck_sync1_co_vacuumanalyze6 values ('1_zero', 1, '1_zero', 1, 1, 1, '{1}', 1, 1, 1, '2005-10-19 10:23:54', '2005-10-19 10:23:54+02', '1-1-2001');
INSERT INTO ck_sync1_co_vacuumanalyze6 values ('2_zero', 2, '2_zero', 2, 2, 2, '{2}', 2, 2, 2, '2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002');
INSERT INTO ck_sync1_co_vacuumanalyze6 select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{3}',i,i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002' from generate_series(3,100)i;



ALTER TABLE ck_sync1_co_vacuumanalyze6 ADD COLUMN added_col character varying(30) default 'test_value';
ALTER TABLE ck_sync1_co_vacuumanalyze6 DROP COLUMN drop_col ;
ALTER TABLE ck_sync1_co_vacuumanalyze6 RENAME COLUMN before_rename_col TO after_rename_col;
ALTER TABLE ck_sync1_co_vacuumanalyze6 ALTER COLUMN change_datatype_col TYPE int4;
ALTER TABLE ck_sync1_co_vacuumanalyze6 set with ( reorganize='true') distributed by (int_col);




INSERT INTO ck_sync1_co_vacuumanalyze6 values ('1_zero', 1, '1_zero', 1, 1, 1, '{1}',  1, 1, '2005-10-19 10:23:54', '2005-10-19 10:23:54+02', '1-1-2001');
INSERT INTO ck_sync1_co_vacuumanalyze6 values ('2_zero', 2, '2_zero', 2, 2, 2, '{2}',  2, 2, '2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002');
INSERT INTO ck_sync1_co_vacuumanalyze6 values ('3_zero', 3, '3_zero', 0, 0, 0, '{0}',  0, 0, '2004-10-19 10:23:54', '2004-10-19 10:23:54+02', '1-1-2000');





CREATE TABLE ck_sync1_co_vacuumanalyze7(
text_col text,
bigint_col bigint,
char_vary_col character varying(30),
numeric_col numeric,
int_col int4,
float_col float4,
int_array_col int[],
drop_col numeric,
before_rename_col int4,
change_datatype_col numeric,
a_ts_without timestamp without time zone,
b_ts_with timestamp with time zone,
date_column date) with ( appendonly='true', orientation='column')  distributed randomly;

INSERT INTO ck_sync1_co_vacuumanalyze7 values ('0_zero', 0, '0_zero', 0, 0, 0, '{0}', 0, 0, 0, '2004-10-19 10:23:54', '2004-10-19 10:23:54+02', '1-1-2000');
INSERT INTO ck_sync1_co_vacuumanalyze7 values ('1_zero', 1, '1_zero', 1, 1, 1, '{1}', 1, 1, 1, '2005-10-19 10:23:54', '2005-10-19 10:23:54+02', '1-1-2001');
INSERT INTO ck_sync1_co_vacuumanalyze7 values ('2_zero', 2, '2_zero', 2, 2, 2, '{2}', 2, 2, 2, '2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002');
INSERT INTO ck_sync1_co_vacuumanalyze7 select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{3}',i,i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002' from generate_series(3,100)i;



ALTER TABLE ck_sync1_co_vacuumanalyze7 ADD COLUMN added_col character varying(30) default 'test_value';
ALTER TABLE ck_sync1_co_vacuumanalyze7 DROP COLUMN drop_col ;
ALTER TABLE ck_sync1_co_vacuumanalyze7 RENAME COLUMN before_rename_col TO after_rename_col;
ALTER TABLE ck_sync1_co_vacuumanalyze7 ALTER COLUMN change_datatype_col TYPE int4;
ALTER TABLE ck_sync1_co_vacuumanalyze7 set with ( reorganize='true') distributed by (int_col);




INSERT INTO ck_sync1_co_vacuumanalyze7 values ('1_zero', 1, '1_zero', 1, 1, 1, '{1}',  1, 1, '2005-10-19 10:23:54', '2005-10-19 10:23:54+02', '1-1-2001');
INSERT INTO ck_sync1_co_vacuumanalyze7 values ('2_zero', 2, '2_zero', 2, 2, 2, '{2}',  2, 2, '2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002');
INSERT INTO ck_sync1_co_vacuumanalyze7 values ('3_zero', 3, '3_zero', 0, 0, 0, '{0}',  0, 0, '2004-10-19 10:23:54', '2004-10-19 10:23:54+02', '1-1-2000');





VACUUM ANALYZE  sync1_co_vacuumanalyze2;
VACUUM ANALYZE  ck_sync1_co_vacuumanalyze1;


