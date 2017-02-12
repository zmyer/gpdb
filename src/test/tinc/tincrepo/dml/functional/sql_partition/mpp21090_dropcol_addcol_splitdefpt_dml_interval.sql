-- @author prabhd 
-- @created 2014-04-01 12:00:00
-- @modified 2012-04-01 12:00:00
-- @tags dml MPP-21090 ORCA
-- @optimizer_mode on	
-- @description Tests for MPP-21090
\echo --start_ignore
set gp_enable_column_oriented_table=on;
\echo --end_ignore
DROP TABLE IF EXISTS mpp21090_dropcol_addcol_splitdefpt_dml_interval;
CREATE TABLE mpp21090_dropcol_addcol_splitdefpt_dml_interval
(
    col1 interval,
    col2 interval,
    col3 char,
    col4 interval
) 
DISTRIBUTED by (col1)
PARTITION BY LIST(col2)
(
default partition def
);

INSERT INTO mpp21090_dropcol_addcol_splitdefpt_dml_interval VALUES('1 hour','1 hour','a','1 hour');
SELECT * FROM mpp21090_dropcol_addcol_splitdefpt_dml_interval ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_addcol_splitdefpt_dml_interval DROP COLUMN col4;

INSERT INTO mpp21090_dropcol_addcol_splitdefpt_dml_interval VALUES('1 hour','1 hour','b');
SELECT * FROM mpp21090_dropcol_addcol_splitdefpt_dml_interval ORDER BY 1,2,3;

ALTER TABLE mpp21090_dropcol_addcol_splitdefpt_dml_interval ADD COLUMN col5 int DEFAULT 10;

INSERT INTO mpp21090_dropcol_addcol_splitdefpt_dml_interval VALUES('1 hour','1 hour','c',1);
SELECT * FROM mpp21090_dropcol_addcol_splitdefpt_dml_interval ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_addcol_splitdefpt_dml_interval SPLIT DEFAULT PARTITION at ('30 secs') into (partition partsplitone,partition def);

INSERT INTO mpp21090_dropcol_addcol_splitdefpt_dml_interval SELECT '1 sec', '1 sec','e', 1;
SELECT * FROM mpp21090_dropcol_addcol_splitdefpt_dml_interval ORDER BY 1,2,3;

-- Update distribution key
UPDATE mpp21090_dropcol_addcol_splitdefpt_dml_interval SET col1 = '14 hours' WHERE col2 = '1 sec' AND col1 = '1 sec';
SELECT * FROM mpp21090_dropcol_addcol_splitdefpt_dml_interval ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_dropcol_addcol_splitdefpt_dml_interval SET col2 = '14 hours' WHERE col2 = '1 sec' AND col1 = '14 hours';
SELECT * FROM mpp21090_dropcol_addcol_splitdefpt_dml_interval ORDER BY 1,2,3;

DELETE FROM mpp21090_dropcol_addcol_splitdefpt_dml_interval WHERE col3='b';
SELECT * FROM mpp21090_dropcol_addcol_splitdefpt_dml_interval ORDER BY 1,2,3;
