\echo --start_ignore
set gp_enable_column_oriented_table=on;
\echo --end_ignore
DROP TABLE IF EXISTS r;
CREATE TABLE r ( a int, b int, c int) distributed by (a);
INSERT INTO r VALUES(1,1,1);
