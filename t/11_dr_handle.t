#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 20;

BEGIN {
    use_ok('DBD::Mock');
    use_ok('DBI');
}

my $drh = DBI->install_driver("Mock");
isa_ok($drh, 'DBI::dr');

is($drh->{Name}, 'Mock', '... got the right name');
is($drh->{Version}, $DBD::Mock::VERSION, '... got the right version');
is($drh->{Attribution}, 
   'DBD Mock driver by Chris Winters & Stevan Little (orig. from Tim Bunce)', 
   '... got the right attribution');

# make sure we always get the same one back
{
    my $drh2 = DBI->install_driver("Mock");
    isa_ok($drh2, 'DBI::dr');
    
    is($drh, $drh2, '... got the same driver');
}

is($drh->data_sources(), 'DBI:Mock:', '... got the expected data sources');

{ # connect through the driver handle
    my $dbh = $drh->connect();
    isa_ok($dbh, 'DBI::db');
    
    is($dbh->{Driver}, $drh, '... our driver is as we expect');
    
    $dbh->disconnect();   
}

{ # check the mock_connect_fail attribute
    cmp_ok($drh->{mock_connect_fail}, '==', 0, '... the default is set not to fail');

    $drh->{mock_connect_fail} = 1;
    cmp_ok($drh->{mock_connect_fail}, '==', 1, '... we are set to fail');
    
    eval {
        DBI->connect('dbi:Mock:', '', '', { RaiseError => 1, PrintError => 0 });
    };
    ok($@, '... could not connect (as expected)');
    like($@, 
         qr/^DBI connect\(\'\'\,\'\'\,\.\.\.\) failed\: Could not connect to mock database/, #'
         '... got the error we expected too');
    
    $drh->{mock_connect_fail} = 0;
    cmp_ok($drh->{'mock_connect_fail'}, '==', 0, '... we are set not to fail');
    
    my $dbh;
    eval {
        $dbh = DBI->connect('dbi:Mock:', '', '', { RaiseError => 1, PrintError => 0 });
    };
    ok(!$@, '... could connect (as expected)');
    isa_ok($dbh, 'DBI::db');
}

{ # check other attributes
    $drh->{mock_nothing} = 100;
    ok(!defined($drh->{mock_nothing}), '... we only support our attributes');

    $drh->{nothing} = 100;
    ok(!defined($drh->{nothing}), '... we only support our attributes');
}
