-- @author prabhd 
-- @created 2012-12-05 12:00:00 
-- @modified 2012-12-05 12:00:00 
-- @tags dml 
-- @db_name dmldb
-- @execute_all_plans True
-- @description update_test8: Update and from values
\echo --start_ignore
set gp_enable_column_oriented_table=on;
\echo --end_ignore
SELECT SUM(b) FROM dml_heap_r WHERE b = 20;
UPDATE dml_heap_r SET a = v.i + 1 FROM (VALUES(100, 20)) as v(i, j) WHERE dml_heap_r.b = v.j;
SELECT SUM(b) FROM dml_heap_r WHERE b = 20;
