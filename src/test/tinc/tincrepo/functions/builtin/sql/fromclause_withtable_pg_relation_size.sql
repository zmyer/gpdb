-- @description fromclause_withtable_pg_relation_size.sql
-- @db_name builtin_functionproperty
-- @author tungs1
-- @modified 2013-04-17 12:00:00
-- @created 2013-04-17 12:00:00
-- @executemode ORCA_PLANNER_DIFF
-- @tags functionPropertiesBuiltin HAWQ
SELECT * FROM pg_relation_size('bar'), foo;
