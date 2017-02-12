--start_ignore
-- @author tungs1
-- @modified 2013-07-17 12:00:00
-- @created 2013-07-17 12:00:00
-- @description SplitDQA lineitem1_SK5_1_2.sql
-- @db_name splitdqa
-- @tags SplitAgg HAWQ
-- @executemode normal
--end_ignore
SELECT * FROM part1, (SELECT COUNT(DISTINCT l_partkey) AS DQA1_dqacol1 FROM lineitem1  GROUP BY l_suppkey) as t where t.DQA1_dqacol1 = part1.p_partkey;
