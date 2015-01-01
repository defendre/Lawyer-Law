#!/usr/bin/perl -w

use strict;

use lib '/home/fahai/cgi-tools';
use lib '/home/fahai/inside-cgi';

use CGI;
use DBI;
use Text::MetaText;
use HTML::FromText; 

require "comm_sub.pl";
require "in_lawyerLib.pl";
require "in_lawofficeLib.pl";

#-------------------------------------------------------------------------------
# global data for configuration
#-------------------------------------------------------------------------------
my @dbiparam = qw( DBI:mysql:fahai:localhost:3306 root password);
my %mtparam = ( 'CASE'  => 1,
                'CHOMP' => 1,
                'ROGUE' => "warn,delete",
                'LIB'   => "./:./template",
                'ERROR' => sub {
                        my ($format, @params) = @_;
                        printf(STDERR "MetaText Error: $format", @params);
                }
              );

#-------------------------------------------------------------------------------
# main program
#-------------------------------------------------------------------------------

# generate CGI object
my $show = new CGI;
print $show->header;

# generate METATEXT object
my $mt = Text::MetaText->new(\%mtparam);

#connet to database,get database handler
my $dbh = DBI->connect(@dbiparam) || 
	print "不能连接到数据库！" && return;
 
#get CGI params
my %param;
foreach ($show->param) {
    $param{$_} = $show->param($_);
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
		&showLawyerDetail($param);}
	elsif($typ eq '1') {
		&showLawOfficeDetail($param);}
	elsif($typ eq '2') {
		&showLawDetail($param);}
	else {
		print "错误指令!!";}
}


#--------------------------------------------------------
#Function:	show lawyer info detail
#Input:		dbh
#			mt
#			lawyer id
#Output:	lawyer info page
#--------------------------------------------------------
sub showLawyerDetail
{
	my $param = shift;

    my $dbh = $param->{'DBH'};
    my $mt = $param->{'METATEXT'};
    
    my $id = $param->{'id'};
    
	my @info = $dbh->selectrow_array(<<__SQL__,undef,$id);
	SELECT concat(lastname_cn,firstname_cn) AS name,province,city,address,zipcode,
		areacode,tel,fax,mobile,email1,email2,website,serial,authdate,law_office,
		language,service_type 
	FROM Lawyer 
	WHERE id = ?
__SQL__

    my $area1 = "";
    my $area2 = "";
    my $area3 = "";
    
    my $service_type = $info[16];
    my $isMember = &isMemberLawyer($dbh,$id);
    if(!$isMember)
    {
    	$area1 = &getLawyer_LawArea($dbh,$id,1);
    }
    elsif($service_type == 1 && $isMember)
    {
    	$area1 = &getLawyer_LawArea($dbh,$id,1);
		$area2 = &getLawyer_LawArea($dbh,$id,2);
    }
    elsif($service_type == 2 && $isMember)
    {
    	$area1 = &getLawyer_LawArea($dbh,$id,1);
		$area2 = &getLawyer_LawArea($dbh,$id,2);
		$area3 = &getLawyer_LawArea($dbh,$id,3);
	}
	
	my $lawOffice = "";
	if(!$info[14] == 0)
	{
		$lawOffice = getLawOfficeName($dbh,$info[14]);
	}
	
	#format telephone and fax
	my $areacode = $info[5];
	my $tel = $info[6];
	my $fax = $info[7];
	$tel = $areacode . "-" . $tel if(!($areacode eq "") && !($tel eq ""));
	$fax = $areacode . "-" . $fax if(!($areacode eq "") && !($fax eq ""));
	
	my $email1 = $info[9];
	if(!($email1 eq ""))
	{
		$email1 = "<a href=mailto:" . $email1 . ">" . $email1 . "</a>";
	}
	my $email2 = $info[10];
	if(!($email2 eq ""))
	{
		$email2 = "<a href=mailto:" . $email2 . ">" . $email2 . "</a>";
	}
	my $website = $info[11];
	if(!($website eq ""))
	{
		$website = "<a href=http://" . $website . ">" . $website . "</a>";
	}
	
	my $authdate = $info[13];
	$authdate = "" if($authdate eq "0000-00-00");
	
    print $mt->process_file('pgLawyerDetail.htm',
    					{
    						id => $id,
    						name => $info[0],
    						province => $info[1],
    						city => $info[2],
    						address => $info[3],
    						zipcode => $info[4],
    						tel => $tel,
    						fax => $fax,
    						mobile => $info[8],
    						email1 => $email1,
    						email2 => $email2,
    						website => $website,
    						serial => $info[12],
    						authdate => $authdate,
    						lawoffice => $lawOffice,
    						language => $info[15],
    						area1 => $area1,
    						area2 => $area2,
    						area3 => $area3,
    					}); 

}


#--------------------------------------------------------
#Function:	show law office info detail
#Input:		dbh
#			mt
#			law office id
#Output:	law office info page
#--------------------------------------------------------
sub showLawOfficeDetail
{
	my $param = shift;

    my $dbh = $param->{'DBH'};
    my $mt = $param->{'METATEXT'};
    
    my $id = $param->{'id'};
    
	my @info = $dbh->selectrow_array(<<__SQL__,undef,$id);
	SELECT name_cn,province,city,address,zipcode,areacode,tel,fax,email1,
		email2,website,serial,authdate,language,service_type,sname
	FROM LawOffice
	WHERE id = ?
__SQL__

    my $area1 = "";
    my $area2 = "";
    my $area3 = "";
    
    my $service_type = $info[14];
    my $isMember = &isMemberLawOffice($dbh,$id);

    if(!$isMember)
    {
    	$area1 = &getLawOffice_LawArea($dbh,$id,1);
    }
    elsif($service_type == 1 && $isMember)
    {
    	$area1 = &getLawOffice_LawArea($dbh,$id,1);
		$area2 = &getLawOffice_LawArea($dbh,$id,2);
    }
    elsif($service_type == 2 && $isMember)
    {
    	$area1 = &getLawOffice_LawArea($dbh,$id,1);
		$area2 = &getLawOffice_LawArea($dbh,$id,2);
		$area3 = &getLawOffice_LawArea($dbh,$id,3);
	}
	
	#format telephone and fax
	my $areacode = $info[5];
	my $tel = $info[6];
	my $fax = $info[7];
	$tel = $areacode . "-" . $tel if(!($areacode eq "") && !($tel eq ""));
	$fax = $areacode . "-" . $fax if(!($areacode eq "") && !($fax eq ""));
    
    my $email1 = $info[8];
	if(!($email1 eq ""))
	{
		$email1 = "<a href=mailto:" . $email1 . ">" . $email1 . "</a>";
	}
	my $email2 = $info[9];
	if(!($email2 eq ""))
	{
		$email2 = "<a href=mailto:" . $email2 . ">" . $email2 . "</a>";
	}
	my $website = $info[10];
	if(!($website eq ""))
	{
		$website = "<a href=http://" . $website . ">" . $website . "</a>";
	}
    
    my $authdate = $info[12];
	$authdate = "" if($authdate eq "0000-00-00");
	
    print $mt->process_file('pgLawOfficeDetail.htm',
    					{
    						id => $id,
    						name_cn => $info[0],
    						province => $info[1],
    						city => $info[2],
    						address => $info[3],
    						zipcode => $info[4],
    						tel => $tel,
    						fax => $fax,
    						email1 => $email1,
    						email2 => $email2,
    						website => $website,
    						serial => $info[11],
    						authdate => $info[12],
    						language => $info[13],
    						sname => $info[15],
    						area1 => $area1,
    						area2 => $area2,
    						area3 => $area3,
    					}); 

}


#--------------------------------------------------------
#Function:	show law info detail
#Input:		dbh
#			mt
#			law id
#Output:	law info page
#--------------------------------------------------------
sub showLawDetail
{
	my $param = shift;

    my $dbh = $param->{'DBH'};
    my $mt = $param->{'METATEXT'};
    my $lw = $param->{'lw'};
    my $add = $param->{'add'};
    my $id = $param->{'id'};

	my ($area,$type,$title,$content,$keyword) = 
		$dbh->selectrow_array("SELECT area,type,title,content,keyword FROM Law WHERE id = ?",undef,$id);
	my ($zc,$fd,$qq,$name,$tpdate) = 
			$dbh->selectrow_array("SELECT zc,td,qq,name,tpdate FROM Tp WHERE id = ?",undef,$id);

    	
	#convert '<' and '>'.
	#print $content;
        #$content =~ s/((.){60})/$1<br>/g;
        #$content =~ s/</&lt;/g;
	#$content =~ s/>/&gt;/g;
        #$content =~ s/\n/<br>/g;
        #$content =~ s/\r//g;
        #$content =~ s/ /&nbsp;/g;
           $content = text2html($content,spaces => 1, lines => 1,urls => 1,email => 1);   

        
        
   	
	if($lw==1)
	{
	       print $mt->process_file('pgLwDetail.htm',
    					{
    						id => $id,
                                                zc => $zc,
    						fd => $fd,
    						qq => $qq,
    						name => $name,
    						tpdate =>$tpdate,
    						title => $title,
    						content => $content,
    					}); 
	}	
        elsif($add==1)
        {

              print $mt->process_file('pgLawInfoEdit.htm',
   					{
    						'id' => $id,
    						'area' => $area,
    						'type' => $type,
    						'title' => $title,
    						'content' => $content,
   						'keyword' => $keyword,
    					#	'bigarealine' => $bigareaLine,
					#	'lawnameline' => $lawnameLine,
					#	'add'         => $add, 
                                        #        'own'         => $own,
                                        #        'file'       => $file,
    					}); 

        }
	else
	{
		print $mt->process_file('pgLawDetail.htm',
    					{
    						id   => $id,
                                                area => $area,
    						type => $type,
    						title => $title,
    						keyword => $keyword,
    						content => $content,
    					}); 
         }
}
