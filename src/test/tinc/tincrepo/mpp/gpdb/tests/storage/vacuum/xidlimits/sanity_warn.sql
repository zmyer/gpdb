-- start_ignore
SET gp_create_table_random_default_distribution=off;
-- end_ignore
CREATE TABLE foo (x int);
INSERT INTO foo VALUES (1);
SELECT * FROM foo;
DROP TABLE foo;
