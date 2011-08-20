#############################################
# E-Blah Bulletin Board Systems        2008 #
#############################################
# Copyright (c) 2001 - 2008 E-Blah.         #
#############################################

CoreLoad('Admin1',1);

is_admin();

sub AdminMain {
	@adminlist = FindRanks('Administrator');
	foreach(@adminlist) {
		GetMemberID($_);
		$adminlist .= "$userurl{$_}, ";
	}
	$adminlist =~ s/, \Z//;

	$curtime = time;
	fopen(FILE,"+<$prefs/AdminLog.txt");
	@log = <FILE>;
	chomp @log;
	truncate(FILE,0);
	seek(FILE,0,0);
	foreach(@log) {
		($timel,$userl,$ipl) = split(/\|/,$_);
		if($userl eq $username && $ipl eq $ENV{'REMOTE_ADDR'} && $timel+3600 > $curtime) { print FILE "$curtime|$userl|$ipl\n"; $alin = 1; }
			else { print FILE "$_\n"; }
	}
	if(!$alin) { print FILE "$curtime|$username|$ENV{'REMOTE_ADDR'}\n"; push(@log,"$curtime|$username|$ENV{'REMOTE_ADDR'}"); }
	fclose(FILE);
	$count = @log;

	if($URL{'r'} < 5 && $URL{'r'} > 0) {
		if($URL{'r'} == 1) { $r = $admintxt[77]; }
		if($URL{'r'} == 2) { $r = $admintxt[145]; }
		if($URL{'r'} == 3) { $r = $admintxt[169]; }
		if($URL{'r'} == 4) { $r = $admintxt[170]; }

		$message = "<strong><center>$r</center></strong>";
	} else { $message = qq~$admintxt[12] <a href="http://www.eblah.com/forum/">$admintxt[13]</a>.~; }

	MakeComma($count);

	$title = $admintxt[187];

	headerA();

	$ebout .= <<"EOT";
<div id="outdated"></div>

<script type="text/javascript" src="http://www.eblah.com/jscheck.php?version=$version"></script>

<table cellpadding="0" cellspacing="0" width="100%">
 <tr>
  <td colspan="3">
   <table width="100%" cellpadding="0" cellspacing="0">
    <tr>
     <td>
      <table cellpadding="5" cellspacing="1" width="100%" class="border">
       <tr>
        <td class="win2">$message</td>
       </tr><tr>
        <td class="titlebg">$admintxt[221]</td>
       </tr><tr>
        <td class="win2" id="headlines" style="padding: 0px">Please wait ...</td>
       </tr>
      </table>
     </td>
    </tr>
   </table>
  </td>
 </tr><tr>
  <td colspan="3">&nbsp;</td>
 </tr><tr>
  <td class="vtop" style="width: 50%">
EOT
	if($members{'Administrator',$username}) {
		$ebout .= <<"EOT";
   <table width="100%" cellpadding="0" cellspacing="0">
    <tr>
     <td colspan="2"><table class="border" cellpadding="4" cellspacing="1" width="100%">
      <tr>
       <td class="win" style="width: 100%; padding: 0px;">
        <table cellpadding="10" cellspacing="0" width="100%">
         <tr>
          <td colspan="2" class="catbg" style="padding: 6px"><strong>$admintxt[14]</strong></td>
         </tr><tr>
          <td><img src="$images/admincenter/forum_settings.png" class="centerimg" alt="" /> &nbsp; <a href="$surl\v-admin/a-sets/">$admintxt[16]</a></td>
          <td><img src="$images/admincenter/board_setup.png" class="centerimg" alt="" /> &nbsp; <a href="$surl\v-admin/a-boards/">$admintxt[43]</a></td>
         </tr><tr>
          <td class="win2"><img src="$images/admincenter/themes.png" class="centerimg" alt="" /> &nbsp; <a href="$surl\v-admin/a-themesman/">$admintxt[47]</a></td>
          <td class="win2"><img src="$images/admincenter/templates.png" class="centerimg" alt="" /> &nbsp; <a href="$surl\v-admin/a-temp/">$admintxt[52]</a></td>
         </tr><tr>
          <td><img src="$images/admincenter/groups.png" class="centerimg" alt="" /> &nbsp; <a href="$surl\v-admin/a-memgrps/">$admintxt[55]</a></td>
          <td><img src="$images/admincenter/register_members.png" class="centerimg" alt="" /> &nbsp; <a href="$surl\v-register/">$admintxt[185]</a></td>
         </tr><tr>
          <td class="win2"><img src="$images/admincenter/rebuild.png" class="centerimg" alt="" /> &nbsp; <a href="$surl\v-admin/a-remem/">$admintxt[60]</a></td>
          <td class="win2"><img src="$images/admincenter/recycle_users.png" class="centerimg" alt="" /> &nbsp; <a href="$surl\v-admin/a-delspec/">$admintxt[61]</a></td>
         </tr><tr>
          <td><img src="$images/admincenter/backup.png" class="centerimg" alt="" /> &nbsp; <a href="$surl\v-admin/a-bkup/">$admintxt[66]</a></td>
          <td><img src="$images/admincenter/prune.png" class="centerimg" alt="" /> &nbsp; <a href="$surl\v-admin/a-remove/">$admintxt[67]</a></td>
         </tr>
        </table>
       </td>
      </tr>
     </table></td>
    </tr>
   </table>
EOT
	}
	$ebout .= <<"EOT";
  </td><td>&nbsp;</td><td class="vtop" style="width: 50%">
   <table width="100%" cellpadding="0" cellspacing="0">
    <tr>
     <td colspan="2"><table class="border" cellpadding="4" cellspacing="1" width="100%">
      <tr>
       <td class="win" style="width: 100%; padding: 0px">
        <table cellpadding="6" cellspacing="0" width="100%">
         <tr>
          <td colspan="2" class="catbg"><strong>$admintxt[211]</strong></td>
         </tr><tr>
          <td class="win2"><strong>$admintxt[17]</strong></td>
	    </tr><tr>
          <td class="smalltext"><a href="mailto:$eadmin">$regto</a> ($eadmin)</td>
         </tr><tr>
          <td colspan="2" class="win2">
           <div style="float: left"><strong>$admintxt[18]</strong></div>
           <div style="float: right" class="smalltext"><a href="$surl\v-members/a-groups/" onclick="target='_parent';">$admintxt[19]</a></div>
          </td>
         </tr><tr>
          <td colspan="2" class="smalltext">$adminlist</td>
         </tr><tr>
          <td colspan="2" class="catbg">
           <div style="float: left"><strong>$admintxt[186]</strong></div>
           <div class="right smalltext" style="float: right">$count $admintxt[204]</div>
          </td>
         </tr><tr>
          <td class="smalltext" colspan="2" style="padding: 0px">
           <table width="100%" cellpadding="6" cellspacing="0">
            <tr>
             <td class="win2 smalltext"><strong>$admintxt[180]</strong></td>
             <td class="win2 smalltext center"><strong>$gtxt{18}</strong></td>
             <td class="win2 smalltext right"><strong>$admintxt[130]</strong></td>
            </tr>
EOT

	foreach(reverse sort {$a <=> $b} @log) {
		($timel,$userl,$ipl) = split(/\|/,$_);
		$timel = get_date($timel);
		GetMemberID($userl);
		if($userurl{$userl}) { $userl = $userurl{$userl}; }
		$ebout .= qq~<tr><td class="smalltext">$userl</td><td class="smalltext center">$ipl</td><td class="smalltext right">$timel</td></tr>~;
		++$counter;
		if($counter > 4) { last; }
	}

	$ebout.= <<"EOT";
           </table>
          </td>
         </tr>
        </table>
       </td>
      </tr>
     </table></td>
    </tr>
   </table>
  </td>
 </tr>
</table>

<table cellpadding="0" cellspacing="0" width="100%">
 <tr>
  <td class="center" colspan="2"><br />
   <table class="border" cellpadding="0" cellspacing="1" width="100%">
    <tr>
     <td class="win2 center">
      <table cellpadding="10" cellspacing="0" width="100%">
       <tr>
	    <td class="vtop win3" style="width: 215px">
	     <div class="titlebg" style="padding: 5px">Developers Personal Blog</div>
		 <div class="win" style="padding: 10px" id="blogheads"></div>
		 <div class="catbg" style="padding: 10px; text-align: center;">
		 <form action="https://www.paypal.com/cgi-bin/webscr" method="post">
		 <div class="center">
		  <input type="hidden" name="cmd" value="_s-xclick" />
		  <input type="image" src="https://www.paypal.com/en_US/i/btn/btn_donateCC_LG.gif" style="border: 0" name="submit" alt="Make payments with PayPal - it's fast, free and secure!" />
		  <img alt="" src="https://www.paypal.com/en_US/i/scr/pixel.gif" width="1" height="1" />
		  <input type="hidden" name="encrypted" value="-----BEGIN PKCS7-----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-----END PKCS7-----" />
		  <br /><span class="smalltext"><a href="http://www.eblah.com/donate.php">Donate to E-Blah</a></span>
		 </div></form>
		 </div>
		</td>
		<td style="width: 5px; padding: 0px;" class="win4"></td>
		<td class="vtop" style="line-height: 1.5;">
		 <div style="font-size: 18px; font-weight: bold;">E-Blah $version</div>
		 <div class="win4" style="height: 5px; margin-top: 5px; margin-bottom: 8px;"></div>
		 <strong>JESUS</strong> is the way, the truth, and the life (John 14:6). If you <strong>confess</strong> with your mouth that <strong>JESUS is LORD</strong> and <strong>believe</strong> in your heart that GOD raised him from the dead, you <strong>will be saved</strong> (Romans 10:9 NLT).<br /><br />
		 <strong>A.</strong> Admit that you are a <strong>sinner</strong> and that you need a <strong>savior</strong>.<br />
		 <strong>B.</strong> Believe in your heart that <strong>Jesus Christ is Lord</strong>.<br />
		 <strong>C. Confess</strong> your sins and <strong>commit your life to him</strong>.<br /><br />
		 <div style="padding: 7px; height: 32px;" class="right"><img src="$images/heart.png" class="rightimg" alt="" />"For GOD so <strong>LOVED</strong> the world that he <strong>gave</strong> his <strong>ONLY</strong> Son, so that <strong>EVERYONE</strong> who believes in him <strong>will not perish</strong> but have <strong>eternal life</strong>." - John 3:16 NLT</div>
		 <div class="win4" style="height: 5px; margin-top: 5px; margin-bottom: 8px;"></div>
		 <div style="padding: 1px; overflow: auto; height: 150px;">
		  <div style="padding: 5px">
		   <div style="font-weight: bold; font-size: 18px;">Credits</div>
		   <strong><a href="http://www.eblah.com/forum/v-members/a-groups/group-Administrator/" onclick="target='_parent';">E-Blah Administration Team</a></strong><br />
		   <div style="margin-left: 5px">Craig<br />Nat<br />Ryan<br />Martin</div><br />
		   <strong>Core Development</strong>
		   <div style="margin-left: 5px"><a href="http://www.revolutionreality.com" onclick="target='_parent';">Justin</a></div><br />
		   <strong>E-Blah Hosting</strong>
		   <div style="margin-left: 5px"><a href="http://www.timlinden.com/blog/" onclick="target='_parent';">Tim Linden</a></div><br />
		   <strong>Design and Various</strong>
		   <div style="margin-left: 5px"><i>Smilies</i> | <a href="http://www.dlanham.com">David Lanham</a>, MacThemes Smileys<br /><i>Icons</i> | <a href="http://www.iconsdesigns.com/" onclick="target='_parent';">Alexandre Moore</a>, <a href="http://www.famfamfam.com/lab/icons/silk/">Mark James</a><br /><i>PNG IE6 Fix</i> | <a href="http://homepage.ntlworld.com/bobosola/index.htm" onclick="target='_parent';">Bob Osola</a><br /><i>URL Regex</i> | Dave B.</div><br />
		   E-Blah is proudly released under the <a href="http://www.eblah.com/license.php">General Public License (GPL)</a>.<br />
		  </div>
		  <div class="win4" style="padding: 5px; margin-bottom: 5px;"><span style="float: right"><a href="http://www.eblah.com" onclick="target='_parent';">Website</a> | <a href="http://www.eblah.com/forum/" onclick="target='_parent';">Community</a> | <a href="http://www.blahdocs.com" onclick="target='_parent';">Documentation</a></span>Copyright &copy; 2001-2008 E-Blah Forum Software</div>
		 </div>
		</td>
	   </tr>
      </table>
     </td>
    </tr>
   </table>
  </td>
 </tr>
</table>
<script type="text/javascript" src="http://www.eblah.com/headlines2.php"></script>
EOT
	footerA();
}

sub Remem {
	is_admin(4.1);

	opendir(DIR,"$members/");
	@list = readdir(DIR);
	closedir(DIR);
	$memcnt = 0;
	foreach(sort {$a <=> $b} @list) {
		if($_ =~ s/.dat\Z//) {
			GetMemberID($_);
			if($memberid{$_}{'registered'} > $lucnt) {
				$luser = $_;
				$lucnt = $memberid{$_}{'registered'};
			}

			if($memberid{$_}{'sn'} ne '') {
				++$memcnt;
				$memlistc .= "$_\n";
				$memlistc2 .= "$_|$memberid{$_}{'sn'}|$memberid{$_}{'posts'}|$memberid{$_}{'registered'}|$memberid{$_}{'dob'}|$memberid{$_}{'email'}|$memberid{$_}{'rep'}\n";

				# PM Counts ...
				$pmcnt = $new = 0;
				fopen(FILE,"$members/$_.pm");
				while($t = <FILE>) {
					($med,$t,$t,$t,$t,$t,$n) = split(/\|/,$t);
					if($med == 1) {
						++$new if($n);
						++$pmcnt;
					}
				}
				fclose(FILE);
				%addtoID = (
					'pmcnt' => $pmcnt,
					'pmnew' => $new
				);
				SaveMemberID($_);
			}
		}
	}
	fopen(LIST,"+>$members/List.txt");
	print LIST "$memlistc";
	fclose(LIST);
	fopen(LIST,"+>$members/List2.txt");
	print LIST "$memlistc2";
	fclose(LIST);
	chomp $luser;
	fopen(FILE,"+>$members/LastMem.txt");
	print FILE "$luser\n$memcnt";
	fclose(FILE);
	if($URL{'v'} eq 'memberpanel' || $URL{'a'} eq 'convert' || $URL{'a'} eq 'delspec' || $URL{'a'} eq 'removemembers' || $URL{'a'} eq 'posts') { return; }

	redirect("$surl\v-admin/r-1/");
}

sub ClickLog {
	is_admin(6.3);

	error($admintxt[78]) if($eclick != 1);
	if($URL{'p'} eq 'delete') {
		fopen(FILE,">$prefs/ClickLog.txt");
		print FILE '';
		fclose(FILE);
		redirect("$surl\v-admin/r-3/");
	}

	$title = $admintxt[79];
	headerA();
	$ebout .= <<"EOT";
<script type="text/javascript">
//<![CDATA[
function clear(url) {
 if(window.confirm("$admintxt[80]")) { location = url; }
}
//]]>
</script>
<table cellpadding="5" cellspacing="1" class="border" width="98%">
 <tr>
  <td class="titlebg"><strong>$title</strong></td>
 </tr><tr>
  <td class="win smalltext">$admintxt[81]<strong><a href="$surl\v-admin/a-sets/l-log/">$admintxt[82]</a></strong>.</td>
 </tr><tr>
  <td class="catbg">$admintxt[198]</td>
 </tr><tr>
  <td class="win2">
   <table width="100%">
    <tr>
     <td style="width: 25%" colspan="2" class="smalltext"><strong>$admintxt[198]</strong></td>
     <td style="width: 25%" class="smalltext"><strong>$admintxt[88]</strong></td>
    </tr>
EOT
	$totalips = 0;
	fopen(FILE,"$prefs/ClickLog.txt");
	while(<FILE>) {
		chomp;
		($t,$ipaddy,$ref[$totalips],$page[$totalips],$info[$totalips]) = split(/\|/,$_);
		if($iplog{$ipaddy} eq '') { push(@ipaddyt,$ipaddy); }
		++$iplog{$ipaddy};

		if($page[$totalips] eq '') { $page[$totalips] = $admintxt[85]; }
		++$ref{$ref[$totalips]};
		++$page{$page[$totalips]};
		++$totalips;
	}
	fclose(FILE);

	foreach(@ipaddyt) { push(@ipaddy,"$iplog{$_}|$_"); }

	foreach(sort {$b <=> $a} @ipaddy) {
		($t1,$t2) = split(/\|/,$_);
		$pper = ($t1/$totalips);
		$pper = sprintf("%.2f",($pper*100));
		if($totalipss > 25) { ++$totalipss; next; }
		$ebout .= <<"EOT";
<tr>
 <td style="width: 15%" class="smalltext">$t2</td>
 <td style="width: 60%"><img src="$images/bar.gif" width="$pper%" height="10" alt="" /></td>
 <td style="width: 25%" class="smalltext">$t1 ($pper%)</td>
</tr>
EOT
		++$totalipss;
	}
	if($totalipss > 25) { $totalipss -= 25; $ebout .= qq~<tr><td colspan="3" class="smalltext"><br />$admintxt[199] $totalipss $admintxt[200] $totalips $admintxt[201] ~.($totalipss+25)." $admintxt[202]</td></tr>"; }
	$ebout .= <<"EOT";
   </table>
  </td>
 </tr><tr>
  <td class="catbg"><div style="float: left; width: 50%">$admintxt[91]</div><div style="float: right; width: 50%">$admintxt[92]</div></td>
 </tr><tr>
  <td class="win">
   <table width="100%">
    <tr>
     <td style="width: 50%; padding: 5px;" class="vtop">
      <table width="100%">
EOT

	%ossearch = (
		'windows'     => 'Windows ',
		'win'         => 'Windows ',
		'linux'       => 'Linux ',
		'mac'         => 'Macintosh ',
		'googlebot'   => 'Googlebot',
		'slurp'       => 'Yahoo! Bot',
		'msnbot'      => 'MSN Bot',
		'inktomi'     => 'Hot Bot',
		'ia_archiver' => 'Archive.org'
	);

	%brsearch = (
		'msie'        => 'Internet Explorer ',
		'opera'       => 'Opera ',
		'netscape'    => 'Netscape ',
		'firefox'     => 'Firefox',
		'gecko'       => 'Gecko',
		'safari'      => 'Safari',
		'mozilla'     => 'Mozilla ',
		'php'         => 'Zend PHP',
		'googlebot'   => 'Googlebot ',
		'slurp'       => 'Yahoo! Bot ',
		'msnbot'      => 'MSN Bot ',
		'inktomi'     => 'Hot Bot ',
		'ia_archiver' => 'Archive.org ',
		'bot'         => 'Search Bot'
	);

	$cntb = 0;
	$cnto = 0;
	for($i = 0; $i < @info; $i++) {
		$fndb = 0;
		$fndo = 0;
		$browser = $info[$i];
		$os = $info[$i];

		if($os =~ /(Windows|Win|Linux|Mac) ([A-Za-z0-9. ]{2,8})/i) { $ouser = $ossearch{lc($1)}.$2; }
		elsif($os =~ /(googlebot|slurp|msnbot|inktomi|ia_archiver)/i) { $ouser = $ossearch{lc($1)}; }
		elsif($os =~ /(bot|crawler)/i) { $ouser = $admintxt[203]; }
		elsif($os eq '') { next; }
			else { $ouser = $gtxt{'1'}; }
		$ouser =~ s/NT 5.0/2000/;
		$ouser =~ s/NT 5.1/XP/;
		$ouser =~ s/NT 6.0/Vista/;
		if($browser =~ /(safari|MSIE|Opera|Netscape|Firefox|Gecko|Mozilla|PHP|googlebot|slurp|msnbot|inktomi|ia_archiver|bot) ([0-9.A-Za-z ]{2,9})/i) { $buser = $brsearch{lc($1)}.$2; }
		elsif($browser =~ /(safari|MSIE|Opera|Firefox|Netscape|PHP|Mozilla|googlebot|slurp|msnbot|inktomi|ia_archiver|bot)/i) { $buser = $brsearch{lc($1)}.$2; }
		elsif($browser =~ /bot|crawler/i) { $buser = $admintxt[203]; }
			else { $buser = $gtxt{'1'}; }

		if(!$oscnt{$ouser}) { push(@os,$ouser); }
		if(!$brcnt{$buser}) { push(@browsers,$buser); }
		++$oscnt{$ouser};
		++$brcnt{$buser};
	}

	foreach(@os) { push(@osall,"$oscnt{$_}|$_"); }
	foreach(sort {$b <=> $a} @osall) {
		($t1,$t2) = split(/\|/,$_);
		$pper = ($t1/$totalips);
		$pper = sprintf("%.2f",($pper*100));
		$ebout .= qq~<tr><td style="width: 30%" class="smalltext">$t2</td><td><img src="$images/bar.gif" height="10" width="$pper%" alt="" /></td><td style="width: 30%" class="smalltext">$t1 ($pper%)</td></tr>~;
	}

	$ebout .= <<"EOT";
</table>
</td><td class="win2 vtop" style="padding: 5px; width: 50%">
<table width="100%">
EOT
	foreach(@browsers) { push(@brall,"$brcnt{$_}|$_"); }
	foreach(sort {$b <=> $a} @brall) {
		($t1,$t2) = split(/\|/,$_);
		$pper = ($t1/$totalips);
		$pper = sprintf("%.2f",($pper*100));
		$ebout .= qq~<tr><td style="width: 30%" class="smalltext">$t2</td><td><img src="$images/bar.gif" height="10" width="$pper%" alt="" /></td><td style="width: 30%" class="smalltext">$t1 ($pper%)</td></tr>~;
	}
	$ebout .= <<"EOT";
   </table>
  </td>
 </tr>
</table>
EOT
	$ebout .= <<"EOT";
  </td>
 </tr><tr>
  <td class="catbg">$admintxt[93]</td>
 </tr><tr>
  <td class="win smalltext">
EOT
	foreach(@ref) {
		if($_ ne '' && !$refa{$_}) { push(@ref2,"$ref{$_}|$_"); $refa{$_} = 1; }
	}

	foreach(sort {$b <=> $a} @ref2) {
		($t1,$t2) = split(/\|/,$_);
		$pper = ($t1/$totalips);
		$pper = sprintf("%.2f",($pper*100));
		$t2 = SizedURL('',$t2);
		$ebout .= qq~$t1 ($pper%) - $t2<br />~;
		$shown = 1;
	}
	if(!$shown) { $ebout .= $admintxt[94]; }
	$ebout .= <<"EOT";
  </td>
 </tr><tr>
  <td class="catbg">$admintxt[95]</td>
 </tr><tr>
  <td class="win2 smalltext">
EOT
	foreach(@page) {
		$_ =~ s/^,//gsi;
		if($_ ne '' && !$pagea{$_}) { push(@page2,"$page{$_}|$_"); $pagea{$_} = 1; }
	}

	foreach(sort {$b <=> $a} @page2) {
		($t1,$t2) = split(/\|/,$_);
		next if(!$t1);
		$t2l = $t2;
		if($t2 eq 'Board Index') { $t2 = ''; }
		$pper = ($t1/$totalips);
		$pper = sprintf("%.2f",($pper*100));
		$ebout .= qq~$t1 ($pper%) - <a href="$scriptname$modrewrite$t2">$t2l</a><br />~;

	}
	$ebout .= <<"EOT";
  </td>
 </tr><tr>
  <td class="catbg smalltext center"><a href="javascript:clear('$surl\v-admin/a-clicklog/p-delete/')"><strong>$admintxt[96]</strong></a></td>
 </tr>
</table>
EOT
	footerA();
	exit;
}

sub ErrorLog {
	is_admin(6.4);

	if($URL{'p'} eq 'delete') {
		unlink("$prefs/ELog.txt");
		redirect("$surl\v-admin/r-3/");
	}
	$title = $admintxt[117];
	headerA();
	$ebout .= <<"EOT";
<script type="text/javascript">
//<![CDATA[
function clear(url) {
 if(window.confirm("$admintxt[80]")) { location = url; }
}
//]]>
</script>
<table class="border" cellpadding="5" cellspacing="1" width="98%">
 <tr>
  <td class="titlebg"><strong>$title</strong></td>
 </tr><tr>
  <td class="win smalltext">$admintxt[118]</td>
 </tr>
EOT

	fopen(FILE,"$prefs/ELog.txt");
	@elog = <FILE>;
	fclose(FILE);
	chomp @elog;
	if(!$elog[0] && $kelog) {
		$ebout .= <<"EOT";
 <tr>
  <td class="center win2"><strong>$admintxt[121]</strong></td>
 </tr>
</table>
EOT
	} else {
		$ebout .= "</table>";
		$clog = 1;
		foreach(reverse @elog) {
			($desc,$reason,$logtime,$lusername,$url) = split(/\|/,$_);
			GetMemberID($lusername);
			if($memberid{$lusername}{'sn'} ne '') { $lusername = $userurl{$lusername}; }
				else { $lusername = $lusername; }
			++$counter;
			$timeoferror = get_date($logtime);
			$reason = $reason ne '?' ? $reason = qq~<tr><td class="win smalltext" colspan="2"><strong>$reason</strong></td></tr>~ : '';
			$ebout .= <<"EOT";
<br /><table class="border" cellpadding="4" cellspacing="1" width="98%">
 <tr>
  <td style="width: 5%" class="win center"><strong>$counter</strong></td>
  <td class="win" style="width: 95%">
   <table width="100%">
    <tr>
     <td style="width: 25%" class="smalltext"><strong>$admintxt[180]:</strong> $lusername</td>
     <td style="width: 40%" class="smalltext"><strong>$admintxt[181]:</strong> $timeoferror</td>
     <td style="width: 35%" class="smalltext"><a href="$url">$url</a></td>
    </tr>
   </table>
  </td>
 </tr><tr>
  <td class="win2 smalltext" colspan="2">$desc</td>
 </tr>$reason
</table>
EOT
		}
	}


	if($clog) { $ebout .= <<"EOT";
<br /><table class="border" cellpadding="4" cellspacing="1" width="98%">
 <tr>
  <td class="catbg smalltext center"><strong><a href="javascript:clear('$surl\v-admin/a-errorlog/p-delete/')">$admintxt[96]</a></strong></td>
 </tr>
</table>
EOT
	}

	footerA();
	exit;
}

sub IPLog {
	is_admin(6.5);

	if($URL{'p'} eq 'delete') {
		unlink("$prefs/IpLog.txt");
		redirect("$surl\v-admin/r-3/");
	}
	$clog = 1;

	$title = $admintxt[125];
	headerA();
	$ebout .= <<"EOT";
<script type="text/javascript">
//<![CDATA[
function clear(url) {
 if(window.confirm("$admintxt[80]")) { location = url; }
}
//]]>
</script>
<table class="border" cellpadding="4" cellspacing="1" width="700">
 <tr>
  <td class="titlebg" colspan="4"><strong>$title</strong></td>
 </tr><tr>
  <td class="win smalltext" colspan="4">$admintxt[126]</td>
 </tr>
EOT

	if(!$logip) { $ebout .= <<"EOT";
 <tr>
  <td colspan="4" class="center win"><strong>$admintxt[120]</strong></td>
 </tr>
EOT
		$clog = 0;
	}
		fopen(FILE,"$prefs/IpLog.txt");
		@iplog = <FILE>;
		fclose(FILE);
		if(!$iplog[0] && $logip == 1) { $ebout .= <<"EOT";
 <tr>
  <td colspan="4" class="center win"><strong>$admintxt[131]</strong></td>
 </tr>
EOT
		$clog = 0;
	} else {
		# Get Pages
		$mupp = 50;
		$maxmessages = @iplog || 1;
		if($maxmessages < $mupp) { $URL{'p'} = 0; }
		$tstart = $URL{'p'} || 0;
		$link = "$surl\v-admin/a-iplog/s-$URL{'s'}/p";
		if($tstart > $maxmessages) { $tstart = $maxmessages; }
		$tstart = (int($tstart/$mupp)*$mupp);
		if($tstart > 0) { $bk = ($tstart-$mupp); $pagelinks = qq~<a href="$link-$bk/">&#171;</a> ~; }
		$counter = 1;
		for($i = 0; $i < $maxmessages; $i += $mupp) {
			if($i == $tstart || $maxmessages < $mupp) { $pagelinks .= qq~<strong>$counter</strong>, ~; $nxt = ($tstart+$mupp); }
				else { $pagelinks .= qq~<a href="$link-$i/">$counter</a>, ~; }
			++$counter;
		}
		$pagelinks =~ s/, \Z//gsi;
		if(($tstart+$mupp) != $i) { $pagelinks .= qq~ <a href="$link-$nxt/">&#187;</a>~; }
		$end = ($tstart+$mupp);
		$pagelinks .= " ($var{'92'} $tstart-$end $var{'93'} ".@iplog.")";

		$ebout .= <<"EOT";
 <tr>
  <td colspan="4" class="win2 smalltext"><strong><img src="$images/board.gif" alt="" /> $gtxt{'17'}:</strong> $pagelinks</td>
 </tr><tr>
  <td class="catbg smalltext center" style="width: 25%"><strong>$admintxt[127]</strong></td>
  <td class="catbg smalltext center" style="width: 20%"><strong>$admintxt[128]</strong></td>
  <td class="catbg smalltext center" style="width: 25%"><strong>$gtxt{'18'}</strong></td>
  <td class="catbg smalltext center" style="width: 30%"><strong>$admintxt[130]</strong></td>
 </tr>
EOT
		@iplog = reverse @iplog;
		for($i = 0; $i < @iplog; ++$i) {
			if($i <= $end && $i > $tstart) { push(@log,$iplog[$i]); }
		}

		foreach(@log) {
			chomp;
			($lusername,$loginout,$ipaddr,$logtime) = split (/\|/,$_);
			GetMemberID($lusername);
			if($memberid{$lusername}{'sn'} eq '') { $lusername = $lusername; }
				else { $lusername = $userurl{$lusername}; }
			$loginout = $loginout == 1 ? $admintxt[132] : $admintxt[133];
			$loggedtime = get_date($logtime);
			$ebout .= <<"EOT";
 <tr>
  <td class="win center">$lusername</td>
  <td class="win2 center">$loginout</td>
  <td class="win center">$ipaddr</td>
  <td class="win2 smalltext center">$loggedtime</td>
 </tr>
EOT
		}
		$ebout .= <<"EOT";
 <tr>
  <td colspan="4" class="win smalltext"><strong><img src="$images/board.gif" alt="" /> $gtxt{'17'}:</strong> $pagelinks</td>
 </tr>
EOT
	}

	if($clog) { $ebout .= <<"EOT";
 <tr>
  <td class="catbg smalltext center" colspan="4"><strong><a href="javascript:clear('$surl\v-admin/a-iplog/p-delete/')">$admintxt[96]</a></strong></td>
 </tr>
EOT
	}

	$ebout .= "</table>";
	footerA();
	exit;
}

sub TempFormat {
	$_[0] =~ s/</&lt;/g;
	$_[0] =~ s/>/&gt;/g;
	$_[0] =~ s/"/\&quot;/g;
	$_[0] =~ s/\cM//g;
	return($_[0]);
}

sub Temp {
	is_admin(2.2);

	fopen(FILE,"$templates/News.html");
	while(<FILE>) { chomp; $temps1 .= $_."\n"; }
	fclose(FILE);
	$temps1 = TempFormat($temps1);

	fopen(FILE,"$prefs/RTemp.txt");
	while(<FILE>) { chomp; $temps2 .= $_."\n"; }
	fclose(FILE);
	$temps2 =~ s/<br \/>/\n/g;
	$temps2 = TempFormat($temps2);

	$title = $admintxt[135];
	headerA();
	$ebout .= <<"EOT";
<script type="text/javascript">
//<![CDATA[
function GetTemplate(gettemplate,tempdesc) {
	oldputaway = document.forms['admin'].putaway;
	tempeditor = document.forms['admin'].tempedit;

	// Lets put away the old ones ... and get rdy for new ones!
	if(oldputaway.value == 1) { document.forms['admin'].temp1.value = tempeditor.value; }
	else if(oldputaway.value == 2) { document.forms['admin'].temp2.value = tempeditor.value; }

	if(gettemplate == 1) { tempeditor.value = document.forms['admin'].temp1.value; }
	else if(gettemplate == 2) { tempeditor.value = document.forms['admin'].temp2.value; }

	oldputaway.value = gettemplate;
	if(tempdesc) { document.getElementById('tempdesc').innerHTML = tempdesc; }
}
//]]>
</script>
<form action="$surl\v-admin/a-temp2/" method="post" id="admin" onsubmit="GetTemplate(0)">
<table width="98%" cellpadding="0" cellspacing="1" class="border">
 <tr>
  <td class="titlebg" style="padding: 5px;"><img src="$images/xx.gif" alt="" /> $admintxt[135]</td>
 </tr><tr>
  <td class="win2">
   <table cellpadding="0" cellspacing="0" width="100%">
    <tr>
     <td class="win vtop" style="width: 175px" rowspan="2"><input type="hidden" name="putaway" />
     <div class="titlebg" style="padding: 5px;"><strong>HTML Templates</strong></div><div style="padding: 10px; line-height: 150%;">
     <a href="#" onclick="GetTemplate('1','$admintxt[182]')">$admintxt[182]</a><input type="hidden" name="temp1" value="$temps1" /></div>
     <div class="titlebg" style="padding: 5px;"><strong>Various Templates</strong></div><div style="padding: 10px; line-height: 150%;">
     <a href="#" onclick="GetTemplate('2','$admintxt[191]')">$admintxt[191]</a><input type="hidden" name="temp2" value="$temps2" /></div><br />
     </td>
     <td class="catbg" style="padding: 5px;"><strong><span id="tempdesc">$admintxt[195]</span></strong></td>
    </tr><tr>
     <td class="vtop center" style="padding: 5px;"><textarea name="tempedit" cols="1" rows="1" style="width: 95%; height: 200px;"></textarea><br /></td>
    </tr>
   </table>
  </td>
 </tr><tr>
  <td class="win2 center" style="padding: 5px;"><input type="submit" name="submit" value=" $admintxt[139] " /></td>
 </tr>
</table>
</form>
EOT
	footerA();
	exit;
}

sub Temp2 {
	is_admin(2.2);

	fopen(FILE,"+>$templates/News.html");
	print FILE $FORM{'temp1'};
	fclose(FILE);

	fopen(FILE,"+>$prefs/RTemp.txt");
	print FILE Format($FORM{'temp2'});
	fclose(FILE);
	redirect("$surl\v-admin/r-3/");
}

sub Repop {
	is_admin(5.1);

	my($messagedb);
	if($URL{'p'} eq '') {
		$title = $admintxt[65];
		headerA();
		$ebout .= <<"EOF";
<table class="border" cellpadding="5" cellspacing="1" width="500">
 <tr>
  <td class="titlebg"><strong><img src="$images/brd_main.gif" alt="" /> $title</strong></td>
 </tr><tr>
  <td class="win smalltext">$admintxt[141]</td>
 </tr><tr>
  <td class="win2">
   <table cellpadding="5">
    <tr>
     <td colspan="2"><a href="$surl\v-admin/a-repop/p-start/">$admintxt[142]</a></td>
    </tr><tr>
     <td><img src="$images/warning.png" style="float: left" alt="" /></td><td>$admintxt[143]</td>
    </tr>
   </table>
  </td>
 </tr>
</table>
EOF
		footerA();
		exit;
	}

	fopen(FILE,">$root/Maintance.lock"); # Start MM
	print FILE "\$maintance = 1;\n\$maintancer = qq~$admintxt[144]~;\n1;";
	fclose(FILE);

	foreach(@boardbase) {
		($cgs) = split("/",$_);
		fopen(FILE,"$boards/$cgs.msg");
		@msg = <FILE>;
		fclose(FILE);
		chomp @msg;
		$number = 0;
		$replycount = 0;
		@output = '';
		$puser = 0;
		$ptime = 0;
		foreach $msgs (@msg) {
			($tmess,$a,$b,$c,$replies,$poll,$f,$g) = split(/\|/,$msgs);
			$curnumber = -1;
			if($inu{$tmess}) { next; }
			if(!-s "$messages/$tmess.txt") { next; }
			fopen(FILE,"$messages/$tmess.txt");
			while( $countz = <FILE> ) {
				chomp $countz;
				($posted,$t,$t,$t,$lp) = split(/\|/,$countz);
				++$curnumber;
			}
			fclose(FILE);
			$replycount = $curnumber+$replycount;
			++$number;
			$inu{$tmess} = 1;
			if($poll && !$polltop) { # Count the polls
				fopen(FILE,"$messages/$tmess.polled");
				@last = <FILE>;
				fclose(FILE);
				chomp @last;
				$lloc = @last-1;
				($poller,$ptime) = split(/\|/,$last[$lloc]);
				if($ptime && $ptime > $lp) { $posted = $poller; $lp = $ptime; }
			}
			push(@output,"$lp|$tmess|$a|$b|$c|$curnumber|$poll|$f|$g|$posted");
		}
		$find = 0;
		fopen(FILE,"+>$boards/$cgs.msg");
		foreach $last (sort{$b <=> $a} @output) {
			($lp,$tmess,$a,$b,$c,$curnumber,$e,$f,$g,$posted) = split(/\|/,$last);
			if($find == 0) { $puser = $posted; $ptime = $lp; ++$find; }
			if($tmess eq '') { next; }
			print FILE "$tmess|$a|$b|$c|$curnumber|$e|$f|$g|$lp|$posted\n";

			$messagedb .= "$tmess|$cgs\n";
		}
		fclose(FILE);
		$replycount = $replycount+$number;
		fopen(FILE,"+>$boards/$cgs.ino");
		print FILE "$number\n$replycount\n";
		fclose(FILE);
	}

	fopen(FILE,"+>$boards/Messages.db");
	print FILE $messagedb;
	fclose(FILE);

	unlink("$root/Maintance.lock"); # End MM
	if($URL{'a'} eq 'remove') { return; } # If removing old threads
	redirect("$surl\v-admin/r-2/");
}

sub News {
	is_admin(1.7);

	if($URL{'p'} == 2) {
		fopen(FILE,"+>$prefs/News.txt");
		print FILE $FORM{'news'};
		fclose(FILE);
		redirect("$surl\v-admin/r-3/");
	}
	fopen(FILE,"$prefs/News.txt");
	@news = <FILE>;
	fclose(FILE);
	chomp @news;
	foreach(@news) { $news .= "$_\n"; }
	$news =~ s/\cM//g; # For non-ASCII files . . .
	$title = $admintxt[49];
	headerA();
	$ebout .= <<"EOT";
<form action="$surl\v-admin/a-news/p-2/" method="post">
<table class="border" cellspacing="1" cellpadding="4" width="550">
 <tr>
  <td class="titlebg"><strong><img src="$images/news.png" alt="" /> $title</strong></td>
 </tr><tr>
  <td class="win smalltext">$admintxt[157]</td>
 </tr><tr>
  <td class="win2 center"><textarea name="news" rows="8" cols="100">$news</textarea></td>
 </tr><tr>
  <td class="win"><input type="submit" value=" $admintxt[139] " /></td>
 </tr>
</table>
</form>
EOT
	footerA();
	exit;
}

sub Reserve {
	is_admin(4.3);

	if($FORM{'cnt'}) {
		for($i = 1; $i <= $FORM{'max'}; ++$i) {
			if($FORM{"del_$i"}) { next; }
			$search = Format($FORM{"search_$i"});
			push(@pdata,qq~$search|$FORM{"box_$i"}~);
		}
		if($FORM{'search_new'}) { push(@pdata,"$FORM{'search_new'}|$FORM{'box_new'}"); }

		fopen(FILE,">$prefs/Names.txt");
		foreach(@pdata) { print FILE "$_\n"; }
		fclose(FILE);
		redirect("$surl\v-admin/a-reserve/");
	}

	$title = $admintxt[171];
	headerA();
	$ebout .= <<"EOT";
<form action="$surl\v-admin/a-reserve/" method="post">
<table cellpadding="4" cellspacing="1" class="border" width="500">
 <tr>
  <td class="titlebg"><strong><img src="$images/mem_main.gif" alt="" /> $title</strong></td>
 </tr><tr>
  <td class="win smalltext">$admintxt[172]</td>
 </tr><tr>
  <td class="win2">
   <table cellpadding="3" cellspacing="0" width="100%">
    <tr>
     <td class="smalltext" style="width: 44%"><strong>$admintxt[174]</strong></td>
     <td class="smalltext center" style="width: 44%"><strong>$admintxt[175]</strong></td>
     <td class="smalltext center" style="width: 12%"><strong>$admintxt[173]</strong></td>
    </tr>
EOT
	$count = 0;
	fopen(FILE,"$prefs/Names.txt");
	while(<FILE>) {
		chomp $_;
		($searchme,$within) = split(/\|/,$_);
		$checked = $within ? ' checked="checked"' : '';
		++$count;
		$ebout .= <<"EOT";
    <tr>
     <td style="width: 44%"><input type="text" name="search_$count" value="$searchme" size="30" /></td>
     <td style="width: 44%" class="center"><input type="checkbox" name="box_$count" value="1"$checked /></td>
     <td style="width: 12%" class="center"><input type="checkbox" name="del_$count" value="1" /></td>
    </tr>
EOT
	}
	if($count <= 0) {
		$ebout .= <<"EOT";
    <tr>
     <td class="smalltext center" colspan="3"><br />$admintxt[176]<br /><br /></td>
    </tr>
EOT
	}
	fclose(FILE);
	$ebout .= <<"EOT";
   </table>
  </td>
 </tr><tr>
  <td class="win">
   <table cellpadding="3" cellspacing="0" width="100%">
    <tr>
     <td style="width: 44%"><input type="text" name="search_new" size="30" /></td>
     <td style="width: 44%" class="center"><input type="checkbox" name="box_new" value="1" /></td>
     <td style="width: 12%">&nbsp;</td>
    </tr>
   </table>
  </td>
 </tr><tr>
  <td class="win2 center"><input type="hidden" name="max" value="$count" /><input type="hidden" name="cnt" value="1" /><input type="submit" value=" $admintxt[139] " /></td>
 </tr>
</table>
</form>
EOT
	footerA();
	exit;
}

sub BoardBackup { # Backup Routines
	is_admin(5.2);

	$title = $admintxt[66];
	headerA();
	$ebout .= <<"EOT";
<script type="text/javascript">
//<![CDATA[
function togledisable() {
 for(i = 0; i < document.forms['admin'].elements.length; i++) {
  if(document.forms['admin'].elements[i].disabled == true || document.forms['admin'].elements[i].name == "broot" || document.forms['admin'].elements[i].name == "removeold" || document.forms['admin'].elements[i].name == "submit") { document.forms['admin'].elements[i].disabled = false; }
   else { document.forms['admin'].elements[i].disabled = true; }
 }
 document.forms['admin'].fname.disabled = false;
}
//]]>
</script>
<form action="$surl\v-admin/a-bkupstart/" id="admin" method="post">
<table class="border" cellpadding="4" cellspacing="1" width="500">
 <tr>
  <td class="titlebg" colspan="2"><strong><img src="$images/open_thread.gif" alt="" /> $title</strong></td>
 </tr><tr>
  <td class="win smalltext">$backupt[2]</td>
 </tr><tr>
  <td class="titlebg"><strong>$backupt[10]</strong></td>
 </tr><tr>
  <td class="win2">
   <table width="100%">
    <tr>
     <td style="width: 50%" class="win2 right"><strong>$backupt[22]:</strong></td>
     <td class="win2 vtop"><input type="text" value="backup" name="fname" /></td>
    </tr><tr>
     <td style="width: 50%" class="win2 right"><strong>$backupt[1]</strong></td>
     <td class="win2 vtop"><input type="checkbox" value="1" name="removeold" checked="checked" /></td>
    </tr><tr><td colspan="2">$backupt[3]</td></tr><tr>
     <td style="width: 50%" class="win2 right">$backupt[20]</td>
     <td class="win2 vtop"><input type="checkbox" value="1" name="broot" onclick="togledisable();" checked="checked" /></td>
    </tr>
   </table>
  </td>
 </tr>
 <tr>
  <td class="win">
   <table width="100%">
    <tr>
     <td style="width: 50%" class="right"><strong>Boards:</strong></td>
     <td><input type="checkbox" value="1" name="boards" disabled="disabled" /></td>
    </tr><tr>
     <td class="right"><strong>Members:</strong></td>
     <td><input type="checkbox" value="1" name="members" disabled="disabled" /></td>
    </tr><tr>
     <td class="right"><strong>Messages:</strong></td>
     <td><input type="checkbox" value="1" name="messages" disabled="disabled" /></td>
    </tr><tr>
     <td class="right"><strong>Prefs:</strong></td>
     <td><input type="checkbox" value="1" name="prefs" disabled="disabled" /></td>
    </tr><tr>
     <td class="right"><strong>Code:</strong></td>
     <td><input type="checkbox" value="1" name="code" disabled="disabled" /></td>
    </tr><tr>
     <td class="right"><strong>Themes:</strong></td>
     <td><input type="checkbox" value="1" name="themes" disabled="disabled" /></td>
    </tr><tr>
     <td class="right"><strong>Uploads:</strong></td>
     <td><input type="checkbox" value="1" name="uploads" disabled="disabled" /></td>
    </tr>
   </table>
  </td>
 </tr><tr>
  <td class="win2 right"><input type="submit" name="submit" value="$backupt[16]" /></td>
 </tr>
</table>
</form>
EOT
	footerA();
	exit;
}

sub BKUPStart {
	is_admin(5.2);

	$FORM{'fname'} =~ s/ /_/g;
	$FORM{'fname'} =~ s/[#%+,\\\/:?"<>'|@^\$\&~'\)\(\]\[\;{}!`=-]//g;

	@backuparray = ("$root|$FORM{'broot'}|full", "$messages|$FORM{'messages'}|messages", "$code|$FORM{'code'}|code", "$boards|$FORM{'boards'}|boards", "$prefs|$FORM{'prefs'}|prefs", "$members|$FORM{'members'}|members", "$uploads|$FORM{'uploads'}|uploads", "$themes|$FORM{'themes'}|themes");

	if($FORM{'removeold'}) {
		opendir(DIR,"$root");
		@opendir = readdir(DIR);
		closedir(DIR);
		foreach(@opendir) {
			if($_ =~ /.tar/) { unlink($_); }
		}
	}

	foreach(@backuparray) {
		($arcdir,$doit,$arcname) = split(/\|/,$_);

		if($doit) {
			`tar -cf - "$arcdir" > "./$FORM{'fname'}_$arcname.tar"`;
			`gzip "./$FORM{'fname'}_$arcname.tar"`;
		}
	}

	redirect("$surl\v-admin/r-4/");
}

sub EncryptPass { # Password encryption .....
	is_admin(4.6);

	if($yabbconver && $encryption == 2) { error($admintxt[205]); }
	if($URL{'type'}) { EncryptPass2(); }

	headerA();
	$ebout .= <<"EOT";
<script type="text/javascript">
//<![CDATA[
function clear(url) {
 if(window.confirm("$admintxt[183]")) { window.location = "$surl\v-admin/a-encrypt/type-"+url+"/"; }
}
//]]>
</script>
<table width="500" cellpadding="5" cellspacing="1" class="border">
 <tr>
  <td class="titlebg">$admintxt[206]</td>
 </tr><tr>
  <td class="win"><a href="javascript:clear('2')"><strong>MD5 Encryption</strong></a> <i>($admintxt[208])</i><br />$admintxt[209]<br />
EOT
	if(!$yabbconver) { $ebout .= qq~<br /><a href="javascript:clear('1')"><strong>Perl crypt() function</strong></a><br />$admintxt[210]~; }
	$ebout .= <<"EOT";
  </td>
 </tr>
</table>
EOT
	footerA();
	exit;
}

sub EncryptPass2 {
	is_admin(4.6);

	if($encryption != 1) {
		fopen(FILE,"$members/List.txt");
		@membarlist = <FILE>;
		fclose(FILE);
		chomp @membarlist;
	}
	if($encryption == 1) { $md5upgrade = 1; }
	$encryption = $URL{'type'} || 2;
	$yabbconver = 1;

	if(!$md5upgrade) {
		foreach(@membarlist) {
			GetMemberID($_);
			$addtoID{'password'} = Encrypt($memberid{$_}{'password'});
			SaveMemberID($_);
		}
	}
	CoreLoad('Admin2');
	Settings3();
}

sub PurgeSessions {
	is_admin(4.5);

	opendir(DIR,"$prefs/Sessions");
	@list = readdir(DIR);
	closedir(DIR);
	$time = time;
	foreach(@list) {
		next if($_ eq '.' || $_ eq '..');
		($t,$t,$t,$t,$t,$t,$t,$t,$t,$mtime) = stat("$prefs/Sessions/$_");
		unlink("$prefs/Sessions/$_") if($mtime+5184000 < $time); # Sessions older than 60 days are removed
	}
	redirect("$surl\v-admin/r-3/");
}
1;