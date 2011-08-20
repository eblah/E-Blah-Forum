#############################################
# E-Blah Bulletin Board Systems        2008 #
#############################################
# Copyright (c) 2001 - 2008 E-Blah.         #
#############################################

CoreLoad('BoardLock',1);

sub MainLO {
	if($URL{'v'} eq 'shownews') { return; }
	if(-e("$root/Maintance.lock")) { require("$root/Maintance.lock"); }
	if($URL{'id'} ne '' && $URL{'v'} eq 'invite') { CoreLoad('Invite'); LinkMeUp(); }
	if($maintance && !$members{'Administrator',$username}) { Maintain(); }
	if($lockout) {
		fopen(FILE,"$members/$username.lo");
		@lock = <FILE>;
		fclose(FILE);
		chomp @lock;
		if($lock[0] eq 'ALLOW') { 1; }
		elsif($lock[0] eq 'TEMP') {
			($for,$long) = split(/\|/,$lock[1]);
			$time = $for*60;
			$maxtime = $long+$time;
			$thistime = time;
			$allowed = $maxtime-$thistime;
			if($allowed > 0) { 1; }
			elsif($URL{'v'} ne 'login' && $URL{'p'} != 2) { LockOut(); }
		}
		elsif($URL{'v'} eq 'login' && $URL{'p'} == 2) { return; }
		else { LockOut(); }
	}
	elsif($noguest && ($username eq 'Guest' || $memberid{$username}{'sn'} eq '')) { KickGuest(); }
		else { return; }
}

sub Password {
	if($members{'Administrator',$username}) { return; } # Admin has full access
	is_member();
	if($Blah{"$cookpre\_$URL{'b'}_pw"} eq $binfo[6]) { return; }
	elsif($sidinuse) {
		@boardaccess = split("/",$baccess);
		foreach(@boardaccess) {
			($board,$pass) = split("=",$_);
			if($board eq $URL{'b'} && $pass eq $binfo[6]) { return; }
		}
	}
	$password = crypt($FORM{'pw'},$pwcry);
	$password =~ s/\///g;
	if($password eq $binfo[6]) { # SIDs: Skip the cookies and add a password handle.
		if($sessionEnabled) {
			$session->param("$cookpre\_$URL{'b'}_pw",$password);
			$session->expire("$cookpre\_$URL{'b'}_pw",'+3h');
		} else { SetCookie("$cookpre\_$URL{'b'}_pw",$password,"temp"); }
		return;
	}
	elsif($FORM{'pw'}) { $in = qq~<br />&nbsp;<strong>&#149; $boardlock[2]</strong>~; }
	$title = $boardlock[3];
	header();
	$message = $binfo[0];
	$message =~ s/&#47;/\//gsi;
	$message = BC($message);
	$ebout .= <<"EOT";
<form action="$surl\lb-$URL{'b'}/" method="post">
<table class="border" cellpadding="4" cellspacing="1" width="450">
 <tr>
  <td class="titlebg"><strong>$title</strong></td>
 </tr><tr>
  <td class="win smalltext">$boardlock[4]$in</td>
 </tr><tr>
  <td class="win2">
   <table cellpadding=2 cellspacing=0 width="100%">
    <tr>
     <td class="right vtop"><strong>$boardlock[5]:</strong></td>
     <td><strong>$binfo[2]</strong><div class="smalltext">$message</div></td>
    </tr><tr>
     <td class="right" style="width: 40%"><strong>$boardlock[6]:</strong></td>
     <td style="width: 60%"><input type="password" name="pw" size="25" /></td>
    </tr>
   </table>
  </td>
 </tr><tr>
  <td class="win center"><input type="submit" value=" $gtxt{'26'} " /></td>
 </tr>
</table>
</form>
EOT
	footer();
	exit;
}

sub KickGuest {
	$gdisable = 1;
	if($URL{'v'} eq 'login') { CoreLoad('Login'); Login(); }
	if($URL{'v'} eq 'register') { CoreLoad('Register'); Register(); }
	$title = $mbname;
	header();
	if($creg != 1) { $register = qq~\n  <br />&nbsp; &#187; <a href="$surl\lv-register/" rel="nofollow">$boardlock[7]</a>~; }
	if($username eq 'Guest') { $access = qq~$boardlock[35]<br /><br /><center><strong>$rtxt[3] <a href="$surl\lv-login/" rel="nofollow">$rtxt[4]</a> $rtxt[44] <a href="$surl\lv-register/" rel="nofollow">$rtxt[5]</a>.</strong></center>~; }
		else { $access = $boardlock[9]; }
	$ebout .= <<"EOT";
<table class="border" cellspacing="1" cellpadding="4" width="500">
 <tr>
  <td class="titlebg"><strong><img src="$images/ban.png" alt="" /> $boardlock[10]</strong></td>
 </tr><tr>
  <td class="win">$access</center></td>
 </tr>
</table>
EOT
	footer();
	exit;
}

sub Maintain {
	$gdisable = 1;
	if($URL{'v'} eq 'login' && $URL{'p'} == 2) { return; }

	$title = "$mbname $boardlock[11]";
	header();
	$ebout .= <<"EOT";
<table class="border" cellpadding="5" cellspacing="1" width="750">
 <tr>
  <td class="titlebg">$title</td>
 </tr><tr>
  <td class="win">
   <table cellpadding="5" cellspacing="0" width="100%">
    <tr>
     <td class="vtop center" style="width: 30px"><img src="$images/error.png" alt="" /></td>
     <td>$boardlock[12]<blockquote style="padding: 10px" class="win2">$maintancer</blockquote></td>
    </tr>
   </table>
  </td>
 </tr><tr>
  <td class="win2 smalltext right" style="padding: 8px;"><a href="mailto:$eadmin">$rtxt[50]</a></td>
 </tr>
</table>
<br />
<form action="$surl\lv-login/p-2/" method="post">
<table class="border" cellpadding="4" cellspacing="1" width="750">
 <tr>
  <td class="titlebg" colspan=2><strong>$boardlock[13] $boardlock[8]</strong></td>
 </tr><tr>
  <td class="win">
   <table cellpadding=3 width=100%>
    <tr>
     <td class="right" style="width: 25%"><strong>$boardlock[15]:</strong></td>
     <td style="width: 25%"><input type="text" name="username" size="20" /></td>
     <td class="right"><strong>$boardlock[16]:</strong></td>
     <td><input type="checkbox" name="nocookie" value="1" /></td>
    </tr><tr>
     <td class="right"><strong>$boardlock[6]:</strong></td>
     <td><input type="password" name="password" size="20" /></td>
     <td class="right"><strong>$boardlock[18]:</strong></td>
     <td><select name="days">
      <option value=".5">12 $gtxt{'3'}</option>
      <option value="1">1 $boardlock[19]</option>
      <option value="4">4 $boardlock[19]</option>
      <option value="7">1 $gtxt{'39'}</option>
      <option value="31">1 $gtxt{'40'}</option>
      <option value="forever" selected="selected">$boardlock[21]</option>
     </select>&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; <input type="submit" value="&nbsp;&nbsp;$boardlock[8]&nbsp;&nbsp;" />
     </td>
    </tr>
   </table>
  </td>
 </tr>
</table>
</form>
EOT
	footer();
	exit;
}

sub LockOut {
	$gdisable = 1;
	print "Content-type: text/html\n\n";
	print <<"EOT";
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN"
	"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
<head>
<title>$mbname $boardlock[23]</title>
<style type="text/css">
h3 {
	font-size: 18px;
	padding-top: 5px;
	margin-bottom: 15px;
}

.lockouttitle {
	padding: 10px;
	border: 2px solid #000000;
	background-color: #EEEEEE;
	font-size: 11px;
	margin-bottom: 4px;
}

.message {
	padding: 5px;
	padding-left: 10px;
	background-color: #FFFFFF;
	font-size: 11px;
	font-weight: normal;
	margin-top: 10px;
}

.textbox2 {
	padding: 12px;
	background-color: #F5F6BE;
	font-size: 11px;
	border: 2px #636363 solid;
}

.copyright {
	padding: 5px;
	padding-left: 10px;
	background-color: #FFFFFF;
	font-size: 9px;
	font-weight: normal;
	text-align: center;
	margin-top: 10px;
	line-height: 1.5;
}

a, a:link, a:active, a:visited, a:hover {
	text-decoration: underline;
	color          : #36383B;
	font-family    : Verdana, Helvetica;
	font-weight    : bold;
}

a:hover { color: #1A1016; }

body { font-family: Verdana; font-size: 9px; }
</style>
</head>

<body>
<form action="$surl\lv-login/p-2/" method="post">
<h3>$mbname $boardlock[23]</h3>

<div class="lockouttitle">$boardlock[24]</div>
<div class="textbox2">$boardlock[25]</div>
<div class="message">
 <strong>$boardlock[15]:</strong> <input type="text" name="username" size="25" value="$URL{'u'}" /><br />
 <strong>$boardlock[6]:</strong> <input type="password"  name="password" size="20" value="$URL{'p'}" /><br /><br />
 <input type="submit" value="&nbsp;&nbsp;$boardlock[8]&nbsp;&nbsp;" />
</div>
<div class="copyright">$mbname $boardlock[23]<br />$copyright</div>
</form>
</body>
</html>
EOT
	exit;
}

sub Banned {
	$btod = 0;
	$gdisable = 1;
	($banlimit,$bantime) = @_;
	if($banlimit && time < $bantime) { $timelimit = qq~[hr][size=9]$boardlock[30] [b]$banlimit $boardlock[19]\[/b]. $boardlock[32] [b]~.get_date($bantime).'.[/b][/size]'; }
	elsif($banlimit && time > $bantime) { # Unban this user, his banning is completed ...
		fopen(FILE,">$prefs/BanList.txt");
		foreach(@banlist) {
			($ipaddy,$banlimit,$bantime) = split(/\|/,$_);
   			$length = length($ipaddy);
   			$ipsearch = substr($ENV{'REMOTE_ADDR'},0,$length);
			if($ipsearch =~ /\Q$ipaddy/i || $username eq $ipaddy || $memberid{$username}{'email'} eq $ipaddy) { next; }
			print FILE "$_\n";
		}
		fclose(FILE);
		return;
	}
	$time = time;
	@settings = ();
	fopen(FILE,"+>>$prefs/NoAccess.txt");
	print FILE "$username|$ENV{'REMOTE_ADDR'}|$time\n";
	fclose(FILE);
	$username = 'Guest'; # Reset to guest
	error("$boardlock[34]$timelimit",3);
}

sub UserLockOut {
	my($errorname);

	if($memberid{$username}{'status'} eq 'EMAIL|ADMIN') { $errorname = $boardlock[36]; }
	elsif($memberid{$username}{'status'} eq 'EMAIL') { $errorname = $boardlock[37]; }
	elsif($memberid{$username}{'status'} eq 'ADMIN') { $errorname = $boardlock[38]; }
		else { $errorname = $boardlock[39]; }

	$ebout .= <<"EOT";
<table cellpadding="5" cellspacing="1" width="100%" class="border">
 <tr>
  <td class="win3"><img src="$images/noaccess.png" class="centerimg" alt="" /> $boardlock[40]</td>
 </tr>
  <td class="win2">$errorname</td>
 </tr>
</table>
<br />
EOT
}
1;