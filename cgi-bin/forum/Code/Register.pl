#############################################
# E-Blah Bulletin Board Systems        2008 #
#############################################
# Copyright (c) 2001 - 2008 E-Blah.         #
#############################################

CoreLoad('Register',1);

push(@INC,"$root");

sub Register {
	$gdisable = 1;
	if($URL{'p'} eq 'resend') { ResendVerification(); }

	if($URL{'a'} eq 'validate') { Validate(); }
	elsif($URL{'p'} eq 'finish') { Finish(); }
	if($username ne 'Guest' && (!$members{'Administrator',$username} && !@myacl)) { error($registertxt[1]); }
	if($members{'Administrator',$username} || @myacl) {
		$quickreg = 0;
		$oldform = ' checked="checked"';
		$vradmin = 0;
		$creg = 0;
		CoreLoad('AdminList');
		is_admin(3.6);
	}
	if($creg) { error($registertxt[2]); }
	if($URL{'p'} eq 'check') { UserCheck(); }
	elsif($URL{'p'} == 1) { Register2(); }
	elsif($URL{'p'} == 2) { Register3(); }
		else { RegisterOkay(); }
}

sub RegisterOkay {
	if(!$quickreg) { Register2(); }

	# Lame way ... count for the leap years ....
	use Time::Local 'timelocal';
	($sec,$min,$hour,$day,$month,$year) = localtime(time);
	$yearz = $year-13;
	eval { $oldie = timelocal($sec,$min,$hour,$day,$month,$yearz); };
	($sec,$min,$hour,$day,$mu,$year,$week) = localtime($oldie);
	$date = "$months[$mu] $day, ".(1900+$year);
	$title = $registertxt[3];
	header();
	$ebout .= <<"EOT";
<table cellspacing="1" cellpadding="5" class="border" width="600">
 <tr>
  <td colspan="2" class="titlebg"><strong>$title</strong></td>
 </tr><tr>
  <td class="win postbody">$registertxt[4]</td>
 </tr><tr>
  <td class="win2 center" style="padding: 10px"><span style="float: left"><a href="$surl">$registertxt[6] $date</a></span><span style="float: right"><a href="$surl\lv-register/p-1/" rel="nofollow">$registertxt[5] $date</a></span></td>
 </tr>
</table>
EOT
	footer();
	exit;
}

sub UserCheck {
	print "Content-type: text/html\n\n";

	$URL{'u'} =~ s/%([a-fA-F0-9]{2,2})/chr(hex($1))/eg;

	$formusername = lc($URL{'u'});
	$formusername =~ s/ |_//g;

	if($formusername eq 'guest' || $formusername eq 'mods' || $formusername eq 'ma' || $formusername eq 'admin') { $unerror = 1; }
	fopen(FILE,"$prefs/Names.txt");
	while(<FILE>) {
		chomp $_;
		($searchme,$within) = split(/\|/,$_);
		$searchme = lc($searchme);
		$searchme =~ s/ |_//g;
		if($within) { $unerror = 1 if($formusername =~ /\Q$searchme\E/gsi); }
			else { $unerror = 1 if($searchme eq $formusername); }
	}
	fclose(FILE);

	$unerror = 1 if($URL{'u'} !~ /\A[0-9A-Za-z%+,\.@†^_ ]+\Z/);

	fopen(FILE,"$members/List2.txt");
	while(<FILE>) {
		($t,$sn) = split(/\|/,$_);
		$memset = lc($sn);
		$memset =~ s/ |_//g;
		if($memset eq $formusername) { $unerror = 1; }
	}
	fclose(FILE);
	if(!$unerror && $URL{'u'} ne '') { print qq~<span class="greenrep">$registertxt[69]</span>~; }
		else { print qq~<span class="redrep">$registertxt[31]</span>~; }
	exit;
}

sub Register2 {
	$title = $registertxt[3];
	if($members{'Administrator',$username} || @myacl) { headerA(); } else { header(); }

	$ebout .= <<"EOT";
<script src="$bdocsdir/common.js" type="text/javascript"></script>

<script type="text/javascript">
//<![CDATA[
function check() {
 box = eval(document.forms['register'].agree);
 box.checked = !box.checked;
}

function escape2(val) {
	val = escape(val);
	val = val.replace(new RegExp("-"), "%2D");
	return val;
}
//]]>
</script>
$error
<form action="$surl\lv-register/p-2/" id="register" method="post">
<table cellspacing="1" cellpadding="5" class="border" width="100%">
 <tr>
  <td class="titlebg"><strong>$title</strong></td>
 </tr><tr>
  <td class="win smalltext" style="padding: 10px">$registertxt[8]</td>
 </tr><tr>
  <td class="catbg smalltext"><strong>$registertxt[9]</strong></td>
 </tr><tr>
  <td class="win2">
   <table cellpadding="7" cellspacing="0" width="100%">
    <tr>
     <td colspan="2"><strong>$registertxt[10]:</strong></td>
    </tr><tr>
     <td colspan="2"><input type="text" name="username" value="$FORM{'username'}" size="30" maxlength="30" onchange="javascript:EditMessage('$surl\v-register/p-check/u-' + escape2(this.value) + '/','','','usercheck');" /></td>
    </tr><tr>
     <td colspan="2"><div id="usercheck">&nbsp;</div></td>
    </tr><tr>
     <td class="win" style="width: 300px"><strong>$gtxt{'23'}:</strong></td>
     <td class="win"><strong>$registertxt[74]:</strong></td>
    </tr><tr>
     <td class="win" style="width: 300px"><input type="text" name="email" value="$FORM{'email'}" size="25" maxlength="40" /></td>
     <td class="win"><input type="text" name="validemail" size="25" maxlength="40" /></td>
    </tr><tr>
     <td class="win" colspan="2">$registertxt[11]</td>
    </tr><tr>
     <td><strong>$registertxt[12]:</strong></td>
     <td><strong>$gtxt{'24'}:</strong></td>
    </tr><tr>
     <td><input type="password"  name="pw" size="20" maxlength="$pwlength" /></td>
     <td><input type="password"  name="cpw" size="20" maxlength="$pwlength" /></td>
    </tr>
EOT

	if($nocomputers) {
		opendir(DIR,"$bdocsdir2/Random");
		@dir = readdir(DIR);
		closedir(DIR);
		foreach(@dir) {
			if($_ eq '.' || $_ eq '..') { next; }
			if((stat("$bdocsdir2/Random/$_"))[9]+3600 < time) { unlink("$bdocsdir2/Random/$_"); } # Delete random stuff every hour
		}

		require GD::SecurityImage;
		GD::SecurityImage->import;
		my $image = GD::SecurityImage->new(width => 200, height => 40, lines => 8, font => "$prefs/font.ttf", angle => 5, scramble => 1, rndmax => 6, ptsize => 14);

		$possible = '23456789ABCDFGJLMNPQRSTWXY23456789'; # Change this to add/remove chars from cap -- More numbers for more numb codes

		$temp1 = 0;
		while($temp1 < 6) { $randpasscode .= substr($possible, int(rand(length($possible))), 1); ++$temp1; }

		$image->random($randpasscode);

		require Digest::MD5;
		import Digest::MD5 qw(md5_hex);
		$datad = md5_hex($captcha_random . $image->random_str());

		$image->create(ttf,rect);
		$badimage = '<br />'.$@ if($image->gdbox_empty());
		@data = $image->out(force => 'png');

		open(FILE,">$bdocsdir2/Random/$datad.png");
		binmode FILE;
		print FILE @data;
		close(FILE);

		$ebout .= <<"EOT";
    <tr>
     <td class="win" colspan="2"><strong>$registertxt[72]:</strong></td>
    </tr><tr>
     <td class="win vtop"><input type="text" name="random" size="20" /><input type="hidden" name="randomconfirm" value="$datad" /></td>
     <td class="win"><img src="$bdocsdir/Random/$datad.png" width="200" height="40" alt="" />$badimage</td>
    </tr><tr>
     <td class="win" colspan="2">$registertxt[73]</td>
    </tr>
EOT
	}

	$ebout .= <<"EOT";
   </table>
  </td>
 </tr>
EOT
	if($showreg) {
		if($FORM{'username'} && $FORM{'agree'}) { $oldform = ' checked="checked"'; }
		fopen(FILE,"$prefs/RTemp.txt");
		@rtemp = <FILE>;
		fclose(FILE);
		chomp @rtemp;
		foreach(@rtemp) { $message .= $_; }
		$message = BC($message);
		$ebout .= <<"EOT";
 <tr>
  <td class="catbg smalltext"><strong>$registertxt[14]</strong></td>
 </tr><tr>
  <td class="win">
   <table cellpadding="4" cellspacing="0">
    <tr>
     <td>
	  <div class="border" style="padding: 1px;">
	   <div style="overflow: auto; width: 100%; height: 250px; margin: 0px;">
	    <div class="win" style="text-align: justify; padding: 8px;">$message</div>
	   </div>
	  </div><br />
      <div style="padding: 5px"><input type="checkbox" name="agree" value="1"$oldform /><span style="cursor:default;" onclick="check();"> <strong>$registertxt[15]</strong></span></div>
     </td>
    </tr>
   </table>
  </td>
 </tr>
EOT
	} else { $ebout .= qq~<input type="hidden" value="1" name="agree" />~; }
	$ebout .= <<"EOT";
 <tr>
  <td class="win" style="padding: 8px"><input type="submit" value="&nbsp;&nbsp;$registertxt[3]&nbsp;&nbsp;" /></td>
 </tr>
</table>
</form>
EOT
	if($members{'Administrator',$username} || @myacl) { footerA(); } else { footer(); }
	exit;
}

sub error_reg {
	my($error1) = $_[0];
	if(!$errorbuild) {
		$error = <<"EOT";
<table class="border" cellpadding="4" cellspacing="1" width="700">
 <tr>
  <td class="titlebg"><strong><img src="$images/ban.png" alt="" /> $registertxt[55]</strong></td>
 </tr><tr>
  <td class="win"><strong>$registertxt[56]</strong><div style="line-height: 140%"><ul>
EOT
	}
	if($error1 ne 'Finish') {
		if($ersal{$error1}) { return; }
		$ersal{$error1} = 1;
		$error .= "<li> $error1</li>";
	} else { $error .= qq~<ul></div><br /></td></tr></table><br />~;
		Register2();
	}
	$errorbuild = 1;
}

sub Register3 {
	my($defun);

	if(!$FORM{'agree'}) { error_reg($registertxt[65]); }

	while(($name,$value) = each(%FORM)) {
		$value =~ s/[\n\r]//g;
		$value =~ s/\A\s+//;
		$value =~ s/\s+\Z//;
		$FORM{$name} = $value;
	}

	# Yawn ... validate the user ... make sure they do not be bad ... (this was boring to code)
	error_reg($registertxt[18]) if($FORM{'username'} eq '');
	error_reg($registertxt[19]) if($FORM{'pw'} eq '');
	error_reg($registertxt[20]) if($FORM{'cpw'} eq '');
	error_reg($registertxt[21]) if($FORM{'email'} eq '');
	error_reg($registertxt[70]) if($FORM{'email'} ne $FORM{'validemail'});
	error_reg($registertxt[22]) if($FORM{'cpw'} ne $FORM{'pw'});

	error_reg($registertxt[23]) if(length($FORM{'username'}) > 30);
	error_reg($registertxt[24]) if(length($FORM{'pw'}) > $pwlength);
	error_reg($registertxt[25]) if(length($FORM{'email'}) > 60);

	$wantedname = $FORM{'username'};
	$formusername = lc($FORM{'username'});
	$formusername =~ s/ |_//g;

	error_reg("$registertxt[26] '$FORM{'username'}'.") if($formusername eq 'guest' || $formusername eq 'mods' || $formusername eq 'ma' || $formusername eq 'admin');
	fopen(FILE,"$prefs/Names.txt");
	while(<FILE>) {
		chomp $_;
		($searchme,$within) = split(/\|/,$_);
		$searchme = lc($searchme);
		$searchme =~ s/ |_//g;
		if($within) { error_reg("$registertxt[26] '$FORM{'username'}'.") if($formusername =~ /\Q$searchme\E/gsi); }
			else { error_reg("$registertxt[26] '$FORM{'username'}'.") if($searchme eq $formusername); }
	}
	fclose(FILE);

	error_reg($registertxt[27]) if($FORM{'username'} !~ /\A[0-9A-Za-z%+,\.@†^_ ]+\Z/);
	error_reg($registertxt[21]) if($FORM{'email'} !~ /\A([0-9A-Za-z\._\-]{1,})@([0-9A-Za-z\._\-]{1,})+\.([0-9A-Za-z\._\-]{1,})+\Z/);

	if($nocomputers) {
		require Digest::MD5;
		import Digest::MD5 qw(md5_hex);
		$datad = md5_hex($captcha_random . uc($FORM{'random'}));
		error_reg($registertxt[71]) if($datad ne $FORM{'randomconfirm'} || !-e("$bdocsdir2/Random/$datad.png"));
		unlink("$bdocsdir2/Random/$datad.png","$bdocsdir2/Random/$FORM{'randomconfirm'}.png");
	}

	fopen(FILE,"$prefs/BanList.txt");
	@banlist = <FILE>;
	fclose(FILE);
	chomp @banlist;
	foreach (@banlist) {
		($banstring) = split(/\|/,$_);
		if($banstring eq $FORM{'email'}) { error_reg($registertxt[21]); }
	}

	$formusername =~ s/\ //gsi;
	fopen(FILE,"$members/List2.txt");
	@membero = <FILE>;
	fclose(FILE);
	chomp @membero;
	foreach(@membero) {
		($un,$sn,$t,$t,$t,$mail) = split(/\|/,$_);
		$mymail = lc($FORM{'email'});
		$mail = lc($mail);
		$memset = lc($sn);
		$memset =~ s/ |_//g;
		if($memset eq $formusername) { error_reg($registertxt[31]); }
		if($mymail eq $mail) { error_reg($registertxt[32]); }
	}
	if($errorbuild) { error_reg('Finish'); }

	$curtime = time;
	if($md5upgrade) { $memberid{$username}{'md5upgrade'} = 1; }
	if($yabbconver) { $FORM{'pw'} = Encrypt($FORM{'pw'}); }

	# Find a new member ID
	fopen(ADD,"+<$members/MaxMember.count") || fopen(ADD,">$members/MaxMember.count");
	$curnumber = <ADD> || 0;
	chomp $curnumber;
	seek(ADD,0,0);
	truncate(ADD,0);
	$viewcnt = $curnumber+1;
	print ADD $viewcnt,"\n";
	fclose(ADD);

	if(-e("$members/$curnumber.dat") || $curnumber == 0) {
		++$curnumber if($curnumber == 0);
		while(-e("$members/$curnumber.dat")) { ++$curnumber; }

		fopen(ADD,">$members/MaxMember.count");
		print ADD "$curnumber\n";
		fclose(ADD);
	}

	if($vradmin) {
		$formid = sprintf("%.0f",rand(int((time)/9)*7000));
		if($vradmin == 2) { $extra = "$registertxt[33]\n"; }
			else { $extra = $registertxt[34]; }
		$message = <<"EOT";
$registertxt[35] $mbname!

$registertxt[36] $mbname, $registertxt[54] $extra

$registertxt[37]:
<a href="$rurl\lv-register/a-validate/id-$formid/u-$curnumber/">$rurl\lv-register/a-validate/id-$formid/u-$curnumber/</a>

$gtxt{'25'}!
EOT
		smail($FORM{'email'},$registertxt[38],$message,$registertxt[39]);
	} else {
		smail($FORM{'email'},$registertxt[45],"$registertxt[66] $mbname.  $registertxt[67]:<br /><br /><strong>$registertxt[10]:</strong> $wantedname<br />$gtxt{'23'}: $FORM{'email'}<br /><br />$registertxt[68]");
	}

	if($emailadmin) { smail($eadmin,$registertxt[64],"$registertxt[63]<br /><br />$registertxt[10]: $wantedname<br />$gtxt{'23'}: $FORM{'email'}<br />$gtxt{'18'}: $ENV{'REMOTE_ADDR'}"); }

	if($vradmin == 1) { $vradmin = "EMAIL"; }
	elsif($vradmin == 2) { $vradmin = "EMAIL|ADMIN"; }
		else { $vradmin = 0; }

	SaveMemberID(
		$curnumber,
		%addtoID = (
			'password'   => $FORM{'pw'},
			'sn'         => $wantedname,
			'email'      => lc($FORM{'email'}),
			'posts'      => 0,
			'registered' => $curtime,
			'timezone'   => $gtzone || 0,
			'status'     => $vradmin,
			'validation' => $formid,
			'md5upgrade' => 1
		)
	);

	fopen(FILE,">>$members/List.txt");
	print FILE "$curnumber\n";
	fclose(FILE);
	fopen(FILE,"$members/LastMem.txt");
	@latestmems = <FILE>;
	fclose(FILE);
	chomp @latestmems;
	++$latestmems[1];
	fopen(FILE,">$members/LastMem.txt");
	print FILE "$curnumber\n$latestmems[1]\n";
	fclose(FILE);

	fopen(FILE,">>$members/List2.txt");
	print FILE "$curnumber|$wantedname|0|$curtime||$FORM{'email'}|0\n";
	fclose(FILE);

	# Mark all them posts as read!
	$defun = $username;
	$username = $curnumber;
	$URL{'l'} = 'bindex';
	Mark();

	$username = $defun;

	if($uextlog) { ++$ExtLog[3]; ExtClose(); }

	if($members{'Administrator',$username}) { $url = "$surl\lv-admin/r-3/"; }
		else { $url = "$surl\lv-register/p-finish/u-$curnumber/"; }

	redirect();
}

sub Finish {
	if($vradmin) { $extra = qq~$registertxt[59]~; }
	if($vradmin == 2 && $username eq 'Guest') { $extra .= qq~<hr />$registertxt[60]~; }
	$title = $registertxt[45];
	header();
	$ebout .= <<"EOT";
<table class="border" cellpadding="4" cellspacing="1" width="500">
 <tr>
  <td class="titlebg"><strong><img src="$images/register_sm.gif" alt="" /> $title</strong></td>
 </tr><tr>
  <td class="win"><table cellspacing="0" cellpadding="5"><tr><td class="smalltext">$registertxt[58] $extra</td></tr></table></td>
 </tr><tr>
  <td class="win2"><strong>&nbsp;<a href="$surl\lv-login/u-$URL{'u'}/" rel="nofollow">$registertxt[46]</a></strong></td>
 </tr>
</table>
EOT
	footer();
	exit;
}

sub Validate {
	$usernameb = $URL{'u'};

	GetMemberID($usernameb);

	if($memberid{$usernameb}{'status'} eq 'ADMIN') { error($registertxt[48]); }
	elsif($memberid{$usernameb}{'status'} != 0) { error($registertxt[49]); }
	if($memberid{$usernameb}{'validation'} ne $URL{'id'}) { error($registertxt[50]); }

	if($memberid{$usernameb}{'status'} eq "EMAIL|ADMIN") { $changestatus = 'ADMIN'; }
		else { $changestatus = 0; }

	SaveMemberID($usernameb,%addtoID = ('status' => $changestatus, 'validation' => ''));

	if($vradmin == 2) { $message = $registertxt[62]; }
		else { $message = $registertxt[61]; }

	$title = $registertxt[52];
	header();
	$ebout .= <<"EOT";
<table class="border" cellpadding="4" cellspacing="1" width="500">
 <tr>
  <td class="titlebg"><strong><img src="$images/register_sm.gif" alt="" /> $title</strong></td>
 </tr><tr>
  <td class="win"><table cellspacing="0" cellpadding="5"><tr><td class="smalltext">$message</td></tr></table></td>
 </tr><tr>
  <td class="win2"><strong>&nbsp;<a href="$surl">$gtxt{'26'}</a></strong></td>
 </tr>
</table>
EOT
	footer();
	exit;
}

sub ResendVerification {
	is_admin();

	$usernameb = $URL{'u'};

	GetMemberID($usernameb);

	if($memberid{$usernameb}{'status'} == 2) { $extra = "$registertxt[33]\n"; }
		else { $extra = $registertxt[34]; }

	$message = <<"EOT";
$registertxt[35] $mbname!

$registertxt[36] $mbname, $registertxt[54] $extra

$registertxt[37]:
<a href="$rurl\lv-register/a-validate/id-$memberid{$usernameb}{'validation'}/u-$usernameb/">$rurl\lv-register/a-validate/id-$memberid{$usernameb}{'validation'}/u-$usernameb/</a>

$gtxt{'25'}!
EOT
	smail($FORM{'email'},$registertxt[38],$message,$registertxt[39]);

	$title = $registertxt[76];
	header();
	$ebout .= qq~<script type="text/JavaScript">//<![CDATA[ \nalert('$memberid{$usernameb}{'sn'} $registertxt[75]'); location = "$surl";\n //]]></script>~;
	footer();
	exit;
}
1;