-- @author prabhd 
-- @created 2014-04-01 12:00:00
-- @modified 2012-04-01 12:00:00
-- @tags dml MPP-21090 ORCA
-- @optimizer_mode on	
-- @description Tests for MPP-21090
\echo --start_ignore
set gp_enable_column_oriented_table=on;
\echo --end_ignore
DROP TABLE IF EXISTS mpp21090_changedistpolicy_dml_pttab_timestamptz;
CREATE TABLE mpp21090_changedistpolicy_dml_pttab_timestamptz
(
    col1 timestamptz,
    col2 timestamptz,
    col3 char,
    col4 timestamptz,
    col5 int
) DISTRIBUTED BY (col1) PARTITION BY RANGE(col2)(partition partone start('2013-12-01 12:00:00 PST') end('2013-12-31 12:00:00 PST') WITH(APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start('2013-12-31 12:00:00 PST') end('2014-01-01 12:00:00 PST') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start('2014-01-01 12:00:00 PST') end('2014-02-01 12:00:00 PST'));


INSERT INTO mpp21090_changedistpolicy_dml_pttab_timestamptz VALUES('2013-12-30 12:00:00 PST','2013-12-30 12:00:00 PST','a','2013-12-30 12:00:00 PST',0);
SELECT * FROM mpp21090_changedistpolicy_dml_pttab_timestamptz ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_changedistpolicy_dml_pttab_timestamptz DROP COLUMN col4;

INSERT INTO mpp21090_changedistpolicy_dml_pttab_timestamptz VALUES('2013-12-30 12:00:00 PST','2013-12-30 12:00:00 PST','b',1);
SELECT * FROM mpp21090_changedistpolicy_dml_pttab_timestamptz ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_changedistpolicy_dml_pttab_timestamptz SET DISTRIBUTED BY (col3);

INSERT INTO mpp21090_changedistpolicy_dml_pttab_timestamptz SELECT '2014-01-01 12:00:00 PST', '2014-01-01 12:00:00 PST','c', 2;
SELECT * FROM mpp21090_changedistpolicy_dml_pttab_timestamptz ORDER BY 1,2,3;

UPDATE mpp21090_changedistpolicy_dml_pttab_timestamptz SET col3 ='c' WHERE col3 ='b';
SELECT * FROM mpp21090_changedistpolicy_dml_pttab_timestamptz ORDER BY 1,2,3;

DELETE FROM mpp21090_changedistpolicy_dml_pttab_timestamptz WHERE col3 ='c';
SELECT * FROM mpp21090_changedistpolicy_dml_pttab_timestamptz ORDER BY 1,2,3;

