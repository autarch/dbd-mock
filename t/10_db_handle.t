#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 22;

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
    my $trace_log = 'tmp_dbi_trace.log';
    
    my $dbh = DBI->connect( 'DBI:Mock:', '', '' );
    $dbh->{RaiseError} = 1;
    $dbh->{PrintError} = 1;
    $dbh->{AutoCommit} = 1;
    $dbh->trace( 2, $trace_log );    
    ok(-f $trace_log, '... the trace log file has been created');    
    cmp_ok( $dbh->{RaiseError}, '==', 1,
        'RaiseError DB attribute set after connect()' );
    cmp_ok( $dbh->{PrintError}, '==', 1,
        'PrintError DB attribute set after connect()' );
    cmp_ok( $dbh->{AutoCommit}, '==', 1,
        'AutoCommit DB attribute set after connect()' );
    cmp_ok( $dbh->{TraceLevel}, '==', 2,
        'TraceLevel DB attribute set after connect()' );
 
     cmp_ok(unlink($trace_log), '==', 1, "... removing the trace log file" );
     ok(!-e $trace_log, "... the trace log file is actually gone" );
    
    $dbh->disconnect();       
}

# test setting them during connect

{
    my $trace_log = 'tmp_dbi_trace.log';
    
    open STDERR, "> $trace_log";
    ok(-f $trace_log, '... the trace log file has been created');
    my $dbh = DBI->connect( 'DBI:Mock:', '', '',
                            { RaiseError => 1,
                              PrintError => 1,
                              AutoCommit => 1,
                              TraceLevel => 2 } );
    cmp_ok( $dbh->{RaiseError}, '==', 1,
        'RaiseError DB attribute set in connect()' );
    cmp_ok( $dbh->{PrintError}, '==', 1,
        'PrintError DB attribute set in connect()' );
    cmp_ok( $dbh->{AutoCommit}, '==', 1,
        'AutoCommit DB attribute set in connect()' );
    cmp_ok( $dbh->{TraceLevel}, '==', 2,
        'TraceLevel DB attribute set in connect()' );       
        
    close STDERR;
    cmp_ok(unlink($trace_log), '==', 1, "... removing the trace log file" );
    ok(!-e $trace_log, "... the trace log file is actually gone" );

    $dbh->disconnect();   
}