#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 11;

BEGIN {
    use_ok('DBD::Mock');  
	use_ok('DBI');
}

# test the ability to overwrite a 
# hash based 'mock_add_resultset'
# and have it work as expected

my $dbh = DBI->connect('dbi:Mock:', '', '');
isa_ok($dbh, 'DBI::db');

$dbh->{mock_add_resultset} = {
    sql => 'SELECT foo FROM bar',
    results => [[ 'foo' ], [ 10 ]]
};

{
    my $sth = $dbh->prepare('SELECT foo FROM bar');
    isa_ok($sth, 'DBI::st');

    $sth->execute();
    my ($result) = $sth->fetchrow_array();
    
    cmp_ok($result, '==', 10, '... got the result we expected');
    
    $sth->finish();
}

$dbh->{mock_add_resultset} = {
    sql => 'SELECT foo FROM bar',
    results => [[ 'foo' ], [ 50 ]]
};

{
    my $sth = $dbh->prepare('SELECT foo FROM bar');
    isa_ok($sth, 'DBI::st');

    $sth->execute();
    my ($result) = $sth->fetchrow_array();

    cmp_ok($result, '==', 50, '... got the result we expected');
    
    $sth->finish();
}

# get it again
{
    my $sth = $dbh->prepare('SELECT foo FROM bar');
    isa_ok($sth, 'DBI::st');

    $sth->execute();
    my ($result) = $sth->fetchrow_array();

    cmp_ok($result, '==', 50, '... got the result we expected');
    
    $sth->finish();
}

# and one more time for good measure
{
    my $sth = $dbh->prepare('SELECT foo FROM bar');
    isa_ok($sth, 'DBI::st');

    $sth->execute();
    my ($result) = $sth->fetchrow_array();

    cmp_ok($result, '==', 50, '... got the result we expected');
    
    $sth->finish();
}