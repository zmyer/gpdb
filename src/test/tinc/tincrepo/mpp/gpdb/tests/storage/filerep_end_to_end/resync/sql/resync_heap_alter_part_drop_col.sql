-- start_ignore
SET gp_create_table_random_default_distribution=off;
-- end_ignore
--
-- RESYNC Heap Part Table 1
--
CREATE TABLE resync_heap_alter_part_drop_col1 (id int, name text,rank int, year date, gender  char(1)) DISTRIBUTED BY (id, gender, year)
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
insert into resync_heap_alter_part_drop_col1 values (generate_series(1,10),'ann',1,'2001-01-01','F');

--
-- RESYNC Heap Part Table 2
--
CREATE TABLE resync_heap_alter_part_drop_col2 (id int, name text,rank int, year date, gender  char(1)) DISTRIBUTED BY (id, gender, year)
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
insert into resync_heap_alter_part_drop_col2 values (generate_series(1,10),'ann',1,'2001-01-01','F');

--
-- RESYNC Heap Part Table 3
--
CREATE TABLE resync_heap_alter_part_drop_col3 (id int, name text,rank int, year date, gender  char(1)) DISTRIBUTED BY (id, gender, year)
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
insert into resync_heap_alter_part_drop_col3 values (generate_series(1,10),'ann',1,'2001-01-01','F');


--
--
--ALTER TABLE TO DROP COL
--
--
--
-- ALTER SYNC1 Heap Part Table To DROP INT COL
--
alter table sync1_heap_alter_part_drop_col6 DROP column rank;
--
-- INSERT ROWS
--
insert into sync1_heap_alter_part_drop_col6 values (generate_series(1,10),'ann','2001-01-01','F');
select count(*) from sync1_heap_alter_part_drop_col6;
--
-- ALTER SYNC1 Heap Part Table  To DROP TEXT COL
--
alter table sync1_heap_alter_part_drop_col6 DROP column name;
--
-- INSERT ROWS
--
insert into sync1_heap_alter_part_drop_col6 values (generate_series(1,10),'2001-01-01','F');
select count(*) from sync1_heap_alter_part_drop_col6;

--
-- ALTER CK_SYNC1 Heap Part Table To DROP INT COL
--
alter table ck_sync1_heap_alter_part_drop_col5 DROP column rank;
--
-- INSERT ROWS
--
insert into ck_sync1_heap_alter_part_drop_col5 values (generate_series(1,10),'ann','2001-01-01','F');
select count(*) from ck_sync1_heap_alter_part_drop_col5;
--
-- ALTER CK_SYNC1 Heap Part Table  To DROP TEXT COL
--
alter table ck_sync1_heap_alter_part_drop_col5 DROP column name;
--
-- INSERT ROWS
--
insert into ck_sync1_heap_alter_part_drop_col5 values (generate_series(1,10),'2001-01-01','F');
select count(*) from ck_sync1_heap_alter_part_drop_col5;

--
-- ALTER CT Heap Part Table To DROP INT COL
--
alter table ct_heap_alter_part_drop_col3 DROP column rank;
--
-- INSERT ROWS
--
insert into ct_heap_alter_part_drop_col3 values (generate_series(1,10),'ann','2001-01-01','F');
select count(*) from ct_heap_alter_part_drop_col3;
--
-- ALTER CT Heap Part Table  To DROP TEXT COL
--
alter table ct_heap_alter_part_drop_col3 DROP column name;
--
-- INSERT ROWS
--
insert into ct_heap_alter_part_drop_col3 values (generate_series(1,10),'2001-01-01','F');
select count(*) from ct_heap_alter_part_drop_col3;

--
-- ALTER RESYNC Heap Part Table To DROP INT COL
--
alter table resync_heap_alter_part_drop_col1 DROP column rank;
--
-- INSERT ROWS
--
insert into resync_heap_alter_part_drop_col1 values (generate_series(1,10),'ann','2001-01-01','F');
select count(*) from resync_heap_alter_part_drop_col1;
--
-- ALTER RESYNC Heap Part Table  To DROP TEXT COL
--
alter table resync_heap_alter_part_drop_col1 DROP column name;
--
-- INSERT ROWS
--
insert into resync_heap_alter_part_drop_col1 values (generate_series(1,10),'2001-01-01','F');
select count(*) from resync_heap_alter_part_drop_col1;
