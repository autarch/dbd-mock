#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 10;

BEGIN {
    use_ok('DBD::Mock');  
	use_ok('DBI');
}

my $sql = 'SELECT * FROM foo WHERE bar = ? AND baz = ?';

{
    my $dbh = DBI->connect( 'DBI:Mock:', '', '' );
    my $sth = eval { $dbh->prepare( $sql ) };
    eval {
        $sth->bind_param( 2, 'bar' );
        $sth->bind_param( 1, 'baz' );
    };
    ok( ! $@, 'Parameters bound to statement handle with bind_param()' );
    eval { $sth->execute() };
    ok( ! $@, 'Called execute() ok (empty, after bind_param calls)' );
    my $t_params = $sth->{mock_my_history}->bound_params;
    is( scalar @{ $t_params }, 2,
        'Correct number of parameters bound (method on tracker)' );
    is( $t_params->[0], 'baz',
        'Statement handle stored bound parameter from bind_param() (method on tracker)' );
    is( $t_params->[1], 'bar',
        'Statement handle stored bound parameter from bind_param() (method on tracker)' );
    my $a_params = $sth->{mock_params};
    is( scalar @{ $a_params }, 2,
        'Correct number of parameters bound (attribute)' );
    is( $a_params->[0], 'baz',
        'Statement handle stored bound parameter from bind_param() (attribute)' );
    is( $a_params->[1], 'bar',
        'Statement handle stored bound parameter from bind_param() (attribute)' );
}
