#############################################
# E-Blah Bulletin Board Systems        2008 #
#############################################
# Copyright (c) 2001 - 2008 E-Blah.         #
#############################################

{
	CoreLoad('Admin1',1);

	%LoadAdminIndex = (
		'bkup'      => 'Admin1,BoardBackup',
		'bkupstart' => 'Admin1,BKUPStart',
		'repop'     => 'Admin1,Repop',
		'temp'      => 'Admin1,Temp',
		'temp2'     => 'Admin1,Temp2',
		'iplog'     => 'Admin1,IPLog',
		'errorlog'  => 'Admin1,ErrorLog',
		'clicklog'  => 'Admin1,ClickLog',
		'remem'     => 'Admin1,Remem',
		'news'      => 'Admin1,News',
		'reserve'   => 'Admin1,Reserve',
		'encrypt'   => 'Admin1,EncryptPass',
		'sessions'  => 'Admin1,PurgeSessions',

		'sets'      => 'Admin2,Settings',
		'smiley'    => 'Admin2,Smiley',
		'delspec'   => 'Admin2,RemoveSpectators',
		'banlog'    => 'Admin2,BanLog',
		'ban'       => 'Admin2,BanUser',
		'censor'    => 'Admin2,Censor',
		'posts'     => 'Admin2,PostRecount',
		'posticons' => 'Admin2,PostIcons',

		'memgrps'       => 'Admin3,MemGrps',
		'mailing'       => 'Admin3,Mailing',
		'validate'      => 'Admin3,Validate',
		'removemembers' => 'Admin3,RemoveMembers',
		'removeelog'    => 'Admin3,RemoveELog',
		'acl'           => 'Admin3,ACL',
		#'extend'        => 'Admin3,ExtendProfile',

		'remove'    => 'Moderate,OldThreads',

		'portal'    => 'Portal,PortalAdmin',

		'themesman' => 'Themes,ThemeManager',
		'sourcemod' => 'SourceCodeMod,SourceMod',

		'attlog'    => 'Attach,AttachLog',

		'referals' => 'Invite,Referals',

		'boards'    => 'ManageForum,ManageBoards',
		'cats'      => 'ManageForum,ManageBoards',

		'tagrebuild' => 'Tags,RebuildTags',
	);

	%categories = (
		1 => "$admintxt[219]|mainconfig.png",
		2 => "$admintxt[51]|temps_themes.png",
		3 => "$admintxt[54]|memsetup.png",
		4 => "$admintxt[59]|memmaint.png",
		5 => "$admintxt[64]|boardmaint.png",
		6 => "$admintxt[68]|loggedinfo.png"
	);

	%subcategories = ( # Name | URL | Warning Level (1-highest; 2-mild; 3-low)
		1.1 => "$admintxt[16]|$surl\v-admin/a-sets/|1",
		1.2 => "$admintxt[43]|$surl\v-admin/a-boards/|1",
		1.3 => "$admintxt[44]|$surl\v-admin/a-smiley/",
		1.4 => "$admintxt[46]|$surl\v-admin/a-censor/",
		1.5 => "$admintxt[218]|$surl\v-admin/a-posticons/",
		1.6 => "$admintxt[168]|$surl\v-admin/a-portal/|3",
		1.7 => "$admintxt[49]|$surl\v-admin/a-news/",
		1.8 => "$admintxt[50]|$surl\v-admin/a-sourcemod/|1",

		2.1 => "$admintxt[47]|$surl\v-admin/a-themesman/|2",
		2.2 => "$admintxt[52]|$surl\v-admin/a-temp/|3",

		3.1 => "$admintxt[55]|$surl\v-admin/a-memgrps/|1",
		3.2 => "$admintxt[58]|$surl\v-admin/a-mailing/|2",
		3.3 => "$admintxt[62]|$surl\v-admin/a-removemembers/|1",
		3.4 => "$admintxt[45]|$surl\v-admin/a-ban/|3",
		3.5 => "$admintxt[63]|$surl\v-admin/a-validate/|",
		3.6 => "$admintxt[185]|$surl\v-register/",
		#3.7 => "$admintxt[220]|$surl\v-admin/a-extend/",

		4.1 => "$admintxt[60]|javascript:clear('$surl\v-admin/a-remem/')",
		4.2 => "$admintxt[61]|$surl\v-admin/a-delspec/|1",
		4.3 => "$admintxt[171]|$surl\v-admin/a-reserve/",
		4.4 => "$admintxt[160]|javascript:clear('$surl\v-admin/a-posts/','','$admintxt[159]')",
		4.5 => "$admintxt[222]|$surl\v-admin/a-sessions/",
		4.6 => "$admintxt[184]|$surl\v-admin/a-encrypt/|2",

		5.1 => "$admintxt[65]|$surl\v-admin/a-repop/|3",
		5.2 => "$admintxt[66]|$surl\v-admin/a-bkup/|2",
		5.3 => "$admintxt[67]|$surl\v-admin/a-remove/|1",
		5.4 => "Rebuild Tags|$surl\v-admin/a-tagrebuild/",

		6.1 => "$admintxt[69]|$surl\v-admin/a-attlog/|1",
		6.2 => "$admintxt[70]|$surl\v-admin/a-banlog/|3",
		6.3 => "$admintxt[71]|$surl\v-admin/a-clicklog/|3",
		6.4 => "$admintxt[72]|$surl\v-admin/a-errorlog/|3",
		6.5 => "$admintxt[73]|$surl\v-admin/a-iplog/",
		6.6 => "$admintxt[74]|$surl\v-admin/a-referals/"
	);
}

sub AdminList { # This file servers the purpose of quickly loading the admin center, with little wait and CPU
	my($core,$sub);
	if($URL{'a'} eq 'verify') { VerifyAdmin(); }
	is_admin();

	if($URL{'r'} ne '') { $URL{'a'} = 'main'; }

	$adminsloaded = 1;
	if($LoadAdminIndex{$URL{'a'}}) {
		($core,$sub) = split(',',$LoadAdminIndex{$URL{'a'}});
		CoreLoad($core);
		&$sub;
	} else {
		CoreLoad('Admin1');
		AdminMain();
	}
}

sub headerA {
	if($hdone) { return; }

	if($ENV{'HTTP_ACCEPT_ENCODING'} !~ /gzip/ && $gzipen) { $gzipen = 0; } # Browser doesn't support gzip =(
	if($gzipen) { print "Content-Encoding: gzip\n"; }

	if($xhtmlct && $ENV{'HTTP_ACCEPT'} =~ /application\/xhtml\+xml/) {
		print "Content-type: application/xhtml+xml; charset=$char\n\n";
	} else {
		print "Content-type: text/html; charset=$char\n\n";
	}

	$hdone = 1; # This is so we get no errors!

	if($templatesu eq '') { $templatesu = "/blahdocs/template"; }

	$ebout .= <<"EOT";
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN"
	"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
<head>
<link rel="stylesheet" type="text/css" href="$templatesu/$dtheme/admintemplate.css" />
<meta http-equiv="Content-Type" content="text/html; charset=$char" />
<title>$title</title>
<!--[if lt IE 7.]>
<script defer="defer" type="text/javascript" src="$bdocsdir/pngfix.js"></script>
<![endif]-->
</head>
<body>
<table cellpadding="6" cellspacing="0" width="100%">
 <tr>
  <td class="titlebg" colspan="3">
   <div style="float: left"><strong><img src="$images/admin_sm.png" class="leftimg" alt="" /> $admintxt[187]</strong></div>
   <div class="smalltext" style="float: right">E-Blah $versioncr</div>
  </td>
 </tr><tr class="win">
  <td class="menubar" style="width: 25%"><a href="$surl" onclick="target='_parent';">$Mimg{'home'}</a></td>
  <td style="width: 50%" class="center"><img src="$images/restriction.png" class="leftimg" alt="" /><img src="$images/restriction.png" class="rightimg" alt="" />$date_time</td>
  <td style="width: 25%" class="right menubar"><a href="$surl\v-login/p-3/" onclick="if(window.confirm('$rtxt[65]')) { parent.location = '$surl\lv-login/p-3/'; } return false;">$Mimg{'logout'}</a></td>
 </tr>
</table>
<div class="border">&nbsp;</div>
<div style="padding: 10px;">
<script type="text/javascript">
//<![CDATA[
function clear(url,url2,explain) {
 if(!explain) { explain = "$admintxt[7]"; }
 if(window.confirm(explain)) { location = url; }
  else {
   if(url2) { location = url2; }
  }
}
//]]>
</script>

   <table cellpadding="0" cellspacing="0" width="100%">
    <tr>
     <td class="vtop" style="width: 225px">
      <table cellpadding="2" class="border" cellspacing="1" width="100%">
       <tr>
        <td class="win2 center" style="padding: 0">
         <img src="$images/eblahlogo.png" style="padding: 10px" alt="" /><br />
	     <div class="win3">
          <br /><div><img src="$images/restriction.png" class="centerimg" alt="" /> <a href="$surl\v-admin/a-main/">$admintxt[187]</a></div><br />
          <div><img src="$images/site_sm.gif" class="centerimg" alt="" /> <a href="$surl">$admintxt[188]</a></div><br />
	     </div>
       </td>
      </tr><tr>
       <td>
        <table cellpadding="5" cellspacing="0" class="border" width="100%" id="mm">
EOT

		for($x = 1; $x <= 6; $x++) {
			($name,$image) = split(/\|/,$categories{$x});
			if(!$members{'Administrator',$username}) {
				foreach(@myacls) { if($x-.9 < $_ && $x+.9 > $_) { $show = 1; last; } }
				next if(!$show);
			}
			$ebout .= <<"EOT";
<tr>
 <td class="catbg"><img src="$images/admincenter/$image" class="centerimg" alt="" /> <strong>$name</strong></td>
</tr><tr>
 <td class="win smalltext"><strong>
EOT
			for($y = $x+.1; $y <= $x+1; $y = $y+.1) {
				if($subcategories{$y} eq '') { next; }
				if(!$acl{$y} && !$members{'Administrator',$username}) { next; }
				($name,$url) = split(/\|/,$subcategories{$y});
				$ebout .= <<"EOT";
<a href="$url">$name</a><br />
EOT
			}
			$ebout .= <<"EOT";
 </strong></td>
</tr>
EOT
			$show = 0;
		}

		$ebout .= <<"EOT";
     </table>
    </td>
   </tr>
  </table>
 </td>
 <td>&nbsp;</td>
 <td class="vtop">
EOT

}

sub footerA {
	$ebout .= <<"EOT";
 </td>
 </tr>
</table>
</div>
<div class="smalltext"><br />$copyright<br /><br /></div>
</body>
</html>
EOT
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

sub VerifyAdmin { # Verify's user is a moderator or Administrator with Password Verification
	if($FORM{'passver'} ne '') {
		$password1 = Encrypt(Format($FORM{'passver'}));
		if($yabbconver) { $password2 = $memberid{$username}{'password'}; } else { $password2 = Encrypt($memberid{$username}{'password'}); }
	}

	if(!$revalidate && !$FORM{'getvalid'}) {
		return(1) if($URL{'v'} eq 'memberpanel' && $URL{'a'} eq 'view');

		if($FORM{'passver'} ne '') {
			if($password1 eq $password2) {
				require Digest::MD5;
				import Digest::MD5 qw(md5_hex);
				$FORM{'verificate'} = md5_hex(Format($FORM{'verificate'}));
				if($memberid{$username}{'adminverify'} ne '' && $memberid{$username}{'adminverify'} ne $FORM{'verificate'}) {}
					else {
						$session->param('admin_login','1');
						$session->expire('admin_login',$FORM{'length'}); # Let's not kill the human. One password verify per three days ...
						if($memberid{$username}{'adminverify'} ne '') {
							$session->param('adminverify',$FORM{'verificate'});
							$session->expire('adminverify',$FORM{'length'});
						} else { $session->clear(["adminverify"]); }
						$session->flush();
						redirect("$surl$FORM{'location'}");
					}
			}
		}
		if($session->param('admin_login') && $session->param('adminverify') eq $memberid{$username}{'adminverify'}) { return(1); }
	} else {
		$getvalid = qq~<input type="hidden" value="1" name="getvalid" />~;
		if($FORM{'passver'} ne '') {
			if($password1 eq $password2) {
				require Digest::MD5;
				import Digest::MD5 qw(md5_hex);
				$FORM{'verificate'} = md5_hex(Format($FORM{'verificate'}));
				if($memberid{$username}{'adminverify'} ne '' && $memberid{$username}{'adminverify'} ne $FORM{'verificate'}) {}
					else {
						$verification = md5_hex(rand(time));

						$addtoID{'verifyquick'} = $verification;
						$addtoID{'verifyage'} = time;
						SaveMemberID($username);

						redirect("$surl$FORM{'location'}\lverify-$verification/");
					}
			}
		}
	}

	if($FORM{'location'} ne '') {
		$ENV{'QUERY_STRING'} = $FORM{'location'};
	}
	$ENV{'QUERY_STRING'} =~ s~verify\-(.+?)\/~~sig;

	$title = $rtxt[71];
	header();
	$ebout .= <<"EOT";
<form action="$surl\lv-admin/a-verify/" method="post">
<table cellpadding="6" cellspacing="1" class="border" width="400">
 <tr>
  <td class="titlebg">$title</td>
 </tr><tr>
  <td class="win"><img src="$images/admincenter/sessions.png" class="centerimg" /> $rtxt[72]</td>
 </tr><tr>
  <td class="catbg smalltext"><strong>$rtxt[73]</strong></td>
 </tr><tr>
  <td class="win2 center"><input type="password" name="passver" style="width: 360px" />$getvalid</td>
 </tr>
EOT
	if($memberid{$username}{'adminverify'}) {
		$ebout .= <<"EOT";
 <tr>
  <td class="catbg smalltext"><strong>$rtxt[79]</strong></td>
 </tr><tr>
  <td class="win2 center"><input type="password" name="verificate" style="width: 360px" /></td>
 </tr>
EOT
	}
	if(!$revalidate) {
		$ebout .= <<"EOT";
 <tr>
  <td class="catbg smalltext"><strong>$rtxt[74]</strong></td>
 </tr><tr>
  <td class="win2 center"><select name="length" style="width: 360px;"><option value="6h">6 $rtxt[75]</option><option value="24h">24 $rtxt[75]</option><option value="72h" selected="selected">3 $rtxt[76]</option><option value="1w">1 $rtxt[77]</option><option value="2w">2 $rtxt[77]</option><option value="1M">1 $rtxt[78]</option></select></td>
 </tr>
EOT
	}
	$ebout .=<<"EOT";
 <tr>
  <td class="center win3"><input type="hidden" name="location" value="$ENV{'QUERY_STRING'}" /><input type="submit" value="$rtxt[71]" /></td>
 </tr>
</table>
</form>
EOT
	footer();
	exit;
}
1;