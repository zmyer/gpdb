-- @author prabhd 
-- @created 2012-12-05 12:00:00 
-- @modified 2012-12-05 12:00:00 
-- @tags dml 
-- @db_name dmldb
-- @execute_all_plans True
-- @description update_test16: Update and case 
\echo --start_ignore
set gp_enable_column_oriented_table=on;
\echo --end_ignore
SELECT COUNT(*) FROM dml_heap_r WHERE a = 100 ;
UPDATE dml_heap_r SET a = (SELECT case when c = 'r' then MAX(b) else 100 end FROM dml_heap_r GROUP BY c ORDER BY 1 LIMIT 1) ;
SELECT COUNT(*) FROM dml_heap_r WHERE a = 100 ;
