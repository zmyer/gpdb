-- @Description Tests that deleting the same tuple twice within the same
-- commands works fine.
-- 

DELETE FROM foo USING BAR WHERE foo.b = bar.b AND foo.a = bar.a AND
(bar.a = 10 OR bar.a = 40000 OR bar.a = 20000);

-- MPP-23546: out of order tuples spanning more than one visimap
-- entry.  We have verified through gdb that the following delete
-- statement results in one visimap entry encountered more than once
-- in appendonly_delete_finish() code path.  This is because values 12
-- and 1001 of foo.a are covered by one visimap entry where as the
-- value 80001 is covered by a different visimap entry.  Assumption:
-- the values are inserted in increasing order by a single insert
-- transaction.

-- Ensure that tuples to be deleted are from the same GPDB segment.
-- This query should return the same output irrespective of GPDB
-- configuration (1 segdb, 2 or more segdbs).
SELECT distinct(a) FROM foo
WHERE gp_segment_id = 0 AND foo.a IN (12, 80001, 1001)
ORDER BY a;

DELETE FROM foo USING bar WHERE foo.b = bar.b AND foo.a = bar.a AND
(bar.a = 12 OR bar.a = 80001 OR bar.a = 1001);

