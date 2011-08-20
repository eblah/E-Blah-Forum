#############################################
# E-Blah Bulletin Board Systems        2008 #
#############################################
# Copyright (c) 2001 - 2008 E-Blah.         #
#############################################

CoreLoad('Report',1);

sub Report {
	is_member();
	if($URL{'a'} eq 'pmreport') { PMReport(); }
	fopen(FILE,"$boards/$URL{'b'}.msg");
	while (<FILE>) {
		chomp;
		($mid, $subject) = split(/\|/,$_);
		if($mid == $URL{'m'}) { $msub = $subject; $fnd = 1; last; }
	}
	fclose(FILE);
	if($fnd != 1) { error($reporttxt[3]); }
	if($URL{'a'} eq 'r2') { Report2(); }

	$title = $reporttxt[14];
	header();
	$ebout .= <<"EOT";
<form action="$surl\lv-report/b-$URL{'b'}/m-$URL{'m'}/n-$URL{'n'}/a-r2/" method="post">
<table cellpadding="4" cellspacing="1" class="border" width="700">
 <tr>
  <td class="titlebg"><strong><img src="$images/report_sm.gif" alt="" /> $title</strong></td>
 </tr><tr>
  <td class="win smalltext">$reporttxt[44]</td>
 </tr><tr>
  <td class="win2">
   <table width="100%">
    <tr>
     <td class="right" style="width: 35%"><strong>$reporttxt[7]:</strong></td>
     <td style="width: 65%">$msub</td>
    </tr>
   </table>
  </td>
 </tr><tr>
  <td class="win">
   <table width="100%">
    <tr>
     <td class="right vtop" style="width: 35%"><strong>$reporttxt[49]:</strong></td>
     <td style="width: 65%"><select name="report"><option value="$URL{'n'}">$reporttxt[17]</option><option value="all">$reporttxt[18]</option></select></td>
    </tr><tr>
     <td class="right vtop" style="width: 35%"><strong>$reporttxt[9]:</strong></td>
     <td style="width: 65%"><select name="sendto"><option value="all admin">$reporttxt[10]</option>
EOT
	if(@mods) {
		$ebout .= qq~<option value="mods">$reporttxt[21]</option><option value="ma" selected="selected">$reporttxt[22]</option>~;
		foreach (@mods) {
			GetMemberID($_);
			if($memberid{$_}{'sn'} eq '') { next; }
			$ebout .= qq~<option value="$_">$memberid{$_}{'sn'}</option>~;
		}
	}
	$ebout .= <<"EOT";
     </select></td>
    </tr>
   </table>
  </td>
 </tr><tr>
  <td class="win2">
   <table width="100%">
     <tr>
     <td class="right vtop" style="width: 35%"><strong>$reporttxt[11]:</strong></td>
     <td style="width: 65%"><textarea name="reason" rows="7" cols="60"></textarea></td>
    </tr>
   </table>
  </td>
 </tr><tr>
  <td class="win center"><input type="submit" name="submit" value=" $reporttxt[12] " /></td>
 </tr>
</table>
</form>
EOT
	footer();
	exit;
}

sub Report2 {
	error($reporttxt[25]) if($FORM{'reason'} eq '');

	# Get all the admins into an array
	@adminslist = FindRanks('Administrator');

	# Find who we should send this report to
	if($FORM{'sendto'} eq 'all admin' || $FORM{'sendto'} eq 'ma') { push(@sendto,@adminslist); }
	if($FORM{'sendto'} eq 'mods' || $FORM{'sendto'} eq 'ma') { push(@sendto,@mods); }
	if(@sendto == 0) { push(@sendto,$FORM{'sendto'}); }

	foreach(@sendto) {
		GetMemberID($_);
		if($senta{$_}) { next; } # Already sent
		$senta{$_} = 1;
		push(@sendsto,$memberid{$_}{'email'});
	}

	if($memberid{$username}{'email'} eq '') { $memberid{$username}{'email'} = "$ENV{'REMOTE_ADDR'}"; }

	$sendmessage = <<"EOT";
"$memberid{$username}{'sn'}" $reporttxt[26]

<a href="$rurl\lm-$URL{'m'}/s-$URL{'n'}/#num$URL{'n'}">$rurl\lm-$URL{'m'}/s-$URL{'n'}/#num$URL{'n'}</a>

$reporttxt[27]:
$FORM{'reason'}
EOT
	foreach(@sendsto) { smail($_,$reporttxt[28],$sendmessage,$memberid{$username}{'email'}); }
	redirect("$surl\lm-$URL{'m'}/s-$URL{'n'}/");
}
1;
