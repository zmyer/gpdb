-- @author prabhd 
-- @created 2013-02-01 12:00:00 
-- @modified 2013-02-01 12:00:00 
-- @tags cte HAWQ 
-- @product_version gpdb: [4.3-],hawq: [1.1-]
-- @db_name world_db
-- @description test21a: Common name for CTEs and subquery alias

WITH v1 AS (SELECT a, b FROM foo WHERE a < 6), 
     v2 AS (SELECT * FROM v1 WHERE a < 3)
SELECT * 
FROM (
        SELECT * FROM v1 WHERE b < 5) v1,
       (SELECT * FROM v1) v2
WHERE v1.a =v2.b  ORDER BY 1;

