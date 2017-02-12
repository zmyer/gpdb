-- start_ignore
SET gp_create_table_random_default_distribution=off;
-- end_ignore
--
-- RESYNC CO TABLE 1
--
create table resync_co_alter_part_split_partrange1 (i int)  with ( appendonly='true', orientation='column') partition by range(i) (start(1) end(10) every(5));
--
-- Insert few records into the table
--
insert into resync_co_alter_part_split_partrange1 values (generate_series(1,9));
--
-- select from the Table
--
select count(*) from resync_co_alter_part_split_partrange1;

--
-- RESYNC CO TABLE 2
--
create table resync_co_alter_part_split_partrange2 (i int)  with ( appendonly='true', orientation='column') partition by range(i) (start(1) end(10) every(5));
--
-- Insert few records into the table
--
insert into resync_co_alter_part_split_partrange2 values (generate_series(1,9));
--
-- select from the Table
--
select count(*) from resync_co_alter_part_split_partrange2;


--
-- RESYNC CO TABLE 3
--
create table resync_co_alter_part_split_partrange3 (i int)  with ( appendonly='true', orientation='column') partition by range(i) (start(1) end(10) every(5));
--
-- Insert few records into the table
--
insert into resync_co_alter_part_split_partrange3 values (generate_series(1,9));
--
-- select from the Table
--
select count(*) from resync_co_alter_part_split_partrange3;





--
-- ALTER SYNC1 CO
--

--
-- Split Partition Range
--
alter table sync1_co_alter_part_split_partrange6 split partition for(1) at (5) into (partition aa, partition bb);
--
-- Insert few records into the table
--
insert into sync1_co_alter_part_split_partrange6 values (generate_series(1,9));
--
-- select from the Table
--
select count(*) from sync1_co_alter_part_split_partrange6;


--
-- ALTER CK_SYNC1 CO
--

--
-- Split Partition Range
--
alter table ck_sync1_co_alter_part_split_partrange5 split partition for(1) at (5) into (partition aa, partition bb);
--
-- Insert few records into the table
--
insert into ck_sync1_co_alter_part_split_partrange5 values (generate_series(1,9));
--
-- select from the Table
--
select count(*) from ck_sync1_co_alter_part_split_partrange5;

-- ALTER CT CO
--

--
-- Split Partition Range
--
alter table ct_co_alter_part_split_partrange3 split partition for(1) at (5) into (partition aa, partition bb);
--
-- Insert few records into the table
--
insert into ct_co_alter_part_split_partrange3 values (generate_series(1,9));
--
-- select from the Table
--
select count(*) from ct_co_alter_part_split_partrange3;

--
-- ALTER RESYNC CO
--

--
-- Split Partition Range
--
alter table resync_co_alter_part_split_partrange1 split partition for(1) at (5) into (partition aa, partition bb);
--
-- Insert few records into the table
--
insert into resync_co_alter_part_split_partrange1 values (generate_series(1,9));
--
-- select from the Table
--
select count(*) from resync_co_alter_part_split_partrange1;

