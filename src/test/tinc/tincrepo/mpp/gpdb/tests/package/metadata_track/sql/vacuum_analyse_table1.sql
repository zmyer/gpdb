CREATE TABLE mdt_all_types ( a int,col001 char DEFAULT 'z',col002 numeric,col003 boolean DEFAULT false,col004 bit(3) DEFAULT '111',col005 text DEFAULT 'pookie', col006 integer[] DEFAULT '{5, 4, 3, 2, 1}', col007 character varying(512) DEFAULT 'Now is the time', col008 character varying DEFAULT 'Now is the time', col009 character varying(512)[], col010 numeric(8),col011 int,col012 double precision, col013 bigint, col014 char(8), col015 bytea,col016 timestamp with time zone,col017 interval, col018 cidr, col019 inet, col020 macaddr,col021 serial, col022 money, col023 bigserial, col024 timetz,col025 circle, col026 box, col027 name,col028 path, col029 int2, col031 bit varying(256),col032 date, col034 lseg,col035 point,col036 polygon,col037 real,col039 time, col040 timestamp )with (appendonly=true);

INSERT INTO mdt_all_types VALUES (1,'a',11,true,'111', '1_one', '{1,2,3,4,5}', 'Hello .. how are you 1', 'Hello .. how are you 1',    '{one,two,three,four,five}',  12345678, 1, 111.1111,  11,  '1_one_11',   'd',  '2001-12-13 01:51:15+1359',  '11',   '0.0.0.0', '0.0.0.0', 'AA:AA:AA:AA:AA:AA', 1,  '34.23',   1,'00:00:00+1359',  '((2,2),1)',   '((1,2),(2,1))',   'hello', '((1,2),(2,1))', 11,   '010101',   '2001-12-13', '((1,1),(2,2))', '(1,1)', '((1,2),(2,3),(3,4),(4,3),(3,2),(2,1))',    111111, '23:00:00',   '2001-12-13 01:51:15');

INSERT INTO mdt_all_types VALUES (    2,   'b',   22,  false, '001',   '2_one',  '{6,7,8,9,10}',  'Hey.. whtz up 2', 'Hey .. whtz up 2',    '{one,two,three,four,five}', 76767669, 1, 222.2222, 11,   '2_two_22',   'c',   '2002-12-13 01:51:15+1359',   '22',    '0.0.0.0',  '0.0.0.0',  'BB:BB:BB:BB:BB:BB',2, '200.00',   2, '00:00:05', '((3,3),2)',  '((3,2),(2,3))',   'hello',  '((3,2),(2,3))', 22,    '01010100101',  '2002-12-13', '((2,2),(3,3))', '(2,2)', '((1,2),(2,3),(3,4),(4,3),(3,2),(2,1))', 11111,  '22:00:00', '2002-12-13 01:51:15');

VACUUM ANALYSE  mdt_all_types ;

create schema myschema;
create schema myschema_new;
create schema myschema_diff;

CREATE TABLE myschema.mdt_supplier_hybrid_part(
                S_SUPPKEY INTEGER,
                S_NAME CHAR(25),
                S_ADDRESS VARCHAR(40),
                S_NATIONKEY INTEGER,
                S_PHONE CHAR(15),
                S_ACCTBAL decimal,
                S_COMMENT VARCHAR(101)
                )
partition by range (s_suppkey)
subpartition by list (s_nationkey) subpartition template (
        values('22','21','17'),
        values('6','11','1','7','16','2') WITH (orientation='column', appendonly=true),
        values('18','20') WITH (checksum=false, appendonly=true,blocksize=1171456, compresslevel=3),
        values('9','23','13') WITH (checksum=true,appendonly=true,blocksize=1335296,compresslevel=7),
        values('0','3','12','15','14','8','4','24','19','10','5')
)
(
partition p1 start('1') end('10001') every(10000)

);

Vacuum analyse myschema.mdt_supplier_hybrid_part;
ALTER TABLE myschema.mdt_supplier_hybrid_part SET SCHEMA myschema_new;
Vacuum myschema_new.mdt_supplier_hybrid_part;
ALTER TABLE myschema.mdt_supplier_hybrid_part_1_prt_p1 SET SCHEMA myschema_new;
ALTER TABLE myschema.mdt_supplier_hybrid_part_1_prt_p1_2_prt_1 SET SCHEMA myschema_diff;
Vacuum analyse myschema_diff.mdt_supplier_hybrid_part_1_prt_p1_2_prt_1;


drop table myschema_new.mdt_supplier_hybrid_part;
drop schema myschema;
drop schema myschema_new;
drop schema myschema_diff;
drop table mdt_all_types;
