use strict;

#################################
#in_lawyerSubAll.pl
#include all sub for lawyer
#No:1 	addLawyer
#No:2 	editLawyer
#No:3 	updateLawyer
#No:4 	deleteLawyer
#No:5 	in_searchLawyer
#No:6 	lawyerInfo
#No:7 	checkLawyerInfo
#No:8 	haveThisLawyer
#No:9 	isMemberLawyer
#No:10 	addLawyer_LawArea
#No:11	getLawyer_LawArea
#No:12	showAddLawyerPage
#No:13	showErrPage
#No:14	memberLawyer
#No:15	checkLawarea
#No:16	checkProvince
#No:17	checkCity
#################################


#No:1
#-------------------------------------------------------------------------------
#Function:	add lawyer info into database
#Input:		lawyer info
#Output:	none
#-------------------------------------------------------------------------------
sub addLawyer
{
	my $param = shift;

    my $dbh = $param->{'DBH'};
    my $mt = $param->{'METATEXT'};
    my $basedir = "/home/fahai/icons";

    if(defined($param->{'init'}))
    {
    	&showAddLawyerPage($param);
    	return;
    }
    
    #put params into a hash table
    my $info = &lawyerInfo($param);
    
    #check the params,and get error string.
    my $err = &checkLawyerInfo($dbh,$mt,$info,"add");
    if(defined($err))
    {
    	#show error page!
    	&showErrPage($mt,$err);
    	return;
    }
	
	#push correct params into an array
    my @info;
    push(@info,$info->{'firstname_cn'});
	push(@info,$info->{'lastname_cn'});
	push(@info,$info->{'firstname_en'});
	push(@info,$info->{'lastname_en'});
	push(@info,$info->{'province'});
	push(@info,$info->{'city'});
	push(@info,$info->{'address'});
	push(@info,$info->{'zipcode'});
	push(@info,$info->{'areacode'});
	push(@info,$info->{'tel'});
	push(@info,$info->{'fax'});
	push(@info,$info->{'mobile'});
	push(@info,$info->{'email1'});
	push(@info,$info->{'email2'});
	push(@info,$info->{'website'});
	push(@info,$info->{'serial'});
	push(@info,$info->{'authdate'});
	push(@info,&getLawOfficeID($dbh,$info->{'lawoffice'}));
	push(@info,$info->{'language'});
	push(@info,$info->{'service_type'});
	push(@info,$info->{'service_from_date'});
	push(@info,$info->{'service_to_date'});
	push(@info,$info->{'remark'});
        push(@info,$info->{'back'});
	push(@info,$info->{'disp_level'});
        push(@info,$info->{'password_date'});

        my  $filename = $info->{'filename'};
        my $file = $filename;
        $filename =~ s/^.*(\\|\/)//; # 去除上传文件的路径得到文件名
     
	$dbh->do(<<__SQL__,undef,@info);
	INSERT INTO Lawyer(firstname_cn,lastname_cn,firstname_en,lastname_en,province,
		city,address,zipcode,areacode,tel,fax,mobile,email1,email2,website,serial,
		authdate,law_office,language,service_type,service_from_date,service_to_date,
		remark,memorandum,disp_level,password_date,cdate) 
	VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,CURRENT_DATE)
__SQL__
	
        $dbh->do("INSERT INTO file (law_id,file) VALUES(LAST_INSERT_ID(),?)", undef, $file);#上传文件写入

	#get the lawyer id
	my $name = $info->{'firstname_cn'}.$info->{'lastname_cn'};
        my $id = 0;	
   
        #my $id = $dbh->selectrow_array("SELECT id FROM Lawyer WHERE concat(firstname_cn,lastname_cn) = ?",undef,$name);
	
	#add this lawyer's lawarea into database
	&addLawyer_LawArea($dbh,$id,$info->{'area1'},$info->{'area2'},$info->{'area3'},$info->{'anhao_date'});
	
	#get the select params
	my $lawofficeLine = selectLawoffice($dbh,$mt);   
	
	#insert ok! and display lawyer input page.
	#reserve several input values.
	#include province,city,address,zipcode,lawoffice
	print $mt->process_file('in_pgLawyerInput.htm',
		{
			'lastname_cn' => "", 'firstname_cn' => "", 
			'lastname_en' => "", 'firstname_en' => "",
			'province' => $info->{'province'}, 'city' => $info->{'city'},
			'address' => $info->{'address'}, 'zipcode' => $info->{'zipcode'},
			'areacode' => "", 'tel' => "", 'fax' => "", 'mobile' => "",
			'email1' => "",	'email2' => "", 'website' => "",
			'serial' => "", 'authdate' => "", 'lawoffice' => $info->{'lawoffice'},
			'language' => "", 'area1' => "", 'area2' => "", 'area3' => "",
			'service_type' => "", 'service_from_date' => "", 'service_to_date' => "",
			'remark' => "", 'lawofficeline' => $lawofficeLine,'disp_level' => "9",
		}); 
 open (OUTFILE,">$basedir/$filename"); # 写入到服务器的本地文件 
        binmode(OUTFILE); # 文件句柄设置为二进制模式 
        while (my $bytesread=read($file,my $buffer,1024)) { 
        print OUTFILE $buffer; 
        } 
        close OUTFILE; # 关闭文件 
}


#No:2
#-------------------------------------------------------------------------------
#Function:	display lawyer info for edit
#Input:		lawyer id
#Output:	lawyer info
#-------------------------------------------------------------------------------
sub editLawyer
{
	my $param = shift;

    my $dbh = $param->{'DBH'};
    my $mt = $param->{'METATEXT'};
    
    my $id = $param->{'id'};
    
    #input type
    my $type = (!defined($param->{'type'}))?0:$param->{'type'};
    my $add = (!defined($param->{'add'}))?0:$param->{'add'};

	my @info = $dbh->selectrow_array(<<__SQL__,undef,$id);
	SELECT lastname_cn,lastname_en,firstname_cn,firstname_en,province,city,
		address,zipcode,areacode,tel,fax,mobile,
		email1,email2,website,serial,authdate,law_office,
		language,service_type,service_from_date,service_to_date,
		remark,memorandum,disp_level,password_date 
	FROM Lawyer 
	WHERE id = ?
__SQL__

#	foreach(@info)
#{
#       print $_;
#}
        my $area1 = &getLawyer_LawArea($dbh,$id,1);
	my $area2 = &getLawyer_LawArea($dbh,$id,2);
	my $area3 = &getLawyer_LawArea($dbh,$id,3);
        my $anhao_date = &getLawyer_LawArea($dbh,$id,4);	

	my $lawoffice = "";
	if($info[17] != 0)#lawoffce_id
	{
		$lawoffice = &getLawOfficeName($dbh,$info[17]);
	}
	
	#authdate,service_from_date,service_to_date
	$info[16] = "" if($info[16] eq '0000-00-00');
	$info[20] = "" if($info[20] eq '0000-00-00');
	$info[21] = "" if($info[21] eq '0000-00-00');
	
	my $lawofficeLine = selectLawoffice($dbh,$mt);
      if($add eq '2')
      {
   #$content = text2html($content,urls => 1,paras => 1,blockquotes => 1); 
   print $mt->process_file('in_pgLawyerInfoEdit.htm',
		{
			'id' => $id,
			'lastname_cn' => $info[0], 'firstname_cn' => $info[2],
			'lastname_en' => $info[1], 'firstname_en' => $info[3],
			'province' => $info[4], 'city' => $info[5], 
			'address' => $info[6], 'zipcode' => $info[7],
			'areacode' => $info[8], 'tel' => $info[9], 
			'fax' => $info[10], 'mobile' => $info[11],
			'email1' => $info[12], 'email2' => $info[13], 'website' => $info[14],
			'serial' => $info[15], 'authdate' => $info[16], 'lawoffice' => $lawoffice,
			'language' => $info[18], 'area1' => $area1,
			'area2' => $area2, 'area3' => $area3,
			'service_type' => $info[19], 'service_from_date' => $info[20],
			'service_to_date' => $info[21], 'remark' => $info[22], 'back' => $info[23],
                        'disp_level' => $info[24],'password_date' => $info[25],
			'lawofficeline' => $lawofficeLine, 'type' => $type,
                        'add'           => $add,'anhao_date' => $anhao_date,
		}); 
  
       return;

      }

	
	print $mt->process_file('in_pgLawyerInfoEdit.htm',
		{
			'id' => $id,
			'lastname_cn' => $info[0], 'firstname_cn' => $info[2],
			'lastname_en' => $info[1], 'firstname_en' => $info[3],
			'province' => $info[4], 'city' => $info[5], 
			'address' => $info[6], 'zipcode' => $info[7],
			'areacode' => $info[8], 'tel' => $info[9], 
			'fax' => $info[10], 'mobile' => $info[11],
			'email1' => $info[12], 'email2' => $info[13], 'website' => $info[14],
			'serial' => $info[15], 'authdate' => $info[16], 'lawoffice' => $lawoffice,
			'language' => $info[18], 'area1' => $area1,
			'area2' => $area2, 'area3' => $area3,
			'service_type' => $info[19], 'service_from_date' => $info[20],
			'service_to_date' => $info[21], 'remark' => $info[22], 'back' => $info[23],
                        'disp_level' => $info[24],'password_date' => $info[25],
			'lawofficeline' => $lawofficeLine, 'type' => $type,
                        'add'           => $add,'anhao_date' => $anhao_date,
		}); 
}


#No:3
#-------------------------------------------------------------------------------
#Function:	update the lawyer info
#Input:		post param 
#Output:	none
#-------------------------------------------------------------------------------
sub updateLawyer
{
	my $param = shift;

    my $dbh = $param->{'DBH'};
    my $mt = $param->{'METATEXT'};
    
    my $id = $param->{'id'};
    my $basedir = "/home/fahai/icons";  

    
    my $info = &lawyerInfo($param);
    my $err = &checkLawyerInfo($dbh,$mt,$info,$id);
    
    if(defined($err))
    {
    	#show err page!
    	&showErrPage($mt,$err);
    	return;
    }
    
    my @info;
    push(@info,$info->{'firstname_cn'});
	push(@info,$info->{'lastname_cn'});
	push(@info,$info->{'firstname_en'});
	push(@info,$info->{'lastname_en'});
	push(@info,$info->{'province'});
	push(@info,$info->{'city'});
	push(@info,$info->{'address'});
	push(@info,$info->{'zipcode'});
	push(@info,$info->{'areacode'});
	push(@info,$info->{'tel'});
	push(@info,$info->{'fax'});
	push(@info,$info->{'mobile'});
	push(@info,$info->{'email1'});
	push(@info,$info->{'email2'});
	push(@info,$info->{'website'});
	push(@info,$info->{'serial'});
	push(@info,$info->{'authdate'});
	push(@info,&getLawOfficeID($dbh,$info->{'lawoffice'}));
	push(@info,$info->{'language'});
	push(@info,$info->{'service_type'});
	push(@info,$info->{'service_from_date'});
	push(@info,$info->{'service_to_date'});
	push(@info,$info->{'remark'});
        push(@info,$info->{'back'});
	push(@info,$info->{'disp_level'});
	push(@info,$info->{'password_date'});
	
	push(@info,$id);

        my  $filename = $info->{'filename'};
        my $file = $filename;
        $filename =~ s/^.*(\\|\/)//; # 去除上传文件的路径得到文件名

        my ($file_id) = $dbh->selectrow_array(<<__SQL__,undef,"$id");
	SELECT count(*) FROM file WHERE  law_id = ?       
__SQL__
        my ($old_file) = $dbh->selectrow_array(<<__SQL__,undef,"$id");
	SELECT file FROM file WHERE  law_id = ?       
__SQL__
        $old_file =~ s/^.*(\\|\/)//;# 去除前上传文件的路径得到文件名

	
	$dbh->do(<<__SQL__,undef,@info);
	UPDATE Lawyer 
	SET firstname_cn=?,lastname_cn=?,firstname_en=?,lastname_en=?,province=?,
		city=?,address=?,zipcode=?,areacode=?,tel=?,fax=?,mobile=?,email1=?,
		email2=?,website=?,serial=?,authdate=?,law_office=?,language=?,
		service_type=?,service_from_date=?,service_to_date=?,remark=?,
                memorandum=?,disp_level=?,password_date=? 
                WHERE id = ?
__SQL__

	$dbh->do("DELETE FROM Lawyer_LawArea WHERE lawyer_id = ?",undef,$id);
	
	&addLawyer_LawArea($dbh,$id,$info->{'area1'},$info->{'area2'},$info->{'area3'},$info->{'anhao_date'});

        
        if($file_id)
         {
           $dbh->do("UPDATE file SET file=?  WHERE law_id = ?",undef, $file , $id);
         }
         else
          {
          $dbh->do("INSERT INTO file (law_id,file) VALUES(?,?)",undef, $id, $file);
          }
	
	&showInfoPage($mt,"修改成功!");
       
        if((-e "$basedir/$old_file") && $old_file)
         {
          
          unlink("$basedir/$old_file"); 

           if($filename)
           {
          open (OUTFILE,">$basedir/$filename"); # 写入到服务器的本地文件 
        binmode(OUTFILE); # 文件句柄设置为二进制模式 
        while (my $bytesread=read($file,my $buffer,1024)) { 
        print OUTFILE $buffer; 
        } 
           }

           #rename("$basedir/$filename","$basedir/$old_file") || die"原文件不存在";
         }
         else
             {
           if($filename)
           {
          open (OUTFILE,">$basedir/$filename"); # 写入到服务器的本地文件 
        binmode(OUTFILE); # 文件句柄设置为二进制模式 
        while (my $bytesread=read($file,my $buffer,1024)) { 
        print OUTFILE $buffer; 
        } 
           }
             }

        close OUTFILE; # 关闭文件 
}


#No:4
#-------------------------------------------------------------------------------
#Function:	delete lawyer info from database
#Input:		dbh
#			mt
#			lawyer id
#Output:	none
#-------------------------------------------------------------------------------
sub deleteLawyer
{
	my $param = shift;

    my $dbh = $param->{'DBH'};
    my $mt = $param->{'METATEXT'};
    
    my $id = $param->{'id'};
    my $basedir = "/home/fahai/icons"; 
 
	
	$dbh->do("DELETE FROM Lawyer_LawArea WHERE lawyer_id = ?",undef,$id);
	$dbh->do("DELETE FROM Lawyer WHERE id = ?",undef,$id);
        my ($filename) = $dbh->selectrow_array(<<__SQL__,undef,$id);
	SELECT file FROM file WHERE  law_id = ?       
__SQL__

    $dbh->do("DELETE FROM file WHERE law_id = ?",undef,$id);
    $filename =~ s/^.*(\\|\/)//; 
  
	&showInfoPage($mt,"删除成功!");

    if((-e "$basedir/$filename") && $filename )
       {
      unlink("$basedir/$filename"); 
       }
}


#No:5
#-------------------------------------------------------------------------------
#Function:	search lawyer
#Input:		search param
#Output:	search result
#-------------------------------------------------------------------------------
sub in_searchLawyer
{
	my $param = shift;

    my $dbh = $param->{'DBH'};
    my $mt = $param->{'METATEXT'};
    
    my $download = $param->{'download'};
    my $filename = "/home/fahai/inside-html/download.txt";
    
    #input type
    my $type = (!defined($param->{'type'}))?0:$param->{'type'};
    
    my $area = (!defined($param->{'area'}))?"":$param->{'area'};
    $area = convert($area);
    
    my $province = (!defined($param->{'province'}))?"":$param->{'province'};
    $province = c_replace($province, qw( 　 省 市), ' ');
        #$province =~ s/ //;
	
    my $city = (!defined($param->{'city'}))?"":$param->{'city'};
    $city = c_replace($city, qw( 　 省 市), ' ');
        #$city =~ s/ //;
	
    my $language = (!defined($param->{'language'}))?"":$param->{'language'};
    my $name = (!defined($param->{'name'}))?"":$param->{'name'};
    my $web = (!defined($param->{'web'}))?"":$param->{'web'};
    my $email = (!defined($param->{'email'}))?"":$param->{'email'};
    $name= uc($name); 

    my $address = (!defined($param->{'address'}))?"":$param->{'address'};

    my $cdate = (!defined($param->{'cdate'}))?"":$param->{'cdate'};
    my $remark = (!defined($param->{'back'}))?"":$param->{'back'};    
    my $memorandum = (!defined($param->{'mem'}))?"":$param->{'mem'};

    my $serv_type = (!defined($param->{'serv_type'}))?"0":$param->{'serv_type'};
    my $stype_from = 0;
    my $stype_to = 2;
    if($serv_type == 0){
	  	$stype_from = 0;
    	$stype_to = 2;}
	elsif($serv_type == 1){
	  	$stype_from = 0;
    	$stype_to = 0;}
	elsif($serv_type == 2){
	  	$stype_from = 1;
    	$stype_to = 1;}
    elsif($serv_type == 3){
	  	$stype_from = 2;
    	$stype_to = 2;}
	
   	my $start = (!defined($param->{'start'}))?1:$param->{'start'};
   	
	my $num = $start;
	my $upStart = $start - 20;
	my $downStart = $start + 20;
	my $offset = $start - 1;
        my $file;

	my $resultSum = 0;
    my $result_ref;
	if(!$cdate eq '')
	{
    	($resultSum) = $dbh->selectrow_array(<<__SQL__,undef,$cdate);
    	SELECT count(*)
    	FROM Lawyer 
    	WHERE cdate = ?
__SQL__

    	$result_ref = $dbh->selectall_arrayref(<<__SQL__,undef,$cdate);
    	SELECT id,concat(lastname_cn,firstname_cn) AS name,concat(province," ",city) AS zone,
    		address,zipcode,areacode,tel,fax,mobile,
    		email1,email2,website,serial,authdate,language,law_office
    	FROM Lawyer 
    	WHERE cdate = ?
    	ORDER BY disp_level,lastname_en,firstname_en 
    	LIMIT $offset,20
__SQL__
	}
    elsif(!$area eq '')
    {

		#要注意group by对count()的影响。
		my ($resultSumTmp) = $dbh->selectall_arrayref(<<__SQL__,undef,"%$name%","%$web%","%$email%","%$province%","%$city%","%$language%","%$area%","%$remark%","%$memorandum%","%$address%",$stype_from,$stype_to);
		SELECT t1.id
		FROM Lawyer AS t1,Lawyer_LawArea AS t2
		WHERE concat(t1.lastname_cn," ",t1.firstname_cn) LIKE ? 
			AND t1.website LIKE ? 
			AND t1.email1 LIKE ? 
			AND t1.province LIKE ? 
			AND t1.city LIKE ? 
			AND t1.language LIKE ? 
			AND t2.area_name LIKE ? 
                        AND t1.remark LIKE ?
                        AND t1.memorandum LIKE ?
                        AND t1.address LIKE ?
			AND t1.id=t2.lawyer_id
			AND t1.service_type BETWEEN ? AND ?
		GROUP BY t1.id
__SQL__
		
		$resultSum = scalar(@$resultSumTmp);
		
		if(defined($download))
		{
			$result_ref = $dbh->selectall_arrayref(<<__SQL__,undef,"%$name%","%$web%","%$email%","%$province%","%$city%","%$language%","%$area%","%$remark%","%$memorandum%","%$address%",$stype_from,$stype_to);
			SELECT t1.id,concat(t1.lastname_cn,t1.firstname_cn) AS name,concat(t1.province," ",t1.city) AS zone,
				t1.address,t1.zipcode,t1.areacode,t1.tel,t1.fax,t1.mobile,
				t1.email1,t1.email2,t1.website,t1.serial,t1.authdate,t1.language,t1.law_office
			FROM Lawyer AS t1,Lawyer_LawArea AS t2
			WHERE concat(t1.lastname_cn,t1.firstname_cn) LIKE ? 
				AND t1.website LIKE ? 
			        AND t1.email1 LIKE ? 
				AND t1.province LIKE ?
				AND t1.city LIKE ? 
				AND t1.language LIKE ? 
				AND t2.area_name LIKE ? 
                                AND t1.remark LIKE ?
                                AND t1.memorandum LIKE ?
                                AND t1.address LIKE ?
				AND t1.id=t2.lawyer_id
				AND t1.service_type BETWEEN ? AND ?
			GROUP BY t1.id
			ORDER BY t1.lastname_en,t1.firstname_en
__SQL__
		}
		else
		{
			$result_ref = $dbh->selectall_arrayref(<<__SQL__,undef,"%$name%","%$web%","%$email%","%$province%","%$city%","%$language%","%$area%","%$remark%","%$memorandum%","%$address%",$stype_from,$stype_to);
			SELECT t1.id,concat(t1.lastname_cn,t1.firstname_cn) AS name,concat(t1.province," ",t1.city) AS zone,
				t1.address,t1.zipcode,t1.areacode,t1.tel,t1.fax,t1.mobile,
				t1.email1,t1.email2,t1.website,t1.serial,t1.authdate,t1.language,t1.law_office
			FROM Lawyer AS t1,Lawyer_LawArea AS t2
			WHERE concat(t1.lastname_cn,t1.firstname_cn) LIKE ? 
				AND t1.website LIKE ? 
			        AND t1.email1 LIKE ? 
				AND t1.province LIKE ? 
				AND t1.city LIKE ? 
				AND t1.language LIKE ? 
				AND t2.area_name LIKE ? 
                                AND t1.remark LIKE ?
                                AND t1.memorandum LIKE ?
                                AND t1.address LIKE ?
				AND t1.id=t2.lawyer_id
				AND t1.service_type BETWEEN ? AND ?
			GROUP BY t1.id
			ORDER BY t1.disp_level,t1.lastname_en,t1.firstname_en
			LIMIT $offset,20
__SQL__
		}
    }
    else
    {
    	($resultSum) = $dbh->selectrow_array(<<__SQL__,undef,"%$name%","%$web%","%$email%","%$province%","%$city%","%$language%","%$remark%","%$memorandum%","%$address%",$stype_from,$stype_to);
    	SELECT count(id)
    	FROM Lawyer 
    	WHERE concat(lastname_cn,firstname_cn) LIKE ? 
    		AND website LIKE ? 
                AND email1 LIKE ? 
    		AND province LIKE ? 
    		AND city LIKE ? 
    		AND language LIKE ?
                AND remark LIKE ?
                AND memorandum LIKE ?
                AND address LIKE ?
    		AND service_type BETWEEN ? AND ?
__SQL__

    	if(defined($download))
    	{
	    	$result_ref = $dbh->selectall_arrayref(<<__SQL__,undef,"%$name%","%$web%","%$email%","%$province%","%$city%","%$language%","%$remark%","%$memorandum%","%$address%",$stype_from,$stype_to);
	    	SELECT id,concat(lastname_cn,firstname_cn) AS name,concat(province," ",city) AS zone,
	    		address,zipcode,areacode,tel,fax,mobile,
	    		email1,email2,website,serial,authdate,language,law_office
	    	FROM Lawyer 
	    	WHERE concat(lastname_cn,firstname_cn) LIKE ? 
	    		AND website LIKE ? 
                        AND email1 LIKE ? 
	    		AND province LIKE ? 
	    		AND city LIKE ? 
	    		AND language LIKE ? 
                        AND remark LIKE ?
                        AND memorandum LIKE ?
                        AND address LIKE ?
	    		AND service_type BETWEEN ? AND ?
	    	ORDER BY lastname_en,firstname_en 
__SQL__
		}
		else
		{
	    	$result_ref = $dbh->selectall_arrayref(<<__SQL__,undef,"%$name%","%$web%","%$email%","%$province%","%$city%","%$language%","%$remark%","%$memorandum%","%$address%",$stype_from,$stype_to);
	    	SELECT id,concat(lastname_cn,firstname_cn) AS name,concat(province," ",city) AS zone,
	    		address,zipcode,areacode,tel,fax,mobile,
	    		email1,email2,website,serial,authdate,language,law_office
	    	FROM Lawyer 
	    	WHERE concat(lastname_cn,firstname_cn) LIKE ? 
	    		AND website LIKE ? 
                        AND email1 LIKE ? 
	    		AND province LIKE ? 
	    		AND city LIKE ? 
	    		AND language LIKE ?
                        AND remark LIKE ?
                        AND memorandum LIKE ?
                        AND address LIKE ?
	    		AND service_type BETWEEN ? AND ?
	    	ORDER BY disp_level,lastname_en,firstname_en 
	    	LIMIT $offset,20
__SQL__
		}
	}
	
	my $searchLawyerResLine = "";
	
	if(defined($download))
	{
		open(LAWYERFILE,">${filename}");
	}
	for (my $i=0; $i<scalar(@$result_ref); $i++)
    {
		my $arow = $result_ref->[$i];
		
		my $id = @$arow[0];
		my $name = @$arow[1];
		my $zone = @$arow[2];
		my $address = @$arow[3];
		my $zipcode = @$arow[4];
		my $areacode = @$arow[5];
		my $tel = @$arow[6];
		my $fax = @$arow[7];
		my $mobile = @$arow[8];
                my $email  = @$arow[9];

		my $email1 = @$arow[9];
		my $email2 = @$arow[10];
		my $website = @$arow[11];
		my $serial = @$arow[12];
		my $authdate = @$arow[13];
		my $language = @$arow[14];
		my $lawoffice_id = @$arow[15];

		my $area1 = &getLawyer_LawArea($dbh,$id,1);
		my $area2 = &getLawyer_LawArea($dbh,$id,2);
		my $area3 = &getLawyer_LawArea($dbh,$id,3);
                my $anhao_date = &getLawyer_LawArea($dbh,$id,4);

		my $lawoffice = "";
		if($lawoffice_id != 0)
		{
			$lawoffice = getLawOfficeName($dbh,$lawoffice_id);
		}
                
            $file = $dbh->selectrow_array(<<__SQL__,undef,"$id");
            select file
            FROM file
            WHERE law_id = ? 
__SQL__

             $file =~ s/^.*(\\|\/)//;
             $file =~ s/([^a-zA-Z0-9_\-.])/uc sprintf("%%%02x",ord($1))/eg; 
            
             if($email1 eq '' && $email2){ $email =  $email2;
             }
             elsif($email2 eq  ''  && $email1 eq ''){ $email = "无邮址";
             }
	     $website = "无网址" if($website eq '');
            



		if(defined($download))
		{
			#format telephone and fax and authdate
			$tel = $areacode . "-" . $tel if(!($areacode eq "") && !($tel eq ""));
			$fax = $areacode . "-" . $fax if(!($areacode eq "") && !($fax eq ""));
			$authdate = "" if($authdate eq '0000-00-00');
		

			$searchLawyerResLine .= $mt->process_file('in_downloadLawyer', 
				{
					name => $name, zone => $zone, address => $address, zipcode => $zipcode,
					tel => $tel, fax => $website,'email'=> $email, mobile => $mobile,
					email1 => $email1, email2 => $email2, website => $website,
					serial => $serial, authdate => $authdate,
					language => $language, lawoffice => $lawoffice,
					area1 => $area1, area2 => $area2, area3 => $area3,
				});
		}
		else
		{
			#format telephone and fax
			$tel = $areacode . "," . $tel if(!($areacode eq "") && !($tel eq ""));
			$fax = $areacode . "," . $fax if(!($areacode eq "") && !($fax eq ""));

			$searchLawyerResLine .= $mt->process_file('in_pmLawyerSearchResLine.htm', 
				{
					'num' => "$num",
					'id' => "$id",
					'name' => "$name",
					'zone' => "$zone",
					'areacode' => "$areacode",
					'tel'=> "$tel",
					'fax'=> "$website",#$website
  	                                'email'=> "$email",#$email
					'lawoffice' => "$lawoffice",
					'language' => "$language",
					'area' => "$area1",
					'type' => "$type",
					'lawoffice_id' => "$lawoffice_id",
                                        'file' => "$file",
				});
		}
		$num += 1;
    }
    
    if(defined($download))
    {
    	print LAWYERFILE $searchLawyerResLine;
    	close(LAWYERFILE);
    	
    	print $mt->process_file('in_pgDownload.htm');
    	
    	return;
    }
   	
   	my $downLink = ($downStart <= $resultSum && $resultSum > 20)?1:0;

    print $mt->process_file('in_pgLawyerSearchRes.htm',
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
			'web'  => "$web",
			'email' => "$email",
			'cdate' => "$cdate",
                        'remark' => "$remark",
                        'mem'    => "$memorandum",
                        'address' => "$address",
		});
}


#No:6
#--------------------------------------------------------
#Fucntion:	format lawyer info
#Input:		param
#Output:	formatted lawyer info(hash table)
#--------------------------------------------------------
sub lawyerInfo
{
	my $param = shift;
	
	my %lawyerInfo;
	
	my $id = (!defined($param->{'id'}))?0:$param->{'id'};
	$lawyerInfo{id} = $id;
	
	my $lastname_cn = (!defined($param->{'lastname_cn'}))?"":$param->{'lastname_cn'};#姓
	$lawyerInfo{lastname_cn} = $lastname_cn;
	
	my $lastname_en = (!defined($param->{'lastname_en'}))?"":$param->{'lastname_en'};
	$lawyerInfo{lastname_en} = $lastname_en;
	
	my $firstname_cn = (!defined($param->{'firstname_cn'}))?"":$param->{'firstname_cn'};#名
	$lawyerInfo{firstname_cn} = $firstname_cn;
	
	my $firstname_en = (!defined($param->{'firstname_en'}))?"":$param->{'firstname_en'};
	$lawyerInfo{firstname_en} = $firstname_en;
	
	my $province = (!defined($param->{'province'}))?"":$param->{'province'};
	$lawyerInfo{province} = convert($province);
	
	my $city = (!defined($param->{'city'}))?"":$param->{'city'};
	$lawyerInfo{city} = convert($city);
	
	my $address = (!defined($param->{'address'}))?"":$param->{'address'};
	$lawyerInfo{address} = $address;
	
	my $zipcode = (!defined($param->{'zipcode'}))?"":$param->{'zipcode'};
	$lawyerInfo{zipcode} = $zipcode;
	
	my $areacode = (!defined($param->{'areacode'}))?"":$param->{'areacode'};
	$lawyerInfo{areacode} = $areacode;
	
	my $tel = (!defined($param->{'tel'}))?"":$param->{'tel'};
	$lawyerInfo{tel} = $tel;
	
	my $fax = (!defined($param->{'fax'}))?"":$param->{'fax'};
	$lawyerInfo{fax} = $fax;
	
	my $mobile = (!defined($param->{'mobile'}))?"":$param->{'mobile'};
	$lawyerInfo{mobile} = $mobile;
	
	my $email1 = (!defined($param->{'email1'}))?"":$param->{'email1'};
	$lawyerInfo{email1} = $email1;
	
	my $email2 = (!defined($param->{'email2'}))?"":$param->{'email2'};
	$lawyerInfo{email2} = $email2;
	
	my $website = (!defined($param->{'website'}))?"":$param->{'website'};
	$lawyerInfo{website} = $website;
	
	my $serial = (!defined($param->{'serial'}))?"":$param->{'serial'};
	$lawyerInfo{serial} = $serial;
	
	my $authdate = (!defined($param->{'authdate'}))?"":$param->{'authdate'};
	$lawyerInfo{authdate} = $authdate;
	
	my $lawoffice = (!defined($param->{'lawoffice'}))?"":$param->{'lawoffice'};
	$lawyerInfo{lawoffice} = $lawoffice;
	if(!($param->{'sel_lawoffice'} eq '0'))
	{
		$lawyerInfo{lawoffice} = $param->{'sel_lawoffice'};
	}
	
	my $language = (!defined($param->{'language'}))?"":$param->{'language'};
	$lawyerInfo{language} = convert($language);
	
	my $area1 = (!defined($param->{'area1'}))?"":$param->{'area1'};
	$lawyerInfo{area1} = convert($area1);#
	
	my $area2 = (!defined($param->{'area2'}))?"":$param->{'area2'};
	$lawyerInfo{area2} = convert($area2);#
	
	my $area3 = (!defined($param->{'area3'}))?"":$param->{'area3'};
	$lawyerInfo{area3} = convert($area3);#
	
	my $service_type = (!defined($param->{'service_type'}))?"0":$param->{'service_type'};
	$lawyerInfo{service_type} = $service_type;
	
	my $service_from_date = (!defined($param->{'service_from_date'}))?"":$param->{'service_from_date'};
	$lawyerInfo{service_from_date} = convert($service_from_date);#
	
	my $service_to_date = (!defined($param->{'service_to_date'}))?"":$param->{'service_to_date'};
	$lawyerInfo{service_to_date} = convert($service_to_date);#
	
	my $remark = (!defined($param->{'remark'}))?"":$param->{'remark'};
	$lawyerInfo{remark} = $remark;
       
        my $back = (!defined($param->{'back'}))?"":$param->{'back'};
        $lawyerInfo{back} = $back;
        
        my $disp_level = (!defined($param->{'disp_level'}))?"9":$param->{'disp_level'};
	$lawyerInfo{disp_level} = $disp_level;
        
        my $password_date = (!defined($param->{'password_date'}))?"":$param->{'password_date'};
	$lawyerInfo{password_date} = $password_date;
	
        my $anhao_date = (!defined($param->{'anhao_date'}))?"#ZZXX":$param->{'anhao_date'};
        $anhao_date ="#ZZXX" if(!$anhao_date);
	$lawyerInfo{anhao_date} = $anhao_date;

	my $another = (!defined($param->{'another'})) ? 0 : 1;
	$lawyerInfo{another} = $another;
  
        my $filename = (!defined($param->{'FILE_NAME'}))?"":$param->{'FILE_NAME'};
	$lawyerInfo{filename} = $filename;

	
	return(\%lawyerInfo);
}


#No:7
#--------------------------------------------------------
#Function:	check the info of lawyer
#Input:		dbh handler
#			mt handler
#			hash ref
#			info type(add,edit)
#Output:	error string
#--------------------------------------------------------
sub checkLawyerInfo
{
	my ($dbh,$mt,$param,$flat) = @_;
	
    my $errStrLine = "";
    my $Sum_Lawyer;

	my $lastname_cn = $param->{'lastname_cn'};
	my $lastname_en = $param->{'lastname_en'};
	my $firstname_cn = $param->{'firstname_cn'};
	my $firstname_en = $param->{'firstname_en'};
        my $password_date = $param->{'password_date'};
        my $anhao_date = $param->{'anhao_date'}; 
        my $filename = $param->{'filename'}; 
        my $file = $filename;
        
        #check Lawyer anhao
        if($anhao_date  ne '')
        {
          my @anhao = split /,/,$anhao_date;
					
		foreach(@anhao)
		{
                    
                     if(!(m/^#/))
                    {
                      
                      $errStrLine .= "案号无效$_!";
                      return $errStrLine;
                    }
                   
                   
		}
        }

        #check Lawyer filename
        $filename =~ s/^.*(\\|\/)//; # 去除上传文件的路径得到文件名
        if($filename !~ /\.jpg/gi && $filename ne '')
	 {
                $errStrLine .= "上传文件类型JPEG图片!";
		return $errStrLine;
	 }  
        my ($file_count) = $dbh->selectrow_array(<<__SQL__,undef,"%$filename%");
	SELECT count(*) FROM file WHERE  file LIKE ?       
__SQL__

        if($file_count)        
        {
          if(($filename))
           {
             $errStrLine .= "上传文件已经存在!";
             return $errStrLine;
           }
	}
       

        #check lawyer password
        if($password_date ne '')
        {
          $Sum_Lawyer = $dbh->selectrow_array(<<__SQL__,undef,$password_date,$flat);
	SELECT count(*)
	FROM Lawyer 
	WHERE password_date = ? AND id != ?
       
__SQL__
         
             
            if($Sum_Lawyer == 1)
              {
               $errStrLine .= "你的个人密码无效!";
               return undef if($errStrLine eq '');
              }
        } 
        
	#check lawyer name
	if($lastname_cn eq '' || $lastname_en eq '' || $firstname_cn eq '' || $firstname_en eq '')
	{
		$errStrLine .= "请输入姓名的中文和拼音!";
		return $errStrLine;
	}

	#check if the lawyer exist
	my $name = $firstname_cn.$lastname_cn;
	
	my $id = (!defined($param->{'id'}))?0:$param->{'id'};
	
	#id = 0 --> add;id != 0 --> edit
	#考虑重名的情况，用参数another表示。
	if(haveThisLawyer($dbh,$name,$id) && !($param->{'another'} eq '1'))
	{
		$errStrLine .= "该个人的记录已经存在!";
		return $errStrLine;
	}
	#
	if(!isChars($lastname_en) || !isChars($firstname_en))
	{
		$errStrLine .= "个人名字的拼音填写错误!";
	}
	
	my $province = $param->{'province'};
	if(!$province eq '' && !checkProvince($dbh,$province))
	{
		$errStrLine .= "省/直辖市填写错误!";
	}
	my $city = $param->{'city'};
	if(!$city eq '' && !checkCity($dbh,$city))
	{
		$errStrLine .= "市/县填写错误!";
	}
		
	my $zipcode = $param->{'zipcode'};
	my $areacode = $param->{'areacode'};
	my $tel = $param->{'tel'};
	my $fax = $param->{'fax'};
	my $mobile = $param->{'mobile'};
	if(!$zipcode eq '' && !isNumber($zipcode))
	{
		$errStrLine .= "邮政编码填写错误!";
	}
	if(!$areacode eq '' && !isNumber($areacode))
	{
		$errStrLine .= "区号填写错误!";
	}
	if(!$tel eq '' && !isNumber($tel))
	{
		$errStrLine .= "电话填写错误!";
	}
	if(!$fax eq '' && !isNumber($fax))
	{
		$errStrLine .= "传真填写错误!";
	}
	if(!$mobile eq '' && !isNumber($mobile))
	{
		$errStrLine .= "手机填写错误!";
	}
	
	my $email1 = $param->{'email1'};
	my $email2 = $param->{'email2'};
	if(!$email1 eq '' && !isValidEmail($email1))
	{
		$errStrLine .= "email1填写错误!";
	}
	if(!$email2 eq '' && !isValidEmail($email2))
	{
		$errStrLine .= "email2填写错误!";
	}
	
	my $serial = $param->{'serial'};
	
	#check authdate format!
	my $authdate = $param->{'authdate'};
	if(!$authdate eq '' && !isValidDate($authdate))
	{
		$errStrLine .= "个人登记日期填写错误!";
	}

	my $lawoffice = $param->{'lawoffice'};

	if(!$lawoffice eq '')
	{
		my $lawoffice_id = getLawOfficeID($dbh,$lawoffice);
		if(!defined($lawoffice_id))
		{
			$errStrLine .= "所填写的所属机构名称不在数据库中!";
		}
	}
	
	#check lawyer lawarea
	my $area1 = $param->{'area1'};
	#print "(!checkLawarea($dbh,$area1)";
        #print "(!$area1)";
        if(!checkLawarea($dbh,$area1) && !$area1 eq '')
	{
	        $errStrLine .= "业务关系1填写错误!";
	}
	my $area2 = $param->{'area2'};
	if(!checkLawarea($dbh,$area2) && !$area2 eq '')
	{
		$errStrLine .= "业务关系2填写错误!";
	}
	my $area3 = $param->{'area3'};
	if(!checkLawarea($dbh,$area3) && !$area3 eq '')
	{
		$errStrLine .= "业务关系3填写错误!";
	}
	
	
        


#check service_type,service_from_date,service_to_date
	
	my $service_from_date = $param->{'service_from_date'};
	my $service_to_date = $param->{'service_to_date'};

	
	if(!$service_from_date eq '' && !$service_to_date eq ''
		&& !isValidDate($service_from_date) && !isValidDate($service_to_date))
	{
		$errStrLine .= "服务起至日期填写错误!";
	}
        elsif( !$service_from_date eq '' && !isValidDate($service_from_date))
        {
	        $errStrLine .= "服务起至日期填写错误!";
	}
	elsif( !$service_to_date eq '' && !isValidDate($service_to_date))
        {
	        $errStrLine .= "服务起至日期填写错误!";
	}
	
	return undef if($errStrLine eq '');
	
	return $errStrLine;
}


#No:8
#---------------------------------------------
#Input:		database handler
#			lawyer name
#Output:	true or false
#---------------------------------------------
sub haveThisLawyer
{
	my ($dbh,$name,$id) = @_;
	
	my $haveit;
	if($id == 0)
	{
		($haveit) = $dbh->selectrow_array(
			"SELECT id FROM Lawyer WHERE concat(firstname_cn,lastname_cn) = ?",
			undef,$name);
	}
	else
	{
		($haveit) = $dbh->selectrow_array(
			"SELECT id FROM Lawyer WHERE concat(firstname_cn,lastname_cn) = ? AND id != ?",
			undef,$name,$id);
	}

	return(0) if(!defined($haveit));
	
	return(1);
}

#No:9
#---------------------------------------------
#Function:	check if a lawyer is a member
#Input:		database handler
#			lawyer id
#Output:	true or false
#---------------------------------------------
sub isMemberLawyer
{
	my ($dbh,$id) = @_;
	
	my ($member) = $dbh->selectrow_array(<<__SQL__,undef,$id);
	SELECT id 
	FROM Lawyer 
	WHERE CURRENT_DATE BETWEEN service_from_date AND service_to_date AND id = ?
__SQL__
	
	return(0) if(!defined($member));
	
	return(1);
}


#No:10
#---------------------------------------------
#Function:	put lawyer law area into database
#Input:		database handler
#			lawyer id
#			law area1
#			law area2
#			law area3
#                       lawyer_anhao_date
#Output:	none
#---------------------------------------------
sub addLawyer_LawArea
{
	my ($dbh,$id,$area1,$area2,$area3,$anhao_date) = @_;
	
	if(!$area1 eq '')
	{
		if($id != 0)
                  {
                   $dbh->do("INSERT INTO Lawyer_LawArea(lawyer_id,area_name,area_order) VALUES(?,?,?)",undef,$id,$area1,1);
                  }
	        else
                  {
                 $dbh->do("INSERT INTO Lawyer_LawArea(lawyer_id,area_name,area_order) VALUES(LAST_INSERT_ID(),?,?)",undef,$area1,1);
                  }
        }
	
	if(!$area2 eq '')
	{
		my @area = split /,/,$area2;
		my $i=2;			
		foreach(@area)
		{
                   if($id == 0)
                    {
                      $dbh->do("INSERT INTO Lawyer_LawArea(lawyer_id,area_name,area_order) VALUES(LAST_INSERT_ID(),?,?)",undef,$_,$i);
			$i += 1;
                    }
                   else
                   {
                   $dbh->do("INSERT INTO Lawyer_LawArea(lawyer_id,area_name,area_order) VALUES(?,?,?)",undef,$id,$_,$i);
                        $i += 1;
                   }
		}
	}
	
	if(!$area3 eq '')
	{
		my @area = split /,/,$area3;
		my $i=6;
		foreach(@area)
		{
                  if($id == 0)
                      {
			$dbh->do("INSERT INTO Lawyer_LawArea(lawyer_id,area_name,area_order) VALUES(LAST_INSERT_ID(),?,?)",undef,$_,$i);
			$i += 1;
                      }
                   else
                      {
                      $dbh->do("INSERT INTO Lawyer_LawArea(lawyer_id,area_name,area_order) VALUES(?,?,?)",undef,$id,$_,$i);
                      }
		}
	}	
        
        if(!$anhao_date eq '')
	{
		my @area = split /,/,$anhao_date;
		my $i=10;
		foreach(@area)
		{
                  if($id == 0)
                      {
			$dbh->do("INSERT INTO Lawyer_LawArea(lawyer_id,area_name,area_order) VALUES(LAST_INSERT_ID(),?,?)",undef,$_,$i);
			$i += 1;
                      }
                   else
                      {
                      $dbh->do("INSERT INTO Lawyer_LawArea(lawyer_id,area_name,area_order) VALUES(?,?,?)",undef,$id,$_,$i);
                      }
		}
	}	        

}


#No:11
#---------------------------------------------
#Function:	get lawyer law area from database
#Input:		database handler
#			lawyer id
#			the num of lawarea
#Output:	a string of lawyer lawarea
#---------------------------------------------
sub getLawyer_LawArea
{
	my ($dbh,$id,$num) = @_;
	
	my $result_ref;
	
	if($num == 1)
	{
		$result_ref = $dbh->selectall_arrayref(<<__SQL__,undef,$id);
		SELECT area_name 
		FROM Lawyer_LawArea 
		WHERE area_order=1 AND lawyer_id = ? 
		ORDER BY area_order
__SQL__
	}
	elsif($num == 2)
	{
		$result_ref = $dbh->selectall_arrayref(<<__SQL__,undef,$id);
		SELECT area_name 
		FROM Lawyer_LawArea 
		WHERE area_order BETWEEN 2 AND 5 AND lawyer_id = ? 
		ORDER BY area_order
__SQL__
	}
	elsif($num == 3)
	{
		$result_ref = $dbh->selectall_arrayref(<<__SQL__,undef,$id);
		SELECT area_name 
		FROM Lawyer_LawArea 
		WHERE area_order BETWEEN 6 AND 9 AND lawyer_id = ? 
		ORDER BY area_order
__SQL__
	}
        elsif($num == 4)
	{
		$result_ref = $dbh->selectall_arrayref(<<__SQL__,undef,$id);
		SELECT area_name 
		FROM Lawyer_LawArea 
		WHERE area_order BETWEEN 10 AND 99 AND lawyer_id = ? 
		ORDER BY area_name 
__SQL__
	}
	
	my @lawArea;
	for (my $i=0; $i<scalar(@$result_ref); $i++)
    {
		my $arow = $result_ref->[$i];
		my ($area) = @$arow;
		push (@lawArea,$area);
	}
	
	return join(',',@lawArea);#return the lawarea string.
}


#No:12
#-------------------------------------------------------------------------------
#Fuction:	display lawyer input page for the first time
#input:		dbh handler
#			metatext handler
#output:	lawyer input page
#-------------------------------------------------------------------------------
sub showAddLawyerPage
{
	my $param = shift;

    my $dbh = $param->{'DBH'};
    my $mt = $param->{'METATEXT'};
	
	my $type = (!defined($param->{'type'}))?0:$param->{'type'};
	
	my $lawofficeLine = selectLawoffice($dbh,$mt);
	
	#display lawyer input page for the first time!
	print $mt->process_file('in_pgLawyerInput.htm',
		{
			lastname_cn=>"",firstname_cn=>"",lastname_en=>"",firstname_en=>"",
			province=>"",city=>"",address=>"",zipcode=>"",
			areacode=>"",tel=>"",fax=>"",mobile=>"",
			email1=>"",	email2=>"",website=>"",
			serial=>"",authdate=>"",lawoffice=>"",
			language=>"",area1=>"",area2=>"",area3=>"",
			service_type=>"",service_from_date=>"",service_to_date=>"",
			remark => "", 'disp_level' => "9",
			'lawofficeline' => $lawofficeLine,
			type => $type,
		}); 
}


#No:13
#---------------------------------------------
#Function:	show error page
#Input:		error string
#Output:	error page
#---------------------------------------------
sub showErrPage
{
	my ($mt,$err) = @_;
	
	my @err = split /!/, $err;
	
	my $errline;
	
	foreach (@err)
	{
		$errline .= $mt->process_file('in_pmErr.htm',
			{
				errstring => $_,
			});
	}
	
	print $mt->process_file('in_pgErr.htm',
		{
			errline => $errline,
		});
}


#No:14
#---------------------------------------------
#Function:	show member lawyer whose membership expire
#Input:		none
#Output:	result page
#---------------------------------------------
sub memberLawyer
{
	my $param = shift;

    my $dbh = $param->{'DBH'};
    my $mt = $param->{'METATEXT'};

   	my $start = (!defined($param->{'start'}))?1:$param->{'start'};
   	
	my $num = $start;
	
	my $upStart = $start - 20;
	my $downStart = $start + 20;
	
	my $offset = $start - 1;
	my $resultSum = 0;
    
	
	$resultSum = $dbh->selectrow_array(<<__SQL__);
	SELECT count(*)
	FROM Lawyer 
	WHERE to_days(service_to_date) != 0 AND to_days(service_from_date) != 0
		AND to_days(now()) > to_days(service_to_date)-90
__SQL__
		
	my $result_ref = $dbh->selectall_arrayref(<<__SQL__);
	SELECT id,concat(lastname_cn,firstname_cn) AS name,areacode,
		tel,fax,law_office,service_type,service_from_date,service_to_date,remark
	FROM Lawyer 
	WHERE to_days(service_to_date) != 0 AND to_days(service_from_date) != 0 
		AND to_days(now()) > to_days(service_to_date)-90
	ORDER BY lastname_en,firstname_en 
	LIMIT $offset,20
__SQL__
	
	my $lawyerMemberLine = "";
	for (my $i=0; $i<scalar(@$result_ref); $i++)
    {
		my $arow = $result_ref->[$i];
		my ($id,$name,$areacode,$tel,$fax,$lawoffice_id,$service_type,$service_from_date,$service_to_date,$remark) = @$arow;
		
		my $lawoffice = "";
		if($lawoffice_id != 0)
		{
			$lawoffice = &getLawOfficeName($dbh,$lawoffice_id);
		}
		
		my $service_type_str = "";
		if($service_type == 0)
		{
			$service_type_str = "免费";
		}
		elsif($service_type == 1)
		{
			$service_type_str = "类型I";
		}
		elsif($service_type == 2)
		{
			$service_type_str = "类型II";
		}
		
		$lawyerMemberLine .= $mt->process_file('in_pmLawyerMemberLine.htm', 
			{
				'num' => "$num",
				'id' => "$id",
				'name' => "$name",
				'areacode' => "$areacode",
				'tel'=> "$tel",
				'fax'=> "$fax",
				'lawoffice' => "$lawoffice",
				'service_type' => "$service_type_str",
				'service_from_date' => "$service_from_date",
				'service_to_date' => "$service_to_date",
				'remark' => $remark,
			});
		$num += 1;
    }
    
    my $downLink = ($downStart <= $resultSum && $resultSum > 20)?1:0;
    
    print $mt->process_file('in_pgLawyerMember.htm',
		{
			'start' => "$start",
			'downlink' => "$downLink",
			'upstart' => "$upStart",
			'downstart' => "$downStart",
			'resultsum' => "$resultSum",
			'lawyermemberline' => "$lawyerMemberLine",
		});
}


#No:15
#---------------------------------------------
#Function:	check if law area is correct
#Input:		dbh handler
#			law areas
#Output:	true or false
#---------------------------------------------
sub checkLawarea
{
	my ($dbh,$areas) = @_;
	
	my @area = split /,/, $areas;
        #for(@area)
        #  {
        #  print $_;
 	#  }
        foreach (@area)
	{
		my $haveIt = $dbh->selectrow_array("SELECT id FROM LawArea WHERE name = ?",undef,$_);
		
		return 0 if(!defined($haveIt));
	}
	
	return 1;
}


#No:16
#---------------------------------------------
#Function:	check if province is correct
#Input:		dbh handler
#			province
#Output:	true or false
#---------------------------------------------
sub checkProvince
{
	my ($dbh,$province) = @_;
	
	my $haveIt = $dbh->selectrow_array("SELECT id FROM District WHERE province = ? AND city = 'nil'",undef,$province);
	
	return 0 if(!defined($haveIt));
	
	return 1;
}


#No:17
#---------------------------------------------
#Function:	check if city is correct
#Input:		dbh handler
#			city
#Output:	true or false
#---------------------------------------------
sub checkCity
{
	my ($dbh,$city) = @_;
	
	my ($haveIt) = $dbh->selectrow_array("SELECT id FROM District WHERE city = ?",undef,$city);
	
	return 0 if(!defined($haveIt));
	
	return 1;
}


#No:18
#---------------------------------------------
#Function:	show info page
#Input:		info string
#Output:	info page
#---------------------------------------------
sub showInfoPage
{
	my ($mt,$info) = @_;
	
	my @info = split /!/, $info;
	
	my $infoline;
	
	foreach (@info)
	{
		$infoline .= $mt->process_file('in_pmInfo.htm',
			{
				infostring => $_,
			});
	}
	
	print $mt->process_file('in_pgInfo.htm',
		{
			infoline => $infoline,
		});
}
#No:19
#---------------------------------------------
#Function:	selectLawyer
#Input:		selectLawyer
#Output:	info page
#---------------------------------------------
#sub selectLawyer
#{
#        my ($dbh,$mt,$id) = @_;
#
#        my $selectLine = "";
#
#        my $result_ref = $dbh->selectall_arrayref("
#                SELECT area_name FROM Lawyer_LawArea
#                WHERE area_order BETWEEN 10 AND 99 AND lawyer_id = ? ORDER BY area_name"
#                ,undef,$id);
#
#
#        for (my $i=0; $i<scalar(@$result_ref); $i++)
#        {
#                my $arow = $result_ref->[$i];
#                my ($name) = @$arow;
#
#                $selectLine .= $mt->process_file('pmSelectLine.htm',
#                        {
#                                'name' => $name,
#                                'value' => $name,
#                        });
#
#        }
#
#        return $selectLine;
#}

1;
