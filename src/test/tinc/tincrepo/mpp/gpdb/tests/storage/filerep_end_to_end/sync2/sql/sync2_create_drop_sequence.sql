-- start_ignore
SET gp_create_table_random_default_distribution=off;
-- end_ignore
CREATE SEQUENCE sync2_seq1  INCREMENT BY 2 MINVALUE 1 MAXVALUE  100  CACHE 100 CYCLE;
CREATE SEQUENCE sync2_seq2  INCREMENT BY 2 MINVALUE 1 MAXVALUE  100  CACHE 100 CYCLE;

DROP SEQUENCE sync1_seq7;
DROP SEQUENCE ck_sync1_seq6;
DROP SEQUENCE ct_seq4;
DROP SEQUENCE resync_seq2;
DROP SEQUENCE sync2_seq1;

-- SEQUENCE USAGE

CREATE TABLE sync2_tbl1 ( col1 int, col2 text, col3 int) DISTRIBUTED RANDOMLY;
INSERT INTO sync2_tbl1 values (generate_series(1,100),repeat('seq_tbl_string',100),generate_series(1,100));
CREATE SEQUENCE sync2_seq11 START 101 OWNED BY sync2_tbl1.col1;
INSERT INTO sync2_tbl1 values (generate_series(1,100),repeat('seq_tbl_string',100),generate_series(1,100));


CREATE TABLE sync2_tbl2 ( col1 int, col2 text, col3 int) DISTRIBUTED RANDOMLY;
INSERT INTO sync2_tbl2 values (generate_series(1,100),repeat('seq_tbl_string',100),generate_series(1,100));
CREATE SEQUENCE sync2_seq22 START 101 OWNED BY sync2_tbl2.col1;
INSERT INTO sync2_tbl2 values (generate_series(1,100),repeat('seq_tbl_string',100),generate_series(1,100));


DROP SEQUENCE sync1_seq77;
DROP SEQUENCE ck_sync1_seq66;
DROP SEQUENCE ct_seq44;
DROP SEQUENCE resync_seq22;
DROP SEQUENCE sync2_seq11;
