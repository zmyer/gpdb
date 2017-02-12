-- @author prabhd 
-- @created 2012-12-05 12:00:00 
-- @modified 2012-12-05 12:00:00 
-- @tags dml 
-- @db_name dmldb
-- @description union_test10:  INSERT and EXCEPT operation
\echo --start_ignore
set gp_enable_column_oriented_table=on;
\echo --end_ignore

SELECT COUNT(*) FROM dml_union_r;
SELECT COUNT(*) FROM (SELECT * FROM dml_union_r EXCEPT ALL SELECT dml_union_s.* FROM dml_union_s)foo;
INSERT INTO dml_union_r SELECT * FROM dml_union_r EXCEPT ALL SELECT dml_union_s.* FROM dml_union_s;
SELECT COUNT(*) FROM dml_union_r;

