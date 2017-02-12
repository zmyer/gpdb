-- @author prabhd 
-- @created 2014-04-01 12:00:00
-- @modified 2012-04-01 12:00:00
-- @tags dml MPP-21090 ORCA
-- @optimizer_mode on	
-- @description Tests for MPP-21090
\echo --start_ignore
set gp_enable_column_oriented_table=on;
\echo --end_ignore
DROP TABLE IF EXISTS mpp21090_dropcol_splitdefpt_addcol_dml_decimal;
CREATE TABLE mpp21090_dropcol_splitdefpt_addcol_dml_decimal
(
    col1 decimal,
    col2 decimal,
    col3 char,
    col4 decimal
) 
DISTRIBUTED by (col1)
PARTITION BY LIST(col2)
(
default partition def
);

INSERT INTO mpp21090_dropcol_splitdefpt_addcol_dml_decimal VALUES(2.00,2.00,'a',2.00);
SELECT * FROM mpp21090_dropcol_splitdefpt_addcol_dml_decimal ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_splitdefpt_addcol_dml_decimal DROP COLUMN col4;

INSERT INTO mpp21090_dropcol_splitdefpt_addcol_dml_decimal VALUES(2.00,2.00,'b');
SELECT * FROM mpp21090_dropcol_splitdefpt_addcol_dml_decimal ORDER BY 1,2,3;

ALTER TABLE mpp21090_dropcol_splitdefpt_addcol_dml_decimal SPLIT DEFAULT PARTITION at (5.00) into (partition partsplitone,partition def);

INSERT INTO mpp21090_dropcol_splitdefpt_addcol_dml_decimal SELECT 1.00, 1.00,'e';
SELECT * FROM mpp21090_dropcol_splitdefpt_addcol_dml_decimal ORDER BY 1,2,3;

ALTER TABLE mpp21090_dropcol_splitdefpt_addcol_dml_decimal ADD COLUMN col5 decimal DEFAULT 2.00;

INSERT INTO mpp21090_dropcol_splitdefpt_addcol_dml_decimal VALUES(2.00,2.00,'c',2.00);
SELECT * FROM mpp21090_dropcol_splitdefpt_addcol_dml_decimal ORDER BY 1,2,3,4;

-- Update distribution key
UPDATE mpp21090_dropcol_splitdefpt_addcol_dml_decimal SET col1 = 35.00 WHERE col2 = 1.00 AND col1 = 1.00;
SELECT * FROM mpp21090_dropcol_splitdefpt_addcol_dml_decimal ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_dropcol_splitdefpt_addcol_dml_decimal SET col2 = 35.00 WHERE col2 = 1.00 AND col1 = 35.00;
SELECT * FROM mpp21090_dropcol_splitdefpt_addcol_dml_decimal ORDER BY 1,2,3;

DELETE FROM mpp21090_dropcol_splitdefpt_addcol_dml_decimal WHERE col3='b';
SELECT * FROM mpp21090_dropcol_splitdefpt_addcol_dml_decimal ORDER BY 1,2,3;
