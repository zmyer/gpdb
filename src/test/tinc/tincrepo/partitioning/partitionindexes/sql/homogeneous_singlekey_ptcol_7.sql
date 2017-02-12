-- @author prabhd
-- @modified 2013-08-01 12:00:00
-- @created 2013-08-01 12:00:00
-- @db_name ptidx
-- @tags partitionindexes
-- @description B-tree single index key = partitioning key
-- start_ignore
DROP INDEX IF EXISTS idx1;
-- end_ignore
CREATE INDEX idx1 on pt_lt_tab(col2);
SELECT * FROM pt_lt_tab WHERE col2 between 10 AND 50 ORDER BY col2,col3 LIMIT 5;
