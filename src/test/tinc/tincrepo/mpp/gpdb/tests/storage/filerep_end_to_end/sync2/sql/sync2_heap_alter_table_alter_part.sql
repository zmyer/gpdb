-- start_ignore
SET gp_create_table_random_default_distribution=off;
-- end_ignore
--
-- SYNC2 Heap Part Table 1
--
CREATE TABLE sync2_heap_alter_table_alter_part1 (
id int,
rank int,
year int,
gender char(1),
name text,
count int ) 
DISTRIBUTED BY (id)
PARTITION BY LIST (gender)
SUBPARTITION BY RANGE (year)
SUBPARTITION TEMPLATE (
SUBPARTITION year1 START (2001),
SUBPARTITION year2 START (2002),
SUBPARTITION year6 START (2006) END (2007) )
(PARTITION girls VALUES ('F'),
PARTITION boys VALUES ('M') );
--
-- Insert few records into the table
--
insert into sync2_heap_alter_table_alter_part1 values (generate_series(1,10),1,2001,'F',6);

--
-- SYNC2 Heap Part Table 2
--
CREATE TABLE sync2_heap_alter_table_alter_part2 (
id int,
rank int,
year int,
gender char(1),
name text,
count int ) 
DISTRIBUTED BY (id)
PARTITION BY LIST (gender)
SUBPARTITION BY RANGE (year)
SUBPARTITION TEMPLATE (
SUBPARTITION year1 START (2001),
SUBPARTITION year2 START (2002),
SUBPARTITION year6 START (2006) END (2007) )
(PARTITION girls VALUES ('F'),
PARTITION boys VALUES ('M') );
--
-- Insert few records into the table
--
insert into sync2_heap_alter_table_alter_part2 values (generate_series(1,10),1,2001,'F',6);


--
--
--ALTER TABLE TO ALTER PART
--
--
--
-- ALTER SYNC1 Heap Part ALTER TABLE TO ALTER PARTITION
--
--
-- Add Default partition for girls
--
alter table sync1_heap_alter_table_alter_part7 alter partition girls add default partition gfuture;
--
-- Add Default partition for boys
--
alter table sync1_heap_alter_table_alter_part7 alter partition boys add default partition bfuture;

select count(*) from sync1_heap_alter_table_alter_part7;
--
-- Insert few records into the table
--
insert into sync1_heap_alter_table_alter_part7 values (generate_series(1,10),1,2001,'F',6);
select count(*) from sync1_heap_alter_table_alter_part7;
--
-- ALTER CK_SYNC1 Heap Part ALTER TABLE TO ALTER PARTITION
--
--
-- Add Default partition for girls
--
alter table ck_sync1_heap_alter_table_alter_part6 alter partition girls add default partition gfuture;
--
-- Add Default partition for boys
--
alter table ck_sync1_heap_alter_table_alter_part6 alter partition boys add default partition bfuture;

select count(*) from ck_sync1_heap_alter_table_alter_part6;
--
-- Insert few records into the table
--
insert into ck_sync1_heap_alter_table_alter_part6 values (generate_series(1,10),1,2001,'F',6);
select count(*) from ck_sync1_heap_alter_table_alter_part6;
--
-- ALTER CT Heap Part ALTER TABLE TO ALTER PARTITION
--
--
-- Add Default partition for girls
--
alter table ct_heap_alter_table_alter_part4 alter partition girls add default partition gfuture;
--
-- Add Default partition for boys
--
alter table ct_heap_alter_table_alter_part4 alter partition boys add default partition bfuture;

select count(*) from ct_heap_alter_table_alter_part4;
--
-- Insert few records into the table
--
insert into ct_heap_alter_table_alter_part4 values (generate_series(1,10),1,2001,'F',6);
select count(*) from ct_heap_alter_table_alter_part4;

--
-- ALTER RESYNC Heap Part ALTER TABLE TO ALTER PARTITION
--
--
-- Add Default partition for girls
--
alter table resync_heap_alter_table_alter_part2 alter partition girls add default partition gfuture;
--
-- Add Default partition for boys
--
alter table resync_heap_alter_table_alter_part2 alter partition boys add default partition bfuture;

select count(*) from resync_heap_alter_table_alter_part2;
--
-- Insert few records into the table
--
insert into resync_heap_alter_table_alter_part2 values (generate_series(1,10),1,2001,'F',6);
select count(*) from resync_heap_alter_table_alter_part2;
--
-- ALTER SYNC2 Heap Part ALTER TABLE TO ALTER PARTITION
--
--
-- Add Default partition for girls
--
alter table sync2_heap_alter_table_alter_part1 alter partition girls add default partition gfuture;
--
-- Add Default partition for boys
--
alter table sync2_heap_alter_table_alter_part1 alter partition boys add default partition bfuture;

select count(*) from sync2_heap_alter_table_alter_part1;
--
-- Insert few records into the table
--
insert into sync2_heap_alter_table_alter_part1 values (generate_series(1,10),1,2001,'F',6);
select count(*) from sync2_heap_alter_table_alter_part1;


