-- start_ignore
SET gp_create_table_random_default_distribution=off;
-- end_ignore
--
-- SYNC2 AO Part Table 1
--
CREATE TABLE sync2_ao_alter_part_add_col1 (id int, rank int, year date, gender
char(1))  with ( appendonly='true') DISTRIBUTED BY (id, gender, year)
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
insert into sync2_ao_alter_part_add_col1 values (1,1,'2001-01-01','F');
insert into sync2_ao_alter_part_add_col1 values (2,2,'2002-01-01','M');
insert into sync2_ao_alter_part_add_col1 values (3,3,'2003-01-01','F');
insert into sync2_ao_alter_part_add_col1 values (4,4,'2003-01-01','M');
--
-- SYNC2 AO Part Table 2
--
CREATE TABLE sync2_ao_alter_part_add_col2 (id int, rank int, year date, gender
char(1))  with ( appendonly='true') DISTRIBUTED BY (id, gender, year)
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
insert into sync2_ao_alter_part_add_col2 values (1,1,'2001-01-01','F');
insert into sync2_ao_alter_part_add_col2 values (2,2,'2002-01-01','M');
insert into sync2_ao_alter_part_add_col2 values (3,3,'2003-01-01','F');
insert into sync2_ao_alter_part_add_col2 values (4,4,'2003-01-01','M');
--
--
--ALTER TABLE TO ADD COL 
--
--
--
-- ALTER SYNC1 AO Part Table 7 To Add INT COL
--
alter table sync1_ao_alter_part_add_col7 add column AAA int default 1;
--
-- INSERT ROWS
--
insert into sync1_ao_alter_part_add_col7 values (5,5,'2001-01-01','F',1);
insert into sync1_ao_alter_part_add_col7 values (6,6,'2002-01-01','M',2);
insert into sync1_ao_alter_part_add_col7 values (7,7,'2003-01-01','F',3);
insert into sync1_ao_alter_part_add_col7 values (8,8,'2003-01-01','M',4);
--
--
-- ALTER SYNC1 AO Part Table 7 To Add TEXT COL
--
--
alter table sync1_ao_alter_part_add_col7 add column BBB text default 'hello';
--
-- INSERT ROWS
--
insert into sync1_ao_alter_part_add_col7 values (5,5,'2001-01-01','F',1,'text1');
insert into sync1_ao_alter_part_add_col7 values (6,6,'2002-01-01','M',2,'text1');
insert into sync1_ao_alter_part_add_col7 values (7,7,'2003-01-01','F',3,'text1');
insert into sync1_ao_alter_part_add_col7 values (8,8,'2003-01-01','M',4,'text1');
--
-- ALTER CK_SYNC1 AO Part Table 6 To Add INT COL
--
alter table ck_sync1_ao_alter_part_add_col6 add column AAA int default 1;
--
-- INSERT ROWS
--
insert into ck_sync1_ao_alter_part_add_col6 values (5,5,'2001-01-01','F',1);
insert into ck_sync1_ao_alter_part_add_col6 values (6,6,'2002-01-01','M',2);
insert into ck_sync1_ao_alter_part_add_col6 values (7,7,'2003-01-01','F',3);
insert into ck_sync1_ao_alter_part_add_col6 values (8,8,'2003-01-01','M',4);
--
--
-- ALTER CK_SYNC1 AO Part Table 6 To Add TEXT COL
--
--
alter table ck_sync1_ao_alter_part_add_col6 add column BBB text default 'hello';
--
-- INSERT ROWS
--
insert into ck_sync1_ao_alter_part_add_col6 values (5,5,'2001-01-01','F',1,'text1');
insert into ck_sync1_ao_alter_part_add_col6 values (6,6,'2002-01-01','M',2,'text1');
insert into ck_sync1_ao_alter_part_add_col6 values (7,7,'2003-01-01','F',3,'text1');
insert into ck_sync1_ao_alter_part_add_col6 values (8,8,'2003-01-01','M',4,'text1');
--
-- ALTER CT AO Part Table 4 To Add INT COL
--
alter table ct_ao_alter_part_add_col4 add column AAA int default 1;
--
-- INSERT ROWS
--
insert into ct_ao_alter_part_add_col4 values (5,5,'2001-01-01','F',1);
insert into ct_ao_alter_part_add_col4 values (6,6,'2002-01-01','M',2);
insert into ct_ao_alter_part_add_col4 values (7,7,'2003-01-01','F',3);
insert into ct_ao_alter_part_add_col4 values (8,8,'2003-01-01','M',4);
--
--
-- ALTER CT AO Part Table 4 To Add TEXT COL
--
--
alter table ct_ao_alter_part_add_col4 add column BBB text default 'hello';
--
-- INSERT ROWS
--
insert into ct_ao_alter_part_add_col4 values (5,5,'2001-01-01','F',1,'text1');
insert into ct_ao_alter_part_add_col4 values (6,6,'2002-01-01','M',2,'text1');
insert into ct_ao_alter_part_add_col4 values (7,7,'2003-01-01','F',3,'text1');
insert into ct_ao_alter_part_add_col4 values (8,8,'2003-01-01','M',4,'text1');
--
-- ALTER RESYNC AO Part Table 2 To Add INT COL
--
alter table resync_ao_alter_part_add_col2 add column AAA int default 1;
--
-- INSERT ROWS
--
insert into resync_ao_alter_part_add_col2 values (5,5,'2001-01-01','F',1);
insert into resync_ao_alter_part_add_col2 values (6,6,'2002-01-01','M',2);
insert into resync_ao_alter_part_add_col2 values (7,7,'2003-01-01','F',3);
insert into resync_ao_alter_part_add_col2 values (8,8,'2003-01-01','M',4);
--
--
-- ALTER RESYNC AO Part Table 2 To Add TEXT COL
--
--
alter table resync_ao_alter_part_add_col2 add column BBB text default 'hello';
--
-- INSERT ROWS
--
insert into resync_ao_alter_part_add_col2 values (5,5,'2001-01-01','F',1,'text1');
insert into resync_ao_alter_part_add_col2 values (6,6,'2002-01-01','M',2,'text1');
insert into resync_ao_alter_part_add_col2 values (7,7,'2003-01-01','F',3,'text1');
insert into resync_ao_alter_part_add_col2 values (8,8,'2003-01-01','M',4,'text1');
--
-- ALTER SYNC2 AO Part Table 1 To Add INT COL
--
alter table sync2_ao_alter_part_add_col1 add column AAA int default 1;
--
-- INSERT ROWS
--
insert into sync2_ao_alter_part_add_col1 values (5,5,'2001-01-01','F',1);
insert into sync2_ao_alter_part_add_col1 values (6,6,'2002-01-01','M',2);
insert into sync2_ao_alter_part_add_col1 values (7,7,'2003-01-01','F',3);
insert into sync2_ao_alter_part_add_col1 values (8,8,'2003-01-01','M',4);
--
--
-- ALTER SYNC2 AO Part Table 1 To Add TEXT COL
--
--
alter table sync2_ao_alter_part_add_col1 add column BBB text default 'hello';
--
-- INSERT ROWS
--
insert into sync2_ao_alter_part_add_col1 values (5,5,'2001-01-01','F',1,'text1');
insert into sync2_ao_alter_part_add_col1 values (6,6,'2002-01-01','M',2,'text1');
insert into sync2_ao_alter_part_add_col1 values (7,7,'2003-01-01','F',3,'text1');
insert into sync2_ao_alter_part_add_col1 values (8,8,'2003-01-01','M',4,'text1');
