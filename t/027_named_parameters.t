use strict;
use warnings;

use Test::More tests => 3;

BEGIN {
    use_ok('DBD::Mock');
}

my $dbh = DBI->connect( 'DBI:Mock:', '', '' );

my $session = DBD::Mock::Session->new(
    (
        {
            statement    => 'SELECT * FROM foo WHERE id = ? and is_active = ?',
            bound_params => [ '613', 'yes' ],
            results      => [ ['foo'], [10] ]
        },
        {
            statement =>
              'SELECT * FROM foo WHERE id = :id and is_active = :active',
            bound_params => ['101', 'no' ],
            results => [ ['bar'], [15] ]
        },
    )
);

$dbh->{mock_session} = $session;

my $sth = $dbh->prepare('SELECT * FROM foo WHERE id = ? and is_active = ?');
$sth->bind_param( 1 => '613' );
$sth->bind_param( 2 => 'yes' );
ok( $sth->execute, 'Execute using positional parameters' );
$sth->finish;

$sth =
  $dbh->prepare('SELECT * FROM foo WHERE id = :id and is_active = :active');
$sth->bind_param( ':id'     => '101' );
$sth->bind_param( ':active' => 'no' );
ok( $sth->execute, 'Execute using named parameters' );
