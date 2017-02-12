-- @product_version gpdb: [4.3.0.0-]
--
-- SYNC1 UAOCS TABLE 1
--

CREATE TABLE sync1_uaocs_alter_part_truncate_part1 (
        unique1         int4,
        unique2         int4
)  with ( appendonly='true', orientation='column') partition by range (unique1)
( partition aa start (0) end (500) every (100), default partition default_part );


CREATE TABLE sync1_uaocs_alter_part_truncate_part1_A (
        unique1         int4,
        unique2         int4)with ( appendonly='true', orientation='column') ;
--
-- Insert few records into the table
--
insert into sync1_uaocs_alter_part_truncate_part1 values ( generate_series(5,50),generate_series(15,60));
insert into sync1_uaocs_alter_part_truncate_part1_A values ( generate_series(1,10),generate_series(21,30));

select count(*) FROM pg_appendonly WHERE visimaprelid is not NULL AND visimapidxid is not NULL AND relid in (SELECT oid FROM pg_class WHERE relname ='sync1_uaocs_alter_part_truncate_part1');
select count(*) AS only_visi_tups_ins  from sync1_uaocs_alter_part_truncate_part1;
set gp_select_invisible = true;
select count(*) AS invisi_and_visi_tups_ins  from sync1_uaocs_alter_part_truncate_part1;
set gp_select_invisible = false;
update sync1_uaocs_alter_part_truncate_part1 set  unique2 = unique2 + 100   where unique1=6;
select count(*) AS only_visi_tups_upd  from sync1_uaocs_alter_part_truncate_part1;
set gp_select_invisible = true;
select count(*) AS invisi_and_visi_tups  from sync1_uaocs_alter_part_truncate_part1;
set gp_select_invisible = false;
delete from sync1_uaocs_alter_part_truncate_part1  where unique1>=7;
select count(*) AS only_visi_tups  from sync1_uaocs_alter_part_truncate_part1;
set gp_select_invisible = true;
select count(*) AS invisi_and_visi_tups  from sync1_uaocs_alter_part_truncate_part1;
set gp_select_invisible = false;
--
-- select from the Table
--
select count(*) from sync1_uaocs_alter_part_truncate_part1;


--
-- SYNC1 UAOCS TABLE 2
--

CREATE TABLE sync1_uaocs_alter_part_truncate_part2 (
        unique1         int4,
        unique2         int4
)  with ( appendonly='true', orientation='column') partition by range (unique1)
( partition aa start (0) end (500) every (100), default partition default_part );


CREATE TABLE sync1_uaocs_alter_part_truncate_part2_A (
        unique1         int4,
        unique2         int4) with ( appendonly='true', orientation='column');
--
-- Insert few records into the table
--
insert into sync1_uaocs_alter_part_truncate_part2 values ( generate_series(5,50),generate_series(15,60));
insert into sync1_uaocs_alter_part_truncate_part2_A values ( generate_series(1,10),generate_series(21,30));
--
-- select from the Table
--
select count(*) from sync1_uaocs_alter_part_truncate_part2;


--
-- SYNC1 UAOCS TABLE 3
--

CREATE TABLE sync1_uaocs_alter_part_truncate_part3 (
        unique1         int4,
        unique2         int4
)  with ( appendonly='true', orientation='column') partition by range (unique1)
( partition aa start (0) end (500) every (100), default partition default_part );


CREATE TABLE sync1_uaocs_alter_part_truncate_part3_A (
        unique1         int4,
        unique2         int4) with ( appendonly='true', orientation='column');
--
-- Insert few records into the table
--
insert into sync1_uaocs_alter_part_truncate_part3 values ( generate_series(5,50),generate_series(15,60));
insert into sync1_uaocs_alter_part_truncate_part3_A values ( generate_series(1,10),generate_series(21,30));
--
-- select from the Table
--
select count(*) from sync1_uaocs_alter_part_truncate_part3;



--
-- SYNC1 UAOCS TABLE 4
--

CREATE TABLE sync1_uaocs_alter_part_truncate_part4 (
        unique1         int4,
        unique2         int4
)  with ( appendonly='true', orientation='column') partition by range (unique1)
( partition aa start (0) end (500) every (100), default partition default_part );


CREATE TABLE sync1_uaocs_alter_part_truncate_part4_A (
        unique1         int4,
        unique2         int4) with ( appendonly='true', orientation='column');
--
-- Insert few records into the table
--
insert into sync1_uaocs_alter_part_truncate_part4 values ( generate_series(5,50),generate_series(15,60));
insert into sync1_uaocs_alter_part_truncate_part4_A values ( generate_series(1,10),generate_series(21,30));
--
-- select from the Table
--
select count(*) from sync1_uaocs_alter_part_truncate_part4;


--
-- SYNC1 UAOCS TABLE 5
--

CREATE TABLE sync1_uaocs_alter_part_truncate_part5 (
        unique1         int4,
        unique2         int4
)  with ( appendonly='true', orientation='column') partition by range (unique1)
( partition aa start (0) end (500) every (100), default partition default_part );


CREATE TABLE sync1_uaocs_alter_part_truncate_part5_A (
        unique1         int4,
        unique2         int4) with ( appendonly='true', orientation='column');
--
-- Insert few records into the table
--
insert into sync1_uaocs_alter_part_truncate_part5 values ( generate_series(5,50),generate_series(15,60));
insert into sync1_uaocs_alter_part_truncate_part5_A values ( generate_series(1,10),generate_series(21,30));
--
-- select from the Table
--
select count(*) from sync1_uaocs_alter_part_truncate_part5;



--
-- SYNC1 UAOCS TABLE 6
--

CREATE TABLE sync1_uaocs_alter_part_truncate_part6 (
        unique1         int4,
        unique2         int4
)  with ( appendonly='true', orientation='column') partition by range (unique1)
( partition aa start (0) end (500) every (100), default partition default_part );


CREATE TABLE sync1_uaocs_alter_part_truncate_part6_A (
        unique1         int4,
        unique2         int4) with ( appendonly='true', orientation='column');
--
-- Insert few records into the table
--
insert into sync1_uaocs_alter_part_truncate_part6 values ( generate_series(5,50),generate_series(15,60));
insert into sync1_uaocs_alter_part_truncate_part6_A values ( generate_series(1,10),generate_series(21,30));
--
-- select from the Table
--
select count(*) from sync1_uaocs_alter_part_truncate_part6;



--
-- SYNC1 UAOCS TABLE 7
--

CREATE TABLE sync1_uaocs_alter_part_truncate_part7 (
        unique1         int4,
        unique2         int4
)  with ( appendonly='true', orientation='column') partition by range (unique1)
( partition aa start (0) end (500) every (100), default partition default_part );


CREATE TABLE sync1_uaocs_alter_part_truncate_part7_A (
        unique1         int4,
        unique2         int4) with ( appendonly='true', orientation='column');
--
-- Insert few records into the table
--
insert into sync1_uaocs_alter_part_truncate_part7 values ( generate_series(5,50),generate_series(15,60));
insert into sync1_uaocs_alter_part_truncate_part7_A values ( generate_series(1,10),generate_series(21,30));
--
-- select from the Table
--
select count(*) from sync1_uaocs_alter_part_truncate_part7;



--
-- SYNC1 UAOCS TABLE 8
--

CREATE TABLE sync1_uaocs_alter_part_truncate_part8 (
        unique1         int4,
        unique2         int4
)  with ( appendonly='true', orientation='column') partition by range (unique1)
( partition aa start (0) end (500) every (100), default partition default_part );


CREATE TABLE sync1_uaocs_alter_part_truncate_part8_A (
        unique1         int4,
        unique2         int4) with ( appendonly='true', orientation='column');
--
-- Insert few records into the table
--
insert into sync1_uaocs_alter_part_truncate_part8 values ( generate_series(5,50),generate_series(15,60));
insert into sync1_uaocs_alter_part_truncate_part8_A values ( generate_series(1,10),generate_series(21,30));
--
-- select from the Table
--
select count(*) from sync1_uaocs_alter_part_truncate_part8;

--
-- ALTER SYNC1 CO
--

--
-- Truncate Partition
--
alter table sync1_uaocs_alter_part_truncate_part1 truncate partition for (rank(1));

--
-- Insert few records into the table
--
insert into sync1_uaocs_alter_part_truncate_part1 values ( generate_series(5,50),generate_series(15,60));
insert into sync1_uaocs_alter_part_truncate_part1_A values ( generate_series(1,10),generate_series(21,30));
select count(*) FROM pg_appendonly WHERE visimaprelid is not NULL AND visimapidxid is not NULL AND relid in (SELECT oid FROM pg_class WHERE relname ='sync1_uaocs_alter_part_truncate_part1');
select count(*) AS only_visi_tups_ins  from sync1_uaocs_alter_part_truncate_part1;
set gp_select_invisible = true;
select count(*) AS invisi_and_visi_tups_ins  from sync1_uaocs_alter_part_truncate_part1;
set gp_select_invisible = false;
update sync1_uaocs_alter_part_truncate_part1 set  unique2 = unique2 + 100   where unique1=6;
select count(*) AS only_visi_tups_upd  from sync1_uaocs_alter_part_truncate_part1;
set gp_select_invisible = true;
select count(*) AS invisi_and_visi_tups  from sync1_uaocs_alter_part_truncate_part1;
set gp_select_invisible = false;
delete from sync1_uaocs_alter_part_truncate_part1  where unique1>=7;
select count(*) AS only_visi_tups  from sync1_uaocs_alter_part_truncate_part1;
set gp_select_invisible = true;
select count(*) AS invisi_and_visi_tups  from sync1_uaocs_alter_part_truncate_part1;
set gp_select_invisible = false;
--
-- Alter the table set distributed by 
--
Alter table sync1_uaocs_alter_part_truncate_part1 set with ( reorganize='true') distributed by (unique2);
--
-- select from the Table
--
select count(*) from sync1_uaocs_alter_part_truncate_part1;
--
-- Truncate default partition
--
alter table sync1_uaocs_alter_part_truncate_part1 truncate default partition;
--
-- Insert few records into the table
--
insert into sync1_uaocs_alter_part_truncate_part1 values ( generate_series(5,50),generate_series(15,60));
insert into sync1_uaocs_alter_part_truncate_part1_A values ( generate_series(1,10),generate_series(21,30));
--
-- select from the Table
--
select count(*) from sync1_uaocs_alter_part_truncate_part1;

