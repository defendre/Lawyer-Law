use strict;

#################################
#in_lawOfficeSubAll.pl
#include all sub for law office
#No:1 	addLawOffice
#No:2 	editLawOffice
#No:3 	updateLawOffice
#No:4 	deleteLawOffice
#No:5 	searchLawOffice
#No:6 	LawOfficeInfo
#No:7 	checkLawOfficeInfo
#No:8 	haveThisLawOffice
#No:9 	isMemberLawOffice
#No:10 	addLawOffice_LawArea
#No:11	getLawOffice_LawArea
#No:12	showAddLawOfficePage
#No:13	getLawOfficeID
#No:14	getLawOfficeName
#No:15	memberLawOffice
#No:16	getLawyers
#################################


#No:1
#-------------------------------------------------------------------------------
#Function:	add lawoffice info into database
#Input:		lawoffice info
#Output:	none
#-------------------------------------------------------------------------------
sub addLawOffice
{
	my $param = shift;

    my $dbh = $param->{'DBH'};
    my $mt = $param->{'METATEXT'};
    my $basedir = "/home/fahai/icons";
    
    my $init = $param->{'init'};
    if(defined($init))
    {
    	&showAddLawOfficePage($param);
    	return;
    }
    
    my $info = &lawOfficeInfo($param);
    my $err = &checkLawOfficeInfo($dbh,$mt,$info,"add");
    
    if(defined($err))
    {
    	#show err page!
    	&showErrPage($mt,$err);
    	return;
    }

    my @info;
    push(@info,$info->{'name_cn'});
	push(@info,$info->{'name_en'});
	push(@info,$info->{'sname'});
	push(@info,$info->{'province'});
	push(@info,$info->{'city'});
	push(@info,$info->{'address'});
	push(@info,$info->{'zipcode'});
	push(@info,$info->{'areacode'});
	push(@info,$info->{'tel'});
	push(@info,$info->{'fax'});
	push(@info,$info->{'email1'});
	push(@info,$info->{'email2'});
	push(@info,$info->{'website'});
	push(@info,$info->{'serial'});
	push(@info,$info->{'authdate'});
	push(@info,$info->{'language'});
	push(@info,$info->{'service_type'});
	push(@info,$info->{'service_from_date'});
	push(@info,$info->{'service_to_date'});
	push(@info,$info->{'remark'});
        push(@info,$info->{'back'});
	push(@info,$info->{'disp_level'});
        my  $filename = $info->{'filename'};
        my $file = $filename;
        $filename =~ s/^.*(\\|\/)//; # 去除上传文件的路径得到文件名
	
	$dbh->do(<<__SQL__,undef,@info);
	INSERT INTO LawOffice(name_cn,name_en,sname,province,city,address,zipcode,
		areacode,tel,fax,email1,email2,website,serial,authdate,language,
		service_type,service_from_date,service_to_date,remark,memorandum,disp_level,cdate) 
	VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,CURRENT_DATE)
__SQL__
        
        $dbh->do("INSERT INTO file (law_id,file) VALUES(LAST_INSERT_ID(),?)", undef, $file);#上传文件写入
        #get the lawoffice id
	my $id = 0;
	#my $id = getLawOfficeID($dbh,$info->{'name_cn'});
	
	&addLawOffice_LawArea($dbh,$id,$info->{'area1'},$info->{'area2'},$info->{'area3'});

       	#insert ok! and display lawyer input page.
	#reserve several input values.
	#include province,city,address,zipcode
	print $mt->process_file('in_pgLawOfficeInput.htm',
		{
			name_cn => "", name_en => "",
			province => $info->{'province'}, city => $info->{'city'}, 
			address => $info->{'address'}, zipcode => $info->{'zipcode'},
			areacode => "", tel => "", fax => "",
			email1 =>"",	email2 => "", website => "",
			serial => "", authdate => "", lawoffice => "",
			language => "", area1 => "", area2 => "", area3 => "",
			service_type => "", service_from_date => "", service_to_date => "",
			remark => "",lawyers => "",'disp_level' => "9",
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
sub editLawOffice
{
	my $param = shift;

    my $dbh = $param->{'DBH'};
    my $mt = $param->{'METATEXT'};
    
    my $id = $param->{'id'};
     
    #input type
    my $type = (!defined($param->{'type'}))?0:$param->{'type'};
    my $add = (!defined($param->{'add'}))?0:$param->{'add'};
	
	my @info = $dbh->selectrow_array(<<__SQL__,undef,$id);
	SELECT name_cn,name_en,province,city,address,zipcode,
		areacode,tel,fax,email1,email2,website,
		serial,authdate,language,service_type,service_from_date,
		service_to_date,remark,memorandum,disp_level,sname
	FROM LawOffice 
	WHERE id = ?
__SQL__

	my $area1 = &getLawOffice_LawArea($dbh,$id,1);
	my $area2 = &getLawOffice_LawArea($dbh,$id,2);
	my $area3 = &getLawOffice_LawArea($dbh,$id,3);
	
	#authdate,service_from_date,service_to_date
	$info[13] = "" if($info[13] eq '0000-00-00');
	$info[16] = "" if($info[16] eq '0000-00-00');
	$info[17] = "" if($info[17] eq '0000-00-00');
	
	my $lawyers = &getLawyers($dbh,$id,$type);

         if($add eq '2')
      {
   #$content = text2html($content,urls => 1,paras => 1,blockquotes => 1); 
  print $mt->process_file('in_pgLawOfficeInfoEdit.htm',
		{
			id => $id,
			name_cn => $info[0], name_en => $info[1],
			province => $info[2], city => $info[3], address => $info[4], zipcode => $info[5],
			areacode => $info[6], tel => $info[7], fax => $info[8],
			email1 => $info[9], email2 => $info[10], website => $info[11],
			serial => $info[12], authdate => $info[13],	language => $info[14],
			area1 => $area1,area2 => $area2, area3 => $area3,
			service_type => $info[15], service_from_date => $info[16],
			service_to_date => $info[17],remark => $info[18],back => $info[19],
			disp_level => $info[20],sname => $info[21], lawyers => $lawyers,type => $type,add => $add,
		}); 
  
       return;

      }

	print $mt->process_file('in_pgLawOfficeInfoEdit.htm',
		{
			id => $id,
			name_cn => $info[0], name_en => $info[1],
			province => $info[2], city => $info[3], address => $info[4], zipcode => $info[5],
			areacode => $info[6], tel => $info[7], fax => $info[8],
			email1 => $info[9], email2 => $info[10], website => $info[11],
			serial => $info[12], authdate => $info[13],	language => $info[14],
			area1 => $area1,area2 => $area2, area3 => $area3,
			service_type => $info[15], service_from_date => $info[16],
			service_to_date => $info[17],remark => $info[18],back => $info[19],
			disp_level => $info[20],sname => $info[21], lawyers => $lawyers,type => $type,add => $add,
		}); 
}


#No:3
#-------------------------------------------------------------------------------
#Function:	update the law office info
#Input:		post param 
#Output:	none
#-------------------------------------------------------------------------------
sub updateLawOffice
{
	my $param = shift;

    my $dbh = $param->{'DBH'};
    my $mt = $param->{'METATEXT'};
    
    my $id = $param->{'id'};
    my $basedir = "/home/fahai/icons"; 
    
    my $info = &lawOfficeInfo($param);
    my $err = &checkLawOfficeInfo($dbh,$mt,$info,"edit");
    
    if(defined($err))
    {
    	#show err page!
    	&showErrPage($mt,$err);
    	return;
    }

    my @info;
    push(@info,$info->{'name_cn'});
	push(@info,$info->{'name_en'});
	push(@info,$info->{'sname'});
	push(@info,$info->{'province'});
	push(@info,$info->{'city'});
	push(@info,$info->{'address'});
	push(@info,$info->{'zipcode'});
	push(@info,$info->{'areacode'});
	push(@info,$info->{'tel'});
	push(@info,$info->{'fax'});
	push(@info,$info->{'email1'});
	push(@info,$info->{'email2'});
	push(@info,$info->{'website'});
	push(@info,$info->{'serial'});
	push(@info,$info->{'authdate'});
	push(@info,$info->{'language'});
	push(@info,$info->{'service_type'});
	push(@info,$info->{'service_from_date'});
	push(@info,$info->{'service_to_date'});
	push(@info,$info->{'remark'});
	push(@info,$info->{'back'});
	push(@info,$info->{'disp_level'});
	
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
	UPDATE LawOffice 
	SET name_cn=?,name_en=?,sname=?,province=?,city=?,address=?,zipcode=?,
		areacode=?,tel=?,fax=?,email1=?,email2=?,website=?,serial=?,
		authdate=?,language=?,service_type=?,service_from_date=?,
		service_to_date=?,remark=?,memorandum=?,disp_level=?
	WHERE id = ?
__SQL__

	$dbh->do("DELETE FROM LawOffice_LawArea WHERE lawoffice_id = ?",undef,$id);

	&addLawOffice_LawArea($dbh,$id,$info->{'area1'},$info->{'area2'},$info->{'area3'});
	
	my $lawyer_sum= $dbh->selectrow_array(<<__SQL__,undef,$id);
           SELECT count(*) FROM Lawyer WHERE law_office = ?
__SQL__
        #my $my_id = $dbh->selectrow_array(<<__SQL__,undef,$info->{'name_cn'});
           #SELECT id FROM LawOffice WHERE name_cn LIKE  ?    
#__SQL__
   if($lawyer_sum != 0)
     {
      $dbh->do(<<__SQL__,undef,$info->{'address'},$info->{'zipcode'},$info->{'areacode'},$info->{'tel'},$info->{'fax'},$info->{'website'},$id);
      UPDATE Lawyer
      SET 
          address = ?,zipcode = ?,areacode = ?,
          tel = ?,fax = ?,
          website = ?  
      WHERE law_office = ?
__SQL__
    }   	
	
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
#Function:	delete law office info from database
#Input:		dbh
#			mt
#			law office id
#Output:	none
#-------------------------------------------------------------------------------
sub deleteLawOffice
{
	my $param = shift;

    my $dbh = $param->{'DBH'};
    my $mt = $param->{'METATEXT'};
    
    my $id = $param->{'id'};
    my $basedir = "/home/fahai/icons"; 

	$dbh->do("DELETE FROM LawOffice_LawArea WHERE lawoffice_id = ?",undef,$id);
	$dbh->do("DELETE FROM LawOffice WHERE id = ?",undef,$id);
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
#Function:	search law office
#Input:		search param
#Output:	search result
#-------------------------------------------------------------------------------
sub in_searchLawOffice
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
    $language = convert($language);    

    my $name = (!defined($param->{'name'}))?"":$param->{'name'};
    my $name2 = (!defined($param->{'name2'}))?"":$param->{'name2'};
    my $web = (!defined($param->{'web'}))?"":$param->{'web'};
    my $email = (!defined($param->{'email'}))?"":$param->{'email'}; 
    my $sum = (!defined($param->{'sum'}))?"":$param->{'sum'};
    $name = uc($name);

    my $cdate = (!defined($param->{'cdate'}))?"":$param->{'cdate'};    
    my $back = (!defined($param->{'back'}))?"":$param->{'back'};
    my $mem  = (!defined($param->{'mem'}))?"":$param->{'mem'};
    my $address  = (!defined($param->{'address'}))?"":$param->{'address'};

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

	my $resultSum = 0;
        my $file;
    my $result_ref;
    
    if(!$cdate eq '')
    {
    	($resultSum) = $dbh->selectrow_array(<<__SQL__,undef,$cdate);
    	SELECT count(*)
    	FROM LawOffice 
    	WHERE cdate = ?
__SQL__

    	$result_ref = $dbh->selectall_arrayref(<<__SQL__,undef,$cdate);
    	SELECT id,name_cn,concat(province," ",city) AS zone,zipcode,address,
    		areacode,tel,fax,email1,email2,website,
    		serial,authdate,language
    	FROM LawOffice 
    	WHERE cdate = ?
        ORDER BY disp_level,name_en 
    	LIMIT $offset,20
__SQL__
    }
    elsif(!$area eq '')
    {
		my $resultSumTmp = $dbh->selectall_arrayref(<<__SQL__,undef,"%$name%","%$email%","%$web%","%$name2%","%$province%","%$city%","%$language%","%$area%","%$back%","%$mem%","%$address%",$stype_from,$stype_to);
		SELECT t1.id
		FROM LawOffice AS t1,LawOffice_LawArea AS t2
		WHERE t1.sname LIKE ?
			AND t1.email1 LIKE ? 
			AND t1.website LIKE ? 
			AND t1.name_cn LIKE ? 
			AND t1.province LIKE ? 
			AND t1.city LIKE ? 
			AND t1.language LIKE ? 
			AND t2.area_name LIKE ? 
			AND t1.remark  LIKE ?
                        AND t1.memorandum LIKE ?
                        AND t1.address LIKE ?  
			AND t1.id=t2.lawoffice_id
			AND t1.service_type BETWEEN ? AND ?
		GROUP BY t1.id
__SQL__
		
		$resultSum = scalar(@$resultSumTmp);
		
		if(defined($download))
		{
			$result_ref = $dbh->selectall_arrayref(<<__SQL__,undef,"%$name%","%$email%","%$web%","%$name2%","%$province%","%$city%","%$language%","%$area%","%$back%","%$mem%","%$address%",$stype_from,$stype_to);
			SELECT t1.id,t1.name_cn,concat(t1.province," ",t1.city) AS zone,t1.zipcode,t1.address,
				t1.areacode,t1.tel,t1.fax,t1.email1,t1.email2,t1.website,
				t1.serial,t1.authdate,t1.language
			FROM LawOffice AS t1,LawOffice_LawArea AS t2
			WHERE t1.sname LIKE ?
				AND t1.email1 LIKE ? 
			        AND t1.website LIKE ? 
			        AND t1.name_cn LIKE ? 
				AND t1.province LIKE ? 
				AND t1.city LIKE ? 
				AND t1.language LIKE ? 
				AND t2.area_name LIKE ?
				AND t1.remark  LIKE ?
                                AND t1.memorandum LIKE ?
                                AND t1.address LIKE ? 
				AND t1.id=t2.lawoffice_id
				AND t1.service_type BETWEEN ? AND ?
			GROUP BY t1.id
			ORDER BY t1.name_en 
__SQL__
		}
		else
		{
			$result_ref = $dbh->selectall_arrayref(<<__SQL__,undef,"%$name%","%$email%","%$web%","%$name2%","%$province%","%$city%","%$language%","%$area%","%$back%","%$mem%","%$address%",$stype_from,$stype_to);
			SELECT t1.id,t1.name_cn,concat(t1.province," ",t1.city) AS zone,t1.zipcode,t1.address,
				t1.areacode,t1.tel,t1.fax,t1.email1,t1.email2,t1.website,
				t1.serial,t1.authdate,t1.language
			FROM LawOffice AS t1,LawOffice_LawArea AS t2
			WHERE t1.sname LIKE ?
				AND t1.email1 LIKE ? 
			AND t1.website LIKE ? 
			AND t1.name_cn LIKE ? 
				AND t1.province LIKE ? 
				AND t1.city LIKE ? 
				AND t1.language LIKE ? 
				AND t2.area_name LIKE ? 
				AND t1.remark  LIKE ?
                                AND t1.memorandum LIKE ?
                                AND t1.address LIKE ?
				AND t1.id=t2.lawoffice_id
				AND t1.service_type BETWEEN ? AND ?
			GROUP BY t1.id
			ORDER BY t1.disp_level,t1.name_en 
			LIMIT $offset,20
__SQL__
		}
    }
    else
    {
    	($resultSum) = $dbh->selectrow_array(<<__SQL__,undef,"%$name%","%$email%","%$web%","%$name2%","%$province%","%$city%","%$language%","%$back%","%$mem%","%$address%",$stype_from,$stype_to);
    	SELECT count(*)
    	FROM LawOffice 
    	WHERE sname LIKE ?
    		AND email1 LIKE ? 
		AND website LIKE ? 
		AND name_cn LIKE ? 
    		AND province LIKE ? 
    		AND city LIKE ? 
    		AND language LIKE ?
    		AND remark  LIKE ?
                AND memorandum LIKE ?
                AND address LIKE ?
    		AND service_type BETWEEN ? AND ?
__SQL__

    	if(defined($download))
    	{
	    	$result_ref = $dbh->selectall_arrayref(<<__SQL__,undef,"%$name%","%$email%","%$web%","%$name2%","%$province%","%$city%","%$language%","%$back%","%$mem%","%$address%",$stype_from,$stype_to);
	    	SELECT id,name_cn,concat(province," ",city) AS zone,zipcode,address,
	    		areacode,tel,fax,email1,email2,website,
	    		serial,authdate,language
	    	FROM LawOffice 
	    	WHERE sname LIKE ?
	    		AND email1 LIKE ? 
			AND website LIKE ? 
			AND name_cn LIKE ? 
	    		AND province LIKE ? 
	    		AND city LIKE ? 
	    		AND language LIKE ? 
	    		AND remark LIKE ?
                        AND memorandum LIKE ?
                        AND address LIKE ? 
	    		AND service_type BETWEEN ? AND ?
	    	ORDER BY name_en 
__SQL__
		}
		else
		{
	    	$result_ref = $dbh->selectall_arrayref(<<__SQL__,undef,"%$name%","%$email%","%$web%","%$name2%","%$province%","%$city%","%$language%","%$back%","%$mem%","%$address%",$stype_from,$stype_to);
	    	SELECT id,name_cn,concat(province," ",city) AS zone,zipcode,address,
	    		areacode,tel,fax,email1,email2,website,
	    		serial,authdate,language
	    	FROM LawOffice 
	    	WHERE sname LIKE ?
	    		AND email1 LIKE ? 
			AND website LIKE ? 
			AND name_cn LIKE ? 
	    		AND province LIKE ? 
	    		AND city LIKE ? 
	    		AND language LIKE ?
	    		AND remark LIKE ?
                        AND memorandum LIKE ?
                        AND address LIKE ?  
	    		AND service_type BETWEEN ? AND ?
	    	ORDER BY disp_level,name_en 
	    	LIMIT $offset,20
__SQL__
		}
	}
	
	my $searchLawOfficeResLine = "";

	if(defined($download))
	{
		open(LAWOFFICEFILE,">${filename}");
	}

	for (my $i=0; $i<scalar(@$result_ref); $i++)
    {
		my $arow = $result_ref->[$i];

		my $id = @$arow[0];
		my $name = @$arow[1];
		my $zone = @$arow[2];
		my $zipcode = @$arow[3];
		my $address = @$arow[4];
		my $areacode = @$arow[5];
		my $tel = @$arow[6];
		my $fax = @$arow[7];
                my $email  = @$arow[8];

		my $email1 = @$arow[8];
		my $email2 = @$arow[9];
		my $website = @$arow[10];
		my $serial = @$arow[11];
		my $authdate = @$arow[12];
		my $language = @$arow[13];

		my $area1 = &getLawOffice_LawArea($dbh,$id,1);
		my $area2 = &getLawOffice_LawArea($dbh,$id,2);
		my $area3 = &getLawOffice_LawArea($dbh,$id,3);

		my $_sum = $dbh->selectrow_array("SELECT count(*) FROM Lawyer WHERE law_office = ? ORDER BY lastname_en,firstname_en",undef,$id);
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
			
			$searchLawOfficeResLine .= $mt->process_file('in_downloadLawoffice', 
				{
					name => $name, zone => $zone, address => $address, zipcode => $zipcode,
					tel => $tel,fax => $website,'email'=> $email, email1 => $email1, 
					email2 => $email2, website => $website,
					serial => $serial, authdate => $authdate,
					language => $language,
					area1 => $area1, area2 => $area2, area3 => $area3,
				});
		}
		else
		{
			#format telephone and fax
			$tel = $areacode . "," . $tel if(!($areacode eq "") && !($tel eq ""));
			$fax = $areacode . "," . $fax if(!($areacode eq "") && !($fax eq ""));
			#$website = "无网址" if($website eq '');	

			if(($sum eq '') || ($sum >= $_sum))
			{
			   $searchLawOfficeResLine .= $mt->process_file('in_pmLawOfficeSearchResLine.htm', 
				{
					'num' => "$num",
					'id' => "$id",
					'sum'=> "$sum",
					'_sum'=> "$_sum",
					'name' => "$name",
					'zone' => "$zone",
					'tel'=> "$tel",
					'fax'=> "$website",#$website
  	                                'email'=> "$email",#$email
					'language' => "$language",
					'area' => "$area1",
					'type' => "$type",
                                        'file' => "$file",
				});
		         }
		}
		$num += 1;
    }

    if(defined($download))
    {
    	print LAWOFFICEFILE $searchLawOfficeResLine;
    	close(LAWOFFICEFILE);
    	
    	print $mt->process_file('in_pgDownload.htm');
    	
    	return;
    }
    
    my $downLink = ($downStart <= $resultSum && $resultSum > 20)?1:0;
    
    print $mt->process_file('in_pgLawOfficeSearchRes.htm',
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
			'name2'=> "$name2",
			'web'  => "$web",
			'sum'  => "$sum",
			'email'=> "$email",
			'cdate' => "$cdate",
			'back' => "$back",
                        'mem'  => "$mem",
                        'address' => "$address",
		});
}


#No:6
#--------------------------------------------------------
#Fucntion:	format law office info
#Input:		param
#Output:	formatted lawoffice info(hash table)
#--------------------------------------------------------
sub lawOfficeInfo
{
	my $param = shift;
	
	my %lawOfficeInfo;
	
	my $id = (!defined($param->{'id'}))?0:$param->{'id'};
	$lawOfficeInfo{id} = $id;
	
	my $name_cn = (!defined($param->{'name_cn'}))?"":$param->{'name_cn'};
	$lawOfficeInfo{name_cn} = $name_cn;
	
	my $name_en = (!defined($param->{'name_en'}))?"":$param->{'name_en'};
        $name_en=uc($name_en);
	$lawOfficeInfo{name_en} = $name_en;

        
	my $sname = (!defined($param->{'sname'}))?"":$param->{'sname'};
	$lawOfficeInfo{sname} = $sname;
	
	my $province = (!defined($param->{'province'}))?"":$param->{'province'};
	$lawOfficeInfo{province} = convert($province);#
	
	my $city = (!defined($param->{'city'}))?"":$param->{'city'};
	$lawOfficeInfo{city} = convert($city);#
	
	my $address = (!defined($param->{'address'}))?"":$param->{'address'};
	$lawOfficeInfo{address} = $address;
	
	my $zipcode = (!defined($param->{'zipcode'}))?"":$param->{'zipcode'};
	$lawOfficeInfo{zipcode} = $zipcode;
	
	my $areacode = (!defined($param->{'areacode'}))?"":$param->{'areacode'};
	$lawOfficeInfo{areacode} = $areacode;
	
	my $tel = (!defined($param->{'tel'}))?"":$param->{'tel'};
	$lawOfficeInfo{tel} = $tel;
	
	my $fax = (!defined($param->{'fax'}))?"":$param->{'fax'};
	$lawOfficeInfo{fax} = $fax;

	my $email1 = (!defined($param->{'email1'}))?"":$param->{'email1'};
	$lawOfficeInfo{email1} = $email1;
	
	my $email2 = (!defined($param->{'email2'}))?"":$param->{'email2'};
	$lawOfficeInfo{email2} = $email2;
	
	my $website = (!defined($param->{'website'}))?"":$param->{'website'};
	$lawOfficeInfo{website} = $website;
	
	my $serial = (!defined($param->{'serial'}))?"":$param->{'serial'};
	$lawOfficeInfo{serial} = $serial;
	
	my $authdate = (!defined($param->{'authdate'}))?"":$param->{'authdate'};
	$lawOfficeInfo{authdate} = $authdate;

	my $language = (!defined($param->{'language'}))?"":$param->{'language'};
	$lawOfficeInfo{language} = convert($language);
	
	my $area1 = (!defined($param->{'area1'}))?"":$param->{'area1'};
	$lawOfficeInfo{area1} = convert($area1);#
	
	my $area2 = (!defined($param->{'area2'}))?"":$param->{'area2'};
	$lawOfficeInfo{area2} = convert($area2);#
	
	my $area3 = (!defined($param->{'area3'}))?"":$param->{'area3'};
	$lawOfficeInfo{area3} = convert($area3);#
	
	my $service_type = (!defined($param->{'service_type'}))?"0":$param->{'service_type'};
	$lawOfficeInfo{service_type} = $service_type;
	
	my $service_from_date = (!defined($param->{'service_from_date'}))?"":$param->{'service_from_date'};
	$lawOfficeInfo{service_from_date} = convert($service_from_date);#
	
	my $service_to_date = (!defined($param->{'service_to_date'}))?"":$param->{'service_to_date'};
	$lawOfficeInfo{service_to_date} = convert($service_to_date);#

	my $remark = (!defined($param->{'remark'}))?"":$param->{'remark'};
	$lawOfficeInfo{remark} = $remark;
	
	my $back = (!defined($param->{'back'}))?"":$param->{'back'};
	$lawOfficeInfo{back} = $back;
        
        my $mem = (!defined($param->{'mem'}))?"":$param->{'mem'};
	$lawOfficeInfo{mem} = $mem;
	
	my $disp_level = (!defined($param->{'disp_level'}))?"9":$param->{'disp_level'};
	$lawOfficeInfo{disp_level} = $disp_level;
	
	my $another = (!defined($param->{'another'})) ? 0 : 1;
	$lawOfficeInfo{another} = $another;

        my $filename = (!defined($param->{'FILE_NAME'}))?"":$param->{'FILE_NAME'};
	$lawOfficeInfo{filename} = $filename;

	return \%lawOfficeInfo;
}


#No:7
#--------------------------------------------------------
#Function:	check the info of lawOffice
#Input:		dbh handler
#			mt handler
#			hash ref
#			info type(add,edit)
#Output:	error string
#--------------------------------------------------------
sub checkLawOfficeInfo
{
	my ($dbh,$mt,$param,$type) = @_;
	
    my $errStrLine = "";

	my $name_cn = $param->{'name_cn'};
	my $name_en = $param->{'name_en'};
        my $filename = $param->{'filename'}; 
        my $file = $filename;
        $name_en=uc($name_en);
	#check law office name
	if($name_cn eq '' || $name_en eq '')
	{
		$errStrLine .= "请输入机构名称的中文和拼音!";
		return $errStrLine;
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

	#check if the law office exist
	my $id = (!defined($param->{'id'}))?0:$param->{'id'};
	
	#id = 0 --> add;id != 0 --> edit
	if(haveThisLawOffice($dbh,$name_cn,$id) && !($param->{'another'} eq '1'))
	{
		$errStrLine .= "该机构的记录已经存在!";
		return $errStrLine;
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

	#
	if(!isChars($name_en) || !isChars($name_en))
	{
		$errStrLine .= "机构名称的拼音填写错误!";
	}
	
	my $zipcode = $param->{'zipcode'};
	my $areacode = $param->{'areacode'};
	my $tel = $param->{'tel'};
	my $fax = $param->{'fax'};
	
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
	
	my $email1 = $param->{'email1'};
	my $email2 = $param->{'email2'};
if(!$email1 eq '' || !$email2 eq '' && ($email1=~m/-/) || ($email2=~m/-/) )
   {	
;
   }
elsif(!$email1 eq '' && !isValidEmail($email1))
	{
		$errStrLine .= "email1填写错误!";
	}

elsif(!$email2 eq '' && !isValidEmail($email2))
	{
		$errStrLine .= "email2填写错误!";
	}

	
	my $serial = $param->{'serial'};
	
	#check authdate format!
	my $authdate = $param->{'authdate'};
	if(!$authdate eq '' && !isValidDate($authdate))
	{
		$errStrLine .= "机构注册日期填写错误!";
	}

	#check lawOffice lawarea
	my $area1 = $param->{'area1'};
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
#			lawOffice name
#Output:	true or false
#---------------------------------------------
sub haveThisLawOffice
{
	my ($dbh,$name,$id) = @_;
	
	my $haveit;
	if($id == 0)
	{
		($haveit) = $dbh->selectrow_array(
			"SELECT id FROM LawOffice WHERE name_cn = ?",
			undef,$name);
	}
	else
	{
		($haveit) = $dbh->selectrow_array(
			"SELECT id FROM LawOffice WHERE name_cn = ? AND id != ?",
			undef,$name,$id);
	}
	
	return 0 if(!defined($haveit));
	
	return 1;
}


#No:9
#---------------------------------------------
#Function:	check if a law office is a member
#Input:		database handler
#			lawoffice id
#Output:	true or false
#---------------------------------------------

sub isMemberLawOffice
{
	my ($dbh,$id) = @_;
	
	my $member = $dbh->selectrow_array(<<__SQL__,undef,$id);
	SELECT id FROM LawOffice 
	WHERE CURRENT_DATE BETWEEN service_from_date AND service_to_date AND id = ?
__SQL__
	
	return 0 if(!defined($member));
	

	return 1;
}


#No:10
#---------------------------------------------
#Input:		database handler
#			lawoffice id
#			lawoffice area1
#			lawoffice area2
#			lawoffice area3
#Output:	none
#---------------------------------------------
sub addLawOffice_LawArea
{
	my ($dbh,$id,$area1,$area2,$area3) = @_;

	if(!$area1 eq '')
	{
		my @area = split /,/,$area1;
		my $i=1;			
		foreach(@area)
		{
			
	           if($id == 0)
                    {
                   $dbh->do("INSERT INTO LawOffice_LawArea(lawOffice_id,area_name,area_order) VALUES(LAST_INSERT_ID(),?,?)", undef, $_, $i);
                     	$i += 1;
                    }
                   else
                   {
                   $dbh->do("INSERT INTO LawOffice_LawArea(lawOffice_id,area_name,area_order) VALUES(?,?,?)", undef, $id, $_, $i);
			$i += 1;
                   }
			
		}
	}
	if(!$area2 eq '')
	{
		my @area = split /,/,$area2;
		my $i=3;			
		foreach(@area)
		{
		   if($id == 0)
                    {
                   $dbh->do("INSERT INTO LawOffice_LawArea(lawOffice_id,area_name,area_order) VALUES(LAST_INSERT_ID(),?,?)", undef, $_, $i);
                     	$i += 1;
                    }
                   else
                   {
                   $dbh->do("INSERT INTO LawOffice_LawArea(lawOffice_id,area_name,area_order) VALUES(?,?,?)", undef, $id, $_, $i);
			$i += 1;
                   }
		}
	}
	if(!$area3 eq '')
	{
		my @area = split /,/,$area3;
		my $i=7;
		foreach(@area)
		{
		   if($id == 0)
                    {
                   $dbh->do("INSERT INTO LawOffice_LawArea(lawOffice_id,area_name,area_order) VALUES(LAST_INSERT_ID(),?,?)", undef, $_, $i);
                     	$i += 1;
                    }
                   else
                   {
                   $dbh->do("INSERT INTO LawOffice_LawArea(lawOffice_id,area_name,area_order) VALUES(?,?,?)", undef, $id, $_, $i);
			$i += 1;
                   }
		}
	}	
}


#No:11
#---------------------------------------------
#Input:		database handler
#			lawoffice id
#			the num of lawarea
#Output:	a string of lawoffice lawarea
#---------------------------------------------
sub getLawOffice_LawArea
{
	my ($dbh,$id,$num) = @_;
	
	my $result_ref;
	
	if($num == 1)
	{
		$result_ref = $dbh->selectall_arrayref(<<__SQL__,undef,$id);
		SELECT area_name 
		FROM LawOffice_LawArea 
		WHERE area_order BETWEEN 1 AND 2 AND lawoffice_id = ? 
		ORDER BY area_order
__SQL__
	}
	elsif($num == 2)
	{
		$result_ref = $dbh->selectall_arrayref(<<__SQL__,undef,$id);
		SELECT area_name 
		FROM LawOffice_LawArea
		WHERE area_order BETWEEN 3 AND 6 AND lawoffice_id = ? 
		ORDER BY area_order
__SQL__

	}
	elsif($num == 3)
	{
		$result_ref = $dbh->selectall_arrayref(<<__SQL__,undef,$id);
		SELECT area_name 
		FROM LawOffice_LawArea
		WHERE area_order BETWEEN 7 AND 10 AND lawoffice_id = ? 
		ORDER BY area_order
__SQL__
	}
	
	my @lawArea;
	
	for (my $i=0; $i<scalar(@$result_ref); $i++)
    {
		my $arow = $result_ref->[$i];
		my ($area) = @$arow;
		push (@lawArea,$area);
	}

	return join(',',@lawArea);
}


#No:12
#-------------------------------------------------------------------------------
#Fuction:	display law office input page for the first time
#input:		dbh handler
#			metatext handler
#output:	law office input page
#-------------------------------------------------------------------------------
sub showAddLawOfficePage
{
	my $param = shift;

    my $dbh = $param->{'DBH'};
    my $mt = $param->{'METATEXT'};
	
	my $type = (!defined($param->{'type'}))?0:$param->{'type'};
	
	print $mt->process_file('in_pgLawOfficeInput.htm',
		{
			name_cn => "", name_en => "",
			province => "", city => "", address => "", zipcode => "",
			areacode => "", tel => "", fax => "",
			email1 =>"",	email2 => "", website => "",
			serial => "", authdate => "", lawoffice => "",
			language => "", area1 => "", area2 => "", area3 => "",
			service_type => "", service_from_date => "", service_to_date => "",
			remark => "",lawyers => "",'disp_level' => "9",
			type => $type,
		}); 
}


#No:13
#--------------------------------------------------------
#Function:	get law office id
#Input:		dbh handler
#			law office name
#Output:	law office id
#--------------------------------------------------------
sub getLawOfficeID
{
	my ($dbh,$name) = @_;
	
	my $id;
	if($name eq '')
	{
		$id = 0;
	}
	else
	{
		($id) = $dbh->selectrow_array("SELECT id FROM LawOffice WHERE name_cn = ?", undef, $name);
	}
	
	return undef if(!defined($id));
	
	return $id;
}


#No:14
#--------------------------------------------------------
#Function:	get law office name
#Input:		dbh handler
#			law office id
#Output:	law office name
#--------------------------------------------------------
sub getLawOfficeName
{
	my ($dbh,$id) = @_;
	
	my ($name) = $dbh->selectrow_array("SELECT name_cn FROM LawOffice WHERE id = ?",undef,$id);
	
	return undef if(!defined($name));
	
	return $name;
}


#No:15
#---------------------------------------------
#Function:	show member lawoffice whose membership expire
#Input:		none
#Output:	result page
#---------------------------------------------
sub memberLawOffice
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
    SELECT count(id)
	FROM LawOffice 
	WHERE to_days(service_to_date) != 0 AND to_days(service_from_date) != 0 
		#AND CURRENT_DATE NOT BETWEEN service_from_date AND service_to_date
		AND CURRENT_DATE > service_to_date
__SQL__
    
	my $result_ref = $dbh->selectall_arrayref(<<__SQL__);
	SELECT id,name_cn,areacode,tel,fax,service_type,service_from_date,service_to_date,remark
	FROM LawOffice 
	WHERE to_days(service_to_date) != 0 AND to_days(service_from_date) != 0 
		#AND CURRENT_DATE NOT BETWEEN service_from_date AND service_to_date
		AND CURRENT_DATE > service_to_date
        ORDER BY name_en 
	LIMIT $offset,20
__SQL__
	
	my $lawOfficeMemberLine = "";
	for (my $i=0; $i<scalar(@$result_ref); $i++)
    {
		my $arow = $result_ref->[$i];
		my ($id,$name,$areacode,$tel,$fax,$service_type,$service_from_date,$service_to_date,$remark) = @$arow;
		
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

		$lawOfficeMemberLine .= $mt->process_file('in_pmLawOfficeMemberLine.htm', 
							{
								'num' => "$num",
								'id' => "$id",
								'name' => "$name",
								'areacode' => "$areacode",
								'tel'=> "$tel",
								'fax'=> "$fax",
								'service_type' => "$service_type_str",
								'service_from_date' => "$service_from_date",
								'service_to_date' => "$service_to_date",
								'remark' => $remark,
							});
		$num += 1;
    }
    
    my $downLink = ($downStart <= $resultSum && $resultSum > 20)?1:0;
    
    print $mt->process_file('in_pgLawOfficeMember.htm',
    					{
    						'start' => "$start",
    						'downlink' => "$downLink",
    						'upstart' => "$upStart",
    						'downstart' => "$downStart",
    						'resultsum' => "$resultSum",
    						'lawofficememberline' => "$lawOfficeMemberLine",
    					});
}


#No:16
#---------------------------------------------
#Function:	show lawyers
#Input:		dbh,
#			law office id
#Output:	lawyers
#---------------------------------------------
sub getLawyers
{
	my ($dbh,$id,$type) = @_;
	
	my $result_ref = $dbh->selectall_arrayref(
		"SELECT id,concat(lastname_cn,firstname_cn) AS name FROM Lawyer WHERE law_office = ? ORDER BY lastname_en,firstname_en",
		undef,$id);
	
	my @lawyers;
	
	for (my $i=0; $i<scalar(@$result_ref); $i++)
    {

		my $arow = $result_ref->[$i];
		my ($id,$lawyer) = @$arow;
		my $lawyerStr = "<a href=/inside-cgi/in_lawyer.pl?cmd=edit&id=" . $id . "&type=" . $type .">" . $lawyer ."</a>";
		push (@lawyers,$lawyerStr);
	}

	return join(',',@lawyers);
}

1;
