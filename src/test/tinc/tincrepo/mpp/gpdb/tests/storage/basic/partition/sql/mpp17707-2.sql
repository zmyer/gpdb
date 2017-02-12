--Create an AO table with partitions ( having diff storage parameters)
--start_ignore
 drop table if exists pt_ao_tab cascade;
--end_ignore
 Create table  pt_ao_tab(a int, b text, c int , d int, e numeric,success bool) with ( appendonly=true )
 distributed by (a)
 partition by list(b)
 (
          partition abc values ('abc','abc1','abc2') with (appendonly=false), -- HEAP
          partition def values ('def','def1','def3') with (appendonly=true, compresslevel=1), 
          partition ghi values ('ghi','ghi1','ghi2') with (appendonly=true), -- AO
          default partition dft
 );

--Create indexes on the table
 -- Partial index
--start_ignore
drop index if exists ao_idx1 cascade;
drop index if exists ao_idx2 cascade;
--end_ignore
 create index ao_idx1 on pt_ao_tab(a) where c > 10;

 -- Expression index
 create index ao_idx2 on pt_ao_tab(upper(b));

--Drop partition
 alter table pt_ao_tab drop default partition;

--Add partition
 alter table pt_ao_tab add partition xyz values ('xyz','xyz1','xyz2') WITH (appendonly=true,orientation=column,compresslevel=5); --CO

 alter table pt_ao_tab add partition jkl values ('jkl','jkl1','jkl2') WITH (appendonly=true); -- AO

 alter table pt_ao_tab add partition mno values ('mno','mno1','mno2') WITH (appendonly=false); --Heap

--Check properties of the added partition tables
 select oid::regclass, relkind, relstorage, reloptions from pg_class where oid in ( select  relfilenode from pg_class where   relname in  ( 'pt_ao_tab_1_prt_xyz', 'pt_ao_tab_1_prt_jkl','pt_ao_tab_1_prt_mno'));

--Insert Data
 insert into pt_ao_tab select 1, 'xyz', 1, 1, 1.0 , true from generate_series(1, 100);
 insert into pt_ao_tab select 1, 'abc', 1, 1, 1.0 , true from generate_series(1, 100);
 insert into pt_ao_tab select 1, 'def', 1, 1, 1.0 , true from generate_series(1, 100);
 insert into pt_ao_tab select 1, 'ghi', 1, 1, 1.0 , true from generate_series(1, 100);
 insert into pt_ao_tab select 1, 'jkl', 1, 1, 1.0 , true from generate_series(1, 100);
 insert into pt_ao_tab select 1, 'mno', 1, 1, 1.0 , true from generate_series(1, 100);

--Split partition [Creates new partitions to be of the same type as the parent partition. All heap partitions created]
 alter table pt_ao_tab split partition abc at ('abc1') into ( partition abc1,partition abc2); -- Heap
 alter table pt_ao_tab split partition ghi at ('ghi1') into ( partition ghi1,partition ghi2); --AO
 alter table pt_ao_tab split partition xyz at ('xyz1') into ( partition xyz1,partition xyz2); --CO

--Check the storage type and properties of the split partition
  select oid::regclass, relkind, relstorage, reloptions from pg_class where oid in (select relfilenode from pg_class where relname in ('pt_ao_tab_1_prt_xyz1','pt_ao_tab_1_prt_xyz2','pt_ao_tab_1_prt_ghi1','pt_ao_tab_1_prt_ghi2','pt_ao_tab_1_prt_abc1','pt_ao_tab_1_prt_abc2'));         
--Exchange partition
 -- Create candidate table
--start_ignore
drop table if exists heap_can cascade;
drop table if exists ao_can cascade;
drop table if exists co_can cascade;
--end_ignore

 create table heap_can(like pt_ao_tab);  
 create table ao_can(like pt_ao_tab) with (appendonly=true);   
 create table co_can(like pt_ao_tab)  with (appendonly=true,orientation=column);   

 -- Exchange
 alter table pt_ao_tab add partition pqr values ('pqr','pqr1','pqr2') WITH (appendonly=true,orientation=column,compresslevel=5);-- CO
 alter table pt_ao_tab add partition stu values ('stu','stu1','stu2') WITH (appendonly=false);-- heap
 alter table pt_ao_tab exchange partition for ('stu') with table ao_can ;-- Heap tab exchanged with  AO
 alter table pt_ao_tab exchange partition for ('def') with table co_can; --AO tab exchanged with CO
 alter table pt_ao_tab exchange partition for ('pqr') with table heap_can; --CO tab exchanged with Heap

--Check for the storage properties and indexes of the two tables involved in the exchange
 \d+ heap_can
 \d+ co_can
 \d+ ao_can

--Further operations
 alter table pt_ao_tab drop partition jkl;
 truncate table pt_ao_tab;

--Further create some more indexes
--start_ignore
drop index if exists ao_idx4 cascade;
drop index if exists ao_idx3 cascade;
--end_ignore
 create index ao_idx3 on pt_ao_tab(c,d) where a = 40 OR a = 50; -- multicol indx
 CREATE INDEX ao_idx4 ON pt_ao_tab ((b || ' ' || e)); --Expression

--Add default partition
 alter table pt_ao_tab add default partition dft;

--Split default partition
 alter table pt_ao_tab split default partition at ('uvw') into (partition dft, partition uvw);
