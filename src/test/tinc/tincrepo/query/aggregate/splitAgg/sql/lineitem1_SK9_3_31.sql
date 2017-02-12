--start_ignore
-- @author tungs1
-- @modified 2013-07-17 12:00:00
-- @created 2013-07-17 12:00:00
-- @description SplitDQA lineitem1_SK9_3_31.sql
-- @db_name splitdqa
-- @tags SplitAgg HAWQ
-- @executemode normal
--end_ignore
(SELECT * FROM (SELECT COUNT(DISTINCT l_partkey) AS DQA1_dqacol1, SUM(l_suppkey) AS DQA1_dqacol2 FROM lineitem1  GROUP BY l_linenumber) as t) UNION (SELECT * FROM (SELECT SUM(DISTINCT p_partkey) AS DQA2_dqacol1, SUM(p_size) AS DQA2_dqacol2 FROM part1  GROUP BY ps_availqty) as t2);
