DROP TABLE IF EXISTS dml_trigger_table_1;
CREATE TABLE dml_trigger_table_1
(
 name varchar(10),
 age  numeric(10),
 updated_by varchar
)
distributed by (age);

CREATE OR REPLACE FUNCTION dml_function_1() RETURNS trigger AS
$$
BEGIN
   NEW.updated_by = 'a';
   RETURN NEW;
END
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER dml_trigger_1
AFTER DELETE or UPDATE
ON dml_trigger_table_1
FOR EACH ROW
EXECUTE PROCEDURE dml_function_1();