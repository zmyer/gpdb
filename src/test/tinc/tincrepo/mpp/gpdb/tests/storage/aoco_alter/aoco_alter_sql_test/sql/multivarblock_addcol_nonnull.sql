-- 
-- @created 2014-05-19 12:00:00
-- @modified 2014-05-19 12:00:00
-- @tags storage
-- @description AOCO multivarblock table : add column with default value non NULL
alter table multivarblock_tab ADD COLUMN added_col5 TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW() ;
select count(*) as added_col5 from pg_attribute pa, pg_class pc where pa.attrelid = pc.oid and pc.relname='multivarblock_tab' and attname='added_col5';
