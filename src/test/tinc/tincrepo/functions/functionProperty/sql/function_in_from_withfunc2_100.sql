-- @description function_in_from_withfunc2_100.sql
-- @db_name functionproperty
-- @author tungs1
-- @modified 2013-04-03 12:00:00
-- @created 2013-04-03 12:00:00
-- @tags functionProperties 
SELECT * FROM func1_read_int_sql_stb(func2_nosql_vol(5)) order by 1; 
