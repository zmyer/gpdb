-- @author prabhd 
-- @created 2012-12-05 12:00:00 
-- @modified 2012-12-05 12:00:00 
-- @tags dml
-- @product_version gpdb: [4.3-]
-- @gucs gp_autostats_mode=none;test_print_direct_dispatch_info=true
-- @db_name dmldb
-- @description Negative test for direct dispatch. Master only table
\echo --start_ignore
set gp_enable_column_oriented_table=on;
\echo --end_ignore
INSERT INTO m VALUES(1,1,1);
