-- @author prabhd 
-- @created 2012-12-05 12:00:00 
-- @modified 2012-12-05 12:00:00 
-- @tags dml 
-- @db_name dmldb
-- @execute_all_plans True
-- @description test9: Delete and using (with no rows)
\echo --start_ignore
set gp_enable_column_oriented_table=on;
\echo --end_ignore
TRUNCATE TABLE dml_heap_pt_s;
SELECT COUNT(*) FROM dml_heap_pt_r;
DELETE FROM dml_heap_pt_r USING dml_heap_pt_s; 
SELECT COUNT(*) FROM dml_heap_pt_r;
