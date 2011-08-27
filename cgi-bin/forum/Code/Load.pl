#############################################
# E-Blah Bulletin Board Systems        2008 #
#############################################
# Copyright (c) 2001 - 2008 E-Blah.         #
#############################################
# Part of the E-Blah Core                   #
#############################################

require("$language/Load.lng");

# Quick errors for restricted areas
sub is_admin  {
	my($lvl);
	my($level) = @_;

	error("$ltxt[1]-admin-",1) if(!$members{'Administrator',$username} && !@myacl);

	if(!@acls) {
		fopen(RANKS,"$prefs/ACL.txt");
		@acls = <RANKS>;
		fclose(RANKS);
		chomp @acls;

		foreach(@myacl) { $myacl{$_} = 1; }

		foreach(@acls) {
			if($_ =~ /(.+?) => {/) {
				$curread = $1;
				push(@totalacl,$curread);
			}
			elsif($_ eq '}') { $curread = ''; }

			if($_ =~ /(.+?) = '(.+?)'/) {
				if($myacl{$curread}) {
					if($1 eq 'level') {
						foreach $lvl (split(',',$2)) { $acl{$lvl} = 1; push(@myacls,$lvl); }
					}
				}
				$aclvalues{$curread}{$1} = $2;
			}
		}
	}

	error("$ltxt[1]-admin-",1) if($level && !$acl{$level} && !$members{'Administrator',$username});

	if($sessionEnabled) {
		CoreLoad('AdminList');
		VerifyAdmin();
	}
}
sub is_mod    {
	error($ltxt[2]) if(!$members{'Administrator',$username} && !$ismod);
	if($sessionEnabled) {
		CoreLoad('AdminList');
		VerifyAdmin();
	}
}
sub is_member {
	if($username eq 'Guest') { error($gtxt{'noguest'}.'-register-'); } # Moved to is_member() for uniformity
	if(!$memberid{$username}{'status'}) { return(); }
	elsif($memberid{$username}{'status'} eq 'ADMIN') { error("$ltxt[24] $ltxt[26]"); }
	elsif($memberid{$username}{'status'} eq 'EMAIL') { error("$ltxt[24] $ltxt[25]"); }
	elsif($memberid{$username}{'status'} eq 'EMAIL|ADMIN') { error("$ltxt[24] $ltxt[27]"); }
		else { error($ltxt[23]); }
}

sub is_secure {
	my($securepage,$callervalue) = @_;

	return() if(!$members{'Administrator',$username}); # Security is only for administrators

	if($securepage eq 'profile' || $securepage eq 'profile_kick') {
		if($callervalue eq '') { $callervalue = $FORM{'caller'}; }
		if(($URL{'u'} eq $username || $members{'Administrator',$URL{'u'}}) && ($callervalue == 1 || $callervalue == 2 || $callervalue == 9)) {}
		elsif($callervalue == 9) {}
			else { return(); }
	}

	if($URL{'verify'} ne $memberid{$username}{'verifyquick'} || $memberid{$username}{'verifyage'}+3600 < time) {
		# Save pages should throw errors ...
		error($ltxt[44]) if($securepage eq 'profile_kick');
		
		$revalidate = 1;
		CoreLoad('AdminList');
		VerifyAdmin();
	}

	if($URL{'verify'}) { $verifyurl = "verify-$URL{'verify'}/"; }
}

sub BoardCheck {
	my($bfnd,$nump,$t);

	fopen(CATS,"$boards/bdscats.db");
	@catbase = <CATS>;
	fclose(CATS);
	chomp @catbase;

	fopen(BOARDS,"$boards/bdindex.db");
	@boardbase = <BOARDS>;
	fclose(BOARDS);
	chomp @boardbase;

	if($URL{'b'} eq '' && $URL{'m'} ne 'latest' && ($URL{'v'} eq '' || $URL{'v'} eq 'print') && $URL{'m'} ne '') {
		$URL{'b'} = GetMessageDatabase($URL{'m'});

		$scripturl = "$scriptname$modrewrite\lb-$URL{'b'}$usert";
		$activeusers = '';
	}

	return() if($URL{'b'} eq '');

	foreach(@boardbase) {
		($boardid,$binfo[0],$binfo[1],$binfo[2],$binfo[3],$binfo[4],$binfo[5],$binfo[6],$binfo[7],$binfo[8],$binfo[9],$binfo[10],$binfo[11],$binfo[12],$binfo[13],$binfo[14],$binfo[15]) = split("/",$_);
		if($boardid eq $URL{'b'}) { $bfnd = 1; last; }
	}

	error($ltxt[5],0,1) if !$bfnd;

	if($binfo[12] ne '') { # This board redirects, increase hits and exit
		fopen(ADD,"+<$boards/$URL{'b'}.hits");
		$nump = <ADD> || 0;
		seek(ADD,0,0);
		truncate(ADD,0);
		print ADD $nump+1,"\n";
		fclose(ADD);

		$binfo[12] =~ s/&#47;/\//g;
		redirect($binfo[12]);
	}

	# Lets start applying board permissions ...
	@mods = split(/\|/,$binfo[1]);
	foreach (@mods) {
		if($_ =~ /\((.+?)\)/ && $members{$1,$username}) { $ismod = 1; } # Member Group Mods
		if($username eq $_) { $ismod = 1; last; }
	}

	foreach (@catbase) {
		($nme,$id,$grps,$input) = split(/\|/,$_);
		if($input ne '') { @cats = split("/",$input); } else { next; }
		foreach (@cats) {
			if($_ eq $URL{'b'}) { $catid = $id; $catname = $nme; $fewlgrp = $grps; $memgrp = $grps; last; }
		}
	}

	push(@mgaccess,(split(',',$binfo[9]),split(',',$memgrp)));
	if(!GetMemberAccess($memgrp) || !GetMemberAccess($binfo[9])) { error($ltxt[5]); }

	if($binfo[6] ne '') { CoreLoad('BoardLock'); Password(); }
	if($binfo[10]) { $allowrate = 1; }

	$boardnm = $binfo[2];
}

sub GetMessageDatabase {
	my($findmessage,$newboard,$savedb) = @_;
	my($t,$boardid,$id,$returnid,$foundid,@newlist);

	if($savedb eq '') {
		fopen(MESSDB,"$boards/Messages.db");
		while($t = <MESSDB>) {
			chomp $t;
			($id,$boardid) = split(/\|/,$t);
			if($id == $findmessage) { $returnid = $boardid; last; }
		}
		fclose(MESSDB);
		return($returnid);
	} else {
		fopen(MESSDB,"+<$boards/Messages.db",1);
		while($t = <MESSDB>) {
			chomp $t;
			($id,$boardid) = split(/\|/,$t);
			if($id eq $findmessage && $savedb != 2) { push(@newlist,"$id|$newboard"); $foundid = 1; next; } # Change board
			elsif($id eq $findmessage && $savedb == 2) { $foundid = 1; next; } # Delete
			push(@newlist,$t);
		}
		truncate(MESSDB,0);
		seek(MESSDB,0,0);
		if(!$foundid) { print MESSDB "$findmessage|$newboard\n"; } # New message
		foreach $t (@newlist) { print MESSDB "$t\n"; }
		fclose(MESSDB);
	}
}

sub Mods {
	my($colors);
	$modz = '';
	foreach(@mods) {
		if($_ =~ /\((.+?)\)/ && $permissions{$1,'name'} ne '') {
			if($permissions{$1,'color'} ne '') { $colors = qq~ class="usercolors" style="color: $permissions{$1,'color'}"~; }
			$modz .= qq~<a href="$surl\lv-members/a-groups/group-$1/"$colors>$permissions{$1,'name'}</a>, ~;
		}
			else {
				GetMemberID($_);
				if($memberid{$_}{'sn'} eq '') { next; }
				$modz .= "$userurl{$_}, ";
			}
	}
	if($modz eq '') { return(); }
	$modz =~ s/, \Z//gi;
}

sub StarCreator {
	my($starr);
	my($input) = @_;
	if($permissions{$input,'starcount'} < 1 || $permissions{$input,'starcount'} > 51) { $permissions{$input,'starcount'} = 1; }
	if($permissions{$input,'star'} eq '') { return(); }
	for($g = 0; $g < $permissions{$input,'starcount'}; $g++) { $starr .= qq~<img src="$images/$permissions{$input,'star'}" alt="" />~; }
	return($starr);
}

sub UserMiniProfile { # Name, Mini-profile, Guest (t/f)
	my($user,$quickprofile) = @_;
	my($membername,$profile,$width,$height,$pic,$gen,$color);

	# Get the list of profile options (change order to change order of occurance)
	@profilelist = ('posts','gender','ppd','reputation','score','timeon','location','age');

	GetMemberID($user);
	if($memberid{$user}{'sn'} eq '') {
		$tempuser = FindOldMemberName($user);
		$tempprof = qq~<div style="padding: 10px" class="center">$gtxt{'0'}</div>~;
		return(1);
	}
	
	$lastactive{$user} = get_date($memberid{$user}{'lastactive'});

	# Get the group apart of, and stars ...
	$permissions{$membergrp{$user},'level'} = $permissions{$membergrp{$user},'level'} <= 0 ? ($permissions{'Moderators','level'}+1) : $permissions{$membergrp{$user},'level'};
	foreach(@mods) {
		if($permissions{'Moderators','level'} && $user eq $_ && $permissions{$membergrp{$user},'level'} >= $permissions{'Moderators','level'}) {
			$membergrp{$user} = 'Moderators';
			last;
		}
	}

	if($membergrp{$user} ne '') {
		$stat{$user} = $permissions{$membergrp{$user},'name'};
		$stat{$user} = CensorList($memberid{$user}{'personaltxt'}) if($permissions{$membergrp{$user},'coverup'} ne '' && $memberid{$user}{'personaltxt'});

		$stat{$user} = "<strong>$stat{$user}</strong>" if($permissions{$membergrp{$user},'team'});
		$stat{$user} = CensorList($memberid{$user}{'personaltxt'}).'<br />'.$stat{$user} if($memberid{$user}{'personaltxt'} ne '' && !$permissions{$membergrp{$user},'coverup'});

		$star{$user} = StarCreator($membergrp{$user}) if($permissions{$membergrp{$user},'star'});
	}
	
	# Avatar
	if(!$memberid{$username}{'ownavatar'} && $memberid{$user}{'avatar'} ne '' && $apic) {
		if($memberid{$user}{'avatarsize'}) { ($height,$width) = split(/\|/,$memberid{$user}{'avatarsize'}); }
			else { $width = $picwidth; $height = $picheight; }
		if($memberid{$user}{'avatar'} =~ /http:/) { $avatar{$user} = qq~<img src="$memberid{$user}{'avatar'}" width="$width" height="$height" alt="" /><br />~; }
			elsif($memberid{$user}{'avatarupload'}) {
				$memberid{$user}{'avatar'} =~ s/\A$uploadurl//;
				$avatar{$user} = qq~<img src="$uploadurl/$memberid{$user}{'avatar'}" width="$width" height="$height" alt="" /><br />~;
			}
			else { $avatar{$user} = qq~<img src="$avsurl/$memberid{$user}{'avatar'}" alt="" /><br />~; }
	}

	# E-mail address
	$email{$user} = $memberid{$user}{'hidemail'} && $hmail && !$members{'Administrator',$username} ? '' : qq~<a href="mailto:$memberid{$user}{'email'}">$Pimg{'email'}</a>$Pmsp2~;

	# Post count
	if(!$hideposts) { $posts{$user} = MakeComma($memberid{$user}{'posts'}); }

	# Instant Messanging
	if($memberid{$user}{'aim'} ne '')   { $aim{$user} = qq~$Pmsp2<a href="aim:goim?screenname=$memberid{$user}{'aim'}&amp;message=You+there?" title="$ltxt[10] ($memberid{$user}{'aim'})">$Pimg{'aim'}</a>~; }
	if($memberid{$user}{'msn'} ne '')   { $msn{$user} = qq~$Pmsp2<a href="http://members.msn.com/$memberid{$user}{'msn'}" onclick="target='msn';" title="$memberid{$user}{'msn'}">$Pimg{'msn'}</a>~; }
	if($memberid{$user}{'icq'} ne '')   { $icq{$user} = qq~$Pmsp2<a href="http://www.icq.com/whitepages/wwp.php?to=$memberid{$user}{'icq'}"$blanktarget title="$memberid{$user}{'icq'}">$Pimg{'icq'}</a>~; }
	if($memberid{$user}{'yim'} ne '')   { $yim{$user} = qq~$Pmsp2<a href="http://profiles.yahoo.com/$memberid{$user}{'yim'}" onclick="target='yim';" title="$memberid{$user}{'yim'}">$Pimg{'yim'}</a>~; }
	if($memberid{$user}{'skype'} ne '') { $skype{$user} = qq~$Pmsp2<a href="skype:$memberid{$user}{'skype'}" onclick="target='skype';" title="$memberid{$user}{'skype'}">$Pimg{'skype'}</a>~; }

	# Signature
	if(!$memberid{$username}{'showsig'} && $maxsig > 0 && $memberid{$user}{'sig'}) {
		$signature{$user} = qq~<tr><td><br /><br /></td></tr><tr><td class="postbody" style="vertical-align: bottom"><div class="messageseps smalltext">~.BC($memberid{$user}{'sig'})."</div></td></tr>";
	}

	# Gender
	if($showgender) {
		if($memberid{$user}{'sex'} == 1) { $pic = 'male'; $gen = $ltxt[11]; }
		elsif($memberid{$user}{'sex'} == 2) { $pic = 'female'; $gen = $ltxt[12]; }

		$gender{$user} = qq~<img src="$images/$pic.png" class="centerimg" alt="" /> $gen~ if($pic && $gen);
	}

	# Posts Per Day
	if($sppd) {
		($t,$t,$t,$lday,$lmonth,$lyear,$lweek) = localtime($memberid{$user}{'registered'});
		($t,$t,$t,$cday,$cmonth,$cyear,$cweek) = localtime(time);
		$lyear = substr($lyear,-2);
		$cyear = substr($cyear,-2);
		++$lmonth; ++$cmonth;
		$reg = (365*$lyear)+(30.42*$lmonth)+$lday;
		$now = (365*$cyear)+(30.42*$cmonth)+$cday;
		$days = ($now-$reg) || 1;
		$ppd{$user} = sprintf("%.2f", $memberid{$user}{'posts'}/$days);
	}

	# Reputation
	if($enablerep) {
		if($memberid{$user}{'rep'} ne '') {
			if($memberid{$user}{'rep'} < 50) { $color = 'redrep'; } # Horrible
			elsif($memberid{$user}{'rep'} > 75) { $color = 'greenrep'; } # Best
				else { $color = 'grayrep'; } # Neut

			$reputation{$user} = qq~<span class="$color">$memberid{$user}{'rep'}%</span>~ if(!$repscore || $repscore == 1);
			$memberid{$user}{'prep'} = 0 if(!$memberid{$user}{'prep'});
			$memberid{$user}{'nrep'} = 0 if(!$memberid{$user}{'nrep'});
			if($repscore && ($memberid{$user}{'prep'} || $memberid{$user}{'nrep'}) && $user ne $username && $username ne 'Guest') {
				$score{$user} = qq~<a href="$surl\lv-memberpanel/a-view/u-$user/r-1/" class="greenrep">+$memberid{$user}{'prep'}</a> / <a href="$surl\lv-memberpanel/a-view/u-$user/r-0/" class="redrep">-$memberid{$user}{'nrep'}</a>~;
			} elsif($repscore && ($memberid{$user}{'prep'} || $memberid{$user}{'nrep'})) {
				$score{$user} = qq~<span class="greenrep">+$memberid{$user}{'prep'}</span> / <span class="redrep">-$memberid{$user}{'nrep'}</span>~ if($repscore && ($memberid{$user}{'prep'} || $memberid{$user}{'nrep'}));
			}
		}
	}

	# User logged in time
	($t1,$t2) = split(/\|/,$memberid{$user}{'rndsid'});
	if($showloggedon && ($t1 > 60)) {
		$days  = int($t1/86400);
		$hours = int($t1/3600)-($days*24);
		$mins  = int($t1/60)-(($hours+($days*24))*60);

		$days  = $days  ? " $days $ltxt[43]"   : '';
		$hours = $hours ? " $hours $gtxt{'3'}" : '';
		$mins  = $mins  ? " $mins $gtxt{'2'}"  : '';

		$timeon{$user} = qq~$days$hours$mins~;
	}

	if($showage && $memberid{$user}{'dob'} ne '') { $age{$user} = calage($memberid{$user}{'dob'}); }

	# Admin Text
	$admintext{$user} = $memberid{$user}{'admintxt'}.'<br />' if $memberid{$user}{'admintxt'} ne '';

	# Location
	$location{$user} = $showlocation && $memberid{$user}{'location'} ne '' ? $memberid{$user}{'location'} : '';

	$instmsg{$user} = "$icq{$user}$aim{$user}$yim{$user}$msn{$user}$skype{$user}";
	
	$profile{$user} = <<"EOT";
<div class="avatarprofile">$avatar{$user}$stat{$user}<br />$admintext{$user}$star{$user}</div>
EOT

	if($quickprofile ne 'quick') {
		foreach(@profilelist) {
			if(${$_}{$user} eq '') { next; }
			if($fancyqprofile) {
				$profile{$user} .= <<"EOT";
<div class="win fancyprofilet"><strong>$miniprofile{$_}</strong></div>
<div class="win2 fancyprofilev">${$_}{$user}</div>
EOT
			} else {
				$profile{$user} .= <<"EOT";
<div class="plainprofile"><strong>$miniprofile{$_}:</strong> ${$_}{$user}</div>
EOT
			}
		}
	}

	return(0); # 0 = not guest
}

sub LogPage {
	if($username eq 'Guest') { return(); }
	my($lid,$ltime,$found,$lltime,$tempwrite,%found);

	$lltime = (time+2); # +2 prevents "Your New Post == New".

	fopen(ULOG,"$members/$username.log");
	while($log = <ULOG>) {
		chomp $log;
		($lid,$ltime) = split(/\|/,$log);
		if($found{$lid}) { next; }
		$logged{$lid} = $ltime; $found{$lid} = 1;
		$tempwrite .= "$log\n" if($lid ne $URL{'m'} && $lid ne $URL{'b'} && $ltime+($logdays*86400) > time);
	}
	fclose(ULOG);

	fopen(ULOG,"+>$members/$username.log");
	print ULOG "$URL{'m'}|$lltime\n" if($URL{'m'} ne '');
	if($_[0]) { $lltime = 0; }
	print ULOG "$URL{'b'}|$lltime\n$tempwrite";
	fclose(ULOG);
}

sub LMGS {
	if($members{'Administrator',$username}) { return(); }
	foreach(@fullgroups) {
		if($members{$_,$username}) {
			$ipon     = $permissions{$_,'ip'} || $ipon;
			$modon    = $permissions{$_,'moderate'} || $modon;
			$ston     = $permissions{$_,'sticky'} || $ston;
			$modifyon = $permissions{$_,'modify'} || $modifyon;
			$proon    = $permissions{$_,'profile'} || $proon;
			$calmod   = $permissions{$_,'cal'} || $calmod;
		}
	}
}

sub Ban {
	fopen(BANL,"$prefs/BanList.txt");
	while(<BANL>) {
		chomp $_;
		($banstring,$banlimit,$bantime) = split(/\|/,$_);
		$length = length($banstring);
		$ipsearch = substr($ENV{'REMOTE_ADDR'},0,$length);
		if($ipsearch =~ /\Q$banstring/i || $username eq $banstring || $banstring eq $memberid{$username}{'email'}) { CoreLoad('BoardLock'); Banned($banlimit,$bantime); }
	}
	fclose(BANL);
}

sub FindRanks {
	my(@rdata);
	($frank) = $_[0];
	fopen(RANKS,"$members/List.txt");
	@list = <RANKS>;
	fclose(RANKS);
	chomp @list;
	foreach(@list) {
		if($members{$frank,$_}) { push(@rdata,$_); }
	}
	return(@rdata);
}

sub Format {
	($temp) = $_[0];
	$temp =~ s/&/\&amp;/g;
	$temp =~ s/</&lt;/g;
	$temp =~ s/>/&gt;/g;
	$temp =~ s/\cM//g;
	$temp =~ s/\n/<br \/>/g;
	$temp =~ s/\|/\&#124;/g;
	$temp =~ s/"/\&quot;/g;
	$temp =~ s/  /&nbsp;&nbsp;/gi;
	$temp =~ s/\t/&nbsp; &nbsp; &nbsp;/gi;
	return $temp;
}

sub Unformat {
	($temp) = $_[0];
	$temp =~ s/<br \/>/\n/g;
	$temp =~ s/<br>/\n/g;     # Temporary
	$temp =~ s/&lt;/</g;
	$temp =~ s/&gt;/>/g;
	$temp =~ s/&nbsp; &nbsp; &nbsp;/\t/g; # DO THE TABS
	$temp =~ s/&nbsp;&nbsp;/  /gi;
	return $temp;
}

sub BoardProperties {
	$tallow = $repallow = 0;

	if(!($noguestp == 0 && $username eq 'Guest') && GetMemberAccess($binfo[3])) { $tallow = 1; }
	if(!($noguestp == 0 && $username eq 'Guest') && GetMemberAccess($binfo[4])) { $repallow = 1; }
}

sub ListBoards {
	if(!$boardbase[1]) { return(qq~<span class="smalltext">$boardnm ($ltxt[19])</span>~); }

	foreach(@catbase) {
		($t,$boardid,$memgrps,$t,$t,$subcats) = split(/\|/,$_);
		$catbase{$boardid} = $_;
		if(!GetMemberAccess($memgrps)) { next; }
		foreach(split(/\//,$subcats)) { $noshow{$_} = 1; }

		$cats .= "$boardid/";
	}

	foreach(@boardbase) {
		($id,$t,$t,$t,$t,$t,$t,$passed,$t,$t,$boardgood,$t,$t,$redir) = split("/",$_);
		if(!$members{'Administrator',$username} && (!GetMemberAccess($boardgood) || $passed ne '' || $redir ne '')) { next; }
		$board{$id} = $_;
	}

	$temp = <<"EOT";
<script type="text/javascript">
//<![CDATA[
function JumpTo(ghere) {
 if(ghere != '') { location = "$surl\lb-"+ghere+"/"; }
}
//]]>
</script>
<select name="JumpZ" onchange="JumpTo(this.value);">
EOT

	$scat{"$URL{'b'}"} = ' selected="selected"';
	SubCatsList($cats,1);
	return($temp."</select>");
}

sub SubCatsList {
	foreach $catbased (split(/\//,$_[0])) {
		if($arshown{$catbased} || $catbase{$catbased} eq '') { next; }
		if($noshow{$catbased} && $_[1]) { next; }
		$arshown{$catbased} = 1;

		($b,$bid,$t,$input,$t,$subcats) = split(/\|/,$catbase{$catbased});

		$temp .= qq~<optgroup label="$_[2]$b">~;
		if($input ne '') {
			foreach $boardbased (split(/\//,$input)) {
				if($board{$boardbased} eq '') { next; }
				($obds,$t,$t,$info) = split("/",$board{$boardbased});
				$temp .= qq~<option value="$obds"$scat{$obds}>$_[2]$info</option>~;
			}
		}

		$temp .= "</optgroup>";
		if($subcats ne '') { SubCatsList($subcats,0,"$_[2]&nbsp; &nbsp; "); }
	}
}

sub FindStatus {
	my($temp);

	if($type) { $temp = 'thread_locked'; }
	elsif($replies >= $vhtdmax) { $temp = 'veryhotthread'; }
	elsif($replies >= $htdmax) { $temp = 'hotthread'; }
		else { $temp = 'thread'; }
	if($poll && $type) { $temp = 'poll_lock'; }
	elsif($poll) { $temp = 'poll_icon'; }

	if(!$stickme{$messid} && ($binfo[15] > 0 && time > $_[0]+(86400*$binfo[15]))) {
		$type = 1 if(!$members{'Administrator',$username});
		$temp = 'archive_lock';
	}

	return($temp);
}

sub CensorList {
	if($memberid{$username}{'censor'}) { return($_[0]); }

	if(!$CensorLoad) {
		fopen(CENSOR,"$prefs/Censor.txt");
		while($censor = <CENSOR>) {
			chomp $censor;
			@t = split(/\|/,$censor);
			if($t[0] ne '' && $t[1] ne '') {
				$CensorValues .= lc($t[0]).'|';
				$Censor{lc($t[0])} = Unformat($t[1]);
				$Censor{lc($t[0])} =~ s/\&quot;/"/g;
			}
		}
		fclose(CENSOR);
		$CensorValues =~ s/\|\Z//g;
		$CensorLoad = 1;
	}

	$_[0] =~ s/\b($CensorValues)\b/$Censor{lc($1)}/gi;

	return($_[0]);
}

sub MakeSmall { # To make long code look like it's suppose to, do this ...
	if(!$BCLoad) { return; }
	$message =~ s/<(.[^">]*?)\Z//gsi;
	$message =~ s~\[(.[^\]]*?)\Z~~gsi;
	$message =~ s/<a href="(.[^">]*?)\Z//gsi;
	$message =~ s~\[code\](.*?)\Z~&Code~esgi;
	$message =~ s~\[quote by=(.+?) link=(.+?) date=(.+?)\](.+?)\Z~&Quote~gsie;
	$message =~ s~\[quote\](.+?)\Z~&Quote~gsie;
	$message =~ s~\[quote=(.+?)\](.+?)\Z~&Quote~gsie;
	$message =~ s~\[s\](.*?)\Z~<s>$1</s>~gsi;
	$message =~ s~\[b\](.*?)\Z~<strong>$1</strong>~gsi;
	$message =~ s~\[i\](.*?)\Z~<i>$1</i>~gsi;
	$message =~ s~\[u\](.*?)\Z~<u>$1</u>~gsi;
	$message =~ s~\[size=([1-9][^\s\n<>]*?)\](.*?)\Z~<span style="font-size: $1px">$2</span>~gsi;
	$message =~ s~\[pre\](.+?)\Z~<pre>$1</pre>~gsi;
	$message =~ s~\[justify\](.+?)\Z~<div style="text-align: justify">$1</div>~gsi;
	$message =~ s~\[left\](.+?)\Z~<div style="text-align: left">$1</div>~gsi;
	$message =~ s~\[right\](.+?)\Z~<div style="text-align: right">$1</div>~gsi;
	$message =~ s~\[center\](.+?)\Z~<div style="text-align: center">$1</div>~gsi;
	$message =~ s~\[face=(.+?)\](.+?)\Z~<span style="font-family: $1">$2</span>~gsi;
	$message =~ s~\[color=(.+?)\](.+?)\Z~<span style="color: $1">$2</span>~gsi;
	$message =~ s~\[sub\](.+?)\Z~<sub>$1</sub>~gsi;
	$message =~ s~\[sup\](.+?)\Z~<sup>$1</sup>~gsi;
	$message =~ s~\[img(.+?)\Z~~gsi;
	if($message =~ /\[list(.*?)\](.+?)\Z/) {
		$message =~ s~\[list\](.+?)\Z~<ul>$1</ul>~gsi;
		$message =~ s~\[list=([a-zA-Z|1]+?)\](.+?)\Z~<ol type="$1">$2</ol>~gsi;
		$message =~ s~\[\*\]~<li>~gsi;
	}
}

sub GetMemberAccess { # Adapted from the BoardIndex =P
	my($grpaccess,$accessuser) = @_;
	my $boot = 1;
	if($accessuser eq '') { $accessuser = $username; }
	foreach $group (split(',',$grpaccess)) {
		if($members{$group,$accessuser}) { $boot = 0; }
		$boot = 0 if(($group eq 'member' && !$lockuserout && $username ne 'Guest') || ($group eq 'guest' && $accessuser eq 'Guest') || ($group eq 'validating' && $lockuserout && $accessuser ne 'Guest'));
	}
	if($boot) { return(0); }
	return(1);
}

sub CreateGroups { # Member Groups (Version 2.2)
	my(%groupmembers);

	fopen(RANKS,"$prefs/Ranks2.txt");
	@globalgroups = <RANKS>;
	fclose(RANKS);
	chomp @globalgroups;

	foreach(@globalgroups) {
		if($_ =~ /(.+?) => {/) {
			$curread = $1;
			push(@fullgroups,$1);
		}
		elsif($_ eq '}') { $curread = ''; }

		if($curread) { # Get the permissions for this group
			if($_ =~ /(.+?) = '(.+?)'/) {
				$permissions{$curread,$1} = $2;

				if($1 eq 'pcount') { push(@grpsposts,"$2|$curread"); }
			}
			elsif($_ =~ /(.+?) = \((.+?)\)/) {
				if($1 eq 'members') {
					foreach $user (split(',',$2)) {
						$members{$curread,$user} = 1;
						if($permissions{$curread,'level'} > 0 && ($permissions{$curread,'level'} < $permissions{$membergrp{$user},'level'} || $membergrp{$user} eq '')) { $membergrp{$user} = $curread; }
						++$permissions{$curread,'count'};
						if($username eq $user && $permissions{$curread,'acl'} ne '') { push(@myacl,$permissions{$curread,'acl'}); }
					}
				}
				$permissions{$curread,$1} = $2;
			}
		}
	}
	@grpsposts = sort{$a <=> $b} @grpsposts;

	# Check if user has post group permissions ...
	if($username ne 'Guest') {
		foreach(@grpsposts) {
			($num,$memgrp) = split(/\|/,$_);
			if($memberid{$username}{'posts'} >= $num) {
				$members{$memgrp,$username} = 1;
				if(($membergrp{$username} eq '' || $tmaxnum) && $tmaxnum < $num) { $tmaxnum = $num; $membergrp{$username} = $memgrp; }
			}
		}
	}

	LMGS();
}

sub SaveMemberID {
	my($userid) = $_[0];
	my($iddata,$item,$itemvalue,@printuser,$hasdat,$failsafe, $size);

	if($userid eq '') { return(0); }

	%{$memberid{$userid}} = (); # Clear out any old data
	GetMemberID($userid,'force');

	while(($item,$itemvalue) = each(%addtoID)) {
		$changeid{$item} = 1;
		if($itemvalue eq '') { next; }
		push(@printuser,"$item = |$itemvalue|");
		if($item eq 'sn') { $failsafe = 1; }
	}

	$hasdat = $memberid{$userid};
	while(($item,$itemvalue) = each(%$hasdat)) {
		if($changeid{$item}) { next; }
		push(@printuser,"$item = |$itemvalue|");
		if($item eq 'sn') { $failsafe = 1; }
	}

	if($failsafe != 1) { return(); }

	$size = @printuser;
	if($size <= 0) { return(); }

	fopen(SAVEMEMBERID,"+>$members/$userid.dat");
	foreach(@printuser) { print SAVEMEMBERID "$_\n"; }
	fclose(SAVEMEMBERID);

	%addtoID  = (); # Ah, this does need to be cleared ...
	%changeid = (); # Clear this too!
}

sub GetMemberID {
	my($userid,$override) = @_;
	my($iddata,$coloruser);

	if($memberid{$userid}{'password'} ne '' && $override ne 'force') { return(1); } # Check for loading info ...

	if(!-e("$members/$userid.dat")) { return(); }

	fopen(GETMEMBERID,"$members/$userid.dat") || return(0);
	while($iddata = <GETMEMBERID>) {
		chomp $iddata;
		$iddata =~ /^(.+?) = \|(.*?)\|\Z/g;
		if($2 eq '') { next; }
		$memberid{$userid}{$1} = $2;
	}
	fclose(GETMEMBERID);

	if($override ne 'force' && (($hiddenmail == 2 && $username eq 'Guest') || ($hiddenmail == 1))) { $memberid{$userid}{'hidemail'} = 1; }

	if($override ne 'force') { $memberid{$userid}{'sn'} = CensorList($memberid{$userid}{'sn'}); }

	if($membergrp{$userid} eq '') {
		foreach(@grpsposts) {
			($num,$memgrp) = split(/\|/,$_);
			if($memberid{$userid}{'posts'} >= $num) { $membergrp{$userid} = $memgrp; }
		}
	}

	$coloruser = $permissions{$membergrp{$userid},'color'} ? qq~ class="usercolors" style="color: $permissions{$membergrp{$userid},'color'}"~ : '';

	$userurl{$userid} = qq~<a href="$surl\lv-memberpanel/a-view/u-$userid/" rel="nofollow"$coloruser onclick="target='_parent';">$memberid{$userid}{'sn'}</a>~;

	return(1);
}

sub FindUsername {
	my($findusername,$emailsearch) = @_;
	my($tmailsearch);

	UserDatabase();

	foreach(@memlist2) {
		($un,$sn,$t,$t,$t,$tmailsearch) = split(/\|/,$_);
		if($emailsearch ne 'email' && lc($sn) eq lc($findusername)) { GetMemberID($un); return($un); }
		elsif($emailsearch eq 'email' && lc($tmailsearch) eq lc($findusername)) { GetMemberID($un); return($un); }
	}
	return();
}

sub FindOldMemberName { # Tries to returns old member name of deleted users
	my($user) = $_[0];
	my($oldid,$olduser,$temp);

	if($user =~ s/ \(Guest\)\Z//gis) { return(CensorList($user)); }

	if(!$oldlog) {
		fopen(OLDLOG,"$members/OldMembers.txt");
		while($temp = <OLDLOG>) {
			chomp $temp;
			($oldid,$olduser) = split(/\|/,$temp);
			$oldmember{$oldid} = $olduser;
		}
		fclose(OLDLOG);
		$oldlog = 1;
	}

	if($oldmember{$user} ne '') { return(CensorList($oldmember{$user})); }
		else { return(CensorList($user)); }
}
1;