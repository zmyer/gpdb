-- start_ignore
SET gp_create_table_random_default_distribution=off;
-- end_ignore
CREATE TABLE ck_sync1_heap_table1 ( phase text,a int,col001 char DEFAULT 'z',col002 numeric,col003 boolean DEFAULT false,col004 bit(3) DEFAULT '111',col005 text DEFAULT 'pookie', col006 integer[] DEFAULT '{5, 4, 3, 2, 1}', 
col007 character varying(512) DEFAULT 'Now is the time', col008 character varying DEFAULT 'Now is the time', col009 character varying(512)[], col010 numeric(8),col011 int,col012 double precision, col013 bigint, col014 char(8), 
col015 bytea,col016 timestamp with time zone,col017 interval, col018 cidr, col019 inet, col020 macaddr,col022 money, col024 timetz,col025 circle, col026 box, col027 name,col028 path, col029 int2, 
col031 bit varying(256),col032 date, col034 lseg,col035 point,col036 polygon,col037 real,col039 time, col040 timestamp );

INSERT INTO ck_sync1_heap_table1 VALUES ('ck_sync1_heap1',1,'a',11,true,'111', '1_one', '{1,2,3,4,5}', 'Hello .. how are you 1', 'Hello .. how are you 1',    '{one,two,three,four,five}',  12345678, 1, 111.1111,  11,  '1_one_11',   'd',  
'2001-12-13 01:51:15+1359',  '11',   '0.0.0.0', '0.0.0.0', 'AA:AA:AA:AA:AA:AA',   '34.23',   '00:00:00+1359',  '((2,2),1)',   '((1,2),(2,1))',   'hello', '((1,2),(2,1))', 11,   '010101',   '2001-12-13', '((1,1),(2,2))', '(1,1)', '((1,2),(2,3),(3,4),(4,3),(3,2),(2,1))',    111111, '23:00:00',   '2001-12-13 01:51:15');

CREATE TABLE ck_sync1_heap_table2 ( phase text,a int,col001 char DEFAULT 'z',col002 numeric,col003 boolean DEFAULT false,col004 bit(3) DEFAULT '111',col005 text DEFAULT 'pookie', col006 integer[] DEFAULT '{5, 4, 3, 2, 1}', 
col007 character varying(512) DEFAULT 'Now is the time', col008 character varying DEFAULT 'Now is the time', col009 character varying(512)[], col010 numeric(8),col011 int,col012 double precision, col013 bigint, 
col014 char(8), col015 bytea,col016 timestamp with time zone,col017 interval, col018 cidr, col019 inet, col020 macaddr,col022 money, col024 timetz,col025 circle, col026 box, col027 name,col028 path,
 col029 int2, col031 bit varying(256),col032 date, col034 lseg,col035 point,col036 polygon,col037 real,col039 time, col040 timestamp );

INSERT INTO ck_sync1_heap_table2 VALUES ('ck_sync1_heap2',1,'a',11,true,'111', '1_one', '{1,2,3,4,5}', 'Hello .. how are you 1', 'Hello .. how are you 1',    '{one,two,three,four,five}',  12345678, 1, 111.1111,  11,  '1_one_11',   'd', 
 '2001-12-13 01:51:15+1359',  '11',   '0.0.0.0', '0.0.0.0', 'AA:AA:AA:AA:AA:AA',   '34.23',   '00:00:00+1359',  '((2,2),1)',   '((1,2),(2,1))',   'hello', '((1,2),(2,1))', 11,   '010101',   '2001-12-13', '((1,1),(2,2))', '(1,1)', 
'((1,2),(2,3),(3,4),(4,3),(3,2),(2,1))',    111111, '23:00:00',   '2001-12-13 01:51:15');

CREATE TABLE ck_sync1_heap_table3 ( phase text,a int,col001 char DEFAULT 'z',col002 numeric,col003 boolean DEFAULT false,col004 bit(3) DEFAULT '111',col005 text DEFAULT 'pookie', col006 integer[] DEFAULT '{5, 4, 3, 2, 1}', col007 character varying(512) DEFAULT 'Now is the time', col008 character varying DEFAULT 'Now is the time', col009 character varying(512)[], col010 numeric(8),col011 int,col012 double precision, col013 bigint, col014 char(8), 
col015 bytea,col016 timestamp with time zone,col017 interval, col018 cidr, col019 inet, col020 macaddr,col022 money, col024 timetz,col025 circle, col026 box, col027 name,col028 path,
 col029 int2, col031 bit varying(256),col032 date, col034 lseg,col035 point,col036 polygon,col037 real,col039 time, col040 timestamp );

INSERT INTO ck_sync1_heap_table3 VALUES ('ck_sync1_heap3',1,'a',11,true,'111', '1_one', '{1,2,3,4,5}', 'Hello .. how are you 1', 'Hello .. how are you 1',    '{one,two,three,four,five}',  12345678, 1, 111.1111,  11,  '1_one_11',   'd',  
'2001-12-13 01:51:15+1359',  '11',   '0.0.0.0', '0.0.0.0', 'AA:AA:AA:AA:AA:AA',   '34.23',   '00:00:00+1359',  '((2,2),1)',   '((1,2),(2,1))',   'hello', '((1,2),(2,1))', 11,   '010101',   '2001-12-13', '((1,1),(2,2))', '(1,1)', '((1,2),(2,3),(3,4),(4,3),(3,2),(2,1))',    111111, '23:00:00',   '2001-12-13 01:51:15');

CREATE TABLE ck_sync1_heap_table4 ( phase text,a int,col001 char DEFAULT 'z',col002 numeric,col003 boolean DEFAULT false,col004 bit(3) DEFAULT '111',col005 text DEFAULT 'pookie', col006 integer[] DEFAULT '{5, 4, 3, 2, 1}', 
col007 character varying(512) DEFAULT 'Now is the time', col008 character varying DEFAULT 'Now is the time', col009 character varying(512)[], col010 numeric(8),col011 int,col012 double precision, col013 bigint,
col014 char(8), col015 bytea,col016 timestamp with time zone,col017 interval, col018 cidr, col019 inet, col020 macaddr,col022 money, col024 timetz,col025 circle, col026 box, col027 name,col028 path,
 col029 int2, col031 bit varying(256),col032 date, col034 lseg,col035 point,col036 polygon,col037 real,col039 time, col040 timestamp );

INSERT INTO ck_sync1_heap_table4 VALUES ('ck_sync1_heap4',1,'a',11,true,'111', '1_one', '{1,2,3,4,5}', 'Hello .. how are you 1', 'Hello .. how are you 1',    '{one,two,three,four,five}',  12345678, 1, 111.1111,  11,  '1_one_11',   'd',  '2001-12-13 01:51:15+1359',  '11',   '0.0.0.0', '0.0.0.0', 'AA:AA:AA:AA:AA:AA',   '34.23',   '00:00:00+1359',  '((2,2),1)',   '((1,2),(2,1))',   'hello', '((1,2),(2,1))', 11,   '010101',   '2001-12-13', '((1,1),(2,2))', '(1,1)', '((1,2),(2,3),(3,4),(4,3),(3,2),(2,1))',  
  111111, '23:00:00',   '2001-12-13 01:51:15');

CREATE TABLE ck_sync1_heap_table5 ( phase text,a int,col001 char DEFAULT 'z',col002 numeric,col003 boolean DEFAULT false,col004 bit(3) DEFAULT '111',col005 text DEFAULT 'pookie', col006 integer[] DEFAULT '{5, 4, 3, 2, 1}', 
col007 character varying(512) DEFAULT 'Now is the time', col008 character varying DEFAULT 'Nowis the time', col009 character varying(512)[], col010 numeric(8),col011 int,col012 double precision, col013 bigint, col014 char(8), 
col015 bytea,col016 timestamp with time zone,col017 interval, col018 cidr, col019 inet, col020 macaddr,col022 money, col024 timetz,col025 circle, col026 box, col027 name,col028 path, col029 int2, 
col031 bit varying(256),col032 date, col034 lseg,col035 point,col036 polygon,col037 real,col039 time, col040 timestamp );

INSERT INTO ck_sync1_heap_table5 VALUES ('ck_sync1_heap5',1,'a',11,true,'111', '1_one', '{1,2,3,4,5}', 'Hello .. how are you 1', 'Hello .. how are you 1',    '{one,two,three,four,five}',  12345678, 1, 111.1111,  11,  '1_one_11',   'd',  '2001-12-13 01:51:15+1359',  '11',   '0.0.0.0', '0.0.0.0', 'AA:AA:AA:AA:AA:AA',   '34.23',   '00:00:00+1359',  '((2,2),1)',   '((1,2),(2,1))',   'hello', '((1,2),(2,1))', 11,   '010101',   '2001-12-13', '((1,1),(2,2))', '(1,1)', '((1,2),(2,3),(3,4),(4,3),(3,2),(2,1))',    111111, '23:00:00',   '2001-12-13 01:51:15');

CREATE TABLE ck_sync1_heap_table6 ( phase text,a int,col001 char DEFAULT 'z',col002 numeric,col003 boolean DEFAULT false,col004 bit(3) DEFAULT '111',col005 text DEFAULT
'pookie', col006 integer[] DEFAULT '{5, 4, 3, 2, 1}', col007 character varying(512) DEFAULT 'Now is the time', col008 character varying DEFAULT 'Now is the time', 
col009 character varying(512)[], col010 numeric(8),col011 int,col012 double precision, col013 bigint, col014 char(8),col015 bytea,col016 timestamp with time zone,col017 interval, 
col018 cidr, col019 inet, col020 macaddr,col022 money, col024 timetz,col025 circle, col026 box, col027 name,col028 path, col029 int2, col031 bit varying(256),col032 date,
 col034 lseg,col035 point,col036 polygon,col037 real,col039 time, col040 timestamp );

INSERT INTO ck_sync1_heap_table6 VALUES ('ck_sync1_heap6',1,'a',11,true,'111', '1_one', '{1,2,3,4,5}', 'Hello .. how are you 1', 'Hello .. how are you 1',    '{one,two,three,four,five}',  
12345678, 1, 111.1111,  11,  '1_one_11',   'd','2001-12-13 01:51:15+1359',  '11',   '0.0.0.0', '0.0.0.0', 'AA:AA:AA:AA:AA:AA',   '34.23',   '00:00:00+1359',  '((2,2),1)',   '((1,2),(2,1))',  
 'hello', '((1,2),(2,1))', 11,   '010101',   '2001-12-13', '((1,1),(2,2))', '(1,1)', '((1,2),(2,3),(3,4),(4,3),(3,2),(2,1))',    111111, '23:00:00',   '2001-12-13 01:51:15');



CREATE TABLE ck_sync1_heap_table7 ( phase text,a int,col001 char DEFAULT 'z',col002 numeric,col003 boolean DEFAULT false,col004 bit(3) DEFAULT '111',col005 text DEFAULT
'pookie', col006 integer[] DEFAULT '{5, 4, 3, 2, 1}',col007 character varying(512) DEFAULT 'Now is the time', col008 character varying DEFAULT 'Now is the time', 
col009 character varying(512)[], col010 numeric(8),col011 int,col012 double precision, col013 bigint,col014 char(8), col015 bytea,col016 timestamp with time zone,col017 interval, 
col018 cidr, col019 inet, col020 macaddr,col022 money, col024 timetz,col025 circle, col026 box, col027 name,col028 path, col029 int2, col031 bit varying(256),col032 date, col034 lseg,
col035 point,col036 polygon,col037 real,col039 time, col040 timestamp );


INSERT INTO ck_sync1_heap_table7 VALUES ('ck_sync1_heap7',1,'a',11,true,'111', '1_one', '{1,2,3,4,5}', 'Hello .. how are you 1', 'Hello .. how are you 1',    '{one,two,three,four,five}',
12345678, 1, 111.1111,  11,  '1_one_11',   'd','2001-12-13 01:51:15+1359',  '11',   '0.0.0.0', '0.0.0.0', 'AA:AA:AA:AA:AA:AA',   '34.23',   '00:00:00+1359',  '((2,2),1)',   '((1,2),(2,1))',
 'hello', '((1,2),(2,1))', 11,   '010101',   '2001-12-13', '((1,1),(2,2))', '(1,1)', '((1,2),(2,3),(3,4),(4,3),(3,2),(2,1))',    111111, '23:00:00',   '2001-12-13 01:51:15');


DROP TABLE sync1_heap_table2;
DROP TABLE ck_sync1_heap_table1;

-- AO CREATE DROP TABLE TEST IN CHECKPOINT SYNC 

CREATE TABLE ck_sync1_ao_table1 ( phase text,a int,col001 char DEFAULT 'z',col002 numeric,col003 boolean DEFAULT false,col004 bit(3) DEFAULT '111',col005 text DEFAULT 'pookie', 
col006 integer[] DEFAULT '{5, 4, 3, 2, 1}',col007 character varying(512) DEFAULT 'Now is the time', col008 character varying DEFAULT 'Now is the time', col009 character varying(512)[], 
col010 numeric(8),col011 int,col012 double precision, col013 bigint, col014 char(8), col015 bytea,col016 timestamp with time zone,col017 interval, col018 cidr, col019 inet, col020 macaddr,
col022 money, col024 timetz,col025 circle, col026 box, col027 name,col028 path, col029 int2, col031 bit varying(256),col032 date, col034 lseg,col035 point,col036 polygon,col037 real,col039 time, 
col040 timestamp ) with (appendonly=true);

INSERT INTO ck_sync1_ao_table1 VALUES ('ck_sync1_ao1',1,'a',11,true,'111', '1_one', '{1,2,3,4,5}', 'Hello .. how are you 1', 'Hello .. how are you 1',    '{one,two,three,four,five}',  12345678, 1, 111.1111,  11, 
 '1_one_11',   'd',  '2001-12-13 01:51:15+1359',  '11',   '0.0.0.0', '0.0.0.0', 'AA:AA:AA:AA:AA:AA',   '34.23',   '00:00:00+1359',  '((2,2),1)',   '((1,2),(2,1))',   'hello', '((1,2),(2,1))', 11,   '010101',   '2001-12-13', '((1,1),(2,2))', 
'(1,1)', '((1,2),(2,3),(3,4),(4,3),(3,2),(2,1))',    111111, '23:00:00',   '2001-12-13 01:51:15');


CREATE TABLE ck_sync1_ao_table2 ( phase text,a int,col001 char DEFAULT 'z',col002 numeric,col003 boolean DEFAULT false,col004 bit(3) DEFAULT '111',col005 text DEFAULT 'pookie', 
col006 integer[] DEFAULT '{5, 4, 3, 2, 1}',col007 character varying(512) DEFAULT 'Now is the time', col008 character varying DEFAULT 'Now is the time', col009 character varying(512)[], 
col010 numeric(8),col011 int,col012 double precision, col013 bigint, col014 char(8), col015 bytea,col016 timestamp with time zone,col017 interval, col018 cidr, col019 inet, col020 macaddr,
col022 money, col024 timetz,col025 circle, col026 box, col027 name,col028 path, col029 int2, col031 bit varying(256),col032 date, col034 lseg,col035 point,col036 polygon,col037 real,col039 time, 
col040 timestamp ) with (appendonly=true);

INSERT INTO ck_sync1_ao_table2 VALUES ('ck_sync1_ao2',1,'a',11,true,'111', '1_one', '{1,2,3,4,5}', 'Hello .. how are you 1', 'Hello .. how are you 1',    '{one,two,three,four,five}',  12345678, 1, 111.1111,  11, 
 '1_one_11',   'd',  '2001-12-13 01:51:15+1359',  '11',   '0.0.0.0', '0.0.0.0', 'AA:AA:AA:AA:AA:AA',   '34.23',   '00:00:00+1359',  '((2,2),1)',   '((1,2),(2,1))',   'hello', '((1,2),(2,1))', 11,   '010101',   '2001-12-13', '((1,1),(2,2))', 
'(1,1)', '((1,2),(2,3),(3,4),(4,3),(3,2),(2,1))',    111111, '23:00:00',   '2001-12-13 01:51:15');

CREATE TABLE ck_sync1_ao_table3 ( phase text,a int,col001 char DEFAULT 'z',col002 numeric,col003 boolean DEFAULT false,col004 bit(3) DEFAULT '111',col005 text DEFAULT 'pookie', 
col006 integer[] DEFAULT '{5, 4, 3, 2, 1}',col007 character varying(512) DEFAULT 'Now is the time', col008 character varying DEFAULT 'Now is the time', col009 character varying(512)[], 
col010 numeric(8),col011 int,col012 double precision, col013 bigint, col014 char(8), col015 bytea,col016 timestamp with time zone,col017 interval, col018 cidr, col019 inet, col020 macaddr,
col022 money, col024 timetz,col025 circle, col026 box, col027 name,col028 path, col029 int2, col031 bit varying(256),col032 date, col034 lseg,col035 point,col036 polygon,col037 real,col039 time, 
col040 timestamp ) with (appendonly=true);

INSERT INTO ck_sync1_ao_table3 VALUES ('ck_sync1_ao3',1,'a',11,true,'111', '1_one', '{1,2,3,4,5}', 'Hello .. how are you 1', 'Hello .. how are you 1',    '{one,two,three,four,five}',  12345678, 1, 111.1111,  11, 
 '1_one_11',   'd',  '2001-12-13 01:51:15+1359',  '11',   '0.0.0.0', '0.0.0.0', 'AA:AA:AA:AA:AA:AA',   '34.23',   '00:00:00+1359',  '((2,2),1)',   '((1,2),(2,1))',   'hello', '((1,2),(2,1))', 11,   '010101',   '2001-12-13', '((1,1),(2,2))', 
'(1,1)', '((1,2),(2,3),(3,4),(4,3),(3,2),(2,1))',    111111, '23:00:00',   '2001-12-13 01:51:15');


CREATE TABLE ck_sync1_ao_table4 ( phase text,a int,col001 char DEFAULT 'z',col002 numeric,col003 boolean DEFAULT false,col004 bit(3) DEFAULT '111',col005 text DEFAULT 'pookie', 
col006 integer[] DEFAULT '{5, 4, 3, 2, 1}',col007 character varying(512) DEFAULT 'Now is the time', col008 character varying DEFAULT 'Now is the time', col009 character varying(512)[], 
col010 numeric(8),col011 int,col012 double precision, col013 bigint, col014 char(8), col015 bytea,col016 timestamp with time zone,col017 interval, col018 cidr, col019 inet, col020 macaddr,
col022 money, col024 timetz,col025 circle, col026 box, col027 name,col028 path, col029 int2, col031 bit varying(256),col032 date, col034 lseg,col035 point,col036 polygon,col037 real,col039 time, 
col040 timestamp ) with (appendonly=true);

INSERT INTO ck_sync1_ao_table4 VALUES ('ck_sync1_ao4',1,'a',11,true,'111', '1_one', '{1,2,3,4,5}', 'Hello .. how are you 1', 'Hello .. how are you 1',    '{one,two,three,four,five}',  12345678, 1, 111.1111,  11, 
 '1_one_11',   'd',  '2001-12-13 01:51:15+1359',  '11',   '0.0.0.0', '0.0.0.0', 'AA:AA:AA:AA:AA:AA',   '34.23',   '00:00:00+1359',  '((2,2),1)',   '((1,2),(2,1))',   'hello', '((1,2),(2,1))', 11,   '010101',   '2001-12-13', '((1,1),(2,2))', 
'(1,1)', '((1,2),(2,3),(3,4),(4,3),(3,2),(2,1))',    111111, '23:00:00',   '2001-12-13 01:51:15');


CREATE TABLE ck_sync1_ao_table5 ( phase text,a int,col001 char DEFAULT 'z',col002 numeric,col003 boolean DEFAULT false,col004 bit(3) DEFAULT '111',col005 text DEFAULT 'pookie', 
col006 integer[] DEFAULT '{5, 4, 3, 2, 1}',col007 character varying(512) DEFAULT 'Now is the time', col008 character varying DEFAULT 'Now is the time', col009 character varying(512)[], 
col010 numeric(8),col011 int,col012 double precision, col013 bigint, col014 char(8), col015 bytea,col016 timestamp with time zone,col017 interval, col018 cidr, col019 inet, col020 macaddr,
col022 money, col024 timetz,col025 circle, col026 box, col027 name,col028 path, col029 int2, col031 bit varying(256),col032 date, col034 lseg,col035 point,col036 polygon,col037 real,col039 time, 
col040 timestamp ) with (appendonly=true);

INSERT INTO ck_sync1_ao_table5 VALUES ('ck_sync1_ao5',1,'a',11,true,'111', '1_one', '{1,2,3,4,5}', 'Hello .. how are you 1', 'Hello .. how are you 1',    '{one,two,three,four,five}',  12345678, 1, 111.1111,  11, 
 '1_one_11',   'd',  '2001-12-13 01:51:15+1359',  '11',   '0.0.0.0', '0.0.0.0', 'AA:AA:AA:AA:AA:AA',   '34.23',   '00:00:00+1359',  '((2,2),1)',   '((1,2),(2,1))',   'hello', '((1,2),(2,1))', 11,   '010101',   '2001-12-13', '((1,1),(2,2))', 
'(1,1)', '((1,2),(2,3),(3,4),(4,3),(3,2),(2,1))',    111111, '23:00:00',   '2001-12-13 01:51:15');


CREATE TABLE ck_sync1_ao_table6 ( phase text,a int,col001 char DEFAULT 'z',col002 numeric,col003 boolean DEFAULT false,col004 bit(3) DEFAULT '111',col005 text DEFAULT 'pookie', 
col006 integer[] DEFAULT '{5, 4, 3, 2, 1}',col007 character varying(512) DEFAULT 'Now is the time', col008 character varying DEFAULT 'Now is the time', col009 character varying(512)[], 
col010 numeric(8),col011 int,col012 double precision, col013 bigint, col014 char(8), col015 bytea,col016 timestamp with time zone,col017 interval, col018 cidr, col019 inet, col020 macaddr,
col022 money, col024 timetz,col025 circle, col026 box, col027 name,col028 path, col029 int2, col031 bit varying(256),col032 date, col034 lseg,col035 point,col036 polygon,col037 real,col039 time, 
col040 timestamp ) with (appendonly=true);

INSERT INTO ck_sync1_ao_table6 VALUES ('ck_sync1_ao6',1,'a',11,true,'111', '1_one', '{1,2,3,4,5}', 'Hello .. how are you 1', 'Hello .. how are you 1',    '{one,two,three,four,five}',  12345678, 1, 111.1111,  11, 
 '1_one_11',   'd',  '2001-12-13 01:51:15+1359',  '11',   '0.0.0.0', '0.0.0.0', 'AA:AA:AA:AA:AA:AA',   '34.23',   '00:00:00+1359',  '((2,2),1)',   '((1,2),(2,1))',   'hello', '((1,2),(2,1))', 11,   '010101',   '2001-12-13', '((1,1),(2,2))', 
'(1,1)', '((1,2),(2,3),(3,4),(4,3),(3,2),(2,1))',    111111, '23:00:00',   '2001-12-13 01:51:15');


CREATE TABLE ck_sync1_ao_table7 ( phase text,a int,col001 char DEFAULT 'z',col002 numeric,col003 boolean DEFAULT false,col004 bit(3) DEFAULT '111',col005 text DEFAULT 'pookie', 
col006 integer[] DEFAULT '{5, 4, 3, 2, 1}',col007 character varying(512) DEFAULT 'Now is the time', col008 character varying DEFAULT 'Now is the time', col009 character varying(512)[], 
col010 numeric(8),col011 int,col012 double precision, col013 bigint, col014 char(8), col015 bytea,col016 timestamp with time zone,col017 interval, col018 cidr, col019 inet, col020 macaddr,
col022 money, col024 timetz,col025 circle, col026 box, col027 name,col028 path, col029 int2, col031 bit varying(256),col032 date, col034 lseg,col035 point,col036 polygon,col037 real,col039 time, 
col040 timestamp ) with (appendonly=true);

INSERT INTO ck_sync1_ao_table7 VALUES ('ck_sync1_ao7',1,'a',11,true,'111', '1_one', '{1,2,3,4,5}', 'Hello .. how are you 1', 'Hello .. how are you 1',    '{one,two,three,four,five}',  12345678, 1, 111.1111,  11, 
 '1_one_11',   'd',  '2001-12-13 01:51:15+1359',  '11',   '0.0.0.0', '0.0.0.0', 'AA:AA:AA:AA:AA:AA',   '34.23',   '00:00:00+1359',  '((2,2),1)',   '((1,2),(2,1))',   'hello', '((1,2),(2,1))', 11,   '010101',   '2001-12-13', '((1,1),(2,2))', 
'(1,1)', '((1,2),(2,3),(3,4),(4,3),(3,2),(2,1))',    111111, '23:00:00',   '2001-12-13 01:51:15');




DROP TABLE sync1_ao_table2;
DROP TABLE ck_sync1_ao_table1;



-- CO CREATE DROP TABLE TEST IN CHECKPOINT  SYNC

CREATE TABLE ck_sync1_co_table1 ( phase text,a int,col001 char DEFAULT 'z',col002 numeric,col003 boolean DEFAULT false,col004 bit(3) DEFAULT '111',col005 text DEFAULT 'pookie', 
col006 integer[] DEFAULT '{5, 4, 3, 2, 1}',col007 character varying(512) DEFAULT 'Now is the time', col008 character varying DEFAULT 'Now is the time', col009 character varying(512)[], 
col010 numeric(8),col011 int,col012 double precision, col013 bigint, col014 char(8), col015 bytea,col016 timestamp with time zone,col017 interval, col018 cidr, col019 inet, col020 macaddr,
col022 money, col024 timetz,col025 circle, col026 box, col027 name,col028 path, col029 int2, col031 bit varying(256),col032 date, col034 lseg,col035 point,col036 polygon,col037 real,col039 time, 
col040 timestamp ) with (orientation='column',appendonly=true);

INSERT INTO ck_sync1_co_table1 VALUES ('ck_sync1_co1',1,'a',11,true,'111', '1_one', '{1,2,3,4,5}', 'Hello .. how are you 1', 'Hello .. how are you 1',    '{one,two,three,four,five}',  12345678, 1, 111.1111,  11, 
 '1_one_11',   'd',  '2001-12-13 01:51:15+1359',  '11',   '0.0.0.0', '0.0.0.0', 'AA:AA:AA:AA:AA:AA',   '34.23',   '00:00:00+1359',  '((2,2),1)',   '((1,2),(2,1))',   'hello', '((1,2),(2,1))', 11,   '010101',   '2001-12-13', '((1,1),(2,2))', 
'(1,1)', '((1,2),(2,3),(3,4),(4,3),(3,2),(2,1))',    111111, '23:00:00',   '2001-12-13 01:51:15');


CREATE TABLE ck_sync1_co_table2 ( phase text,a int,col001 char DEFAULT 'z',col002 numeric,col003 boolean DEFAULT false,col004 bit(3) DEFAULT '111',col005 text DEFAULT 'pookie', 
col006 integer[] DEFAULT '{5, 4, 3, 2, 1}',col007 character varying(512) DEFAULT 'Now is the time', col008 character varying DEFAULT 'Now is the time', col009 character varying(512)[], 
col010 numeric(8),col011 int,col012 double precision, col013 bigint, col014 char(8), col015 bytea,col016 timestamp with time zone,col017 interval, col018 cidr, col019 inet, col020 macaddr,
col022 money, col024 timetz,col025 circle, col026 box, col027 name,col028 path, col029 int2, col031 bit varying(256),col032 date, col034 lseg,col035 point,col036 polygon,col037 real,col039 time, 
col040 timestamp ) with (orientation='column',appendonly=true);

INSERT INTO ck_sync1_co_table2 VALUES ('ck_sync1_co2',1,'a',11,true,'111', '1_one', '{1,2,3,4,5}', 'Hello .. how are you 1', 'Hello .. how are you 1',    '{one,two,three,four,five}',  12345678, 1, 111.1111,  11, 
 '1_one_11',   'd',  '2001-12-13 01:51:15+1359',  '11',   '0.0.0.0', '0.0.0.0', 'AA:AA:AA:AA:AA:AA',   '34.23',   '00:00:00+1359',  '((2,2),1)',   '((1,2),(2,1))',   'hello', '((1,2),(2,1))', 11,   '010101',   '2001-12-13', '((1,1),(2,2))', 
'(1,1)', '((1,2),(2,3),(3,4),(4,3),(3,2),(2,1))',    111111, '23:00:00',   '2001-12-13 01:51:15');

CREATE TABLE ck_sync1_co_table3 ( phase text,a int,col001 char DEFAULT 'z',col002 numeric,col003 boolean DEFAULT false,col004 bit(3) DEFAULT '111',col005 text DEFAULT 'pookie', 
col006 integer[] DEFAULT '{5, 4, 3, 2, 1}',col007 character varying(512) DEFAULT 'Now is the time', col008 character varying DEFAULT 'Now is the time', col009 character varying(512)[], 
col010 numeric(8),col011 int,col012 double precision, col013 bigint, col014 char(8), col015 bytea,col016 timestamp with time zone,col017 interval, col018 cidr, col019 inet, col020 macaddr,
col022 money, col024 timetz,col025 circle, col026 box, col027 name,col028 path, col029 int2, col031 bit varying(256),col032 date, col034 lseg,col035 point,col036 polygon,col037 real,col039 time, 
col040 timestamp ) with (orientation='column',appendonly=true);

INSERT INTO ck_sync1_co_table3 VALUES ('ck_sync1_co3',1,'a',11,true,'111', '1_one', '{1,2,3,4,5}', 'Hello .. how are you 1', 'Hello .. how are you 1',    '{one,two,three,four,five}',  12345678, 1, 111.1111,  11, 
 '1_one_11',   'd',  '2001-12-13 01:51:15+1359',  '11',   '0.0.0.0', '0.0.0.0', 'AA:AA:AA:AA:AA:AA',   '34.23',   '00:00:00+1359',  '((2,2),1)',   '((1,2),(2,1))',   'hello', '((1,2),(2,1))', 11,   '010101',   '2001-12-13', '((1,1),(2,2))', 
'(1,1)', '((1,2),(2,3),(3,4),(4,3),(3,2),(2,1))',    111111, '23:00:00',   '2001-12-13 01:51:15');


CREATE TABLE ck_sync1_co_table4 ( phase text,a int,col001 char DEFAULT 'z',col002 numeric,col003 boolean DEFAULT false,col004 bit(3) DEFAULT '111',col005 text DEFAULT 'pookie', 
col006 integer[] DEFAULT '{5, 4, 3, 2, 1}',col007 character varying(512) DEFAULT 'Now is the time', col008 character varying DEFAULT 'Now is the time', col009 character varying(512)[], 
col010 numeric(8),col011 int,col012 double precision, col013 bigint, col014 char(8), col015 bytea,col016 timestamp with time zone,col017 interval, col018 cidr, col019 inet, col020 macaddr,
col022 money, col024 timetz,col025 circle, col026 box, col027 name,col028 path, col029 int2, col031 bit varying(256),col032 date, col034 lseg,col035 point,col036 polygon,col037 real,col039 time, 
col040 timestamp ) with (orientation='column',appendonly=true);

INSERT INTO ck_sync1_co_table4 VALUES ('ck_sync1_co4',1,'a',11,true,'111', '1_one', '{1,2,3,4,5}', 'Hello .. how are you 1', 'Hello .. how are you 1',    '{one,two,three,four,five}',  12345678, 1, 111.1111,  11, 
 '1_one_11',   'd',  '2001-12-13 01:51:15+1359',  '11',   '0.0.0.0', '0.0.0.0', 'AA:AA:AA:AA:AA:AA',   '34.23',   '00:00:00+1359',  '((2,2),1)',   '((1,2),(2,1))',   'hello', '((1,2),(2,1))', 11,   '010101',   '2001-12-13', '((1,1),(2,2))', 
'(1,1)', '((1,2),(2,3),(3,4),(4,3),(3,2),(2,1))',    111111, '23:00:00',   '2001-12-13 01:51:15');


CREATE TABLE ck_sync1_co_table5 ( phase text,a int,col001 char DEFAULT 'z',col002 numeric,col003 boolean DEFAULT false,col004 bit(3) DEFAULT '111',col005 text DEFAULT 'pookie', 
col006 integer[] DEFAULT '{5, 4, 3, 2, 1}',col007 character varying(512) DEFAULT 'Now is the time', col008 character varying DEFAULT 'Now is the time', col009 character varying(512)[], 
col010 numeric(8),col011 int,col012 double precision, col013 bigint, col014 char(8), col015 bytea,col016 timestamp with time zone,col017 interval, col018 cidr, col019 inet, col020 macaddr,
col022 money, col024 timetz,col025 circle, col026 box, col027 name,col028 path, col029 int2, col031 bit varying(256),col032 date, col034 lseg,col035 point,col036 polygon,col037 real,col039 time, 
col040 timestamp ) with (orientation='column',appendonly=true);

INSERT INTO ck_sync1_co_table5 VALUES ('ck_sync1_co5',1,'a',11,true,'111', '1_one', '{1,2,3,4,5}', 'Hello .. how are you 1', 'Hello .. how are you 1',    '{one,two,three,four,five}',  12345678, 1, 111.1111,  11, 
 '1_one_11',   'd',  '2001-12-13 01:51:15+1359',  '11',   '0.0.0.0', '0.0.0.0', 'AA:AA:AA:AA:AA:AA',   '34.23',   '00:00:00+1359',  '((2,2),1)',   '((1,2),(2,1))',   'hello', '((1,2),(2,1))', 11,   '010101',   '2001-12-13', '((1,1),(2,2))', 
'(1,1)', '((1,2),(2,3),(3,4),(4,3),(3,2),(2,1))',    111111, '23:00:00',   '2001-12-13 01:51:15');


CREATE TABLE ck_sync1_co_table6 ( phase text,a int,col001 char DEFAULT 'z',col002 numeric,col003 boolean DEFAULT false,col004 bit(3) DEFAULT '111',col005 text DEFAULT 'pookie', 
col006 integer[] DEFAULT '{5, 4, 3, 2, 1}',col007 character varying(512) DEFAULT 'Now is the time', col008 character varying DEFAULT 'Now is the time', col009 character varying(512)[], 
col010 numeric(8),col011 int,col012 double precision, col013 bigint, col014 char(8), col015 bytea,col016 timestamp with time zone,col017 interval, col018 cidr, col019 inet, col020 macaddr,
col022 money, col024 timetz,col025 circle, col026 box, col027 name,col028 path, col029 int2, col031 bit varying(256),col032 date, col034 lseg,col035 point,col036 polygon,col037 real,col039 time, 
col040 timestamp ) with (orientation='column',appendonly=true);

INSERT INTO ck_sync1_co_table6 VALUES ('ck_sync1_co6',1,'a',11,true,'111', '1_one', '{1,2,3,4,5}', 'Hello .. how are you 1', 'Hello .. how are you 1',    '{one,two,three,four,five}',  12345678, 1, 111.1111,  11, 
 '1_one_11',   'd',  '2001-12-13 01:51:15+1359',  '11',   '0.0.0.0', '0.0.0.0', 'AA:AA:AA:AA:AA:AA',   '34.23',   '00:00:00+1359',  '((2,2),1)',   '((1,2),(2,1))',   'hello', '((1,2),(2,1))', 11,   '010101',   '2001-12-13', '((1,1),(2,2))', 
'(1,1)', '((1,2),(2,3),(3,4),(4,3),(3,2),(2,1))',    111111, '23:00:00',   '2001-12-13 01:51:15');


CREATE TABLE ck_sync1_co_table7 ( phase text,a int,col001 char DEFAULT 'z',col002 numeric,col003 boolean DEFAULT false,col004 bit(3) DEFAULT '111',col005 text DEFAULT 'pookie', 
col006 integer[] DEFAULT '{5, 4, 3, 2, 1}',col007 character varying(512) DEFAULT 'Now is the time', col008 character varying DEFAULT 'Now is the time', col009 character varying(512)[], 
col010 numeric(8),col011 int,col012 double precision, col013 bigint, col014 char(8), col015 bytea,col016 timestamp with time zone,col017 interval, col018 cidr, col019 inet, col020 macaddr,
col022 money, col024 timetz,col025 circle, col026 box, col027 name,col028 path, col029 int2, col031 bit varying(256),col032 date, col034 lseg,col035 point,col036 polygon,col037 real,col039 time, 
col040 timestamp ) with (orientation='column',appendonly=true);

INSERT INTO ck_sync1_co_table7 VALUES ('ck_sync1_co7',1,'a',11,true,'111', '1_one', '{1,2,3,4,5}', 'Hello .. how are you 1', 'Hello .. how are you 1',    '{one,two,three,four,five}',  12345678, 1, 111.1111,  11, 
 '1_one_11',   'd',  '2001-12-13 01:51:15+1359',  '11',   '0.0.0.0', '0.0.0.0', 'AA:AA:AA:AA:AA:AA',   '34.23',   '00:00:00+1359',  '((2,2),1)',   '((1,2),(2,1))',   'hello', '((1,2),(2,1))', 11,   '010101',   '2001-12-13', '((1,1),(2,2))', 
'(1,1)', '((1,2),(2,3),(3,4),(4,3),(3,2),(2,1))',    111111, '23:00:00',   '2001-12-13 01:51:15');

DROP TABLE sync1_co_table2;
DROP TABLE ck_sync1_co_table1;



