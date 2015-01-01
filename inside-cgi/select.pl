#!/usr/bin/perl -w

use strict;

sub selectProvince
{
	my ($dbh,$mt) = @_;
	
	my $selectLine = "";
	
	my $result_ref = $dbh->selectall_arrayref(
		"SELECT province FROM District WHERE city = 'nil' ORDER BY p_abbr");
	for (my $i=0; $i<scalar(@$result_ref); $i++)
    {
		my $arow = $result_ref->[$i];
		my ($province) = @$arow;
		
		$selectLine .= $mt->process_file('pmSelectLine.htm', 
			{
				'name' => $province,
				'value' => $province,
			});
	}
	
	return $selectLine;	
}


sub selectCity
{
	my ($dbh,$mt,$province,$area) = @_;
		
	my $selectLine = "";
	
	my $result_ref = $dbh->selectall_arrayref(
		"SELECT DISTINCT city FROM District WHERE province = ? AND city != 'nil' ORDER BY c_abbr",
		undef,$province);
		
	for (my $i=0; $i<scalar(@$result_ref); $i++)
    {
		my $arow = $result_ref->[$i];
		my ($city) = @$arow;
	
		
		$selectLine .= $mt->process_file('pmSelectLine.htm', 
			{
				'name'  => $city,
				'value' => $city,
			});
	        
 
    }
	
	return $selectLine;
}


sub selectLawarea
{
	my ($dbh,$mt,$own) = @_;
	my $label;
        my @val;
	
	my $selectLine = "";
	
	my $result_ref = $dbh->selectall_arrayref("SELECT DISTINCT name,own  FROM LawArea ORDER BY abbr");
	for (my $i=0; $i<scalar(@$result_ref); $i++)
    {
		my $arow = $result_ref->[$i];
		my ($name,$hmlr) = @$arow;
		
		
		
              if($hmlr eq '1' || $hmlr eq '2' || $hmlr eq '4' || $hmlr eq '8')
                {
                  $label = $hmlr/2**($own); 
                }
              elsif($hmlr eq '0')
                {
                  $label = 0;
                }
              else
                {
                  for(my $x=0; $x<=3; $x++)
                    {
                       $val[$x]=$hmlr % 2;
                       $hmlr/=2;
                    }
                   $label = $val[$own];
                }

              if($label == 1) 
            	{
                  $selectLine .= $mt->process_file('pmSelectLine.htm', 
			{
				'name' => $name,
				'value' => $name,
			});
                }
             else
                {
                next;
                }

 	
          }		
		
	return $selectLine;
}

sub selectLawyerarea
{
       my ($dbh,$mt,$province,$city,$own) = @_;
       my $selectLine = "";
        my $label;
        my @val;

       my $result_ref = $dbh->selectall_arrayref(<<__SQL__,undef,"%$province%","%$city%");
       SELECT DISTINCT t2.area_name  
       FROM Lawyer As t1,Lawyer_LawArea As t2
       WHERE t1.province LIKE ? AND t1.city LIKE ?
             AND t1.id = t2.lawyer_id 
             AND ((t2.area_order =1 AND CURRENT_DATE NOT BETWEEN t1.service_from_date AND t1.service_to_date)
				OR (t2.area_order<=5 AND  t1.service_type =1 AND CURRENT_DATE BETWEEN t1.service_from_date AND t1.service_to_date)
				OR (t2.area_order<=9 AND  t1.service_type =2 AND CURRENT_DATE BETWEEN t1.service_from_date AND t1.service_to_date))
       ORDER BY t2.area_name

__SQL__
 
 for (my $Lawyer_i=0; $Lawyer_i<scalar(@$result_ref); $Lawyer_i++)
    {
                my $arow = $result_ref->[$Lawyer_i];
                my ($Lawyer_name) = @$arow;
                 
                my ($hmlr)  = $dbh->selectrow_array(<<__SQL__,undef,"%$Lawyer_name%");
                SELECT  own
                FROM  LawArea
                WHERE name LIKE ?                                      
__SQL__
    
                if($hmlr eq '1' || $hmlr eq '2' || $hmlr eq '4' || $hmlr eq '8')
                {
                  $label = $hmlr/2**($own); 
                }
              elsif($hmlr eq '0')
                {
                  $label = 0;
                }
              else
                {
                  for(my $x=0; $x<=3; $x++)
                    {
                       $val[$x]=$hmlr % 2;
                       $hmlr/=2;
                    }
                   $label = $val[$own];
                }

              if($label == 1) 
            	{
                   $selectLine .= $mt->process_file('pmSelectLine.htm',
                        {
                                'name' => $Lawyer_name,
                                'value' => $Lawyer_name,
                        });
                }
             else
                {
                next;
                }              
      
    }
        return $selectLine;
}

sub selectLawOffiearea
{
       my ($dbh,$mt,$province,$city,$own) = @_;
       my $selectLine = "";
       my $label;
       my @val;
       
       my $result_ref = $dbh->selectall_arrayref(<<__SQL__,undef,"%$province%","%$city%");
       SELECT DISTINCT t2.area_name  
       FROM LawOffice As t1,LawOffice_LawArea As t2
       WHERE t1.province LIKE ? AND t1.city LIKE ?
             AND t1.id = t2.lawoffice_id 
             AND ((t2.area_order =1 AND CURRENT_DATE NOT BETWEEN t1.service_from_date AND t1.service_to_date)
				OR (t2.area_order<=5 AND  t1.service_type =1 AND CURRENT_DATE BETWEEN t1.service_from_date AND t1.service_to_date)
				OR (t2.area_order<=9 AND  t1.service_type =2 AND CURRENT_DATE BETWEEN t1.service_from_date AND t1.service_to_date))
       ORDER BY t2.area_name

__SQL__
     
  for (my $LawOffice_i=0; $LawOffice_i<scalar(@$result_ref); $LawOffice_i++)
    {
                my $arow = $result_ref->[$LawOffice_i];
                my ($LawOffice_name) = @$arow;

                my ($hmlr)  = $dbh->selectrow_array(<<__SQL__,undef,"%$LawOffice_name%");
                SELECT  own
                FROM  LawArea
                WHERE name LIKE ?                                      
__SQL__

                if($hmlr eq '1' || $hmlr eq '2' || $hmlr eq '4' || $hmlr eq '8')
                {
                  $label = $hmlr/2**($own); 
                }
              elsif($hmlr eq '0')
                {
                  $label = 0;
                }
              else
                {
                  for(my $x=0; $x<=3; $x++)
                    {
                       $val[$x]=$hmlr % 2;
                       $hmlr/=2;
                    }
                   $label = $val[$own];
                }

              if($label == 1) 
            	{
                   $selectLine .= $mt->process_file('pmSelectLine.htm',
                        {
                                'name' => $LawOffice_name,
                                'value' => $LawOffice_name,
                        });
                }
             else
                {
                next;
                }
      
    }
        return $selectLine;
}

sub selectLawoffice
{
	my ($dbh,$mt) = @_;
	
	my $selectLine = "";
	
	my $result_ref = $dbh->selectall_arrayref("SELECT name_cn FROM LawOffice ORDER BY name_en");
	for (my $i=0; $i<scalar(@$result_ref); $i++)
    {
		my $arow = $result_ref->[$i];
		my ($name) = @$arow;
		
		$selectLine .= $mt->process_file('pmSelectLine.htm', 
			{
				'name' => $name,
				'value' => $name,
			});
	}
	
	return $selectLine;
}

sub selectLawyer
{
	my ($dbh,$mt,$id) = @_;
	
	my $selectLine = "";
	
	my $result_ref = $dbh->selectall_arrayref("
                SELECT area_name FROM Lawyer_LawArea 
		WHERE area_order BETWEEN 10 AND 99 AND lawyer_id = ? ORDER BY area_name"
                ,undef,$id);
		

        for (my $i=0; $i<scalar(@$result_ref); $i++)
        {
		my $arow = $result_ref->[$i];
		my ($name) = @$arow;
		
		$selectLine .= $mt->process_file('pmSelectLine.htm', 
			{
				'name' => $name,
				'value' => $name,
			});
	}
	
	return $selectLine;
}

sub selectBigarea
{
	my ($dbh,$mt,$own) = @_;
        my $label;
        my @val;
	my $selectLine = "";
	
	my $result_ref = $dbh->selectall_arrayref("SELECT DISTINCT name,own FROM BigArea ORDER BY abbr");
	for (my $i=0; $i<scalar(@$result_ref); $i++)
    {
		my $arow = $result_ref->[$i];
		my ($name,$hmlr) = @$arow;
	    
              if($hmlr eq '1' || $hmlr eq '2' || $hmlr eq '4' || $hmlr eq '8')
                {
                  $label = $hmlr/2**($own); 
                }
              elsif($hmlr eq '0')
                {
                  $label = 0;
                }
              else
                {
                  for(my $x=0; $x<=3; $x++)
                    {
                       $val[$x]=$hmlr % 2;
                       $hmlr/=2;
                    }
                   $label = $val[$own];
                }

              if($label == 1) 
            	{
                  $selectLine .= $mt->process_file('pmSelectLine.htm', 
			{
				'name' => $name,
				'value' => $name,
			});
                }
             else
                {
                  next;
                }

 	
    }
	
	return $selectLine;
}

sub selectLawName
{
	my ($dbh,$mt,$bigarea,$own) = @_;
	my $label;
        my @val;
	my $selectLine = "";
	
	my $result_ref = $dbh->selectall_arrayref(
		"SELECT DISTINCT name,own FROM LawName WHERE area = ? ORDER BY abbr",
		undef,$bigarea);

	for (my $i=0; $i<scalar(@$result_ref); $i++)
    {
		my $arow = $result_ref->[$i];
		my ($name,$hmlr) = @$arow;
		
		if($hmlr eq '1' || $hmlr eq '2' || $hmlr eq '4' || $hmlr eq '8')
                {
                  $label = $hmlr/2**($own); 
                }
              elsif($hmlr eq '0')
                {
                  $label = 0;
                }
              else
                {
                  for(my $x=0; $x<=3; $x++)
                    {
                       $val[$x]=$hmlr % 2;
                       $hmlr/=2;
                    }
                   $label = $val[$own];
                }

              if($label == 1) 
            	{
                  $selectLine .= $mt->process_file('pmSelectLine.htm', 
			{
				'name' => $name,
				'value' => $name,
			});
                }
             else
                {
                next;
                }   
                
   }
	
	return $selectLine;
}

1;
