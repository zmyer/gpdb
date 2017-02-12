DROP table if exists pg_table_inherit;
DROP table if exists pg_table_inherit_base;

CREATE table pg_table_inherit_base  (
    did integer,
    name varchar(40),
    CONSTRAINT con1 CHECK (did > 99 AND name <> '')
    )DISTRIBUTED RANDOMLY;

CREATE table pg_table_inherit() inherits( pg_table_inherit_base) distributed randomly;

select oid, gp_segment_id, conname from pg_constraint where conrelid = 'pg_table_inherit'::regclass;
select oid, gp_segment_id, conname from gp_dist_random('pg_constraint') where conrelid = 'pg_table_inherit'::regclass;


