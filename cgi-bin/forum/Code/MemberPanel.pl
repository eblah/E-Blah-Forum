#############################################
# E-Blah Bulletin Board Systems        2008 #
#############################################
# Copyright (c) 2001 - 2008 E-Blah.         #
#############################################

CoreLoad('MemberPanel',1);

sub SecureMemberData {
	if($URL{'a'} eq 'view' && (!$proon && $URL{'u'} ne $username && !$members{'Administrator',$username})) { PView(); }
	is_member();
	if($URL{'u'} eq '' || $URL{'u'} eq $username) { $URL{'u'} = $username; }
	elsif($proon) { $profileonly = 1; }
	elsif($URL{'u'} ne $username) { is_admin(-1); $profileonly = 1; }
	if($URL{'a'} eq 'remove') { Remove(); }

	GetMemberID($URL{'u'});
	if($memberid{$URL{'u'}}{'sn'} eq '') { error("$profiletxt[2] $URL{'u'}"); }
	fopen(FILE,"$members/$URL{'u'}.pm");
	@pmdata = <FILE>;
	fclose(FILE);
	chomp @pmdata;

	fopen(FILE,"$members/$URL{'u'}.prefs");
	@prefs = <FILE>;
	fclose(FILE);
	chomp @prefs;
	@folders = split(/\|/,$prefs[6]);
	foreach(@folders) {
		($fname,$fid) = split("/",$_);
		$fids{$fid} = $fname;
		++$foldercnt;
		$folderops .= qq~<option value="$fid">$fname</option>~;
	}

	#fopen(FILE,"$prefs/ProfileSubsections.txt");
	#while(<FILE>) {
	#	chomp;
	#	($tid,$toptname,$tvariables,$tsectionimage) = split(/\|/,$_);
	#	$subsection{$tid} = $toptname;
	#	$subsectvar{$tid} = $tvariables;
	#	$subsectimg{$tid} = $tsectionimage;
	#}
	#fclose(FILE);
}

sub MemberPanel {
	my($usericon);

	SecureMemberData();
	$perpic = '';
	if($memberid{$URL{'u'}}{'avatar'} ne '' && $apic) {
		$pic = $memberid{$URL{'u'}}{'avatar'};
		if($memberid{$URL{'u'}}{'avatarsize'}) { ($height,$width) = split(/\|/,$memberid{$URL{'u'}}{'avatarsize'}); }
			else { $width = $picwidth; $height = $picheight; }

		if($memberid{$URL{'u'}}{'avatar'} =~ /http:/) { $perpic = qq~<img src="$pic" width="$width" height="$height" alt="" /><br />~; }
		elsif($memberid{$URL{'u'}}{'avatarupload'}) {
			$memberid{$URL{'u'}}{'avatar'} =~ s/\A$uploadurl//;
			$perpic = qq~<img src="$uploadurl/$memberid{$URL{'u'}}{'avatar'}" width="$width" height="$height" alt="" /><br />~;
		}
			else { $perpic = qq~<img src="$avsurl/$memberid{$URL{'u'}}{'avatar'}" alt="" /><br />~; }
	}

	$online = '';
	$usericon = 'user-offline';
	if($activemembers{$URL{'u'}} && (!$memberid{$URL{'u'}}{'hideonline'} || ($members{'Administrator',$username} && $memberid{$URL{'u'}}{'hideonline'}))) { $usericon = 'user-online'; }
	$usericon = qq~<img src="$images/$usericon.png" class="centerimg" alt="" /> ~;

	if($URL{'a'} eq 'profile') {
		if($URL{'s'} eq 'contact') { $callt = qq~<img src="$images/pm2_sm.gif" class="centerimg" alt="" /> $profiletxt[177]~; CallProfile(1); }
		elsif($URL{'s'} eq 'pw') { $callt = qq~<img src="$images/restriction.png" class="centerimg" alt="" /> $profiletxt[178]~; CallProfile(2); }
		elsif($URL{'s'} eq 'sig') { $callt = qq~<img src="$images/xx.gif" class="centerimg" alt="" /> $profiletxt[179]~; CallProfile(3); }
		elsif($URL{'s'} eq 'avatar') { $callt = qq~<img src="$images/smiley.png" class="centerimg" alt="" /> $profiletxt[180]~; CallProfile(4); }
			else { $callt = qq~<img src="$images/profile_sm.gif" class="centerimg" alt="" /> $profiletxt[181]~; CallProfile(5); }
	} elsif($URL{'a'} eq 'forum') {
		if($URL{'s'} eq 'lng') { $callt = qq~<img src="$images/open_thread.gif" class="centerimg" alt="" /> $profiletxt[182]~; CallProfile(8); }
		elsif($URL{'s'} eq 'time') { $callt = qq~<img src="$images/time_sm.png" class="centerimg" alt="" /> $profiletxt[183]~; CallProfile(7); }
		elsif($URL{'s'} eq 'messageblock') {  $callt = qq~<img src="$images/ban.png" class="centerimg" alt="" /> $profiletxt[266]~; CallProfile(10); }
			else { $callt = qq~<img src="$images/thread.png" class="centerimg" alt="" /> $profiletxt[184]~; CallProfile(6); }
	} elsif($URL{'a'} eq 'notify') {
		CoreLoad('Notify');
		if($URL{'s'} eq 'delete') { NotifyDel(); }
		elsif($URL{'m'} ne '') { AddDelNotify2(); }
			else { View(); }
	#} elsif($URL{'a'} eq 'extend' && $subsection{$URL{'s'}} ne '') {
		#$callt = qq~<img src="$images/$subsectimg{$URL{'s'}}" class="centerimg" alt="" /> $subsection{$URL{'s'}}~; CallProfile($URL{'s'});
	} elsif($URL{'a'} eq 'admin') {
		$callt = qq~<img src="$images/restriction.png" class="centerimg" alt="" /> $profiletxt[185]~; CallProfile(9);
	} elsif($URL{'a'} eq 'pm') {
		CoreLoad('PM');
		PMOpen();
		if($URL{'s'} eq 'write') { Write(); }
		elsif($URL{'s'} eq 'prefs') { Prefs(); }
		elsif($URL{'s'} eq 'block') { PMBlock(); }
		elsif($URL{'s'} eq 'delete') { PMDelete(); }
		elsif($URL{'s'} eq 'mdelete') { PMDelete2(); }
		elsif($URL{'s'} eq 'folders') { Folders(); }
		elsif($URL{'s'} eq 'search') { Search(); }
		elsif($URL{'s'} eq 'blist') { LoadBuddys(); }
		elsif($URL{'m'} ne '') { PMDisplay(); }
			else { PMStart(); }
	} elsif($URL{'a'} eq 'save') { CoreLoad('ProfileEdit'); SaveSettings(); }
		else { $panel = 1; PView();  $callt = qq~<img src="$images/profile_sm.gif" class="centerimg" alt="" /> $profiletxt[186]~; }

	if($perpic eq $var{60}) { $perpic = ''; }

	$title = $profiletxt[187];
	header();
	$ebout .= <<"EOT";
<table cellpadding="0" cellspacing="0" width="100%">
 <tr>
  <td class="vtop">
   <table cellpadding="0" cellspacing="1" class="border" width="200">
    <tr>
     <td class="titlebg"><div style="padding: 5px;"><strong>$title</strong></div></td>
    </tr><tr>
     <td style="width: 100%" class="win vtop">
      <div class="win2 center" style="padding: 20px;">$usericon$userurl{$URL{'u'}}</div>
      <div class="smalltext" id="membercenter">
EOT
	if(!$profileonly && !$pmdisable) {
		fopen(FILE,"$members/$username.pm");
		while($pms = <FILE>) {
			($med,$t,$t,$t,$t,$t,$n) = split(/\|/,$pms);
			if($med == 1) {
				++$new if($n);
				++$pmcnt;
			} elsif($med == 2) { ++$pmsent; }
			elsif($med == 3) { ++$pmstore; }
				else { ++$pmcnt{$med}; }
		}
		fclose(FILE);
		if($URL{'m'} eq '') {
			if($memberid{$username}{'pmnew'} != $new || $memberid{$username}{'pmcnt'} != $pmcnt) {
				%addtoID = (
					pmnew => $new,
					pmcnt => $pmcnt
				);

				SaveMemberID($username);
			}
		}

		$pmstore = $pmstore || 0;
		$pmsent = $pmsent || 0;
		$pmcnt = $pmcnt || 0;

		++$foldercnt;
		$foldercnt += 2;
		$ebout .= <<"EOT";
    <div class="catbg smalltext center" style="padding: 5px;"><strong>$profiletxt[188]</strong></div>
     <div style="padding: 5px; line-height: 1.5;"><a href="$surl\lv-memberpanel/a-pm/s-write/">$profiletxt[189]</a><br />
     <div style="padding: 3px; margin: 2px;" class="win2">
      <div style="padding: 3px;" class="win3"><strong><a href="$surl\lv-memberpanel/a-pm/s-folders/">$foldercnt $profiletxt[253]</a></strong></div>
	 <a href="$surl\lv-memberpanel/a-pm/s-start/f-1/">$profiletxt[190]</a> ($pmcnt)<br />
      <a href="$surl\lv-memberpanel/a-pm/s-start/f-2/">$profiletxt[192]</a> ($pmsent)<br />
      <a href="$surl\lv-memberpanel/a-pm/s-start/f-3/">$profiletxt[193]</a> ($pmstore)<br />
EOT
		foreach(@folders) {
			($fname,$fid) = split("/",$_);
			$cnt = $pmcnt{$fid} || 0;
			$ebout .= <<"EOT";
      <a href="$surl\lv-memberpanel/a-pm/s-start/f-$fid/">$fname</a> ($cnt)<br />
EOT
		}
		$ebout .= <<"EOT";
     </div>
     <a href="$surl\lv-memberpanel/a-pm/s-search/">$profiletxt[256]</a><br />
     <a href="$surl\lv-memberpanel/a-pm/s-prefs/">$profiletxt[194]</a><br />
     <a href="$surl\lv-memberpanel/a-pm/s-blist/">$profiletxt[257]</a>
    </div>
EOT
	}
	$ebout .= <<"EOT";
    <div class="catbg center smalltext" style="padding: 5px;"><strong>$profiletxt[195]</strong></div>
     <div style="padding: 5px; line-height: 140%;">
     <a href="$surl\lv-memberpanel/a-profile/s-contact/u-$URL{'u'}/">$profiletxt[177]</a><br />
     <a href="$surl\lv-memberpanel/a-profile/s-profile/u-$URL{'u'}/">$profiletxt[181]</a><br />
     <a href="$surl\lv-memberpanel/a-profile/s-pw/u-$URL{'u'}/">$profiletxt[178]</a><br />
EOT
	if($maxsig >= 0) { $ebout .= qq~<a href="$surl\lv-memberpanel/a-profile/s-sig/u-$URL{'u'}/">$profiletxt[179]</a><br />~; }
	$ebout .= <<"EOT";
     <a href="$surl\lv-memberpanel/a-profile/s-avatar/u-$URL{'u'}/">$profiletxt[180]</a>
     </div>
    <div class="catbg center smalltext" style="padding: 5px;"><strong>$profiletxt[196]</strong></div>
     <div style="padding: 5px; line-height: 140%;">
     <a href="$surl\lv-memberpanel/a-forum/s-messageblock/u-$URL{'u'}/">$profiletxt[266]</a><br />
     <a href="$surl\lv-memberpanel/a-forum/s-board/u-$URL{'u'}/">$profiletxt[184]</a><br />
     <a href="$surl\lv-memberpanel/a-forum/s-time/u-$URL{'u'}/">$profiletxt[183]</a><br />
     <a href="$surl\lv-memberpanel/a-forum/s-lng/u-$URL{'u'}/">$profiletxt[182]</a><br />
     </div>
EOT

	#fopen(FILE,"$prefs/ProfileSections.txt");
	#while($garb = <FILE>) {
	#	chomp $garb;
	#	($t,$section,$subsects) = split(/\|/,$garb);

		$eboutX .= <<"EOT";
     <div class="catbg center smalltext" style="padding: 5px;"><strong>$section</strong></div>
     <div style="padding: 5px; line-height: 140%;">
EOT
	#	foreach $subid (split(/\//,$subsects)) {
	#		$ebout .= qq~<a href="$surl\lv-memberpanel/a-extend/s-$subid/u-$URL{'u'}/">$subsection{$subid}</a><br />~;
	#	}
	#	$ebout .= "</div>";
	#}
	#fclose(FILE);

	if(!$profileonly && !$nonotify) {
		$ebout .= <<"EOT";
     <div class="catbg smalltext center" style="padding: 5px;"><strong>$profiletxt[197]</strong></div>
      <div style="padding: 5px; line-height: 140%;"><a href="$surl\lv-memberpanel/a-notify/">$profiletxt[198]</a></div>
EOT
	}
	if($members{'Administrator',$username}) {
		$ebout .= <<"EOT";
     <div class="catbg smalltext center" style="padding: 5px;"><strong>$profiletxt[199]</strong></div>
      <div style="padding: 5px; line-height: 140%;"><a href="$surl\lv-memberpanel/a-admin/s-position/u-$URL{'u'}/">$profiletxt[185]</a></div>
EOT
	}
	if($morecaller) {
		$morecaller = qq~<tr><td class="win smalltext" style="padding: 10px;">$morecaller</td></tr>~;
	}
	$ebout .= <<"EOT";
      </div>
     </td>
    </tr>
   </table>
  </td><td>&nbsp;</td><td class="vtop" style="width: 100%">
   <table cellpadding="0" cellspacing="1" class="border" width="100%">
    <tr>
     <td class="titlebg" style="padding: 5px;"><strong>$callt</strong></td>
    </tr>$morecaller<tr>
     <td class="win4"><div style="padding: 7px; padding-top: 10px; padding-bottom: 10px;">$displaycenter</div></td>
    </tr>
   </table>
  </td>
 </tr>
</table>
EOT
	footer();
	exit;
}

sub CallProfile {
	my($callervalue) = $_[0];
	CoreLoad('ProfileEdit');

	is_secure('profile', $callervalue);

	$displaycenter .= <<"EOT";
<form action="$surl\lv-memberpanel/a-save/as-$URL{'a'}/s-$URL{'s'}/u-$URL{'u'}/$verifyurl" method="post" id="post" enctype="multipart/form-data">
<table cellpadding="5" cellspacing="1" class="border" width="100%">
EOT
	if($callervalue == 1) { Contact(); } # Start Edit Profile
	elsif($callervalue == 2) { PW(); }
	elsif($callervalue == 3) { Signature(); }
	elsif($callervalue == 4) { AvatarSetup(); }
	elsif($callervalue == 5) { ProfileInfo(); }
	elsif($callervalue == 6) { BoardSettings(); } # Start Forum Settings
	elsif($callervalue == 7) { TimeSettings(); }
	elsif($callervalue == 8) { LngTheme(); }
	elsif($callervalue == 9) { AdminLoad(); } # Admin Settings
	elsif($callervalue == 10) { MessageBlock(); }
	# elsif($subsection{$callervalue} ne '') { ExtendedProfile($callervalue); }
	if($disablecaller) { return(); }
	$displaycenter .= <<"EOT";
 <tr>
  <td class="win2"><input type="hidden" name="caller" value="$callervalue" /><input type="submit" name="save" value=" $profiletxt[200] " /></td>
 </tr>
</table>
</form>
EOT
}

sub RecentReps {
	my(@temp);

	if(!@vlog) {
		fopen(VLOG,"$members/$viewuser.vlog");
		@vlog = <VLOG>;
		fclose(VLOG);
		chomp @vlog;
	}

	$start = $URL{'s'} || 0;
	$ending = 5+($start+1);

	$recentreps = <<"EOT";
<table class="innertable" cellpadding="7" cellspacing="0">
 <tr>
  <td>&nbsp;</td>
  <td width="200"><strong>$profiletxt[318]</strong></td>
  <td><strong>$profiletxt[319]</strong></td>
 </tr>
EOT

	foreach(@vlog) {
		($name,$t,$updwn,$repadded,$comment) = split(/\|/,$_);
		push(@temp,"$repadded|$name|$updwn");
	}
	foreach(sort {$b <=> $a} @temp) {
		($repadded,$name,$updwn) = split(/\|/,$_);
		++$counter;

		if($counter > $start && $counter < $ending) {
			$updown = $updwn == 1 ? 'add' : 'minus';
			GetMemberID($name);

			# if($comment eq '') { $comment = "<i>No comments.</i>"; }

			if($repadded ne '') { $daysago = int((time-($repadded))/86400)." $profiletxt[321]"; }
				else { $daysago = "<i>$profiletxt[320]</i>"; }

			if($userurl{$name} eq '') { $userurl{$name} = "<i>$profiletxt[320]</i>"; }

			$recentreps .= <<"EOT";
 <tr>
  <td><img src="$images/$updown.gif" alt="" /></td>
  <td>$userurl{$name}</td>
  <td>$daysago</td>
 </tr>
EOT
		}
	}

	if(!@vlog) {
		$recentreps .= qq~<tr><td colspan="3"><i>$memberid{$URL{'u'}}{'sn'} $profiletxt[322]</i></td></tr>~;
	}

	$recentreps .= qq~</table>~;

	if($registered eq '') { # AJAX
		
	}
}

sub PView {
	@mods = ();

	if($URL{'r'} ne '') {
		ReputationModify();

		GetMemberID($URL{'u'},'force');
	}

	# Error checking ...
	if(!$memguest) { is_member(); }
	$viewuser = $URL{'u'} ne '' ? $URL{'u'} : $username;
	GetMemberID($viewuser);
	if(!$memberid{$viewuser}{'sn'}) { error($profiletxt[88]); }

	UserMiniProfile($viewuser,'quick');

	if($username ne 'Guest') {
		if(!$pmdisable) {
			$addbuddy = qq~<span class="smalltext"><strong><a href="$surl\lv-memberpanel/a-pm/s-blist/p-2/buddy-$viewuser/">$profiletxt[258]</a></strong></span>~;
			$pm = qq~<a href="$surl\lv-memberpanel/a-pm/s-write/t-$URL{'u'}/">$profiletxt[284]</a>~;
		}
	}

	$registered = get_date($memberid{$viewuser}{'registered'},1);

	if($memberid{$viewuser}{'sitename'}) { $website = qq~<img src="$images/site_sm.gif" class="leftimg" alt="" />&nbsp;$profiletxt[285]: <strong><a href="$memberid{$viewuser}{'siteurl'}"$blanktarget>$memberid{$viewuser}{'sitename'}</a></strong><br /><br />~; }

	$mailme = $hmail && $memberid{$viewuser}{'hidemail'} && !$members{'Administrator',$username} ? '' : qq~<a href="mailto:$memberid{$viewuser}{'email'}" title="$gtxt{'28'}">$profiletxt[286]</a>~;

	$memberstat =~ s/<br \/>\Z//g;

	$title = "$profiletxt[93] $memberid{$viewuser}{'sn'}";
	if(!$panel) { header(); }

	$displaycenter = '';

	$displaycenter .= <<"EOT";
<script type="text/javascript">
//<![CDATA[
function confirmwin(mevalues) {
 if(mevalues == 1) { url = "/a-remove"; explain = "$profiletxt[150]: $memberid{$URL{'u'}}{'sn'}?"; }
 if(mevalues == 2) { url = "/a-view/r-1"; explain = "$profiletxt[280] \\"$memberid{$URL{'u'}}{'sn'}\\"$profiletxt[279]"; }
 if(mevalues == 3) { url = "/a-view/r-0"; explain = "$profiletxt[281] \\"$memberid{$URL{'u'}}{'sn'}\\"$profiletxt[279]";}

 if(window.confirm(explain)) { location = "$surl\lv-memberpanel/u-$URL{'u'}"+url+'/'; }
}
//]]>
</script>
<table cellpadding="5" cellspacing="1" class="border" width="100%">
 <tr>
  <td class="titlebg" colspan="2"><strong>$profiletxt[93]</strong></td>
 </tr><tr>
  <td class="win smalltext vtop" rowspan="2" style="width: 180px; padding:0px;">$profile{$viewuser}</td>
  <td class="win2 vtop">
   <div style="font-size: 25px; font-weight: bold;">$memberid{$viewuser}{'sn'}</div>
   <div class="smalltext">$addbuddy<br /><strong>$profiletxt[283]</strong> $registered<br /></div><br /><div>$website<img src="$images/search.png" class="centerimg" border="" /> <a href="$surl\lv-search/p-user/by-$viewuser/">$profiletxt[248]</a></div>
  </td>
 </tr><tr>
  <td class="win3 smalltext">
   <table cellpadding="3" cellspacing="0" class="innertable">
EOT
	$lastpm = $memberid{$viewuser}{'lastpm'} && (!$memberid{$viewuser}{'hideonline'} || $members{'Administrator',$username}) ? get_date($memberid{$viewuser}{'lastpm'}) : $gtxt{'1'};
	$lastpost = $memberid{$viewuser}{'lastpost'} && (!$memberid{$viewuser}{'hideonline'} || $members{'Administrator',$username}) ? get_date($memberid{$viewuser}{'lastpost'}) : $gtxt{'1'};

	if($logactive) {
		$lastactive = $memberid{$viewuser}{'lastactive'} && (!$memberid{$viewuser}{'hideonline'} || $members{'Administrator',$username}) ? get_date($memberid{$viewuser}{'lastactive'}) : $gtxt{'1'};

		$displaycenter .= <<"EOT";
    <tr>
     <td class="smalltext"><strong>$profiletxt[113]:</strong></td><td class="smalltext">$lastactive</td>
    </tr>
EOT
	}
	$displaycenter .= <<"EOT";
    <tr>
     <td class="smalltext"><strong>$profiletxt[307]:</strong></td><td class="smalltext">$lastpost</td>
    </tr><tr>
     <td class="smalltext"><strong>$profiletxt[308]:</strong></td><td class="smalltext">$lastpm</td>
    </tr>
   </table>
  </td>
 </tr>
</table><br />
EOT
	if($enablerep) {
		fopen(VLOG,"$members/$viewuser.vlog");
		@vlog = <VLOG>;
		fclose(VLOG);
		$totalcount = @vlog;
		$totalup = 0;
		$totaldown = 0;
		$lpos = $mpos = $spos = $sneg = $mneg = $lneg = 0;
		chomp @vlog;
		foreach(@vlog) {
			($name,$t,$updwn,$repadded) = split(/\|/,$_);
			if($name eq $username) {
				$updown = $updwn;
				$votelog = 1;
			}

			if($updwn == 1) {
				++$totalup;

				if(time < 2592000+$repadded) { ++$spos; }
				elsif(time < 15552000+$repadded) { ++$mpos; }
				elsif(time < 31104000+$repadded) { ++$lpos; }
					else { ++$lpos; }
			} else {
				++$totaldown;

				if(time < 2592000+$repadded) { ++$sneg; }
				elsif(time < 15552000+$repadded) { ++$mneg; }
				elsif(time < 31104000+$repadded) { ++$lneg; }
					else { ++$lneg; }
			}
		}
		if($username ne $viewuser && $username ne 'Guest') {
			$js = $updown == 1 ? '3' : '2';
			$updown = $updown == 1 ? 'minus' : 'add';
			if(!$votelog) { $finalrep = qq~&nbsp; &nbsp; <a href="javascript:confirmwin(2);"><img src="$images/add.gif" style="vertical-align: middle" alt="" /></a> <a href="javascript:confirmwin(3);"><img src="$images/minus.gif" style="vertical-align: middle" alt="" /></a>~; }
				else { $finalrep = qq~&nbsp; &nbsp; <a href="javascript:confirmwin($js);"><img src="$images/$updown.gif" alt="" /></a>~; }
		}

		$memberrep = $memberid{$viewuser}{'rep'} ne '' ? "$memberid{$viewuser}{'rep'}%" : $gtxt{'13'};

		RecentReps();

		$displaycenter .= <<"EOT";
<table cellpadding="5" cellspacing="1" class="border" width="100%">
 <tr>
  <td class="titlebg"><strong>$profiletxt[289]$finalrep</strong></td>
 </tr><tr>
  <td class="win">
   <table cellpadding="0" cellspacing="1" width="100%">
    <tr>
     <td style="width: 40%" class="vtop">
      <table cellpadding="3" cellspacing="0" width="100%">
       <tr>
        <td><strong>$profiletxt[290]:</strong></td>
        <td class="right">$memberrep</td>
       </tr><tr>
        <td colspan="2"></td>
       </tr><tr>
        <td><strong>$profiletxt[291]:</strong></td>
        <td class="right"><span class="greenrep">$totalup</span></td>
       </tr><tr>
        <td><strong>$profiletxt[292]:</strong></td>
        <td class="right"><span class="redrep">$totaldown</span></td>
       </tr><tr>
        <td colspan="2"></td>
       </tr><tr>
        <td><strong>$profiletxt[293]:</strong></td>
        <td class="right">$totalcount</td>
       </tr>
      </table>
     </td>
     <td>&nbsp;</td>
     <td style="width: 60%" class="vtop">
      <table cellpadding="5" cellspacing="0" width="100%">
       <tr>
        <td colspan="2"></td>
        <td class="center">$profiletxt[294]</td>
        <td class="center">$profiletxt[295]</td>
        <td class="center">$profiletxt[296]</td>
       </tr><tr>
        <td class="border" colspan="5" style="padding: 1px"></td>
       </tr><tr>
        <td class="center"><img src="$images/add.gif" alt="" /></td>
        <td class="greenrep">$profiletxt[297]</td>
        <td class="greenrep center">$spos</td>
        <td class="greenrep center">$mpos</td>
        <td class="greenrep center">$lpos</td>
       </tr><tr>
        <td class="border" colspan="5" style="padding: 1px"></td>
       </tr><tr>
        <td class="center"><img src="$images/minus.gif" alt="" /></td>
        <td class="redrep">$profiletxt[298]</td>
        <td class="redrep center">$sneg</td>
        <td class="redrep center">$mneg</td>
        <td class="redrep center">$lneg</td>
       </tr>
      </table>
     </td>
    </tr>
   </table>
  </td>
 </tr><tr>
  <td class="catbg">$profiletxt[323]</td>
 </tr><tr>
  <td class="win2" id="recentreps">
   $recentreps
  </td>
 </tr>
</table><br />
EOT
		}

		$displaycenter .= <<"EOT";
<table cellpadding="0" cellspacing="0" width="100%">
 <tr>
  <td style="width: 50%" class="vtop">
   <table cellpadding="5" cellspacing="1" class="border" width="100%">
    <tr>
     <td class="catbg" style="width: 100%"><strong>$profiletxt[94]</strong></td>
    </tr><tr>
     <td class="win" style="padding: 0px">
      <table cellpadding="6" cellspacing="0" width="100%">
EOT
	$displaycenter .= !$hideposts ? qq~<tr><td style="width: 100px"><strong>$profiletxt[96]:</strong></td><td>~.MakeComma($memberid{$viewuser}{'posts'})."</td></tr>" : '';

	$displaycenter .= $memberid{$viewuser}{'location'} ? qq~<tr><td><strong>$ltxt[41]:</strong></td><td>$memberid{$viewuser}{'location'}</td></tr>~ : '';

	if($memberid{$viewuser}{'sex'}) {
		if($memberid{$viewuser}{'sex'} == 1) { $gen = $profiletxt[35]; }
		elsif($memberid{$viewuser}{'sex'} == 2) { $gen = $profiletxt[36]; }
		$displaycenter .= <<"EOT";
<tr>
 <td><strong>$profiletxt[33]:</strong></td>
 <td>$gen</td>
</tr>
EOT
	}

	if($memberid{$viewuser}{'dob'}) {
		$age = calage($memberid{$viewuser}{'dob'});
		$displaycenter .= <<"EOT";
<tr>
 <td><strong>$profiletxt[100]:</strong></td>
 <td><a href="$ageurl">$age</a></td>
</tr>
EOT
	}

	if($logactive) {
		($t1,$t2) = split(/\|/,$memberid{$viewuser}{'rndsid'});
		if($t1 > 60) {
			$days = '';
			$timeon = '';
			$days  = int($t1/86400);
			$hours = int($t1/3600)-($days*24);
			$mins  = int($t1/60)-(($hours+($days*24))*60);

			$days  = $days ? " $days $profiletxt[300]" : '';
			$hours = $hours ? " $hours $gtxt{'3'}" : '';
			$mins  = $mins ? " $mins $gtxt{'2'}" : '';
			$timeon = "<br /><strong>$profiletxt[299]:</strong>$days$hours$mins";

			$displaycenter .= <<"EOT";
<tr>
 <td><strong>$profiletxt[299]:</strong></td>
 <td>$days$hours$mins</td>
</tr>
EOT
		}
	}

	if($activemembers{$viewuser}) { $offonline = $gtxt{'30'}; }
	elsif($offonline eq '') { $offonline = $gtxt{'31'}; }
	if(!$members{'Administrator',$username} && $memberid{$viewuser}{'hideonline'}) { $offonline = $gtxt{'1'}; }

	$displaycenter .= <<"EOT";
       <tr>
        <td><strong>$profiletxt[287]:</strong></td>
		<td>$offonline</td>
       </tr>
      </table>
     </td>
    </tr>
   </table>
  </td>
  <td>&nbsp;</td>
  <td style="width: 50%" class="vtop">
   <table cellpadding="5" cellspacing="1" class="border" width="100%">
    <tr>
     <td class="catbg" style="width: 100%"><strong>$profiletxt[288]</strong></td>
    </tr><tr>
     <td class="win" style="padding: 0px">
      <table cellpadding="6" cellspacing="0" width="100%">
EOT
	if($memberid{$viewuser}{'icq'} ne '') {
		$allcnt = 1;
		$displaycenter .= <<"EOT";
<tr>
 <td class="center win2" style="width: 35px"><img src="$images/icq.png" alt="$profiletxt[42]" /></td>
 <td><a href="http://www.icq.com/whitepages/wwp.php?to=$memberid{$viewuser}{'icq'}" onclick="target='icq';">$memberid{$viewuser}{'icq'}</a></td>
</tr>
EOT
	}
	if($memberid{$viewuser}{'aim'} ne '') {
		$allcnt = 1;
		$small = $memberid{$viewuser}{'aim'};
		$small =~ s/\+/ /gsi;
		$displaycenter .= <<"EOT";
<tr>
 <td class="center win2" style="width: 35px"><img src="$images/aim.png" alt="$profiletxt[43]" /></td>
 <td><a href="aim:goim?screenname=$memberid{$viewuser}{'aim'}&amp;message=You+there?" title="$profiletxt[43]">$small</a></td>
</tr>
EOT
	}
	if($memberid{$viewuser}{'yim'} ne '') {
		$allcnt = 1;
		$displaycenter .= <<"EOT";
<tr>
 <td class="center win2" style="width: 35px"><img src="$images/yim.png" alt="$profiletxt[44]" /></td>
 <td><a href="http://edit.yahoo.com/config/send_webmesg?.target=$memberid{$viewuser}{'yim'}" onclick="target='yahoo';" title="$profiletxt[44]">$memberid{$viewuser}{'yim'}</a></td>
</tr>
EOT
	}
	if($memberid{$viewuser}{'msn'} ne '') {
		$allcnt = 1;
		$displaycenter .= <<"EOT";
<tr>
 <td class="center win2" style="width: 35px"><img src="$images/msn.png" alt="$profiletxt[45]" /></td>
 <td><a href="http://members.msn.com/$memberid{$viewuser}{'msn'}" title="$profiletxt[45]">$memberid{$viewuser}{'msn'}</a></td>
</tr>
EOT
	}
	if($memberid{$viewuser}{'skype'} ne '') {
		$allcnt = 1;
		$displaycenter .= <<"EOT";
<tr>
 <td class="center win2" style="width: 35px"><img src="$images/skype.png" alt="Skype" /></td>
 <td><a href="skype:$memberid{$viewuser}{'skype'}" onclick="target='skype';" title="Skype">$memberid{$viewuser}{'skype'}</a></td>
</tr>
EOT
	}
	if($pm ne '') {
		$allcnt = 1;
		$displaycenter .= <<"EOT";
<tr>
 <td class="center win2" style="width: 35px"><img src="$images/pm_sm.gif" alt="" /></td>
 <td>$pm</td>
</tr>
EOT
	}
	if($mailme ne '') {
		$allcnt = 1;
		$displaycenter .= <<"EOT";
<tr>
 <td class="center win2" style="width: 35px"><img src="$images/email_sm.gif" alt="" /></td>
 <td>$mailme</td>
</tr>
EOT
	}

	$displaycenter .= !$allcnt ? qq~<tr><td colspan="2">$profiletxt[110]</td></tr>~ : '';

	$displaycenter .= <<"EOT";
      </table>
     </td>
    </tr>
   </table>
  </td>
 </tr>
EOT
	if($memberid{$viewuser}{'status'} || ($members{'Administrator',$username} || $URL{'u'} eq $username || $proon)) {
		$displaycenter .= <<"EOT";
 <tr>
  <td colspan="3"><br />
   <table cellpadding="5" cellspacing="1" class="border" width="100%">
    <tr>
     <td class="catbg" colspan="2"><strong>$profiletxt[111]</strong></td>
    </tr><tr>
     <td class="win" colspan="2" style="padding: 0px">
      <table cellspacing="0" cellpadding="6" class="innertable">
EOT
}
	if($memberid{$viewuser}{'status'}) {
		$type = $memberid{$viewuser}{'stauts'} eq 'ADMIN' ? $profiletxt[173] : $memberid{$viewuser}{'status'} eq 'EMAIL|ADMIN' ? $profiletxt[174] : $memberid{$viewuser}{'status'} eq 'EMAIL' ? $profiletxt[175] : $profiletxt[176];
		$validation = $memberid{$viewuser}{'validation'} ne '' ? qq~ (<a href="$surl\lv-register/p-resend/u-$viewuser/">$profiletxt[326]</a>)~ : '';
		$displaycenter .= <<"EOT";
<tr>
 <td class="center win2" style="width: 35px"><img src="$images/mem_main.gif" alt="" /></td>
 <td><strong>$profiletxt[172]:</strong></td>
 <td class="redrep">$type$validation</td>
</tr>
EOT
	}

	if($members{'Administrator',$username} || $URL{'u'} eq $username || $proon) {
		$cnt = $members{'Administrator',$username} ? 2 : 1;
		$displaycenter .= <<"EOT";
<tr>
 <td rowspan="$cnt" class="center win2" style="width: 35px"><img src="$images/restriction.png" alt="" /></td>
 <td><strong>$profiletxt[117]:</strong></td>
 <td><a href="javascript:confirmwin(1);">$profiletxt[119]</a></td>
</tr>
EOT
	}
	if($memberid{$viewuser}{'status'} || ($members{'Administrator',$username} || $URL{'u'} eq $username || $proon)) {
		$displaycenter .= <<"EOT";
      </table>
     </td>
    </tr>
   </table>
  </td>
 </tr>
EOT
	}

	$message = BC($memberid{$viewuser}{'sig'});

	if($message) {
		$displaycenter .= <<"EOT";
 <tr>
  <td colspan="3"><br />
   <table cellpadding="5" cellspacing="1" class="border" width="100%">
    <tr>
     <td class="catbg" colspan="2"><strong>$profiletxt[55]</strong></td>
    </tr><tr>
     <td class="win postbody" colspan="2"><div class="smalltext">$message</div></td>
    </tr>
   </table>
  </td>
 </tr>
EOT
	}

	$displaycenter .= "</table>";
	if(!$panel) { $ebout .= $displaycenter; footer(); exit; }
}

sub Remove {
	if(!-e("$members/$URL{'u'}.dat")) { error("$profiletxt[2] $URL{'u'}."); }

	$title = $profiletxt[152];
	header();

	CoreLoad('Moderate');
	KillGroups($URL{'u'},3);

	$ebout .= qq~<script type="text/JavaScript">//<![CDATA[ window.alert('$memberid{$URL{'u'}}{'sn'}, $profiletxt[153]'); location = "$surl"; //]]></script>~;
	footer();
	exit;
}

sub ReputationModify {
	my($memberrep);

	is_member();
	if($URL{'u'} eq $username) { return(0); }

	GetMemberID($URL{'u'});
	if($memberid{$URL{'u'}}{'sn'} eq '') { return(-1); } # User not found
	$memberrep = 0;

	fopen(VLOG,"$members/$URL{'u'}.vlog");
	@vlog = <VLOG>;
	fclose(VLOG);
	chomp @vlog;

	$rvar = $URL{'r'} ? 1 : 0;
	$curtime = time;
	if($username ne $URL{'u'}) { push(@vlog,"$username||$rvar|$curtime"); } else { $nevar = 2; }

	fopen(VLOG,">$members/$URL{'u'}.vlog");
	foreach(@vlog) {
		($vuser,$t,$vadd,$pasttime) = split(/\|/,$_);

		if($noadd && $vuser eq $username) { $nevar = 1; next; }

		if($username eq $vuser) {
			$noadd = 1;
			if($vadd != $rvar) { $vadd = $rvar; }
			$pasttime = time;
		}

		if($vadd == 1) { ++$pluses; ++$totals; }
			else { ++$totals; }

		print VLOG "$vuser||$vadd|$pasttime\n";
	}
	fclose(VLOG);

	if($totals > 0) { $memberrep = sprintf("%.2f",(($pluses/$totals)*100)); }
		else { $memberrep = ''; }

	$addtoID{'rep'} = $memberrep;
	$addtoID{'prep'} = $pluses;
	$addtoID{'nrep'} = $totals-$pluses;

	SaveMemberID($URL{'u'});

	UserDatabase($URL{'u'},$memberid{$URL{'u'}}{'sn'},$memberid{$URL{'u'}}{'posts'},$memberid{$URL{'u'}}{'registered'},$memberid{$URL{'u'}}{'dob'},$memberid{$URL{'u'}}{'email'},$memberrep);

	return(1);
}
1;