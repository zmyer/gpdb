-- @author prabhd
-- @modified 2013-08-01 12:00:00
-- @created 2013-08-01 12:00:00
-- @db_name ptidx
-- @tags partitionindexes
-- @negtest True
-- @description Negative tests Combination tests , no index on default partition 
SELECT * FROM pt_lt_tab WHERE col2 > 51 ORDER BY col2,col3 LIMIT 5;
