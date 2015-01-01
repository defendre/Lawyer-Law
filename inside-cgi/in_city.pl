#!/usr/bin/perl -w
use strict;
use CGI;
use DBI;
use Text::MetaText;
use lib "/home/fahai/cgi-tools";

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
my $city = new CGI;
print $city->header;
# generate METATEXT object
my $mt = Text::MetaText->new(\%mtparam);



#connet to database,get database handler
my $dbh = DBI->connect(@dbiparam) || 
	print "不能连接到数据库！" && return;

 

#get CGI params
my %param;
foreach ($city->param) {
    $param{$_} = $city->param($_);
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
		&addCity($param);}
	elsif($cmd eq 'search') {
		&searchCity($param);}
	elsif($cmd eq 'edit') {
		&editCity($param);}
	elsif($cmd eq '修  改') {
		&updateCity($param);}
	elsif($cmd eq '删  除') {
		&delCity($param);}
	else {
		print "错误指令!!";}



}



sub addCity
{
	my $param = shift;

    my $dbh = $param->{'DBH'};
    my $mt = $param->{'METATEXT'};
   

    my $province = $param->{'province'};
    my $p_abbr = $param->{'p_abbr'};
    my $city = $param->{'city'};
    my $c_abbr = $param->{'c_abbr'};

    

    if($province eq '' || $p_abbr eq '')
    {
    	&showErrPage($mt,"请输入必要的信息!");
    	return;
    }

    

    if($city eq '')
    {
    	$city = "nil";
    	$c_abbr = "";
    }

    else
    {
    	if($c_abbr eq '')
    	{
    		&showErrPage($mt,"请输入市/县的拼音!");
    		return;
    	}

        my ($isProvince) = $dbh->selectrow_array(
    	"SELECT count(*) FROM District WHERE province = ? AND city = ?",
    	undef,convert($province),"nil");
        
        my ($isp_abbr) = $dbh->selectrow_array(
    	"SELECT count(*) FROM District WHERE p_abbr = ? AND city = ?",
    	undef,convert($p_abbr),"nil");

	
	if($isProvince == 0)
	{
	&showErrPage($mt,"省/直辖市填写错误!");
    	return;
	}   
     
        if($isp_abbr == 0)
	{
	&showErrPage($mt,"省/直辖市的拼音填写错误!");
    	return;
	}     
    }

    

    my ($haveit) = $dbh->selectrow_array(
    	"SELECT count(*) FROM District WHERE province = ? AND city = ?",
    	undef,$province,$city);

    

    if($haveit != 0)
    {
    	&showErrPage($mt,"该信息已经存在!");
    	return;

    }

    

    $dbh->do("INSERT INTO District(province,p_abbr,city,c_abbr) VALUES(?,?,?,?)",
    	undef,$province,$p_abbr,$city,$c_abbr);


    &showInfoPage($mt,"记录添加成功!");
}



sub searchCity
{
	my $param = shift;
    my $dbh = $param->{'DBH'};
    my $mt = $param->{'METATEXT'};

	my $result_ref = $dbh->selectall_arrayref("SELECT * FROM District ORDER BY p_abbr,c_abbr");


	my $cityLine = "";
	for (my $i=0; $i<scalar(@$result_ref); $i++)
	{
		my $arow = $result_ref->[$i];
		my ($id,$province,$p_abbr,$city,$c_abbr) = @$arow;
	

		$city = "" if($city eq 'nil');
		$cityLine .= $mt->process_file('in_pmCityLine.htm',

			{

				'province' => $province,
				'p_abbr' => $p_abbr,
				'city' => $city,
				'c_abbr' => $c_abbr,
				'id' => $id,

			}); 

	}

	

	print $mt->process_file('in_pgCity.htm',
		{
			'cityline' => $cityLine,
		});

}



sub delCity
{
	my $param = shift;
    my $dbh = $param->{'DBH'};
    my $mt = $param->{'METATEXT'};
    my $id = $param->{'id'};
    my $have_Lawyer=0;
    my $have_LawOffice=0;
    my $it_Lawyer=0;
    my $it_LawOffice=0;
    my $province_id=0;

    my ($province,$p_abbr,$city,$c_abbr) = $dbh->selectrow_array(
		"SELECT province,p_abbr,city,c_abbr FROM District WHERE id = ?",undef,$id);

    ($province_id) = $dbh->selectrow_array(
		"select count(*) from District where province LIKE ?",undef,$province);
    ($have_Lawyer) = $dbh->selectrow_array(
		"select count(*) from Lawyer  where city LIKE ?",undef,$city);
    ($have_LawOffice) = $dbh->selectrow_array(
		"select count(*) from LawOffice where city LIKE ?",undef,$city);
    ($it_Lawyer) = $dbh->selectrow_array(
		"select count(*) from Lawyer where province LIKE ?",undef,$province);
    ($it_LawOffice) = $dbh->selectrow_array(
		"select count(*) from LawOffice where province LIKE ?",undef,$province);



    if($c_abbr)
     {
         if($have_Lawyer > 0 || $have_LawOffice > 0)
          {
            &showInfoPage($mt,"删除无效!");
          }
          else
          {
            $dbh->do("DELETE FROM District WHERE id = ?",undef,$id);
            &showInfoPage($mt,"删除成功!");
          }
     }
     else
     {
          if($it_Lawyer > 0 || $it_LawOffice > 0 || $province_id > 1)
          {
            &showInfoPage($mt,"删除无效!");
          }
          else
          {
            $dbh->do("DELETE FROM District WHERE id = ?",undef,$id);
            &showInfoPage($mt,"删除成功!");
          }
     }



#print "Lawyer:$it_Lawyer,$have_Lawyer   LawOffice:$it_LawOffice,$have_LawOffice   $province_id"; 

            
}



sub editCity
{
	my $param = shift;

    my $dbh = $param->{'DBH'};
    my $mt = $param->{'METATEXT'};

	
	my $id = $param->{'id'};
	my ($province,$p_abbr,$city,$c_abbr) = $dbh->selectrow_array(
		"SELECT province,p_abbr,city,c_abbr FROM District WHERE id = ?",undef,$id);


	print $mt->process_file('in_pgCityEdit.htm',
		{
			'province' => $province,
			'p_abbr' => $p_abbr,
			'city' => $city,
			'c_abbr' => $c_abbr,
			'id' => $id,
		});

}



sub updateCity
{
    my $param = shift;
    my $dbh = $param->{'DBH'};
    my $mt = $param->{'METATEXT'};


	my $id = $param->{'id'};
	my $province = $param->{'province'};
    my $p_abbr = $param->{'p_abbr'};
    my $city = $param->{'city'};
    my $c_abbr = $param->{'c_abbr'};

    my ($isProvince) = $dbh->selectrow_array(
    	"SELECT count(*) FROM District WHERE province = ? AND city = ?",
    	undef,convert($province),"nil");

    my ($isp_abbr) = $dbh->selectrow_array(
    	"SELECT count(*) FROM District WHERE p_abbr = ? AND city = ?",
    	undef,convert($p_abbr),"nil");



    if($province eq '' || $p_abbr eq '')
    {
    	&showErrPage($mt,"请输入必要的信息!");
    	return;
    }

    

    if($city eq '')
    {
    	$city = "nil";
    	$c_abbr = "";
    }
    else
    {
    	if($c_abbr eq '' && $city ne "nil")
    	{
    		&showErrPage($mt,"请输入市/县的拼音!");
    		return;

    	}
        
        
	
	if($isProvince == 0)
	{
	&showErrPage($mt,"省/直辖市填写错误!");
    	return;
	}    

        if($isp_abbr == 0)
	{
	&showErrPage($mt,"省/直辖市的拼音填写错误!");
    	return;
	}    
    }

	

	$dbh->do("UPDATE District SET province = ?,p_abbr = ?,city = ?,c_abbr = ? WHERE id = ?",

		undef,$province,$p_abbr,$city,$c_abbr,$id);

	

	&showInfoPage($mt,"修改成功!");
}

