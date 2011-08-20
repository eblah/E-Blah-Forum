#############################################
# E-Blah Bulletin Board Systems        2008 #
#############################################
# Copyright (c) 2001 - 2008 E-Blah.         #
#############################################

CoreLoad('Print',1);

$nosmile = 1;

sub PrintDisplay {
	if($URL{'s'} eq '') {
		fopen(FILE,"$boards/$URL{'b'}.msg");
		while (<FILE>) {
			chomp $_;
			($__,$___,$user,$t,$t,$poll) = split(/\|/,$_);
			if($__ eq "$URL{'m'}") { $fnd = 1; $title = $___; last; }
		}
		fclose(FILE);
		if(!$fnd) { error($printtxt[1]); }
	} else {
		fopen(FILE,"$members/$username.pm");
		@pm = <FILE>;
		fclose(FILE);
		chomp @pm;
		if($URL{'f'} eq '') { $URL{'f'} = 1; }
		foreach(sort {$b cmp $a} @pm) {
			($med,$pmid,$title,$tof,$message,$ip) = split(/\|/,$_);
			if($med eq $URL{'f'}) {
				$message =~ s~{REPLY: (.+?)}(.+?){/REPLY}~~eisg;
				if($URL{'m'} eq $pmid) { push(@messages,"$tof|$message|||$pmid"); $found = 1; last; }
				elsif($URL{'m'} eq 'all') { push(@messages,"$tof|$message|||$pmid|$title"); }
			}
		}
		if($found != 1 && $URL{'m'} ne 'all') { error($printtxt[14]); }

		$link = "s-pm/f-$URL{'f'}/";
	}
	if($URL{'a'} && $URL{'s'} ne '') { PrintDisplay2(1); }
	if($URL{'a'} || $URL{'s'} eq '') { PrintDisplay2(); }
	$title = $printtxt[9];
	header();
	$ebout .= <<"EOT";
<table width="500" cellpadding="4" cellspacing="1" class="border">
 <tr>
  <td class="titlebg"><strong>$title</strong></td>
 </tr><tr>
  <td class="catbg"><strong><a href="$surl\lv-print/m-$URL{'m'}/a-2/$link">$printtxt[10]</a></strong></td>
 </tr><tr>
  <td class="win">
   <table>
    <tr>
     <td class="smalltext">$printtxt[11]</td>
    </tr>
   </table>
  </td>
 </tr><tr>
  <td class="catbg"><strong><a href="$surl\lv-print/m-$URL{'m'}/a-1/$link" rel="nofollow">$printtxt[12]</a></strong></td>
 </tr><tr>
  <td class="win">
   <table>
    <tr>
     <td class="smalltext">$printtxt[13]</td>
    </tr>
   </table>
  </td>
 </tr>
</table>
EOT
	footer();
	exit;
}

sub PrintDisplay2 {
	$pmprinter = $_[0];
	if(!$pmprinter) {
		fopen(FILE,"$messages/$URL{'m'}.txt") || error("$printtxt[2] $title ($URL{'m'}.txt).");
		@messages = <FILE>;
		fclose(FILE);
		$fullmessagelink = qq~<a href="$rurl\lm-$URL{'m'}/$link">$printtxt[15]</a> ~;
	} else {
		if($URL{'m'} eq 'all') { $title = $printtxt[17]; }
		$boardnm = $printtxt[16];
	}

	$thistime = time;

	$date_time = get_date($thistime,1);
	$title = CensorList($title);
	$title2 = lc($title);
	$title2 =~ s/ /_/gis;

	if($URL{'a'} == 1) { $type = qq~download/html;\nContent-Disposition: attachment; filename="$title2.html"~; }
		else { $type = 'text/html;'; }

	GetMemberID($user);
	$fuser = $memberid{$user}{'sn'};
	$ebout .= qq~Content-Type: $type\n\n~;
	$ebout .= <<"EOT";
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
     "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<title>$title - $printtxt[3]</title>

<style type="text/css">
.printtitle {
	padding: 10px;
	border-top: 1px solid #000000;
	border-bottom: 1px solid #000000;
	background-color: #EEEEEE;
	font-size: 13px;
	margin-bottom: 4px;
}

h3 {
	font-size: 18px;
	padding-top: 5px;
	margin-bottom: 15px;
}

.olink {
	font-size     : 9px;
	margin-bottom: 10px;
}

.printwarning {
	padding: 5px;
	border-top: 1px solid #BF3737;
	border-bottom: 1px solid #BF3737;
	background-color: #FFBBBB;
	font-size: 10px;
	text-align: center;
}

.posthead {
	padding: 8px;
	background-color: #F6F6F6;
	font-size: 10px;
	font-weight: normal;
}

.message {
	padding: 5px;
	padding-left: 10px;
	background-color: #FFFFFF;
	font-size: 10px;
	font-weight: normal;
}

.envelope {
	padding: 5px;
	border-bottom: 1px solid #CCCCCC;
	margin-bottom: 5px;
}

.generation {
	padding: 10px;
	background-color: #F5F6BE;
	font-size: 10px;
	border: 1px #636363 solid;
}

.copyright {
	padding: 5px;
	padding-left: 10px;
	background-color: #FFFFFF;
	font-size: 9px;
	font-weight: normal;
	text-align: center;
	margin-top: 10px;
}

a, a:link, a:active, a:visited,a:hover {
	text-decoration: underline;
	color          : #36383B;
	font-family    : Verdana, Helvetica;
	font-weight    : bold;
}

a:hover { color: #1A1016; }

body, table, td { font-family: Verdana; font-size: 9px; }
</style>

<meta http-equiv="Content-Type" content="text/html; charset=$char" />
</head>

<body>
<h3>$printtxt[3]</h3>
<div class="olink">$fullmessagelink<a href="$surl\lv-print/a-1/m-$URL{'m'}/$link" rel="nofollow">$printtxt[12].</a></div>
<div class="printtitle"><strong>$mbname &nbsp;/ &nbsp;$boardnm &nbsp;/ &nbsp;$title</strong></div>
EOT
	if($poll) {
		$ebout .= <<"EOT";
<div class="printwarning"><strong>$printtxt[6]</strong></div>
EOT
	}
	$reply = 0;
	foreach (@messages) {
		chomp $_;
		($poster,$message,$t,$email,$timeposted,$pmtitle) = split(/\|/,$_);
		GetMemberID($poster);
		if($memberid{$poster}{'sn'} eq '') { $postedby = "$poster ($printtxt[7])"; }
			else { $postedby = $memberid{$poster}{'sn'}; }
		$oldtime = get_date($timeposted,1);
		$message = BC($message);
		if($reply > 0) { $replys = qq~; <strong>$gtxt{'37'}:</strong> $reply~; }
		if($URL{'m'} eq 'all') { $replys = "; <strong>$printtxt[18]:</strong> $pmtitle"; }
		$ebout .= <<"EOT";
<div class="posthead"><strong>$gtxt{'19'}:</strong> $postedby, $oldtime$replys</div>
<div class="envelope">
<div class="message">$message</div>
</div>
EOT
		++$reply;
	}
	$ebout .= <<"EOT";
<div class="generation"><strong>$printtxt[8]:</strong> $date_time</div>
<div class="copyright">$copyright</div>
</body>
</html>
EOT
	print $ebout;
	exit;
}
1;
