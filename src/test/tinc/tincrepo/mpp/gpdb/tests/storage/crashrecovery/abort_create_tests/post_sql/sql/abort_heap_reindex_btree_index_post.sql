REINDEX INDEX cr_heap_reindex_btree_idx1;
\d cr_heap_reindex_table_btree_index
insert into cr_heap_reindex_table_btree_index select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{3}',i,i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002' from generate_series(101,110)i;
SELECT COUNT(*) FROM cr_heap_reindex_table_btree_index;

set enable_seqscan=off;
select numeric_col from cr_heap_reindex_table_btree_index where numeric_col=1;
drop table cr_heap_reindex_table_btree_index;
