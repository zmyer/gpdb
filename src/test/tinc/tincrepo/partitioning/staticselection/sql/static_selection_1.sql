-- @author elhela
-- @created 2014-10-14 12:00:00 
-- @modified 2014-10-14 12:00:00
-- @description Tests for static partition selection (MPP-24709, GPSQL-2879)
-- @tags MPP-24709 GPSQL-2879 ORCA HAWQ
-- @product_version gpdb: [4.3.3.0-], hawq: [1.2.2.0-]
-- @optimizer_mode on
-- @gpopt 1.499

select get_selected_parts('explain select * from foo;');

select * from foo;
