-- @Description Ensures that a vacuum during reindex operations is ok
-- 

DELETE FROM reindex_heap WHERE a < 128;
1: BEGIN;
1: REINDEX index idx_bitmap_reindex_heap;
2&: VACUUM reindex_heap;
1: COMMIT;
2<:
2: COMMIT;
3: SELECT COUNT(*) FROM reindex_heap WHERE a = 1500;
3: INSERT INTO reindex_heap VALUES (0);
3: SELECT 1 AS relfilenode_same_on_all_segs from gp_dist_random('pg_class')   WHERE relname = 'idx_bitmap_reindex_heap' GROUP BY relfilenode having count(*) = (SELECT count(*) FROM gp_segment_configuration WHERE role='p' AND content > -1);
