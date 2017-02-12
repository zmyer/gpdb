-- start_ignore
SET gp_create_table_random_default_distribution=off;
-- end_ignore
--
-- SYNC2 AO TABLE 1
--
create table sync2_ao_alter_part_split_partlist1 (i int)  with ( appendonly='true') partition by list(i) (partition a values(1, 2, 3, 4),
partition b values(5, 6, 7, 8), default partition default_part);
--
-- Insert few records into the table
--
insert into sync2_ao_alter_part_split_partlist1 values (generate_series(1,10));
--
-- select from the Table
--
select count(*) from sync2_ao_alter_part_split_partlist1;


--
-- SYNC2 AO TABLE 2
--
create table sync2_ao_alter_part_split_partlist2 (i int)  with ( appendonly='true') partition by list(i) (partition a values(1, 2, 3, 4),
partition b values(5, 6, 7, 8), default partition default_part);
--
-- Insert few records into the table
--
insert into sync2_ao_alter_part_split_partlist2 values (generate_series(1,10));
--
-- select from the Table
--
select count(*) from sync2_ao_alter_part_split_partlist2;





--
--ALTER SYNC1 AO TABLE
--
--
-- split partition
--
alter table sync1_ao_alter_part_split_partlist7 split partition for(1) at (1,2) into (partition f1a, partition f1b);
--
-- Insert few records into the table
--
insert into sync1_ao_alter_part_split_partlist7 values (generate_series(1,10));
--
-- Alter the table set distributed by 
--
Alter table sync1_ao_alter_part_split_partlist7  set with ( reorganize='true') distributed randomly;
--
-- select from the Table
--
select count(*) from sync1_ao_alter_part_split_partlist7;

--
--ALTER CK_SYNC1 AO TABLE
--
--
-- split partition
--
alter table ck_sync1_ao_alter_part_split_partlist6 split partition for(1) at (1,2) into (partition f1a, partition f1b);
--
-- Insert few records into the table
--
insert into ck_sync1_ao_alter_part_split_partlist6 values (generate_series(1,10));
--
-- Alter the table set distributed by 
--
Alter table ck_sync1_ao_alter_part_split_partlist6  set with ( reorganize='true') distributed randomly;
--
-- select from the Table
--
select count(*) from ck_sync1_ao_alter_part_split_partlist6;

--
--ALTER CT AO TABLE
--
--
-- split partition
--
alter table ct_ao_alter_part_split_partlist4 split partition for(1) at (1,2) into (partition f1a, partition f1b);
--
-- Insert few records into the table
--
insert into ct_ao_alter_part_split_partlist4 values (generate_series(1,10));
--
-- Alter the table set distributed by 
--
Alter table ct_ao_alter_part_split_partlist4  set with ( reorganize='true') distributed randomly;
--
-- select from the Table
--
select count(*) from ct_ao_alter_part_split_partlist4;

--
--ALTER RESYNC AO TABLE
--
--
-- split partition
--
alter table resync_ao_alter_part_split_partlist2 split partition for(1) at (1,2) into (partition f1a, partition f1b);
--
-- Insert few records into the table
--
insert into resync_ao_alter_part_split_partlist2 values (generate_series(1,10));
--
-- Alter the table set distributed by 
--
Alter table resync_ao_alter_part_split_partlist2  set with ( reorganize='true') distributed randomly;
--
-- select from the Table
--
select count(*) from resync_ao_alter_part_split_partlist2;
--
--ALTER SYNC2 AO TABLE
--
--
-- split partition
--
alter table sync2_ao_alter_part_split_partlist1 split partition for(1) at (1,2) into (partition f1a, partition f1b);
--
-- Insert few records into the table
--
insert into sync2_ao_alter_part_split_partlist1 values (generate_series(1,10));
--
-- Alter the table set distributed by 
--
Alter table sync2_ao_alter_part_split_partlist1  set with ( reorganize='true') distributed randomly;
--
-- select from the Table
--
select count(*) from sync2_ao_alter_part_split_partlist1;


