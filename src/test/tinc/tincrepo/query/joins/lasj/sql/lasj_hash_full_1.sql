-- @author ramans2
-- @created 2013-07-05 12:00:00 
-- @modified 2013-07-05 12:00:00
-- @tags lasj HAWQ
-- @db_name lasjdb
-- @product_version gpdb: [4.3.0.0-9.9.99.99] , hawq: [1.1.4.0-9.9.99.99]
-- @description OPT-3351: Add test cases for LASJ

-- enable hash join
SELECT enable_xform('CXformLeftAntiSemiJoin2HashJoin');

-- empty outer, non-empty inner
SELECT * FROM (SELECT * FROM foo WHERE b = -1) foo2 FULL OUTER JOIN bar ON (a = x);
