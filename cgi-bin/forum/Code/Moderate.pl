#############################################
# E-Blah Bulletin Board Systems        2008 #
#############################################
# Copyright (c) 2001 - 2008 E-Blah.         #
#############################################

CoreLoad('Moderate',1);

sub Moderate {
	foreach(split(",",$newsboard)) { $newsboards{$_} = 1; }

	if($URL{'a'} eq 'calendar') { CoreLoad('Calendar'); CalendarEvents(); }
	$ipon  = 1 if($ismod);
	$ismod = 1 if($modon);

	foreach(@boardbase) {
		($id,$t,$t,$btit) = split("/",$_);
		$boards{$id} = $btit;

		fopen(TEMPMSG,"$boards/$id.msg");
		while($temp = <TEMPMSG>) {
			($tid,$ttitle) = split(/\|/,$temp);
			$thread{$tid} = "$id|$ttitle";
		}
		fclose(TEMPMSG);
	}

	if($URL{'a'} eq 'delnum') { Delnum(); }
	if($URL{'a'} eq 'ban') { IPBan(); }
	if($URL{'a'} eq 'ban2') { IPBan2(); }
	if($URL{'a'} eq 'sticky' && ($ston || $ismod)) { $ismod = 1; }
	elsif($URL{'a'} eq 'sticky' && !$ston) { $ismod = 0; }
	is_mod();
	if($URL{'a'} eq 'delthread') { DelThread(); }
	if($URL{'a'} eq 'move') { Move(); }
	if($URL{'a'} eq 'move2') { Move2(); }
	if($URL{'a'} eq 'sticky') { Sticky(); }
	if($URL{'a'} eq 'lock') { Lock(); }
	if($URL{'a'} eq 'split') { Split(); }
	if($URL{'a'} eq 'merge') { Merge(); }
	if($URL{'a'} eq 'mindex') { QMIndex(); }
	if($URL{'a'} eq 'modlog') { ModLog(); }
	CoreLoad('MessageDisplay'); MessageDisplay(); # No mod needed
}

sub QMIndex {
	$noredirh = 1;
	fopen(FILE,"$boards/$URL{'b'}.ino");
	@brdinfor = <FILE>;
	fclose(FILE);
	chomp @brdinfor;
	for($i = 0; $i <= ($brdinfor[0])+1; $i++) {
		if($FORM{$i} eq '') { next; }
		$URL{'m'} = $FORM{$i};
		if($FORM{'opt1'}) { Sticky(); $oR = 1; }
		if($FORM{'opt2'}) { Lock(); $oR = 1; }
		if($FORM{'opt4'}) { Move2(); $oR = 1; }
		if($FORM{'opt3'} && !$oR) { DelThread(); } # Only if others were not run!
	}

	# Rebuild the news ...
	CoreLoad('Portal');
	Shownews('1','html');
	Shownews('1','xml');

	redirect("$surl\lb-$URL{'b'}/");
}

sub Delnum {
	$mu = 1;
	fopen(FILE,"<$boards/$URL{'b'}.msg");
	@msg = <FILE>;
	fclose(FILE);
	foreach (@msg) {
		chomp $_;
		($mid,$t,$t,$t,$repliecnt,$t,$locked) = split(/\|/,$_);
		if($mid == $URL{'m'}) { $fnd = 1; last; }
	}

	if($fnd != 1) { error("$moderate[1]: $URL{'m'}.txt"); }
	if($locked) { error($moderate[2]); }
	if($repliecnt < $URL{'n'}) { error("$moderate[1]."); }
	$counter = 0;
	$mu = 0;
	fopen(FILE,"$messages/$URL{'m'}.txt");
	@usethis = <FILE>;
	fclose(FILE);
	foreach(@usethis) {
		chomp $_;
		($whoposted,$t,$t,$t,$fdate,$t,$t,$t,$afile) = split(/\|/,$_);
		if($counter == $URL{'n'}) {
			if((!$members{'Administrator',$username} && !$ismod && !$modifyon) && $whoposted ne $username) { push(@newmess,$_); $mu = 1; ++$counter; next; }
			if($modifytime && (!$members{'Administrator',$username} && !$ismod && !$modifyon) && $fdate+($modifytime*3600) < time) { error($moderate[72]); }

			if($afile ne '') {
				foreach $deletefile (split(/\//,$afile)) { unlink("$uploaddir/$deletefile","$uploaddir/thumbnails/$deletefile","$prefs/Hits/$deletefile.txt"); }
			}
			$pdu = $whoposted;
		} else { push(@newmess,$_); }
		++$counter;
	}
	if($mu) { error($moderate[4]); }

	fopen(FILE,"+>$messages/$URL{'m'}.txt");
	foreach(@newmess) { print FILE "$_\n"; }
	fclose(FILE);

	if($counter == 1) { DelThread(); }

	fopen(FILE,"+<$boards/$URL{'b'}.msg") || error("$moderate[1]: $URL{'b'}.msg");
	@fdata = <FILE>;
	chomp @fdata;
	for($i = 0; $i < @fdata; $i++) {
		($mid,$c,$d,$e,$reply,$b,$locked,$a,$ff,$jj) = split(/\|/,$fdata[$i]);
		if($fdata[$i] =~ m/\A$URL{'m'}\|/) {
			$reply = @newmess-1;
			($jj,$t,$t,$t,$ff) = split(/\|/,$newmess[$reply]);
		}
		push(@writedata,"$ff|$mid|$c|$d|$e|$reply|$b|$locked|$a|$jj");
	}

	truncate(FILE,0);
	seek(FILE,0,0);

	foreach(sort{$b <=> $a} @writedata) {
		($q,$mid,$c,$d,$e,$reply,$b,$locked,$a,$z) = split(/\|/,$_);
		if($mid eq '') { next; }
		print FILE "$mid|$c|$d|$e|$reply|$b|$locked|$a|$q|$z\n";
		$totalreplys += $reply;
		++$mtotal;
	}
	fclose(FILE);
	$totalreplys += $mtotal;

	fopen(FILE,"+>$boards/$URL{'b'}.ino");
	print FILE "$mtotal\n$totalreplys\n";
	fclose(FILE);

	MLogging($URL{'m'},8,$username,time,"$URL{'n'}/$pdu",$URL{'b'});

	if($newsboards{$URL{'b'}}) {
		CoreLoad('Portal');
		Shownews('1','html');
		Shownews('1','xml');
	}

	redirect("$surl\lm-$URL{'m'}/");
}

sub Lock {
	if($URL{'m'} eq '') { error($gtxt{'error2'}); }

	$fnd = 0;
	$counter = 0;
	fopen(FILE,"+<$boards/$URL{'b'}.msg") || error("$moderate[1]: $URL{'b'}.msg",1);
	$readdata = 1;
	while($readdata) {
		$messageend = tell FILE; # Get location
		$readdata = <FILE>;
		($tmid) = split(/\|/,$readdata);
		if($tmid eq $URL{'m'}) { $fnd = 1; last; }
	}
	if($fnd) {
		seek(FILE,$messageend,0);
		chomp $readdata;
		($mid,$a,$b,$c,$d,$e,$lock,$f,$sd,$ds) = split(/\|/,$readdata);
		$lock = $lock ? 0 : 1;
		print FILE "$mid|$a|$b|$c|$d|$e|$lock|$f|$sd|$ds\n";
	}
	fclose(FILE);

	MLogging($URL{'m'},3,$username,time,$lock,$thread{$URL{'m'}});

	$url = $lock ? "$surl\lb-$URL{'b'}/" : "$surl\lm-$URL{'m'}/";
	if(!$noredirh) { redirect(); }
}

sub Sticky {
	my($noadd,$added);
	if($access && !$members{'Administrator',$username}) { error($gtxt{'error'}); }

	fopen(FILE,"+<$boards/Stick.txt");
	@sticky = <FILE>;
	truncate(FILE,0);
	seek(FILE,0,0);
	foreach(@sticky) {
		chomp $_;
		($bdat,$tdat) = split(/\|/,$_);
		if($tdat eq $URL{'m'}) { $noadd = 1; next; }
		print FILE "$_\n";
	}
	if(!$noadd && !$unstickstick) { print FILE "$URL{'b'}|$URL{'m'}\n"; $added = 1; }
	fclose(FILE);

	MLogging($URL{'m'},2,$username,time,$added,$thread{$URL{'m'}});

	if(!$noredirh && !$unstickstick) { redirect("$surl\lb-$URL{'b'}/"); }
}

sub DelThread {
	my($mtotal,$totalreplys,$wefnd,$temp1,$temp2);

	fopen(FILE,"+<$boards/$URL{'b'}.msg") || error("$moderate[1]: $URL{'b'}.msg");
	@fdata = <FILE>;
	truncate(FILE,0);
	seek(FILE,0,0);
	foreach(@fdata) {
		($t,$mtitle,$t,$t,$replies) = split(/\|/,$_);
		if($_ =~ m/\A$URL{'m'}\|/) { $wefnd = 1; $tsub = $mtitle; next; }
		print FILE $_;
		$totalreplys += $replies;
		++$mtotal;
	}
	fclose(FILE);
	$totalreplys += $mtotal;

	fopen(FILE,"+>$boards/$URL{'b'}.ino");
	print FILE "$mtotal\n$totalreplys\n";
	fclose(FILE);

	if(!$noredirh && !$wefnd) { error("$moderate[1]."); }

	GetMessageDatabase($URL{'m'},'',2);

	fopen(FILE,"$messages/$URL{'m'}.txt");
	@messagedata = <FILE>;
	fclose(FILE);
	chomp @messagedata;
	foreach(@messagedata) {
		($t,$t,$t,$t,$t,$t,$t,$t,$afile) = split(/\|/,$_);
		if($afile ne '') {
			foreach $deletefile (split(/\//,$afile)) { unlink("$uploaddir/$deletefile","$uploaddir/thumbnails/$deletefile","$prefs/Hits/$deletefile.txt"); }
		}
	}

	unlink("$messages/$URL{'m'}.txt","$messages/$URL{'m'}.tags","$messages/$URL{'m'}.rate","$messages/$URL{'m'}.txt.temp","$messages/$URL{'m'}.view","$messages/$URL{'m'}.polled","$messages/Mail/$URL{'m'}.mail","$messages/$URL{'m'}.poll","$messages/$URL{'m'}.log");
	if($tagsenable) {
		CoreLoad('Tags');
		RemoveTags($URL{'m'});
	}

	$unstickstick = 1;
	Sticky();

	($temp1,$temp2) = split(/\|/,$thread{$URL{'m'}});

	MLogging($URL{'m'},6,$username,time,$temp2,$temp1,$temp2);

	if(!$noredirh) { redirect("$surl\lb-$URL{'b'}/"); }
}

sub Move {
	fopen(FILE,"$boards/$URL{'b'}.msg");
	while(<FILE>) {
		($mid) = split(/\|/,$_);
		if($mid eq $URL{'m'}) { $ok = 1; }
	}
	fclose(FILE);
	if(!$ok) { error($moderate[14]); }

	$scat{$URL{'b'}} = ' selected="selected"';
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

	if($ops eq '') { error($moderate[69]); }

	if($showmove) {
		$totalmove = <<"EOT";
<tr>
 <td class="vtop right"><input type="checkbox" name="showmove2" value="1" checked="checked" /></td>
 <td><strong>$moderate[70]</strong><div class="smalltext">$moderate[71]</div></td>
</tr>
EOT
	}

	$title = $moderate[18];
	header();
	$ebout .= <<"EOT";
<form action="$surl\lv-mod/b-$URL{'b'}/a-move2/m-$URL{'m'}/" method="post">
<table class="border" cellpadding="5" cellspacing="1" width="500">
 <tr>
  <td class="titlebg"><strong>$title</strong></td>
 </tr><tr>
  <td class="win2 smalltext">$moderate[19]</td>
 </tr><tr>
  <td class="win">
   <table cellpadding="4" cellspacing="0" width="100%">
    <tr>
     <td style="width: 40%" class="right"><strong>$moderate[20]:</strong></td>
     <td style="width: 60%"><select name="b">$ops</select></td>
    </tr>$totalmove
   </table>
  </td>
 </tr><tr>
  <td class="win2 center"><input type="submit" name="move" value="&nbsp;$moderate[21] " /></td>
 </tr>
</table>
</form>
EOT
	footer();
	exit;
}

sub Move2 {
	my($totalreplys,$mtotal,$totalreplys2,$mtotal2,@savedata,$stuck,$new);

	if($showmove) {
		$showmove = 0 if($FORM{'showmove2'} != 1 && !$noredirh);
	}

	# Basics
	fopen(FILE,"$boards/$URL{'b'}.msg");
	while(<FILE>) {
		($mid,$sub) = split(/\|/,$_);
		if($mid eq $URL{'m'}) { $ok = 1; $tsub = $sub; last; }
	}
	fclose(FILE);
	if(!$ok) { error($moderate[14]); }

	if($FORM{'b'} eq '') { error($gtxt{'bfield'}); }
	if($FORM{'b'} eq $URL{'b'}) { error($gtxt{'bfield'}); }
	foreach(@boardbase) {
		($okay) = split("/",$_);
		if($okay eq $FORM{'b'}) { $error = 1; }
	}
	if(!$error) { error($gtxt{'bfield'}); }

	$movingid = $URL{'m'};

	# Remove from board ...
	fopen(FILE,"+<$boards/$URL{'b'}.msg") || error("$moderate[1]: $URL{'b'}.msg");
	@fdata = <FILE>;
	truncate(FILE,0);
	seek(FILE,0,0);
	$message = Format($FORM{'message'});
	if($showmove) { # Create a forwarding message
		$new = time;
		while(-e("$messages/$new.txt")) { ++$new; }
		fopen(MESS,">$messages/$new.txt");
		print MESS qq~$username|{MOVED-MESSAGE-PLACEHOLDER}|$ENV{'REMOTE_ADDR'}|$memberid{$username}{'email'}|$new\n~;
		fclose(MESS);
		fopen(VIEW,">$messages/$new.view");
		print VIEW "0\n";
		fclose(VIEW);
		print FILE "$new|$movingid<>$sub|$username|$new|0|0|1|xx.gif|$new|$username\n";

		# Ensure thread left is not marked as "new"
		$URL{'m'} = $new;
		LogPage();
	}

	foreach(@fdata) {
		if($_ =~ m/\A$movingid\|/) { $movemessage = $_; next; }
		print FILE $_;
		($t,$t,$t,$t,$replies) = split(/\|/,$_);
		$totalreplys += $replies;
		++$mtotal;
	}
	fclose(FILE);
	$totalreplys += $mtotal;

	# Create a forwarding message
	GetMessageDatabase($new,$URL{'b'},1) if($showmove && $FORM{'addmessage'} && $message ne '');

	fopen(FILE,"+>$boards/$URL{'b'}.ino");
	print FILE "$mtotal\n$totalreplys\n";
	fclose(FILE);

	# Write to target board ...
	fopen(FILE,"+<$boards/$FORM{'b'}.msg") || error("$moderate[1]: $FORM{'b'}.msg");
	my @tempdata = <FILE>;
	push(@tempdata,$movemessage);
	chomp @tempdata;

	foreach(@tempdata) {
		($mid,$sub,$poster,$pdate,$replies,$poll,$lock,$micon,$lposttime,$luserwhoposted) = split(/\|/,$_);
		push(@savedata,"$lposttime|$mid|$sub|$poster|$pdate|$replies|$poll|$lock|$micon|$luserwhoposted");
		$totalreplys2 += $replies;
		++$mtotal2;
	}

	truncate(FILE,0);
	seek(FILE,0,0);

	foreach(sort{$b <=> $a} @savedata) {
		($q,$mid,$c,$d,$e,$reply,$b,$locked,$a,$z) = split(/\|/,$_);
		if($mid eq '') { next; }
		print FILE "$mid|$c|$d|$e|$reply|$b|$locked|$a|$q|$z\n";
	}
	fclose(FILE);
	$totalreplys2 += $mtotal2;

	GetMessageDatabase($movingid,$FORM{'b'},1);

	fopen(FILE,"+>$boards/$FORM{'b'}.ino");
	print FILE "$mtotal2\n$totalreplys2\n";
	fclose(FILE);

	# Check if it was sticky ...
	fopen(FILE,"+<$boards/Stick.txt");
	@sticky = <FILE>;
	truncate(FILE,0);
	seek(FILE,0,0);
	foreach(@sticky) {
		chomp $_;
		($bdat,$tdat) = split(/\|/,$_);
		if($tdat eq $movingid) { $stuck = 1; next; }
		print FILE "$_\n";
	}
	if($stuck) { print FILE "$FORM{'b'}|$movingid\n"; }
	fclose(FILE);

	MLogging($movingid,1,$username,time,$FORM{'b'},$FORM{'b'});

	if(!$noredirh) { redirect("$surl\lm-$movingid/"); }
}

sub IPBan {
	IPBanOk();
	fopen(FILE,"$prefs/BanList.txt");
	@banlist = <FILE>;
	fclose(FILE);
	chomp @banlist;
	foreach(@banlist) {
		($ips,$days) = split(/\|/,$_);
		if($URL{'ip'} eq $ips) { $ipfnd = 1; }
	}
	if($ipfnd) { $message = "$moderate[28] ($URL{'ip'}) $moderate[29]"; $what = $moderate[30]; }
		else { $message = <<"EOT";
$moderate[31]
<table cellpadding="2" width="75%">
 <tr>
  <td class="right"><strong>$moderate[49]:</strong></td>
  <td><select name="ban">
<option value="forever">$moderate[48]</option>
<option value="1">1 $moderate[47]</option>
<option value="3">3 $moderate[47]</option>
<option value="7">1 $gtxt{'39'}</option>
<option value="30">1 $gtxt{'40'}</option>
</select></td>
 </tr><tr>
  <td class="right"><strong>$moderate[50]:</strong></td>
  <td><input type="grp" name="grp" /></td>
 </tr>
</table>
EOT
			$what = $moderate[33];
		}
	if($URL{'ip'} !~ /[1-9.]/ || $URL{'ip'} =~ /[A-Za-z]/) { error($moderate[34]); }
	$title = $moderate[33];
	header();
	$ebout .= <<"EOT";
<form action="$surl\lv-mod/a-ban2/ip-$URL{'ip'}/m-$URL{'m'}/" method="post">
<table class="border" cellspacing="1" cellpadding="4" width="450">
 <tr>
  <td class="titlebg"><strong><img src="$images/ban.png" alt="" /> $title</strong></td>
 </tr><tr>
  <td class="win">$message</td>
 </tr><tr>
  <td class="win2"><strong><input type="submit" value=" $what " /></strong></td>
 </tr>
</table>
EOT
	footer();
	exit;
}

sub IPBan2 {
	IPBanOk();
	if($FORM{'grp'} eq '') { $FORM{'grp'} = "Mod_Ban"; }
	fopen(FILE,"$prefs/BanList.txt");
	@banlist = <FILE>;
	fclose(FILE);
	chomp @banlist;
	foreach(@banlist) {
		($ips,$days) = split(/\|/,$_);
		if($URL{'ip'} eq $ips) { $noadd = 1; next; }
			else { $readd .= "$_\n"; }
	}
	if($noadd != 1) {
		if($FORM{'ban'} ne 'forever') {
			$expire = time+($FORM{'ban'}*86400);
			$URL{'ip'} .="|$FORM{'ban'}|$expire";
		} else { $URL{'ip'} .= "||"; }
		$FORM{'grp'} =~ s/ /_/g;
		$FORM{'grp'} =~ s/[#%+,\\\/:?"<>'|@^\$\&~'\)\(\]\[\;{}!`=-]//g;
		$readd .= "$URL{'ip'}|$FORM{'grp'}\n";
	}
	fopen(FILE,"+>$prefs/BanList.txt");
	print FILE $readd;
	fclose(FILE);
	$url = "$surl\lm-$URL{'m'}/";
	if($URL{'tf'} ne '') { $url = "$surl\lv-admin/a-reports/"; }
	redirect();
}

sub IPBanOk {
	if($URL{'ip'} eq $ENV{'REMOTE_ADDR'}) { error($moderate[36]); }
	if($ipon != 1 && !$members{'Administrator',$username}) { error($gtxt{'error'}); }
	fopen(FILE,"$prefs/BanList.txt");
	@banlist = <FILE>;
	fclose(FILE);
	chomp @banlist;
	if($URL{'ip'} !~ /[1-9.]/ || $URL{'ip'} =~ /[A-Za-z]/) { error($gtxt{'bfield'}); }
}

sub OldThreads {
	is_admin(5.3);
	CoreLoad('AdminList');
	if($URL{'p'}) { OldThreads2(); }

	$title = $moderate[41];
	headerA();
	$ebout .= <<"EOT";
<form action="$surl\lv-admin/a-remove/p-1/" method="post" enctype="multipart/form-data" onsubmit="if(!window.confirm('$moderate[104]')) { return false; }">
<table class="border" cellpadding="6" cellspacing="1" width="500">
 <tr>
  <td class="titlebg"><strong><img src="$images/brd_main.gif" alt="" /> $title</strong></td>
 </tr><tr>
  <td class="win smalltext">$moderate[37]</td>
 </tr><tr>
  <td class="win2"><strong>$moderate[38] <input type="text" name="days" value="30" size="4" /> $moderate[39].</strong></td>
 </tr><tr>
  <td class="catbg smalltext center"><strong>$moderate[40]</strong></td>
 </tr><tr>
  <td class="win center"><select name="boards" size="10" style="width: 300px;" multiple="multiple">
EOT
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
		$scat{$id} = ' selected="selected"';
	}

	$temp = '';
	SubCatsList($cats,1);
	$ebout .= $temp;

	$ebout .= <<"EOT";
  </select></td>
 </tr><tr>
  <td class="win2 center"><input type="submit" value=" $moderate[41] " /></td>
 </tr>
</table>
</form>
EOT
	footerA();
	exit;
}

sub OldThreads2 {
	is_admin(5.3);

	# Lock the forum ...
	fopen(FILE,">$root/Maintance.lock");
	print FILE "\$maintance = 1;\n\$maintancer = qq~$moderate[51]~;\n1;";
	fclose(FILE);

	$threadold = time-($FORM{'days'}*86400);

	$counter = 0;
	@delbds = split(",",$FORM{'boards'});
	foreach(@delbds) { $temp{$_} = 1; }

	fopen(FILE,"$boards/Stick.txt");
	@sticky = <FILE>;
	fclose(FILE);
	chomp @sticky;
	foreach(@sticky) {
		($bdat,$tdat) = split(/\|/,$_);
		if(!$temp{$bdat}) { $other = "$_\n"; next; }
		$stick{$tdat} = $bdat;
	}

	fopen(MODLOG,">>$prefs/Moderator.log");
	foreach $open (@delbds) {
		unlink("$boards/$open.msg.bak","$boards/$open.msg.temp");
		rename("$boards/$open.msg","$boards/$open.msg.bak");
		fopen(FILE,"$boards/$open.msg.bak") || error("$moderate[1]: $open.msg.bak");
		@messdata = <FILE>;
		fclose(FILE);
		chomp @messdata;
		fopen(FILE,">$boards/$open.msg.temp");
		foreach(@messdata) {
			($id,$mtitle) = split(/\|/,$_);
			if($id > $threadold || $stick{$id}) { # If thread is old, or is stuck, leave it ...
				print FILE "$_\n";
				next;
			}

			$keep = 0;

			fopen(MESS,"$messages/$id.txt");
			@mread = <MESS>;
			fclose(MESS);
			chomp @mread;
			foreach $read (@mread) {
				($t,$t,$t,$t,$oldtime,$t,$t,$t,$afile) = split(/\|/,$read);
				if($afile) {
					foreach $deletefile (split(/\//,$afile)) { unlink("$uploaddir/$deletefile","$uploaddir/thumbnails/$deletefile","$prefs/Hits/$deletefile.txt"); }
				}
				if($oldtime > $threadold) { # Thread is old, but has been active within the past x days
					print FILE "$_\n";
					$keep = 1;
					last;
				}
			}
			if(!$keep) {
				GetMessageDatabase($id,'',2);
				print MODLOG "7|$username|".time."|$mtitle|$ENV{'REMOTE_ADDR'}|$id|$open|$mtitle\n";
				unlink("$messages/$id.txt","$messages/$id.tags","$messages/$id.rate","$messages/$id.txt.temp","$messages/$id.view","$messages/$id.polled","$messages/Mail/$id.mail","$messages/$id.poll");
				++$counter;

				if($tagsenable) {
					CoreLoad('Tags');
					RemoveTags($id);
				}
			}
		}
		fclose(FILE);
		unlink("$boards/$open.msg.bak");
		rename("$boards/$open.msg.temp","$boards/$open.msg");
	}
	fclose(MODLOG);

	CoreLoad('Admin1');
	Repop();

	$title = $moderate[62];
	headerA();
	$ebout .= <<"EOT";
<table class="border" cellpadding="4" cellspacing="1" width="500">
 <tr>
  <td class="titlebg"><strong><img src="$images/brd_main.gif" alt="" /> $title</strong></td>
 </tr><tr>
  <td class="win smalltext"><strong>$moderate[45]: $counter<br />$moderate[46]: $attcnt</strong></td>
 </tr><tr>
  <td class="win2"><strong><a href="javascript:history.back(-2)">&#171; $gtxt{'26'}</a></strong></td>
 </tr>
</table>
EOT
	footerA();
	exit;
}

sub Split {
	$messid = $URL{'m'};
	fopen(FILE,"$boards/$URL{'b'}.msg") || error("$moderate[1]: $URL{'b'}.msg");
	while(<FILE>) {
		chomp;
		($messageid,$ptitle,$t,$t,$treplies) = split(/\|/,$_);
		if($messid == $messageid) { $fnd = 1; last; }
	}
	fclose(FILE);
	if(!$fnd) { error("$moderate[1]: $messageid.txt"); }

	fopen(FILE,"$messages/$messageid.txt") || error("$moderate[1]: $messageid.txt");
	@message = <FILE>;
	fclose(FILE);
	$message = @message;
	if($message == 1) { error($moderate[53]); }
	if($URL{'p'}) { Split2(); }

	$scat{$URL{'b'}} = ' selected="selected"';
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

	$title = $moderate[54];
	header();
	$ebout .= <<"EOT";
<form action="$scripturl/v-mod/a-split/m-$URL{'m'}/p-1/" method="post">
<table cellpadding="4" cellspacing="1" class="border" width="750">
 <tr>
  <td class="titlebg"><strong>$title</strong></td>
 </tr><tr>
  <td class="win smalltext">$moderate[55]</td>
 </tr><tr>
  <td class="win2">
   <table cellpadding="4" cellspacing="0" width="100%">
    <tr>
     <td class="right" style="width: 45%"><strong>$moderate[56]:</strong></td>
     <td style="width: 55%">$ptitle</td>
    </tr><tr>
     <td colspan="2"><hr /></td>
    </tr><tr>
     <td class="right" style="width: 45%"><strong>$moderate[57]:</strong></td>
     <td style="width: 55%"><input type="text" name="title" size="30" maxlength="50" /></td>
    </tr><tr>
     <td class="right" style="width: 45%"><strong>$moderate[58]:</strong></td>
     <td style="width: 55%"><select name="board">$ops</select></td>
    </tr>
   </table>
  </td>
 </tr>
</table>
<br />
<table class="border" cellpadding="4" cellspacing="1" width="750">
 <tr>
  <td class="center vtop catbg smalltext"><strong>$moderate[59]</strong></td>
  <td class="catbg smalltext center"><strong>$moderate[60]</strong></td>
 </tr>
EOT
	@bgcolors = ('win','win2');
	$count = 0;
	foreach(@message) {
		$bgcolor = $bgcolors[$count % 2];
		($postinguser,$message,$ip,$email,$date,$nosmile) = split(/\|/,$_);
		GetMemberID($postinguser);
		if($memberid{$postinguser}{'sn'} eq '') { $postedby = $postinguser; }
			else { $postedby = $userurl{$postinguser}; }
		$datepost = get_date($date);

		if(length($message) > 200) {
			$message =~ s~\[table\](.*?)\[\/table\]~$var{'88'}~sgi;
			$message = substr($message,0,400);
			$message = BC($message);
			MakeSmall();
			$message .= " ...";
		} else { $message = BC($message); }

		if($count > 0) { $split = qq~<input type="checkbox" name="split_$count" value="1" />~; }

		$ebout .= <<"EOT";
 <tr>
  <td class="center $bgcolor">$split</td>
  <td class="$bgcolor">
  <table cellpadding="1" width="100%">
   <tr>
    <td class="smalltext"><strong>$gtxt{'19'}:</strong> $postedby</td>
    <td class="right smalltext"><strong>$gtxt{'21'}:</strong> $datepost</td>
   </tr><tr>
    <td colspan="2" class="smalltext"><hr />$message</td>
   </tr>
  </table></td>
 </tr>
EOT
		++$count;
	}
	$bgcolor = $bgcolors[$count % 2];
	$ebout .= <<"EOT";
 <tr>
  <td class="$bgcolor center" colspan="2"><input type="submit" value=" $moderate[54] " /></td>
 </tr>
</table>
</form>
EOT
	footer();
	exit;
}

sub Split2 {
	$sub = Format($FORM{'title'});
	if($sub eq '') { error($gtxt{'bfield'}); }
	if(length($sub) > 50) { error($gtxt{'bfield'}); }
	if($FORM{'board'} eq '') { error($gtxt{'bfield'}); }

	if(!-e("$boards/$URL{'b'}.msg")) { error("$moderate[1]: $URL{'b'}.msg"); }
	if(!-e("$boards/$FORM{'board'}.msg")) { error("$moderate[1]: $FORM{'board'}.msg"); }

	# Lets split the message files first ...
	$count = 0;
	fopen(FILE,"+<$messages/$messageid.txt") || error("$moderate[1]: $messageid.txt");
	@tempopen = <FILE>;
	chomp @tempopen;
	foreach(@tempopen) {
		if(!$FORM{"split_$count"} || $count == 0) {
			($lopostinguser,$t,$t,$t,$lodate) = split(/\|/,$_);
			push(@rewrite,$_);
		} else {
			if(!$first) { ($postinguser,$message,$ip,$email,$date,$nosmile) = split(/\|/,$_); $first = 1; }
			($lpostinguser,$t,$t,$t,$ldate) = split(/\|/,$_);
			++$first4;
			push(@addto,$_);
		}
		++$count;
	}
	if(!$first4) {
		fclose(FILE);
		error($moderate[61]);
	}
	truncate(FILE,0);
	seek(FILE,0,0);
	foreach(@rewrite) { print FILE "$_\n"; }
	fclose(FILE);
	--$first4;

	# Lets find a valid thread to write to ...
	for($e = 0; $e < 99; $e++) {
		if(-e "$messages/$date.txt") { ++$date; } else { last; }
	}

	# Write to it now
	fopen(FILE,">$messages/$date.txt");
	foreach(@addto) { print FILE "$_\n"; }
	fclose(FILE);
	fopen(FILE,">$messages/$date.view");
	fclose(FILE);
	GetMessageDatabase($date,$FORM{'board'},1);

	$newboarddata = "$ldate|$date|$sub|$postinguser|$date|$first4|0|0|xx.gif|$lpostinguser";

	# Now comes the tricky part, edit message data.
	fopen(FILE,"+<$boards/$URL{'b'}.msg") || error("$moderate[1]: $URL{'b'}.msg");
	@tempopen = <FILE>;
	chomp @tempopen;
	foreach(@tempopen) {
		($mid,$sub,$poster,$pdate,$replies,$poll,$lock,$micon,$lposttime,$luserwhoposted) = split(/\|/,$_);
		if($mid eq $URL{'m'}) {
			$replies -= $first4+1;
			$repcnt += $replies;
			$lposttime = $lodate;
			$luserwhoposted = $lopostinguser;
		} else { $repcnt += $replies; }
		push(@tempwrite,"$lposttime|$mid|$sub|$poster|$pdate|$replies|$poll|$lock|$micon|$luserwhoposted");
	}
	if($FORM{'board'} eq $URL{'b'}) { push(@tempwrite,$newboarddata); $repcnt += $first4; $aadd = 1; }
	truncate(FILE,0);
	seek(FILE,0,0);
	foreach(sort{$b <=> $a} @tempwrite) {
		($q,$mid,$c,$d,$e,$reply,$b,$locked,$a,$z) = split(/\|/,$_);
		if($mid eq '') { next; }
		print FILE "$mid|$c|$d|$e|$reply|$b|$locked|$a|$q|$z\n";
		++$num;
	}
	fclose(FILE);
	$repcnt += $num;
	fopen(FILE,">$boards/$URL{'b'}.ino");
	print FILE "$num\n$repcnt\n";
	fclose(FILE);

	if(!$aadd) { # Move split message to another board ...
		$num = 0;
		fopen(FILE,"+<$boards/$FORM{'board'}.msg") || error("$moderate[1]: $FORM{'board'}.msg");
		@tempopen = <FILE>;
		chomp @tempopen;
		foreach(@tempopen) {
			($mid,$sub,$poster,$pdate,$replies,$poll,$lock,$micon,$lposttime,$luserwhoposted) = split(/\|/,$_);
			$copyto += $replies;
			push(@tempwriteto,"$lposttime|$mid|$sub|$poster|$pdate|$replies|$poll|$lock|$micon|$luserwhoposted");
		}
		push(@tempwriteto,$newboarddata);
		$copyto += $first4;
		truncate(FILE,0);
		seek(FILE,0,0);
		foreach(sort{$b <=> $a} @tempwriteto) {
			($q,$mid,$c,$d,$e,$reply,$b,$locked,$a,$z) = split(/\|/,$_);
			if($mid eq '') { next; }
			print FILE "$mid|$c|$d|$e|$reply|$b|$locked|$a|$q|$z\n";
			++$num;
		}
		fclose(FILE);
		$copyto += $num;
		fopen(FILE,">$boards/$FORM{'board'}.ino");
		print FILE "$num\n$copyto\n";
		fclose(FILE);
	}

	MLogging($messageid,4,$username,time,$sub,$FORM{'board'});

	redirect("$surl\lm-$date/");
}

sub Merge {
	if($FORM{'topic'} =~ s/http:\/\///gsi) {
		@url = split(/\,|\/|\?/,$FORM{'topic'});
		foreach (@url) {
			($action,$actiondo) = split("-",$_);
			if($action eq 'm') { $getfrom = $actiondo; }
		}
	} else { $getfrom = $FORM{'topic'}; }

	foreach(@boardbase) {
		($oboard,$desc,$t,$bnme) = split("/",$_);
		fopen(FILE,"$boards/$oboard.msg");
		while(<FILE>) {
			chomp $_;
			($mid,$t) = split(/\|/,$_);
			if($getfrom eq $mid) { $mergebrd = $oboard; }
			if($URL{'m'} eq $mid) { $ttitle = $t; $urlthread = $mid; }
			if($urlthread && $mergebrd) { last; }
		}
		fclose(FILE);
		if($urlthread && $mergebrd) { last; }
	}
	if($urlthread eq '') { error("$moderate[1]: $urlthread"); }
	if($URL{'p'}) { Merge2(); }
	$title = $moderate[67];
	header();
	$ebout .= <<"EOT";
<form action="$scripturl\lv-mod/a-merge/m-$URL{'m'}/p-1/" method="post">
<table cellpadding="4" cellspacing="1" class="border" width="700">
 <tr>
  <td class="titlebg"><strong>$title</strong></td>
 </tr><tr>
  <td class="win smalltext">$moderate[63]</td>
 </tr><tr>
  <td class="win2">
   <table width="100%" cellpadding="4" cellspacing="0">
    <tr>
     <td style="width: 40%" class="right"><strong>$moderate[64]:</strong></td>
     <td style="width: 60%" class="vtop"><input type="text" name="subject" value="$ttitle" maxlength="50" size="40" /></td>
    </tr><tr>
     <td style="width: 40%" class="right"><strong>$moderate[65]:</strong><div class="smalltext">$moderate[66]</div></td>
     <td style="width: 60%" class="vtop"><input type="text" name="topic" size="50" /></td>
    </tr>
   </table>
  </td>
 </tr><tr>
  <td class="win center"><input type="submit" value="$moderate[67]" /></td>
 </tr>
</table>
</form>
EOT
	footer();
	exit
}

sub Merge2 {
	$subject = Format($FORM{'subject'});
	if(length($subject) > 50) { error($gtxt{'bfield'}); }
	if($subject eq ' ' || $subject eq '&nbsp;' || $subject eq '') { error($gtxt{'bfield'}); }
	if(!$mergebrd) { error("$moderate[1]: $getfrom"); }
	if($getfrom eq $urlthread) { error($moderate[68]); }

	fopen(FILE,"$messages/$getfrom.txt");
	while(<FILE>) {
		chomp $_;
		($user,$message,$ipaddr,$email,$fdate,$nosmile,$mod4,$mod2,$afile) = split(/\|/,$_);
		push(@cont,"$fdate|$user|$message|$ipaddr|$email|$nosmile|$mod4|$mod2|$afile");
	}
	fclose(FILE);

	$URLbackup = $URL{'m'};
	$URL{'m'} = $getfrom;
	$unstickstick = 1;
	Sticky();
	$URL{'m'} = $URLbackup;

	unlink("$messages/$getfrom.poll","$messages/$getfrom.tags","$messages/$getfrom.polled","$messages/$getfrom.view","$messages/$getfrom.txt","$messages/$getfrom.rate","$messages/$getfrom.txt.temp","$messages/Mail/$getfrom.mail","$messages/$getfrom.log");

	if($tagsenable) {
		CoreLoad('Tags');
		RemoveTags($getfrom);
	}

	GetMessageDatabase($getfrom,'',2);

	fopen(FILE,"$messages/$URL{'m'}.txt");
	while(<FILE>) {
		chomp $_;
		($user,$message,$ipaddr,$email,$fdate,$nosmile,$mod4,$mod2,$afile) = split(/\|/,$_);
		push(@cont,"$fdate|$user|$message|$ipaddr|$email|$nosmile|$mod4|$mod2|$afile");
	}
	fclose(FILE);
	fopen(FILE,">$messages/$URL{'m'}.txt");
	foreach(sort{$a <=> $b} @cont) {
		($fdate,$user,$message,$ipaddr,$email,$nosmile,$mod4,$mod2,$afile) = split(/\|/,$_);
		if(!$threadstart) { $threadstart = $user; $starttime = $fdate; }
		print FILE "$user|$message|$ipaddr|$email|$fdate|$nosmile|$mod4|$mod2|$afile\n";
		++$messagecnt;
	}
	fclose(FILE);

	if(-e("$messages/$starttime.txt")) { $starttime = $URL{'m'}; }

	# Keep the old stickys ...
	foreach (@sticky) {
		($bdat,$tdat) = split(/\|/,$_);
		if($tdat eq $URL{'m'}) { $restick = 1; }
	}
	if($restick) {
		fopen(FILE,"+>$boards/Stick.txt");
		foreach(@sticky) {
			($bdat,$tdat) = split(/\|/,$_);
			if($tdat eq $URL{'m'}) { $tdat = $starttime; }
			print FILE "$bdat|$tdat\n";
		}
		fclose(FILE);
	}
	rename("$messages/$URL{'m'}.txt","$messages/$starttime.txt");
	rename("$messages/$URL{'m'}.rate","$messages/$starttime.rate");
	rename("$messages/$URL{'m'}.polled","$messages/$starttime.polled");
	rename("$messages/$URL{'m'}.poll","$messages/$starttime.poll");
	unlink("$messages/$URL{'m'}.txt.temp");
	$lastposted = $user;
	$lasttime = $fdate;

	GetMessageDatabase($starttime,$URL{'b'},1);

	# Remove old thread from board ...
	fopen(FILE,"+<$boards/$mergebrd.msg") || error("$moderate[1]: $mergebrd.msg");
	@fdata = <FILE>;
	truncate(FILE,0);
	seek(FILE,0,0);
	foreach(@fdata) {
		if($_ =~ m/\A$getfrom\|/) { $wefnd = 1; next; }
		print FILE $_;
		($t,$tsub,$t,$t,$replies) = split(/\|/,$_);
		$totalreplys += $replies;
		++$mtotal;
	}
	fclose(FILE);
	$totalreplys += $mtotal;

	fopen(FILE,"+>$boards/$mergebrd.ino");
	print FILE "$mtotal\n$totalreplys\n";
	fclose(FILE);

	# Readd to index ...
	$mtotal = 0;
	$totalreplys = 0;
	fopen(FILE,"+<$boards/$URL{'b'}.msg") || error("$moderate[1]: $URL{'b'}.msg");
	while( $readdata = <FILE> ) {
		chomp $readdata;
		($mid,$sub,$poster,$pdate,$replies,$poll,$lock,$micon,$lposttime,$luserwhoposted) = split(/\|/,$readdata);
		if($mid eq $URL{'m'}) { $sub = $subject; $replies = $messagecnt-1; $lposttime = $lasttime; $luserwhoposted = $lastposted; $mid = $starttime; $poster = $threadstart; }
		push(@mergedata,"$lposttime|$mid|$sub|$poster|$pdate|$replies|$poll|$lock|$micon|$luserwhoposted");
	}
	truncate(FILE,0);
	seek(FILE,0,0);
	foreach(sort{$b <=> $a} @mergedata) {
		($lposttime,$mid,$sub,$poster,$pdate,$replies,$poll,$lock,$micon,$luserwhoposted) = split(/\|/,$_);
		$totalreplys += $replies;
		print FILE "$mid|$sub|$poster|$pdate|$replies|$poll|$lock|$micon|$lposttime|$luserwhoposted\n";
		++$mtotal;
	}
	fclose(FILE);
	$totalreplys += $mtotal;

	fopen(FILE,"+>$boards/$URL{'b'}.ino");
	print FILE "$mtotal\n$totalreplys\n";
	fclose(FILE);

	MLogging($starttime,5,$username,time,$tsub,$URL{'b'});

	redirect("$surl\lm-$starttime/");
}

sub ModLog {
	is_admin(-1);

	$title = $moderate[73];
	header();

	$FORM{'searchby'} = $URL{'s'} if(!$FORM{'searchby'});
	$FORM{'value'} =~ s/\+/ /gsi;	
	$FORM{'value'} = $URL{'value'} if(!$FORM{'value'});

	$ebout .= <<"EOT";
<table cellpadding="5" cellspacing="1" class="border" width="100%">
 <tr>
  <td class="titlebg" colspan="6"><strong>$title</strong></td>
 </tr>
   <tr>
    <td class="catbg" style="width: 120px"><strong>$moderate[74]</strong></td>
    <td class="catbg center" style="width: 175px"><strong>$moderate[75]</strong></td>
    <td class="catbg" style="width: 150px"><strong>$moderate[87]</strong></td>
    <td class="catbg" style="width: 170px"><strong>$moderate[86]</strong></td>
    <td class="catbg" style="width: 175px"><strong>$moderate[76]</strong></td>
    <td class="catbg center" style="width: 100px"><strong>$gtxt{'18'}</strong></td>
   </tr>
EOT
	fopen(FILE,"$prefs/Moderator.log");
	@modlog = <FILE>;
	fclose(FILE);
	chomp @modlog;

	$nolog = 1;

	$counter = $counter2 = 0;
	$npp = 25;
	foreach(reverse @modlog) {
		($id,$usr,$tm,$ext,$ipaddy,$mid,$board,$huh) = split(/\|/,$_);

		if(!$sbuser{$usr}) { push(@usrlog,$usr); $sbuser{$usr} = 1; }
			else { ++$sbuser{$usr}; }

		if(!$sbtask{$id}) { push(@tasklogs,$id); $sbtask{$id} = 1; }
			else { ++$sbtask{$id}; }

		($tb,$ttitle) = split(/\|/,$thread{$mid});

		if($URL{'u'} ne '' && $usr ne $URL{'u'}) { next; }
		elsif($URL{'m'} ne '' && $mid ne $URL{'m'}) { next; }
		elsif($URL{'t'} ne '' && $id ne $URL{'t'}) { next; }
		elsif($FORM{'searchby'} == 1 && $mid ne $FORM{'value'}) { next; }
		elsif($FORM{'searchby'} == 2 && $ttitle !~ /\Q$FORM{'value'}\E/sig && $huh !~ /\Q$FORM{'value'}\E/sig) { next; }
		elsif($FORM{'searchby'} == 3 && $board ne $FORM{'value'}) { next; }
		elsif($FORM{'searchby'} == 4 && $ipaddy !~ /\Q$FORM{'value'}/i) { next; }

		++$totallinks;
		if(($totallinks > $URL{'l'} && $counter2 < $npp)) { ++$counter2; } else { next; }

		$nolog = 0;

		if($id == 1) {
			if($boards{$ext} eq '') { $boards = $gtxt{1}; }
				else { $boards = qq~<a href="$surl\lb-$ext/">$boards{$ext}</a>~; }
			$function = "$moderate[77]: $boards";
		}
		elsif($id == 2) { $function = $ext ? $moderate[78] : $moderate[79]; }
		elsif($id == 3) { $function = $ext ? $moderate[80] : $moderate[81]; }
		elsif($id == 4) { $function = "$moderate[82] $ext"; }
		elsif($id == 5) { $function = "$moderate[83] $ext"; }
		elsif($id == 6) { $function = "$moderate[99]: $ext"; }
		elsif($id == 7) { $function = "$moderate[100]: $ext"; }
		elsif($id == 8) {
			($number,$pus) = split(/\//,$ext);
			GetMemberID($pus);
			$pus = $memberid{$pus}{'sn'} ? $userurl{$pus} : $pus;
			$function = "$gtxt{'37'} $number, $moderate[101] $pus $moderate[102]";
		} elsif($id == 9) { $function = $moderate[105]; }
			else { $function = ''; }

		$datetime = get_date($tm);
		GetMemberID($usr);
		$usr = $memberid{$usr}{'sn'} ? $userurl{$usr} : $usr;

		if($tb) { $dew = qq~<a href="$surl\lm-$mid/b-$tb/">$ttitle</a>~; }
		elsif($huh) { $dew = $huh; } else { $dew = ''; }

		if($id == 9 && $board ne '') { $board = $deletelocation[$board-1]; }
		elsif($boards{$board} eq '') { $board = $gtxt{1}; }
			else { $board = qq~<a href="$surl\lb-$board/">$boards{$board}</a>~; }

		$ebout .= <<"EOT";
<tr>
 <td class="win smalltext">$usr</td>
 <td class="center win2 smalltext">$datetime</td>
 <td class="win smalltext">$board</td>
 <td class="win2 smalltext">$dew<br />ID: $mid</td>
 <td class="win smalltext">$function</td>
 <td class="win2 smalltext center">$ipaddy</td>
</tr>
EOT
	}
	if($nolog) { $ebout .= qq~<tr><td colspan="6" class="win center"><br /><strong>$moderate[84]</strong><br /><br /></td></tr>~; }
		else {
			$counter = 1;
			$start = $URL{'l'};
			$mresults = $totallinks || 1;
			if($mresults < $npp) { $start = 0; }
			$tstart = $start || 0;

			# How many page links?
			$smax = $totalpp*20;
			$startdot = ($totalpp*2)/5;

			# Create the main link ...
			$FORM{'value'} =~ s/ /\+/gsi;
			$link = "$surl\lv-mod/a-modlog/m-$URL{'m'}/u-$URL{'u'}/t-$URL{'t'}/s-$FORM{'searchby'}/value-$FORM{'value'}/l";

			if($tstart > $mresults) { $tstart = $mresults; }
			$tstart = (int($tstart/$npp)*$npp);
			if($tstart > 0) { $bk = ($tstart-$npp); $pagelinks = qq~<a href="$link-$bk/">&#171;</a> ~; }
			if($mresults > ($smax/2) && $tstart > $npp*($startdot+1) && $mresults > $smax) {
				$sbk = $tstart-$smax; $sbk = 0 if($sbk < 0); $pagelinks .= qq~<a href="$link-$sbk/">...</a> ~;
			}
			for($i = 0; $i < $mresults; $i += $npp) {
				if($i < $bk-($npp*$startdot) && $mresults > $smax) { ++$counter; $final = $counter-1; next; }
				if($start ne 'all' && $i == $tstart || $mresults < $npp) { $pagelinks .= qq~<strong>$counter</strong>, ~; $nxt = ($tstart+$npp); }
					else { $pagelinks .= qq~<a href="$link-$i/">$counter</a>, ~; }
				++$counter;
				if($counter > $totalpp+$final && $mresults > $smax) { $gbk = $tstart+$smax; if($gbk > $mresults) { $gbk = (int($mresults/$npp)*$npp); } $pagelinks =~ s/, \Z//gsi; $pagelinks .= qq~ <a href="$link-$gbk/">...</a> ~; ++$i; last; }
			}
			if($counter > 2) { $pgs = 's'; }
			$pagelinks =~ s/, \Z//gsi;
			if(($tstart+$npp) != $i && $start ne 'all') { $pagelinks .= qq~ <a href="$link-$nxt/">&#187;</a>~; }

			$onpage = ($tstart+1).' - '.($tstart+$npp);

			$mresults = 0 if($search[0] eq '');

			$ebout .= <<"EOT";
<tr>
 <td colspan="6" class="catbg smalltext"><strong>$gtxt{'17'}:</strong> $pagelinks</td>
</tr>
EOT
		}
	$ebout .= <<"EOT";
</table><br />
<table cellpadding="5" cellspacing="1" class="border" width="100%">
 <tr>
  <td class="titlebg"><strong>$moderate[88]</strong></td>
 </tr><tr>
  <td class="win">
   <table cellpadding="2" cellspacing="0" width="100%">
    <tr>
     <td style="width: 50%" class="vtop">
      <table width="100%" cellpadding="5" cellspacing="1" class="border">
       <tr>
        <td class="catbg"><strong>$moderate[89]</strong></td>
       </tr><tr>
        <td class="win2 smalltext"><div class="win" style="padding: 5px;"><div style="float: left"><strong>$moderate[90]</strong></div><div style="float: right"><strong>$moderate[91]</strong></div><br /></div>
        <div style="overflow: auto; width: 100%; height: 200px; margin: 0px;">
         <table cellpadding="5" cellspacing="0" width="100%">
EOT
	foreach(@usrlog) { push(@usrlog2,"$sbuser{$_}|$_"); }
	foreach(sort {$b <=> $a} @usrlog2) {
		($t,$_) = split(/\|/,$_);
		GetMemberID($_);

		$coloruser = $permissions{$membergrp{$_},'color'} ? qq~<span style="color: $permissions{$membergrp{$_},'color'}"><strong>$memberid{$_}{'sn'}</strong></span>~ : $memberid{$_}{'sn'};

		$usr = $memberid{$_}{'sn'} ? $coloruser : $_;
		$ebout .= qq~<tr><td><a href="$surl\lv-mod/a-modlog/u-$_/">$usr</a></td><td class="right">$sbuser{$_}&nbsp; &nbsp; &nbsp;</td></tr>~;
	}
	$ebout .= <<"EOT";
         </table>
        </div>
        </td>
       </tr>
      </table>
     </td><td></td>
     <td style="width: 50%" class="vtop">
      <table width="100%" cellpadding="5" cellspacing="1" class="border">
       <tr>
        <td class="catbg"><strong>$moderate[92]</strong></td>
       </tr><tr>
        <td class="win2 smalltext"><div class="win" style="padding: 5px;"><div style="float: left"><strong>$moderate[76]</strong></div><div style="float: right"><strong>$moderate[91]</strong></div><br /></div>
EOT

	foreach(@tasklogs) { push(@tasklogs2,"$sbtask{$_}|$_"); }

	foreach(sort {$b <=> $a} @tasklogs2) {
		($t,$_) = split(/\|/,$_);
		$ebout .= qq~<div style="padding: 5px;"><div style="float: left"><a href="$surl\lv-mod/a-modlog/t-$_/">$tasklog[$_-1]</a></div><div style="float: right">$sbtask{$_}</div><br /></div>~;
	}
	$SEL{$FORM{'searchby'}} = ' selected="selected"';

	$ebout .= <<"EOT";
        </td>
       </tr>
      </table>
     </td>
    </tr><tr>
     <td colspan="3">
      <form action="$surl\lv-mod/a-modlog/" method="post">
      <table width="100%" cellpadding="5" cellspacing="1" class="border">
       <tr><td class="win2 smalltext"><strong>$moderate[93] &nbsp; <select name="searchby" style="vertical-align: middle"><option value="1"$SEL{1}>$moderate[94]</option><option value="2"$SEL{2}>$moderate[95]</option><option value="3"$SEL{3}>$moderate[96]</option><option value="4"$SEL{4}>$moderate[97]</option></select> : &nbsp; </strong><input type="text" name="value" value="$FORM{'value'}" style="vertical-align: middle" /> &nbsp; <input type="submit" value="$moderate[98]" style="vertical-align: middle" /></td></tr>
      </table>
      </form>
     </td>
    </tr>
   </table>
  </td>
 </tr>
</table>
EOT

	footer();
	exit;
}

sub MLogging {
	my($mymid,$myid,$myusr,$mytm,$ext,$boardid,$previous) = @_;

	fopen(FILE,">>$prefs/Moderator.log");
	print FILE "$myid|$myusr|$mytm|$ext|$ENV{'REMOTE_ADDR'}|$mymid|$boardid|$previous\n";
	fclose(FILE);
}

sub KillGroups { # ALWAYS use this routine to remove users: || Input: user1,user2,user3 (not array!)
	error($moderate[103]) if($disabledel && !$members{'Administrator',$username});

	# Remove users one by one -- put into hash what we want to delete for easier remembering
	fopen(OLDMEMBERS,">>$members/OldMembers.txt");
	foreach(split(',',$_[0])) {
		$killgroup{$_} = 1;

		GetMemberID($_);
		if($memberid{$_}{'avatarupload'}) {
			$memberid{$_}{'avatar'} =~ s/$uploadurl\///gsi;
			unlink("$uploaddir/$memberid{$_}{'avatar'}");
		}
		unlink("$members/$_.dat","$members/$_.vlog","$members/$_.lo","$members/$_.log","$members/$_.pm","$members/$_.prefs","$members/$_.msg");

		if($memberid{$_}{'sn'} ne '') {
			print OLDMEMBERS "$_|$memberid{$_}{'sn'}\n";
			MLogging($_,9,$username,time,'',$_[1],$memberid{$_}{'sn'});
		}
	}
	fclose(OLDMEMBERS);

	# Remove user from groups ...
	foreach $write (@globalgroups) {
		if($write =~ /(.+?) => {/) { $open = $1; }
		elsif($write =~ /}/ && $open ne '') { $open = ''; }
		elsif($write =~ /(.+?) = \((.*?)\)/) {
			$type  = $1;
			$value = $2;
			$newwrite = '';
			foreach(split(',',$value)) {
				if($killgroup{$_}) { next; }
				$newwrite .= "$_,";
			}
			$newwrite =~ s/,\Z//s;
			$write = "$type = ($newwrite)";
		}
		$printnew .= "$write\n";
	}

	fopen(FILE,">$prefs/Ranks2.txt");
	print FILE $printnew;
	fclose(FILE);

	# Delete users events ...
	fopen(FILE,"$prefs/Events2.txt");
	while(<FILE>) {
		chomp;
		($olduser,$grps) = split(/\|/,$_);
		if($killgroup{$olduser} && $grps eq '') { next; }
			else { push(@events,$_); }
	}
	fclose(FILE);

	fopen(FILE,">$prefs/Events2.txt");
	foreach(@events) { print FILE "$_\n"; }
	fclose(FILE);

	# Remove them from the lists and be done with it ...
	$list = '';
	fopen(LIST,"+<$members/List.txt");
	while($name = <LIST>) {
		chomp $name;
		if($killgroup{$name}) { next; }
			else { $list .= "$name\n"; }
	}
	seek(LIST,0,0);
	truncate(LIST,0);
	print LIST $list;
	fclose(LIST);

	$list = '';
	$counter = 0;
	fopen(LIST,"+<$members/List2.txt");
	while($name = <LIST>) {
		chomp $name;
		($id,$t,$t,$regdate) = split(/\|/,$name);
		if($killgroup{$id}) { next; }
			else {
				$list .= "$name\n";
				if($regdate > $lastrdate) { $lastrdate = $regdate; $lastruser = $id; }
				++$counter;
			}
	}
	seek(LIST,0,0);
	truncate(LIST,0);
	print LIST $list;
	fclose(LIST);

	fopen(LAST,">$members/LastMem.txt");
	print LAST "$lastruser\n$counter";
	fclose(LAST);
}
1;