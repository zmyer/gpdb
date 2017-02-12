-- @author prabhd 
-- @created 2014-04-01 12:00:00
-- @modified 2012-04-01 12:00:00
-- @tags dml MPP-21090 ORCA
-- @optimizer_mode on	
-- @description Tests for MPP-21090
\echo --start_ignore
set gp_enable_column_oriented_table=on;
\echo --end_ignore
DROP TABLE IF EXISTS mpp21090_dropcol_addcol_splitpt_dml_date;
CREATE TABLE mpp21090_dropcol_addcol_splitpt_dml_date
(
    col1 date,
    col2 date,
    col3 char,
    col4 date
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start('2013-12-01') end('2013-12-31') WITH(APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start('2013-12-31') end('2014-01-01') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start('2014-01-01') end('2014-02-01'));

INSERT INTO mpp21090_dropcol_addcol_splitpt_dml_date VALUES('2013-12-31','2013-12-31','a','2013-12-31');
SELECT * FROM mpp21090_dropcol_addcol_splitpt_dml_date ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_addcol_splitpt_dml_date ADD COLUMN col5 int DEFAULT 10;

INSERT INTO mpp21090_dropcol_addcol_splitpt_dml_date VALUES('2013-12-31','2013-12-31','b','2013-12-31',0);
SELECT * FROM mpp21090_dropcol_addcol_splitpt_dml_date ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_addcol_splitpt_dml_date DROP COLUMN col4;

INSERT INTO mpp21090_dropcol_addcol_splitpt_dml_date VALUES('2013-12-31','2013-12-31','c',1);
SELECT * FROM mpp21090_dropcol_addcol_splitpt_dml_date ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_addcol_splitpt_dml_date SPLIT PARTITION partone at ('2013-12-15') into (partition partsplitone,partition partsplitwo);

INSERT INTO mpp21090_dropcol_addcol_splitpt_dml_date SELECT '2013-12-01', '2013-12-01','d', 1;
SELECT * FROM mpp21090_dropcol_addcol_splitpt_dml_date ORDER BY 1,2,3;

-- Update distribution key
UPDATE mpp21090_dropcol_addcol_splitpt_dml_date SET col1 = '2014-02-10' WHERE col2 = '2013-12-01' AND col1 = '2013-12-01';
SELECT * FROM mpp21090_dropcol_addcol_splitpt_dml_date ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_dropcol_addcol_splitpt_dml_date SET col2 ='2013-12-31'  WHERE col2 = '2013-12-01' AND col1 = '2014-02-10';
SELECT * FROM mpp21090_dropcol_addcol_splitpt_dml_date ORDER BY 1,2,3;

DELETE FROM mpp21090_dropcol_addcol_splitpt_dml_date WHERE col3='b';
SELECT * FROM mpp21090_dropcol_addcol_splitpt_dml_date ORDER BY 1,2,3;
