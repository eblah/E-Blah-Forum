#############################################
# E-Blah Bulletin Board Systems        2008 #
#############################################
# Copyright (c) 2001 - 2008 E-Blah.         #
#############################################

CoreLoad('MessageIndex',1);

sub MessageIndex {
	$boardurl = $URL{'b'};
	error($ltxt[5]) if($boardurl eq '');

	# How many page links?
	$tmax = $totalpp*20;
	$startdot = ($totalpp*2)/5;

	fopen(FILE,"$boards/Stick.txt");
	while(<FILE>) {
		chomp;
		($sb,$sid) = split(/\|/,$_);
		$stickme{$sid} = 1 if($sb eq $URL{'b'});
	}
	fclose(FILE);

	BoardProperties();

	fopen(ULOG,"$members/$username.log");
	while(<ULOG>) {
		chomp;
		($lid,$ltime) = split(/\|/,$_);
		$logged{$lid} = $ltime;
	}
	fclose(ULOG);

	fopen(FILE,"$boards/$boardurl.msg");
	while( $mlata = <FILE> ) {
		chomp $mlata;

		($del,$t,$t,$t,$t,$t,$t,$t,$date) = split(/\|/,$mlata);

		if($logged{$del} > $date || $logged{"AllRead_$URL{'b'}"} > $date) { next if $URL{'n'}; }
			else { $boardnew = 1; }

		if($stickme{$del}) { push(@mlata3,$mlata); }
			else { push(@mlata2,$mlata); }
	}
	fclose(FILE);

	unshift(@mlata2,@mlata3);
	$maxm = @mlata2-1 || 1; # Come up with brd cnt
	LogPage($boardnew);

	$treplies = $maxm < 0 ? 1 : $maxm;
	if($treplies <= $maxdis) {
		$pagelinks = "<strong>1</strong>";
		$totalpages = 1;
		$URL{'s'} = 0;
	} else {
		$totalpages = int(($treplies/$maxdis)+.99);

		$tstart = $URL{'s'} || 0;
		$counter = 1;
		$linknewtwo = "/n-$URL{'n'}" if($URL{'n'});
		$link = "$scripturl\ls";
		if($tstart > $treplies) { $tstart = $treplies; }
		$tstart = (int($tstart/$maxdis)*$maxdis);
		if($tstart > 0) { $bk = ($tstart-$maxdis); $pagelinks = qq~<a href="$link-$bk/">&#171;</a> ~; }
		if($treplies > ($tmax/2) && $tstart > $maxdis*($startdot+1) && $treplies > $tmax) { $pagelinks .= qq~<a href="$link-0/">...</a> ~; }
		for($i = 0; $i < $treplies+1; $i += $maxdis) {
			if($i < $bk-($maxdis*$startdot) && $treplies > $tmax) { ++$counter; $final = $counter-1; next; }
			if($URL{'s'} ne 'all' && $i == $tstart || $treplies < $maxdis) { $pagelinks .= qq~<strong>$counter</strong> ~; $nxt = ($tstart+$maxdis); }
				else { $pagelinks .= qq~<a href="$link-$i/">$counter</a> ~; }
			++$counter;
			if($counter > $totalpp+$final && $treplies > $tmax) { $gbk = (int($treplies/$maxdis)*$maxdis); $pagelinks .= qq~ <a href="$link-$gbk/">...</a> ~; ++$i; last; }
		}
		if(($tstart+$maxdis) != $i && $URL{'s'} ne 'all') { $pagelinks .= qq~ <a href="$link-$nxt/">&#187;</a>~; }
		if($treplies > $maxdis && !$sall) { $pagelinks .= $URL{'s'} ne 'all' ? qq~ <a href="$link-all/">$messageindex[1]</a>~ : qq~ <strong>$messageindex[1]</strong>~; }
	}

	if($username ne 'Guest') { $maread = qq~<a href="$scripturl\lv-mark/l-bdis/">$messageindex[45]</a>~; }
	$title = $boardnm;
	header();
	Mods();
	if($modz) { $modz = "<strong>$ltxt[7]:</strong> $modz"; }

	$ratewid = 6;
	if($members{'Administrator',$username} || $ismod) { ++$ratewid; }

	$ebout .= <<"EOT";
<script type="text/javascript">
//<![CDATA[
function checkAll() {
 shortname = document.forms['messageindex'];
 if(shortname.checkall.checked) { cvalue = true; } else { cvalue = false; }
 for(i = 0; i < shortname.elements.length; i++) {
  if(shortname.elements[i].name == 'opt1') { return; }
  shortname.elements[i].checked = cvalue;
 }
}
//]]>
</script>

<table cellpadding="1" cellspacing="1" width="100%" class="border">
 <tr>
  <td class="win">
   <table cellpadding="6" cellspacing="0" width="100%">
    <tr>
     <td><img src="$images/crumbs.png" class="centerimg" alt="" /> <a href="$surl">$mbname</a> &nbsp;<strong>&rsaquo;</strong> &nbsp;<a href="$surl\lc-$catid/">$catname</a> &nbsp;<strong>&rsaquo; &nbsp;$boardnm</strong></td>
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
	$ebout .= <<"EOT";
</table><br />
EOT
	if($showdes && $binfo[0] ne '') {
		if($binfo[13]) {
			$binfo[13] =~ s/\|/\//g;
			$binfo[13] = $binfo[13] =~ /http:\/\// ? $binfo[13] : "$images/$binfo[13]";
			$binfo[13] = qq~<img src="$binfo[13]" style="vertical-align: middle;" alt="" /> ~;
		}

		$message = $binfo[0];
		$message =~ s/&#47;/\//gsi;
		$message = BC($message);
		$ebout .= <<"EOT";
<table cellpadding="8" cellspacing="1" class="border" width="100%">
 <tr>
  <td class="win">$binfo[13] $message</td>
 </tr>
</table><br />
EOT
	}

	if($members{'Administrator',$username} || $ismod) { $ebout .= qq~<form action="$surl\lb-$URL{'b'}/v-mod/a-mindex/" id="messageindex" method="post">~; $endform = qq~</form>~; }

	$stata = !$tallow || !$repallow ? 'thread_locked' : 'thread';
	if($tallow) { $allowposts = qq~<a href="$surl\lv-post/b-$URL{'b'}/" rel="nofollow">$Iimg{'newthread'}</a>$spoll~; }

	if($username ne 'Guest' && !$nonotify) { $notify .= qq~ | <a href="$surl\lv-memberpanel/a-notify/m-brd/b-$URL{'b'}/">$messageindex[46]</a>~; }

	$ebout .= <<"EOT";
<table cellpadding="0" cellspacing="0" width="100%" style="margin-bottom: 5px;">
 <tr>
  <td class="indextitle">$boardnm</td>
  <td class="right indexmenu">$allowposts</td>
 </tr>
</table>
<table cellpadding="5" cellspacing="1" class="border" width="100%">
 <tr>
  <td class="catbg" colspan="$ratewid" style="padding: 8px">
   <table cellpadding="0" cellspacing="0" width="100%">
    <tr>
     <td class="pages">$totalpages $gtxt{'45'} $pagelinks</td>
     <td class="right normaltext">$maread$notify</td>
    </tr>
   </table>
  </td>
 </tr><tr>
  <td class="titlebg center"><div style="padding: 2px;"><a href="$surl\lv-shownews/a-feed/b-$URL{'b'}/"><img src="$images/feed.png" alt="" /></a></div></td>
  <td class="titlebg smalltext" style="width: 40%"><strong>$messageindex[9]</strong></td>
  <td class="titlebg smalltext center" style="width: 8%"><strong>$gtxt{'38'}</strong></td>
  <td class="titlebg smalltext center" style="width: 15%"><strong>$gtxt{'36'}</strong></td>
  <td class="titlebg smalltext center" style="width: 8%"><strong>$messageindex[11]</strong></td>
  <td class="titlebg smalltext center" style="width: 25%"><strong>$messageindex[12]</strong></td>
EOT

	if($members{'Administrator',$username} || $ismod) { $ebout .= qq~<td class="titlebg smalltext center" style="padding: 5px;"><strong>$messageindex[34]</strong></td>~; }

	$ebout .= '</tr>';

	$end = $URL{'s'} eq 'all' ? $maxm : $tstart+$maxdis;

	$messageurl = $surl;

	for($h = 0; $h < @mlata2; $h++) {
		if($h >= $tstart && $h < $end) { ($messid,$messtitle,$posted,$date,$replies,$poll,$type,$micon,$date,$lastuser) = split(/\|/,$mlata2[$h]); }
		elsif($h >= $tstart) { last; }
			else { next; }

		fopen(FILE,"$messages/$messid.view");
		$pviews = MakeComma(<FILE>) || 0;
		fclose(FILE);

		$statuscng = 0;
		$status = FindStatus($date);
		if(!$stuck && $stickme{$messid}) {
			$statuscng = $messageindex[24];
			$sticksicon = qq~<img src="$images/stuck.png" style="float: right; padding-right: 10px;" alt="$messageindex[26]" />~;
			$sticks = "<strong>$messageindex[26]:</strong> ";
			$stuck = 1;
		}
		if($stuck && !$stickme{$messid}) {
			$statuscng = $messageindex[25];
			$sticks = $sticksicon = '';
			$stuck = 0;
		}

		if($statuscng) {
			$ebout .= <<"EOT";
 <tr>
  <td class="win5 smalltext" colspan="$ratewid"><strong>$statuscng</strong></td>
 </tr>
EOT
		}

		$poll = !$sticks && ($status eq 'poll_icon' || $status eq 'poll_lock') ? "<strong>$var{'67'}:</strong> " : '';

		if($username ne 'Guest') {
			$new = '';
			$notifys = '';
			$yay = 0;
			$tempurl = '';
			if(($logged{$messid}-$date) <= 0 && ($logged{"AllRead_$URL{'b'}"}-$date) <= 0) { $new = qq~<div style="font-weight: bold; float: left;"><img src="$images/new.png" alt="$messageindex[28]" style="margin: 0 3px 0 3px;" /> ~; $tempurl = "s-new/"; }
				else { $new = qq~<div style="float: left">~; }

			if(NotifyAddStatus($messid,2)) { $notifys = qq~<img src="$images/notify_index.png" style="float: right; padding-right: 10px;" alt="$messageindex[13]" />~; }
		} else { $new = qq~<div style="float: left">~; }

		GetMemberID($posted);
		$threadstart = $memberid{$posted}{'sn'} ne '' ? $userurl{$posted} : FindOldMemberName($posted) || $var{'60'};
		GetMemberID($lastuser);
		$lastuser = $memberid{$lastuser}{'sn'} ne '' ? $userurl{$lastuser} : FindOldMemberName($lastuser) || $var{'60'};

		$messlinks = '';
		if($replies > 20000) { $replies = 50; }

		if($maxmess-1 < $replies) {
			$max = $replies+1;
			$pcnt = 0;
			$messlinks = qq~<div style="clear: both"></div><div style="padding-top: 5px; float:left;">$gtxt{'17'}: ~;

			$beforeafter = int($totalpp/2);
			$counter = int(($max/$maxmess)+2) - $beforeafter;

			for($cnt = 0; $cnt < $max; $cnt += $maxmess) {
				++$pcnt;
				if(int($max/$maxmess) > $totalpp && $pcnt == $beforeafter+1) { $messlinks =~ s/, \Z/ /; $messlinks .= "... "; }
				if($pcnt > $beforeafter && $pcnt < $counter) { next; }
				$messlinks .= qq~<a href="$messageurl\lm-$messid/s-$cnt/">$pcnt</a>, ~;
			}

			$messlinks =~ s/, \Z/ /;
			if(!$sall) { $messlinks .= qq~ : <a href="$messageurl\lm-$messid/s-all/">$messageindex[1]</a>~; }
			$messlinks .= '</div>';
		}

		$replies = MakeComma($replies);

		$date = get_date($date);
		$startdate = get_date($messid,1);
		$messtitle = CensorList($messtitle);

		$icon = '';
		if($micon ne 'xx.gif' && $micon ne 'xx.png') { $icon = qq~<td style="width: 20px" class="center"><img src="$images/icons/$micon" alt="" />&nbsp;</td>~; }

		$rate = '';
		if($allowrate && -e("$messages/$messid.rate")) {
			$rcnt = 0;
			$ratecnt = 0;
			fopen(FILE,"$messages/$messid.rate");
			while(<FILE>) {
				chomp $_;
				if($rcnt == 0) { $rate = $_; $rcnt = 1; }
					else { ++$ratecnt; }
			}
			fclose(FILE);
			if($rate) { $rate = qq~<img src="$images/$rate\star.gif" alt="$ratecnt $messageindex[20]" />~; }
			$rate = qq~<div style="float: right; padding-right: 10px;">$rate</div>~;
		}

		($movedid,$movedsubject) = split("<>",$messtitle);
		if($movedsubject) { $status = 'moved'; }

		$tags = '';
		if(-e("$messages/$messid.tags")) {
			fopen(TAGS,"$messages/$messid.tags");
			@tags = <TAGS>;
			fclose(TAGS);
			chomp @tags;

			$tags[0] = CensorList($tags[0]);

			if($tags[0] ne '') { $tags = qq~<img src="$images/tags.png" style="float: right; padding-right: 10px;" alt="$tags[0]" />~; }
		}

		$ebout .= <<"EOT";
<tr>
 <td class="win3 center"><div style="padding: 11px;"><img src="$images/$status.png" alt="" /></div></td>
EOT
		if($movedsubject) {
			$ebout .= <<"EOT";
 <td class="win"><strong>$messageindex[39]:</strong> <a href="$surl\lm-$movedid/">$movedsubject</a></td>
 <td class="win2 center smalltext" colspan="3"><i>$messageindex[38]</i></td>
EOT
		} else {
			$ebout .= <<"EOT";
 <td class="win">$new$sticks$poll<a href="$messageurl\lm-$messid/$tempurl" title="$messageindex[15]: $startdate">$messtitle</a></div><div style="float: right">$sticksicon$tags$notifys</div>$messlinks$rate</td>
 <td class="win2 smalltext center" style="width: 8%">$replies</td>
 <td class="win smalltext center" style="width: 15%">$threadstart</td>
 <td class="win2 smalltext center" style="width: 8%">$pviews</td>
EOT
		}
		$ebout .= <<"EOT";
 <td class="win" style="width: 25%">
  <table width="100%">
   <tr>
    <td class="smalltext">
     <div class="milastaction">$messageindex[16] $lastuser</div><div class="midate">$date</div>
    </td>$icon
   </tr>
  </table>
 </td>
EOT
		if($members{'Administrator',$username} || $ismod) { ++$scounter; $ebout .= qq~<td class="win3 center" style="width: 5%"><input type="checkbox" name="$scounter" value="$messid" /></td>~; }
		$ebout .= "</tr>";
	}
	if(!$lastuser) {
		if($URL{'n'}) { $messageindex[17] = $messageindex[23]; }
		$ebout .= <<"EOT";
<tr>
 <td class="win center" colspan="$ratewid"><br />$messageindex[17]<br /><br /></td>
</tr>
EOT
	}
	$GoBoards = ListBoards();
	if($allowposts eq '' && $maread eq '') { $lck = qq~<img src="$images/thread_locked.png" alt="" /> $messageindex[36]~; }

	if($members{'Administrator',$username} || $ismod) {
		if($sessionEnabled && (!$session->param('admin_login') || $session->param('adminverify') ne $memberid{$username}{'adminverify'})) {
			$ebout .= <<"EOT";
<tr>
 <td class="catbg smalltext right" colspan="$ratewid"><a href="$surl\lv-admin/a-verify/">$messageindex[47]</a></td>
</tr>
EOT
		} else {
			%arshown = ();
			$cats = '';
	
			foreach(@catbase) {
				($t,$boardid,$memgrps,$t,$t,$subcats) = split(/\|/,$_);
				$catbase{$boardid} = $_;
				foreach(split(/\//,$subcats)) { $noshow{$_} = 1; }
		
				$cats .= "$boardid/";
			}
		
			foreach(@boardbase) {
				($id,$t,$t,$t,$t,$t,$t,$passed,$t,$t,$boardgood,$t,$t,$redir) = split("/",$_);
				$board{$id} = $_;
			}
		
			$temp = '';
			SubCatsList($cats,1);
			$ops = $temp;
	
			if($ops ne '') { $move = qq~&nbsp; <input type="checkbox" value="1" name="opt4" /> $messageindex[29]: <select name="b">$ops</select>~; }
			$ratewid2 = $ratewid-1;
			$ebout .= <<"EOT";
<tr>
 <td class="catbg smalltext right" colspan="$ratewid2"><strong><input type="checkbox" value="1" name="opt1" /> $messageindex[30] &nbsp; <input type="checkbox" value="1" name="opt2" /> $messageindex[31] &nbsp; <input type="checkbox" value="1" name="opt3" /> $messageindex[32] $move&nbsp;</strong> <input type="submit" value="$messageindex[33]" /></td>
 <td class="catbg center"><input type="checkbox" name="checkall" onclick="checkAll();" /></td>
</tr>
EOT
		}
	}

	$loggedinq = $username ne 'Guest' ? qq~<div class="win2" style="float: right; padding: 7px;"><strong>$messageindex[41]:</strong> <a href="$scripturl\ln-1/">$messageindex[42]</a> | <a href="$scripturl">$messageindex[43]</a> | <a href="$surl\lv-search/p-newposts/">$messageindex[44]</a></div>~ : '';

	$ebout .= <<"EOT";
 <tr>
  <td class="catbg" colspan="$ratewid" style="padding: 8px">
   <table cellpadding="0" cellspacing="0" width="100%">
    <tr>
     <td class="pages">$totalpages $gtxt{'45'} $pagelinks</td>
     <td class="right normaltext">$maread$notify</td>
    </tr>
   </table>
  </td>
 </tr>
</table>
<table cellpadding="0" cellspacing="0" width="100%" style="margin-top: 5px;">
 <tr>
  <td class="right indexmenu">$allowposts</td>
 </tr>
</table>
$endform
<br />

<div style="padding: 1px;" class="border">
 <table cellpadding="0" cellspacing="0" class="win" width="100%">
  <tr>
   <td style="padding: 7px"><img src="$images/crumbs.png" class="centerimg" alt="" /> <a href="$surl">$mbname</a> &nbsp;<strong>&rsaquo;</strong> &nbsp;<a href="$surl\lc-$catid/">$catname</a> &nbsp;<strong>&rsaquo; &nbsp;$boardnm</strong></td>
   <td>$loggedinq</td>
  </tr>
 </table>
</div>
<br />

<table cellpadding="6" cellspacing="1" style="float: left; margin: 0px;">
 <tr>
  <td class="center" style="width: 15px"><img src="$images/thread.png" alt="" /></td>
  <td class="smalltext">$var{'61'}</td>
  <td class="center" style="width: 15px"><img src="$images/thread_locked.png" alt="" /></td>
  <td class="smalltext">$var{'62'}</td>
  <td class="center" style="width: 15px"><img src="$images/hotthread.png" alt="" /></td>
  <td class="smalltext">$var{'63'} ($htdmax+)</td>
 </tr><tr>
  <td class="center"><img src="$images/veryhotthread.png" alt="" /></td>
  <td class="smalltext">$var{'64'} ($vhtdmax+)</td>
  <td class="center"><img src="$images/poll_icon.png" alt="" /></td>
  <td class="smalltext">$var{'67'}</td>
  <td class="center"><img src="$images/poll_lock.png" alt="" /></td>
  <td class="smalltext">$var{'69'}</td>
 </tr><tr>
  <td class="center"><img src="$images/archive_lock.png" alt="" /></td>
  <td colspan="5" class="smalltext">$messageindex[40]</td>
 </tr>
</table>

<form action="$surl\lv-search/b-$URL{'b'}/p-bs/" method="post">
<table cellpadding="4" cellspacing="1" width="400" style="float: right; margin: 0px;">
 <tr>
  <td class="right"><input type="hidden" name="searchboards" value="$URL{'b'}" /><input type="text" name="searchstring" class="textinput boardsearch" value="$messageindex[37]" onfocus="if(this.value == '$messageindex[37]') { this.value=''; }" size="30" /></td>
 </tr><tr>
  <td class="right">$GoBoards</td>
 </tr>
</table>
</form>
<div style="clear: both"></div>
EOT
	footer();
	exit;
}
1;