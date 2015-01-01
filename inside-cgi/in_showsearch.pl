#!/usr/bin/perl -w

use strict;

use lib '/home/fahai/cgi-tools';
use lib '/home/fahai/inside-cgi';

use CGI;
use DBI;
use Text::MetaText;

require "comm_sub.pl";
require "in_lawyerLib.pl";
require "in_lawofficeLib.pl";
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
                'LIB'   => "./:./template:/home/fahai/inside-cgi/in_template",
                'ERROR' => sub {
                        my ($format, @params) = @_;
                        printf(STDERR "MetaText Error: $format", @params);
                }
              );

#-------------------------------------------------------------------------------
# main program
#-------------------------------------------------------------------------------

# generate CGI object
my $showsearch = new CGI;
print $showsearch->header;

# generate METATEXT object
my $mt = Text::MetaText->new(\%mtparam);

#connet to database,get database handler
my $dbh = DBI->connect(@dbiparam) || 
	print "不能连接到数据库！" && return;
 
#get CGI params
my %param;
foreach ($showsearch->param) {
    $param{$_} = $showsearch->param($_);
    #print "$param{$_}<br>\n";
}

$param{'DBH'} = $dbh;
$param{'METATEXT'} = $mt;
$param{'DATE'} = $now;
&main(\%param);

$dbh->disconnect();

sub main
{
	my $param = shift;
	
	#0 lawyer
	#1 lawoffice
	#2 law
	my $typ = $param->{'typ'};
	
	if($typ eq '0') {
		&in_showLawyerSearch($param);}
	elsif($typ eq '1') {
		&in_showLawOfficeSearch($param);}
	elsif($typ eq '2') {
		&in_showLawSearch($param);}
	else {

		print "错误指令!!";}
}

sub in_showLawyerSearch
{
	my $param = shift;

    my $dbh = $param->{'DBH'};
    my $mt = $param->{'METATEXT'};
    my $own = $param->{'own'};	
    my $area = (!defined($param->{'area'}))?"":$param->{'area'};
    my $province = (!defined($param->{'province'}))?"":$param->{'province'};
    
    #input type
    my $type = (!defined($param->{'type'}))?0:$param->{'type'};
	
	my $haveCity = 0;
	my $cityLine = "";
	
	my $lawareaLine = selectLawarea($dbh,$mt,$own);
	my $provinceLine = selectProvince($dbh,$mt);
	
	if(!($province eq '') && !isCouncilCity($dbh,$province))
	{
		$haveCity = 1;
		$cityLine = selectCity($dbh,$mt,$province);
	}
		
	print $mt->process_file('in_pgLawyerSearch.htm',
		{
			'area' => $area,
			'lawarealine' => $lawareaLine,
			'province' => $province,
			'provinceline' => $provinceLine,
			'havecity' => $haveCity,
			'cityline' => $cityLine,
			'type' => $type,
                        'own'  => $own,
		});
}

sub in_showLawOfficeSearch
{
	my $param = shift;

    my $dbh = $param->{'DBH'};
    my $mt = $param->{'METATEXT'};
	
	#input type
    my $type = (!defined($param->{'type'}))?0:$param->{'type'};
    my $own = $param->{'own'}; 
    my $area = (!defined($param->{'area'}))?"":$param->{'area'};
    my $province = (!defined($param->{'province'}))?"":$param->{'province'};
	
	my $haveCity = 0;
	my $cityLine = "";

	if(!($province eq '') && !isCouncilCity($dbh,$province))
	{
		$haveCity = 1;
		$cityLine = selectCity($dbh,$mt,$province);
	}

	my $lawareaLine = selectLawarea($dbh,$mt,$own);
	my $provinceLine = selectProvince($dbh,$mt);
		
	print $mt->process_file('in_pgLawOfficeSearch.htm',
		{
			'area' => $area,
			'lawarealine' => $lawareaLine,
			'province' => $province,
			'provinceline' => $provinceLine,
			'havecity' => $haveCity,
			'cityline' => $cityLine,
			'type' => $type,
                        'own'  => $own,
		});
}

sub in_showLawSearch
{
	my $param = shift;

    my $dbh = $param->{'DBH'};
    my $mt = $param->{'METATEXT'};
    my $area = (!defined($param->{'area'}))?"":$param->{'area'};
    my $law  = (!defined($param->{'law'}))?0:$param->{'law'};
    my $own = $param->{'own'};
    my $keyword ="";

	my $bigareaLine = selectBigarea($dbh,$mt,$own);
        my $haveLawname = 0;
        my $lawnameLine="";

   if(!($area eq ''))
        {
                $haveLawname = 1;
                $lawnameLine = selectLawName($dbh,$mt,$area,$own);
        }

my @councilCity = ('TS工时统计');
 foreach (@councilCity)
        {
          $keyword = '/'.$param->{'DATE'} if($area eq $_);
        }
   
       if($law)
	{
         print $mt->process_file('in_pgLawInput.htm',
              {
              'area' => $area,
              'bigarealine' => $bigareaLine,
              'lawnameline' => $lawnameLine,
              'havalawname' => $haveLawname,
              'own'         => $own,
              'keyword'     => $keyword, 
              });
        } 
	else
        {
          print $mt->process_file('in_pgLawSearch.htm',
		{
            	        'thearea'     => $area,
                        'bigarealine' => $bigareaLine,
			'lawnameline' => $lawnameLine,
                        'havelawname' => $haveLawname,
                        'own'         => $own,
                      
		});
        }
}
