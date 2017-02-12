
\echo '--permission denied'
CREATE OR REPLACE FUNCTION pltest.nonsuper_untrustfunc() RETURNS integer AS $$
     my $tmpfile = "/tmp/perlfile";
     open my $fh, '>', $tmpfile or elog(ERROR, qq{could not open the file "$tmpfile": $!});
     print $fh "Testing superuser can execute unsafe function\n";
     close $fh or elog(ERROR, qq{could not close the file "$tmpfile": $!});
     return 1;
$$ LANGUAGE plperlu;

