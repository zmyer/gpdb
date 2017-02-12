-- @product_version gpdb: [4.3.4.0 -],4.3.4.0O2
-- @Description Ensures that a reindex table during alter tab add partition  operations is ok
-- 

DELETE FROM reindex_crtabforalter_part_ao_btree  WHERE id < 12;
1: BEGIN;
2: BEGIN;
1: REINDEX TABLE  reindex_crtabforalter_part_ao_btree;
2&: alter table reindex_crtabforalter_part_ao_btree add partition p1 START (date '2013-05-01') INCLUSIVE with(appendonly=true);
1: COMMIT;
2<:
2: COMMIT;
3: Insert into reindex_crtabforalter_part_ao_btree values(9,'2013-05-22',14.22); 
3: select count(*) from reindex_crtabforalter_part_ao_btree where id = 29;
3: set enable_seqscan=false;
3: set enable_indexscan=true;
3: select count(*) from reindex_crtabforalter_part_ao_btree where id = 29;
3: SELECT 1 AS relfilenode_same_on_all_segs_maintable from gp_dist_random('pg_class') WHERE relname = 'reindex_crtabforalter_part_ao_btree' and relfilenode = oid GROUP BY relfilenode having count(*) = (SELECT count(*) FROM gp_segment_configuration WHERE role='p' AND content > -1);

3: select 1 AS relfilenode_same_on_all_segs_mainidx from gp_dist_random('pg_class') WHERE relname = 'idx_reindex_crtabforalter_part_ao_btree' and relfilenode != oid GROUP BY relfilenode having count(*) = (SELECT count(*) FROM gp_segment_configuration WHERE role='p' AND content > -1);

3: select  1 AS relfilenode_same_on_all_segs_partition_1_data from gp_dist_random('pg_class') WHERE relname = 'reindex_crtabforalter_part_ao_btree_1_prt_sales_aug13' and relfilenode = oid GROUP BY relfilenode having count(*) = (SELECT count(*) FROM gp_segment_configuration WHERE role='p' AND content > -1);


3: select  1 AS relfilenode_same_on_all_segs_partition_1_idx from gp_dist_random('pg_class') WHERE relname = 'idx_reindex_crtabforalter_part_ao_btree_1_prt_sales_aug13' and relfilenode != oid GROUP BY relfilenode having count(*) = (SELECT count(*) FROM gp_segment_configuration WHERE role='p' AND content > -1);


3: select 1 AS relfilenode_same_on_all_segs_partition_3_data from gp_dist_random('pg_class') WHERE relname = 'reindex_crtabforalter_part_ao_btree_1_prt_sales_sep13' and relfilenode = oid GROUP BY relfilenode having count(*) = (SELECT count(*) FROM gp_segment_configuration WHERE role='p' AND content > -1);

3: select 1 AS relfilenode_same_on_all_segs_partition_3_idx from gp_dist_random('pg_class') WHERE relname = 'idx_reindex_crtabforalter_part_ao_btree_1_prt_sales_sep13' and relfilenode != oid GROUP BY relfilenode having count(*) = (SELECT count(*) FROM gp_segment_configuration WHERE role='p' AND content > -1);
3: select 1 AS relfilenode_same_on_all_segs_partition_new_data from gp_dist_random('pg_class') WHERE relname = 'reindex_crtabforalter_part_ao_btree_1_prt_p1' and relfilenode = oid GROUP BY relfilenode having count(*) = (SELECT count(*) FROM gp_segment_configuration WHERE role='p' AND content > -1);

3: select 1 AS relfilenode_same_on_all_segs_partition_new_idx from gp_dist_random('pg_class') WHERE relname = 'reindex_crtabforalter_part_ao_btree_1_prt_p1_id_key' and relfilenode = oid GROUP BY relfilenode having count(*) = (SELECT count(*) FROM gp_segment_configuration WHERE role='p' AND content > -1);
