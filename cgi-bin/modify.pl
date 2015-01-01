#!/usr/bin/perl -w
use Mail::Sendmail;
                    # unattended Mail::Sendmail test, sends a message to the author
                    # but you probably want to change $mail{To} below
                    # to send the message to yourself.
                    # version 0.78





                    # if you change your mail server, you may need to change the From:
                    # address below.
                    $mail{From} = '卫利<fahai@163bj.com>';

                    $mail{To}   = '法海<bangzhu@fahai.com.cn>';
                    #$mail{To}   = 'Sendmail Test <sendmail@alma.ch>, You me@myaddress';

                    # if you want to get a copy of the test mail, you need to specify your
                    # own server here, by name or IP address
                    $server = '202.130.3.7';
                    #$server = 'my.usual.mail.server';

                    #BEGIN { $| = 1; print "1..2\n"; }
                    #END {print "not ok 1\n" unless $loaded;}

                    #$loaded = 1;
                    #print "ok 1\n";

                    #print <<EOT
                    #Test Mail::Sendmail $Mail::Sendmail::VERSION
                    #
                    #Try to send a message to the author (and/or whoever if you edited test.pl)
                    #
                    #(The test is designed so it can be run by Test::Harness from CPAN.pm.
                    #Edit it to send the mail to yourself for more concrete feedback. If you
                    #do this, you also need to specify a different mail server, and possibly
                    #a different From: address.)
                    #
                    #Current recipient(s): '$mail{To}'
                    #
                    #EOT
                    #;

                    if ($server) {
                        $mail{Smtp} = $server;
                        #print "Server set to: $server\n";
                        }

use lib '/home/fahai/cgi-tools';
use lib '/home/fahai/inside-cgi';

use CGI;
use DBI;
use Text::MetaText;

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
my $modify = new CGI;
print $modify->header;

# generate METATEXT object
my $mt = Text::MetaText->new(\%mtparam);

#connet to database,get database handler
my $dbh = DBI->connect(@dbiparam) || 
	print "不能连接到数据库！" && return;
 
#get CGI params
my %param;
foreach ($modify->param) {
    $param{$_} = $modify->param($_);
    #print "$param{$_}<br>\n";
}

$param{'DBH'} = $dbh;
$param{'METATEXT'} = $mt;

&main(\%param);

$dbh->disconnect();

sub main
{
	my $param = shift;
	
	#1 lawyer
	#2 lawoffice
	my $typ = $param->{'typ'};#modify type
	
	if($typ eq '1') {
		&modifyLawyer($param);}
	elsif($typ eq '2') {
		&modifyLawOffice($param);}
	elsif($typ eq '3') {
                &modifyLaw($param);}
        else {
		print "错误指令!!";}	
}


#----------------------------------------------------------------------^M
#Function:      modify law info & send the info to specified email box^M
#Input:         param^M
#Output:        none^M
#----------------------------------------------------------------------^M

sub modifyLaw
{
        my $param = shift;

    my $dbh = $param->{'DBH'};
    my $mt = $param->{'METATEXT'};
        
    my $id = $param->{'id'};
    if(defined($id))
        {
              
       my ($area,$type,$title,$content,$keyword) = $dbh->selectrow_array(
          "SELECT area,type,title,content,keyword FROM Law WHERE id = ?",
           undef,$id);

       print $mt->process_file('pgLawModify.htm',
                                        {
                                                'id' => $id,
                                                'area' => $area,
                                                'type' => $type,
                                                'title' => $title,
                                                'content' => $content,
                                                'keyword' => $keyword,
                                        });
         return;
        }
         &sendLawInfo($param);
}


#----------------------------------------------------------------------
#Function:	modify lawyer info & send the info to specified email box
#Input:		param
#Output:	none
#----------------------------------------------------------------------
sub modifyLawyer
{
	my $param = shift;

    my $dbh = $param->{'DBH'};
    my $mt = $param->{'METATEXT'};
	
	my $id = $param->{'id'};
	if(defined($id))
	{
		&showLawyerModifyPage($param);
		return;
	}
	
	my $name = (!defined($param->{'name'}))?"":$param->{'name'};
	
	if($name eq '')
	{
    	print $mt->process_file('pgLawyerErrPage.htm',{'error_no'=>"2"});#error 2
    	return;
	}
	
	&sendLawyerInfo($param);
}


#----------------------------------------------------------------------
#Function:	show lawyer modify page
#Input:		param
#Output:	lawyer modify page
#----------------------------------------------------------------------
sub showLawyerModifyPage
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
	
	my $area = $area1;
	$area .= "," . $area2 if(!$area2 eq '');
	$area .= "," . $area3 if(!$area3 eq '');
	
	my $lawOffice = "";
	if(!$info[14] == 0)
	{
		$lawOffice = getLawOfficeName($dbh,$info[14]);
	}
	
	$info[13] = "" if($info[13] eq '0000-00-00');
	
    print $mt->process_file('pgLawyerModify.htm',
    					{
    						name => $info[0],
    						province => $info[1],
    						city => $info[2],
    						address => $info[3],
    						zipcode => $info[4],
    						areacode => $info[5],
    						tel => $info[6],
    						fax => $info[7],
    						mobile => $info[8],
    						email1 => $info[9],
    						email2 => $info[10],
    						website => $info[11],
    						serial => $info[12],
    						authdate => $info[13],
    						lawoffice => $lawOffice,
    						language => $info[15],
    						area => $area,
    					}); 

}
#----------------------------------------------------------------------^M
#Function:      send the law info to specified email box^M
#Input:         param^M
#Output:        message page(success or not)^M
#----------------------------------------------------------------------^M
sub sendLawInfo
{
        my $param = shift;

    my $mt = $param->{'METATEXT'};

    my $area = (!defined($param->{'area'}))?"":$param->{'area'};
    my $type = (!defined($param->{'type'}))?"":$param->{'type'};
    my $title = (!defined($param->{'title'}))?"":$param->{'title'};
    my $keyword = (!defined($param->{'keyword'}))?"":$param->{'keyword'};
    my $content = (!defined($param->{'content'}))?"":$param->{'content'};
  
        #the specified email box^M
  $mail{Subject} ="详细内容更新\n";
  $mail{Message} ="法律领域:$area\n";
  $mail{Message}.="法律名称:$type\n";
  $mail{Message}.="问题类别:$title\n";
  $mail{Message}.="正文关键字:$keyword\n";
  $mail{Message}.="正　　文:$content\n";
if (sendmail %mail) {
 #print "content of \$Mail::Sendmail::log:\n$Mail::Sendmail::log\n";
  if ($Mail::Sendmail::error)
   { #print "content of \$Mail::Sendmail::error:\n$Mail::Sendmail::error\n";
     }
      #print "ok 2\n";
      }
      else {
       #print "\n!Error sending mail:\n$Mail::Sendmail::error\n";
        #print "not ok 2\n";
       }       
         print $mt->process_file('pgMessage.htm',{'msg_no'=>"2"});#message 0
}
#----------------------------------------------------------------------
#Function:	send the lawyer info to specified email box
#Input:		param
#Output:	message page(success or not)
#----------------------------------------------------------------------
sub sendLawyerInfo
{
	my $param = shift;

    my $mt = $param->{'METATEXT'};

	my $name = $param->{'name'};
	my $province = (!defined($param->{'province'}))?"":$param->{'province'};
	my $city = (!defined($param->{'city'}))?"":$param->{'city'};
	my $address = (!defined($param->{'address'}))?"":$param->{'address'};
	my $zipcode = (!defined($param->{'zipcode'}))?"":$param->{'zipcode'};
	my $areacode = (!defined($param->{'areacode1'}))?"":$param->{'areacode1'};
	my $tel = (!defined($param->{'tel'}))?"":$param->{'tel'};
	my $fax = (!defined($param->{'fax'}))?"":$param->{'fax'};
	my $mobile = (!defined($param->{'mobile'}))?"":$param->{'mobile'};
	my $email1 = (!defined($param->{'email1'}))?"":$param->{'email1'};
	my $email2 = (!defined($param->{'email2'}))?"":$param->{'email2'};
	my $website = (!defined($param->{'website'}))?"":$param->{'website'};
	my $serial = (!defined($param->{'serial'}))?"":$param->{'serial'};
	my $authdate = (!defined($param->{'authdate'}))?"":$param->{'authdate'};
	my $lawoffice = (!defined($param->{'lawoffice'}))?"":$param->{'lawoffice'};
	my $language = (!defined($param->{'language'}))?"":$param->{'language'};
	my $area = (!defined($param->{'area'}))?"":$param->{'area'};
        my $remark = (!defined($param->{'remark'}))?"":$param->{'remark'};

	#the specified email box
$mail{Subject} ="律师信息更新\n";
$mail{Message} ="姓名:$name\n";
$mail{Message}.="省/直辖市:$province\n";
$mail{Message}.="市/县:$city\n";
$mail{Message}.="地址:$address\n";
$mail{Message}.="邮编:$zipcode\n";
$mail{Message}.="电话:$areacode-$tel\n";
$mail{Message}.="传真:$areacode-$fax\n";
$mail{Message}.="手机:$mobile\n";
$mail{Message}.="电子信箱1:$email1\n";
$mail{Message}.="电子信箱2:$email2\n";
$mail{Message}.="网站:$website\n";
$mail{Message}.="法律领域:$area\n";
$mail{Message}.="律师执业证号:$serial\n";
$mail{Message}.="执业机构名称:$lawoffice\n";
$mail{Message}.="语言:$language\n";
$mail{Message}.="律师执业证取得日期:$authdate\n";
$mail{Message}.="备注:$remark\n";
if (sendmail %mail) {
 #print "content of \$Mail::Sendmail::log:\n$Mail::Sendmail::log\n";
  if ($Mail::Sendmail::error)
   { #print "content of \$Mail::Sendmail::error:\n$Mail::Sendmail::error\n";
     }
      #print "ok 2\n";
      }
      else {
       #print "\n!Error sending mail:\n$Mail::Sendmail::error\n";
        #print "not ok 2\n";
       }       
   	print $mt->process_file('pgMessage.htm',{'msg_no'=>"0"});#message 0
}


#----------------------------------------------------------------------
#Function:	modify law office info & send the info to specified email box
#Input:		param
#Output:	none
#----------------------------------------------------------------------
sub modifyLawOffice
{
	my $param = shift;

    my $dbh = $param->{'DBH'};
    my $mt = $param->{'METATEXT'};

	my $id = $param->{'id'};
	if(defined($id))
	{
		&showLawOfficeModifyPage($param);
		return;
	}
	
	my $name = (!defined($param->{'name'}))?"":$param->{'name'};
	
	if($name eq '')
	{
    	print $mt->process_file('pgLawOfficeErrPage.htm',{'error_no'=>"2"});#error 2
    	return;
	}

	&sendLawOfficeInfo($param);

}


#----------------------------------------------------------------------
#Function:	show law office modify page
#Input:		param
#Output:	law office modify page
#----------------------------------------------------------------------
sub showLawOfficeModifyPage
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
	
	my $area = $area1;
	$area .= "," . $area2 if(!$area2 eq '');
	$area .= "," . $area3 if(!$area3 eq '');
	
	$info[12] = "" if($info[12] eq '0000-00-00');
    
    print $mt->process_file('pgLawOfficeModify.htm',
    					{
    						name => $info[0],
    						province => $info[1],
    						city => $info[2],
    						address => $info[3],
    						zipcode => $info[4],
    						areacode => $info[5],
    						tel => $info[6],
    						fax => $info[7],
    						email1 => $info[8],
    						email2 => $info[9],
    						website => $info[10],
    						serial => $info[11],
    						authdate => $info[12],
    						language => $info[13],
    						sname => $info[15],
    						area => $area,
    					});
}


#----------------------------------------------------------------------
#Function:	send the law office info to specified email box
#Input:		param
#Output:	message page(success or not)
#----------------------------------------------------------------------
sub sendLawOfficeInfo
{
	my $param = shift;

    my $dbh = $param->{'DBH'};
    my $mt = $param->{'METATEXT'};

	my $name = $param->{'name'};
	my $province = (!defined($param->{'province'}))?"":$param->{'province'};
	my $sname = (!defined($param->{'sname'}))?"":$param->{'sname'};
	my $city = (!defined($param->{'city'}))?"":$param->{'city'};
	my $address = (!defined($param->{'address'}))?"":$param->{'address'};
	my $zipcode = (!defined($param->{'zipcode'}))?"":$param->{'zipcode'};
	my $areacode = (!defined($param->{'areacode1'}))?"":$param->{'areacode1'};
	my $tel = (!defined($param->{'tel'}))?"":$param->{'tel'};
	my $fax = (!defined($param->{'fax'}))?"":$param->{'fax'};
	my $mobile = (!defined($param->{'mobile'}))?"":$param->{'mobile'};
	my $email1 = (!defined($param->{'email1'}))?"":$param->{'email1'};
	my $email2 = (!defined($param->{'email2'}))?"":$param->{'email2'};
	my $website = (!defined($param->{'website'}))?"":$param->{'website'};
	my $serial = (!defined($param->{'serial'}))?"":$param->{'serial'};
	my $authdate = (!defined($param->{'authdate'}))?"":$param->{'authdate'};
	my $lawoffice = (!defined($param->{'lawoffice'}))?"":$param->{'lawoffice'};
	my $language = (!defined($param->{'language'}))?"":$param->{'language'};
	my $area = (!defined($param->{'area'}))?"":$param->{'area'};
        my $remark = (!defined($param->{'remark'}))?"":$param->{'remark'};
	
	#the specified email box
       
        $mail{Subject} ="律师所信息更新\n";
        $mail{Message} ="名称:$name\n";
        $mail{Message}.="简称:$sname\n";
        $mail{Message}.="省/直辖市:$province\n";
        $mail{Message}.="市/县:$city\n";
        $mail{Message}.="地址:$address\n";
        $mail{Message}.="邮编:$zipcode\n";
        $mail{Message}.="电话:$areacode-$tel\n";
        $mail{Message}.="传真:$areacode-$fax\n";
        $mail{Message}.="手机:$mobile\n";
        $mail{Message}.="电子信箱1:$email1\n";
        $mail{Message}.="电子信箱2:$email2\n";
        $mail{Message}.="网站:$website\n";
        $mail{Message}.="法律领域:$area\n";
        $mail{Message}.="律师执业证号:$serial\n";
        $mail{Message}.="执业机构名称:$lawoffice\n";
        $mail{Message}.="语言:$language\n";
        $mail{Message}.="律师执业证取得日期:$authdate\n";
        $mail{Message}.="备注:$remark\n";
        if (sendmail %mail) {
         #print "content of \$Mail::Sendmail::log:\n$Mail::Sendmail::log\n";
          if ($Mail::Sendmail::error)
           { #print "content of \$Mail::Sendmail::error:\n$Mail::Sendmail::error\n";
             }
              #print "ok 2\n";
              }
              else {
               #print "\n!Error sending mail:\n$Mail::Sendmail::error\n";
                #print "not ok 2\n";
                  }
        print $mt->process_file('pgMessage.htm',{'msg_no'=>"1"});#message 1
}
