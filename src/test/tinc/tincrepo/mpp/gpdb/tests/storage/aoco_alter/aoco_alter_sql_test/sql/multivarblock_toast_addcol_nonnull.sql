-- 
-- @created 2014-05-19 12:00:00
-- @modified 2014-05-19 12:00:00
-- @tags storage
-- @description AOCO multivarblock table : add column with default value non NULL
alter table multivarblock_toast ADD COLUMN added_col4  bytea default ("decode"(repeat('1234567890',10000),'escape'));
select count(*) as added_col4 from pg_attribute pa, pg_class pc where pa.attrelid = pc.oid and pc.relname='multivarblock_toast' and attname='added_col4';
