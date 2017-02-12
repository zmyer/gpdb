-- @author prabhd 
-- @created 2014-04-01 12:00:00
-- @modified 2012-04-01 12:00:00
-- @tags dml MPP-21090 ORCA
-- @optimizer_mode on	
-- @description Tests for MPP-21090
\echo --start_ignore
set gp_enable_column_oriented_table=on;
\echo --end_ignore
DROP TABLE IF EXISTS mpp21090_drop_lastcol_dml_timestamp;
CREATE TABLE mpp21090_drop_lastcol_dml_timestamp(
col1 int,
col2 decimal,
col3 char,
col4 date,
col5 timestamp
) DISTRIBUTED by(col3);
INSERT INTO mpp21090_drop_lastcol_dml_timestamp VALUES(0,0.00,'a','2014-01-01','2013-12-31 12:00:00');
SELECT * FROM mpp21090_drop_lastcol_dml_timestamp ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_lastcol_dml_timestamp DROP COLUMN col5;
INSERT INTO mpp21090_drop_lastcol_dml_timestamp SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_lastcol_dml_timestamp ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_lastcol_dml_timestamp SET col3='c' WHERE col3 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_lastcol_dml_timestamp ORDER BY 1,2,3,4;
DELETE FROM mpp21090_drop_lastcol_dml_timestamp WHERE col3='c';
SELECT * FROM mpp21090_drop_lastcol_dml_timestamp ORDER BY 1,2,3,4;

