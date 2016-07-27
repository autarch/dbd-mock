use strict;
use warnings;

use Test::More;
use Test::Exception; 

# test style cribbed from t/013_st_execute_bound_params.t

BEGIN {
    use_ok('DBD::Mock');  
    use_ok('DBI');
}

my $sql = 'INSERT INTO staff (first_name, last_name, dept) VALUES(?, ?, ?)';

{
    my $dbh = DBI->connect( 'DBI:Mock:', '', '' );
    my $sth = eval { $dbh->prepare( $sql ) };

    # taken from: https://metacpan.org/module/DBI#Statement-Handle-Methods
    $dbh->{RaiseError} = 1;        # save having to check each method call
    $sth = $dbh->prepare($sql);

    $sth->bind_param_array(1, [ 'John', 'Mary', 'Tim' ]);
    $sth->bind_param_array(2, [ 'Booth', 'Todd', 'Robinson' ]);
    # TODO: $sth->bind_param_array(3, "SALES"); # scalar will be reused for each row

    eval {
        $sth->execute_array( { ArrayTupleStatus => \my @tuple_status } );
    };
    ok( ! $@, 'Called execute_array() ok' )
        or diag $@;
}

subtest 'execute_array with multiple bind values' => sub {
    my $dbh = DBI->connect( 'DBI:Mock:', '', '' );
    my $qry = qq{ insert into mytable (foo,bar,baz) values (?,?,?) };                                                                                            
    my $sqlh = $dbh->prepare($qry);                                                                                                                                                 
    $sqlh->execute_array( { ArrayTupleStatus => \my @tuple_status },                                                                                                         
        [1,2,3],
        [4,5,6],
        [7,8,9]
    );
    $sqlh->finish();                                                                                                                                                             

    #interrogate the statement tracker
    my $history = $dbh->{mock_all_history}->[0];                                                                                                                                     
    is($history->{bound_params}->[0],3,'execute_array(\%attrs,bind_values) should bind parameters column-wise when provided, 1st column first');
    is($history->{bound_params}->[1],6,'execute_array(\%attrs,bind_values) should bind parameters column-wise when provided, 2st column second');
    is($history->{bound_params}->[2],9,'execute_array(\%attrs,bind_values) should bind parameters column-wise when provided, 3st column third');
};

subtest 'execute_array with single bind values' => sub {
    my $dbh = DBI->connect( 'DBI:Mock:', '', '' );
    my $qry = qq{ insert into mytable (foo,bar,baz) values (?,?,?) };                                                                                            
    my $sqlh = $dbh->prepare($qry);                                                                                                                                                 
    $sqlh->execute_array( { ArrayTupleStatus => \my @tuple_status },                                                                                                         
        [1],
        [2],
        [3]
    );
    $sqlh->finish();                                                                                                                                                             

    #interrogate the statement tracker
    my $history = $dbh->{mock_all_history}->[0];                                                                                                                                     
    is($history->{bound_params}->[0],1,'execute_array(\%attrs,bind_values) should bind parameters column-wise when provided, 1st column first');
    is($history->{bound_params}->[1],2,'execute_array(\%attrs,bind_values) should bind parameters column-wise when provided, 2st column second');
    is($history->{bound_params}->[2],3,'execute_array(\%attrs,bind_values) should bind parameters column-wise when provided, 3st column third');
};

subtest 'execute_array should complain if not provided array refs after \%attrs' => sub {
    my $dbh = DBI->connect( 'DBI:Mock:', '', '' );
    $dbh->{RaiseError} = 1;
    $dbh->{PrintError} = 0;
    my $qry = qq{ insert into mytable (foo,bar,baz) values (?,?,?) };                                                                                            
    my $sqlh = $dbh->prepare($qry);                                                                                                                                                 
    throws_ok { $sqlh->execute_array( { ArrayTupleStatus => \my @tuple_status },1,2,3); } qr/execute_array expects the 3rd param onwards to be array references/,
        'Should complain if you do pass non-array refs for the 3rd parameter' ;
};

done_testing;
