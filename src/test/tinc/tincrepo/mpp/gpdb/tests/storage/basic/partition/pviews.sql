drop view partlist cascade;
drop view partrank cascade;
drop view partagain cascade;

create view partlist as
  select
    pt.parrelid::regclass as ptable, 
    pt.parlevel as plevel,
    pt.paristemplate as ptemplate,
    pt.parkind as pkind, 
    pr.parchildrelid::regclass as rchild, 
    pr.parname as rname, 
    pr.parruleord as rrank,
    ppr.parchildrelid::regclass as rparent 
  from 
    pg_partition pt, 
    pg_partition_rule pr
      left join
      pg_partition_rule ppr
      on (pr.parparentrule = ppr.oid)
  where pt.oid = pr.paroid;


create view partrank as
  select 
      p1.schemaname, 
      p1.tablename, 
      p1.partitionschemaname, 
      p1.partitiontablename, 
      p1.partitionname, 
      p1.parentpartitiontablename, 
      p1.parentpartitionname, 
      p1.partitiontype, 
      p1.partitionlevel, 
      case
          when p1.partitiontype <> 'range'::text then null::bigint
          when p1.partitionnodefault > 0 then p1.partitionrank
          when p1.partitionrank = 1 then null::bigint
          else p1.partitionrank - 1
          end as partitionrank, 
      p1.partitionposition, 
      p1.partitionlistvalues, 
      p1.partitionrangestart, 
      case
          when p1.partitiontype = 'range'::text then p1.partitionstartinclusive
          else null::boolean
          end as partitionstartinclusive, p1.partitionrangeend, 
      case
          when p1.partitiontype = 'range'::text then p1.partitionendinclusive
          else null::boolean
          end as partitionendinclusive, 
      p1.partitioneveryclause, 
      p1.parisdefault as partitionisdefault, 
      p1.partitionboundary
  from 
      ( 
          select 
              n.nspname as schemaname, 
              cl.relname as tablename, 
              n2.nspname as partitionschemaname, 
              cl2.relname as partitiontablename, 
              pr1.parname as partitionname, 
              cl3.relname as parentpartitiontablename, 
              pr2.parname as parentpartitionname, 
              case
                  when pp.parkind = 'h'::"char" then 'hash'::text
                  when pp.parkind = 'r'::"char" then 'range'::text
                  when pp.parkind = 'l'::"char" then 'list'::text
                  else null::text
                  end as partitiontype, 
              pp.parlevel as partitionlevel, 
              pr1.parruleord as partitionposition, 
              
              case
                  when pp.parkind != 'r'::"char" or pr1.parisdefault then null::bigint
                  else
                      rank() over(
                      partition by pp.oid, cl.relname, pp.parlevel, cl3.relname
                      order by pr1.parisdefault, pr1.parruleord) 
                  end as partitionrank, 
                  
              pg_get_expr(pr1.parlistvalues, pr1.parchildrelid) as partitionlistvalues, 
              pg_get_expr(pr1.parrangestart, pr1.parchildrelid) as partitionrangestart, 
              pr1.parrangestartincl as partitionstartinclusive, 
              pg_get_expr(pr1.parrangeend, pr1.parchildrelid) as partitionrangeend, 
              pr1.parrangeendincl as partitionendinclusive, 
              pg_get_expr(pr1.parrangeevery, pr1.parchildrelid) as partitioneveryclause, 
              min(pr1.parruleord) over(
                  partition by pp.oid, cl.relname, pp.parlevel, cl3.relname
                  order by pr1.parruleord) as partitionnodefault, 
              pr1.parisdefault, 
              pg_get_partition_rule_def(pr1.oid, true) as partitionboundary
          from 
              pg_namespace n, 
              pg_namespace n2, 
              pg_class cl, 
              pg_class cl2, 
              pg_partition pp, 
              pg_partition_rule pr1
                  left join 
              pg_partition_rule pr2 on pr1.parparentrule = pr2.oid
                  left join 
              pg_class cl3 on pr2.parchildrelid = cl3.oid
      where 
          pp.paristemplate = false and 
          pp.parrelid = cl.oid and 
          pr1.paroid = pp.oid and 
          cl2.oid = pr1.parchildrelid and 
          cl.relnamespace = n.oid and 
          cl2.relnamespace = n2.oid) p1;


create view partagain as
  select 
      p1.schemaname, 
      p1.tablename, 
      p1.partitionschemaname, 
      p1.partitiontablename, 
      p1.partitionname, 
      p1.parentpartitiontablename, 
      p1.parentpartitionname, 
      p1.partitiontype, 
      p1.partitionlevel, 
      case
          when p1.partitiontype <> 'range'::text then null::bigint
          when p1.partitionnodefault > 0 then p1.partitionrank
          when p1.partitionrank = 0 then null::bigint
          else p1.partitionrank
          end as partitionrank, 
      p1.partitionposition, 
      p1.partitionlistvalues, 
      p1.partitionrangestart, 
      case
          when p1.partitiontype = 'range'::text then p1.partitionstartinclusive
          else null::boolean
          end as partitionstartinclusive, p1.partitionrangeend, 
      case
          when p1.partitiontype = 'range'::text then p1.partitionendinclusive
          else null::boolean
          end as partitionendinclusive, 
      p1.partitioneveryclause, 
      p1.parisdefault as partitionisdefault, 
      p1.partitionboundary
  from 
      ( 
          select 
              n.nspname as schemaname, 
              cl.relname as tablename, 
              n2.nspname as partitionschemaname, 
              cl2.relname as partitiontablename, 
              pr1.parname as partitionname, 
              cl3.relname as parentpartitiontablename, 
              pr2.parname as parentpartitionname, 
              case
                  when pp.parkind = 'h'::"char" then 'hash'::text
                  when pp.parkind = 'r'::"char" then 'range'::text
                  when pp.parkind = 'l'::"char" then 'list'::text
                  else null::text
                  end as partitiontype, 
              pp.parlevel as partitionlevel, 
              pr1.parruleord as partitionposition, 
              
              case
                  when pp.parkind != 'r'::"char" or pr1.parisdefault then null::bigint
                  else
                      rank() over(
                      partition by pp.oid, cl.relname, pp.parlevel, cl3.relname
                      order by pr1.parisdefault, pr1.parruleord) 
                  end as partitionrank, 
                  
              pg_get_expr(pr1.parlistvalues, pr1.parchildrelid) as partitionlistvalues, 
              pg_get_expr(pr1.parrangestart, pr1.parchildrelid) as partitionrangestart, 
              pr1.parrangestartincl as partitionstartinclusive, 
              pg_get_expr(pr1.parrangeend, pr1.parchildrelid) as partitionrangeend, 
              pr1.parrangeendincl as partitionendinclusive, 
              pg_get_expr(pr1.parrangeevery, pr1.parchildrelid) as partitioneveryclause, 
              min(pr1.parruleord) over(
                  partition by pp.oid, cl.relname, pp.parlevel, cl3.relname
                  order by pr1.parruleord) as partitionnodefault, 
              pr1.parisdefault, 
              pg_get_partition_rule_def(pr1.oid, true) as partitionboundary
          from 
              pg_namespace n, 
              pg_namespace n2, 
              pg_class cl, 
              pg_class cl2, 
              pg_partition pp, 
              pg_partition_rule pr1
                  left join 
              pg_partition_rule pr2 on pr1.parparentrule = pr2.oid
                  left join 
              pg_class cl3 on pr2.parchildrelid = cl3.oid
      where 
          pp.paristemplate = false and 
          pp.parrelid = cl.oid and 
          pr1.paroid = pp.oid and 
          cl2.oid = pr1.parchildrelid and 
          cl.relnamespace = n.oid and 
          cl2.relnamespace = n2.oid) p1;
