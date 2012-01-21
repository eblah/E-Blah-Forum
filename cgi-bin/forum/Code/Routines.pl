#############################################
# E-Blah Bulletin Board Systems        2008 #
#############################################
# Copyright (c) 2001 - 2008 E-Blah.         #
#############################################
# Part of the E-Blah Core                   #
#############################################

require("$language/Routines.lng");

{	# Let's work out the dateformat now ...
	if($datedisv2 eq '') { $datedisv2 = 'F j, Y, g:ia'; }
	if($memberid{$username}{'dateformat'} eq '' && $memberid{$username}{'timeformat'} eq '') { $memberid{$username}{'dateformat'} = $datedisv2; }

	$datedisplayH{0} = 'F j, Y, ';
	$datedisplayH{1} = 'l, F j, Y, ';
	$datedisplayH{2} = 'd F Y, ';
	$datedisplayH{3} = 'm.d.Y, ';
	$datedisplayH{4} = 'd/m/Y, ';
	$datedisplayH{5} = 'Y/m/d, ';

	$timedisplayH{0} = 'g:ia';
	$timedisplayH{1} = 'g:i:sa';
	$timedisplayH{2} = 'H:i';
	$timedisplayH{3} = 'H:i:s';

	if($datedisplayH{$memberid{$username}{'dateformat'}} ne '') { $DateDisplay = $datedisplayH{$memberid{$username}{'dateformat'}}; }
		else { $DateDisplay = $memberid{$username}{'dateformat'}; $memberid{$username}{'timeformat'} = ''; }
	$DateDisplay = "$DateDisplay$timedisplayH{$memberid{$username}{'timeformat'}}";

	# DO NOT REMOVE OR EDIT THE FOLLOWING LINE (unless licensed) ...
	$copyright = qq~Powered by <a href="http://www.eblah.com"$blanktarget>E-Blah Forum Software</a> $versioncr &#169; 2001-2008~;

	# <> - makes it not open .dat files (v10+ should be no issue anyway)
	%botsearch = (
		'mediapartners-google<>' => 'AdSense',
		'googlebot<>'            => 'Googlebot',
		'slurp<>'                => 'Yahoo! Bot',
		'msnbot<>'               => 'Bing Bot',
		'inktomi<>'              => 'Hot Bot',
		'ask jeeves<>'           => 'Ask.com',
		'lycos<>'                => 'Lycos',
		'ia_archiver<>'          => 'Alexa',
		'baiduspider<>'          => 'Baidu Spider',
		'gigabot<>'              => 'Gigabot',
		'googlebot-image<>'      => 'Googlebot-Image',
		'scooter<>'              => 'AltaVista',
		'infoseek<>'             => 'InfoSeek.com',
		'mantraagent<>'          => 'LookSmart.com',
		'voilabot<>'             => 'Voila.fr'
	);

	if($username eq 'Guest') { $memberid{$username}{'timezone'} = $gtzone; }

	$date_time = get_date(time,1);

	my $oldtime = time-86400;
	($t,$t,$t,$Yday,$Ymonth,$Yyear) = gmtime($oldtime+(3600*($memberid{$username}{'timezone'}+$memberid{$username}{'dst'}+$gtoff)));
	($t,$t,$Khour,$Kday,$Kmonth,$Kyear) = gmtime(time+(3600*($memberid{$username}{'timezone'}+$memberid{$username}{'dst'}+$gtoff)));
	$Kyear += 1900;
	$Yyear += 1900;

	if($URL{'v'} eq 'checktime') { CheckTime(); }
}

sub header {
	my($sfoot,$Ecopyright,$sep,$newpms,$header);
	return if($hdone); # Headers have already been completed

	if($ENV{'HTTP_ACCEPT_ENCODING'} !~ /gzip/ && $gzipen) { $gzipen = 0; } # Browser doesn't support gzip

	print "Content-Encoding: gzip\n" if($gzipen);

	if($xhtmlct && $ENV{'HTTP_ACCEPT'} =~ /application\/xhtml\+xml/) {
		print "Content-type: application/xhtml+xml; charset=$char\n\n";
	} else {
		print "Content-type: text/html; charset=$char\n\n";
	}

	$hdone = 1;

	# Time of day ...
	if($Khour > 11 && $Khour < 17)  { $wmessage = $rtxt[46]; } # Afternoon
	elsif($Khour <= 12 && $Khour > 2) { $wmessage = $rtxt[45]; } # Morning
		else { $wmessage = $rtxt[47]; } # Evening

	if($username eq 'Guest') {
		$userwelcome = $displayuser = qq~$rtxt[1], <strong>$rtxt[2]</strong>.~;
		$displayuser .= $userpm = qq~$rtxt[3] <a href="$surl\lv-login/" rel="nofollow">$rtxt[4]</a> $rtxt[44] <a href="$surl\lv-register/" rel="nofollow">$rtxt[5]</a>.~; ShowGuest();
	} elsif($lockuserout) {
		$userwelcome = $displayuser = qq~$rtxt[1] $rtxt[9] <strong>$username</strong>.~;
		$displayuser .= $userpm = $rtxt[7];
		$memberid{$username}{'md5upgrade'} = 1;
	} else {
		if(!$pmdisable) {
			if($pmmaxquota && $pmmaxquota-((-s"$members/$username.pm")/1024) < 0) { $userpm = qq~<strong><img src="$images/warning_sm.png" class="centerimg" alt="" /> $rtxt[67] <img src="$images/warning_sm.png" class="centerimg" alt="" /></strong>~; }
				else {
					$memberid{$username}{'pmnew'} = $memberid{$username}{'pmnew'} || 0;
					$memberid{$username}{'pmcnt'} = $memberid{$username}{'pmcnt'} || 0;
					$newpms = qq~ (<strong>$memberid{$username}{'pmnew'} $rtxt[11]</strong>)~ if($memberid{$username}{'pmnew'} > 0);
					$displayuser .= $userpm = qq~ $rtxt[10] <strong>$memberid{$username}{'pmcnt'}</strong>$newpms <a href="$surl\lv-memberpanel/a-pm/" title="$rtxt[12]">$rtxt[13]</a>.~;
				}
		} else { $displayuser .= $userpm = " $rtxt[54]"; }

		$userwelcome = $displayuser = "$wmessage <strong>$memberid{$username}{'sn'}</strong>.";

		if(($members{'Administrator',$username} || @myacl) && ($maintance || $lockout)) {
			if($maintance) { $on = $rtxt[14]; }
			if($maintance && $lockout) { $on .= $rtxt[15]; }
			if($lockout) { $on .= $rtxt[16]; }
			$displayuser = $userpm .= qq~<br /><strong><img src="$images/warning_sm.png" alt="" /> $rtxt[17] $on <img src="$images/warning_sm.png" alt="" /></strong>~;
		}
	}

	if($helpdesk) { $help = qq~<a href="$helpdesk" onclick="target='_new';">$Mimg{'help'}</a>~; $sep = $Mmsp2; }

	$homemenu = qq~<a href="$surl">$Mimg{'home'}</a>~;
	$calmenu = qq~<a href="$surl\lv-cal/" rel="nofollow">$Mimg{'cal'}</a>~;
	$searchmenu = qq~<a href="$surl\lv-search/~; $searchmenu .= "b-$URL{'b'}/" if($URL{'b'}); $searchmenu .= qq~">$Mimg{'search'}</a>~;

	$menubar = '<div class="menubar">'.$homemenu.$sep.$help.$Mmsp2.$calmenu.$Mmsp2.$searchmenu.$Mmsp2;

	if($members{'Administrator',$username} || @myacl) {
		$adminmenu = qq~<a href="$surl\lv-admin/">$Mimg{'admin'}</a>~;
		$menubar .= $adminmenu.$Mmsp2;
	}

	if($username ne 'Guest') {
		$profilemenu = qq~<a href="$surl\lv-memberpanel/">$Mimg{'profile'}</a>~;
		$loginmenu   = qq~<a href="$surl\lv-login/p-3/" rel="nofollow" onclick="if(window.confirm('$rtxt[65]')) { location = '$surl\lv-login/p-3/'; } return false;">$Mimg{'logout'}</a>~;
		$menubar    .= $profilemenu.$Mmsp2;
	} else {
		$registermenu = qq~<a href="$surl\lv-register/" rel="nofollow">$Mimg{'register'}</a>~;
		$loginmenu    = qq~<a href="$surl\lv-login/" rel="nofollow">$Mimg{'login'}</a>~;
		$menubar     .= $registermenu.$Mmsp2;
	}
	$menubar .= $loginmenu.'</div>';
	
	$lastvisit = get_date($memberid{$username}{'lastvisit'},1);

	# Get the template
	$footer = '';

	fopen(TEMP,"$templates/$dtheme/template.html") or $ebout .= '<strong>Theme not found!</strong><br /><br />';
	while(<TEMP>) {
		$_ =~ s/<blah v="\$(.+?)">/${$1}/gsi;
		if($_ =~ /eblah.com/) { $Ecopyright = 1; }

		if($advancedhtml) {
			if($_ =~ /<\?(.*?)(\Z|\?>)/) {
				$eval = $1;
				if($2 eq '?>') { $keepevaling = 0; eval $eval; } else { $keepevaling = 1; }
				next;
			}
			if($keepevaling && $_ =~ /(.*?)(\Z|\?>)/) {
				$eval .= $1;
				if($2 eq '?>') {
					$keepevaling = 0;
					eval $eval;
					$ebout .= qq~$@~ if($@ ne '');
					$eval = '';
				}
				next;
			}
		}

		if($_ =~ /(.*?)<blah main>(.*?)\Z/) { $sfoot = 1; $header .= $1; $footer .= $2; next; }
		if(!$sfoot) { $header .= $_; } else { $footer .= $_; }
	}
	fclose(TEMP);
	if($dtheme eq '') { $Ecopyright = 1; }

	$ebout .= $header;

	if(!$Ecopyright && $URL{'v'} ne 'admin') { $footer = "$copyright<br />$footer"; }

	# Guest?
	$ebout .= $guestlogin if(!$gdisable && $username eq 'Guest');

	$ebout .= $URL{'v'} ne 'memberpanel' && $memberid{$username}{'pmpopup'} && $memberid{$username}{'pmnew'} > 0 ? qq~<script type="text/javascript">//<![CDATA[\nif(window.confirm("$rtxt[59] $memberid{$username}{'pmnew'} $rtxt[58]")) { location = "$surl\lv-memberpanel/a-pm/"; }\n//]]></script>~ : '';

	if($md5upgrade && !$memberid{$username}{'md5upgrade'} && $username ne 'Guest') { CoreLoad('Login'); ChangePass(); }

	if($lockuserout ne '') { CoreLoad('BoardLock'); UserLockOut(); }
}

sub footer {
	ExtClose() if($uextlog);

	if($memberid{$username}{'sn'} ne '' && $logactive) {
		($totaltime,$lasttime) = split(/\|/,$memberid{$username}{'rndsid'});
		if($keepon && $lasttime) { $totaltime += (time-$lasttime); }

		%addtoID = (
			'lastactive' => time,
			'rndsid'     => "$totaltime|".time
		);
		if(time > $memberid{$username}{'lastactive'}+1800) { $addtoID{'lastvisit'} = $memberid{$username}{'lastactive'}; }

		SaveMemberID($username);
	}

	if($debug && $members{'Administrator',$username}) { # Debug, remove in finals
		if($start_debug) { $time_running = sprintf("%.4f",Time::HiRes::time() - $start_debug); }
		$gzipend = $gzipen ? 'Enabled' : 'Disabled';

		if($^O eq 'linux') {
			$uptime = `uptime`;
			($t,$la) = split("load average:",$uptime);
			($five) = split(", ",$la);
		}

		$ebout .= qq~<div style="text-align: center"><br /><img src="$images/clock.png" class="centerimg" alt="" /> $time_running seconds &nbsp; <img src="$images/files.png" class="centerimg" alt="" /> $openedfiles opened &nbsp; <img src="$images/gzip.png" class="centerimg" alt="" /> $gzipend &nbsp; <img src="$images/cpu.png" class="centerimg" alt="" /> $five</div><!--\n$openedfilenames-->~;
		if($debug == 2 || $debug == 4) { sleep(5); }
	}

	$ebout .= $footer;

	if($gzipen) {
		if($gzipen == 2) {
			open(GZIP,"| gzip -f");
			print GZIP $ebout;
			close(GZIP);
		} else {
			require Compress::Zlib;
			binmode STDOUT;
			print Compress::Zlib::memGzip($ebout);
		}
	} else { print $ebout; }
}

sub AL {
	my($buser,$luser,$ltime,@maxlog,$totactive);

	if($username eq 'Guest') {
		if($ENV{'HTTP_USER_AGENT'} =~ /(voilabot|mantraagent|infoseek|mediapartners-google|googlebot|inktomi|ask jeeves|lycos|ia_archiver|slurp|msnbot|baiduspider|gigabot|googlebot-image|scooter)/i) { $buser = lc($1).'<>'; }
			else { $buser = $ENV{'REMOTE_ADDR'}; }
	} else { $buser = $username; }

	fopen(ACTIVE,"+<$prefs/Active.txt");
	while( <ACTIVE> ) {
		chomp;
		($luser,$ltime) = split(/\|/,$_);
		if(time-$ltime < (60*$activeuserslog)) {
			push(@activeusers,"$_") if(lc($luser) ne lc($buser));
			$keepon = 1 if(lc($luser) eq lc($buser));
			$activemembers{$luser} = 1; # Keep user in memory for checking online status quickly
		}
		++$totactive;
	}

	# Check server load ...
	if($serload && !$keepon && $totactive > $serload && !$members{'Administrator',$username}) {
		fclose(ACTIVE);
		return() if $URL{'v'} eq 'login';
		error($rtxt[55]);
	} else {
		push(@activeusers,"$buser|".time."|$URL{'v'}|$URL{'b'}|$URL{'m'}");
	}

	seek(ACTIVE,0,0);
	truncate(ACTIVE,0);
	foreach(@activeusers) { print ACTIVE "$_\n"; }
	fclose(ACTIVE);

	fopen(MAXLOG,"$prefs/MaxLog.txt");
	@maxlog = <MAXLOG>;
	fclose(MAXLOG);
	chomp @maxlog;
	if($maxlog[0] < $totactive) {
		fopen(MAXLOG,">$prefs/MaxLog.txt");
		print MAXLOG "$totactive\n".time;
		fclose(MAXLOG);
	}

	if($uextlog) { $ExtLog[7] = $totactive; }
}

sub error {
	$gdisable = 1;

	my($ecode,$elog,$notfound) = @_;
	my($ttime,$etype,$icon);
	if($ecode eq 'OPEN_ERROR'){ $ecode = $rtxt[56]; }
	$error = BC(Format($ecode));
	if($error =~ /-admin-/ || $error =~ /-register-/) { SpecialErrors(); }
	$icon = 'ban';
	if($elog && $elog < 3) {
		if($elog == 2) { $rtxt[18] = $rtxt[51]; $rtxt[19] = "<strong>$rtxt[51] $rtxt[41]:</strong> $rtxt[53]"; }
		$ewhat = "$rtxt[18] ";

		$esig = <<"EOT";
<tr>
 <td class="vtop center" style="width: 30px"><img src="$images/forbidden.png" alt="" /></td>
 <td>$rtxt[66]</td>
</tr>
EOT

		if($kelog) {
			chomp $!; chomp $error; chomp $errorurl;
			$errorurl = "Blah.pl?$ENV{'QUERY_STRING'}";
			$ttime = time;
			$specify = $! || '?';
			fopen(ELOG,"+>>$prefs/ELog.txt");
			print ELOG "$error|$specify|$ttime|$username|$errorurl\n";
			fclose(ELOG);
		}
	}
	$ewhat .= $rtxt[41];
	if($elog == 3) {
		$ewhat = $boardlock[33];
	}
	$error =~ s/$code|$messages|$members|$prefs|$boards/./gsi;  # Security: Change full paths to local
	$error =~ s/\$rights/&lt;blah v="\$copyright"&gt;/g;
	if($root ne '.') { $error =~ s/$root/./gsi; }
	$title = $ewhat;
	$date_time = get_date(time,1);

	if($plinks ne '') {
		$plinks = <<"EOT";
<tr>
 <td class="catbg">$rtxt[32]</td>
</tr><tr>
 <td class="win links">$plinks</td>
</tr>
EOT
	}

	if($adminsloaded) { headerA(); } else { header(); }
	$ebout .= <<"EOT";
<table class="border" cellpadding="5" cellspacing="1" width="100%">
 <tr>
  <td class="titlebg">$title</td>
 </tr><tr>
  <td class="win3" style="padding: 10px">Sorry, but an error occurred. If you are unsure about how to solve this error you can contact the system administrator.</td>
 </tr><tr>
  <td class="win">
   <table cellpadding="5" cellspacing="0" width="100%">
    <tr>
     <td class="vtop center" style="width: 30px"><img src="$images/error.png" alt="" /></td>
     <td>$error</td>
    </tr>$esig
   </table>
  </td>
 </tr>$qlogin$plinks<tr>
  <td class="win2 smalltext right" style="padding: 8px;"><a href="mailto:$eadmin">$rtxt[50]</a></td>
 </tr>
</table>
EOT
	if($adminsloaded) { footerA(); } else { footer(); }
	exit;
}

sub redirect {
	($url2,$noexit) = $_[0];

	if($url eq '') { $url = $surl; }
	if($url2) { $url = $url2; }
	if($redirectfix == 1) { print qq~Content-type: text/html\n\n<html><head><meta http-equiv="refresh" content="0;URL=$url"></head></html>~; } 
	elsif($redirectfix == 2) { print "Refresh: 0;url=$url\n\n"; }
		else { print "Location: $url\n\n"; }
	if(!$noexit) { exit; }
}

sub get_date {
	my($date,$unbld,$personalized,$hourcnt) = @_;
	my($tdate);

	$date = time if($date eq '');

	if($personalized) { ($sec,$min,$hour,$day,$month,$year,$week,$ydays,$dst) = localtime($date); }
		else {
			if($date+10800 > time && !$unbld && $btod) {
				$tdate = int((time-$date)/60);
				if($tdate == 0) { return($rtxt[64]); }
				elsif($tdate == 1) { return($rtxt[63]); }
				elsif($tdate < 60 && $tdate > 0) { return("$tdate $rtxt[62]"); }
				elsif($tdate > 60 && $tdate < 120) { return($rtxt[68]); }
				elsif($tdate > 120 && $tdate < 360) { return(ceil($tdate/60)." $rtxt[69]"); }
			}

			($sec,$min,$hour,$day,$month,$year,$week,$ydays,$dst) = gmtime($date+(3600*($memberid{$username}{'timezone'}+$memberid{$username}{'dst'}+$gtoff)));
		}

	$curmonth = $month;
	$ampm = 'am';
	$year = 1900 + $year;
	if($min < 10) { $min = "0$min"; }
	if($hour == 12) { $ampm = 'pm'; }
	if($hour == 0) { $hour = 12; }
	if($hour > 12) {
		$hour -= 12;
		$ampm = 'pm';
	}
	if($sec < 10) { $sec = "0$sec"; }

	date_dis();

	if(!$unbld) { return($ddis); }
		else {
			$ddis =~ s/\<(.*?)\>//sg;
			return($ddis);
		}
}

sub date_dis {
	my($blocknext,$REP);
	if($notime_date) { $ddis = "$months[$month] $day, $year"; $notime_date = ''; return(); }

	$ddis = '';
	for($REP = 0; $REP < length($DateDisplay); ++$REP) {
		$temp = substr($DateDisplay, $REP, 1);
		if($temp eq '\\') { $blocknext = 1; next; }
		if(!$blocknext) { $temp = TimeVariables($temp); }
		$ddis .= "$temp";
		$blocknext = 0;
	}
}

sub TimeVariables {
	my($tztemp);

	if($_[0] eq 'l') { return($days[$week]); }
	elsif($_[0] eq 'j') { return($day); }
	elsif($_[0] eq 'S') {
		if($day < 20 && $day > 10) { return('th'); }
		elsif($day % 10 == 1) { return('st'); }
		elsif($day % 10 == 2) { return('nd'); }
		elsif($day % 10 == 3) { return('rd'); }
			else { return('th'); }
	} elsif($_[0] eq 'E') {
		if($day < 20 && $day > 10) { return('<sup>th</sup>'); }
		elsif($day % 10 == 1) { return('<sup>st</sup>'); }
		elsif($day % 10 == 2) { return('<sup>nd</sup>'); }
		elsif($day % 10 == 3) { return('<sup>rd</sup>'); }
			else { return('<sup>th</sup>'); }
	} elsif($_[0] eq 'D') { return($sdays[$week]); }
	elsif($_[0] eq 'd') {
		if($day < 10) { return("0$day"); } else { return($day); }
	} elsif($_[0] eq 'w') { return($week); }
	elsif($_[0] eq 'N') { return($week+1); }
	elsif($_[0] eq 'z') { return($ydays); }
	elsif($_[0] eq 'F') { return($months[$month]); }
	elsif($_[0] eq 'm') {
		if($month < 9) { return("0".($month+1)); } else { return($month+1); }
	}
	elsif($_[0] eq 'M') { return($smonths[$month]); }
	elsif($_[0] eq 'n') { return($month+1); }
	elsif($_[0] eq 'Y') { return($year); }
	elsif($_[0] eq 'y') { return(substr($year, 2)); }
	elsif($_[0] eq 'a') { return($ampm); }
	elsif($_[0] eq 'A') { return(uc($ampm)); }
	elsif($_[0] eq 'g') { return($hour); }
	elsif($_[0] eq 'G') {
		if($ampm eq 'pm' && $hour != 12) { return($hour+12); }
		elsif($hour == 12 && $ampm eq 'am') { return('0'); }
			else { return($hour); }
	}
	elsif($_[0] eq 'h') {
		if($hour < 10) { return("0$hour"); } else { return($hour); }
	}
	elsif($_[0] eq 'H') {
		if($ampm eq 'pm' && $hour != 12) { return($hour+12); }
		elsif($hour == 12 && $ampm eq 'am') { return('00'); }
			else {
				if($hour < 10) { return("0$hour"); } else { return($hour); }
			}
	}
	elsif($_[0] eq 'i') { return($min); }
	elsif($_[0] eq 's') { return($sec); }
		else { return($temp); }
}

sub ClickLog {
	my($clt,$lgtm,$rawprint);
	if($uextlog) { ++$ExtLog[0]; }

	return() if !$eclick;

	$ref = $ENV{'HTTP_REFERER'} =~ /$rurl/ ? '' : $ENV{'HTTP_REFERER'};
	$ref = Format($ref);

	$clt = time-($logcnt*60);

	fopen(RAWLOG,"+<$prefs/ClickLog.txt");
	while(<RAWLOG>) {
		chomp;
		($lgtm) = split(/\|/,$_);
		$lgtm -= $clt;
		if($lgtm > 0 && $LoggedClicks < 7500) { $rawprint .= "$_\n"; ++$LoggedClicks; } else { last; }
	}
	seek(RAWLOG,0,0);
	truncate(RAWLOG,0);
	print RAWLOG time."|$ENV{'REMOTE_ADDR'}|$ref|$ENV{'QUERY_STRING'}|$ENV{'HTTP_USER_AGENT'}\n$rawprint";
	fclose(RAWLOG);
}

sub BCSmileys {
	my($tempsmile) = $_[0];

	my($smilecnt,$temper);
	if($simages2 ne '') { $temper = $simages; $simages = $simages2; }
	while($smilecnt < $gmaxsmils && $tempsmile =~ s~\Q::)\E~<img src="$simages/roll.png" style="vertical-align: middle" alt="" />~) { ++$smilecnt; }
	while($smilecnt < $gmaxsmils && $tempsmile =~ s~\Q:)\E~<img src="$simages/smiley.png" style="vertical-align: middle" alt="" />~) { ++$smilecnt; }
	while($smilecnt < $gmaxsmils && $tempsmile =~ s~\Q:-)\E~<img src="$simages/smiley.png" style="vertical-align: middle" alt="" />~) { ++$smilecnt; }
	while($smilecnt < $gmaxsmils && $tempsmile =~ s~\Q:D\E~<img src="$simages/lol.png" style="vertical-align: middle" alt="" />~) { ++$smilecnt; }
	while($smilecnt < $gmaxsmils && $tempsmile =~ s~\Q:-D\E~<img src="$simages/lol.png" style="vertical-align: middle" alt="" />~) { ++$smilecnt; }
	while($smilecnt < $gmaxsmils && $tempsmile =~ s~\Q:B\E~<img src="$simages/blush.png" style="vertical-align: middle" alt="" />~) { ++$smilecnt; }
	while($smilecnt < $gmaxsmils && $tempsmile =~ s~\Q??)\E~<img src="$simages/huh.png" style="vertical-align: middle" alt="" />~) { ++$smilecnt; }
	while($smilecnt < $gmaxsmils && $tempsmile =~ s~\Q:'(\E~<img src="$simages/cry.png" style="vertical-align: middle" alt="" />~) { ++$smilecnt; }
	while($smilecnt < $gmaxsmils && $tempsmile =~ s~\Q:X\E~<img src="$simages/lipsx.png" style="vertical-align: middle" alt="" />~) { ++$smilecnt; }
	while($smilecnt < $gmaxsmils && $tempsmile =~ s~\Q:o\E~<img src="$simages/shock.png" style="vertical-align: middle" alt="" />~) { ++$smilecnt; }
	while($smilecnt < $gmaxsmils && $tempsmile =~ s~\Q:K)\E~<img src="$simages/kiss.png" style="vertical-align: middle" alt="" />~) { ++$smilecnt; }
	while($smilecnt < $gmaxsmils && $tempsmile =~ s~(\A|\W);D~$1<img src="$simages/grin.png" style="vertical-align: middle" alt="" />~) { ++$smilecnt; }
	while($smilecnt < $gmaxsmils && $tempsmile =~ s~\Q;-D\E~<img src="$simages/grin.png" style="vertical-align: middle" alt="" />~) { ++$smilecnt; }
	while($smilecnt < $gmaxsmils && $tempsmile =~ s~\Q8)\E~<img src="$simages/cool.png" style="vertical-align: middle" alt="" />~) { ++$smilecnt; }
	while($smilecnt < $gmaxsmils && $tempsmile =~ s~\Q:P\E~<img src="$simages/tongue.png" style="vertical-align: middle" alt="" />~) { ++$smilecnt; }
	while($smilecnt < $gmaxsmils && $tempsmile =~ s~\Q\&gt;:(\E~<img src="$simages/angry.png" style="vertical-align: middle" alt="" />~) { ++$smilecnt; }
	while($smilecnt < $gmaxsmils && $tempsmile =~ s~\Q:-/\E~<img src="$simages/undecided.png" style="vertical-align: middle" alt="" />~) { ++$smilecnt; }
	while($smilecnt < $gmaxsmils && $tempsmile =~ s~\Q:(\E~<img src="$simages/sad.png" style="vertical-align: middle" alt="" />~) { ++$smilecnt; }
	while($smilecnt < $gmaxsmils && $tempsmile =~ s~\Q:-(\E~<img src="$simages/sad.png" style="vertical-align: middle" alt="" />~) { ++$smilecnt; }
	while($smilecnt < $gmaxsmils && $tempsmile =~ s~(\A|\W)\Q;)\E~$1<img src="$simages/wink.png" style="vertical-align: middle" alt="" />~) { ++$smilecnt; }
	while($smilecnt < $gmaxsmils && $tempsmile =~ s~(\A|\W)\Q;-)\E~$1<img src="$simages/wink.png" style="vertical-align: middle" alt="" />~) { ++$smilecnt; }
	if($upbc) {
		if($temper ne '') { $simages = $temper };
		if(!$SmileysOpen) {
			fopen(SMILEY,"$prefs/smiley.txt");
			while($smiley = <SMILEY>) {
				chomp $smiley;
				@t = split(/\|/,$smiley);
				push(@Smilies,$t[0]);
				$Smiley{$t[0]} = $t[1];
			}
			fclose(SMILEY);
			$SmileysOpen = 1;
		}

		foreach(@Smilies) { $tempsmile =~ s~\Q$_\E~<img src="$simages/$Smiley{$_}" style="vertical-align: middle" alt="" />~g; }
	}

	return($tempsmile);
}

sub Quote {
	my($qdate,$qmessage,$repaste,$qname);
	if($2) {
		GetMemberID($1);
		if($memberid{$1}{'sn'} ne '') { $qname = $userurl{$1}; }
			else { $qname = $1; }

		if($3) {
			$qdate = get_date($3);
			$quotedfrom = qq~$rtxt[22] <strong>$qname</strong>, $rtxt[23] <strong>$qdate</strong> $rtxt[21] <strong><a href="$2" title="$rtxt[25]">$rtxt[26]</a></strong>~;
			$qmessage = $4;
		} else { $quotedfrom = qq~$rtxt[22] <strong>$qname</strong>~; $qmessage = $2; }
	} else {
		$quotedfrom = "<strong>$rtxt[27]</strong>";
		$qmessage = $1;
	}

	return <<"EOT";
<blockquote>
 <div class="win3 quoteby">$quotedfrom</div>
 <div class="win quotebody">$qmessage</div>
</blockquote>
EOT
}

sub SizedURL {
	my $url;

	$url = $_[1];

	if(length($url) > 100 && $URL{'v'} ne 'print') { $url = substr($url,0,30).'.....'.substr($url,length($url)-20); }
	return(qq~$_[0]<a href="$_[1]"$blanktarget>$url</a>~);
}

sub Code {
	if($BCLoad == 0) { return; }

	%translation = (
		'('  => '&#040;',
		'D'  => '&#068;',
		')'  => '&#041;',
		'-'  => '&#045;',
		'/'  => '&#047;',
		':'  => '&#058;',
		'?'  => '&#063;',
		'['  => '&#091;',
		'\\' => '&#092;',
		']'  => '&#093;',
		'.'  => '&#046;'
	);
	$codelander = $1;

	$height = 50;
	$codelander =~ s/&nbsp; &nbsp; &nbsp;/\t/g; # DO THE TABS

	while($codelander =~ s/<br \/>/\n/s) { $height += 10; }
	$codelander =~ s/<br \/>/\n/g;

	$codelander =~ s/([\:\(\)\-\/\?\[\]\\\.D])/$translation{$1}/g;
	$height = 350 if($height > 350);

	return <<"EOT";
<table class="border" cellpadding="0" cellspacing="1">
 <tr>
  <td>
   <div class="win3" style="padding: 8px"><strong>$rtxt[57]</strong></div>
   <div class="win" style="padding: 2px; overflow: auto; width: 800px; height: $height\lpx; margin: 0px;">
    <table cellpadding="0" cellspacing="0" class="innertable">
     <tr>
      <td style="padding: 8px"><pre>$codelander</pre></td>
     </tr>
    </table>
   </div>
  </td>
 </tr>
</table>
EOT
}

sub BC {
	my($tempinput) = $_[0];
	my($temp1,$temp2,$ol);

	if($tempinput eq '') { return(); }

	$or_nosmiley = $or_nobc = $or_html = 0;
	while($tempinput =~ s/^\#(nosmiley|nobc|html)//) { ${"or_$1"} = 1; }

	if($html && $nosmile < 2 && !$or_html) {
		$tempinput =~ s/&quot;/"/g;
		if($htmls[0] ne '') {
			foreach(@htmls) {
				$close = $open = 0;
				while($tempinput =~ s~\&lt;$_(\w? || .*?)\&gt;~<$_$1$2>~) { ++$open; }
				while($tempinput =~ s~\&lt;/$_(.*?)\&gt;~</$_$1>~) { ++$close; }
				while($open > $close) { $tempinput .= "</$_>"; ++$close; } # Close open tags ('security')
			}
		} else { $tempinput =~ s~\&lt;(.*?)\&gt;~<$1>~gsi; }
	}
	$tempinput =~ s~\[code\](.+?)\[/code\]~Code()~esgi;

	while($tempinput =~ s~\[quote by=(.+?) link=(.+?) date=(.+?)\](.+?)\[/quote\]~Quote()~gsie) { }
	while($tempinput =~ s~\[quote=(.+?)\](.+?)\[/quote\]~Quote()~gsie) { }
	while($tempinput =~ s~\[quote\](.+?)\[/quote\]~Quote()~gsie) { }

	if($al) {
		$tempinput =~ s~([^\w\"\=\[\]]|[\n\b]|\A)\\*(\w+://[\w\~\.\;\:\$\-\+\!\*\?/\=\&\@\#\%]+\.[\w\~\;\:\$\-\+\!\*\?/\=\&\@\#\%,.]+[\w\~\;\:\$\-\+\!\*\?/\=\&\@\#\%])~SizedURL($1,$2)~eisg;
		$tempinput =~ s~([^\"\=\[\]/\:\.(\://\w+)]|[\n\b]|\A|[\<\n\b\>])\\*(www\.[^\.][\w\~\.\;\:\$\-\+\!\*\?/\=\&\@\#\%]+\.[\w\~\;\:\$\-\+\!\*\?/\=\&\@\#\%\,]+[\w\~\;\:\$\-\+\!\*\?/\=\&\@\#\%])~SizedURL($1,"http://$2")~eisg;
	}
	if($BCSmile && ($nosmile != 1 && $nosmile != 3 && !$or_nosmiley)) { $tempinput = BCSmileys($tempinput); }

	if(!$BCLoad || $or_nobc) { return(CensorList($tempinput)); } # BC is disabled =(

	while($tempinput =~ s~\[s\](.*?)\[/s\]~<span style="text-decoration: line-through;">$1</span>~gsi) { }
	while($tempinput =~ s~\[b\](.+?)\[/b\]~<strong>$1</strong>~gsi) { }
	while($tempinput =~ s~\[i\](.*?)\[/i\]~<span style="font-style: italic;">$1</span>~gsi) { }
	while($tempinput =~ s~\[u\](.*?)\[/u\]~<span style="text-decoration: underline;">$1</span>~gsi) { }
	while($tempinput =~ s~\[blockquote\](.*?)\[/blockquote\]~<blockquote>$1</blockquote>~gsi) { }
	while($tempinput =~ s~\[size=([1-9][^\s\n<>]*?)\](.*?)\[/size\]~<span style="font-size: $1px;">$2</span>~gsi) { }

	$tempinput =~ s~\[img\](http|ftp|mms|https)://(.[^\s\n<>]+?)\[/img\]~<img class="imgcode" src="$1://$2" alt="" />~gsi;
	$tempinput =~ s~\[img width=([1-9][^\s]*?) height=([1-9][^\s]*?)\](http|ftp|mms|https)://(.[^\s\n<>]+?)\[/img\]~<img class="imgcode" src="$3://$4" width="$1" height="$2" alt="" />~gsi;
	$tempinput =~ s~\[img width=([1-9][^\s]*?) height=([1-9][^\s]*?) align=(right|left)\](http|ftp|mms|https)://(.[^\s\n<>]+?)\[/img\]~<img src="$4://$5" width="$1" height="$2" class="$3img imgcode" alt="" />~gsi;
	$tempinput =~ s~\[img align=(right|left|center)\](http|ftp|mms|https)://(.[^\s\n<>]+?)\[/img\]~<img src="$2://$3" class="$1img imgcode" alt="" />~gsi;

	$tempinput =~ s~\[url=(http|ftp|mms|https)://(.[^\s\n<>]+?)\](.+?)\[/url\]~<a href="$1://$2" title="$2" onclick="target='_new';">$3</a>~gsi;
	$tempinput =~ s~\[url=www\.(.[^\s\n<>]+?)\](.+?)\[/url\]~<a href="http://www.$1" title="www.$1" onclick="target='_new';">$2</a>~gsi;
	$tempinput =~ s~\[url\](http|ftp|mms|https)://(.[^\s\n<>]+?)\[/url\]~SizedURL('',"$1://$2")~egsi;
	$tempinput =~ s~\[url\]www\.(.[^\s\n<>]+?)\[/url\]~SizedURL('',"http://www.$1")~egsi;

	$tempinput =~ s~\[youtube\]([A-Za-z0-9\_\+\-]+?)\[\/youtube\]~<object width="425" height="350"><param name="movie" value="http://www.youtube.com/v/$1"></param><embed src="http://www.youtube.com/v/$1" type="application/x-shockwave-flash" width="425" height="350"></embed></object>~gsi;
	$tempinput =~ s~\[tube\]http://www.youtube.com/(.[^\s\n<>]+?)\[\/tube\]~<object width="425" height="350"><param name="movie" value="http://www.youtube.com/$1"></param><embed src="http://www.youtube.com/$1" type="application/x-shockwave-flash" width="425" height="350"></embed></object>~gsi;

	$tempinput =~ s~\[flash width=([0-9]*?) height=([0-9]*?) url=(http|ftp|mms|https)://(.[^\s\n<>]+?)\]~<object classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000" width="$1" height="$2"><param name="movie" value="$3://$4" /><param name="play" value="true" /><param name="loop" value="true" /><param name="quality" value="high" /><embed src="$3://$4" width="$1" height="$2" play="true" loop="true" quality="high"></embed></object>~gsi;

	$tempinput =~ s~\[pre\](.+?)\[/pre\]~<pre>$1</pre>~gsi;

	while($tempinput =~ s~^(.*?)\[list=?([a-zA-Z|1]*?)\](.*?)\[/list\](.*?)\Z~~s) {
		$tempinput = $1;
		$temp1 = $3; $temp2 = $4;

		$tempinput .= $2 ne '' ? qq~<ol type="$2">~ : '<ul>';
		$ol = $2 ne '' ? '</ol>' : '</ul>';

		$temp1 =~ s/^\<br \/\>//g;
		while($temp1 =~ s~\[\*\](.+?)(\[\*\]|\<li\>|\Z)~<li>$1</li>$2~gsi) { }

		$tempinput .= $temp1.$ol.$temp2;
	}

	while($tempinput =~ s~\[left\](.+?)\[/left\]~<div style="text-align: left">$1</div>~gsi) { }
	while($tempinput =~ s~\[right\](.+?)\[/right\]~<div style="text-align: right">$1</div>~gsi) { }
	while($tempinput =~ s~\[center\](.+?)\[/center\]~<div style="text-align: center">$1</div>~gsi) { }
	while($tempinput =~ s~\[justify\](.+?)\[/justify\]~<div style="text-align: justify">$1</div>~gsi) { }
	while($tempinput =~ s~\[face=(.+?)\](.+?)\[/face\]~<span style="font-family: $1">$2</span>~gsi) { }
	while($tempinput =~ s~\[color=(.+?)\](.+?)\[/color\]~<span style="color: $1">$2</span>~gsi) { }
	while($tempinput =~ s~\[bgcolor=(.+?)\](.+?)\[/bgcolor\]~<span style="background-color: $1; padding: 5px;">$2</span>~gsi) { }

	$tempinput =~ s~\[glow=(.+?) strength=(.+?)\](.*?)\[/glow\]~<span style="filter:glow(color=$1, strength=$2);height: 1px;">$3</span>~gsi;
	$tempinput =~ s~\[glow=(.+?)\](.*?)\[/glow\]~<span style="filter:glow(color=$1, strength=5);height: 1px;">$2</span>~gsi;
	$tempinput =~ s~\[shadow=(.+?) strength=(.+?)\](.*?)\[/shadow\]~<span style="filter:shadow(color=$1, strength=$2);height: 1px;">$3</span>~gsi;
	$tempinput =~ s~\[shadow=(.+?)\](.*?)\[/shadow\]~<span style="filter:shadow(color=$1, strength=5);height: 1px;">$2</span>~gsi;

	$tempinput =~ s~\[hr\]~<hr />~gsi;
	$tempinput =~ s~\[sub\](.+?)\[/sub\]~<sub>$1</sub>~gsi;
	$tempinput =~ s~\[sup\](.+?)\[/sup\]~<sup>$1</sup>~gsi;
	$tempinput =~ s~\[mail\](.+?)\[/mail\]~<a href="mailto:$1">$1</a>~gsi;
	$tempinput =~ s~\[mail=(.+?)\](.+?)\[/mail\]~<a href="mailto:$1">$2</a>~gsi;
	$tempinput =~ s~\[move\](.+?)\[/move\]~<marquee>$1</marquee>~gsi;

	if($tempinput =~ /\[table\](.+?)\[\/table\]/) {
		$tempinput =~ s/<br \/>/\t/gsi;
		while($tempinput =~ s~\t{0,1}\[table\]\t{0,1}(.+?)\t{0,1}\[\/table\]\t{0,1}~<table class="innertable">$1</table>~sgi) {
			while($tempinput =~ s~<table class="innertable">\t{0,1}(.*?)\t{0,1}\[tr\]\t{0,1}(.*?)\t{0,1}\[/tr\]\t{0,1}(.*?)\t{0,1}</table>~<table class="innertable">$1<tr>$2</tr>$3</table>~sgi) { } # Loop until rows are done.
			while($tempinput =~ s~<table class="innertable">(.*?)<tr>\t{0,1}(.*?)\t{0,1}\[td\]\t{0,1}(.*?)\t{0,1}\[/td\]\t{0,1}(.*?)\t{0,1}</tr>(.*?)</table>~<table class="innertable">$1<tr>$2<td>$3</td>$4</tr>$5</table>~sig) { } # Loop until cols are done.
		}
		$tempinput =~ s/\t/<br \/>/gsi;
	}
	return(CensorList($tempinput));
}

sub smail {
	my($subject,$message,$wholemessage,$tothis);
	my($to,$subject,$message,$from) = @_;
	if(!$to || !$subject || !$message) { return(-1); }
	if($to !~ /\A([0-9A-Za-z\._\-]{1,})@([0-9A-Za-z\._\-]{1,})+\.([0-9A-Za-z\._\-]{1,})+\Z/) { return(-1); }

	$message =~ s/\cM//g;
	$message =~ s/\n/<br \/>/gsi;
	$message =~ s/  /&nbsp; /gsi;
	$message =~ s/&lt;br&gt;/<br \/>/gsi;
	$message =~ s/<br \/>/<br \/>\n/gsi;
	$message =~ s/bgcolor="(.+?)"/bgcolor="#FFFFFF"/gsi;
	$emailsig = Unformat($emailsig);
	if($emailsig) { $message .= qq~<br /><br /><hr />$emailsig~; }

	$wholemessage = <<"EOT";
<div style="font-family: Verdana, sans-serif; font-size: 11px; color: black; line-height: 150%">$message</div>
EOT
	if($eadmin eq '') { $eadmin = "noreply\@noreply.noreply"; }
	if($mailuse == 1) {
		open(MAIL,"| $smaill -t");
		print MAIL "MIME-Version: 1.0\n";
		print MAIL "Content-Type: text/html; charset=\"$char\"\n";
		print MAIL "Content-Transfer-Encoding: $char2\n";
		print MAIL "X-Forum-System: E-Blah, $version, copyright 2001-2008\n";
		print MAIL "X-Username: $username\n";
		print MAIL "X-Sent-From-IP: $ENV{'REMOTE_ADDR'}\n";
		print MAIL "To: $to\n";
		print MAIL "From: \"$regto\" <$eadmin>\n";
		print MAIL "Subject: $subject\n\n";
		print MAIL "$wholemessage";
		print MAIL "\n\n";
		close(MAIL);
	} elsif($mailuse == 2) {
		eval q{
			use Net::SMTP;
			my $smtp = Net::SMTP->new($mailhost);
			$smtp->auth($mailusername,$mailpassword) if($mailauth);
			$smtp->mail($eadmin);
			$smtp->to($to);
			$smtp->data();
			$smtp->datasend("MIME-Version: 1.0\n");
			$smtp->datasend("Content-Type: text/html; charset=$char\n");
			$smtp->datasend("Content-Transfer-Encoding: $char2\n");
			$smtp->datasend("X-Forum-System: E-Blah, $version, copyright 2001-2008\n");
			$smtp->datasend("X-Username: $username\n");
			$smtp->datasend("X-Sent-From-IP: $ENV{'REMOTE_ADDR'}\n");
			$smtp->datasend("To: $to\n");
			$smtp->datasend("From: \"$regto\" <$eadmin>\n");
			$smtp->datasend("Subject: $subject\n\n");
			$smtp->datasend("$wholemessage");
			$smtp->datasend("\n");
			$smtp->dataend();
			$smtp->quit;
		};
		if($@) { error("[b]Net::SMTP Error[/b]\n\n$@",2); }
	}

	$maildebug = 0;
	if($maildebug) {
		$time = time;
		fopen(OPENFILE,">$root/$time\_mailed.txt");
		print OPENFILE "To: $to\nFrom: \"$from\" <$eadmin>\nSubject: $subject\n\n$wholemessage";
		fclose(OPENFILE);
	}

	return(1); # Clean return
}

sub ExtClose { # Save extensive log ..
	my($save,$u,$day,$month,$year);

	($t,$t,$t,$day,$month,$year) = localtime(time);
	$save = $day.$month.$year;

	fopen(WRITEEXT,"+<$prefs/BHits/$save.txt");
	@ExtensiveLogs = <WRITEEXT>;
	chomp @ExtensiveLogs;
	if($ExtensiveLogs[0] eq '') {
		fclose(WRITEEXT);
		fopen(WRITEEXT,"+>$prefs/BHits/$save.txt");
	}
	seek(WRITEEXT,0,0);
	truncate(WRITEEXT,0);
	for($u = 0; $u < 9; $u++) {
		$ExtensiveLogs[$u] = 0 if($ExtensiveLogs[$u] eq '');
		if($u != 7) { $PLog[$u] = ($ExtLog[$u]+$ExtensiveLogs[$u]) || 0; }
	}
	if($ExtensiveLogs[7] < $ExtLog[7]) { $PLog[7] = $ExtLog[7]; } else { $PLog[7] = $ExtensiveLogs[7]; }
	print WRITEEXT "$PLog[0]\n$PLog[1]\n$PLog[2]\n$PLog[3]\n$PLog[4]\n$PLog[5]\n".time."\n$PLog[7]\n$PLog[8]";
	fclose(WRITEEXT);
}

sub Mark {
	my($olddata);
	if($username eq 'Guest') { error($gtxt{'noguest'}.'-register-'); }

	$time = time;

	if($URL{'l'} eq 'bindex') {
		$del{'AllBoards'} = 1;

		$addlist = "AllBoards|$time\n";

		foreach(@boardbase) { # Delete all old boards too ...
			($woot) = split('/',$_);

			fopen(BMESSAGES,"$boards/$woot.msg");
			while(<BMESSAGES>) {
				($t) = split(/\|/,$_);
				$del{$t} = 1;
			}
			fclose(BMESSAGES);

			$del{$woot} = $del{"AllRead_$woot"} = 1;
			$addlist .= "AllRead_$woot|$time\n";
		}
	}

	if($URL{'l'} eq 'bdis')   {
		$url = $surl;

		fopen(BMESSAGES,"$boards/$URL{'b'}.msg");
		while(<BMESSAGES>) {
			($t) = split(/\|/,$_);
			$del{$t} = 1;
		}
		fclose(BMESSAGES);

		$del{"AllRead_$URL{'b'}"} = $del{$URL{'b'}} = 1;

		$addlist = "AllRead_$URL{'b'}|$time\n";
	}

	if(-e("$members/$username.log")) {
		fopen(MEMLOG,"$members/$username.log");
		while(<MEMLOG>) {
			chomp;
			($t) = split(/\|/,$_);
			if($del{$t}) { next; }
			$olddata .= "$_\n";
		}
		fclose(MEMLOG);
	}

	fopen(MEMLOG,">$members/$username.log");
	print MEMLOG "$addlist$olddata";
	fclose(MEMLOG);

	if($URL{'v'} eq 'register') { return(1); }
		else { redirect(); }
}

sub MakeComma {
	$ctobe = $_[0];
	if(!$nocomma) { return($ctobe); }
	if(!$ctobe) { return(0); }
	while($ctobe =~ s/^([-+]?\d+)(\d{3})/$1$nocomma$2/) { } # Loop and make commas
	return($ctobe);
}

sub SpecialErrors {
	$error =~ s/(-admin-|-register-)//g;

	$plinks .= qq~<ul><li><a href="$surl\lv-register/" rel="nofollow">$rtxt[33]</a></li><li><a href="$surl\lv-login/" rel="nofollow">$rtxt[34]</a></li><li><a href="$surl\lv-login/p-forgotpw/" rel="nofollow">$rtxt[81]</a></li></ul>~;

	$qlogin = <<"EOT";
<tr>
 <td class="catbg">$rtxt[80]</td>
</tr><tr>
 <td class="win3">
  <form action="$surl\lv-login/p-2/" method="post">
   <table cellpadding="4" cellspacing="0" class="innertable" width="300">
    <tr>
     <td>$rtxt[36]</td>
    </tr><tr>
	 <td><input type="text" name="username" size="20" tabindex="56" /></td>
    </tr><tr>
     <td>$rtxt[37]</td>
    </tr><tr>
     <td><input type="password" name="password" size="20" tabindex="57" /></td>
    </tr><tr>
     <td><input type="hidden" name="days" value="forever" /><input type="hidden" name="redirect" value="$ENV{'QUERY_STRING'}" /><input type="submit" value="&nbsp;&nbsp;$rtxt[38]&nbsp;&nbsp;" tabindex="58" /></td>
    </tr>
   </table>
  </form>
 </td>
</tr>
EOT
}

sub ShowGuest {
	CoreLoad('Login',1);

	$guestlogin = <<"EOT";
<table cellpadding="4" cellspacing="1" class="border" width="450">
 <tr>
  <td class="titlebg smalltext"><strong>$rtxt[35]</strong></td>
 </tr><tr>
  <td class="win">
   <form action="$surl\lv-login/p-2/" method="post">
    <table cellpadding="2" cellspacing="0" width="100%">
     <tr>
      <td class="smalltext"><strong>$rtxt[36]:</strong></td>
      <td colspan="2"><input type="text" name="username" size="20" tabindex="56" /></td>
      <td class="smalltext"><strong><a href="$surl\lv-register/" rel="nofollow">$logintxt[3]</a></strong></td>
     </tr><tr>
      <td class="smalltext"><strong>$rtxt[37]:</strong></td>
      <td><input type="password" name="password" size="20" tabindex="57" /></td>
      <td>&nbsp; &nbsp;<input type="hidden" name="days" value="forever" /><input type="hidden" name="redirect" value="$ENV{'QUERY_STRING'}" /><input type="submit" value="&nbsp;&nbsp;$rtxt[38]&nbsp;&nbsp;" tabindex="58" /></td>
      <td class="smalltext"><strong><a href="$surl\lv-login/p-forgotpw/" rel="nofollow">$logintxt[5]</a></strong></td>
     </tr>
    </table>
   </form>
  </td>
 </tr>
</table><br />
EOT
}

sub calage {
	($bday) = @_;
	($t,$t,$t,$td,$tm,$ty) = localtime(time);
	($m,$d,$y) = split("/",$bday);
	$ty += 1900;
	if($y < 1900) { $y += 1900; }
	$age = ($ty-$y)-1;
	if((($tm+1) == $m && $td >= $d) || ($tm+1) > $m) { ++$age; }
	if(!$bday) { $age = 0; } else { --$m; $ageurl = "$surl\lv-cal/month-".($m+1)."/"; }
	return($age);
}

sub Highlight {
	$_[0] =~ s/<br \/>/<br \/>\n/gsi;
	@smallm = split(/(<.*?>)\s/,$_[0]);
	$_[0] = '';

	foreach(@smallm) {
		if($_ !~ /[ht|f]tp/ && $_ !~ /<(.*?)>/) {
			foreach $hl (@lights) {
				if($hl eq '') { next; }
				$_ =~ s~(\Q$hl\E)~<span style="background-color:yellow; color: black; font-weight: bold;">$1</span>~isg;
			}
		}
		$_[0] .= "$_ ";
	}
}

sub VerifyBoard { # This simply verifies that the user requesting, has authorization to get the data requested
	my($id,$nme,$grps,$input,$memgrp,$catbase,@binfo,$grp);

	foreach $catbase (@catbase) {
		($nme,$id,$grps,$input) = split(/\|/,$catbase);

		if($grps ne '') {
			$con = '';
			$con = 1 if(GetMemberAccess($grps));
			if(!$con) { next; }
		}
		@input2 = split("/",$input);
		foreach $onlist (@input2) {
			$boardson{$onlist} = 1;
		}

		$catallow{$id} = 1;
		++$catcounter;
	}

	foreach $boardindex (@boardbase) {
		($id2,$t,$t,$t,$t,$t,$t,$binfo[6],$t,$t,$binfo[9],$t,$t,$t,$t,$binfo[14]) = split("/",$boardindex);

		if(!$boardson{$id2}) { next; }
		if($binfo[6] ne '') { next; }

		$con = '';
		$con = 1 if(GetMemberAccess($binfo[9]));
		if(!$con) { next; }

		$boardallow{$id2} = 1;
		$readallow{$id2} = GetMemberAccess($binfo[14]);
		++$boardcounter;
	} # Command outputs: $[cat|board]allow{id} and $[cat|board]counter
}

sub SetCookie { # Gets cookie data, and prints it
	my($cookname,$cookvalue,$cookexp) = @_;
	print "Set-Cookie: $cookname=$cookvalue; path=/; expires=$cookexp\n";
	return();
}

sub NotifyAddStatus {
	if($username eq 'Guest') { return(0); }

	my($message,$status,$add,$type) = @_; # 1 = Add/Rem; 2 = Certain Message Status; 3 = Users on 1 message; 4 = Return the full db
	my($messageid,$userbase,$baseuser,$newbase,$indb,$temp);

	$type = $type ? 1 : 0;

	if(!$maildbopen) {
		fopen(DB,"$messages/Mail/database.mail");
		@maildatabase = <DB>;
		fclose(DB);
		chomp @maildatabase;
		$maildbopen = 1;
	}

	return(1) if $status == 4;

	fopen(DB,">$messages/Mail/database.mail") if ($status == 1);
	foreach(@maildatabase) {
		($messageid,$userbase) = split(/\|/,$_);
		@userbase = split(",",$userbase);

		if($messageid eq $message) {
			return(@userbase) if $status == 3;

			foreach $temp (@userbase) {
				($baseuser,$basetype) = split("/",$temp);
				if($username eq $baseuser) {
					return(1) if $status == 2;
					next;
				}
				$newbase .= "$baseuser/$basetype,";
			}
			$newbase .= "$username/$type" if $add;
			$newbase =~ s/,\Z//g;
			$indb = 1;
		}

		if($status == 1) {
			print DB "$messageid|$newbase\n" if ($messageid eq $message && $newbase ne '');
			print DB "$messageid|$userbase\n" if ($messageid ne $message);
		}
	}
	print DB "$message|$username\n" if ($status == 1 && !$indb && $add);
	fclose(DB) if ($status == 1);

	$maildbopen = 0 if $status == 1; # We've got to reload the DB ...

	return(0) if $status == 2;
}

sub UserDatabase {
	my(@tfuser,@t);

	@tfuser = @_;
	if(!$mlistload) {
		fopen(ULIST,"$members/List2.txt");
		@memlist2 = <ULIST>;
		fclose(ULIST);
		chomp @memlist2;
		$mlistload = 1;
	}

	if($tfuser[0] eq '') { return(); }

	fopen(ULIST,">$members/List2.txt");
	foreach(@memlist2) {
		@t = split(/\|/,$_);
		if($t[0] eq $tfuser[0]) { print ULIST "$tfuser[0]|$tfuser[1]|$tfuser[2]|$tfuser[3]|$tfuser[4]|$tfuser[5]|$tfuser[6]\n"; }
			else { print ULIST "$t[0]|$t[1]|$t[2]|$t[3]|$t[4]|$t[5]|$t[6]\n"; }
	}
	fclose(ULIST);
}

sub CheckTime {
	print "Content-type: text/html\n\n";
	$URL{'zone'} =~ s/\'/\-/g;
	$memberid{$username}{'timezone'} = $URL{'zone'};
	$memberid{$username}{'dst'} = 1 if($URL{'saving'} eq 'true');
	$memberid{$username}{'dst'} = 0 if($URL{'saving'} eq 'false');

	if($datedisplayH{$URL{'date'}} ne '') { $DateDisplay = $datedisplayH{$URL{'date'}}; }
		else { $DateDisplay = $FORM{'date'}; }
	$DateDisplay = $DateDisplay.$timedisplayH{$URL{'time'}};
	print get_date(time,1);
	print qq~<div style="margin-top: 5px"><strong>$rtxt[70]:</strong> $DateDisplay</div>~;
	exit;
}

sub GetActiveUsers { # Outputs: $hidec, $botc, $memcnt, $gcnt, $memberson, $B{x}, $useronline{y}
	my($luser,$ltime,$lview,$lboard,$lmess,@quicksort,$coloruser);

	foreach(@activeusers) {
		chomp $_;
		($luser) = split(/\|/,$_);
		GetMemberID($luser);
		$tuser = $memberid{$luser}{'sn'} || $botsearch{$luser} || $luser;
		push(@quicksort,"$tuser|$_");
	}

	$activecnt = @quicksort;

	$hidec = $botc = $memcnt = $gcnt = 0;

	foreach(sort{lc($a) cmp lc($b)} @quicksort) {
		($t,$luser,$ltime,$lview,$lboard,$lmess) = split(/\|/,$_);
		++$B{$lboard};

		if($URL{'b'} ne '' && $URL{'b'} ne $lboard) { next; }

		$t = get_date($ltime,1);

		if($memberid{$luser}{'sn'} ne '') {
			$coloruser = $permissions{$membergrp{$luser},'color'} ? qq~ class="usercolors" style="color: $permissions{$membergrp{$luser},'color'}"~ : '';

			if($memberid{$luser}{'hideonline'}) {
				++$hidec;
				if($members{'Administrator',$username}) { $memberson .= qq~<i><a href="$surl\lv-memberpanel/a-view/u-$luser/" rel="nofollow"$coloruser title="$t">$memberid{$luser}{'sn'}</a></i>, ~; }
					else { next; }
			} else {
				++$memcnt;
				$memberson .= qq~<a href="$surl\lv-memberpanel/a-view/u-$luser/" rel="nofollow"$coloruser title="$t">$memberid{$luser}{'sn'}</a>, ~;
			}

			$useronline{$luser} = 1;
		} elsif($botsearch{$luser}) {
			$memberson .= qq~<a title="$t" class="onlinebots" style="cursor:default;">$botsearch{$luser}</a>, ~;
			++$botc;
		} else { ++$gcnt; }
	}

	$memberson =~ s/, \Z//i;
	if($memberson eq '') { $memberson = $ltxt[20]; }
}

sub ceil {
	return int($_[0] + .5 * ($_[0] <=> 0));
}

# From http://melecio.org/node/76, 3 Mar 08
sub urlencode {
	my $urlencode = $_[0];
	$urlencode =~ s/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg;
	return($urlencode);
}

sub urldecode {
	my $urldecode = $_[0];
	$urldecode =~ s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg;
	return($urldecode);
}
1;