#############################################
# E-Blah Bulletin Board Systems        2008 #
#############################################
# Copyright (c) 2001 - 2008 E-Blah.         #
#############################################

CoreLoad('BoardIndex',1);

sub Glimpse { # Taken from latest threads in Portal
	my($lastthread,$tmpcnt, $posted_sn);
	$tmpcnt = $glimpsecnt+1;

	if($URL{'a'} eq 'feed') {
		print "Content-type: text/xml\n\n";

		print <<"EOT";
<?xml version="1.0" encoding="$char"?>
<rss version="2.0" xmlns:dc="http://purl.org/dc/elements/1.1/">
 <channel>
  <title>$boardindex[104] - $mbname</title>
  <link>$rurl</link>
  <generator>http://www.eblah.com</generator>
  <description></description>
  <language>en</language>
EOT
	} else {
		$lastthread .= <<"EOT";
<table class="border" cellpadding="5" cellspacing="1" width="100%">
 <tr>
  <td class="titlebg" colspan="4"><strong><a href="$surl\la-feed/"><img src="$images/feed.png" alt="" class="centerimg" /></a> $boardindex[104]</strong></td>
 </tr><tr>
  <td class="catbg smalltext" colspan="2"><strong>$boardindex[3]</strong></td>
  <td class="catbg smalltext" colspan="2"><strong>$boardindex[3]</strong></td>
 </tr><tr>
EOT
	}

	VerifyBoard();

	foreach $use (@boardbase) {
		($board,$t,$t,$t,$t,$t,$t,$pass) = split('/',$use);
		if(!$boardallow{$board}) { next; }
		fopen(FILE,"$boards/$board.msg");
		$counts = 0;
		while(<FILE>) {
			chomp $_;
			($id,$title,$posted,$date,$replies,$poll,$type,$micon,$date,$lastuser) = split(/\|/,$_);

			($xt1,$xt2) = split("<>",$title);
			if($xt2 ne '') { next; }

			push(@data,"$date|$id|$title|$posted|$replies|$poll|$type|$micon|$lastuser|$board");
			++$counts;
			if($counts > 21) { last; }
		}
		fclose(FILE);
	}

	$counter = 1;
	$counter3 = 0;

	foreach(sort{$b <=> $a} @data) {
		if($counter == ($glimpsecnt*2)+1) { last; }
		($date,$id,$title,$posted,$replies,$poll,$type,$micon,$lastuser,$board) = split(/\|/,$_);
		if($username ne 'Guest') {
			$new = '';
			$isnew = 0;
			foreach $logged (@log) {
				($mbah,$lmtime) = split(/\|/,$logged);
				if($mbah eq "AllRead_$board" || $mbah eq $id) {
					$isnew = $lmtime-$date;
					last;
				}
			}
			if($isnew <= 0) { $new = qq~<strong><img src="$images/new.png" style="margin: 0 3px 0 3px;" alt="" /> ~; $newend = "</strong>"; $snew = 's-new/'; }
				else { $snew = $newend = ''; }
		}

		$status = FindStatus;
		GetMemberID($posted);
		$posted_sn = $memberid{$posted}{'sn'} ne '' ? $memberid{$posted}{'sn'} : FindOldMemberName($posted);
		if($lastuser eq '') {
			$lastuser = $posted;
		} else {
			GetMemberID($lastuser);
		}
		$lastuser = $memberid{$lastuser}{'sn'} ne '' ? $userurl{$lastuser} : FindOldMemberName($lastuser);
		$title = CensorList($title);
		$date = get_date($date);

		if($counter3 == 2) {
			$lastthread .= " </tr><tr>\n";
			$counter3 = 0;
		}

		if($URL{'a'} eq 'feed') {
			($s,$m,$h,$day,$month,$year,$wday) = localtime($id);
			$year += 1900;
			++$month;
			if($h < 10) { $h = "0$h"; }
			if($m < 10) { $m = "0$m"; }
			if($s < 10) { $s = "0$s"; }

			print <<"EOT";
  <item>
   <title>$title</title>
   <link>$rurl\lm-$id/$snew</link>
   <comments>$rurl\lm-$id/#num1</comments>
   <pubDate>$sdays[$wday], $day $smonths[$month-1] $year $h:$m:$s</pubDate>
   <dc:creator>$posted</dc:creator>
  </item>
EOT
		} else {
			$board_name = '';
			foreach (@boardbase) {
				($bid,$t,$t,$board_name) = split("/",$_);
				if($bid eq $board) {
					last;
				} 
			}

			$lastthread .= <<"EOT";
  <td class="win center" style="vertical-align: top;"><div style="padding: 11px; padding-top: 4px;"><img src="$images/$status.png" alt="" /></div></td>
  <td class="win2" style="width: 50%">$new<a href="$surl\lm-$id/$snew" title="$gtxt{'19'} $posted_sn">$title</a>$newend<div class="smalltext">$gtxt{'46'} $lastuser<div class="bidate">$date $boardindex[105] <a href="$surl\lb-$board" title="$board_name">$board_name</a></div></div></td>
EOT
		}
		++$counter;
		++$counter3;
	}

	if($URL{'a'} eq 'feed') {
		print " </channel>\n</rss>";
		exit;
	}

	$lastthread .= "</tr></table><br />";
	return($lastthread);
}

sub LoadIndex {
	my($moderate,$postsandtops,$group);
	if($URL{'a'} eq 'tog') { Tog(); }
	if($glimpsecnt > 0 && $URL{'a'} eq 'feed') { Glimpse(); }

	$gdisable = 1;
	$title = $mbname;
	header();
	foreach (@catbase) {
		($nme,$id) = split(/\|/,$_);
		if($id eq $URL{'c'}) { $catid = $id; $catname = $nme; last; }
	}
	if($URL{'c'} ne '') { $dirlist = qq~<a href="$surl">$mbname</a> &nbsp;<strong>&rsaquo; &nbsp;$catname</strong>~; }
		else { $dirlist = "<strong>$mbname</strong>"; }

	if($username ne 'Guest' && $memberid{$username}{'sn'} ne '') {
		$newpostslv = qq~ &nbsp; - &nbsp; <a href="$surl\lv-search/p-newposts/">$boardindex[97]</a>~;
		if($memberid{$username}{'lastvisit'} ne '') {
			$newpostslv .= qq~ &nbsp; - &nbsp; <a href="$surl\lv-search/p-newposts/a-lastvisit/">$boardindex[103]</a>~;
		}
	}

	$ebout .= <<"EOT";
<table cellpadding="1" cellspacing="1" width="100%" class="border">
 <tr>
  <td class="win" style="padding: 0px;">
   <table cellpadding="0" cellspacing="0" width="100%">
    <tr>
     <td style="padding: 7px"><img src="$images/crumbs.png" class="centerimg" alt="" /> $dirlist</td>
     <td><div class="win2" style="float: right; padding: 7px; white-space: nowrap;"><a href="$surl\lv-search/p-topten/">$boardindex[25]</a>$newpostslv</div></td>
    </tr>
   </table>
  </td>
 </tr>
EOT
	if($username eq 'Guest') {
		CoreLoad('Login',1);
		$ebout .= <<"EOT";
 <tr>
  <td class="win3">
   <form action="$surl\lv-login/p-2/" method="post">
    <table cellpadding="5" cellspacing="0" width="100%">
     <tr>
      <td><a href="$surl\lv-login/" rel="nofollow">$logintxt[60]</a> &nbsp; | &nbsp; <a href="$surl\lv-register/" rel="nofollow">$logintxt[3]</a> &nbsp; | &nbsp; <a href="$surl\lv-login/p-forgotpw/" rel="nofollow">$logintxt[5]</a></td>
      <td style="padding: 5px;" class="right"><input type="text" name="username" size="20" onfocus="if(this.value == '$rtxt[36]') { this.value=''; }" value="$rtxt[36]" tabindex="60" /> &nbsp; <input type="password" name="password" size="20" maxlength="$pwlength" onfocus="if(this.value == '$rtxt[37]') { this.value=''; }" value="$rtxt[37]" tabindex="61" /> &nbsp; <input type="hidden" name="redirect" value="$ENV{'QUERY_STRING'}" /><input type="hidden" name="days" value="forever" /><input type="submit" value=" $rtxt[38] " tabindex="77" /></td>
     </tr>
    </table>
   </form>
  </td>
 </tr>
EOT
	}
	$ebout .= <<"EOT";
</table><br />
EOT

	if($enews) {
		$ebout .= <<"EOT";
<table cellpadding="5" cellspacing="1" class="border" width="100%">
 <tr>
  <td class="titlebg"><strong><img src="$images/site_sm.gif" alt="" /> $mbname $var{'4'}</strong></td>
 </tr><tr>
  <td class="win center" style="height: 40px">
   <script type="text/javascript" src="$bdocsdir/news.js"></script>
   <script type="text/javascript">
   //<![CDATA[
EOT
		$number = 0;
		fopen(FILE,"$prefs/News.txt");
		while($message = <FILE>) {
			chomp $message;
			$message = BC($message);
			$message =~ s/\r|\n//g;
			$message =~ s/'/\\\'/g;
			$message =~ s/"/\\\"/g;
			$ebout .= "   singletext[$number]='$message'\n";
			$temp = $message;
			++$number;
		}
		fclose(FILE);

		if($number == 1) { $ebout .= "singletext[$number]='$temp'\n"; }
		elsif(!$number) {
			$mbname =~ s/'/\\'/;
			$ebout .= "   singletext[0]='$mbname $var{'4'}'\n  singletext[1]='$mbname $var{'4'}'\n";
		}
		$ebout .= <<"EOT";
    //]]>
   </script>
   <script type="text/javascript">
   //<![CDATA[
   if(document.all){
      document.writeln('<div style="cursor:default;position:relative;overflow:hidden;width:'+swidth+'px;height:'+sheight+'px;clip:rect(0 '+swidth+'px '+sheight+'px 0);" onmouseover="sspeed=0;" onmouseout="sspeed=2">')
      document.writeln('<div id="ieslider1" style="position:relative;width:'+swidth+'px;">')
      document.write(singletext[0])
   }
   if(document.getElementById&&!document.all){
      document.writeln('<div style="cursor:default;position:relative;overflow:hidden;width:'+swidth+'px;height:'+sheight+'px;clip:rect(0 '+swidth+'px '+sheight+'px 0);" onmouseover="sspeed=0;" onmouseout="sspeed=2">')
      document.writeln('<div id="ns6slider1" style="position:relative;width:'+swidth+'px;">')
      document.write(singletext[0])
   }
   window.onload = start;
    //]]>
   </script>
  </td>
 </tr>
</table><br />
EOT
	}

	if($username ne 'Guest') {
		fopen(FILE,"$members/$username.log");
		@log = <FILE>;
		fclose(FILE);
		chomp @log;
	}

	$ebout .= Glimpse() if($glimpsecnt > 0);

	GetActiveUsers();

	$bcnt = 0; $bp = 0; $bt = 0; $catcnt = 0;

	if($username ne 'Guest') {
		foreach(@log) {
			($t1,$t2) = split(/\|/,$_);
			$logged{$t1} = $t2;
		}
	}

	if($memberid{$username}{'shownewonly'}) { $link = "$surl\ln-1/b-"; } else { $link = "$surl\lb-"; }

	foreach(split(/\|/,$memberid{$username}{'rank'})) { $catshow{$_} = 1; }

	foreach(@boardbase) {
		($id) = split("/",$_);
		$board{$id} = $_;
	}

	foreach(@catbase) {
		($t,$boardid,$t,$t,$t,$subcats) = split(/\|/,$_);
		$catbase{$boardid} = $_;
		if(!$URL{'c'} && $subcats) {
			foreach(split(/\//,$subcats)) { $noshow{$_} = 1; }
		}
		push(@cats,$boardid);
	}

	foreach(@cats) {
		if($noshow{$_} || $URL{'c'} && $URL{'c'} ne $_) { next; }
		($name,$boardid,$memgroups,$boardlist,$message,$subcats) = split(/\|/,$catbase{$_});

		if(!GetMemberAccess($memgroups)) { next; }

		$message = BC($message); $catdesc = $message ? qq~<tr><td colspan="5" class="win3 smalltext" style="width: 0px;"><div class="catdesc">$message</div></td></tr>~ : '';

		$rollup = !$catshow{$boardid} ? 'minimize' : 'expand';
		$rollup = $username ne 'Guest' ? qq~<a href="$surl\la-tog/cat-$boardid/"><img src="$images/$rollup.gif" alt="" class="centerimg" /></a>~ : '';
		if($catshown) { $ebout .= '</table><br />'; } else { $catshown = 1; }

		$ebout .= <<"EOT";
<table cellpadding="7" cellspacing="1" class="border" width="100%">
 <tr>
  <td colspan="5" class="titlebg">
   <div style="float: left"><strong><a href="$surl\lv-shownews/a-feed/c-$boardid/"><img src="$images/feed.png" alt="" class="centerimg" /></a> <a href="$surl\lc-$boardid/">$name</a></strong></div>
   <div style="float: right">$rollup</div>
  </td>
 </tr>$catdesc
EOT
		if($catshow{$boardid}) {
			$catdisabled = 1;

			$ebout .= <<"EOT";
 <tr>
  <td colspan="5" class="win smalltext">$boardindex[88]<a href="$surl\la-tog/cat-$boardid/">$boardindex[89]</a>.</td>
 </tr>
EOT
			next;
		}
			else {
				$ebout .= <<"EOT";
 <tr>
  <th class="catbg smalltext" colspan="2"><strong>$boardindex[2]</strong></th>
  <th class="catbg smalltext center" style="width: 75px;"><strong>$boardindex[3]</strong></th>
  <th class="catbg smalltext center" style="width: 75px;"><strong>$boardindex[4]</strong></th>
  <th class="catbg smalltext center" style="width: 225px;"><strong>$boardindex[5]</strong></th>
 </tr>
EOT
			}

		if($boardlist eq '') { GetSubCats(); next; }
		foreach $bid (split("/",$boardlist)) {
			if($board{$bid} eq '') { next; } # Invalid board data
			($t,$message,$binfo[1],$binfo[2],$binfo[3],$binfo[4],$binfo[5],$binfo[6],$t,$t,$binfo[9],$t,$t,$redir,$boardimage) = split("/",$board{$bid});

			$lastuser = $lastdate = $icon = $bstat = $postsandtops = $infrm = $rowspan = $restriction = '';

			if(GetMemberAccess($binfo[9]) == 0) { next; }

			# Get the post totals
			fopen(FILE,"$boards/$bid.ino");
			@postinfo = <FILE>;
			fclose(FILE);
			chomp @postinfo;
			$posts  = $postinfo[1] > 0 ? MakeComma($postinfo[1]) : 0;
			$topics = $postinfo[0] > 0 ? MakeComma($postinfo[0]) : 0;

			# Compile the mods list
			@mods = split(/\|/,$binfo[1]);
			Mods();
			if($modz) { $modz = qq~<div class="smalltext" style="line-height: 200%;"><strong>$ltxt[7]:</strong> $modz</div>~; }

			# Users browsing
			$infrm = qq~ title="$B{$bid} $boardindex[45]"~ if($B{$bid});

			# Get last thread info (and look in log for new threads)
			fopen(FILE,"$boards/$bid.msg");
			while(<FILE>) {
				chomp;
				($tmid,$mtitle,$t,$t,$t,$t,$t,$icon,$lastdate,$lastuser) = split(/\|/,$_);
				$icon = $icon ne 'xx.gif' && $icon ne 'xx.png' ? qq~<img src="$images/icons/$icon" class="centerimg" alt="" /> ~ : '';
				last;
			}
			fclose(FILE);

			GetBoardData($mtitle,$lastdate,$lastuser,$bid,$binfo[6],$tmid);

			if($foundnew) { $new = 'off.gif'; $alt = $boardindex[9]; }
				else { $new = 'on.gif'; $alt = $boardindex[10]; }

			# Restricted posting?
			if(!GetMemberAccess($binfo[3]) && !GetMemberAccess($binfo[4])) { $restriction = $boardindex[98]; }
			elsif(!GetMemberAccess($binfo[3])) { $restriction = $boardindex[99]; }
			elsif(!GetMemberAccess($binfo[4])) { $restriction = $boardindex[100]; }

			if($restriction ne '' && !$redir) {
				$restriction = qq~<div style="padding: 7px" class="win3 smalltext"><img src="$images/binfo.png" class="leftimg" alt="" /> $restriction</div>~;
			} else { $restriction = ''; }

			if(!GetMemberAccess($binfo[3]) && !GetMemberAccess($binfo[4])) { $new = "thread_locked.png"; }

			# Basic board info (like description)
			$message =~ s/&#47;/\//gsi;
			$message = BC($message);

			# Info blocked by permissions?
			if($binfo[6]) {
				$bstat .= qq~<div class="smalltext" style="line-height: 200%;"><strong>$boardindex[7]</strong></div>~;
				if(($Blah{"$bid\_pw"} ne $binfo[6] && !$members{'Administrator',$username}) || $username eq 'Guest') {
					$lastpost = $gtxt{'13'};
					$bt -= $postinfo[0];
					$bp -= $postinfo[1];
					$topics = $posts = '?';
					$new = 'thread_locked.png';
					$lastdate = 1;
				}
			}

			# Redirect forum, or regular?
			if($redir) {
				fopen(ADD,"$boards/$bid.hits");
				$nump = MakeComma( <ADD> ) || 0;
				fclose(ADD);

				$postsandtops = <<"EOT";
  <td class="win smalltext center" colspan="2">$boardindex[71]: $nump</td>
EOT
				$lastpost = qq~<div class="bidate">$boardindex[72]<br /></div>~;
				$new = 'redirect.gif';
				$bid = $bid.qq~/" onclick="target='_new';~;
			} else {
				$postsandtops = <<"EOT";
  <td class="win center">$topics</td>
  <td class="win center">$posts</td>
EOT
				$bp += $postinfo[1];
				$bt += $postinfo[0];
				$bid .= '/';
			}
			++$bcnt;

			if($boardimage) {
				$boardimage =~ s/\|/\//g;
				$boardimage = $boardimage =~ /http:\/\// ? $boardimage : "$images/$boardimage";
				$boardimage = qq~<img src="$boardimage" style="vertical-align: middle;" alt="" /> ~;
			}

			$ebout .= <<"EOT";
 <tr>
  <td class="win center vtop" style="width: 30px; padding: 7px;"$rowspan><img src="$images/$new" alt="$alt" /></td>
  <td style="padding: 0px;" class="win2 vtop">
   <div style="padding: 7px;"><div class="boardname">$boardimage<a href="$link$bid"$infrm>$binfo[2]</a></div>
   <div class="bidesc">$message</div>$bstat$modz</div>$restriction
  </td>$postsandtops
  <td class="win2 vtop smalltext" style="width: 225px">
$lastpost
  </td>
 </tr>
EOT
		}
		if($subcats) { GetSubCats(); }
		++$catcnt;
	}

	if($bcnt == 0 && !$catdisabled) {
		if($catcnt) { $ebout .= qq~</table><br />~; }
		$ebout .= <<"EOT";
<table cellpadding="5" cellspacing="1" class="border" width="100%">
 <tr>
  <td class="win2 center" colspan="5"><br />$boardindex[14]<br /><br /></td>
 </tr>
</table><br />
EOT
	} else {
		if($memberid{$username}{'timezone'} > 0) { $memberid{$username}{'timezone'} = "+$memberid{$username}{'timezone'}"; }
		if($memberid{$username}{'timezone'}) { $timezone = " $memberid{$username}{'timezone'} $gtxt{'3'}"; }
		if($username ne 'Guest' && $URL{'c'} eq '') { $maread = qq~<div class="win2" style="padding: 7px; float: right"><a href="$surl\lv-mark/l-bindex/">$boardindex[102]</a></div>~; }

		$ebout .= <<"EOT";
</table><br />
<div style="padding: 1px;" class="border">
 <table cellpadding="0" cellspacing="0" class="win" width="100%">
  <tr>
   <td style="padding: 7px">$boardindex[67]$timezone</td>
   <td>$maread</td>
  </tr>
 </table>
</div>
<br />
EOT
	}
	if($bcnt == 1) { $r = $boardindex[49]; } else { $r = $boardindex[50]; }
	$bp = MakeComma($bp);
	$bt = MakeComma($bt);
	if(!$lasttopic) { $lasttopic = $boardindex[24]; }

	fopen(FILE,"$members/LastMem.txt");
	@lastmember = <FILE>;
	fclose(FILE);
	chomp @lastmember;
	$nums = @lastmember;

	$memberson =~ s/, \Z//i;
	if($memberson eq '') { $memberson = "<i>$boardindex[69]</i>"; }

	fopen(FILE,"$prefs/MaxLog.txt");
	@maxlogged = <FILE>;
	fclose(FILE);
	chomp @maxlogged;
	$maxtime = get_date($maxlogged[1]);

	GetMemberID($lastmember[0]);
	$allcnt = MakeComma($gcnt+$hidec+$memcnt+$botc);
	$membercount = MakeComma($lastmember[1]);

	foreach(@fullgroups) {
		if($permissions{$_,'color'} && !$permissions{$_,'colorcodes'}) {
			$permissions{$_,'level'} = 100 if($permissions{$_,'pcount'});
			push(@sortgroups, "$permissions{$_,'level'}|$_");
		}
	}

	foreach(sort {$a <=> $b} @sortgroups) {
		($t,$group) = split(/\|/,$_);
		$colorcodes .= !$permissions{$group,'pcount'} ? qq~<a href="$surl\lv-members/a-groups/group-$group/" class="usercolors" style="color: $permissions{$group,'color'}">$permissions{$group,'name'}</a>~ : qq~<span class="usercolors" style="color: $permissions{$group,'color'}">$permissions{$group,'name'}</span>~;
		$colorcodes .= ', ';
	}
	$colorcodes =~ s/, \Z//i;
	if($colorcodes ne '') { $colorcodes = qq~<div style="padding: 2px" class="smalltext"><strong>$boardindex[78]:</strong> $colorcodes</div>~; }

	$colorcnt = 1;
	@colorclass = ('win','win2');

	if($members{'Administrator',$username}) { $hiddenusers = "; $hidec $boardindex[57]"; }

	$ebout .= <<"EOT";
<table cellpadding="0" cellspacing="1" class="border" width="100%">
 <tr>
  <td style="padding: 5px" class="titlebg"><strong>$boardindex[76]</strong></td>
 </tr><tr>
  <td style="padding: 5px" class="catbg"><span style="float: left;"><a href="$surl\lv-stats/a-whereis/">$allcnt $boardindex[77]</a><span class="smalltext"> ($memcnt $boardindex[56]; $botc $boardindex[91]; $gcnt $boardindex[59]$hiddenusers)</span></span><span class="smalltext" style="float: right">$boardindex[87] $activeuserslog $gtxt{'2'}.</span></td>
 </tr><tr>
  <td class="$colorclass[0]">
   <table cellpadding="9" cellspacing="1" width="100%">
    <tr>
     <td class="win3 center" style="width: 23px"><img src="$images/computer.png" alt="" /></td>
     <td>$memberson<hr />$colorcodes
      <div style="padding: 2px" class="smalltext">$boardindex[61] <strong>$maxlogged[0]</strong> $boardindex[62] <strong>$maxtime</strong>.</div>
     </td>
    </tr>
   </table>
  </td>
 </tr>
EOT
	if(!$forumstats) {
		$ebout .= <<"EOT";
 <tr>
  <td style="padding: 5px" class="catbg"><strong>$boardindex[79]</strong></td>
 </tr><tr>
  <td class="$colorclass[1]">
   <table cellpadding="9" cellspacing="1" width="100%">
    <tr>
      <td class="win3 center" style="width: 23px"><img src="$images/forumstats.png" alt="" /></td>
      <td><strong>$gtxt{'7'}:</strong> $bcnt &nbsp; | &nbsp; <strong>$gtxt{'6'}:</strong> $catcnt &nbsp; | &nbsp; <strong>$gtxt{'8'}:</strong> $bt &nbsp; | &nbsp; <strong>$gtxt{'9'}:</strong> $bp &nbsp; | &nbsp; <strong>$var{'83'}:</strong> $membercount<hr /><a href="$surl\lv-portal/">$boardindex[48]</a> &nbsp; - &nbsp; <a href="$surl\lv-search/p-topten/">$boardindex[25]</a>$newpostslv &nbsp; - &nbsp; <a href="$surl\v-members/">$boardindex[80]</a> &nbsp; - &nbsp; <strong>$boardindex[81]:</strong> $lasttopic &nbsp; | &nbsp; <strong>$boardindex[82]:</strong> $userurl{$lastmember[0]}</td>
     </tr>
   </table>
  </td>
 </tr>
EOT
	}

	if(($eclick && (!$hideclog || $members{'Administrator',$username})) || ($uextlog && (!$hideelog || $members{'Administrator',$username}))) {
		++$colorcnt;
		$ebout .= <<"EOT";

 <tr>
  <td style="padding: 5px" class="catbg"><strong>$boardindex[83]</strong></td>
 </tr><tr>
  <td class="$colorclass[$colorcnt % 2]">
   <table cellpadding="9" cellspacing="1" width="100%">
    <tr>
     <td class="win3 center" style="width: 23px"><img src="$images/logs.png" alt="" /></td>
     <td>
EOT
		if($eclick && (!$hideclog || $members{'Administrator',$username})) {
			$logcnt = $logcnt > 59 ? sprintf("%.0f",($logcnt/60))." $gtxt{'3'}" : "$logcnt $gtxt{'2'}";
			$LoggedClicks = MakeComma($LoggedClicks+1);

			$ebout .= <<"EOT";
  $boardindex[51] <strong>$logcnt</strong> $boardindex[52] <strong>$LoggedClicks $boardindex[53]</strong>.<br />
EOT
		}
		if($uextlog  && (!$hideelog || $members{'Administrator',$username})) { $ebout .= qq~<strong><a href="$surl\lv-stats/">$boardindex[22] $boardindex[21]</a></strong>~; }
		$ebout .= <<"EOT";
     </td>
    </tr>
   </table>
  </td>
 </tr>
EOT
	}

	if($showevents) {
		CoreLoad('Calendar');
		GetEvents();
		@events = UpcomingEvents($upevents);

		foreach(@events) {
			($start,$owner,$groups,$id,$t,$end,$t,$t,$bgcolor,$title) = split(/\|/,$_);
			if($ids{$id}) { next; } else { $ids{$id} = 1; }
			$notime_date = 1;
			$date = get_date($start,1,1);
			($t,$t,$t,$day,$month,$year) = localtime($start);
			$year += 1900;
			++$month;
			$events .= <<"EOT";
<tr>
 <td style="background-color: $bgcolor;" onclick="location='$surl\v-cal/month-$month/year-$year/day-$day/'">
  <span style="float: left"><a href="$surl\v-cal/month-$month/year-$year/day-$day/">$title</a></span>
  <span style="float: right">$date</span>
 </td>
</tr>
EOT
		}

		if($enbdays) {
			GetBirthdays();

			($t,$t,$t,$day,$month) = localtime(time);
			++$month;

			if($BirthDayC{"$month|$day"}) {
				$birthdays = qq~<tr><td>$boardindex[93] $BirthDayC{"$month|$day"} $boardindex[94]<ol type="$1">~;
				foreach(split(',',$BirthDay{"$month|$day"})) {
					GetMemberID($_);
					$age = calage($memberid{$_}{'dob'});
					$birthdays .= '<li>'.$userurl{$_}." - $age $boardindex[92].</li>";
				}
				$birthdays =~ s/, \Z//g;
				$birthdays .= "</ol></td></tr>";
			}
		}

		if($events eq '' && $birthdays eq '') { $events = qq~<tr><td>$boardindex[96]</td></tr>~; }

		++$colorcnt;
		$ebout .= <<"EOT";
 <tr>
  <td style="padding: 5px;" class="catbg"><div style="float: left"><strong>$boardindex[84]</strong></div><div class="smalltext" style="float: right">$boardindex[95]</div></td>
 </tr><tr>
  <td class="$colorclass[$colorcnt % 2]">
   <table cellpadding="9" cellspacing="1" width="100%">
    <tr>
     <td class="win3 center" style="width: 23px"><img src="$images/events.png" alt="" /></td>
     <td style="padding: 0px;" class="vtop">
      <table cellspacing="0" cellpadding="5" width="100%">$events$birthdays</table>
     </td>
    </tr>
   </table>
  </td>
 </tr>
EOT
	}

	if($invfri && $username ne 'Guest') {
		CoreLoad('Invite',1);
		++$colorcnt;
		$ebout .= <<"EOT";
 <tr>
  <td style="padding: 5px" class="catbg"><strong>$boardindex[85]</strong></td>
 </tr><tr>
  <td class="$colorclass[$colorcnt % 2]">
   <form action="$surl\v-invite/" method="post">
   <table cellpadding="9" cellspacing="1" width="100%">
    <tr>
     <td class="win3 center" style="width: 23px"><img src="$images/invite.png" alt="" /></td>
     <td>
      <table cellspacing="0" width="400" class="innertable">
       <tr>
        <td><strong>$invite[3]:</strong></td>
        <td style="width: 150px"><input type="text" name="friendname" size="25" /></td>
        <td rowspan="2"><input type="submit" value=" $invite[6] " /></td>
       </tr><tr>
        <td><strong>$gtxt{'23'}:</strong></td>
        <td><input type="hidden" name="post" value="1" /><input type="text" name="friendmail" size="25" /></td>
       </tr>
      </table>
     </td>
    </tr>
   </table>
   </form>
  </td>
 </tr>
EOT
	}


	$ebout .= "</table>";

	footer();
	exit;
}

sub Tog {
	is_member();
	VerifyBoard(); # So someone can't overload the datafile ...
	my($delMZ);
	$URL{'cat'} =~ s~\A\s+~~; # As always ... hack protection
	$URL{'cat'} =~ s~\s+\Z~~;
	$URL{'cat'} =~ s~[\n\r]~~g;

	$userrank = '';
	foreach(split(/\|/,$memberid{$username}{'rank'})) {
		if($URL{'cat'} eq $_) { $delMZ = 1; next; }
		$userrank .= "$_|";
	}
	if(!$delMZ && $catallow{"$URL{'cat'}"}) { $userrank .= "$URL{'cat'}"; }

	$addtoID{'rank'} = $userrank;

	SaveMemberID($username);

	redirect();
}

sub GetBoardData {
	my($mtitle,$lastdate,$lastuser,$board,$blockout,$tmid,$movedmessage,$urltemp) = @_;
	my($found,$isnew,$tdate);

	$tdate = get_date($lastdate);
	if($username ne 'Guest') { $found = 1 if(($logged{$board}-$lastdate) >= 0 || ($logged{"AllRead_$board"}-$lastdate) >= 0 || ($logged{'AllBoards'}-$lastdate) >= 0); }
	$foundnew = $username eq 'Guest' || $found || $lastdate eq '' ? 1 : 0;

	# Get last post info
	GetMemberID($lastuser);
	$lpby = $memberid{$lastuser}{'sn'} ne '' ? $userurl{$lastuser} : FindOldMemberName($lastuser);

	$mtitle = CensorList($mtitle);
	my $mtitlelong = $mtitle;
	$mtitle =~ s/\&quot;/"/g;
	$mtitle =~ s/\&amp;/\&/g;

	($movedid,$movedmessage) = split("<>",$mtitle);

	if($movedmessage eq '') {
		if(length($mtitle) > 24) { $mtitle = substr($mtitle,0,22)."..."; }
		$messageurl = $surl;
		if($username ne 'Guest' && ($logged{$tmid}-$lastdate) <= 0 && ($logged{"AllRead_$board"}-$lastdate) <= 0) { $urltemp = "s-new/"; }

		$lpin = $mtitle ne '' ? qq~<a href="$messageurl\lm-$tmid/$urltemp" title="$mtitlelong">$mtitle</a>~ : $gtxt{'13'};
	}
		else {
			if($username ne 'Guest') { $urltemp = "s-new/"; }
			if(length($movedmessage) > 24) { $movedmessage = substr($movedmessage,0,22)."..."; }
			$lpin = qq~<a href="$surl\lm-$movedid/$urltemp">$movedmessage</a>~;

			$mtitle = $movedmessage;
		}

	if($subcatslist eq '') { $boardfeed = qq~<a href="$surl\lv-shownews/a-feed/b-$board/"><img src="$images/feed.png" alt="" class="rightimg" /></a>~; }
		else { $boardfeed = qq~<a href="$surl\lv-shownews/a-feed/c-$nohere/"><img src="$images/feed.png" alt="" class="rightimg" /></a>~; }

	$lastpost = $lpby ne '' ? qq~<div class="bilastaction"><strong>$icon$lpin</strong><br />$gtxt{'46'} $lpby</div><div class="bidate">$boardfeed$tdate</div>~ : qq~<div class="bidate">$gtxt{'13'}</div>~;

	if($blockout ne '') { return() if(($Blah{"$bid\_pw"} ne $blockout && !$members{'Administrator',$username}) || $username eq 'Guest'); }
	if($max < $lastdate) { $max = $lastdate; $lasttopic = qq~<a href="$messageurl\lm-$tmid/$urltemp" title="$boardindex[13]">$mtitle</a>~; }
}

sub GetMSubs {
	my($msubcats,$memgroupsx,@boards);
	$noloop{$_[0]} = 1;
	($t,$t,$memgroupsx,$boardlist,$t,$msubcats) = split(/\|/,$catbase{$_[0]});

	if(!GetMemberAccess($memgroupsx)) { return(0); }

	foreach(split(/\//,$boardlist)) {
		push(@boardlists, "$_/1" );
	}

	if($msubcats) { foreach $subcat (split(/\//,$msubcats)) { GetMSubs($subcat,1); } }

	return(1);
}

sub GetSubCats {
	my($cats,$msubcats,$tname);
	@boardlists = ();
	foreach $nohere (split(/\//,$subcats)) {
		if($catbase{$nohere} eq '') { next; }
		$subboards = $maxlastdate = 0;
		$icon = $sflist = $lastpost = $posts = $subcatslist = $topics = '';
		($name,$t,$memgroups,$boardlist,$message,$msubcats) = split(/\|/,$catbase{$nohere});
		$message = BC($message);
		if(!GetMemberAccess($memgroups)) { next; }
		@boardlists = split(/\//,$boardlist);

		foreach $subcat (split(/\//,$msubcats)) {
			if(!GetMSubs($subcat)) { next; }
			($tname) = split(/\|/,$catbase{$subcat});

			$subcatslist .= qq~<a href="$surl\lc-$subcat">$tname</a>, ~;
		}
		$subcatslist =~ s/, \Z//g;
		if($subcatslist ne '') { $subcatslist = qq~<div class="smalltext" style="line-height: 200%;"><strong>$boardindex[101]:</strong> $subcatslist</div>~ if($subboards <= 4); ++$subboards; }

		$subboards = 0;
		foreach $board (@boardlists) {
			($board,$displaynob) = split(/\//,$board);
			++$subboards;
			($daid,$t,$t,$sflname,$t,$t,$t,$binfo[6],$t,$t,$grp,$t,$t,$redir) = split("/",$board{$board});
			if($binfo[6] ne '' && (($Blah{"$board\_pw"} ne $binfo[6] && !$members{'Administrator',$username}) || $username eq 'Guest')) { next; }

			if(GetMemberAccess($grp)) { $sflist .= qq~<a href="$surl\lb-$daid/">$sflname</a>, ~ if($subboards <= 4 && !$displaynob); }
				else { next; }
			if($redir) { next; }

			# Get the post totals
			fopen(FILE,"$boards/$board.ino");
			@postinfo = <FILE>;
			fclose(FILE);
			chomp @postinfo;
			$posts  += $postinfo[1];
			$topics += $postinfo[0];
			$bp += $postinfo[1];
			$bt += $postinfo[0];
			++$bcnt;

			fopen(FILE,"$boards/$board.msg");
			while(<FILE>) {
				chomp;
				($xxtmid,$mtitle,$t,$t,$t,$t,$t,$icon,$lastdate,$lastuser) = split(/\|/,$_);
				if($lastdate > $maxlastdate) { $maxlastdate = $lastdate; $lastpost = "$board|$mtitle|$icon|$lastuser"; $tmid = $xxtmid; }
				last;
			}
			fclose(FILE);
		}
		$sflist =~ s/, \Z//g;
		if($sflist ne '') { $sflist = qq~<div class="smalltext" style="line-height: 200%;"><strong>$boardindex[74]:</strong> $sflist</div>~; }

		if($lastpost) {
			($board,$mtitle,$icon,$lastuser) = split(/\|/,$lastpost);

			$icon = $icon ne 'xx.gif' && $icon ne '' ? qq~<img src="$images/icons/$icon" class="centerimg" alt="" /> ~ : '';

			GetBoardData($mtitle,$maxlastdate,$lastuser,$board,$binfo[6],$tmid);

			if($foundnew) { $new = 'cat_off.gif'; $alt = $boardindex[9]; }
				else { $new = 'cat_on.gif'; $alt = $boardindex[10]; }
		} else { $new = 'cat_off.gif'; $alt = $boardindex[9]; $lastpost = $gtxt{'13'}; }

		$posts  = MakeComma($posts);
		$topics = MakeComma($topics);

		$ebout .= <<"EOT";
 <tr>
  <td class="win center vtop" style="width: 30px; padding: 7px;"><img src="$images/$new" alt="$alt" /></td>
  <td class="win2 vtop"><div class="boardname"><a href="$surl\lc-$nohere/">$name</a></div><div class="smalltext">$message</div>$sflist$subcatslist</td>
  <td class="win center">$topics</td>
  <td class="win center">$posts</td>
  <td class="win2 vtop smalltext" style="width: 225px">
$lastpost
  </td>
 </tr>
EOT
		$catdisabled = 1;
	}
}
1;