CREATE TABLE cr_heap_ctas AS SELECT * FROM cr_seed_table;
\d cr_heap_ctas
select count(*) from cr_heap_ctas;
drop table cr_heap_ctas;
drop table cr_seed_table;
