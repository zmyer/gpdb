-- @description varying_fromtable_timeofday.sql
-- @db_name builtin_functionproperty
-- @author tungs1
-- @modified 2013-04-17 12:00:00
-- @created 2013-04-17 12:00:00
-- @executemode gt1
-- @tags functionPropertiesBuiltin HAWQ
SELECT count( distinct i ) FROM (SELECT timeofday() i from foo) t;
