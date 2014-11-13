#############################################
# E-Blah Bulletin Board Systems        2008 #
#############################################
# Copyright (c) 2001 - 2008 E-Blah.         #
#############################################

CoreLoad('Poll',1);

sub PollDisplay {
	fopen(FILE,"$messages/$URL{'m'}.poll");
	@polldata = <FILE>;
	fclose(FILE);
	chomp @polldata;

	fopen(FILE,"$messages/$URL{'m'}.polled");
	@ptemp = <FILE>;
	fclose(FILE);
	$y = @ptemp-1;
	chomp @ptemp;
	$count = 0;
	foreach (@ptemp) {
		($pollers[$count],$date) = split(/\|/,$_);
		++$count;
	}

	if($slpoller && $pollers[$y] ne '') {
		GetMemberID($pollers[$y]);
		if($memberid{$pollers[$y]}{'sn'}) { $lp = $userurl{$pollers[$y]}; }
			else { $lp = $pollers[$y]; }
		if($date) { $lpoller = "$polltxt[1] <strong>".get_date($date)."</strong> $polltxt[2] <strong>$lp</strong>"; }
	}

	foreach (@pollers) {
		$temp = lc $_;
		$tusername = lc $username;
		if($temp eq $tusername) { $pfound = 1; last; }
	}

	foreach(@polldata) {
		($res,$on) = split(/\|/,$_);
		if($res eq 'res') { $reson = $on; }
		if($res eq 'res2') { $multi = $on; }
		if($res eq 'timelimit') { $xtimelimit = $on; }

		if($xtimelimit ne '') { $xtimelimit = ceil((($xtimelimit*86400+$URL{'m'})-time)/86400); }
	}

	$polldata[0] = CensorList($polldata[0]);

	$ebout .= <<"EOT";
<form action="$scripturl/v-ppoll/a-vote/m-$URL{'m'}/s-$tstart/" method="post">
<table width="100%" class="border" cellpadding="6" cellspacing="1">
 <tr>
  <td class="titlebg"><strong><img src="$images/poll_icon.png" class="centerimg" alt="" />&nbsp;$polldata[0]</strong></td>
 </tr><tr>
  <td class="win" style="padding: 0px">
   <table cellpadding="6" cellspacing="0" width="100%">
EOT
	if($pfound) { $show = 1; }
	elsif($xtimelimit ne '' && $xtimelimit < 0) { $show = 1; }
	elsif($reson != 1 && $username eq 'Guest') {
		$ebout .= <<"EOT";
    <tr>
     <td class="win"><strong>$polltxt[4]</strong></td>
    </tr>
   </table>
  </td>
 </tr>
</table>
EOT
		return;
	}
	elsif(($reson && $URL{'vr'}) || ($username eq 'Guest')) { $show = 1; }
		else { $show = 0; }

	if($mlocked || $show) {
		if($URL{'vr'} && $pfound == 0) { $backlink = qq~<a href="javascript:history.go(-1)">$polltxt[5]</a>~; }
		for($i = 1; $i < @polldata; $i++) {
			($do,$value,$tally) = split(/\|/,$polldata[$i]);
			if($do eq 'vc') { $vc = $value; }
			push(@sorteddataa,"$tally|$do|$value");
		}
		@sorteddata = sort {$b <=> $a} @sorteddataa;
		for($i = 0; $i < @sorteddata; $i++) {
			($tally,$do,$value) = split(/\|/,$sorteddata[$i]);

			if($do eq 'op') {
				if($vc >= 1) {
					$pper = ($tally/$vc);
					$pper = sprintf("%.2f",($pper*100));
				} else { $pper = 0; }

				$value = CensorList($value);

				$dapper = $pper >= 99 ? 99 : $pper <= 0 ? 3 : $pper;
				$pper = $pper > 99 ? 100 : $pper <= 0 ? 0 : $pper;

				$polldata = '';
				$ebout .= <<"EOT";
<tr>
 <td style="width: 30%">$value</td>
 <td class="right smalltext">($tally $polltxt[6])</td>
 <td style="width: 60%" class="vtop">
  <table width="$dapper%" cellpadding="2" cellspacing="0" class="pollborder innertable">
   <tr>
    <td style="width: 100%" class="pollcolor right"></td>
    <td class="pollpercents smalltext center" style="width: 1px">$pper%</td>
   </tr>
  </table>
 </td>
</tr>
EOT
				++$cnt;
			}
		}
		$endofit = <<"EOT";
<tr>
 <td class="win2">
  <table cellpadding="5" width="100%">
   <tr>
    <td style="width: 33%" class="smalltext">$backlink</td>
    <td style="width: 33%" class="center smalltext"><strong>$vc $polltxt[7]</strong></td>
    <td style="width: 33%" class="right smalltext">$lpoller</td>
   </tr>
  </table>
 </td>
</tr>
EOT
	} else {
		for($z = 1; $z < @polldata; $z++) {
			chomp $polldata[$z];
			($do,$value) = split(/\|/,$polldata[$z]);
			if($do eq 'vc') { $vc = $value; }
			if($do eq 'op') {
				$value = CensorList($value);

				if(!$multi) { $multisel = qq~<input type="radio" name="voteop" value="$z" />~; }
					else { $multisel = qq~<input type="checkbox" name="val_$z" value="1" />~; }
				$ebout .= <<"EOT";
<tr>
 <td style="width: 5px; padding: 10px;" class="win3">$multisel</td>
 <td>$value</td>
</tr>
EOT
			}
			if($do eq 'res' && $value) { $showres = qq~<a href="$surl\lm-$URL{'m'}/s-$tstart/vr-1/">$polltxt[8]</a>~; }
		}
		$endofit = <<"EOT";
<tr>
 <td class="win2">
  <table cellpadding="0" width="100%">
   <tr>
    <td style="width: 33%" class="smalltext"><input type="submit" value=" $polltxt[15] " name="submit" /> &nbsp; $showres</td>
    <td style="width: 33%" class="center smalltext"><strong>$vc $polltxt[7]</strong></td>
    <td style="width: 33%" class="right smalltext">$lpoller</td>
   </tr>
  </table>
 </td>
</tr>
EOT
	}

	if($pfound || $username eq 'Guest' || $xtimelimit) {
		if($pfound) { $reason = $polltxt[16]; }
		elsif($username eq 'Guest') { $reason = $polltxt[17]; }
			else { $reason = $polltxt[22]; }

		if($xtimelimit ne '') {
			$xtimelimit = $xtimelimit > 1 ? "$polltxt[20]" : "$xtimelimit $polltxt[21]";
			if($xtimelimit > 0) { $saying = "$polltxt[19] <strong>$xtimelimit</strong>."; }
				else { $saying = $polltxt[18]; }

			$reason2 = "$saying";
		}

		$endofit .= <<"EOT";
<tr>
 <td class="win3">
  <table cellpadding="5" width="100%">
   <tr>
    <td style="width: 100%" class="smalltext">
     <div style="float: left">$reason</div>
     <div style="float: right">$reason2</div>
    </td>
   </tr>
  </table>
 </td>
</tr>
EOT
	}
	$ebout .= <<"EOT";
   </table>
  </td>
 </tr>$endofit
EOT
	$ebout .= <<"EOT";
</table>
</form>
<br />
EOT
}

sub PPoll {
	my($xtimelimit);

	if($URL{'e'}) { Rate(); }
	is_member();

	fopen(FILE,"<$messages/$URL{'m'}.polled");
	while (<FILE>) {
		chomp $_;
		($pollname,$trash) = split(/\|/,$_);
		$cur = lc($username);
		$avote = lc($pollname);
		if($avote eq $cur) { error($polltxt[11]); }
	}
	fclose(FILE);

	fopen(FILE,"+<$messages/$URL{'m'}.poll") || error($polltxt[12]);
	@polldata = <FILE>;
	$datacnt = @polldata;
	chomp @polldata;
	foreach(@polldata) {
		($do,$value,$tally) = split(/\|/,$_);
		if($do eq 'res2' && $value) {
			while($overcnt != $pollops+2) {
				if($FORM{"val_$overcnt"}) { $pollhash{$overcnt} = 1; $FORM{'voteop'} = 1; ++$totalvotes; }
				++$overcnt;
				$fndalready = 1;
			}
		}
		if($do eq 'timelimit' && $value ne '') {
			$xtimelimit = ceil((($value*86400+$URL{'m'})-time)/86400);
			if($xtimelimit ne '' && $xtimelimit < 0) {
				fclose(FILE);
				redirect("$surl\lm-$URL{'m'}/s-$URL{'s'}/"); # Time's up!
			}
		}
	}
	if(!$fndalready) { $pollhash{"$FORM{'voteop'}"} = 1; $totalvotes = 1; }

	$voteops = $FORM{'voteop'};

	for($x = 2; $x < $datacnt; $x++) {
		($ac,$av) = split(/\|/,$polldata[$x]);
		if($ac eq 'op') {
			$so = lc $av;
			$so =~ s/ /_/gi;
			$so =~ s/&nbsp;/_/gi;
			if($pollhash{$x}) { $pfnd = 1; }
		}
	}
	if($pfnd != 1) { fclose(FILE); error($polltxt[13]); }

	seek(FILE,0,0);
	truncate(FILE, 0);
	print FILE "$polldata[0]\n";
	for($q = 1; $q < $datacnt; $q++) {
		($do,$value,$tally) = split(/\|/,$polldata[$q]);
		if($do eq 'vc') { $value += $totalvotes; print FILE "vc|$value\n"; }
		elsif($do eq 'op') {
			$savedops = lc $value;
			$savedops =~ s/ /_/gi;
			$savedops =~ s/&nbsp;/_/gi;
			if($pollhash{$q}) { ++$tally; print FILE "op|$value|$tally\n"; }
				else { print FILE "op|$value|$tally\n"; }
		}
		elsif($do eq 'res') { print FILE "res|$value\n"; }
		elsif($do eq 'res2') { print FILE "res2|$value\n"; }
		elsif($do eq 'timelimit') { print FILE "timelimit|$value\n"; }
	}
	fclose(FILE);

	$ttime = time;
	fopen(FILE,"+>>$messages/$URL{'m'}.polled");
	print FILE "$username|$ttime\n";
	fclose(FILE);

	if($polltop) {
		$mtime = time;

		fopen(FILE,"+<$boards/$URL{'b'}.msg") || error("$polltxt[14]: $URL{'b'}.msg",1);
		seek(FILE,0,0);
		@mess = <FILE>;
		chomp @mess;
		fopen(WRITE,"+>$boards/$URL{'b'}.msg.temp");
		seek(WRITE,0,0);
		truncate(FILE,0);
		seek(FILE,0,0);
		foreach(@mess) {
			($tmid,$subject,$tempposted,$trdate,$replies,$poll,$type,$micon) = split(/\|/,$_);
			if($tmid eq $URL{'m'}) { print FILE "$tmid|$subject|$tempposted|$trdate|$replies|$poll|$type|$micon|$mtime|$username\n"; }
				else { print WRITE "$_\n"; }
		}
		seek(WRITE,0,0);
		while( $pmessage = <WRITE> ) { print FILE $pmessage; }
		fclose(WRITE);
		unlink("$boards/$URL{'b'}.msg.temp");
		fclose(FILE);
	}

	redirect("$surl\lm-$URL{'m'}/s-$URL{'s'}/");
}

sub Rate {
	if(!$allowrate || $username eq 'Guest') { error($polltxt[18]); }
	if(!$FORM{'rate'} || ($FORM{'rate'} != 1 && $FORM{'rate'} != 2 && $FORM{'rate'} != 3 && $FORM{'rate'} != 4 && $FORM{'rate'} != 5)) { error($gtxt{'bfield'}); }

	$counter = 0;
	fopen(FILE,"$messages/$URL{'m'}.rate");
	while(<FILE>) {
		chomp $_;
		if($_ eq $username) { error($polltxt[18]); }
		if($counter == 0) { $rate = $_; }
			else { $rate2 .= "$_\n"; }
		++$counter;
	}
	fclose(FILE);

	if($rate) {
		$rate = sprintf("%.1f",(($rate+$FORM{'rate'})/2));
		if($rate > 1 && $rate < 2) { $rate = '1.5'; }
		elsif($rate > 2 && $rate < 3) { $rate = '2.5'; }
		elsif($rate > 3 && $rate < 4) { $rate = '3.5'; }
		elsif($rate > 4 && $rate < 5) { $rate = '4.5'; }
			else { $rate = sprintf("%.0f",$rate); }
	} else { $rate = $FORM{'rate'}; }

	fopen(FILE,">$messages/$URL{'m'}.rate");
	print FILE "$rate\n$rate2$username";
	fclose(FILE);
	redirect("$surl\lb-$URL{'b'}/");
}
1;
