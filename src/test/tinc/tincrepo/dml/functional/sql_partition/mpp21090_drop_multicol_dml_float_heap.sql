-- @author prabhd 
-- @created 2014-04-01 12:00:00
-- @modified 2012-04-01 12:00:00
-- @tags dml MPP-21090 ORCA
-- @optimizer_mode on	
-- @description Tests for MPP-21090
\echo --start_ignore
set gp_enable_column_oriented_table=on;
\echo --end_ignore
DROP TABLE IF EXISTS mpp21090_drop_multicol_dml_float;
CREATE TABLE mpp21090_drop_multicol_dml_float(
col1 float,
col2 decimal,
col3 char,
col4 date,
col5 int
)  DISTRIBUTED by (col3);
INSERT INTO mpp21090_drop_multicol_dml_float VALUES(2.00,0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_multicol_dml_float ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_multicol_dml_float DROP COLUMN col1;
ALTER TABLE mpp21090_drop_multicol_dml_float DROP COLUMN col4;
INSERT INTO mpp21090_drop_multicol_dml_float SELECT 1.00,'b',1;
SELECT * FROM mpp21090_drop_multicol_dml_float ORDER BY 1,2,3;
UPDATE mpp21090_drop_multicol_dml_float SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_multicol_dml_float ORDER BY 1,2,3;
DELETE FROM mpp21090_drop_multicol_dml_float WHERE col3='c';
SELECT * FROM mpp21090_drop_multicol_dml_float ORDER BY 1,2,3;

