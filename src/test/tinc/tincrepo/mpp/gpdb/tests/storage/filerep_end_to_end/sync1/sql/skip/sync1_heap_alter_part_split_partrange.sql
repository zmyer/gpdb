-- start_ignore
SET gp_create_table_random_default_distribution=off;
-- end_ignore
--
-- SYNC1 HEAP TABLE 1
--
create table sync1_heap_alter_part_split_partrange1 (i int) partition by range(i) (start(1) end(10) every(5));
--
-- Insert few records into the table
--
insert into sync1_heap_alter_part_split_partrange1 values (generate_series(1,9));
--
-- select from the Table
--
select count(*) from sync1_heap_alter_part_split_partrange1;

--
-- SYNC1 HEAP TABLE 2
--
create table sync1_heap_alter_part_split_partrange2 (i int) partition by range(i) (start(1) end(10) every(5));
--
-- Insert few records into the table
--
insert into sync1_heap_alter_part_split_partrange2 values (generate_series(1,9));
--
-- select from the Table
--
select count(*) from sync1_heap_alter_part_split_partrange2;


--
-- SYNC1 HEAP TABLE 3
--
create table sync1_heap_alter_part_split_partrange3 (i int) partition by range(i) (start(1) end(10) every(5));
--
-- Insert few records into the table
--
insert into sync1_heap_alter_part_split_partrange3 values (generate_series(1,9));
--
-- select from the Table
--
select count(*) from sync1_heap_alter_part_split_partrange3;



--
-- SYNC1 HEAP TABLE 4
--
create table sync1_heap_alter_part_split_partrange4 (i int) partition by range(i) (start(1) end(10) every(5));
--
-- Insert few records into the table
--
insert into sync1_heap_alter_part_split_partrange4 values (generate_series(1,9));
--
-- select from the Table
--
select count(*) from sync1_heap_alter_part_split_partrange4;



--
-- SYNC1 HEAP TABLE 5
--
create table sync1_heap_alter_part_split_partrange5 (i int) partition by range(i) (start(1) end(10) every(5));
--
-- Insert few records into the table
--
insert into sync1_heap_alter_part_split_partrange5 values (generate_series(1,9));
--
-- select from the Table
--
select count(*) from sync1_heap_alter_part_split_partrange5;


--
-- SYNC1 HEAP TABLE 6
--
create table sync1_heap_alter_part_split_partrange6 (i int) partition by range(i) (start(1) end(10) every(5));
--
-- Insert few records into the table
--
insert into sync1_heap_alter_part_split_partrange6 values (generate_series(1,9));
--
-- select from the Table
--
select count(*) from sync1_heap_alter_part_split_partrange6;


--
-- SYNC1 HEAP TABLE 7
--
create table sync1_heap_alter_part_split_partrange7 (i int) partition by range(i) (start(1) end(10) every(5));
--
-- Insert few records into the table
--
insert into sync1_heap_alter_part_split_partrange7 values (generate_series(1,9));
--
-- select from the Table
--
select count(*) from sync1_heap_alter_part_split_partrange7;


--
-- SYNC1 HEAP TABLE 8
--
create table sync1_heap_alter_part_split_partrange8 (i int) partition by range(i) (start(1) end(10) every(5));
--
-- Insert few records into the table
--
insert into sync1_heap_alter_part_split_partrange8 values (generate_series(1,9));
--
-- select from the Table
--
select count(*) from sync1_heap_alter_part_split_partrange8;


--
-- ALTER SYNC1 HEAP
--

--
-- Split Partition Range
--
alter table sync1_heap_alter_part_split_partrange1 split partition for(1) at (5) into (partition aa, partition bb);
--
-- Insert few records into the table
--
insert into sync1_heap_alter_part_split_partrange1 values (generate_series(1,9));
--
-- select from the Table
--
select count(*) from sync1_heap_alter_part_split_partrange1;

