-- @author prabhd 
-- @created 2012-12-05 12:00:00 
-- @modified 2012-12-05 12:00:00 
-- @tags dml HAWQ 
-- @db_name dmldb
-- @execute_all_plans True
-- @description test24: Negative test - Insert NULL value to a table without default partition
\echo --start_ignore
set gp_enable_column_oriented_table=on;
\echo --end_ignore
SELECT COUNT(*) FROM dml_ao_pt_r;
SELECT COUNT(*) FROM (SELECT dml_ao_pt_r.b, NULL, dml_ao_pt_r.c FROM dml_ao_pt_r, dml_ao_pt_s WHERE dml_ao_pt_r.b = dml_ao_pt_s.b)foo;
INSERT INTO dml_ao_pt_r SELECT dml_ao_pt_r.b, NULL, dml_ao_pt_r.c FROM dml_ao_pt_r, dml_ao_pt_s WHERE dml_ao_pt_r.b = dml_ao_pt_s.b;
SELECT COUNT(*) FROM dml_ao_pt_r;
