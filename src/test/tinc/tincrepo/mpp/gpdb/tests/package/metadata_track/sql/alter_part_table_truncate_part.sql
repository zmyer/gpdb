CREATE TABLE mdt_part_tbl_partrange (
        unique1         int4,
        unique2         int4
) partition by range (unique1)
( partition aa start (0) end (500) every (100), default partition default_part );


CREATE TABLE mdt_part_tbl_partrange_A (
        unique1         int4,
        unique2         int4);

alter table mdt_part_tbl_partrange truncate partition for (rank(1));


drop table mdt_part_tbl_partrange;
drop table mdt_part_tbl_partrange_A;
