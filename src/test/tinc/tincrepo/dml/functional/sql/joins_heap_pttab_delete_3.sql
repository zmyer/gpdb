-- @author prabhd 
-- @created 2012-12-05 12:00:00 
-- @modified 2012-12-05 12:00:00 
-- @tags dml 
-- @db_name dmldb
-- @execute_all_plans True
-- @description test3: Delete with predicate
\echo --start_ignore
set gp_enable_column_oriented_table=on;
\echo --end_ignore
SELECT COUNT(*) FROM dml_heap_pt_s;
SELECT COUNT(*) FROM dml_heap_pt_s WHERE a is NULL;
DELETE FROM dml_heap_pt_s WHERE a is NULL; 
SELECT COUNT(*) FROM dml_heap_pt_s;
