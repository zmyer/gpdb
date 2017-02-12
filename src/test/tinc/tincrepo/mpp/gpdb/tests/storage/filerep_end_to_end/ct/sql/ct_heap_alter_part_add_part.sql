-- start_ignore
SET gp_create_table_random_default_distribution=off;
-- end_ignore
--
-- CT Heap Part Table 1
--
create table ct_heap_alter_part_add_part1 (a char, b int, d char,e text) 
partition by range (b)
subpartition by list (d)
subpartition template (
 subpartition sp1 values ('a'),
 subpartition sp2 values ('b'))
(
start (1) end (10) every (5)
);
--
-- Insert few records into the table
--
 insert into ct_heap_alter_part_add_part1 values ('a',generate_series(1,5),'b','test_1');
--
-- CT Heap Part Table 2
--
create table ct_heap_alter_part_add_part2 (a char, b int, d char,e text) 
partition by range (b)
subpartition by list (d)
subpartition template (
 subpartition sp1 values ('a'),
 subpartition sp2 values ('b'))
(
start (1) end (10) every (5)
);
--
-- Insert few records into the table
--
 insert into ct_heap_alter_part_add_part2 values ('a',generate_series(1,5),'b','test_1');
--
-- CT Heap Part Table 3
--
create table ct_heap_alter_part_add_part3 (a char, b int, d char,e text) 
partition by range (b)
subpartition by list (d)
subpartition template (
 subpartition sp1 values ('a'),
 subpartition sp2 values ('b'))
(
start (1) end (10) every (5)
);
--
-- Insert few records into the table
--
 insert into ct_heap_alter_part_add_part3 values ('a',generate_series(1,5),'b','test_1');
--
-- CT Heap Part Table 4
--
create table ct_heap_alter_part_add_part4 (a char, b int, d char,e text) 
partition by range (b)
subpartition by list (d)
subpartition template (
 subpartition sp1 values ('a'),
 subpartition sp2 values ('b'))
(
start (1) end (10) every (5)
);
--
-- Insert few records into the table
--
 insert into ct_heap_alter_part_add_part4 values ('a',generate_series(1,5),'b','test_1');
--
-- CT Heap Part Table 5
--
create table ct_heap_alter_part_add_part5 (a char, b int, d char,e text) 
partition by range (b)
subpartition by list (d)
subpartition template (
 subpartition sp1 values ('a'),
 subpartition sp2 values ('b'))
(
start (1) end (10) every (5)
);
--
-- Insert few records into the table
--
 insert into ct_heap_alter_part_add_part5 values ('a',generate_series(1,5),'b','test_1');
--
--
-- ALTER TABLE TO ADD PART
--
--
--
-- ALTER SYNC1 Heap Part Add Partition
--
-- Add partition
--
alter table sync1_heap_alter_part_add_part4 add partition p1 end (11);
--
-- Insert few records into the table
--
 insert into sync1_heap_alter_part_add_part4 values ('a',generate_series(1,5),'b','test_1');
--
-- Set subpartition Template
--
alter table sync1_heap_alter_part_add_part4 set subpartition template ();
--
-- Add Partition
--
alter table sync1_heap_alter_part_add_part4 add partition p3 end (13) (subpartition sp3 values ('c'));
--
-- Insert few records into the table
--
 insert into sync1_heap_alter_part_add_part4 values ('a',generate_series(1,5),'b','test_1');
--
-- ALTER CK_SYNC1 Heap Part Add Partition
--
-- Add partition
--
alter table ck_sync1_heap_alter_part_add_part3 add partition p1 end (11);
--
-- Insert few records into the table
--
 insert into ck_sync1_heap_alter_part_add_part3 values ('a',generate_series(1,5),'b','test_1');
--
-- Set subpartition Template
--
alter table ck_sync1_heap_alter_part_add_part3 set subpartition template ();
--
-- Add Partition
--
alter table ck_sync1_heap_alter_part_add_part3 add partition p3 end (13) (subpartition sp3 values ('c'));
--
-- Insert few records into the table
--
 insert into ck_sync1_heap_alter_part_add_part3 values ('a',generate_series(1,5),'b','test_1');
--
-- ALTER CT Heap Part Add Partition
--
-- Add partition
--
alter table ct_heap_alter_part_add_part1 add partition p1 end (11);
--
-- Insert few records into the table
--
 insert into ct_heap_alter_part_add_part1 values ('a',generate_series(1,5),'b','test_1');
--
-- Set subpartition Template
--
alter table ct_heap_alter_part_add_part1 set subpartition template ();
--
-- Add Partition
--
alter table ct_heap_alter_part_add_part1 add partition p3 end (13) (subpartition sp3 values ('c'));
--
-- Insert few records into the table
--
 insert into ct_heap_alter_part_add_part1 values ('a',generate_series(1,5),'b','test_1');
