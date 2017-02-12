drop external table if exists ext_lineitem;
CREATE EXTERNAL TABLE EXT_LINEITEM ( L_ORDERKEY    INTEGER ,
                             L_PARTKEY     INTEGER ,
                             L_SUPPKEY     INTEGER ,
                             L_LINENUMBER  INTEGER ,
                             L_QUANTITY    DECIMAL(15,2) ,
                             L_EXTENDEDPRICE  DECIMAL(15,2) ,
                             L_DISCOUNT    DECIMAL(15,2) ,
                             L_TAX         DECIMAL(15,2) ,
                             L_RETURNFLAG  CHAR(1) ,
                             L_LINESTATUS  CHAR(1) ,
                             L_SHIPDATE    DATE ,
                             L_COMMITDATE  DATE ,
                             L_RECEIPTDATE DATE ,
                             L_SHIPINSTRUCT CHAR(25) ,
                             L_SHIPMODE     CHAR(10) ,
                             L_COMMENT      VARCHAR(44) )
location ('gpfdist://@hostname@:@gp_port@/lineitem.tbl.small.null' )
FORMAT 'csv' (delimiter '|') ;

SELECT COALESCE(l_comment, 'NULL!') from ext_lineitem;

drop external table if exists ext_lineitem;
CREATE EXTERNAL TABLE EXT_LINEITEM ( L_ORDERKEY    INTEGER ,
                             L_PARTKEY     INTEGER ,
                             L_SUPPKEY     INTEGER ,
                             L_LINENUMBER  INTEGER ,
                             L_QUANTITY    DECIMAL(15,2) ,
                             L_EXTENDEDPRICE  DECIMAL(15,2) ,
                             L_DISCOUNT    DECIMAL(15,2) ,
                             L_TAX         DECIMAL(15,2) ,
                             L_RETURNFLAG  CHAR(1) ,
                             L_LINESTATUS  CHAR(1) ,
                             L_SHIPDATE    DATE ,
                             L_COMMITDATE  DATE ,
                             L_RECEIPTDATE DATE ,
                             L_SHIPINSTRUCT CHAR(25) ,
                             L_SHIPMODE     CHAR(10) ,
                             L_COMMENT      VARCHAR(44) )
location ('gpfdist://@hostname@:@gp_port@/lineitem.tbl.small.null' )
FORMAT 'csv' (delimiter '|' force not null l_comment) ;

SELECT COALESCE(l_comment, 'NULL!') from ext_lineitem;

drop external table if exists test_quote1;
drop external table if exists test_quote2;
CREATE EXTERNAL TABLE test_quote1( i text)
location ('file://@hostname@@gpfdist_datadir@/quote.csv' )
FORMAT 'csv' (delimiter '|' quote '''') ;

select * from test_quote1;

CREATE EXTERNAL TABLE test_quote2( i text)
location ('file://@hostname@@gpfdist_datadir@/quote.csv' )
FORMAT 'csv' (delimiter '|' quote '"') ;

select * from test_quote2 order by i;

drop external table if exists e3;
create external web table e3(c1 int, c2 int) execute 'echo 1, 1' format 'CSV';

alter table e3 drop column c2;

alter table e3 add column c2 int;

drop external table if exists doc_blah;
CREATE EXTERNAL WEB TABLE doc_blah (blah text)
EXECUTE 'BLAH=blah-blah-blah; export BLAH; echo $BLAH' on segment 0
FORMAT 'TEXT';
select * from doc_blah;
