insert into abort_create_needed_cr_co_reindex_table_bitmap_index select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{3}',i,i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002' from generate_series(101,110)i;
REINDEX INDEX  abort_create_needed_cr_co_reindex_bitmap_idx1;
SELECT COUNT(*) FROM abort_create_needed_cr_co_reindex_table_bitmap_index;
drop table abort_create_needed_cr_co_reindex_table_bitmap_index;
