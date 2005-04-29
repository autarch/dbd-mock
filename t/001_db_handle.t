use strict;

use Test::More tests => 16;

BEGIN {
    use_ok('DBD::Mock');  
    use_ok('DBI');  
}

# test misc. attributes

{
    my $dbh = DBI->connect('DBI:Mock:', 'user', 'pass');
    isa_ok($dbh, 'DBI::db'); 
    
    is($dbh->{Name}, '', '... if no db-name is given');
    
    # DBI will handle attributes with 'private_', 'dbi_' or ,
    # 'dbd_' prefixes but all others, we need to handle.
    
    $dbh->{mysql_insertid} = 10;
    cmp_ok($dbh->{mysql_insertid}, '==', 10, '... this attribute should be 10');
    
    # DBI will handle these
    
    $dbh->{private_insert_id} = 15;
    cmp_ok($dbh->{private_insert_id}, '==', 15, '... this attribute should be 15');    
    
    $dbh->{dbi_attribute} = 2000;
    cmp_ok($dbh->{dbi_attribute}, '==', 2000, '... this attribute should be 2000');  
    
    $dbh->{dbd_attr} = 15_000;
    cmp_ok($dbh->{dbd_attr}, '==', 15_000, '... this attribute should be 15,000');  
    
    $dbh->disconnect();     
}   

# test setting attributes post-connect

{
    
    my $dbh = DBI->connect( 'DBI:Mock:', '', '' );
    $dbh->{RaiseError} = 1;
    $dbh->{PrintError} = 1;
    $dbh->{AutoCommit} = 1;
   
    cmp_ok( $dbh->{RaiseError}, '==', 1,
        'RaiseError DB attribute set after connect()' );
    cmp_ok( $dbh->{PrintError}, '==', 1,
        'PrintError DB attribute set after connect()' );
    cmp_ok( $dbh->{AutoCommit}, '==', 1,
        'AutoCommit DB attribute set after connect()' );
            
    $dbh->disconnect();       
}

# test setting them during connect

{
    my $dbh = DBI->connect( 'DBI:Mock:', '', '',
                            { RaiseError => 1,
                              PrintError => 1,
                              AutoCommit => 1 } );
    cmp_ok( $dbh->{RaiseError}, '==', 1,
        'RaiseError DB attribute set in connect()' );
    cmp_ok( $dbh->{PrintError}, '==', 1,
        'PrintError DB attribute set in connect()' );
    cmp_ok( $dbh->{AutoCommit}, '==', 1,
        'AutoCommit DB attribute set in connect()' );

    $dbh->disconnect();   
}


{
    my $dbh = DBI->connect( 'DBI:Mock:', '', '' );
    is_deeply(
        [ $dbh->data_sources() ],
        [ 'DBI:Mock:' ],
        '... got the right data sources');
        
    $dbh->{'mock_add_data_sources'} = 'foo';
    
    is_deeply(
        [ $dbh->data_sources() ],
        [ 'DBI:Mock:', 'DBI:Mock:foo' ],
        '... got the right data sources');

}
