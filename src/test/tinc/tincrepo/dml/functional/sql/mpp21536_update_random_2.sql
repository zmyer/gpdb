-- @author ramans2
-- @created 2013-10-30 12:00:00 
-- @modified 2013-10-30 12:00:00
-- @tags dml 
-- @db_name dmldb
-- @description MPP-21536: Duplicated rows inserted when ORCA is turned on
\echo --start_ignore
set gp_enable_column_oriented_table=on;
\echo --end_ignore

update yyy set b=m.b from m where m.a=yyy.a;

select * from yyy order by 1, 2;
