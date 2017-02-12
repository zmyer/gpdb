create schema hashagg_spill;
set search_path to hashagg_spill;

-- start_ignore
create language plpythonu;
-- end_ignore

-- set workfile is created to true if all segment did it.
create or replace function hashagg_spill.is_workfile_created(explain_query text)
returns setof int as
$$
import re
query = "select count(*) as nsegments from gp_segment_configuration where role='p' and content >= 0;"
rv = plpy.execute(query)
nsegments = int(rv[0]['nsegments'])
rv = plpy.execute(explain_query)
search_text = 'Work_mem used'
result = []
for i in range(len(rv)):
    cur_line = rv[i]['QUERY PLAN']
    if search_text.lower() in cur_line.lower():
        p = re.compile('.+\((seg[\d]+).+ Workfile: \(([\d+]) spilling\)')
        m = p.match(cur_line)
        workfile_created = int(m.group(2))
        cur_row = int(workfile_created == nsegments)
        result.append(cur_row)
return result
$$
language plpythonu;

create table testhagg (i1 int, i2 int, i3 int, i4 int);
insert into testhagg select i,i,i,i from
	(select generate_series(1, nsegments * 15000) as i from
	(select count(*) as nsegments from gp_segment_configuration where role='p' and content >= 0) foo) bar;

set statement_mem="1800";
set gp_resqueue_print_operator_memory_limits=on;

-- the number of rows returned by the query varies depending on the number of segments, so
-- only print the first 10
select * from (select max(i1) from testhagg group by i2) foo order by 1 limit 10;
select * from hashagg_spill.is_workfile_created('explain analyze select max(i1) from testhagg group by i2;');
select * from hashagg_spill.is_workfile_created('explain analyze select max(i1) from testhagg group by i2 limit 45000;');

drop schema hashagg_spill cascade;
