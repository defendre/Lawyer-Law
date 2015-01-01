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
my $lawname = new CGI;
print $lawname->header;

# generate METATEXT object
my $mt = Text::MetaText->new(\%mtparam);

#connet to database,get database handler
my $dbh = DBI->connect(@dbiparam) || 
	print "不能连接到数据库！" && return;
 
#get CGI params
my %param;
foreach ($lawname->param) {
    $param{$_} = $lawname->param($_);
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
		&addLawName($param);}
	elsif($cmd eq 'search') {
		&searchLawName($param);}
	elsif($cmd eq 'edit') {
		&editLawName($param);}
	elsif($cmd eq '修  改') {
		&updateLawName($param);}
	elsif($cmd eq '删  除') {
		&delLawName($param);}
	else {
		print "错误指令!!";}

}

sub addLawName
{
	my $param = shift;

    my $dbh = $param->{'DBH'};
    my $mt = $param->{'METATEXT'};
    
    my $area = $param->{'area'};
    my $name = $param->{'name'};
    my $abbr = $param->{'abbr'};
    my $rate = $param->{'rate'};
    my $own = $param->{'own'};

     $abbr = $abbr . ',' . $rate;

    if($area eq '' || $name eq '' || $abbr eq '')
    {
    	&showErrPage($mt,"请输入必要的信息!");
    	return;
    }
    
    my ($isBigarea) = $dbh->selectrow_array(
    	"SELECT count(*) FROM BigArea WHERE name = ?",
    	undef,convert($area));
	
	if($isBigarea == 0)
	{
		&showErrPage($mt,"主库类别填写错误!");
    	return;
	}
	    	
    my ($haveit) = $dbh->selectrow_array(
    	"SELECT count(*) FROM LawName WHERE area =? AND name = ? AND abbr = ?",
    	undef,$area,$name,$abbr);
    
    if($haveit != 0)
    {
    	&showErrPage($mt,"该信息已经存在!");
    	return;
    }
    if($own eq '')
    {
    $dbh->do("INSERT INTO LawName(area,name,abbr) VALUES(?,?,?)",undef,$area,$name,$abbr);
    }
    else
    {
    $dbh->do("INSERT INTO LawName(area,name,abbr,own) VALUES(?,?,?,?)",undef,$area,$name,$abbr,$own);
    }
     &showInfoPage($mt,"记录添加成功!");
}

sub searchLawName
{
	my $param = shift;

    my $dbh = $param->{'DBH'};
    my $mt = $param->{'METATEXT'};
    my  $rate;
	my $result_ref = $dbh->selectall_arrayref(<<__SQL__);
	select t1.id,t1.area,t1.name,t1.abbr,t1.own 
	FROM LawName AS t1,BigArea AS t2 
	WHERE t2.name = t1.area
	ORDER BY t2.abbr,t1.abbr
__SQL__
	
	my $lawnameLine = "";
	for (my $i=0; $i<scalar(@$result_ref); $i++)
	{
		my $arow = $result_ref->[$i];
		my ($id,$area,$name,$abbr,$own) = @$arow;
		   ($abbr,$rate)= split /,/,$abbr;
		$lawnameLine .= $mt->process_file('in_pmLawnameLine.htm',
			{
				'num'  => $i+1,
				'area' => $area,
				'name' => $name,
				'abbr' => $abbr,
				'own'  => $own,
				'id' => $id,
			}); 
	}
	
	print $mt->process_file('in_pgLawname.htm',
		{
			'lawnameline' => $lawnameLine,
		});
}

sub delLawName
{
	my $param = shift;

    my $dbh = $param->{'DBH'};
    my $mt = $param->{'METATEXT'};
    my $id = $param->{'id'};
    my $have = 0;

        my ($area,$name,$abbr,$own) = $dbh->selectrow_array("SELECT area,name,abbr,own FROM LawName WHERE id = ?",undef,$id);
       
        ($have) = $dbh->selectrow_array("SELECT count(*) FROM Law WHERE type = ?",undef,$name);
         
         if($have > 0)
          {
            &showInfoPage($mt,"删除无效!");
          }
          else
          {
            $dbh->do("DELETE FROM LawName WHERE id = ?",undef,$id);
            &showInfoPage($mt,"删除成功!");
          }

	
        #print $have;
	#$dbh->do("DELETE FROM LawName WHERE id = ?",undef,$id);
	#&showInfoPage($mt,"删除成功!");
}

sub editLawName
{
	my $param = shift;

    my $dbh = $param->{'DBH'};
    my $mt = $param->{'METATEXT'};
     my $rate  ;
	my $id = $param->{'id'};
	my $add = $param->{'add'};

	my ($area,$name,$abbr,$own) = $dbh->selectrow_array("SELECT area,name,abbr,own FROM LawName WHERE id = ?",undef,$id);
                 ($abbr,$rate)= split /,/,$abbr;
	print $mt->process_file('in_pgLawnameEdit.htm',
		{
			'area' => $area,
			'name' => $name,
			'abbr' => $abbr,
                                                'rate' => $rate,
                                                'own'  => $own, 
			'id' => $id,
                        'add' => $add,
		});
}

sub updateLawName
{
	my $param = shift;

    my $dbh = $param->{'DBH'};
    my $mt = $param->{'METATEXT'};
	
	my $id = $param->{'id'};
	my $area = $param->{'area'};
	my $name = $param->{'name'};
	my $abbr = $param->{'abbr'};
                my $rate = $param->{'rate'};
               $abbr = $abbr . ',' . $rate;

	my $own  = (!defined($param->{'own'}))?15:$param->{'own'};
	
	if($area eq '' || $name eq '' || $abbr eq '')
    {
    	&showErrPage($mt,"请输入必要的信息!");
    	return;
    }
    
    my ($isBigarea) = $dbh->selectrow_array(
    	"SELECT count(*) FROM BigArea WHERE name = ?",
    	undef,convert($area));
	
	if($isBigarea == 0)
	{
		&showErrPage($mt,"主库类别填写错误!");
    	return;
	}
	
    my ($haveit) = $dbh->selectrow_array(
    	"SELECT count(*) FROM LawName WHERE area = ? AND name = ? AND abbr = ? AND id != ?",
    	undef,$area,$name,$abbr,$id);
    
    if($haveit != 0)
    {
    	&showErrPage($mt,"该信息已经存在!");
    	return;
    }
	
	$dbh->do("UPDATE LawName SET area = ?,name = ?,abbr = ? ,own = ? WHERE id = ?",undef,$area,$name,$abbr,$own,$id);
	
	&showInfoPage($mt,"修改成功!");
}
