use strict;

use Test::More tests => 6;

BEGIN {
    use_ok('DBD::Mock');  
    use_ok('DBI');  
}

# test misc. attributes

{
    my $dbh = DBI->connect('DBI:Mock:', 'user', 'pass');
    isa_ok($dbh, 'DBI::db'); 
    
    $dbh->{mock_add_resultset} = {
        sql => 'SELECT foo FROM bar',
        results => DBD::Mock->NULL_RESULTSET,
        failure => [ 5, 'Ooops!' ],
    };

    $dbh->{PrintError} = 0;
    $dbh->{RaiseError} = 1;

    my $sth = eval { $dbh->prepare('SELECT foo FROM bar') };
    ok(!$@, '$sth handle prepared correctly');
    isa_ok($sth, 'DBI::st');

    eval { $sth->execute() };
    ok( $@, '$sth handled executed and died' );
}
