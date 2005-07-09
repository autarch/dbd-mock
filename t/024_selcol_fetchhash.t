#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;

BEGIN {
    use_ok('DBD::Mock');  
	use_ok('DBI');
}

my $swallow_sql = "SELECT id, type, inventory_id, species FROM birds WHERE species='swallow'";
my $items_sql   = "SELECT id, name, weight FROM items";
my @resultList =  
  (
   {
     sql     => $swallow_sql,
     results => [
		 [ 'id', 'type', 'inventory_id' ],
		 [ '1',  'european', '42' ],
		 [ '27', 'african',  '2' ],
		 ],
     },
   {
     sql     => $items_sql,
     results => [
		 [ 'id', 'name', 'weight' ],
		 [ '2',  'coconuts',     'fairly hefty' ],
		 [ '42', 'not coconuts', 'pretty light' ],
		 ],
     },
   );

my $coco_hash = { 
  'id'     => '2',
  'name'   => 'coconuts',
  'weight' => 'fairly hefty',
};

my $not_coco_hash = {
  'id'     => '42',
  'name'   => 'not coconuts',
  'weight' => 'pretty light',
};    

my $dbh = DBI->connect( 'DBI:Mock:', '', '' );

{
  my $res;

  foreach $res (@resultList) {
    $dbh->{mock_add_resultset} = $res;
  }
}

{
  my @res = [];

  my @expected = ('1','27');

  eval {
    @res = $dbh->selectcol_arrayref($swallow_sql);
  };
    
  
  is_deeply(\@res, \@expected, "Checking if selectcol_arrayref works.");
}

is_deeply(
	  $dbh->selectall_hashref($items_sql, 'id', "Checking selectall_hashref with named key."), 
	  { '2' => $coco_hash,
	    '42' =>$not_coco_hash,
	  },
	  '... selectall_hashref worked correctly');

is_deeply(
	  $dbh->selectall_hashref($items_sql, 1, "Checking selectall_hashref with named key."), 
	  { 'coconuts' => $coco_hash,
	    'not coconuts' =>$not_coco_hash,
	  },
	  '... selectall_hashref worked correctly');
