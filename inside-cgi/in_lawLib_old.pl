use strict;
#################################
#in_lawLib.pl
#include all sub for law
#No:1 	addLaw
#No:2 	editLaw
#No:3 	updateLaw
#No:4 	deleteLaw
#No:5 	in_searchLaw
#No:6 	showAddLawPage
#No:7 	haveThisLaw
#No:8 	checkBigArea
#No:9 	checkLawName
#No:10  checkLawkeyword
#################################





#No:1
sub addLaw
{

	my $param = shift;
    my $dbh = $param->{'DBH'};
    my $mt = $param->{'METATEXT'};
    my $cgi = $param->{'LAW'};


     my $basedir = "/home/httpd/online/icons";


    my $init = $param->{'init'};
    if(defined($init))
    {
    	&showAddLawPage($param);
    	return;
    }
  

	my $area = (!defined($param->{'area'}))?"":$param->{'area'};
	my $type = (!defined($param->{'type'}))?"":$param->{'type'};

	my $title = (!defined($param->{'title'}))?"":$param->{'title'};
	my $content = (!defined($param->{'content'}))?"":$param->{'content'};
	my $keyword = (!defined($param->{'keyword'}))?"":$param->{'keyword'};

       my $filename = $cgi->param('FILE_NAME'); # 获取表单中的FILE_NAME域
       my $file = $filename;

        $filename =~ s/^.*(\\|\/)//;

        my $cdate ='0000-00-00';
    
	my @councilCity = ('TS工时统计','案件开支统计','案件帐单统计','办公开支统计','帐单收入统计','财产管理统计');

 foreach (@councilCity)
        {
            ($keyword,$cdate)=split(/\//,$keyword) if($area eq $_);
        }
       

        if($filename !~ /\.jpg/gi && $filename ne '')
	 {
		&showErrPage($mt,"上传文件类型JPEG图片!");
		return;
	 }  

	if($area eq '' || $type eq '' || $title eq '' || $content eq '')
	{
		&showErrPage($mt,"主库类别，辅库类别，主关键字，内容正文!");
		return;
	}
	

	$area    = convert($area);
	$type    = convert($type);
       	$keyword = convert($keyword);
	#检查法律领域

	if(!checkBigArea($dbh,$area))
	{
		&showErrPage($mt,"主库类别填写错误!");
		return;
	}

	#检查法律名称
	if(!checkLawName($dbh,$type,$area))
	{
		&showErrPage($mt,"辅库类别填写错误!");
		return;
	}

	

      if($area eq 'TS工时统计' || $area eq  '案件开支统计' || $area eq '案件帐单统计' || $area eq '办公开支统计' || $area eq '帐单收入统计' || $area eq	'财产管理统计')
       { 
          if(!ValidDate($cdate))      
  	  {
		&showErrPage($mt,"副关键填写错误!");
		return;
	  }  

         



       } 
    

        if(&haveThisLaw($param))
	  {
		&showErrPage($mt,"该信息已经存在!");
		return;
	  }
 
        if(&haveThisLaw_Law($param))
	  {
		&showErrPage($mt,"该信息已经存在!");
		return;
	  }

  #      if($area eq 'TS工时统计' || $area eq  '案件开支统计' || $area eq '案件帐单统计' || $area eq '办公开支统计')

 #       {

         #$dbh->do("INSERT INTO Law(area,type,title,content,keyword,DATE_FORMAT(cdate,'%Y-%m-%d')) VALUES(?,?,?,?,?,?)",

	#undef,convert($area),convert($type),convert($title),$content,$keyword,$cdate);

#

 #       }

  #      else

  #      {

	$dbh->do("INSERT INTO Law(area,type,title,content,keyword,cdate) VALUES(?,?,?,?,?,?)",
		undef,convert($area),convert($type),convert($title),$content,$keyword,$cdate);
        $dbh->do("INSERT INTO file (law_id,file) VALUES(LAST_INSERT_ID(),?)", undef, $file);

       # }         
        
        &showInfoPage($mt,"记录添加成功!");   
       
        open (OUTFILE,">$basedir/$filename"); # 写入到服务器的本地文件 
        binmode(OUTFILE); # 文件句柄设置为二进制模式 
        while (my $bytesread=read($file,my $buffer,1024)) { 
        print OUTFILE $buffer; 
        } 
        close OUTFILE; # 关闭文件       	  
}





#No:2

sub editLaw
{
	my $param = shift;

    my $dbh = $param->{'DBH'};
    my $mt = $param->{'METATEXT'};
  

    my $id = $param->{'id'};
    my $own = $param->{'own'}; 
    my $add = (!defined($param->{'add'}))?0:$param->{'add'};

	my ($area,$type,$title,$content,$keyword,$cdate) = $dbh->selectrow_array(
		"SELECT area,type,title,content,keyword,cdate FROM Law WHERE id = ?",
		undef,$id);

    	my ($file) = $dbh->selectrow_array(
		"SELECT file FROM file WHERE law_id = ?",
		undef,$id);

        
        $file =~ s/^.*(\\|\/)//;
	my @councilCity = ('TS工时统计','案件开支统计','案件帐单统计','办公开支统计','帐单收入统计','财产管理统计');



 if($add eq '1')
 {
 foreach (@councilCity)
        {
            $keyword = $keyword.'/'.$param->{'DATE'} if($area eq $_);
        }
 } 
 else
 {
 foreach (@councilCity)
        {                       
            $keyword = $keyword.'/'.$cdate if($area eq $_);
        }
 }

	my $bigareaLine = selectBigarea($dbh,$mt,$own);
	my $lawnameLine = selectLawName($dbh,$mt,$own);

	print $mt->process_file('in_pgLawInfoEdit.htm',
   					{
    						'id' => $id,
    						'area' => $area,
    						'type' => $type,
    						'title' => $title,
    						'content' => $content,
   						'keyword' => $keyword,
    						'bigarealine' => $bigareaLine,
						'lawnameline' => $lawnameLine,
						'add'         => $add, 
                                                'own'         => $own,
                                                'file'       => $file,
    					}); 
}



#No:3
sub updateLaw
{
	my $param = shift;



    my $dbh = $param->{'DBH'};
    my $mt = $param->{'METATEXT'};
    my $cgi = $param->{'LAW'};

    my $basedir = "/home/httpd/online/icons";   
   my $id = $param->{'id'};

   
	my $area = (!defined($param->{'area'}))?"":$param->{'area'};
	my $type = (!defined($param->{'type'}))?"":$param->{'type'};
	my $title = (!defined($param->{'title'}))?"":$param->{'title'};
	my $content = (!defined($param->{'content'}))?"":$param->{'content'};
	my $keyword = (!defined($param->{'keyword'}))?"":$param->{'keyword'};
        my $filename = $cgi->param('FILE_NAME'); # 获取表单中的FILE_NAME域
        my $file = $filename;



        $filename =~ s/^.*(\\|\/)//;
        my $time = $keyword;
        my $cdate ='0000-00-00';

	

        my @councilCity = ('TS工时统计','案件开支统计','案件帐单统计','办公开支统计','帐单收入统计','财产管理统计');





 foreach (@councilCity)
        {
            ($time,$cdate)=split(/\//,$keyword) if($area eq $_);
        }      	
         if($filename !~ /\.jpg/gi && $filename ne '')
	 {
		&showErrPage($mt,"上传文件类型JPEG图片!");
		return;
	 }  

	if($area eq '' || $type eq '' || $title eq '' || $content eq '')

	{
		&showErrPage($mt,"主库类别，辅库类别，主关键字，内容正文!");
		return;
	}



	$area = convert($area);
	$type = convert($type);
        $time = convert($time);	
	

        #检查法律领域

	if(!checkBigArea($dbh,$area))
	{
		&showErrPage($mt,"主库类别填写错误!");
		return;
	}

	

	#检查法律名称

	if(!checkLawName($dbh,$type,$area))
	{
		&showErrPage($mt,"辅库类别填写错误!");
		return;
	}
	

  

       if($area eq 'TS工时统计' || $area eq  '案件开支统计' || $area eq '案件帐单统计' || $area eq '办公开支统计' || $area eq '帐单收入统计'|| $area eq '财产管理统计')
       { 

       	 if(!ValidDate($cdate))
          {
                &showErrPage($mt,"副关键填写错误!");
                return;       
          }
       } 

     

        

	#if(&haveThisLaw($param))
	#{
	#	&showErrPage($mt,"该信息已经存在!");
	#	return;
	#}

        

        #if($area eq 'TS工时统计' || $area eq  '案件开支统计' || $area eq '案件帐单统计' || $area eq '办公开支统计')
        #{
	#$dbh->do("UPDATE Law SET area=?,type=?,title=?,content=?,keyword=?,cdate= DATE_FORMAT(?,'%Y-%m-%d') WHERE id = ?",
	#		undef,$area,$type,$title,$content,$time,$cdate,$id);
        #}
	#else
        #{
        $dbh->do("UPDATE Law SET area=?,type=?,title=?,content=?,keyword=?,cdate= ? WHERE id = ?",
			undef,$area,$type,$title,$content,$time,$cdate,$id);
        #}

        my ($old_file) = $dbh->selectrow_array(<<__SQL__,undef,"$id");
	SELECT file FROM file WHERE  law_id  LIKE ?       
__SQL__

        $old_file =~ s/^.*(\\|\/)//;

        if($old_file)
        {
        $dbh->do("UPDATE file SET file=?  WHERE law_id = ?",undef,$file,$id);     
        }
        else
            {
             $dbh->do("INSERT INTO file (law_id,file) VALUES(?,?)",undef, $id, $file);
            }

        &showInfoPage($mt,"修改成功!");
               

        if((-e "$basedir/$old_file"))
         {
          open (OUTFILE,">$basedir/$old_file"); # 写入到服务器的本地文件 
        binmode(OUTFILE); # 文件句柄设置为二进制模式 
        while (my $bytesread=read($file,my $buffer,1024)) { 
        print OUTFILE $buffer; 
        } 

           rename("$basedir/$filename","$basedir/$old_file") || die"原文件不存在";
         }
         else
             {
              open (OUTFILE,">$basedir/$filename"); # 写入到服务器的本地文件 
        binmode(OUTFILE); # 文件句柄设置为二进制模式 
        while (my $bytesread=read($file,my $buffer,1024)) { 
        print OUTFILE $buffer; 
        } 
             }

        close OUTFILE; # 关闭文件 
}





#No:4
sub deleteLaw
{
	my $param = shift;

    my $dbh = $param->{'DBH'};
    my $mt = $param->{'METATEXT'};

    my $basedir = "/home/httpd/online/icons"; 
  

    my $id = $param->{'id'};
	$dbh->do("DELETE FROM Law WHERE id = ?",undef,"$id");

        $dbh->do("DELETE FROM file WHERE law_id = ?",undef,"$id");

     my ($filename) = $dbh->selectrow_array(<<__SQL__,undef,"$id");
	SELECT file FROM file WHERE  law_id  LIKE ?       
__SQL__

     $filename =~ s/^.*(\\|\/)//; 

	&showInfoPage($mt,"删除成功!");

      unlink("$basedir/$filename"); 
}





#No:5

sub in_searchLaw
{
	my $param = shift;
        

    my $dbh = $param->{'DBH'};

    my $mt = $param->{'METATEXT'};

    

    my $download = $param->{'download'};

    my $filename = "/home/cmlo/inside-html/download.txt";



 	my $area = (!defined($param->{'area'}))?"":$param->{'area'};

	

	my $type = (!defined($param->{'type'}))?"":$param->{'type'};

        $type = $param->{'sel_type'} if(!$param->{'sel_type'} eq "");

        $type = convert($type);



	my $title = (!defined($param->{'title'}))?"":$param->{'title'};

	my $keyword = (!defined($param->{'keyword'}))?"":$param->{'keyword'};

        my $text  = (!defined($param->{'text'}))?"":$param->{'text'};

	my $service_from_date = $param->{'service_from_date'}; 

	

	$service_from_date = '1901-01-01' if($service_from_date eq '');

	

	my $service_to_date = $param->{'service_to_date'};

	

	$service_to_date = '2099-12-31' if($service_to_date eq '');

	

        my $own = $param->{'own'};

                  



        my $select  = (!defined($param->{'select'}))?"":$param->{'select'};

        my $no_data = (!defined($param->{'no_data'}))?"":$param->{'no_data'};



    

   	my $start = (!defined($param->{'start'}))?1:$param->{'start'};

   	my $time='';

   	

	my $num = $start;

	

	my $upStart = $start - 20;

	my $downStart = $start + 20;

	

	my $offset = $start - 1;

	my $resultSum = 0;

	

        my @councilkeyword = ('TS工时统计','案件开支统计','案件帐单统计','办公开支统计','帐单收入统计','财产管理统计');



	###################

        #linker for (+/*)

         my $linker ='+';

         my @titlelinker =split(/\+/,$title);

         my $numlinker = @titlelinker;

            if ($numlinker == 1)

              {

                @titlelinker =split(/\*/,$title);

                $numlinker = @titlelinker;

                if ($numlinker >= 2)

                  {

                   $linker ='*';

                  }

              }  

        ###################################

        #主关键字是否有效！

         if($numlinker >= 2)

          {

          	 &showErrPage($mt,"主关键字填写错误!");

                 return;

          }	    

       ###################################

         



        ###################

        #Name from BigArea 

        ###################

        my $iown ;





        my $link  = (!defined($param->{'Sum_Reg'}))?0:$param->{'Sum_Reg'};

        

        my $Lawyer_id = 0;

        my $Sum_Reg = 0;

        

        $iown =$dbh->selectrow_array(<<__SQL__,undef,"%$area%");

                SELECT name FROM BigArea

                WHERE  (own LIKE "%.1" OR own LIKE "%.2") AND name LIKE ?

__SQL__

        $iown = 0 if($iown eq "");

        ###################

        #Reg -->user or password

        

        my $name = (!defined($param->{'name'}))?"":$param->{'name'};

        my $password = (!defined($param->{'password'}))?"":$param->{'password'};

        

        ###################################################

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

       my $lawName = (!defined(selectLawyer($dbh,$mt,$Lawyer_id)))?0:selectLawyer($dbh,$mt,$Lawyer_id);

   

       #my $lawName = (!defined(selectLawyer($dbh,$mt,$Lawyer_id)))?"":selectLawyer($dbh,$mt,$Lawyer_id);    

          $lawName = ""  if($link == 1);

       #################################

       #TS考勤与另主库类别查询

        if($service_from_date != '1901-01-01'  || $service_to_date != '2099-12-31')

        {



        ($resultSum) = $dbh->selectrow_array(<<__SQL__,undef,"%$area%","%$type%","%$title%","%$keyword%","%$text%","$service_from_date","$service_to_date");



	SELECT count(*)

    FROM Law 

    WHERE  area LIKE ? AND type LIKE ? AND title LIKE ? AND  concat(keyword,cdate) LIKE ? AND content LIKE ?

           AND to_days(cdate) >= to_days(?) AND to_days(cdate) <= to_days(?)

__SQL__

         }

         else

         {

      	 ($resultSum) = $dbh->selectrow_array(<<__SQL__,undef,"%$area%","%$type%","%$title%","%$keyword%","%$text%");

	SELECT count(*)

        FROM Law 

        WHERE  area LIKE ? AND type LIKE ? AND title LIKE ? 

        AND keyword LIKE ? AND content LIKE ?

__SQL__

                     

         }

        if ($title eq '' && $link == 1){

         ($resultSum) = $dbh->selectrow_array(<<__SQL__,undef,"%$area%","%$type%","%#%","%$keyword%","%$text%");

	SELECT count(*)

        FROM Law 

        WHERE  area LIKE ? AND type LIKE ? AND title NOT LIKE ? 

        AND keyword LIKE ? AND content LIKE ?

__SQL__



        }      

        if ($no_data == 1){  

        ($resultSum) = $dbh->selectrow_array(<<__SQL__,undef);

        SELECT count(*) 

        FROM Law LEFT JOIN BigArea ON Law.area=BigArea.name

        LEFT JOIN LawName ON Law.type=LawName.name

        WHERE

        BigArea.name is NULL

        OR LawName.name is NULL

        OR Law.cdate is NULL

        OR Law.cdate = ""



__SQL__

                            } 

        #SELECT count(*)

     	#FROM Law 

    	#WHERE ( area LIKE "%统计%" AND ( cdate = "" OR cdate = "0000-00-00" ))  



        #OR ( area LIKE "%管理%" AND cdate = "" )

        #OR cdate LIKE "" OR cdate is NULL



       ###################################

       #Reg用户是否有效！

       

       if($Sum_Reg == 0 && $iown eq $area && $name )

          {

          	 &showErrPage($mt,"无权访问!");

                 return;

          }	    

       ###################################

    

    

    #foreach(@councilkeyword)

      #{

       if($area eq 'TS工时统计')

       {

       $time = $dbh->selectrow_array(<<__SQL__,undef,"%$area%","%$type%","%$keyword%","%$title%","%$text%","$service_from_date","$service_to_date");

    select SEC_TO_TIME(SUM(TIME_TO_SEC(TIME_FORMAT(keyword,'%H:%i:%s'))))

    FROM Law

    WHERE area LIKE ? AND type LIKE ?

    AND concat(keyword,cdate) LIKE ?

    AND title LIKE ? AND content LIKE ?

    AND to_days(cdate) >= to_days(?) AND to_days(cdate) <= to_days(?)

 

__SQL__

         

          #($resultSum) = $service_to_date;



  

            if(!checkLawkeyword($dbh,$keyword))

	       {

          &showErrPage($mt,"副关键字填写错误!");

          return;

	       } 

       

            if(!checkLawkeyword($dbh,$service_from_date))

	       {

          &showErrPage($mt,"副关键字填写错误!");



          return;

	       } 

       

            if(!checkLawkeyword($dbh,$service_to_date))

	       {

          &showErrPage($mt,"副关键字填写错误!");

          return;

	       } 

           

          }

        elsif($area eq '案件开支统计' || $area eq '案件帐单统计' || $area eq '办公开支统计' || $area eq '帐单收入统计'|| $area eq '财产管理统计')



            {



   $time = $dbh->selectrow_array(<<__SQL__,undef,"%$area%","%$type%","%$keyword%","%$title%","%$text%","$service_from_date","$service_to_date");

    select SUM(keyword)

    FROM Law

    WHERE area LIKE ? AND type LIKE ?

    AND concat(keyword,cdate) LIKE ?

    AND title LIKE ? AND content LIKE ?

    AND to_days(cdate) >= to_days(?) AND to_days(cdate) <= to_days(?)



__SQL__

             

            if(!checkLawkeyword($dbh,$service_from_date))

	       {

          &showErrPage($mt,"副关键字填写错误!");

          return;

	       } 

       

            if(!checkLawkeyword($dbh,$service_to_date))

	       {

          &showErrPage($mt,"副关键字填写错误!");

          return;

	       } 

            	

            }	    	    

      

      #}    

        

    

    

    

    

    if($time eq '00:00:00')

        {

          $time = '';

        }



    my $result_ref;



    if(defined($download))

    {



        if($area eq 'TS工时统计' || $area eq '案件开支统计' || $area eq '案件帐单统计' || $area eq '办公开支统计' || $area eq '帐单收入统计'|| $area eq '财产管理统计')

         {

           if ($title eq '' && $link == 1){                          

        $result_ref = $dbh->selectall_arrayref(<<__SQL__,undef,"%$area%","%$type%","%#%","%$keyword%","%$text%","$service_from_date","$service_to_date");

        SELECT id,area,type,title,content,keyword,cdate

     	FROM Law 

    	WHERE area LIKE ? AND type LIKE ? AND title NOT LIKE ? 

        AND concat(keyword,cdate) LIKE ? AND content LIKE ?

        AND to_days(cdate) >= to_days(?) AND to_days(cdate) <= to_days(?) 

        ORDER BY cdate DESC,id DESC

        

__SQL__

                   } 

                   else{                    

        $result_ref = $dbh->selectall_arrayref(<<__SQL__,undef,"%$area%","%$type%","%$title%","%$keyword%","%$text%","$service_from_date","$service_to_date");

        SELECT id,area,type,title,content,keyword,cdate

     	FROM Law 

    	WHERE area LIKE ? AND type LIKE ? AND title LIKE ? 

        AND concat(keyword,cdate) LIKE ? AND content LIKE ?

        AND to_days(cdate) >= to_days(?) AND to_days(cdate) <= to_days(?)

        ORDER BY area,type,cdate DESC,id DESC   

__SQL__

                     }

           if ($select eq '1'){

          $result_ref = $dbh->selectall_arrayref(<<__SQL__,undef,"%$area%","%$type%","%$title%","%$keyword%","%$text%","$service_from_date","$service_to_date");

        SELECT id,area,type,title,content,keyword,cdate

     	FROM Law 

    	WHERE area LIKE ? AND type LIKE ? AND title LIKE ? 

        AND concat(keyword,cdate) LIKE ? AND content LIKE ?

        AND to_days(cdate) >= to_days(?) AND to_days(cdate) <= to_days(?)

        ORDER BY area,type,title,cdate DESC,id DESC   

__SQL__

                      }

            ($resultSum) = scalar(@$result_ref);

         }

         else

            {

              if ($title eq '' && $link == 1){                          

        $result_ref = $dbh->selectall_arrayref(<<__SQL__,undef,"%$area%","%$type%","%#%","%$keyword%","%$text%");

        SELECT id,area,type,title,content,keyword,cdate

     	FROM Law 

    	WHERE area LIKE ? AND type LIKE ? AND title NOT LIKE ? 

        AND keyword LIKE ? AND content LIKE ?

        ORDER BY area,type,title

__SQL__



                            }	

                            else{

        $result_ref = $dbh->selectall_arrayref(<<__SQL__,undef,"%$area%","%$type%","%$title%","%$keyword%","%$text%");

        SELECT id,area,type,title,content,keyword,cdate

  	FROM Law 

    	WHERE area LIKE ? AND type LIKE ? AND title LIKE ? 

        AND keyword LIKE ? AND content LIKE ?

        ORDER BY area,type,title

__SQL__

                                 }



           }

      

    }

    else

    {

        if($area eq 'TS工时统计' || $area eq '案件开支统计' || $area eq '案件帐单统计' || $area eq '办公开支统计' || $area eq '帐单收入统计'|| $area eq '财产管理统计')

         {        

            if ($title eq '' && $link == 1){                          

        $result_ref = $dbh->selectall_arrayref(<<__SQL__,undef,"%$area%","%$type%","%#%","%$keyword%","%$text%","$service_from_date","$service_to_date");

        SELECT id,area,type,title,content,keyword,cdate

     	FROM Law 

    	WHERE area LIKE ? AND type LIKE ? AND title NOT LIKE ? 

        AND concat(keyword,cdate) LIKE ? AND content LIKE ?

        AND to_days(cdate) >= to_days(?) AND to_days(cdate) <= to_days(?) 

        ORDER BY cdate DESC,id DESC

    	LIMIT $offset,20

__SQL__

                            } 

                            else{

          $result_ref = $dbh->selectall_arrayref(<<__SQL__,undef,"%$area%","%$type%","%$title%","%$keyword%","%$text%","$service_from_date","$service_to_date");

        SELECT id,area,type,title,content,keyword,cdate

     	FROM Law 

    	WHERE area LIKE ? AND type LIKE ? AND title LIKE ? 

        AND concat(keyword,cdate) LIKE ? AND content LIKE ?

        AND to_days(cdate) >= to_days(?) AND to_days(cdate) <= to_days(?)

        ORDER BY area,type,cdate DESC,id DESC

    	LIMIT $offset,20

__SQL__

                        

                               }          

         #($resultSum) = scalar(@$result_ref);

          if ($select eq '1'){

            $result_ref = $dbh->selectall_arrayref(<<__SQL__,undef,"%$area%","%$type%","%$title%","%$keyword%","%$text%","$service_from_date","$service_to_date");

        SELECT id,area,type,title,content,keyword,cdate

     	FROM Law 

    	WHERE area LIKE ? AND type LIKE ? AND title LIKE ? 

        AND concat(keyword,cdate) LIKE ? AND content LIKE ?

        AND to_days(cdate) >= to_days(?) AND to_days(cdate) <= to_days(?)



        ORDER BY area,type,title,cdate DESC,id DESC

    	LIMIT $offset,20

__SQL__

     

                             }

        }   

        else

            {

            if ($title eq '' && $link == 1){  

        $result_ref = $dbh->selectall_arrayref(<<__SQL__,undef,"%$area%","%$type%","%#%","%$keyword%","%$text%");

        SELECT id,area,type,title,content,keyword,cdate

     	FROM Law 

    	WHERE area LIKE ? AND type LIKE ? AND title NOT LIKE ? 

        AND keyword LIKE ? AND content LIKE ?

        ORDER BY area,type,title

    	LIMIT $offset,20

__SQL__



                            }     	   

                            else{

          $result_ref = $dbh->selectall_arrayref(<<__SQL__,undef,"%$area%","%$type%","%$title%","%$keyword%","%$text%");

    	SELECT t1.id,t1.area,t1.type,t1.title,t1.content,t1.keyword,t1.cdate

        FROM Law AS t1 LEFT JOIN LawName AS t2 USING(area)

        WHERE t1.area LIKE ? AND t1.type LIKE ? AND t1.title LIKE ? 

        AND t1.keyword LIKE ? AND t1.content LIKE ?

        AND (t1.area = t2.area AND t1.type = t2.name)

        ORDER BY t1.area,t2.abbr,t1.type,t1.title

    	LIMIT $offset,20

__SQL__

                                }         

            }       

        

        if ($no_data == 1){  

        $result_ref = $dbh->selectall_arrayref(<<__SQL__,undef);   

select Law.id,Law.area,Law.type,Law.title,Law.content,Law.keyword,Law.cdate

        FROM Law LEFT JOIN BigArea ON Law.area=BigArea.name

        LEFT JOIN LawName ON Law.type=LawName.name

        WHERE

        BigArea.name is NULL

        OR LawName.name is NULL

        OR Law.cdate is NULL

        OR Law.cdate = ""

        ORDER BY Law.area,Law.type,Law.title

        LIMIT $offset,20

__SQL__

                 }   

           

    }





        

	#print "iown=$iown\n";

	

        my $content;



	my $id;

        my $searchLawResLine ="";

        my $file;

	if(defined($download))

            {

               $searchLawResLine = qq(<html><head>

                                  <title>信息查询结果</title>

                                  <meta http-equiv="Content-Type" content="text/html; charset=gb2312"></head><body bgcolor="#FFFFFF">

                                  <style type="text/css">

                                  <!--

                                   p,div {font-size:14px; line-height:18px; font-family:宋体;}

                                   small {font-size:12px; font-family:宋体;}

                                   a:visited {color:blue;}

                                   a:hover {color:red;}

                                  -->



                                  </style>

                                  <table width="100%" border="1" bgColor="#EEEEEE" bordercolor="#CCCCCC">);

	     }



	if(defined($download))

	{

		open(LAWFILE,">${filename}");

	}

	

 

	for (my $i=0; $i<scalar(@$result_ref); $i++)

        #for (my $i=0; $i<$resultSum; $i++)

    {

		my $arow = $result_ref->[$i];

		my ($res_id,$res_area,$res_type,$res_title,$res_content,$res_keyword,$res_cdate) = @$arow;

         

        my @councilkeyword = ('TS工时统计','案件开支统计','案件帐单统计','办公开支统计','帐单收入统计','财产管理统计');

        

            foreach(@councilkeyword)

      { 

  $res_keyword = $res_keyword.'/'.$res_cdate if($res_area eq $_);

      }

             $file = $dbh->selectrow_array(<<__SQL__,undef,"$res_id");
      
      select file
  
      FROM file

      WHERE law_id = ? 

__SQL__
             $file =~ s/^.*(\\|\/)//;

		if(defined($download))

		{

			$searchLawResLine .= $mt->process_file('in_downloadLaw', 

								{

									'num' => "$num",

                                                                        'area' => "$res_area",

									'type' => "$res_type",

									'title' => "$res_title",

									'content' => "$res_content",

									'keyword'=> "$res_keyword",

								});



		}
        	else
		{

			$searchLawResLine .= $mt->process_file('in_pmLawSearchResLine.htm', 

								{
									'num' => "$num",
									'id' => "$res_id",
									'area' => "$res_area",
									'type' => "$res_type",
									'title' => "$res_title",
									'content' => "$res_content",
									'keyword'=> "$res_keyword",
                                                                        'own'   => "$own",
                                                                        'file' => "$file",
								});

		}

		$num += 1;

    }

          

        #print $searchLawResLine;



    if(defined($download))

    {

    	$searchLawResLine .= qq(   <tr> 

                                   <th></th>

                                   <th></th>

                                   <th></th>

                                   <th></th>

                                   <th> 

                                    <div align="center">$time</div>

                                   </th>

                                   </tr>  

                                   </table>

                                  </body>

                                </html>);

        print LAWFILE $searchLawResLine;

    	close(LAWFILE);

    	

    	print $mt->process_file('in_pgDownload.htm');

    	

    	return;

    }

    

    my $downLink = ($downStart <= $resultSum && $resultSum > 20)?1:0;

       

         

    ###############################################

    #出现验证页面！

       $title  = '%23'.substr($title,1) if($Sum_Reg == 0 && $title =~ /#/); 

       $text   = '%23'.substr($text,1)  if($Sum_Reg == 0 && $text =~ /#/);      

       $type   = '%23'.substr($type,1)  if($Sum_Reg == 0 && $type =~ /#/);



       $link = 0 if($name eq "" && $password eq "");

       $link = 1 if($lawName ne "" && $name ne "" && $password ne "");

       $link = 2 if($lawName eq "" && $name ne "" && $password ne "");

               

             

       #$link = 1 if(($title eq "" && $lawName eq "") && $downLink == 1);

       

    

     

     

#if($iown eq $area && $Sum_Reg != 1 && ($link == 0 || $link ==2 ))

    if($iown eq $area  &&  $Sum_Reg != 1 &&  ($link == 0 && $lawName eq "") || (($link == 1 && ($lawName ne "" || $lawName eq "") && $name ne "" && $password ne "") || $link == 2 && $lawName ne ""))

    {  

          

              print $mt->process_file('in_pmLawReg.htm',

                               {

                                'area' => "$area",

                                'type' => "$type",

                                'title' => "$title",

                                'keyword' => "$keyword",

                                'own' => "$own",

                                'service_from_date' => "$service_from_date",

                                'service_to_date'   => "$service_to_date",

                                'lawnameline'       => "$lawName",

                                'link'              => "$link",

                                'name'              => "$name",

                                'password'          => "$password",

                                'Sum_Reg'           => "$link",

                                'text'              => "$text",

                               });                

          

             

     }

    else

    {

     print $mt->process_file('in_pgLawSearchRes.htm',

    					{

    						'start' => "$start",

    						'downlink' => "$downLink",

    						'upstart' => "$upStart",

    						'downstart' => "$downStart",

    						'resultsum' => "$resultSum",

                                                #'resultsum' => "$id",        						

    						'lawsearchresline' => "$searchLawResLine",

    						'area' => "$area",

    						'type' => "$type",

    						'title' => "$title",

    						'keyword' => "$keyword",

    						'text'     => "$text",

                                                'time'    => "$time",

    						'name'    => "$name",

    						'password'    => "$password",

                                                'service_from_date'    => "$service_from_date",

                                                'service_to_date'    => "$service_to_date",

                                                'Sum_Reg'              => "$Sum_Reg",

                                                'select'              => "$select",  

                                                'no_data'              => "$no_data", 

    					});

   } 

}









#No:6

sub showAddLawPage





{

	my $param = shift;



	

    my $dbh = $param->{'DBH'};

    my $mt = $param->{'METATEXT'};

    

    my $own = $param->{'own'};

    



	

	my $bigareaLine = selectBigarea($dbh,$mt,$own);

	my $lawnameLine = selectLawName($dbh,$mt,$own);

	

	print $mt->process_file('in_pgLawInput.htm',

    					{

    						'area' => "",

    						'type' => "",

    						'title' => "", 

    						'content' => "",

    						'keyword' => "",

    						'bigarealine' => $bigareaLine,

						'lawnameline' => $lawnameLine,

                                                'own'         => $own,

    					}); 

}







#No:7

sub haveThisLaw

{

	my $param = shift;



    my $dbh = $param->{'DBH'};

    my $mt = $param->{'METATEXT'};

 

	my $area = $param->{'area'};

	my $type = $param->{'type'};

	my $title = $param->{'title'};

        

        my $keyword = $param->{'keyword'};

      

         my @info = split /\//, $keyword;	

      

        my  ($haveIt) = $dbh->selectrow_array(

       "select count(*) FROM Law WHERE area = ? AND type =? AND title =? AND cdate = ?",

                undef,convert($area),convert($type),convert($title),convert($info[1]));

       

	

     

	return 0 if($haveIt == 0);

	

	return 1;

}



sub haveThisLaw_Law

{

	my $param = shift;



    my $dbh = $param->{'DBH'};

    my $mt = $param->{'METATEXT'};

 

	my $area = $param->{'area'};

	my $type = $param->{'type'};



	my $title = $param->{'title'};

        

        my $keyword = $param->{'keyword'};

 

        my ($haveIt) = $dbh->selectrow_array(

       "select count(*) FROM Law WHERE area = ? AND type =? AND title =? AND concat(keyword) = ?",

		undef,convert($area),convert($type),convert($title),convert($keyword));

  

         return 0 if($haveIt == 0);

	

	return 1;

}



#No:8

sub checkBigArea

{

	my ($dbh,$bigArea) = @_;

	

	my ($haveIt) = $dbh->selectrow_array("SELECT id FROM BigArea WHERE name = ?",undef,$bigArea);

	

	return 0 if(!defined($haveIt));



	

	return 1;

}









#No:9

sub checkLawName

{



	my ($dbh,$lawName,$bigArea) = @_;

	



	my ($haveIt) = $dbh->selectrow_array("SELECT id FROM LawName WHERE name = ? AND area = ?",undef,$lawName,$bigArea);



	

	return 0 if(!defined($haveIt));



	



	return 1;	

}



#No:10



sub checkLawkeyword

{

	my ($dbh,$keyword) = @_;

	

        return 1 if(!$keyword);



	return 0 if(!isValidDate($keyword));

       

	return 1;	

}





1;

