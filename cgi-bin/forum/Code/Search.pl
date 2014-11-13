#############################################
# E-Blah Bulletin Board Systems        2008 #
#############################################
# Copyright (c) 2001 - 2008 E-Blah.         #
#############################################

CoreLoad('Search',1);

$maxmesscanfind = 300; # Change this to the MAX number of SAVED results.

sub Search {
	my($cnter,$searchID,$file,$counter);
	is_member() if(!$gsearch);

	# Find where we should go:
	if($URL{'p'} ne '') { Results(); }

	$title = $searchtxt[2];
	header();
	$ebout .= <<"EOT";
<script type="text/javascript">
//<![CDATA[
function Submit() { document.forms['search'].submit.disabled = true; }
//]]>
</script>
<form action="$surl\lv-search/p-2/" method="post" enctype="multipart/form-data" id="search" onsubmit="Submit()">
<table cellpadding="5" cellspacing="1" width="100%" class="border">
 <tr>
  <td class="titlebg"><img src="$images/search.png" style="vertical-align: middle" alt="" /> <strong>$title</strong></td>
 </tr><tr> 
  <td class="catbg smalltext"><strong>$searchtxt[35]</strong></td>
 </tr><tr>
  <td class="win" style="padding: 0px">
   <table cellpadding="8" cellspacing="0" width="100%">
    <tr>
     <td class="win2" style="width: 50%"><strong>$searchtxt[48]</strong></td>
     <td class="win2" style="width: 50%">$searchtxt[49]</td>
    </tr><tr>
     <td><input type="text" name="searchstring" size="35" /></td>
     <td><input type="text" name="searchuser" size="30" /></td>
    </tr><tr>
     <td>$searchtxt[71] <select name="individualwords"><option value="0">$searchtxt[72]</option><option value="1">$searchtxt[73]</option><option value="2">$searchtxt[74]</option></select></td>
     <td><input type="checkbox" name="searchmtype" value="1" /> $searchtxt[67]</td>
    </tr>
EOT
	if($members{'Administrator',$username}) {
		$ebout .= <<"EOT";
    <tr>
     <td colspan="2" class="win2"><strong>$searchtxt[55]</strong></td>
    </tr><tr>
     <td colspan="2"><input type="text" name="searchip" size="20" maxlength="15" /> &nbsp; $searchtxt[66]</td>
    </tr>
EOT
	}
	$ebout .= <<"EOT";
   </table>
  </td>
 </tr><tr> 
  <td class="catbg smalltext"><strong>$searchtxt[56]</strong></td>
 </tr><tr>
  <td class="win" style="padding: 0px">
   <table cellpadding="8" cellspacing="0" width="100%">
    <tr>
     <td class="win2" style="width: 50%"><strong>$searchtxt[57]</strong></td>
     <td class="win2" style="width: 50%"><strong>$searchtxt[58]</strong></td>
    </tr><tr>
     <td>$searchtxt[59] <input type="text" name="searchdate" value="90" size="4" maxlength="4" /> $searchtxt[60] <select name="searcholder"><option value="0">$searchtxt[40]</option><option value="1" selected="selected">$searchtxt[41]</option></select></td>
     <td><select name="searchresults"><option value="5">5</option><option value="10">10</option><option value="15">15</option><option value="20" selected="selected">20</option><option value="25">25</option><option value="30">30</option></select> $searchtxt[61]</td>
    </tr><tr>
     <td colspan="2">$searchtxt[62] <select name="searchnm"><option value="1">$searchtxt[63]</option><option value="0" selected="selected">$searchtxt[64]</option></select></td>
    </tr>
   </table>
  </td>
 </tr><tr> 
  <td class="catbg smalltext"><strong>$searchtxt[65]</strong></td>
 </tr><tr> 
  <td class="win center"><br /><select size="10" style="width: 300px" name="searchboards" multiple="multiple">
EOT

	foreach(@catbase) {
		($t,$boardid,$memgrps,$t,$t,$subcats) = split(/\|/,$_);
		$catbase{$boardid} = $_;
		if(!GetMemberAccess($memgrps)) { next; }
		foreach(split(/\//,$subcats)) { $noshow{$_} = 1; }

		$cats .= "$boardid/";
	}

	foreach(@boardbase) {
		($id,$t,$t,$t,$t,$t,$t,$passed,$t,$t,$boardgood,$t,$t,$redir) = split("/",$_);
		if((!$members{'Administrator',$username}) && (!GetMemberAccess($boardgood) || $passed ne '' || $redir ne '')) { next; }
		$board{$id} = $_;
		if($URL{'b'} eq '') { $scat{$id} = ' selected="selected"'; }
	}
	if($URL{'b'} ne '') { $scat{$URL{'b'}} = ' selected="selected"'; }

	$temp = '';
	SubCatsList($cats,1);
	$ebout .= $temp;

	$ebout .= <<"EOT";
  </select><br /><br /></td>
 </tr><tr> 
  <td class="catbg center"><input type="submit" value=" $searchtxt[24] " name="submit" /></td>
 </tr>
</table>
</form>
EOT

	if($tagsenable) {
		$ebout .= "<br />";
		CoreLoad('Tags');
		Tags();
	}

	# Recent Searches ... =D
	$ebout .= <<"EOT";
<br />
<table cellpadding="0" cellspacing="1" width="100%" class="border">
 <tr>
  <td class="titlebg" style="padding: 5px;"><strong>$searchtxt[68]</strong></td>
 </tr><tr>
  <td class="win"><table cellpadding="8" cellspacing="0" width="100%">
EOT

	opendir(DIR,"$prefs/BHits");
	@list = readdir(DIR);
	closedir(DIR);

	@colors = ('win2','win');

	foreach(reverse @list) { # After 4 hours, search expires
		if($_ =~ /.search\Z/) { $file = $_; $file =~ s/.search\Z//g; } else { next; }
		$time = time;

		if($file+13900 > $time) {
			$cnter = 0;

			fopen(FILE,"$prefs/BHits/$file.search");
			while( $read = <FILE> ) {
				++$cnter;
				chomp $read;
				if($cnter == 1) { $searchID = $read; }
				elsif($cnter == 2) { $searchPOSTER = $read; }
				elsif($cnter == 6) { last; }
			}
			fclose(FILE);
			if($cnter == 5) { next; }

			if($searchID eq '||PERSONAL||') { next; }

			++$counter;
			$window = $colors[$counter % 2];

			$searchdate = get_date($file);
			if($searchPOSTER ne '' && $searchID eq '') {
				GetMemberID($searchPOSTER);
				if($memberid{$searchPOSTER}{'sn'}) { $searchPOSTER = $memberid{$searchPOSTER}{'sn'}; }
				$searchID = "<strong>$searchtxt[78]</strong> $searchPOSTER";
			}
				elsif($searchID eq '') { $searchID = "<strong>$searchtxt[79]</strong> \l$searchdate"; }

			$ebout .= <<"EOT";
<tr>
 <td class="$window" style="width: 50%"><a href="$surl\lv-search/p-2/s-$file/">$searchID</a></td>
 <td class="$window" style="width: 50%">$searchdate</td>
</tr>
EOT
		}
	}

	$ebout .= qq~<tr><td class="win2 center" style="padding: 15px; width: 100%;">$searchtxt[69]</td></tr>~ if $searchdate eq '';

	$ebout .= "</table></td></tr></table>";

	footer();
	exit;
}

sub Results { # Search Results
	if($username ne 'Guest') {
		fopen(ULOG,"$members/$username.log");
		while(<ULOG>) {
			chomp;
			($lid,$ltime) = split(/\|/,$_);
			$logged{$lid} = $ltime;
		}
		fclose(ULOG);
	}

	if($URL{'s'} eq '') {
		Clean();
		DirtySearch();
	} else { $searchtime = $URL{'s'}; }

	error($searchtxt[36]) if !-e("$prefs/BHits/$searchtime.search");
	fopen(SEARCH,"$prefs/BHits/$searchtime.search");
	@search2 = <SEARCH>;
	fclose(SEARCH);
	chomp @search2;
	if($search2[0] eq '||PERSONAL||') { $personal = 1; shift(@search2); }

	$searchterms = $search2[0];
	$searchusers = $search2[1];
	$searchnm    = $search2[3];
	$npp         = $search2[2] || 1;
	$maxrank     = $search2[4] || 1;
	shift(@search2); shift(@search2); shift(@search2); shift(@search2); shift(@search2);

	VerifyBoard();

	foreach(@search2) {
		($ptime,$board,$id,$msub,$message,$ip,$user,$count,$nosmile,$rank,$starter,$replies,$lastpost,$date) = split(/\|/,$_);
		if($boardallow{$board} && $readallow{$board}) {
			if($URL{'sort'} eq 'rank') { push(@search,"$rank|$ptime|$board|$id|$msub|$message|$ip|$user|$count|$nosmile|$starter|$replies|$lastpost|$date"); }
				else { push(@search,$_); }
		}
	}

	if($URL{'sort'} eq 'rank') {
		@search = sort {$b <=> $a} @search;
		$sorted = '/sort-rank';
		$sorter = qq~<a href="$surl\lv-search/p-2/s-$searchtime/">$searchtxt[75]</a>~;
	} else { $sorter = qq~<a href="$surl\lv-search/p-2/s-$searchtime/sort-rank/">$searchtxt[76]</a>~; }

	$title = $searchtxt[27];
	if($searchterms ne '') { $title .= " - '$searchterms'"; }
	elsif($searchusers ne '') {
		GetMemberID($searchusers);
		$searchusers = $memberid{$searchusers}{'sn'} if($memberid{$searchusers}{'sn'});
		$title .= " - $searchtxt[78] $searchusers";
	} elsif($searchterms eq '' && $searchusers eq '') {
		$searchdate = get_date($searchtime);
		if($personal) { $title .= " - New posts as of \l$searchdate"; }
			else { $title .= " - $searchtxt[79] \l$searchdate"; }
	}

	header();

	$start = $URL{'l'};
	$mresults = @search || 1;
	if($mresults < $npp) { $start = 0; }
	$tstart = $start || 0;
	$counter = 1;

	# How many page links?
	$smax = $totalpp*20;
	$startdot = ($totalpp*2)/5;

	# Create the main link ...
	$searchterms =~ s/ /\+/gsi;
	$totalpages = int(($mresults/$npp)+.99);
	if($searchterms ne '') { $hllink = "highlight-$searchterms/"; }
	$link = "$surl\lv-search/p-2/s-$searchtime$sorted/l";

	if($tstart > $mresults) { $tstart = $mresults; }
	$tstart = (int($tstart/$npp)*$npp);
	if($tstart > 0) { $bk = ($tstart-$npp); $pagelinks = qq~<a href="$link-$bk/">&#171;</a> ~; }
	if($mresults > ($smax/2) && $tstart > $npp*($startdot+1) && $mresults > $smax) {
		$sbk = $tstart-$smax; $sbk = 0 if($sbk < 0); $pagelinks .= qq~<a href="$link-$sbk/">...</a> ~;
	}
	for($i = 0; $i < $mresults; $i += $npp) {
		if($i < $bk-($npp*$startdot) && $mresults > $smax) { ++$counter; $final = $counter-1; next; }
		if($start ne 'all' && $i == $tstart || $mresults < $npp) { $pagelinks .= qq~<strong>$counter</strong> ~; $nxt = ($tstart+$npp); }
			else { $pagelinks .= qq~<a href="$link-$i/">$counter</a> ~; }
		++$counter;
		if($counter > $totalpp+$final && $mresults > $smax) { $gbk = $tstart+$smax; if($gbk > $mresults) { $gbk = (int($mresults/$npp)*$npp); } $pagelinks .= qq~ <a href="$link-$gbk/">...</a> ~; ++$i; last; }
	}
	if($counter > 2) { $pgs = 's'; }
	if(($tstart+$npp) != $i && $start ne 'all') { $pagelinks .= qq~ <a href="$link-$nxt/">&#187;</a>~; }

	if($tstart+$npp > $mresults) { $endmenow = $mresults; } else { $endmenow = ($tstart+$npp); }

	$onpage = ($tstart+1).' - '.$endmenow;

	$mresults = 0 if($search[0] eq '');

	$ebout .= <<"EOT";
<script src="$bdocsdir/common.js" type="text/javascript"></script>

<table cellpadding="5" cellspacing="1" class="border" width="100%">
 <tr>
  <td colspan="4" style="padding: 7px;" class="titlebg"><div style="float: left"><img src="$images/search.png" style="vertical-align: middle" alt="" /> <strong>$title</strong></div><div style="float: right">$sorter</div></td>
 </tr><tr>
  <td colspan="4" class="win3" style="padding: 10px;">
   <div style="float: left" class="pages">$totalpages $gtxt{'45'} $pagelinks</div>
   <div class="smalltext" style="float: right">$searchtxt[28] $onpage ($mresults $searchtxt[29])</div>
  </td>
 </tr>
EOT
	$counter = 1;
	$counter2 = 0;
	if($search2 !~ /[#%,\\\/:?"<>'|@^\$\&~'\)\(\]\[\;{}!`=-]/) { # Highlighter
		@lights = split(/\+/,$searchterms);
	}

	$maxrank = 1 if(!$maxrank);

	if($searchnm) {
		$ebout .= <<"EOT";
 <tr>
  <td class="catbg smalltext"><strong>$searchtxt[85]</strong></td>
  <td class="catbg smalltext center" style="width: 100px"><strong>$searchtxt[84]</strong></td>
  <td class="catbg smalltext center" style="width: 150px"><strong>$searchtxt[83]</strong></td>
  <td class="catbg smalltext" style="width: 200px"><strong>$searchtxt[82]</strong></td>
 </tr>
EOT
	} else { $ebout .= "</table><br />"; }

	foreach(@search) {
		if(($counter > $tstart && $counter2 < $npp)) {
			if($URL{'sort'} eq 'rank') { ($rank,$ptime,$board,$id,$msub,$message,$ip,$user,$count,$nosmile,$starter,$replies,$lastpost,$date2,$ticon) = split(/\|/,$_); }
				else { ($ptime,$board,$id,$msub,$message,$ip,$user,$count,$nosmile,$rank,$starter,$replies,$lastpost,$date2,$ticon) = split(/\|/,$_); }
			$msub = CensorList($msub);
			if(@lights) { Highlight($msub); }

			$date = get_date($ptime);
			GetMemberID($user);
			if($memberid{$user}{'sn'}) { $user = $userurl{$user}; }

			$msub = $count > 0 ? "Re: $msub" : $msub;
			if($ipadd) { $showip = qq~<br /><strong>$gtxt{'18'}:</strong> $ip~; }

			$rank = 1 if(!$rank);
			$relevance = sprintf(" (%.2f",($rank/$maxrank)*100)."%)";

			if($ticon ne 'xx.gif') { $ticon = qq~<img src="$images/icons/$ticon" class="centerimg" alt="" />&nbsp; ~; } else { $ticon = ''; }

			if(!$searchnm) {
				# if($counter != 1) { $ebout .= qq~<tr><td colspan="4" class="win4" style="height: 5px"></td></tr>~; }
				$ebout .= <<"EOT";
<table cellpadding="5" cellspacing="1" class="border" width="100%">
 <tr>
  <td colspan="4" class="win2" style="padding: 0px">
   <table cellpadding="8" cellspacing="0" width="100%">
    <tr>
     <td style="padding-left: 10px;">$ticon<strong><a href="$surl\lm-$id/s-$count/$hllink#num$count">$msub</a></strong></td>
     <td class="right"><strong>$gtxt{'19'}:</strong> $user<br /><strong>$gtxt{'21'}:</strong> $date</td>
     <td style="width: 100px" class="center win3"><strong>$searchtxt[77]</strong><br />$rank$relevance</td>
    </tr>
   </table>
  </td>
 </tr>
EOT
				$message = BC($message);
				if(@lights) { Highlight($message); }

				$ebout .= <<"EOT";
 <tr>
  <td colspan="4" class="win smalltext" style="padding: 7px;">$message</td>
 </tr>
</table><br />
EOT
			} else {
				if(($logged{$id}-$date2) <= 0 && ($logged{"AllRead_$board"}-$date2) <= 0) { $new = qq~<div style="font-weight: bold;"><img src="$images/new.png" alt="$searchtxt[81]" style="margin: 0 3px 0 3px;" /> ~; $tempurl = "s-new/"; }
					else { $new = "<div>"; $tempurl = ''; }

				GetMemberID($starter);
				GetMemberID($lastpost);
				$date2 = get_date($date2);

				if($memberid{$starter}{'sn'}) { $starter = $userurl{$starter}; }
				if($memberid{$lastpost}{'sn'}) { $lastpost = $userurl{$lastpost}; }
				$ebout .= <<"EOT";
 <tr>
  <td class="win">$new<strong><a href="$surl\lm-$id/s-$count/$hllink$tempurl">$msub</a></strong></div></td>
  <td class="win2 smalltext center" style="width: 100px">$replies</td>
  <td class="win center" style="width: 150px">$starter</td>
  <td class="win smalltext" style="width: 200px">$date2<br /><strong>$searchtxt[80]:</strong> $lastpost</td>
 </tr>
EOT
			}

			++$counter2;
		}
		++$counter;
	}

	if($search[0] eq '') {
		if(!$searchnm) { $ebout .= qq~<table cellpadding="5" cellspacing="1" class="border" width="100%">~; }
		$ebout .= <<"EOT";
 <tr>
  <td colspan="4" class="win center" style="padding: 15px">$searchtxt[32]</td>
 </tr>
EOT
		if(!$searchnm) { $ebout .= qq~</table><br />~; }
	}

	if(!$searchnm) { $ebout .= qq~<table cellpadding="5" cellspacing="1" class="border" width="100%">~; }

	$ebout .= <<"EOT";
 <tr>
  <td colspan="4" class="win3" style="padding: 10px;">
   <div style="float: left" class="pages">$totalpages $gtxt{'45'} $pagelinks</div>
   <div class="smalltext" style="float: right">$searchtxt[28] $onpage ($mresults $searchtxt[29])</div>
  </td>
 </tr>
</table>
EOT
	footer();
	exit;
}

sub DirtySearch { # We need to create a Search ID for use =( ... !=D!
	# Create Variables, first:
	if($URL{'p'} eq 'topten') { # Topten
		$searchmaxresults = 100;
		$searchresults    = 30;
		$searchnm         = 0;
	} elsif($URL{'p'} eq 'newposts') { # New Posts
		is_member();
		$searchmaxresults = 100;
		$searchresults    = 30;
		$searchnm         = 1;
		if($URL{'a'} eq 'lastvisit') { $searchdate = $memberid{$username}{'lastvisit'}; $searcholder = 1; $woot = $searchdate; }
	} elsif($URL{'p'} eq 'user') { # By username
		$searchuser       = $URL{'by'} || $username;
		$searchresults    = 30;
		$searchmaxresults = 100;
		$searchnm         = 0;
	} elsif($URL{'p'} eq 'quick') {
		$searchstring  = Format($URL{'find'});
		@words = split(' ',Format($URL{'find'}));
		$searchresults = 30;
		$searchnm      = 0;
	} else { # Search using the form
		$searchstring  = Format($FORM{'searchstring'});
		$searchuser    = FindUsername($FORM{'searchuser'}) || $FORM{'searchuser'} if($FORM{'searchuser'} ne '');
		$individualwords = Format($FORM{'individualwords'});

		if($members{'Administrator',$username}) { $searchip = $FORM{'searchip'}; }

		@words = split(' ',Format($FORM{'searchstring'}));

		if($individualwords) {
			foreach(@words) { $wordlength = 1 if(length($_) < 3); }
		} else { $wordlength = 1 if(length($searchstring) < 3 || !@words); }

		if(@words == 1 && $individualwords) { $individualwords = 2; }

		error($searchtxt[4]) if($wordlength && $searchuser eq '' && $searchip eq '');

		$searchmtype   = $FORM{'searchmtype'};
		$searcholder   = $FORM{'searcholder'};
		$searchnm      = $FORM{'searchnm'};
		$searchresults = $FORM{'searchresults'} || 20;
		$searchdate    = time-($FORM{'searchdate'}*86400);

		foreach $selbrd (split(",",$FORM{'searchboards'})) { $searchboards{$selbrd} = 1; }
	}

	# Find boards to search this go around =)
	foreach(@catbase) {
		($t,$t,$memgrps,$thelist,$t,$subcats) = split(/\|/,$_);
		GetMemberAccess($memgrps) || next;
		foreach( split(/\//,$thelist) ) { $goodboard{$_} = 1; }
	}

	foreach(@boardbase) {
		($id,$t,$t,$t,$t,$t,$t,$passed,$t,$t,$boardgood) = split("/",$_);
		next if !$goodboard{$id} || $passed ne '';
		GetMemberAccess($boardgood) || next;
		if($FORM{'searchboards'} ne '' && !$searchboards{$id}) { next; }
		push(@searchboards,$id);
	}

	# It's search time!
	$searchtime = time;
	foreach $board (@searchboards) {
		$deeplvl = 0;
		fopen(MSGDB,"$boards/$board.msg");
		while( $msgdb = <MSGDB> ) {
			chomp $msgdb;
			($id,$msub,$starter,$t,$replies,$t,$t,$ticon,$date,$lastpost) = split(/\|/,$msgdb);

			($t,$testme) = split("<>",$msub);
			if($testme ne '') { next; }

			if(($URL{'p'} eq 'newposts' && $URL{'a'} eq 'lastvisit') || $URL{'p'} ne 'newposts') {
				if(($searcholder && $searchdate) && ($date-$searchdate) < 0) { next; }
				elsif((!$searcholder && $searchdate) && ($date-$searchdate) > 0) { next; }
			}

			if($URL{'p'} eq 'newposts') {
				unless(($logged{$id}-$date) <= 0 && ($logged{"AllRead_$board"}-$date) <= 0) { next; }

				push(@searchresults,"$date|$board|$id|$msub|||||||$starter|$replies|$lastpost|$date|$ticon");
				next;
			}

			if($searchmaxresults && $deeplvl > $searchmaxresults+30) { last; }

			$count = -1;
			fopen(MESSAGE,"$messages/$id.txt");
			while( $buffer = <MESSAGE> ) {
				chomp $buffer;
				($user,$message,$ip,$t,$ptime,$smiley) = split(/\|/,$buffer);
				if($searchmtype && $count == 0) { last; }
				++$count;

				if(($searcholder && $searchdate) && ($ptime-$searchdate) < 0) { next; }
				elsif((!$searcholder && $searchdate) && ($ptime-$searchdate) > 0) { next; }

				$ptime =~ s/\n//g;

				if($user eq '' || $msub eq '' || $message eq '' || $msub eq '') { next; }

				if($searchip) {
					$ipsearch = substr($ip,0, length($searchip) );
					if($ipsearch !~ /\Q$searchip/i) { next; }
				}

				if($searchuser && $searchuser ne $user) { next; }
					else { ++$deeplvl; } # Number found by user

				if(@words) {
					$next = 0;
					$dead = 0;
					if($individualwords == 1) { # All words
						foreach(@words) {
							$wdf = 0;
							while($message =~ /\Q$_\E/sig) { $wdf = 1; ++$next; }
							while($msub =~ /\Q$_\E/sig)    { $wdf = 1; ++$next; }
							if(!$next || !$wdf) { $dead = 1; last; }
						}
					} if($individualwords == 2) { # Any words
						foreach(@words) {
							while($message =~ /\Q$_\E/sig) { ++$next; }
							while($msub =~ /\Q$_\E/sig)    { ++$next; }
							$rank += $next;
						}
					} else { # Exact
						while($message =~ /\Q$searchstring\E/sig) { ++$next; }
						while($msub =~ /\Q$searchstring\E/sig)    { ++$next; }
					}
					if(!$next && $URL{'p'} ne 'topten') { next; }
						else { $rank = $next; }

					if($rank > $maxrank) { $maxrank = $rank; }
				}
				next if($dead);

				# We found one!
				push(@searchresults,"$ptime|$board|$id|$msub|$message|$ip|$user|$count|$smiley|$rank|$starter|$replies|$lastpost|$date|$ticon");
			}
			fclose(MESSAGE);
			if($URL{'p'} eq 'topten') { ++$deeplvl; }
		}
		fclose(MSGDB);
	}

	$count = 0;

	fopen(FILE,">$prefs/BHits/$searchtime.search");
	if($URL{'p'} eq 'newposts') { print FILE "||PERSONAL||\n"; }
	print FILE "$searchstring\n$searchuser\n$searchresults\n$searchnm\n$maxrank\n";
	foreach(sort{$b <=> $a} @searchresults) {
		if($maxmesscanfind < $count) { last; }
		print FILE "$_\n";
		++$count;
	}
	fclose(FILE);
}

sub Clean {
	opendir(DIR,"$prefs/BHits");
	@list = readdir(DIR);
	closedir(DIR);
	foreach(@list) { # After 2 hours, search expires
		if($_ =~ /.search\Z/) { $file = $_; $file =~ s/.search\Z//g; } else { next; }

		$time = time;
		if($file+14400 < $time) { unlink("$prefs/BHits/$_"); }
			elsif($file > $max) { $max = $file; }

		# Limit search directory to 10MBs
		$thissize = -s("$prefs/BHits/$_");
		$thissize /= 1024;
		$totalsize += $thissize;

		if($totalsize > 10000) { unlink("$prefs/BHits/$_"); }
	}
}

sub BrowserSearch {
	foreach(@boardbase) {
		($id,$t,$t,$t,$t,$t,$t,$passed,$t,$t,$boardgood,$t,$t,$redir) = split("/",$_);
		if((!$members{'Administrator',$username}) && (!GetMemberAccess($boardgood) || $passed ne '' || $redir ne '')) { next; }
		$board{$id} = 1;
	}

	foreach(@catbase) {
		($t,$boardid,$memgrps,$t,$t,$subcats) = split(/\|/,$_);
		if(!GetMemberAccess($memgrps) || !$board{$id}) { next; }
		$FORM{'searchboards'} .= "$boardid,";
	}
}
1;