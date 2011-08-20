#############################################
# E-Blah Bulletin Board Systems        2008 #
#############################################
# Copyright (c) 2001 - 2008 E-Blah.         #
#############################################

CoreLoad('Admin1',1);
CoreLoad('Admin2',1);

is_admin();

sub PostRecount {
	is_admin(4.4);

	foreach $use (@boardbase) {
		($board,$t,$t,$t,$t,$t,$t,$t,$t,$pcnt) = split('/',$use);
		if($pcnt) { next; }
		fopen(FILE,"$boards/$board.msg");
		while(<FILE>) {
			chomp $_;
			($id,$msub) = split(/\|/,$_);
			fopen(MESSAGE,"$messages/$id.txt");
			while( $buffer = <MESSAGE> ) {
				chomp $buffer;
				($user,$message,$ip,$t,$ptime) = split(/\|/,$buffer);
				++$posts{$user};
			}
			fclose(MESSAGE);
		}
		fclose(FILE);
	}
	fopen(FILE,"$members/List.txt") || error($admintxt2[304],1);
	while(<FILE>) {
		chomp $_;

		$posts{$_} = $posts{$_} || 0;

		SaveMemberID($_, %addtoID = ('posts' => $posts{$_}));
	}
	fclose(FILE);

	CoreLoad('Admin1');
	Remem();

	redirect("$surl\lv-admin/r-3/");
}

sub Smiley {
	is_admin(1.3);

	if($URL{'s'}) { Smiley2(); }
	$title = $admintxt2[5];
	headerA();
	$ebout .= <<"EOT";
<script type="text/javascript">
//<![CDATA[
function clear(url) {
 if(window.confirm("$admintxt2[4]")) { location = url; }
}
//]]>
</script>
<form action="$surl\lv-admin/a-smiley/s-1/" method="post"><input type="hidden" name="ok" value="ok" />
<table class="border" cellpadding="4" cellspacing="1" width="98%">
 <tr>
  <td class="titlebg" colspan="5"><strong><img src="$images/smiley.png" alt="" /> $title</strong></td>
 </tr><tr>
  <td class="catbg smalltext" colspan="2" style="width: 200px"><strong>$var{'44'}</strong></td>
  <td class="catbg smalltext" style="width: 250px"><strong>$admintxt2[7]</strong></td>
  <td class="catbg smalltext center" style="width: 200px"><strong>$admintxt2[231]</strong></td>
  <td class="catbg smalltext center" style="width: 50px"><strong>$admintxt2[8]</strong></td>
 </tr>
EOT
	fopen(FILE,"$prefs/smiley.txt");
	@smile = <FILE>;
	fclose(FILE);
	chomp @smile;
	$counter = 0;
	foreach (@smile) {
		($smiley,$url,$pack) = split(/\|/,$_);
		if($pack) { $packn = qq~$pack (<a href="$surl\lv-admin/a-smiley/s-1/p-$pack/o-1/">$admintxt2[229]</a>)~; }
			else { $packn = $admintxt2[157]; }
		$ebout .= <<"EOT";
 <tr>
  <td class="win2 center" style="width: 50px"><img src="$simages/$url" alt="" /></td>
  <td class="win center"><input type="text" name="smile_$counter" value="$smiley" size="25" /></td>
  <td class="win2 smalltext"><strong>smilies / <input type="text" name="url_$counter" value="$url" size="30" /><input type="hidden" name="pack_$counter" value="$pack" /></strong></td>
  <td class="win smalltext center"><strong>$packn</strong></td>
  <td class="win2 center"><input type="checkbox" name="del_$counter" value="1" /></td>
 </tr>
EOT
		++$counter;
	}
	if($smile[0] eq '') {
		$ebout .= <<"EOT";
<tr>
 <td class="win2 smalltext center" colspan="5"><br />$admintxt2[9]<br /><br /></td>
</tr>
EOT
	}

	opendir(DIR,"$modsdir/");
	@smiley = readdir(DIR);
	closedir(DIR);
	foreach(@smiley) {
		if($_ =~ m/(.*)(.smp)\Z/) {
			if(-e "$modsdir/$_.installed") { $action = qq~<a href="$surl\lv-admin/a-smiley/s-1/p-$1/o-1/">$admintxt2[229]</a>~; }
				else { $action = qq~<a href="$surl\lv-admin/a-smiley/s-1/p-$1/o-0/">$admintxt2[228]</a>~; }
			$smileypacks .= "<br /><strong>$1</strong> - $action";
		}
	}
	if(!$smileypacks) { $smileypacks = "<br />$admintxt2[227]"; }

	$ebout .= <<"EOT";
 <tr>
  <td class="catbg smalltext" colspan="5"><strong>$admintxt2[10]</strong></td>
 </tr><tr>
  <td class="win2 center" style="width: 50px"><img src="$images/question.png" alt="" /></td>
  <td class="win center" style="width: 150px"><input type="text" name="smile_new" size="25" /></td>
  <td class="win2 smalltext" colspan="3"><strong>smilies / <input type="text" name="url_new" size="30" /></strong></td>
 </tr><tr>
  <td class="win2 center" style="width: 50px"><img src="$images/smiley.png" alt="" /></td>
  <td class="win smalltext" colspan="4"><strong>$admintxt2[226]</strong>$smileypacks</td>
 </tr><tr>
  <td class="win2 center" colspan="5"><input type="hidden" name="cnt" value="$counter" /><input type="submit" name="submit" value=" $admintxt2[11] " /></td>
 </tr>
</table>
</form>
EOT
	footerA();
	exit;
}

sub Smiley2 {
	is_admin(1.3);

	fopen(FILE,"$prefs/smiley.txt");
	@data = <FILE>;
	fclose(FILE);
	chomp @data;
	if($URL{'p'}) { # Smiley packs
		if(!-e "$modsdir/$URL{'p'}.smp") { error($admintxt2[230]); }
		fopen(FILE,"$modsdir/$URL{'p'}.smp");
		@pack = <FILE>;
		fclose(FILE);
		chomp @pack;
		foreach (@pack) { $pak{"$_|$URL{p}"} = 1; }

		fopen(FILE,"+>$prefs/smiley.txt");
		foreach(@data) {
			if(!$pak{$_}) { print FILE "$_\n"; }
		}
		if(!$URL{'o'}) {
			foreach (@pack) { print FILE "$_|$URL{'p'}\n"; }
			fopen(FILE,">$modsdir/$URL{'p'}.smp.installed");
			fclose(FILE);
		} else { unlink("$modsdir/$URL{'p'}.smp.installed"); }
		fclose(FILE);
	} else { # Add / Delete / Edit Smileys
		while(($in,$out) = each(%FORM)) {
			$output = Format($out);
			if($output =~ s/"//gsi) { error($gtxt{'bfield'}); }
			$FORM{$in} = $output;
		}
		fopen(FILE,"+>$prefs/smiley.txt");
		for($i = 0; $i < $FORM{'cnt'}; $i++) {
			if(!$FORM{"del_$i"}) { print FILE qq~$FORM{"smile_$i"}|$FORM{"url_$i"}|$FORM{"pack_$i"}\n~; }
		}
		if($FORM{'smile_new'} ne '') {
			print FILE "$FORM{'smile_new'}|$FORM{'url_new'}\n";
		}
		fclose(FILE);
	}
	redirect("$surl\lv-admin/a-smiley/");
}

sub Settings {
	is_admin(1.1);

	$l = $URL{'l'};
	if($bversion != $theblahver) { $l = "all"; }
	if($URL{'s'} eq 'save') { Settings3(); }
	elsif($l ne '') { Settings2(); }
	$title = $admintxt2[12];
	headerA();
	$ebout .= <<"EOT";
<table class="border" cellpadding="8" cellspacing="1" width="600">
 <tr>
  <td class="titlebg" colspan="2"><strong><img src="$images/settings.gif" alt="" /> $title</strong></td>
 </tr><tr>
  <td class="win3 center" style="width: 40px"><img src="$images/admincenter/dirweb.png" alt="" /></td>
  <td style="padding: 0px" class="win"><div style="padding: 8px;"><strong><a href="$surl\lv-admin/a-sets/l-dir/">$admintxt2[13]</a></strong></div><div style="padding: 8px" class="win2 smalltext">$admintxt2[14]</div></td>
 </tr><tr>
  <td class="win3 center" style="width: 40px"><img src="$images/admincenter/essential.png" alt="" /></td>
  <td style="padding: 0px" class="win"><div style="padding: 8px;"><strong><a href="$surl\lv-admin/a-sets/l-ess/">$admintxt2[17]</a></strong></div><div style="padding: 8px" class="win2 smalltext">$admintxt2[18]</div></td>
 </tr><tr>
  <td class="win3 center" style="width: 40px"><img src="$images/admincenter/locked.png" alt="" /></td>
  <td style="padding: 0px" class="win"><div style="padding: 8px;"><strong><a href="$surl\lv-admin/a-sets/l-blk/">$admintxt2[19]</a></strong></div><div style="padding: 8px" class="win2 smalltext">$admintxt2[20]</div></td>
 </tr><tr>
  <td class="win3 center" style="width: 40px"><img src="$images/admincenter/attachments.png" alt="" /></td>
  <td style="padding: 0px" class="win"><div style="padding: 8px;"><strong><a href="$surl\lv-admin/a-sets/l-upl/">$admintxt2[21]</a></strong></div><div style="padding: 8px" class="win2 smalltext">$admintxt2[22]</div></td>
 </tr><tr>
  <td class="win3 center" style="width: 40px"><img src="$images/admincenter/forumstats.png" alt="" /></td>
  <td style="padding: 0px" class="win"><div style="padding: 8px;"><strong><a href="$surl\lv-admin/a-sets/l-bro/">$admintxt2[23]</a></strong></div><div style="padding: 8px" class="win2 smalltext">$admintxt2[24]</div></td>
 </tr><tr>
  <td class="win3 center" style="width: 40px"><img src="$images/admincenter/logs.png" alt="" /></td>
  <td style="padding: 0px" class="win"><div style="padding: 8px;"><strong><a href="$surl\lv-admin/a-sets/l-log/">$admintxt2[25]</a></strong></div><div style="padding: 8px" class="win2 smalltext">$admintxt2[26]</div></td>
 </tr><tr>
  <td class="win3 center" style="width: 40px"><img src="$images/admincenter/mods.png" alt="" /></td>
  <td style="padding: 0px" class="win"><div style="padding: 8px;"><strong><a href="$surl\lv-admin/a-sets/l-mods/">$admintxt2[31]</a></strong></div><div style="padding: 8px" class="win2 smalltext">$admintxt2[32]</div></td>
 </tr><tr>
  <td class="catbg smalltext" colspan="2"><strong><a href="$surl\lv-admin/a-sets/l-all/">$admintxt2[33]</a></strong></td>
 </tr>
</table>
EOT
	footerA();
	exit;
}

sub Settings2 {
	is_admin(1.1);

	$title = "$admintxt2[12] - ";
	if($l eq 'dir') { $title .= $admintxt2[13]; }
	elsif($l eq 'ess') { $title .= $admintxt2[17]; }
	elsif($l eq 'blk') { $title .= $admintxt2[19]; }
	elsif($l eq 'bro') { $title .= $admintxt2[23]; }
	elsif($l eq 'upl') { $title .= $admintxt2[21]; }
	elsif($l eq 'log') { $title .= $admintxt2[25]; }
	elsif($l eq 'flk') { $title .= $admintxt2[27]; }
	elsif($l eq 'news') { $title .= $admintxt2[29]; }
	elsif($l eq 'mods') { $title .= $admintxt2[31]; }
	elsif($l eq 'all') { $title .= $admintxt2[35]; }
		else { error($admintxt2[36]); }
	$gzipen2 = $gzipen;
	headerA();
	$ebout .= <<"EOT";
<form action="$surl\lv-admin/a-sets/l-$URL{'l'}/s-save/" method="post" enctype="multipart/form-data">
<table class="border" cellspacing="1" cellpadding="6" width="98%">
 <tr>
  <td class="titlebg"><strong><img src="$images/settings.gif" alt="" /> $admintxt2[12]</strong></td>
 </tr>
EOT
	if($l eq 'dir' || $l eq 'all') {
		$rurl =~ s~/Blah.pl\?~~gsi;
		$ebout .= <<"EOT";
 <tr>
  <td class="catbg"><img src="$images/admincenter/dirweb.png" class="centerimg" alt="" /> <strong>$admintxt2[13]</strong></td>
 </tr><tr>
  <td class="win smalltext">$admintxt2[14]<br />$admintxt2[244]</td>
 </tr><tr>
  <td class="win2" style="padding: 0px">
   <table cellspacing="0" cellpadding="6" width="100%">
    <tr>
     <td colspan="3" class="win3 smalltext"><strong>$admintxt2[380]</strong></td>
    </tr><tr>
     <td class="right" style="width: 40%"><strong>Root:</strong></td>
     <td><input type="text" name="root" value="$root" size="30" /></td>
	<td class="smalltext lessimp right">$admintxt2[377]</td>
    </tr><tr>
     <td></td>
     <td class="smalltext" colspan="2">$admintxt2[38]</td>
    </tr><tr>
     <td class="right"><strong>Code:</strong><br /></td>
     <td><input type="text" name="code" value="$code" size="30" /></td>
     <td class="smalltext lessimp right">$admintxt2[377]</td>
    </tr><tr>
     <td class="right"><strong>Boards:</strong></td>
     <td><input type="text" name="boards" value="$boards" size="30" /></td>
     <td class="smalltext lessimp right">$admintxt2[377]</td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[41]:</strong></td>
     <td><input type="text" name="prefs" value="$prefs" size="30" /></td>
     <td class="smalltext lessimp right">$admintxt2[377]</td>
    </tr><tr>
     <td class="right"><strong>Members:</strong></td>
     <td><input type="text" name="members" value="$members" size="30" /></td>
     <td class="smalltext lessimp right">$admintxt2[377]</td>
    </tr><tr>
     <td class="right"><strong>Messages:</strong></td>
     <td><input type="text" name="messages" value="$messages" size="30" /></td>
     <td class="smalltext lessimp right">$admintxt2[377]</td>
    </tr><tr>
     <td class="right"><strong>Languages:</strong></td>
     <td><input type="text" name="languages" value="$languages" size="30" /></td>
     <td class="smalltext lessimp right">$admintxt2[377]</td>
    </tr><tr>
     <td class="right"><strong>Mods:</strong></td>
     <td><input type="text" name="modsdir" value="$modsdir" size="30" /></td>
     <td class="smalltext lessimp right">$admintxt2[377]</td>
    </tr><tr>
     <td colspan="3" class="win3 smalltext"><strong>Templates</strong></td>
    </tr><tr>
     <td class="right"><strong>Templates:</strong></td>
     <td><input type="text" name="templates" value="$templates" size="30" /></td>
     <td class="smalltext lessimp right">$admintxt2[377]</td>
    </tr><tr>
     <td class="right"><strong>Templates:</strong></td>
     <td><input type="text" name="templatesu" value="$templatesu" size="30" /></td>
     <td class="smalltext lessimp right">$admintxt2[378]</td>
    </tr><tr>
     <td colspan="3" class="win3 smalltext"><strong>$admintxt2[292]</strong></td>
    </tr><tr>
     <td class="right"><strong>Avatars:</strong></td>
     <td><input type="text" name="avdir" value="$avdir" size="30" /></td>
     <td class="smalltext lessimp right">$admintxt2[377]</td>
    </tr><tr>
     <td class="right"><strong>Avatars:</strong></td>
     <td><input type="text" name="avsurl" value="$avsurl" size="30" /></td>
     <td class="smalltext lessimp right">$admintxt2[378]</td>
    </tr><tr>
     <td colspan="3" class="win3 smalltext"><strong>$admintxt2[293]</strong></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[40]:</strong></td>
     <td><input type="text" name="rurl" value="$realurl" size="30" /></td>
     <td class="smalltext lessimp right">$admintxt2[378]</td>
    </tr><tr>
     <td></td>
     <td class="smalltext" colspan="2">$admintxt2[345]</td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[336] Images:</strong></td>
     <td><input type="text" name="images" value="$oimages" size="30" /></td>
     <td class="smalltext lessimp right">$admintxt2[378]</td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[336] Buttons:</strong></td>
     <td><input type="text" name="buttons" value="$obuttons" size="30" /></td>
     <td class="smalltext lessimp right">$admintxt2[378]</td>
    </tr><tr>
     <td class="right"><strong>Smilies:</strong></td>
     <td><input type="text" name="simages" value="$simages" size="30" /></td>
     <td class="smalltext lessimp right">$admintxt2[378]</td>
    </tr><tr>
     <td class="right"><strong>blahdocs:</strong></td>
     <td><input type="text" name="bdocsdir" value="$bdocsdir" size="30" /></td>
     <td class="smalltext lessimp right">$admintxt2[378]</td>
    </tr><tr>
     <td class="right"><strong>blahdocs:</strong></td>
     <td><input type="text" name="bdocsdir2" value="$bdocsdir2" size="30" /></td>
     <td class="smalltext lessimp right">$admintxt2[377]</td>
    </tr><tr>
     <td class="right"><strong>Help:</strong></td>
     <td><input type="text" name="helpdesk" value="$helpdesk" size="30" /></td>
     <td class="smalltext lessimp right">$admintxt2[378]</td>
    </tr>
   </table>
  </td>
 </tr>
EOT
	} if($l eq 'ess' || $l eq 'all') {
		push(@checks,('mailauth'));
		CheckBoxes();
		$mail{$mailuse} = ' selected="selected"';
		$emailsig = Unformat($emailsig);
		$ebout .= <<"EOT";
 <tr>
  <td class="catbg"><img src="$images/admincenter/essential.png" class="centerimg" alt="" /> <strong>$admintxt2[17]</strong></td>
 </tr><tr>
  <td class="win smalltext">$admintxt2[18]</td>
 </tr><tr>
  <td class="win2" style="padding: 0px">
   <table cellspacing="0" cellpadding="6" width="100%">
    <tr>
     <td colspan="2" class="win3 smalltext"><strong>$admintxt2[381]</strong></td>
    </tr><tr>
     <td class="right" style="width: 40%"><strong>$admintxt2[48]:</strong></td>
     <td><input type="text" name="regto" value="$regto" size="30" /></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[49]:</strong></td>
     <td><input type="text" name="eadmin" value="$eadmin" size="30" /></td>
    </tr><tr>
     <td colspan="2" class="win3 smalltext"><strong>$admintxt2[294]</strong></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[51]:</strong></td>
     <td><input type="text" name="cookpre" value="$cookpre" size="30" /></td>
    </tr><tr>
     <td colspan="2" class="win3 smalltext"><strong>$admintxt2[295]</strong></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[52]:</strong></td>
     <td><select name="mailuse"><option value="1"$mail{'1'}>Sendmail</option><option value="2"$mail{'2'}>SMTP</option></select></td>
    </tr><tr>
     <td class="right"><strong>Sendmail $admintxt2[53]:</strong></td>
     <td><input type="text" name="smaill" value="$smaill" size="30" /></td>
    </tr><tr>
     <td class="right"><strong>SMTP $admintxt2[54]:</strong></td>
     <td><input type="text" name="mailhost" value="$mailhost" size="30" /></td>
    </tr><tr>
     <td>&nbsp;</td>
     <td><table cellspacing="0" cellpadding="3" width="100%">
      <tr>
       <td colspan="2"><input type="checkbox" name="mailauth" value="1"$mailauth{1} /> <span class="smalltext"><strong>$admintxt2[268]</strong></span></td>
      </tr><tr>
       <td class="right smalltext"><strong>SMTP $admintxt2[173]:</strong></td>
       <td><input type="text" name="mailusername" value="$mailusername" size="30" /></td>
      </tr><tr>
       <td class="right smalltext"><strong>SMTP $admintxt2[267]:</strong></td>
       <td><input type="password"  name="mailpassword" value="$mailpassword" size="30" /></td>
      </tr>
     </table></td>
    </tr><tr>
     <td class="right vtop"><strong>$admintxt2[252]:</strong></td>
     <td><textarea name="emailsig" rows="3" cols="50">$emailsig</textarea></td>
    </tr><tr>
     <td></td>
     <td class="smalltext">$admintxt2[251]</td>
    </tr>
   </table>
  </td>
 </tr>
EOT
	} if($l eq 'blk' || $l eq 'all') {
		push(@checks,('maintance','lockout','noguest','creg'));
		CheckBoxes();
		$maintancer = $maintancer || $admintxt2[257];
		$gzipen{$gzipen2} = ' selected="selected"';

		$ebout .= <<"EOT";
 <tr>
  <td class="catbg"><img src="$images/admincenter/locked.png" class="centerimg" alt="" /> <strong>$admintxt2[19]</strong></td>
 </tr><tr>
  <td class="win smalltext">$admintxt2[20]</td>
 </tr><tr>
  <td class="win2" style="padding: 0px">
   <table cellspacing="0" cellpadding="6" width="100%">
    <tr>
     <td colspan="2" class="win3 smalltext"><strong>$admintxt2[379]</strong></td>
    </tr><tr>
     <td class="right" style="width: 40%"><strong>$admintxt2[55]:</strong></td>
     <td><input type="checkbox" name="maintance" value="1"$maintance{1} /></td>
    </tr><tr>
     <td></td>
     <td class="smalltext">$admintxt2[56]</td>
    </tr><tr>
     <td class="vtop right"><strong>$admintxt2[57]:</strong></td>
     <td><textarea name="maintancer" rows="4" cols="50">$maintancer</textarea></td>
    </tr><tr>
     <td colspan="2" class="win3 smalltext"><strong>$admintxt2[58]</strong></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[58]:</strong></td>
     <td><input type="checkbox" name="lockout" value="1"$lockout{1} /></td>
    </tr><tr>
     <td></td>
     <td class="smalltext">$admintxt2[59]</td>
    </tr><tr>
     <td colspan="2" class="win3 smalltext"><strong>$admintxt2[296]</strong></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[60]:</strong></td>
     <td><input type="checkbox" name="noguest" value="1"$noguest{1} /></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[61]:</strong></td>
     <td><input type="checkbox" name="creg" value="1"$creg{1} /></td>
    </tr><tr>
     <td colspan="2" class="win3 smalltext"><strong>$admintxt2[254]</strong></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[254]:</strong></td>
     <td><input type="text" name="serload" size="4" value="$serload" /></td>
    </tr><tr>
     <td></td>
     <td class="smalltext">$admintxt2[253]</td>
    </tr><tr>
     <td colspan="2" class="win3 smalltext"><strong>$admintxt2[332]</strong></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[329]:</strong></td>
     <td><select name="gzipen"><option value="0"$gzipen{0}>$admintxt2[157]</option><option value="2"$gzipen{2}>gzip (*nix)</option><option value="1"$gzipen{1}>Zlib (Win32/*nix)</option></select></td>
    </tr><tr>
     <td></td>
     <td class="smalltext">$admintxt2[328]</td>
    </tr>
   </table>
  </td>
 </tr>
EOT
	} if($l eq 'upl' || $l eq 'all') {
		push(@checks,('avupload','autoresize'));
		CheckBoxes();
		$uallows{$uallow} = ' selected="selected"';

		$ebout .= <<"EOT";
 <tr>
  <td class="catbg"><img src="$images/admincenter/attachments.png" class="centerimg" alt="" /> <strong>&nbsp;$admintxt2[21]</strong></td>
 </tr><tr>
  <td class="win smalltext">$admintxt2[22]</td>
 </tr><tr>
  <td class="win2" style="padding: 0px">
   <table cellspacing="0" cellpadding="6" width="100%">
    <tr>
     <td colspan="3" class="win smalltext"><strong>$admintxt2[382]</strong></td>
    </tr><tr>
     <td class="right" style="width: 40%"><strong>$admintxt2[63]:</strong></td>
     <td colspan="2"><select name="uallow"><option value="0"$uallows{0}>$admintxt2[64]</option><option value="1"$uallows{1}>$admintxt2[65]</option><option value="2"$uallows{2}>$admintxt2[66]</option><option value="3"$uallows{3}>$admintxt2[67]</option></select></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[206]</strong></td>
     <td colspan="2"><input type="checkbox" name="avupload" value="1"$avupload{1} /></td>
    </tr><tr>
     <td></td>
     <td class="smalltext" colspan="2">$admintxt2[207]</td>
    </tr><tr>
     <td colspan="3" class="win smalltext"><strong>$admintxt2[297]</strong></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[69]:</strong></td>
     <td><input type="text" name="uploaddir" value="$uploaddir" size="30" /></td>
	<td class="right smalltext lessimp">$admintxt2[377]</td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[69]:</strong></td>
     <td><input type="text" name="uploadurl" value="$uploadurl"  size="30" /></td>
	<td class="right smalltext lessimp">$admintxt2[378]</td>
    </tr><tr>
     <td colspan="3" class="win smalltext"><strong>$admintxt2[298]</strong></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[364]</strong></td>
     <td colspan="2"><input type="checkbox" name="autoresize" value="1"$autoresize{1} /></td>
    </tr><tr>
     <td></td>
     <td class="smalltext" colspan="2">$admintxt2[365]</td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[366]:</strong></td>
     <td colspan="2"><input type="text" name="tnwidth" value="$tnwidth" size="5" /> X <input type="text" name="tnheight" value="$tnheight" size="5" /></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[70]:</strong></td>
     <td colspan="2"><input type="text" name="allowedext" value="$allowedext" size="25" /></td>
    </tr><tr>
     <td></td>
     <td class="smalltext" colspan="2">$admintxt2[71]</td>
    </tr><tr>
     <td class="right vtop"><strong>$admintxt2[72]:</strong></td>
     <td colspan="2">
      <table cellpadding="0" cellspacing="0" class="innertable">
       <tr>
        <td><input type="text" name="maxsize" value="$maxsize" size="6" /></td>
        <td class="smalltext lessimp">&nbsp; $admintxt2[303]</td>
       </tr><tr>
        <td><input type="text" name="maxsize2" value="$maxsize2" size="6" /></td>
        <td class="smalltext lessimp">&nbsp; $admintxt2[302]</td>
       </tr>
      </table>
     </td>
    </tr><tr>
     <td></td>
     <td class="smalltext" colspan="2">$admintxt2[73]</td>
    </tr>
   </table>
  </td>
 </tr>
EOT
	} if($l eq 'bro' || $l eq 'all') {
		push(@checks,('tagsenable','BCAdvanced','xhtmlct','showage','nocomputers','forumstats','enablecal','fancyqprofile','disabledel','disablesn','showloggedon','gattach','enablerep','emailadmin','enbdays','showlocation','nonotify','html','hiddenmail','allowrate','pmdisable','gdisable','reversesum','showevents','logactive','showactive','quickreg','sview','showtheme','sall','showdes','showgender','btod','enews','upbc','showreg','BCLoad','BCSmile','slpoller','hmail','quickreply','polltop','showmove','whereis','al','sppd','invfri','gsearch','noguestp','memguest'));
		CheckBoxes();

		$pollops = $pollops || 7;
		foreach(@htmls) { $tags .= "$_,"; }

		$apic{$apic}  = ' selected="selected"';
		$REP{$repscore} = ' selected="selected"';

		($sec,$min,$hour,$day,$month,$year,$week,$ydays,$dst) = localtime($date+(3600*($gtoff+$gtzone)));
		$year = $year+1900;

		$VRA{$vradmin} = ' selected="selected"';

		opendir(DIR,"$languages/");
		@lngs = readdir(DIR);
		closedir(DIR);

		foreach(@lngs) {
			($lng,$type) = split(/\./,$_);
			if($type ne 'lng') { next; }
			$check = '';
			if($language eq "$languages/$lng") { $check = ' selected="selected"'; }
			$lngs .= qq~<option value="$lng"$check>$lng</option>~;
		}

		$redirectfix{$redirectfix} = ' selected="selected"';
		$hms{$hiddenmail} = ' selected="selected"';
		$hps{$hideposts} = ' selected="selected"';
		$ensids{$ensids} = ' selected="selected"';

		$posttext{$posttext} = ' checked="checked"';
		$indextext{$indextext} = ' checked="checked"';
		$menutext{$menutext} = ' checked="checked"';

		$ebout .= <<"EOT";
 <tr>
  <td class="catbg"><img src="$images/admincenter/forumstats.png" class="centerimg" alt="" /> <strong>$admintxt2[23]</strong></td>
 </tr><tr>
  <td class="win smalltext">$admintxt2[24]</td>
 </tr><tr>
  <td class="win2" style="padding: 0px">
   <table cellspacing="0" cellpadding="6" width="100%">
    <tr>
     <td colspan="2" class="win3 smalltext"><strong>$admintxt2[382]</strong></td>
    </tr><tr>
     <td class="right" style="width: 40%"><strong>$admintxt2[123]:</strong></td>
     <td><input type="text" name="mbname" value="$mbname" size="40" /></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[119]:</strong></td>
     <td><select name="lng">$lngs</select></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[94]</strong></td>
     <td><input type="checkbox" name="btod" value="1"$btod{1} /></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[224]:</strong></td>
     <td><input type="text" name="nocomma" value="$nocomma" size="5" /></td>
    </tr><tr>
     <td></td>
     <td class="smalltext">$admintxt2[223]</td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[269]:</strong></td>
     <td><select name="redirectfix"><option value="0"$redirectfix{0}>Location $admintxt2[270]</option><option value="2"$redirectfix{2}>Redirect (no html)</option><option value="1"$redirectfix{1}>HTML Redirect ($admintxt2[271])</option></select></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[98]</strong></td>
     <td><input type="checkbox" name="showtheme" value="1"$showtheme{1} /></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[406]:</strong></td>
     <td><input type="checkbox" name="xhtmlct" value="1"$xhtmlct{1} /></td>
    </tr><tr>
     <td></td>
     <td class="smalltext">$admintxt2[405]</td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[410]</strong></td>
     <td><input type="checkbox" name="tagsenable" value="1"$tagsenable{1} /></td>
    </tr><tr>
     <td></td>
     <td class="smalltext">$admintxt2[409]</td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[412]:</strong></td>
     <td><input type="text" name="autotag" value="$autotag" /></td>
    </tr><tr>
     <td></td>
     <td class="smalltext">$admintxt2[413]</td>
    </tr><tr>
     <td colspan="2" class="win3 smalltext"><strong>$admintxt2[393]</strong></td>
    </tr><tr>
     <td class="right vtop"><strong>$admintxt2[394]:</strong></td>
     <td>
	  <table cellpadding="4" cellspacing="0" width="100%">
	   <tr>
	    <td class="center win3" width="150"><img src="$buttons/home.png" alt="" /></td>
	    <td class="center win3" width="150"><img src="$buttons/icons/home.png" class="centerimg" alt="" /> $admintxt2[399]</td>
	    <td class="center win3" width="150">$admintxt2[399]</td>
		<td class="smalltext lessimp right" rowspan="2">CSS Class: <b>menubar</b></td>
	   </tr><tr>
	    <td class="center win3"><input type="radio" name="menutext" value="0"$menutext{0} /></td>
	    <td class="center win3"><input type="radio" name="menutext" value="2"$menutext{2} /></td>
	    <td class="center win3"><input type="radio" name="menutext" value="1"$menutext{1} /></td>
	   </tr>
	  </table>
	 </td>
    </tr><tr>
     <td class="right vtop"><strong>$admintxt2[395]:</strong></td>
     <td>
	  <table cellpadding="4" cellspacing="0" width="100%">
	   <tr>
	    <td class="center win3" width="150"><img src="$buttons/new_thread.png" alt="" /></td>
	    <td class="center win3" width="150"><img src="$buttons/icons/new_thread.png" class="centerimg" alt="" /> $admintxt2[398]</td>
	    <td class="center win3" width="150">$admintxt2[398]</td>
		<td class="smalltext lessimp right" rowspan="2">CSS Class: <b>indexmenu</b></td>
	   </tr><tr>
	    <td class="center win3"><input type="radio" name="indextext" value="0"$indextext{0} /></td>
	    <td class="center win3"><input type="radio" name="indextext" value="2"$indextext{2} /></td>
	    <td class="center win3"><input type="radio" name="indextext" value="1"$indextext{1} /></td>
	   </tr>
	  </table>
	 </td>
    </tr><tr>
     <td class="right vtop"><strong>$admintxt2[396]:</strong></td>
     <td>
	  <table cellpadding="4" cellspacing="0" width="100%">
	   <tr>
	    <td class="center win3" width="150"><img src="$buttons/quote.png" alt="" /></td>
	    <td class="center win3" width="150"><img src="$buttons/icons/quote.png" class="centerimg" alt="" /> $admintxt2[397]</td>
	    <td class="center win3" width="150">$admintxt2[397]</td>
		<td class="smalltext lessimp right" rowspan="2">CSS Class: <b>postmenu</b></td>
	   </tr><tr>
	    <td class="center win3"><input type="radio" name="posttext" value="0"$posttext{0} /></td>
	    <td class="center win3"><input type="radio" name="posttext" value="2"$posttext{2} /></td>
	    <td class="center win3"><input type="radio" name="posttext" value="1"$posttext{1} /></td>
	   </tr>
	  </table>
	 </td>
    </tr><tr>
     <td colspan="2" class="win3 smalltext"><strong>$admintxt2[322]</strong></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[323]:</strong></td>
     <td><input type="text" name="maxattempts" value="$maxattempts" size="5" /></td>
    </tr><tr>
     <td></td>
     <td class="smalltext">$admintxt2[324]</td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[325]:</strong></td>
     <td><input type="text" name="loginfailtime" value="$loginfailtime" size="5" /></td>
    </tr><tr>
     <td></td>
     <td class="smalltext">$admintxt2[326]</td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[389]:</strong></td>
     <td><select name="ensids"><option value="0"$ensids{0}>$admintxt2[390]</option><option value="2"$ensids{2}$ensids{1}>$admintxt2[392]</option></select></td>
    </tr><tr>
     <td></td>
     <td class="smalltext">$admintxt2[315]</td>
    </tr><tr>
     <td colspan="2" class="win3 smalltext"><strong>$admintxt2[278]</strong></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[117]:</strong></td>
     <td><input type="text" name="datedisv2" value="$datedisv2" size="30" /></td>
    </tr><tr>
     <td></td>
     <td class="smalltext">$admintxt2[404]</td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[212]:</strong></td>
     <td><input type="text" name="gtoff" value="$gtoff" size="5" /></td>
    </tr><tr>
     <td></td>
     <td class="smalltext">$admintxt2[211]</td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[245]:</strong></td>
     <td><input type="text" name="gtzone" value="$gtzone" size="5" /></td>
    </tr><tr>
     <td></td>
     <td class="smalltext">$admintxt2[246]</td>
    </tr><tr>
     <td colspan="2" class="win3 smalltext"><strong>$admintxt2[279]</strong></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[75]</strong></td>
     <td><input type="checkbox" name="noguestp" value="1"$noguestp{1} /></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[76]</strong></td>
     <td><input type="checkbox" name="memguest" value="1"$memguest{1} /></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[77]</strong></td>
     <td><input type="checkbox" name="gsearch" value="1"$gsearch{1} /></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[209]</strong></td>
     <td><input type="checkbox" name="gdisable" value="1"$gdisable{1} /></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[335]</strong></td>
     <td><input type="checkbox" name="gattach" value="1"$gattach{1} /></td>
    </tr><tr>
     <td colspan="2" class="win3 smalltext"><strong>$admintxt2[280]</strong></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[84]</strong></td>
     <td><select name="apic"><option value="0"$apic{0}>$admintxt[3]</option><option value="2"$apic{2}>$admintxt2[313]</option><option value="1"$apic{1}>$admintxt2[314]</option></select></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[129]:</strong></td>
     <td><input type="text" name="picwidth" value="$picwidth" size="4" /> <strong>&times;</strong> <input type="text" name="picheight" value="$picheight" size="4" /> <span class="smalltext">$admintxt2[130]</span></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[78]</strong></td>
     <td><input type="checkbox" name="invfri" value="1"$invfri{1} /></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[102]</strong></td>
     <td><input type="checkbox" name="logactive" value="1"$logactive{1} /></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[114]:</strong></td>
     <td><input type="text" name="maxsig" value="$maxsig" size="10" /></td>
    </tr><tr>
     <td></td>
     <td class="smalltext">$admintxt2[346]</td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[85]</strong></td>
     <td><input type="checkbox" name="hmail" value="1"$hmail{1} /></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[225]:</strong></td>
     <td><select name="hiddenmail"><option value="0"$hms{0}>$admintxt2[275]</option><option value="1"$hms{1}>$admintxt2[276]</option><option value="2"$hms{2}>$admintxt2[277]</option></select></td>
    </tr><tr>
     <td></td>
     <td class="smalltext">$admintxt2[274]</td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[232]</strong></td>
     <td><input type="checkbox" name="nonotify" value="1"$nonotify{1} /></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[310]:</strong></td>
     <td><select name="hideposts"><option value="0"$hps{0}>$admintxt2[311]</option><option value="2"$hps{2}>$admintxt2[334]</option><option value="1"$hps{1}>$admintxt2[312]</option></select></td>
    </tr><tr>
     <td></td>
     <td class="smalltext">$admintxt2[309]</td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[327]</strong></td>
     <td><input type="checkbox" name="enablerep" value="1"$enablerep{1} /></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[385]:</strong></td>
     <td><select name="repscore"><option value="0"$REP{0}>$admintxt2[386]</option><option value="1"$REP{1}>$admintxt2[387]</option><option value="2"$REP{2}>$admintxt2[388]</option></select></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[340]</strong></td>
     <td><input type="checkbox" name="disablesn" value="1"$disablesn{1} /></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[341]</strong></td>
     <td><input type="checkbox" name="disabledel" value="1"$disabledel{1} /></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[348]:</strong></td>
     <td><input type="text" name="enablecal" value="$enablecal" size="5" /></td>
    </tr><tr>
     <td></td>
     <td class="smalltext">$admintxt2[347]</td>
    </tr><tr>
     <td colspan="2" class="win3 smalltext"><strong>$admintxt2[281]</strong></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[89]</strong></td>
     <td><input type="checkbox" name="showreg" value="1"$showreg{1} /></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[100]</strong></td>
     <td><input type="checkbox" name="quickreg" value="1"$quickreg{1} /></td>
    </tr><tr>
     <td></td>
     <td class="smalltext">$admintxt2[305]</td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[131]:</strong></td>
     <td><select name="vradmin"><option value="0"$VRA{'0'}>$admintxt2[133]</option><option value="1"$VRA{'1'}>$admintxt2[134]</option><option value="2"$VRA{'2'}>$admintxt2[135]</option></select></td>
    </tr><tr>
     <td></td>
     <td class="smalltext">$admintxt2[132]</td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[320]</strong></td>
     <td><input type="checkbox" name="emailadmin" value="1"$emailadmin{1} /></td>
    </tr><tr>
     <td></td>
     <td class="smalltext">$admintxt2[321]</td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[358]</strong></td>
     <td><input type="checkbox" name="nocomputers" value="1"$nocomputers{1} /></td>
    </tr><tr>
     <td></td>
     <td class="smalltext">$admintxt2[357]</td>
    </tr><tr>
     <td colspan="2" class="win3 smalltext"><strong>$admintxt2[282]</strong></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[107]</strong></td>
     <td><input type="checkbox" name="pmdisable" value="1"$pmdisable{1} /></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[108]:</strong></td>
     <td><input type="text" name="pmmaxquota" value="$pmmaxquota" size="10" /></td>
    </tr><tr>
     <td colspan="2" class="win3 smalltext"><strong>$admintxt2[283]</strong></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[111]:</strong></td>
     <td><input type="text" name="mmpp" value="$mmpp" size="10" /></td>
    </tr><tr>
     <td colspan="2" class="win3 smalltext"><strong>$admintxt2[284]</strong></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[90]</strong></td>
     <td><input type="checkbox" name="enews" value="1"$enews{1} /></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[103]</strong></td>
     <td><input type="checkbox" name="showevents" value="1"$showevents{1} /></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[318]</strong></td>
     <td><input type="checkbox" name="enbdays" value="1"$enbdays{1} /></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[301]:</strong></td>
     <td><input type="text" name="upevents" value="$upevents" size="4" /></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[403]:</strong></td>
     <td><input type="text" name="glimpsecnt" value="$glimpsecnt" size="4" /> &times; 2</td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[81]</strong></td>
     <td><input type="checkbox" name="whereis" value="1"$whereis{1} /></td>
    </tr><tr>
     <td></td>
     <td class="smalltext">$admintxt2[82]</td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[359]</strong></td>
     <td><input type="checkbox" name="forumstats" value="1"$forumstats{1} /></td>
    </tr><tr>
     <td colspan="2" class="win3 smalltext"><strong>$admintxt2[285]</strong></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[96]</strong></td>
     <td><input type="checkbox" name="showdes" value="1"$showdes{1} /></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[121]:</strong></td>
     <td><input type="text" name="maxdis" value="$maxdis" size="10" /></td>
    </tr><tr>
     <td colspan="2" class="win3 smalltext"><strong>$admintxt2[286]</strong></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[87]</strong></td>
     <td><input type="checkbox" name="BCSmile" value="1"$BCSmile{1} /></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[265]:</strong></td>
     <td><input type="text" name="gmaxsmils" value="$gmaxsmils" size="5" /></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[88]</strong></td>
     <td><input type="checkbox" name="BCLoad" value="1"$BCLoad{1} /></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[74]</strong></td>
     <td><input type="checkbox" name="upbc" value="1"$upbc{1} /></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[80]</strong></td>
     <td><input type="checkbox" name="al" value="1"$al{1} /></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[95]</strong></td>
     <td><input type="checkbox" name="showgender" value="1"$showgender{1} /></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[79]</strong></td>
     <td><input type="checkbox" name="sppd" value="1"$sppd{1} /></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[317]</strong></td>
     <td><input type="checkbox" name="showlocation" value="1"$showlocation{1} /></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[376]</strong></td>
     <td><input type="checkbox" name="showage" value="1"$showage{1} /></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[342]</strong></td>
     <td><input type="checkbox" name="fancyqprofile" value="1"$fancyqprofile{1} /></td>
    </tr><tr>
     <td></td>
     <td class="smalltext">$admintxt2[344]</td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[99]</strong></td>
     <td><input type="checkbox" name="sview" value="1"$sview{1} /></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[83]</strong></td>
     <td><input type="checkbox" name="showmove" value="1"$showmove{1} /></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[255]</strong></td><!-- Is Christ #1 in YOUR life? -->
     <td><input type="checkbox" name="quickreply" value="1"$quickreply{1} /></td>
    </tr><tr>
     <td></td>
     <td class="smalltext">$admintxt2[256]</td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[338]</strong></td>
     <td><input type="checkbox" name="showloggedon" value="1"$showloggedon{1} /></td>
    </tr><tr>
     <td></td>
     <td class="smalltext">$admintxt2[339]</td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[120]:</strong></td>
     <td><input type="text" name="maxmess" value="$maxmess" size="10" /></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[337]:</strong></td>
     <td><input type="text" name="maxmodifycount" value="$maxmodifycount" size="10" /></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[349]:</strong></td>
     <td><input type="text" name="showads" value="$showads" size="10" /></td>
    </tr><tr>
     <td class="right vtop"><strong>$admintxt2[350]:</strong></td>
     <td><textarea name="displayadverts" rows="1" cols="1" style="width: 98%; height: 75px;">$displayadverts</textarea></td>
    </tr><tr>
     <td class="right vtop"><strong>$admintxt2[351]:</strong></td>
     <td><select name="disableads" size="6" multiple="multiple">
EOT
	foreach(split(',',$disableads)) { $t2{$_} = ' selected="selected"'; }
	push(@fullgroups,('member','validating','guest'));
	$permissions{'member','name'} = $admintxt2[352];
	$permissions{'guest','name'} = $admintxt2[353];
	$permissions{'validating','name'} = $admintxt2[354];
	$ebout .= qq~<optgroup label="$admintxt2[355]">~;
	foreach(@fullgroups) {
		if($permissions{$_,'pcount'} ne '' || $_ eq 'Moderators') { next; }
		if($_ eq 'member') { $ebout .= qq~</optgroup><optgroup label="$admintxt2[356]">~; }
		$ebout .= qq~<option value="$_"$t2{$_}>$permissions{$_,'name'}</option>~;
	}

	$ebout .= <<"EOT";
      </optgroup></select>
     </td>
    </tr><tr>
     <td colspan="2" class="win3 smalltext"><strong>$admintxt2[287]</strong></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[97]</strong></td>
     <td><input type="checkbox" name="sall" value="1"$sall{1} /></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[210]</strong></td>
     <td><input type="checkbox" name="allowrate" value="1"$allowrate{1} /></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[101]</strong></td>
     <td><input type="checkbox" name="showactive" value="1"$showactive{1} /></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[122]:</strong></td>
     <td><input type="text" name="totalpp" value="$totalpp" size="10" /></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[112]:</strong></td>
     <td><input type="text" name="htdmax" value="$htdmax" size="10" /></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[113]:</strong></td>
     <td><input type="text" name="vhtdmax" value="$vhtdmax" size="10" /></td>
    </tr><tr>
     <td colspan="2" class="win3 smalltext"><strong>$admintxt2[289]</strong></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[105]</strong></td>
     <td><input type="checkbox" name="reversesum" value="1"$reversesum{1} /></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[272]:</strong></td><!--GOD IS GOOD _ALL_ THE TIME!-->
     <td><input type="text" name="maxsumc" value="$maxsumc" size="5" /></td>
    </tr><tr>
     <td></td>
     <td class="smalltext">$admintxt2[273]</td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[109]:</strong></td>
     <td><input type="text" name="iptimeout" value="$iptimeout" size="5" /></td>
    </tr><tr>
     <td></td>
     <td class="smalltext">$admintxt2[110]</td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[266]:</strong></td>
     <td><input type="text" name="maxmesslth" value="$maxmesslth" size="10" /></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[330]:</strong></td>
     <td><input type="text" name="modifytime" value="$modifytime" size="10" /></td>
    </tr><tr>
     <td></td>
     <td class="smalltext">$admintxt2[331]</td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[407]</strong></td>
     <td><input type="checkbox" name="BCAdvanced" value="1"$BCAdvanced{1} /></td>
    </tr><tr>
     <td></td>
     <td class="smalltext">$admintxt2[408]</td>
    </tr><tr>
     <td colspan="2" class="win3 smalltext"><strong>$admintxt2[290]</strong></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[219]</strong></td>
     <td><input type="checkbox" name="html" value="1"$html{1} /></td>
    </tr><tr>
     <td class="right vtop"><strong>$admintxt2[220]:</strong></td>
     <td><textarea name="htmls" rows="3" cols="50">$tags</textarea></td>
    </tr><tr>
     <td></td>
     <td class="smalltext">$admintxt2[221]</td>
    </tr><tr>
     <td colspan="2" class="win3 smalltext"><strong>$admintxt2[291]</strong></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[86]</strong></td>
     <td><input type="checkbox" name="slpoller" value="1"$slpoller{1} /></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[239]</strong></td>
     <td><input type="checkbox" name="polltop" value="1"$polltop{1} /></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[240]:</strong></td>
     <td><input type="text" name="pollops" value="$pollops" size="4" maxlength="4" /></td>
    </tr>
   </table>
  </td>
 </tr>
EOT
	} if($l eq 'log' || $l eq 'all') {
		push(@checks,('eclick','uextlog','kelog','logip','hideelog','hideclog'));
		CheckBoxes();
		$logdays = $logdays || 365;

		$ebout .= <<"EOT";
 <tr>
  <td class="catbg"><img src="$images/admincenter/logs.png" class="centerimg" alt="" /> <strong>$admintxt2[25]</strong></td>
 </tr><tr>
  <td class="win smalltext">$admintxt2[26]</td>
 </tr><tr>
  <td class="win2" style="padding: 0px">
   <table cellspacing="0" cellpadding="6" width="100%">
    <tr>
     <td colspan="2" class="win3 smalltext"><strong>$admintxt2[383]</strong></td>
    </tr><tr>
     <td class="right" style="width: 40%"><strong>$admintxt2[136]</strong></td>
     <td><input type="checkbox" name="eclick" value="1"$eclick{1} /></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[137]:</strong></td>
     <td><input type="text" name="logcnt" value="$logcnt" size="10" />&nbsp; <span class="smalltext lessimp">$admintxt2[384]</span></td>
    </tr><tr>
     <td></td>
     <td class="smalltext">$admintxt2[138]</td>
    </tr><tr>
     <td colspan="2" class="win3 smalltext"><strong>$admintxt2[300]</strong></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[139]</strong></td>
     <td><input type="checkbox" name="uextlog" value="1"$uextlog{1} /></td>
    </tr><tr>
     <td></td>
     <td class="smalltext">$admintxt2[248]</td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[140]</strong></td>
     <td><input type="checkbox" name="kelog" value="1"$kelog{1} /></td>
    </tr><tr>
     <td></td>
     <td class="smalltext">$admintxt2[249]</td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[141]</strong></td>
     <td><input type="checkbox" name="logip" value="1"$logip{1} /></td>
    </tr><tr>
     <td></td>
     <td class="smalltext">$admintxt2[250]</td>
    </tr><tr>
     <td colspan="2" class="win3 smalltext"><strong>$admintxt2[299]</strong></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[142]:</strong></td>
     <td><input type="text" name="logdays" value="$logdays" size="5" /></td>
    </tr><tr>
     <td></td>
     <td class="smalltext">$admintxt2[241]</td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[243]:</strong></td>
     <td><input type="text" name="activeuserslog" value="$activeuserslog" size="5" /></td>
    </tr><tr>
     <td></td>
     <td class="smalltext">$admintxt2[242]</td>
    </tr><tr>
     <td colspan="2" class="win3 smalltext"><strong>$admintxt2[306]</strong></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[307]</strong></td>
     <td><input type="checkbox" name="hideclog" value="1"$hideclog{1} /></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[308]</strong></td>
     <td><input type="checkbox" name="hideelog" value="1"$hideelog{1} /></td>
    </tr>
   </table>
  </td>
 </tr>
EOT
	} if($l eq 'mods' || $l eq 'all') {
		if(!$yabbconver) { $converteds = qq~$admintxt2[400] <a href="$surl\lv-admin/a-encrypt/">$admintxt2[401]</a>.~; }
			else { $converteds = $admintxt2[402]; }

		@selected = split(",",$newsboard);
		foreach(@selected) { $sel{$_} = ' selected="selected"'; }
		$boards2 = qq~<select name="newsboard" multiple="multiple" size="4">~;
		foreach(@catbase) {
			($t,$t,$access,$bhere) = split(/\|/,$_);
			@bdsh = split("/",$bhere);
			foreach $hh (@bdsh) {
				foreach $bbase (@boardbase) {
					($bid,$t,$t,$name) = split("/",$bbase);
					if($bid ne $hh) { next; }
					$boards2 .= qq~<option value="$bid"$sel{$bid}>$name</option>~;
					last;
				}
			}
		}
		$boards2 .= qq~</select>~;

		$ebout .= <<"EOT";
 <tr>
  <td class="catbg"><img src="$images/admincenter/mods.png" class="centerimg" alt="" /> <strong>$admintxt2[31]</strong></td>
 </tr><tr>
  <td class="win smalltext">$admintxt2[32]</td>
 </tr><tr>
  <td class="win2" style="padding: 0px">
   <table cellspacing="0" cellpadding="6" width="100%">
    <tr>
     <td colspan="2" class="win3 smalltext"><strong>$admintxt2[333]</strong></td>
    </tr><tr>
     <td class="right vtop" style="width: 40%"><strong>$admintxt2[150]</strong></td>
     <td>$converteds</td>
    </tr><tr>
     <td colspan="2" class="win3 smalltext"><strong>$admintxt2[29]</strong></td>
    </tr><tr>
     <td class="vtop right"><strong>$admintxt2[147]:</strong></td>
     <td>$boards2</td>
    </tr><tr>
     <td></td>
     <td class="smalltext">$admintxt2[148]</td>
    </tr><tr>
     <td class="vtop right"><strong>$admintxt2[149]:</strong></td>
     <td><input type="text" value="$newsshow" name="newsshow" size="5" /></td>
    </tr><tr>
     <td class="vtop right"><strong>$admintxt2[222]:</strong></td>
     <td><input type="text" value="$newslength" name="newslength" size="5" /></td>
    </tr><tr>
     <td colspan="2" class="win3 smalltext"><strong>$admintxt2[361]</strong></td>
    </tr><tr>
     <td colspan="2" class="win smalltext">$admintxt2[360]</td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[362]:</strong></td>
     <td><input type="text" name="akismetkey" value="$akismetkey" /></td>
    </tr><tr>
     <td class="right"><strong>$admintxt2[367]:</strong></td>
     <td><input type="text" name="akismetcheck" value="$akismetcheck" /></td>
    </tr><tr>
     <td></td>
     <td class="smalltext">$admintxt2[368]</td>
    </tr>
   </table>
  </td>
 </tr>
EOT
	}
	$ebout .= <<"EOT";
 <tr>
  <td class="win center"><input type="submit" name="submit" value="$admintxt2[152]" /></td>
 </tr>
</table>
</form>
EOT
	footerA();
	exit;
}

sub CheckBoxes {
	foreach(@checks) { ${$_}{${$_}} = ' checked="checked"'; }
	@checks = (); # Clear cache
}

sub CloseQuotes { # Closes " and ' so code cannot be injected
	$_[0] =~ s~\"~&quot;~g;
	$_[0] =~ s~\'~&#39;~g;
	return($_[0]);
}

sub CloseTitle { # Closes ~ so code cannot be injected
	$_[0] =~ s~\~~&#126;~g;
	return($_[0]);
}

sub CheckNumbers { # Makes sure value is, indeed, a number so code cannot be injected
	foreach(@numvals) {
		if($FORM{$_} !~ s~^(-?\.?\d+\.?\d*)\Z~$1~g) { $FORM{$_} = 0; }
	}
	@numvals = ();
}

sub Settings3 {
	is_admin(1.1);

	while(($iname,$ivalue) = each(%FORM)) {
		$ivalue =~ s~\A\s+~~;
		$ivalue =~ s~\s+\Z~~;
		$ivalue =~ s~\$~&#36;~g;
		$FORM{$iname} = $ivalue;
	}

	$images = $oimages;
	$buttons = $obuttons;

	if($l eq 'blk' || $l eq 'all') {
		push(@switches,('maintance','lockout','noguest','creg','serload'));
		@numvals = ('gzipen');
		CheckNumbers();
		$maintancer = CloseTitle($FORM{'maintancer'}) || $admintxt2[153];
		$gzipen = $FORM{'gzipen'} || 0;
	} if($l eq 'dir' || $l eq 'all') {
		while (($name,$value) = each(%FORM)) {
			$value =~ s~\\~/~gi;
			$FORM{$name} = $value;
		}
		$root = CloseQuotes($FORM{'root'}) || '.';
		$code = CloseQuotes($FORM{'code'}) || './Code';
		$boards = CloseQuotes($FORM{'boards'}) || './Boards';
		$prefs = CloseQuotes($FORM{'prefs'}) || './Prefs';
		$members = CloseQuotes($FORM{'members'}) || './Members';
		$messages = CloseQuotes($FORM{'messages'}) || './Messages';
		$images = CloseQuotes($FORM{'images'}) || '/';
		$buttons = CloseQuotes($FORM{'buttons'}) || '/';
		$simages = CloseQuotes($FORM{'simages'}) || '/';
		$avsurl = CloseQuotes($FORM{'avsurl'}) || $ENV{'DOCUMENT_ROOT'};
		$avdir = CloseQuotes($FORM{'avdir'});
		$realurl = CloseQuotes($FORM{'rurl'}) || '/';
		$bdocsdir = CloseQuotes($FORM{'bdocsdir'}) || '/blahdocs';
		$helpdesk = CloseQuotes($FORM{'helpdesk'});
		$languages = CloseQuotes($FORM{'languages'}) || './Languages';
		$templates = CloseQuotes($FORM{'templates'}) || "$ENV{'DOCUMENT_ROOT'}/blahdocs/template";
		$templatesu = CloseQuotes($FORM{'templatesu'}) || '/blahdocs/template';
		$modsdir = CloseQuotes($FORM{'modsdir'}) || "$root/Mods";
		$bdocsdir2 = CloseQuotes($FORM{'bdocsdir2'}) || "$ENV{'DOCUMENT_ROOT'}/blahdocs";

		$realurl =~ s/\/\Z//g;
		$realurl .= '/' if($modrewrite eq '?');
	} if($l eq 'ess' || $l eq 'all') {
		push(@switches,'mailauth');
		@numvals = ('mailuse');
		CheckNumbers();
		$regto = CloseTitle($FORM{'regto'}) || $username;
		$eadmin = CloseTitle($FORM{'eadmin'}) || "unknown\@unknown.unknown";
		$cookpre = CloseTitle($FORM{'cookpre'}) || "eblah";
		$mailuse = $FORM{'mailuse'} || 1;
		$smaill = CloseQuotes($FORM{'smaill'});
		$mailhost = CloseQuotes($FORM{'mailhost'});
		$mailusername = CloseQuotes($FORM{'mailusername'});
		$mailpassword = CloseQuotes($FORM{'mailpassword'});
		$emailsig = Format($FORM{'emailsig'});
		$emailsig =~ s/\*//sgi;
	} if($l eq 'upl' || $l eq 'all') {
		push(@switches,('uallow','autoresize','avupload'));
		@numvals = ('tnheight','tnwidth','maxsize','maxsize2');
		CheckNumbers();
		$uploaddir = CloseQuotes($FORM{'uploaddir'});
		$uploadurl = CloseQuotes($FORM{'uploadurl'});
		$tnheight = $FORM{'tnheight'};
		$tnwidth = $FORM{'tnwidth'};
		$allowedext = CloseQuotes($FORM{'allowedext'});
		$maxsize = $FORM{'maxsize'};
		$maxsize2 = $FORM{'maxsize2'};
		if($maxsize2 eq '') { $maxsize2 = $maxsize; }
	} if($l eq 'bro' || $l eq 'all') {
		push(@switches,('tagsenable','BCAdvanced','xhtmlct','showage','nocomputers','forumstats','fancyqprofile','disabledel','disablesn','showloggedon','gattach','enablerep','emailadmin','enbdays','showlocation','html','maxmesslth','maxsumc','redirectfix','quickreply','hiddenmail','gtzone','pollops','polltop','nonotify','allowrate','pmdisable','gdisable','reversesum','showevents','logactive','showactive','quickreg','sview','showtheme','sall','showdes','gsearch','memguest','showgender','iptimeout','btod','enews','picwidth','picheight','gtoff','maxsig','pmmaxquota','showreg','BCLoad','BCSmile','slpoller','hmail','apic','showmove','whereis','al','sppd','invfri','noguestp','upbc'));
		@numvals = ('glimpsecnt','menutext','indextext','posttext','loginfailtime','maxattempts','modifytime','ensids','repscore','enablecal','showads','maxmodifycount','maxmess','maxdis','vhtdmax','mmpp','totalpp','vradmin','gmaxsmils','upevents','hideposts');
		CheckNumbers();
		$maxmess = $FORM{'maxmess'} || '15';
		$maxdis = $FORM{'maxdis'} || '20';
		$mbname = $FORM{'mbname'};
		$mbname =~ s/\*//sgi; # Error prevention
		$vhtdmax = $FORM{'vhtdmax'} || 50;
		$htdmax = $FORM{'htdmax'} || 25;
		$mmpp = $FORM{'mmpp'} || 25;
		$totalpp = $FORM{'totalpp'} || 20;
		$vradmin = $FORM{'vradmin'};
		$languagep = CloseQuotes($FORM{'lng'}) || 'English';
		$nocomma = CloseTitle($FORM{'nocomma'});
		$gmaxsmils = $FORM{'gmaxsmils'} || 200;
		$upevents = $FORM{'upevents'};
		$hideposts = $FORM{'hideposts'} || 0;
		@htmls = split(',',CloseQuotes($FORM{'htmls'}));
		$loginfailtime = $FORM{'loginfailtime'} || 0;
		$maxattempts = $FORM{'maxattempts'} || 0;
		$modifytime = $FORM{'modifytime'} || 0;
		$maxmodifycount = $FORM{'maxmodifycount'} || 0;
		$showads = $FORM{'showads'} || 0;
		$displayadverts = CloseTitle($FORM{'displayadverts'});
		$disableads = CloseQuotes($FORM{'disableads'});
		$enablecal = $FORM{'enablecal'} || 0;
		$repscore = $FORM{'repscore'} || 0;
		$ensids = $FORM{'ensids'} || 0;
		$menutext = $FORM{'menutext'} || 0;
		$posttext = $FORM{'posttext'} || 0;
		$indextext = $FORM{'indextext'} || 0;
		$glimpsecnt = $FORM{'glimpsecnt'} || 0;
		$datedisv2 = $FORM{'datedisv2'} || 'F j, Y, g:ia';
		$autotag = $FORM{'autotag'} || 0;
	} if($l eq 'log' || $l eq 'all') {
		push(@switches,('eclick','uextlog','kelog','logip','hideelog','hideclog'));
		@numvals = ('logcnt','logdays','activeuserslog');
		CheckNumbers();
		$logcnt = $FORM{'logcnt'} || 1440;
		$logdays = $FORM{'logdays'} || 365;
		$activeuserslog = $FORM{'activeuserslog'} || 15;
	} if($l eq 'mods' || $l eq 'all') { # Board Modifications Settings Below ...
		push(@switches,'newsshow');
		@numvals = ('newslength','akismetcheck');
		CheckNumbers();
		$newsboard = CloseQuotes($FORM{'newsboard'});
		$newslength = $FORM{'newslength'} || 2000;

		if($akismetkey ne $FORM{'akismetkey'}) {
			if($FORM{'akismetkey'} ne '') {
				CoreLoad('Akismet');
				AkismetVerify($FORM{'akismetkey'}) || error($admintxt2[363]);
			}
			$akismetkey = CloseQuotes($FORM{'akismetkey'}) || '';
		}

		$akismetcheck = $FORM{'akismetcheck'} || 0;
	}

	if($URL{'a'} eq 'encrypt') {
		$FORM{'yabbconver'} = 1;
		push(@switches,'yabbconver');
	}

	$rurl =~ s~/Blah.pl\?~~gsi;

	foreach(@htmls) {
		$_ =~ s/'//gsi;
		if($_ eq '') { next; }
		$htmls .= "'$_',";
	}
	$htmls =~ s/,\Z//gsi;
	foreach(@switches) { ${$_} = $FORM{$_} || 0; }

	if(!$advancedhtml) { $advancedhtml = 0; }

	$printtofile = <<"EOT";
#####################################################
# E-Blah Bulletin Board Systems               2008  #
#####################################################
# This file contains setup information vital to     #
# running E-Blah. You should not edit this file     #
# manualy. Use Admin Center on your Forum to change #
# these settings.                                   #
#####################################################

\$bversion = $theblahver;

# Directories Sets
\$root = "$root";
\$code = "$code";
\$boards = "$boards";
\$prefs = "$prefs";
\$members = "$members";
\$messages = "$messages";
\$modsdir = "$modsdir";
\$images = "$images";
\$simages = "$simages";
\$avsurl = "$avsurl";
\$avdir = "$avdir";
\$realurl = "$realurl";
\$bdocsdir = "$bdocsdir";
\$helpdesk = "$helpdesk";
\$languages = "$languages";
\$templates = "$templates";
\$templatesu = "$templatesu";
\$buttons = "$buttons";
\$bdocsdir2 = "$bdocsdir2";

# Settings
\$regto = qq~$regto~;
\$eadmin = q~$eadmin~;
\$cookpre = qq~$cookpre~;
\$mailuse = $mailuse;
\$smaill = "$smaill";
\$mailhost = "$mailhost";
\$emailsig = q*$emailsig*;
\$mailauth = $mailauth;
\$mailusername = '$mailusername';
\$mailpassword = '$mailpassword';
\$maintance = $maintance;
\$maintancer = qq~$maintancer~;
\$lockout = $lockout;
\$noguest = $noguest;
\$creg = $creg;
\$serload = $serload;
\$gzipen = $gzipen;
\$uallow = $uallow;
\$avupload = $avupload;
\$ntsys = $ntsys;
\$uploaddir = "$uploaddir";
\$uploadurl = "$uploadurl";
\$allowedext = "$allowedext";
\$maxsize = "$maxsize";
\$maxsize2 = "$maxsize2";
\$autoresize = $autoresize;
\$tnwidth = "$tnwidth";
\$tnheight = "$tnheight";
\$upbc = $upbc;
\$noguestp = $noguestp;
\$invfri = $invfri;
\$sppd = $sppd;
\$al = $al;
\$whereis = $whereis;
\$showmove = $showmove;
\$apic = $apic;
\$hmail = $hmail;
\$slpoller = $slpoller;
\$BCSmile = $BCSmile;
\$BCLoad = $BCLoad;
\$showreg = $showreg;
\$pmmaxquota = "$pmmaxquota";
\$maxsig = "$maxsig";
\$gtoff = '$gtoff';
\$datedisv2 = "$datedisv2";
\$maxmess = $maxmess;
\$maxdis = $maxdis;
\$mbname = q*$mbname*;
\$picheight = "$picheight";
\$picwidth = "$picwidth";
\$btod = $btod;
\$mmpp = $mmpp;
\$iptimeout = $iptimeout;
\$vhtdmax = $vhtdmax;
\$htdmax = $htdmax;
\$enews = $enews;
\$showgender = $showgender;
\$totalpp = $totalpp;
\$memguest = $memguest;
\$gsearch = $gsearch;
\$showdes = $showdes;
\$sall = $sall;
\$vradmin = $vradmin;
\$showtheme = $showtheme;
\$sview = $sview;
\$quickreg = $quickreg;
\$showactive = $showactive;
\$logactive = $logactive;
\$showevents = $showevents;
\$reversesum = $reversesum;
\$gdisable = $gdisable;
\$redirectfix = $redirectfix;
\$pmdisable = $pmdisable;
\$languagep = "$languagep";
\$allowrate = $allowrate;
\$nocomma = qq~$nocomma~;
\$html = $html;
\@htmls = ($htmls);
\$hiddenmail = $hiddenmail;
\$nonotify = $nonotify;
\$polltop = $polltop;
\$pollops = "$pollops";
\$gtzone = "$gtzone";
\$quickreply = $quickreply;
\$gmaxsmils = $gmaxsmils;
\$maxmesslth = $maxmesslth;
\$maxsumc = "$maxsumc";
\$upevents = $upevents;
\$hideposts = $hideposts;
\$ensids = $ensids;
\$showlocation = $showlocation;
\$enbdays = $enbdays;
\$emailadmin = $emailadmin;
\$maxattempts = $maxattempts;
\$loginfailtime = $loginfailtime;
\$enablerep = $enablerep;
\$modifytime = $modifytime;
\$gattach = $gattach;
\$maxmodifycount = $maxmodifycount;
\$showloggedon = $showloggedon;
\$disablesn = $disablesn;
\$disabledel = $disabledel;
\$fancyqprofile = $fancyqprofile;
\$enablecal = $enablecal;
\$showads = $showads;
\$displayadverts = qq~$displayadverts~;
\$disableads = "$disableads";
\$nocomputers = "$nocomputers";
\$forumstats = $forumstats;
\$eclick = $eclick;
\$uextlog = $uextlog;
\$kelog = $kelog;
\$logip = $logip;
\$logcnt = "$logcnt";
\$logdays = $logdays;
\$activeuserslog = $activeuserslog;
\$hideclog = $hideclog;
\$hideelog = $hideelog;
\$newsboard = "$newsboard";
\$newsshow = $newsshow;
\$newslength = $newslength;
\$yabbconver = $yabbconver;
\$encryption = $encryption;
\$md5upgrade = $md5upgrade;
\$akismetkey = '$akismetkey';
\$akismetcheck = $akismetcheck;
\$showage = $showage;
\$repscore = $repscore;
\$menutext = $menutext;
\$posttext = $posttext;
\$indextext = $indextext;
\$advancedhtml = $advancedhtml;
\$glimpsecnt = $glimpsecnt;
\$xhtmlct = $xhtmlct;
\$BCAdvanced = $BCAdvanced;
\$tagsenable = $tagsenable;
\$autotag = $autotag;
1;
EOT

	$printtofile =~ s~\$(.*?) \= ;~\$$1 \= 0;~sig; # Check for blanks (error handeling)

	# Print and redirect
	fopen(FILE,"+>$root/Settings.pl");
	print FILE $printtofile;
	fclose(FILE);
	redirect("$surl\lv-admin/r-3/");
}

sub RemoveSpectators {
	is_admin(4.2);

	if($URL{'p'} == 2) {
		fopen(FILE,"$members/List.txt");
		@list = <FILE>;
		fclose(FILE);
		chomp @list;
		if($FORM{'days'} !~ /[0-9]/) { error($admintxt2[155]); }
		if($FORM{'posts'} !~ /[0-9]/) { error($admintxt2[156]); }
		$time = time;
		$days = $time-($FORM{'days'}*86400);
		$active = $logactive ? $time-($FORM{'active'}*86400) : 1;

		$title = $admintxt2[161];
		headerA();
		$ebout .= <<"EOT";
<form action="$surl\lv-admin/a-delspec/p-3/" method="post">
<table class="border" cellpadding="5" cellspacing="1" width="97%">
 <tr>
  <td class="titlebg"><strong><img src="$images/mem_main.gif" alt="" /> $title</strong></td>
 </tr><tr>
  <td class="win smalltext">$admintxt2[264]</td>
 </tr><tr>
  <td class="win2">
   <table cellpadding="5" cellspacing="0" width="100%">
    <tr>
     <td style="width: 30%" class="catbg"><strong>$admintxt2[263]</strong></td>
     <td style="width: 25%" class="center catbg"><strong>$admintxt2[262]</strong></td>
     <td style="width: 25%" class="catbg"><strong>$admintxt2[261]</strong></td>
     <td style="width: 20%" class="center catbg"><strong>$admintxt2[203]</strong></td>
    </tr>
EOT
		$counts = 0;
		foreach (@list) {
			GetMemberID($_);
			$deletea = $memberid{$_}{'registered'}-$days;
			$deleteb = $memberid{$_}{'lastactive'}-$active;
			$fnd = 0;
			$posts = ($memberid{$_}{'posts'}-$FORM{'posts'});
			next if($FORM{'validate'} && !$memberid{$_}{'status'});
			if($deletea <= 0 && $deleteb <= 0) {
				if($posts <= 0 && $username ne $_) {
					if($username ne $_) {
						if($memberid{$_}{'lastactive'}) { $lastact = get_date($memberid{$_}{'lastactive'}); }
							else { $lastact = $gtxt{'13'}; }
						$ebout .= <<"EOT";
<tr>
 <td>$userurl{$_} &nbsp; (<i>$_</i>)</td>
 <td class="center smalltext">$memberid{$_}{'posts'}</td>
 <td class="smalltext">$lastact</td>
 <td class="center"><input type="checkbox" name="$counts" value="$_" checked="checked" /></td>
</tr>
EOT
					}
					++$counts;
				}
			}
		}
		if($counts == 0) {
			$ebout .= <<"EOT";
<tr>
 <td colspan="4" class="center smalltext"><br />$admintxt2[260]<br /><br /></td>
</tr>
EOT
		}
		$ebout .= <<"EOT";
   </table>
  </td>
 </tr><tr>
  <td class="win center" colspan="2"><input type="hidden" name="cnt" value="$counts" /><input type="submit" value=" $admintxt2[168] " /></td>
 </tr>
</table>
</form>
EOT
		footerA();
		exit;
	} elsif($URL{'p'} == 3) {
		for($dsp = 0; $dsp < $FORM{'cnt'}; ++$dsp) {
			$deldata = $FORM{$dsp};
			if($deldata eq '') { next; }
			$killymems .= "$deldata,";
		}
		CoreLoad('Moderate');
		KillGroups($killymems,1);

		redirect("$surl\lv-admin/r-3/");
	}

	$title = $admintxt2[161];
	headerA();
	$ebout .= <<"EOT";
<form action="$surl\lv-admin/a-delspec/p-2/" method="post">
<table class="border" cellpadding="4" cellspacing="1" width="500">
 <tr>
  <td class="titlebg"><strong><img src="$images/mem_main.gif" alt="" /> $title</strong></td>
 </tr><tr>
  <td class="win smalltext">$admintxt2[162]</td>
 </tr><tr>
  <td class="catbg smalltext"><strong>$admintxt2[163]</strong></td>
 </tr><tr>
  <td class="win2">
   <table cellpadding="3" cellspacing="0">
    <tr>
     <td class="vtop"><input type="text" value="60" name="days" size="4" /></td>
     <td><strong>$admintxt2[164]</strong></td>
    </tr><tr>
     <td class="vtop"><input type="text" value="30" name="active" size="4" /></td>
     <td><strong>$admintxt2[165]</strong></td>
    </tr><tr>
     <td class="vtop"><input type="text" value="5" name="posts" size="4" /></td>
     <td><strong>$admintxt2[166]</strong></td>
    </tr><tr>
     <td class="vtop right"><input type="checkbox" value="1" name="validate" /></td>
     <td><strong>$admintxt2[411]</strong></td>
    </tr>
   </table>
  </td>
 </tr><tr>
  <td class="win center" colspan="2"><input type="submit" value=" $admintxt2[259] " /></td>
 </tr>
</table>
</form>
EOT
	footerA();
	exit;
}

sub BanLog {
	is_admin(6.2);

	if($URL{'p'}) {
		unlink("$prefs/NoAccess.txt");
		redirect("$surl\lv-admin/r-3/");
	}
	$title = $admintxt2[170];
	headerA();
	$ebout .= <<"EOT";
<script type="text/javascript">
//<![CDATA[
function clear(url) {
 if(window.confirm("$admintxt2[169]")) { location = url; }
}
//]]>
</script>
<table class="border" cellpadding="3" cellspacing="1" width="650">
 <tr>
  <td class="titlebg" colspan="3"><strong>$title</strong></td>
 </tr><tr>
  <td class="win smalltext" colspan="3">$admintxt2[171]</td>
 </tr><tr>
  <td class="catbg smalltext center"><strong>$gtxt{'18'}</strong></td>
  <td class="catbg smalltext center"><strong>$admintxt2[173]</strong></td>
  <td class="catbg smalltext center"><strong>$admintxt2[174]</strong></td>
 </tr>
EOT
	fopen(FILE,"$prefs/NoAccess.txt");
	@nac = <FILE>;
	fclose(FILE);
	chomp @nac;
	foreach(@nac) {
		($user,$ip,$date) = split(/\|/,$_);
		$datetime = get_date($date);
		GetMemberID($user);
		if($memberid{$user}{'sn'}) { $memberid{$user}{'sn'} = $userurl{$user}; } else { $memberid{$user}{'sn'} = $user; }
		$ebout .= <<"EOT";
 <tr>
  <td class="win center">$ip</td>
  <td class="win2 center">$memberid{$user}{'sn'}</td>
  <td class="win center">$datetime</td>
 </tr>
EOT
	}
	if($nac[0]) {
		$ebout .= <<"EOT";
 <tr>
  <td class="catbg smalltext center" colspan="3"><strong><a href="javascript:clear('$surl\lv-admin/a-banlog/p-clear/')">$admintxt2[175]</a></strong></td>
 </tr>
EOT
	} else {
		$ebout .= <<"EOT";
 <tr>
  <td class="win center" colspan="3"><strong>$admintxt2[176]</strong></td>
 </tr>
EOT
	}
	$ebout .= "</table>";

	footerA();
	exit;
}

sub BanUser {
	is_admin(3.4);

	fopen(FILE,"$prefs/BanList.txt");
	@blist = <FILE>;
	fclose(FILE);
	chomp @blist;
	if($URL{'g'}) { BanUser2(); }
	push(@groups,$gtxt{'13'});
	$BAN{"$gtxt{'13'}"} = 0;
	foreach(@blist) {
		($ipaddy,$banlimit,$bantime,$bangrp) = split(/\|/,$_);
		if($bangrp eq '') { $bangrp = $gtxt{'13'}; }
		++$BAN{$bangrp};
		if($BAN{$bangrp} == 1 && $bangrp ne $gtxt{'13'}) { push(@groups,$bangrp); }
	}
	$title = $admintxt2[179];
	headerA();
	$ebout .= <<"EOT";
<script type="text/javascript">
//<![CDATA[
function del(grp) {
 if(window.confirm("$admintxt2[180]")) { location = '$surl\lv-admin/a-ban/g-'+grp+'/p-del/'; }
}
//]]>
</script>
<table class="border" cellpadding="4" cellspacing="1" width="500">
 <tr>
  <td class="titlebg" colspan="3"><strong><img src="$images/mem_main.gif" alt="" /> $title</strong></td>
 </tr><tr>
  <td class="win smalltext">$admintxt2[181]</td>
 </tr><tr>
  <td class="win2"><table width="100%">

EOT
	foreach(@groups) {
		++$count;
		$name = $_;
		$_ =~ s/ /_/gsi;
		if($name ne $gtxt{'13'}) { $delete = qq~<br /><strong><a href="javascript:del('$_')">$admintxt2[178]</a></strong>~; }
		$ebout .= <<"EOT";
   <tr>
    <td style="width: 5px"><strong>$count.</strong></td>
    <td><strong><a href="$surl\lv-admin/a-ban/g-$_/">$name</a></strong></td>
   </tr><tr>
    <td>&nbsp;</td>
    <td class="smalltext"><strong>$admintxt2[177]:</strong> $BAN{$name}$delete</td>
   </tr>
EOT
	}
	$ebout .= <<"EOT";
  </table></td>
 </tr>
</table>
EOT
	footerA();
	exit;
}

sub BanUser2 {
	is_admin(3.4);

	if($URL{'p'} eq 'save' || $URL{'p'} eq 'del') { BanUser3(); }
	$title = $admintxt2[179];
	headerA();
	$ebout .= <<"EOT";
<form action="$surl\lv-admin/a-ban/g-$URL{'g'}/p-save/" method="post">
<table class="border" cellpadding="4" cellspacing="1" width="600">
 <tr>
  <td class="titlebg" colspan="4"><strong><img src="$images/mem_main.gif" alt="" /> $title</strong></td>
 </tr><tr>
  <td class="win smalltext" colspan="4">$admintxt2[182]</td>
 </tr><tr>
  <td class="catbg" colspan="4">
   <table cellpadding="0" cellspacing="0" width="100%">
    <tr>
     <td style="width: 25%" class="center smalltext"><strong>$admintxt2[258]</strong></td>
     <td style="width: 25%"><strong>$admintxt2[183]</strong></td>
     <td style="width: 25%" class="center smalltext"><strong>$admintxt2[184]</strong></td>
     <td style="width: 25%"><strong>$admintxt2[185]</strong></td>
    </tr>
   </table>
  </td>
 </tr><tr>
  <td class="win2" colspan="4">
   <table cellpadding="2" cellspacing="0" width="100%">
EOT
	if($URL{'g'} =~ /_/) { $URL{'g2'} =~ s/_/ /gsi; }

	$counter = 0;
	push(@blist,"|||$URL{'g'}");
	foreach(@blist) {
		($ipaddy,$banlimit,$bantime,$bangrp) = split(/\|/,$_);
		if($bangrp eq '') { $bangrp = $gtxt{'13'}; }
		if($bangrp ne $URL{'g'} && $bangrp ne $URL{'g2'}) { next; }
		$bantime = $bantime eq '' ? $admintxt2[186] : get_date($bantime);
		$sel{$banlimit} = ' selected="selected"';
		$ebout .= <<"EOT";
    <tr>
     <td style="width: 25%"><input type="text" name="$counter-ipaddy" value="$ipaddy" /></td>
     <td style="width: 25%"><select name="$counter-banlimit"><option value="forever">forever</option><option value="1"$sel{1}>1 $admintxt2[187]</option><option value="3"$sel{3}>3 $admintxt2[187]</option><option value="7"$sel{7}>1 $gtxt{'39'}</option><option value="30"$sel{30}>1 $gtxt{'40'}</option></select></td>
     <td style="width: 25%" class="center smalltext">$bantime</td>
     <td style="width: 25%"><input type="text" name="$counter-bangrp" value="$bangrp" /></td>
    </tr>
EOT
		$sel{$banlimit} = '';
		++$counter;
	}
	$ebout .= <<"EOT";
   </table>
  </td>
 </tr><tr>
  <td class="win" colspan="4"><input type="hidden" name="vals" value="$counter" /><table width="100%"><tr><td class="smalltext"><strong><a href="$surl\lv-admin/a-ban/">$admintxt2[188]</a></strong></td><td class="right"><input type="submit" value=" $admintxt2[152] " /></td></tr></table></td>
 </tr>
</table>
</form>
EOT
	footerA();
	exit;
}

sub BanUser3 {
	is_admin(3.4);

	$xURLg = $URL{'g'};
	$URL{'g'} =~ s/_/ /gsi;
	foreach(@blist) { # Save banned list ...
		($ipaddy,$banlimit,$bantime,$bangrp) = split(/\|/,$_);
		if($bangrp eq '') { $bangrp = $gtxt{'13'}; }
		if(($bangrp ne $URL{'g'} && $bangrp ne $xURLg) && !$prev{$ipaddy}) { $all .= "$_\n"; $prev{$ipaddy} = 1; }
		$BANA{$ipaddy} = $banlimit;
		$BANB{$ipaddy} = $bantime;
	}

	if($URL{'p'} eq 'save') {
		for($x = 0; $x < $FORM{'vals'}; $x++) {
			$updatetime = '';
			$ipaddy = $FORM{"$x-ipaddy"};
			if(!$ipaddy || $prev{$ipaddy}) { next; }
			$FORM{'$x-bangrp'} =~ s/ /_/g;
			$FORM{'$x-bangrp'} =~ s/[#%+,\\\/:?"<>'|@^\$\&~'\)\(\]\[\;{}!`=-]//g;

			if($FORM{"$x-banlimit"} ne $BANA{$ipaddy}) { $updatetime = time+($FORM{"$x-banlimit"}*86400); }
			elsif($BANB{$ipaddy}) { $updatetime = $BANB{$ipaddy}; }
			if($FORM{"$x-banlimit"} eq 'forever') { $FORM{"$x-banlimit"} = ''; $updatetime = ''; }

			$all .= qq~$FORM{"$x-ipaddy"}|$FORM{"$x-banlimit"}|$updatetime|$FORM{"$x-bangrp"}\n~;
			$prev{$ipaddy} = 1;
		}
	}

	fopen(FILE,">$prefs/BanList.txt");
	print FILE $all;
	fclose(FILE);
	redirect("$surl\lv-admin/a-ban/");
}

sub Censor {
	is_admin(1.4);

	if($URL{'s'}) { Censor2(); }
	$title = $admintxt2[200];
	headerA();
	$ebout .= <<"EOT";
<script type="text/javascript">
//<![CDATA[
function clear(url) {
 if(window.confirm("$admintxt2[199]")) { location = url; }
}
//]]>
</script>
<form action="$surl\lv-admin/a-censor/s-1/" method="post">
<table class="border" cellpadding="4" cellspacing="1" width="450">
 <tr>
  <td class="titlebg" colspan="3"><input type="hidden" value="ok" name="ok" /><strong><img src="$images/ban.png" alt="" /> $title</strong></td>
 </tr><tr>
  <td class="catbg smalltext"><strong>$admintxt2[201]</strong></td>
  <td class="catbg smalltext"><strong>$admintxt2[202]</strong></td>
  <td class="catbg smalltext center" style="width: 60px"><strong>$admintxt2[203]</strong></td>
 </tr>
EOT
	fopen(FILE,"$prefs/Censor.txt");
	@censor = <FILE>;
	fclose(FILE);
	chomp @censor;
	$counter = 0;
	foreach(@censor) {
		($censor,$change) = split(/\|/,$_);
		$ebout .= <<"EOT";
 <tr>
  <td class="win center"><input type="text" name="censor_$counter" value="$censor" /></td>
  <td class="win2 center"><input type="text" name="change_$counter" value="$change" /></td>
  <td class="win center"><input type="checkbox" name="del_$counter" value="1" /></td>
 </tr>
EOT
		++$counter;
	}
	if(!$censor[0]) {
		$ebout .= <<"EOT";
 <tr>
  <td class="win2 smalltext center" colspan="3"><br />$admintxt2[204]<br /><br /></td>
 </tr>
EOT
	}
	$ebout .= <<"EOT";
 <tr>
  <td class="catbg" colspan="3"><strong>$admintxt2[205]</strong></td>
 </tr><tr>
  <td class="win center"><input type="text" name="censor_new" /></td>
  <td class="win center" colspan="2"><input type="text" name="change_new" /></td>
 </tr><tr>
  <td class="win2 center" colspan="3"><input type="hidden" name="cnt" value="$counter" /><input type="submit" name="submit" value=" $admintxt2[152] " /></td>
 </tr>
</table>
</form>
EOT
	footerA();
	exit;
}

sub Censor2 {
	is_admin(1.4);

	while(($in,$out) = each(%FORM)) {
		$output = Format($out);
		$FORM{$in} = $output;
	}
	fopen(FILE,"+>$prefs/Censor.txt");
	for($i = 0; $i < $FORM{'cnt'}; $i++) {
		$FORM{"change_$i"} =~ s/\(|\)|\[|\]|\||\\|\///g;
		$FORM{"censor_$i"} =~ s/\(|\)|\[|\]|\||\\|\///g;
		if(!$FORM{"del_$i"}) { print FILE qq~$FORM{"censor_$i"}|$FORM{"change_$i"}\n~; }
	}
	if($FORM{'censor_new'} ne '') { print FILE "$FORM{'censor_new'}|$FORM{'change_new'}\n"; }
	fclose(FILE);

	redirect("$surl\lv-admin/a-censor/");
}

sub PostIcons {
	is_admin(1.5);

	my($group,$file,$name,$i);

	$counter = (keys %FORM)-1;
	$counter /= 3;

	if($FORM{'submit'}) {
		@icons = ();
		for($i = 0; $i < $counter; ++$i) {
			$group = Format($FORM{"group_$i"});
			$icon  = Format($FORM{"icon_$i"});
			$name  = Format($FORM{"name_$i"});

			if($icon eq '' || $FORM{"del_$i"}) { next; }

			push(@icons,qq~$group|$icon|$name|$FORM{"members_$i"}~);
		}

		fopen(FILE,">$prefs/MessageIcons.txt");
		foreach(@icons) { print FILE "$_\n"; }
		fclose(FILE);

		redirect("$surl\lv-admin/a-posticons/");
	}

	$title = $admintxt[218];
	headerA();
	$ebout .= <<"EOT";
<form action="$surl\lv-admin/a-posticons/" method="post">
<table cellpadding="5" cellspacing="1" width="98%" class="border">
 <tr>
  <td class="titlebg">$title</td>
 </tr><tr>
  <td class="win">$admintxt2[369]</td>
 </tr><tr>
  <td class="win2">
   <table cellpadding="4" cellspacing="0" width="100%">
    <tr>
     <td class="catbg center"><img src="$images/ban.png" /></td>
     <td style="width: 25%" class="catbg">$admintxt2[370]</td>
     <td style="width: 25%" class="catbg center">$admintxt2[371]</td>
     <td style="width: 25%" class="catbg center">$admintxt2[372]</td>
     <td style="width: 25%" class="catbg center">$admintxt2[373]</td>
    </tr><tr>
     <td class="center">-</td>
     <td class="center">xx.gif</td>
     <td class="win center">$var{0}</td>
     <td></td>
     <td></td>
    </tr>
EOT
	$counter = 0;

	fopen(FILE,"$prefs/MessageIcons.txt");
	@icons = <FILE>;
	fclose(FILE);

	push(@icons,('','',''));

	foreach(@icons) {
		($group,$file,$name,$memgroups) = split(/\|/,$_);

		if($file eq '' && !$shown) {
			$ebout .= qq~<tr><td colspan="5" class="catbg">$admintxt2[374]</td></tr>~;
			$shown = 1;
			$del = '';
		}
		if(!$shown) { $del = qq~<input type="checkbox" name="del_$counter" value="1" />~; }
		$ebout .= <<"EOT";
    <tr>
     <td class="center">$del</td>
     <td class="center"><input type="text" name="icon_$counter" value="$file" size="40" /></td>
     <td class="win center"><input type="text" name="name_$counter" value="$name" size="40" /></td>
     <td class="center"><input type="text" name="group_$counter" value="$group" size="40" /></td>
     <td class="center"><input type="text" name="members_$counter" value="$memgroups" size="40" /></td>
    </tr>
EOT
		++$counter;
	}
	$ebout .= <<"EOT";
    <tr>
     <td colspan="5" class="catbg center"><input type="submit" name="submit" value="$admintxt2[375]" /></td>
    </tr>
   </table>
  </td>
 </tr>
</table>
</form>
EOT
	footerA();
}
1;