-- @author prabhd
-- @created 2012-02-01 12:00:00
-- @modified 2013-02-01 12:00:00
-- @tags cte HAWQ
-- @description MPP-19271: Unexpected internal error when we issue CTE with CSQ when we disable inlining of CTE

WITH cte AS(
    SELECT code, n, x from t , (SELECT 100 as x) d ) 
SELECT code FROM t WHERE (
    SELECT count(*) FROM cte WHERE cte.code::text=t.code::text
) = 1 ORDER BY 1;
