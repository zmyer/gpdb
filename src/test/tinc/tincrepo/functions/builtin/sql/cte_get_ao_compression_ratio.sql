-- @description cte_get_ao_compression_ratio.sql
-- @db_name builtin_functionproperty
-- @author tungs1
-- @modified 2013-04-17 12:00:00
-- @created 2013-04-17 12:00:00
-- @executemode ORCA_PLANNER_DIFF
-- @tags functionPropertiesBuiltin HAWQ
WITH v(a,b) AS (SELECT get_ao_compression_ratio(a)), b FROM foo WHERE b > 10000) SELECT v1.a, v2.b FROM v AS v1, v AS v2 WHERE v1.a < v2.a;
