-- start_ignore
SET gp_create_table_random_default_distribution=off;
-- end_ignore
drop table if exists chksum_on_header_sml_ao;
create table chksum_on_header_sml_ao(a int) with (appendonly=true, checksum=true);
insert into chksum_on_header_sml_ao values (1),(1),(1),(-1),(1),(1),(1),(2),(2),(2),(2),(2),(2),(2),(33),(3),(3),(3),(1),(8),(19),(20),(31),(32),(33),(34),(5),(5),(5),(5),(5),(6),(6),(6),(6),(6),(6),(7),(7),(7),(7),(7),(7),(7),(7), (null),(7),(7),(7),(null),(8),(8),(8),(8),(8),(8),(4),(4),(null),(4),(17),(17),(17),(null),(null),(null); 
