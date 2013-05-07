use strict;

use Test::More tests => 8;

BEGIN {
    use_ok('DBD::Mock');
    use_ok('DBI');
}

{
    my $dbh = DBI->connect('dbi:Mock:', '', '', { RaiseError => 1, PrintError => 0 });
    isa_ok($dbh, 'DBI::db');
    
    my $session = DBD::Mock::Session->new((
        {
            statement    => 'SELECT foo FROM bar WHERE baz = ?',
            bound_params => [ qr/\d+/ ],
            results      => [[ 'foo' ], [ 10 ]]
        },
        {
            statement    => 'SELECT bar FROM foo WHERE baz = ?',
            bound_params => [ qr/\d\d\d/ ],
            results      => [[ 'bar' ], [ 15 ]]
        },
    ));
    isa_ok($session, 'DBD::Mock::Session');
    
    $dbh->{mock_session} = $session;
    
    eval {
        my $sth = $dbh->prepare('SELECT foo FROM bar WHERE baz = ?');
        $sth->execute(100);
        my ($result) = $sth->fetchrow_array();
        is($result, 10, '... got the right value');        
    };
    ok(!$@, '... everything worked as planned'.$@);
    
    eval {
        my $sth = $dbh->prepare('SELECT bar FROM foo WHERE baz = ?');
        $sth->execute(125);
        my ($result) = $sth->fetchrow_array();
        is($result, 15, '... got the right value');
    };
    ok(!$@, '... everything worked as planned');

    # Shuts up warning when object is destroyed
    undef $dbh->{mock_session};
}