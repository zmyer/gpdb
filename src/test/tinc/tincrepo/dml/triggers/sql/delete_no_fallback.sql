SELECT * FROM dml_trigger_table_1 order by 2;

--start_ignore
SET client_min_messages='log';
DELETE FROM dml_trigger_table_1 where age=10;
SET client_min_messages='notice';
--end_ignore

SELECT * FROM dml_trigger_table_1 order by 2;

\!grep Planner %MYD%/output/delete_no_fallback_orca.out
