-- @description function_in_from_join_withfunc2_75.sql
-- @db_name functionproperty
-- @author tungs1
-- @modified 2013-04-03 12:00:00
-- @created 2013-04-03 12:00:00
-- @tags functionProperties 
SELECT * FROM func1_sql_setint_stb(func2_sql_int_imm(5)), foo order by 1,2,3; 
