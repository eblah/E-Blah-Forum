#############################################
# E-Blah Bulletin Board Systems        2008 #
#############################################
# Copyright (c) 2001 - 2008 E-Blah.         #
#############################################

if($members{'Administrator',$username}) { $disablesn = 0; }

sub SaveSettings {
	is_secure('profile_kick');

	$url = "$surl\lv-memberpanel/a-$URL{'as'}/u-$URL{'u'}/s-$URL{'s'}/";
	$INP{'message'} = $FORM{'message'};

	while(($iname,$ivalue) = each(%FORM)) {
		$ivalue =~ s~\A\s+~~;
		$ivalue =~ s~\s+\Z~~;
		$ivalue =~ s~[\n\r]~~g;
		$FORM{$iname} = Format($ivalue);
	}

	if($FORM{'caller'} == 1) {
		error($profiletxt[64]) if($FORM{'sn'} eq '' && !$disablesn);
		error($profiletxt[66]) if($FORM{'sn'} !~ /\A[0-9A-Za-z#%+,-\.@†^_ "']+\Z/ && !$disablesn);
		error($profiletxt[67]) if(length($FORM{'sn'}) > 30);
		error($profiletxt[65]) if($FORM{'email'} !~ /\A([0-9A-Za-z\._\-]{1,})@([0-9A-Za-z\._\-]{1,})+\.([0-9A-Za-z\._\-]{1,})+\Z/);
		error($profiletxt[68]) if(length($FORM{'email'}) > 60);

		$remem = 1;

		UserDatabase();
		$bah = $FORM{'sn'};
		$bah =~ s/ |_//g;

		if(!$disablesn) {
			fopen(FILE,"$prefs/Names.txt");
			while(<FILE>) {
				chomp $_;
				($searchme,$within) = split(/\|/,$_);
				$searchme = lc($searchme);
				$searchme =~ s/ |_//g;
				if($within) { error($profiletxt[69]) if(lc($bah) =~ /\Q$searchme\E/gsi); }
					else { error($profiletxt[69]) if($searchme eq lc($bah)); }
			}
			fclose(FILE);
		}

		foreach(@memlist2) {
			($un,$sn,$t,$t,$t,$mail) = split(/\|/,$_);
			$sn =~ s/ |_//g;

			if(lc($un) ne lc($URL{'u'})) {
				if((lc($bah) eq lc($sn) || lc($un) eq lc($bah)) && !$disablesn) { error($profiletxt[69]); }
				if(lc($FORM{'email'}) eq lc($mail)) { error($profiletxt[70]); }
			}
		}

		fopen(FILE,"$prefs/BanList.txt");
		@banlist = <FILE>;
		fclose(FILE);
		chomp @banlist;
		foreach(@banlist) {
			($banstring) = split(/\|/,$_);
			if($banstring eq $FORM{'email'}) { error($profiletxt[70]); }
		}

		$FORM{'aim'} =~ s/ /+/gsi;

		if(!$members{'Administrator',$username} && (($memberid{$URL{'u'}}{'email'} ne lc($FORM{'email'})) && $vradmin)) {
			$formid = sprintf("%.0f",rand(int((time)/9)*7000));
			$newuser->[23] = 'EMAIL';

			$revalidate = <<"EOT";
$profiletxt[301]
<a href="$rurl\lv-register/a-validate/id-$formid/u-$URL{'u'}/">$rurl\lv-register/a-validate/id-$formid/u-$URL{'u'}/</a>

$gtxt{'25'}!
EOT
			smail($FORM{'email'},$profiletxt[302],$revalidate);

			$url = "$surl\lv-register/p-finish/u-$URL{'u'}/";
		}

		if(!$disablesn) {
			if($FORM{'sn'} ne $memberid{$URL{'u'}}{'sn'}) { $remem = 1; }
			$addtoID{'sn'} = $FORM{'sn'};
		}

		$email = lc($FORM{'email'});

		$addtoID{'email'} = $email;
		$addtoID{'aim'}   = $FORM{'aim'};
		$addtoID{'msn'}   = $FORM{'msn'};
		$addtoID{'icq'}   = $FORM{'icq'};
		$addtoID{'yim'}   = $FORM{'yim'};
		$addtoID{'skype'} = $FORM{'skype'};
	} elsif($FORM{'caller'} == 2) {
		if($FORM{'newpw'} ne '') {
			error($profiletxt[84]) if($FORM{'newpw'} ne $FORM{'newpwc'});
			error($profiletxt[85]) if(length($FORM{'newpw'}) > $pwlength);

			if($yabbconver) {
				$FORM{'oldpw'} = Encrypt($FORM{'oldpw'});
				if($md5upgrade) {
					$encryption = 2;
					$memberid{$username}{'md5upgrade'} = 1;
					$addtoID{'md5upgrade'} = 1;
				}
				$FORM{'newpw'} = Encrypt($FORM{'newpw'});
			}
	
			error($profiletxt[86]) if($FORM{'newpw'} eq '');
			error($profiletxt[87]) if($memberid{$URL{'u'}}{'password'} ne $FORM{'oldpw'} && !$members{'Administrator',$username});
	
			$addtoID{'password'} = $FORM{'newpw'};
	
			smail($memberid{$URL{'u'}}{'email'},$profiletxt[231],qq~$profiletxt[232] <strong>$FORM{'newpwc'}</strong>\n\n$rurl\n\n$gtxt{'25'}~);
	
			if($username eq $URL{'u'}) { $url = "$surl\lv-login/"; }
		}
		if($members{'Administrator',$URL{'u'}}) {
			if(($memberid{$URL{'u'}}{'adminverify'} ne '' && $FORM{'oldverify'} ne '') || ($memberid{$URL{'u'}}{'adminverify'} eq '' && $FORM{'newver'} ne '')) {
				require Digest::MD5;
				import Digest::MD5 qw(md5_hex);
				$FORM{'oldverify'} = md5_hex($FORM{'oldverify'});
				if($FORM{'newver'} ne '') {
					$FORM{'newver'} = md5_hex($FORM{'newver'});
					$FORM{'newverc'} = md5_hex($FORM{'newverc'});
				}
	
				error($profiletxt[312]) if($memberid{$URL{'u'}}{'adminverify'} ne '' && $memberid{$URL{'u'}}{'adminverify'} ne $FORM{'oldverify'});
				error($profiletxt[311]) if($FORM{'newver'} ne $FORM{'newverc'});
	
				$addtoID{'adminverify'} = $FORM{'newver'};
			}
		} else { $addtoID{'adminverify'} = ''; }
	} elsif($FORM{'caller'} == 3) { # Signature
		if($maxsig && length($INP{'message'}) > $maxsig) { error($profiletxt[74]); }
		$addtoID{'sig'} = Format($INP{'message'});
	} elsif($FORM{'caller'} == 4) {
		if($memberid{$URL{'u'}}{'avatarupload'} && ($FORM{'avcust'} || $FORM{'ulfile'} || $FORM{'avatartype'} == 3 || $FORM{'avatartype'} == 1)) {
			$memberid{$URL{'u'}}{'avatar'} =~ s/$uploadurl\///gsi;
			unlink("$uploaddir/$memberid{$URL{'u'}}{'avatar'}");
			$addtoID{'avatarupload'} = '';
			$addtoID{'avatar'} = '';
		}

		if($FORM{'avatartype'} == 1 && $FORM{'av'}) {
			if(!-e("$avdir/$FORM{'av'}")) { $FORM{'av'} = ''; }
			$addtoID{'avatar'} = $FORM{'av'};
		}
		elsif($apic == 1 && $FORM{'avatartype'} == 2 && ($FORM{'avcust'} && $FORM{'avcust'} =~ /(http|ftp|mms|https):\/\/(.[^\s\n]+?)$/)) { $addtoID{'avatar'} = $FORM{'avcust'}; }
		elsif($FORM{'avatartype'} == 2 && $FORM{'ulfile'}) {
			$allowedext = "gif,jpg,jpeg,png,bmp,png";
			$maxsize = $maxsize2;
			CoreLoad('Attach'); Upload();
			$addtoID{'avatar'} = $atturl;
			$addtoID{'avatarupload'} = 1;
		} elsif($memberid{$URL{'u'}}{'avatarupload'}) { 1; }
			else { $addtoID{'avatar'} = ''; }

		if($FORM{'picwidth'} && $FORM{'picwidth'} <= $picwidth) { $width = $FORM{'picwidth'}; } else { $width = $picwidth; }
		if($FORM{'picheight'} && $FORM{'picheight'} <= $picheight) { $height = $FORM{'picheight'}; } else { $height = $picheight; }
		if($height && $width) { $addtoID{'avatarsize'} = "$height|$width"; }
			else { $addtoID{'avatarsize'} = ''; }
	} elsif($FORM{'caller'} == 5) {
		$remem = 1;

		$personaltext = Format($FORM{'pt'});
		if(length($personaltext) > 50) { error($profiletxt[63]); }

		if($FORM{'dd'} && $FORM{'mm'} && $FORM{'yyyy'}) {
			if($FORM{'yyyy'} < 0 || $FORM{'mm'} > 12 || $FORM{'mm'} < 0 || $FORM{'dd'} > 31 || $FORM{'dd'} < 0) { error($profiletxt[158]); }
			$birthday = "$FORM{'mm'}/$FORM{'dd'}/$FORM{'yyyy'}";
		}

		$siteurl = $FORM{'url'};
		if($siteurl && $siteurl !~ /http:\/\/(.*?)\Z/ && $1 eq '') { error($profiletxt[75]); }
		if($siteurl eq 'http://') { $siteurl = ''; }
		if($siteurl eq '') { $FORM{'sname'} = ''; }
		if($FORM{'sname'} eq '') { $siteurl = ''; }


		%addtoID = (
			'personaltxt' => $personaltext,
			'sex'         => $FORM{'sex'},
			'dob'         => $birthday,
			'sitename'    => $FORM{'sname'},
			'siteurl'     => $FORM{'url'},
			'location'    => $FORM{'location'}
		);
	} elsif($FORM{'caller'} == 6) {
		%addtoID = (
			'hidemail'    => $FORM{'hidemail'},
			'hideonline'  => $FORM{'hideonline'},
			'ml'          => $FORM{'mailing'},
			'hidesum'     => $FORM{'showsums'},
			'notify'      => $FORM{'notify'},
			'shownewonly' => $FORM{'onlynew'},
			'showsig'     => $FORM{'signature'},
			'ownavatar'   => $FORM{'avatar'},
			'censor'      => $FORM{'censor'},
			'pmpopup'     => $FORM{'pmpop'},
			'bcadvanced'  => $FORM{'bcadvanced'}
		);
	} elsif($FORM{'caller'} == 7) {
		if($FORM{'datetype'} == 2) { $FORM{'dformat'} = $FORM{'dformata'}; $FORM{'tformat'} = ''; }
		%addtoID = (
			'timezone'   => $FORM{'toff'},
			'dateformat' => $FORM{'dformat'},
			'timeformat' => $FORM{'tformat'},
			'dst'        => $FORM{'tcng'}
		);
	} elsif($FORM{'caller'} == 8) {
		$FORM{'theme'} =~ s/&#124;/\|/g;
		($themename) = split(/\|/,$FORM{'theme'});
		if(!-e("$templates/$themename/theme.dat") && $themename ne '') { error($profiletxt[73]); }
		if($theme{$themename,'default'}) { $themename = ''; }

		%addtoID = (
			'theme' => $themename,
			'lng'   => $FORM{'lng'}
		);
	} elsif($FORM{'caller'} == 9) { # Administrators options
		is_admin(-1);
		$remem = 1;
		use Time::Local 'timelocal';
		if(!$FORM{'posts'}) { $FORM{'posts'} = 0; }
		if($memberid{$URL{'u'}}{'status'} ne 'EMAIL' && $FORM{'status'} ne 'EMAIL') { $status = $FORM{'status'}; }

		if($FORM{'keytype'} ne '') {
			if($FORM{'keytype'} eq "TEMP") {
				($date2,$time2) = split(" at ",$FORM{'active'});
				($mm2,$dd2,$yy2) = split(/\//,$date2);
				($hh2,$mi2,$ss2) = split(":",$time2);
				$yy2 += 100;
				--$mm2;
				eval { $stime = timelocal($ss2,$mi2,$hh2,$dd2,$mm2,$yy2); };
				if($stime eq '') { $stime = time; }
				$extrakey = "$FORM{'max'}|$stime\n";
			}
			fopen(FILE,">$members/$URL{'u'}.lo");
			print FILE "$FORM{'keytype'}\n$extrakey";
			fclose(FILE);
		} else { unlink("$members/$URL{'u'}.lo"); }

		($date,$time) = split(" at ",$FORM{'regid'});
		($mm,$dd,$yy) = split(/\//,$date);
		($hh,$mi,$ss) = split(":",$time);
		$yy += 100;

		--$mm;
		eval { $registered = timelocal($ss,$mi,$hh,$dd,$mm,$yy); };

		$addtoID{'posts'} = $FORM{'posts'};

		foreach(split(',',$FORM{'pos'})) { $become{$_} = 1; }
		foreach $write (@globalgroups) {
			if($write =~ /(.+?) => {/) { $open = $1; }
			elsif($write =~ /}/ && $open ne '') { $open = ''; }
			elsif($write =~ /(.+?) = \((.*?)\)/) {
				$type  = $1;
				$value = $2;
				$newwrite = '';
				foreach(split(',',$value)) {
					if($type eq 'waiting') {
						if($URL{'u'} eq $_ && $become{$open}) { next; }
					}
					else {
						if($type eq 'manager' && $URL{'u'} eq $_) { $man{$open} = 1; }
						if($URL{'u'} eq $_) { next; }
					}
					$newwrite .= "$_,";
				}
				if(($1 ne 'waiting' && !($1 eq 'manager' && !$man{$open})) && $become{$open}) { $newwrite .= "$URL{'u'},"; }
				$newwrite =~ s/,\Z//s;
				$write = "$type = ($newwrite)";
			}
			$printnew .= "$write\n";
		}

		fopen(FILE,">$prefs/Ranks2.txt");
		print FILE $printnew;
		fclose(FILE);

		$addtoID{'status'} = $status;

		if($registered ne '') { $addtoID{'registered'} = $registered; }
		$addtoID{'pmdisable'} = $FORM{'pm'};
		$addtoID{'admintxt'} = $FORM{'admintext'};
	} elsif($FORM{'caller'} == 10 || $URL{'caller'} == 10) {
		@blockeduserlist = split(/\|/,$memberid{$URL{'u'}}{'blockedusers'});

		if($URL{'remove'}) {
			$addtoID{'blockedusers'} = '';
			foreach(@blockeduserlist) { $addtoID{'blockedusers'} .= "$_|" if($URL{'remove'} ne $_); }
		} else {
			$FORM{'1'} =~ s/\ //gsi;
			fopen(FILE,"$members/List.txt");
			@list = <FILE>;
			fclose(FILE);
			foreach(@list) {
				chomp $_;
				GetMemberID($_);
				$memberscreenname = $memberid{$_}{'sn'};
				$memberscreenname =~ s/ //gsi;
				if(lc($memberscreenname) eq lc($FORM{'1'}) || lc($_) eq lc($FORM{'1'})) { $FORM{'1'} = $_; $fnduser = 1; last; }
			}

			if($FORM{'1'} eq 'Guest') { $fnduser = 1; }
			foreach(@blockeduserlist) {
				if($_ eq $FORM{'1'}) { $fnduser = 0; }
			}
			if($fnduser) { $addtoID{'blockedusers'} = "$memberid{$URL{'u'}}{'blockedusers'}$FORM{'1'}|"; }
				else { error($profiletxt[265]); }
		}
	} #elsif($subsection{$FORM{'caller'}}) {
	#	foreach(split(/\//,$subsectvar{$FORM{'caller'}})) { $thisid{$_} = 1; }

	#	fopen(FILE,"$prefs/ProfileVariables.txt");
	#	@varibles = <FILE>;
	#	fclose(FILE);
	#	chomp @varibles;

	#	foreach(@varibles) {
	#		($t,$optionid,$t,$type,$valuesvote) = split(/\|/,$_);
	#		if(!$thisid{$optionid}) { next; }
	#		if($type == 1) { $addtoID{$optionid} = $FORM{$optionid} ne '' ? 1 : 0; }
	#		elsif($type == 3) {
	#			foreach $vv (split(/\//,$valuesvote)) {
	#				$tester{$vv} = 1;
	#			}
	#			$addtoID{$optionid} = $tester{$FORM{$optionid}} ? $FORM{$optionid} : '';
	#		} else {
	#			$addtoID{$optionid} = $FORM{$optionid};
	#		}
	#	}
	#}
	elsif($URL{'c'} eq 'reset') {
		is_admin(-1);
		$resetme .= sprintf("%.0f",rand(int((time)/90)*9000));
		$resetme =~ tr/15973/MaZDnfJflkJHC/;
		smail($memberid{$URL{'u'}}{'email'},$profiletxt[231],qq~$profiletxt[232] <strong>$resetme</strong>\n\n$rurl\n\n$gtxt{'25'}~);
		if($yabbconver) { $resetme = Encrypt($resetme); }
		$addtoID{'password'} = $resetme;
		if($username eq $URL{'u'}) { $url = "$surl\lv-login/"; }
	} else { error($gtxt{'bfield'}); }

	# Save ID, Get ID, Reindex Database, Quit

	SaveMemberID($URL{'u'});

	GetMemberID($URL{'u'},'force');

	UserDatabase($URL{'u'},$memberid{$URL{'u'}}{'sn'},$memberid{$URL{'u'}}{'posts'},$memberid{$URL{'u'}}{'registered'},$memberid{$URL{'u'}}{'dob'},$memberid{$URL{'u'}}{'email'},$memberid{$URL{'u'}}{'rep'}) if($remem);

	redirect();
}

sub AdminLoad {
	is_admin(-1);
	fopen(FILE,"$members/$URL{'u'}.lo");
	@key = <FILE>;
	fclose(FILE);
	chomp @key;
	$KEY{$key[0]} = ' selected="selected"';

	# Key Time
	if($key[1] ne '') { ($max,$active) = split(/\|/,$key[1]); } else { $active = time; }
	($ss2,$mi2,$hh2,$dd2,$mm2,$yy2) = localtime($active);
	++$mm2;
	if($ss2 < 10) { $ss2 = "0$ss2"; }
	if($mi2 < 10) { $mi2 = "0$mi2"; }
	if($hh2 < 10) { $hh2 = "0$hh2"; }
	if($dd2 < 10) { $dd2 = "0$dd2"; }
	if($mm2 < 10) { $mm2 = "0$mm2"; }
	$yy2 -= 100;
	if($yy2 < 10) { $yy2 = "0$yy2"; }

	# Register Date
	($ss,$mi,$hh,$dd,$mm,$yy) = localtime($memberid{$URL{'u'}}{'registered'});
	++$mm;
	if($ss < 10) { $ss = "0$ss"; }
	if($mi < 10) { $mi = "0$mi"; }
	if($hh < 10) { $hh = "0$hh"; }
	if($dd < 10) { $dd = "0$dd"; }
	if($mm < 10) { $mm = "0$mm"; }
	$yy -= 100;
	if($yy < 10) { $yy = "0$yy"; }

	$status{$memberid{$URL{'u'}}{'status'}} = ' selected="selected"';
	$PM{$memberid{$URL{'u'}}{'pmdisable'}} = ' checked="checked"';

	$morecaller = $profiletxt[252];

	$displaycenter .= <<"EOT";
<tr>
 <td class="catbg smalltext"><strong>$profiletxt[242]</strong></td>
</tr><tr>
 <td class="win" style="padding: 0px">
  <table cellpadding="5" cellspacing="0" class="innertable">
   <tr>
    <td class="win2" rowspan="4" style="width: 35px"></td>
    <td class="win3" rowspan="4" style="width: 35px"></td>
    <td><strong>$profiletxt[96]:</strong></td>
    <td><input type="text" name="posts" value="$memberid{$URL{'u'}}{'posts'}" size="10" /></td>
   </tr><tr>
    <td><strong>$profiletxt[304]:</strong></td>
    <td><input type="text" name="admintext" value="$memberid{$URL{'u'}}{'admintxt'}" size="25" maxlength="30" /></td>
   </tr><tr>
    <td><strong>$profiletxt[136]:</strong></td>
    <td><input type="text" name="regid" value="$mm/$dd/$yy at $hh:$mi:$ss" size="25" /></td>
   </tr><tr>
    <td>&nbsp;</td>
    <td class="smalltext">$profiletxt[137]</td>
   </tr><tr>
    <td class="center vtop win2"><input type="checkbox" name="pm" value="1"$PM{1} /></td>
    <td class="center win3"><img src="$images/pm2_sm.gif" alt="" /></td>
    <td colspan="2"><strong>$profiletxt[250]</strong><div class="smalltext">$profiletxt[251]</div></td>
   </tr>
  </table>
 </td>
</tr><tr>
 <td class="catbg smalltext"><strong>$profiletxt[204]</strong></td>
</tr><tr>
 <td class="win" style="padding: 5px">
  <table cellpadding="5" cellspacing="0" class="innertable">
   <tr>
    <td class="right vtop"><strong>$profiletxt[97]:</strong></td>
    <td colspan="2"><select size="5" name="pos" multiple="multiple">
EOT

	foreach(@fullgroups) {
		if($permissions{$_,'pcount'} ne '' || $_ eq 'Moderators') { next; }
		$select{1} = '';
		$select{$members{$_,$URL{'u'}}} = ' selected="selected"';
		$displaycenter .= qq~<option value="$_"$select{1}>$permissions{$_,'name'}</option>~;
	}

	$displaycenter .= <<"EOT";
    </select></td>
   </tr>
   <tr>
    <td><strong>$profiletxt[131]:</strong></td>
    <td><select name="status"><option value=""$status{''}>$profiletxt[133]</option><option value="ADMIN"$status{'ADMIN'}>$profiletxt[134]</option><option value="EMAIL"$status{'EMAIL'}>$profiletxt[156]</option><option value="DISABLE"$status{'DISABLE'}>$profiletxt[135]</option></select></td>
   </tr>
  </table>
 </td>
</tr><tr>
 <td class="catbg smalltext"><strong>$profiletxt[243]</strong></td>
</tr><tr>
 <td class="win" style="padding: 5px">
  <table cellpadding="5" cellspacing="0" class="innertable">
   <tr>
    <td class="center" style="width: 25px"><img src="$images/locked.png" alt="" /></td>
    <td><select name="keytype" onchange="OpenTemp(this.value);"><option value=""$KEY{''}>$profiletxt[142]</option><option value="ALLOW"$KEY{'ALLOW'}>$profiletxt[143]</option><option value="TEMP"$KEY{'TEMP'}>$profiletxt[144]</option></select></td>
   </tr><tr id="temp" style="display:none;">
    <td>&nbsp;</td>
    <td>
     <table cellpadding="3" cellspacing="0" width="100%">
      <tr>
       <td colspan="2"><strong>$profiletxt[245]</strong></td>
      </tr><tr>
       <td style="width: 200px" class="right smalltext"><strong>$profiletxt[246]:</strong></td>
       <td><input type="text" name="active" value="$mm2/$dd2/$yy2 at $hh2:$mi2:$ss2" size="25" /></td>
      </tr><tr>
       <td>&nbsp;</td>
       <td class="smalltext">$profiletxt[137]</td>
      </tr><tr>
       <td style="width: 200px" class="right smalltext"><strong>$profiletxt[147]:</strong></td>
       <td><input type="text" name="max" value="$max" size="4" maxlength="4" /></td>
      </tr>
     </table>
    </td>
   </tr>
  </table>
  <script type="text/javascript">
//<![CDATA[
function OpenTemp(open) {
	if(document.getElementById) { openItem = document.getElementById('temp'); }
	else if (document.all){ openItem = document.all['temp']; }
	else if (document.layers){ openItem = document.layers['temp']; }

	if(open == 'TEMP') { ShowType = ""; }
		else { ShowType = "none"; }

	if(openItem.style) { openItem.style.display = ShowType; }
		else { openItem.visibility = "show"; }
}
OpenTemp(document.forms['post'].keytype.value);
//]]>
  </script>
 </td>
</tr>
EOT
}

sub ProfileInfo {
	$memberid{$URL{'u'}}{'personaltxt'} =~ s~"~\&quot;~g;
	$SEL{$memberid{$URL{'u'}}{'sex'}} = ' selected="selected"';
	if($memberid{$URL{'u'}}{'dob'}) { ($mm,$dd,$yyyy) = split("/",$memberid{$URL{'u'}}{'dob'}); }

	$morecaller = $profiletxt[263];
	$displaycenter .= <<"EOT";
<tr>
 <td class="catbg smalltext"><strong>$profiletxt[224]</strong></td>
</tr><tr>
 <td class="win" style="padding: 5px">
  <table cellpadding="5" cellspacing="0" class="innertable">
   <tr>
    <td><strong>$gtxt{'15'}:</strong></td>
    <td><input type="text" name="location" value="$memberid{$URL{'u'}}{'location'}" size="40" /></td>
   </tr><tr>
    <td><strong>$profiletxt[33]: </strong></td>
    <td><select name="sex"><option value="">$profiletxt[34]</option><option value="1"$SEL{'1'}>$profiletxt[35]</option><option value="2"$SEL{'2'}>$profiletxt[36]</option></select></td>
   </tr><tr>
    <td><strong>$profiletxt[38]: </strong></td>
    <td><input type="text" name="mm" value="$mm" size="2" maxlength="2" /> - <input type="text" name="dd" value="$dd" size="2" maxlength="2" /> - <input type="text" name="yyyy" value="$yyyy" size="4" maxlength="4" /></td>
   </tr><tr>
    <td>&nbsp;</td>
    <td class="smalltext">$profiletxt[39]</td>
   </tr>
  </table>
 </td>
</tr><tr>
 <td class="catbg smalltext"><strong>$profiletxt[223]</strong></td>
</tr><tr>
 <td class="win" style="padding: 0px">
  <table cellpadding="6" cellspacing="0" class="innertable">
   <tr>
    <td style="width: 50px" class="center win2" rowspan="4"><img src="$images/site_sm.gif" alt="" /></td>
    <td colspan="2" style="height: 8px;"></td>
   </tr><tr>
    <td><strong>$profiletxt[40]:</strong></td>
    <td><input type="text" name="sname" value="$memberid{$URL{'u'}}{'sitename'}" size="30" /></td>
   </tr><tr>
    <td><strong>$profiletxt[41]:</strong></td>
    <td><input type="text" name="url" value="$memberid{$URL{'u'}}{'siteurl'}" size="50" /></td>
   </tr><tr>
    <td colspan="2" style="height: 8px;"></td>
   </tr>
  </table>
 </td>
</tr><tr>
 <td colspan="2" class="catbg smalltext"><strong>$profiletxt[222]</strong></td>
</tr><tr>
 <td class="win" style="padding: 10px">
  <table cellpadding="5" cellspacing="0" class="innertable">
   <tr>
    <td><strong>$profiletxt[46]:</strong><div class="smalltext">$profiletxt[47]</div></td>
    <td><input type="text" name="pt" value="$memberid{$URL{'u'}}{'personaltxt'}" size="50" maxlength="50" /></td>
   </tr>
  </table>
 </td>
</tr>
EOT
}

sub TimeSettings {
	$DF{"$memberid{$URL{'u'}}{'dateformat'}"} = ' selected="selected"';
	$TZ{"$memberid{$URL{'u'}}{'timezone'}"} = ' selected="selected"';
	$TCNG{"$memberid{$URL{'u'}}{'dst'}"} = ' checked="checked"';
	$TF{"$memberid{$URL{'u'}}{'timeformat'}"} = ' selected="selected"';
	get_date(time);
	($sec,$min,$hour2,$dayz,$month,$year) = gmtime(time+(3600*$memberid{$username}{'timezone'}+$memberid{$username}{'dst'}));
	$month2 = $month+1;
	if($hour == 0) { $hour = 12; }
	if($hour >= 13) { $hour = ($hour - 12); }
	++$hour2;
	if($hour2 == 24) { $hour2 = '00'; }
	if($min < 10) { $min = "0$min"; }
	if($sec < 10) { $sec = "0$sec"; }
	$year += 1900;
	$morecaller = $profiletxt[261];

	if($datedisplayH{$memberid{$URL{'u'}}{'dateformat'}} ne '') { $DEF{'1'} = ' selected="selected"'; }
		else {
			if($memberid{$URL{'u'}}{'dateformat'} eq '') { $DEF{'1'} = ' selected="selected"'; }
				else { $DEF{'2'} = ' selected="selected"'; }
		}


	$displaycenter .= <<"EOT";
<tr>
 <td class="catbg smalltext">
 <script src="$bdocsdir/common.js" type="text/javascript"></script>
 <strong>$profiletxt[306]</strong></td>
</tr><tr>
  <td class="win" style="padding: 10px; height: 40px;"><span id="timecheck">&nbsp;</span></td>
</tr><tr>
 <td class="catbg smalltext"><strong>$profiletxt[226]</strong></td>
</tr><tr>
 <td class="win" style="padding: 0px">
  <div class="win2" style="padding: 10px">
   <select name="datetype" onchange="toggle(this.value);">
    <option value="1"$DEF{'1'}>Basic</option>
    <option value="2"$DEF{'2'}>Advanced</option>
   </select>
  </div>
  <div style="padding: 5px" id="basic">
  <table cellpadding="5" cellspacing="0" class="innertable">
   <tr>
    <td><strong>$profiletxt[25]:</strong></td>
    <td>
     <select name="dformat" onchange="javascript:GetTheTime()">
      <option value="0"$DF{'0'}>$months[$month] $dayz, $year</option>
      <option value="1"$DF{'1'}>$days[$week], $months[$month] $dayz, $year</option>
      <option value="2"$DF{'2'}>$dayz $months[$month] $year</option>
      <option value="3"$DF{'3'}>$month2.$dayz.$year</option>
      <option value="4"$DF{'4'}>$dayz/$month2/$year</option>
      <option value="5"$DF{'5'}>$year/$month2/$dayz</option>
     </select>
    </td>
   </tr><tr>
    <td><strong>$profiletxt[26]:</strong></td>
    <td>
     <select name="tformat" onchange="javascript:GetTheTime()">
      <option value="0"$TF{'0'}>$hour:$min$ampm</option>
      <option value="1"$TF{'1'}>$hour:$min:$sec$ampm</option>
      <option value="2"$TF{'2'}>$hour2:$min</option>
      <option value="3"$TF{'3'}>$hour2:$min:$sec</option>
     </select>
    </td>
   </tr>
  </table>
  </div>
  <div style="padding: 5px" id="advanced">
  <table cellpadding="5" cellspacing="0" class="innertable">
   <tr>
    <td><strong>$profiletxt[310]:</strong></td>
    <td><input type="text" name="dformata" value="$DateDisplay" onchange="GetTheTime();" /></td>
   </tr><tr>
    <td colspan="2"><img src="$images/help.png" class="centerimg" alt="" /> <a href="http://www.eblah.com/forum/m-1162263083/">$profiletxt[309]</a></td>
   </tr>
  </table>
  </div>
 </td>
</tr><tr>
 <td class="catbg smalltext"><strong>$profiletxt[227]</strong></td>
</tr><tr>
 <td class="win" style="padding: 0px">
  <table cellpadding="8" cellspacing="0" class="innertable">
   <tr>
    <td class="win2" rowspan="2"></td>
    <td><strong>$profiletxt[159]</strong></td>
   </tr><tr>
    <td><select name="toff" onchange="javascript:GetTheTime()">
      <option value="-12"$TZ{'-12'}>(GMT-12:00) Eniwetok, Kwajalein</option>
      <option value="-11"$TZ{'-11'}>(GMT-11:00) Midway Island, Samoa</option>
      <option value="-10"$TZ{'-10'}>(GMT-10:00) Hawaii</option>
      <option value="-9"$TZ{'-9'}>(GMT-9:00) Alaska</option>
      <option value="-8"$TZ{'-8'}>(GMT-8:00) Pacific Time (US &amp; Canada)</option>
      <option value="-7"$TZ{'-7'}>(GMT-7:00) Mountain Time (US &amp; Canada)</option>
      <option value="-6"$TZ{'-6'}>(GMT-6:00) Central Time (US &amp; Canada), Mexico City</option>
      <option value="-5"$TZ{'-5'}>(GMT-5:00) Eastern Time (US &amp; Canada), Bogota, Lima, Quito</option>
      <option value="-4"$TZ{'-4'}>(GMT-4:00) Atlantic Time (Canada), Caracas, La Paz</option>
      <option value="-3.5"$TZ{'-3.5'}>(GMT-3:30) Newfoundland</option>
      <option value="-3"$TZ{'-3'}>(GMT-3:00) Brazil, Buenos Aires, Georgetown</option>
      <option value="-2"$TZ{'-2'}>(GMT-2:00) Mid-Atlantic</option>
      <option value="-1"$TZ{'-1'}>(GMT-1:00) Azores, Cape Verde Islands</option>
      <option value="0"$TZ{'0'}>(GMT) Western Europe Time, London, Lisbon, Casablanca, Monrovia</option>
      <option value="1"$TZ{'1'}>(GMT+1:00) Central Europe Time, Brussels, Copenhagen, Madrid, Paris</option>
      <option value="2"$TZ{'2'}>(GMT+2:00) Eastern Europe Time, Kaliningrad, South Africa</option>
      <option value="3"$TZ{'3'}>(GMT+3:00) Baghdad, Kuwait, Riyadh, Moscow, St. Petersburg, Volgograd, Nairobi</option>
      <option value="3.5"$TZ{'3.5'}>(GMT+3:30) Tehran</option>
      <option value="4"$TZ{'4'}>(GMT+4:00) Abu Dhabi, Muscat, Baku, Tbilisi</option>
      <option value="4.5"$TZ{'4.5'}>(GMT+4:30) Kabul</option>
      <option value="5"$TZ{'5'}>(GMT+5:00) Ekaterinburg, Islamabad, Karachi, Tashkent</option>
      <option value="5.5"$TZ{'5.5'}>(GMT+5:30) Bombay, Calcutta, Madras, New Delhi</option>
      <option value="6"$TZ{'6'}>(GMT+6:00) Almaty, Dhaka, Colombo</option>
      <option value="7"$TZ{'7'}>(GMT+7:00) Bangkok, Hanoi, Jakarta</option>
      <option value="8"$TZ{'8'}>(GMT+8:00) Beijing, Perth, Singapore, Hong Kong, Chongqing, Urumqi, Taipei</option>
      <option value="9"$TZ{'9'}>(GMT+9:00) Tokyo, Seoul, Osaka, Sapporo, Yakutsk</option>
      <option value="9.5"$TZ{'9.5'}>(GMT+9:30) Adelaide, Darwin</option>
      <option value="10"$TZ{'10'}>(GMT+10:00) East Australian Standard, Guam, Papua New Guinea, Vladivostok</option>
      <option value="11"$TZ{'11'}>(GMT+11:00) Magadan, Solomon Islands, New Caledonia</option>
      <option value="12"$TZ{'12'}>(GMT+12:00) Auckland, Wellington, Fiji, Kamchatka, Marshall Island</option>
     </select>
    </td>
   </tr><tr>
    <td class="center vtop win2" rowspan="2"><input type="checkbox" name="tcng" value="1" onclick="javascript:GetTheTime()"$TCNG{'1'} /></td>
    <td><strong>$profiletxt[166]</strong></td>
   </tr><tr>
    <td class="smalltext">$profiletxt[167]
     <script type="text/javascript">
//<![CDATA[
outtimer = '';

function toggle() {
	if(document.forms['post'].datetype.value == 2) {
		document.getElementById('advanced').style.display = '';
		document.getElementById('basic').style.display = 'none';
	} else {
		document.getElementById('advanced').style.display = 'none';
		document.getElementById('basic').style.display = '';
	}

	GetTheTime();
}

function GetTheTime() {
	clearTimeout(outtimer);
	outtimer = setTimeout('NoServerKill()',400); // We don't want to send 100's of requests to the server!
}

function NoServerKill() {
	if(document.forms['post'].datetype.value == 2) {
		CheckData = ''; PostData = 'date=' + encodeURIComponent(document.forms['post'].dformata.value);
	} else {
		CheckData = '/date-' + document.forms['post'].dformat.value + '/time-' + document.forms['post'].tformat.value; PostData = '';
	}
	EditMessage('$surl\v-checktime/zone-' + document.forms['post'].toff.value.replace(RegExp("-"), "'") + '/saving-' + document.forms['post'].tcng.checked + CheckData + '/','2',PostData,'timecheck');
}

toggle();
GetTheTime();
//]]>
 </script>
    </td>
   </tr>
  </table>
 </td>
</tr>
EOT
}

sub LngTheme {
	opendir(DIR,"$languages/");
	@lngs = readdir(DIR);
	closedir(DIR);

	$languagepack = $memberid{$URL{'u'}}{'lng'};

	if($languagepack eq '') { $languagepack = $languagep; }
	foreach(@lngs) {
		($lng,$type) = split(/\./,$_);
		if($type ne 'lng') { next; }
		$check = '';
		if("$languages/$languagepack" eq "$languages/$lng") { $check = ' selected="selected"'; }
		$lngs .= qq~<option value="$lng"$check>$lng</option>\n~;
	}
	$morecaller = $profiletxt[260];
	$displaycenter .= <<"EOT";
<tr>
 <td class="catbg smalltext"><strong>$profiletxt[205] $profiletxt[225]</strong></td>
</tr><tr>
 <td class="win" style="padding: 5px">
  <table cellpadding="5" cellspacing="0" class="innertable">
   <tr>
    <td class="win right"><strong>$profiletxt[205]:</strong></td>
    <td class="win vtop"><select name="lng">$lngs</select></td>
   </tr>
  </table>
 </td>
</tr>
EOT
	if($showtheme) {
		$displaycenter .= <<"EOF";
<tr>
 <td class="catbg smalltext"><strong>$profiletxt[29]</strong></td>
</tr><tr>
 <td class="win" style="padding: 5px">
  <table cellpadding="5" cellspacing="0" class="innertable">
   <tr>
    <td class="vtop" colspan="2"><strong>$profiletxt[29]</strong><div class="smalltext">$profiletxt[30]</div></td>
   </tr><tr>
    <td>
     <select name="theme" onchange="ShowImage(this.value,0);">
EOF
		my(@themes,$themename2,$themename,$default,$temp);
		fopen(FILE,"$prefs/ThemesList.txt");
		@themes = <FILE>;
		fclose(FILE);
		chomp @themes;

		$userthemes = $memberid{$URL{'u'}}{'theme'};

		$selected{$userthemes} = ' selected="selected"';

		foreach $temp (sort {lc($a) cmp lc($b)} @themes) {
			($themename,$default) = split(/\|/,$temp);
			$hidden = 0;
			$preview = 0;
			fopen(FILE,"$templates/$themename/theme.dat") or next;
			while(<FILE>) {
				if($_ =~ /name = '(.+?)'/) { $themename2 = $1; }
				if($_ =~ /preview = '1'/) { $preview = 1; }
				if($_ =~ /hidden = '1'/) { $hidden = 1; }
			}
			fclose(FILE);
			if($hidden && !$members{'Administrator',$username}) { next; }

			if($userthemes eq '' && $default) { $selected{$themename} = ' selected="selected"'; }
			$displaycenter .= qq~<option value="$themename|$preview"$selected{$themename}>$themename2</option>~;
		}

		$displaycenter .= <<"EOF";
     </select>
    </td>
    <td class="center"><input type="button" value="$profiletxt[239]" onclick="ShowImage(document.forms['post'].theme.value,1);" /></td>
   </tr><tr>
    <td colspan="2"><img src="$images/nopic.gif" name="icon" alt="" /></td>
   </tr>
  </table>
  <script type="text/javascript">
//<![CDATA[
function ShowImage(valy,NewWinder) {
 preview_array = valy.split("|");

 if(NewWinder == 1) { window.open('$surl\ltheme-'+preview_array[0]+'/','themes','align=center,height=500,width=750,resizable=yes,scrollbars=yes,status=yes'); }
  else {
   if(preview_array[1] == 1) { document.images.icon.src = "$templatesu/"+preview_array[0]+"/preview.gif"; }
    else { document.images.icon.src = "$images/nopic.gif"; }
  }
}

ShowImage(document.forms['post'].theme.value,0);
//]]>
  </script>
 </td>
</tr>
EOF
	}
}

sub BoardSettings {
	$HIDE{$memberid{$URL{'u'}}{'hideonline'}} = ' checked="checked"';
	$H{$memberid{$URL{'u'}}{'hidemail'}} = ' checked="checked"';
	$ML{$memberid{$URL{'u'}}{'ml'}} = ' checked="checked"';
	$SS{$memberid{$URL{'u'}}{'hidesum'}} = ' checked="checked"';
	$NOTIFY{$memberid{$URL{'u'}}{'notify'}} = ' checked="checked"';
	$ONEW{$memberid{$URL{'u'}}{'shownewonly'}} = ' checked="checked"';
	if($memberid{$URL{'u'}}{'timezone'} eq '') { $TZ{'0'} = ' selected="selected"'; }
	$SIGNATURE{$memberid{$URL{'u'}}{'showsig'}} = ' checked="checked"';
	$AVATAR{$memberid{$URL{'u'}}{'ownavatar'}} = ' checked="checked"';
	$CENSOR{$memberid{$URL{'u'}}{'censor'}} = ' checked="checked"';
	$PMPOP{$memberid{$URL{'u'}}{'pmpopup'}} = ' checked="checked"';
	$ADVEDIT{$memberid{$URL{'u'}}{'bcadvanced'}} = ' checked="checked"';

	$morecaller = $profiletxt[228];

	$displaycenter .= <<"EOF";
<tr>
 <td class="catbg smalltext"><strong>$profiletxt[201]</strong></td>
</tr><tr>
 <td class="win" style="padding: 0px">
  <table cellspacing="0" cellpadding="5" width="100%">
   <tr>
    <td class="win2" style="height: 5px"></td>
    <td></td>
   </tr><tr>
    <td class="center vtop win2" style="width: 50px"><input type="checkbox" name="showsums" value="1"$SS{'1'} /></td>
    <td colspan="2"><strong>$profiletxt[23]</strong><div class="smalltext" style="margin-top: 3px;">$profiletxt[24]</div></td>
   </tr><tr>
    <td class="center vtop win2"><input type="checkbox" name="onlynew" value="1"$ONEW{'1'} /></td>
    <td colspan="2"><strong>$profiletxt[168]</strong><div class="smalltext" style="margin-top: 3px;">$profiletxt[241]</div></td>
   </tr>
EOF
	if($BCAdvanced) {
		$displaycenter .= <<"EOF";
   <tr>
    <td class="center vtop win2"><input type="checkbox" name="bcadvanced" value="1"$ADVEDIT{'1'} /></td>
    <td colspan="2"><strong>$profiletxt[325]</strong><div class="smalltext" style="margin-top: 3px;">$profiletxt[324]</div></td>
   </tr>
EOF
	}
	$displaycenter .= <<"EOF";
   <tr>
    <td class="center vtop win2"><input type="checkbox" name="notify" value="1"$NOTIFY{'1'} /></td>
    <td class="center win3" style="width: 30px"><img src="$images/notify_sm.png" alt="" /></td>
    <td><strong>$profiletxt[155]</strong><div class="smalltext" style="margin-top: 3px;">$profiletxt[240]</div></td>
   </tr><tr>
    <td class="center vtop win2"><input type="checkbox" name="censor" value="1"$CENSOR{'1'} /></td>
    <td class="center win3"><img src="$images/report_sm.gif" alt="" /></td>
    <td><strong>$profiletxt[255]</strong><div class="smalltext" style="margin-top: 3px;">$profiletxt[254]</div></td>
   </tr><tr>
    <td class="center vtop win2"><input type="checkbox" name="pmpop" value="1"$PMPOP{'1'} /></td>
    <td class="center win3"><img src="$images/pm2_sm.gif" alt="" /></td>
    <td><strong>$profiletxt[274]</strong><div class="smalltext" style="margin-top: 3px;">$profiletxt[275]</div></td>
   </tr><tr>
    <td colspan="3"><hr /></td>
   </tr><tr>
    <td class="center vtop win2"><input type="checkbox" name="signature" value="1"$SIGNATURE{'1'} /></td>
    <td colspan="2"><strong>$profiletxt[229]</strong></td>
   </tr><tr>
    <td class="center vtop win2"><input type="checkbox" name="avatar" value="1"$AVATAR{'1'} /></td>
    <td colspan="2"><strong>$profiletxt[230]</strong></td>
   </tr><tr>
    <td class="win2" style="height: 5px"></td>
    <td></td>
   </tr>
  </table>
 </td>
</tr><tr>
 <td class="catbg smalltext"><strong>$profiletxt[206]</strong></td>
</tr><tr>
 <td class="win" style="padding: 0px">
  <table cellspacing="0" cellpadding="5" class="innertable">
EOF
	if($hmail || $hiddenmail == 2) {
		$displaycenter .= <<"EOF";
   <tr>
    <td class="center vtop win2"><input type="checkbox" name="hidemail" value="1"$H{'1'} /></td>
    <td class="center win3" style="width: 30px"><img src="$images/lockmail.png" alt="" /></td>
    <td><strong>$profiletxt[15]</strong><div class="smalltext" style="margin-top: 3px;">$profiletxt[16]</div></td>
   </tr>
EOF
	}

	$displaycenter .= <<"EOF";
   <tr>
    <td class="win2" style="height: 5px"></td>
    <td colspan="2"></td>
   </tr><tr>
    <td class="center vtop win2" style="width: 50px"><input type="checkbox" name="hideonline" value="1"$HIDE{'1'} /></td>
    <td colspan="2"><strong>$profiletxt[19]</strong><div class="smalltext" style="margin-top: 3px;">$profiletxt[20]</div></td>
   </tr><tr>
    <td class="center vtop win2"><input type="checkbox" name="mailing" value="1"$ML{'1'} /></td>
    <td colspan="2"><strong>$profiletxt[21]</strong><div class="smalltext" style="margin-top: 3px;">$profiletxt[22]</div></td>
   </tr><tr>
    <td class="win2" style="height: 5px"></td>
    <td colspan="2"></td>
   </tr>
  </table>
 </td>
</tr>
EOF
}

sub Contact {
	$aimcontact = $memberid{$URL{'u'}}{'aim'};
	$aimcontact =~ s/\+/ /gsi;

	if($vradmin) { $extra = qq~<div class="smalltext win3" style="padding: 5px"><img src="$images/warning.png" class="centerimg" alt="" /> $profiletxt[303]</div>~; }
	$morecaller = $profiletxt[264];

	$screennameinput = $disablesn ? $memberid{$URL{'u'}}{'sn'} : qq~<input type="text" name="sn" value="$memberid{$URL{'u'}}{'sn'}" maxlength="30" />~;
	$displaycenter .= <<"EOT";
<tr>
 <td colspan="2" class="catbg smalltext"><strong>$profiletxt[94]</strong></td>
</tr><tr>
 <td class="win" style="padding: 0px">
  <div style="padding: 5px">
   <table cellpadding="5" cellspacing="0" class="innertable">
    <tr>
     <td><strong>$profiletxt[10]:</strong></td>
     <td>$screennameinput</td>
    </tr><tr>
     <td></td>
     <td class="smalltext">$profiletxt[11]</td>
    </tr><tr>
     <td><strong>$gtxt{'23'}: </strong></td>
     <td><input type="text" name="email" value="$memberid{$URL{'u'}}{'email'}" size="25" maxlength="80" /></td>
    </tr>
   </table>
  </div>$extra
 </td>
</tr><tr>
 <td colspan="2" class="catbg smalltext"><strong>$profiletxt[102]</strong></td>
</tr><tr>
 <td class="win" style="padding: 0px">
  <table cellpadding="5" cellspacing="0" class="innertable">
   <tr>
    <td class="center win2" style="width: 50px; height: 8px;"></td>
    <td colspan="2"></td>
   </tr><tr>
    <td class="center win2" style="width: 50px"><img src="$images/icq.png" alt="" /></td>
    <td><strong>$profiletxt[42]:</strong></td>
    <td><input type="text" name="icq" value="$memberid{$URL{'u'}}{'icq'}" maxlength="30" size="20" /></td>
   </tr><tr>
    <td class="center win2"><img src="$images/aim.png" alt="" /></td>
    <td><strong>$profiletxt[43]:</strong></td>
    <td><input type="text" name="aim" value="$aimcontact" maxlength="30" /></td>
   </tr><tr>
    <td class="center win2"><img src="$images/yim.png" alt="" /></td>
    <td><strong>$profiletxt[44]:</strong></td>
    <td><input type="text" name="yim" value="$memberid{$URL{'u'}}{'yim'}" maxlength="30" /></td>
   </tr><tr>
    <td class="center win2"><img src="$images/msn.png" alt="" /></td>
    <td><strong>$profiletxt[45]:</strong></td>
    <td><input type="text" name="msn" value="$memberid{$URL{'u'}}{'msn'}" maxlength="40" /></td>
   </tr><tr>
    <td class="center win2"><img src="$images/skype.png" alt="" /></td>
    <td><strong>Skype:</strong></td>
    <td><input type="text" name="skype" value="$memberid{$URL{'u'}}{'skype'}" maxlength="30" /></td>
   </tr><tr>
    <td class="center win2" style="height: 8px;"></td>
    <td colspan="2"></td>
   </tr>
  </table>
 </td>
</tr>
EOT
}

sub MessageBlock {
	@blockeduserlist = split(/\|/,$memberid{$URL{'u'}}{'blockedusers'});
	foreach(@blockeduserlist) {
		GetMemberID($_);
		$membername = $memberid{$_}{'sn'};
		if($membername eq '') { $membername = $gtxt{'0'}; } else { $membername = $userurl{$_}; }
		$usersblocked .= qq~<img src="$images/ban.png" alt="" /> <a href="$surl\lv-memberpanel/a-save/as-forum/s-messageblock/caller-10/u-$URL{'u'}/remove-$_/">$profiletxt[267]</a> -- $membername ($_)<br />~;
		++$cnt;
	}
	if($usersblocked eq '') { $usersblocked = $profiletxt[268]; }

	$morecaller = $profiletxt[269];
	$displaycenter .= <<"EOT";
<tr>
 <td colspan="2" class="catbg smalltext"><strong>$profiletxt[270]</strong></td>
</tr><tr>
 <td class="win" style="padding: 5px">
  <table cellpadding="5" cellspacing="0" class="innertable">
   <tr>
    <td>$usersblocked</td>
   </tr>
  </table>
 </td>
</tr><tr>
 <td colspan="2" class="catbg smalltext"><strong>$profiletxt[271]</strong></td>
</tr><tr>
 <td class="win" style="padding: 5px">
  <table cellpadding="5" cellspacing="0" class="innertable">
   <tr>
    <td>$profiletxt[272] </strong><input type="text" size="30" name="1" /><br /><br />$profiletxt[273]</td>
   </tr>
  </table>
 </td>
</tr>
EOT
}

sub PW {
	if($members{'Administrator',$username}) {
		$admins = <<"EOT";
<tr>
 <td colspan="2">
<script type="text/javascript">
//<![CDATA[
function reset() {
 if(window.confirm("$profiletxt[234]")) { location = "$surl\lv-memberpanel/a-save/as-profile/s-pw/u-$URL{'u'}/c-reset/"; }
}
//]]>
</script>
<strong><img src="$images/restriction.png" class="centerimg" alt="" /> <a href="javascript:reset();">$profiletxt[233]</a></strong></td>
</tr>
EOT
	}
	$morecaller = $profiletxt[78];
	if(!$members{'Administrator',$username}) {
		$displaycenter .= <<"EOT";
<tr>
 <td class="catbg smalltext"><strong>$profiletxt[79] $profiletxt[80]</strong></td>
</tr><tr>
 <td class="win" style="padding: 5px">
  <table cellpadding="5" cellspacing="0" class="innertable">
   <tr>
    <td><strong>$profiletxt[79] $profiletxt[80]: </strong></td>
    <td><input type="password" name="oldpw" size="25" /></td>
   </tr>
  </table>
 </td>
</tr>
EOT
	}

	$displaycenter .= <<"EOT";
<tr>
 <td class="catbg smalltext"><strong>$profiletxt[81] $profiletxt[80]</strong></td>
</tr><tr>
 <td class="win" style="padding: 5px">
  <table cellpadding="5" cellspacing="0" class="innertable">
   <tr>
    <td><strong>$profiletxt[81] $profiletxt[80]: </strong></td>
    <td><input type="password" name="newpw" size="25" maxlength="$pwlength" /></td>
   </tr><tr>
    <td><strong>$gtxt{'24'}: </strong></td>
    <td><input type="password" name="newpwc" size="25" maxlength="$pwlength" /></td>
   </tr>$admins
  </table>
 </td>
</tr>
EOT

	eval {
		require Digest::MD5;
		import Digest::MD5 qw(md5_hex);
	};

	if($members{'Administrator',$URL{'u'}} && !$@) {
		$displaycenter .= <<"EOT";
<tr>
 <td class="catbg smalltext"><strong>$profiletxt[313]</strong></td>
</tr><tr>
 <td class="win2 smalltext" style="padding: 8px;">$profiletxt[314]</td>
</tr><tr>
 <td class="win" style="padding: 5px">
  <table cellpadding="5" cellspacing="0" class="innertable">
EOT

		if($memberid{$URL{'u'}}{'adminverify'}) {
			$displaycenter .= <<"EOT";
   <tr>
    <td><strong>$profiletxt[315]:</strong></td>
    <td><input type="password" name="oldverify" size="25" maxlength="$pwlength" /></td>
   </tr>
EOT
		}

		$displaycenter .= <<"EOT";
   <tr>
    <td><strong>$profiletxt[316]:</strong></td>
    <td><input type="password" name="newver" size="25" maxlength="20" /></td>
   </tr><tr>
    <td><strong>$profiletxt[317]:</strong></td>
    <td><input type="password" name="newverc" size="25" maxlength="20" /></td>
   </tr>
  </table>
 </td>
</tr>
EOT
	}
	$@ = '';
}

sub Signature {
	if($maxsig < 0) { error($profiletxt[305]); }
	$message = BC($memberid{$URL{'u'}}{'sig'});
	$membersig = $memberid{$URL{'u'}}{'sig'};
	$membersig =~ s/<br \/>/\n/gi;
	if(!$maxsig) { $maxsig = $profiletxt[54]; }
	$morecaller = $profiletxt[56];

	if($message ne '') {
		$displaycenter .= <<"EOT";
<tr>
 <td class="catbg smalltext"><strong>$profiletxt[220]</strong></td>
</tr><tr>
 <td class="win" style="padding: 5px">
  <table cellpadding="5" cellspacing="0" class="innertable">
   <tr>
    <td class="smalltext">$message</td>
   </tr>
  </table>
 </td>
</tr>
EOT
	}
	$displaycenter .= <<"EOT";
<tr>
 <td colspan="2" class="catbg smalltext">
EOT
	CoreLoad('Post');
	if($BCLoad || $BCSmile) { $displaycenter .= BCWait(); }
	$displaycenter .= <<"EOT";
 <strong>$profiletxt[221]</strong></td>
</tr>
EOT
	if($BCLoad) { $bcload .= BCLoad(); }
	if($BCSmile) { $smileys = BCSmile(); }

	$displaycenter .= <<"EOT";
<tr>
 <td class="win" style="padding: 0px">
  <table cellpadding="0" cellspacing="0" width="100%">
   <tr>
    <td>$bcload
     <table cellpadding="0" cellspacing="0" width="100%">
      <tr>
	  <td style="width: 70%; padding: 8px;"><textarea name="message" rows="12" cols="90" style="width: 98%">$membersig</textarea><br />$profiletxt[57]: <strong>$maxsig</strong>; $profiletxt[169]: <strong><span id="remain">$maxsig</span></strong></td>
	  <td class="win2 vtop">$smileys</td>
	 </tr>
     </table>
EOT
	if($maxsig ne $profiletxt[54]) {
		$displaycenter .= <<"EOT";
<script type="text/javascript">
//<![CDATA[
function tick() {
 textCounter();
 timerID = setTimeout("tick()",300);
}

function textCounter() {
 if(document.forms['post'].message.value.length > $maxsig) { document.forms['post'].message.value = document.forms['post'].message.value.substring(0,$maxsig); }
  else {
   if(document.all){ remain.innerHTML = $maxsig - document.forms['post'].message.value.length; }
   if(document.getElementById && !document.all){ document.getElementById('remain').innerHTML = $maxsig - document.forms['post'].message.value.length; }
  }
}
tick();
//]]>
</script>
EOT
	}
	$displaycenter .= <<"EOT";
    </td>
   </tr>
  </table>
 </td>
</tr>
EOT
}

sub AvatarSetup {
	$maxsize = $maxsize2;
	if(!$apic) {
		$disablecaller = 1;
		$displaycenter = <<"EOT";
<table cellpadding="4" cellspacing="1" class="border" width="97%">
 <tr>
  <td class="win">$profiletxt[216]</td>
 </tr>
</table>
EOT
		return;
	}
	$file = $memberid{$URL{'u'}}{'avatar'};
	$avup = $memberid{$URL{'u'}}{'avatarupload'};
	$avsize = $memberid{$URL{'u'}}{'avatarsize'}; # MY GENERATION IS ACHING FOR YOU [Jesus]!!!

	if($avsize) { ($height,$width) = split(/\|/,$memberid{$URL{'u'}}{'avatarsize'}); }
		else { $width = $picwidth; $height = $picheight; }

	($fdname,$ffname) = split(/\//,$memberid{$URL{'u'}}{'avatar'});

	opendir(DIR,"$avdir/");
	@dlist = readdir(DIR);
	fclose(DIR);
	foreach (sort {lc($a) cmp lc($b)} @dlist) {
		if($fname =~ /[#%+,\\\/:?"<>'|@^\$\&~'\)\(\]\[\;{}!`=]/ || $_ eq 'nopic.gif') { next; }
		$selected = '';
		($fname,$fext) = split(/\./,$_);
		$fext = lc($fext);
		if($memberid{$URL{'u'}}{'avatar'} eq $_) { $show = $_; $selected = ' selected="selected"'; $found = 1; }
		$fname2 = $fname;
		$fname =~ s/\_/ /gsi;
		if($fext eq 'jpg' || $fext eq 'gif' || $fext eq 'jpeg' || $fext eq 'png' && $fname ne 'nopic') { $list{'basic'} .= qq~<option value="$_"$selected="selected">$fname</option>~; }
		if($fext eq '' && $fname ne '') {
			$sel = '';
			if($fname2 eq $fdname) { $sel = ' selected="selected"'; $fldfnd = 1; }
			if($fname eq 'valueopen' || $fname eq 'value' || $fname eq 'basic' || $fname eq 'valueclose') { next; }
			$avslist .= qq~<option value="$_"$sel>$fname</option>~;

			opendir(DIR,"$avdir/$fname2");
			@blist = readdir(DIR);
			fclose(DIR);
			$varlist .= "$fname2 = '";
			foreach (sort {lc($a) cmp lc($b)} @blist) {
				$selected = '';
				($fname,$fext) = split(/\./,$_);
				$fext = lc($fext);
				if(($fname2 eq $fdname) && $ffname eq $_) { $show = $memberid{$URL{'u'}}{'avatar'}; $selected = ' selected="selected"'; $found = 1; $aval = "$fname2/$_"; }
				$fname =~ s/\_/ /gsi;
				if($fext eq 'jpg' || $fext eq 'gif' || $fext eq 'png' && $fname ne 'nopic') { $varlist .= qq~<option value="$fname2/$_"$selected="selected">$fname</option>~; }
			}
			$varlist .= "';\nif(list == '$fname2') { list = $fname2; }\n";
		}
	}
	$sel = '';
	if(!$found && $memberid{$URL{'u'}}{'avatar'} ne '') { $selected = ' selected="selected"'; $cvalue = 2; $avurl = $memberid{$URL{'u'}}{'avatar'}; }
	if(!$fldfnd) { $sel = ' selected="selected"'; }

	if($memberid{$URL{'u'}}{'avatarupload'}) {
		$cvalue = 2;
		$uploaded .= <<"EOT";
<tr>
 <td colspan="2" class="center smalltext"><strong><br />$profiletxt[207]<br /><br /></strong></td>
</tr>
EOT
	}

	if($found) { $cvalue = 1; }
	if(!$cvalue) { $cvalue = 3; $checked = ' checked="checked"'; }
	if($show eq '') { $scr = "$avsurl/nopic.gif"; } else { $scr = "$avsurl/$show"; }

	if($avup) { $avurl = ''; }
	if(!$perpic) { $perpic = $var{'60'}; }

	$morecaller = $profiletxt[262];
	$displaycenter .= <<"EOT";
<tr>
 <td class="catbg smalltext">
 <script type="text/javascript">
//<![CDATA[
function ShowImage(showtimage) {
	tmpdoc = document.forms['post'].av;
	if(!document.images) return;
	if(tmpdoc) { tmpdoc.value = showtimage; }
	document.getElementById('preview').src = '$avsurl/'+showtimage;
}
function Change(id) {
	if(id == 3) { cvalue = true; } else { cvalue = false; }
	document.forms['post'].avcheckbox.checked = cvalue;
	document.forms['post'].avatartype.value = id;
}
//]]>
 </script>
 <strong>$profiletxt[218]</strong></td>
</tr><tr>
 <td class="win">
  <table width="100%">
   <tr>
    <td class="smalltext"><strong>$perpic</strong></td>
   </tr>
  </table>
 </td>
</tr><tr>
 <td class="catbg smalltext"><strong>$profiletxt[209]</strong></td>
</tr><tr>
 <td class="win">
  <table cellpadding="5" cellspacing="0" class="innertable">
   <tr>
    <td class="center smalltext"><strong>$profiletxt[235]</strong></td>
    <td class="center smalltext"><strong>$profiletxt[236]</strong></td>
    <td class="smalltext"><strong>$profiletxt[237]</strong></td>
   </tr><tr>
    <td class="vtop center" style="width: 180px"><select name="avlist" size="9" style="width: 175px" onchange="FunctionList(this.value);" onfocus="Change(1);"><option value="basic"$sel>$profiletxt[238]</option>$avslist</select></td>
    <td class="center vtop" style="height: 125px; width: 200px"><span id="vis"></span></td>
    <td style="width: 200px">&nbsp; &nbsp; &nbsp;<img id="preview" alt="$profiletxt[51]" src="$scr" /></td>
   </tr>
  </table>
  <script type="text/javascript">
//<![CDATA[
function FunctionList(list) {
	if(list == '') { return; }
	valueopen = '<select name="avf" style="width: 175px" size="9" onchange="ShowImage(this.value);" onfocus="Change(1);">';
	valueclose = '</select>';
	basic = '$list{'basic'}';
	if(list == 'basic') { list = basic; }
$varlist
	if(document.all) {
		vis.innerHTML = valueopen+list+valueclose;
		pic = document.forms['post'].avf.value;
		if(!pic) { pic = 'nopic.gif'; }
	}
	if(document.getElementById && !document.all) {
		document.getElementById('vis').innerHTML = valueopen+list+valueclose;
		pic = 'nopic.gif';
	}
	ShowImage(pic);
}
FunctionList(document.forms['post'].avlist.value);
//]]>
  </script>
 </td>
</tr>
EOT
	if($avupload || $apic == 1) {
		$displaycenter .= <<"EOT";
<tr>
 <td class="catbg smalltext"><strong>$profiletxt[211]</strong></td>
</tr><tr>
 <td class="win" style="padding: 0px">
  <div style="padding: 5px">
  <table cellpadding="5" cellspacing="0" class="innertable">
EOT
		if($apic == 1) {
			$displaycenter .= <<"EOT";
   <tr>
    <td><strong>$profiletxt[53]:</strong></td>
    <td><input type="text" class="textinput" name="avcust" value="$avurl" size="30" onfocus="Change(2);" /></td>
   </tr>
EOT
		}

		if($avupload) {
			$maxsize = $maxsize <= 0 ? $profiletxt[161] : "$maxsize MB";
			if($maxsize > 0 && $maxsize < 1) { $maxsize = 1024*$maxsize . " KB"; }
			$displaycenter .= <<"EOT";
   <tr>
    <td><strong>$profiletxt[162]:</strong></td>
    <td><input type="file" name="ulfile" size="30" onfocus="Change(2);" /></td>
   </tr>
EOT
		}

		$displaycenter .= <<"EOT";
   $uploaded
  </table>
  </div>
  <div class="win3" style="padding: 10px"><strong>$profiletxt[208]:</strong> $maxsize</div>
 </td>
</tr>
EOT
	}
	$displaycenter .= <<"EOT";
<tr>
 <td class="catbg smalltext"><strong>$profiletxt[212]</strong></td>
</tr><tr>
 <td class="win" style="padding: 0px">
  <table cellpadding="10" cellspacing="0" width="100%">
   <tr>
    <td><input type="text" name="picwidth" value="$width" size="4" onfocus="Change(2);" /> &times; <input type="text" name="picheight" value="$height" size="4" onfocus="Change(2);" /> &nbsp; $profiletxt[214]</td>
   </tr><tr>
    <td class="win3"><strong>$profiletxt[213]:</strong> $picheight &times; $picwidth</td>
   </tr>
  </table>
 </td>
</tr><tr>
 <td class="catbg smalltext"><strong>$profiletxt[50]</strong></td>
</tr><tr>
 <td class="win" style="padding: 0px">
  <table cellpadding="10" cellspacing="0" class="innertable">
   <tr>
    <td class="win2"><input type="hidden" name="avatartype" value="$cvalue" /><input type="hidden" name="av" value="$show" /><input type="checkbox" value="3" name="avcheckbox" onclick="Change(3);"$checked /></td>
    <td style="cursor:default;"><span onclick="Change(3);">$profiletxt[217]</span></td>
   </tr>
  </table>
 </td>
</tr>
EOT
}

sub ExtendedProfile {
	fopen(FILE,"$prefs/ProfileVariables.txt");
	@sortme = <FILE>;
	fclose(FILE);
	chomp @sortme;

	@sortme = sort {$a cmp $b} @sortme;

	foreach(split(/\//,$subsectvar{$URL{'s'}})) { $thisid{$_} = 1; }

	foreach(@sortme) {
		($cattitle,$optionid,$optiontitle,$type,$valuesvote) = split(/\|/,$_);
		if(!$thisid{$optionid}) { next; }

		if($cattitle ne $oldcattitle) {
			if($oldcattitle ne '') { $displaycenter .= qq~</td></tr>~; }
			$oldcattitle = $cattitle;
			$displaycenter .= <<"EOT";
<tr>
 <td class="catbg smalltext"><strong>$cattitle</strong></td>
</tr><tr>
 <td class="win" style="padding: 0px">
EOT
		}

		$checkbox = $checked{1} = $otherboxes = '';
		if($type == 1) {
			$checked{$memberid{$URL{'u'}}{$optionid}} = ' checked="checked"';
			$checkbox = qq~<td class="win2 vtop"><input type="checkbox" value="1" name="$optionid"$checked{1} /></td>~;
		}
		elsif($type == 2) { $otherboxes = qq~<td><input type="input" name="$optionid" value="$memberid{$URL{'u'}}{$optionid}" /></td>~; }
		elsif($type == 3) {
			$otherboxes = qq~<td class="vtop"><select name="$optionid">~;
			foreach $vv (split(/\//,$valuesvote)) {
				$selected{$vv} = '';
				$selected{$memberid{$URL{'u'}}{$optionid}} = ' selected="selected"';
				$otherboxes .= qq~<option value="$vv"$selected{$vv}>$vv</option>~;
			}
			$otherboxes .= qq~</select></td>~;
		}
		elsif($type == 4) {
			@vv = split(/\//,$valuesvote);
			$width = $vv[0];
			$rows = $vv[1];
			$memberid{$URL{'u'}}{$optionid} =~ s/<br \/>/\n/g;
			$otherboxes = qq~<td class="vtop"><textarea name="$optionid" rows="$rows" cols="5" style="width: $width\lpx">$memberid{$URL{'u'}}{$optionid}</textarea></td>~;
		}

		$displaycenter .= <<"EOT";

  <table cellpadding="10" cellspacing="0" class="innertable">
   <tr>$checkbox
    <td class="vtop">$optiontitle</td>$otherboxes
   </tr>
  </table>
EOT
	}
	if($oldcattitle ne '') { $displaycenter .= qq~</td></tr>~; }
}
1;