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
my $bigarea = new CGI;
print $bigarea->header;

# generate METATEXT object
my $mt = Text::MetaText->new(\%mtparam);

#connet to database,get database handler
my $dbh = DBI->connect(@dbiparam) || 
	print "不能连接到数据库！" && return;
 
#get CGI params
my %param;
foreach ($bigarea->param) {
    $param{$_} = $bigarea->param($_);
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
		&addBigArea($param);}
	elsif($cmd eq 'search') {
		&searchBigArea($param);}
	elsif($cmd eq 'edit') {
		&editBigArea($param);}
	elsif($cmd eq '修  改') {
		&updateBigArea($param);}
	elsif($cmd eq '删  除') {
		&delBigArea($param);}
	else {
		print "错误指令!!";}

}

sub addBigArea
{
	my $param = shift;

    my $dbh = $param->{'DBH'};
    my $mt = $param->{'METATEXT'};
    
    my $name = $param->{'name'};
    my $abbr = $param->{'abbr'};
    my $own = $param->{'own'};
    
    if($name eq '' || $abbr eq '')
    {
    	&showErrPage($mt,"请输入必要的信息!");
    	return;
    }
    
    my ($haveit) = $dbh->selectrow_array(
    	"SELECT count(*) FROM BigArea WHERE name = ? AND abbr = ?",
    	undef,$name,$abbr);
    
    if($haveit != 0)
    {
    	&showErrPage($mt,"该信息已经存在!");
    	return;
    }
    if($own eq '')
    {
    $dbh->do("INSERT INTO BigArea(name,abbr) VALUES(?,?)",undef,$name,$abbr);
    }
    else
    {
    $dbh->do("INSERT INTO BigArea(name,abbr,own) VALUES(?,?,?)",undef,$name,$abbr,$own);
    }
    &showInfoPage($mt,"记录添加成功!");
}

sub searchBigArea
{
	my $param = shift;

    my $dbh = $param->{'DBH'};
    my $mt = $param->{'METATEXT'};

	my $result_ref = $dbh->selectall_arrayref("SELECT * FROM BigArea ORDER BY abbr");
	
	my $bigareaLine = "";
	for (my $i=0; $i<scalar(@$result_ref); $i++)
	{
		my $arow = $result_ref->[$i];
		my ($id,$name,$abbr,$own) = @$arow;
		
		$bigareaLine .= $mt->process_file('in_pmBigareaLine.htm',
			{
				'num'  => $i+1,
				'name' => $name,
				'abbr' => $abbr,
                                'own'  => $own,
				'id' => $id,
			}); 
	}
	
	print $mt->process_file('in_pgBigarea.htm',
		{
			'bigarealine' => $bigareaLine,
		});
}

sub delBigArea
{
	my $param = shift;

    my $dbh = $param->{'DBH'};
    my $mt = $param->{'METATEXT'};
    my $id = $param->{'id'};
    my $have_Lawyer=0;
    my $have=0;
        
        my ($name,$abbr,$own) = $dbh->selectrow_array("SELECT name,abbr,own FROM BigArea WHERE id = ?",undef,$id);

	($have) =  $dbh->selectrow_array("select count(*) from LawName where area LIKE ? ",undef,$name);
        ($have_Lawyer) = $dbh->selectrow_array("select count(*) from Law where area LIKE ? ",undef,$name);
       
        if($have_Lawyer > 0 || $have > 0)
          {
            &showInfoPage($mt,"删除无效!");
          }
          else
          {
            $dbh->do("DELETE FROM BigArea WHERE id = ?",undef,$id);
            &showInfoPage($mt,"删除成功!");
          }

        #print $have,$have_Lawyer;
     	#$dbh->do("DELETE FROM BigArea WHERE id = ?",undef,$id);
	#&showInfoPage($mt,"删除成功!");
}

sub editBigArea
{
	my $param = shift;

    my $dbh = $param->{'DBH'};
    my $mt = $param->{'METATEXT'};
	
	my $id = $param->{'id'};
        my $add = $param->{'add'};
	
	my ($name,$abbr,$own) = $dbh->selectrow_array("SELECT name,abbr,own FROM BigArea WHERE id = ?",undef,$id);
	
	print $mt->process_file('in_pgBigareaEdit.htm',
		{
			'name' => $name,
			'abbr' => $abbr,
                        'own'  => $own, 
			'id' => $id,
                        'add' => $add,
		});
}

sub updateBigArea
{
	my $param = shift;

    my $dbh = $param->{'DBH'};
    my $mt = $param->{'METATEXT'};
	
	my $id = $param->{'id'};
	my $name = $param->{'name'};
	my $abbr = $param->{'abbr'};
        my $own  = (!defined($param->{'own'}))?15:$param->{'own'};
        
	
	#if($name eq '' || $abbr eq '' || $own eq '')
    #{
    #	&showErrPage($mt,"请输入必要的信息!");
    # 	return;
    #}
    
    if($name eq '' || $abbr eq '')
    {
    	&showErrPage($mt,"请输入必要的信息!");
    	return;
    }
    
    my ($haveit) = $dbh->selectrow_array(
    	"SELECT count(*) FROM BigArea WHERE name = ? AND abbr = ? AND id != ?",
    	undef,$name,$abbr,$id);
    
    if($haveit != 0)
    {
    	&showErrPage($mt,"该信息已经存在!");
    	return;
    }
	
	$dbh->do("UPDATE BigArea SET name = ?,abbr = ?,own = ? WHERE id = ?",undef,$name,$abbr,$own,$id);
	
	&showInfoPage($mt,"修改成功!");
}
