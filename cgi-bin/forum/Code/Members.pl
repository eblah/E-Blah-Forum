#############################################
# E-Blah Bulletin Board Systems        2008 #
#############################################
# Copyright (c) 2001 - 2008 E-Blah.         #
#############################################

CoreLoad('Members',1);

sub JoinGroup {
	is_member();
	if($URL{'group'} eq 'Administrator') { is_admin(); }

	error($memtext[202]) if($members{$URL{'group'},$username});
	error($memtext[203]) if($permissions{$URL{'group'},'name'} eq '');
	error($memtext[204]) if(!$permissions{$URL{'group'},'accepting'});

	$newfile = '';
	foreach(@globalgroups) {
		if($_ =~ /(.+?) => {/) { $curread = $1; }
		elsif($_ eq '}') { $curread = ''; }

		if($curread eq $URL{'group'} && $_ =~ /(.+?) = \((.*?)\)/) {
			$olds = $2;
			if($1 eq 'waiting' && $permissions{$URL{'group'},'accepting'} == 1) {
				foreach $olds (split(',',$2)) {
					if($username eq $olds) { error($memtext[205]); }
				}
				if($olds ne '') { $olds .= ','; }
				$olds .= $username;
			} elsif($1 eq 'members' && $permissions{$URL{'group'},'accepting'} == 2) {
				if($olds ne '') { $olds .= ','; }
				$olds .= $username;
			}
			$newfile .= "$1 = ($olds)\n";
		} else { $newfile .= "$_\n"; }
	}
	fopen(FILE,">$prefs/Ranks2.txt");
	print FILE $newfile;
	fclose(FILE);

	if($permissions{$URL{'group'},'manager'} eq '') { $permissions{$URL{'group'},'manager'} = $permissions{'Administrator','members'}; }
	if($permissions{$URL{'group'},'accepting'} == 1) {
		if(!$pmdisable) {
			CoreLoad('PM');
			$managersend = 1; # Disables error messages
			foreach(split(',',$permissions{$URL{'group'},'manager'})) {
				GetMemberID($_);
				if($memberid{$_}{'sn'} eq '') { next; }
				PMSend2($memtext[206],"$memberid{$username}{'sn'} ($username) $memtext[207] '$permissions{$URL{'group'},'name'}' $memtext[208].\n\n[url=$rurl\lv-members/a-manage/group-$URL{'group'}/]$memtext[209]\[/url] $memtext[210]",$_);
			}
		}
	}

	$title = "$memtext[211] $permissions{$URL{'group'},'name'}";
	if($permissions{$URL{'group'},'accepting'} == 1) { $text = $memtext[212]; }
		else { $text = $memtext[213]; }
	header();
	$ebout .= <<"EOT";
<table cellpadding="5" cellspacing="1" class="border" width="500">
 <tr>
  <td class="titlebg">$title</td>
 </tr><tr>
  <td class="win2">$text</td>
 </tr><tr>
  <td class="win"><strong><a href="javascript:history.go(-1)">&#171; $gtxt{'22'}</a></strong></td>
 </tr>
</table>
EOT
	footer();
	exit;
}

sub Manage2 {
	if($URL{'group'} eq 'Administrator') { is_admin(); }
	while(($iname,$ivalue) = each(%FORM)) {
		$ivalue =~ s~\A\s+~~;
		$ivalue =~ s~\s+\Z~~;
		$ivalue =~ s~[\n\r]~~g;
		$FORM{$iname} = $ivalue;
	}

	$FORM{'waiting'} .= ",$FORM{'addmembers'}";
	$type = $FORM{'members'} || $FORM{'waiting'};

	if($URL{'r'}) {
		$FORM{'delete'} = 1;
		$type = $username;
	}

	foreach(split(',',$type)) {
		GetMemberID($_);

		if($memberid{$_}{'sn'} eq '') { $_ = FindUsername($_); GetMemberID($_); }

		if($memberid{$_}{'sn'} eq '' || ($username ne $_ && $manager{$_} && !$members{'Administrator',$username})) { next; }
		$chosen{$_} = 1;
		$addgroup .= "$_,";
	}
	$addgroup =~ s/,\Z//g;
	if($addgroup eq '' || ($FORM{'manage'} && !$members{'Administrator',$username})) { error($memtext[214]); }

	$adminoverride = 1;
	$newfile = '';
	CoreLoad('PM') if(!$pmdisable);
	$managersend = 1; # Disables error messages
	foreach(@globalgroups) {
		if($_ =~ /(.+?) => {/) { $curread = $1; }
		elsif($_ eq '}') { $curread = ''; }

		if($curread eq $URL{'group'} && $_ =~ /(.+?) = \((.*?)\)/) {
			$old = '';
			$add = '';
			$work = 0;
			if($1 eq 'manager' && ($FORM{'manage'} || $FORM{'delete'} || $FORM{'remove'})) {
				foreach $addold (split(',',$2)) {
					GetMemberID($addold);
					if($chosen{$addold} || $memberid{$addold}{'sn'} eq '') { next; }
					$old .= "$addold,";
				}

				if($FORM{'manage'}) { $add = $addgroup; }
					else { $old =~ s/,\Z//; }
				$newfile .= "manager = ($old$add)\n";
				$work = 1;
			}

			if($1 eq 'members' && ($FORM{'delete'} || $FORM{'add'})) {
				foreach $addold (split(',',$2)) {
					GetMemberID($addold);
					if($chosen{$addold} || $memberid{$addold}{'sn'} eq '') { next; }
					$old .= "$addold,";
				}
				if($FORM{'add'}) { $add = $addgroup; }
					else { $old =~ s/,\Z//; }

				if($FORM{'add'} && !$pmdisable) {
					foreach $pmsender (split(',',$add)) {
						PMSend2($memtext[215],"$memberid{$username}{'sn'} ($username) $memtext[216] '$permissions{$URL{'group'},'name'}' $memtext[208].",$pmsender);
					}
				}

				$newfile .= "members = ($old$add)\n";
				$work = 1;
			}
			if($1 eq 'waiting' && ($FORM{'deny'} || $FORM{'add'})) {
				foreach $addold (split(',',$2)) {
					GetMemberID($addold);
					if($chosen{$addold} || $memberid{$addold}{'sn'} eq '') { next; }
					$old .= "$addold,";
				}
				$old =~ s/,\Z//;

				$newfile .= "waiting = ($old)\n";
				$work = 1;
			}
			if(!$work) { $newfile .= "$_\n"; }
		} else { $newfile .= "$_\n"; }
	}

	fopen(FILE,">$prefs/Ranks2.txt");
	print FILE $newfile;
	fclose(FILE);
	$url = "$surl\lv-members/a-manage/group-$URL{'group'}/";
	if($URL{'r'}) { $url = "$surl\lv-members/a-groups/group-$URL{'group'}/"; }

	redirect();
}

sub Manage {
	is_member();
	if($URL{'group'} eq 'Administrator') { is_admin(); }

	foreach(split(',',$permissions{$URL{'group'},'manager'})) { $manager{$_} = 1; }

	if($members{$URL{'group'},$username} && $URL{'r'}) { Manage2(); }
	if(!$members{'Administrator',$username} && !$manager{$username}) { error($memtext[217]); }

	if(%FORM) { Manage2(); }
	$title = $memtext[8];
	header();
	$ebout .= <<"EOT";
<table cellpadding="4" cellspacing="1" width="500" class="border">
 <tr>
  <td class="titlebg">$title</td>
 </tr>
EOT
	if($members{'Administrator',$username}) { $adminonly = qq~ <input type="submit" name="manage" value="$memtext[218]" /><br /><br /><input type="submit" name="remove" value="$memtext[219]" />~; }
	$ebout .= <<"EOT";
 <tr>
  <td class="catbg">$memtext[220]</td>
 </tr><tr>
  <td class="win smalltext">$memtext[221]</td>
 </tr><tr>
  <td class="win2">
   <form action="$surl\lv-members/a-manage/group-$URL{'group'}/" method="post" enctype="multipart/form-data">
   <table width="100%">
    <tr>
     <td class="center"><select name="members" multiple="multiple" size="5" style="width: 250px">
EOT
	foreach(split(',',$permissions{$URL{'group'},'members'})) {
		$nonremove = '';
		GetMemberID($_);
		if($memberid{$_}{'sn'} eq '') { next; }
		if($manager{$_}) { $nonremove = " (manager)"; }
		$ebout .= qq~<option value="$_">$memberid{$_}{'sn'}$nonremove</option>~;
	}
	$ebout .= <<"EOT";
     </select><br /><br /></td>
    </tr><tr>
     <td class="center"><input type="submit" name="delete" value="$memtext[222]" />$adminonly</td>
    </tr>
   </table></form>
  </td>
 </tr><tr>
  <td class="catbg">$memtext[223]</td>
 </tr><tr>
  <td class="win smalltext">$memtext[224]</td>
 </tr><tr>
  <td class="win2">
   <form action="$surl\lv-members/a-manage/group-$URL{'group'}/" method="post" enctype="multipart/form-data">
   <table width="100%">
    <tr>
     <td class="center"><strong>$memtext[225]:</strong><br /><textarea name="addmembers" rows="1" cols="1" style="width: 250px; height: 50px"></textarea><br /><br />
EOT
	if($permissions{$URL{'group'},'waiting'} ne '') {
		$ebout .= qq~<select name="waiting" multiple="multiple" size="5" style="width: 250px">~;
		foreach(split(',',$permissions{$URL{'group'},'waiting'})) {
			GetMemberID($_);
			if($memberid{$_}{'sn'} eq '') { next; }
			$ebout .= qq~<option value="$_">$memberid{$_}{'sn'}</option>~;
		}
		$ebout .= "</select>";
	}
	$ebout .= <<"EOT";
     </td>
    </tr><tr>
     <td class="center"><input type="submit" name="deny" value="$memtext[226]" /> <input type="submit" name="add" value="$memtext[227]" /></td>
    </tr>
   </table>
   </form>
  </td>
 </tr>
</table>
EOT
	footer();
	exit;

}

sub Members {
	if($FORM{'search'} ne '') {
		$FORM{'searchuser'} = urlencode($FORM{'searchuser'});
		$FORM{'searchemail'} = urlencode($FORM{'searchemail'});

		$FORM{'search'} = "$FORM{'searchuser'}.$FORM{'searchregistered'}.$FORM{'searchreputation'}.$FORM{'searchpostslow'}.$FORM{'searchpostshigh'}.$FORM{'searchonline'}.$FORM{'searchemail'}.";
	}
	if($URL{'search'} ne '' && $FORM{'search'} eq '') {
		$FORM{'search'} = $URL{'search'};
	}
	if($FORM{'search'} ne '') {
		($FORM{'searchuser'},$FORM{'searchregistered'},$FORM{'searchreputation'},$FORM{'searchpostslow'},$FORM{'searchpostshigh'},$FORM{'searchonline'},$FORM{'searchemail'}) = split(/\./,$FORM{'search'});

		$searchuser       = lc(Format($FORM{'searchuser'}));
		$searchregistered = $FORM{'searchregistered'} if($FORM{'searchregistered'} >= 0 && $FORM{'searchregistered'} < 999999);
		$searchreputation = $FORM{'searchreputation'} if($FORM{'searchreputation'} >= 0 && $FORM{'searchreputation'} <= 100);
		$searchpostslow   = $FORM{'searchpostslow'}   if($FORM{'searchpostslow'} >= 0 && $FORM{'searchpostslow'} < 999999);
		$searchpostshigh  = $FORM{'searchpostshigh'}  if($FORM{'searchpostshigh'} >= 0 && $FORM{'searchpostshigh'} < 999999);
		$searchonline     = $FORM{'searchonline'}     if($FORM{'searchonline'} == 1);
		$searchemail      = $FORM{'searchemail'};

		# Unencode URLs
		$searchuser  = urldecode($searchuser);
		$searchemail = urldecode($searchemail);
		$searchuser  = $searchuserenc  = lc(Format($searchuser));
		$searchemail = $searchemailenc = lc(Format($searchemail));

		$searchuserenc = urlencode($searchuserenc);
		$searchemailenc = urlencode($searchemailenc);

		$searchurl = "/search-$searchuserenc.$searchregistered.$searchreputation.$searchpostslow.$searchpostshigh.$searchonline.$searchemailenc.";
	}

	GetActiveUsers();

	is_member() if(!$memguest);

	if($URL{'a'} eq 'groups' && $URL{'group'} ne '' && $permissions{$URL{'group'},'name'} eq '') { error($memtext[203]); }

	if($URL{'a'} eq 'join') { JoinGroup(); }
	elsif($URL{'a'} eq 'manage') { Manage(); }

	$a = $URL{'a'};
	fopen(FILE,"$members/List2.txt");
	while(<FILE>) {
		chomp $_;
		@data = split(/\|/,$_);

		if($FORM{'search'} ne '') {
			if($searchuser && $data[1] !~ /\Q$searchuser\E/sig) { $searchex{$data[0]} = 1; next; }
			if($searchpostshigh ne '' && $searchpostshigh < $data[2]) { $searchex{$data[0]} = 1; next; }
			if($searchpostslow ne '' && $searchpostslow > $data[2]) { $searchex{$data[0]} = 1; next; }
			if($searchregistered ne '' && ($searchregistered*86400 < time-$data[3])) { $searchex{$data[0]} = 1; next; }
			if($searchonline ne '' && !$useronline{$data[0]}) { $searchex{$data[0]} = 1; next; }
			if($searchemail && $data[5] !~ /\Q$searchemail\E/sig) { $searchex{$data[0]} = 1; next; }
			if($searchreputation ne '' && ($searchreputation > $data[6])) { $searchex{$data[0]} = 1; next; }
		}
		if($URL{'a'} eq 'groups') { next; }

		if($URL{'a'} eq '') { # Lets not load the entire database!
			next if !-e("$members/$data[0].dat");
			push(@listz,$data[0]);
		}

		push(@mlist,"$data[1]|$data[0]|$data[2]|$data[6]|$data[3]");
	}
	fclose(FILE);

	$found = 0;
	if($hideposts != 1) {
		if($a eq 'top') { $top = qq~| &nbsp;  &nbsp; </td><td class="win"><strong>&nbsp; $memtext[2] &nbsp;</strong></td><td class="smalltext">&nbsp; ~; $link = "$surl\lv-members/a-$URL{'a'}$searchurl/s"; TopPosters(); }
			else { $top = qq~| &nbsp; <a href="$surl\lv-members/a-top$searchurl/">$memtext[2]</a>~; }
	}

	if($a eq 'registered') { $registered = qq~| &nbsp;  &nbsp; </td><td class="win"><strong>&nbsp; $memtext[19] &nbsp;</strong></td><td class="smalltext">&nbsp; ~; $link = "$surl\lv-members/a-$URL{'a'}$searchurl/s"; RegDate(); }
		else { $registered = qq~| &nbsp; <a href="$surl\lv-members/a-registered$searchurl/">$memtext[19]</a>~; }

	if($a eq 'let') {
		$userletter = uc($URL{'l'});
		if($userletter && ($userletter ne 'NUM' && $userletter =~ s~([A-Z]{1})~~)) { $userletter = $1; }
		elsif($userletter && $userletter ne 'NUM') { $userletter = A; }
		$letter = <<"EOT";
 <tr>
  <td class="win" colspan="9">
   <table cellpadding="8" cellspacing="0"><tr>
   <td class="smalltext">
EOT
		for($ll = 'A'; $ll ne 'AA'; $ll++) {
			if($userletter eq $ll || ($userletter eq '' && $ll eq 'A')) { $letter .= qq~</td><td class="win2"><strong>&nbsp; $ll &nbsp;</strong></td><td class="smalltext">&nbsp; ~; }
				else { $letter .= qq~<a href="$surl\lv-members/a-$URL{'a'}$searchurl/l-$ll/">$ll</a>&nbsp; &nbsp; ~; }
		}
		if($userletter ne 'NUM') { $letter .= qq~<a href="$surl\lv-members/a-$URL{'a'}$searchurl/l-num/" title="$memtext[5]">#</a>~; }
			else { $letter .= qq~</td><td class="win2"><strong>&nbsp;#&nbsp;</strong></td><td>~; }
		$letter .= <<"EOT";
    </td>
   </tr>
  </table>
  </td>
 </tr>
EOT
		$let = qq~| &nbsp;  &nbsp; </td><td class="win"><strong>&nbsp; $memtext[6] &nbsp;</strong></td><td class="smalltext">&nbsp; ~; Letter();
		$templetter = $userletter;
		$link = "$surl\lv-members/a-$URL{'a'}$searchurl/l-$userletter/s";
	} else { $let = qq~| &nbsp; <a href="$surl\lv-members/a-let$searchurl/">$memtext[6]</a>~; }

	if($a eq 'groups') {
		push(@list2,FindRanks($URL{'group'}));

		foreach(split(",",$permissions{$URL{'group'},'manager'})) {
			$manager{$_} = 1;
			if($searchex{$_}) { next; }

			$came .= "$_\n";

			push(@listz,$_);
		}
		@listz = sort {lc($a) cmp lc($b)} @listz;
		@list2 = sort {lc($a) cmp lc($b)} @list2;

		foreach(@list2) {
			if($manager{$_}) { next; }
			if($searchex{$_}) { next; }
			$came .= "$_\n";
			push(@listz,$_);
		}

		$pro = qq~| &nbsp;  &nbsp; </td><td class="win"><strong>&nbsp; <a href="$surl\lv-members/a-groups$searchurl/">$memtext[8]</a> &nbsp;</strong></td><td class="smalltext">&nbsp; ~;
		$link = "$surl\lv-members/a-$URL{'a'}$searchurl/group-$URL{'group'}/s";
	} else { $pro = qq~| &nbsp; <a href="$surl\lv-members/a-groups$searchurl/">$memtext[8]</a>~; }

	if($enablerep) {
		if($URL{'a'} eq 'reputation') {
			foreach $temp (@mlist) {
				($t,$_,$t,$rep) = split(/\|/,$temp);
				push(@listz,"$rep|$_");
			}

			@listz = sort {$b <=> $a} @listz;

			$rep = qq~| &nbsp;  &nbsp; </td><td class="win"><strong>&nbsp; $gtxt{'rep'} &nbsp;</strong></td><td class="smalltext">&nbsp; ~;
			$link = "$surl\lv-members/a-$URL{'a'}$searchurl/s";
		} else { $rep = qq~| &nbsp; <a href="$surl\lv-members/a-reputation$searchurl/">$gtxt{'rep'}</a>~; }
	}

	if($a eq '') { @listz = sort {lc($a) cmp lc($b)} @listz; $list = qq~</td><td class="win"><strong>&nbsp; $memtext[10] &nbsp;</strong></td><td class="smalltext">&nbsp; ~; $link = "$surl\lv-members$searchurl/s"; }
		else { $list = qq~<a href="$surl\lv-members$searchurl/">$memtext[10]</a>~; }
	$sortedby = "$list &nbsp; $top &nbsp; $let &nbsp; $registered &nbsp; $pro &nbsp; $rep";

	# How many page links?
	$tmax = $totalpp*20;
	$treplies = @listz < 0 ? 1 : @listz-1;
	$totalpages = int(($treplies/$mmpp)+.99);
	if($treplies < $mmpp) { $URL{'s'} = 0; }
	$tstart = $URL{'s'} || 0;
	$counter = 1;
	if($tstart > $treplies) { $tstart = $treplies; }
	$tstart = (int($tstart/$mmpp)*$mmpp);
	if($tstart > 0) { $bk = ($tstart-$mmpp); $pagelinks = qq~<a href="$link-$bk/">&#171;</a> ~; }
	if($treplies > ($tmax/2) && $tstart > $mmpp*((($totalpp*2)/5)+1) && $treplies > $tmax) { $pagelinks .= qq~<a href="$link-0/">...</a> ~; }
	for($i = 0; $i < $treplies+1; $i += $mmpp) {
		if($i < $bk-($mmpp*(($totalpp*2)/5)) && $treplies > $tmax) { ++$counter; $final = $counter-1; next; }
		if($URL{'s'} ne 'all' && $i == $tstart || $treplies < $mmpp) { $pagelinks .= qq~<strong>$counter</strong> ~; $nxt = ($tstart+$mmpp); }
			else { $pagelinks .= qq~<a href="$link-$i/">$counter</a> ~; }
		++$counter;
		if($counter > $totalpp+$final && $treplies > $tmax) { $gbk = (int($treplies/$mmpp)*$mmpp); $pagelinks .= qq~ <a href="$link-$gbk/">...</a> ~; ++$i; last; }
	}
	if(($tstart+$mmpp) != $i && $URL{'s'} ne 'all') { $pagelinks .= qq~ <a href="$link-$nxt/">&#187;</a>~; }

	$counter = -1;

	$title = $memtext[12];
	header();
	$ebout .= <<"EOT";
<table class="border" cellpadding="0" cellspacing="1" width="100%">
 <tr>
  <td class="titlebg" style="padding: 7px;"><img src="$images/profile_sm.gif" class="leftimg" alt="" /> <strong>$title</strong></td>
 </tr><tr>
  <td class="win2" colspan="9">
   <table cellpadding="10" cellspacing="0">
    <tr>
     <td class="smalltext">$sortedby</td>
    </tr>
   </table>
  </td>
 </tr>$letter
</table>
EOT

	if($URL{'a'} eq 'groups' && $URL{'group'}) {
		if($permissions{$URL{'group'},'hidden'} && !($members{'Administrator',$username} || $members{$URL{'group'},$username})) {
			$ebout .= <<"EOT";
<br /><table class="border" cellpadding="5" cellspacing="1" width="100%">
 <tr>
  <td class="win center"><br />$memtext[242]<br /><br /></td>
 </tr>
</table>
EOT
			footer();
			exit;
		}
		if($permissions{$URL{'group'},'team'}) { $team = qq~<img src="$images/admin_sm.png" class="leftimg" alt="" /> ~; }

		if($permissions{$URL{'group'},'accepting'}) { $acceptingnew = "<i>$memtext[229]</i>"; $manage = qq~<br /><a href="$surl\lv-members/a-join/group-$URL{'group'}/">$memtext[230]</a>~; }
		if($members{$URL{'group'},$username}) {
			$acceptingnew = "<i>$memtext[228]</i>";
			$manage = '';
			$removefrom = qq~<td class="win2">&nbsp;<input type="submit" value="$memtext[232]" />&nbsp;</td>~;
		}
		if($manager{$username} || $members{'Administrator',$username}) { $manage = qq~<br /><strong><a href="$surl\lv-members/a-manage/group-$URL{'group'}/">$memtext[231]</a></strong>~; }

		$ebout .= <<"EOT";
<br /><table class="border" cellpadding="5" cellspacing="1" width="100%">
 <tr>
  <td class="titlebg"><strong>$memtext[233]</strong></td>
 </tr><tr>
  <td class="catbg"><strong>$team$permissions{$URL{'group'},'name'}</strong></td>
 </tr>
EOT
		if($permissions{$URL{'group'},'desc'}) {
			$ebout .= <<"EOT";
 <tr>
  <td class="win2">$permissions{$URL{'group'},'desc'}</td>
 </tr>
EOT
		}
		if($acceptingnew eq '') { $acceptingnew = "<i>$memtext[234]</i>"; }
		elsif($members{'Administrator',$username} && $acceptingnew && !$members{$URL{'group'},$username}) { $acceptingnew = "<i>$memtext[235]</i>"; }
		$ebout .= <<"EOT";
 <tr>
  <td class="win"><form action="$surl\lv-members/a-manage/group-$URL{'group'}/r-1/" method="post"><table cellpadding="5" cellspacing="0" class="innertable"><tr>$removefrom<td>$acceptingnew$manage</td></tr></table></form></td>
 </tr>
</table>

EOT
	}

	$ebout .= qq~<br /><table class="border" cellpadding="7" cellspacing="1" width="100%">~;

	if($URL{'a'} eq 'groups' && $URL{'group'} eq '') {
		$ebout .= <<"EOT";
 <tr>
  <td class="catbg" colspan="$tspan">$memtext[236]</td>
 </tr><tr>
  <td class="win" colspan="$tspan">
   <table width="100%" cellpadding="4">
EOT
		foreach(@fullgroups) {
			if($permissions{$_,'hidden'} && !($members{'Administrator',$username} || $members{$_,$username})) { next; }
			if($permissions{$_,'pcount'} eq '' && $_ ne 'Moderators') {
				$yeswefoundone = 1;
				$permissions{$_,'count'} = $permissions{$_,'count'} ? $permissions{$_,'count'} : 0;
				$ebout .= <<"EOT";
    <tr>
     <td><a href="$surl\lv-members/a-groups$searchurl/group-$_/"><strong>$permissions{$_,'name'}</strong></a> ($permissions{$_,'count'} $memtext[237])</td>
    </tr>
EOT
				if($permissions{$_,'desc'}) {
					$ebout .= <<"EOT";
    <tr>
     <td class="win2">$permissions{$_,'desc'}</td>
    </tr>
EOT
				}
			}
		}
		if($yeswefoundone eq '') { $ebout .= qq~<tr><td class="center" style="padding: 10px;">$memtext[245]</td></tr>~; }
		$ebout .= <<"EOT";
   </table>
  </td>
 </tr>
EOT
	} else {
		$ebout .= <<"EOT";
 <tr>
  <td class="titlebg smalltext center" style="width: 5%"><img src="$images/pm_sm.gif" alt="$memtext[14]" /></td>
  <td class="titlebg smalltext center" style="width: 25%"><strong>$memtext[15]</strong></td>
  <td class="titlebg smalltext center" style="width: 7%"><strong>$var{'22'}</strong></td>
  <td class="titlebg smalltext center" style="width: 5%"><img src="$images/site_sm.gif" alt="$memtext[16]" /></td>
  <td class="titlebg smalltext center" style="width: 7%"><strong>$memtext[2]</strong></td>
  <td class="titlebg smalltext center" style="width: 20%"><strong>$memtext[18]</strong></td>
  <td class="titlebg smalltext center" style="width: 25%"><strong>$memtext[19]</strong></td>
EOT
		if($enablerep) { $ebout .= qq~<td class="titlebg smalltext center" style="width: 10%"><strong>$gtxt{'rep'}</strong></td>~; $tspan = 8; } else { $tspan = 7; }
		$ebout .= "</tr>";
	}

	$mans = '2';
	foreach $temp (@listz) {
		if($a eq 'groups' || $a eq '') { $_ = $temp; }
			else { ($temp2,$_) = split(/\|/,$temp); }

		++$counter;
		if($counter < $tstart) { next; }
		if($counter >= ($tstart+$mmpp)) { last; }

		GetMemberID($_);

		$homepage = '';
		$offonline = '';

		if($memberid{$_}{'sn'} eq '') { next; }

		if($memberid{$_}{'hidemail'} && $hmail && !$members{'Administrator',$username}) { $email = qq~<img src="$images/lockmail.png" alt="$gtxt{'27'}" />~; }
			else { $email = qq~<a href="mailto:$memberid{$_}{'email'}"><img src="$images/email_sm.gif" alt="$memberid{$_}{'email'}" /></a>~; }
		if($memberid{$_}{'siteurl'} ne '' && $memberid{$_}{'sitename'} eq '') { $sitename = $memberid{$_}{'siteurl'}; }
			else { $sitename = $memberid{$_}{'sitename'}; }
		if($memberid{$_}{'sitename'} ne '') { $homepage = qq~<a href="$memberid{$_}{'siteurl'}"$blanktarget><img src="$images/site_sm.gif" alt="$sitename" /></a>~; }
		if($messagecnt > 0) {
			$postcount = sprintf("%.2f",(($memberid{$_}{'posts'}/$messagecnt)*100));
			if($postcount > 100) { $postcount = "100"; }
		}

		if($useronline{$_}) { $offonline = qq~<a href="$surl\lv-memberpanel/t-$_/a-pm/s-write/" rel="nofollow"><img src="$images/pm_sm.gif" alt="$gtxt{'30'}" /></a>~; }

		if($offonline eq '' || $memberid{$_}{'hideonline'}) { $offonline = qq~<a href="$surl\lv-memberpanel/t-$_/a-pm/s-write/" rel="nofollow"><img src="$images/pm_sm_off.gif" alt="$gtxt{'31'}" /></a>~; }
		$regdate = get_date($memberid{$_}{'registered'});

		$change = $stat = $var{'60'};

		foreach $temp (@grpsposts) {
			($num,$memgrp) = split(/\|/,$temp);
			if($memberid{$_}{'posts'} >= $num) { $stat = $permissions{$memgrp,'name'}; }
		}

		$change = $stat;

		if($URL{'a'} eq 'groups' && $manager{$_} ne $mans) {
			if($manager{$_}) {
				$ebout .= <<"EOT";
 <tr>
  <td class="catbg smalltext" colspan="$tspan"><strong>$memtext[238]</strong></td>
 </tr>
EOT
				$mans = $manager{$_};
			} else {
				$ebout .= <<"EOT";
 <tr>
  <td class="catbg smalltext" colspan="$tspan"><strong>$memtext[239]</strong></td>
 </tr>
EOT
				$mans = $manager{$_};
			}
		}

		$ts = lc(substr($temp2,0,1));
		if($URL{'a'} eq 'let' && $ts ne $templetter) {
			$tsb = uc(substr($temp2,0,1));
			$ebout .= <<"EOT";
 <tr>
  <td class="catbg" colspan="$tspan"><strong>$tsb</strong></td>
 </tr>
EOT
			$templetter = $ts;
		}

		if($URL{'a'} eq 'top' && $change ne $tempstat) {
			$tsb = uc(substr($_,0,1));
			$ebout .= <<"EOT";
 <tr>
  <td class="catbg" colspan="$tspan"><strong>$change</strong></td>
 </tr>
EOT
			$tempstat = $change;
		}

		$ebout .= <<"EOT";
 <tr>
  <td class="win2 smalltext center">$offonline</td>
  <td class="win smalltext">$userurl{$_}</td>
  <td class="win2 center">$email</td>
  <td class="win2 center">$homepage</td>
EOT
		if($hideposts != 1) { $ebout .= qq~<td class="win2 smalltext center" style="width: 3%">~.MakeComma($memberid{$_}{'posts'}).qq~</td>~; }
			else { $ebout .= qq~<td class="smalltext">$gtxt{13}</td>~; }

		$ebout .= <<"EOT";
  <td class="win smalltext">$stat</td>
  <td class="win smalltext">$regdate</td>
EOT
		if($enablerep) {
			$reputation = '';
			if($memberid{$_}{'rep'} ne '') {
				$color = '';
				if($memberid{$_}{'rep'} < 50) { $color = qq~class="redrep"~; } # Horrible
				elsif($memberid{$_}{'rep'} > 75) { $color = qq~class="greenrep"~; } # Best
					else { $color = qq~class="grayrep"~; }

				$reputation = qq~<span $color>$memberid{$_}{'rep'}%</span>~;
			}
			$ebout .= qq~<td class="win2 smalltext center">$reputation</td>~;
		}

		$ebout .= "</tr>";
	}
	if($listz[0] eq '' && (($URL{'a'} eq 'groups' && $URL{'group'} ne '') || $URL{'a'} ne 'groups')) {
		$ebout .= <<"EOT";
 <tr>
  <td class="win center" colspan="9"><br /><strong>$memtext[23]</strong><br /><br /></td>
 </tr>
EOT
		$pagelinks = '';
	}
	if($pagelinks ne '' && ($URL{'a'} ne 'groups' || ($URL{'a'} eq 'groups' && $URL{'group'} ne ''))) {
		$ebout .= <<"EOT";
 <tr>
  <td colspan="$tspan" class="catbg" style="padding: 8px;"><div class="pages">$totalpages $gtxt{'45'} $pagelinks</div></td>
 </tr>
EOT
	}

	$searchonlinec{$searchonline} = ' checked="checked"';

	$ebout .= <<"EOT";
</table><br />
<form action="$surl\lv-members/" method="post" enctype="multipart/form-data">
<table class="border" cellpadding="5" cellspacing="1" width="100%">
 <tr>
  <td class="titlebg"><strong><img src="$images/search.png" class="leftimg" alt="" /> $memtext[249]</strong></td>
 </tr><tr>
  <td class="win">
   <input type="hidden" name="search" value="1" />
   <table cellpadding="3" cellspacing="0" class="innertable">
    <tr>
     <td><strong>$memtext[247]:</strong></td><td><input type="text" name="searchuser" value="$searchuser" size="40" /></td>
    </tr><tr>
     <td><strong>$memtext[250]:</strong></td><td><input type="text" name="searchemail" value="$searchemail" size="35" /></td>
    </tr><tr>
     <td><strong>$memtext[251]</strong></td><td><input type="checkbox" name="searchonline" value="1"$searchonlinec{'1'} /></td>
    </tr><tr>
     <td><strong>$memtext[252]:</strong></td><td><input type="text" name="searchpostslow" value="$searchpostslow" size="5" /></td>
    </tr><tr>
     <td><strong>$memtext[253]:</strong></td><td><input type="text" name="searchpostshigh" value="$searchpostshigh" size="5" /></td>
    </tr><tr>
     <td colspan="2"><strong>$memtext[254]</strong> <input type="text" name="searchregistered" value="$searchregistered" size="3" /> $memtext[256]</td>
    </tr><tr>
     <td colspan="2"><strong>$memtext[255]</strong> <input type="text" name="searchreputation" value="$searchreputation" size="3" /> %</td>
    </tr><tr>
     <td colspan="2"><input type="submit" value="$memtext[248]" /></td>
    </tr>
   </table>
  </td>
 </tr>
</table>
</form>
EOT
	footer();
	exit;
}


sub Letter {
	$l = $userletter || 'A';
	@mlist = sort{lc($a) cmp lc($b)} @mlist;
	foreach $listme (@mlist) {
		($_,$usename) = split(/\|/,$listme);
		$snu = uc(substr($_,0,1));
		if($snu =~ s~[0-9#%+,\\\/:?"<>'|@^\$\&\~'\)\(\]\[\;{}!`=-]~~gsi) { $snu = 'NUM'; }
		$letter{$snu} .= "$_:$usename|";
	}

	for($ll = 'A'; $ll ne 'AB'; $ll++) {
		if($ll eq 'AA') { $ll = 'NUM'; }
		if(uc($l) ne $ll && !$nope) { next; }
		$nope = 1;
		@array = split(/\|/,$letter{$ll});
		foreach(@array) {
			($p1,$p2) = split(/\:/,$_);
			push(@listz,"$p1|$p2");
		}
		if($ll eq 'NUM') { return; }
	}
}

sub TopPosters {
	foreach $temp (@mlist) {
		($t,$_,$pc) = split(/\|/,$temp);
		push(@slist,"$pc|$_");
	}
	foreach(sort {$b <=> $a} @slist) {
		($t,$usr) = split(/\|/,$_);
		push(@listz,"$_|$usr");
	}
}

sub RegDate {
	foreach $temp (@mlist) {
		($t,$_,$t,$t,$time) = split(/\|/,$temp);
		push(@slist,"$time|$_");
	}
	foreach(sort {$b <=> $a} @slist) {
		($t,$usr) = split(/\|/,$_);
		push(@listz,"$usr|$usr");
	}
}
1;