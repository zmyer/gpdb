CREATE TABLE co_jit_table( phase text,a int,col001 char DEFAULT 'z',col002 numeric,col003 boolean DEFAULT false,col004 bit(3) DEFAULT '111',
col005 text DEFAULT 'pookie', col006 integer[] DEFAULT '{5, 4, 3, 2, 1}', col007 character varying(512) DEFAULT 'Now is the time', col008 character varying DEFAULT 'Now is the time', 
col009 character varying(512)[], col010 numeric(8),col011 int,col012 double precision, col013 bigint, col014 char(8), col015 bytea,col016 timestamp with time zone,col017 interval, 
col018 cidr, col019 inet, col020 macaddr,col022 money, col024 timetz,col025 circle, col026 box, col027 name,col028 path, col029 int2, col031 bit varying(256),
col032 date, col034 lseg,col035 point,col036 polygon,col037 real,col039 time, col040 timestamp ) WITH (appendonly=true, orientation=column) tablespace co_ts ;
