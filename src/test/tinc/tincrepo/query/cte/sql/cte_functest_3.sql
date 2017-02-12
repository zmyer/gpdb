-- @author prabhd 
-- @created 2013-02-01 12:00:00 
-- @modified 2013-02-01 12:00:00 
-- @tags cte HAWQ 
-- @product_version gpdb: [4.3-],hawq: [1.1-]
-- @db_name world_db
-- @description test3: Single producer and multiple consumers, with a predicate that can be pushed down one of the consumers

WITH v AS (SELECT a, b FROM foo WHERE b < 5)
SELECT v1.a, v2.b
FROM v AS v1, v AS v2
WHERE v1.a < v2.a
AND v1.a < 10 ORDER BY 1,2;


