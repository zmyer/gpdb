-- @author prabhd
-- @modified 2013-08-01 12:00:00
-- @created 2013-08-01 12:00:00
-- @db_name ptidx
-- @tags partitionindexes
-- @description multiple column b-tree index
-- start_ignore
DROP INDEX IF EXISTS idx1;
-- end_ignore
CREATE INDEX idx1 on pt_lt_tab(col1,col2);
SELECT * FROM pt_lt_tab WHERE col2 = 25 ORDER BY col2,col3 LIMIT 5;
