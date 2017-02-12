CREATE or REPLACE function pltest.lineitem_record (
OUT L_ORDERKEY INT8,
OUT L_PARTKEY INTEGER,
OUT L_SUPPKEY INTEGER,
OUT L_LINENUMBER integer,
OUT L_QUANTITY decimal,
OUT L_EXTENDEDPRICE decimal,
OUT L_DISCOUNT decimal,
OUT L_TAX decimal,
OUT L_RETURNFLAG CHAR(1),
OUT L_LINESTATUS CHAR(1),
OUT L_SHIPDATE date,
OUT L_COMMITDATE date,
OUT L_RECEIPTDATE date,
OUT L_SHIPINSTRUCT CHAR(25),
OUT L_SHIPMODE CHAR(10),
OUT L_COMMENT VARCHAR(44) ) RETURNS SETOF RECORD as $$
my $rv = spi_exec_query("select * from pltest.lineitem where l_returnflag in ('A');");
my $status = $rv->{status};
my $nrows = $rv->{processed};
foreach my $rn (0 .. $nrows - 1) {
my $row = $rv->{rows}[$rn];
return_next($row);
}
return undef;
$$ language PLPERL;

SELECT count(*) FROM pltest.lineitem_record();

DROP FUNCTION pltest.lineitem_record();

/* Commented case
CREATE or REPLACE function pltest.lineitem_record (
OUT L_ORDERKEY INT8,
OUT L_PARTKEY INTEGER,
OUT L_SUPPKEY INTEGER,
OUT L_LINENUMBER integer,
OUT L_QUANTITY decimal,
OUT L_EXTENDEDPRICE decimal,
OUT L_DISCOUNT decimal,
OUT L_TAX decimal,
OUT L_RETURNFLAG CHAR(1),
OUT L_LINESTATUS CHAR(1),
OUT L_SHIPDATE date,
OUT L_COMMITDATE date,
OUT L_RECEIPTDATE date,
OUT L_SHIPINSTRUCT CHAR(25),
OUT L_SHIPMODE CHAR(10),
OUT L_COMMENT VARCHAR(44) ) RETURNS SETOF RECORD as $$
my $rv = spi_exec_query("select * from pltest.lineitem;");
my $status = $rv->{status};
my $nrows = $rv->{processed};
foreach my $rn (0 .. $nrows - 1) {
my $row = $rv->{rows}[$rn];
return_next($row);
}
return undef;
$$ language PLPERL;

SELECT count(*) FROM pltest.lineitem_record();

DROP FUNCTION pltest.lineitem_record();

*/


