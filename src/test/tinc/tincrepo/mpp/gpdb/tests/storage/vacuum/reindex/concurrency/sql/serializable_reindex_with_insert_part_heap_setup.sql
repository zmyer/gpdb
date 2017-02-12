-- @product_version gpdb: [4.3.4.0 -],4.3.4.0O2
DROP TABLE IF EXISTS reindex_serialize_ins_tab_heap_part;


CREATE TABLE reindex_serialize_ins_tab_heap_part ( id INTEGER, owner VARCHAR, description VARCHAR, property BOX, poli POLYGON, target CIRCLE, v VARCHAR, t TEXT, f FLOAT, p POINT, c CIRCLE, filler VARCHAR DEFAULT 'Big data is difficult to work with using most relational database management systems and desktop statistics and visualization packages, requiring instead massively parallel software running on tens, hundreds, or even thousands of servers.What is considered big data varies depending on the capabilities of the organization managing the set, and on the capabilities of the applications.This is here just to take up space so that we use more pages of data and sequential scans take a lot more time. ')DISTRIBUTED BY (id) PARTITION BY RANGE (id) ( PARTITION p_one START('1') INCLUSIVE END ('10') EXCLUSIVE, DEFAULT PARTITION de_fault );
insert into reindex_serialize_ins_tab_heap_part (id, owner, description, property, poli, target) select i, 'user' || i, 'Testing GiST Index', '((3, 1300), (33, 1330))','( (22,660), (57, 650), (68, 660) )', '( (76, 76), 76)' from generate_series(1,1000) i ;
insert into reindex_serialize_ins_tab_heap_part (id, owner, description, property, poli, target) select i, 'user' || i, 'Testing GiST Index', '((3, 1300), (33, 1330))','( (22,660), (57, 650), (68, 660) )', '( (76, 76), 76)' from generate_series(1,1000) i ;

create index idxa_reindex_serialize_ins_tab_heap_part on reindex_serialize_ins_tab_heap_part(id);
create index idxb_reindex_serialize_ins_tab_heap_part on reindex_serialize_ins_tab_heap_part(owner);
create index idxc_reindex_serialize_ins_tab_heap_part on reindex_serialize_ins_tab_heap_part USING GIST(property);
create index idxd_reindex_serialize_ins_tab_heap_part on reindex_serialize_ins_tab_heap_part USING GIST(poli);
create index idxe_reindex_serialize_ins_tab_heap_part on reindex_serialize_ins_tab_heap_part USING GIST(target);
create index idxf_reindex_serialize_ins_tab_heap_part on reindex_serialize_ins_tab_heap_part USING BITMAP(v);
create index idxh_reindex_serialize_ins_tab_heap_part on reindex_serialize_ins_tab_heap_part USING GIST(c);
create index idxi_reindex_serialize_ins_tab_heap_part on reindex_serialize_ins_tab_heap_part(f);




SELECT 1 AS relfilenode_same_on_all_segs_maintable from gp_dist_random('pg_class') WHERE relname = 'reindex_serialize_ins_tab_heap_part' and relfilenode = oid GROUP BY relfilenode having count(*) = (SELECT count(*) FROM gp_segment_configuration WHERE role='p' AND content > -1);

select 1 AS relfilenode_same_on_all_segs_mainidx from gp_dist_random('pg_class') WHERE relname = 'idxi_reindex_serialize_ins_tab_heap_part' and relfilenode = oid GROUP BY relfilenode having count(*) = (SELECT count(*) FROM gp_segment_configuration WHERE role='p' AND content > -1);

select  1 AS relfilenode_same_on_all_segs_partition_default_data from gp_dist_random('pg_class') WHERE relname = 'reindex_serialize_ins_tab_heap_part_1_prt_de_fault' and relfilenode = oid GROUP BY relfilenode having count(*) = (SELECT count(*) FROM gp_segment_configuration WHERE role='p' AND content > -1);


select  1 AS relfilenode_same_on_all_segs_partition_default_idx from gp_dist_random('pg_class') WHERE relname = 'idxi_reindex_serialize_ins_tab_heap_part_1_prt_de_fault' and relfilenode = oid GROUP BY relfilenode having count(*) = (SELECT count(*) FROM gp_segment_configuration WHERE role='p' AND content > -1);

select 1 AS relfilenode_same_on_all_segs_partition_1_data from gp_dist_random('pg_class') WHERE relname = 'reindex_serialize_ins_tab_heap_part_1_prt_p_one' and relfilenode = oid GROUP BY relfilenode having count(*) = (SELECT count(*) FROM gp_segment_configuration WHERE role='p' AND content > -1);

select 1 AS relfilenode_same_on_all_segs_partition_1_idx from gp_dist_random('pg_class') WHERE relname = 'idxi_reindex_serialize_ins_tab_heap_part_1_prt_p_one' and relfilenode = oid GROUP BY relfilenode having count(*) = (SELECT count(*) FROM gp_segment_configuration WHERE role='p' AND content > -1)
;

select 1 AS relfilenode_same_on_all_segs_partition_1_idx from gp_dist_random('pg_class') WHERE relname = 'idxa_reindex_serialize_ins_tab_heap_part_1_prt_p_one' and relfilenode = oid GROUP BY relfilenode having count(*) = (SELECT count(*) FROM gp_segment_configuration WHERE role='p' AND content > -1)


