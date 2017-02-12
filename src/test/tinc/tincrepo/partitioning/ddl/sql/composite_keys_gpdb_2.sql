-- @author elhela 
-- @created 2015-05-11 12:00:00
-- @tags ORCA
-- @db_name gptest
-- @gpopt 1.577
-- @product_version gpdb: [4.3.5.1-]
-- @gucs optimizer_multilevel_partitioning=on
-- @optimizer_mode on
-- @description Testing composite keys

-- start_ignore
DROP TABLE IF EXISTS pt;

CREATE TABLE pt (i int, j int, k int, l int, m int) DISTRIBUTED BY (i)
PARTITION BY list(k)
  SUBPARTITION BY list(j, m) SUBPARTITION TEMPLATE (subpartition p11 values ((1,1)), subpartition p12 values((2,2)))
( partition p1 values(1), partition p2 values(2));

set client_min_messages='log';
SELECT * FROM pt;
set client_min_messages='notice';
-- end_ignore

\!grep Planner %MYD%/output/composite_keys_gpdb_2_orca.out|wc -l
