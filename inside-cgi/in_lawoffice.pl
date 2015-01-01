#!/usr/bin/perl -w
use strict;
use CGI;
use DBI;
use Text::MetaText;
use HTML::FromText; 
use lib "/home/fahai/cgi-tools";

require "comm_sub.pl";
require "in_lawyerLib.pl";
require "in_lawofficeLib.pl";
require "select.pl";


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
my $lawoffice = new CGI;
print $lawoffice->header;



# generate METATEXT object
my $mt = Text::MetaText->new(\%mtparam);

#connet to database,get database handler
my $dbh = DBI->connect(@dbiparam) || 
	print "不能连接到数据库！" && return;

 

#get CGI params
my %param;
foreach ($lawoffice->param) {
    $param{$_} = $lawoffice->param($_);
    #print "$param{$_}<br>\n";
}



$param{'DBH'} = $dbh;
$param{'METATEXT'} = $mt;
&main(\%param);
$dbh->disconnect();

sub main
{
	my $param = shift;
	my $cmd = $param->{'cmd'};
	if($cmd eq 'add') {
		&addLawOffice($param);}
	elsif($cmd eq 'edit') {
		&editLawOffice($param);}
	elsif($cmd eq 'search') {
		&in_searchLawOffice($param);}
	elsif($cmd eq 'member') {
		&memberLawOffice($param);}
	elsif($cmd eq '修  改') {
		&updateLawOffice($param);}
	elsif($cmd eq '删  除') {
		&deleteLawOffice($param);}
	else {
		print "错误指令!!";}
}
