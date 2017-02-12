-- @author ramans2
-- @created 2014-03-14 12:00:00
-- @modified 2014-03-14 12:00:00
-- @gpdiff True
-- @description  Check segment logs for ERROR/PANIC messages
-- @product_version gpdb:[4.3.0.0-MAIN]

-- SQL to check segment logs for ERROR or PANIC messages
select logseverity, logstate, logmessage from gp_toolkit.__gp_log_segment_ext where logstate = 'XX000' and  logtime >= (select logtime from gp_toolkit.__gp_log_master_ext where logmessage like 'statement: select 20785 as explain_test;'order by logtime desc limit 1) order by logtime desc limit 1;
