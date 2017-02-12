DROP table if exists pg_table_column_unique cascade;

CREATE table pg_table_column_unique (i int  constraint unique1 unique, t text) distributed by (i);

select oid, gp_segment_id, conname from pg_constraint where conrelid = 'pg_table_column_unique'::regclass;
select oid, gp_segment_id, conname from gp_dist_random('pg_constraint') where conrelid = 'pg_table_column_unique'::regclass;

