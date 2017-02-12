-- 
-- @created 2014-04-14 12:00:00
-- @modified 2014-04-14 12:00:00
-- @tags storage
-- @description AOCO multivarblock table : add column with default value NULL
alter table multivarblock_bitab ADD COLUMN added_col2 character varying(35) default NULL;
select count(*) as added_col2 from pg_attribute pa, pg_class pc where pa.attrelid = pc.oid and pc.relname='multivarblock_bitab' and attname='added_col2';

