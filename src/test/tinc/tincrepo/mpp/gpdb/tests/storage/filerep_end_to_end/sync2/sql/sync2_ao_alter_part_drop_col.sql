-- start_ignore
SET gp_create_table_random_default_distribution=off;
-- end_ignore
--
-- SYNC2 AO Part Table 1
--
CREATE TABLE sync2_ao_alter_part_drop_col1 (id int, name text,rank int, year date, gender  char(1))  with ( appendonly='true') DISTRIBUTED BY (id, gender, year)
partition by list (gender)
subpartition by range (year)
subpartition template (
start (date '2001-01-01'))
(
values ('M'),
values ('F')
);
--
-- INSERT ROWS
--
insert into sync2_ao_alter_part_drop_col1 values (generate_series(1,10),'ann',1,'2001-01-01','F');

--
-- SYNC2 AO Part Table 2
--
CREATE TABLE sync2_ao_alter_part_drop_col2 (id int, name text,rank int, year date, gender  char(1))  with ( appendonly='true') DISTRIBUTED BY (id, gender, year)
partition by list (gender)
subpartition by range (year)
subpartition template (
start (date '2001-01-01'))
(
values ('M'),
values ('F')
);
--
-- INSERT ROWS
--
insert into sync2_ao_alter_part_drop_col2 values (generate_series(1,10),'ann',1,'2001-01-01','F');

--
--
--ALTER TABLE TO DROP COL
--
--
--
-- ALTER SYNC1 AO Part Table To DROP INT COL
--
alter table sync1_ao_alter_part_drop_col7 DROP column rank;
--
-- INSERT ROWS
--
insert into sync1_ao_alter_part_drop_col7 values (generate_series(1,10),'ann','2001-01-01','F');
select count(*) from sync1_ao_alter_part_drop_col7;
--
-- ALTER SYNC1 AO Part Table  To DROP TEXT COL
--
alter table sync1_ao_alter_part_drop_col7 DROP column name;
--
-- INSERT ROWS
--
insert into sync1_ao_alter_part_drop_col7 values (generate_series(1,10),'2001-01-01','F');
select count(*) from sync1_ao_alter_part_drop_col7;

--
-- ALTER CK_SYNC1 AO Part Table To DROP INT COL
--
alter table ck_sync1_ao_alter_part_drop_col6 DROP column rank;
--
-- INSERT ROWS
--
insert into ck_sync1_ao_alter_part_drop_col6 values (generate_series(1,10),'ann','2001-01-01','F');
select count(*) from ck_sync1_ao_alter_part_drop_col6;
--
-- ALTER CK_SYNC1 AO Part Table  To DROP TEXT COL
--
alter table ck_sync1_ao_alter_part_drop_col6 DROP column name;
--
-- INSERT ROWS
--
insert into ck_sync1_ao_alter_part_drop_col6 values (generate_series(1,10),'2001-01-01','F');
select count(*) from ck_sync1_ao_alter_part_drop_col6;

--
-- ALTER CT AO Part Table To DROP INT COL
--
alter table ct_ao_alter_part_drop_col4 DROP column rank;
--
-- INSERT ROWS
--
insert into ct_ao_alter_part_drop_col4 values (generate_series(1,10),'ann','2001-01-01','F');
select count(*) from ct_ao_alter_part_drop_col4;
--
-- ALTER CT AO Part Table  To DROP TEXT COL
--
alter table ct_ao_alter_part_drop_col4 DROP column name;
--
-- INSERT ROWS
--
insert into ct_ao_alter_part_drop_col4 values (generate_series(1,10),'2001-01-01','F');
select count(*) from ct_ao_alter_part_drop_col4;

--
-- ALTER RESYNC AO Part Table To DROP INT COL
--
alter table resync_ao_alter_part_drop_col2 DROP column rank;
--
-- INSERT ROWS
--
insert into resync_ao_alter_part_drop_col2 values (generate_series(1,10),'ann','2001-01-01','F');
select count(*) from resync_ao_alter_part_drop_col2;
--
-- ALTER RESYNC AO Part Table  To DROP TEXT COL
--
alter table resync_ao_alter_part_drop_col2 DROP column name;
--
-- INSERT ROWS
--
insert into resync_ao_alter_part_drop_col2 values (generate_series(1,10),'2001-01-01','F');
select count(*) from resync_ao_alter_part_drop_col2;

--
-- ALTER SYNC2 AO Part Table To DROP INT COL
--
alter table sync2_ao_alter_part_drop_col1 DROP column rank;
--
-- INSERT ROWS
--
insert into sync2_ao_alter_part_drop_col1 values (generate_series(1,10),'ann','2001-01-01','F');
select count(*) from sync2_ao_alter_part_drop_col1;
--
-- ALTER SYNC2 AO Part Table  To DROP TEXT COL
--
alter table sync2_ao_alter_part_drop_col1 DROP column name;
--
-- INSERT ROWS
--
insert into sync2_ao_alter_part_drop_col1 values (generate_series(1,10),'2001-01-01','F');
select count(*) from sync2_ao_alter_part_drop_col1;
