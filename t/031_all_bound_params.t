use 5.006;

use strict;
use warnings;
use Test::Exception;
use Test::More tests => 12;
use Data::Dumper;

BEGIN {
    use_ok('DBD::Mock');
    use_ok('DBI');
}

my $dbh = DBI->connect( 'DBI:Mock:', '', '', { RaiseError => 1 } );


lives_ok(
    sub {
        $dbh->{mock_add_resultset} = [];
        my $sth = $dbh->prepare("INSERT INTO foo (bar) VALUES (?)");

        $sth->bind_param(1,'1');
        $sth->execute();

        {
            my $st_track = $dbh->{mock_all_history}->[0];
            is($st_track->times_executed(),1,'... Should know it was executed once');
            is($st_track->{all_bound_params}->[0]->[0],'1','... should have the bound parameter tracked correctly in all_bound_params');
            is($st_track->{bound_params}->[0],'1','... should have the bound parameter tracked correctly in bound_params');
        }

        $sth->bind_param(1,'2');
        $sth->execute();

        {
            my $st_track = $dbh->{mock_all_history}->[0];
            is($st_track->times_executed(),2,'... Should know it was executed twice');
            is($st_track->{all_bound_params}->[1]->[0],'2','... should have the bound parameter tracked correctly in all_bound_params');
            is($st_track->{bound_params}->[0],'2','... should have the bound parameter tracked correctly in bound_params');
        }

        $sth->bind_param(1,'3');
        $sth->execute();

        {
            my $st_track = $dbh->{mock_all_history}->[0];
            is($st_track->times_executed(),3,'... Should know it was executed thrice');
            is($st_track->{all_bound_params}->[2]->[0],'3','... should have the bound parameter tracked correctly in all_bound_params');
            is($st_track->{bound_params}->[0],'3','... should have the bound parameter tracked correctly in bound_params');
        }
    },
    'Successfully execute prepared insert statement multiple times'
);

