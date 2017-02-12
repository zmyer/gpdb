-- @author prabhd 
-- @created 2012-12-05 12:00:00 
-- @modified 2012-12-05 12:00:00 
-- @tags dml 
-- @db_name dmldb
-- @description test15: Delete with PREPARE plan
\echo --start_ignore
set gp_enable_column_oriented_table=on;
\echo --end_ignore
SELECT COUNT(*) FROM (SELECT dml_heap_pt_r.b FROM dml_heap_pt_r,dml_heap_pt_s WHERE dml_heap_pt_r.b = dml_heap_pt_s.b) foo;
SELECT COUNT(*) FROM dml_heap_pt_r;
PREPARE plan_del as DELETE FROM dml_heap_pt_r WHERE b in (SELECT dml_heap_pt_r.b FROM dml_heap_pt_r,dml_heap_pt_s WHERE dml_heap_pt_r.b = dml_heap_pt_s.b);
EXECUTE plan_del;
SELECT COUNT(*) FROM dml_heap_pt_r;
