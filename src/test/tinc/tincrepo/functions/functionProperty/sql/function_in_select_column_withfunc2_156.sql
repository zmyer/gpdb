-- @description function_in_select_column_withfunc2_156.sql
-- @db_name functionproperty
-- @author tungs1
-- @modified 2013-04-03 12:00:00
-- @created 2013-04-03 12:00:00
-- @tags functionProperties 
SELECT func1_mod_setint_vol(func2_read_int_vol(a)) FROM foo order by 1; 
