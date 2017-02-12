-- @author prabhd 
-- @created 2013-02-01 12:00:00 
-- @modified 2013-02-01 12:00:00 
-- @tags cte
-- @gucs optimizer_cte_inlining = on;optimizer_cte_inlining_bound=1000
-- @product_version gpdb: [4.3-],hawq: [1.1-]
-- @db_name world_db
-- @description test15e: CTE with a user-defined function [STABLE READS SQL DATA]

CREATE OR REPLACE FUNCTION cte_func1(a int) RETURNS int 
LANGUAGE plpgsql
STABLE READS SQL DATA
AS $$
DECLARE
    r int;
BEGIN
    SELECT d FROM foobar WHERE c = $1 LIMIT 1 INTO r;
    RETURN r;
END
$$;

WITH v(a, b) AS (SELECT cte_func1(a), b FROM foo WHERE b < 5)
SELECT v1.a, v2.b
FROM v AS v1, v AS v2
WHERE v1.a < v2.a ORDER BY 1,2;
