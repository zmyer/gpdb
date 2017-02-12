-- @author prabhd 
-- @created 2014-04-01 12:00:00
-- @modified 2012-04-01 12:00:00
-- @tags dml MPP-21090 ORCA
-- @optimizer_mode on	
-- @description Tests for MPP-21090
\echo --start_ignore
set gp_enable_column_oriented_table=on;
\echo --end_ignore
DROP TABLE IF EXISTS mpp21090_pttab_addpt_dropcol_addcol_dml_numeric;
CREATE TABLE mpp21090_pttab_addpt_dropcol_addcol_dml_numeric
(
    col1 numeric,
    col2 numeric,
    col3 char,
    col4 int
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1.000000) end(10.000000)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(10.000000) end(20.000000) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(20.000000) end(30.000000));

INSERT INTO mpp21090_pttab_addpt_dropcol_addcol_dml_numeric VALUES(2.000000,2.000000,'a',0);

ALTER TABLE mpp21090_pttab_addpt_dropcol_addcol_dml_numeric ADD PARTITION partfour start(30.000000) end(40.000000) inclusive;

INSERT INTO mpp21090_pttab_addpt_dropcol_addcol_dml_numeric SELECT 35.000000,35.000000,'b',1;
SELECT * FROM mpp21090_pttab_addpt_dropcol_addcol_dml_numeric ORDER BY 1,2,3;

ALTER TABLE mpp21090_pttab_addpt_dropcol_addcol_dml_numeric DROP COLUMN col1;

INSERT INTO mpp21090_pttab_addpt_dropcol_addcol_dml_numeric SELECT 35.000000,'c',1;
SELECT * FROM mpp21090_pttab_addpt_dropcol_addcol_dml_numeric ORDER BY 1,2,3;

ALTER TABLE mpp21090_pttab_addpt_dropcol_addcol_dml_numeric ADD COLUMN col5 numeric DEFAULT 2.000000;

INSERT INTO mpp21090_pttab_addpt_dropcol_addcol_dml_numeric SELECT 35.000000,'d',1,35.000000;
SELECT * FROM mpp21090_pttab_addpt_dropcol_addcol_dml_numeric ORDER BY 1,2,3;

UPDATE mpp21090_pttab_addpt_dropcol_addcol_dml_numeric SET col4 = 10 WHERE col2 = 35.000000;
SELECT * FROM mpp21090_pttab_addpt_dropcol_addcol_dml_numeric ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_addpt_dropcol_addcol_dml_numeric SET col2 = 1.000000 WHERE col2 = 35.000000;
SELECT * FROM mpp21090_pttab_addpt_dropcol_addcol_dml_numeric ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_addpt_dropcol_addcol_dml_numeric WHERE col2 = 1.000000;
SELECT * FROM mpp21090_pttab_addpt_dropcol_addcol_dml_numeric ORDER BY 1,2,3;

