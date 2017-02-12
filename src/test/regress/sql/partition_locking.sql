-- Test locking behaviour. When creating, dropping, querying or adding indexes
-- partitioned tables, we want to lock only the master, not the children.

-- Show locks in master and in segments. Because the number of segments
-- in the cluster depends on configuration, we print only summary information
-- of the locks in segments. If a relation is locked only on one segment,
-- we print that as a special case, but otherwise we just print "n segments",
-- meaning the relation is locked on more than one segment.
create or replace view locktest as
select coalesce(
  case when relname like 'pg_toast%index' then 'toast index'
       when relname like 'pg_toast%' then 'toast table'
       when relname like 'pg_aoseg%' then 'aoseg table'
       else relname end, 'dropped table'),
  mode,
  locktype,
  case when l.gp_segment_id = -1 then 'master'
       when COUNT(*) = 1 then '1 segment'
       else 'n segments' end AS node
from pg_locks l
left outer join pg_class c on (l.relation = c.oid),
pg_database d
where relation is not null
and l.database = d.oid
and (relname <> 'gp_fault_strategy' or relname IS NULL)
and d.datname = current_database()
group by l.gp_segment_id = -1, relation, relname, locktype, mode
order by 1, 3, 2;

-- Partitioned table with toast table
begin;

-- creation
create table g (i int, t text) partition by range(i)
(start(1) end(10) every(1));

select * from locktest;
commit;

-- drop
begin;
drop table g;
select * from locktest;
commit;

-- AO table (ao segments, block directory won't exist after create)
begin;
-- creation
create table g (i int, t text, n numeric)
with (appendonly = true)
partition by list(i)
(values(1), values(2), values(3));
select * from locktest;
commit;
begin;

-- add a little data
insert into g values(1), (2), (3);
insert into g values(1), (2), (3);
insert into g values(1), (2), (3);
insert into g values(1), (2), (3);
insert into g values(1), (2), (3);
select * from locktest;

commit;
-- drop
begin;
drop table g;
select * from locktest;
commit;

-- Indexing
create table g (i int, t text) partition by range(i)
(start(1) end(10) every(1));

begin;
create index g_idx on g(i);
select * from locktest;
commit;

-- Force use of the index in the select and delete below. We're not interested
-- in the plan we get, but a seqscan will not lock the index while an index
-- scan will, and we want to avoid the plan-dependent difference in the
-- expected output of this test.
set enable_seqscan=off;

-- test select locking
begin;
select * from g where i = 1;
-- Known_opt_diff: MPP-20936
select * from locktest;
commit;

begin;
-- insert locking
insert into g values(3, 'f');
select * from locktest;
commit;

-- delete locking
begin;
delete from g where i = 4;
-- Known_opt_diff: MPP-20936
select * from locktest;
commit;

-- drop index
begin;
drop table g;
select * from locktest;
commit;
