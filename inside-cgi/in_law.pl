#!/usr/bin/perl -w 
use strict;
use CGI;
use DBI;
use Time::Local;
use Text::MetaText;
use HTML::FromText; 


use lib "/home/fahai/cgi-tools";
require "comm_sub.pl";
require "in_lawLib.pl";
require "in_lawyerLib.pl";
require "select.pl";

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
$mon=$mon+1;
$year=$year+1900;
if ($mon < 10)
{
   $mon='0'.$mon;
}
if($mday < 10)
{
   $mday='0'.$mday;
}
my $now=$year.'-'.$mon.'-'.$mday;







#-------------------------------------------------------------------------------
# global data for configuration
#-------------------------------------------------------------------------------
my @dbiparam = qw( DBI:mysql:fahai:localhost:3306 root password);
my %mtparam = ( 'CASE'  => 1,
                'CHOMP' => 1,
                'ROGUE' => "warn,delete",
                'LIB'   => "./:./in_template",
                'ERROR' => sub {
                        my ($format, @params) = @_;
                        printf(STDERR "MetaText Error: $format", @params);
                }
              );



#-------------------------------------------------------------------------------
# main program
#-------------------------------------------------------------------------------


# generate CGI object
my $law = new CGI;
print $law->header;

# generate METATEXT object
my $mt = Text::MetaText->new(\%mtparam);
#connet to database,get database handler
my $dbh = DBI->connect(@dbiparam) || 
	print "不能连接到数据库！" && return;

 

#get CGI params
my %param;
foreach ($law->param) {
    $param{$_} = $law->param($_);
    #print "$param{$_}<br>\n";
}


$param{'DBH'} = $dbh;
$param{'METATEXT'} = $mt;
$param{'DATE'} = $now;
$param{'LAW'} = $law;
&main(\%param);

$dbh->disconnect();
sub main
{
	my $param = shift;
	my $cmd = $param->{'cmd'};
	if($cmd eq 'add') {
		&addLaw($param);}
	elsif($cmd eq 'edit') {
		&editLaw($param);}
	elsif($cmd eq 'search') {   
		&in_searchLaw($param);}
	elsif($cmd eq 'member') {
		&memberLaw($param);}
	elsif($cmd eq '修  改') {
		&updateLaw($param);}
	elsif($cmd eq '删  除') {
		&deleteLaw($param);}
	else {
		print "错误指令!!";}
}

