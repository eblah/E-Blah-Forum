#############################################
# E-Blah Bulletin Board Systems        2008 #
#############################################
# Copyright (c) 2001 - 2008 E-Blah.         #
#############################################

CoreLoad('Post',1);

if($memberid{$username}{'bcadvanced'}) { $BCAdvanced = 0; }

sub Post {
	$uallow = 0 if(!GetMemberAccess($binfo[11]));
	$maxsize_t = $maxsize;

	if($URL{'a'} eq 'smilies') { Smilies(); }
	if($username eq 'Guest' && !$noguestp) { error($gtxt{'noguest'}); }
	PostRights();
	if($URL{'a'} eq 'modify' || $URL{'q'} ne '') {
		if($URL{'q'} ne '') { $URL{'n'} = $URL{'q'}; }
		if($username eq 'Guest' && $URL{'a'} eq 'modify') { error($posttxt[2]); }
		GetMessages();
		GetMessage();
		$counter = 0;
		$wefnd = 0;
		foreach(@messagez) {
			if($counter != $URL{'n'}) { ++$counter; next; }
			($postinguser,$message,$ip,$email,$date,$smile,$t,$t,$t,$modsource) = split(/\|/,$_);
			$wefnd = 1;
			last;
		}
		if($wefnd != 1) { error($posttxt[3]); }
		if($URL{'a'} eq 'modify' && (!$members{'Administrator',$username} && !$ismod && !$modon && $username ne $postinguser && !$modifyon)) { error($posttxt[4]); }

		if($URL{'quick'} eq '') { $qmodify = Unformat($message); }
			else { $qmodify = $message; }

		if($URL{'a'} eq 'modify') {
			if($modifytime && (!$members{'Administrator',$username} && !$ismod && !$modon && !$modifyon) && $date+($modifytime*3600) < time) { error($posttxt[129]); }

			$title = $posttxt[119];
			if(!$URL{'n'}) {
				$titleed = $mtitle; $sel{$micon} = ' selected="selected"';

				fopen(FILE,"$messages/$URL{'m'}.poll");
				@polldata = <FILE>;
				fclose(FILE);
				chomp @polldata;
				$psub = $polldata[0];

				if(!$preview) {
					$res{1} = '';
					$res2{1} = '';
					$i = 1;
					foreach $pollops (@polldata) {
						$data .= $pollops."<br />";
						($type,$value,$opvalue) = split(/\|/,$pollops);
						if($type eq 'op') { $value{$i} = $value; $currentvalue{$i} = $opvalue; ++$i; }
						elsif($type eq 'res') { $res{$value} = ' checked="checked"'; }
						elsif($type eq 'res2') { $res2{$value} = ' checked="checked"'; }
						elsif($type eq 'timelimit') { $timelimit = $value; }
					}
				}
			}
		} else {
			$title = "$posttxt[6] '$mtitle' $posttxt[5]";
			$qmodify =~ s~\[quot(.+?)\](.*?)\[/quote\]~~gsi;
			$qmodify = "\[quote=$postinguser\]$qmodify\[/quote\]\n\n";
		}
		$psmiley{$smile} = ' checked="checked"';
	} elsif($URL{'m'} ne '') {
		GetMessages();
		GetMessage();

		if(!$FORM{'preview'} || $FORM{'xout'}) {
			$statused = NotifyAddStatus($URL{'m'},2);
			if($statused) { $notify = ' checked="checked"'; }
				else { $notify = ''; }
		}

		$title = "$posttxt[6] '$mtitle'";
	}
		else { $title = $posttxt[10]; }
	if($URL{'post'} == 1) { PostThread(); }

	$res{'1'} = ' checked="checked"';
	$results = ' checked="checked"';

	if($micon eq '') { $micon = 'xx.gif'; }
	Post2();
}

sub Smilies {
	if(!$upbc) { error($gtxt{'error'}); }
	print "Content-type: text/html\n\n";
	if($smiliestemplate eq '') {
		$smiliestemplate = "$templates/$dtheme/Smilies.html";
		if(!-e("$smiliestemplate")) { $smiliestemplate = "$prefs/Smilies.html" if !(-e $smiliestemplate); }
	}

	$title = $posttxt[11];

	if($smiliestemplate =~ /.html/) {
		fopen(FILE,"$smiliestemplate");
		@temp = <FILE>;
		fclose(FILE);
		chomp @temp;
		foreach(@temp) {
			$_ =~ s/<blah v="\$(.+?)">/${$1}/gsi;
			if($_ =~ /<blah main>/) { $sfoot = 1; next; }
			elsif(!$sfoot) { $header .= $_; }
				else { $footer .= $_; }
		}
	}

	print $header;
	print <<"EOT";
<script type="text/javascript" src="$bdocsdir/bc.js"></script>
<table class="border" cellpadding="4" cellspacing="1" width="95%">
 <tr>
  <td class="titlebg"><strong><img src="$images/smiley.png" alt="" /> $title</strong></td>
 </tr><tr>
  <td class="win">
   <table cellpadding="2" cellspacing="0" width="100%">
EOT
	fopen(FILE,"$prefs/smiley.txt");
	@smilies = <FILE>;
	fclose(FILE);
	chomp @smilies;
	foreach(@smilies) {
		($smilie,$url) = split(/\|/,$_);
		if(!$show) {
			$ebout .= qq~<tr>~;
			$show = 1;
		}
		++$show;
		$smilie =~ s/'/\\'/gsi;
		print qq~<td class="center"><img src="$simages/$url" onclick="openuse('$smilie');" onmouseover="this.style.cursor='hand';" alt="" /></td>~;
		if($show > 8) { print "</tr>"; $show = 0; next; }
	}
	if($show && $show < 8) {
		$span = 9-$show;
		print qq~<td colspan="$span">&nbsp;</td></tr>~;
	}
	print <<"EOT";
   </table>
  </td>
 </tr>
</table>
EOT
	print $footer;
	exit;
}

sub PostRights {
	if($URL{'m'} eq '') { # New thread
		if(!GetMemberAccess($binfo[3])) { error($posttxt[138]); }
	} else { # Replies
		if(!GetMemberAccess($binfo[4])) { error($posttxt[138]); }
	}
}

sub GetMessages {
	my($templast,$sb,$sid,%stickme);

	fopen(FILE,"$boards/Stick.txt");
	while(<FILE>) {
		chomp;
		($sb,$sid) = split(/\|/,$_);
		$stickme{$sid} = 1 if($sb eq $URL{'b'});
	}
	fclose(FILE);

	fopen(FILE,"$boards/$URL{'b'}.msg");
	@msg = <FILE>;
	fclose(FILE);
	chomp(@msg);
	foreach(@msg) {
		($mid,$mtitle,$t,$t,$t,$modifypoll,$locked,$micon,$templast) = split(/\|/,$_);
		if($mid == $URL{'m'}) { $fnd = 1; last; }
	}
	if($fnd != 1) { error("$posttxt[18] $URL{'m'}"); }
	if($locked == 1 || $locked == 3 || (!$stickme{$URL{'m'}} && !$members{'Administrator',$username} && ($binfo[15] > 0 && time > $templast+(86400*$binfo[15])))) { error($posttxt[19]); }
}

sub GetMessage {
	fopen(FILE,"$messages/$URL{'m'}.txt");
	@messagez = <FILE>;
	fclose(FILE);
	chomp @messagez;
}

sub StartPoll {
	if($URL{'m'} eq '' && !$FORM{'addpoll'}) {
		print "Content-type: text/html\n\n";
		$ebout = "";
	}
	if($URL{'disable'} == 1) {
		print qq~<div style="padding: 10px"><img src="$images/poll_icon.png" class="centerimg" alt="" /> <a href="#" onclick="javascript:EditMessage('$scripturl\lv-post/a-poll/','','','polling');">$posttxt[146]</a></div>~;
		exit;
	}
	$ebout .= <<"EOT";
<table cellpadding="5" cellspacing="0" width="100%">
 <tr>
  <td class="win">
   <table cellpadding="6" cellspacing="0" width="100%">
    <tr>
     <td class="right" style="width: 40%"><strong>$var{'67'} $posttxt[125]:</strong></td>
     <td style="width: 60%"><input type="hidden" name="addpoll" value="1" /><input type="text" name="psubject" value="$psub" maxlength="50" size="40" /></td>
    </tr>
   </table>
  </td>
 </tr><tr>
  <td class="win2">
   <table cellpadding="6" cellspacing="0" width="100%">
EOT
	for($i = 1; $i <= $pollops; ++$i) {
		$ebout .= <<"EOT";
    <tr>
     <td class="right smalltext" style="width: 40%"><strong>$posttxt[117] $i.</strong></td>
     <td style="width: 60%"><input type="text" name="$i" value="$value{$i}" maxlength="100" size="30" /></td>
    </tr>
EOT
		if($members{'Administrator',$username}) {
			$ebout .= <<"EOT";
    <tr>
     <td>&nbsp;</td>
     <td class="smalltext">$posttxt[127]: <input type="text" name="currentvalue_$i" value="$currentvalue{$i}" size="4" maxlength="4" /></td>
    </tr>
EOT
		}
	}
	$ebout .= <<"EOT";
    <tr>
     <td colspan="2" class="center smalltext"><strong>$posttxt[23]</strong></td>
    </tr>
   </table>
  </td>
 </tr><tr>
  <td class="win">
   <table cellpadding="6" cellspacing="0" width="100%">
    <tr>
     <td class="right" style="width: 40%"><strong>$posttxt[24]</strong></td>
     <td style="width: 60%" class="vtop smalltext"><input type="checkbox" name="results" value="1"$res{'1'} /> &nbsp; $posttxt[25]</td>
    </tr><tr>
     <td class="right" style="width: 40%"><strong>$posttxt[123]</strong></td>
     <td style="width: 60%" class="vtop smalltext"><input type="checkbox" name="multi" value="1"$res2{'1'} /> &nbsp; $posttxt[124]</td>
    </tr><tr>
     <td class="right"><strong>$posttxt[143]:</strong></td>
     <td style="width: 60%" class="vtop smalltext"><input type="text" value="$timelimit" name="timelimit" size="5" /> &nbsp; $posttxt[144]</td>
    </tr>
EOT
	if($URL{'m'}) {
		$ebout .= <<"EOT";
    <tr>
     <td colspan="2"><hr /></td>
    </tr><tr>
     <td class="right" style="width: 40%"><strong>$posttxt[128]</strong></td>
     <td style="width: 60%" class="vtop"><input type="checkbox" name="deletepoll" value="1"$res3{'1'} /></td>
    </tr>
EOT
	}
	$ebout .= <<"EOT";
   </table>
  </td>
 </tr>
EOT
	if($URL{'m'} eq '') {
		$ebout .= <<"EOT";
 <tr>
  <td class="win3" colspan="2" style="padding: 10px"><img src="$images/ban.png" class="centerimg" alt="" /> <a href="#" onclick="javascript:EditMessage('$scripturl\lv-post/a-poll/disable-1/','','','polling');">$posttxt[147]</a></td>
 </tr>
EOT
	}
	$ebout .= "</table>";
	if($URL{'m'} eq '' && !$FORM{'addpoll'}) { print $ebout; exit; }
}

sub Post2 {
	if($URL{'a'} eq 'poll') { StartPoll(); }
	if($URL{'quick'} && $URL{'m'} ne '') { # Lets edit this post quickly ...
		print "Content-type: text/html\n\n";
		if($URL{'quick'} eq '2') {
			$message = $qmodify;
			$message = BC($message);
			print $message;
			exit;
		}
		$qmodify = Unformat($qmodify);

		print <<"EOT";
<form name="edit$URL{'n'}">
<div class="border" style="padding: 1px; width: 100%;">
<div class="win center" style="padding: 5px;"><textarea name="message" rows="15" cols="80" style="width: 98%;">$qmodify</textarea></div>
<div class="win3" style="padding: 5px"><input type="button" onclick="EditMessage('$surl\lv-post/b-$URL{'b'}/a-modify/m-$URL{'m'}/n-$URL{'n'}/post-1/quick-1/',1,document.edit$URL{'n'}.message.value,'m$URL{'n'}')" value="$posttxt[141]" /> <input type="button" onclick="if(window.confirm('$posttxt[139]')) { EditMessage('$surl\lv-post/b-$URL{'b'}/a-modify/m-$URL{'m'}/n-$URL{'n'}/quick-2/',1,document.edit$URL{'n'}.message.value,'m$URL{'n'}'); }" value="$posttxt[140]" /></div>
</div>
</form>
EOT
		exit;
	}

	$tempopen = $FORM{'tempopen'};

	if($BCLoad) { $spanclose = "</span>"; }
	$title = CensorList($title);
	header();
	Mods();
	if($modz) { $modz = "<strong>$ltxt[7]:</strong> $modz"; }

	$ebout .= <<"EOT";
<script type="text/javascript">
//<![CDATA[
function ShowImage(valy) {
 document.getElementById('icon').src = "$images/icons/"+valy;
}
//]]>
</script>

<table cellpadding="1" cellspacing="1" width="100%" class="border">
 <tr>
  <td class="win">
   <table cellpadding="6" cellspacing="0" width="100%">
    <tr>
     <td><img src="$images/crumbs.png" class="centerimg" alt="" /> <a href="$surl">$mbname</a> &nbsp;<strong>&rsaquo;</strong> &nbsp;<a href="$surl\lc-$catid/">$catname</a> &nbsp;<strong>&rsaquo;</strong> &nbsp;<a href="$scripturl/">$boardnm</a> &nbsp;<strong>&rsaquo; &nbsp;$title</strong></td>
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

	$extras = '';
	if($URL{'a'} ne '') { $extras .= "a-$URL{'a'}/"; }
	if($URL{'q'} ne '') { $extras .= "q-$URL{'q'}/"; }
	if($URL{'n'} ne '') { $extras .= "n-$URL{'n'}/"; }

	$ebout .= qq~</table><br /><form action="$surl\lv-post/b-$URL{'b'}/m-$URL{'m'}/post-1/$extras" id="post" method="post" enctype="multipart/form-data">~;

	if($error) {
		$ebout .= <<"EOT";
<table class="border" cellpadding="5" cellspacing="1" width="100%">
 <tr>
  <td class="titlebg"><strong><img src="$images/ban.png" class="centerimg" alt="" /> $rtxt[41]</strong></td>
 </tr><tr>
  <td class="win2">$error</td>
 </tr>
</table><br />
EOT
	}

	if($FORM{'preview'}) { $ebout .= $preview; }

	if($BCLoad) { $color = 'win'; }
		else { $color = 'win2'; }

	if($BCLoad || $BCSmile) { BCWait(); }

	$tempopen = $tempopen ? $tempopen : time;
	$ebout .= <<"EOT";
<script src="$bdocsdir/common.js" type="text/javascript"></script>
<table class="border" cellspacing="1" cellpadding="5" width="100%">
 <tr>
  <td class="titlebg"><strong>$title</strong><input type="hidden" value="$tempopen" name="tempopen" /></td>
 </tr>
EOT
	if($modifytime && $username ne 'Guest' && (!$members{'Administrator',$username} && !$ismod && !$modon && !$modifyon) && $URL{'a'} ne 'modify') {
		$ebout .= <<"EOT";
 <tr>
  <td class="win2 smalltext">$posttxt[130]</td>
 </tr>
EOT
	}
	if($titleed || ($URL{'m'} eq '' || ($URL{'n'} == 0 && $URL{'a'} eq 'modify')) || $username eq 'Guest') {
		$ebout .= <<"EOT";
 <tr>
  <td class="$color">
   <table cellpadding="6" cellspacing="0" width="100%">
EOT
		if($URL{'m'} eq '' || ($URL{'n'} == 0 && $URL{'a'} eq 'modify')) {
			if($BCLoad) { $onload6 = qq~<span onmouseover="funclu('subject')" onmouseout="funclu('wait')">~; }
			if($BCLoad) { $onload7 = qq~<span onmouseover="funclu('icon')" onmouseout="funclu('wait')">~; }
			$ebout .= <<"EOT";
    <tr>
     <td class="right" style="width: 40%"><strong>$posttxt[28] $posttxt[22]:</strong></td>
     <td style="width: 60%">$onload6<input type="text" name="subject" onchange="document.title = this.value + ' - $title - $mbname';" value="$titleed" size="40" maxlength="50" tabindex="1" />$spanclose</td>
    </tr><tr>
     <td class="right" style="width: 40%"><strong>$posttxt[28] $posttxt[31]:</strong></td>
     <td style="width: 60%">$onload7<select name="micon" tabindex="2" onchange="ShowImage(this.value);">
EOT
			# Default icon must stay as it's required ...
			@icon_ = ("xx.gif|$var{0}");
			@sections = ("");
			$sectionf{''} = 1;

			fopen(ICON,"$prefs/MessageIcons.txt");
			while(<ICON>) {
				chomp;
				($section,$icon,$iconname,$icongroups) = split(/\|/,$_);
				if($icongroups ne '' && !GetMemberAccess($icongroups)) { next; }
				if(!$sectionf{$section}) { push(@sections,"$section"); $sectionf{$section} = 1; }
				push(@{"icon_$section"},"$icon|$iconname");
			}
			fclose(ICON);

			foreach $section (@sections) {
				if($section ne '') { $ebout .= qq~<optgroup label="$section">~; }
				foreach(@{"icon_$section"}) {
					($icon,$iconname) = split(/\|/,$_);
					$ebout .= <<"EOT";
<option value="$icon"$sel{$icon}>$iconname</option>
EOT
				}
				if($section ne '') { $ebout .= "</optgroup>"; }
			}

			$ebout .= <<"EOT";
      </select> &nbsp; <img src="$images/icons/$micon" class="centerimg" id="icon" alt="" />$spanclose</td>
    </tr>
EOT
		}
		if($URL{'a'} eq 'modify') {
			GetMemberID($postinguser);
			$postedby = $memberid{$postinguser}{'sn'} ne '' ? $userurl{$postinguser} : FindOldMemberName($postinguser);
			$ebout .= <<"EOT";
    <tr>
     <td class="right" style="width: 40%"><strong>$gtxt{'19'}:</strong></td>
     <td style="width: 60%">$postedby</td>
    </tr>
EOT
		} else {
			if($username eq 'Guest') {
				$postedby = qq~<input type="text" tabindex="3" name="username" value="$unpost" size="25" maxlength="25" />~;
				$guestemail = <<"EOT";
    <tr>
     <td class="right" style="width: 40%"><strong>$gtxt{'23'}:</strong></td>
     <td style="width: 60%"><input type="text" tabindex="4" name="email" size="30" value="$epost" maxlength="100" /></td>
    </tr>
EOT
			$ebout .= <<"EOT";
    <tr>
     <td class="right" style="width: 40%"><strong>$gtxt{'19'}:</strong></td>
     <td style="width: 60%">$postedby</td>
    </tr>$guestemail
EOT
			}
		}
	$ebout .= <<"EOT";
   </table>
  </td>
 </tr>
EOT
	}

	if((GetMemberAccess($binfo[5]) && $URL{'m'} eq '') || ($titleed && $modifypoll)) {
		$ebout .= <<"EOT";
 <tr>
  <td class="catbg">$posttxt[148]</td>
 </tr><tr>
  <td class="win2" style="padding: 0px" id="polling">
EOT
		if($titleed && $modifypoll || $FORM{'addpoll'}) { StartPoll(); }
			else { $ebout .= qq~<div style="padding: 10px"><img src="$images/poll_icon.png" class="centerimg" alt="" /> <a href="#" onclick="javascript:EditMessage('$scripturl\lv-post/a-poll/','','','polling'); return false;">$posttxt[146]</a></div>~; }

		$ebout .= <<"EOT";
  </td>
 </tr>
EOT
	}

	$ebout .= <<"EOT";
 <tr>
  <td class="catbg">$posttxt[149]</td>
 </tr><tr>
  <td class="win" style="padding: 0px">
   <table cellpadding="0" cellspacing="0" width="100%">
    <tr>
     <td>
EOT
	if($BCLoad) {
		if(!$BCAdvanced) { BCLoad(); }
			else { BCLoadAE(); }
	}
	if($BCLoad) { $onload3 = qq~<span onmouseover="funclu('message')" onmouseout="funclu('wait')">~; }
	$messagelength = !$BCSmile ? 100 : 70;
	$qmodify =~ s/</&lt;/g;
	$qmodify =~ s/>/&gt;/g;
	$ebout .= <<"EOT";
     <table cellpadding="8" cellspacing="0" width="100%">
      <tr>
       <td style="width: $messagelength%">
	   $onload3<textarea name="message" id="message" tabindex="5" rows="12" cols="80" style="width: 98%">$qmodify</textarea>$spanclose
       </td><td class="vtop win2" style="padding: 0px">
EOT
	if($BCSmile) {
		if(!$BCAdvanced) { BCSmile(); }
			else { BCSmileAE(); }
	}

	$ebout .= <<"EOT";
	  </td>
	 </tr>
	</table>
    </td>
   </tr>
   </table>
  </td>
 </tr>
EOT

	if($URL{'a'} ne 'modify' && (($uallow eq 2 && $username ne 'Guest') || ($uallow eq 3 && $members{'Administrator',$username}) || ($uallow eq 1))) {
		$maxsizedisplay = $maxsize_t == 0 ? $posttxt[36] : "$maxsize MB"; # MB
		if($maxsize > 0 && $maxsize < 1) { $maxsizedisplay = 1024*$maxsize . " KB"; } # KB
		if($maxsize <= 0) { $maxsizedisplay = "0 KB"; }
		if($allowedext ne '') {
			$aup = "<strong>$posttxt[39]:</strong> ";
			@au = split(/,/,$allowedext);
			foreach (@au) { $aup .= "$_, "; }
			$aup =~ s/, \Z/<br \/>/i;
		}

		$ebout .= <<"EOT";
 <tr>
  <td class="catbg">$posttxt[150]</td>
 </tr><tr>
  <td class="win2">
   <table cellpadding="6" cellspacing="0" width="100%">
    <tr>
     <td style="width: 40%" class="vtop right"><strong>$posttxt[38]:</strong></td>
     <td style="width: 60%"><input type="file" name="ulfile" size="30" class="upload" /> <input type="submit" value="$posttxt[133]" name="uploadonly" />
      <table cellpadding="4" cellspacing="0" width="100%">
EOT

		if($tempopen && -e("$prefs/Hits/$tempopen.temp")) { # Yeah, we're going to find the current temp, and load his currently uploaded files
			fopen(TEMPFILE,"$prefs/Hits/$tempopen.temp");
			while(<TEMPFILE>) {
				chomp;
				if(!-e("$uploaddir/$_") || $alreadythere{$_}) { next; }
				$alreadythere{$_} = 1;
				$size = sprintf("%.3f",((-s("$uploaddir/$_"))/1024/1024));
				$size = "$size MB"; # MB
				if($size > 0 && $size < 1) { $size = 1024*$size . " KB"; } # KB
				$ebout .= <<"EOT";
     <tr>
      <td style="width: 25px" class="center"><img src="$images/disk.png" alt="" /></td>
      <td class="smalltext">$_</td>
      <td class="smalltext">$size</td>
      <td><input type="submit" value="$posttxt[134]" name="del_$_" /></td>
     </tr>
EOT
			}
			fclose(TEMPFILE);
		}

		$ebout .= <<"EOT";
       <tr>
        <td colspan="4" class="smalltext">$aup<strong>$posttxt[40]:</strong> $maxsizedisplay</td>
       </tr>
      </table>
     </td>
    </tr>
   </table>
  </td>
 </tr>
EOT
	}
	if($URL{'a'} eq 'modify') {
		$ebout .= <<"EOT";
 <tr>
  <td class="catbg">$posttxt[151]</td>
 </tr><tr>
  <td class="win">
   <table cellpadding="6" cellspacing="0" width="100%">
    <tr>
     <td class="right" style="width: 40%"><strong>$posttxt[135]:</strong></td>
     <td style="width: 60%"><input type="text" style="width: 98%" name="editreason" maxlength="150" /></td>
    </tr>
EOT

		if($URL{'a'} eq 'modify' && $modsource ne '' && $members{'Administrator',$username}) {
			$ebout .= <<"EOT";
    <tr>
     <td style="width: 40%" class="vtop right"><strong>$posttxt[136]:</strong></td>
     <td style="width: 60%" class="smalltext"><textarea name="modifyedit" rows="4" style="width: 98%">
EOT

			foreach(split(/\>/,$modsource)) { $ebout .= "$_\n"; }

			$ebout .= <<"EOT";
</textarea>$posttxt[137]
     </td>
    </tr>
EOT

		}
		$ebout .= <<"EOT";
   </table>
  </td>
 </tr>
EOT
	}

	if($tagsenable && ($URL{'m'} eq '' || ($URL{'n'} == 0 && $URL{'a'} eq 'modify'))) {
		if(-e("$messages/$URL{'m'}.tags")) {
			fopen(FILE,"$messages/$URL{'m'}.tags");
			@tags = <FILE>;
			fclose(FILE);
			chomp @tags;
			$tags = Unformat($tags[0]);
		}

		$ebout .= <<"EOT";
 <tr>
  <td class="catbg">$posttxt[155]</td>
 </tr><tr>
  <td class="win">
   <table cellpadding="6" cellspacing="0" width="100%">
    <tr>
     <td class="right" style="width: 40%"><strong><img src="$images/tag_edit.png" class="centerimg" alt="" /> $posttxt[155]:</strong></td>
     <td style="width: 60%" class="smalltext"><input type="text" name="tags" size="50" maxlength="100" value="$tags" /> &nbsp; $posttxt[156]</td>
    </tr>
   </table>
  </td>
 </tr>
EOT
	}

	$ebout .= <<"EOT";
 <tr>
  <td class="catbg">$posttxt[152]</td>
 </tr><tr>
  <td class="win">
   <table cellpadding="6" cellspacing="0" width="100%">
EOT

	if($username ne 'Guest') {
		if($memberid{$username}{'notify'} && ($notify ne ' unchecked' && $URL{'m'} eq '')) { $notify = ' checked="checked"'; }
		$ebout .= <<"EOT";
    <tr>
     <td class="right" style="width: 40%"><strong><img src="$images/notify_sm.png" class="centerimg" alt="" /> $posttxt[43]</strong></td>
     <td style="width: 60%" class="smalltext"><input type="checkbox" name="notify" value="1"$notify /> &nbsp; $posttxt[42]</td>
    </tr>
EOT
	}

	if($psmiley{1} || $psmiley{3}) { $smilechecked = ' checked="checked"'; }
	$ebout .= <<"EOT";
    <tr>
     <td class="right" style="width: 40%"><strong>$posttxt[44]</strong></td>
     <td style="width: 60%" class="smalltext"><input type="checkbox" name="smile" value="1"$smilechecked /> &nbsp; $posttxt[120]</td>
    </tr>
EOT
	if($html) {
		if($psmiley{2} || $psmiley{3}) { $htmlc = ' checked="checked"'; }
		$ebout .= <<"EOT";
    <tr>
     <td class="right" style="width: 40%"><strong>$posttxt[81]</strong></td>
     <td style="width: 60%" class="smalltext"><input type="checkbox" name="html" value="2"$htmlc /> &nbsp; $posttxt[121]</td>
    </tr>
EOT
	}
	if($URL{'m'} eq '' && ($members{'Administrator',$username} || $ismod)) {
		$ebout .= <<"EOT";
    <tr>
     <td class="right" style="width: 40%"><strong>$posttxt[45]:</strong></td>
     <td style="width: 60%" class="smalltext"><input type="checkbox" name="sticky" value="1" $stick{'1'} /> &nbsp; $posttxt[122]</td>
    </tr>
EOT
	}
	$time = $FORM{'viewtimer'} ? $FORM{'viewtimer'} : time;
	$ebout .= <<"EOT";
   </table>
  </td>
 </tr><tr>
  <td class="win2 center"><input type="hidden" name="viewtimer" value="$time" /><input type="submit" tabindex="6" value=" $posttxt[46] " name="submit" />&nbsp; <input type="submit" tabindex="7" name="preview" value=" $posttxt[47] " /></td>
 </tr>
</table>
</form>
EOT
	if($URL{'m'} ne '' && $URL{'a'} ne 'modify') { ThreadSummary(); }
	footer();
	exit;
}

sub PostThread { # Start posting now ...
	Mods();
	$mtime = time;
	$found = 0;
	fopen(FILE,"$prefs/ips.txt");
	@log = <FILE>;
	fclose(FILE);
	chomp @log;
	fopen(FILE,"+>$prefs/ips.txt");
	foreach (@log) {
		($remoteip,$logtime) = split(/\|/,$_);
		$plus = $mtime-$iptimeout;
		$minus = $plus-$logtime;
		if($minus < 0) {
			print FILE "$_\n";
			if($remoteip eq $ENV{'REMOTE_ADDR'}) { $found = 1; }
		}
	}
	fclose(FILE);
	if($found && !$members{'Administrator',$username} && $URL{'a'} ne 'modify') { error("$posttxt[48] $iptimeout $posttxt[49]"); }
	$message = Format($FORM{'message'});
	$smiley = $FORM{'smile'}+$FORM{'html'};

	UserDatabase();

	if($username eq 'Guest') {
		$tuser = Format($FORM{'username'}) || 'Guest';
		$temail = Format($FORM{'email'});
		if(-e("$members/$tuser.dat")) { error($posttxt[50]); }
			else {
				foreach(@list2) {
					($un,$sn,$t,$t,$t,$mail) = split(/\|/,$_);
					error($posttxt[50]) if($tuser eq $sn);
					error($posttxt[53]) if($mail eq $temail);
				}
			}

		$uscheck = lc($tuser);
		fopen(FILE,"$prefs/Names.txt");
		while(<FILE>) {
			chomp $_;
			($searchme,$within) = split(/\|/,$_);
			$searchme = lc($searchme);
			if($within) { error($posttxt[50]) if($uscheck =~ /\Q$searchme\E/gsi); }
				else { error($posttxt[50]) if($searchme eq $uscheck); }
		}
		fclose(FILE);

		$tuser .= " (Guest)";
	} else { $tuser = $username; $temail = $memberid{$username}{'email'}; }

	# Let's check for spam ...
	if($akismetkey ne '') {
		if($username eq 'Guest' || ($username ne 'Guest' && $akismetcheck > $memberid{$username}{'posts'})) {
			CoreLoad('Akismet');
			if(!AkismetCheck($tuser,$message,$temail)) {
				++$ExtLog[8]; # Count the spam and error out.
				error($posttxt[142]);
			}
		}
	}

	error($posttxt[52]) if($tuser eq '');
	error($posttxt[53]) if($temail eq '');
	error($posttxt[80]) if($temail !~ /\A([0-9A-Za-z\._\-]{1,})@([0-9A-Za-z\._\-]{1,})+\.([0-9A-Za-z\._\-]{1,})+\Z/);

	$FORM{'tempopen'} = $FORM{'tempopen'} || time;
	if($FORM{'tempopen'}) {
		fopen(TEMPFILE,"$prefs/Hits/$FORM{'tempopen'}.temp");
		while(<TEMPFILE>) {
			chomp;
			if($FORM{"del_$_"} ne '') { unlink("$uploaddir/$_","$uploaddir/thumbnails/$_","$prefs/Hits/$_.txt"); $deleteatts = 1; next; }
			$addupload{$_} = 1;
			$totalusize += -s("$uploaddir/$_");
			if(-e("$uploaddir/$_")) { $atturl .= "$_/"; }
		}
		fclose(TEMPFILE);
		$maxsize -= sprintf("%.2f",($totalusize/1024/1024)); # With other attachments, total size goes down.  ;)
	}

	if($message eq '') { $error = $posttxt[54]; }
	if(length($message) > $maxmesslth && $maxmesslth) { $error = $gtxt{'long'}; }

	if($URL{'m'} eq '') {
		if(length($FORM{'subject'}) > 50) { $error = $posttxt[55]; }
		$subject = Format($FORM{'subject'});
		if($subject eq ' ' || $subject eq '&nbsp;' || $subject eq '') { $error = $posttxt[56]; }
	}

	if($uallow && $FORM{'ulfile'} ne '') { CoreLoad('Attach'); Upload(); }
	if($FORM{'preview'} || $FORM{'uploadonly'} || $deleteatts || $error) { Preview(); }

	for($e = 0; $e < 99; $e++) { # Find a correct time to use (for heavy boards)
		if(-e "$messages/$mtime.txt") { ++$mtime; } else { last; }
	}

	if($FORM{'addpoll'} == 1 && $URL{'a'} ne 'modify') { $poll = 1; PollSave(); PostTopic(); }
	elsif($URL{'a'} eq 'modify') { PostModify(); }
	elsif($URL{'m'} ne '') { ReplyThread(); }
		else { PostTopic(); }

	if($FORM{'tempopen'}) { # Delete the temp file now that all errors have been cleared!  =D
		$atturl =~ s/\/\Z//g;
		unlink("$prefs/Hits/$FORM{'tempopen'}.temp");
	}

	if($URL{'a'} ne 'modify') {
		if($username ne 'Guest' && $binfo[8] eq '') { # Add a post count
			$addtoID{'posts'} = $posts = $memberid{$username}{'posts'}+1;
			$addtoID{'lastpost'} = time;
			SaveMemberID($username);
			UserDatabase($username,$memberid{$username}{'sn'},$posts,$memberid{$username}{'registered'},$memberid{$username}{'dob'},$memberid{$username}{'email'},$memberid{$username}{'rep'});
		}

		fopen(FILE,"+<$boards/$URL{'b'}.ino");
		@binfo = <FILE>;
		seek(FILE,0,0);
		truncate(FILE,0);
		chomp @binfo;
		$posts = $binfo[0]+$bi[0];
		$replys = $binfo[1]+$bi[1];
		print FILE "$posts\n$replys\n";
		fclose(FILE);

		fopen(FILE,"+>>$prefs/ips.txt");
		print FILE "$ENV{'REMOTE_ADDR'}|$mtime\n";
		fclose(FILE);
	}

	foreach(split(",",$newsboard)) { $newsboards{$_} = 1; }

	if($newsboards{$URL{'b'}}) {
		CoreLoad('Portal');
		Shownews('1','html'); # Runs the news, and saves it to ./templates/news.html
		Shownews('1','xml');  # Runs the news, and saves it to ./templates/news.rss
	}

	if(@emails > 0) {
		$msid = $URL{'b'} if($URL{'m'} eq '');

		foreach $mails (@emails) {
			next if($mails eq $username || $sent{$mails});
			$sent{$mails} = 1; # Only spam once

			GetMemberID($mails);
			if($memberid{$mails}{'sn'} ne '') {
				$norun = 0;

				%logged = ();
				fopen(USRLOG,"$members/$mails.log"); # We will ensure this user has only been mailed ONCE (we don't need to fill up their inbox!)
				while( <USRLOG> ) {
					($lstview,$lsttime) = split(/\|/,$_);
					$logged{$lstview} = $lsttime;
				}
				fclose(USRLOG);

				if($URL{'m'} ne '' && $logged{$URL{'m'}} < $lastmessagetime) { $norun = 1; }
				else {
					($t,$t,$t,$t,$t,$t,$t,$t,$lastdate) = split(/\|/,$fdump[0]);
					if(($logged{$msid}-$lastdate) >= 0 || ($logged{"AllRead_$msid"}-$lastdate) >= 0 || ($logged{'AllBoards'}-$lastdate) >= 0) { $norun = 0; }
						else { $norun = 1; }
				}

				smail($memberid{$mails}{'email'},$sendsubject,$sendmessage,$eadmin) if(!$norun);
			}
		}
	}

	redirect();
}

sub PostTopic {
	fopen(FILE,"+>$messages/$mtime.txt") || error("$posttxt[58]: $mtime.txt",1);
	print FILE "$tuser|$message|$ENV{'REMOTE_ADDR'}|$temail|$mtime|$smiley|||$atturl\n";
	fclose(FILE);

	fopen(FILE,">$messages/$mtime.view");
	print FILE "0\n";
	fclose(FILE);

	if($FORM{'notify'}) { NotifyAddStatus($mtime,1,1); }

	$micon = ValIcon($FORM{'micon'});

	fopen(FILE,"+<$boards/$URL{'b'}.msg",1) || error("$posttxt[58]: $URL{'b'}.msg",1);
	@fdump = <FILE>;
	truncate(FILE,0);
	seek(FILE,0,0);
	print FILE "$mtime|$subject|$tuser|$mtime|0|$poll|0|$micon|$mtime|$tuser\n";
	print FILE @fdump;
	fclose(FILE);

	GetMessageDatabase($mtime,$URL{'b'},1);

	$url = "$surl\lm-$mtime/";
	if($uextlog) { ++$ExtLog[1]; ExtClose(); }
	++$bi[0];
	++$bi[1];
	if(($FORM{'sticky'} && $URL{'m'} eq '') && ($members{'Administrator',$username} || $ismod)) { DoSticky(); }

	$FORM{'tags'} =~ s/\n|\'|\"//g;
	if(length($FORM{'tags'}) > 75) { $tags = ''; }
	$tags = Format($FORM{'tags'});

	if($FORM{'tags'} eq '' && $tagsenable && $autotag) {
		fopen(FILE,"$prefs/stopwords.txt");
		@stopwords = <FILE>;
		fclose(FILE);
		chomp @stopwords;
		foreach(@stopwords) { $stopword{$_} = 1; }

		$tagslength = '';
		foreach $testtag (split(' ',$message)) {
			$testtag = lc($testtag);
			if($testtag =~ /\A[0-9A-Za-z\'\-_]+\Z/ && !$stopword{$testtag}) {
				++$enabletag{$testtag};
				$test .= ($enabletag{$testtag}.$testtag."\n");
				if($enabletag{$testtag} >= $autotag) {
					$tags .= $testtag.', ';
					$tagslength += length($testtag);
					last if($tagslength > 70);
					$enabletag{$testtag} = -100;
				}
			}
		}
		$tags =~ s/, \Z//g;
	}

	if($tagsenable && $tags ne '') {
		fopen(TAGS,">$messages/$mtime.tags");
		print TAGS $tags;
		fclose(TAGS);

		CoreLoad('Tags');
		AddTags($mtime,$tags);
	}

	if($binfo[7]) { # Start SPAMMING **EVERYONE!!!!** an e-mail ...
		fopen(USRLIST,"$members/List.txt");
		@mlist = <USRLIST>;
		fclose(USRLIST);
		chomp @mlist;
		foreach(@mlist) {
			if(GetMemberAccess($fewlgrp,$_) && GetMemberAccess($binfo[9],$_)) {
				GetMemberID($_);
				if($memberid{$_}{'email'} && !$memberid{$_}{'ml'}) { push(@emails,$_); }
			}
		}
	}

	if(-e("$boards/$URL{'b'}.mail")) {
		$msid = $URL{'b'};

		fopen(USRMAIL,"$boards/$URL{'b'}.mail");
		while(<USRMAIL>) {
			if(GetMemberAccess($fewlgrp,$_) && GetMemberAccess($binfo[9],$_)) {
				chomp $_;
				push(@emails,$_) if($_ ne '');
			}
		}
		fclose(USRMAIL);
	}

	if($emails[0] ne '') {
		$sendsubject = "$posttxt[10]: $subject";
		$sendmessage = qq~$posttxt[59] "$boardnm" $posttxt[76] "$mbname".\n\n$posttxt[60] <a href="$rurl\lm-$mtime/">$rurl\lm-$mtime/</a>.\n\n\n$gtxt{'25'}~;
	}
}

sub ReplyThread {
	my($addtolist,$activated,$resave,$oldtime,$olduser);
	$msid = $URL{'m'};

	foreach(NotifyAddStatus($msid,3)) {
		($dauser,$datype) = split("/",$_);
		if(!$datype) { push(@emails,$dauser); }
	}

	fopen(FILE,"+>>$messages/$msid.txt") || error("$posttxt[58]: $msid.txt",1);
	print FILE "$tuser|$message|$ENV{'REMOTE_ADDR'}|$temail|$mtime|$smiley|||$atturl\n";
	fclose(FILE);

	# Notify tick on/off add/remove
	if($username ne 'Guest' && !$FORM{'quickreply'}) {
		if($FORM{'xout'}) { $FORM{'notify'} = $notify; }

		foreach(@emails) {
			if($_ ne $username) { $addtolist .= "$_\n"; }
			elsif($_ eq $username && $FORM{'notify'}) { $addtolist .= "$_\n"; $activated = 1; }
			elsif($_ eq $username && !$FORM{'notify'}) { $resave = 1; }
		}

		if($resave || (!$activated && $FORM{'notify'})) {
			$add = 1 if($FORM{'notify'} && !$activated);

			NotifyAddStatus($msid,1,$add);
		}
	}

	if($URL{'a'} eq 'poll') { $poll = 1; } else { $poll = 0; }

	fopen(FILE,"+<$boards/$URL{'b'}.msg",1) || error("$posttxt[58]: $URL{'b'}.msg",1);
	@fdump = <FILE>;
	foreach(@fdump) {
		if($_ =~ m/\A$msid\|/) { $receive = $_; last; }
	}
	truncate(FILE,0);
	seek(FILE,0,0);
	chomp $receive;
	($miduse,$subject,$tempposted,$trdate,$replies,$poll,$type,$micon,$oldtime,$olduser) = split(/\|/,$receive);

	$start = $replies+1;

	print FILE "$msid|$subject|$tempposted|$trdate|$start|$poll|$type|$micon|$mtime|$tuser\n";

	foreach(@fdump) {
		if($_ =~ m/\A$msid\|/) { next; }
		print FILE $_;
	}
	fclose(FILE);

	$tstart = (int($start/$maxmess)*$maxmess);

	# Notify users in the database
	if(@emails) {
		($t,$t,$t,$t,$lastmessagetime) = split(/\|/,$messagez[@messagez-1]);

		$postedonthisdate = get_date($mtime,1);
		if($username eq 'Guest') { $usersentthis = $tuser; } else { $usersentthis = $memberid{$username}{'sn'}; }

		$sendsubject = "$posttxt[64] $subject";
		$sendmessage = qq~$posttxt[62]\n\n$posttxt[116] $postedonthisdate, $usersentthis $posttxt[63], "<a href="$rurl\lm-$msid/s-$tstart/">$subject</a>".\n\n\n$gtxt{'25'}~;
	}

	if($oldtime > $FORM{'viewtimer'} && $olduser ne $username) { $oldtimer = "s-new/new-posts/"; }
		else { $oldtimer = "s-$tstart/#num$start"; }

	$url = "$surl\lm-$msid/$oldtimer";

	if($uextlog) { ++$ExtLog[2]; ExtClose(); }
	++$bi[1];
}

sub PostModify {
	my($tempeditreason);
	$counter = 0;

	$curtime = time;
	if($URL{'n'} == 0 && !$URL{'quick'}) {
		if(length($FORM{'subject'}) > 50) { error($posttxt[55]); }
		$subject = Format($FORM{'subject'});
		if($subject eq ' ' || $subject eq '&nbsp;' || $subject eq '') { error($posttxt[56]); }
		$micon = Format($FORM{'micon'}) || 'xx.gif';
		$micon = ValIcon($FORM{'micon'});

		if($titleed && $modifypoll && !$FORM{'deletepoll'}) { PollSave(); }

		fopen(FILE,"+<$boards/$URL{'b'}.msg",1) || error("$posttxt[58]: $URL{'b'}.msg",1);
		@fdump = <FILE>;
		for($i = 0; $i < @fdump; $i++) {
			if($fdump[$i] =~ m/\A$URL{'m'}\|/) {
				chomp $fdump[$i];
				($miduse,$t,$tempposted,$trdate,$replies,$poll,$type,$t,$ttime,$tuser) = split(/\|/,$fdump[$i]);
				if($FORM{'deletepoll'}) { unlink("$messages/$URL{'m'}.poll","$messages/$URL{'m'}.polled"); $poll = 0; }
				$fdump[$i] = "$miduse|$subject|$tempposted|$trdate|$replies|$poll|$type|$micon|$ttime|$tuser\n";
				last;
			}
		}
		truncate(FILE,0);
		seek(FILE,0,0);
		foreach(@fdump) { print FILE $_; }
		fclose(FILE);

		$FORM{'tags'} =~ s/\n|\'|\"//g;
		if(length($FORM{'tags'}) > 75) { $tags = ''; }
		$tags = Format($FORM{'tags'});

		if($tagsenable && $tags ne '') {
			fopen(TAGS,">$messages/$URL{'m'}.tags");
			print TAGS $tags;
			fclose(TAGS);

			CoreLoad("Tags");
			AddTags($URL{'m'},$tags);
		} else { unlink("$messages/$URL{'m'}.tags"); }
	}

	fopen(FILE,"$messages/$URL{'m'}.txt");
	while( $mline = <FILE> ) {
		chomp $mline;
		($uuser,$t,$oldipsave,$uemail,$ptime,$oldsmiley,$oldedits,$oldedits2,$atturl,$saveedits) = split(/\|/,$mline);
		if($counter == $URL{'n'}) {
			if($oldedits) { $saveedits = "$oldedits/$oldedits2/>"; }
			$FORM{'editreason'} =~ s/(\/|\>|\n)//g;
			if($members{'Administrator',$username} && !$URL{'quick'}) {
				$saveedits = '';
				foreach(split(/\n/,$FORM{'modifyedit'})) { $_ =~ s/\cM//g; $saveedits .= "$_>"; }
			}
			if($curtime > $ptime+600 || $FORM{'editreason'} ne '') {
				$saveedits .= "$curtime/$username/".Format($FORM{'editreason'}).'>';
			}
			if($URL{'quick'}) { $nosmile = $smiley = $oldsmiley; }
			$writedata .= "$uuser|$message|$oldipsave|$uemail|$ptime|$smiley|||$atturl|$saveedits\n";
		} else { $writedata .= "$mline\n"; }
		++$counter;
	}
	fclose(FILE);
	fopen(WRITE,"+>$messages/$URL{'m'}.txt");
	print WRITE $writedata;
	fclose(WRITE);

	if($URL{'quick'}) {
		$message = BC($message);
		print "Content-type: text/html\n\n$message";
		exit;
	} else {
		$tstart = (int($URL{'n'}/$maxmess)*$maxmess);
		$url = "$surl\lm-$URL{'m'}/s-$tstart/";
	}
}

sub PollSave {
	my($timelimit);

	if(length($FORM{'psubject'}) > 50) { error($posttxt[55]); }
	$psubject = Format($FORM{'psubject'});
	if($psubject eq '' || $psubject eq ' ' || $psubject eq '&nbsp;') { error($posttxt[68]); }
	$ecnts = 0;
	for($e = 1; $e <= $pollops; $e++) {
		$form = Format($FORM{"$e"});
		if(length($form) > 250) { error("$posttxt[70] $e $posttxt[71]"); }
		if($members{'Administrator',$username}) { $currentvalue{$e} = $FORM{"currentvalue_$e"}; }

		if($dadata{$form}) { next; }
		$dadata{$form} = 1;

		$votecount += ($pollvcnt = $currentvalue{$e} || 0);
		if($form ne '') { push(@pollops,"$form|$pollvcnt"); }
		if($titleed) { $mtime = $URL{'m'}; }
	}
	if(@pollops < 2) { error($posttxt[72]); }

	$res = $FORM{'results'} ? 1 : 0;
	$res2 = $FORM{'multi'} ? 1 : 0;

	$timelimit = $FORM{'timelimit'} > 365 || $FORM{'timelimit'} < 0 ? '' : $FORM{'timelimit'};

	fopen(FILE,">$messages/$mtime.poll");
	print FILE "$psubject\n";
	print FILE "vc|$votecount\n";
	foreach(@pollops) {
		if($_ ne '') { print FILE qq~op|$_\n~; }
	}
	print FILE "res|$res\n";
	print FILE "res2|$res2\n";
	print FILE "timelimit|$timelimit\n";
	fclose(FILE);
}

sub ThreadSummary {
	if($memberid{$username}{'hidesum'}) { return; }
	$ebout .= <<"EOT";
<br /><table class="border" cellpadding="5" cellspacing="1" width="100%">
 <tr>
  <td class="titlebg smalltext center"><strong>$posttxt[73]</strong></td>
 </tr><tr>
  <td class="win3">
   <div style="overflow: auto; width: 100%; height: 200px;">
EOT
	foreach(@messagez) {
		($postinguser,$message,$ip,$email,$date,$nosmile) = split(/\|/,$_);
		push(@message,"$date|$postinguser|$message|$ip|$email|$nosmile");
	}
	if($reversesum) { @message = sort{$b <=> $a} @message; }

	foreach(@message) {
		if($maxsumc && $junkcounter == $maxsumc) { last; }
		($date,$postinguser,$message,$ip,$email,$nosmile) = split(/\|/,$_);

		GetMemberID($postinguser);
		if($memberid{$postinguser}{'sn'} eq '') { $guestuser = 1; }

		if($username ne 'Guest') {
			foreach(@blockedusers) {
				if($postinguser eq $_ || ($guestuser && $_ eq 'Guest')) { $quit = 1; }
			}
		}
		if($quit) { $ebout .= qq~<tr><td class="win2 smalltext">$posttxt[126]</td></tr>~; next; }

		$postedby = $memberid{$postinguser}{'sn'} ne '' ? $userurl{$postinguser} : FindOldMemberName($postinguser);

		$datepost = get_date($date);

		if(length($message) > 1000) {
			$message =~ s~\[table\](.*?)\[\/table\]~$var{'88'}~sgi;
			$message = substr($message,0,1000);
			$message = BC($message);
			MakeSmall();
			$message .= " ...";
		} else { $message = BC($message); }

		$ebout .= <<"EOT";
<table cellpadding="4" cellspacing="1" width="99%" class="border">
 <tr>
  <td class="win"><table cellpadding="1" width="100%">
   <tr>
    <td class="smalltext"><strong>$gtxt{'19'}:</strong> $postedby</td>
    <td class="right smalltext"><strong>$gtxt{'21'}:</strong> $datepost</td>
   </tr>
  </table></td>
 </tr><tr>
  <td class="win2 smalltext">$message</td>
 </tr>
</table>
<br />
EOT
		++$junkcounter;
	}
	$ebout .= <<"EOT";
   </div>
  </td>
 </tr>
</table>
EOT
}

sub Preview {
	while(($iname,$ivalue) = each(%FORM)) {
		$ivalue =~ s/\"/&#034;/g;
		$FORM{$iname} = $ivalue;
	}

	$nosmile = $smiley;
	%psmiley = (1 => '',2 => '',3 => '');
	$qmodify = Unformat($message);
	$message = BC($message);

	$FORM{'tags'} =~ s/\n|\'|\"//g;
	if(length($FORM{'tags'}) > 75) { $tags = ''; }
	$tags = Format($FORM{'tags'});

	$titleed = $FORM{'subject'};
	$sel{"$FORM{'micon'}"} = ' selected="selected"';
	$micon = $FORM{'micon'};

	for($i = 1; $i <= $pollops; ++$i) {
		$currentvalue{$i} = $FORM{"currentvalue_$i"};
		$value{$i} = $FORM{$i};
	}

	$psub = $FORM{'psubject'};
	$results = $FORM{'results'};
	$stick{"$FORM{'sticky'}"} = ' checked="checked"';
	if($FORM{'notify'}) { $notify = ' checked="checked"'; } else { $notify = ''; }
	$psmiley{$smiley} = ' checked="checked"';
	$res{"$FORM{'results'}"} = ' checked="checked"';
	$res2{"$FORM{'multi'}"} = ' checked="checked"';
	$res3{"$FORM{'deletepoll'}"} = ' checked="checked"';

	$unpost = $FORM{'username'};
	$epost = $FORM{'email'};
	if($message eq '') { $message = qq~<i>$gtxt{'13'}</i>~; }

	if($username ne 'Guest') { UserMiniProfile($username); }
		else { $profile{$username} = qq~<div style="padding: 8px;" class="center">$posttxt[145]</div>~; }

	$preview = <<"EOT";
<table class="border" cellpadding="4" cellspacing="1" width="100%">
 <tr>
  <td class="vtop catbg" colspan="2"><strong>$posttxt[47]</strong></td>
 </tr><tr>
  <td style="padding: 0px; width: 180px;" class="win2 vtop smalltext">$profile{$username}</td>
  <td class="vtop win postbody">$message</td>
 </tr>
</table><br />
EOT
	Post2();
}

sub ValIcon {
	my($micon) = $_[0];
	my($foundicon,$icongroups);

	fopen(ICON,"$prefs/MessageIcons.txt");
	while(<ICON>) {
		chomp;
		($t,$icon,$t,$icongroups) = split(/\|/,$_);
		if($icongroups ne '' && !GetMemberAccess($icongroups)) { next; }
		if($micon eq $icon) { $foundicon = 1; last; }
	}
	fclose(ICON);
	if(!$foundicon) { $micon = 'xx.gif'; }

	return($micon);
}

sub DoSticky {
	fopen(FILE,"+>>$boards/Stick.txt");
	print FILE "$URL{'b'}|$mtime\n";
	fclose(FILE);
}

sub BCSmile {
	my($temp,$temper);
	if($BCLoad) { $onload = qq~ onmouseover="funclu('smiley')" onmouseout="funclu('wait')"~; }
	if($simages2 ne '') { $temper = $simages; $simages = $simages2; }
	$temp = <<"EOT";
<table cellpadding="5" cellspacing="0" width="100%">
 <tr>
  <td colspan="8" class="smalltext"><strong>$posttxt[34]</strong></td>
 </tr><tr$onload>
  <td><img src="$simages/smiley.png" alt="$var{'44'}" onclick="use(' :)');" onmouseover="$ghand" /></td>
  <td><img src="$simages/wink.png" alt="$var{'45'}" onclick="use(' ;)');" onmouseover="$ghand" /></td>
  <td><img src="$simages/tongue.png" alt="$var{'46'}" onclick="use(' :P');" onmouseover="$ghand" /></td>
  <td><img src="$simages/grin.png" alt="$var{'47'}" onclick="use(' ;D');" onmouseover="$ghand" /></td>
  <td><img src="$simages/sad.png" alt="$var{'48'}" onclick="use(' :(');" onmouseover="$ghand" /></td>
  <td><img src="$simages/angry.png" alt="$var{'49'}" onclick="use(' >:(');" onmouseover="$ghand" /></td>
  <td><img src="$simages/cry.png" alt="$var{'50'}" onclick="use(' :\\'(');" onmouseover="$ghand" /></td>
  <td><img src="$simages/lipsx.png" alt="$var{'51'}" onclick="use(' :X');" onmouseover="$ghand" /></td>
 </tr><tr$onload>
  <td><img src="$simages/undecided.png" alt="$var{'52'}" onclick="use(' :-/');" onmouseover="$ghand" /></td>
  <td><img src="$simages/shock.png" alt="$var{'53'}" onclick="use(' :o');" onmouseover="$ghand" /></td>
  <td><img src="$simages/blush.png" alt="$var{'54'}" onclick="use(' :B');" onmouseover="$ghand" /></td>
  <td><img src="$simages/cool.png" alt="$var{'55'}" onclick="use(' 8)');" onmouseover="$ghand" /></td>
  <td><img src="$simages/kiss.png" alt="$var{'56'}" onclick="use(' :K)');" onmouseover="$ghand" /></td>
  <td><img src="$simages/lol.png" alt="$var{'57'}" onclick="use(' :D');" onmouseover="$ghand" /></td>
  <td><img src="$simages/roll.png" alt="$var{'58'}" onclick="use(' ::)');" onmouseover="$ghand" /></td>
  <td><img src="$simages/huh.png" alt="$var{'59'}" onclick="use(' ??)');" onmouseover="$ghand" /></td>
 </tr>
EOT
	if($upbc) {
		$temp .= <<"EOT";
 <tr$onload>
  <td colspan="8" class="center win3 smalltext"><a href="$surl\lv-post/a-smilies/" onclick="window.open('$surl\lv-post/a-smilies/','smiles','height=400,width=750,resizable=yes,scrollbars=yes'); target='smilies'; return false;">$posttxt[11]</a></td>
 </tr>
EOT
	}
	$temp .= <<"EOT";
</table>
EOT
	if($temper) { $simages = $temper; }
	if($URL{'v'} eq 'memberpanel') { return($temp); }
		else { $ebout .= $temp; }
}

sub BCLoad {
	my($temp);
	$temp = <<"EOT";
<table cellpadding="6" cellspacing="0" class="border innertable" width="100%">
 <tr>
  <td class="win2" id="postbar">
   <a href="#"><img src="$images/bold.gif" alt="$var{'10'}" onclick="use('[b]','[/b]'); return false;" onmouseover="funclu('b')" /></a>
   <a href="#"><img src="$images/italics.gif" alt="$var{'11'}" onclick="use('[i]','[/i]'); return false;" onmouseover="funclu('i')" /></a>
   <a href="#"><img src="$images/underline.gif" alt="$var{'12'}" onclick="use('[u]','[/u]'); return false;" onmouseover="funclu('u')" /></a>
   <a href="#"><img src="$images/strike.gif" alt="$var{'17'}" onclick="use('[s]','[/s]'); return false;" onmouseover="funclu('s')" /></a>
   <img src="$images/div.gif" alt="" />
   <a href="#"><img src="$images/center.gif" alt="$var{'14'}" onclick="use('[center]','[/center]'); return false;" onmouseover="funclu('center')" /></a>
   <a href="#"><img src="$images/right.gif" alt="$var{'15'}" onclick="use('[right]','[/right]'); return false;" onmouseover="funclu('right')" /></a>
   <a href="#"><img src="$images/justify.gif" alt="$var{'16'}" onclick="use('[justify]','[/justify]'); return false;" onmouseover="funclu('justify')" /></a>
   <img src="$images/div.gif" alt="" />
   <a href="#"><img src="$images/list.gif" alt="$var{'18'}" onclick="use('[list]\\n[*]','\\n[/list]'); return false;" onmouseover="funclu('list')" /></a>
   <a href="#"><img src="$images/sub.gif" alt="$var{'19'}" onclick="use('[sub]','[/sub]'); return false;" onmouseover="funclu('sub')" /></a>
   <a href="#"><img src="$images/sup.gif" alt="$var{'20'}" onclick="use('[sup]','[/sup]'); return false;" onmouseover="funclu('sup')" /></a>
   <a href="#"><img src="$images/hr.gif" alt="$var{'25'}" onclick="use('[hr]'); return false;" onmouseover="funclu('hr')" /></a>
   <img src="$images/div.gif" alt="" />
   <a href="#"><img src="$images/url.gif" alt="$var{'21'}" onclick="use('[url]','[/url]'); return false;" onmouseover="funclu('url')" /></a>
   <a href="#"><img src="$images/email_click.gif" alt="$var{'22'}" onclick="use('[mail]','[/mail]'); return false;" onmouseover="funclu('mail')" /></a>
   <a href="#"><img src="$images/img.gif" alt="$var{'23'}" onclick="use('[img]','[/img]'); return false;" onmouseover="funclu('img')" /></a>
   <img src="$images/div.gif" alt="" />
   <a href="#"><img src="$images/code.gif" alt="$var{'87'}" onclick="use('[code]','[/code]'); return false;" onmouseover="funclu('code')" /></a>
   <a href="#"><img src="$images/quote_click.gif" alt="$var{'24'}" onclick="use('[quote]','[/quote]'); return false;" onmouseover="funclu('quote')" /></a>
   <img src="$images/div.gif" alt="" />
   <a href="#"><img src="$images/table.gif" alt="$var{'27'}" onclick="use('[table]\\n','[/table]'); return false;" onmouseover="funclu('table')" /></a>
   <a href="#"><img src="$images/tr.gif" alt="$var{'28'}" onclick="use('[tr]\\n','[/tr]'); return false;" onmouseover="funclu('tr')" /></a>
   <a href="#"><img src="$images/td.gif" alt="$var{'29'}" onclick="use('[td]\\n','[/td]'); return false;" onmouseover="funclu('td')" /></a>
   <div style="padding: 5px !important;">
    <select style="width:75px;" name="face" onchange="AddNewValue('face',this.value); return false;" onmouseover="funclu('face')"><option value="">$var{'8'}</option><option value="Arial">Arial</option><option value="Times">Times</option><option value="Courier">Courier</option><option value="Geneva">Geneva</option><option value="Sans-Serif">Sans-Serif</option><option value="Verdana">Verdana</option></select>
    <select style="width:75px;" name="size" onchange="AddNewValue('size',this.value); return false;" onmouseover="funclu('size')"><option value="">$var{'9'}</option><option value="9">$var{'94'}</option><option value="14">$var{'95'}</option><option value="18">$var{'96'}</option></select>
    <select style="width:75px;" name="color" onchange="AddNewValue('color',this.value);" onmouseover="funclu('color')"><option value="">$var{'30'}</option><option value="green" style="color:green">$var{'39'}</option><option value="blue" style="color:blue">$var{'37'}</option><option value="purple" style="color:purple">$var{'34'}</option><option value="orange" style="color:orange;">$var{'41'}</option><option value="yellow" style="color: yellow">$var{'40'}</option><option value="red" style="color:red">$var{'42'}</option><option value="black" style="color: black">$var{'33'}</option></select>
   </div>
  </td>
 </tr><tr>
  <td class="smalltext win3" id="about">$posttxt[111]</td>
 </tr>
</table>
EOT
	if($URL{'v'} eq 'memberpanel') { return($temp); }
		else { $ebout .= $temp; }
}


sub BCSmileAE {
	my($temp,$temper);
	if($BCLoad) { $onload = qq~ onmouseover="funclu('smiley')" onmouseout="funclu('wait')"~; }
	if($simages2 ne '') { $temper = $simages; $simages = $simages2; }
	$temp = <<"EOT";
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
EOT
	if($temper) { $simages = $temper; }
	if($URL{'v'} eq 'memberpanel') { return($temp); }
		else { $ebout .= $temp; }
}

sub BCLoadAE {
	my($temp);

	$temp = <<"EOT";
<table cellpadding="6" cellspacing="0" class="border innertable" width="100%">
 <tr>
  <td class="smalltext win3" id="about">$posttxt[111]</td>
 </tr><tr>
  <td class="smalltext win4"><strong><a href="#" onclick="tinyMCE.execCommand('mceToggleEditor',false,'message'); return false;">$posttxt[153]</a></strong> &nbsp; $posttxt[154]</td>
 </tr>
</table>
EOT
	if($URL{'v'} eq 'memberpanel') { return($temp); }
		else { $ebout .= $temp; }
}

sub BCWait {
	my($temp);
	$ghand = "\" style=\"cursor: hand";
	$temp = <<"EOT";
<script src="$bdocsdir/bc.js" type="text/javascript"></script>
<script type="text/javascript">
//<![CDATA[
 var et = '$posttxt[82] <i>';
 var et2 = '$posttxt[83] <i>';
 var al = '$posttxt[84] <i>';
 var cr = '$posttxt[85] ... <i>';
 var c = '.</i>';
 var func_b = et+'$posttxt[86]'+c;
 var func_face = et2+'$posttxt[87]'+c;
 var func_size = et2+'$posttxt[88]'+c;
 var func_i = et+'$posttxt[89]'+c;
 var func_u = et+'$posttxt[90]'+c;
 var func_left = al+'$posttxt[91]'+c;
 var func_right = al+'$posttxt[92]'+c;
 var func_center = et+'$posttxt[93]'+c;
 var func_pre = et+'$posttxt[94]'+c;
 var func_justify = et+'$posttxt[94]'+c;
 var func_s = et+'$posttxt[95]'+c;
 var func_list = cr+'$posttxt[96]'+c;
 var func_code = cr+'$posttxt[97]'+c;
 var func_sub = et+'$posttxt[98]'+c;
 var func_sup = et+'$posttxt[99]'+c;
 var func_url = cr+'$posttxt[100]'+c;
 var func_mail = cr+'$posttxt[101]'+c;
 var func_img = cr+'$posttxt[102]'+c;
 var func_quote = cr+'$posttxt[103]'+c;
 var func_hr = cr+'$posttxt[104]'+c;
 var func_flash = cr+'$posttxt[105]'+c;
 var func_upload = cr+'$posttxt[106]'+c;
 var func_table = cr+'$posttxt[107]'+c;
 var func_tr = cr+'$posttxt[108]'+c;
 var func_td = cr+'$posttxt[109]'+c;
 var func_color = et2+'$posttxt[110]'+c;
 var func_icon = '$posttxt[112]';
 var func_subject = '$posttxt[113]';
 var func_message = '$posttxt[114]';
 var func_smiley = '$posttxt[115]';
 var func_shadow = et+'$posttxt[131]'+c;
 var func_glow = et+'$posttxt[132]'+c;
 var func_wait = "$posttxt[111]";
//]]>
</script>
EOT

	if($BCAdvanced) {
		$temp .= <<"EOT";
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

	if($URL{'v'} eq 'memberpanel') { return($temp); }
		else { $ebout .= $temp; }
}
1;