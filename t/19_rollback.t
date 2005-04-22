#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 12;

BEGIN {
    use_ok('DBI');
}

my $dbh = DBI->connect( 'dbi:Mock:', '', '' );
isa_ok($dbh, 'DBI::db');

ok( $dbh->begin_work, 'begin_work() returns true' );
ok( $dbh->commit, 'commit() returns true' );
ok( $dbh->rollback, 'rollback() returns true' );

my $history = $dbh->{mock_all_history};
ok( @$history == 3, "Correct number of statements" );

is( $history->[0]->statement, 'BEGIN WORK' );
ok( @{$history->[0]->bound_params} == 0, 'No parameters' );

is( $history->[1]->statement, 'COMMIT' );
ok( @{$history->[1]->bound_params} == 0, 'No parameters' );

is( $history->[2]->statement, 'ROLLBACK' );
ok( @{$history->[2]->bound_params} == 0, 'No parameters' );
