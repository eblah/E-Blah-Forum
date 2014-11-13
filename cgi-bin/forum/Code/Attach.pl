#############################################
# E-Blah Bulletin Board Systems        2008 #
#############################################
# Copyright (c) 2001 - 2008 E-Blah.         #
#############################################

CoreLoad('Attach',1);

sub Upload {
	if($FORM{'ulfile'} eq '') { return; }

	if($uallow == 0 && (!$avupload && $URL{'v'} ne 'memberpanel')) { error($atext[1]); }
	if($uallow == 2 && $username eq 'Guest') { error($atext[55]); }
	if($uallow == 3 && !$members{'Administrator',$username}) { error($atext[56]); }

	$fname = lc($FORM{'ulfile'});
	$fname =~ s/.+\\([^\\]+)$|.+\/([^\/]+)$/$1/;
	$fname =~ s/^.*(\\|\/\*)//;
	$fname =~ s/ /_/g;
	$fname =~ s/[#%+,\\\/:?"<>'|@^\$\&~'\)\(\]\[\;{}!`=-]//g;
	if($fname eq '.htaccess') { error($atext[5]); }

	$uploadz = new CGI;
	$file = $uploadz->param("ulfile");
	$tmpfile = $uploadz->tmpFileName($file);

	$fnchk = $fname;
	$fnchk =~ s/(.+?)[(.)]/$2/gsi;
	$fname =~ s/(.+?)\.//g;

	$fnchk =~ s/(pl|cgi|php|shtml|html|xml|php4|asp)/txt/g; # Banned internaly (script extentions cng to txt)

	$fname = "$1\_".int(rand(9999)).'.'.$fnchk;

	if($allowedext ne '') {
		@allowed = split(",",$allowedext);
		foreach(@allowed) {
			if($fnchk eq lc($_)) { $okay = 1; last; }
		}
		foreach(@allowed) { $aup .= "$_, "; }
		$aup =~ s/, \Z//i;
		if($okay != 1 && $FORM{'tempopen'} eq '') { clear_temp(); error("$atext[2] $aup"); }
		elsif($okay != 1) { $error = "$atext[2] $aup"; clear_temp(); return(); }
	}

	$savedfile = "$uploaddir/$fname";

	if(-e("$savedfile") && $FORM{'tempopen'} eq '') { clear_temp(); error($atext[3]); }
	elsif($addupload{$fname} && -e("$uploaddir/$fname")) { clear_temp(); return(); }
	elsif(-e("$savedfile")) { $error = $atext[3]; return(); }

	fopen(OUTFILE, ">$savedfile");
	binmode(OUTFILE);
	while($bytesread = read($file,$buffers,1024)) { print OUTFILE $buffers; }
	fclose(OUTFILE);

	$savedsize = -s($savedfile);
	if($savedsize == 0) {
		unlink($savedfile);
		if($FORM{'tempopen'} ne '') { $error = $atext[4]; clear_temp(); return(); } else { clear_temp(); error($atext[4]); }
	}
	$savedsize = sprintf("%.2f",($savedsize/1024/1024));
	if($maxsize != 0) {
		if($maxsize < $savedsize) {
			unlink("$savedfile");
			$over = $savedsize-$maxsize;
			if($FORM{'tempopen'} ne '') { $error = $atext[5]; clear_temp(); return(); } else { clear_temp(); error($atext[5]); }
		}
	}

	if($fname =~ /\.(jpg|jpeg|png|gif)\Z/ && $autoresize && $URL{'v'} eq 'post') { # Resize the image ...
		eval { # Parts are taken from the Image::Resize module
			require GD;

			GD::Image->trueColor( 1 );

			$gd = GD::Image->new($savedfile) or die;

			$gwidth  = ($gd->getBounds)[0];
			$gheight = ($gd->getBounds)[1];

			$tnwidth  = $tnwidth || 500;
			$tnheight = $tnheight || 500;

			if($gwidth > $tnwidth || $gheight > $tnheight) {
				my $k_h = $tnheight / $gheight;
				my $k_w = $tnwidth / $gwidth;
				my $k = $k_h < $k_w ? $k_h : $k_w;
				$height = int($gheight * $k);
				$width  = int($gwidth * $k);

				my $image = GD::Image->new($width, $height);
				$image->copyResampled($gd,0,0,0,0,$width,$height,$gwidth,$gheight);

				fopen(PIC,">$uploaddir/thumbnails/$fname");
				binmode(PIC);
				if($1 eq 'jpg' || $1 eq 'jpeg') { print PIC $image->jpeg(); }
				elsif($1 eq 'png') { print PIC $image->png(); }
				elsif($1 eq 'gif') { print PIC $image->gif(); }
				fclose(PIC);
			}
		};
	}

	$maxsize -= $savedsize;
	fopen(FILE,">$prefs/Hits/$fname.txt");
	print FILE "0";
	fclose(FILE);
	$atturl .= $fname;
	my $tttime = time;
	if($username eq 'Guest') { $temp1 = $ENV{'REMOTE_ADDR'}; } else { $temp1 = $username; }
	if($uextlog) { ++$ExtLog[4]; }

	unlink("$root/Blah.pl.core");
	clear_temp();

	if($URL{'v'} eq 'post') {
		fopen(TEMPFILE,">>$prefs/Hits/$FORM{'tempopen'}.temp");
		print TEMPFILE "$fname\n"; # This file has been uploaded
		fclose(TEMPFILE);

		fopen(FILE,"$prefs/Hits/totaltemps.temp"); # This is the global temp file, which keeps track of time of attachments and delete as ness
		while( <FILE> ) {
			chomp;
			($tempfopen,$tempdate) = split(/\|/,$_);
			if($tempfopen ne $FORM{'tempopen'}) { # After 3 hours, delete all temped attachments
				if($tempdate+10800 < time) {
					fopen(DELTEMPS,"$prefs/Hits/$tempfopen.temp");
					while( $open = <DELTEMPS> ) { chomp $open; unlink("$prefs/Hits/$open.txt","$uploaddir/$open"); }
					fclose(DELTEMPS);
					unlink("$prefs/Hits/$tempfopen.temp");
				} else { $tempsave .= "$_\n"; }
			}
		}
		fclose(FILE);
		$time = time;
		fopen(FILEZ,">$prefs/Hits/totaltemps.temp");
		print FILEZ $tempsave."$FORM{'tempopen'}|$time\n";
		fclose(FILEZ);
	}
}

sub clear_temp {
	if($filename) { close($filename); }

	if(-e($tmpfile)) { # Note: this only deletes the LAST temp file(s)
		@delete_temps = <CGItemp*>;
		foreach $delete_temps (@delete_temps){
			close($delete_temps);
			unlink("$root/$delete_temps");
		}
	}
}

sub Download {
	if($gattach && $username eq 'Guest') { error($gtxt{'noguest'}); }
	if($URL{'a'}) { AttachLog3(); }

	if(-e("$uploaddir/$URL{'f'}") == 0) { error($atext[6]); }
	fopen(ADD,"+<$prefs/Hits/$URL{'f'}.txt");
	$nump = <ADD> || 0;
	seek(ADD,0,0);
	truncate(ADD,0);
	print ADD $nump+1,"\n";
	fclose(ADD);

	if($uextlog) { ++$ExtLog[5]; ExtClose(); }

	$title = $atext[64];
	header();
	$ebout .= <<"EOT";
<meta http-equiv="refresh" content="1;url=$uploadurl/$URL{'f'}" />
<table class="border" cellspacing="1" cellpadding="4" width="400">
 <tr>
  <td class="titlebg"><strong><img src="$images/open_thread.gif" alt="" /> $title</strong></td>
 </tr><tr>
  <td class="win smalltext">$atext[61]</td>
 </tr><tr>
  <td class="win2 center"><br />$atext[62]<br /><br /><span class="smalltext"><a href="$uploadurl/$URL{'f'}">$atext[8]</a> $atext[63]</span><br /><br /></td>
 </tr>
</table>
EOT
	footer();
	exit;
}

sub AttachLog {
	is_admin(6.1);
	CoreLoad('Admin1',1); # Load language files
	CoreLoad('Admin2',1);

	if($URL{'p'} eq 'del2' || $URL{'p'} eq 'del1') { AttachLog2(); }
	elsif($URL{'p'} eq 'delete') { AttachLog4(); }
	elsif($URL{'p'} eq 'rebuild') { RebuildThumbnails(); }

	if($uploaddir) {
		opendir(DIR,"$uploaddir/");
		@dirlist = readdir(DIR);
		closedir(DIR);
		$counter = 0;
		foreach(@dirlist) {
			chomp;
			$fsize = (-s "$uploaddir/$_");
			if($fsize == 0) { next; }
			$size += $fsize;
			++$counter;
		}
		$size = sprintf("%.2f",$size/1024);
		$type = "KB";
		if($size > 1000) { $size = sprintf("%.2f",$size/1024); $type = "MB"; }

		opendir(DIR,"$uploaddir/thumbnails/");
		@dirlistt = readdir(DIR);
		closedir(DIR);
		$countert = 0;
		foreach(@dirlistt) {
			chomp;
			$fsizet = (-s "$uploaddir/thumbnails/$_");
			if($fsizet == 0) { next; }
			$sizet += $fsizet;
			++$countert;
		}
		$sizet = sprintf("%.2f",$sizet/1024);
		$typet = "KB";
		if($sizet > 1000) { $sizet = sprintf("%.2f",$sizet/1024); $typet = "MB"; }
	}

	$title = $admintxt[69];
	headerA();
	$ebout .= <<"EOT";
<table class="border" cellpadding="5" cellspacing="1" width="600">
 <tr>
  <td class="titlebg"><strong>$title</strong></td>
 </tr><tr>
  <td class="win smalltext">$admintxt[97]</td>
 </tr><tr>
  <td class="catbg"><strong>$admintxt[98]</strong></td>
 </tr><tr>
  <td class="win2">
   <table cellpadding="3" width="100%">
    <tr>
     <td class="right" style="width: 40%"><strong>$admintxt[99]:</strong></td>
     <td style="width: 60%">$counter</td>
    </tr><tr>
     <td class="right" style="width: 40%"><strong>$admintxt[100]:</strong></td>
     <td style="width: 60%">$size $type</td>
    </tr><tr>
     <td class="right" style="width: 40%"><strong>$atext[66]:</strong></td>
     <td style="width: 60%">$countert</td>
    </tr><tr>
     <td class="right" style="width: 40%"><strong>$atext[67]:</strong></td>
     <td style="width: 60%">$sizet $typet</td>
    </tr>
   </table>
  </td>
 </tr><tr>
  <td class="catbg"><strong>$admintxt[101]</strong></td>
 </tr><tr>
  <td class="win">
   <table cellpadding="2" width="100%">
    <tr>
     <td><form action="$surl\lv-admin/a-attlog/p-delete/" method="post">$admintxt[104] <input type="text" name="days" value="60" maxlength="3" size="6" /> $admintxt[102]. <input type="submit" name="submit" value="$admintxt[106]" /></form></td>
    </tr><tr>
     <td><form action="$surl\lv-admin/a-attlog/p-delete/" method="post">$admintxt[105] <input type="text" name="kb" value="1024" maxlength="6" size="6" /> KBs. <input type="submit" name="submit" value="$admintxt[106]" /></form></td>
    </tr>
   </table>
  </td>
 </tr><tr>
  <td class="win2 center"><br /><strong><a href="$surl\lv-download/a-1/"$blanktarget>$admintxt[103]</a><br /><br /><a href="$surl\lv-admin/a-attlog/p-rebuild/">$atext[65]</a><br /><br /></strong></td>
 </tr>
</table>
EOT
	footerA();
	exit;
}

sub AttachLog3 {
	CoreLoad('Admin1',1); # Load language files
	CoreLoad('Admin2',1);
	$title = $admintxt[107];

	if(!$URL{'a'}) { headerA(); } else { header(); }
	$ebout .= <<"EOT";
<script type="text/javascript">
//<![CDATA[
function clear(url) {
 if(window.confirm("$admintxt[108]")) { location = url; }
}
//]]>
</script>
<table cellpadding="5" cellspacing="1" class="border" width="98%">
 <tr>
  <td class="titlebg"><strong>$title</strong></td>
 </tr>
EOT
	if($uploaddir) { # Open Uploads DIR
		if($URL{'search'}) { $FORM{'search'} = $URL{'search'}; }
		opendir(DIR,"$uploaddir/");
		while( $list = readdir(DIR) ) {
			if(!$members{'Administrator',$username} && $list !~ /(jpg|jpeg|gif|art|bmp|png)\Z/) { next; }
			if($list ne '.' && $list ne '..' && $list ne '.htaccess' && ($list =~ /\Q$FORM{'search'}\E/)) { push(@dirlist,$list); }
		}
		closedir(DIR);

		# Get Pages
		$mupp = 40;
		$maxuploads = @dirlist || 1;
		if($maxuploads < $mupp) { $URL{'s'} = 0; }
		$tstart = $URL{'s'} || 0;
		$counter = 1;
		$link = "$surl\lv-download/a-1/search-$FORM{'search'}/s";
		if($tstart > $maxuploads) { $tstart = $maxuploads; }
		$tstart = (int($tstart/$mupp)*$mupp);
		if($tstart > 0) { $bk = ($tstart-$mupp); $pagelinks = qq~<a href="$link-$bk/">&#171;</a> ~; }
		for($i = 0; $i < $maxuploads; $i += $mupp) {
			if($i == $tstart || $maxuploads < $mupp) { $pagelinks .= qq~<strong>$counter</strong>, ~; $nxt = ($tstart+$mupp); }
				else { $pagelinks .= qq~<a href="$link-$i/">$counter</a>, ~; }
			++$counter;
		}
		$pagelinks =~ s/, \Z//gsi;
		if(($tstart+$mupp) != $i) { $pagelinks .= qq~ <a href="$link-$nxt/">&#187;</a>~; }
		$end = ($tstart+$mupp);
		$tstart2 = $tstart ? $tstart : 1;
		$pagelinks .= " ($var{'92'} $tstart2-$end $var{'93'} ".@dirlist." $admintxt2[218])";

		$counter = 0;

		for($i = 0; $i < @dirlist; $i++) {
			if($i < $tstart || $i+1 > $end) { next; }

			if($counter == 0) { $ebout .= qq~<tr><td class="win2"><table width="100%">~; }
			++$counter;

			if($dirlist[$i] =~ /(jpg|jpeg|gif|art|bmp|png)/) {
				if(-e("$uploaddir/thumbnails/$dirlist[$i]")) { $t = "/thumbnails"; } else { $t = ''; }
				$picture = qq~<a href="$uploadurl/$dirlist[$i]"><img src="$uploadurl$t/$dirlist[$i]" style="height: 50; max-height: 50; min-height:1; min-width:1; max-width:80;" alt="" /></a>~;
			}
				else { $picture = qq~<img src="$images/disk.png" alt="" />~; }

			$size = (-s"$uploaddir/$dirlist[$i]");
			if($size == 0) { next; }
			$color = $colors[$counter % 2];
			$size = sprintf("%.2f",$size/1024);
			$type = "KB";
			if($size > 1000) { $size = sprintf("%.2f",$size/1024); $type = "MB"; }
			$fdate = (stat("$uploaddir/$dirlist[$i]"))[9];
			$fdate = get_date($fdate);

			fopen(FILE,"$prefs/Hits/$dirlist[$i].txt");
			@nump = <FILE>;
			fclose(FILE);
			chomp @nump;
			$downloads = $nump[0] || 0;

			if($members{'Administrator',$username}) { $admindelete = qq~ &nbsp; <a href="javascript:clear('$surl\lv-admin/a-attlog/p-del1/f-$dirlist[$i]/s=$URL{'s'}/')"><img src="$images/ban.png" alt="" /></a>~; }

			$ebout .= <<"EOT";
 <td style="width: 50%"><table width="100%"><tr><td colspan="2"><strong>$admintxt[189]:</strong> <a href="$surl\lv-download/d-1/f-$dirlist[$i]/"$blanktarget>$dirlist[$i]</a>$admindelete</td></tr><tr><td style="width: 75px; padding: 4px;" class="win center">$picture</td><td class="vtop"><strong>$admintxt2[213]:</strong> $fdate<br /><strong>$admintxt[111]:</strong> $size $type<br /><strong>$gtxt{'14'}:</strong> $downloads</td></tr></table></td>
EOT
			if($counter == 2) {
				$ebout .= qq~</table></td></tr>~;
				$counter = 0;
			}
		}
		if($counter != 0) { $ebout .= qq~</table></td></tr>~;  }
	} else {
		$ebout .= qq~<tr><td class="win">$admintxt[116]</td></tr></table>~;
		if(!$URL{'a'}) { footerA(); } else { footer(); }
		exit;
	}

	$ebout .= <<"EOT";
 <tr>
  <td class="win">$pagelinks</td>
 </tr><tr>
  <td class="win2 smalltext"><form action="$surl\lv-download/a-1/" method="post" enctype="multipart/form-data"><strong>$atext[59]:</strong> <input type="text" name="search" value="$FORM{'search'}" size="30" /> <input type="submit" value="$atext[59]" /><br />$atext[60]</form></td>
 </tr>
</table>
EOT
	if(!$URL{'a'}) { footerA(); } else { footer(); }
	exit;
}

sub RebuildThumbnails {
	opendir(DIR,"$uploaddir/");
	@dirlist = readdir(DIR);
	closedir(DIR);

	opendir(DIR,"$uploaddir/thumbnails/");
	@dirlistt = readdir(DIR);
	closedir(DIR);

	foreach(@dirlistt) { unlink("$uploaddir/thumbnails/$_"); }

	foreach $fname (@dirlist) {
		if($fname =~ /\.(jpg|jpeg|png|gif)\Z/ && $autoresize) { # Resize the image ...
			eval { # Parts are taken from the Image::Resize module
				require GD;

				GD::Image->trueColor( 1 );

				$gd = GD::Image->new("$uploaddir/$fname") or die;

				$gwidth  = ($gd->getBounds)[0];
				$gheight = ($gd->getBounds)[1];

				$tnwidth  = $tnwidth || 500;
				$tnheight = $tnheight || 500;

				if($gwidth > $tnwidth || $gheight > $tnheight) {
					my $k_h = $tnheight / $gheight;
					my $k_w = $tnwidth / $gwidth;
					my $k = $k_h < $k_w ? $k_h : $k_w;
					$height = int($gheight * $k);
					$width  = int($gwidth * $k);

					my $image = GD::Image->new($width, $height);
					$image->copyResampled($gd,0,0,0,0,$width,$height,$gwidth,$gheight);

					fopen(PIC,">$uploaddir/thumbnails/$fname");
					binmode(PIC);
					if($1 eq 'jpg' || $1 eq 'jpeg') { print PIC $image->jpeg(); }
					elsif($1 eq 'png') { print PIC $image->png(); }
					elsif($1 eq 'gif') { print PIC $image->gif(); }
					fclose(PIC);
				}
			};
		}
	}
	redirect("$surl\lv-admin/a-attlog/");
}

sub AttachLog4 {
	is_admin(6.1);
	opendir(DIR,"$uploaddir/");
	@dirlist = readdir(DIR);
	closedir(DIR);
	$counter = 0;
	if($FORM{'days'}) {
		$maxdays = ($FORM{'days'}*86400);
		$great = time-$maxdays;
	}
	$deleted = 0;
	foreach(@dirlist) {
		chomp;
		if($_ eq '.' || $_ eq '..') { next; }
		$fsize = sprintf("%.2f",((-s "$uploaddir/$_"))/1024);
		$fdate = (stat("$uploaddir/$_"))[9];
		if($FORM{'days'} && $fdate < $great) {
			++$deleted;
			push(@remove,$_);
		}
		if($FORM{'kb'} && $FORM{'kb'} < $fsize) {
			++$deleted;
			push(@remove,$_);
		}
		if($fsize == 0) { next; }
		$size = $size+$fsize;
		++$counter;
	}

	foreach(@remove) { unlink("$uploaddir/$_","$uploaddir/thumbnails/$_","$prefs/Hits/$_.txt"); }
	return;
}

sub AttachLog2 {
	if(!$modifyon) { is_admin(6.1); }
	unlink("$uploaddir/$URL{'f'}","$uploaddir/thumbnails/$URL{'f'}","$prefs/Hits/$URL{'f'}.txt");
	if($URL{'m'} eq '') { $url = "$surl\lv-download/a-1/s-$URL{'s'}/"; } else { $url = "$surl\lm-$URL{'m'}/s-$URL{'s'}/"; }
	redirect();
}
1;
