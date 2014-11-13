#############################################
# E-Blah Bulletin Board Systems        2008 #
#############################################
# Copyright (c) 2001 - 2008 E-Blah.         #
#############################################

CoreLoad('PM',1);

$URL{'b'} = '';

if($pmdisable) { error($pmtxt[133]); }

if($memberid{$username}{'bcadvanced'}) { $BCAdvanced = 0; }

sub PMOpen {
	$fids{'3'} = $pmtxt[27];
	if($URL{'f'} == 2) { $load = 2; $select = $pmtxt[139]; $folder = $pmtxt[25]; }
	elsif($fids{$URL{'f'}} ne '') { $load = $URL{'f'}; $select = $pmtxt[5]; $folder = $fids{$URL{'f'}}; }
		else { $load = 1; $select = $pmtxt[7]; $folder = $pmtxt[23]; }
}

sub PMStart {
	$size = -s("$members/$username.pm");
	if($pmmaxquota > 0 && $size > 0) { # Quota
		$remain = $size = sprintf("%.2f",($size/1024));
		$left = $pmmaxquota-$remain;
		if($remain < 0) { $remain = "0.00"; }
		if($size eq '') { $size = 0; }
		$width = "70%";

		$size = sprintf("%.2f",(($size/$pmmaxquota)*100));
		$type = $typeb = $typec = 'KB';
		if($remain > 1000) { $remain = sprintf("%.2f",$remain/1024); $type = "MB"; }
		$total = $pmmaxquota;
		if($total > 1000) { $total = sprintf("%.2f",$total/1024); $typeb = "MB"; }
		$left = sprintf("%.2f",(($left/100)*100));
		if($left > 1000) { $left = sprintf("%.2f",$left/1024); $typec = "MB"; }
		if($size > 100) { $size = 100; }
		if($left < 0) { $left = 0; $error = $pmtxt[140]; }

		fopen(FILE,"$members/$username.pm");
		while($temp = <FILE>) {
			($boxid) = split(/\|/,$temp);
			if($boxid == 2) { $sizesent += length $temp; }
			elsif($boxid == 1) { $sizein += length $temp; }
				else { $sizerest += length $temp; }

			$sizetotal += length $temp;
		}
		fclose(FILE);

		if($sizetotal > 0) {
			$sizesent = sprintf("%.2f",($sizesent/$sizetotal)*100);
			$sizein = sprintf("%.2f",($sizein/$sizetotal)*100);
			$sizerest = sprintf("%.2f",($sizerest/$sizetotal)*100);
		} else { $sizesent = $sizein = $sizerest = 0; }

		$quota = <<"EOT";
<table class="border" cellpadding="6" cellspacing="1" width="100%">
 <tr>
  <td class="win2"><strong>$size%</strong> $pmtxt[185] <strong>$total $typeb</strong> $pmtxt[186] <strong>$left $typec</strong> $pmtxt[10].$error</td>
 </tr><tr>
  <td class="win"><div style="width: $size%"><img src="$images/bar.gif" width="$sizein%" height="10" alt="$sizein%" /><img src="$images/bar_sent.gif" width="$sizesent%" height="10" alt="$sizesent%" /><img src="$images/bar_rest.gif" width="$sizerest%" height="10" alt="$sizerest%" /></div></td>
 </tr><tr>
  <td class="win3">
   <table cellpadding="0" cellspacing="0" width="100%">
    <tr>
     <td class="smalltext" style="width: 33%">0%</td>
     <td class="smalltext center" style="width: 33%">50%</td>
     <td class="smalltext right" style="width: 34%">100%</td>
	</tr>
   </table>
  </td>
 </tr>
</table>
<br />
EOT
	} # END QUOTA

	if($URL{'start'} ne 'title') { $stitle = qq~<a href="$surl\lv-memberpanel/a-pm/f-$URL{'f'}/start-title/">$pmtxt[12]</a>~; }
		else { $stitle = "&rsaquo; $pmtxt[12]"; $ta = 1; }
	if($URL{'start'} ne 'user') { $suser = qq~<a href="$surl\lv-memberpanel/a-pm/f-$URL{'f'}/start-user/">$select</a>~; }
		else { $suser = "&rsaquo; $select"; $ta = 1; }
	if($ta) { $sgot = qq~<a href="$surl\lv-memberpanel/a-pm/f-$URL{'f'}/">$pmtxt[14]</a>~; }
		else { $sgot = "&rsaquo; $pmtxt[14]"; }

	$callt = qq~<img src="$images/pm2_sm.gif" alt="" /> $folder~;

	$displaycenter = <<"EOT";
<script type="text/javascript">
//<![CDATA[
function checkAll() {
	for(i = 0; i < document.forms['pm'].elements.length; i++) {
		if(document.forms['pm'].del.checked) { document.forms['pm'].elements[i].checked = true; }
			else { document.forms['pm'].elements[i].checked = false; }
	}
}
//]]>
</script>
$quota
<form action="$surl\lv-memberpanel/a-pm/s-delete/f-$URL{'f'}/start-$URL{'start'}/" id="pm" method="post">
<table cellspacing="0" cellpadding="0" width="100%" style="margin-bottom: 5px;">
 <tr>
  <td class="right"><a href="$surl\lv-memberpanel/a-pm/s-write/">$Iimg{'new_pm'}</a>$Imsp2<a href="$surl\lv-print/s-pm/f-$URL{'f'}/m-all/">$Iimg{'print_pm'}</a></td>
 </tr>
</table>
<table cellpadding="0" cellspacing="0" width="100%">
 <tr>
  <td class="right vtop" style="width: 80%">
   <table class="border" cellpadding="7" cellspacing="1" width="100%">
EOT
	$sort = $URL{'start'};

	foreach(@pmdata) {
		($med,$pmid,$title,$tof,$ta,$tb,$mnew,$service,$beep,$flag) = split(/\|/,$_);
		if($med ne $load || $_ eq '') { next; }
		if($sort eq 'user') { push(@pmz,"$tof|$pmid|$title|$med|$ta|$tb|$mnew|$service|$beep|$flag"); }
		elsif($sort eq 'title') { push(@pmz,"$title|$pmid|$med|$tof|$ta|$tb|$mnew|$service|$beep|$flag"); }
			else { push(@pmz,"$pmid|$med|$title|$tof|$ta|$tb|$mnew|$service|$beep|$flag"); }
	}
	if($sort eq 'user' || $sort eq 'title') { @pmz = sort{lc($a) cmp lc($b)} @pmz; }
		else { @pmz = sort{$b <=> $a} @pmz; }

	# Get Pages



	$maxm = @pmz-1 || 1; # Come up with brd cnt
	$maxdis = 15; # Max per page

	$treplies = $maxm < 0 ? 1 : $maxm;
	if($treplies <= $maxdis) {
		$pagelinks = "<strong>1</strong>";
		$totalpages = 1;
		$tstart = $URL{'p'} = 0;
	} else {
		$totalpages = int(($treplies/$maxdis)+.99);

		$tstart = $URL{'p'} || 0;
		$counter = 1;
		$linknewtwo = "/n-$URL{'n'}" if($URL{'n'});
		$link = "$surl\lv-memberpanel/a-pm/f-$URL{'f'}/start-$URL{'start'}/p";
		if($tstart > $treplies) { $tstart = $treplies; }
		$tstart = (int($tstart/$maxdis)*$maxdis);
		if($tstart > 0) { $bk = ($tstart-$maxdis); $pagelinks = qq~<a href="$link-$bk/">&#171;</a> ~; }
		if($treplies > ($tmax/2) && $tstart > $maxdis*($startdot+1) && $treplies > $tmax) { $pagelinks .= qq~<a href="$link-0/">...</a> ~; }
		for($i = 0; $i < $treplies+1; $i += $maxdis) {
			if($i < $bk-($maxdis*$startdot) && $treplies > $tmax) { ++$counter; $final = $counter-1; next; }
			if($URL{'p'} ne 'all' && $i == $tstart || $treplies < $maxdis) { $pagelinks .= qq~<strong>$counter</strong> ~; $nxt = ($tstart+$maxdis); }
				else { $pagelinks .= qq~<a href="$link-$i/">$counter</a> ~; }
			++$counter;
			if($counter > $totalpp+$final && $treplies > $tmax) { $gbk = (int($treplies/$maxdis)*$maxdis); $pagelinks .= qq~ <a href="$link-$gbk/">...</a> ~; ++$i; last; }
		}
		if(($tstart+$maxdis) != $i && $URL{'p'} ne 'all') { $pagelinks .= qq~ <a href="$link-$nxt/">&#187;</a>~; }
	}
	$end = ($tstart+$maxdis);
	if($end > @pmz) { $end = @pmz; }

	if($maxm != 1 && $maxm != 0) { ++$maxm; }

	$totalshown = "\u$var{'92'} ".($tstart+1)."-$end $var{'93'} ".@pmz." $gtxt{'11'}.";

	$displaycenter .= <<"EOT";
    <tr>
     <td class="catbg center" style="width: 25px"><img src="$images/flag_off.gif" alt="$pmtxt[30]" /></td>
     <td class="catbg"><strong>$stitle</strong></td>
     <td class="catbg center" style="width: 20%"><strong>$suser</strong></td>
     <td class="catbg" style="width: 20%"><strong>$sgot</strong></td>
     <td class="catbg center" style="width: 30px"><input type="checkbox" name="del" onclick="checkAll();" /></td>
    </tr>
EOT

	if(@pmz > 0) {
		for($c = 0; $c < $maxm+1; $c++) {
			if($c >= $tstart && $c < $end) { push(@pmlist,$pmz[$c]); }
		}
		$counter = $tstart;
	} else { $counter = 0; }

	foreach(@pmlist) {
		$pflag = qq~<img src="$images/flag_off.gif" alt="" />~;
		if($sort eq 'user') { ($tof,$pmid,$title,$med,$trash,$trash,$mnew,$service,$beep,$flag) = split(/\|/,$_); }
		elsif($sort eq 'title') { ($title,$pmid,$med,$tof,$trash,$trash,$mnew,$service,$beep,$flag) = split(/\|/,$_); }
			else { ($pmid,$med,$title,$tof,$trash,$trash,$mnew,$service,$beep,$flag) = split(/\|/,$_); }
		$date = get_date($pmid);
		GetMemberID($tof);
		if($memberid{$tof}{'sn'} eq '') { $sender = $tof; }
			else { $sender = $userurl{$tof}; }

		if($mnew) { $new = qq~<img src="$images/new.png" style="margin: 0 3px 0 3px;" alt="$pmtxt[20]" /> ~; $title = "<strong>$title</strong>"; } else { $new = ''; }
		if($flag == 1) { $pflag = qq~<img src="$images/flag.gif" alt="$pmtxt[30]" />~; }
		elsif($flag == 2) { $pflag = qq~<img src="$images/replied.gif" alt="$pmtxt[31]" /> ~; }
		if($service == 1) { $snote = qq~<div class="win3 smalltext" style="float: right; padding: 9px">$pmtxt[32]</div>~; }
		elsif($service == 2) { $snote = qq~<div class="win3 smalltext" style="float: right; padding: 9px">$pmtxt[33]</div>~; }
		elsif($service == 3) { $snote = qq~<div class="win3 smalltext" style="float: right; padding: 9px">$beep</div>~; }
			else { $snote = ''; }
		$displaycenter .= <<"EOT";
    <tr>
     <td class="win2 center" id="$counter">$pflag</td>
     <td class="win" id="$counter" style="padding: 0px">
	  <table cellspacing="0" cellpadding="0" width="100%">
	   <tr>
	    <td style="padding: 9px">$new<a href="$surl\lv-memberpanel/a-pm/f-$URL{'f'}/m-$pmid/">$title</a></td>
	    <td>$snote</td>
	   </tr>
	  </table>
	 </td>
     <td class="win2 smalltext center" id="$counter">$sender</td>
     <td class="win smalltext" id="$counter">$date</td>
     <td class="win2 center" id="$counter"><input type="checkbox" name="d_$counter" value="$pmid" /></td>
    </tr>
EOT
		++$counter;
	}
	if(!$counter) { $displaycenter .= <<"EOT";
<tr>
 <td class="win2 center" colspan="5"><br />$pmtxt[34]<br /><br /></td>
</tr>
EOT
	} else {
		$move = <<"EOT";
<select name="moveto"><option value="3">$pmtxt[27]</option>$folderops</select> <input type="submit" name="move" value="$pmtxt[35]" />
EOT
		$displaycenter .= <<"EOT";
    <tr>
     <td class="catbg right" colspan="5">$move <input type="submit" value="$pmtxt[132]" onclick="if(!confirm('$pmtxt[188]')) { return false; }" /></td>
    </tr>
EOT
	}
	$displaycenter .= <<"EOT";
   <tr>
    <td style="padding: 10px;" class="win smalltext pages" colspan="5">
	 <div style="float: left">$totalpages $gtxt{'45'} $pagelinks</div>
	 <div style="float: right">$totalshown</div>
	</td>
   </tr></table>
  </td>
 </tr><tr>
  <td class="center"><br />
   <table cellpadding="5" cellspacing="0">
    <tr>
     <td style="width: 15px" class="center"><img src="$images/flag_off.gif" alt="" /></td>
     <td class="smalltext">$pmtxt[145]</td>
     <td style="width: 15px" class="center"><img src="$images/flag.gif" alt="" /></td>
     <td class="smalltext">$pmtxt[30]</td>
     <td style="width: 15px" class="center"><img src="$images/replied.gif" alt="" /></td>
     <td class="smalltext">$pmtxt[31]</td>
    </tr>
   </table>
  </td>
 </tr>
</table>
</form>
EOT
}

sub Move {
	if($FORM{'moveto'} < 3) { error($pmtxt[37]); }
	if(($FORM{'moveto'} != 3 && $fids{$FORM{'moveto'}} eq '') || $FORM{'moveto'} eq $load) { error($gtxt{'bfield'}); }
	fopen(FILE,"$members/$username.pm");
	@message = <FILE>;
	fclose(FILE);
	$max = @message;
	chomp @message;

	for($p = 0; $max > $p; $p++) {
		if($FORM{"d_$p"} ne '') { push(@search,$FORM{"d_$p"}); }
	}
	foreach(@message) {
		$fnd = 0;
		($med,$pmid,$title,$tof,$ta,$tb,$mnew,$service,$other,$flag) = split(/\|/,$_);
		if($load eq $med) {
			foreach $find (@search) {
				if($find eq $pmid) { $fnd = 1; }
			}
		}
		$move .= !$fnd ? "$_\n" : "$FORM{'moveto'}|$pmid|$title|$tof|$ta|$tb|$mnew|$service|$other|$flag\n";
	}

	fopen(FILE,">$members/$username.pm");
	print FILE $move;
	fclose(FILE);

	redirect("$surl\lv-memberpanel/a-pm/f-$URL{'f'}/");
}

sub PMDelete {
	if($FORM{'move'}) { Move(); }
	fopen(FILE,"$members/$username.pm");
	@message = <FILE>;
	fclose(FILE);
	$max = @message;

	for($p = 0; $max > $p; $p++) {
		if($FORM{"d_$p"} ne '') { push(@search,$FORM{"d_$p"}); }
	}
	foreach (@message) {
		$fnd = 0;
		chomp;
		($med,$pmid,$title,$tof,$trash,$trash,$mnew,$service) = split(/\|/,$_);
		if($load eq $med) {
			foreach $find (@search) {
				if($find eq $pmid) { $fnd = 1; }
			}
		}
		if($fnd != 1) { $deleted .= "$_\n"; }
	}

	fopen(FILE,">$members/$username.pm");
	print FILE $deleted;
	fclose(FILE);

	# Reset the PM over message
	$prefs[7] = 0;
	fopen(FILE,">$members/$username.prefs");
	for($i = 0; $i < 9; $i++) { print FILE "$prefs[$i]\n"; }
	fclose(FILE);

	redirect("$surl\lv-memberpanel/a-pm/f-$URL{'f'}/");
}

sub Write {
	if($managersend) { return(0); }

	if($URL{'m'} ne '') {
		fopen(FILE,"$members/$username.pm");
		while (<FILE>) {
			chomp;
			($folder,$mid,$ttitle,$replyuser,$message) = split(/\|/,$_);
			if($folder == $load) {
				if($URL{'m'} == $mid) { $fnd = 1; last; }
			}
		}
		fclose(FILE);
		$message =~ s~\[quot(.+?)\](.*?)\[/quote\]~~gsi;
		$messageedit = "[quote]".Unformat($message)."[/quote]\n\n";
	}
	if($URL{'p'} == 2 && !$FORM{'preview'}) { PMSend2(); return(1); }
	elsif($FORM{'preview'}) {
		$ttitle = Format($FORM{'title'});
		$messageedit = Format($FORM{'message'});
		$replyuser = Format($FORM{'to'});
		$other = Format($FORM{'other'});
		$toall{$FORM{'toall'}} = ' selected="selected"';
		$smile{$FORM{'smile'}} = ' checked="checked"';
		$flag{$FORM{'flag'}} = ' checked="checked"';
		$sendmeth{$FORM{'sendmeth'}} = ' selected="selected"';
	} else {
		GetMemberID($replyuser);
		$replyuser = $memberid{$replyuser}{'sn'};
	}
	$message2 = $message;
	if($FORM{'message'}) {
		$message = $messageedit;
		$message = BC($message);
		$displaycenter .= <<"EOT";
<table cellpadding="5" cellspacing="1" width="100%" class="center border">
 <tr>
  <td class="catbg smalltext"><strong>$pmtxt[184]</strong></td>
 </tr><tr>
  <td class="win">$message</td>
 </tr>
</table><br />
EOT
	}
	if($fnd) {
		$title = $pmtxt[38];
		$ttitle =~ s/Re: //gsi;
		$ttitle = "Re: $ttitle";
		$fndinp = qq~<input type="hidden" name="ron" value="1" />~;
	} else { $title = $pmtxt[39]; }

	if($URL{'t'} ne '') {
		$replyuser = $URL{'t'};
		GetMemberID($replyuser);
		$replyuser = $memberid{$replyuser}{'sn'};
	}
	GetMemberID($replyuser);

	$callt = qq~<img src="$images/pm2_sm.gif" alt="" /> $title~;

	CoreLoad('Post');
	if($BCLoad || $BCSmile) { $displaycenter .= BCWait(); }

	$displaycenter .= <<"EOT";
<script type="text/javascript">
//<![CDATA[
function AddBuddy() {
	if(!document.forms['post'].to.disabled == true) {
		if(document.forms['post'].to.value != '') { front = ','; } else { front = ''; }
		document.forms['post'].to.value += front+document.forms['post'].addbud.value;
		document.forms['post'].addbud.value = '';
	}
}

function OhnoesMartin(hmm) {
	if(hmm == 1) {
		if(!window.confirm('$pmtxt[187]')) { document.forms['post'].toall.value = 0; }
			else { document.forms['post'].to.value = ''; document.forms['post'].to.disabled = true; }
	} else {
		document.forms['post'].to.disabled = false;
	}
}
//]]>
</script>
<form action="$surl\lv-memberpanel/a-pm/f-$URL{'f'}/s-write/p-2/m-$URL{'m'}/" method="post" id="post">
<table cellpadding="2" cellspacing="1" class="border" width="100%">
 <tr>
  <td class="catbg smalltext" style="padding: 5px"><strong>$pmtxt[189]</strong></td>
 </tr><tr>
  <td class="win">
   <table cellpadding="4" width="100%">
    <tr>
     <td style="width: 30%" class="right vtop" rowspan="2"><strong>$pmtxt[42]:</strong></td>
     <td style="width: 150px"><input type="text" name="to" value="$replyuser" size="30" tabindex="1" /></td><td>
EOT
	LoadBuddys(1);
	if(@buddylist > 0) {
		$displaycenter .= qq~<select name="addbud" tabindex="1" onchange="AddBuddy();"><option value=''>$pmtxt[167]</option>~;

		foreach(@buddylist) {
			($name,$myname) = split("/",$_);
			GetMemberID($name);
			if(!$memberid{$name}{'sn'} || $blocked{$name}) { next; }
			$online = $activemembers{$name} && !$memberid{$name}{'hideonline'} ? " ($gtxt{'30'})" : '';
			$buddyname = $memberid{$name}{'sn'};
			if($myname) { $buddyname = $myname; }
			$displaycenter .= qq~<option value="$memberid{$name}{'sn'}">$buddyname$online</option>~;
		}
		$displaycenter .= qq~</select>~;
	}

	if(!$members{'Administrator',$username}) {
		foreach $ohgroup (@fullgroups) {
			if($isamanager) { last; }
			foreach $manager (split(',',$permissions{$uno,'managers'})) {
				if($username eq $manager) { $isamanager = 1; }
			}
		}
	}
	if($members{'Administrator',$username} || $isamanager) { $pmtxt[43] = "$pmtxt[43] $pmtxt[192]"; }

	$displaycenter .= qq~</td></tr><tr><td colspan="2" class="smalltext">$pmtxt[43]</td></tr>~;

	if($members{'Administrator',$username}) {
		$displaycenter .= <<"EOT";
    <tr>
     <td class="right vtop" style="width: 30%" rowspan="2"><strong>$pmtxt[44]:</strong></td>
     <td class="vtop" colspan="2"><select name="toall" tabindex="2" onchange="OhnoesMartin(this.value);"><option value="0"$toall{0}>$pmtxt[46]</option><option value="1"$toall{1}>$pmtxt[47]</option></select></td>
    </tr><tr>
     <td colspan="2" class="smalltext">$pmtxt[45]</td>
    </tr>
EOT
	}

	if($BCSmile) {
		if(!$BCAdvanced) { $smilies = BCSmile(); }
			else { $smilies = BCSmileAE(); }
	}

	if($BCLoad) {
		if(!$BCAdvanced) { $bcode = BCLoad(); }
			else { $bcode = BCLoadAE(); }
	}

	$messageedit =~ s/<br \/>/\n/g;
	if(!$prefs[2]) { $prefs[2] = 0; }
	$sentitems{$prefs[2]} = ' checked="checked"';

	$displaycenter .= <<"EOT";
    <tr>
     <td class="right" style="width: 30%"><strong>$pmtxt[48]:</strong></td>
     <td colspan="2"><input type="text" tabindex="3" name="title" value="$ttitle" size="40" maxlength="50" /></td>
    </tr>
   </table>
  </td>
 </tr><tr>
  <td class="catbg smalltext" style="padding: 5px"><strong>$pmtxt[191]</strong></td>
 </tr><tr>
  <td class="win" style="padding: 0px">
   $bcode
   <table cellpadding="0" cellspacing="0" width="100%">
    <tr>
     <td style="width: 70%; padding: 8px;"><textarea name="message" id="message" tabindex="4" rows="12" cols="95" style="width: 98%">$messageedit</textarea></td>
     <td class="win2 vtop">$smilies</td>
    </tr>
   </table>
  </td>
 </tr><tr>
  <td class="catbg smalltext" style="padding: 5px"><strong>$pmtxt[190]</strong></td>
 </tr><tr>
  <td class="win">
   <table cellpadding="4" cellspacing="0" width="100%">
    <tr>
     <td class="right" style="width: 30%"><strong>$pmtxt[54]:</strong></td>
     <td style="width: 70%" class="vtop smalltext"><input type="checkbox" tabindex="7" name="smile" value="1"$smile{1} /> &nbsp; $posttxt[120]</td>
    </tr><tr>
     <td class="right vtop" style="width: 30%"><strong>$pmtxt[55]:</strong></td>
     <td style="width: 70%" class="vtop smalltext"><input type="checkbox" tabindex="8" name="flag" value="1"$flag{1} /> &nbsp; $pmtxt[56]</td>
    </tr><tr>
     <td class="right vtop" style="width: 30%"><strong>$pmtxt[194]:</strong></td>
     <td style="width: 70%" class="vtop smalltext"><input type="checkbox" tabindex="9" name="sentitems" value="1"$sentitems{0} /> &nbsp; $pmtxt[193]</td>
    </tr>
   </table>
  </td>
 </tr>
EOT
	if($members{'Administrator',$username}) {
		$displaycenter .= <<"EOT";
 <tr>
  <td class="catbg smalltext" style="padding: 5px"><strong>$pmtxt[57]</strong></td>
 </tr><tr>
  <td class="win">
   <table cellpadding="4" cellspacing="0" width="100%">
    <tr>
     <td colspan="2"><strong>$pmtxt[58]</strong></td>
    </tr><tr>
     <td style="width: 25%"><select name="sendmethod" tabindex="10"><option value="0"$sendmeth{0}>$pmtxt[60]</option><option value="2"$sendmeth{2}>$pmtxt[33]</option><option value="1"$sendmeth{1}>$pmtxt[32]</option><option value="3"$sendmeth{3}>$pmtxt[64] $pmtxt[63]</option></select></td>
     <td class="smalltext"><strong>$pmtxt[64]:</strong> <input type="text" tabindex="10" name="other" value="$other" maxlength="50" /></td>
    </tr><tr>
     <td colspan="2" class="smalltext">$pmtxt[59]</td>
    </tr>
   </table>
  </td>
 </tr>
EOT
	}
	$displaycenter .= <<"EOT";
 <tr>
  <td class="win2" style="padding: 5px"><input type="submit" tabindex="5" value=" $pmtxt[66] " name="submit" /> &nbsp;<input type="submit" tabindex="6" value=" $pmtxt[184] " name="preview" /></td>
 </tr>
</table>
</form>
EOT
}

sub PMSend2 {
	my(@to);

	if($URL{'v'} eq 'members') {
		($FORM{'title'},$FORM{'message'},$FORM{'to'}) = @_;

		GetMemberID($FORM{'to'});
		$FORM{'to'} = $memberid{$FORM{'to'}}{'sn'};

		if($managersend) {
			$members{'Administrator',$username} = 1; # Sets a temp admin group
			$FORM{'sendmethod'} = 2;
		}
	}

	if($pmmaxquota && 0 > $pmmaxquota-(sprintf("%.2f",(-s("$members/$username.pm"))/1024)) && !$members{'Administrator',$username}) { error($pmtxt[141]); }

	$mess = $message;

	$subject = Format($FORM{'title'});
	$message = Format($FORM{'message'});

	if($subject eq '') { error($pmtxt[68]); }
	if($message eq '') { error($pmtxt[69]); }

	error($gtxt{'long'}) if(length($message) > $maxmesslth && $maxmesslth);
	$adminoverride = 0;
	$message =~ s~\{R~\{<!>R~gi;
	$message =~ s~\Y}~Y<!>\}~gi;

	if($members{'Administrator',$username} && $FORM{'toall'}) {
		fopen(FILE,"$members/List2.txt") || error($pmtxt[70],1);
		while(<FILE>) {
			chomp;
			($t,$sn) = split(/\|/,$_);
			push(@to,$sn);
		}
		fclose(FILE);
		$adminoverride = 1;
	} else {
		if($FORM{'to'} eq '') { error($pmtxt[71]); }
		foreach(split(',',$FORM{'to'})) {
			if($_ =~ /\|(.*?)\|/) { # Groups ...
				$uno = $1;
				foreach $ohgroup (@fullgroups) {
					if($permissions{$ohgroup,'name'} eq $uno) { $uno = $ohgroup; }
					last;
				}
				if(!$members{'Administrator',$username}) {
					foreach $manager (split(',',$permissions{$uno,'managers'})) {
						if($username eq $manager) {
							$iisamanager = 1;
							push(@to,split(',',$permissions{$uno,'members'}));
							last; # Manager last
						}
					}
				} else { push(@to,split(',',$permissions{$uno,'members'})); }
			} else { push(@to,$_); }
		}
	}

	if($members{'Administrator',$username}) {
		if(length($FORM{'other'}) > 50) { error($pmtxt[72]); }
		if($FORM{'sendmethod'} == 1) { $adminadd = 1; $FORM{'other'} = ''; }
		elsif($FORM{'sendmethod'} == 2) { $adminadd = 2; $FORM{'other'} = ''; }
		elsif($FORM{'sendmethod'} == 3) { $adminadd = 3; }
			else { $FORM{'other'} = ''; }
	}

	$counter = 0;
	$ttime = time;

	fopen(FILE,"$members/List2.txt");
	@members = <FILE>;
	fclose(FILE);
	chomp @members;

	$countmenow = 0;
	foreach(@to) {
		++$countmenow;
		if(!$iisamanager && !$members{'Administrator',$username} && $countmenow > 10) { last; } # Normal users can't spam the world ...

		$_ = FindUsername($_);

		return() if($_ eq '' && $managersend);
		if($_ eq '' && $adminoverride) { error("$_ $pmtxt[73]"); }
		if($_ eq '' && !$adminoverride) { error("$_ $pmtxt[74]"); }
		GetMemberID($_);

		if($memberid{$_}{'pmdisable'} && !$adminoverride) { error("$pmtxt[146] $memberid{$_}{'sn'}."); }

		$cnt = 0;
		fopen(FILE,"$members/$_.prefs");
		while( $value = <FILE> ) {
			chomp $value;
			$prefs{$_}->[$cnt] = $value;
			++$cnt;
		}
		fclose(FILE);

		if(!$adminoverride && !$members{'Administrator',$username}) {
			@blocked = split(/\|/,$prefs{$_}->[0]);
			foreach $block (@blocked) {
				if($username eq $block) { error("$pmtxt[75] $_ $pmtxt[76]"); }
			}
		}

		# Check the PM quota
		GetMemberID($_);
		$pmdis = 0;
		if($pmmaxquota && !$adminoverride && !$members{'Administrator',$_}) {
			$size = -s("$members/$_.pm");
			if($size > 0) { $size = sprintf("%.2f",($size/1024)); }
			$remain = $pmmaxquota-$size;
			if($remain < 0) { # PM limit has been reached
				$remain = "0.00";
				if(!$prefs{$_}->[7]) {
					$prefs{$_}->[7] = 1;
					fopen(FILE,">$members/$_.prefs");
					for($i = 0; $i < 9; $i++) { print FILE "$prefs{$_}->[$i]\n"; }
					fclose(FILE);

					++$ttime;
					fopen(FILE,">>$members/$_.pm");
					print FILE "1|$ttime|$pmtxt[79]|admin|$pmtxt[80]|$ENV{'REMOTE_ADDR'}|1|1\n";
					fclose(FILE);
					if($prefs{$_}->[1]) { smail($memberid{$_}{'email'},$pmtxt[81],$pmtxt[80]); }
				}
				error("$_ $pmtxt[83]");
				$pmdis = 1;
			}
		}
		if($prefs{$_}->[1] && (!$pmdis)) { $emailm[$counter] = $memberid{$_}{'email'}; ++$counter; }
		if(!$adminoverride && !$pmdis) { $sentto .= "$memberid{$_}{'sn'}<br />"; }

		# Send message ...
		if(!$prefs{$_}->[7]) { push(@confirmed,$_); }
	}

	if(@errors) { Write(1); }

	foreach(@confirmed) {
		if($prefs{$_}->[4] && !$managersend) {
			($tsub,$tmess) = split(/\|/,$prefs{$_}->[5]);
			++$ttime;
			push(@esend,"1|$ttime|$tsub|$_|$tmess|$ENV{'REMOTE_ADDR'}|1|3|$pmtxt[99]");
			fopen(FILE,">>$members/$_.pm");
			++$ttime;
			print FILE "2|$ttime|$tsub|$username|$tmess|$ENV{'REMOTE_ADDR'}||3|$pmtxt[99]\n";
			fclose(FILE);
		}
	}
	$date_time = get_date(time,1);
	$mcut = $message;
	$BCSmile = 0;
	$message = BC($message);
	$sendmessage = qq~$memberid{$username}{'sn'} $pmtxt[84] ($date_time):<hr /><br />$message<br /><br /><hr /><span class="smalltext"><a href="$rurl\lv-memberpanel/a-pm/">$pmtxt[85]</a>.</span>~;
	$message = $mcut;
	foreach(@emailm) {
		if($NOEM{$_}) { next; }
		smail($_,"$pmtxt[86]: $subject",$sendmessage);
		$NOEM{$_} = 1;
	}
	fopen(FILE,"$members/$username.prefs");
	@perprefs = <FILE>;
	fclose(FILE);
	chomp @perprefs;

	foreach(@confirmed) {
		if($NO{$_}) { next; }
		++$ttime;
		fopen(FILE,">>$members/$_.pm");
		print FILE "1|$ttime|$subject|$username|$message|$ENV{'REMOTE_ADDR'}|1|$adminadd|$FORM{'other'}|$FORM{'flag'}|$FORM{'smile'}\n";
		fclose(FILE);

		%addtoID = (
			'pmcnt' => ++$memberid{$_}{'pmcnt'},
			'pmnew' => ++$memberid{$_}{'pmnew'}
		);

		SaveMemberID($_);

		if($adminoverride == 0 && $FORM{'sentitems'} == 1 && !$managersend) {
			++$ttime;
			fopen(FILE,">>$members/$username.pm");
			print FILE "2|$ttime|$subject|$_|$message|$ENV{'REMOTE_ADDR'}||$adminadd|$FORM{'other'}||$FORM{'smile'}\n";
			fclose(FILE);
		}
		$NO{$_} = 1;
	}
	if($adminoverride && !$managersend) {
		if($FORM{'sentitems'} == 1) {
			++$ttime;
			fopen(FILE,">>$members/$username.pm");
			print FILE "2|$ttime|$subject|$pmtxt[87]|$message|$ENV{'REMOTE_ADDR'}||$adminadd|$FORM{'other'}||$FORM{'smile'}\n";
			fclose(FILE);
		}
		$sentto = "$pmtxt[47]<br />";
	}
	fopen(FILE,">>$members/$username.pm");
	foreach(@esend) { print FILE "$_\n"; }
	fclose(FILE);

	# Mark as replied
	if($URL{'m'}) {
		fopen(FILE,"$members/$username.pm");
		@replied = <FILE>;
		fclose(FILE);
		chomp @replied;

		fopen(FILE,"+>$members/$username.pm");
		foreach(@replied) {
			($folder,$mid,$ttitle,$replyuser,$message,$ip,$t1,$t2,$t3,$t4,$t5) = split(/\|/,$_);
			if($folder == $load && $URL{'m'} == $mid) { print FILE "$folder|$mid|$ttitle|$replyuser|$message|$ip|$t1|$t2|$t3|2|$t5\n"; }
				else { print FILE "$_\n"; }
		}
		fclose(FILE);
	}

	if($managersend) { return(1); }

	$addtoID{'lastpm'} = time;
	SaveMemberID($username);

	if($perprefs[3]) { redirect("$surl\lv-memberpanel/a-pm/f-$URL{'f'}/"); }

	$callt = qq~<img src="$images/pm2_sm.gif" alt="" /> $pmtxt[144]</strong>~;
	$morecaller = $pmtxt[182];
	$displaycenter = <<"EOT";
<meta http-equiv="refresh" content="5;url=$surl\lv-memberpanel/a-pm/f-$URL{'f'}/">
<table class="border" width="425" cellpadding="4" cellspacing="1">
 <tr>
  <td class="win smalltext"><strong>$pmtxt[88]</strong></td>
 </tr><tr>
  <td class="win2 smalltext"><br /><center>$sentto<br /><input type="button" onclick="location='$surl\lv-memberpanel/a-pm/f-$URL{'f'}/'" value="&nbsp; $gtxt{'26'} &nbsp;" /></center><br /></td>
 </tr>
</table>
EOT
}

sub Prefs {
	if($URL{'p'} == 2) { Prefs2(); }

	$CHECK1["$prefs[1]"] = ' checked="checked"';
	$CHECK2["$prefs[2]"] = ' checked="checked"';
	$CHECK3["$prefs[3]"] = ' checked="checked"';
	$CHECK4["$prefs[4]"] = ' checked="checked"';
	($sub,$mess) = split(/\|/,$prefs[5]);
	$subject = Unformat($sub);
	$message = Unformat($mess);

	$callt = qq~<img src="$images/pm2_sm.gif" alt="" /> $pmtxt[177]~;

	$displaycenter = <<"EOT";
<form action="$surl\lv-memberpanel/a-pm/s-prefs/f-$URL{'f'}/p-2/" id="pm" method="post">
<table class="border" cellspacing="1" cellpadding="5" width="100%">
 <tr>
  <td class="catbg smalltext"><strong>$pmtxt[143]</strong></td>
 </tr><tr>
  <td class="win" style="padding: 0px">
   <table cellpadding="5" cellspacing="0" width="100%">
    <tr>
     <td style="height: 5px" class="win2"></td>
	<td></td>
    </tr><tr>
     <td style="width: 35px" class="center win2"><input type="checkbox" name="email" value="1"$CHECK1[1] /></td>
     <td><strong>$pmtxt[93]</strong></td>
    </tr><tr>
     <td class="center win2"><input type="checkbox" name="outbox" value="1"$CHECK2[1] /></td>
     <td><strong>$pmtxt[95]</strong></td>
    </tr><tr>
     <td class="center win2"><input type="checkbox" name="sent" value="1"$CHECK3[1] /></td>
     <td><strong>$pmtxt[97]</strong></td>
    </tr><tr>
     <td style="height: 5px" class="win2"></td>
	<td></td>
    </tr>
   </table>
  </td>
 </tr><tr>
  <td class="catbg smalltext"><strong>$pmtxt[99]</strong></td>
 </tr><tr>
  <td class="win2 smalltext">$pmtxt[100]</td>
 </tr><tr>
  <td class="win" style="padding: 0px">
   <table cellpadding="5" cellspacing="0" width="100%">
    <tr>
     <td style="height: 5px" class="win2"></td>
	<td></td>
    </tr><tr>
     <td style="width: 35px" class="center win2"><input type="checkbox" name="auto" value="1" onclick="OpenTemp()"$CHECK4[1] /></td>
     <td><strong>$pmtxt[77]</strong></td>
    </tr><tr id="temp" style="display:none;">
     <td class="win2"></td>
     <td colspan="2">
      <table cellpadding="5" cellspacing="0" class="innertable">
       <tr>
        <td><strong>$pmtxt[102]:</strong></td>
        <td><input type="text" value="$subject" name="autosub" size="30" /></td>
       </tr><tr>
        <td class="vtop"><strong>$pmtxt[103]:</strong></td>
        <td><textarea name="automessage" cols="50" rows="6">$message</textarea></td>
       </tr>
      </table>
     </td>
    </tr><tr>
     <td style="height: 5px" class="win2"></td>
	<td></td>
    </tr>
   </table>
  </td>
 </tr><tr>
  <td class="win2"><input type="submit" value=" $pmtxt[104] " /></td>
 </tr>
</table>
</form>
<script type="text/javascript">
//<![CDATA[
function OpenTemp() {
	if(document.getElementById) { openItem = document.getElementById('temp'); }
	else if (document.all){ openItem = document.all['temp']; }
	else if (document.layers){ openItem = document.layers['temp']; }

	if(document.forms['pm'].auto.checked == true) { ShowType = ""; }
		else { ShowType = "none"; }

	if(openItem.style) { openItem.style.display = ShowType; }
		else { openItem.visibility = "show"; }
}
OpenTemp();
//]]>
</script>
EOT
}

sub Prefs2 {
	$FORM{'blocked'} =~ s/\cM//g;
	$FORM{'blocked'} =~ s/\n/\|/g;
	$email = $FORM{'email'} || 0;
	$outbox = $FORM{'outbox'} || 0;
	$sent = $FORM{'sent'} || 0;
	$auto = $FORM{'auto'} || 0;
	$autosub = Format($FORM{'autosub'});
	$automessage = Format($FORM{'automessage'});
	if($auto && $automessage eq '') { error($pmtxt[105]); }
	if(length($automessage) > 800) { error($pmtxt[106]); }
	fopen(FILE,">$members/$username.prefs");
	print FILE "$prefs[0]\n$email\n$outbox\n$sent\n$auto\n$autosub|$automessage\n$prefs[6]\n$prefs[7]\n$prefs[8]\n";
	fclose(FILE);
	redirect("$surl\lv-memberpanel/a-pm/f-$URL{'f'}/");
}

sub PMBlock {
	if($URL{'user'} eq 'All Members') { error($pmtxt[107]); }
	fopen(FILE,"$members/$username.prefs");
	@prefs = <FILE>;
	fclose(FILE);
	chomp @prefs;
	@blocks = split(/\|/,$prefs[0]);
	foreach (@blocks) {
		chomp;
		if($_ eq $URL{'user'}) { $alreadyon = 1; }
	}

	GetMemberID($URL{'user'});
	if($memberid{$URL{'user'}}{'sn'} eq '') { $fullmemname = $URL{'user'}; }
		else { $fullmemname = $userurl{$URL{'user'}}; }

	if($alreadyon != 1) {
		fopen(FILE,"+>$members/$username.prefs");
		print FILE "$prefs[0]$URL{'user'}|\n";
		for($q = 1; $q < @prefs; $q++) {
			print FILE "$prefs[$q]\n";
		}
		fclose(FILE);
		$title = $pmtxt[110];
		$message = "$fullmemname $pmtxt[111]";
	} else {
		$title = $pmtxt[112];
		$message = "$fullmemname $pmtxt[113]";
	}

	redirect("$surl\lv-memberpanel/a-pm/s-blist/");
}

sub PMDisplay {
	fopen(FILE,"$members/$username.pm");
	@pm = <FILE>;
	fclose(FILE);
	chomp @pm;
	foreach(@pm) {
		($med,$pmid,$tm,$tof,$message,$ip,$new) = split(/\|/,$_);
		if($med eq $load && $pmid == $URL{'m'}) { $found = 1; last; }
	}
	if($found != 1) { error($pmtxt[115]); }
	GetMemberID($tof);
	if($memberid{$tof}{'sn'} eq '') { $tofrom = $tof; }
		else { $tofrom = qq~$userurl{$tof}<br /><strong><a href="$surl\lv-memberpanel/a-pm/s-blist/p-2/buddy-$tof/">$pmtxt[169]</a></strong>~; }
	$dategot = get_date($pmid);

	if($load == 1 || $load == 3) {
		if($new == 1) {
			fopen(FILE,"+>$members/$username.pm");
			foreach(@pm) {
				($tmed,$tpmid,$ttm,$ttof,$tmessage,$tip,$tnew,$tmore,$tmore2,$flag,$smile) = split(/\|/,$_);
				if($tpmid == $URL{'m'} && $tmed == $load) {
					if($flag) { $fl = 1; } $ttmT = $ttm;
					print FILE "$tmed|$tpmid|$ttm|$ttof|$tmessage|$tip|0|$tmore|$tmore2||$smile\n";
				} else { print FILE "$_\n"; }
			}
			fclose(FILE);

			$addtoID{'pmnew'} = --$memberid{$username}{'pmnew'};
			SaveMemberID($username);
			--$memberid{$username}{'pmnew'};
		}
	}
	if($fl == 1 && $memberid{$tof}{'sn'} ne '') {
		$curforumtime = time;
		$thisdate = get_date(time);
		fopen(USER,"+>>$members/$tof.pm");
		print USER "1|$curforumtime|$pmtxt[55]: $ttmT|$username|$memberid{$username}{'sn'} $pmtxt[117] $thisdate.|$ENV{'REMOTE_ADDR'}|1|2\n";
		fclose(USER);
		$cntme = 0;
		fopen(FILE,"$members/$tof.prefs");
		@prefs = <FILE>;
		fclose(FILE);
		chomp @prefs;
		if($prefs[1]) { smail($_,"$pmtxt[86]: $subject",$sendmessage); }
	}

	if(!$smile) { $smiley = $pmtxt[138]; } else { $smiley = $pmtxt[120]; }

	$callt = qq~<img src="$images/pm2_sm.gif" alt="" /> $pmtxt[121]~;

	$titlem = CensorList($tm);

	$displaycenter = <<"EOT";
<script type="text/javascript">
//<![CDATA[
function clear(url) {
 if(window.confirm("$pmtxt[136]")) { location = url; }
}
//]]>
</script>
<table class="border" cellpadding="4" cellspacing="1" width="100%">
 <tr>
  <td class="win">
   <table cellpadding="4" cellspacing="0" width="100%">
    <tr>
     <td style="width: 30%" class="right smalltext"><strong>$pmtxt[12]:</strong></td>
     <td style="width: 70%" class="smalltext">$titlem</td>
    </tr><tr>
     <td class="right vtop smalltext"><strong>$select:</strong></td>
     <td class="smalltext">$tofrom</td>
    </tr><tr>
     <td class="right smalltext"><strong>$pmtxt[14]:</strong></td>
     <td class="smalltext">$dategot</td>
    </tr>
   </table>
  </td>
 </tr><tr>
  <td class="win2">
   <table cellpadding="4" cellspacing="0" width="100%">
    <tr>
     <td style="width: 30%" class="right vtop smalltext"><strong>$pmtxt[126]:</strong></td>
     <td style="width: 70%" class="smalltext"><a href="javascript:clear('$surl\lv-memberpanel/a-pm/s-block/user-$tof/')">$pmtxt[137]</a></td>
    </tr><tr>
     <td class="right vtop smalltext"><strong>$pmtxt[129]:</strong></td>
     <td class="smalltext">$smiley</td>
    </tr>
   </table>
  </td>
 </tr><tr>
  <td class="catbg">
   <form action="$surl\lv-memberpanel/a-pm/s-delete/f-$URL{'f'}/" method="post">
   <table cellpadding="0" cellspacing="0" width="100%">
    <tr>
     <td><input type="hidden" name="d_0" value="$URL{'m'}" /><select name="moveto"><option value="3">$pmtxt[27]</option>$folderops</select> <input type="submit" name="move" value="$pmtxt[35]" /></td>
    </tr>
   </table>
   </form>
  </td>
 </tr>
</table><br />
EOT
	if($smile) { $BCSmile = 0; }
	$message = BC($message);
	if($load == 2) { $tof = $username; }

	$guest = UserMiniProfile($tof);
	if(!$guest) {
		$membername = $userurl{$tof};
	} else {
		$profile{$tof} = $tempprof;
		$membername = $tempuser;
	}

	$email = $guest ? qq~<a href="mailto:$email">$Pimg{'email'}</a>~ : $email{$tof};
	$email .= $pmdisable || $guest ? '' : qq~<a href="$surl\lv-memberpanel/a-pm/s-write/t-$tof/">$Pimg{'pm'}</a>~;

	$homepage = ($memberid{$tof}{'sitename'} && $memberid{$tof}{'siteurl'}) ? qq~$sep<a href="$memberid{$tof}{'siteurl'}" title="$memberid{$tof}{'sitename'}"$blanktarget>$Pimg{'site'}</a>$Pmsp2~: '';

	$online = '';
	$usericon = 'user-offline';
	if($activemembers{$tof} && !$memberid{$tof}{'hideonline'}) { $online = $gtxt{'30'}; $usericon = 'user-online'; }
	elsif($logactive && !$memberid{$tof}{'hideonline'} && $lastactive{$tof}) { $online = qq~<a title="$lastactive{$tof}">$gtxt{'31'}</a>~; }
	if(!$guest) { $usericon = qq~<img src="$images/$usericon.png" class="centerimg" alt="" /> ~; }
		else { $usericon = ''; }

	$showip = $members{'Administrator',$username} ? $ip : $pmtxt[183];
	$displaycenter .= <<"EOT";
<table cellpadding="0" cellspacing="0" width="100%" style="margin-bottom: 5px;">
 <tr>
  <td class="right"><a href="$surl\lv-memberpanel/a-pm/s-write/f-$URL{'f'}/m-$URL{'m'}/">$Iimg{'reply'}</a>$Imsp2<a href="javascript:clear('$surl\lv-memberpanel/a-pm/s-mdelete/f-$URL{'f'}/m-$URL{'m'}/')">$Iimg{'remove_pm'}</a>$Imsp2<a href="$surl\lv-print/s-pm/f-$URL{'f'}/m-$URL{'m'}/">$Iimg{'print_pm'}</a></td>
 </tr>
</table>
<table class="border" cellpadding="6" cellspacing="1" width="100%">
 <tr>
  <td class="titlebg" colspan="2"><strong>$titlem</strong></td>
 </tr><tr>
  <td class="win center" style="width: 180px">$usericon<strong>$membername</strong></td>
  <td class="win">
   <table cellpadding="0" cellspacing="2" width="100%">
    <tr>
     <td class="smalltext didate">$dategot</td>
    </tr>
   </table>
  </td>
 </tr><tr>
  <td class="win2 smalltext vtop" style="width: 180px">$profile{$tof}</td>
  <td class="win2 vtop">
   <table cellspacing="0" cellpadding="0" width="100%">
    <tr>
     <td class="postbody vtop">$message</td>
    </tr>$extra
   </table>
  </td>
 </tr><tr>
  <td class="win" style="width: 180px">
   <table width="100%">
    <tr>
     <td class="smalltext"><img src="$images/ip.png" class="leftimg" alt="" /> $showip</td>
     <td class="right smalltext"><strong>$online</strong></td>
    </tr>
   </table>
  </td><td class="win smalltext">$homepage$email$instmsg{$tof}</td>
 </tr>
</table>
EOT
$online = '';
}

sub PMDelete2 {
	if($URL{'p'} eq 'move') { $FORM{"d_0"} = $URL{'m'}; $FORM{'moveto'} = 3; Move(); }

	fopen(FILE,"$members/$username.pm");
	@message = <FILE>;
	fclose(FILE);
	chomp @message;
	foreach (@message) {
		$fnd = 0;
		($med,$pmid) = split(/\|/,$_);
		if($load eq $med) {
			if($URL{'m'} eq $pmid) { $fnd = 1; }
		}
		if(!$fnd) { $deleted .= "$_\n"; }
	}
	fopen(FILE,">$members/$username.pm");
	print FILE $deleted;
	fclose(FILE);

	# Reset the PM over message
	$prefs[7] = 0;
	fopen(FILE,">$members/$username.prefs");
	for($i = 0; $i < 9; $i++) { print FILE "$prefs[$i]\n"; }
	fclose(FILE);

	redirect("$surl\lv-memberpanel/a-pm/f-$URL{'f'}/");
}

sub Folders {
	if($URL{'p'}) { Folders2(); }

	$callt = qq~<img src="$images/thread.png" alt="" /> $pmtxt[147]~;
	$morecaller = $pmtxt[149];
	$displaycenter = <<"EOT";
<form action="$surl\lv-memberpanel/a-pm/s-folders/p-1/" method="post">
<table cellpadding="5" cellspacing="1" class="border" width="100%">
 <tr>
  <td class="catbg smalltext"><strong>$pmtxt[150]</strong></td>
 </tr><tr>
  <td class="win2 smalltext">$pmtxt[151]</td>
 </tr><tr>
  <td class="win" style="padding: 0px">
   <div style="padding: 5px">
   <table cellpadding="5" cellspacing="0" class="innertable">
    <tr>
     <td style="width: 150px"><strong>$pmtxt[23]</strong></td>
     <td class="smalltext">$pmtxt[148]</td>
    </tr><tr>
     <td style="width: 150px"><strong>$pmtxt[25]</strong></td>
     <td class="smalltext">$pmtxt[148]</td>
    </tr><tr>
     <td style="width: 150px"><strong>$pmtxt[27]</strong></td>
     <td class="smalltext">$pmtxt[148]</td>
    </tr>
EOT
	foreach(@folders) {
		($fname,$fid) = split("/",$_);
		$fids{$fid} = $fname;
		$displaycenter .= <<"EOT";
<tr>
 <td colspan="2"><input type="text" name="$fid" value="$fname" size="30" maxlength="30" /></td>
</tr>
EOT
	}

	$displaycenter .= <<"EOT";
   </table></div>
   <div style="padding: 8px" class="win3"><img src="$images/warning.png" class="centerimg" alt="" /> $pmtxt[155]</div>
  </td>
 </tr><tr>
  <td class="catbg smalltext"><strong>$pmtxt[152]</strong></td>
 </tr><tr>
  <td class="win2 smalltext">$pmtxt[153]</td>
 </tr><tr>
  <td class="win">
   <table cellpadding="5" cellspacing="0" class="innertable">
EOT
	$folderucnt = $foldercnt;
	for($i = $folderucnt+4; $i < $folderucnt+7; $i++) {
		while($fids{$i} ne '') { ++$i; ++$folderucnt; }
		$displaycenter .= qq~<tr><td><input type="text" name="new_$i" size="30" maxlength="30" /></td></tr>~;
	}
	$displaycenter .= <<"EOT";
   </table>
  </td>
 </tr><tr>
  <td class="win2"><input type="submit" value="$pmtxt[154]" /></td>
 </tr>
</table>
</form>
EOT
}

sub Folders2 {
	while(($iname,$ivalue) = each(%FORM)) {
		push(@data,"$iname|$ivalue");
	}
	foreach(@data) {
		($iname,$ivalue) = split(/\|/,$_);
		$ivalue =~ s/\n//gsi;
		$ivalue =~ s~\/~&#47;~gsi;
		$iname =~ s/\n//gsi;
		$iname =~ s~\/~&#47;~gsi;
		$current = Format($ivalue);
		if($iname =~ /new_(.*?)\Z/) {
			if($current eq '') { next; }
			if($fids{$1} ne '') { next; } # It's already a folder! Don't overwrite!
			push(@print,"$1|$current");
			next;
		}
		if($current eq '') {
			$nodel = '';
			fopen(FILE,"$members/$username.pm");
			@message = <FILE>;
			fclose(FILE);
			chomp @message;
			foreach (@message) {
				$fnd = 0;
				($med) = split(/\|/,$_);
				if($iname eq $med) { $fnd = 1; }
				if(!$fnd) { $nodel .= "$_\n"; }
			}
			fopen(FILE,">$members/$username.pm");
			print FILE $nodel;
			fclose(FILE);
		} else { push(@print,"$iname|$current"); }
	}

	foreach(sort{$a <=> $b} @print) {
		($t1,$t2) = split(/\|/,$_);
		$printdata .= "$t2/$t1|";
	}

	fopen(FILE,">$members/$username.prefs");
	print FILE "$prefs[0]\n$prefs[1]\n$prefs[2]\n$prefs[3]\n$prefs[4]\n$prefs[5]\n$printdata\n$prefs[7]\n$prefs[8]\n";
	fclose(FILE);

	redirect("$surl\lv-memberpanel/a-pm/s-folders/");
}

sub Search {
	if($URL{'p'}) { Search2(); return; }

	$callt = qq~<img src="$images/search.png" class="leftimg" alt="" /> $pmtxt[163]~;
	$displaycenter = <<"EOT";
<form action="$surl\lv-memberpanel/a-pm/s-search/p-1/" method="post">
<table cellpadding="5" cellspacing="1" class="border" width="100%">
 <tr>
  <td class="catbg smalltext"><strong>$pmtxt[162]</strong></td>
 </tr><tr>
  <td class="win" style="padding: 8px">
   <table cellpadding="5" cellspacing="0" class="innertable">
    <tr>
     <td><strong>$pmtxt[161]:</strong></td>
     <td><input type="text" name="search" size="35" /></td>
    </tr><tr>
     <td><strong>$pmtxt[178]:</strong></td>
     <td><input type="text" name="touser" size="30" /></td>
    </tr><tr>
     <td><strong>$pmtxt[160]:</strong></td>
     <td><select name="inside"><option value="0">$pmtxt[159]</option><option value="1">$pmtxt[23]</option><option value="2">$pmtxt[25]</option><option value="3">$pmtxt[27]</option>$folderops</select></td>
    </tr><tr>
     <td><strong>$pmtxt[179]:</strong></td>
     <td><input type="text" name="fresults" value="5" size="5" maxlength="4" /></td>
    </tr><tr>
     <td><strong>$pmtxt[180]:</strong></td>
     <td><input type="text" name="results" value="30" size="5" maxlength="4" /></td>
    </tr>
   </table>
  </td>
 </tr><tr>
  <td class="win2"><input type="submit" value="$pmtxt[157]" /></td>
 </tr>
</table>
</form>
EOT
}

sub Search2 {
	if($FORM{'search'} eq '') { error($gtxt{'bfield'}); }
	$callt = qq~<img src="$images/search.png" class="leftimg" alt="" /> $pmtxt[156]~;

	$displaycenter = qq~<table cellpadding="4" cellspacing="1" class="border" width="100%">~;
	$fids{'1'} = $pmtxt[23];
	$fids{'2'} = $pmtxt[25];

	$FORM{'touser'} = FindUsername($FORM{'touser'}) || '';

	foreach(sort {$a <=> $b} @pmdata) {
		($folder,$mid,$sub,$puser,$message) = split(/\|/,$_);
		if($FORM{'inside'} && $FORM{'inside'} != $folder) { next; }
		if($message !~ /\Q$FORM{'search'}\E/sig && $sub !~ /\Q$FORM{'search'}\E/sig) { next; }
		if($FORM{'touser'} && $puser !~ /\Q$FORM{'touser'}\E/sig) { next; }
		$message = BC($message);
		GetMemberID($puser);

		if($memberid{$puser}{'sn'} eq '') { $puser = $puser; }
			else { $puser = $userurl{$puser}; }
		++$counter;
		if($folder != $current) {
			$current = $folder;
			$displaycenter .= <<"EOT";
<tr>
 <td class="catbg smalltext" colspan="2"><strong>$fids{$folder}</strong></td>
</tr>
EOT
			$foldercnt = 1;
		} elsif($FORM{'fresults'} && $foldercnt > $FORM{'fresults'}) { next; }
		$displaycenter .= <<"EOT";
<tr>
 <td class="win center" rowspan="2" style="width: 25px"><strong>$counter</strong></td>
 <td class="win2">
  <table width="100%">
   <tr>
    <td class="smalltext"><strong><a href="$surl\lv-memberpanel/a-pm/s-display/f-$folder/m-$mid/">$sub</a></strong></td>
    <td class="right smalltext"><strong>$pmtxt[165]:</strong> $puser</td>
   </tr>
  </table>
 </td>
</tr><tr>
 <td class="win smalltext">$message</td>
</tr>
EOT
		if($FORM{'results'} && $counter > $FORM{'results'}-1) { last; }
		++$foldercnt;
	}
	if(!$counter) {
		$displaycenter .= <<"EOT";
<tr>
 <td class="win center" colspan="2"><strong>$pmtxt[164]</strong></td>
</tr>
EOT
	}
	$displaycenter .= "</table>";
}

sub LoadBuddys {
	@blocklist = split(/\|/,$prefs[0]);
	foreach(@blocklist) {
		$blocked{$_} = 1;
	}
	@buddylist = split(/\|/,$prefs[8]);
	foreach(@buddylist) {
		($name) = split("/");
		$buddy{$name} = 1;
	}
	foreach(@blocklist) {
		if(!$buddy{$_}) { push(@buddylist,$_); }
	}
	if($_[0] == 1) { return; }
	if($URL{'p'}) { SaveBuddys(); return; }
	$callt = qq~<img src="$images/profile_sm.gif" alt="" /> $profiletxt[257]~;
	$morecaller = $pmtxt[170];

	$displaycenter = <<"EOT";
<form action="$surl\lv-memberpanel/a-pm/s-blist/p-1/" method="post">
<table width="100%" cellpadding="4" cellspacing="1" class="border">
 <tr>
  <td class="catbg smalltext"><strong>$pmtxt[171]</strong></td>
 </tr><tr>
  <td class="win2 smalltext">$pmtxt[176]</td>
 </tr><tr>
  <td class="win"><table cellpadding="5" cellspacing="0" class="innertable">
   <tr>
    <td class="center vtop smalltext" style="width: 150px"><strong>$pmtxt[172]</strong></td>
    <td style="width: 200px" class="smalltext center"><strong>$pmtxt[173]</strong><br />$pmtxt[174]</td>
    <td style="width: 200px" class="vtop smalltext center"><strong>$pmtxt[181]</strong></td>
   </tr>
EOT
	foreach(@buddylist) {
		($name,$display) = split("/");
		++$counter;
		if(!-e("$members/$name.dat")) { next; }
		$sel{''} = '';
		$sel{$blocked{$name}} = ' selected="selected"';
		GetMemberID($name);
		$displaycenter .= <<"EOT";
<tr>
 <td class="center"><input type="text" name="name_$counter" value="$memberid{$name}{'sn'}" size="25" /></td>
 <td class="center"><input type="text" name="display_$counter" value="$display" size="30" /></td>
 <td class="center"><select name="block_$counter"><option value="1"$sel{1}>$gtxt{'33'}</option><option value="0"$sel{''}>$gtxt{'32'}</option></select></td>
</tr>
EOT
	}
	$displaycenter .= <<"EOT";
  </table></td>
 </tr><tr>
  <td class="catbg smalltext"><strong>$pmtxt[175]</strong></td>
 </tr><tr>
  <td class="win"><table cellpadding="5" cellspacing="0" class="innertable">
   <tr>
    <td class="center vtop" style="width: 150px"><input type="text" name="name_new" size="25" /></td>
    <td class="center" style="width: 200px"><input type="text" name="display_new" size="30" /></td>
    <td class="center" style="width: 200px"><select name="block_new"><option value="1">$gtxt{'33'}</option><option value="0" selected="selected">$gtxt{'32'}</option></select></td>
   </tr>
  </table></td>
 </tr><tr>
  <td class="win2"><input type="hidden" name="cnt" value="$counter" /><input type="submit" value=" $pmtxt[104] " /></td>
 </tr>
</table>
</form>
EOT
}

sub SaveBuddys {
	my($o);

	if($URL{'p'} == 2) {
		LoadBuddys(1);
		foreach(@buddylist) {
			($name,$display) = split("/");
			$printdata .= "$name/$display|";
			$onlist{$name} = 1;
		}
		if(!$onlist{$URL{'buddy'}} && -e("$members/$URL{'buddy'}.dat")) { $printdata .= "$URL{'buddy'}/|"; }

		fopen(FILE,">$members/$username.prefs");
		print FILE "$prefs[0]\n$prefs[1]\n$prefs[2]\n$prefs[3]\n$prefs[4]\n$prefs[5]\n$prefs[6]\n$prefs[7]\n$printdata\n";
		fclose(FILE);
	} else {
		for($o = 1; $o <= $FORM{'cnt'}; ++$o) {
			$FORM{"display_$o"} =~ s/\n//gsi;
			$FORM{"display_$o"} =~ s~\/~&#47;~gsi;
			$FORM{"display_$o"} = Format($FORM{"display_$o"});

			$findname = FindUsername($FORM{"name_$o"});

			if($findname eq '' || $onlist{$findname}) { next; }

			$onlist{$findname} = 1;
			$printdata .= qq~$findname/$FORM{"display_$o"}|~;
			if($FORM{"block_$o"}) { $blockdata .= qq~$findname|~; }
		}

		$findname = FindUsername($FORM{'name_new'});

		if($findname ne '' && !$onlist{$findname}) {
			$FORM{'display_new'} =~ s/\n//gsi;
			$FORM{'display_new'} =~ s~\/~&#47;~gsi;
			$printdata .= qq~$findname/$FORM{'display_new'}|~;
			if($FORM{'block_new'}) { $blockdata .= "$findname|"; }
		}

		fopen(FILE,">$members/$username.prefs");
		print FILE "$blockdata\n$prefs[1]\n$prefs[2]\n$prefs[3]\n$prefs[4]\n$prefs[5]\n$prefs[6]\n$prefs[7]\n$printdata\n";
		fclose(FILE);
	}

	redirect("$surl\lv-memberpanel/a-pm/s-blist/");
}
1;