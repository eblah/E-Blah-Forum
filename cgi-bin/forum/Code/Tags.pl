#############################################
# E-Blah Bulletin Board Systems        2008 #
#############################################
# Copyright (c) 2001 - 2008 E-Blah.         #
#############################################

CoreLoad('Tags',1);

use Storable;
eval { %taghash = %{ retrieve("$prefs/Tags.txt") }; };

sub Tags {
	my($name,$value,$indtags,%tagcount,@taglist,@taglistsort,$totaltags,$tag);

	if($URL{'find'} || $URL{'search'}) { SearchTags(); }

	if($URL{'v'} ne 'search') {
		$title = $tagtxt[1];
		header();
	}

	while(($t,$value) = each(%taghash)) {
		foreach $indtags (split(/, ?/,$value)) {
			push(@taglist,$indtags) if(!$tagcount{$indtags});
			++$tagcount{$indtags};
			++$totaltags;
		}
	}

	foreach(@taglist) { push(@taglistsort,"$tagcount{$_}|$_"); }

	$totaltags = 1 if($totaltags == 0);

	$ebout .= <<"EOT";
<table cellpadding="5" cellspacing="1" class="border" width="100%">
 <tr>
  <td class="titlebg"><span style="float: left"><strong><img src="$images/tag.png" alt="" class="centerimg" /> $tagtxt[1]</strong></span><span class="smalltext" style="float: right">$tagtxt[2]</span></td>
 </tr><tr>
  <td class="win" style="padding: 0">
   <div style="padding: 15px; text-align: center">
EOT

	@taglist = ();

	foreach(sort {$b <=> $a} @taglistsort) {
		($count,$tag) = split(/\|/,$_);
		push(@taglist,"$tag|$count");
		++$counting;
		if($counting > 100) { last; }
	}

	foreach(sort {$a cmp $b} @taglist) {
		($tag,$count) = split(/\|/,$_);
		$enc = urlencode($tag);
		$enc =~ s/\%20/\+/g;
		$enc =~ s/\%2D/\*/g;
		$tag = CensorList($tag);

		if(($count/$totaltags) <= 1 && ($count/$totaltags) > .8) { $level = "5"; }
		elsif(($count/$totaltags) <= .8 && ($count/$totaltags) > .6) { $level = "4"; }
		elsif(($count/$totaltags) <= .6 && ($count/$totaltags) > .4) { $level = "3"; }
		elsif(($count/$totaltags) <= .4 && ($count/$totaltags) > .2) { $level = "2"; }
		elsif(($count/$totaltags) <= .2 && ($count/$totaltags) > 0) { $level = "1"; }

		$ebout .= <<"EOT";
    <a href="$surl\lv-tags/find-$enc/" class="tag$level">$tag</a> &nbsp; 
EOT
	}

	$ebout .= <<"EOT";
   </div>
   <form action="$surl\lv-tags/search-find/" method="post">
   <div class="win3" style="padding: 10px"><strong>$tagtxt[3]:</strong> <input type="text" name="search" size="40" value="" /> <input type="submit" value="$tagtxt[4]" /></div>
   </form>
  </td>
 </tr>
</table>
EOT

	if($URL{'v'} ne 'search') {
		footer();
		exit;
	}
}

sub SearchTags {
	my(@taglist,$tagfind,$messid,$value,%taglist,$read,%taginmess,$boardid,@boardlist,%boardneeded,$messtitle,$posted,$t,$replies,$micon,$date,$lastuser,%boardname,$name);

	$tagfind = $URL{'find'};
	$tagfind =~ s/\+/ /g;
	$tagfind =~ s/\*/\-/g;
	$tagfind = urldecode($tagfind);

	if($URL{'search'} ne '') { $tagfind = $FORM{'search'}; }

	$found = 0;
	while(($messid,$value) = each(%taghash)) {
		foreach(split(',',$value)) {
			if($_ eq $tagfind) { $taginmess{$messid} = 1; $found = 1; }
		}
	}

	error($tagtxt[5]) if(!$found);

	if($URL{'search'} ne '') {
		$enc = urlencode($FORM{'search'});
		$enc =~ s/\%20/\+/g;
		$enc =~ s/\%2D/\*/g;
		redirect("$surl\lv-tags/find-$enc/");
	}

	VerifyBoard();

	fopen(FILE,"$boards/Messages.db");
	while($read = <FILE>) {
		chomp $read;
		($messid,$boardid) = split(/\|/,$read);

		if($taginmess{$messid} && $boardallow{$boardid} && $readallow{$boardid}) {
			push(@boardlist,"$boardid") if(!$boardneeded{$boardid});
			$boardneeded{$boardid} = 1;
			$taglist{$messid} = 1;
		}
	}
	fclose(FILE);

	foreach(@boardbase) {
		($boardid,$t,$t,$name) = split("/",$_);
		$boardname{$boardid} = $name;
	}

	foreach $boardid (@boardlist) {
		fopen(FILE,"$boards/$boardid.msg");
		while($read = <FILE>) {
			chomp $read;
			($messid,$messtitle,$posted,$t,$replies,$poll,$type,$micon,$date,$lastuser) = split(/\|/,$read);
			if($taglist{$messid}) {
				push(@taglist,"$date|$messid|$messtitle|$posted|$replies|$poll|$type|$micon|$lastuser|$boardid");
			}
		}
		fclose(FILE);
	}

	$tagsperpage = 10;
	$link = "$surl\lv-tags/find-$URL{'find'}/s";

	# How many page links?
	$tmax = $totalpp*20;
	$treplies = @taglist < 0 ? 1 : @taglist-1;
	$totalpages = int(($treplies/$tagsperpage)+.99) || 1;
	if($treplies < $tagsperpage) { $URL{'s'} = 0; }
	$tstart = $URL{'s'} || 0;
	$counter = 1;
	if($tstart > $treplies) { $tstart = $treplies; }
	$tstart = (int($tstart/$tagsperpage)*$tagsperpage);
	if($tstart > 0) { $bk = ($tstart-$tagsperpage); $pagelinks = qq~<a href="$link-$bk/">&#171;</a> ~; }
	if($treplies > ($tmax/2) && $tstart > $tagsperpage*((($totalpp*2)/5)+1) && $treplies > $tmax) { $pagelinks .= qq~<a href="$link-0/">...</a> ~; }
	for($i = 0; $i < $treplies+1; $i += $tagsperpage) {
		if($i < $bk-($tagsperpage*(($totalpp*2)/5)) && $treplies > $tmax) { ++$counter; $final = $counter-1; next; }
		if($URL{'s'} ne 'all' && $i == $tstart || $treplies < $tagsperpage) { $pagelinks .= qq~<strong>$counter</strong> ~; $nxt = ($tstart+$tagsperpage); }
			else { $pagelinks .= qq~<a href="$link-$i/">$counter</a> ~; }
		++$counter;
		if($counter > $totalpp+$final && $treplies > $tmax) { $gbk = (int($treplies/$tagsperpage)*$tagsperpage); $pagelinks .= qq~ <a href="$link-$gbk/">...</a> ~; ++$i; last; }
	}
	if(($tstart+$tagsperpage) != $i && $URL{'s'} ne 'all') { $pagelinks .= qq~ <a href="$link-$nxt/">&#187;</a>~; }

	$title = "$tagtxt[6] $tagfind";
	header();

	$ebout .= <<"EOT";
<table cellpadding="5" cellspacing="1" class="border" width="100%">
 <tr>
  <td colspan="5" class="titlebg"><strong><img src="$images/tag.png" alt="" class="centerimg" /> $tagtxt[6] <i>$tagfind</i></strong></td>
 </tr><tr>
  <td colspan="2" class="catbg">$tagtxt[7]</td>
  <td class="catbg smalltext center"><strong>$tagtxt[8]</strong></td>
  <td class="catbg">$tagtxt[10]</td>
  <td class="catbg">$tagtxt[11]</td>
 </tr>
EOT

	if($username ne 'Guest') {
		fopen(FILE,"$members/$username.log");
		@log = <FILE>;
		fclose(FILE);
		chomp @log;
	}

	$counter = 0;
	foreach(sort {$b <=> $a} @taglist) {
		++$counter;
		if($counter < $tstart) { next; }
		if($counter >= ($tstart+$tagsperpage)) { last; }

		($date,$messid,$messtitle,$posted,$replies,$poll,$type,$micon,$lastuser,$boardid) = split(/\|/,$_);

		if($username ne 'Guest') {
			$new = '';
			$isnew = 0;
			foreach $logged (@log) {
				($mbah,$lmtime) = split(/\|/,$logged);
				if($mbah eq "AllRead_$boardid" || $mbah eq $messid) {
					$isnew = $lmtime-$date;
					last;
				}
			}
			if($isnew <= 0) { $new = qq~<img src="$images/new.png" style="margin: 0 3px 0 3px;" alt="" /> ~; $snew = 's-new/'; }
				else { $snew = ''; }
		}

		$status = FindStatus($date);
		GetMemberID($lastuser);
		GetMemberID($posted);
		if($lastuser eq '') { $lastuser = $posted; }
			else { $lastuser = $memberid{$lastuser}{'sn'} ne '' ? $userurl{$lastuser} : $lastuser; }
		$messtitle = CensorList($messtitle);
		$date = get_date($date);

		$icon = '';
		if($micon ne 'xx.gif' && $micon ne 'xx.png') { $icon = qq~<td style="width: 20px" class="center"><img src="$images/icons/$micon" alt="" />&nbsp;</td>~; }

		$ebout .= <<"EOT";
 <tr>
  <td class="win3"><div style="padding: 11px; padding-top: 4px;"><img src="$images/$status.png" alt="" /></div></td>
  <td class="win" style="width: 40%">$new<a href="$surl\lm-$messid/$snew" title="$gtxt{'19'} $memberid{$posted}{'sn'}">$messtitle</a></td>
  <td class="win2 smalltext center" style="width: 5%">$replies</td>
  <td class="win2" style="width: 25%">
   <table width="100%">
    <tr>
     <td class="smalltext">
      <div class="milastaction">$tagtxt[12] $lastuser</div><div class="midate">$date</div>
     </td>$icon
    </tr>
   </table>
  </td>
  <td class="win3" style="width: 30%"><a href="$surl\lb-$boardid/">$boardname{$boardid}</a></td>
 </tr>
EOT
	}

	$ebout .= <<"EOT";
 <tr>
  <td colspan="5" class="catbg"><div class="pages">$totalpages $gtxt{'45'} $pagelinks</div></td>
 </tr>
</table>
EOT

	footer();
	exit;
}

sub RebuildTags {
	is_admin(5.4);
	error($tagtxt[13]) if(!$tagsenable);

	my($posttags,$messid,%tagincluded,$tagid);

	%taghash = ();

	opendir(DIR,"$messages/");
	@dir = readdir(DIR);
	closedir(DIR);

	foreach(@dir) {
		if($_ =~ /(.*?).tags\Z/) {
			$messid = $1;
			$posttags = ''; %tagincluded = ();

			fopen(TAG,"$messages/$_");
			@tags = <TAG>;
			fclose(TAG);
			chomp @tags;

			foreach $tagid (split(/, ?/,$tags[0])) {
				if($tagincluded{$tagid}) { next; }
				$posttags .= $tagid.',';
				$tagincluded{$tagid} = 1;
			}
			$posttags =~ s/,\Z//g;

			$taghash{$messid} = $posttags;
		}
	}

	store(\%taghash,"$prefs/Tags.txt");

	redirect("$surl\lv-admin/r-3/");
}

sub RemoveTags {
	my($posttime) = $_[0];

	delete $taghash{$posttime};

	store(\%taghash,"$prefs/Tags.txt");
}

sub AddTags {
	my($posttime,$posttags,%tagincluded) = @_;
	my($posttags2);

	foreach(split(/, ?/,$posttags)) {
		if($tagincluded{$_}) { next; }
		$posttags2 .= $_.',';
		$tagincluded{$_} = 1;
	}
	$posttags2 =~ s/,\Z//g;

	$taghash{$posttime} = $posttags2;

	store(\%taghash,"$prefs/Tags.txt");
}
1;