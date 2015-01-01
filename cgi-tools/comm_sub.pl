use strict;

#-------------------------------------------------------------------------------
# Function:     check if the email is valid
# Input:        email address
# Output:       true or false
#-------------------------------------------------------------------------------
sub isValidEmail {
    my $email = shift;
    return $email =~ /^[\S\.]+@(\S+\.)+\w+$/;
}

#-------------------------------------------------------------------------------
# Function:     check if the homepage is valid
# Input:        homepage url
# Output:       true or false
#-------------------------------------------------------------------------------
sub isValidHomepage {
    my $homepage = shift;
#    return $homepage !~ /\s/;
    return lc($homepage) =~ /^http:\/\/\S+$/;
}

 
     
#-------------------------------------------------------------------------------
# Function:     check if the date is valid
# Input:        date
# Output:       true or false
#-------------------------------------------------------------------------------
sub isValidDate {
    my $date = shift;
   if($date =~ /[:]{1,2}/)
    {
       return(1);
     }
#   if($date =~ /^([0-9]{4})/)
#    {
#        return(0) if($1 <= 1900);
#        return(1);
#        }
#        else
#        {
#                return(0);
#        }
#    if($date =~ /^([0-9]{4})-([0-9]{1,2})/)
#    {
#        return(0) if($1 <= 1900);
#        return(0) if($2 > 12 || $2 < 1);
#        return(1);
#        }
#        else
#        {
#                return(0);
#        }
     
    if($date =~ /^([0-9]{4})-([0-9]{1,2})-([0-9]{1,2})/)
    {
    	return(0) if($1 <= 1900);
    	return(0) if($2 > 12 || $2 < 1);
    	return(0) if($3 > 31 || $3 < 1);
    	return(1);
	}
	else
	{
		return(0);
	}
}

sub isValidTime {
    my $time = shift;
   if($time =~ /^([0-9]{2}):([0-9]{2})/)
    {
          return(0) if($1 > 59);
        return(0) if($2 > 59);
       return(1);
     }
     else
            {
                     return(0);
            }

}

sub ValidDate {
    my $date = shift;
    if($date =~ /^([0-9]{4})-([0-9]{1,2})-([0-9]{1,2})/)
    {
        return(0) if($1 <= 1900);
        return(0) if($2 > 12 || $2 < 1);
        return(0) if($3 > 31 || $3 < 1);
        return(1);
        }
        else
        {
                return(0);
        }
}

#-------------------------------------------------------------------------------
# Function:     check if the zipcode,areacode,tel,fax is valid
# Input:        tel or fax
# Output:       true or false
#-------------------------------------------------------------------------------
sub isNumber
{
	my $num = shift;
	return $num =~ /[0-9]+/;
}

#-------------------------------------------------------------------------------
# Function:     check if the name_en is valid
# Input:        name_en
# Output:       true or false
#-------------------------------------------------------------------------------
sub isChars
{
	my $chars = shift;
	return $chars =~ /\S+/;
}

sub convert
{
	my $param = shift;
	
   	#$param =~ s/ //g;#半角空格
   	
   	$param = c_replace($param, qw( 　 ), '');#全角空格
        $param = c_replace($param, qw("), '&quot;');
        $param = c_replace($param, qw(：), ':');
   	$param = c_replace($param, qw( ， ； ), ',');
        $param = c_replace($param, qw( ：), ':');
   	$param = c_replace($param, qw( － ), '-');
   	$param = c_replace($param, qw( （ ), '(');
   	$param = c_replace($param, qw( ） ), ')');
   	$param = c_replace($param, qw( ０ ), '0');
   	$param = c_replace($param, qw( １ ), '1');
   	$param = c_replace($param, qw( ２ ), '2');
   	$param = c_replace($param, qw( ３ ), '3');
   	$param = c_replace($param, qw( ４ ), '4');
   	$param = c_replace($param, qw( ５ ), '5');
   	$param = c_replace($param, qw( ６ ), '6');
   	$param = c_replace($param, qw( ７ ), '7');
   	$param = c_replace($param, qw( ８ ), '8');
   	$param = c_replace($param, qw( ９ ), '9');
   	
   	return($param);
}

sub c_replace
{
	my $src = shift;
	my $rep = pop || 
		return $src;
	
	my @ptns = map(quotemeta($_), @_);
	my $ptn = join('|', @ptns);

	my $dest = '';
	while ($src ne '')
	{
		# check whether it is a Chinese char
		if ($src !~ m/[\xa0-\xfe][\x40-x7e|\x80-\xfe]/)
		{
			$src =~ s/$ptn/$rep/g;
			return $dest . $src;
		}

		$src = $';
		
		my $t = $`.$&;
		$t =~ s/$ptn/$rep/g;
		$dest .= $t;
	}
	
	return $dest;
}

sub isCouncilCity
{
	my ($dbh,$name) = @_;
	
	my @councilCity = ("广州","重庆","天津","上海","北京","SINGAPORE","LUXEMBOURG");
	
	$name = c_replace($name, qw( 　 省 市), ' ');
	$name =~ s/ //;
	
	my $flag = 0;
	foreach (@councilCity)
	{
               #$flag = 1 if($name eq "SINGAPORE";
		$flag = 1 if($name eq $_);
	}
	
	return $flag;
}


1;
