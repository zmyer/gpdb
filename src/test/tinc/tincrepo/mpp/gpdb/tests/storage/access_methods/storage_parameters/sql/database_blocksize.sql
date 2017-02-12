-- 
-- @description Guc setting at database level for blocksize (default blocksize is 32k)


-- Guc value blocksize= 64k
Alter database dsp_db1 set gp_default_storage_options="appendonly=true, blocksize=65536";

Select datconfig from pg_database where datname='dsp_db1';

\c dsp_db1

show gp_default_storage_options;

-- Table with no options
Drop table if exists ao_db_bk_t1;
Create table ao_db_bk_t1 ( i int, j int);

Create index ap_t1_ix on ao_db_bk_t1(i);

Insert into ao_db_bk_t1 select i, i+1 from generate_series(1,10) i;

update ao_db_bk_t1 set j=i where i>5;

Delete from ao_db_bk_t1 where i<2;

Select count(*) from ao_db_bk_t1;

\d+ ao_db_bk_t1;

select relstorage, reloptions from pg_class where relname='ao_db_bk_t1';
select compresslevel, compresstype, blocksize, checksum, columnstore from pg_appendonly where relid = (select oid from pg_class where relname='ao_db_bk_t1');

Drop table ao_db_bk_t1;



-- Create table with blocksize=8k

Drop table if exists ao_db_bk_t2;
Create table ao_db_bk_t2 ( i int, j int) with(blocksize=8192);

Insert into ao_db_bk_t2 select i, i+1 from generate_series(1,10) i;
Select count(*) from ao_db_bk_t2;

\d+ ao_db_bk_t2;

select relstorage, reloptions from pg_class where relname='ao_db_bk_t2';
select compresslevel, compresstype, blocksize, checksum, columnstore from pg_appendonly where relid = (select oid from pg_class where relname='ao_db_bk_t2');

Drop table ao_db_bk_t2;



-- Create table with blocksize=64k

Drop table if exists ao_db_bk_t3;
Create table ao_db_bk_t3 ( i int, j int) with(blocksize=65536);

Insert into ao_db_bk_t3 select i, i+1 from generate_series(1,10) i;
Select count(*) from ao_db_bk_t3;

\d+ ao_db_bk_t3;

select relstorage, reloptions from pg_class where relname='ao_db_bk_t3';
select compresslevel, compresstype, blocksize, checksum, columnstore from pg_appendonly where relid = (select oid from pg_class where relname='ao_db_bk_t3');

Drop table ao_db_bk_t3;



-- Create table with invalid value for blocksize (only multiples of 8k are valid values)

Drop table if exists ao_db_bk_t4;
Create table ao_db_bk_t4 ( i int, j int) with(blocksize=3456);


-- Create table with other storage parameters , orientation, checksum, compresstype, compresslevel
Drop table if exists ao_db_bk_t5;
Create table ao_db_bk_t5 ( i int, j int) with(orientation=column, compresstype=zlib, compresslevel=1, checksum=true);

Insert into ao_db_bk_t5 select i, i+1 from generate_series(1,10) i;
Select count(*) from ao_db_bk_t5;

\d+ ao_db_bk_t5

select relstorage, reloptions from pg_class where relname='ao_db_bk_t5';
select compresslevel, compresstype, blocksize, checksum, columnstore from pg_appendonly where relid = (select oid from pg_class where relname='ao_db_bk_t5');

Drop table ao_db_bk_t5;


-- ========================================
-- Set the database level guc to the default value


Alter database dsp_db2 set gp_default_storage_options="appendonly=true,blocksize=32768";

Select datconfig from pg_database where datname='dsp_db2';

\c dsp_db2

show gp_default_storage_options;


-- Create table with no options
Drop table if exists ao_db_bk_t1;
Create table ao_db_bk_t1 ( i int, j int);

Insert into ao_db_bk_t1 select i, i+1 from generate_series(1,10) i;

Select count(*) from ao_db_bk_t1;

\d+ ao_db_bk_t1;

select relkind, relstorage, reloptions from pg_class where relname='ao_db_bk_t1';

Drop table ao_db_bk_t1;



-- Create table with blocksize=1G

Drop table if exists ao_db_bk_t2;
Create table ao_db_bk_t2 ( i int, j int) with(blocksize=1048576);

Insert into ao_db_bk_t2 select i, i+1 from generate_series(1,10) i;
Select count(*) from ao_db_bk_t2;

\d+ ao_db_bk_t2;

select relstorage, reloptions from pg_class where relname='ao_db_bk_t2';
select compresslevel, compresstype, blocksize, checksum, columnstore from pg_appendonly where relid = (select oid from pg_class where relname='ao_db_bk_t2');

Drop table ao_db_bk_t2;



-- Create table with appendonly=false

Drop table if exists ao_db_bk_t3;
Create table ao_db_bk_t3 ( i int, j int) with(appendonly=false);

Insert into ao_db_bk_t3 select i, i+1 from generate_series(1,10) i;
Select count(*) from ao_db_bk_t3;

\d+ ao_db_bk_t3;

select relkind, relstorage, reloptions from pg_class where relname='ao_db_bk_t3';

Drop table ao_db_bk_t3;


--- =====================================
-- GUC with invalid value, value without appendonly=true
Alter database dsp_db3 set gp_default_storage_options="appendonly=true,blocksize=9123";

-- Guc with no appendonly=true specified
Alter database dsp_db4 set gp_default_storage_options="blocksize=8192";

\c dsp_db4
show gp_default_storage_options;

-- With no option it will a heap table
Drop table if exists ao_db_bk_t1;
Create table ao_db_bk_t1( i int, j int);

Insert into ao_db_bk_t1 select i, i+1 from generate_series(1,10) i;
Select count(*) from ao_db_bk_t1;

\d+ ao_db_bk_t1;

select relkind, relstorage,reloptions from pg_class where relname='ao_db_bk_t1';

Drop table ao_db_bk_t1;
-- with appendonly=true specified the table will be created as AO table with blocksize

Drop table if exists ao_db_bk_t2;
Create table ao_db_bk_t2( i int, j int) with(appendonly=true);
Insert into ao_db_bk_t2 select i, i+1 from generate_series(1,10) i;
Select count(*) from ao_db_bk_t2;

\d+ ao_db_bk_t2;

select relstorage, reloptions from pg_class where relname='ao_db_bk_t2';
select compresslevel, compresstype, blocksize, checksum, columnstore from pg_appendonly where relid = (select oid from pg_class where relname='ao_db_bk_t2');

Drop table ao_db_bk_t2;


-- Reset guc to default value for all three databases

Alter database dsp_db1 set gp_default_storage_options TO DEFAULT;
Alter database dsp_db2 set gp_default_storage_options TO DEFAULT;
Alter database dsp_db3 set gp_default_storage_options TO DEFAULT;
Alter database dsp_db4 set gp_default_storage_options TO DEFAULT;

select datname, datconfig from pg_database where datname in ('dsp_db1', 'dsp_db2', 'dsp_db3', 'dsp_db4') order by datname;

