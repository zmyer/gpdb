-- start_ignore
SET gp_create_table_random_default_distribution=off;
-- end_ignore
DROP TABLE IF EXISTS foo;
CREATE TABLE foo (a INT, b INT, c CHAR(128)) WITH (appendonly=true, orientation=column);
INSERT INTO foo SELECT i as a, i as b, 'hello world' as c FROM generate_series(1,10) AS i;
INSERT INTO foo SELECT i as a, i as b, 'hello world' as c FROM generate_series(11,20) AS i;
INSERT INTO foo SELECT i as a, i as b, 'hello world' as c FROM generate_series(21,30) AS i;
