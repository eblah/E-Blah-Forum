#############################################
# E-Blah Bulletin Board Systems        2008 #
#############################################
# Copyright (c) 2001 - 2008 E-Blah.         #
#############################################

CoreLoad('MessageDisplay',1);

$BCAdvanced = 0 if($memberid{$username}{'bcadvanced'});

sub MessageDisplay {
	if(!GetMemberAccess($binfo[14])) {
		if($binfo[14] eq '') { error($messagedisplay[66]); }
		error($messagedisplay[53]);
	}

	$messid = $URL{'m'};
	fopen(FILE,"$boards/Stick.txt");
	while(<FILE>) {
		chomp;
		($t,$m) = split(/\|/,$_);
		$stickme{$m} = 1;
	}
	fclose(FILE);

	if($username ne 'Guest') {
		fopen(ULOG,"$members/$username.log");
		while(<ULOG>) {
			chomp;
			($lid,$ltime) = split(/\|/,$_);
			$logged{$lid} = $ltime;
		}
		fclose(ULOG);
	}

	fopen(FILE,"$boards/$URL{'b'}.msg") || error($ltxt[5]);
	while(<FILE>) {
		chomp;
		($messageid,$ptitle,$t,$t,$treplies,$tpoll,$type,$tmicon,$ltime) = split(/\|/,$_);
		if($found == 1) { ++$found; }
		if($messid eq 'latest' && !$found) { $messid = $messageid; $URL{'m'} = $messid; $URL{'s'} = $treplies; }
		if($messid == $messageid) {
			$poll = $tpoll;
			$status = FindStatus($ltime);
			$title = $ptitle;
			$found = 1;
			$maxreplies = $replies = $treplies;
			$micon = $tmicon;
			$mlocked = $type;
		} else {
			if($logged{$messageid} < $ltime && $logged{"AllRead_$URL{'b'}"} < $ltime && $logged{"AllBoards"} < $ltime) { $boardnew = 1; }
		}

		last if($boardnew && $found);
	}
	fclose(FILE);
	if($found < 0 || !(-s("$messages/$messid.txt"))) { error("$messagedisplay[1]: $messid.txt",1); }

	if($URL{'s'} eq 'new') {
		$latestmessage = 0;
		fopen(FILE,"$messages/$messid.txt");
		while($append = <FILE>) {
			($t,$t,$t,$t,$newdate) = split(/\|/,$append);
			++$latestmessage;
			if($newdate > $logged{$messid} && $logged{"AllRead_$URL{'b'}"} < $newdate && $logged{"AllBoards"} < $newdate) { last; }
		}
		fclose(FILE);
		$latestmessage -= 1;
		$URL{'s'} = $latestmessage;
	}

	BoardProperties();

	if($mlocked) { $repallow = 0; }

	fopen(ADD,"+<$messages/$messid.view") || fopen(ADD,">$messages/$messid.view");
	$curnumber = <ADD> || 0;
	seek(ADD,0,0);
	truncate(ADD,0);
	$viewcnt = $curnumber+1;
	print ADD $viewcnt,"\n";
	fclose(ADD);
	$viewcnt = MakeComma($viewcnt);

	# How many page links?
	$tmax = $totalpp*20;

	$treplies = ($maxreplies+1);
	if($treplies <= $maxmess) {
		$pagelinks = "<strong>1</strong>";
		$totalpages = 1;
		$URL{'s'} = 1;
	} else {
		$totalpages = int(($treplies/$maxmess)+.99);

		$tstart = $URL{'s'} || 0;
		$link = "$surl\lm-$messid/s";
		if($tstart > $treplies) { $tstart = $treplies; }
		$tstart = (int($tstart/$maxmess)*$maxmess);
		if($tstart > 0) { $bk = ($tstart-$maxmess); $pagelinks = qq~<a href="$link-$bk/">&#171;</a> ~; }
	
		if((int($treplies/$maxmess) < $totalpp) < $totalpp) { $totalpp *= 2; }
		$beforeafter = int($totalpp/2);
		$counter = (($tstart/$maxmess)+1)-$beforeafter;
		if($counter < 1) { $counter = 1; }
		$mcnter = ($tstart-($maxmess*$beforeafter));
		if($mcnter < 1) { $mcnter = 0; }
		$counter2 = $counter;
	
		if($counter != 1) { $pagelinks .= qq~<a href="$link-0/">...</a> ~; }
	
		for($i = $mcnter; $i < $treplies; $i += $maxmess) {
			if($URL{'s'} ne 'all' && $i == $tstart || $treplies < $maxmess) { $pagelinks .= qq~<strong>$counter</strong> ~; $nxt = ($tstart+$maxmess); }
				else { $pagelinks .= qq~<a href="$link-$i/">$counter</a> ~; }
	
			++$counter;
	
			if($counter > $counter2+$beforeafter*2) {
				$gbk = (int($treplies/$maxmess)*$maxmess); # Last post in series
				$pagelinks .= qq~ <a href="$link-$gbk/">...</a>~; last;
			}
		}
		if(($tstart+$maxmess) != $i && $URL{'s'} ne 'all') { $pagelinks .= qq~ <a href="$link-$nxt/">&#187;</a>~; }
		if($treplies > $maxmess && !$sall) { $pagelinks .= $URL{'s'} ne 'all' ? qq~ <a href="$link-all/">$messagedisplay[2]</a>~ : qq~ <strong>$messagedisplay[2]</strong>~; }
	}

	if($tagsenable && -e("$messages/$URL{'m'}.tags")) {
		fopen(FILE,"$messages/$URL{'m'}.tags");
		@tags = <FILE>;
		fclose(FILE);
		chomp @tags;
		if($tags[0] ne '') {
			foreach(split(/, ?/,$tags[0])) {
				$enc = urlencode($_);
				$enc =~ s/\%20/\+/g;
				$enc =~ s/\%2D/\*/g;
				$tag = CensorList($_);
				$threadtags .= qq~$tag, ~;
			}
		}
		$threadtags =~ s/, \Z//g;
	}

	$title = CensorList($title);
	LogPage($boardnew);
	header();
	Mods();
	if($modz) { $modz = "<strong>$ltxt[7]:</strong> $modz"; }
	$ebout .= <<"EOT";
<script src="$bdocsdir/common.js" type="text/javascript"></script>

<script type="text/javascript">
//<![CDATA[
function clear(o,url2) {
	if(o == 'all') { url = '$scripturl/v-mod/a-delthread/m-$messid'; }
	else if(o == '') { url = url2; }
		else { url = '$scripturl/v-mod/a-delnum/p-1/m-$messid/n-'+o+'/'; }
	if(window.confirm('$messagedisplay[23]')) { location = url; }
}

outtimer = '';
function GetLinks(JSinput) {
	MenuItems = new Array();
	MenuItems[0] = '<a href="#" onclick="javascript:EditMessage(\\'$surl\lv-post/b-$URL{'b'}/a-modify/m-$URL{'m'}/n-' + JSinput + '/quick-1/\\',\\'\\',\\'\\',\\'' + 'm' + JSinput + '\\'); ClearMenu(); return false;">$messagedisplay[59]</a>';
	MenuItems[1] = '<a href="$surl\lv-post/b-$URL{'b'}/a-modify/m-$messid/n-' + JSinput + '/" onclick="ClearMenu();">$messagedisplay[60]</a>';
}
//]]>
</script>

<div id="menu-eblah" style="width: 100px; visibility: hidden; position: absolute; z-index: 100; padding: 1px" onmouseout="outtimer = setTimeout('ClearMenu()',3000);" onmouseover="clearTimeout(outtimer);" class="border center"></div>

<table cellpadding="1" cellspacing="1" width="100%" class="border">
 <tr>
  <td class="win">
   <table cellpadding="6" cellspacing="0" width="100%">
    <tr>
     <td><img src="$images/crumbs.png" class="centerimg" alt="" /> <a href="$surl">$mbname</a> &nbsp;<strong>&rsaquo;</strong> &nbsp;<a href="$surl\lc-$catid/">$catname</a> &nbsp;<strong>&rsaquo;</strong> &nbsp;<a href="$surl\lb-$URL{'b'}/">$boardnm</a> &nbsp;<strong>&rsaquo; &nbsp;$title</strong></td>
     <td class="right smalltext">$modz</td>
    </tr>
   </table>
  </td>
 </tr>
EOT
	if($showactive) {
		GetActiveUsers();
		$ebout .= <<"EOT";
 <tr>
  <td class="win smalltext">
   <div class="win2" style="padding: 6px"><strong>$var{'90'}</strong></div>
   <div style="padding: 6px">$memberson $var{'97'} $gcnt $var{'91'}</div>
  </td>
 </tr>
EOT
	}
	$ebout .= '</table><br />';

	if($poll) { CoreLoad('Poll'); PollDisplay(); }
	if($repallow) { $allowposts = qq~<a href="$surl\lv-post/b-$URL{'b'}/m-$messid/" rel="nofollow">$Iimg{'reply'}</a>$Imsp2~; } else { $mlocked = 1; }
	$print_reply = qq~$allowposts$Imsp2<a href="$surl\lv-print/m-$messid/">$Iimg{'print'}</a>~;
	if($sview) { $views = qq~<span class="smalltext">&nbsp; $messagedisplay[8] <strong>$viewcnt</strong> $messagedisplay[9]</span>~; }
	if($username ne 'Guest' && !$nonotify) { $notify = qq~ | <a href="$scripturl/v-memberpanel/a-notify/m-$messid/" rel="nofollow">$messagedisplay[73]</a>~; }

	if($latestmessage ne '' && $latestmessage > 0) {
		$ebout .= <<"EOT";
<script type="text/javascript">
//<![CDATA[
window.onload = function() {
	document.location.href = '#num$latestmessage';
}
//]]>
</script>		
<table cellpadding="3" cellspacing="1" class="border" width="100%">
 <tr>
  <td class="win3" colspan="3" style="padding: 10px;">
EOT
		if($URL{'new'} eq 'posts') { $ebout .= qq~<img src="$images/lamp.gif" class="centerimg"> $messagedisplay[62]<br /><br />~; }
		$ebout .= <<"EOT";
   $messagedisplay[54] <a href="#num$latestmessage">$messagedisplay[55] $latestmessage</a>.
  </td>
 </tr>
</table><br />
EOT
	}

	$ebout .= <<"EOT";
<table cellpadding="0" cellspacing="0" width="100%" style="margin-bottom: 5px;">
 <tr>
  <td style="width: 25%" class="indextitle">$title<span class="smalltext">$views</span></td>
  <td style="text-align: right; width: 25%" class="indexmenu">$print_reply</td>
 </tr>
</table>
<table cellpadding="5" cellspacing="1" class="border" width="100%">
 <tr>
  <td class="catbg" colspan="3" style="padding: 8px">
   <table cellpadding="0" cellspacing="0" width="100%">
    <tr>
	 <td class="pages">$totalpages $gtxt{'45'} $pagelinks</td>
	 <td class="right normaltext"><a href="$surl\lv-recommend/b-$URL{'b'}/m-$messid/" rel="nofollow">$messagedisplay[74]</a>$notify</td>
	</tr>
   </table>
  </td>
 </tr>
EOT
	$stick = qq~<a href="$scripturl/v-mod/a-sticky/m-$messid/s-$URL{'s'}/">$messagedisplay[68]</a>~;
	if($ismod) { $ipon = 1; }
	if($modon) {
		$ismod = 1;
		$stick = $ston ? " $stick" : '';
	}
	elsif($ston) { $stick = " | ".$stick; }
		else { $stick = " | $stick"; }

	$counter = 0;
	$counter2 = 0;
	fopen(FILE,"$messages/$messid.txt");
	while($append = <FILE>) {
		++$counter;
		if($URL{'s'} eq 'all' || ($counter > $tstart && $counter2 < $maxmess)) {
			push(@msgs,$append);
			++$counter2;
		}
	}
	fclose(FILE);
	chomp @msgs;

	$ads[1] = $displayadverts;

	$counter = $tstart || 0;
	if($URL{'highlight'} && $URL{'highlight'} !~ /[#%,\\\/:?"<>'|@^\$\&~'\)\(\]\[\;{}!`=-]/) { @lights = split(/\+/,$URL{'highlight'}); } # Highlighter
	foreach(@msgs) {
		$extra = '';
		($user,$message,$ipaddr,$email,$fdate,$nosmile,$t,$t,$afile,$modified) = split(/\|/,$_);
		GetMemberID($user);
		if($memberid{$user}{'sn'} eq '') { $guestuser = 1; $user2 = 'Guest'; } else { $user2 = $user; }

		# Show the cool bar ...
		if($showbar) {
			$ad = $ad2 = '';
			if($showads > 0 && !GetMemberAccess($disableads)) { $ad = $ads[$counter % ($maxmess/$showads)]; }
			if($ad eq '') { $ad2 = ' style="height: 5px"'; }
			$ebout .= qq~<tr><td colspan="3" class="win4"$ad2>$ad</td></tr>~;
		} else { $showbar = 1; }

		# Block the users now ...
		$quit = 0;
		if($username ne 'Guest' && $URL{'override'} ne $counter && ($URL{'override2'} ne $user2)) {
			foreach(@blockedusers) {
				if($_ eq $user || ($guestuser && $_ eq 'Guest')) {
					GetMemberID($_);
					$ebout .= <<"EOT";
<tr>
 <td colspan="3" class="center win2"><br /><strong>$memberid{$_}{'sn'}</strong> ($_) $messagedisplay[39] (<strong><a href="$surl\lv-memberpanel/remove-$_/a-save/as-forum/s-messageblock/caller-10/">$messagedisplay[40]</a></strong>).<br />$messagedisplay[41] <strong><a href="$surl\lm-$URL{'m'}/s-$URL{'s'}/override-$counter/">$messagedisplay[42]</a></strong>, $messagedisplay[43] <strong><a href="$surl\lm-$URL{'m'}/s-$URL{'s'}/override2-$_/">$messagedisplay[42]</a></strong>.<br /><br /></td>
</tr>
EOT
					$quit = 1;
					++$counter;
					last;
				}
			}
			if($quit) { next; }
		}

		$message =~ s/\&#124;/|/g;
		$message = BC($message);

		$message = qq~<div id="m$counter">$message</div>~;

		($message,$message2) = ($message2,$message);

		if($URL{'highlight'}) { Highlight($message2); }
		$nosmile = ($nosmile == 1 || $nosmile == 3) ? 1 : 0;

		if($profile{$user} eq '') {
			$guest = UserMiniProfile($user);
		} else { $guest = 0; }
		
		if(!$guest) {
			$membername = $userurl{$user};
		} else {
			$profile{$user} = $tempprof;
			$membername = $tempuser;
		}

		$date = get_date($fdate);

		$attachments = '';
		if($afile) {
			$attachments .= '<br /><br /><br />';

			foreach( split(/\//,$afile) ) {
				$attachments3 = '';
				if($_ && -e("$uploaddir/$_")) {
					if($gattach && $username eq 'Guest') { $downloads = qq~<span class="smalltext">$messagedisplay[51]</span>~; } else {
						fopen(FILE,"$prefs/Hits/$_.txt");
						@nump = <FILE>;
						fclose(FILE);
						chomp @nump;
						$nump = $nump[0];

						$size = sprintf("%.2f",(-s "$uploaddir/$_")/1024);
						$type = "KB";
						if($size > 1000) { $size = sprintf("%.2f",$size/1024); $type = "MB"; }
						if($_ =~ /(jpg|jpeg|gif|art|bmp|png)\Z/) {
							++$nump;
							if(-e("$uploaddir/thumbnails/$_")) { $thumbnail = '/thumbnails'; $below = qq~<br /><a href="$surl\lv-download/f-$_/">$messagedisplay[61]</a>~; }
								else {
									fopen(ADD,"+>$prefs/Hits/$_.txt");
									print ADD $nump,"\n";
									fclose(ADD);

									$thumbnail = $below = '';
								}
							$downloadurl = "$uploadurl/$_";
							$attachments3 = qq~<tr><td class="win" colspan="2"><a href="$uploadurl/$_"><img src="$uploadurl$thumbnail/$_" alt="" /></a></td></tr>~;
						} else {
							$downloadcount = qq~<strong>$nump</strong> $messagedisplay[46] &nbsp; - &nbsp; ~;
							$downloadurl = "$surl\lv-download/f-$_/";
						}
						if($members{'Administrator',$username} || $modifyon) { $attachments2 = qq~<a href="javascript:clear('','$scripturl/v-admin/a-attlog/p-del1/f-$_/m-$URL{'m'}/s-$URL{'s'}/');"><img src="$images/ban.png" alt="$messagedisplay[45]" /></a>~; }
						$downloads = qq~<strong>$messagedisplay[12]:</strong> <a href="$downloadurl" onclick="target='download';">$_</a><br />$downloadcount<strong>$messagedisplay[47]:</strong> $size $type</td><td class="center vtop">$attachments2~;
					}

					$attachments .= <<"EOT";
<table cellpadding="5" cellspacing="0" class="innerhtml">
 <tr>
  <td class="win" style="width: 400px">
   <table width="100%">
    <tr>
     <td class="vtop" style="width: 18px"><img src="$images/disk.png" alt="" /></td>
     <td>$downloads</td>
    </tr>
   </table>
  </td>
 </tr>$attachments3
</table><br />
EOT
					if($gattach && $username eq 'Guest') { last; }
				}
			}
		}

		if($modified ne '' && $maxmodifycount > 0) {
			@modified = split(/\>/,$modified);
			$total = @modified;
			$shown = '';
			if($total > $maxmodifycount) { $shown = "; $maxmodifycount $messagedisplay[52]"; }
			$extra = <<"EOT";
<tr><td><br /></td></tr><tr>
 <td>
  <div class="messageseps">
  <table cellpadding="0" cellspacing="1" class="border" width="100%">
   <tr>
    <td class="catbg smalltext" style="padding: 5px"><strong>$messagedisplay[48]</strong> ($total $messagedisplay[49]$shown)</td>
   </tr><tr>
    <td class="win" style="padding: 2px;">
     <table cellpadding="5" cellspacing="0" width="100%">
EOT
			$modifycount = 0;
			foreach(reverse @modified) {
				($mod4,$mod2,$modreason) = split(/\//,$_);
				if($modifycount == $maxmodifycount) { last; }
				$modate = get_date($mod4);
				GetMemberID($mod2);
				if($memberid{$mod2}{'sn'}) { $moduser = $userurl{$mod2}; }
				$moduser = $moduser || $mod2;
				$extra .= qq~<tr><td class="smalltext">$moduser &nbsp;-&nbsp; $modate</td></tr>~;
				if($modreason) { $extra .= qq~<tr><td class="win2 smalltext vtop" style="padding: 7px">$modreason</td></tr>~; }
				++$modifycount;
			}
			$extra .= qq~</table></td></tr></table></div></td></tr>~;
		}

		if($members{'Administrator',$username} || $ipon) { $ipaddr = qq~<a href="$scripturl/v-mod/a-ban/ip-$ipaddr/m-$messid/">$ipaddr</a>~; }
			else { $ipaddr = $messagedisplay[32]; }
		if($counter > 0) { $replycnt = qq~<strong>$gtxt{'37'}:</strong> <a href="#num$counter">$counter</a> - $maxreplies~; }

		$online = '';
		$usericon = 'user-offline';
		if($activemembers{$user} && !$memberid{$user}{'hideonline'}) { $online = $gtxt{'30'}; $usericon = 'user-online'; }
		elsif($logactive && !$memberid{$user}{'hideonline'} && $lastactive{$user}) { $online = qq~<a title="$messagedisplay[44]: $lastactive{$user}">$gtxt{'31'}</a>~; }
		if(!$guest) { $usericon = qq~<img src="$images/$usericon.png" class="centerimg" alt="" /> ~; }
			else { $usericon = ''; }

		if($guest && $members{'Administrator',$username}) { $email = qq~<a href="mailto:$email">$Pimg{'email'}</a>~; }
		elsif($guest) { $email = ''; }
			else { $email = $email{$user}; }
		$email .= $pmdisable || $guest ? '' : qq~<a href="$surl\lv-memberpanel/t-$user/a-pm/s-write/">$Pimg{'pm'}</a>~;

		$modify = !$mlocked && (($members{'Administrator',$username} || $ismod || $modifyon) || $username eq $user && (!$modifytime || $fdate+($modifytime*3600) > time)) ? qq~$Pmsp2<a href="javascript:clear('$counter')">$Pimg{'delete'}</a>$Pmsp2<a href="$surl\lv-post/b-$URL{'b'}/a-modify/m-$messid/n-$counter/" onmouseover="CreateMenus(this,25,'$counter'); outtimer = setTimeout('ClearMenu()',2000);">$Pimg{'modify'}</a>~ : '';

		$counter = 0 if($counter eq '');
		$quote = !$mlocked ? qq~<a href="$surl\lv-post/b-$URL{'b'}/m-$messid/q-$counter/" rel="nofollow">$Pimg{'quote'}</a>~ : '';

		$homepage = ($memberid{$user}{'sitename'} && $memberid{$user}{'siteurl'}) ? qq~<a href="$memberid{$user}{'siteurl'}" title="$memberid{$user}{'sitename'}"$blanktarget>$Pimg{'site'}</a>$Pmsp2~: '';
		$message = $message2;
		$ebout .= <<"EOT";
<tr>
 <td class="win center" style="padding: 5px;"><a id="num$counter"></a>$usericon<strong>$membername</strong></td>
 <td class="win">
  <table cellpadding="0" cellspacing="2" width="100%">
   <tr>
    <td class="smalltext didate">$date</td>
    <td class="right smalltext postmenu">$quote$modify$Pmsp2<a href="$surl\lv-report/b-$URL{'b'}/m-$messid/n-$counter/" rel="nofollow">$Pimg{'report'}</a></td>
   </tr>
  </table>
 </td>
</tr><tr>
 <td class="win2 smalltext vtop" style="padding: 0px; width: 180px;">$profile{$user}</td>
 <td class="win2 vtop" style="height: 100%">
  <table cellspacing="0" cellpadding="3" width="100%" style="height: 100%;">
   <tr>
    <td class="postbody vtop">$message$attachments</td>
   </tr>$signature{$user}$extra
  </table>
 </td>
</tr><tr>
 <td class="win3">
  <table width="100%">
   <tr>
    <td class="smalltext"><strong><img src="$images/ip.png" class="centerimg" alt="" /> $ipaddr</strong></td>
    <td class="right smalltext"><strong>$online</strong></td>
   </tr>
  </table>
 </td>
 <td class="win3">
  <table width="100%">
   <tr>
    <td class="smalltext postmenu">$homepage$email$instmsg{$user}</td>
    <td class="right smalltext">$replycnt</td>
   </tr>
  </table>
 </td>
</tr>
EOT
		$profile{$user} = '' if($guest); # Clear guest cache

		++$counter;
	}

	$GoBoards = ListBoards();

	if($members{'Administrator',$username} || $ismod) {
		$moderate = <<"EOT";
  <td><a href="javascript:clear('all')">$messagedisplay[76]</a> | <a href="$scripturl/v-mod/a-move/m-$messid/">$messagedisplay[69]</a>$stick | <a href="$scripturl/v-mod/a-lock/m-$messid/">$messagedisplay[70]</a> | <a href="$scripturl/v-mod/a-split/m-$messid/">$messagedisplay[71]</a> | <a href="$scripturl/v-mod/a-merge/m-$messid/">$messagedisplay[72]</a></td>
EOT
	}
	elsif($ston) { $moderate = $stick; }

	$ebout .= <<"EOT";
 <tr>
  <td class="catbg" colspan="3" style="padding: 8px;">
   <table cellpadding="0" cellspacing="0" width="100%">
    <tr>
	 <td class="pages">$totalpages $gtxt{'45'} $pagelinks</td>
	 <td class="right normaltext"><a href="$surl\lv-recommend/b-$URL{'b'}/m-$messid/" rel="nofollow">$messagedisplay[74]</a>$notify</td>
	</tr>
   </table>
  </td>
 </tr>
</table>
<table cellpadding="5" cellspacing="0" width="100%" style="margin-top: 5px;">
 <tr>
  <td colspan="3" class="right indexmenu">$print_reply</td>
 </tr>
</table>
<br />

<table cellpadding="0" cellspacing="1" class="border" width="100%">
 <tr>
  <td class="win">
  <div style="float: left; padding: 8px;"><img src="$images/crumbs.png" class="centerimg" alt="" /> <a href="$surl">$mbname</a> &nbsp;<strong>&rsaquo;</strong> &nbsp;<a href="$surl\lc-$catid/">$catname</a> &nbsp;<strong>&rsaquo;</strong> &nbsp;<a href="$surl\lb-$URL{'b'}/">$boardnm</a> &nbsp;<strong>&rsaquo; &nbsp;$title</strong></div>
  <div class="win2" style="float: right; padding: 8px;">$GoBoards</div>
  </td>
 </tr>
</table>
<br />
EOT
	if(($quickreply && $username ne 'Guest') && $repallow) {
		$time = time;
		$ghand = "this.style.cursor='hand';";

		$ebout .= <<"EOT";
<form action="$surl\lv-post/b-$URL{'b'}/m-$URL{'m'}/post-1/" id="post" method="post">
<table cellspacing="1" cellpadding="5" width="100%" class="border">
 <tr>
  <td class="titlebg"><img src="$images/replied.gif" class="centerimg" alt="" /> <strong>$messagedisplay[36]</strong></td>
 </tr><tr>
  <td class="win center" style="padding: 0px">
  <script src="$bdocsdir/bc.js" type="text/javascript"></script>
   <table cellpadding="5" cellspacing="0" width="100%">
EOT
		if($BCLoad && !$BCAdvanced) {
			$ebout .= <<"EOT";
    <tr>
     <td class="win2">
      <table cellpadding="1" cellspacing="0" class="innertable" id="postbar">
       <tr>
        <td><a href="#"><img src="$images/bold.gif" alt="$var{'10'}" onclick="use('[b]','[/b]'); return false;" /></a></td>
        <td><a href="#"><img src="$images/italics.gif" alt="$var{'11'}" onclick="use('[i]','[/i]'); return false;" /></a></td>
        <td><a href="#"><img src="$images/underline.gif" alt="$var{'12'}" onclick="use('[u]','[/u]'); return false;" /></a></td>
        <td><a href="#"><img src="$images/strike.gif" alt="$var{'17'}" onclick="use('[s]','[/s]'); return false;" /></a></td>
        <td><select style="width:75px;" name="face" onchange="AddNewValue('face',this.value); return false;"><option value="">$var{'8'}</option><option value="Arial">Arial</option><option value="Times">Times</option><option value="Courier">Courier</option><option value="Geneva">Geneva</option><option value="Sans-Serif">Sans-Serif</option><option value="Verdana">Verdana</option></select></td>
        <td><select style="width:75px;" name="size" onchange="AddNewValue('size',this.value); return false;"><option value="">$var{'9'}</option><option value="9">$var{'94'}</option><option value="14">$var{'95'}</option><option value="18">$var{'96'}</option></select></td>
        <td><select style="width:75px;" name="color" onchange="AddNewValue('color',this.value);"><option value="">$var{'30'}</option><option value="green" style="color:green">$var{'39'}</option><option value="blue" style="color:blue">$var{'37'}</option><option value="purple" style="color:purple">$var{'34'}</option><option value="orange" style="color:orange;">$var{'41'}</option><option value="yellow" style="color: yellow">$var{'40'}</option><option value="red" style="color:red">$var{'42'}</option><option value="black" style="color: black">$var{'33'}</option></select></td>
        <td><img src="$images/div.gif" alt="" /></td>
        <td><a href="#"><img src="$images/center.gif" alt="$var{'14'}" onclick="use('[center]','[/center]'); return false;" /></a></td>
        <td><a href="#"><img src="$images/right.gif" alt="$var{'15'}" onclick="use('[right]','[/right]'); return false;" /></a></td>
        <td><a href="#"><img src="$images/justify.gif" alt="$var{'16'}" onclick="use('[justify]','[/justify]'); return false;" /></a></td>
        <td><img src="$images/div.gif" alt="" /></td>
        <td><a href="#"><img src="$images/list.gif" alt="$var{'18'}" onclick="use('[list]\\n[*]','\\n[/list]'); return false;" /></a></td>
        <td><a href="#"><img src="$images/sub.gif" alt="$var{'19'}" onclick="use('[sub]','[/sub]'); return false;" /></a></td>
        <td><a href="#"><img src="$images/sup.gif" alt="$var{'20'}" onclick="use('[sup]','[/sup]'); return false;" /></a></td>
        <td><a href="#"><img src="$images/hr.gif" alt="$var{'25'}" onclick="use('[hr]'); return false;" /></a></td>
        <td><img src="$images/div.gif" alt="" /></td>
        <td><a href="#"><img src="$images/url.gif" alt="$var{'21'}" onclick="use('[url]','[/url]'); return false;" /></a></td>
        <td><a href="#"><img src="$images/email_click.gif" alt="$var{'22'}" onclick="use('[mail]','[/mail]'); return false;" /></a></td>
        <td><a href="#"><img src="$images/img.gif" alt="$var{'23'}" onclick="use('[img]','[/img]'); return false;" /></a></td>
        <td><img src="$images/div.gif" alt="" /></td>
        <td><a href="#"><img src="$images/code.gif" alt="$var{'87'}" onclick="use('[code]','[/code]'); return false;" /></a></td>
        <td><a href="#"><img src="$images/quote_click.gif" alt="$var{'24'}" onclick="use('[quote]','[/quote]'); return false;" /></a></td>
        <td><img src="$images/div.gif" alt="" /></td>
        <td><a href="#"><img src="$images/table.gif" alt="$var{'27'}" onclick="use('[table]\\n','[/table]'); return false;" /></a></td>
        <td><a href="#"><img src="$images/tr.gif" alt="$var{'28'}" onclick="use('[tr]\\n','[/tr]'); return false;" /></a></td>
        <td><a href="#"><img src="$images/td.gif" alt="$var{'29'}" onclick="use('[td]\\n','[/td]'); return false;" /></a></td>
       </tr>
      </table>
     </td>
    </tr>
EOT
		} elsif($BCAdvanced) {
			$ebout .= <<"EOT";
    <tr>
     <td class="win2">
      <table cellpadding="5" cellspacing="0" width="100%" class="innertable" id="postbar">
       <tr>
        <td class="smalltext"><strong><a href="#" onclick="tinyMCE.execCommand('mceToggleEditor',false,'message'); return false;">$messagedisplay[77]</a></strong> &nbsp; $messagedisplay[78]</td>
       </tr>
      </table>
     </td>
    </tr>
EOT
		}
		$ebout .= <<"EOT";
    <tr>
     <td style="padding: 0px">
	 <table cellpadding="8" cellspacing="0" class="innertable" width="100%">
	  <tr>
	   <td><textarea name="message" id="message" tabindex="1" rows="12" cols="95" style="width: 98%"></textarea></td>
	   <td class="win2 vtop" style="padding: 0px; width: 250px;">
EOT
		if($BCSmile && !$BCAdvanced) {
			$ebout .= <<"EOT";
         <table cellpadding="5" cellspacing="0" width="100%">
          <tr>
           <td colspan="8" class="smalltext"><strong>$messagedisplay[65]</strong></td>
          </tr><tr>
           <td><img src="$simages/smiley.png" alt="$var{'44'}" onclick="use(' :)');" onmouseover="$ghand" /></td>
           <td><img src="$simages/wink.png" alt="$var{'45'}" onclick="use(' ;)');" onmouseover="$ghand" /></td>
           <td><img src="$simages/tongue.png" alt="$var{'46'}" onclick="use(' :P');" onmouseover="$ghand" /></td>
          <td><img src="$simages/grin.png" alt="$var{'47'}" onclick="use(' ;D');" onmouseover="$ghand" /></td>
           <td><img src="$simages/sad.png" alt="$var{'48'}" onclick="use(' :(');" onmouseover="$ghand" /></td>
           <td><img src="$simages/angry.png" alt="$var{'49'}" onclick="use(' >:(');" onmouseover="$ghand" /></td>
           <td><img src="$simages/cry.png" alt="$var{'50'}" onclick="use(' :\\'(');" onmouseover="$ghand" /></td>
           <td><img src="$simages/lipsx.png" alt="$var{'51'}" onclick="use(' :X');" onmouseover="$ghand" /></td>
          </tr><tr>
           <td><img src="$simages/undecided.png" alt="$var{'52'}" onclick="use(' :-/');" onmouseover="$ghand" /></td>
           <td><img src="$simages/shock.png" alt="$var{'53'}" onclick="use(' :o');" onmouseover="$ghand" /></td>
           <td><img src="$simages/blush.png" alt="$var{'54'}" onclick="use(' :B');" onmouseover="$ghand" /></td>
           <td><img src="$simages/cool.png" alt="$var{'55'}" onclick="use(' 8)');" onmouseover="$ghand" /></td>
           <td><img src="$simages/kiss.png" alt="$var{'56'}" onclick="use(' :K)');" onmouseover="$ghand" /></td>
           <td><img src="$simages/lol.png" alt="$var{'57'}" onclick="use(' :D');" onmouseover="$ghand" /></td>
           <td><img src="$simages/roll.png" alt="$var{'58'}" onclick="use(' ::)');" onmouseover="$ghand" /></td>
           <td><img src="$simages/huh.png" alt="$var{'59'}" onclick="use(' ??)');" onmouseover="$ghand" /></td>
          </tr><tr>
           <td colspan="8" class="center win3 smalltext"><a href="$surl\lv-post/a-smilies/" onclick="window.open('$surl\lv-post/a-smilies/','smiles','height=400,width=750,resizable=yes,scrollbars=yes'); target='smilies'; return false;">$messagedisplay[67]</a></td>
          </tr>
         </table>
EOT
		}

		if($BCAdvanced) {
			$ebout .= <<"EOT";
		<table cellpadding="5" cellspacing="0" width="100%">
		 <tr>
		  <td colspan="8" class="smalltext"><strong>$posttxt[34]</strong></td>
		 </tr><tr$onload>
		  <td><img src="$simages/smiley.png" alt="$var{'44'}" onclick="useAE('$simages/smiley.png');" onmouseover="$ghand" /></td>
		  <td><img src="$simages/wink.png" alt="$var{'45'}" onclick="useAE('$simages/wink.png');" onmouseover="$ghand" /></td>
		  <td><img src="$simages/tongue.png" alt="$var{'46'}" onclick="useAE('$simages/tongue.png');" onmouseover="$ghand" /></td>
		  <td><img src="$simages/grin.png" alt="$var{'47'}" onclick="useAE('$simages/grin.png');" onmouseover="$ghand" /></td>
		  <td><img src="$simages/sad.png" alt="$var{'48'}" onclick="useAE('$simages/sad.png');" onmouseover="$ghand" /></td>
		  <td><img src="$simages/angry.png" alt="$var{'49'}" onclick="useAE('$simages/angry.png');" onmouseover="$ghand" /></td>
		  <td><img src="$simages/cry.png" alt="$var{'50'}" onclick="useAE('$simages/cry.png');" onmouseover="$ghand" /></td>
		  <td><img src="$simages/lipsx.png" alt="$var{'51'}" onclick="useAE('$simages/lipsx.png');" onmouseover="$ghand" /></td>
		 </tr><tr$onload>
		  <td><img src="$simages/undecided.png" alt="$var{'52'}" onclick="useAE('$simages/undecided.png');" onmouseover="$ghand" /></td>
		  <td><img src="$simages/shock.png" alt="$var{'53'}" onclick="useAE('$simages/shock.png');" onmouseover="$ghand" /></td>
		  <td><img src="$simages/blush.png" alt="$var{'54'}" onclick="useAE('$simages/blush.png');" onmouseover="$ghand" /></td>
		  <td><img src="$simages/cool.png" alt="$var{'55'}" onclick="useAE('$simages/cool.png');" onmouseover="$ghand" /></td>
		  <td><img src="$simages/kiss.png" alt="$var{'56'}" onclick="useAE('$simages/kiss.png');" onmouseover="$ghand" /></td>
		  <td><img src="$simages/lol.png" alt="$var{'57'}" onclick="useAE('$simages/lol.png');" onmouseover="$ghand" /></td>
		  <td><img src="$simages/roll.png" alt="$var{'58'}" onclick="useAE('$simages/roll.png');" onmouseover="$ghand" /></td>
		  <td><img src="$simages/huh.png" alt="$var{'59'}" onclick="useAE('$simages/huh.png');" onmouseover="$ghand" /></td>
		 </tr>
		</table>
		<script language="javascript" type="text/javascript" src="$bdocsdir/tiny_mce/tiny_mce.js"></script>
		<script language="javascript" type="text/javascript">
		//<![CDATA[
		tinyMCE.init({
			theme : "advanced",
			mode : "exact",
			elements : "message",
			plugins : "bbcode,inlinepopups",
			theme_advanced_buttons1 : "bold,italic,underline,strikethrough,|,undo,redo,justifyleft,justifycenter,justifyright,justifyfull,|,bullist,sub,sup,hr,|,link,unlink,image,|,removeformat,code",
			theme_advanced_buttons2 : "fontselect,fontsizeselect,forecolor",
			theme_advanced_buttons3 : "",
			theme_advanced_toolbar_location : "top",
			theme_advanced_toolbar_align : "left",
			entity_encoding : "raw",
			add_unload_trigger : false,
			remove_linebreaks : false,
			convert_fonts_to_spans : false,
			smileyurl : "$simages",
			invalid_elements : "span",
			height : "250",
			relative_urls : false,
			convert_urls : false
		});
		//]]>
		</script>
EOT
		}

		$ebout .= <<"EOT";
        </td>
	  </tr>
	 </table>
	</td>
    </tr>
   </table>
  </td>
 </tr><tr>
  <td class="win2 center"><input type="hidden" name="quick" value="1" /><input type="hidden" name="viewtimer" value="$time" /><input type="hidden" name="xout" value="1" /><input type="submit" tabindex="2" value=" $messagedisplay[37] " name="submit" />&nbsp; <input type="submit" tabindex="3" name="preview" value=" $messagedisplay[38] " /></td>
 </tr>
</table>
</form><br />
EOT
	}

	if($allowrate) {
		fopen(FILE,"$messages/$messid.rate");
		while(<FILE>) {
			chomp;
			if($rcnt == 0) { $rate = $_; $rcnt = 1; }
				else { ++$ratecnt; $rated{$_} = 1; }
		}
		fclose(FILE);
		if($rate) { $rate = qq~<img src="$images/$rate\star.gif" alt="" /><br />$messagedisplay[30] <strong>$ratecnt</strong> $messagedisplay[35]~; }
			else { $rate = "<i>$messagedisplay[33]</i>"; }

		$ebout .= <<"EOT";
<table cellpadding="4" cellspacing="1" class="border innertable" width="300">
 <tr>
  <td class="catbg smalltext center"><strong>$messagedisplay[34]</strong></td>
 </tr><tr>
  <td class="win smalltext center">$rate</td>
 </tr>
EOT
		if(!$rated{$username}) {
			$ebout .= <<"EOT";
 <tr>
  <td class="win2">
   <form action="$scripturl/v-ppoll/a-vote/m-$URL{'m'}/s-$tstart/e-rate/" method="post">
    <table width="100%">
     <tr>
      <td style="width: 50%" class="center"><select name="rate">
       <option value="" selected="selected">$messagedisplay[25]</option>
       <option value="5">5 - $messagedisplay[26]</option>
       <option value="4">4</option>
       <option value="3">3 - $messagedisplay[27]</option>
       <option value="2">2</option>
       <option value="1">1 - $messagedisplay[28]</option>
      </select> &nbsp; <input type="submit" value="$messagedisplay[24]" /></td>
     </tr>
    </table>
   </form>
  </td>
 </tr>
EOT
		}
		$ebout .= "</table><br />";
	}

	if($tagsenable && $tags[0] ne '') {
		$ebout .= <<"EOT";
<table cellpadding="5" cellspacing="1" class="border" width="100%">
 <tr>
  <td class="titlebg"><strong><img src="$images/tag.png" alt="" class="centerimg" /> $messagedisplay[80]</strong></td>
 </tr><tr>
  <td class="win" style="padding: 0">
   <div style="padding: 8px">
EOT
		foreach(split(/, ?/,$tags[0])) {
			$enc = urlencode($_);
			$enc =~ s/\%20/\+/g;
			$enc =~ s/\%2D/\*/g;
			$tag = CensorList($_);
			$ebout .= qq~<a href="$surl\lv-tags/find-$enc/">$tag</a>, &nbsp;~;
		}
		$ebout =~ s/, &nbsp;\Z//g;

		$ebout .= <<"EOT";
   </div>
   <div class="win3 smalltext" style="padding: 8px"><a href="$surl\lv-tags/">$messagedisplay[79]</a></div>
  </td>
 </tr>
</table><br />
EOT
	}

	if($moderate) {
		if($members{'Administrator',$username}) { $modlist = qq~<tr><td class="center win3"><a href="$scripturl/v-mod/a-modlog/m-$URL{'m'}/">$messagedisplay[50]</a></td></tr>~; }
		$ebout .= <<"EOT";
<table cellpadding="0" cellspacing="1" class="border">
 <tr>
  <td class="win">
   <table cellpadding="8" cellspacing="0">
   <tr>
    <td class="titlebg">$messagedisplay[75]</td>
   </tr><tr>$moderate</tr>$modlist
   </table>
  </td>
 </tr>
</table>
EOT
	}
	footer();
	exit;
}
1;
