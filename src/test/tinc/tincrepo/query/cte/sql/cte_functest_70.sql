-- @author prabhd
-- @created 2013-02-01 12:00:00
-- @modified 2013-02-01 12:00:00
-- @tags cte HAWQ
-- @product_version gpdb: [4.3-],hawq: [1.1-]
-- @description test8a: CTE defined in the HAVING clause

WITH w AS (SELECT a, b from foo where b < 5)
SELECT a, sum(b) FROM foo WHERE b > 1 GROUP BY a HAVING sum(b) < (SELECT d FROM bar, w WHERE c = w.a AND c > 2) ORDER BY 1;

