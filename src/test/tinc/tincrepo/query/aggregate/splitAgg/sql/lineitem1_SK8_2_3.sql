--start_ignore
-- @author tungs1
-- @modified 2013-07-17 12:00:00
-- @created 2013-07-17 12:00:00
-- @description SplitDQA lineitem1_SK8_2_3.sql
-- @db_name splitdqa
-- @tags SplitAgg HAWQ
-- @executemode normal
--end_ignore
SELECT * from part1 WHERE part1.p_partkey = ALL (SELECT SUM(DISTINCT l_suppkey) AS DQA1_dqacol1 FROM lineitem1  WHERE lineitem1.l_suppkey = part1.p_size ) ;
