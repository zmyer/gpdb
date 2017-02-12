-- start_ignore
SET gp_create_table_random_default_distribution=off;
-- end_ignore
--
-- SYNC2 AO TABLE 1
--
create table sync2_ao_alter_part_split_default_part1 (a text, b text)   with ( appendonly='true') partition by list (a) (partition foo values ('foo'), partition bar values ('bar'), default partition baz);

--
-- Insert few records into the table
--

insert into sync2_ao_alter_part_split_default_part1 values ('foo','foo');
insert into sync2_ao_alter_part_split_default_part1 values ('bar','bar');
insert into sync2_ao_alter_part_split_default_part1 values ('foo','bar');
--
-- select from the Table
--
select count(*) from sync2_ao_alter_part_split_default_part1;



--
-- SYNC2 AO TABLE 2
--
create table sync2_ao_alter_part_split_default_part2 (a text, b text)   with ( appendonly='true') partition by list (a) (partition foo values ('foo'), partition bar values ('bar'), default partition baz);

--
-- Insert few records into the table
--

insert into sync2_ao_alter_part_split_default_part2 values ('foo','foo');
insert into sync2_ao_alter_part_split_default_part2 values ('bar','bar');
insert into sync2_ao_alter_part_split_default_part2 values ('foo','bar');
--
-- select from the Table
--
select count(*) from sync2_ao_alter_part_split_default_part2;



--
-- ALTER SYNC1 AO 
--
-- split default partition
--
alter table sync1_ao_alter_part_split_default_part7 split default partition at ('baz') into (partition bing, default partition);
--
-- Insert few records into the table
--

insert into sync1_ao_alter_part_split_default_part7 values ('foo','foo');
insert into sync1_ao_alter_part_split_default_part7 values ('bar','bar');
insert into sync1_ao_alter_part_split_default_part7 values ('foo','bar');
--
-- select from the Table
--
select count(*) from sync1_ao_alter_part_split_default_part7;

--
-- ALTER CK_SYNC1 AO 
--
-- split default partition
--
alter table ck_sync1_ao_alter_part_split_default_part6 split default partition at ('baz') into (partition bing, default partition);
--
-- Insert few records into the table
--

insert into ck_sync1_ao_alter_part_split_default_part6 values ('foo','foo');
insert into ck_sync1_ao_alter_part_split_default_part6 values ('bar','bar');
insert into ck_sync1_ao_alter_part_split_default_part6 values ('foo','bar');
--
-- select from the Table
--
select count(*) from ck_sync1_ao_alter_part_split_default_part6;

--
-- ALTER CT AO 
--
-- split default partition
--
alter table ct_ao_alter_part_split_default_part4 split default partition at ('baz') into (partition bing, default partition);
--
-- Insert few records into the table
--

insert into ct_ao_alter_part_split_default_part4 values ('foo','foo');
insert into ct_ao_alter_part_split_default_part4 values ('bar','bar');
insert into ct_ao_alter_part_split_default_part4 values ('foo','bar');
--
-- select from the Table
--
select count(*) from ct_ao_alter_part_split_default_part4;

--
-- ALTER RESYNC AO 
--
-- split default partition
--
alter table resync_ao_alter_part_split_default_part2 split default partition at ('baz') into (partition bing, default partition);
--
-- Insert few records into the table
--

insert into resync_ao_alter_part_split_default_part2 values ('foo','foo');
insert into resync_ao_alter_part_split_default_part2 values ('bar','bar');
insert into resync_ao_alter_part_split_default_part2 values ('foo','bar');
--
-- select from the Table
--
select count(*) from resync_ao_alter_part_split_default_part2;

--
-- ALTER SYNC2 AO 
--
-- split default partition
--
alter table sync2_ao_alter_part_split_default_part1 split default partition at ('baz') into (partition bing, default partition);
--
-- Insert few records into the table
--

insert into sync2_ao_alter_part_split_default_part1 values ('foo','foo');
insert into sync2_ao_alter_part_split_default_part1 values ('bar','bar');
insert into sync2_ao_alter_part_split_default_part1 values ('foo','bar');
--
-- select from the Table
--
select count(*) from sync2_ao_alter_part_split_default_part1;
