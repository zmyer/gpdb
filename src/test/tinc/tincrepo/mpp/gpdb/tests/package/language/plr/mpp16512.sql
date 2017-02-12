\echo '-- start_ignore'
create language plr;
drop function mpp16512test();
\echo '-- end_ignore'

CREATE OR REPLACE FUNCTION mpp16512test() RETURNS TEXT AS
$$
    v1 <- c(1,1,1,1,1,1,1,1,1,1,3,3,3,3,3,4,5,6)
    v2 <- c(1,2,1,1,1,1,2,1,2,1,3,4,3,3,3,4,6,5)
    v3 <- c(3,3,3,3,3,1,1,1,1,1,1,1,1,1,1,5,4,6)
    v4 <- c(3,3,4,3,3,1,1,2,1,1,1,1,2,1,1,5,6,4)
    v5 <- c(1,1,1,1,1,3,3,3,3,3,1,1,1,1,1,6,4,5)
    v6 <- c(1,1,1,2,1,3,3,3,4,3,1,1,1,2,1,6,5,4)
    m1 <- cbind(v1,v2,v3,v4,v5,v6)
    factanal(m1, factors = 3, rotation = "promax")
    return ('done');
$$
LANGUAGE plr;
select * from test();
