-- @author prabhd 
-- @created 2014-04-01 12:00:00
-- @modified 2012-04-01 12:00:00
-- @tags dml MPP-21090 ORCA
-- @optimizer_mode on	
-- @description Tests for MPP-21090
\echo --start_ignore
set gp_enable_column_oriented_table=on;
\echo --end_ignore
DROP TABLE IF EXISTS mpp21090_dropcol_addcol_splitpt_dml_time;
CREATE TABLE mpp21090_dropcol_addcol_splitpt_dml_time
(
    col1 time,
    col2 time,
    col3 char,
    col4 time
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start('12:00:00') end('18:00:00')  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start('18:00:00') end('24:00:00') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start('0:00:00') end('11:00:00'));

INSERT INTO mpp21090_dropcol_addcol_splitpt_dml_time VALUES('12:00:00','12:00:00','a','12:00:00');
SELECT * FROM mpp21090_dropcol_addcol_splitpt_dml_time ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_addcol_splitpt_dml_time ADD COLUMN col5 int DEFAULT 10;

INSERT INTO mpp21090_dropcol_addcol_splitpt_dml_time VALUES('12:00:00','12:00:00','b','12:00:00',0);
SELECT * FROM mpp21090_dropcol_addcol_splitpt_dml_time ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_addcol_splitpt_dml_time DROP COLUMN col4;

INSERT INTO mpp21090_dropcol_addcol_splitpt_dml_time VALUES('12:00:00','12:00:00','c',1);
SELECT * FROM mpp21090_dropcol_addcol_splitpt_dml_time ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_addcol_splitpt_dml_time SPLIT PARTITION partone at ('15:00:00') into (partition partsplitone,partition partsplitwo);

INSERT INTO mpp21090_dropcol_addcol_splitpt_dml_time SELECT '12:00:00', '12:00:00','d', 1;
SELECT * FROM mpp21090_dropcol_addcol_splitpt_dml_time ORDER BY 1,2,3;

-- Update distribution key
UPDATE mpp21090_dropcol_addcol_splitpt_dml_time SET col1 = '11:30:00' WHERE col2 = '12:00:00' AND col1 = '12:00:00';
SELECT * FROM mpp21090_dropcol_addcol_splitpt_dml_time ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_dropcol_addcol_splitpt_dml_time SET col2 ='12:00:00'  WHERE col2 = '12:00:00' AND col1 = '11:30:00';
SELECT * FROM mpp21090_dropcol_addcol_splitpt_dml_time ORDER BY 1,2,3;

DELETE FROM mpp21090_dropcol_addcol_splitpt_dml_time WHERE col3='b';
SELECT * FROM mpp21090_dropcol_addcol_splitpt_dml_time ORDER BY 1,2,3;
