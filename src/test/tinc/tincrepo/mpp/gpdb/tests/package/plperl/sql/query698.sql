CREATE OR REPLACE FUNCTION kw_match_init() RETURNS void AS $$
        
        $rv = spi_exec_query('SELECT * FROM stop_word');
        $nrows = $rv->{processed};
        foreach my $i (0..$nrows) {
                my $key=$rv->{rows}[$i]->{'word'};
                $key='stopword'.$key;
                $_SHARED{$key}=1;
        }
        
        $$ LANGUAGE plperl;

drop function kw_match_init();
