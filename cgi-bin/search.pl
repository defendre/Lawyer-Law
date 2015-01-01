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
my $search = new CGI;
#my $password = $search->cookie("password");
#my $name = $search->cookie("name");   


#unless($password && $name)
#{
# my $cookie = $search->cookie(-name => "name",
#                            -value => $search->param('name'));
# my $cookie1 =$search->cookie(-name => "password",
#                            -value => $search->param('password'));                    
#print $search->header(-cookie =>[$cookie,$cookie1]);
#}
#else
#{
print $search->header;
#}

# generate METATEXT object
my $mt = Text::MetaText->new(\%mtparam);

#connet to database,get database handler
my $dbh = DBI->connect(@dbiparam) || 
	print "不能连接到数据库！" && return;
 
#get CGI params
my %param;
foreach ($search->param) {
    $param{$_} = $search->param($_);
    #print "$param{$_}<br>\n";
}

$param{'DBH'} = $dbh;
$param{'METATEXT'} = $mt;
#$param{'SEARCH'} = $search;

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
		&searchLawyer($param);}
	elsif($typ eq '1') {
		&searchLawOffice($param);}
	elsif($typ eq '2') {
		&searchLaw($param);}
	else {
		print "错误指令!!";}
}

sub searchLawyer
{
	my $param = shift;
	
    my $dbh = $param->{'DBH'};
    my $mt = $param->{'METATEXT'};
    
    my $howMany = 100;
    
    my $area = (!defined($param->{'area'}))?"":$param->{'area'};
    $area = convert($area);
    
    my $province = (!defined($param->{'province'}))?"":$param->{'province'};
    $province = c_replace($province, qw( 　 省 市), ' ');
	#$province =~ s/ //;

    my $city = (!defined($param->{'city'}))?"":$param->{'city'};
    $city = c_replace($city, qw( 　 省 市), ' ');
        #$city =~ s/ //;
        if ($city=~/[a-z]|[A-Z]/)
           {
            $city = uc($city);
           }
    my $language = (!defined($param->{'language'}))?"":$param->{'language'};
    my $name = (!defined($param->{'name'}))?"":$param->{'name'};

    $name = uc($name);

        
	if($name eq '' 
		&& ($province eq '' 
			|| $area eq ''
			|| ((!$province eq '' && !isCouncilCity($dbh,$province) && $city eq ''))))
	{
		print $mt->process_file('pgLawyerErrPage.htm',{'error_no'=>"1"});#error 1
    	return;
	}
	
   	my $start = (!defined($param->{'start'}))?1:$param->{'start'};
   	
	my $num = $start;
	
	my $upStart = $start - $howMany;
	my $downStart = $start + $howMany;
	
	my $offset = $start - 1;
	my $resultSum = 0;
    
    my ($result_ref);
    my $isNameSearch = 0;
    if(!$name eq '')
    {
    	$isNameSearch = 1;
    	($resultSum) = $dbh->selectrow_array(<<__SQL__,undef,"$name");
    	SELECT count(id)
    	FROM Lawyer 
    	WHERE concat(lastname_cn,firstname_cn) = ? 
    	ORDER BY lastname_en,firstname_en
__SQL__
    	
    	$result_ref = $dbh->selectall_arrayref(<<__SQL__,undef,"$name");
    	SELECT id,concat(lastname_cn,firstname_cn) AS name,concat(province," ",city) AS zone,areacode,tel,fax,language,law_office,website,email1,email2
    	FROM Lawyer 
    	WHERE concat(lastname_cn,firstname_cn) = ? 
    	ORDER BY disp_level,lastname_en,firstname_en
    	LIMIT $offset,$howMany
__SQL__
    }
    elsif(!$area eq '')
    {
		my $resultSumTmp = $dbh->selectall_arrayref(<<__SQL__,undef,"%$province%","%$city%","%$language%","%$area%");
		SELECT t1.id
		FROM Lawyer AS t1,Lawyer_LawArea AS t2
		WHERE (t1.province LIKE ? AND t1.city LIKE ? AND t1.language LIKE ? AND t2.area_name LIKE ? AND t1.id=t2.lawyer_id)
			AND ((t2.area_order =1 AND CURRENT_DATE NOT BETWEEN t1.service_from_date AND t1.service_to_date)
				OR (t2.area_order<=5 AND  t1.service_type =1 AND CURRENT_DATE BETWEEN t1.service_from_date AND t1.service_to_date)
				OR (t2.area_order<=9 AND  t1.service_type =2 AND CURRENT_DATE BETWEEN t1.service_from_date AND t1.service_to_date))
		GROUP BY t1.id
__SQL__
		
		$resultSum = scalar(@$resultSumTmp);
		
		$result_ref = $dbh->selectall_arrayref(<<__SQL__,undef,"%$province%","%$city%","%$language%","%$area%");
		SELECT t1.id,concat(t1.lastname_cn,t1.firstname_cn) AS name,concat(t1.province," ",t1.city) AS zone,t1.areacode,t1.tel,t1.fax,t1.language,t1.law_office,t1.website,t1.email1,t1.email2
		FROM Lawyer AS t1,Lawyer_LawArea AS t2
		WHERE (t1.province LIKE ? AND t1.city LIKE ? AND t1.language LIKE ? AND t2.area_name LIKE ? AND t1.id=t2.lawyer_id)
		AND ((t2.area_order =1 AND CURRENT_DATE NOT BETWEEN t1.service_from_date AND t1.service_to_date)
			OR (t2.area_order<=5 AND  t1.service_type =1 AND CURRENT_DATE BETWEEN t1.service_from_date AND t1.service_to_date)
			OR (t2.area_order<=9 AND  t1.service_type =2 AND CURRENT_DATE BETWEEN t1.service_from_date AND t1.service_to_date))
		GROUP BY t1.id
		ORDER BY t1.disp_level,t1.lastname_en,t1.firstname_en
		LIMIT $offset,$howMany
__SQL__
		
    }
    else
    {
    	$resultSum = $dbh->selectrow_array(<<__SQL__,undef,"%$province%","%$city%","%$language%");
    	SELECT count(*)
		FROM Lawyer WHERE province LIKE ? AND city LIKE ? AND language LIKE ?
__SQL__
		

    	$result_ref = $dbh->selectall_arrayref(<<__SQL__,undef,"%$province%","%$city%","%$language%");
		SELECT id,concat(lastname_cn,firstname_cn) AS name,concat(province," ",city) AS zone,areacode,tel,fax,language,law_office,website,email1,email2
		FROM Lawyer WHERE province LIKE ? AND city LIKE ? AND language LIKE ?
		ORDER BY disp_level,lastname_en,firstname_en
		LIMIT $offset,$howMany
__SQL__
		
	}
	
	if($resultSum == 0)
	{
    	if($isNameSearch == 1)
    	{
    		print $mt->process_file('pgLawyerErrPage.htm',{'error_no'=>"3"});#error 3
    		return;
    	}
    	print $mt->process_file('pgLawyerErrPage.htm',{'error_no'=>"0"});#error 0
    	return;		
	}
	
	my $searchLawyerResLine = "";
	
	
	for (my $i=0; $i<scalar(@$result_ref); $i++)
    {
		my $arow = $result_ref->[$i];
		my ($id,$name,$zone,$areacode,$tel,$fax,$language,$lawoffice_id,$website,$email1,$email2) = @$arow;
		my $area1 = "";
                my $email = "";

                if($isNameSearch == 1)
                {
                    $area1 = &getLawyer_LawArea($dbh,$id,1);
                }
                else
                {
                    $area1 = $area;
                }
		my $lawoffice = "";
		if($lawoffice_id != 0)
		{
			$lawoffice = getLawOfficeName($dbh,$lawoffice_id);
		}
		
		#format telephone and fax
		$tel = $areacode . "-" . $tel if(!($areacode eq "") && !($tel eq ""));
		$fax = $areacode . "-" . $fax if(!($areacode eq "") && !($fax eq ""));
                $email = $email1;

            if($email1 eq '' && $email2){ $email =  $email2;
             }
             elsif($email2 eq  ''  && $email1 eq ''){ $email = "无邮址";
             }
	     $website = "无网址" if($website eq '');

		$searchLawyerResLine .= $mt->process_file('pmLawyerSearchResLine.htm', 
							{
								'num' => "$num",
								'id' => "$id",
								'name' => "$name",
								'zone' => "$zone",
								'tel'=> "$tel",
								'fax'=> "$website",#$website
                                                                'email' => "$email",#email
								'lawoffice' => "$lawoffice",
								'lawoffice_id'=>"$lawoffice_id",
								'language' => "$language",
								'area' => "$area1",
							});
		$num += 1;
    }
    
    my $downLink = ($downStart <= $resultSum && $resultSum > $howMany)?1:0;
    
    print $mt->process_file('pgLawyerSearchRes.htm',
    					{
    						'start' => "$start",
    						'downlink' => "$downLink",
    						'upstart' => "$upStart",
    						'downstart' => "$downStart",
    						'resultsum' => "$resultSum",
    						'lawyersearchresline' => "$searchLawyerResLine",
    						'area' => "$area",
    						'province' => "$province",
    						'city' => "$city",
    						'language' => "$language",
    						'name' => "$name",
    					});
}

sub searchLawOffice
{
	my $param = shift;

    my $dbh = $param->{'DBH'};
    my $mt = $param->{'METATEXT'};
    
    my $howMany = 100;
    
    my $area = (!defined($param->{'area'}))?"":$param->{'area'};
    $area = convert($area);
    
    my $province = (!defined($param->{'province'}))?"":$param->{'province'};
    $province = c_replace($province, qw( 　 省 市), ' ');
	#$province =~ s/ //;
    
    my $city = (!defined($param->{'city'}))?"":$param->{'city'};
	$city = c_replace($city, qw( 　 省 市), ' ');
        #$city =~ s/ //;
        #$city = uc($ctiy);
        if ($city=~/[a-z]|[A-Z]/)
           {
            $city = uc($city);
           }
    my $language = (!defined($param->{'language'}))?"":$param->{'language'};
    my $name = (!defined($param->{'name'}))?"":$param->{'name'};

    $name = uc($name);

	if($name eq '' 
		&& ($province eq '' 
			|| $area eq ''
			|| ((!$province eq '' && !isCouncilCity($dbh,$province) && $city eq ''))))
	{
    	print $mt->process_file('pgLawOfficeErrPage.htm',{'error_no'=>"0"});#error 0
    	return;
	}

   	my $start = (!defined($param->{'start'}))?1:$param->{'start'};
   	
	my $num = $start;
	
	my $upStart = $start - $howMany;
	my $downStart = $start + $howMany;
	
	my $offset = $start - 1;
	my $resultSum = 0;
    
    my ($result_ref);
    my $isNameSearch = 0;
    if(!$name eq '')
    {
    	$isNameSearch = 1;
    	($resultSum) = $dbh->selectrow_array(<<__SQL__,undef,"%$name%");
    	SELECT count(*)
    	FROM LawOffice WHERE sname LIKE ?
__SQL__
    	
    	$result_ref = $dbh->selectall_arrayref(<<__SQL__,undef,"%$name%");
    	SELECT id,name_cn,concat(province," ",city) AS zone,areacode,tel,fax,language,website,email1,email2
    	FROM LawOffice WHERE sname LIKE ? 
    	ORDER BY disp_level,name_en
    	LIMIT $offset,$howMany
__SQL__
    	
    }
    elsif(!$area eq '')
    {
		my $resultSumTmp = $dbh->selectall_arrayref(<<__SQL__,undef,"%$province%","%$city%","%$language%","%$area%");
		SELECT count(t1.id)
		FROM LawOffice AS t1,LawOffice_LawArea AS t2
		WHERE (t1.province LIKE ? AND t1.city LIKE ? AND t1.language LIKE ? AND t2.area_name LIKE ? AND t1.id=t2.lawoffice_id)
			AND ((t2.area_order <=2 AND CURRENT_DATE NOT BETWEEN t1.service_from_date AND t1.service_to_date)
			OR (t2.area_order<=6 AND  t1.service_type =1 AND CURRENT_DATE BETWEEN t1.service_from_date AND t1.service_to_date)
			OR (t2.area_order<=10 AND  t1.service_type =2 AND CURRENT_DATE BETWEEN t1.service_from_date AND t1.service_to_date))
		GROUP BY t1.id
__SQL__

		$resultSum = scalar(@$resultSumTmp);
		
		$result_ref = $dbh->selectall_arrayref(<<__SQL__,undef,"%$province%","%$city%","%$language%","%$area%");
		SELECT t1.id,name_cn,concat(t1.province," ",t1.city) AS zone,t1.areacode,t1.tel,t1.fax,t1.language,t1.website,t1.email1,t1.email2
		FROM LawOffice AS t1,LawOffice_LawArea AS t2
		WHERE (t1.province LIKE ? AND t1.city LIKE ? AND t1.language LIKE ? AND t2.area_name LIKE ? AND t1.id=t2.lawoffice_id)
			AND ((t2.area_order <=2 AND CURRENT_DATE NOT BETWEEN t1.service_from_date AND t1.service_to_date)
			OR (t2.area_order<=6 AND  t1.service_type =1 AND CURRENT_DATE BETWEEN t1.service_from_date AND t1.service_to_date)
			OR (t2.area_order<=10 AND  t1.service_type =2 AND CURRENT_DATE BETWEEN t1.service_from_date AND t1.service_to_date))
		GROUP BY t1.id
		ORDER BY t1.disp_level,t1.name_en
		LIMIT $offset,$howMany
__SQL__
    }
    else
    {
    	$resultSum = $dbh->selectrow_array(<<__SQL__,undef,"%$province%","%$city%","%$language%");
    	SELECT count(id)
		FROM LawOffice WHERE province LIKE ? AND city LIKE ? AND language LIKE ?
__SQL__

    	$result_ref = $dbh->selectall_arrayref(<<__SQL__,undef,"%$province%","%$city%","%$language%");
		SELECT id,name_cn,concat(province," ",city) AS zone,areacode,tel,fax,language,website,email1,email2
		FROM LawOffice WHERE province LIKE ? AND city LIKE ? AND language LIKE ?
		ORDER BY disp_level,name_en
		LIMIT $offset,$howMany
__SQL__
	}
	
	if($resultSum == 0)
	{
    	if($isNameSearch == 1)
    	{
    		print $mt->process_file('pgLawOfficeErrPage.htm',{'error_no'=>"3"});#error 3
    		return;
    	}
    	print $mt->process_file('pgLawOfficeErrPage.htm',{'error_no'=>"1"});#error 1
    	return;
	}
	
	my $searchLawOfficeResLine = "";
	for (my $i=0; $i<scalar(@$result_ref); $i++)
    {
		my $arow = $result_ref->[$i];
		my ($id,$name,$zone,$areacode,$tel,$fax,$language,$website,$email1,$email2) = @$arow;
		my $area1 = "";
                my $email = "";
                if($isNameSearch == 1) 
                {
                    $area1 = &getLawOffice_LawArea($dbh,$id,1);
                }
                else
                {
                    $area1 = $area;
                }

		#format telephone and fax
		$tel = $areacode . "-" . $tel if(!($areacode eq "") && !($tel eq ""));
		$fax = $areacode . "-" . $fax if(!($areacode eq "") && !($fax eq ""));
                $email = $email1;

            if($email1 eq '' && $email2){ $email =  $email2;
             }
             elsif($email2 eq  ''  && $email1 eq ''){ $email = "无邮址";
             }
	     $website = "无网址" if($website eq '');
		
		$searchLawOfficeResLine .= $mt->process_file('pmLawOfficeSearchResLine.htm', 
							{
								'num' => "$num",
								'id' => "$id",
								'name' => "$name",
								'zone' => "$zone",
								'tel'=> "$tel",
								'fax'=> "$website",#$website
	                                                        'email'=> "$email",#$email
								'language' => "$language",
								'area' => "$area1",
							});
		$num += 1;
    }
    
    my $downLink = ($downStart <= $resultSum && $resultSum > $howMany)?1:0;
    
    print $mt->process_file('pgLawOfficeSearchRes.htm',
    					{
    						'start' => "$start",
    						'downlink' => "$downLink",
    						'upstart' => "$upStart",
    						'downstart' => "$downStart",
    						'resultsum' => "$resultSum",    						
    						'lawofficesearchresline' => "$searchLawOfficeResLine",
    						'area' => "$area",
    						'province' => "$province",
    						'city' => "$city",
    						'language' => "$language",
    						'name' => "$name",
    					});
}

sub searchLaw
{
	my $param = shift;

    my $dbh = $param->{'DBH'};
    my $mt = $param->{'METATEXT'};
    #my $search = $param->{'SEARCH'};
    my $cdate;
    my $howMany = 20;
    
   	my $area = (!defined($param->{'area'}))?"":$param->{'area'};
   	$area = convert($area);
        my $cmd = (!defined($param->{'cmd'}))?0:$param->{'cmd'};
	
   	my $type = (!defined($param->{'type'}))?"":$param->{'type'};
   	$type = $param->{'sel_type'} if(!$param->{'sel_type'} eq "");
   	$type = convert($type);
   	
	my $title = (!defined($param->{'title'}))?"":$param->{'title'};
	my $keyword = (!defined($param->{'keyword'}))?"":$param->{'keyword'};
        my $iown;
        my $link = (!defined($param->{'Sum_Reg'}))?0:$param->{'Sum_Reg'}; 
          
        my $Lawyer_id = 0;

my @councilCity = ('TS工时统计','案件开支统计','案件帐单统计','办公开支统计','帐单收入统计','财产管理统计');
 foreach (@councilCity)
        {
            ($keyword,$cdate)=split(/\//,$keyword) if($area eq $_);
        }   
   
    if($type eq '' && $area eq '')
    {
   	print $mt->process_file('pgLawErrPage.htm',{'error_no'=>"0"});#error 0
   	return;
    }

       
        ###################
        #Name from BigArea 
        ###################
        my $Sum_Reg = 0;

        my $name = (!defined($param->{'name'}))?"":$param->{'name'};
        my $password = (!defined($param->{'password'}))?"":$param->{'password'};
        #my $name = $search->cookie("name");
        #my $password = $search->cookie("password"); 
        
        
        $iown =$dbh->selectrow_array(<<__SQL__,undef,"%$area%");
                SELECT name FROM BigArea
                WHERE (own LIKE "%.0" OR own LIKE "%.2") AND name LIKE ?
__SQL__
        ###################
       
       

      
        #Reg 用户存在与否!  
        if($iown eq $area)
          {
            ($Sum_Reg,$Lawyer_id) = $dbh->selectrow_array(<<__SQL__,undef,$name,$password);
	    SELECT count(*),id
            FROM Lawyer 
            WHERE  concat(lastname_cn,firstname_cn) = ? AND password_date = ?
            GROUP BY id
__SQL__
          }
          
         my $lawName = selectLawyer($dbh,$mt,$Lawyer_id);
            $lawName = "" if($link == 1);       
          

         
        #################################
        #Reg用户是否有效！
       
       if($iown eq $area && $Lawyer_id == 0 && $name)
    {
   	print $mt->process_file('pgLawErrPage.htm',{'error_no'=>"2"});#error 0
   	return;
    }
                
       ###################################  

      
       
   	my $start = (!defined($param->{'start'}))?1:$param->{'start'};
   	
	my $num = $start;
	
	my $upStart = $start - $howMany;
	my $downStart = $start + $howMany;
	
	my $offset = $start - 1;
	my $resultSum = 0;


        


    my $result_ref;
    my $searchLawResLine = "";
    my $titleStr = "";
    
    #SELECT count(DISTINCT area,type) FROM Law WHERE area LIKE ?
    #if($type eq '' && $title eq '' && $keyword eq '')
    #{
#    	
    #    my $resultSumTmp = $dbh->selectall_arrayref(
    #		"SELECT DISTINCT area,type FROM Law WHERE area LIKE ?"
    # 		,undef,"%$area%");
    # 	$resultSum = scalar(@$resultSumTmp);
#	
#    	$result_ref = $dbh->selectall_arrayref(<<__SQL__,undef,"%$area%");
#    	SELECT DISTINCT area,type FROM Law WHERE area LIKE ?
#    	LIMIT $offset,$howMany
#__SQL__
    		          


    	#for (my $i=0; $i<scalar(@$result_ref); $i++)
    	#{
#			my $arow = $result_ref->[$i];
#			my ($area,$type) = @$arow;
#            if($cmd)
#            {
#            $searchLawResLine .= $mt->process_file('pmLawSearchResLine.htm',
#                                                 {
#                                                       'num' => "$num",
#                                                       area => "$area",
#                                                      type => "$type",
#                                                     title => "",
#                                                     keyword => "",
#                                                                });
#            }
#            else
#               {
#			$searchLawResLine .= $mt->process_file('pmLawSearchResLine.htm', 
#								{
#								'num' => "$num",
#								area => "$area",
#								type => "$type",
#								title => "",
#								keyword => "",
#								});
#                    }            
#			$num += 1;
#		}
#    }
#    else
#    {
        if ($title eq '' && $link == 1){  

        $result_ref = $dbh->selectall_arrayref(<<__SQL__,undef,"%$area%","%$type%","%#%","%$keyword%");
    	SELECT id,area,type,title,keyword,cdate
    	FROM Law 
    	WHERE area LIKE ? AND type LIKE ? AND title NOT LIKE ? AND keyword LIKE ?
        ORDER BY area,type,title
    	LIMIT $offset,$howMany
__SQL__
        

        $resultSum = scalar(@$result_ref);

         ($resultSum) = $dbh->selectrow_array(<<__SQL__,undef,"%$area%","%$type%","%#%","%$keyword%","%$cdate%");
    	SELECT count(id)
    	FROM Law 
    	WHERE area LIKE ? AND type LIKE ? AND title NOT LIKE ? AND keyword LIKE ? AND cdate LIKE ?
__SQL__

                                       }    	
                                       else{
        ($resultSum) = $dbh->selectrow_array(<<__SQL__,undef,"%$area%","%$type%","%$title%","%$keyword%","%$cdate%");
    	SELECT count(id)
    	FROM Law 
    	WHERE area LIKE ? AND type LIKE ? AND title LIKE ? AND keyword LIKE ?  AND cdate LIKE ?
__SQL__
    		
    	$result_ref = $dbh->selectall_arrayref(<<__SQL__,undef,"%$area%","%$type%","%$title%","%$keyword%","%$cdate%");
    	SELECT id,area,type,title,keyword,cdate
    	FROM Law 
    	WHERE area LIKE ? AND type LIKE ? AND title LIKE ? AND keyword LIKE ?  AND cdate LIKE ?
        ORDER BY area,type,title
    	LIMIT $offset,$howMany
__SQL__
    		                           }
    	
    	for (my $i=0; $i<scalar(@$result_ref); $i++)
    	{
			my $arow = $result_ref->[$i];
			my ($res_id,$res_area,$res_type,$res_title,$res_keyword,$res_cdate) = @$arow;
	
               $titleStr = $mt->process_file('pmLawSearchResLine_title.htm', 
			{id => "$res_id", title => "$res_title"});
        
	 if($res_area eq 'TS工时统计' || $res_area eq  '案件开支统计' || $res_area eq '案件帐单统计' || $res_area eq '帐单收入统计')
                   {
                $searchLawResLine .= $mt->process_file('pmLawSearchResLine.htm', {
                                                'num' => "$num",
                                                'area' => "$res_area",
                                                'type' => "$res_type",
                                                'title' => "$titleStr",
                                                'keyword' => "$res_keyword"."/"."$res_cdate",
                                                                });
                   }
                   else
                   {

                $searchLawResLine .= $mt->process_file('pmLawSearchResLine.htm', {
                                                'num' => "$num",
                                                'area' => "$res_area",
                                                'type' => "$res_type",
                                                'title' => "$titleStr",
                                                'keyword' => "$res_keyword",
                                                                });

                    }         
                
         	
			$num += 1;
		}
    
    
    if($resultSum == 0)
    {
    	print $mt->process_file('pgLawErrPage.htm',{'error_no'=>"1"});#error 1
    	return;
    }
    
    my $downLink = ($downStart <= $resultSum && $resultSum > $howMany)?1:0;
  

       $link = 0 if($name eq "" && $password eq "");
       $link = 1 if($lawName ne "" && $name ne "" && $password ne "");
       $link = 2 if($lawName eq "" && $name ne "" && $password ne "");
       
     
      #$link = 1 if($link == 2 && $downLink == 1);

    ###############################################
    #出现验证页面！
    
    
   
       
#if($iown eq $area  &&  ($link == 0 && $lawName eq "" )  || (($link == 1 && ($lawName ne "" || $lawName eq "") && $name ne "" && $password ne "") || ($link == 2 && $lawName ne ""))) 
   if($iown eq $area  &&  ($link == 0 && $lawName eq "" )  || (($link == 1 && ($lawName ne "") && $name ne "" && $password ne "") || ($link == 2 && $lawName ne "")))

    {
        
        print $mt->process_file('in_pmLawReg.htm',
                               {
                                'area' => "$area",
                                'type' => "$type",
                                'title' => "$title",
                                'keyword' => "$keyword",
                                'lawnameline'           => "$lawName",
                                'name'              => "$name",
                                'password'              => "$password",
                                'Sum_Reg'              => "$link",
                                'link'              => "$link"
                               });  

    }
    else
    {
      print $mt->process_file('pgLawSearchRes.htm',
                                        {
                                                'start' => "$start",
                                                'downlink' => "$downLink",
                                                'upstart' => "$upStart",
                                                'downstart' => "$downStart",
                                                'resultsum' => "$resultSum",

                                                'lawsearchresline' => "$searchLawResLine",
                                                'area' => "$area",
                                                'type' => "$type",
                                                'title' => "$title",
                                                'keyword' => "$keyword",
                                                'name'    => "$name",
                                                'password' => "$password",
                                                'Sum_Reg'  => "$Sum_Reg",
                                        });
  

  }
}
