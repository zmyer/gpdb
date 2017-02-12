-- @author prabhd 
-- @created 2014-04-01 12:00:00
-- @modified 2012-04-01 12:00:00
-- @tags dml MPP-21090 ORCA
-- @optimizer_mode on	
-- @description Tests for MPP-21090
\echo --start_ignore
set gp_enable_column_oriented_table=on;
\echo --end_ignore
DROP TABLE IF EXISTS mpp21090_pttab_droplastcol_addpt_int4;
CREATE TABLE mpp21090_pttab_droplastcol_addpt_int4
(
    col1 int4,
    col2 int4,
    col3 char,
    col4 int,
    col5 int4
    
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1) end(100000001)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(100000001) end(200000001) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(200000001) end(300000001));

INSERT INTO mpp21090_pttab_droplastcol_addpt_int4 VALUES(20000000,20000000,'a',0,20000000);

ALTER TABLE mpp21090_pttab_droplastcol_addpt_int4 DROP COLUMN col5;
ALTER TABLE mpp21090_pttab_droplastcol_addpt_int4 ADD PARTITION partfour start(300000001) end(400000001);

INSERT INTO mpp21090_pttab_droplastcol_addpt_int4 SELECT 35000000,35000000,'b',1;
SELECT * FROM mpp21090_pttab_droplastcol_addpt_int4 ORDER BY 1,2,3;

-- Update distribution key
UPDATE mpp21090_pttab_droplastcol_addpt_int4 SET col1 = 10000000 WHERE col2 = 35000000 AND col1 = 35000000;
SELECT * FROM mpp21090_pttab_droplastcol_addpt_int4 ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_droplastcol_addpt_int4 SET col2 = 10000000 WHERE col2 = 35000000 AND col1 = 10000000;
SELECT * FROM mpp21090_pttab_droplastcol_addpt_int4 ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_droplastcol_addpt_int4 WHERE col2 = 10000000;
SELECT * FROM mpp21090_pttab_droplastcol_addpt_int4 ORDER BY 1,2,3;

