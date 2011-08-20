#############################################
# E-Blah Bulletin Board Systems        2008 #
#############################################
# Copyright (c) 2001 - 2008 E-Blah.         #
#############################################

CoreLoad('Notify',1);

sub AddDelNotify2 {
	if($URL{'m'} ne 'brd') {
		GetMessages();

		$switch = NotifyAddStatus($URL{'m'},2) ? 0 : 1;

		NotifyAddStatus($URL{'m'},1,$switch);
	} else {
		fopen(FILE,"$boards/$URL{'b'}.mail");
		while(<FILE>) {
			chomp $_;
			if($_ eq $username) { $fnd = 1; } else { push(@bdata,$_); }
		}
		fclose(FILE);
		if(!$fnd) { push(@bdata,$username); }
		fopen(FILE,">$boards/$URL{'b'}.mail");
		foreach(@bdata) { print FILE "$_\n"; }
		fclose(FILE);
	}
	redirect("$surl\lv-memberpanel/a-notify/");
}

sub GetMessages {
	fopen(FILE,"$boards/$URL{'b'}.msg");
	@msg = <FILE>;
	fclose(FILE);
	chomp(@msg);
	foreach(@msg) {
		($mid,$mtitle,$t,$t,$t,$t,$locked) = split(/\|/,$_);
		if($mid == $URL{'m'}) { $fnd = 1; last; }
	}
	if($fnd != 1) { error("$notify[8]: $URL{'m'}.txt"); }
}

sub View {
	foreach(@boardbase) {
		($oboard,$desc,$t,$bnme) = split("/",$_);
		fopen(FILE,"$boards/$oboard.mail");
		while(<FILE>) {
			chomp $_;
			if($_ eq $username) { push(@bdata,"$oboard|$bnme|$desc"); }
		}
		fclose(FILE);
		fopen(FILE,"$boards/$oboard.msg");
		while(<FILE>) { chomp $_;
			($id,$msub,$auth,$t,$t,$t,$t,$t,$last) = split(/\|/,$_);
			$message{$id} = "$msub|$auth|$last";
		}
		fclose(FILE);
	}

	NotifyAddStatus($mdat,4);

	foreach(@maildatabase) {
		($messageid,$userbase) = split(/\|/,$_);
		foreach $temp (split(",",$userbase)) {
			($ubed,$type) = split("/",$temp);
			if($ubed eq $username) {
				$onlist{$messageid} = $type;
				push(@allmessages,$messageid);
			}
		}
	}

	fopen(ULOG,"$members/$username.log");
	while(<ULOG>) {
		chomp;
		($lid,$ltime) = split(/\|/,$_);
		$logged{$lid} = $ltime;
	}
	fclose(ULOG);

	$callt = qq~<img src="$images/notify_sm.png" alt="" /> $notify[17]~;
	$morecaller = $notify[5];

	$displaycenter = <<"EOT";
<script type="text/javascript">
//<![CDATA[
function check(what) {
 for(i = 0; i < document.forms['notify'].elements.length; i++) { document.forms['notify'].elements[i].checked = what; }
}
//]]>
</script>
<form action="$surl\lv-memberpanel/a-notify/s-delete/" id="notify" method="post">
<table class="border" cellpadding="8" cellspacing="1" width="100%">
 <tr>
  <td class="catbg smalltext"><strong>$notify[19]</strong></td>
 </tr><tr>
  <td class="win">
   <table cellpadding="6" cellspacing="0" width="100%"><tr>
EOT
	$cnt = 0;
	foreach(@bdata) {
		($id,$name,$message) = split(/\|/,$_);
		$message =~ s/&#47;/\//gsi;
		$message = BC($message);
		++$cnt;
		$displaycenter .= qq~$next<td class="vtop" style="width: 10px"><input type="checkbox" name="b_$id" value="1" /></td><td style="width: 50%" class="vtop"><strong><a href="$surl\lb-$id/">$name</a></strong><div class="smalltext">$message</div></td>~;
		if($cnt == 2) { $next = "</tr><tr>"; $cnt = 0; } else { $next = ''; }
	}
	if($cnt == 1) { $displaycenter .= "<td>&nbsp;</td><td>&nbsp;</td>"; }
	if(!$bdata[0]) { $displaycenter .= qq~<td class="center"><br />$notify[20]<br /><br /></td>~; }
	$displaycenter .= <<"EOT";
  </tr></table></td>
 </tr><tr>
  <td class="catbg smalltext"><strong>$notify[11]</strong></td>
 </tr><tr>
  <td class="win" style="padding: 0px">
   <table cellpadding="6" cellspacing="0" width="100%">
    <tr>
     <td class="titlebg" style="width: 25px">&nbsp;</td>
     <td class="titlebg smalltext"><strong>$notify[24]</strong></td>
     <td class="titlebg smalltext center"><strong>$notify[25]</strong></td>
     <td class="titlebg smalltext right" style="width: 150px"><strong>$notify[26]&nbsp;</strong></td>
    </tr>
EOT
	foreach $viewid (@allmessages) {
		$checked{0} = $checked{1} = '';
		$checked{$onlist{$viewid}} = ' selected="selected"';
		($title,$author,$last) = split(/\|/,$message{$viewid});
		GetMemberID($author);

		if($logged{$viewid} < $last) { $new = qq~<div style="font-weight: bold;"><img src="$images/new.png" alt="$notify[23]" style="margin: 0 3px 0 3px;" /> ~; $newbies = "s-new/"; }
			else { $new = '<div>'; $newbies = ''; }

		$displaycenter .= <<"EOT";
    <tr>
     <td class="win3 center"><input type="checkbox" name="$viewid" value="1" /></td>
     <td>$new<a href="$surl\lm-$viewid/$newbies">$title</a></div></td>
     <td class="win2 center">$userurl{$author}</td>
     <td class="right"><select name="type_$viewid"><option value="0"$checked{0}>$notify[21]</option><option value="1"$checked{1}>$notify[22]</option></select></td>
    </tr>
EOT
	}

	if(!$allmessages[0]) { $displaycenter .= qq~<tr><td colspan="4" class="center"><br />$notify[12]<br /><br /></td></tr>~; }

	$displaycenter .= <<"EOT";
   </table>
  </td>
 </tr>
EOT

	if($allmessages[0] || $bdata[0]) {
		$displaycenter .= <<"EOT";
 <tr>
  <td class="win2 center">
   <table cellpadding="0" cellspacing="0" width="100%">
    <tr>
     <td><input type="submit" value=" $notify[13] " /></td>
     <td class="right smalltext"><a href="javascript:check(true)">$notify[15]</a> <strong>::</strong> <a href="javascript:check(false)">$notify[16]</a>&nbsp;</td>
    </tr>
   </table>
  </td>
 </tr>
EOT
	}
	$displaycenter .= "</table></form>";
}

sub NotifyDel {
	while(($mdat,$on) = each(%FORM)) {
		if($mdat =~ /type_(.+?)\Z/gsi && $FORM{$1} != 1) {
			NotifyAddStatus($1,1,1,$on);
		}
		if($mdat =~ /b_(.+?)\Z/gsi) {
			fopen(FILE,"$boards/$1.mail");
			@bdat = <FILE>;
			fclose(FILE);
			chomp @bdat;
			fopen(FILE,">$boards/$1.mail");
			foreach(@bdat) { unless($username eq $_) { print FILE $_; } else { $found = 1; } }
			fclose(FILE);
			if(-s("$boards/$1.mail") == 0) { unlink("$boards/$1.mail"); }
		} else { NotifyAddStatus($mdat,1,0); }
	}
	redirect("$surl\lv-memberpanel/a-notify/");
}
1;