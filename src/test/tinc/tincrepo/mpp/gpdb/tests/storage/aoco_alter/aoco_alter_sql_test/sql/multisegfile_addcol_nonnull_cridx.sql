-- 
-- @created 2014-05-19 12:00:00
-- @modified 2014-05-19 12:00:00
-- @tags storage
-- @description AOCO multivarblock table : add column with default value non NULL then add index on new column
alter table multi_segfile_tab ADD COLUMN added_col50 TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW() ;
select count(*) as added_col50 from pg_attribute pa, pg_class pc where pa.attrelid = pc.oid and pc.relname='multi_segfile_tab' and attname='added_col50';
insert into multi_segfile_tab (c_custkey, c_name, c_comment, c_rating, c_phone, c_acctbal,c_date, c_timestamp)
                     values( 500, 'acz','yet another  looong text' , 11.5, '778777',550.54,'2014/05/04',now());
create index multi_segfile_tab_idx2 on multi_segfile_tab(added_col50);

