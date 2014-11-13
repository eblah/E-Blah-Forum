#############################################
# E-Blah Bulletin Board Systems        2008 #
#############################################
# Copyright (c) 2001 - 2008 E-Blah.         #
#############################################

CoreLoad('Recommend',1);

sub Recommend {
	is_member();
	fopen(FILE,"$boards/$URL{'b'}.msg");
	while (<FILE>) {
		chomp $_;
		($id,$tit) = split(/\|/,$_);
		if($id eq $URL{'m'}) { $fnd = 1; $ttitle = $tit; last; }
	}
	fclose(FILE);
	if(!$fnd) { error("$gtxt{error2}: $URL{'m'}"); }

	$title = CensorList($title);

	if($URL{'p'} eq 'send') { Recommend2(); }

	$title = $rectxt[5];
	header();
	$ebout .= <<"EOT";
<form action="$surl\lv-recommend/b-$URL{'b'}/m-$URL{'m'}/p-send/" method="post">
<table class="border" cellpadding="4" cellspacing="1" width="700">
 <tr>
  <td class="titlebg"><strong><img src="$images/recommend_sm.gif" alt="" /> $title</strong></td>
 </tr><tr>
  <td class="win smalltext">$rectxt[18]</td>
 </tr><tr>
  <td class="win2">
   <table cellpadding="5" cellspacing="0" width="100%">
    <tr>
     <td style="width: 35%" class="vtop right"><strong>$rectxt[6]:</strong></td>
     <td style="width: 65%">$ttitle</td>
    </tr>
   </table>
  </td>
 </tr><tr>
  <td class="win">
   <table cellpadding="5" cellspacing="0" width="100%">
    <tr>
     <td class="right" style="width: 35%"><strong>$rectxt[7]:</strong></td>
     <td style="width: 65%"><input type="text" size="30" name="name" value="$memberid{$username}{'sn'}" /></td>
    </tr><tr>
     <td class="right" style="width: 35%"><strong>$rectxt[8]:</strong></td>
     <td style="width: 65%"><input type="text" size="30" name="email" value="$memberid{$username}{'email'}" /></td>
    </tr>
   </table>
  </td>
 </tr><tr>
  <td class="win2">
   <table cellpadding="5" cellspacing="0" width="100%">
    <tr>
     <td class="right" style="width: 35%"><strong>$rectxt[9]:</strong></td>
     <td style="width: 65%"><input type="text" size="30" name="fname" /></td>
    </tr><tr>
     <td class="right" style="width: 35%"><strong>$rectxt[10]:</strong></td>
     <td style="width: 65%"><input type="text" size="30" name="femail" /></td>
    </tr>
   </table>
  </td>
 </tr><tr>
  <td class="win">
   <table cellpadding="5" cellspacing="0" width="100%">
    <tr>
     <td class="right vtop" style="width: 35%"><strong>$rectxt[22]:</strong></td>
     <td style="width: 65%">$rectxt[2]</td>
    </tr><tr>
     <td class="right vtop" style="width: 35%"><strong>$rectxt[11]:</strong><div class="smalltext">$rectxt[23]</div></td>
     <td style="width: 65%"><textarea name="message" rows="7" cols="60">$rectxt[16]\n\n$rectxt[13], $memberid{$username}{'sn'}, $rectxt[14] "$mbname".\n\n$rectxt[20], "$ttitle" $rectxt[21]:\n$rurl\lm-$URL{'m'}/\n\n$gtxt{'25'}</textarea></td>
    </tr>
   </table>
  </td>
 </tr><tr>
  <td class="win2 center"><input type="submit" value=" $rectxt[17] " /></td>
 </tr>
</table>
</form>
EOT
	footer();
	exit;
}

sub Recommend2 {
	my($to,$subject,$message,$from) = @_;

	if($URL{'he'}) { error("[b]E-BLAH![/b]\n\nCreated by Justin\n\nCongrats, you've found a private area!"); }
	error($rectxt[4]) if($FORM{'email'} eq '' || $FORM{'femail'} eq '');
	error($rectxt[3]) if($FORM{'name'} eq '' || $FORM{'fname'} eq '');
	$message = Format($FORM{'message'});
	if($message eq '') { error($gtxt{'bfield'}); }

	smail($FORM{'femail'},$rectxt[2],$message,$FORM{'email'});
	redirect("$surl\lm-$URL{'m'}/");
}
1;