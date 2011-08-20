#############################################
# E-Blah Bulletin Board Systems        2008 #
#############################################
# Copyright (c) 2001 - 2008 E-Blah.         #
#############################################

VerifyBoard();
CoreLoad('Stats',1);

sub Stats {
	if($URL{'a'} eq 'whereis') { WhereIs(); }

	if(!$uextlog) { error($statstxt[1]); }
	if($hideelog) { is_admin(6.3); }

	if($URL{'a'} ne '') { MonthlyStats(); }

	# Open the member list, and get all the members into a nice table we can look at later
	fopen(FILE,"$members/List2.txt");
	@memlist = <FILE>;
	fclose(FILE);
	chomp @memlist;
	$totalmembers = @memlist;
	$totalmembers = MakeComma($totalmembers);
	foreach(@memlist) {
		($un,$t,$pc,$reg) = split(/\|/,$_);
		push(@maxmempcount,"$pc|$_");  # User post count max variable
		push(@newmembers,  "$reg|$_"); # When user reg'd
	}
	@maxmempcount = sort{$b <=> $a} @maxmempcount;
	@newmembers   = sort{$b <=> $a} @newmembers;

	# Open the max log to find on what date the most users logged on was
	fopen(FILE,"$prefs/MaxLog.txt");
	@maxlogged = <FILE>;
	fclose(FILE);
	chomp @maxlogged;
	$maxtime = get_date($maxlogged[1]);

	# Find how many active users there are (online ppl)
	fopen(FILE,"$prefs/Active.txt");
	while(<FILE>) { ++$active; }
	fclose(FILE);

	# If click log is enabled, open it and find how many clicks there are
	if($eclick) {
		$clicklogc = $LoggedClicks;
		if($logcnt > 59) { $logcnt = sprintf("%.0f",($logcnt/60))." $gtxt{'3'}"; }
			else { $logcnt = "$logcnt $gtxt{'2'}"; }
	}

	# Open all the states files and compile that info for later use
	opendir(DIR,"$prefs/BHits");
	@crap = readdir(DIR);
	closedir(DIR);

	($t,$t,$t,$day,$month,$year) = localtime(time);
	$tempper = $day.$month.$year;

	foreach $junk (@crap) {
		if($junk !~ /.txt/ || $junk eq "$tempper.txt" || $junk eq "quickdb.txt") { next; }

		fopen(FILE,"$prefs/BHits/$junk");
		@junk2 = <FILE>;
		fclose(FILE);
		chomp @junk2;

		unlink("$prefs/BHits/$junk");

		$junk =~ s/.txt\Z//g;
		push(@database,"$junk|$junk2[0]|$junk2[1]|$junk2[2]|$junk2[3]|$junk2[4]|$junk2[5]|$junk2[6]|$junk2[7]|$junk2[8]");
	}

	fopen(DATABASE,"$prefs/BHits/quickdb.txt");
	@hits = <DATABASE>;
	fclose(DATABASE);
	chomp @hits;

	foreach(@hits) { ($t) = split(/\|/,$_); $taken{$t} = 1; }

	fopen(DATABASE,">>$prefs/BHits/quickdb.txt");
	foreach(@database) {
		($t) = split(/\|/,$_);
		print DATABASE "$_\n";
		push(@hits,"$_");
	}
	fclose(DATABASE);

	fopen(FILE2,"$prefs/BHits/$tempper.txt");
	@junk2 = <FILE2>;
	fclose(FILE2);
	chomp @junk2;

	$tempper =~ s/.txt\Z//g;
	push(@hits,"$tempper|$junk2[0]|$junk2[1]|$junk2[2]|$junk2[3]|$junk2[4]|$junk2[5]|$junk2[6]|$junk2[7]|$junk2[8]");

	foreach(@hits) {
		@hitsL = split(/\|/,$_);

		# Clicks (0) | Threads (1) | Replies (2) | Mems (3) | New Att. (4) | Att. Downloads (5) | Most Online (7)
		$dateinfo{$hitsL[7]} = "$hitsL[1]|$hitsL[2]|$hitsL[3]|$hitsL[4]|$hitsL[5]|$hitsL[6]|$hitsL[8]|$hitsL[9]";

		push(@sortdate,    $hitsL[7]);
		push(@sortclicks,  "$hitsL[1]|$hitsL[7]");
		push(@sortthreads, "$hitsL[2]|$hitsL[7]");
		push(@sortreplies, "$hitsL[3]|$hitsL[7]");
		push(@sortmems,    "$hitsL[4]|$hitsL[7]");
		push(@sortatts,    "$hitsL[5]|$hitsL[7]");
		push(@sortdowns,   "$hitsL[6]|$hitsL[7]");
		push(@sortonline,  "$hitsL[8]|$hitsL[7]");
		push(@spamers,     "$hitsL[9]|$hitsL[7]");
	}

	@sortdate    = sort{$b <=> $a} @sortdate;
	@sortclicks  = sort{$b <=> $a} @sortclicks;
	@sortthreads = sort{$b <=> $a} @sortthreads;
	@sortreplies = sort{$b <=> $a} @sortreplies;
	@sortmems    = sort{$b <=> $a} @sortmems;
	@sortatts    = sort{$b <=> $a} @sortatts;
	@sortdowns   = sort{$b <=> $a} @sortdowns;
	@sortonline  = sort{$b <=> $a} @sortonline;
	@spammers    = sort{$b <=> $a} @spammers;

	# Lets load the board stats
	BoardStats();

	$title = $statstxt[2];
	header();

	$ebout .= <<"EOT";
<table cellpadding="4" cellspacing="1" class="border" width="100%">
 <tr>
  <td class="titlebg">$title</td>
 </tr><tr>
  <td class="catbg smalltext center"><strong>$statstxt[3]</strong></td>
 </tr><tr>
  <td class="win2">
   <table width="100%">
    <tr>
     <td style="width: 50%"><img src="$images/profile_sm.gif" class="centerimg" alt="" /> <strong>$statstxt[4]</strong></td>
     <td style="width: 50%"><img src="$images/open_thread.gif" class="centerimg" alt="" /> <strong>$statstxt[5]</strong></td>
    </tr>
   </table>
  </td>
 </tr><tr>
  <td class="win">
   <table width="100%">
    <tr>
     <td style="width: 50%" class="vtop">
      <table width="100%">
       <tr>
        <td><strong>$statstxt[6]:</strong></td>
        <td class="right">$totalmembers $statstxt[32]</td>
       </tr><tr>
        <td><strong>$statstxt[8]:</strong></td>
        <td class="right">$active $statstxt[31]</td>
       </tr><tr>
        <td colspan="2"><hr /></td>
       </tr><tr>
        <td class="vtop"><strong>$statstxt[9]:</strong></td>
        <td class="right">$maxlogged[0] $statstxt[31]<br /><span class="smalltext">$maxtime</span></td>
       </tr>
      </table>
     </td>
     <td style="width: 50%">
      <table cellpadding="3" cellspacing="0" width="100%">
EOT
	if($eclick && (!$hideclog || $members{'Administrator',$username})) {
		foreach(@clicklog) {
			($logtime,$ipaddy,$ref,$page,$info) = split(/\|/,$_);
			$f1 = 1;
			if(@ipaddys) { foreach(@ipaddys) { if($_ eq $ipaddy) { $f1 = 0; last; } } }
			if($f1) { push(@ipaddys,$ipaddy); ++$ipcnt; }
		}
		$clicklogc = MakeComma($clicklogc);
		$ebout .= <<"EOT";
       <tr>
        <td class="vtop"><strong>$statstxt[10] $logcnt:</strong></td>
        <td class="right"><a title="$ipcnt $gtxt{'5'}">$clicklogc</a></td>
       </tr>
EOT
	}
	$threads = MakeComma($threads);
	$messagecnt = MakeComma($messagecnt);
	$ebout .= <<"EOT";
       <tr>
        <td class="vtop"><strong>$gtxt{'6'}:</strong></td>
        <td class="right">$catcnt</td>
       </tr><tr>
        <td class="vtop"><strong>$gtxt{'7'}:</strong></td>
        <td class="right">$bdscnt</td>
       </tr><tr>
        <td class="vtop"><strong>$gtxt{'8'}:</strong></td>
        <td class="right">$threads</td>
       </tr><tr>
        <td class="vtop"><strong>$gtxt{'9'}:</strong></td>
        <td class="right">$messagecnt</td>
       </tr>
      </table>
     </td>
    </tr>
   </table>
  </td>
 </tr>
EOT

	if($members{'Administrator',$username}) {
		GetSize("$members>1|$messages>1|$prefs|$modsdir|$uploaddir|$boards>1");

		$totalsize = FormatSize($totalsize);

		$ebout .= <<"EOT";
 <tr>
  <td class="catbg smalltext center"><strong>$statstxt[33]</strong></td>
 </tr><tr>
  <td class="win2">
   <table cellpadding="3" cellspacing="0" width="100%">
    <tr>
     <td style="width: 50%"><strong>$statstxt[34]</strong></td>
     <td style="width: 50%"><strong>$statstxt[35]</strong></td>
    </tr>
   </table>
  </td>
 </tr><tr>
  <td class="win">
   <table cellpadding="3" cellspacing="0" width="100%">
    <tr>
     <td style="width: 50%" class="vtop">
      <table width="100%">
       <tr>
        <td><strong>Boards $statstxt[36]:</strong></td>
        <td class="right">$size{$boards}</td>
       </tr><tr>
        <td><strong>Messages $statstxt[36]:</strong></td>
        <td class="right">$size{$messages}</td>
       </tr><tr>
        <td><strong>Members $statstxt[36]:</strong></td>
        <td class="right">$size{$members}</td>
       </tr><tr>
        <td colspan="2"><hr /></td>
       </tr><tr>
        <td><strong>$statstxt[37]:</strong></td>
        <td class="right">$size{'CORE'}</td>
       </tr>
      </table>
     </td><td style="width: 50%" class="vtop">
      <table width="100%">
       <tr>
        <td><strong>Prefs $statstxt[36]:</strong></td>
        <td class="right">$size{$prefs}</td>
       </tr><tr>
        <td><strong>Modifications $statstxt[36]:</strong></td>
        <td class="right">$size{$modsdir}</td>
       </tr><tr>
        <td><strong>Attachments $statstxt[36]:</strong></td>
        <td class="right">$size{$uploaddir}</td>
       </tr><tr>
        <td colspan="2"><hr /></td>
       </tr><tr>
        <td><strong>$statstxt[38]:</strong></td>
        <td class="right">$size{'NOESS'}</td>
       </tr>
      </table>
     </td>
    </tr><tr>
     <td colspan="2" class="center"><hr /><strong>$statstxt[39]:</strong> $totalsize</td>
    </tr>
   </table>
  </td>
 </tr>
EOT
	}
	$ebout .= <<"EOT";
 <tr>
  <td class="catbg smalltext center"><strong>$statstxt[5]</strong></td>
 </tr><tr>
  <td class="win2">
   <table cellpadding="3" cellspacing="0" width="100%">
    <tr>
     <td style="width: 50%"><img src="$images/lamp.gif" class="centerimg" alt="" /> <strong>$statstxt[12]</strong></td>
     <td style="width: 50%"><img src="$images/profile_sm.gif" class="centerimg" alt="" /> <strong>$statstxt[28]</strong></td>
    </tr>
   </table>
  </td>
 </tr><tr>
  <td class="win vtop">
   <table cellpadding="3" cellspacing="0" width="100%">
    <tr>
EOT
	$c = 1;
	for($g = 0; $g < 10; ++$g) {
		$team = '';
		($posts,$member) = split(/\|/,$maxmempcount[$g]);
		GetMemberID($member);
		$posts = MakeComma($posts);
		if($member eq '') { next; }
		if($permissions{$membergrp{$member},'team'}) { $team = qq~ <img src="$images/team.gif" alt="$gtxt{'29'}" /> ~; }
		$topmems .= qq~<strong>$c.</strong>$team $userurl{$member} <span class="smalltext">($posts $gtxt{'10'})</span><br />~;
		++$c;
	}
	$c = 1;
	for($g = 0; $g < 10; ++$g) {
		$team = '';
		($regged,$member) = split(/\|/,$newmembers[$g]);
		GetMemberID($member);
		$regged = get_date($regged);
		if($member eq '') { next; }
		if($permissions{$membergrp{$member},'team'}) { $team = qq~ <img src="$images/team.gif" alt="$gtxt{'29'}" /> ~; }
		$regnew .= qq~<strong>$c.</strong>$team $userurl{$member} ($regged)<br />~;
		++$c;
	}

	$ebout .= <<"EOT";
     <td style="width: 50%" class="smalltext vtop">$topmems</td>
     <td style="width: 50%" class="smalltext vtop">$regnew</td>
    </tr>
   </table>
  </td>
 </tr><tr>
  <td class="win2">
   <table cellpadding="3" cellspacing="0" width="100%">
    <tr>
     <td style="width: 50%"><img src="$images/hotthread.png" class="centerimg" alt="" /> <strong>$statstxt[13]</strong></td>
     <td style="width: 50%"><img src="$images/veryhotthread.png" class="centerimg" alt="" /> <strong>$statstxt[14] ($gtxt{'12'})</strong></td>
    </tr>
   </table>
  </td>
 </tr><tr>
  <td class="win vtop">
   <table cellpadding="3" cellspacing="0" width="100%">
    <tr>
EOT
	foreach $use (@boardbase) {
		($board,$t,$t,$t,$t,$t,$t,$apwbrd) = split('/',$use);
		if(!$boardallow{$board}) { next; }
		fopen(FILE,"$boards/$board.msg");
		while(<FILE>) {
			chomp $_;
			($id,$msub,$t,$t,$replies) = split(/\|/,$_);
			push(@mdata,"$replies|$msub|$id|$board");
		}
		fclose(FILE);
	}
	@mdata = sort{$b <=> $a} @mdata;

	$c = 1;
	for($g = 0; $g < 10; ++$g) {
		($replies,$msub,$id,$bdat) = split(/\|/,$mdata[$g]);
		$replies = MakeComma($replies);
		$msub = Format($msub);
		if($msub) { $toptops .= qq~<strong>$c.</strong> <a href="$surl\lm-$id/s-$replies/">$msub</a> <span class="smalltext">($replies $gtxt{'12'})</span><br />~; }
		++$c;
	}
	if(!$toptops) { $toptops = $statstxt[15]; }
	@tbds = sort{$b <=> $a} @tbds;

	$c = 1;
	for($g = 0; $g < 10; ++$g) {
		($mcnt,$boardnm,$bid) = split(/\|/,$tbds[$g]);
		$mcnt = MakeComma($mcnt);
		if($boardnm) { $topboards .= qq~<strong>$c.</strong> <a href="$surl\lb-$bid/">$boardnm</a> <span class="smalltext">($mcnt $gtxt{'11'})</span><br />~; }
		++$c;
	}
	$ebout .= <<"EOT";
     <td style="width: 50%" class="smalltext vtop">$topboards</td>
     <td style="width: 50%" colspan="2" class="smalltext vtop">$toptops</td>
    </tr>
   </table>
  </td>
 </tr>
</table><br />
<table cellpadding="4" cellspacing="1" class="border" width="100%">
 <tr>
  <td class="titlebg smalltext center" colspan="7"><strong>$statstxt[40]</strong></td>
 </tr><tr>
EOT
	$stats = 0;
	foreach(@sortdate) {
		($maxclicks,$maxthreads,$maxreplies,$maxmems,$maxnewatt,$maxattdownloads,$maxmostonline,$spammers) = split(/\|/,$dateinfo{$_});
		($t,$t,$t,$day,$month,$year) = localtime($_);
		$year = $year+1900;

		$maxclicks       = MakeComma($maxclicks) || 1;
		$maxthreads      = MakeComma($maxthreads);
		$maxreplies      = MakeComma($maxreplies);
		$maxmems         = MakeComma($maxmems);
		$maxnewatt       = MakeComma($maxnewatt);
		$maxattdownloads = MakeComma($maxattdownloads);
		$maxmostonline   = MakeComma($maxmostonline);
		$spammers        = MakeComma($spammers);

		$ebout .= <<"EOT";
  <td class="win vtop" style="width: 14%">
   <div class="win2 smalltext center" style="padding: 5px;"><strong>$months[$month] $day, $year</strong></div>
   <table cellpadding="3" cellspacing="0" width="100%">
    <tr>
     <td class="smalltext right"><strong>$maxclicks</strong></td>
     <td class="smalltext">$var{'89'}</td>
    </tr><tr>
     <td class="smalltext right"><strong>$maxthreads</strong></td>
     <td class="smalltext">$statstxt[22]</td>
    </tr><tr>
     <td class="smalltext right"><strong>$maxreplies</strong></td>
     <td class="smalltext">$gtxt{'38'}</td>
    </tr><tr>
     <td class="smalltext right"><strong>$maxmems</strong></td>
     <td class="smalltext">$statstxt[41]</td>
    </tr><tr>
     <td class="smalltext right"><strong>$maxmostonline</strong></td>
     <td class="smalltext">$statstxt[42]</td>
    </tr>
EOT
		if($noguestp && $akismetkey ne '') {
			$ebout .= <<"EOT";
    <tr>
     <td class="smalltext right"><strong>$spammers</strong></td>
     <td class="smalltext">$statstxt[47]</td>
    </tr>
EOT
		}
		if($uallow) {
			$ebout .= <<"EOT";
    <tr>
     <td colspan="2" class="win2 smalltext center" style="padding: 3px;"><strong>$statstxt[18]</strong></td>
    </tr><tr>
     <td class="smalltext right"><strong>$maxnewatt</strong></td>
     <td class="smalltext">$statstxt[19]</td>
    </tr><tr>
     <td class="smalltext right"><strong>$maxattdownloads</strong></td>
     <td class="smalltext">$gtxt{'14'}</td>
    </tr>
EOT
		}

		$ebout .= <<"EOT";
   </table>
  </td>
EOT

		++$stats;
		if($stats == 7) { last; }
	}
	$ebout .= <<"EOT";
 </tr>
</table><br />
<table cellpadding="4" cellspacing="1" class="border" width="100%">
 <tr>
  <td class="titlebg smalltext center"><strong>$statstxt[43]</strong></td>
 </tr><tr>
  <td class="win" style="padding: 0px">
   <table cellpadding="8" cellspacing="0" width="100%">
    <tr>
     <td class="win2 center" style="width: 15%"><strong>$statstxt[44]</strong></td>
     <td class="win2 center" style="width: 17%"><strong>$var{'89'}</strong></td>
     <td class="win2 center" style="width: 17%"><strong>$statstxt[22]</strong></td>
     <td class="win2 center" style="width: 17%"><strong>$gtxt{'38'}</strong></td>
     <td class="win2 center" style="width: 17%"><strong>$statstxt[41]</strong></td>
EOT
	if($noguestp && $akismetkey ne '') { $ebout .= qq~<td class="win2 center" style="width: 17%"><strong>$statstxt[47]</strong></td>~; }
	$ebout .= "</tr>";

	foreach(@sortdate) {
		($maxclicks,$maxthreads,$maxreplies,$maxmems,$maxnewatt,$maxattdownloads,$maxmostonline,$spammers) = split(/\|/,$dateinfo{$_});
		($t,$t,$t,$t,$month,$yr,$weekday) = localtime($_);

		$cdays{$weekday} += $maxclicks;
		$tdays{$weekday} += $maxthreads;
		$rdays{$weekday} += $maxreplies;
		$mdays{$weekday} += $maxmems;
		$sdays{$weekday} += $spammers;
	}
	$days{$weekday} = MakeComma($days{$weekday});

	for($i = 0; $i < 7; ++$i) {
		$cdays{$i} = MakeComma($cdays{$i});
		$tdays{$i} = MakeComma($tdays{$i});
		$rdays{$i} = MakeComma($rdays{$i});
		$mdays{$i} = MakeComma($mdays{$i});
		$sdays{$i} = MakeComma($sdays{$i});
		$ebout .= <<"EOT";
    <tr>
     <td class="center win2">$days[$i]</td>
     <td class="center">$cdays{$i}</td>
     <td class="center">$tdays{$i}</td>
     <td class="center">$rdays{$i}</td>
     <td class="center">$mdays{$i}</td>
EOT
		if($noguestp && $akismetkey ne '') { $ebout .= qq~<td class="center">$sdays{$i}</td>~; }
		$ebout .= "</tr>";
	}

	$ebout .= <<"EOT";
   </table>
  </td>
 </tr>
</table><br />

<script src="$bdocsdir/common.js" type="text/javascript"></script>

<table cellpadding="4" cellspacing="1" class="border" width="100%">
 <tr>
  <td class="titlebg smalltext center"><strong>$statstxt[48]</strong></td>
 </tr><tr>
  <td class="win3 smalltext center" style="padding: 8px"><a href="#" onclick="javascript:GetTheData('clicks'); return false;">$statstxt[50]</a> | <a href="#" onclick="javascript:GetTheData('threads'); return false;">$statstxt[51]</a> | <a href="#" onclick="javascript:GetTheData('replies'); return false;">$statstxt[52]</a> | <a href="#" onclick="javascript:GetTheData('members'); return false;">$statstxt[53]</a> | <a href="#" onclick="javascript:GetTheData('spam'); return false;">$statstxt[47]</a></td>
 </tr><tr>
  <td class="win center vtop" id="statscheck" style="height: 320px">$statstxt[49]</td>
 </tr>
</table>
<script type="text/javascript">
//<![CDATA[
function GetTheData(thevalue) {
 EditMessage('$surl\v-stats/a-'+thevalue+'/','','','statscheck');
}

GetTheData('clicks');
//]]>
</script>
EOT
	footer();
	exit;
}

sub MonthlyStats {
	($t,$t,$t,$day,$month,$year) = localtime(time);
	$tempper = $day.$month.$year;
	$globyr = $year;

	fopen(DATABASE,"$prefs/BHits/quickdb.txt");
	@hits = <DATABASE>;
	fclose(DATABASE);
	chomp @hits;

	fopen(FILE2,"$prefs/BHits/$tempper.txt");
	@junk2 = <FILE2>;
	fclose(FILE2);
	chomp @junk2;

	push(@hits,"|$junk2[0]|$junk2[1]|$junk2[2]|$junk2[3]|$junk2[4]|$junk2[5]|$junk2[6]|$junk2[7]|$junk2[8]");

	@hits = sort {$a <=> $b} @hits;

	$tempyeard = 105;
	foreach(@hits) {
		($t,$maxclicks,$maxthreads,$maxreplies,$maxmems,$t,$t,$datetime,$t,$spammers) = split(/\|/,$_);
		($t,$t,$t,$t,$month,$yr) = localtime($datetime);

		if($yr < 101) { next; } # E-Blah wasn't around until 102 ...
		if(!$tempyearl) { $tempyearl = $yr; }
		if($tempyeard > $yr) { $tempyeard = $yr; }
		$clicks{$month,$yr} += $maxclicks;
		$threads{$month,$yr} += $maxthreads;
		$replies{$month,$yr} += $maxreplies;
		$members{$month,$yr} += $maxmems;
		$spam{$month,$yr} += $spammers;
	}
	if(!$tempyearl) { $tempyearl = $globyr; }

	if($URL{'a'} eq 'clicks' || $URL{'a'} eq 'threads' || $URL{'a'} eq 'replies' || $URL{'a'} eq 'members' || $URL{'a'} eq 'spam') { $type = $URL{'a'}; }
		else { $type = 'clicks'; }

	$document = "Content-type: text/html\n\n";
	$document .= <<"EOT";
<table cellpadding="4" cellspacing="0" width="100%">
 <tr>
  <td class="win2 center"><strong>$statstxt[45]</strong></td>
  <td class="win2 center"><strong>$months[0]</strong></td>
  <td class="win2 center"><strong>$months[1]</strong></td>
  <td class="win2 center"><strong>$months[2]</strong></td>
  <td class="win2 center"><strong>$months[3]</strong></td>
  <td class="win2 center"><strong>$months[4]</strong></td>
  <td class="win2 center"><strong>$months[5]</strong></td>
  <td class="win2 center"><strong>$months[6]</strong></td>
  <td class="win2 center"><strong>$months[7]</strong></td>
  <td class="win2 center"><strong>$months[8]</strong></td>
  <td class="win2 center"><strong>$months[9]</strong></td>
  <td class="win2 center"><strong>$months[10]</strong></td>
  <td class="win2 center"><strong>$months[11]</strong></td>
 </tr>
EOT
	for($y = $tempyeard; $y <= $tempyearl; ++$y) {
		$document .= qq~<tr><td style="width: 7.5%" class="win2 center">~.(1900+$y)."</td>";
		for($x = 0; $x < 12; ++$x) {
			$year = $y-100;
			push(@statsmonths, "$smonths[$x] 0$year");
			push(@stats, "${$type}{$x,$y}|$smonths[$x] 0$year");
			${$type}{$x,$y} = MakeComma(${$type}{$x,$y});
			if(${$type}{$x,$y} == 0) { ${$type}{$x,$y} = '-'; }
			$document .= qq~<td class="center">${$type}{$x,$y}</td>~;
		}
		$document .= "</tr>";
	}

	$x = $counter ='';
	foreach(reverse @stats) {
		($stat,$monthyr) = split(/\|/,$_);
		if($stat eq '' && $x eq '') { next; }
			else { $x = $stat; }
		if($maxmonth < $stat) { $maxmonth = $stat; }
		push(@stats2,$stat);

		push(@yrstats,$monthyr);
		if($x == 24) { last; }
		++$counter;
		if($counter >= 18) { last; }
	}

	$yr = 106;

	if($maxmonth > 0) {
		foreach(reverse @yrstats) { $stats .= "$_|"; }
		foreach(reverse @stats2) { $stats2 .= int(($_/$maxmonth)*100).','; }
		$stats =~ s/\|\Z//g;
		$stats2 =~ s/,\Z//g;
		$image = qq~<img src="http://chart.apis.google.com/chart?chxt=x,y&chxl=0:|$stats|1:|0|~.int($maxmonth/4).'|'.int($maxmonth/3).'|'.int($maxmonth/2).qq~|$maxmonth&cht=bvs&chd=t:$stats2&chco=76A4FB&chbh=25,20&chs=875x300&chf=a,s,c0c0c0" alt="" />~;
	}

	$document .= qq~<tr><td class="win3 center vtop">$statstxt[54]</td><td colspan="12">$image</td></tr>~;

	$document .= "</table>";

	print $document; exit;
}

sub GetSize { # Gets the database size
	foreach( split(/\|/,$_[0]) ) {
		($directory,$ess) = split(/\>/,$_);
		if($directory eq '') { next; }
		opendir(DIR,"$directory/");
		my @tlist = readdir(DIR);
		closedir(DIR);
		foreach(@tlist) {
			$size{$directory} += -s("$directory/$_");
		}

		$totalsize += $size{$directory};
		if($ess) { $size{'CORE'} += $size{$directory}; } else { $size{'NOESS'} += $size{$directory}; }
		$size{$directory} = FormatSize($size{$directory});
	}
	$size{'CORE'}  = FormatSize($size{'CORE'});
	$size{'NOESS'} = FormatSize($size{'NOESS'});
}

sub FormatSize {
	my $t = $_[0];
	my $type,$bytes;

	$bytes = $t;
	$t = sprintf("%.2f",$t/1024);
	$type = "KB";
	if($t > 1000) { $t = sprintf("%.2f",$t/1024); $type = "MB"; }

	return("$t $type (".MakeComma($bytes)." bytes)");
}

sub BoardStats {
	foreach(@boardbase) {
		($board,$t,$t,$bname,$t,$t,$t,$apwbrd) = split("/",$_);
		if(!$boardallow{$board}) { next; }
		fopen(FILE,"$boards/$board.ino");
		@ino = <FILE>;
		fclose(FILE);
		if(!$ino[1]) { $ino[1] = 0; }
		push(@tbds,"$ino[1]|$bname|$board");
		chomp @ino;
		$threads    += $ino[0];
		$messagecnt += $ino[1];
	}
	$catcnt = $catcounter;
	$bdscnt = $boardcounter;
}

sub WhereIs {
	my(@activeness);

	if(!$whereis) { is_admin(6.3); }
	$title = $whereistxt[1];
	header();
	$ebout .= <<"EOT";
<table class="border" cellpadding="6" cellspacing="1" width="750">
 <tr>
  <td class="titlebg" colspan="4"><strong>$title</strong></td>
 </tr><tr>
  <td class="catbg center center" style="width: 30px"><img src="$images/pm2_sm.gif" title="$whereistxt[2]" alt="" /></td>
  <td class="catbg center" style="width: 170px"><strong>$whereistxt[3]</strong></td>
  <td class="catbg smalltext center" style="width: 175px"><strong>$whereistxt[4]</strong></td>
  <td class="catbg center" style="width: 375px"><strong>$gtxt{'15'}</strong></td>
 </tr>
EOT
	fopen(FILE,"$prefs/Active.txt");
	@activeness = <FILE>;
	fclose(FILE);
	chomp @activeness;

	foreach(reverse @activeness) {
		$member = 3;

		($luser,$ldate,$lvis,$oboard,$viewid) = split(/\|/,$_);
		GetMemberID($luser,'force');
		if($memberid{$luser}{'sn'}) { $member = 1; ++$monline; }
		elsif($botsearch{$luser} ne '') { $member = 2; ++$bonline; }
			else { ++$gonline; }
		push(@active,"$member|$ldate|$luser|$lvis|$oboard|$viewid");
	}

	@active = sort {$a <=> $b} @active;

	foreach(@active) {
		($usertype,$ldate,$luser,$lvis,$oboard,$viewid) = split(/\|/,$_);
		$pm = '';

		if($usertype != $changetype) {
			$ebout .= qq~<tr><td class="win3 smalltext" colspan="4"><strong>$whereistxt[39] ~;
			if($usertype == 1) { $ebout .= "$monline $whereistxt[40]"; }
			if($usertype == 2) { $ebout .= "$bonline $statstxt[57]"; }
			if($usertype == 3) { $ebout .= "$gonline $whereistxt[41]"; }
			$ebout .= "</strong></td></tr>";
			$changetype = $usertype;
		}

		if($usertype == 3) { $viewuser = $gtxt{'0'}; }
		elsif($botsearch{$luser} ne '') { $viewuser = qq~<span class="onlinebots">$botsearch{$luser}</span>~; }
		elsif($memberid{$luser}{'sn'} eq '') { $viewuser = $luser; }
			else { $viewuser = $userurl{$luser}; }

		if($usertype == 3 && $members{'Administrator',$username}) { $viewuser = $luser; }

		$lastact = get_date($ldate);
		$a = 1;

		Map();

		if($memberid{$luser}{'sn'} ne '' && (($username ne 'Guest' && !$memberid{$luser}{'hideonline'}) || $members{'Administrator',$username})) { $pm = qq~<a href="$surl\lv-memberpanel/a-pm/s-write/t-$luser/" rel="nofollow" title="$whereistxt[7] $whereistxt[2]"><img src="$images/pm2_sm.gif" alt="" /></a>~; }
		if($a) { $curaction = qq~<a href="$surl\lv-$lvis/">$curaction</a>~; }
		if($memberid{$luser}{'hideonline'} && !$members{'Administrator',$username}) { $viewuser = $gtxt{'1'}; }

		$ebout .= <<"EOT";
 <tr>
  <td class="win center center" style="width: 30px">$pm</td>
  <td class="win2 center">$viewuser</td>
  <td class="win smalltext center">$lastact</td>
  <td class="win2">$curaction</td>
 </tr>
EOT
	}

	$ebout .= "</table>";
	footer();
	exit;
}

sub Map {
	if($lvis eq 'stats' && $URL{'a'} eq 'whereis') { $curaction = $whereistxt[8]; $a = 0; }
	elsif($lvis eq 'mindex') { $curaction = $whereistxt[10]; BoardLoad(); $a = 0; }
	elsif($lvis eq 'post') { $curaction = $whereistxt[11]; if($viewid eq '') { BoardLoad(); } else { MessageLoad(); } $a = 0; }
	elsif($lvis eq 'admin') { $curaction = $whereistxt[13]; }
	elsif($lvis eq 'login') { $curaction = $whereistxt[14]; if($username ne 'Guest') { $a = 0; } }
	elsif($lvis eq 'mod') { $curaction = $whereistxt[15]; $a = 0; }
	elsif($lvis eq 'register') { $curaction = $whereistxt[16]; if($username ne 'Guest') { $a = 0; } }
	elsif($lvis eq 'print') { $curaction = $whereistxt[17]; $a = 0; }
	elsif($lvis eq 'members') { $curaction = $whereistxt[18]; }
	elsif($lvis eq 'report') { $curaction = $whereistxt[19]; $a = 0; }
	elsif($lvis eq 'cal') { $curaction = $whereistxt[20]; }
	elsif($lvis eq 'download') { $curaction = $whereistxt[21]; $a = 0; }
	elsif($lvis eq 'stats') { $curaction = $whereistxt[22]; $a = 0; }
	elsif($lvis eq 'search') { $curaction = $whereistxt[23]; }
	elsif($lvis eq 'memberpanel') { $curaction = $whereistxt[2]; if($username eq 'Guest') { $a = 0; } }
	elsif($lvis eq 'shownews') { $curaction = $whereistxt[38]; $a = 0; }
	elsif($oboard ne '' && $viewid ne '') { $curaction = $whereistxt[9]; MessageLoad(); $a = 0; }
	elsif($oboard ne '') { $curaction = $whereistxt[10]; BoardLoad(); $a = 0; }
	elsif($lvis eq '') { $curaction = $whereistxt[25]; }
		else { $curaction = $whereistxt[26]; }
}

sub MessageLoad {
	$fast = 1;
	foreach(@msearched) {
		if($_ eq $oboard) { $fast = 0; last; }
	}
	if($fast) {
		push(@msearched,"$oboard");
		if(!$boardallow{$oboard}) { return; }
		fopen(FILE,"$boards/$oboard.msg");
		while(<FILE>) {
			chomp $_;
			($id,$msub) = split(/\|/,$_);
			push(@mdata,"$id|$msub");
		}
		fclose(FILE);
	}
	foreach(@mdata) {
		($id,$msub) = split(/\|/,$_);
		if($id eq $viewid) {
			if($lvis eq 'post') { $curaction = qq~<strong>$whereistxt[27]:</strong> <a href="$surl\lm-$id/" title="$whereistxt[27] $whereistxt[29]">~.CensorList($msub)."</a>"; }
				else { $curaction = qq~<strong>$whereistxt[29]:</strong> <a href="$surl\lm-$id/" title="$whereistxt[31] $whereistxt[29]">~.CensorList($msub)."</a>"; }
			last;
		}
	}
}

sub BoardLoad {
	foreach(@boardbase) {
		($id,$t,$t,$bname) = split("/",$_);
		if(!$boardallow{$id}) { return; }
		if($id eq $oboard) {
			if($lvis eq 'post') { $curaction = qq~<strong>$whereistxt[11] $whereistxt[34]:</strong> <a href="$surl\lb-$oboard/" title="$whereistxt[11] $whereistxt[34] $bname">$bname</a>~; }
				else { $curaction = qq~<strong>$whereistxt[37]:</strong> <a href="$surl\lb-$oboard/" title="$whereistxt[10]">$bname</a>~; }
			last;
		}
	}
}
1;