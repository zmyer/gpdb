CREATE or REPLACE function pltest.lineitem_compositetype () RETURNS SETOF pltest.LINEITEM_TYPE as $$
        my $rv = spi_exec_query("select * from pltest.lineitem where l_returnflag in ('A');");
        my $status = $rv->{status};
        my $nrows = $rv->{processed};
        foreach my $rn (0 .. $nrows - 1) {
        my $row = $rv->{rows}[$rn];
                return_next($row);
        }
        return undef;
$$ language PLPERL;


SELECT count(*) FROM pltest.lineitem_compositetype();

DROP FUNCTION pltest.lineitem_compositetype();

/* comment cases
CREATE or REPLACE function pltest.lineitem_compositetype () RETURNS SETOF pltest.LINEITEM_TYPE as $$
        my $rv = spi_exec_query("select * from pltest.lineitem;");
        my $status = $rv->{status};
        my $nrows = $rv->{processed};
        foreach my $rn (0 .. $nrows - 1) {
        my $row = $rv->{rows}[$rn];
                return_next($row);
        }
        return undef;
$$ language PLPERL;


SELECT count(*) FROM pltest.lineitem_compositetype();

DROP FUNCTION pltest.lineitem_compositetype();
*/ 



