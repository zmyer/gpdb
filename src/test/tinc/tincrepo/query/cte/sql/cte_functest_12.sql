-- @author prabhd 
-- @created 2013-02-01 12:00:00 
-- @modified 2013-02-01 12:00:00 
-- @tags cte HAWQ 
-- @product_version gpdb: [4.3-],hawq: [1.1-]
-- @db_name world_db
-- @description test9: CTE defined inside another CTE

WITH v AS (WITH w AS (SELECT a, b FROM foo WHERE b < 5) 
SELECT w1.a, w2.b from w w1, w w2 WHERE w1.a = w2.a AND w1.a > 2)
SELECT v1.a, v2.a, v2.b
FROM v as v1, v as v2
WHERE v1.a = v2.a ORDER BY 1;
