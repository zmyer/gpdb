-- start_ignore
SET gp_create_table_random_default_distribution=off;
-- end_ignore
--
-- Drop table if exists
--
DROP TABLE if exists co_cr_partrle_type32768_4 cascade;

DROP TABLE if exists co_cr_partrle_type32768_4_uncompr cascade;

--
-- Create table
--
CREATE TABLE co_cr_partrle_type32768_4 
	(id SERIAL,a1 int,a2 char(5),a3 numeric,a4 boolean DEFAULT false ,a5 char DEFAULT 'd',a6 text,a7 timestamp,a8 character varying(705),a9 bigint,a10 date,a11 varchar(600),a12 text,a13 decimal,a14 real,a15 bigint,a16 int4 ,a17 bytea,a18 timestamp with time zone,a19 timetz,a20 path,a21 box,a22 macaddr,a23 interval,a24 character varying(800),a25 lseg,a26 point,a27 double precision,a28 circle,a29 int4,a30 numeric(8),a31 polygon,a32 date,a33 real,a34 money,a35 cidr,a36 inet,a37 time,a38 text,a39 bit,a40 bit varying(5),a41 smallint,a42 int )  WITH (appendonly=true, orientation=column) distributed randomly 
Partition by range(a1) (start(1)  end(5000) every(1000) ,
 COLUMN  a1 ENCODING (compresstype=rle_type,compresslevel=4,blocksize=32768),
 COLUMN a5 ENCODING (compresstype=quicklz,compresslevel=1, blocksize=32768),
 DEFAULT COLUMN ENCODING (compresstype=rle_type,compresslevel=4,blocksize=32768));

-- 
-- Create Indexes
--
CREATE INDEX co_cr_partrle_type32768_4_idx_bitmap ON co_cr_partrle_type32768_4 USING bitmap (a1);

CREATE INDEX co_cr_partrle_type32768_4_idx_btree ON co_cr_partrle_type32768_4(a9);

--
-- Insert data to the table
--
COPY co_cr_partrle_type32768_4(a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,a31,a32,a33,a34,a35,a36,a37,a38,a39,a40,a41,a42)  FROM '/data/sivand/test/tincrepo/private/sivand/mpp/gpdb/tests/storage/aoco_compression/data/copy_base_small' DELIMITER AS '|' ;


--Create Uncompressed table of same schema definition

CREATE TABLE co_cr_partrle_type32768_4_uncompr(id SERIAL,a1 int,a2 char(5),a3 numeric,a4 boolean DEFAULT false ,a5 char DEFAULT 'd',a6 text,a7 timestamp,a8 character varying(705),a9 bigint,a10 date,a11 varchar(600),a12 text,a13 decimal,a14 real,a15 bigint,a16 int4 ,a17 bytea,a18 timestamp with time zone,a19 timetz,a20 path,a21 box,a22 macaddr,a23 interval,a24 character varying(800),a25 lseg,a26 point,a27 double precision,a28 circle,a29 int4,a30 numeric(8),a31 polygon,a32 date,a33 real,a34 money,a35 cidr,a36 inet,a37 time,a38 text,a39 bit,a40 bit varying(5),a41 smallint,a42 int) WITH (appendonly=true, orientation=column) distributed randomly Partition by range(a1) (start(1)  end(5000) every(1000)) ;

--
-- Insert to uncompressed table
--
COPY co_cr_partrle_type32768_4_uncompr(a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,a31,a32,a33,a34,a35,a36,a37,a38,a39,a40,a41,a42)  FROM '/data/sivand/test/tincrepo/private/sivand/mpp/gpdb/tests/storage/aoco_compression/data/copy_base_small' DELIMITER AS '|' ;

--
-- ********Validation******* 
--
\d+ co_cr_partrle_type32768_4_1_prt_1

--
-- Compression ratio
--
 select 'compression_ratio' as compr_ratio ,get_ao_compression_ratio('co_cr_partrle_type32768_4_1_prt_1'); 

--
-- Compare data with uncompressed table
--
--
-- Select number of rows from the uncompressed table 
--
SELECT count(*) as count_uncompressed from  co_cr_partrle_type32768_4_uncompr ;
--
-- Select number of rows from the compressed table 
--
SELECT count(*) as count_compressed from  co_cr_partrle_type32768_4;
--
-- Select number of rows using a FULL outer join on all the columns of the two tables 
-- Count should match with above result if the all the rows uncompressed correctly: 
--
Select count(*) as count_join from co_cr_partrle_type32768_4 t1 full outer join co_cr_partrle_type32768_4_uncompr t2 on t1.id=t2.id and t1.a1=t2.a1 and t1.a2=t2.a2 and t1.a3=t2.a3 and t1.a4=t2.a4 and t1.a5=t2.a5 and t1.a6=t2.a6 and t1.a7=t2.a7 and t1.a8=t2.a8 and t1.a9=t2.a9 and t1.a10=t2.a10 and t1.a11=t2.a11 and t1.a12=t2.a12 and t1.a13=t2.a13 and t1.a14=t2.a14 and t1.a15=t2.a15 and t1.a16=t2.a16 and t1.a17=t2.a17 and t1.a18=t2.a18 and t1.a19=t2.a19 and t1.a22=t2.a22 and t1.a23=t2.a23 and t1.a24=t2.a24 and t1.a27=t2.a27 and t1.a29=t2.a29 and t1.a30=t2.a30 and t1.a32=t2.a32 and t1.a33=t2.a33 and t1.a34=t2.a34 and t1.a35=t2.a35 and t1.a36=t2.a36 and t1.a37=t2.a37 and t1.a38=t2.a38 and t1.a39=t2.a39 and t1.a40=t2.a40 and t1.a41=t2.a41 and t1.a42=t2.a42 ;
--
-- Truncate the table 
--
TRUNCATE table co_cr_partrle_type32768_4;
--
-- Insert data again 
--
insert into co_cr_partrle_type32768_4 select * from co_cr_partrle_type32768_4_uncompr order by a1;

--
-- Compression ratio
--

--Alter table Add Partition 
alter table co_cr_partrle_type32768_4 add partition new_p start(5050) end (5061);

alter table co_cr_partrle_type32768_4 add default partition df_p;

-- Insert data 
Insert into co_cr_partrle_type32768_4(a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,a31,a32,a33,a34,a35,a36,a37,a38,a39,a40,a41,a42) values(generate_series(1,5000),'C',2011,'t','a','dfjjjjjj','2001-12-24 02:26:11','hghgh',333,'2011-10-11','Tddd','sss','1234.56',323453,4454,7845,'0011','2005-07-16 01:51:15+1359','2001-12-13 01:51:15','((1,2),(0,3),(2,1))','((2,3)(4,5))','08:00:2b:01:02:03','1-2','dfdf','((2,3)(4,5))','(6,7)',11.222,'((4,5),7)',32,3214,'(1,0,2,3)','2010-02-21',43564,'$1,000.00','192.168.1','126.1.3.4','12:30:45','ggg','1','0',12,23) ; 

Insert into co_cr_partrle_type32768_4(a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,a31,a32,a33,a34,a35,a36,a37,a38,a39,a40,a41,a42) values(generate_series(5061,6050),'F',2011,'t','a','dfjjjjjj','2001-12-24 02:26:11','hghgh',333,'2011-10-11','Tddd','sss','1234.56',323453,4454,7845,'0011','2005-07-16 01:51:15+1359','2001-12-13 01:51:15','((1,2),(0,3),(2,1))','((2,3)(4,5))','08:00:2b:01:02:03','1-2','dfdf','((2,3)(4,5))','(6,7)',11.222,'((4,5),7)',32,3214,'(1,0,2,3)','2010-02-21',43564,'$1,000.00','192.168.1','126.1.3.4','12:30:45','ggg','1','0',12,23) ; 

Insert into co_cr_partrle_type32768_4(a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,a31,a32,a33,a34,a35,a36,a37,a38,a39,a40,a41,a42) values(generate_series(5051,6050),'M',2011,'t','a','dfjjjjjj','2001-12-24 02:26:11','hghgh',333,'2011-10-11','Tddd','sss','1234.56',323453,4454,7845,'0011','2005-07-16 01:51:15+1359','2001-12-13 01:51:15','((1,2),(0,3),(2,1))','((2,3)(4,5))','08:00:2b:01:02:03','1-2','dfdf','((2,3)(4,5))','(6,7)',11.222,'((4,5),7)',32,3214,'(1,0,2,3)','2010-02-21',43564,'$1,000.00','192.168.1','126.1.3.4','12:30:45','ggg','1','0',12,23) ; 

--Alter table Drop Partition 
alter table co_cr_partrle_type32768_4 drop partition new_p;

-- Drop the default partition 
alter table co_cr_partrle_type32768_4 drop default partition;

--Alter table alter type of a column 
Alter table co_cr_partrle_type32768_4 Alter column a3 TYPE int4; 
--Insert data to the table, select count(*)
Insert into co_cr_partrle_type32768_4(a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,a31,a32,a33,a34,a35,a36,a37,a38,a39,a40,a41,a42) select a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,a31,a32,a33,a34,a35,a36,a37,a38,a39,a40,a41,a42 from co_cr_partrle_type32768_4 where id =10;
Select count(*) from co_cr_partrle_type32768_4; 

--Alter table drop a column 
Alter table co_cr_partrle_type32768_4 Drop column a12; 
Insert into co_cr_partrle_type32768_4(a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,a31,a32,a33,a34,a35,a36,a37,a38,a39,a40,a41,a42) select a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,a31,a32,a33,a34,a35,a36,a37,a38,a39,a40,a41,a42 from co_cr_partrle_type32768_4 where id =10;
Select count(*) from co_cr_partrle_type32768_4; 

--Alter table rename a column 
Alter table co_cr_partrle_type32768_4 Rename column a13 TO after_rename_a13; 
--Insert data to the table, select count(*)
Insert into co_cr_partrle_type32768_4(a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,after_rename_a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,a31,a32,a33,a34,a35,a36,a37,a38,a39,a40,a41,a42) select a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,after_rename_a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,a31,a32,a33,a34,a35,a36,a37,a38,a39,a40,a41,a42 from co_cr_partrle_type32768_4 where id =10;
Select count(*) from co_cr_partrle_type32768_4; 

--Alter table add a column 
Alter table co_cr_partrle_type32768_4 Add column a12 text default 'new column'; 
--Insert data to the table, select count(*)
Insert into co_cr_partrle_type32768_4(a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,after_rename_a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,a31,a32,a33,a34,a35,a36,a37,a38,a39,a40,a41,a42) select a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,after_rename_a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,a31,a32,a33,a34,a35,a36,a37,a38,a39,a40,a41,a42 from co_cr_partrle_type32768_4 where id =10;
Select count(*) from co_cr_partrle_type32768_4; 

--
-- Drop table if exists
--
DROP TABLE if exists co_cr_partrle_type32768_4_2 cascade;

DROP TABLE if exists co_cr_partrle_type32768_4_2_uncompr cascade;

--
-- Create table
--
CREATE TABLE co_cr_partrle_type32768_4_2 
	(id SERIAL,a1 int,a2 char(5),a3 numeric,a4 boolean DEFAULT false ,a5 char DEFAULT 'd',a6 text,a7 timestamp,a8 character varying(705),a9 bigint,a10 date,a11 varchar(600),a12 text,a13 decimal,a14 real,a15 bigint,a16 int4 ,a17 bytea,a18 timestamp with time zone,a19 timetz,a20 path,a21 box,a22 macaddr,a23 interval,a24 character varying(800),a25 lseg,a26 point,a27 double precision,a28 circle,a29 int4,a30 numeric(8),a31 polygon,a32 date,a33 real,a34 money,a35 cidr,a36 inet,a37 time,a38 text,a39 bit,a40 bit varying(5),a41 smallint,a42 int )  WITH (appendonly=true, orientation=column) distributed randomly 
Partition by list(a2) (partition p1 values ('M'), partition p2 values ('F')  ,
 COLUMN  a2 ENCODING (compresstype=rle_type,compresslevel=4,blocksize=32768),
 COLUMN a5 ENCODING (compresstype=quicklz,compresslevel=1, blocksize=32768), 
 DEFAULT COLUMN ENCODING (compresstype=rle_type,compresslevel=4,blocksize=32768));

-- 
-- Create Indexes
--
CREATE INDEX co_cr_partrle_type32768_4_2_idx_bitmap ON co_cr_partrle_type32768_4_2 USING bitmap (a1);

CREATE INDEX co_cr_partrle_type32768_4_2_idx_btree ON co_cr_partrle_type32768_4_2(a9);

--
-- Insert data to the table
--
COPY co_cr_partrle_type32768_4_2(a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,a31,a32,a33,a34,a35,a36,a37,a38,a39,a40,a41,a42)  FROM '/data/sivand/test/tincrepo/private/sivand/mpp/gpdb/tests/storage/aoco_compression/data/copy_base_small' DELIMITER AS '|' ;


--Create Uncompressed table of same schema definition

CREATE TABLE co_cr_partrle_type32768_4_2_uncompr(id SERIAL,a1 int,a2 char(5),a3 numeric,a4 boolean DEFAULT false ,a5 char DEFAULT 'd',a6 text,a7 timestamp,a8 character varying(705),a9 bigint,a10 date,a11 varchar(600),a12 text,a13 decimal,a14 real,a15 bigint,a16 int4 ,a17 bytea,a18 timestamp with time zone,a19 timetz,a20 path,a21 box,a22 macaddr,a23 interval,a24 character varying(800),a25 lseg,a26 point,a27 double precision,a28 circle,a29 int4,a30 numeric(8),a31 polygon,a32 date,a33 real,a34 money,a35 cidr,a36 inet,a37 time,a38 text,a39 bit,a40 bit varying(5),a41 smallint,a42 int) WITH (appendonly=true, orientation=column) distributed randomly Partition by list(a2) (default partition p1 , partition p2 values ('M') );

--
-- Insert to uncompressed table
--
COPY co_cr_partrle_type32768_4_2_uncompr(a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,a31,a32,a33,a34,a35,a36,a37,a38,a39,a40,a41,a42)  FROM '/data/sivand/test/tincrepo/private/sivand/mpp/gpdb/tests/storage/aoco_compression/data/copy_base_small' DELIMITER AS '|' ;

--
-- ********Validation******* 
--
\d+ co_cr_partrle_type32768_4_2_1_prt_p2

--
-- Compression ratio
--
 select 'compression_ratio' as compr_ratio ,get_ao_compression_ratio('co_cr_partrle_type32768_4_2_1_prt_p2'); 

--
-- Compare data with uncompressed table
--
--
-- Select number of rows from the uncompressed table 
--
SELECT count(*) as count_uncompressed from  co_cr_partrle_type32768_4_2_uncompr ;
--
-- Select number of rows from the compressed table 
--
SELECT count(*) as count_compressed from  co_cr_partrle_type32768_4_2;
--
-- Select number of rows using a FULL outer join on all the columns of the two tables 
-- Count should match with above result if the all the rows uncompressed correctly: 
--
Select count(*) as count_join from co_cr_partrle_type32768_4_2 t1 full outer join co_cr_partrle_type32768_4_2_uncompr t2 on t1.id=t2.id and t1.a1=t2.a1 and t1.a2=t2.a2 and t1.a3=t2.a3 and t1.a4=t2.a4 and t1.a5=t2.a5 and t1.a6=t2.a6 and t1.a7=t2.a7 and t1.a8=t2.a8 and t1.a9=t2.a9 and t1.a10=t2.a10 and t1.a11=t2.a11 and t1.a12=t2.a12 and t1.a13=t2.a13 and t1.a14=t2.a14 and t1.a15=t2.a15 and t1.a16=t2.a16 and t1.a17=t2.a17 and t1.a18=t2.a18 and t1.a19=t2.a19 and t1.a22=t2.a22 and t1.a23=t2.a23 and t1.a24=t2.a24 and t1.a27=t2.a27 and t1.a29=t2.a29 and t1.a30=t2.a30 and t1.a32=t2.a32 and t1.a33=t2.a33 and t1.a34=t2.a34 and t1.a35=t2.a35 and t1.a36=t2.a36 and t1.a37=t2.a37 and t1.a38=t2.a38 and t1.a39=t2.a39 and t1.a40=t2.a40 and t1.a41=t2.a41 and t1.a42=t2.a42 ;
--
-- Truncate the table 
--
TRUNCATE table co_cr_partrle_type32768_4_2;
--
-- Insert data again 
--
insert into co_cr_partrle_type32768_4_2 select * from co_cr_partrle_type32768_4_2_uncompr order by a1;

--
-- Compression ratio
--

--Alter table Add Partition 
alter table co_cr_partrle_type32768_4_2 add partition new_p values('C');

alter table co_cr_partrle_type32768_4_2 add default partition df_p;

-- Insert data 
Insert into co_cr_partrle_type32768_4_2(a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,a31,a32,a33,a34,a35,a36,a37,a38,a39,a40,a41,a42) values(generate_series(1,5000),'C',2011,'t','a','dfjjjjjj','2001-12-24 02:26:11','hghgh',333,'2011-10-11','Tddd','sss','1234.56',323453,4454,7845,'0011','2005-07-16 01:51:15+1359','2001-12-13 01:51:15','((1,2),(0,3),(2,1))','((2,3)(4,5))','08:00:2b:01:02:03','1-2','dfdf','((2,3)(4,5))','(6,7)',11.222,'((4,5),7)',32,3214,'(1,0,2,3)','2010-02-21',43564,'$1,000.00','192.168.1','126.1.3.4','12:30:45','ggg','1','0',12,23) ; 

Insert into co_cr_partrle_type32768_4_2(a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,a31,a32,a33,a34,a35,a36,a37,a38,a39,a40,a41,a42) values(generate_series(5061,6050),'F',2011,'t','a','dfjjjjjj','2001-12-24 02:26:11','hghgh',333,'2011-10-11','Tddd','sss','1234.56',323453,4454,7845,'0011','2005-07-16 01:51:15+1359','2001-12-13 01:51:15','((1,2),(0,3),(2,1))','((2,3)(4,5))','08:00:2b:01:02:03','1-2','dfdf','((2,3)(4,5))','(6,7)',11.222,'((4,5),7)',32,3214,'(1,0,2,3)','2010-02-21',43564,'$1,000.00','192.168.1','126.1.3.4','12:30:45','ggg','1','0',12,23) ; 

Insert into co_cr_partrle_type32768_4_2(a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,a31,a32,a33,a34,a35,a36,a37,a38,a39,a40,a41,a42) values(generate_series(5051,6050),'M',2011,'t','a','dfjjjjjj','2001-12-24 02:26:11','hghgh',333,'2011-10-11','Tddd','sss','1234.56',323453,4454,7845,'0011','2005-07-16 01:51:15+1359','2001-12-13 01:51:15','((1,2),(0,3),(2,1))','((2,3)(4,5))','08:00:2b:01:02:03','1-2','dfdf','((2,3)(4,5))','(6,7)',11.222,'((4,5),7)',32,3214,'(1,0,2,3)','2010-02-21',43564,'$1,000.00','192.168.1','126.1.3.4','12:30:45','ggg','1','0',12,23) ; 

--Alter table Drop Partition 
alter table co_cr_partrle_type32768_4_2 drop partition new_p;

-- Drop the default partition 
alter table co_cr_partrle_type32768_4_2 drop default partition;

--Alter table alter type of a column 
Alter table co_cr_partrle_type32768_4_2 Alter column a3 TYPE int4; 
--Insert data to the table, select count(*)
Insert into co_cr_partrle_type32768_4_2(a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,a31,a32,a33,a34,a35,a36,a37,a38,a39,a40,a41,a42) select a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,a31,a32,a33,a34,a35,a36,a37,a38,a39,a40,a41,a42 from co_cr_partrle_type32768_4_2 where id =10;
Select count(*) from co_cr_partrle_type32768_4_2; 

--Alter table drop a column 
Alter table co_cr_partrle_type32768_4_2 Drop column a12; 
Insert into co_cr_partrle_type32768_4_2(a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,a31,a32,a33,a34,a35,a36,a37,a38,a39,a40,a41,a42) select a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,a31,a32,a33,a34,a35,a36,a37,a38,a39,a40,a41,a42 from co_cr_partrle_type32768_4_2 where id =10;
Select count(*) from co_cr_partrle_type32768_4_2; 

--Alter table rename a column 
Alter table co_cr_partrle_type32768_4_2 Rename column a13 TO after_rename_a13; 
--Insert data to the table, select count(*)
Insert into co_cr_partrle_type32768_4_2(a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,after_rename_a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,a31,a32,a33,a34,a35,a36,a37,a38,a39,a40,a41,a42) select a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,after_rename_a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,a31,a32,a33,a34,a35,a36,a37,a38,a39,a40,a41,a42 from co_cr_partrle_type32768_4_2 where id =10;
Select count(*) from co_cr_partrle_type32768_4_2; 

--Alter table add a column 
Alter table co_cr_partrle_type32768_4_2 Add column a12 text default 'new column'; 
--Insert data to the table, select count(*)
Insert into co_cr_partrle_type32768_4_2(a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,after_rename_a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,a31,a32,a33,a34,a35,a36,a37,a38,a39,a40,a41,a42) select a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,after_rename_a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,a31,a32,a33,a34,a35,a36,a37,a38,a39,a40,a41,a42 from co_cr_partrle_type32768_4_2 where id =10;
Select count(*) from co_cr_partrle_type32768_4_2; 

