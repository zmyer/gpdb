-- @author tungs1
-- @modified 2013-07-28 12:00:00
-- @created 2013-07-28 12:00:00
-- @description groupingfunction groupingfunc123.sql
-- @db_name groupingfunction
-- @executemode normal
-- @tags groupingfunction
SELECT GROUPING(product.pname) as g1 FROM product, sale WHERE product.pn=sale.pn GROUP BY sale.cn,product.pname,sale.pn ORDER BY sale.cn;
