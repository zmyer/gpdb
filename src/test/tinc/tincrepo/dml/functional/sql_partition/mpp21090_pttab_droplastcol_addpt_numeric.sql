-- @author prabhd 
-- @created 2014-04-01 12:00:00
-- @modified 2012-04-01 12:00:00
-- @tags dml MPP-21090 ORCA
-- @optimizer_mode on	
-- @description Tests for MPP-21090
\echo --start_ignore
set gp_enable_column_oriented_table=on;
\echo --end_ignore
DROP TABLE IF EXISTS mpp21090_pttab_droplastcol_addpt_numeric;
CREATE TABLE mpp21090_pttab_droplastcol_addpt_numeric
(
    col1 numeric,
    col2 numeric,
    col3 char,
    col4 int,
    col5 numeric
    
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1.000000) end(10.000000)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(10.000000) end(20.000000) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(20.000000) end(30.000000));

INSERT INTO mpp21090_pttab_droplastcol_addpt_numeric VALUES(2.000000,2.000000,'a',0,2.000000);

ALTER TABLE mpp21090_pttab_droplastcol_addpt_numeric DROP COLUMN col5;
ALTER TABLE mpp21090_pttab_droplastcol_addpt_numeric ADD PARTITION partfour start(30.000000) end(40.000000) inclusive;

INSERT INTO mpp21090_pttab_droplastcol_addpt_numeric SELECT 35.000000,35.000000,'b',1;
SELECT * FROM mpp21090_pttab_droplastcol_addpt_numeric ORDER BY 1,2,3;

-- Update distribution key
UPDATE mpp21090_pttab_droplastcol_addpt_numeric SET col1 = 1.000000 WHERE col2 = 35.000000 AND col1 = 35.000000;
SELECT * FROM mpp21090_pttab_droplastcol_addpt_numeric ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_droplastcol_addpt_numeric SET col2 = 1.000000 WHERE col2 = 35.000000 AND col1 = 1.000000;
SELECT * FROM mpp21090_pttab_droplastcol_addpt_numeric ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_droplastcol_addpt_numeric WHERE col2 = 1.000000;
SELECT * FROM mpp21090_pttab_droplastcol_addpt_numeric ORDER BY 1,2,3;

