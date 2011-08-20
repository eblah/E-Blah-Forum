#############################################
# E-Blah Bulletin Board Systems        2008 #
#############################################
# Copyright (c) 2001 - 2008 E-Blah.         #
#############################################

CoreLoad('Login',1);

if($ensids) {
	eval { require("CGI/Session.pm"); };
	if($@) { $sessionError = 1; }
}

sub error_log {
	if($URL{'r'} == 1 && $er eq '') { $er = $logintxt[13]; }
	elsif($er ne '') { } # Already added
		else { $er = $logintxt[14]; }
	$error = <<"EOT";
<table class="border" cellpadding="6" cellspacing="1" width="100%">
 <tr>
  <td class="titlebg"><strong>$logintxt[41]</strong></td>
 </tr><tr>
  <td class="win"><strong>$logintxt[42]</strong><br /><br />&nbsp; &nbsp; &nbsp; &#149; $er<br /><br />$appendattempts</td>
 </tr>
</table><br />
EOT
}

sub Login {
	if($maxattempts > 0 && $loginfailtime > 0) {
		fopen(FILE,"$prefs/loginlock.txt");
		@locked = <FILE>;
		fclose(FILE);
		chmod @locked;
		foreach(@locked) {
			($ipaddy,$time,$attempts) = split(/\|/,$_);
			if($ipaddy eq $ENV{'REMOTE_ADDR'}) {
				$attempts = $maxattempts-$attempts;
				if((time-$time) < (60*$loginfailtime)) { $appendattempts = "$logintxt[43] $attempts $logintxt[44]"; }
					else { last; }
				if($attempts <= 0) { $er = "$logintxt[45] $loginfailtime $logintxt[46]"; $appendattempts = ''; }
				last;
			}
		}
	}

	if($URL{'p'} > 2) { Logout(); }
	if($username ne 'Guest') { error($logintxt[1]); }

	$gdisable = 1;
	if($URL{'p'} eq 'forgotpw') { SendPassword(); }
	if($URL{'p'} eq 'forgotpw2') { SendPassword2(); }
	if($URL{'p'} eq 'forgotpw3') { SendPassword3(); }
	if($URL{'p'} == 2) { Login2(); }
	if($URL{'r'} || $er) { error_log(); }

	if($uservalue eq '') { GetMemberID($URL{'u'}); $uservalue = $memberid{$URL{'u'}}{'sn'}; }

	$title = $logintxt[12];
	header();
	$ebout .= <<"EOT";
$error$warnonthis
<form action="$surl\lv-login/p-2/" method="post">
<table cellspacing="1" cellpadding="5" class="border" width="100%">
 <tr>
  <td colspan="2" class="titlebg"><strong>$title</strong></td>
 </tr><tr>
  <td style="width: 50%" class="catbg"><strong>$logintxt[65]</strong></td>
  <td style="width: 50%" class="catbg"><strong>$logintxt[55]</strong></td>
 </tr><tr>
  <td colspan="2" class="win" style="padding: 0px">
   <table cellpadding="5" cellspacing="0" width="100%">
    <tr>
     <td style="width: 50%">
      <table cellpadding="5" cellspacing="0" width="100%">
       <tr>
        <td colspan="2"><strong>$logintxt[2]</strong></td>
       </tr><tr>
        <td><input type="text" name="username" size="45" value="$uservalue" tabindex="1" /></td>
        <td class="win3 center"><img src="$images/register_sm.gif" class="centerimg" alt="" /> <a href="$surl\lv-register/" rel="nofollow">$logintxt[3]</a></td>
       </tr><tr>
        <td colspan="2" class="smalltext">$logintxt[63]</td>
       </tr><tr>
        <td colspan="2"><strong>$logintxt[4]</strong></td>
       </tr><tr>
        <td><input type="password" name="password" size="35" tabindex="2" /></td>
        <td class="win3 center"><img src="$images/restriction.png" class="centerimg" alt="" /> <a href="$surl\lv-login/p-forgotpw/" rel="nofollow">$logintxt[5]</a></td>
       </tr>
      </table>
     </td>
     <td class="win5" style="width: 3px">&nbsp;</td>
     <td class="vtop" style="width: 50%">
      <table cellpadding="5" cellspacing="0" width="100%">
       <tr>
        <td colspan="2"><strong>$logintxt[54]</strong></td>
       </tr><tr>
        <td colspan="2"><select name="days" tabindex="3"><option value="forever" selected="selected">Yes</option><option value="">No</option></select></td>
       </tr><tr>
        <td colspan="2" class="smalltext">$logintxt[64]</td>
       </tr>
       </table>
      </td>
     </tr>
   </table>
  </td>
 </tr><tr>
  <td colspan="2" class="win2 center"><input type="hidden" name="redirect" value="$FORM{'redirect'}" /><input type="submit" value=" $logintxt[12] " tabindex="5" /></td>
 </tr>
</table>
</form>
EOT

	footer();
	exit;
}

sub Login2 {
	my(@files);
	$FORM{'password'} = Format($FORM{'password'});

	if($maxattempts > 0 && $loginfailtime > 0) {
		$timecur = time;
		fopen(FILE,">$prefs/loginlock.txt");
		foreach(@locked) {
			($ipaddy,$time,$attempts) = split(/\|/,$_);

			if(($timecur-$time) > (60*$loginfailtime)) { next; }

			if($ipaddy eq $ENV{'REMOTE_ADDR'}) {
				++$attempts;
				print FILE "$ENV{'REMOTE_ADDR'}|$timecur|$attempts\n";
				$exout = 1;
				if($maxattempts-$attempts < 0) { $redirafter = 1; }
			} else { print FILE "$_\n"; }
		}
		if(!$exout) { print FILE "$ENV{'REMOTE_ADDR'}|$timecur|1\n"; }
		fclose(FILE);
		if($redirafter) { $URL{'p'} = ''; $URL{'r'} = 3; Login(); }
	}

	$username = FindUsername($FORM{'username'}) || FindUsername($FORM{'username'},'email');
	if($username eq '') { $username = 'Guest'; $URL{'p'} = ''; $URL{'r'} = 1; Login(); }
	GetMemberID($username);

	# Get passwords
	$password1 = Encrypt($FORM{'password'});
	if($yabbconver) { $password2 = $memberid{$username}{'password'}; } else { $password2 = Encrypt($memberid{$username}{'password'}); }

	if($password2 ne $password1) { $username = 'Guest'; $URL{'p'} = ''; $URL{'r'} = 2; $uservalue = $FORM{'username'}; Login(); }

	if((!$FORM{'nocookie'} && $ensids && !$sessionError) || $ensids == 2) {
		$session = new CGI::Session("driver:File", undef, {Directory=>"$prefs/Sessions"});

		$sessionID = $session->id();

		$session->param('username', $username);
		$session->param('password', $password1);

		if($FORM{'days'} ne 'forever') {
			$session->expire('+1h'); # Expires after 1 idle hour
		}

		$session->flush();

		SetCookie("$cookpre\_session",$sessionID,'Sat, 31-Dec-2039 00:00:00 GMT');
		$url = $surl;
	} else {
		if($FORM{'days'} eq '') { $FORM{'days'} = '.5'; } # Set's it to 12 hours
		if($FORM{'days'} eq 'forever') {
			$exp = 'Sat, 31-Dec-2039 00:00:00 GMT';
		} else {
			$time = time;
			if($FORM{'days'} !~ /[0-9]/) { $FORM{'days'} = 365; } # Blank? Lets make it a year then
			if($FORM{'days'} eq '') { $FORM{'days'} = 1; }
			$maxdays = $FORM{'days'}*86400;
			$maxdays = $maxdays+$time;
			($csec,$cmin,$chour,$cday,$cmonth,$cyear,$cweek,$cydays,$cdst) = gmtime($maxdays);
			if($chour < 10) { $chour = "0$chour"; }
			if($cmonth < 10) { $cmonth = "0$cmonth"; }
			$xyear = $cyear+1900;
			@xdays = ('Sun','Mon','Tues','Wed','Thur','Fri','Sat');
			@xmonths = ('Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec');
			$exp = "$xdays[$cweek], $cday-$xmonths[$cmonth]-$xyear $chour:00:00 GMT";
		}
		SetCookie("$cookpre\_un",$username,$exp);
		SetCookie("$cookpre\_pw",$password1,$exp);
		$url = $surl;
	}
	fopen(FILE,"$prefs/Active.txt");
	@active = <FILE>;
	fclose(FILE);
	chomp @active;
	fopen(FILE,"+>$prefs/Active.txt");
	foreach(@active) {
		($luser) = split(/\|/,$_);
		if($luser ne $ENV{'REMOTE_ADDR'}) { print FILE "$_\n"; }
	}
	fclose(FILE);
	if($logip) {
		$curtime = time;
		fopen(FILE,">>$prefs/IpLog.txt");
		print FILE "$username|1|$ENV{'REMOTE_ADDR'}|$curtime\n";
		fclose(FILE);
	}
	$redirectfix = 1;

	if($FORM{'redirect'}) { $url = "$surl$FORM{'redirect'}"; }

	redirect($url);
}

sub Logout {
	if($username eq 'Guest') { error($gtxt{'noguest'}.'-register-'); }

	if($sessionEnabled && !$sessionError) {
		my $session = new CGI::Session("driver:File", $Blah{"$cookpre\_session"}, {Directory=>"$prefs/Sessions"});

		$session->delete();
		SetCookie("$cookpre\_session",'','Sat, 31-Dec-2039 00:00:00 GMT');
	}

	SetCookie("$cookpre\_un",'','Sat, 31-Dec-2039 00:00:00 GMT');
	SetCookie("$cookpre\_pw",'','Sat, 31-Dec-2039 00:00:00 GMT');

	# Log last THREE logins for later board use ...
	if($Blah{"$cookpre\_Logout1"} eq $username || $Blah{"$cookpre\_Logout2"} eq $username || $Blah{"$cookpre\_Logout3"} eq $username) { $skip = 1; }
	for($x = 1; $x < 3; ++$x) {
		if($skip) { last; }
		if(!$Blah{"$cookpre\_Logout$x"}) {
			SetCookie("$cookpre\_Logout$x",$username,'Sat, 31-Dec-2039 00:00:00 GMT');
			last;
		}
	}

	fopen(FILE,"$prefs/Active.txt");
	@active = <FILE>;
	fclose(FILE);
	fopen(FILE,"+>$prefs/Active.txt");
	foreach (@active) {
		chomp;
		($luser) = split(/\|/,$_);
		if($luser ne $username) { print FILE "$_\n"; }
	}
	fclose(FILE);
	if($logip) {
		$curtime = time;
		fopen(FILE,">>$prefs/IpLog.txt");
		print FILE "$username|2|$ENV{'REMOTE_ADDR'}|$curtime\n";
		fclose(FILE);
	}
	$redirectfix = 1;
	$members{'Administrator',$username} = 0;
	$username = 'Guest';
	redirect($surl);
}

sub SendPassword {
	$title = $logintxt[5];
	header();
	$ebout .= <<"EOT";
<form action="$surl\lv-login/p-forgotpw2/" method="post">
<table class="border" cellpadding="5" cellspacing="1" width="450">
 <tr>
  <td class="titlebg"><strong>$logintxt[5]</strong></td>
 </tr><tr>
  <td class="win smalltext">$logintxt[29]</td>
 </tr><tr>
  <td class="win2">
  <table cellpadding="4" cellspacing="0" width="100%">
   <tr>
    <td class="right" style="width: 40%"><strong>$gtxt{'23'}:</strong></td>
    <td style="width: 60%"><input type="text" name="email" size="30" /></td>
   </tr>
  </table>
  </td>
 </tr><tr>
  <td class="win center"><input type="submit" name="submit" value=" $logintxt[31] " /></td>
 </tr>
</table>
</form>
EOT
	footer();
	exit;
}

sub SendPassword2 {
	fopen(FILE,"$members/List2.txt");
	@list = <FILE>;
	fclose(FILE);
	chomp @list;
	foreach(@list) {
		($un,$sn,$t,$t,$t,$mail) = split(/\|/,$_);
		if($mail eq $FORM{'email'}) { GetMemberID($un); $FORM{'username'} = $un; last; }
	}

	if($memberid{$un}{'sn'} eq '') { error($logintxt[62]); }

	if($memberid{$FORM{'username'}}{'forgotpass'} ne '') {
		($t,$oldtime) = split(/\|/,$memberid{$FORM{'username'}}{'forgotpass'});
		if($oldtime+43200 > time) { error($logintxt[47]); }
	}

	$randomsid = sprintf("%.0f",rand(int((time)/9)*7000));
	$forgotpass = $randomsid."|".time;

	SaveMemberID($FORM{'username'},%addtoID = ('forgotpass' => $forgotpass));

	$message = <<"EOT";
$logintxt[33] <a href="$rurl\lv-login/p-forgotpw3/uid-$FORM{'username'}/id-$randomsid/">$logintxt[48]</a>.

$logintxt[61]


$gtxt{'25'}



$logintxt[37] "$mbname", $logintxt[38]
EOT
	$warnonthis = qq~<body onload="javascript:window.alert('$logintxt[49]');">~;
	smail($memberid{$FORM{'username'}}{'email'},$logintxt[5],$message);
}

sub SendPassword3 {
	GetMemberID($URL{'uid'});
	if($memberid{$URL{'uid'}}{'forgotpass'} ne '') {
		($tempsid,$oldtime) = split(/\|/,$memberid{$URL{'uid'}}{'forgotpass'});
		if(($oldtime+43200 > time) && $tempsid eq $URL{'id'}) {
			$randomsid = sprintf("%.0f",rand(int(time/9)*8000));

			$randomsid = substr($randomsid,0,7); # Limit new pass to 7 characters ...

			$passwordf = $randomsid;
			$memberid{$username}{'md5upgrade'} = 1;
			if($yabbconver) { $passwordf = Encrypt($randomsid); }

			SaveMemberID(
				$URL{'uid'},
				%addtoID = (
					'forgotpass' => '',
					'md5upgrade' => 1,
					'password'   => $passwordf
				)
			);
		} else { error($logintxt[51]); }
	} else { error($logintxt[51]); }
	$message = <<"EOT";
$logintxt[50]

<strong>$logintxt[34]</strong> $randomsid
<strong>$logintxt[36]</strong> $memberid{$URL{'uid'}}{'sn'}


$gtxt{'25'}


$logintxt[37] "$mbname", $logintxt[38]
EOT
	$warnonthis = qq~<body onload="javascript:window.alert('$logintxt[52]');">~;
	smail($memberid{$URL{'uid'}}{'email'},$logintxt[5],$message);
}

sub ChangePass {
	$ebout .= <<"EOT";
<form action="$surl\lv-memberpanel/a-save/as-profile/s-pw/u-$username/" method="post" enctype="multipart/form-data">
<table cellpadding="5" cellspacing="1" class="border" width="100%">
 <tr>
  <td class="titlebg">$logintxt[56]</td>
 </tr><tr>
  <td class="win smalltext">$logintxt[57]</td>
 </tr><tr>
  <td class="catbg smalltext center"><strong>$logintxt[56]</strong></td>
 </tr><tr><td class="win center"><table cellspacing="0" cellpadding="3" width="100%"><tr>
  <td style="width: 25%" class="right" rowspan="2"><strong>$logintxt[58]: </strong></td>
  <td style="width: 25%" class="win2 center" rowspan="2"><input type="password" name="oldpw" size="25" /></td>
  <td style="width: 25%" class="right"><strong>$logintxt[59]: </strong></td>
  <td style="width: 25%" class="win2 center"><input type="password" name="newpw" size="25" maxlength="20" /></td>
 </tr><tr>
  <td style="width: 25%" class="right"><strong>$gtxt{'24'}: </strong></td>
  <td style="width: 25%" class="win2 center"><input type="password" name="newpwc" size="25" maxlength="20" /></td>
 </tr></table></td>
 </tr><tr>
  <td class="win2 center"><input type="hidden" name="caller" value="2" /><input type="submit" value="$logintxt[56]" /></td>
 </tr>
</table>
</form><br />
EOT
}
1;