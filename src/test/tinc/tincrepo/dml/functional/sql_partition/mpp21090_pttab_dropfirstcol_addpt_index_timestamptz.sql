-- @author prabhd 
-- @created 2014-04-01 12:00:00
-- @modified 2012-04-01 12:00:00
-- @tags dml MPP-21090 ORCA
-- @optimizer_mode on	
-- @description Tests for MPP-21090
\echo --start_ignore
set gp_enable_column_oriented_table=on;
\echo --end_ignore
DROP TABLE IF EXISTS mpp21090_pttab_dropfirstcol_addpt_index_timestamptz;
CREATE TABLE mpp21090_pttab_dropfirstcol_addpt_index_timestamptz
(
    col1 timestamptz,
    col2 timestamptz,
    col3 char,
    col4 timestamptz,
    col5 int
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start('2013-12-01 12:00:00 PST') end('2013-12-31 12:00:00 PST') WITH(APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start('2013-12-31 12:00:00 PST') end('2014-01-01 12:00:00 PST') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start('2014-01-01 12:00:00 PST') end('2014-02-01 12:00:00 PST'));

INSERT INTO mpp21090_pttab_dropfirstcol_addpt_index_timestamptz VALUES('2013-12-30 12:00:00 PST','2013-12-30 12:00:00 PST','a','2013-12-30 12:00:00 PST',0);

DROP INDEX IF EXISTS mpp21090_pttab_dropfirstcol_addpt_index_idx_timestamptz;
CREATE INDEX mpp21090_pttab_dropfirstcol_addpt_index_idx_timestamptz on mpp21090_pttab_dropfirstcol_addpt_index_timestamptz(col2);

ALTER TABLE mpp21090_pttab_dropfirstcol_addpt_index_timestamptz DROP COLUMN col1;
ALTER TABLE mpp21090_pttab_dropfirstcol_addpt_index_timestamptz ADD PARTITION partfour start('2014-02-01 12:00:00 PST') end('2014-03-01 12:00:00 PST') inclusive;

INSERT INTO mpp21090_pttab_dropfirstcol_addpt_index_timestamptz SELECT '2014-02-10 12:00:00 PST','b','2014-02-10 12:00:00 PST', 1;
SELECT * FROM mpp21090_pttab_dropfirstcol_addpt_index_timestamptz ORDER BY 1,2,3;

UPDATE mpp21090_pttab_dropfirstcol_addpt_index_timestamptz SET col4 = '2014-01-01 12:00:00 PST' WHERE col2 = '2014-02-10 12:00:00 PST' AND col4 = '2014-02-10 12:00:00 PST';
SELECT * FROM mpp21090_pttab_dropfirstcol_addpt_index_timestamptz ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_dropfirstcol_addpt_index_timestamptz SET col2 = '2014-01-01 12:00:00 PST' WHERE col2 = '2014-02-10 12:00:00 PST' AND col4 = '2014-01-01 12:00:00 PST';
SELECT * FROM mpp21090_pttab_dropfirstcol_addpt_index_timestamptz ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_dropfirstcol_addpt_index_timestamptz WHERE col2 = '2014-01-01 12:00:00 PST';
SELECT * FROM mpp21090_pttab_dropfirstcol_addpt_index_timestamptz ORDER BY 1,2,3;

