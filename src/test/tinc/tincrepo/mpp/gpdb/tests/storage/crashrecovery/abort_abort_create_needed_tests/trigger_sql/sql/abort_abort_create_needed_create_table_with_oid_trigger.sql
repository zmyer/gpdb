begin;
CREATE TABLE abort_create_needed_cr_table_with_oid (
    text_col text,
    bigint_col bigint,
    char_vary_col character varying(30),
    numeric_col numeric
) WITH OIDS DISTRIBUTED RANDOMLY;
drop table abort_create_needed_cr_table_with_oid;
commit;
