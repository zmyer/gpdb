-- start_ignore
SET gp_create_table_random_default_distribution=off;
-- end_ignore
DROP TABLE IF EXISTS reindex_crtab_aoco_bitmap;

CREATE TABLE reindex_crtab_aoco_bitmap (a INT) WITH (appendonly=true, orientation=column);
insert into reindex_crtab_aoco_bitmap select generate_series(1,1000);
insert into reindex_crtab_aoco_bitmap select generate_series(1,1000);
create index idx_reindex_crtab_aoco_bitmap on reindex_crtab_aoco_bitmap USING BITMAP(a);
select 1 as relfilenode_same_on_all_segs from gp_dist_random('pg_class')   where relname = 'idx_reindex_crtab_aoco_bitmap' group by relfilenode having count(*) = (select count(*) from gp_segment_configuration where role='p' and content > -1);

