-- start_ignore
SET gp_create_table_random_default_distribution=off;
-- end_ignore
DROP TABLE IF EXISTS foo;

CREATE TABLE foo (a INT, b INT, c CHAR(128)) WITH (appendonly=true, orientation=column);
CREATE INDEX foo_index ON foo(b);
INSERT INTO foo SELECT i as a, i as b, 'hello world' as c FROM generate_series(1,1000) AS i;
