-- @executemode ORCA_PLANNER_DIFF
-- @description function_in_from_subqry_withfunc2_160.sql
-- @db_name functionproperty

-- @author tungs1
-- @modified 2013-04-03 12:00:00
-- @created 2013-04-03 12:00:00
-- @tags functionProperties 
SELECT * FROM foo, (SELECT * FROM func1_mod_setint_stb(func2_nosql_vol(5))) r order by 1,2,3; 
