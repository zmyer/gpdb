-- @author prabhd 
-- @created 2012-12-05 12:00:00 
-- @modified 2012-12-05 12:00:00 
-- @tags dml 
-- @db_name dmldb
-- @execute_all_plans True
-- @description test7: Delete with join on non-distribution column
\echo --start_ignore
set gp_enable_column_oriented_table=on;
\echo --end_ignore
SELECT COUNT(*) FROM dml_heap_s;
DELETE FROM dml_heap_s USING dml_heap_r WHERE dml_heap_s.a = dml_heap_r.a;
SELECT COUNT(*) FROM dml_heap_s;
