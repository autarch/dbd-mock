#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 8;

BEGIN {
    use_ok('DBD::Mock');
    use_ok('DBI');
}

my $drh = DBI->install_driver("Mock");
isa_ok($drh, 'DBI::dr');

# make sure we always get the same one back
{
    my $drh2 = DBI->install_driver("Mock");
    isa_ok($drh2, 'DBI::dr');
    
    is($drh, $drh2, '... got the same driver');
}

is($drh->data_sources(), 'DBI:Mock:', '... got the expected data sources');

my $dbh = $drh->connect();
isa_ok($dbh, 'DBI::db');

is($dbh->{Driver}, $drh, '... our driver is as we expect');

$dbh->disconnect();   
