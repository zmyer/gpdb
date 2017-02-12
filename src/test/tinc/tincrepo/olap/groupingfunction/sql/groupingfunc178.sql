-- @author tungs1
-- @modified 2013-07-28 12:00:00
-- @created 2013-07-28 12:00:00
-- @description groupingfunction groupingfunc178.sql
-- @db_name groupingfunction
-- @executemode normal
-- @tags groupingfunction
-- order 1
select 'a', * from ((SELECT GROUPING(product.pname) as g1 FROM product, sale WHERE product.pn=sale.pn GROUP BY ROLLUP((sale.pn),(product.pname),(sale.pn)) ORDER BY g1) UNION (SELECT sale.pn FROM sale))a;
