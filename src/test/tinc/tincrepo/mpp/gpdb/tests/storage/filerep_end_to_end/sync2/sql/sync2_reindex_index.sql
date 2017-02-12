-- start_ignore
SET gp_create_table_random_default_distribution=off;
-- end_ignore
--
-- SYNC2
--
--
-- HEAP TABLE
--

CREATE TABLE sync2_heap_reindex_table_unique_index(
text_col text,
bigint_col bigint,
char_vary_col character varying(30),
numeric_col numeric,
int_col int4,
float_col float4,
int_array_col int[],
drop_col numeric,
before_rename_col int4,
change_datatype_col numeric,
a_ts_without timestamp without time zone,
b_ts_with timestamp with time zone,
date_column date) ;

CREATE UNIQUE INDEX sync2_heap_reindex_unq_idx1 ON sync2_heap_reindex_table_unique_index (numeric_col);
CREATE UNIQUE INDEX sync2_heap_reindex_unq_idx2 ON sync2_heap_reindex_table_unique_index (numeric_col);



insert into sync2_heap_reindex_table_unique_index values ('0_zero', 0, '0_zero', 0, 0, 0, '{0}', 0, 0, 0, '2004-10-19 10:23:54', '2004-10-19 10:23:54+02', '1-1-2000');
insert into sync2_heap_reindex_table_unique_index values ('1_zero', 1, '1_zero', 1, 1, 1, '{1}', 1, 1, 1, '2005-10-19 10:23:54', '2005-10-19 10:23:54+02', '1-1-2001');
insert into sync2_heap_reindex_table_unique_index values ('2_zero', 2, '2_zero', 2, 2, 2, '{2}', 2, 2, 2, '2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002');
insert into sync2_heap_reindex_table_unique_index select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{3}',i,i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002' from generate_series(3,100)i;

SELECT COUNT(*) FROM sync2_heap_reindex_table_unique_index;

CREATE TABLE sync2_heap_reindex_table_btree_index(
text_col text,
bigint_col bigint,
char_vary_col character varying(30),
numeric_col numeric,
int_col int4,
float_col float4,
int_array_col int[],
drop_col numeric,
before_rename_col int4,
change_datatype_col numeric,
a_ts_without timestamp without time zone,
b_ts_with timestamp with time zone,
date_column date) ;

CREATE INDEX sync2_heap_reindex_btree_idx1 ON sync2_heap_reindex_table_btree_index (numeric_col);
CREATE INDEX sync2_heap_reindex_btree_idx2 ON sync2_heap_reindex_table_btree_index (numeric_col);


insert into sync2_heap_reindex_table_btree_index values ('0_zero', 0, '0_zero', 0, 0, 0, '{0}', 0, 0, 0, '2004-10-19 10:23:54', '2004-10-19 10:23:54+02', '1-1-2000');
insert into sync2_heap_reindex_table_btree_index values ('1_zero', 1, '1_zero', 1, 1, 1, '{1}', 1, 1, 1, '2005-10-19 10:23:54', '2005-10-19 10:23:54+02', '1-1-2001');
insert into sync2_heap_reindex_table_btree_index values ('2_zero', 2, '2_zero', 2, 2, 2, '{2}', 2, 2, 2, '2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002');
insert into sync2_heap_reindex_table_btree_index select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{3}',i,i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002' from generate_series(3,100)i;

SELECT COUNT(*) FROM  sync2_heap_reindex_table_btree_index;

CREATE TABLE sync2_heap_reindex_table_bitmap_index(
text_col text,
bigint_col bigint,
char_vary_col character varying(30),
numeric_col numeric,
int_col int4,
float_col float4,
int_array_col int[],
drop_col numeric,
before_rename_col int4,
change_datatype_col numeric,
a_ts_without timestamp without time zone,
b_ts_with timestamp with time zone,
date_column date) ;

CREATE INDEX sync2_heap_reindex_bm_idx1 ON sync2_heap_reindex_table_bitmap_index USING bitmap (numeric_col);
CREATE INDEX sync2_heap_reindex_bm_idx2 ON sync2_heap_reindex_table_bitmap_index USING bitmap (numeric_col);

insert into sync2_heap_reindex_table_bitmap_index values ('0_zero', 0, '0_zero', 0, 0, 0, '{0}', 0, 0, 0, '2004-10-19 10:23:54', '2004-10-19 10:23:54+02', '1-1-2000');
insert into sync2_heap_reindex_table_bitmap_index values ('1_zero', 1, '1_zero', 1, 1, 1, '{1}', 1, 1, 1, '2005-10-19 10:23:54', '2005-10-19 10:23:54+02', '1-1-2001');
insert into sync2_heap_reindex_table_bitmap_index values ('2_zero', 2, '2_zero', 2, 2, 2, '{2}', 2, 2, 2, '2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002');
insert into sync2_heap_reindex_table_bitmap_index select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{3}',i,i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002' from generate_series(3,100)i;

SELECT COUNT(*) FROM sync2_heap_reindex_table_bitmap_index;

CREATE TABLE sync2_heap_reindex_table_gist_index (
 id INTEGER,
 property BOX, 
 filler VARCHAR DEFAULT 'This is here just to take up space so that we use more pages of data and sequential scans take a lot more time.  Stones tinheads and mixers coming; we did it all on our own; this summer I hear the crunching; 11 dead in Ohio. Got right down to it; we were cutting us down; could have had fun but, no; left them face down dead on the ground.  How can you listen when you know?'
 )
 DISTRIBUTED BY (id);


INSERT INTO sync2_heap_reindex_table_gist_index (id, property) VALUES (1, '( (0,0), (1,1) )');
INSERT INTO sync2_heap_reindex_table_gist_index (id, property) VALUES (2, '( (0,0), (2,2) )');
INSERT INTO sync2_heap_reindex_table_gist_index (id, property) VALUES (3, '( (0,0), (3,3) )');
INSERT INTO sync2_heap_reindex_table_gist_index (id, property) VALUES (4, '( (0,0), (4,4) )');
INSERT INTO sync2_heap_reindex_table_gist_index (id, property) VALUES (5, '( (0,0), (5,5) )');

CREATE INDEX sync2_heap_reindex_gist_idx1 ON sync2_heap_reindex_table_gist_index USING GiST (property);
CREATE INDEX sync2_heap_reindex_gist_idx2 ON sync2_heap_reindex_table_gist_index USING GiST (property);


SELECT COUNT(*) FROM  sync2_heap_reindex_table_gist_index;

--
-- REINDEX INDEX   
--
--
--
REINDEX INDEX  sync1_heap_reindex_unq_idx7;
insert into sync1_heap_reindex_table_unique_index select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{3}',i,i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002' from generate_series(161,170)i;
SELECT COUNT(*) FROM sync1_heap_reindex_table_unique_index;

REINDEX INDEX  sync1_heap_reindex_btree_idx7;
insert into sync1_heap_reindex_table_btree_index select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{3}',i,i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002' from generate_series(101,110)i;
SELECT COUNT(*) FROM sync1_heap_reindex_table_btree_index;

REINDEX INDEX  sync1_heap_reindex_bm_idx7;
insert into sync1_heap_reindex_table_bitmap_index select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{3}',i,i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002' from generate_series(101,110)i;
SELECT COUNT(*) FROM sync1_heap_reindex_table_bitmap_index;

REINDEX INDEX  sync1_heap_reindex_gist_idx7;
INSERT INTO sync1_heap_reindex_table_gist_index (id, property) VALUES (6, '( (0,0), (6,6) )');
SELECT COUNT(*) FROM sync1_heap_reindex_table_gist_index;
--
--
REINDEX INDEX  ck_sync1_heap_reindex_unq_idx6;
insert into ck_sync1_heap_reindex_table_unique_index select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{3}',i,i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002' from generate_series(161,170)i;
SELECT COUNT(*) FROM ck_sync1_heap_reindex_table_unique_index;

REINDEX INDEX  ck_sync1_heap_reindex_btree_idx6;
insert into ck_sync1_heap_reindex_table_btree_index select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{3}',i,i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002' from generate_series(101,110)i;
SELECT COUNT(*) FROM ck_sync1_heap_reindex_table_btree_index;

REINDEX INDEX  ck_sync1_heap_reindex_bm_idx6;
insert into ck_sync1_heap_reindex_table_bitmap_index select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{3}',i,i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002' from generate_series(101,110)i;
SELECT COUNT(*) FROM ck_sync1_heap_reindex_table_bitmap_index;

REINDEX INDEX  ck_sync1_heap_reindex_gist_idx6;
INSERT INTO ck_sync1_heap_reindex_table_gist_index (id, property) VALUES (6, '( (0,0), (6,6) )');
SELECT COUNT(*) FROM ck_sync1_heap_reindex_table_gist_index;
--
--
REINDEX INDEX  ct_heap_reindex_unq_idx4;
insert into ct_heap_reindex_table_unique_index select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{3}',i,i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002' from generate_series(161,170)i;
SELECT COUNT(*) FROM ct_heap_reindex_table_unique_index;

REINDEX INDEX  ct_heap_reindex_btree_idx4;
insert into ct_heap_reindex_table_btree_index select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{3}',i,i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002' from generate_series(101,110)i;
SELECT COUNT(*) FROM ct_heap_reindex_table_btree_index;

REINDEX INDEX  ct_heap_reindex_bm_idx4;
insert into ct_heap_reindex_table_bitmap_index select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{3}',i,i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002' from generate_series(101,110)i;
SELECT COUNT(*) FROM ct_heap_reindex_table_bitmap_index;

REINDEX INDEX  ct_heap_reindex_gist_idx4;
INSERT INTO ct_heap_reindex_table_gist_index (id, property) VALUES (6, '( (0,0), (6,6) )');
SELECT COUNT(*) FROM ct_heap_reindex_table_gist_index;
--
--
REINDEX INDEX  resync_heap_reindex_unq_idx2;
insert into resync_heap_reindex_table_unique_index select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{3}',i,i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002' from generate_series(161,170)i;
SELECT COUNT(*) FROM resync_heap_reindex_table_unique_index;

REINDEX INDEX  resync_heap_reindex_btree_idx2;
insert into resync_heap_reindex_table_btree_index select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{3}',i,i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002' from generate_series(101,110)i;
SELECT COUNT(*) FROM resync_heap_reindex_table_btree_index;

REINDEX INDEX  resync_heap_reindex_bm_idx2;
insert into resync_heap_reindex_table_bitmap_index select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{3}',i,i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002' from generate_series(101,110)i;
SELECT COUNT(*) FROM resync_heap_reindex_table_bitmap_index;

REINDEX INDEX  resync_heap_reindex_gist_idx2;
INSERT INTO resync_heap_reindex_table_gist_index (id, property) VALUES (6, '( (0,0), (6,6) )');
SELECT COUNT(*) FROM resync_heap_reindex_table_gist_index;
--
--
REINDEX INDEX  sync2_heap_reindex_unq_idx1;
insert into sync2_heap_reindex_table_unique_index select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{3}',i,i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002' from generate_series(161,170)i;
SELECT COUNT(*) FROM sync2_heap_reindex_table_unique_index;

REINDEX INDEX  sync2_heap_reindex_btree_idx1;
insert into sync2_heap_reindex_table_btree_index select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{3}',i,i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002' from generate_series(101,110)i;
SELECT COUNT(*) FROM sync2_heap_reindex_table_btree_index;

REINDEX INDEX  sync2_heap_reindex_bm_idx1;
insert into sync2_heap_reindex_table_bitmap_index select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{3}',i,i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002' from generate_series(101,110)i;
SELECT COUNT(*) FROM sync2_heap_reindex_table_bitmap_index;

REINDEX INDEX  sync2_heap_reindex_gist_idx1;
INSERT INTO sync2_heap_reindex_table_gist_index (id, property) VALUES (6, '( (0,0), (6,6) )');
SELECT COUNT(*) FROM sync2_heap_reindex_table_gist_index;
--
--

--
-- AO Index
--

CREATE TABLE sync2_ao_reindex_table_btree_index(
text_col text,
bigint_col bigint,
char_vary_col character varying(30),
numeric_col numeric,
int_col int4,
float_col float4,
int_array_col int[],
drop_col numeric,
before_rename_col int4,
change_datatype_col numeric,
a_ts_without timestamp without time zone,
b_ts_with timestamp with time zone,
date_column date) with (appendonly=true) ;

CREATE INDEX sync2_ao_reindex_btree_idx1 ON sync2_ao_reindex_table_btree_index (numeric_col);
CREATE INDEX sync2_ao_reindex_btree_idx2 ON sync2_ao_reindex_table_btree_index (numeric_col);


insert into sync2_ao_reindex_table_btree_index values ('0_zero', 0, '0_zero', 0, 0, 0, '{0}', 0, 0, 0, '2004-10-19 10:23:54', '2004-10-19 10:23:54+02', '1-1-2000');
insert into sync2_ao_reindex_table_btree_index values ('1_zero', 1, '1_zero', 1, 1, 1, '{1}', 1, 1, 1, '2005-10-19 10:23:54', '2005-10-19 10:23:54+02', '1-1-2001');
insert into sync2_ao_reindex_table_btree_index values ('2_zero', 2, '2_zero', 2, 2, 2, '{2}', 2, 2, 2, '2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002');
insert into sync2_ao_reindex_table_btree_index select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{3}',i,i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002' from generate_series(3,100)i;

SELECT COUNT(*) FROM sync2_ao_reindex_table_btree_index ;

CREATE TABLE sync2_ao_reindex_table_bitmap_index(
text_col text,
bigint_col bigint,
char_vary_col character varying(30),
numeric_col numeric,
int_col int4,
float_col float4,
int_array_col int[],
drop_col numeric,
before_rename_col int4,
change_datatype_col numeric,
a_ts_without timestamp without time zone,
b_ts_with timestamp with time zone,
date_column date) with (appendonly=true) ;

CREATE INDEX sync2_ao_reindex_bm_idx1 ON sync2_ao_reindex_table_bitmap_index USING bitmap (numeric_col);
CREATE INDEX sync2_ao_reindex_bm_idx2 ON sync2_ao_reindex_table_bitmap_index USING bitmap (numeric_col);


insert into sync2_ao_reindex_table_bitmap_index values ('0_zero', 0, '0_zero', 0, 0, 0, '{0}', 0, 0, 0, '2004-10-19 10:23:54', '2004-10-19 10:23:54+02', '1-1-2000');
insert into sync2_ao_reindex_table_bitmap_index values ('1_zero', 1, '1_zero', 1, 1, 1, '{1}', 1, 1, 1, '2005-10-19 10:23:54', '2005-10-19 10:23:54+02', '1-1-2001');
insert into sync2_ao_reindex_table_bitmap_index values ('2_zero', 2, '2_zero', 2, 2, 2, '{2}', 2, 2, 2, '2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002');
insert into sync2_ao_reindex_table_bitmap_index select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{3}',i,i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002' from generate_series(3,100)i;

SELECT COUNT(*) FROM sync2_ao_reindex_table_bitmap_index;

CREATE TABLE sync2_ao_reindex_table_gist_index (
 id INTEGER,
 property BOX,
 filler VARCHAR DEFAULT 'This is here just to take up space so that we use more pages of data and sequential scans take a lot more time.  Stones tinheads and mixers coming; we did it all on our own; this summer I hear the crunching; 11
 dead in Ohio. Got right down to it; we were cutting us down; could have had fun but, no; left them face down dead on the ground.  How can you listen when you know?'
 )
 DISTRIBUTED BY (id);


INSERT INTO sync2_ao_reindex_table_gist_index (id, property) VALUES (1, '( (0,0), (1,1) )');
INSERT INTO sync2_ao_reindex_table_gist_index (id, property) VALUES (2, '( (0,0), (2,2) )');
INSERT INTO sync2_ao_reindex_table_gist_index (id, property) VALUES (3, '( (0,0), (3,3) )');
INSERT INTO sync2_ao_reindex_table_gist_index (id, property) VALUES (4, '( (0,0), (4,4) )');
INSERT INTO sync2_ao_reindex_table_gist_index (id, property) VALUES (5, '( (0,0), (5,5) )');

CREATE INDEX sync2_ao_reindex_gist_idx1 ON sync2_ao_reindex_table_gist_index USING GiST (property);
CREATE INDEX sync2_ao_reindex_gist_idx2 ON sync2_ao_reindex_table_gist_index USING GiST (property);


SELECT COUNT(*) FROM sync2_ao_reindex_table_gist_index;

--
-- REINDEX INDEX       
--

REINDEX INDEX  sync1_ao_reindex_btree_idx7;
insert into sync1_ao_reindex_table_btree_index select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{3}',i,i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002' from generate_series(101,110)i;
SELECT COUNT(*) FROM sync1_ao_reindex_table_btree_index;

REINDEX INDEX  sync1_ao_reindex_bm_idx7;
insert into sync1_ao_reindex_table_bitmap_index select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{3}',i,i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002' from generate_series(101,110)i;
SELECT COUNT(*) FROM sync1_ao_reindex_table_bitmap_index;

REINDEX INDEX  sync1_ao_reindex_gist_idx7;
INSERT INTO sync1_ao_reindex_table_gist_index (id, property) VALUES (6, '( (0,0), (6,6) )');
SELECT COUNT(*) FROM sync1_ao_reindex_table_gist_index;
--
--
REINDEX INDEX  ck_sync1_ao_reindex_btree_idx6;
insert into ck_sync1_ao_reindex_table_btree_index select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{3}',i,i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002' from generate_series(101,110)i;
SELECT COUNT(*) FROM ck_sync1_ao_reindex_table_btree_index;

REINDEX INDEX  ck_sync1_ao_reindex_bm_idx6;
insert into ck_sync1_ao_reindex_table_bitmap_index select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{3}',i,i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002' from generate_series(101,110)i;
SELECT COUNT(*) FROM ck_sync1_ao_reindex_table_bitmap_index;

REINDEX INDEX  ck_sync1_ao_reindex_gist_idx6;
INSERT INTO ck_sync1_ao_reindex_table_gist_index (id, property) VALUES (6, '( (0,0), (6,6) )');
SELECT COUNT(*) FROM ck_sync1_ao_reindex_table_gist_index;
--
--
REINDEX INDEX  ct_ao_reindex_btree_idx4;
insert into ct_ao_reindex_table_btree_index select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{3}',i,i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002' from generate_series(101,110)i;
SELECT COUNT(*) FROM ct_ao_reindex_table_btree_index;
REINDEX INDEX  ct_ao_reindex_bm_idx4;
insert into ct_ao_reindex_table_bitmap_index select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{3}',i,i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002' from generate_series(101,110)i;
SELECT COUNT(*) FROM ct_ao_reindex_table_bitmap_index ;
REINDEX INDEX  ct_ao_reindex_gist_idx4;
INSERT INTO ct_ao_reindex_table_gist_index (id, property) VALUES (6, '( (0,0), (6,6) )');
SELECT COUNT(*) FROM ct_ao_reindex_table_gist_index;
--
--
REINDEX INDEX  resync_ao_reindex_btree_idx2;
insert into resync_ao_reindex_table_btree_index select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{3}',i,i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002' from generate_series(101,110)i;
SELECT COUNT(*) FROM resync_ao_reindex_table_btree_index;
REINDEX INDEX  resync_ao_reindex_bm_idx2;
insert into resync_ao_reindex_table_bitmap_index select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{3}',i,i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002' from generate_series(101,110)i;
SELECT COUNT(*) FROM resync_ao_reindex_table_bitmap_index ;
REINDEX INDEX  resync_ao_reindex_gist_idx2;
INSERT INTO resync_ao_reindex_table_gist_index (id, property) VALUES (6, '( (0,0), (6,6) )');
SELECT COUNT(*) FROM resync_ao_reindex_table_gist_index;
--
--
REINDEX INDEX  sync2_ao_reindex_btree_idx1;
insert into sync2_ao_reindex_table_btree_index select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{3}',i,i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002' from generate_series(101,110)i;
SELECT COUNT(*) FROM sync2_ao_reindex_table_btree_index;

REINDEX INDEX  sync2_ao_reindex_bm_idx1;
insert into sync2_ao_reindex_table_bitmap_index select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{3}',i,i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002' from generate_series(101,110)i;
SELECT COUNT(*) FROM sync2_ao_reindex_table_bitmap_index;

REINDEX INDEX  sync2_ao_reindex_gist_idx1;
INSERT INTO sync2_ao_reindex_table_gist_index (id, property) VALUES (6, '( (0,0), (6,6) )');
SELECT COUNT(*) FROM sync2_ao_reindex_table_gist_index;

--
-- CO Index
--

CREATE TABLE sync2_co_reindex_table_btree_index(
text_col text,
bigint_col bigint,
char_vary_col character varying(30),
numeric_col numeric,
int_col int4,
float_col float4,
int_array_col int[],
drop_col numeric,
before_rename_col int4,
change_datatype_col numeric,
a_ts_without timestamp without time zone,
b_ts_with timestamp with time zone,
date_column date) with (orientation='column',appendonly=true) ;

CREATE INDEX sync2_co_reindex_btree_idx1 ON sync2_co_reindex_table_btree_index (numeric_col);
CREATE INDEX sync2_co_reindex_btree_idx2 ON sync2_co_reindex_table_btree_index (numeric_col);


insert into sync2_co_reindex_table_btree_index values ('0_zero', 0, '0_zero', 0, 0, 0, '{0}', 0, 0, 0, '2004-10-19 10:23:54', '2004-10-19 10:23:54+02', '1-1-2000');
insert into sync2_co_reindex_table_btree_index values ('1_zero', 1, '1_zero', 1, 1, 1, '{1}', 1, 1, 1, '2005-10-19 10:23:54', '2005-10-19 10:23:54+02', '1-1-2001');
insert into sync2_co_reindex_table_btree_index values ('2_zero', 2, '2_zero', 2, 2, 2, '{2}', 2, 2, 2, '2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002');
insert into sync2_co_reindex_table_btree_index select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{3}',i,i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002' from generate_series(3,100)i;

SELECT COUNT(*) FROM sync2_co_reindex_table_btree_index; 

CREATE TABLE sync2_co_reindex_table_bitmap_index(
text_col text,
bigint_col bigint,
char_vary_col character varying(30),
numeric_col numeric,
int_col int4,
float_col float4,
int_array_col int[],
drop_col numeric,
before_rename_col int4,
change_datatype_col numeric,
a_ts_without timestamp without time zone,
b_ts_with timestamp with time zone,
date_column date) with (orientation='column',appendonly=true);

CREATE INDEX sync2_co_reindex_bm_idx1 ON sync2_co_reindex_table_bitmap_index USING bitmap (numeric_col);
CREATE INDEX sync2_co_reindex_bm_idx2 ON sync2_co_reindex_table_bitmap_index USING bitmap (numeric_col);



insert into sync2_co_reindex_table_bitmap_index values ('0_zero', 0, '0_zero', 0, 0, 0, '{0}', 0, 0, 0, '2004-10-19 10:23:54', '2004-10-19 10:23:54+02', '1-1-2000');
insert into sync2_co_reindex_table_bitmap_index values ('1_zero', 1, '1_zero', 1, 1, 1, '{1}', 1, 1, 1, '2005-10-19 10:23:54', '2005-10-19 10:23:54+02', '1-1-2001');
insert into sync2_co_reindex_table_bitmap_index values ('2_zero', 2, '2_zero', 2, 2, 2, '{2}', 2, 2, 2, '2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002');
insert into sync2_co_reindex_table_bitmap_index select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{3}',i,i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002' from generate_series(3,100)i;

SELECT COUNT(*) FROM sync2_co_reindex_table_bitmap_index;

CREATE TABLE sync2_co_reindex_table_gist_index (
 id INTEGER,
 property BOX,
 filler VARCHAR DEFAULT 'This is here just to take up space so that we use more pages of data and sequential scans take a lot more time.  Stones tinheads and mixers coming; we did it all on our own; this summer I hear the crunching; 11
 dead in Ohio. Got right down to it; we were cutting us down; could have had fun but, no; left them face down dead on the ground.  How can you listen when you know?'
 )
 DISTRIBUTED BY (id);


INSERT INTO sync2_co_reindex_table_gist_index (id, property) VALUES (1, '( (0,0), (1,1) )');
INSERT INTO sync2_co_reindex_table_gist_index (id, property) VALUES (2, '( (0,0), (2,2) )');
INSERT INTO sync2_co_reindex_table_gist_index (id, property) VALUES (3, '( (0,0), (3,3) )');
INSERT INTO sync2_co_reindex_table_gist_index (id, property) VALUES (4, '( (0,0), (4,4) )');
INSERT INTO sync2_co_reindex_table_gist_index (id, property) VALUES (5, '( (0,0), (5,5) )');

CREATE INDEX sync2_co_reindex_gist_idx1 ON sync2_co_reindex_table_gist_index USING GiST (property);
CREATE INDEX sync2_co_reindex_gist_idx2 ON sync2_co_reindex_table_gist_index USING GiST (property);


SELECT COUNT(*) FROM sync2_co_reindex_table_gist_index;
--
-- REINDEX INDEX       
--

REINDEX INDEX  sync1_co_reindex_btree_idx7;
insert into sync1_co_reindex_table_btree_index select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{3}',i,i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002' from generate_series(101,110)i;
SELECT COUNT(*) FROM sync1_co_reindex_table_btree_index;
REINDEX INDEX  sync1_co_reindex_bm_idx7;
insert into sync1_co_reindex_table_bitmap_index select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{3}',i,i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002' from generate_series(101,110)i;
SELECT COUNT(*) FROM sync1_co_reindex_table_bitmap_index ;
REINDEX INDEX  sync1_co_reindex_gist_idx7;
INSERT INTO sync1_co_reindex_table_gist_index (id, property) VALUES (6, '( (0,0), (6,6) )');
SELECT COUNT(*) FROM sync1_co_reindex_table_gist_index;
--
--
REINDEX INDEX  ck_sync1_co_reindex_btree_idx6;
insert into ck_sync1_co_reindex_table_btree_index select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{3}',i,i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002' from generate_series(101,110)i;
SELECT COUNT(*) FROM ck_sync1_co_reindex_table_btree_index;
REINDEX INDEX  ck_sync1_co_reindex_bm_idx6;
insert into ck_sync1_co_reindex_table_bitmap_index select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{3}',i,i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002' from generate_series(101,110)i;
SELECT COUNT(*) FROM ck_sync1_co_reindex_table_bitmap_index ;
REINDEX INDEX  ck_sync1_co_reindex_gist_idx6;
INSERT INTO ck_sync1_co_reindex_table_gist_index (id, property) VALUES (6, '( (0,0), (6,6) )');
SELECT COUNT(*) FROM ck_sync1_co_reindex_table_gist_index;
--
--
REINDEX INDEX  ct_co_reindex_btree_idx4;
insert into ct_co_reindex_table_btree_index select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{3}',i,i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002' from generate_series(101,110)i;
SELECT COUNT(*) FROM ct_co_reindex_table_btree_index;
REINDEX INDEX  ct_co_reindex_bm_idx4;
insert into ct_co_reindex_table_bitmap_index select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{3}',i,i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002' from generate_series(101,110)i;
SELECT COUNT(*) FROM ct_co_reindex_table_bitmap_index ;
REINDEX INDEX  ct_co_reindex_gist_idx4;
INSERT INTO ct_co_reindex_table_gist_index (id, property) VALUES (6, '( (0,0), (6,6) )');
SELECT COUNT(*) FROM ct_co_reindex_table_gist_index;
--
--
REINDEX INDEX  resync_co_reindex_btree_idx2;
insert into resync_co_reindex_table_btree_index select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{3}',i,i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002' from generate_series(101,110)i;
SELECT COUNT(*) FROM resync_co_reindex_table_btree_index;
REINDEX INDEX  resync_co_reindex_bm_idx2;
insert into resync_co_reindex_table_bitmap_index select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{3}',i,i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002' from generate_series(101,110)i;
SELECT COUNT(*) FROM resync_co_reindex_table_bitmap_index ;
REINDEX INDEX  resync_co_reindex_gist_idx2;
INSERT INTO resync_co_reindex_table_gist_index (id, property) VALUES (6, '( (0,0), (6,6) )');
SELECT COUNT(*) FROM resync_co_reindex_table_gist_index;
--
--
REINDEX INDEX  sync2_co_reindex_btree_idx1;
insert into sync2_co_reindex_table_btree_index select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{3}',i,i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002' from generate_series(101,110)i;
SELECT COUNT(*) FROM sync2_co_reindex_table_btree_index;
REINDEX INDEX  sync2_co_reindex_bm_idx1;
insert into sync2_co_reindex_table_bitmap_index select i||'_'||repeat('text',100),i,i||'_'||repeat('text',3),i,i,i,'{3}',i,i,i,'2006-10-19 10:23:54', '2006-10-19 10:23:54+02', '1-1-2002' from generate_series(101,110)i;
SELECT COUNT(*) FROM sync2_co_reindex_table_bitmap_index ;
REINDEX INDEX  sync2_co_reindex_gist_idx1;
INSERT INTO sync2_co_reindex_table_gist_index (id, property) VALUES (6, '( (0,0), (6,6) )');
SELECT COUNT(*) FROM sync2_co_reindex_table_gist_index;


