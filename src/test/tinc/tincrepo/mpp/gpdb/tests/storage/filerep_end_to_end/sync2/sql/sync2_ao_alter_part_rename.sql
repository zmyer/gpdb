-- start_ignore
SET gp_create_table_random_default_distribution=off;
-- end_ignore
--
-- SYNC2 AO TABLE 1
--
CREATE TABLE sync2_ao_alter_part_rn1 (id int, rank int, year date, gender
char(1))   with ( appendonly='true') DISTRIBUTED BY (id, gender, year)
partition by list (gender)
subpartition by range (year)
subpartition template (
start (date '2001-01-01'))
(
values ('M'),
values ('F')
);
--
-- Insert few records into the table
--
insert into sync2_ao_alter_part_rn1 values (generate_series(1,20),1,'2001-01-01','F');

--
-- select from the Table
--
select count(*) from sync2_ao_alter_part_rn1;

--
-- SYNC2 AO TABLE 2
--
CREATE TABLE sync2_ao_alter_part_rn2 (id int, rank int, year date, gender
char(1))   with ( appendonly='true') DISTRIBUTED BY (id, gender, year)
partition by list (gender)
subpartition by range (year)
subpartition template (
start (date '2001-01-01'))
(
values ('M'),
values ('F')
);
--
-- Insert few records into the table
--
insert into sync2_ao_alter_part_rn2 values (generate_series(1,20),1,'2001-01-01','F');

--
-- select from the Table
--
select count(*) from sync2_ao_alter_part_rn2;


--
-- ALTER SYNC1 AO
--

--
-- Add default Partition
--
alter table sync1_ao_alter_part_rn7 add default partition default_part;
--
-- Rename Default Partition
--
alter table sync1_ao_alter_part_rn7 rename default partition to new_default_part;

--
-- Insert few records into the table
--
insert into sync1_ao_alter_part_rn7 values (generate_series(1,10),1,'2001-01-01','F');

--
-- select from the Table
--
select count(*) from sync1_ao_alter_part_rn7;

--
-- Rename Table
--
alter table sync1_ao_alter_part_rn7 rename to  sync1_ao_alter_part_rn7_0;

--
-- Insert few records into the table
--
insert into sync1_ao_alter_part_rn7_0 values (generate_series(1,10),1,'2001-01-01','F');

--
-- select from the Table
--
select count(*) from sync1_ao_alter_part_rn7_0;
--
-- ALTER CK_SYNC1 AO
--

--
-- Add default Partition
--
alter table ck_sync1_ao_alter_part_rn6 add default partition default_part;
--
-- Rename Default Partition
--
alter table ck_sync1_ao_alter_part_rn6 rename default partition to new_default_part;

--
-- Insert few records into the table
--
insert into ck_sync1_ao_alter_part_rn6 values (generate_series(1,10),1,'2001-01-01','F');

--
-- select from the Table
--
select count(*) from ck_sync1_ao_alter_part_rn6;

--
-- Rename Table
--
alter table ck_sync1_ao_alter_part_rn6 rename to  ck_sync1_ao_alter_part_rn6_0;

--
-- Insert few records into the table
--
insert into ck_sync1_ao_alter_part_rn6_0 values (generate_series(1,10),1,'2001-01-01','F');

--
-- select from the Table
--
select count(*) from ck_sync1_ao_alter_part_rn6_0;

--
-- ALTER CT AO
--

--
-- Add default Partition
--
alter table ct_ao_alter_part_rn4 add default partition default_part;
--
-- Rename Default Partition
--
alter table ct_ao_alter_part_rn4 rename default partition to new_default_part;

--
-- Insert few records into the table
--
insert into ct_ao_alter_part_rn4 values (generate_series(1,10),1,'2001-01-01','F');

--
-- select from the Table
--
select count(*) from ct_ao_alter_part_rn4;

--
-- Rename Table
--
alter table ct_ao_alter_part_rn4 rename to  ct_ao_alter_part_rn4_0;

--
-- Insert few records into the table
--
insert into ct_ao_alter_part_rn4_0 values (generate_series(1,10),1,'2001-01-01','F');

--
-- select from the Table
--
select count(*) from ct_ao_alter_part_rn4_0;

--
-- ALTER RESYNC AO
--

--
-- Add default Partition
--
alter table resync_ao_alter_part_rn2 add default partition default_part;
--
-- Rename Default Partition
--
alter table resync_ao_alter_part_rn2 rename default partition to new_default_part;

--
-- Insert few records into the table
--
insert into resync_ao_alter_part_rn2 values (generate_series(1,10),1,'2001-01-01','F');

--
-- select from the Table
--
select count(*) from resync_ao_alter_part_rn2;

--
-- Rename Table
--
alter table resync_ao_alter_part_rn2 rename to  resync_ao_alter_part_rn2_0;

--
-- Insert few records into the table
--
insert into resync_ao_alter_part_rn2_0 values (generate_series(1,10),1,'2001-01-01','F');

--
-- select from the Table
--
select count(*) from resync_ao_alter_part_rn2_0;

--
-- ALTER SYNC2 AO
--

--
-- Add default Partition
--
alter table sync2_ao_alter_part_rn1 add default partition default_part;
--
-- Rename Default Partition
--
alter table sync2_ao_alter_part_rn1 rename default partition to new_default_part;

--
-- Insert few records into the table
--
insert into sync2_ao_alter_part_rn1 values (generate_series(1,10),1,'2001-01-01','F');

--
-- select from the Table
--
select count(*) from sync2_ao_alter_part_rn1;

--
-- Rename Table
--
alter table sync2_ao_alter_part_rn1 rename to  sync2_ao_alter_part_rn1_0;

--
-- Insert few records into the table
--
insert into sync2_ao_alter_part_rn1_0 values (generate_series(1,10),1,'2001-01-01','F');

--
-- select from the Table
--
select count(*) from sync2_ao_alter_part_rn1_0;
