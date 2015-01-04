#!/usr/bin/env perl
$countname="/home/fahai/cgi-bin/template/counts.txt";
$logip=1;
$ipname="/home/fahai/cgi-bin/template/ipdata.txt";
$url="http://15.30.84.53/icons/";
$always_counter=0;
$digext=".gif";   
$prefix="counter";     
$width = "15";    
$height = "20";
open(FILE, $countname);
flock(FILE,2);
$counter = <FILE>;
flock(FILE,8);
close(FILE);


print "Content-type: text/html\n\n";
&validate;




sub counter {
@data=split(":", $counter);	
$count=@data[0];	
$lastip=@data[1];
    if (($ENV{'REMOTE_ADDR'} ne $lastip) or ($always_counter==1)) 
{
$count=$count+1;        
}  
@nums = split(//, $count);	
foreach $CountNr (@nums) {       
$printcount = "<img src=\"$url$prefix$CountNr$digext\" width=\"$width\" height=\"$height\" alt=\"$CountNr\">";		print $printcount;		}		}
sub write_count 
{	
open(FILE, ">$countname");	
flock(FILE,2);
print FILE "$count:$ENV{'REMOTE_ADDR'}";	
flock(FILE,8);
close(FILE);	
}

sub write_ip {    
my ($sec,$min,$hour,$day,$mon,$year)=localtime(time);
    $mon++;
    $year+=1900;
    $date="$year:$mon:$day:$hour:$min";	
open(FILE, ">>$ipname");        
flock(FILE,2);
print FILE "${date}:$ENV{'REMOTE_ADDR'}\n";
flock(FILE,8);
close(FILE);
	}


sub validate {    		
&counter;		
&write_count;		
if ($logip eq "1") {			
&write_ip;			
}			
}
