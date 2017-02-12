-- @author prabhd
-- @created 2012-02-01 12:00:00
-- @modified 2013-02-01 12:00:00
-- @tags cte bfv MPP-19436
-- @db_name world_db
-- @product_version gpdb: [4.2.6.1-],hawq: [1.1.0.2-]
-- @description MPP-19436

WITH t(a,b,d) AS
(
  SELECT foo.a,foo.b,bar.d FROM foo,bar WHERE foo.a = bar.d
)
SELECT cup.*, SUM(t.d) FROM  
  ( 
    SELECT bar.*, count(*) OVER() AS e FROM t,bar WHERE t.a = bar.c
  ) AS cup,
t GROUP BY cup.c,cup.d, cup.e,t.a
HAVING AVG(t.d) < 10 ORDER BY 1,2,3,4 LIMIT 10;
