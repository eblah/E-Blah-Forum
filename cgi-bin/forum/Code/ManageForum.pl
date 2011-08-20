#############################################
# E-Blah Bulletin Board Systems        2008 #
#############################################
# Copyright (c) 2001 - 2008 E-Blah.         #
#############################################

is_admin(1.2);
CoreLoad('ManageBoards',1);

sub ManageBoards {
	foreach(@catbase) {
		($cattitle,$catid,$t,$input,$desc,$subcats) = split(/\|/,$_);
		$catname{$catid} = "$cattitle|$input|$desc|$subcats";
		foreach $nohere (split(/\//,$subcats)) { $noshow{$nohere} = 1; }
	}
	if($URL{'a'} eq 'cats') { EditCatsR(); }
		else {
			if($URL{'g'} eq '2') { EditBoards2(); }
			elsif($URL{'g'} eq '3') { EditBoards3(); }
			if($URL{'p'} eq 'move') { MoveBoards(); }
			if($URL{'p'} eq 'moveboard') { MoveToCat(); }
			StartBoards();
		}
	exit;
}

sub StartBoards {
	$title = $manageboards[1];
	headerA();

	$ebout .= <<"EOT";
<script type="text/javascript">
//<![CDATA[
function Removebrd(cateid) {
 if(window.confirm("$managecats[18]")) { location = "$surl\lv-admin/a-cats/p-2/id-"+cateid+"/remove-remove/"; }
}
//]]>
</script>
<table cellpadding="5" cellspacing="1" width="98%" class="center border">
 <tr>
  <td class="titlebg"><strong><img src="$images/cat.gif" alt="" /> $title</strong></td>
 </tr><tr>
  <td class="win smalltext" colspan="2">$manageboards[51]</td>
 </tr><tr>
  <td class="win2" style="padding: 0px;">
   <table width="100%" cellpadding="5" cellspacing="0">
EOT
	foreach(@catbase) {
		($t,$nohere) = split(/\|/,$_);
		if(!$noshow{$nohere}) { push(@catlist,$nohere); }
	}

	foreach(@boardbase) {
		($bid,$bdisc[0],$bdisc[1],$bdisc[2],$bdisc[3],$bdisc[4],$bdisc[5],$bdisc[6]) = split("/",$_);
		$boardname{$bid} = "$bdisc[0]/$bdisc[1]/$bdisc[2]/$bdisc[3]/$bdisc[4]/$bdisc[5]/$bdisc[6]";
	}

	$totallinks = @catlist;
	$counter = 0;
	foreach(@catlist) { ++$counter; SubCat($_,'',$totallinks,$counter); }

	$ebout .= <<"EOT";
    <tr>
     <td class="catbg center" colspan="3"><strong>$subcat<a href="$surl\lv-admin/a-cats/n-1/">$managecats[3]</a></strong></td>
    </tr>
   </table>
  </td>
 </tr>
</table>
EOT

	footerA();
	exit;
}

sub SubCat { # This puts together all sub cats ...
	my($catid,$subcat,$total,$curcount) = @_;
	my($curcounter,$move);
	if($subcat eq '') { $depth = ''; }

	if($catname{$catid} eq '') { return(-1); }

	if($alreadyshown{$catid}) { return(-1); }
	$alreadyshown{$catid} = 1;

	($cattitle,$input,$desc,$subcats) = split(/\|/,$catname{$catid});

	@forumlist = split(/\//,$input);
	$totalforums{$catid} = @forumlist;
	@subcats = split(/\//,$subcats);
	$totalscats{$catid} = @subcats;

	$updown = '';
	if($total > 1) {
		$down = qq~<a href="$surl\lv-admin/a-cats/id-$catid/p-move/s-down/"><img src="$images/expand.gif" alt="$manageboards[2]" /></a>~;
		$up = '';
		if($curcount != 1) { $up = qq~<a href="$surl\lv-admin/a-cats/id-$catid/p-move/s-up/"><img src="$images/minimize.gif" alt="$manageboards[3]" /></a>~; }
		if($total == $curcount) { $down = ''; $up =~ s/ \| //gi; }
		if($total > 0) { $updown = qq~<span style="text-align: left; width: 50%;">$up</span><span style="text-align: right; width: 50%;">$down</span>~; }
		if($input ne '') { @randoms = split("/",$input); }
		$incnt = $input ne '' ? @randoms : 0;
	}
	if(@catbase > 1) { $move = qq~<a href="$surl\lv-admin/a-boards/p-moveboard/cid-$catid/"><img src="$images/move_board.gif" alt="$manageboards[48]" /></a>~; }

	$ebout .= <<"EOT";
<tr>
 <td class="catbg"><strong>$subcat<img src="$images/open_thread.gif" alt="" /> <a href="$surl\lv-admin/a-cats/id-$catid/">$cattitle</a></strong></td>
 <td class="catbg smalltext center"><strong>$totalforums{$catid}</strong> $manageboards[61], <strong>$totalscats{$catid}</strong> $managecats[27]</td>
 <td class="catbg right">
  <table cellpadding="3" cellspacing="1" class="border innertable">
   <tr>
    <td class="win3" style="padding-left: 15px; padding-right: 15px; width: 40px; text-align: center;">$updown</td>
    <td class="win" style="padding-left: 15px; padding-right: 15px; width: 40px; text-align: center;">$move</td>
    <td class="win3" style="padding-left: 15px; padding-right: 15px; width: 40px; text-align: center;"><a href="javascript:Removebrd('$catid');"><img src="$images/brd_main.gif" alt="$managecats[2]" /></a></td>
   </tr>
  </table>
 </td>
</tr><tr>
 <td class="win">$depth&nbsp;<img src="$images/subdown.gif" width="10" alt="" />&nbsp;<img src="$images/thread.png" alt="" /> <a href="$surl\lv-admin/a-boards/g-2/c-$catid/n-1/">$manageboards[11]</a></td>
 <td class="win right" colspan="2"><a href="$surl\lv-admin/a-cats/n-1/l-$catid/">$managecats[29]</a></td>
</tr>
EOT

	foreach(@forumlist) {
		if($_ eq '') { next; }
		SubForums($_,$catid,$depth,$totalforums{$catid},$curcounter); ++$curcounter;
	}
	$curcounter = 0;
	foreach(split(/\//,$subcats)) {
		$depth = qq~<img src="$images/nopic.gif" width="16" alt="" />~.$subcat;
		++$curcounter; SubCat($_,$depth,$totalscats{$catid},$curcounter);
	}
}

sub SubForums { # This puts together all sub forums ...
	my($boardid,$catid,$depth,$max,$counter) = @_;
	($bdisc[0],$bdisc[1],$bdisc[2],$bdisc[3],$bdisc[4],$bdisc[5],$bdisc[6]) = split("/",$boardname{$boardid});

	$bmoveup = $bmovedown = '';
	if($counter >= 0 && !($counter == $max-1)) { $bmovedown = qq~<a href="$surl\lv-admin/a-boards/p-move/s-down/id-$boardid/"><img src="$images/expand.gif" alt="$manageboards[2]" /></a>~; }
	if($counter > 0) { $bmoveup = qq~<a href="$surl\lv-admin/a-boards/p-move/s-up/id-$boardid/"><img src="$images/minimize.gif" alt="$manageboards[3]" /></a>~; }
	if(@catbase > 1) { $moveto = qq~<a href="$surl\lv-admin/a-boards/p-moveboard/id-$boardid/"><img src="$images/move_board.gif" alt="$manageboards[48]" /></a>~; }

	$ebout .= <<"EOT";
<tr>
 <td>$depth&nbsp;<img src="$images/subdown.gif" width="10" alt="" />&nbsp;<img src="$images/thread.png" alt="" /> <a href="$surl\lv-admin/a-boards/g-2/c-$catid/bd-$boardid/">$bdisc[2]</a></td>
 <td class="right" colspan="2">
  <table cellpadding="3" cellspacing="1" class="border innertable">
   <tr>
    <td class="win" style="padding-left: 15px; padding-right: 15px; width: 40px; text-align: center;"><span style="text-align: left; width: 50%;">$bmoveup</span> <span style="text-align: right; width: 50%;">$bmovedown</span></td>
    <td class="win3" style="padding-left: 15px; padding-right: 15px; width: 40px; text-align: center;">$moveto</td>
    <td class="win" style="padding-left: 15px; padding-right: 15px; width: 40px; text-align: center;"><a href="$surl\lv-admin/a-boards/g-3/c-$catid/bd-$boardid/remove-1/"><img src="$images/brd_main.gif" alt="$managecats[2]" /></a></td>
   </tr>
  </table>
 </td>
</tr>
EOT
}

sub EditBoards2 {
	$catid = $URL{'c'};
	$board = $URL{'bd'};
	if($URL{'n'} != 1) {
		foreach (@catbase) {
			($t,$t,$t,$input) = split(/\|/,$_);
			if($input ne '') { @randoms = split("/",$input); } else { next; }
			foreach(@randoms) {
				if($_ eq $board) { $fnd = 1; last; }
			}
		}
		if($fnd != 1) { error("$gtxt{'error2'}: $board"); }
		foreach(@boardbase) {
			($bdid,$bdisc[0],$bdisc[1],$bdisc[2],$bdisc[3],$bdisc[4],$bdisc[5],$bdisc[6],$bdisc[7],$bdisc[8],$bdisc[9],$bdisc[10],$bdisc[11],$bdisc[12],$bdisc[13],$bdisc[14],$bdisc[15]) = split("/",$_);
			if($bdid eq $board) { last; }
		}

		foreach(split(/\|/,$bdisc[1])) {
			if($_ =~ /\((.+?)\)/) { $mods{$1} = ' selected="selected"'; next; }
			GetMemberID($_);
			if($memberid{$_}{'sn'} eq '') { next; }
			$mods .= "$memberid{$_}{'sn'}\n";
		}

		$mods =~ s/,\Z//;
		$boardid = $board;
		$remove = qq~&nbsp;&nbsp;<input type="submit" name="remove" value=" $manageboards[10] " />~;
	} else { $boardid = qq~<input type="text" name="bid" />~; }
	$E{$bdisc[7]}     = ' checked="checked"';
	$PC{$bdisc[8]}    = ' checked="checked"';
	$V{$bdisc[10]}    = ' checked="checked"';

	$bdisc[0] =~ s/&#47;/\//g;
	$desc = Unformat($bdisc[0]);

	if($URL{'n'}) { $title = $manageboards[11]; }
		else { $title = "$manageboards[12]: $bdisc[2]"; }

	$count = 0;

	$bdisc[13] =~ s/\|/\//g;

	headerA();
	$ebout .= <<"EOT";
<script type="text/javascript">
//<![CDATA[
function checkAll(type,ucheck) {
 counter = 1;
 for(i = 0; i < document.forms['manage'].elements.length; i++) {
  string = document.forms['manage'].elements[i].name;
  if(string.match(type) && !ucheck) { document.forms['manage'].elements[i].checked = true; }
  else if(string.match(type) && ucheck) { document.forms['manage'].elements[i].checked = false; }
 }
}
//]]>
</script>
<form action="$surl\lv-admin/a-boards/g-3/c-$URL{'c'}/bd-$URL{'bd'}/n-$URL{'n'}/" id="manage" method="post" enctype="multipart/form-data">
<table cellpadding="5" cellspacing="1" class="border" width="98%">
 <tr>
  <td class="titlebg"><strong><img src="$images/thread.png" alt="" /> $title</strong></td>
 </tr><tr>
  <td class="win smalltext">$manageboards[54]</td>
 </tr><tr>
  <td class="catbg smalltext center"><strong>$manageboards[52]</strong></td>
 </tr><tr>
  <td class="win2">
   <table cellpadding="5" cellspacing="0" width="100%">
    <tr>
     <td class="right" style="width: 35%"><strong>$manageboards[13]:</strong></td>
     <td style="width: 65%" class="vtop"><input type="text" name="bname" value="$bdisc[2]" size="30" /></td>
    </tr><tr>
     <td class="right" style="width: 35%"><strong>$manageboards[14]:</strong></td>
     <td style="width: 65%" class="vtop">$boardid</td>
    </tr><tr>
     <td style="width: 35%" class="vtop right"><strong>$manageboards[15]:</strong></td>
     <td style="width: 65%" class="vtop"><textarea name="bdisc" style="width: 90%; height: 50px;" rows="1" cols="1">$desc</textarea></td>
    </tr><tr>
     <td class="right" style="width: 35%"><strong>$managecats[33]:</strong></td>
     <td style="width: 65%"><input type="text" name="bgfx" value="$bdisc[13]" size="50" /></td>
    </tr><tr>
     <td style="width: 35%" class="vtop right"><strong>$manageboards[16]:</strong><div class="smalltext">$manageboards[17]</div></td>
     <td style="width: 65%" class="vtop">
      <table cellpadding="2" cellspacing="0" width="100%">
       <tr>
        <td style="width: 50%"><textarea name="mods" rows="5" cols="35" style="width: 95%;">$mods</textarea></td>
        <td style="width: 50%"><select size="5" name="mods2" style="width: 100%" multiple="multiple"><optgroup label="$managecats[31]">
EOT
	foreach(@fullgroups) {
		if($_ eq 'Moderators') { next; }
		$ebout .= qq~<option value="$_"$mods{$_}>$permissions{$_,'name'}</option>~;
	}

	$ebout .= <<"EOT";
        </optgroup></select></td>
       </tr>
      </table>
     </td>
    </tr>
   </table>
  </td>
 </tr><tr>
  <td class="catbg smalltext center"><strong>$manageboards[53]</strong></td>
 </tr><tr>
  <td class="win" style="padding:0px">
   <table cellpadding="6" cellspacing="0" width="100%">
    <tr class="titlebg">
     <td class="center" style="width: 30%"><strong>$managecats[34]</strong></td>
     <td class="center" style="width: 11%"><strong>$managecats[35]</strong></td>
     <td class="center" style="width: 11%"><strong>$managecats[36]</strong></td>
     <td class="center" style="width: 11%"><strong>$managecats[37]</strong></td>
     <td class="center" style="width: 11%"><strong>$managecats[43]</strong></td>
     <td class="center" style="width: 11%"><strong>$managecats[38]</strong></td>
     <td class="center" style="width: 11%"><strong>$managecats[39]</strong></td>
    </tr>
    </table>
   </td>
 </tr><tr>
  <td class="win" style="padding:0px;">
   <div style="overflow: auto; width: 100%; height: 200px;">
   <table cellpadding="6" cellspacing="0" width="100%" class="innertable">
    <tr class="catbg">
     <td colspan="7"><i><strong>$managecats[31]</strong></i></td>
    </tr>
EOT
	foreach(split(',',$bdisc[3])) { $start{$_} = ' checked="checked"'; }
	foreach(split(',',$bdisc[4])) { $reply{$_} = ' checked="checked"'; }
	foreach(split(',',$bdisc[9])) { $allow{$_} = ' checked="checked"'; }
	foreach(split(',',$bdisc[14])) { $read{$_} = ' checked="checked"'; }
	foreach(split(',',$bdisc[11])) { $upload{$_} = ' checked="checked"'; }
	foreach(split(',',$bdisc[5])) { $polls{$_} = ' checked="checked"'; }

	push(@fullgroups,('member','validating','guest'));
	$permissions{'member','name'} = $managecats[40];
	$permissions{'guest','name'} = $managecats[41];
	$permissions{'validating','name'} = $managecats[42];

	$count = 1;
	foreach(@fullgroups) {
		if($_ eq 'Moderators') { next; }
		if($_ eq 'member') { $ebout .= qq~<tr class="catbg"><td colspan="7"><i><strong>$managecats[32]</strong></i></td></tr>~; }

		if($URL{'n'} && ($_ eq 'member' || $_ eq 'guest' || $_ eq 'validating')) {
			$start{$_} = ' checked="checked"';
			$reply{$_} = ' checked="checked"';
			$allow{$_} = ' checked="checked"';
			$read{$_} = ' checked="checked"';
			$upload{$_} = ' checked="checked"';
			$polls{$_} = ' checked="checked"';
		}

		$ebout .= <<"EOT";
<tr>
 <td class="win3" style="width: 30%"><span style="float: left">$permissions{$_,'name'}</span><span style="float: right"><a href="javascript:checkAll('_$_',0);"><img src="$images/add.gif" style="vertical-align: middle;" alt="" /></a> &nbsp; <a href="javascript:checkAll('_$_',1);"><img src="$images/minus.gif" style="vertical-align: middle;" alt="" /></a></span></td>
 <td class="center" style="width: 11%"><input type="checkbox" name="start_$_" value="1"$start{$_} /></td>
 <td style="width: 11%" class="win2 center"><input type="checkbox" name="reply_$_" value="1"$reply{$_} /></td>
 <td class="center" style="width: 11%"><input type="checkbox" name="allow_$_" value="1"$allow{$_} /></td>
 <td style="width: 11%" class="win2 center"><input type="checkbox" name="read_$_" value="1"$read{$_} /></td>
 <td class="center" style="width: 11%"><input type="checkbox" name="polls_$_" value="1"$polls{$_} /></td>
 <td style="width: 11%" class="win2 center"><input type="checkbox" name="upload_$_" value="1"$upload{$_} /></td>
</tr>
EOT
		++$count;
	}

	$ebout .= <<"EOT";
   </table></div>
  </td>
 </tr><tr>
  <td class="win" style="padding:0px">
   <table cellpadding="6" cellspacing="0" width="100%">
    <tr class="win">
     <td style="width: 30%" class="center"><a href="javascript:checkAll('_',0);"><img src="$images/add.gif" style="vertical-align: middle;" alt="" /></a> &nbsp; <a href="javascript:checkAll('_',1);"><img src="$images/minus.gif" style="vertical-align: middle;" alt="" /></a></td>
     <td class="center" style="width: 11%"><a href="javascript:checkAll('start',0);"><img src="$images/add.gif" style="vertical-align: middle;" alt="" /></a> &nbsp; <a href="javascript:checkAll('start',1);"><img src="$images/minus.gif" style="vertical-align: middle;" alt="" /></a></td>
     <td class="center" style="width: 11%"><a href="javascript:checkAll('reply',0);"><img src="$images/add.gif" style="vertical-align: middle;" alt="" /></a> &nbsp; <a href="javascript:checkAll('reply',1);"><img src="$images/minus.gif" style="vertical-align: middle;" alt="" /></a></td>
     <td class="center" style="width: 11%"><a href="javascript:checkAll('allow',0);"><img src="$images/add.gif" style="vertical-align: middle;" alt="" /></a> &nbsp; <a href="javascript:checkAll('allow',1);"><img src="$images/minus.gif" style="vertical-align: middle;" alt="" /></a></td>
     <td class="center" style="width: 11%"><a href="javascript:checkAll('read',0);"><img src="$images/add.gif" style="vertical-align: middle;" alt="" /></a> &nbsp; <a href="javascript:checkAll('read',1);"><img src="$images/minus.gif" style="vertical-align: middle;" alt="" /></a></td>
     <td class="center" style="width: 11%"><a href="javascript:checkAll('polls',0);"><img src="$images/add.gif" style="vertical-align: middle;" alt="" /></a> &nbsp; <a href="javascript:checkAll('polls',1);"><img src="$images/minus.gif" style="vertical-align: middle;" alt="" /></a></td>
     <td class="center" style="width: 11%"><a href="javascript:checkAll('upload',0);"><img src="$images/add.gif" style="vertical-align: middle;" alt="" /></a> &nbsp; <a href="javascript:checkAll('upload',1);"><img src="$images/minus.gif" style="vertical-align: middle;" alt="" /></a></td>
   </tr>
   </table>
  </td>
 </tr><tr>
  <td class="catbg smalltext center"><strong>$managecats[20]</strong></td>
 </tr><tr>
  <td class="win">
   <table cellpadding="5" cellspacing="0" width="100%">
    <tr>
     <td class="center vtop"><input type="checkbox" name="pcnt" value="1"$PC{'1'} /></td>
     <td><strong>$manageboards[63]:</strong><div class="smalltext">$manageboards[64]</div></td>
    </tr><tr>
     <td class="center vtop"><input type="checkbox" name="email" value="1"$E{'1'} /></td>
     <td><strong>$manageboards[26]</strong><div class="smalltext">$manageboards[27]</div></td>
    </tr><tr>
     <td class="center vtop"><input type="checkbox" name="voting" value="1"$V{'1'} /></td>
     <td><strong>$managecats[21]</strong></td>
    </tr><tr>
     <td colspan="2"><strong>$managecats[24]:</strong></td>
    </tr><tr>
     <td colspan="2" class="smalltext" style="padding-left: 25px;"><input type="text" name="redirurl" value="$bdisc[12]" size="50" /><br />$managecats[25]</td>
    </tr><tr>
     <td colspan="2"><strong>$manageboards[24]:</strong></td>
    </tr><tr>
     <td colspan="2" style="padding-left: 25px;"><input type="password" name="boardpassword" value="$bdisc[6]" size="15" /></td>
    </tr><tr>
     <td colspan="2"><img src="$images/archive_lock.png" class="centerimg" alt="" /> <strong>$managecats[44]:</strong></td>
    </tr><tr>
     <td colspan="2" class="smalltext" style="padding-left: 25px;"><input type="text" name="archive" value="$bdisc[15]" size="15" /><br />$managecats[45]</td>
    </tr>
   </table>
  </td>
 </tr><tr>
  <td class="win2 center"><input type="submit" name="submit" value=" $manageboards[28] " />$remove</td>
 </tr>
</table>
</form>
EOT
	footerA();
	exit;
}

sub EditBoards3 {
	$catid = $URL{'c'};
	$board = $URL{'bd'};
	if($URL{'n'} != 1) {
		$fnd = 1;
		foreach (@catbase) {
			($t,$t,$t,$input) = split(/\|/,$_);
			if($input ne '') { @randoms = split("/",$input); } else { next; }
			foreach(@randoms) {
				if($_ eq $board) { $fnd = 1; last; }
			}
		}
		if($fnd != 1) { error("$gtxt{'error2'}: $board"); }
		foreach(@boardbase) {
			($bdid,$t,$t,$t,$t,$t,$t,$oldpass) = split("/",$_);
			if($bdid eq $board) { $fnd = 0; last; }
		}
		if($fnd) { error("$gtxt{'error2'}: $board"); }
	} else {
		$idbud = 0;
		if($FORM{'bid'} eq 'AllBoards' || $FORM{'bid'} =~ s/AllRead// || $FORM{'bid'} =~ s/Cat// || $FORM{'bid'} eq 'All') { error("$gtxt{'bfield'} :: \"AllBoards\", \"AllRead\", \"All\", and \"Cat\""); }
		$FORM{'bid'} =~ s/[#%+,\\\/:?"<>'| @^\$\&~'\)\(\]\[\;{}!`=-]//g;
		if($FORM{'bid'} eq '') { error($gtxt{'bfield'}); }
		foreach(@boardbase) {
			($bdid) = split("/",$_);
			if(lc($bdid) eq lc($FORM{'bid'})) { $idbud = 1; last; }
		}
		if($idbud) { error($manageboards[29]); } else { $board = $FORM{'bid'}; }
		fopen(FILE,">$boards/$FORM{'bid'}.msg");
		fclose(FILE);
		fopen(FILE,">$boards/$board.hits");
		fclose(FILE);
		fopen(FILE,">$boards/$FORM{'bid'}.ino");
		fclose(FILE);
	}

	if(!-e("$boards/$board.hits") && $FORM{'bid'} == '') {
		fopen(FILE,">$boards/$board.hits");
		fclose(FILE);
	}

	if($FORM{'remove'} || $URL{'d'} || $URL{'remove'} == 1) { DeleteBoards(); }
		else {
			error($gtxt{'bfield'}) if($FORM{'bdisc'} eq '');
			error($gtxt{'bfield'}) if($FORM{'bname'} eq '');
		}

	$desc = Format($FORM{'bdisc'});
	$desc =~ s/\//&#47;/g;
	$bname = Format($FORM{'bname'});
	$bname =~ s/\//&#47;/g;
	if($FORM{'boardpassword'} ne $oldpass) {
		if($FORM{'boardpassword'} =~ s/[#|%^\\{}\/?~'\)\(\]\[\;]//) { error($manageboards[30]); }
		$password = Format($FORM{'boardpassword'});
		if($password ne '') {
			$password = crypt($password,$pwcry);
			$password =~ s/\///g;
		}
	} else { $password = $oldpass; }

	if($FORM{'mods'} ne '') {
		foreach(split(/\n/,$FORM{'mods'})) {
			$_ =~ s/\cM//g;
			if($_ eq '') { next; }
			$modss .= FindUsername($_) || error("$_ $manageboards[31]");
			$modss .= '|';
		}
	}

	if($FORM{'mods2'} ne '') {
		foreach(split(',',$FORM{'mods2'})) { $modss .= "($_)|"; }
	}
	$modss =~ s/\|\Z//g;

	$redirurl = $FORM{'redirurl'};
	$redirurl =~ s/\//&#47;/g;

	fopen(FILE,"+>$boards/bdindex.db");
	foreach (@boardbase) {
		($usethis) = split("/",$_);
		if($usethis ne $board) { print FILE "$_\n"; }
	}
	$bgfx = $FORM{'bgfx'};
	$bgfx =~ s/\//\|/g;

	# Do the permissions:
	while(($name,$value) = each(%FORM)) {
		if($name =~ /start_(.*?)\Z/ && $value == 1) { $startthreads .= "$1,"; }
		if($name =~ /reply_(.*?)\Z/ && $value == 1) { $replythreads .= "$1,"; }
		if($name =~ /allow_(.*?)\Z/ && $value == 1) { $allowaccess .= "$1,"; }
		if($name =~ /read_(.*?)\Z/ && $value == 1) { $readmess .= "$1,"; }
		if($name =~ /upload_(.*?)\Z/ && $value == 1) { $upload .= "$1,"; }
		if($name =~ /polls_(.*?)\Z/ && $value == 1) { $polls .= "$1,"; }
	}
	$allowaccess =~ s/,\Z//g;
	$replythreads =~ s/,\Z//g;
	$startthreads =~ s/,\Z//g;
	$readmess =~ s/,\Z//g;
	$upload =~ s/,\Z//g;
	$polls =~ s/,\Z//g;

	print FILE "$board/$desc/$modss/$bname/$startthreads/$replythreads/$polls/$password/$FORM{'email'}/$FORM{'pcnt'}/$allowaccess/$FORM{'voting'}/$upload/$redirurl/$bgfx/$readmess/$FORM{'archive'}\n";
	fclose(FILE);

	if($URL{'n'}) {
		fopen(FILE,"+>$boards/bdscats.db");
		foreach(@catbase) {
			($ll,$cid,$aa,$bds,$cdat1,$desc,$subcats) = split(/\|/,$_);
			if($cid eq $catid) {
				$bds =~ s/\/\Z//g;
				if($bds eq '') { $bds = $board; } else { $bds .= "/$board"; }
				print FILE "$ll|$cid|$aa|$bds|$cdat1|$desc|$subcats\n";
			} else { print FILE "$_\n"; }
		}
		fclose(FILE);
	}
	redirect("$surl\lv-admin/a-boards/");
}

sub DeleteBoards {
	if(($FORM{'remove'} || $URL{'remove'}) && $URL{'d'} eq '') {
		foreach(@boardbase) {
			($bdid,$bdisc[0],$bdisc[1],$bdisc[2],$bdisc[3],$bdisc[4],$bdisc[5],$bdisc[6],$bdisc[7]) = split("/",$_);
			if($bdid eq $board) { last; }
		}
		$title = $manageboards[32];
		headerA();
		$ebout .= <<"EOT";
<table cellpadding="5" cellspacing="1" class="border" width="600">
 <tr>
  <td class="titlebg"><strong><img src="$images/ban.png" alt="" /> $title</strong></td>
 </tr><tr>
  <td class="win smalltext">$manageboards[55] "$bdisc[2]".</td>
 </tr><tr>
  <td class="win2">
   <table width="100%" cellpadding="5" cellspacing="0">
    <tr>
     <td class="catbg"><strong><a href="$surl\lv-admin/a-boards/g-3/c-$URL{'c'}/bd-$URL{'bd'}/d-1/m-1/">$manageboards[56]</a></strong></td>
    </tr><tr>
     <td class="smalltext"><br />&nbsp; $manageboards[57]<br /><br /></td>
    </tr><tr>
     <td class="catbg"><strong><a href="$surl\lv-admin/a-boards/g-3/c-$URL{'c'}/bd-$URL{'bd'}/d-1/">$manageboards[58]</a></strong></td>
    </tr><tr>
     <td class="smalltext"><br />&nbsp; $manageboards[59]<br /><br /></td>
    </tr><tr>
     <td class="catbg"><strong><a href="javascript:history.back(-1)">$manageboards[60]</a></strong></td>
    </tr><tr>
     <td class="smalltext"><br />&nbsp; $managecats[30]<br /><br /></td>
    </tr>
   </table>
  </td>
 </tr>
</table>
EOT
		footerA();
		exit;
	} else {
		fopen(FILE,"$boards/$URL{'bd'}.msg");
		@messages = <FILE>;
		fclose(FILE);
		chomp @messages;
		$title = $manageboards[32];
		headerA();
		$ebout .= <<"EOT";
<meta http-equiv="refresh" content="2;url=$surl\lv-admin/a-boards/">
<table cellpadding="4" cellspacing="1" class="border" width="500">
 <tr>
  <td class="titlebg"><strong><img src="$images/ban.png" alt="" /> $title</strong></td>
 </tr><tr>
  <td class="win smalltext">
EOT
		$count = 0;
		$replycnt = 0;
		foreach (@messages) {
			($mid,$t,$t,$t,$replys) = split(/\|/,$_);
			unlink("$messages/$mid.txt","$messages/$mid.rate","$messages/$mid.view","$messages/Mail/$mid.mail","$messages/$mid.poll","$messages/$mid.polled");
			GetMessageDatabase($mid,'',2);
			$ebout .= "$manageboards[38]: <strong>$mid</strong><br />\n";
			++$count;
			$replycnt = $replycnt+$replys;
		}
		unlink("$boards/$URL{'bd'}.msg","$boards/$URL{'bd'}.hits","$boards/$URL{'bd'}.ino","$boards/$URL{'bd'}.mail");
		if($URL{'m'}) {
			fopen(FILE,">$boards/$URL{'bd'}.msg");
			print FILE "";
			fclose(FILE);
			fopen(FILE,">$boards/$URL{'bd'}.ino");
			print FILE "";
			fclose(FILE);
		}
		$ebout .= "$manageboards[38]: <strong>$URL{'bd'}.msg, $URL{'bd'}.ino, $URL{'bd'}.mail</strong><br />";
		if(!$URL{'m'}) {
			$gottcha = 1;
			fopen(FILE,"+>$boards/bdscats.db");
			foreach(@catbase) {
				($cname,$cid,$cmemgrps,$input,$desc,$subcats) = split(/\|/,$_);
				@ball = split("/",$input);
				$pbdata = "$cname|$cid|$cmemgrps|";
				foreach $useme (@ball) {
					if($useme ne $URL{'bd'}) { $pbdata .= "$useme/"; }
						else { $gottcha = 0; }
				}
				$pbdata =~ s/\/\Z//gsi;
				print FILE "$pbdata|$desc|$subcats\n";
			}
			fclose(FILE);
			fopen(FILE,"+>$boards/bdindex.db");
			foreach (@boardbase) {
				($boardid) = split("/",$_);
				if($boardid ne $URL{'bd'}) { print FILE "$_\n"; }
			}
			fclose(FILE);
			if($gottcha) { $thereserror = qq~<br /> - $error{'error2'} :: $URL{'bd'}</span>~; }
			$ebout .= "$manageboards[38]: <strong>$URL{'bd'} in <i>bdscats.db</i>$thereserror</strong><br />";
		}
		$total = $replycnt+$count;
		$ebout .= <<"EOT";
  </td>
 </tr><tr>
  <td class="win2">$manageboards[38]: <strong>$count</strong><br />$manageboards[38]: <strong>$replycnt</strong><br />$manageboards[38]: <strong>$total</strong></td>
 </tr>
</table>
EOT
		footerA();
		exit;
	}
}

sub MoveBoards {
	foreach (@catbase) {
		($t,$t,$t,$input) = split(/\|/,$_);
		@output = split("/",$input);
		foreach $add (@output) {
			foreach $test (@boardbase) {
				($uid) = split("/",$test);
				if($uid eq $add) { push(@baseboard,"$test\n"); }
			}
		}
	}
	@boardbase = @baseboard;
	for($i = 0; $i < @boardbase; $i++) {
		($id) = split("/",$boardbase[$i]);
		if($id eq $URL{'id'}) { $move = $i; last; }
	}
	if($URL{'s'} eq 'up') {
		$counter = 0;
		for($e = 0; $e < @boardbase; $e++) {
			if($e == $move) {
				if($move == 0) { $add[$e] = $boardbase[$e]; } else {
					$add[--$e] = $boardbase[$move]; $add[++$e] = $boardbase[--$move];
				}
			}
				else { $add[$e] = $boardbase[$e]; }
		}
	} elsif($URL{'s'} eq 'down') {
		$max = @boardbase-1;
		$counter = 0;
		for($e = 0; $e < @boardbase; $e++) {
			if($e == $move) {
				if($move == $max) { $add[$e] = $boardbase[$e]; } else {
					$add[$e] = $boardbase[++$move]; $add[++$e] = $boardbase[--$move];
				}
			}
				else { $add[$e] = $boardbase[$e]; }
		}
	}
	chomp @add;
	fopen(FILE,"+>$boards/bdindex.db");
	foreach(@add) { print FILE "$_\n"; }
	fclose(FILE);

	fopen(FILE,"+>$boards/bdscats.db");
	foreach $cats(@catbase) {
		($name,$other,$otherb,$oldinput,$desc,$subcats) = split(/\|/,$cats);
		$update = "$name|$other|$otherb|";
		@outputs = split("/",$oldinput);
			foreach $outs (@add) {
				($id) = split("/",$outs);
				foreach $argh (@outputs) {
					if($argh eq $id) { $update .= "$id/"; }
				}
			}
		print FILE "$update|$desc|$subcats\n";
	}
	fclose(FILE);

	redirect("$surl\lv-admin/a-boards/");
}

sub FindCrosslinks { # This finds all the cats that CANNOT be used when moving this cat!
	my($catid) = @_;

	if($catname{$catid} eq '') { return(-1); }

	if($alreadyshown{$catid}) { return(-1); }
	$alreadyshown{$catid} = 1;

	($t,$t,$t,$subcats) = split(/\|/,$catname{$catid});

	foreach(split(/\//,$subcats)) { FindCrosslinks($_); }
}

sub MoveToCat {
	$board = $URL{'id'} || '';
	$cat   = $URL{'cid'} || '';
	FindCrosslinks($cat);
	foreach(@catbase) {
		($name,$useid,$t,$input,$t,$subscat) = split(/\|/,$_);
		if($input ne '') { @randoms = split("/",$input); }
		elsif(!$alreadyshown{$useid}) { $selection .= qq~<option value="$useid">$name</option>\n~; next; }
		if($cat eq '') {
			foreach(@randoms) {
				if($_ eq $board) { $other = 1; $fnd = 1; }
			}
		} else {
			if($useid eq $cat) { $fnd = 1; $other = 1; }
			$addmore = qq~<option value=""></option><option value="">$managecats[28]</option>~;
		}
		if($other eq '' && !$alreadyshown{$useid}) { $selection .= qq~<option value="$useid">$name</option>\n~; }
		$other = '';
	}
	if($fnd != 1) { error($manageboards[44]); }
	if($URL{'o'} == 2) { MoveToCat2(); }
	if(!$selection) { error($manageboards[45]); }
	$title = $manageboards[46];
	headerA();
	$ebout .= <<"EOT";
<form action="$surl\lv-admin/a-boards/p-moveboard/id-$URL{'id'}/cid-$URL{'cid'}/o-2/" method="post">
<table class="border" cellspacing="1" cellpadding="5" width="400">
 <tr>
  <td class="titlebg"><strong>$title</strong></td>
 </tr><tr>
  <td class="win2 smalltext">The following action will move this board or category to the specified category below.</td>
 </tr><tr>
  <td class="win"><strong>$manageboards[47] ...</strong><br /><br /><div class="center"><select name="cat" size="7">
$selection$addmore
  </select></div><br /></td>
 </tr><tr>
  <td class="win2 center"><input type="submit" value=" $manageboards[48] " name="submit" /></td>
 </tr>
</table>
</form>
EOT
	footerA();
	exit;
}

sub MoveToCat2 {
	foreach(@catbase) {
		($name,$useid,$ts,$input,$desc,$subcats) = split(/\|/,$_);
		$pushed = "$name|$useid|$ts|";

		if($board ne '') {
			if($input ne '') { @randoms = split("/",$input); }
				else {
					if($FORM{'cat'} eq $useid) { $pushed .= "$board/"; }
					push(@catbase2,$pushed);
					next;
				}
			foreach(@randoms) {
				if($_ ne $board) { $pushed .= "$_/"; }
			}
			if($FORM{'cat'} eq $useid) { $pushed .= "$board/"; }
			$pushed =~ s/\/\Z//;
		} else {
			$resubcats = '';
			$pushed .= $input; # Do not change boards
			foreach $subcatz (split(/\//,$subcats)) {
				if($cat ne $subcatz) { $resubcats .= "$subcatz/"; }
			}
			if($FORM{'cat'} eq $useid && !$alreadyshown{$useid}) { $resubcats .= $cat; }
			$subcats = $resubcats;
			$subcats =~ s/\/\Z//g;
		}

		push(@catbase2,"$pushed|$desc|$subcats");
	}

	fopen(FILE,"+>$boards/bdscats.db");
	foreach(@catbase2) { print FILE "$_\n"; }
	fclose(FILE);

	redirect("$surl\lv-admin/a-boards/");
}

sub EditCatsR {
	if($URL{'remove'} eq 'remove' || $URL{'p'} == 3) { DelCats(); }
	if($URL{'p'} == 2) { EditCats2(); }
	if($URL{'p'} eq 'move') { MoveCat(); }
	if($URL{'n'} != 1) {
		$title = "$managecats[1]: ";
		foreach (@catbase) {
			($cname,$id,$membergrp,$t,$catdesc) = split(/\|/,$_);
			if($id eq $URL{'id'}) {
				$title .= $cname;
				last;
			}
		}
		if($URL{'n'} eq '') { $remove = qq~&nbsp;&nbsp;<input type="button" name="remove" value=" $managecats[2] " onclick="Removebrd();" />~; }
		$id = $URL{'id'};
	} else {
		$id = qq~<input type="text" name="id" size="4" />~;
		$title = "$managecats[3]";
	}

	headerA();
	$ebout .= <<"EOT";
<script type="text/javascript">
//<![CDATA[
function Removebrd() {
 if(window.confirm("$managecats[18]")) { location = "$surl\lv-admin/a-cats/p-2/id-$URL{'id'}/n-$URL{'n'}/remove-remove/"; }
}
//]]>
</script>
<form action="$surl\lv-admin/a-cats/p-2/id-$URL{'id'}/l-$URL{'l'}/n-$URL{'n'}/" method="post" enctype="multipart/form-data">
<table cellpadding="5" cellspacing="1" class="border" width="650">
 <tr>
  <td class="titlebg"><strong><img src="$images/cat.gif" alt="" /> $title</strong></td>
 </tr><tr>
  <td class="win smalltext">$managecats[19]</td>
 </tr><tr>
  <td class="win2">
   <table cellpadding="5" cellspacing="0" width="100%">
    <tr>
     <td style="width: 50%" class="right"><strong>$managecats[4]:</strong></td>
     <td style="width: 50%" class="vtop"><input type="text" size="25" name="name" value="$cname" /></td>
    </tr><tr>
     <td style="width: 50%" class="vtop right"><strong>$managecats[26]:</strong></td>
     <td style="width: 50%" class="vtop"><textarea name="catdesc" rows="3" cols="50">$catdesc</textarea></td>
    </tr><tr>
     <td style="width: 50%" class="right"><strong>$managecats[5]:</strong></td>
     <td style="width: 50%" class="vtop">$id</td>
    </tr><tr>
     <td style="width: 50%" class="right vtop"><strong>$managecats[6]:</strong><div class="smalltext">$managecats[7]</div></td>
     <td style="width: 50%" class="vtop"><select name="memgrp" size="6" style="width: 90%" multiple="multiple">
EOT
	if($URL{'n'} == 1) { $membergrp = 'member,guest,validating'; }
	foreach(split(',',$membergrp)) { $t2{$_} = ' selected="selected"'; }
	push(@fullgroups,('member','validating','guest'));
	$permissions{'member','name'} = $managecats[40];
	$permissions{'guest','name'} = $managecats[41];
	$permissions{'validating','name'} = $managecats[42];
	$ebout .= qq~<optgroup label="$managecats[31]">~;
	foreach(@fullgroups) {
		if($_ eq 'Moderators') { next; }
		if($_ eq 'member') { $ebout .= qq~</optgroup><optgroup label="$managecats[32]">~; }
		$ebout .= qq~<option value="$_"$t2{$_}>$permissions{$_,'name'}</option>~;
	}

	$ebout .= <<"EOT";
      </optgroup></select>
     </td>
    </tr>
   </table>
  </td>
 </tr><tr>
  <td class="win center"><input type="submit" name="submit" value=" $managecats[8] " />$remove</td>
 </tr>
</table>
</form>
EOT
	footerA();
	exit;
}

sub EditCats2 {
	my($memgrp);

	if($FORM{'name'} eq '') { error($gtxt{'bfield'}); }
	$name = Format($FORM{'name'});

	foreach(split(",",$FORM{'memgrp'})) {
		if($_ eq '') { next; }
		$memgrp .= Format($_).',';
	}
	$memgrp =~ s/,\Z//g;

	$catdesc = Format($FORM{'catdesc'});
	$ids = Format($FORM{'id'});
	$ids =~ s/[#%+,\\\/:?"<>'| @^\$\&~'\)\(\]\[\;{}!`=-]//g;
	if($ids eq '' && $URL{'n'}) { error($gtxt{'bfield'}); }

	foreach(@catbase) {
		($xname,$id,$xmemgrp,$bds,$xcatdesc,$subcats) = split(/\|/,$_);
		if($URL{'n'} && (lc($id) eq lc($FORM{'id'}))) { error($managecats[17]); }
		if($URL{'n'} && $URL{'l'} eq $id) {
			$subcats =~ s/\/\Z//g;
			if($subcats) { $subcats .= "/$ids"; } else { $subcats = $ids; }
			$update .= "$xname|$id|$xmemgrp|$bds|$xcatdesc|$subcats\n";
		}
		elsif($id eq $URL{'id'}) { $update .= "$name|$id|$memgrp|$bds|$catdesc|$subcats\n"; } else { $update .= "$_\n"; }
	}
	if($URL{'n'}) { $update .= "$name|$ids|$memgrp||$catdesc|\n"; }

	fopen(FILE,"+>$boards/bdscats.db");
	print FILE $update;
	fclose(FILE);

	redirect("$surl\lv-admin/a-boards/");
}

sub DelCats {
	foreach(@catbase) {
		($name,$id,$t,$input) = split(/\|/,$_);
		if($id eq $URL{'id'}) { $delete = $name; @delete = split("/",$input); last; }
	}
	if($delete eq '') { error("$gtxt{'error2'}: $delete"); }

	$title = $managecats[9];
	headerA();
	$count = 0;
	$ebout .= <<"EOT";
<meta http-equiv="refresh" content="2;url=$surl\lv-admin/a-boards/">
<table cellpadding="4" cellspacing="1" class="border" width="500">
 <tr>
  <td class="titlebg"><strong><img src="$images/ban.png" alt="" /> $title</strong></td>
 </tr><tr>
  <td class="win smalltext">
EOT
	foreach (@delete) {
		fopen(FILE,"$boards/$_.msg");
		@messages = <FILE>;
		fclose(FILE);
		fopen(FILE,"$boards/bdindex.db");
		@boardbase = <FILE>;
		fclose(FILE);
		chomp @boardbase;
		chomp @messages;
		foreach (@messages) {
			($mid) = split(/\|/,$_);
			GetMessageDatabase($mid,'',2);
			unlink("$messages/$mid.txt","$messages/$mid.rate","$messages/$mid.view","$messages/$mid.poll","$messages/$mid.polled");
			$ebout .= "$managecats[12]: <strong>$mid</strong><br />\n";
			++$count;
		}
		unlink("$boards/$_.msg","$boards/$_.hits","$boards/$_.ino","$boards/$_.mail");
		fopen(FILE,"+>$boards/bdindex.db");
		foreach $fix (@boardbase) {
			($boardid) = split("/",$fix);
			if($boardid ne $_) { print FILE "$fix\n"; }
		}
		fclose(FILE);
		$ebout .= "<strong>$managecats[12]: $_.msg, $_.ino, $_.mail</strong><br />";
		$ebout .= qq~<hr />~;
	}
	$ebout .= "$managecats[12]: <strong>$id.cg</strong><br />";
	fopen(FILE,"+>$boards/bdscats.db");
	foreach(@catbase) {
		($name,$id,$tg1,$tg2,$tg3,$subcats) = split(/\|/,$_);
		if($subcats) {
			$subcatz = '';
			foreach $subcat (split(/\//,$subcats)) {
				if($URL{'id'} ne $subcat) { $subcatz .= $subcat."/"; }
			}
			$subcatz =~ s/\/\Z//g;
			print FILE "$name|$id|$tg1|$tg2|$tg3|$subcatz\n";
		}
		elsif($id ne $URL{'id'}) { print FILE "$_\n"; }
	}
	$ebout .= "$managecats[12]: <strong>$id $managecats[16] <i>bdscats.db</i></strong><br />";
	fclose(FILE);
	$ebout .= <<"EOT";
  </td>
 </tr><tr>
  <td class="win2">$managecats[12]: <strong>$count messages</strong></td>
 </tr>
</table>
EOT
	footerA();
	exit;
}

sub MoveCat {
	foreach(@catbase) {
		($t,$id,$t,$t,$t,$subcats) = split(/\|/,$_);
		foreach $nohere (split(/\//,$subcats)) {
			if($URL{'id'} eq $nohere) {
				@subcats = split(/\//,$subcats);
				$subcats{$id} = 1;
				$noshow{$nohere} = 1;
				last;
			}
		}
	}

	$readd = '';
	$count = 0;
	if($noshow{$URL{'id'}} && $URL{'s'} eq 'up') {
		foreach(@catbase) {
			($cattitle,$catid,$temp1,$input,$desc,$subcats) = split(/\|/,$_);
			if($subcats{$catid}) {
				foreach(@subcats) {
					if($URL{'id'} eq $_) { $movecnt = $count; }
					++$count; last;
				}

				for($e = 0; $e < @subcats; $e++) {
					if($e == $movecnt) {
						if($movecnt == 0) { $add[$e] = $subcats[$e]; } else { $add[--$e] = $subcats[$movecnt]; $add[++$e] = $subcats[--$movecnt]; }
					} else { $add[$e] = $subcats[$e]; }
				}
				foreach(@add) { $add .= "$_/"; }
				$add =~ s/\/\Z//g;
				$readd .= "$cattitle|$catid|$temp1|$input|$desc|$add\n";
			} else { $readd .= "$_\n"; }
		}
	} elsif($noshow{$URL{'id'}} && $URL{'s'} eq 'down') {
		foreach(@catbase) {
			($cattitle,$catid,$temp1,$input,$desc,$subcats) = split(/\|/,$_);
			if($subcats{$catid}) {
				foreach(@subcats) {
					if($URL{'id'} eq $_) { $movecnt = $count; }
					++$count;
				}
				for($e = 0; $e < @subcats; $e++) {
					if($e == $movecnt) {
						if($movecnt == $count) { $add[$e] = $subcats[$e]; } else { $add[$e] = $subcats[++$movecnt]; $add[++$e] = $subcats[--$movecnt]; }
					} else { $add[$e] = $subcats[$e]; }
				}
				foreach(@add) { $add .= "$_/"; }
				$add =~ s/\/\Z//g;
				$readd .= "$cattitle|$catid|$temp1|$input|$desc|$add\n";
			} else { $readd .= "$_\n"; }
		}
	} elsif(!$noshow{$URL{'id'}} && $URL{'s'} eq 'up') {
		$counter = 0;
		for($i = 0; $i < @catbase; $i++) {
			($name,$id) = split(/\|/,$catbase[$i]);
			if($id eq $URL{'id'}) { $move = $i; last; }
		}
		for($e = 0; $e < @catbase; $e++) {
			if($e == $move) {
				if($move == 0) { $add[$e] = $catbase[$e]; } else {
					$add[--$e] = $catbase[$move]; $add[++$e] = $catbase[--$move];
				}
			}
				else { $add[$e] = $catbase[$e]; }
		}
	} elsif(!$noshow{$URL{'id'}} && $URL{'s'} eq 'down') {
		$max = @catbase-1;
		$counter = 0;
		for($i = 0; $i < @catbase; $i++) {
			($name,$id) = split(/\|/,$catbase[$i]);
			if($id eq $URL{'id'}) { $move = $i; last; }
		}
		for($e = 0; $e < @catbase; $e++) {
			if($e == $move) {
				if($move == $max) { $add[$e] = $catbase[$e]; } else {
					$add[$e] = $catbase[++$move]; $add[++$e] = $catbase[--$move];
				}
			}
				else { $add[$e] = $catbase[$e]; }
		}
	}

	fopen(FILE,"+>$boards/bdscats.db");
	if(!$noshow{$URL{'id'}}) { foreach(@add) { print FILE "$_\n"; } }
		else { print FILE $readd; }
	fclose(FILE);

	redirect("$surl\lv-admin/a-boards/");
}
1;