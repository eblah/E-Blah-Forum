#############################################
# E-Blah Bulletin Board Systems        2008 #
#############################################
# Copyright (c) 2001 - 2008 E-Blah.         #
#############################################

CoreLoad('Portal',1);

{
	@totalinputs = ();

	VerifyBoard(); # Run this once -- it verifies the boards
	LoadValues();

	eval { require("$prefs/PortalModules.pl"); };
	foreach(@addmodules) {
		$installed{$_} = 1;
		eval { require("$modsdir/Modules/$_.pl"); };
	}

	if($URL{'p'} != 2) { eval { require("$prefs/PortalSet.pl"); }; }
}

sub LoadValues {
	eval { require("$prefs/PortalConf.pl"); };
	foreach(@inputvariables) {
		($t1,$t2) = split(/\|/,$_);
		$$t1 = $t2;
	}
}

sub PortalAdmin2 { # This entire thing is sooooooo ugly!
	print "Content-type: text/html\n\n";

	@names = ('leftblock','enterblock','rightblock');

	foreach(@names) {
		foreach $data (split(',',$FORM{$_})) {
			($t1,$t2) = split("=",$data);
			$$_{$t1} = $t2;
		}
	}

	if($FORM{'scriptdata'} eq '') { exit; }

	$FORM{'scriptdata'} =~ s/\+//g;
	foreach(split(/\&/,$FORM{'scriptdata'})) {
		($t1,$t2) = split("=",$_);
		$counter = 0;
		@$t1 = ();
		foreach $data2 (split(',',$t2)) {
			if($$t1{$data2} eq '') { next; }
			if($data2 == $URL{'delete'} && $URL{'block'} eq $t1) { next; }
			push(@$t1,$$t1{$data2});
		}
	}

	$fullcr = '';
	foreach(@names) {
		$grrness = $temp = '';
		foreach $temp (@$_) {
			$grrness .= "'$temp',";
		}
		$grrness =~ s/,\Z//g;
		if($grrness ne '') { $fullcr .= "\@$_ = ($grrness);\n"; }
	}

	fopen(PORTALSET,">$prefs/PortalSet.pl");
	print PORTALSET $fullcr . '1;';
	fclose(PORTALSET);

	if($URL{'delete'} eq '') { print $portal[49]; }
		else { print $portal[50]; }
	exit;
}

sub PortalAdmin3 {
	$module = $URL{'module'};
	@blocks = ('leftblock','rightblock','enterblock');
	foreach(@blocks) {
		foreach $block (@$_) {
			$newblock{$_} .= "'$block',";
		}
	}
	if($module ne 'SimpleCalendar') { eval { &$module; }; }
	if($@) { error($portal[51]); }
	$newblock{$URL{'area'}} .= "'$module',";

	fopen(FILE,">$prefs/PortalSet.pl");
	foreach(@blocks) {
		$newblock{$_} =~ s/,\Z//g;
		print FILE "\@$_ = ($newblock{$_});\n";
	}
	print FILE "1;";
	fclose(FILE);

	redirect("$surl\lv-admin/a-portal/");
}

sub PortalAdmin {
	is_admin(1.6);

	if($URL{'p'} == 2) { PortalAdmin2(); }
	elsif($URL{'p'} == 3) { PortalAdmin3(); }
	elsif($URL{'p'} == 4) {
		$data = '';
		push(@totalinputs,('lastmemcnt','showlastpostsn','topmemcnt'));
		fopen(FILE,">$prefs/PortalConf.pl");
		foreach(@totalinputs) { $FORM{$_} =~ s/'|\|//g; $data .= "'$_|$FORM{$_}',"; }
		$data =~ s/,\Z//g;
		print FILE "\@inputvariables = ($data);\n";
		fclose(FILE);
		print FILE "1;";

		redirect("$surl\lv-admin/a-portal/");
	} elsif($URL{'p'} == 5) {
		$addstuff = '';
		foreach(@addmodules) {
			if($URL{'install'} eq $_ || $URL{'deinstall'} eq $_) { next; }
			$addstuff .= "'$_',";
		}
		if($URL{'install'} ne '') { $addstuff .= "'$URL{'install'}'"; }

		$addstuff =~ s/,\Z//g;

		fopen(FILE,">$prefs/PortalModules.pl");
		print FILE "\@addmodules = ($addstuff);\n1;";
		fclose(FILE);

		redirect("$surl\lv-admin/a-portal/");
	}
	$title = "$mbname $portal[1]";
	headerA();

	@blocks = ('leftblock','enterblock','rightblock');
	foreach(@blocks) {
		$count = 0;
		foreach $temp (@$_) {
			$$_ .= "$count=$temp,";
			++$count;
		}
		$$_ =~ s/,\Z//g;
	}

	$ebout .= <<"EOT";
<script type="text/javascript" src="$bdocsdir/common.js"></script>
<script type="text/javascript" src="$bdocsdir/dbx.js"></script>

<script type="text/javascript">
//<![CDATA[
var lockitems = 0;

function DeleteABlock(deletionid,deletionblock) {
	lockitems = 1;

	EditMessage("$surl\lv-admin/a-portal/p-2/delete-"+deletionid+'/block-'+deletionblock+'/',2,senddata,'refreshme');
	senddata = '';

	setTimeout("location = '$surl\lv-admin/a-portal/'",2000);
}

window.onload = function()
{
	//initialise the docking boxes manager 
	var manager = new dbxManager('eblah'); 	//session ID [/-_a-zA-Z0-9/]
	var lameee = 0;

	manager.onstatechange = function()
	{
		if(lockitems == 1) { return false; }
EOT
	$moredata = '';
	foreach(@blocks) {
		if(@$_) { $moredata .= qq~ + '&' + '$_=' + encodeURIComponent('$$_')~; }
	}

	$ebout .= <<"EOT";
		senddata = ("scriptdata=" + encodeURIComponent(this.state)$moredata);

		if(lameee == 0) { return true; }
			else { lameee = 0; }

		EditMessage("$surl\lv-admin/a-portal/p-2/",2,senddata,'refreshme');

	}

	manager.onboxdrag = function() {
		lameee = 1;

		return true;
	}
EOT

	foreach(@blocks) {
		if(!@$_) { next; }
		$ebout .= <<"EOT";
	var $_ = new dbxGroup('$_','vertical','5','yes','5','no','open','open','close',$portal[53]);
EOT
	}

	$ebout .= <<"EOT";
};
//]]>
</script>

<table cellpadding="5" cellspacing="1" class="border" width="98%">
 <tr>
  <td class="titlebg" colspan="3">Portal Layout</td>
 </tr><tr>
  <td class="catbg center">$portal[54]</td>
  <td class="catbg center">$portal[55]</td>
  <td class="catbg center">$portal[56]</td>
 </tr><tr>
EOT
	foreach(@blocks) {
		$perc = $_ eq 'enterblock' ? 50 : 25;
		$ebout .= <<"EOT";
  <td class="win vtop" style="width: $perc%">
   <table cellpadding="5" cellspacing="0" width="100%">
    <tr>
     <td class="win" id="$_">
EOT
		$counter = 0;
		foreach $block (@$_) {
			if($modules{$block} eq '') { next; }
			$ebout .= <<"EOT";
      <div class="dbx-box">
       <div class="dbx-handle">
        <table cellpadding="5" cellspacing="1" class="border" width="100%" style="cursor: move">
         <tr>
          <td class="titlebg"><div style="float: left">$modules{$block}</div><div style="float: right"><a href="#" onclick="if(window.confirm('$portal[57]')) { DeleteABlock($counter,'$_'); } return false;"><img src="$images/ban.png" alt="" /></a></div></td>
         </tr><tr>
          <td class="win2">$moduled{$block}</td>
         </tr>
        </table><br />
       </div>
      </div>
EOT
			++$counter;
		}
		$ebout .= <<"EOT";
     </td>
    </tr>
   </table>
  </td>
EOT
	}
		$ebout .= <<"EOT";
 </tr><tr>
  <td colspan="3" class="win3"><div id="refreshme">&nbsp;</div></td>
 </tr>
</table><br />
<table cellpadding="5" cellspacing="1" width="98%" class="center border">
 <tr>
  <td class="titlebg">$portal[58]</td>
 </tr><tr>
  <td class="win2">
   <table cellpadding="6" cellspacing="0" width="100%">
    <tr>
     <td class="catbg">$portal[59]</td>
     <td class="catbg">$portal[60]</td>
     <td class="catbg right">$portal[61]</td>
    </tr><tr>
     <td class="win" colspan="3">$portal[62]</td>
    </tr>
EOT
	foreach(@modules) {
		$deinstall = '';
		if(!$defaultmodules{$_}) {
			$deinstall = qq~<a href="$surl\lv-admin/a-portal/p-5/deinstall-$internalname{$_}/"><img src="$images/ban.png" class="leftimg" alt="" /></a> &nbsp;~;
			if(!$moduleinstall) {
				$ebout .= <<"EOT";
    <tr>
     <td class="win" colspan="3">$portal[63]</td>
    </tr>
EOT
				$moduleinstall = 1;
			}

		}
		$ebout .= <<"EOT";
<tr>
 <td>$deinstall<i>$modules{$_}</i></td><td>$moduled{$_}</td><td class="right"><a href="$surl\lv-admin/a-portal/p-3/module-$_/area-leftblock/">$portal[54]</a> | <a href="$surl\lv-admin/a-portal/p-3/module-$_/area-enterblock/">$portal[55]</a> | <a href="$surl\lv-admin/a-portal/p-3/module-$_/area-rightblock/">$portal[56]</a></td>
</tr>
EOT
	}
	$ebout .= <<"EOT";
   </table>
  </td>
 </tr>
</table><br />
<form action="$surl\lv-admin/a-portal/p-4/" method="post" enctype="multipart/form-data">
<table cellpadding="5" cellspacing="1" width="98%" class="center border">
 <tr>
  <td class="titlebg">$portal[64]</td>
 </tr><tr>
  <td class="catbg">$portal[65]</td>
 </tr><tr>
  <td class="win">$portal[66]: <input type="text" name="showlastpostsn" value="$showlastpostsn" /></td>
 </tr><tr>
  <td class="catbg">$portal[67]</td>
 </tr><tr>
  <td class="win">$portal[68]: <input type="text" name="lastmemcnt" value="$lastmemcnt" /></td>
 </tr><tr>
  <td class="catbg">$portal[69]</td>
 </tr><tr>
  <td class="win">$portal[70]: <input type="text" name="topmemcnt" value="$topmemcnt" /></td>
 </tr>$extrasettings<tr>
  <td class="win2"><input type="submit" value="$portal[71]" name="submit" /></td>
 </tr>
</table>
</form><br />
<table cellpadding="5" cellspacing="1" width="98%" class="center border">
 <tr>
  <td class="titlebg">$portal[72]</td>
 </tr><tr>
  <td class="win">
   <table cellpadding="6" cellspacing="0" width="100%">
   <tr>
    <td class="catbg">$portal[59]</td>
    <td class="catbg">$portal[60]</td>
    <td class="catbg right">$portal[74]</td>
   </tr>
EOT
	opendir(DIR,"$modsdir/Modules/");
	@modules2 = readdir(DIR);
	closedir(DIR);
	@modules = ();
	foreach(@modules2) {
		$_ =~ s/.pl//g;
		eval { require("$modsdir/Modules/$_.pl"); };
		if($@ || $installed{$_}) { $@ = ''; next; }
		$filename = $_;
		foreach(@modules) {
			$ebout .= <<"EOT";
 <tr>
  <td>$modules{$_}</td>
  <td>$moduled{$_}</td>
  <td class="right"><a href="$surl\lv-admin/a-portal/p-5/install-$filename/">$portal[75]</a></td>
 </tr>
EOT
			$modulesinstalled = 1;
		}
		@modules = ();
	}
	if(!$modulesinstalled) {
			$ebout .= <<"EOT";
 <tr>
  <td colspan="3" class="center"><br />$portal[76]<br /><br /></td>
 </tr>
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

sub Portal {
	CoreLoad('Calendar');
	($t,$t,$t,$kday,$kmon,$kyear) = localtime(time+(3600*($memberid{$username}{'timezone'}+$memberid{$username}{'dst'}+$gtoff)));
	eval { $gtime = timelocal(1,1,1,1,$kmon,$kyear,1); };
	$kyear += 1900;

	@colorclass = ('win','win2');
	$percent = 100;

	$date_time = get_date(time,1);
	$title = "$mbname $portal[47]";
	header();
	$ebout .= <<"EOT";
<table cellpadding="1" cellspacing="0" width="100%">
 <tr>
EOT
	$portalcounter = 0;
	if(@leftblock) { # Build the left panel
		$ebout .= qq~<td style="width: 25%" class="vtop">~;

		foreach(@leftblock) { $ebout .= &$_; ++$portalcounter; }

		$ebout .= "</td>";
		$percent -= 25;
	}

	$percent -= 25 if @rightblock;

	$ebout .= qq~<td style="width: $percent%" class="vtop">~;

	$portalcounter = 0;
	foreach(@enterblock) { $ebout .= &$_; ++$portalcounter; }

	$ebout .= "</td>";

	$portalcounter = 0;
	if(@rightblock) { # Build the right panel
		$ebout .= qq~<td style="width: 25%" class="vtop">~;

		foreach(@rightblock) { $ebout .= &$_; ++$portalcounter; }

		$ebout .= "</td>";
	}
	$ebout .= <<"EOT";
 </tr>
</table>
EOT
	footer();
	exit;
}

sub Stats {
	if(!$mlistload) { LoadMemberList(); }
	$c = 1;
	$returnto = <<"EOT";
 <table width="100%" cellpadding="0" cellspacing="1" class="border"><tr>
  <td style="padding: 5px" class="titlebg smalltext" colspan="2"><strong>$portal[33]</strong></td>
 </tr><tr>
  <td style="padding: 9px" class="$colorclass[$portalcounter % 2] smalltext" colspan="2">
EOT
	for($g = 0; $g < $topmemcnt; ++$g) {
		$team = '';
		($posts,$member) = split(/\|/,$maxmem[$g]);
		GetMemberID($member);
		$posts = MakeComma($posts);
		if($member eq '') { next; }
		if($permissions{$membergrp{$member},'team'}) { $team = qq~ <img src="$images/team.gif" alt="$gtxt{'29'}" /> ~; }
		$returnto .= qq~<strong>$c.</strong>$team $userurl{$member} ($posts $gtxt{'10'})<br />~;
		++$c;
	}
	
	return($returnto."</td></tr></table><br />");
}

sub MembersOnline {
	if(!$morun) { GetActiveUsers(); }
	$returnto = <<"EOT";
 <table width="100%" cellpadding="0" cellspacing="1" class="border">
  <tr>
   <td style="padding: 5px" class="titlebg smalltext"><strong>$allview $portal[77] ($memcnt $portal[78]; $gcnt $portal[79]; $hidec $portal[80])</strong></td>
  </tr><tr>
   <td class="$colorclass[$portalcounter % 2]">
    <table cellpadding="9" cellspacing="1" width="100%">
     <tr>
      <td class="win3 center" style="width: 25px"><img src="$images/computer.png" alt="" /></td>
      <td class="smalltext">$memberson</td>
     </tr>
    </table>
   </td>
  </tr>
 </table><br />
EOT
	return($returnto);
}

sub BoardData {
	if(!$bdrun) {
		foreach(@boardbase) {
			($board,$t,$t,$bname,$t,$t,$t,$t,$t,$t,$brdmemgrps) = split("/",$_);
			if($boardallow{$board} != 1) { next; }
			fopen(FILE,"$boards/$board.ino");
			@ino = <FILE>;
			fclose(FILE);
			if($brdmemgrps) {
			}
			if(!$ino[1]) { $ino[1] = 0; }
			push(@tbds,"$ino[1]|$bname|$board");
			chomp @ino;
			$threads = $threads+$ino[0];
			$message = $message+$ino[1];
		}
		$catcnt  = MakeComma($catcounter);
		$bdscnt  = MakeComma($boardcounter);
		$threads = MakeComma($threads);
		$message = MakeComma($message);

		@tbds = sort{$b <=> $a} @tbds;

		$c = 1;
		for($g = 0; $g < 10; ++$g) {
			($mcnt,$boardnm,$bid) = split(/\|/,$tbds[$g]);
			$mcnt = MakeComma($mcnt);
			if($boardnm) { $topboards .= qq~<strong>$c.</strong> <a href="$surl\lb-$bid/">$boardnm</a> ($mcnt $gtxt{'11'})<br />~; }
			++$c;
		}
		$bdrun = 1;
	}

	$returnto = <<"EOT";
<table width="100%" cellpadding="0" cellspacing="1" class="border">
 <tr>
  <td style="padding: 5px" class="titlebg smalltext"><strong>$portal[17]</strong></td>
 </tr><tr>
  <td style="padding: 5px" class="catbg smalltext"><strong>$portal[81]</strong></td>
 </tr><tr>
  <td class="$colorclass[$portalcounter % 2]">
   <table cellpadding="9" cellspacing="1" width="100%">
    <tr>
     <td class="win3 center" style="width: 25px"><img src="$images/forumstats.png" alt="" /></td>
     <td class="smalltext"><strong>$gtxt{'6'}:</strong> $catcnt<br /><strong>$gtxt{'7'}:</strong> $bdscnt<br /><strong>$gtxt{'8'}:</strong> $threads<br /><strong>$gtxt{'9'}:</strong> $message</td>
    </tr>
   </table>
  </td>
 </tr><tr>
  <td style="padding: 5px" class="catbg smalltext"><strong>$portal[82]</strong></td>
 </tr><tr>
EOT
	++$portalcounter;
	$returnto .= <<"EOT";
  <td class="$colorclass[$portalcounter % 2]">
   <table cellpadding="9" cellspacing="1" width="100%">
    <tr>
     <td class="win3 center" style="width: 25px"><img src="$images/forumstats.png" alt="" /></td>
     <td class="smalltext">$topboards</td>
    </tr>
   </table>
  </td>
 </tr>
</table><br />
EOT
	return($returnto);
}

sub LatestThreads {
	my($lastthread);
	$lastthread .= <<"EOT";
<table class="border" cellpadding="4" cellspacing="1" width="100%">
 <tr>
  <td class="titlebg" colspan="4"><strong>$portal[18]</strong></td>
 </tr><tr>
  <td class="catbg" style="width: 20px">&nbsp;</td>
  <td class="catbg smalltext"><strong>$portal[19]</strong></td>
  <td class="catbg smalltext center" style="width: 50px"><strong>$gtxt{'38'}</strong></td>
  <td class="catbg smalltext" style="width: 200px"><strong>$portal[21]</strong></td>
 </tr>
EOT
	foreach $use (@boardbase) {
		($board,$t,$t,$t,$t,$t,$t,$pass) = split('/',$use);
		if(!$boardallow{$board}) { next; }
		fopen(FILE,"$boards/$board.msg");
		$counts = 0;
		while(<FILE>) {
			chomp $_;
			($id,$title,$posted,$date,$replies,$poll,$type,$micon,$date,$lastuser) = split(/\|/,$_);

			($xt1,$xt2) = split("<>",$title);
			if($xt2 ne '') { next; }

			push(@data,"$date|$id|$title|$posted|$replies|$poll|$type|$micon|$lastuser|$board");
			++$counts;
			if($counts > 11+$showlastpostsn) { last; }
		}
		fclose(FILE);
	}
	$counter = 1;

	if($username ne 'Guest') {
		fopen(FILE,"$members/$username.log");
		@log = <FILE>;
		fclose(FILE);
		chomp @log;
	}

	foreach(sort{$b <=> $a} @data) {
		if($counter == $showlastpostsn+1) { last; }
		($date,$id,$title,$posted,$replies,$poll,$type,$micon,$lastuser,$board) = split(/\|/,$_);
		if($username ne 'Guest') {
			$new = '';
			$isnew = 0;
			foreach $logged (@log) { # This is sloppy and should be rewritten ...
				($mbah,$lmtime) = split(/\|/,$logged);
				if($mbah eq "AllRead_$board" || $mbah eq $id) {
					$isnew = $lmtime-$date;
					last;
				}
			}
			if($isnew <= 0) { $new = qq~<img src="$images/new.png" style="margin: 0 3px 0 3px;" alt="" /> ~; $snew = 's-new/'; }
				else { $snew = ''; }
		}

		$status = FindStatus($date);
		GetMemberID($lastuser);
		GetMemberID($posted);
		if($lastuser eq '') { $lastuser = $posted; }
			else { $lastuser = $memberid{$lastuser}{'sn'} ne '' ? $userurl{$lastuser} : $lastuser; }
		$title = CensorList($title);
		$date = get_date($date);

		$lastthread .= <<"EOT";
 <tr>
  <td class="win center" style="width: 20px"><img src="$images/$status.png" alt="" /></td>
  <td class="win2 smalltext">$new <a href="$surl\lm-$id/$snew" title="$gtxt{'19'} $memberid{$posted}{'sn'}">$title</a></td>
  <td class="win smalltext center" style="width: 50px">$replies</td>
  <td class="win2" style="width: 200px"><table class="innertable">
   <tr>
    <td style="width: 20px" class="center"><img src="$images/icons/$micon" alt="" /></td>
    <td class="smalltext">$date $portal[23] $lastuser</td>
   </tr>
  </table></td>
 </tr>
EOT
		++$counter;
	}

	$lastthread .= "</table><br />";
	return($lastthread);
}

sub RSSLatestThreads {
	if($URL{'max'} < 50 && $URL{'max'} > 0) { $showlastpostsn = $URL{'max'}; }

	print "Content-type: text/xml\n\n";

	print <<"EOT";
<?xml version="1.0" encoding="$char"?>
<rss version="2.0"
	xmlns:dc="http://purl.org/dc/elements/1.1/"
	>
 <channel>
  <title>$mbname</title>
  <link>$rurl</link>
  <generator>http://www.eblah.com</generator>
  <description></description>
  <language>en</language>
EOT
	foreach $use (@boardbase) {
		($board,$t,$t,$t,$t,$t,$t,$pass) = split('/',$use);
		if(!$boardallow{$board}) { next; }
		fopen(FILE,"$boards/$board.msg");
		$counts = 0;
		while(<FILE>) {
			chomp $_;
			($id,$title,$posted,$date,$replies,$poll,$type,$micon,$date,$lastuser) = split(/\|/,$_);

			($xt1,$xt2) = split("<>",$title);
			if($xt2 ne '') { next; }

			push(@data,"$date|$id|$title|$posted|$replies|$poll|$type|$micon|$lastuser|$board");
			++$counts;
			if($counts > 11+$showlastpostsn) { last; }
		}
		fclose(FILE);
	}
	$counter = 1;

	if($username ne 'Guest') {
		fopen(FILE,"$members/$username.log");
		@log = <FILE>;
		fclose(FILE);
		chomp @log;
	}

	foreach(sort{$b <=> $a} @data) {
		if($counter == $showlastpostsn+1) { last; }
		($date,$id,$title,$posted,$replies,$poll,$type,$micon,$lastuser,$board) = split(/\|/,$_);
		if($username ne 'Guest') {
			$new = '';
			$isnew = 0;
			foreach $logged (@log) { # This is sloppy and should be rewritten ...
				($mbah,$lmtime) = split(/\|/,$logged);
				if($mbah eq "AllRead_$board" || $mbah eq $id) {
					$isnew = $lmtime-$date;
					last;
				}
			}
			if($isnew <= 0) { $new = 1; }

			if($URL{'g'} eq 'new' && !$new) { next; }
		}

		GetMemberID($posted);
		$title = CensorList($title);

		fopen(FILE,"$messages/$id.txt");
		while($temp = <FILE>) {
			($t,$message,$t,$t,$t,$nosmile) = split(/\|/,$temp);
			last;
		}
		fclose(FILE);

		$message = BC($message);

		if($memberid{$posted}{'sn'} eq '') { $userpost = $posted; }
			else { $userpost = $memberid{$posted}{'sn'}; }

		($s,$m,$h,$day,$month,$year,$wday) = localtime($id);
		$year += 1900;
		++$month;
		if($h < 10) { $h = "0$h"; }
		if($m < 10) { $m = "0$m"; }
		if($s < 10) { $s = "0$s"; }

		print <<"EOT";
  <item>
   <title>$title</title>
   <link>$rurl\lm-$id/</link>
   <comments>$rurl\lm-$id/#num1</comments>
   <description><![CDATA[$message]]></description>
   <pubDate>$sdays[$wday], $day $smonths[$month-1] $year $h:$m:$s</pubDate>
   <dc:creator>$userpost</dc:creator>
  </item>
EOT
		++$counter;
	}

	print " </channel>\n</rss>";
	exit;
}

sub News {
	my($lastthread);
	$lastthread .= <<"EOT";
<table class="border" cellpadding="4" cellspacing="1" width="100%">
 <tr>
  <td class="titlebg"><strong><img src="$images/news.png" alt="" /> $var{'4'}</strong></td>
 </tr>
EOT
	@open = split(",",$newsboard);
	foreach(@open) {
		@news1 = ();
		fopen(FILE,"$boards/$_.msg");
		while($curforumread = <FILE>) {
			chomp $curforumread;
			push(@news1,"$curforumread|$_");
		}
		fclose(FILE);
		push(@news,@news1);
	}	$counter = 0;

	$newslength = $newslength || 0;

	foreach(sort{$b <=> $a} @news) {
		if($counter eq $newsshow) { last; }
		($messid,$messtitle,$posted,$date,$replies,$poll,$type,$micon,$date,$t,$curforumread) = split(/\|/,$_);

		($t,$xt2) = split("<>",$messtitle);
		if($xt2 ne '') { next; }

		if($posted eq '') { next; }
		fopen(FILE,"$messages/$messid.txt");
		while($temp = <FILE>) {
			($t,$message) = split(/\|/,$temp);
			last;
		}
		fclose(FILE);
		if($newslength && length($message) > $newslength) {
			$message =~ s~\[table\](.*?)\[\/table\]~$var{'88'}~sgi;
			$message = substr($message,0,$newslength);

			$message =~ s~([^\w\"\=\[\]]|[\n\b]|\A)\\*(\w+://[\w\~\.\;\:\$\-\+\!\*\?/\=\&\@\#\%]+\.[\w\~\;\:\$\-\+\!\*\?/\=\&\@\#\%,.]+[\w\~\;\:\$\-\+\!\*\?/\=\&\@\#\%]\Z)~~eisg;
			$message =~ s~([^\"\=\[\]/\:\.(\://\w+)]|[\n\b]|\A|[\<\n\b\>])\\*(www\.[^\.][\w\~\.\;\:\$\-\+\!\*\?/\=\&\@\#\%]+\.[\w\~\;\:\$\-\+\!\*\?/\=\&\@\#\%\,]+[\w\~\;\:\$\-\+\!\*\?/\=\&\@\#\%]\Z)~~eisg;

			$message = BC($message);
			MakeSmall();
			$message .= qq~ <a href="$rurl\lm-$messid/">$portal[48]</a>~;
		} else { $message = BC($message); }
		$sdate = get_date($messid);
		GetMemberID($posted);
		if($memberid{$posted}{'sn'} eq '') { $userpost = $posted; }
			else { $userpost = $userurl{$posted}; }

		$lastthread .= <<"EOT";
 <tr>
  <td class="win">
   <table cellpadding="0" cellspacing="0" width="100%">
    <tr>
     <td><strong><img src="$images/icons/$micon" class="centerimg" alt="" />&nbsp;&nbsp;<a href="$rurl\lm-$messid/">$messtitle</a></strong></td>
     <td class="right smalltext">$sdate<br />$gtxt{'36'}: $userpost</td>
    </tr>
   </table>
  </td>
 </tr><tr>
  <td class="win2">$message<hr /><a href="$rurl\lm-$messid/">$portal[26]</a> ($replies)</td>
 </tr>
EOT
		++$counter;
	}
	$lastthread .= "</table><br />";
	return($lastthread);
}

sub LoadMemberList {
	fopen(FILE,"$members/List2.txt");
	@list = <FILE>;
	fclose(FILE);
	chomp @list;
	foreach(@list) {
		($un,$t,$posts,$regtime) = split(/\|/,$_);
		push(@maxmem,"$posts|$un");
		push(@newmembers,"$regtime|$un");
	}

	@maxmem = sort{$b <=> $a} @maxmem;
	@newmembers = sort{$b <=> $a} @newmembers;
	$mlistload = 1;
}

sub LastMember {
	if(!$mlistload) { LoadMemberList(); }
	$returnto = <<"EOT";
 <table width="100%" cellpadding="0" cellspacing="1" class="border">
  <tr>
   <td style="padding: 5px" class="titlebg smalltext"><strong>$portal[27]</strong></td>
  </tr><tr>
   <td class="$colorclass[$portalcounter % 2]">
    <table cellpadding="9" cellspacing="1" width="100%">
     <tr>
      <td class="smalltext">
EOT
	$counter = 1;
	for($g = 0; $g < $lastmemcnt; ++$g) {
		$team = '';
		($regged,$member) = split(/\|/,$newmembers[$g]);
		GetMemberID($member);
		$regged = get_date($regged);
		if($member eq '') { next; }
		if($permissions{$membergrp{$member},'team'}) { $team = qq~ <img src="$images/team.gif" alt="$gtxt{'29'}" /> ~; }
		$returnto .= qq~<strong>$counter.</strong>$team $userurl{$member} $portal[28] $regged<br />~;
		++$counter;
	}
	$returnto .= <<"EOT";
     </td>
    </tr>
   </table>
  </td>
 </tr>
</table>
<br />
EOT
	return($returnto);
}

sub Shownews {
	my($shownewstemp,@news,$filetype,$counter);
	($save,$filetype) = @_;
	if($filetype eq '') {
		if($URL{'a'} eq 'headlines' || $URL{'a'} eq 'feed') { $filetype = 'xml'; }
			else { $filetype = 'html'; }
	}

	if($URL{'a'} eq 'lastposts') { LatestThreads(); $shownewstemp .= $lastthread; exit; }
	elsif($URL{'a'} eq 'online') { Online(); exit; }
	elsif($URL{'a'} eq 'latest') { RSSLatestThreads(); }

	if($filetype eq 'xml') {
		if(!$save) { print "Content-type: text/xml\n\n"; }
		if($URL{'b'} eq '') { $title = $mbname; }
			else { $title = $boardnm; }

		$shownewstemp .= <<"EOT";
<?xml version="1.0" encoding="$char"?>
<rss version="2.0"
	xmlns:dc="http://purl.org/dc/elements/1.1/"
	>
 <channel>
  <title>$title</title>
  <link>$rurl</link>
  <generator>http://www.eblah.com</generator>
  <description></description>
  <language>en</language>
EOT
	} else { print "Content-type: text/html\n\n" if !$save; }

	if($URL{'b'} && $URL{'v'} eq 'shownews' && GetMemberAccess($binfo[14])) { $newsboard = $URL{'b'}; }
		elsif($URL{'c'} && $URL{'v'} eq 'shownews') {
			$newsboard = '';
			foreach(@catbase) {
				($t,$boardid) = split(/\|/,$_);
				$catbase{$boardid} = $_;
			}

			foreach(@boardbase) {
				($id) = split("/",$_);
				$board{$id} = $_;
			}

			($name,$boardid,$memgroups,$boardlist,$message,$subcats) = split(/\|/,$catbase{$URL{'c'}});
			if(GetMemberAccess($memgroups)) {
				foreach $bid (split("/",$boardlist)) {
					($t,$t,$t,$t,$t,$t,$t,$t,$t,$t,$binfo[9]) = split("/",$board{$bid});
					if(!GetMemberAccess($binfo[9])) { next; }
					$newsboard .= "$bid,";
				}
				GetSubCats($subcats);
			}
		}

	@open = split(",",$newsboard);
	foreach $openbrd (@open) {
		fopen(FILE,"$boards/$openbrd.msg");
		while($curforumread = <FILE>) {
			chomp $curforumread;
			push(@news,"$curforumread|$_");
		}
		fclose(FILE);
	}
	$counter = 0;

	$newslength = $newslength || 2000;

	$usertxt = $gtxt{'36'}; $commenttxt = $portal[26];

	fopen(FILE,"$templates/News.html");
	@temp = <FILE>;
	fclose(FILE);
	chomp @temp;

	if(!@temp) {
		News();
		$shownewstemp .= $lastthread;
		exit;
	}

	foreach(sort{$b <=> $a} @news) {
		if($counter == $newsshow) { last; }
		($messid,$messtitle,$posted,$date,$replies,$poll,$type,$micon,$date,$t,$curforumread) = split(/\|/,$_);

		($xt1,$xt2) = split("<>",$messtitle);
		if($posted eq '' || $xt2 ne '') { next; }

		fopen(FILE,"$messages/$messid.txt");
		while($temp = <FILE>) {
			($t,$message,$t,$t,$t,$nosmile) = split(/\|/,$temp);
			last;
		}
		fclose(FILE);

		$sdate = get_date($messid,1);
		GetMemberID($posted);
		if($memberid{$posted}{'sn'} eq '') { $userpost = $posted; }
			else { $userpost = $userurl{$posted}; }
		$totalurl = "$rurl\lm-$messid/";

		if($filetype eq 'xml') {
			$message = BC($message);

			if($memberid{$posted}{'sn'} eq '') { $userpost = $posted; }
				else { $userpost = $memberid{$posted}{'sn'}; }

			($s,$m,$h,$day,$month,$year,$wday) = localtime($messid);
			$year += 1900;
			++$month;
			if($h < 10) { $h = "0$h"; }
			if($m < 10) { $m = "0$m"; }
			if($s < 10) { $s = "0$s"; }

			$shownewstemp .= <<"EOT";
  <item>
   <title>$messtitle</title>
   <link>$totalurl</link>
   <comments>$totalurl#num1</comments>
   <description><![CDATA[$message]]></description>
   <pubDate>$sdays[$wday], $day $smonths[$month-1] $year $h:$m:$s</pubDate>
   <dc:creator>$userpost</dc:creator>
  </item>
EOT
		} else {
			if(length($message) > $newslength) {
				$message =~ s~\[table\](.*?)\[\/table\]~$var{'88'}~sgi;
				$message = substr($message,0,$newslength);

				$message =~ s~([^\w\"\=\[\]]|[\n\b]|\A)\\*(\w+://[\w\~\.\;\:\$\-\+\!\*\?/\=\&\@\#\%]+\.[\w\~\;\:\$\-\+\!\*\?/\=\&\@\#\%,.]+[\w\~\;\:\$\-\+\!\*\?/\=\&\@\#\%]\Z)~~eisg;
				$message =~ s~([^\"\=\[\]/\:\.(\://\w+)]|[\n\b]|\A|[\<\n\b\>])\\*(www\.[^\.][\w\~\.\;\:\$\-\+\!\*\?/\=\&\@\#\%]+\.[\w\~\;\:\$\-\+\!\*\?/\=\&\@\#\%\,]+[\w\~\;\:\$\-\+\!\*\?/\=\&\@\#\%]\Z)~~eisg;

				$message = BC($message);
				MakeSmall();
				$message .= qq~<br /><br /><a href="$rurl\lm-$messid/">$portal[48]</a>~;
			} else { $message = BC($message); }
			foreach(@temp) {
				$pdata = $_;
				$pdata =~ s/<blah v="\$(.+?)">/${$1}/gsi;
				$shownewstemp .= "$pdata\n";
			}
		}

		++$counter;
	}
	if($filetype eq 'xml') { $shownewstemp .= " </channel>\n</rss>"; }
	print $shownewstemp if !$save;
	if($save) {
		fopen(FILE,">$templates/Shownews.$filetype");
		print FILE $shownewstemp;
		fclose(FILE);
	}
	exit if !$save;
}

sub GetSubCats {
	my($msubcats,$memgroupsx,@boards);
	$noloop{$_[0]} = 1;
	($name,$boardid,$memgroups,$boardlist,$message,$subcats) = split(/\|/,$catbase{$_[0]});

	if(GetMemberAccess($memgroups) != 0) {
		foreach $bid (split("/",$boardlist)) {
			($t,$t,$t,$t,$t,$t,$t,$t,$t,$t,$binfo[9]) = split("/",$board{$bid});
			if(GetMemberAccess($binfo[9])) { next; }
			$newsboard .= "$bid,";
		}
		foreach $sigh (@subcats) {
			if(!$noloop{$sigh}) { GetSubCats($subcats); }
		}
	}

	return(1);
}

sub Online {
	GetActiveUsers();

	print "Content-type: text/xml\n\n";

	print <<"EOT";
<?xml version="1.0" encoding="$char"?>
<rss version="2.0">
 <channel>
  <title>$mbname</title>
  <link>$rurl</link>
  <generator>http://www.eblah.com</generator>
  <description></description>
  <language>en</language>
  <total members="$memcnt" guests="$gcnt" hide="$hidec"></total>
EOT

	fopen(ACTIVE,"$prefs/Active.txt");
	while(<ACTIVE>) {
		($user,$time) = split(/\|/,$_);

		GetMemberID($user);
		if(($memberid{$user}{'sn'} eq '' || $memberid{$user}{'hideonline'}) && $botsearch{$user} eq '') { next; }

		if($botsearch{$user}) { $user = $botsearch{$user}; $type = "bot"; }
			else { $url = "$rurl\lv-memberpanel/a-view/u-$user"; $user = $memberid{$user}{'sn'}; $type = "mem"; }

		($s,$m,$h,$day,$month,$year,$wday) = localtime($time);
		$year += 1900;
		++$month;
		if($h < 10) { $h = "0$h"; }
		if($m < 10) { $m = "0$m"; }
		if($s < 10) { $s = "0$s"; }

		print <<"EOT";
  <item>
   <title>$user</title>
   <link>$url</link>
   <type>$type</type>
   <time>$sdays[$wday], $day $smonths[$month-1] $year $h:$m:$s</time>
  </item>
EOT
	}
	fclose(ACTIVE);

	print <<"EOT";
 </channel>
</rss>
EOT
	exit;
}
1;