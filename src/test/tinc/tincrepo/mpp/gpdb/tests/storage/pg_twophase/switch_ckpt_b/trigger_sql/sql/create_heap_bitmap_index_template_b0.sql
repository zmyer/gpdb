-- start_ignore
SET gp_create_table_random_default_distribution=off;
-- end_ignore
CREATE INDEX pg2_heap_bitmap_idx1_b0 ON pg2_heap_table_bitmap_index_b0 USING bitmap (numeric_col);
