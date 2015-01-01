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
		&showLawyerSearch($param);}
	elsif($typ eq '1') {
		&showLawOfficeSearch($param);}
	elsif($typ eq '2') {
		&showLawSearch($param);}
        else {
		print "错误指令!!";}
}

sub showLawyerSearch
{
	my $param = shift;

    my $dbh = $param->{'DBH'};
    my $mt = $param->{'METATEXT'};
    
    my $area = (!defined($param->{'area'}))?"":$param->{'area'};
    my $province = $param->{'province'};
    my $city= (!defined($param->{'city'}))?"":$param->{'city'}; 	
    my $button= (!defined($param->{'button'}))?1:$param->{'button'};
    my $own = (!defined($param->{'own'}))?0:$param->{'own'};
    my $X = 0;
    my $lawyerareaLine ="";


        my $haveCity = 0;
	my $cityLine = "";
	
	my ($resultSum)  = $dbh->selectrow_array(<<__SQL__,undef,"%$province%","%$city%","%$area%");
		SELECT count(t1.id)
		FROM Lawyer AS t1,Lawyer_LawArea AS t2
		WHERE (t1.province LIKE ? AND t1.city LIKE ? AND t2.area_name LIKE ? AND t1.id=t2.lawyer_id)
			AND ((t2.area_order =1 AND CURRENT_DATE NOT BETWEEN t1.service_from_date AND t1.service_to_date)
				OR (t2.area_order<=5 AND  t1.service_type =1 AND CURRENT_DATE BETWEEN t1.service_from_date AND t1.service_to_date)
				OR (t2.area_order<=9 AND  t1.service_type =2 AND CURRENT_DATE BETWEEN t1.service_from_date AND t1.service_to_date))
		GROUP BY t1.id
__SQL__

    
   
    if(defined($province) && !($province eq ''))
	{
	   $X = 1;	
		if(!isCouncilCity($dbh,$province))
		{
			if ($city eq '')
			{
			  $X = 0;	
			}	
			
			$haveCity = 1;
			$cityLine = selectCity($dbh,$mt,$province,$area);
		}
	}
	else
	{
		$province = "";
	}
	
        my $lawareaLine = selectLawarea($dbh,$mt,$own);
	my $provinceLine = selectProvince($dbh,$mt);


        if($resultSum != 0)
	{
          print $mt->process_file('pgLawyerSearch.htm',
		{
			'area' => $area,
			'lawarealine' => $lawareaLine,
			'province' => $province,
			'city' => $city,
			'provinceline' => $provinceLine,
			'havecity' => $haveCity,
			'cityline' => $cityLine,
		});
	}	
	else
	{
           if($button == 1 && $X == 1)
            {
             $lawyerareaLine = selectLawyerarea($dbh,$mt,$province,$city,$own);
            }    
          print $mt->process_file('VAL_pgLawyerSearch.htm',
                {
                        'area' => $area,
                        'lawarealine' => $lawareaLine,
                        'lawyerarealine' =>$lawyerareaLine, 
                        'province' => $province,
                        'city' => $city,
                        'provinceline' => $provinceLine,
                        'havecity' => $haveCity,
                        'cityline' => $cityLine,
                        'VAL'      => $X,
                });

         }
           		
}

sub showLawOfficeSearch
{
	my $param = shift;

    my $dbh = $param->{'DBH'};
    my $mt = $param->{'METATEXT'};
	
    my $area = (!defined($param->{'area'}))?"":$param->{'area'};
    my $province = $param->{'province'};
    my $city= (!defined($param->{'city'}))?"":$param->{'city'}; 	
    my $button= (!defined($param->{'button'}))?1:$param->{'button'};
    my $own =(!defined($param->{'own'}))?0:$param->{'own'}; 
    my $X = 0;
    my $lawofficeareaLine;
    
    
          my $resultSum = $dbh->selectrow_array(<<__SQL__,undef,"%$province%","%$city%","%$area%");
		SELECT count(t1.id)
		FROM LawOffice AS t1,LawOffice_LawArea AS t2
		WHERE (t1.province LIKE ? AND t1.city LIKE ? AND t2.area_name LIKE ? AND t1.id=t2.lawoffice_id)
			AND ((t2.area_order <=2 AND CURRENT_DATE NOT BETWEEN t1.service_from_date AND t1.service_to_date)
			OR (t2.area_order<=6 AND  t1.service_type =1 AND CURRENT_DATE BETWEEN t1.service_from_date AND t1.service_to_date)
			OR (t2.area_order<=10 AND  t1.service_type =2 AND CURRENT_DATE BETWEEN t1.service_from_date AND t1.service_to_date))
		GROUP BY t1.id
__SQL__

		#my $resultSum = scalar(@$resultSumTmp);

      
	
	my $haveCity = 0;
	my $cityLine = "";

	if(defined($province) || !($province eq ''))
	{
		$X = 1;
		
		if(!isCouncilCity($dbh,$province))
		{
			if ($city eq '')
			{
			  $X = 0;	
			}	
			
			$haveCity = 1;
			$cityLine = selectCity($dbh,$mt,$province);
		}
	}
	else
	{
		$province = "";
	}

	my $lawareaLine = selectLawarea($dbh,$mt,$own);




	my $provinceLine = selectProvince($dbh,$mt);

        	
	if(($resultSum != 0))
	{
	     print $mt->process_file('pgLawOfficeSearch.htm',
		{
			'area' => $area,
			'lawarealine' => $lawareaLine,
			'province' => $province,
			'provinceline' => $provinceLine,
			'havecity' => $haveCity,
			'cityline' => $cityLine,
			'city'     => $city,
			
		});
        }
        else
        {
           if($button == 1 && $X == 1)
            {
             $lawofficeareaLine = selectLawOffiearea($dbh,$mt,$province,$city,$own);
            }    	
        
            print $mt->process_file('VAL_pgLawOfficeSearch.htm',
		{
			'area' => $area,
			'lawarealine' => $lawareaLine,
			'lawofficearealine' => $lawofficeareaLine,
			'province' => $province,
			'provinceline' => $provinceLine,
			'havecity' => $haveCity,
			'cityline' => $cityLine,
			'city'     => $city,
			'button'   => $button,
		        'VAL'      => $X,
				
		});
        
        
        
        }
        	

}


sub showLawSearch
{
	my $param = shift;

    my $dbh = $param->{'DBH'};
    my $mt = $param->{'METATEXT'};

    
    my $area = (!defined($param->{'area'}))?"":$param->{'area'};
    my $own  = (!defined($param->{'own'}))?0:$param->{'own'};
	
	my $bigareaLine = selectBigarea($dbh,$mt,$own);
	
	my $haveLawname = 0;
	my $lawnameLine = "";
	if(!($area eq ''))
	{
		$haveLawname = 1;
		$lawnameLine = selectLawName($dbh,$mt,$area,$own);
	}
	
	#print $lawnameLine;
	
	
		print $mt->process_file('pgLawSearch.htm',
		{
			'thearea' => $area,
			'bigarealine' => $bigareaLine,
			'lawnameline' => $lawnameLine,
			'havelawname' => $haveLawname,
		});
        
}

	
