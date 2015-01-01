#!/usr/bin/perl -w

use strict;
use DBI;

my @dbiparam = qw( DBI:mysql:fahai:localhost:3306 root password);

my $dbh = DBI->connect(@dbiparam) || 
	print "不能连接到数据库！" && return;

my $fileName = "district.txt";

open(DISTRICT,$fileName);
while(<DISTRICT>)
{		
	next if(/^\/\//);#skip the note.
	chomp;
	chop;
	#print length $_,"$_\n";
	
	$_ =~ /(\S+),(\S+)/;
	my $province = $1;
	my $city = $2;
	
	my $insertStr = "INSERT INTO District(province,city) values(?,?)";    		
   	my $insert = $dbh->prepare(qq{$insertStr});
   	$insert->execute($province,$city);
   	$insert->finish();
}

close(DISTRICT);

$dbh->disconnect();
