#############################################
# E-Blah Bulletin Board Systems        2008 #
#############################################
# Copyright (c) 2001 - 2008 E-Blah.         #
#############################################

CoreLoad('Invite',1);

sub Invite {
	if($invfri != 1) { is_member(); }
	elsif($URL{'id'} ne '') { LinkMeUp(); }
	elsif($URL{'p'} eq '') { InviteLong(); }
		else { Finalize(); }
}

sub InviteLong {
	is_member();
	$title = $invite[6];
	header();

	$ebout .= <<"EOT";
<form action="$surl\lv-invite/p-2/" method="post">
<table cellpadding="4" cellspacing="1" class="border" width="750">
 <tr>
  <td class="titlebg"><strong><img src="$images/recommend_sm.gif" alt="" /> $title</strong></td>
 </tr><tr>
  <td class="catbg smalltext"><strong>$invite[8]</strong></td>
 </tr><tr>
  <td class="win">
   <table cellspacing="0" cellpadding="4" width="100%">
    <tr>
     <td class="right" style="width: 25%"><strong>$invite[3]:</strong></td>
     <td style="width: 25%"><input type="text" name="friendname" size="25" value="$FORM{'friendname'}" /></td>
     <td class="right" style="width: 25%"><strong>$invite[4]:</strong></td>
     <td style="width: 25%"><input type="text" name="yourname" value="$memberid{$username}{'sn'}" size="25" /></td>
    </tr><tr> 
     <td class="right"><strong>$invite[5] $gtxt{'23'}:</strong></td>
     <td><input type="text" name="friendmail" value="$FORM{'friendmail'}" size="25" /></td>
     <td class="right"><strong>$gtxt{'23'}:</strong></td>
     <td><input type="text" name="yourmail" value="$memberid{$username}{'email'}" size="25" /></td>
    </tr>
   </table>
  </td>
 </tr><tr>
  <td class="catbg smalltext"><strong>$invite[12]</strong></td>
 </tr><tr>
  <td class="win2">
   <table cellspacing="0" cellpadding="2" width="100%">
    <tr>
      <td style="width: 5%" class="center"><input type="checkbox" name="emailme" value="1" checked="checked" /></td>
      <td style="width: 95%" colspan="2"><strong>$invite[13]</strong><div class="smalltext">$invite[14]</div></td>
    </tr>
   </table>
  </td>
 </tr><tr>
  <td class="win">
   <table cellspacing="0" cellpadding="4" width="100%">
    <tr> 
     <td class="right" style="width: 40%"><strong>$invite[18]:</strong></td>
     <td style="width: 60%"><input type="text" name="subject" value="$invite[19]" size="30" maxlength="30" /></td>
    </tr><tr>
     <td class="right vtop" style="width: 40%"><strong>$invite[20]:</strong></td>
     <td style="width: 60%"><textarea name="permessage" rows="4" cols="45">$invite[21]</textarea><br />$invite[44]</td>
    </tr>
   </table>
  </td>
 </tr><tr>
  <td class="win2 center"><input type="submit" value=" $invite[22] " /></td>
 </tr>
</table>
</form>
EOT
	footer();
	exit;
}

sub Finalize {
	is_member();

	error($invite[32]) if($FORM{'friendmail'} eq '');
	error($invite[33]) if($FORM{'friendname'} eq '');
	error($invite[34]) if($FORM{'permessage'} eq '');
	error($invite[35]) if($FORM{'subject'} eq '');

	if(length($FORM{'permessage'}) > 499) { error($gtxt{'bfield'}); }
	if(length($FORM{'subject'}) > 29) { error($gtxt{'bfield'}); }

	if($FORM{'yourname'} eq '') { $FORM{'yourname'} = $memberid{$username}{'sn'}; }
	if($FORM{'yourmail'} eq '') { $FORM{'yourmail'} = $memberid{$username}{'email'}; }

	$referid = time;
	error($invite[32]) if($FORM{'friendmail'} !~ /\A([0-9A-Za-z\._\-]{1,})@([0-9A-Za-z\._\-]{1,})+\.([0-9A-Za-z\._\-]{1,})+\Z/);
	if($FORM{'yourmail'} !~ /\A([0-9A-Za-z\._\-]{1,})@([0-9A-Za-z\._\-]{1,})+\.([0-9A-Za-z\._\-]{1,})+\Z/) { $FORM{'yourmail'} = $memberid{$username}{'email'}; }

	# Write to file
	$friendmail = Format($FORM{'yourmail'});
	$friendemail = $FORM{'emailme'} ? 1 : 0;
	$friendname = Format($FORM{'friendname'});
	fopen(FILE,"+>>$prefs/Refer.txt");
	print FILE "$referid|$surl|$friendmail|$friendemail|$friendname|$username\n";
	fclose(FILE);

	# Send message
	$message2 = Format($FORM{'permessage'});
	$subject = Format($FORM{'subject'});
	if(!$subject) { $subject = $invite[37]; }
	$sendto = Format($FORM{'friendmail'});
	$message = <<"EOT";
$message2

$invite[24]:
<a href="$rurl\lv-invite/id-$referid/">$rurl\lv-invite/id-$referid/</a>

$invite[51] $FORM{'yourname'}$invite[52] $FORM{'yourmail'}.
EOT
	smail($sendto,$subject,$message,$friendmail);

	redirect();
}

sub LinkMeUp {
	fopen(FILE,"$prefs/Refer.txt");
	while(<FILE>) {
		chomp;
		($followid,$returnto,$emailof,$send,$thisname) = split(/\|/,$_);
		if($followid eq $URL{'id'}) {
			if($send) {
				$timedate = get_date(time);
				$message = qq~$invite[31] "$thisname" $invite[26]~;
				smail($emailof,$invite[27],$message);
			}
			$addto = "$_\n";
			$url = $returnto;
		} else { $readd .= "$_\n"; }
	}
	fclose(FILE);
	if($url eq '') { redirect($surl); } # May have already been invited
	fopen(FILE,"+>>$prefs/ReferLog.txt");
	print FILE $addto;
	fclose(FILE);

	fopen(FILE,"+>$prefs/Refer.txt");
	print FILE $readd;
	fclose(FILE);
	redirect();
}

sub Referals {
	is_admin(6.6);

	if($URL{'p'} eq 'remove') {
		if($URL{'pp'}) { unlink("$prefs/Refer.txt"); } else { unlink("$prefs/ReferLog.txt"); }
		redirect("$surl\lv-admin/r-3/");
	}
	fopen(FILE,"$prefs/Refer.txt");
	while(<FILE>) { chomp; push(@refer,"1|$_"); }
	fclose(FILE);

	fopen(FILE,"$prefs/ReferLog.txt");
	while(<FILE>) { chomp; push(@refer,"2|$_"); }
	fclose(FILE);

	$title = $invite[38];
	headerA();
	$ebout .= <<"EOT";
<script type="text/javascript">
//<![CDATA[
function clear(url) {
 if(window.confirm("$invite[39]")) { location = url; }
}
//]]>
</script>
<table class="border" cellpadding="4" cellspacing="1" width="700">
 <tr>
  <td class="titlebg" colspan="5"><strong><img src="$images/recommend_sm.gif" alt="" /> $title</strong></td>
 </tr><tr>
  <td class="win">
   <table cellpadding="4" cellspacing="0" width="100%">
EOT
	foreach(sort{$a <=> $b} @refer) {
		($t,$followid,$returnto,$emailof,$send,$thisname,$inviteusername) = split(/\|/,$_);
		if($t ne $current) {
			if($counter == 1) { $ebout .= "</td><td>&nbsp;</td></tr><tr>"; $counter = 0; }
			if($counter == 2) { $ebout .= "</tr><tr>\n"; $counter = 0; }
			else { $ebout .= "<tr>"; }
			$current = $t;
			if($t == 1) { $t = $invite[40]; $remove = 1; }
			if($t == 2) { $t = $invite[41]; $remove = 1; }
			$ebout .= <<"EOT";
$next<td colspan="2" class="win2 smalltext"><strong>$t</strong></td></tr><tr>
EOT
			$c = 0;
			$next = '';
		}
		++$c;
		$getdate = get_date($followid);
		if($c > 2) { $o = "<br />"; }
		$serviceen = '';
		if($send) { $serviceen = qq~<strong>$invite[43]</strong>~; }

		GetMemberID($inviteusername);
		if($memberid{$inviteusername}{'sn'} ne '') { $inviteusername = $userurl{$inviteusername}; }
		elsif($inviteusername) { $inviteusername = "$inviteusername"; }
			else { $inviteusername = qq~<a href="mailto:$emailof">$emailof</a>~; }

		$ebout .= <<"EOT";
$next<td style="width: 50%">$o
 <table>
  <tr>
   <td rowspan="2" class="vtop"><strong>$c.</strong></td>
   <td><strong>$invite[45]:</strong> $thisname</td>
  </tr><tr>
   <td class="smalltext"><strong>$invite[46]:</strong> $getdate<br /><strong>$invite[47]:</strong> $inviteusername</td>
  </tr><tr>
   <td colspan="2" class="smalltext">$serviceen</td>
  </tr>
 </table>
</td>
EOT
		$next = '';
		++$counter;
		if($counter == 2) { $next = "</tr><tr>\n"; $counter = 0; }
	}
	if($counter == 1) { $ebout .= "</td><td>&nbsp;</td>"; }
	if($remove) {
		$ebout .= <<"EOT";
<tr><td colspan="2" class="center win2" class="smalltext"><strong><a href="javascript:clear('$surl\lv-admin/a-referals/p-remove/pp-2/')">$invite[49]</a> | <a href="javascript:clear('$surl\lv-admin/a-referals/p-remove/')">$invite[48]</a></strong></td></tr>
EOT
	} else {
		$ebout .= <<"EOT";
<tr><td colspan="2">$invite[50]</td></tr>
EOT
	}
	$ebout .= <<"EOT";
   </table>
  </td>
 </tr>
</table>
EOT
	footerA();
	exit;
}
1;