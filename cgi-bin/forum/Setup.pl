#!/usr/bin/perl

############################################################
# E-Blah Bulletin Board Systems                       2012 #
############################################################
# Software Version : E-Blah Setup -- Version 4             #
# Setup Project    : May 2005 by Justin <justin@eblah.com> #
# Distrobuted by   : http://www.eblah.com                  #
# License          : http://www.eblah.com/license.php      #
############################################################
# Copyright (c) 2005 - 2012 E-Blah                         #
############################################################

# Global version information:
$versionnum  = '10.3.7';                      # For the upgrade ...
$eblahsetupv = $coreversion = 2;
$version     = 'E-Blah '.$versionnum;
$scriptname  = 'Setup.pl';
$blahname    = 'Blah.pl';
$interals    = 'Setup100.5'; # Keep things over 100 (generally sub-ver + 1)

$members{'Administrator',$username} = 1;
use CGI::Carp 'fatalsToBrowser';
use Fcntl ':flock';

{
	UFS();
	$copyright = qq~Copyright &#169; 2001-2008 <a href="http://www.eblah.com" target="_blank">E-Blah</a>.~;

	InstallConfig() if(!SetupLoad('./Settings.pl',1) || !SetupLoad("$code/QuickCore.pl",1));

	$languagep = "English";

	$language = "$languages/$languagep";

	open(FILE,"$prefs/Version.txt");
	$oldversionnum = <FILE>;
	close(FILE);

	# Upgrade lock clear ...
	if(!-e("$messages/Mail/database.mail")) { unlink("$prefs/Setup.lock"); } # This forum will be upgraded to P9.2

	if(-e("$prefs/$interals.lock") && $URL{'step'} ne '3') { inst_error("This forum has already been installed, please remove the $scriptname file from your server."); }
		elsif($URL{'step'} eq '3') { Step3(); }

	if($URL{'a'} && $URL{'step'} eq '1') { Step1U(); }
	elsif($URL{'step'} eq '1') { Step1(); }
	elsif($URL{'step'} eq '2') { Step2(); }
		else { Welcome(); }
}

sub InstallConfig {
	$tempreturn =~ s/, \Z//g;

	header('Configuration Error');
	print <<"EOT";
<div class="win2 header">
 Configuration Issues ...
</div>
<div class="blockquote">
 Setup has determined that you must manually edit the paths to Settings.pl or other core files. If you need help, <a href="http://www.eblah.com/forum/">contact E-Blah technical support</a>.<br /><br />
 The following may help you figure out what your paths are:
 <div class="blockquote">
  <strong>Document Root:</strong> $ENV{'DOCUMENT_ROOT'}<br />
  <strong>Script name:</strong> $0<br />
  <strong>File(s) Not Loaded:</strong> $tempreturn<br />
  <strong>Reason for failure:</strong> $!
 </div>
</div>
EOT
	footer();
}

sub SetupLoad {
	eval { require($_[0]) };
	if($@) {
		if($_[1]) { $tempreturn .= $_[0].', '; return(0); }
		inst_error(qq~Fatal Error in loading: $_[0]<br><br>$@~);
	} else { return(1); }
}

sub UFS {
	my($query);
	@url = split(/\//,$ENV{'QUERY_STRING'});
	foreach (@url) {
		($action,$actiondo) = split(/-/,$_);
		$URL{$action} = $actiondo;
	}
	read(STDIN, my $temp, $ENV{'CONTENT_LENGTH'});
	@pairs = split(/&/,$temp);

	foreach (@pairs) {
		($key,$content) = split(/=/,$_);
		$content =~ tr/+/ /;
		$content =~ s/%(..)/pack("c",hex($1))/ge;
		$key =~ tr/+/ /;
		$key =~ s/%(..)/pack("c",hex($1))/ge;
		chomp($content);
		$FORM{$key} = $content;
	}
}

sub inst_error {
	header('Fatal Error');
	print <<"EOT";
<div class="win2 header">
 There was an error installing or upgrading your forum ...
</div>
<div class="blockquote">
 $_[0]
</div>
EOT
	footer();
}

# This isn't needed, but is called by Themes.pl when loaded
sub CoreLoad { 1; }

sub Welcome {
	header('Welcome');
	print <<"EOT";
<div class="win2 header">
 Welcome to the E-Blah Install / Upgrade Script
</div>
<div class="blockquote">
 Welcome to E-Blah 10 Setup. We are very pleased that you have chosen E-Blah as your forum software, and hope that you will enjoy it for years to come!
 <br /><br />
 This script will install or upgrade your forum to the latest version of E-Blah. If you are new to E-Blah, this script will help you with your first time installation. If you are upgrading from an older version of E-Blah, you will enjoy how easy this upgrade will be.  If you are using a version of E-Blah prior to Platinum 8.x, please <a href="http://www.eblah.com/forum/m-1107906919/">click here</a>. This installation should only take a few minutes of your time, and you will then be able to configuring your forum and then on your way to creating a community!
 <br /><br />
 Before you continue, please make sure you have read the pre-installation instructions carefully. It should be found in the main package under the filename of Readme.html.
</div>

<div class="win2 header">
 E-Blah 10 Release Notes
</div>
<div class="blockquote">
 <strong>XHTML Validation</strong> &nbsp; E-Blah is now supporting the XHTML 1.1 Strict web standard. If you are upgrading, there are additional CSS properties you will need to add to your main template. More information on this can be found in the documentation.<br /><br />
 <strong>Akismet Spam Protection</strong> &nbsp; Your forum can now be protected from unwanted spam with Akismet. To use this, you must enable it in the Administrator Center, under Settings.<br /><br />
 <strong>Portal</strong> &nbsp; The portal has been rewritten for the most part. Your previous Portal Setup will be removed once you upgrade. You will need to readd the modules you were using after the upgrade is completed.<br /><br />
 <strong>CAPTCHA</strong> &nbsp; E-Blah can now tell if a user trying to register is human or not. For information as to how to use this, <a href="http://www.eblah.com/forum/m-1140405457/">read this thread</a>.
</div>

<div class="win2 header">
 Before Continuing
</div>
<div class="blockquote">
 <strong>Please</strong> be sure you have uploaded <strong>all</strong> files in the documentation <strong>before</strong> continuing (Code and Languages, for example).  If you do not, you may have issues upgrading or installing E-Blah.
</div>

<div class="win2 header">
 Setup Options
</div>
<div class="blockquote" id="setup-options">
EOT

	if(-e("$prefs/Ranks.txt") || -e("$prefs/Ranks2.txt")) { print qq~<a href="$scriptname?step-1/a-upgrade/">Upgrade your Forum to $version >></a>~; }
		else {
			print qq~<a href="$scriptname?step-1/">Install a New Forum >></a>~;
		}

	print <<"EOT";
</div>
EOT
	footer();
}

sub is_admin { return(1); }

sub ConvertEnd {
	header('Convert Files');
	print <<"EOT";
<script language="JavaScript" type="text/javascript">
<!-- <![CDATA[
var req;
function EditMessage(url,messageid,levelnum2) {
	EditMessage2(url);

	function EditMessage2(url,messageid,levelnum2) {
		req = false;
		if(window.XMLHttpRequest) { // Non IE browsers
			try { req = new XMLHttpRequest(encoding="utf-8"); }
			catch(e) { req = false; }
		} else if(window.ActiveXObject) { // IE
			try { req = new ActiveXObject("Msxml2.XMLHTTP"); }
			catch(e) {
				try { req = new ActiveXObject("Microsoft.XMLHTTP"); }
				catch(e) { req = false; }
			}
		}

		if(req) {
			req.onreadystatechange = processReqChange;
			req.open("POST", url, true); // Use POST so we don't get CACHED items!
			req.send('TEMP');
		} else { alert('Cannot upgrade, please refresh.'); }
	}

	function processReqChange() {
		if(req.readyState != 4) { document.getElementById(messageid).innerHTML = '<img src="$images/converting.gif" style="float: left; padding-right: 5px;" alt="" /> Please wait ...'; }
		if(req.readyState == 4) {
			if (req.status == 200) {
				document.getElementById(messageid).innerHTML = req.responseText;

				if(levelnum2 == 6) {
					document.getElementById('conversiondot').style.display = "none";
					document.getElementById('convertedid').style.display = "";
				}
				if(levelnum2 < 6) { Conversioooon(levelnum2); }

			} else {
				document.getElementById('conversiondot').style.display = "none";
				document.getElementById('conversionstats').style.display = "none";
				document.getElementById('conversionerror').style.display = "";
			}
		}
	}
}

// ]]> -->
</script>

<div id="conversionstats">
 <div class="win2 header">
  Current Forum Conversion Status ...
 </div>
 <div class="blockquote">
  <span id="one"></span>
  <span id="two"></span>
  <span id="three"></span>
  <span id="four"></span>
  <span id="five"></span>
 </div>
</div>

<div id="conversiondot">
 <div class="win2 header">
  Please wait ...
 </div>
 <div class="blockquote">
  Your forum is being upgraded, this could take a few minutes ...<br /><br /><strong>DO NOT REFRESH OR LEAVE THIS PAGE UNTIL UPGRADE IS COMPLETE</strong>
 </div>
</div>

<div style="display: none" id="convertedid">
 <div class="win2 header">
  Upgrade Finished ...
 </div>
 <div class="blockquote" id="setup-options">
  This forum has been upgrade successfully!<br /><br />
  You <strong>should not</strong> have to run this upgrade script again.<br /><br />
  <a href="$scriptname?step-3/a-upgrade/">Delete Setup Files and go to Your Forum</a>
 </div>
</div>

<div style="display: none" id="conversionerror">
 <div class="win2 header">
  <img src="$images/warning_sm.png" style="float: left; padding-right: 5px;" alt="" /> Fatal Error
 </div>
 <div class="blockquote">
  Your forum cannot be upgraded at this time.</strong>
 </div>
</div>

<script language="JavaScript" type="text/javascript">
<!-- <![CDATA[

function Conversioooon(levelnum) {
	if(levelnum == 1) { therid = 'one'; }
	if(levelnum == 2) { therid = 'two'; }
	if(levelnum == 3) { therid = 'three'; }
	if(levelnum == 4) { therid = 'four'; }
	if(levelnum == 5) { therid = 'five'; }
	levelnum2 = 1 + (levelnum*1);
	EditMessage('$scriptname?step-1/a-upgrade/level-'+ levelnum + '/',therid,levelnum2);
}
Conversioooon('1');

// ]]> -->
</script>
EOT
	footer();
	exit;
}

sub Step1U {
	$level = $URL{'level'};
	if($level eq '') { ConvertEnd(); }

	# To be safe, we're going to chmod the current directories so that no problems come up.
	chmod 0777, $prefs,$boards,$members,$messages,$boards,$uploaddir,$templates;
	chmod 0666, "$root/Settings.pl";
	$converted = '';

	{ # The braces just help in formatting ...
		print "Content-type: text/html\n\n";

		if(!$oldversionnum) { # New versions will actual be better for these upgrades!
			if($level == 1) {
				if(!-e("$prefs/Ranks2.txt")) { PrePlatinumNine(); }
				if(!-e("$messages/Mail/database.mail")) { MailDatabaseUpgrade(); }

				if($converted eq '') { exit; } # Already Converted ...
					else { print $converted; exit; }
			}

			if($level == 2) {
				if(!-e("$prefs/Setup95.lock")) {
					MemberUpgrade(); # Shouldn't matter if it runs over and over
					NewPermissions();
				}

				if($converted eq '') { exit; } # Already Converted ...
					else { print $converted; exit; }
			}

			if($level == 3) {
				if(!-e("$prefs/Events2.txt")) { CalendarUpgrade(); }
				if(!-e("$members/MaxMember.count")) { RebuildAllMembers(); }

				if($converted eq '') { exit; } # Already Converted ...
					else { print $converted; exit; }
			}
		} elsif($level < 4) { exit; } # Already converted ...

		if($level == 4) {
			if($oldversionnum < 9.81) { RebuildMemberDatabase(); }
			if($oldversionnum <= 9.82) { RebuildMessageDatabase(); }
			if($oldversionnum < 9.84) { CreateMessageIcons(); }

			if($converted eq '') { exit; }
				else { print $converted; exit; }
		}

		if($level == 5) {
			# Run this always to ensure that it is valid ... NEVER REMOVE THIS!!!!!
			RebuildMemList();

			# For good measure, let's also rebuild the boards database ....
			$URL{'p'} = 'setup';
			$URL{'a'} = 'remove'; # We need it to return ...
			Repop();

			print "<li>Rebuilt member list ...</li>";

			CloseSetup();

			print "<li>Closed setup file ...</li>";

			exit;
		}
	}

	sub CreateMessageIcons {
		$tempwrite = <<"EOT";
|lamp.png|Lamp
|question.png|Question
|news.png|News
|thumbup.png|Thumb Up
|thumbdown.png|Thumb Down
|ban.png|X
|smiley.png|Smiley
|angry.png|Angry
|lol.png|Laughing Out Loud
|open_thread.png|Folder
|warning.png|Warning
EOT
		fopen(FILE,">$prefs/MessageIcons.txt");
		print FILE $tempwrite;
		fclose(FILE);

		fopen(FILE,"$boards/bdindex.db");
		@boardbase = <FILE>;
		fclose(FILE);
		chomp @boardbase;

		foreach $board (@boardbase) {
			($open) = split("/",$board);

			fopen(MESS,"$boards/$open.msg");
			@messages = <MESS>;
			fclose(MESS);
			chomp @messages;

			$newdata = '';

			foreach $messagedb (@messages) {
				($t1,$t2,$t3,$t4,$t5,$t6,$t7,$t8,$t9,$t10) = split(/\|/,$messagedb);
				$newdata .= "$t1|$t2|$t3|$t4|$t5|$t6|$t7|$t8.png|$t9|$t10\n";
			}

			fopen(MESS,">$boards/$open.msg");
			print MESS $newdata;
			fclose(MESS);
		}

		$converted .= "<li>Created Message Icons Database (9.84) ...</li>";
		$converted .= "<li>Converted Message Icons (9.84) ...</li>";
	}

	sub RebuildMessageDatabase {
		my(@boardbase,$t,$id,$boardid);

		fopen(FILE,"$boards/bdindex.db");
		@boardbase = <FILE>;
		fclose(FILE);
		chomp @boardbase;

		foreach(@boardbase) {
			($boardid) = split("/",$_);

			fopen(FILE,"$boards/$boardid.msg");
			while($t = <FILE>) {
				chomp $t;
				($id) = split(/\|/,$t);
				$mdatabase .= "$id|$_\n";
			}
			fclose(FILE);
		}

		fopen(FILE,">$boards/Messages.db");
		print FILE $mdatabase;
		fclose(FILE);

		$converted .= "<li>Created message database (9.82) ...</li>";
	}

	sub RebuildMemberDatabase {
		my(@printdata,$item,$itemvalue,%addtoID,@printuser);
		RebuildMemListPreP981(); # Sync ...

		fopen(LIST,"$members/List.txt");
		while($list = <LIST>) {
			chomp $list;

			fopen(DATA,"$members/$list.dat");
			@printdata = <DATA>;
			fclose(DATA);
			chomp @printdata;

			@printuser = ();
			%addtoID   = ();

			%addtoID = (
				'password'     =>  $printdata[0],
				'sn'           =>  $printdata[1],
				'email'        =>  $printdata[2],
				'posts'        =>  $printdata[3],
				'admintxt'     =>  $printdata[4],
				'avatar'       =>  $printdata[5],
				'personaltxt'  =>  $printdata[6],
				'sex'          =>  $printdata[7],
				'icq'          =>  $printdata[8],
				'aim'          =>  $printdata[9],
				'msn'          => $printdata[10],
				'sig'          => $printdata[11],
				'hidemail'     => $printdata[12],
				'registered'   => $printdata[14],
				'timezone'     => $printdata[15],
				'dob'          => $printdata[16],
				'dateformat'   => $printdata[17],
				'hideonline'   => $printdata[18],
				'sitename'     => $printdata[19],
				'siteurl'      => $printdata[20],
				'location'     => $printdata[21],
				'timeformat'   => $printdata[22],
				'status'       => $printdata[23],
				'validation'   => $printdata[24],
				'ml'           => $printdata[25],
				'theme'        => $printdata[26],
				'yim'          => $printdata[27],
				'lastactive'   => $printdata[28],
				'hidesum'      => $printdata[29],
				'notify'       => $printdata[30],
				'dst'          => $printdata[31],
				'avatarupload' => $printdata[32],
				'shownewonly'  => $printdata[33],
				'lng'          => $printdata[34],
				'avatarsize'   => $printdata[35],
				'showsig'      => $printdata[36],
				'ownavatar'    => $printdata[37],
				'pmdisable'    => $printdata[38],
				'censor'       => $printdata[39],
				'blockedusers' => $printdata[40],
				'pmpopup'      => $printdata[41],
				'rank'         => $printdata[42],
				'rep'          => $printdata[43],
				'forgotpass'   => $printdata[44],
				'rndsid'       => $printdata[45],
				'md5upgrade'   => $printdata[46]
			);

			while(($item,$itemvalue) = each(%addtoID)) {
				if($itemvalue eq '') { next; }
				push(@printuser,"$item = |$itemvalue|");
			}

			fopen(FILE,">$members/$list.dat");
			foreach(@printuser) { print FILE "$_\n"; }
			fclose(FILE);
		}
		fclose(LIST);

		$converted .= "<li>Rebuilt member database (9.81) ...</li>";
		unlink("$root/Settings_Default.pl");
	}

	sub RebuildAllMembers {
		RebuildMemListPreP981(); # Make sure this is in sync before we destroy the old database ...

		$counter = 0;
		fopen(FILE,"$members/List2.txt");
		@templist = <FILE>;
		fclose(FILE);
		chomp @templist;

		foreach(@templist) {
			($t1,$t2,$t3,$t4,$t5,$t6,$t7) = split(/\|/,$_);

			++$counter;

			while(-e("$members/$counter.dat")) { # ... lame ...
				++$counter;
			}

			$username{$t1} = $counter;

			rename("$members/$t1.dat"  ,"$members/$counter.dat");
			rename("$members/$t1.vlog" ,"$members/$counter.vlog");
			rename("$members/$t1.lo"   ,"$members/$counter.lo");
			rename("$members/$t1.log"  ,"$members/$counter.log");
			rename("$members/$t1.pm"   ,"$members/$counter.pm");
			rename("$members/$t1.prefs","$members/$counter.prefs");
			rename("$members/$t1.msg"  ,"$members/$counter.msg");
			rename("$members/$t1.cal"  ,"$members/$counter.cal");


			# We rebuild the member list at the end, so that's not needed really ...
		}

		foreach(@templist) {
			($t1) = split(/\|/,$_);

			if(-e("$members/$username{$t1}.pm")) {
				fopen(FILE,"$members/$username{$t1}.pm");
				@pms = <FILE>;
				fclose(FILE);
				chomp @pms;

				fopen(FILE2,">$members/$username{$t1}.pm");
				foreach $pms (@pms) {
					($t1,$t2,$t3,$t4,$t5,$t6,$t7,$t8,$t9,$t10,$t11) = split(/\|/,$pms);

					if($username{$t4} ne '') { $t4 = $username{$t4}; }

					print FILE2 "$t1|$t2|$t3|$t4|$t5|$t6|$t7|$t8|$t9|$t10|$t11\n";
				}
				fclose(FILE2);
			}

			if(-e("$members/$username{$t1}.vlog")) { # Vote logs ...
				fopen(FILE,"$members/$username{$t1}.vlog");
				@vlog = <FILE>;
				fclose(FILE);
				chomp @vlog;

				fopen(FILE2,">$members/$username{$t1}.vlog");
				foreach $vlogs (@vlog) {
					($t1,$t2,$t3,$t4) = split(/\|/,$vlogs);

					if($username{$t1} ne '') { $t1 = $username{$t1}; }

					print FILE2 "$t1|$t2|$t3|$t4\n";
				}
				fclose(FILE2);
			}
		}

		fopen(FILE,">$members/MaxMember.count");
		print FILE "$counter\n";
		fclose(FILE);

		# This will be a pain ... open all boards and messages and change usernames ... :X
		fopen(FILE,"$boards/bdindex.db");
		@boardbase = <FILE>;
		fclose(FILE);
		chomp @boardbase;

		foreach $board (@boardbase) { # Moderators aren't used as much, so we won't search for them
			($open) = split("/",$board);
			fopen(MAIL,"$boards/$open.mail");
			@mail = <MAIL>;
			fclose(MAIL);
			chomp @mail;

			fopen(MAIL,">$boards/$open.mail");
			foreach(@mail) { print MAIL "$username{$_}\n"; }
			fclose(FILE);

			fopen(MESS,"$boards/$open.msg");
			@messages = <MESS>;
			fclose(MESS);
			chomp @messages;

			@openms = (); # Clear the old message db

			foreach $messagedb (@messages) {
				($t1,$t2,$t3,$t4,$t5,$t6,$t7,$t8,$t9,$t10) = split(/\|/,$messagedb);

				fopen(FILE,"$messages/$t1.txt");
				@message = <FILE>;
				fclose(FILE);
				chomp @message;

				fopen(FILE,">$messages/$t1.txt");
				foreach $messagefile (@message) {
					($p1,$p2,$p3,$p4,$p5,$p6,$p7,$p8,$p9,$p10,$p11) = split(/\|/,$messagefile);
					if($username{$p1} ne '') { $p1 = $username{$p1}; }

					if($p11 ne '') {
						$p12 = '';
						foreach $edits (split(">",$p11)) {
							($c1,$c2,$c3) = split('/',$edits);
							if($username{$c2} ne '') { $c2 = $username{$c2}; }
							$p12 .= "$c1/$c2/$c3>";
						}
					}

					print FILE "$p1|$p2|$p3|$p4|$p5|$p6|$p7|$p8|$p9|$p10|$p12\n";
				}
				fclose(FILE);

				if($username{$t3} ne '') { $t3 = $username{$t3}; }
				if($username{$t10} ne '') { $t10 = $username{$t10}; }

				if(-e("$messages/$t1.polled")) {
					fopen(XYZ,"$messages/$t1.polled");
					@polled = <FILE>;
					fclose(XYZ);
					chomp @polled;

					fopen(XYZ,"$messages/$t1.polled");
					foreach $pdata (@polled) {
						($oldies,$timer) = split(/\|/,$pdata);
						if($username{$oldies} ne '') { $oldies = $username{$oldies}; }
						print XYZ "$oldies|$timer\n";
					}
					fclose(XYZ);
				}

				push(@openms,"$t1|$t2|$t3|$t4|$t5|$t6|$t7|$t8|$t9|$t10");
			}

			# The huge DB ... written ...
			fopen(MESS,">$boards/$open.msg");
			foreach(@openms) { print MESS "$_\n"; }
			fclose(MESS);
		}

		fopen(FILE,"$prefs/Ranks2.txt");
		@ranks = <FILE>;
		fclose(FILE);
		chomp @ranks;

		fopen(RANKS,">$prefs/Ranks2.txt");
		foreach $data (@ranks) {
			if($data =~ /(.+?) = \((.+?)\)/) {
				$thespec = $1;
				$spl = '';
				foreach $split (split(",",$2)) { # It's only a shadow!  It's only a shadow!
					if($username{$split} ne '') { $split = $username{$split}; }
					$spl .= "$split,";
				}

				$spl =~ s/,\Z//g;
				print RANKS "$thespec = ($spl)\n";
			} else {
				print RANKS "$data\n";
			}
		}
		fclose(RANKS);

		fopen(FILE,"$prefs/Events2.txt");
		@events = <FILE>;
		fclose(FILE);
		chomp @events;

		fopen(FILE2,">$prefs/Events2.txt");
		foreach $theevents (@events) {
			($t1,$t2,$t3,$t4,$t5,$t6,$t7,$t8,$t9,$t10,$t11) = split(/\|/,$theevents);

			if($username{$t1} ne '') { $t1 = $username{$t1}; }

			print FILE2 "$t1|$t2|$t3|$t4|$t5|$t6|$t7|$t8|$t9|$t10|$t11\n";
		}
		fclose(FILE2);

		fopen(FILE,"$prefs/AdminLog.txt");
		@adminlog = <FILE>;
		fclose(FILE);
		chomp @adminlog;

		fopen(FILE2,">$prefs/AdminLog.txt");
		foreach $adminlog (@adminlog) {
			($t1,$t2,$t3) = split(/\|/,$adminlog);

			if($username{$t2} ne '') { $t2 = $username{$t2}; }

			print FILE2 "$t1|$t2|$t3\n";
		}
		fclose(FILE2);

		fopen(FILE,"$prefs/Moderator.log");
		@modlog = <FILE>;
		fclose(FILE);
		chomp @modlog;

		fopen(FILE2,">$prefs/Moderator.log");
		foreach $modlog (@modlog) {
			($t1,$t2,$t3,$t4,$t5,$t6,$t7,$t8) = split(/\|/,$modlog);

			if($username{$t2} ne '') { $t2 = $username{$t2}; }

			print FILE2 "$t1|$t2|$t3|$t4|$t5|$t6|$t7|$t8\n";
		}
		fclose(FILE2);

		# Files NOT converted: IpLog.txt, Moderators List, PM's
		$converted .= "<li>Rebuilt member database (9.8) ...</li>";
	}

	sub loaduserOLD {
		my($user) = $_[0];   # DO NOT ADD LOADUSER TO MY STATEMENT!

		my $i = 0;
		fopen(LOADUSER,"$members/$user.dat") || return(0);
		while($luserdata = <LOADUSER>) {
			chomp $luserdata;
			$userset{$user}->[$i] = $luserdata;
			++$i;
		}
		fclose(LOADUSER);
	}

	sub RebuildMemListPreP981 {
		my($memlistc,$memcnt,$lucnt,$luser,$memlistc2);

		opendir(DIR,"$members/");
		@list = readdir(DIR);
		closedir(DIR);
		$memcnt = 0;
		foreach(sort {$a <=> $b} @list) {
			if($_ =~ s/.dat\Z//) {
				loaduserOLD($_);
				if($userset{$_}->[14] > $lucnt) {
					$luser = $_;
					$lucnt = $userset{$_}->[14];
				}
				if($userset{$_}->[1]) { ++$memcnt; $memlistc .= "$_\n"; $memlistc2 .= "$_|$userset{$_}->[1]|$userset{$_}->[3]|$userset{$_}->[14]|$userset{$_}->[16]|$userset{$_}->[2]|$userset{$_}->[43]\n"; }
			}
		}
		fopen(LIST,"+>$members/List.txt");
		print LIST "$memlistc";
		fclose(LIST);
		fopen(LIST,"+>$members/List2.txt");
		print LIST "$memlistc2";
		fclose(LIST);
		fopen(FILE,"+>$members/LastMem.txt");
		print FILE "$luser\n$memcnt";
		fclose(FILE);

		$converted .= "<li>Rebuilt the OLD members database ($versionnum) ...</li>";
	}

	sub RebuildMemList {
		$URL{'v'} = 'memberpanel';
		require("$code/Admin1.pl");
		require("$code/Load.pl");
		Remem();
		$converted .= "<li>Rebuilt the members list ($versionnum) ...</li>";
	}

	sub CalendarUpgrade {
		fopen(FILE,"$prefs/Events.txt");
		@files = <FILE>;
		fclose(FILE);
		chomp @files;

		fopen(FILE,">$prefs/Events2.txt");
		foreach(@files) {
			($id,$start,$title,$desc,$owner,$spandays,$spancolor) = split(/\|/,$_);
			if($spandays > 1) { $end = $start+($spandays*86400); }
				else { $end = ''; }
			if($owner eq '') { $owner = 'admin'; }
			print FILE "$owner|guest,validating,member|$id|$start|$end|||$spancolor|$title|$desc|/\n";
		}
		fclose(FILE);

		$converted = "<li>Converted calendar events to new events format (9.8) ...</li>";
	}

	# New Permissions Setup ........... (needs finishing) <-- no wonder it never worked fully ... *sigh*
	sub NewPermissions {
		fopen(FILE,"$boards/bdindex.db");
		@file = <FILE>;
		fclose(FILE);
		chomp @file;
		$newfile = '';
		foreach(@file) {
			$mgroups = '';
			($t1,$t2,$t3,$t4,$t5,$t6,$t7,$t8,$t9,$t10,$mgroups2,$t12,$t13,$t14,$t15) = split('/',$_);
			if($t5 eq '') { $t5 = 'guest,validating,member'; }
			if($t6 eq '') { $t6 = 'guest,validating,member'; }
			if(!$t7) { $t7 = 'guest,validating,member'; } else { $t7 = ''; }
			if(!$t13) { $t13 = 'guest,validating,member'; } else { $t13 = ''; }
			if($mgroups2 eq '') { $mgroups2 = 'guest,validating,member'; }
			$mgroups =~ s/,\Z//g;
			$newfile .= "$t1/$t2/$t3/$t4/$t5/$t6/$t7/$t8/$t9/$t10/$mgroups2/$t12/$t13/$t14/$t15/guest,validating,member\n";
		}
		fopen(FILE,">$boards/bdindex.db");
		print FILE $newfile;
		fclose(FILE);

		fopen(FILE,"$boards/bdscats.db");
		@file = <FILE>;
		fclose(FILE);
		chomp @file;
		$newfile = '';
		foreach(@file) {
			$mgroups = '';
			($t1,$t2,$mgroups2,$t4,$t5,$t6) = split(/\|/,$_);
			if($mgroups2 eq '') { $mgroups2 = 'guest,validating,member'; }
			$newfile .= "$t1|$t2|$mgroups2|$t4|$t5|$t6\n";
		}
		fopen(FILE,">$boards/bdscats.db");
		print FILE $newfile;
		fclose(FILE);

		$converted .= "<li>Rebuilt permissions (9.5) ...</li>";
	}

	sub MemberUpgrade { # P9.3/5 Updates
		fopen(FILE,"$members/List.txt");
		@memlist = <FILE>;
		fclose(FILE);
		chomp @memlist;
		foreach $memname (@memlist) {
			if($memname =~ /-/) {
				$memname1 = $memname;
				$memname =~ s/-/_/g;
				if(-e("$members/$memname.dat")) { $memname .= time; }

				rename("$members/$memname1.dat","$members/$memname.dat");
				rename("$members/$memname1.vlog","$members/$memname.vlog");
				rename("$members/$memname1.lo","$members/$memname.lo");
				rename("$members/$memname1.log","$members/$memname.log");
				rename("$members/$memname1.pm","$members/$memname.pm");
				rename("$members/$memname1.prefs","$members/$memname.prefs");
				rename("$members/$memname1.msg","$members/$memname.msg");
			}
		}

		$converted .= "<li>Restructured the members list (9.5) ...</li>";
	}

	sub MailDatabaseUpgrade { # P9.2 Updates
		opendir(DIR,"$messages/Mail/");
		while($show = readdir(DIR)) {
			if($show =~ /\.mail/) { push(@messages,$show); }
		}
		closedir(DIR);
		fopen(DB,">$messages/Mail/database.mail");
		foreach(@messages) {
			fopen(FILE,"$messages/Mail/$_");
			@file = <FILE>;
			fclose(FILE);
			chomp @file;
			$strang = '';
			foreach $junks (@file) {
				$strang .= "$junks,";
			}
			unlink("$messages/Mail/$_");

			$crao = $_;
			$crao =~ s/\.mail\Z//g;
			$strang =~ s/,\Z//g;
			if($strang eq '') { next; }
			print DB "$crao|$strang\n";
		}
		fclose(DB);

		$converted .= "<li>Rebuilt the mail database (9.2) ...</li>";
	}

	# Pre-P9 upgrades
	sub PrePlatinumNine { # This ONLY checks for this file, may cause issues with alpha upgraders ... haha ...
		use File::Copy;
		if(!-e("$prefs/ThemesList.txt")) {
			mkdir("$templates/convert",0777);
			fopen(FILE,">$templates/convert/theme.dat");
			print FILE "name = 'Converted Theme'";
			fclose(FILE);

			copy("$templates/template.html","$templates/convert/template.html");
			copy("$templates/template.css","$templates/convert/template.css");
			copy("$templates/admintemplate.css","$templates/convert/admintemplate.css");
			copy("$templates/Smilies.html","$templates/convert/Smilies.html");
		}
		if(!-e("$messages/Mail")) {
			mkdir("$messages/Mail/",0777);

			opendir(DIR,"$messages");
			while($show = readdir(DIR)) {
				if($show =~ /\.mail/) { copy("$messages/$_","$messages/Mail/$_"); }
			}
			closedir(DIR);

			opendir(DIR,"$messages/Mail/");
			while($show = readdir(DIR)) {
				if($show =~ /\.mail/) { push(@messages,$show); }
			}
			closedir(DIR);
			fopen(DB,">$messages/Mail/database.mail");
			foreach(@messages) {
				fopen(FILE,"$messages/Mail/$_");
				@file = <FILE>;
				fclose(FILE);
				chomp @file;
				$strang = '';
				foreach $junks (@file) {
					$strang .= "$junks,";
				}
				unlink("$messages/Mail/$_");

				$crao = $_;
				$crao =~ s/\.mail\Z//g;
				$strang =~ s/,\Z//g;
				if($strang eq '') { next; }
				print DB "$crao|$strang\n";
			}
			fclose(DB);
		}
		if(!-e("$prefs/Ranks2.txt")) {
			$converted .= "<li>Converted Member Group permissions to version 2 (Ranks.txt file deleted) ...</li>";
			$converted .= "<li>Cleaned up previous member group settings from member files ...</li>";

			fopen(FILE,"$prefs/Ranks.txt") || inst_error("Could not find the old member group permissions! This forum may have already been upgraded, or has not yet been installed.");
			@ranks = <FILE>;
			fclose(FILE);
			chomp @ranks;

			foreach(@ranks) {
				($name,$reparse) = split(/\|/,$_);
				($t,$t,$t,$t,$t,$t,$t,$t,$t,$admin) = split(',',$reparse);
				$admingrp{$name} = $admin;
			}

			$counter = 0;

			fopen(FILE,"$members/List.txt");
			@list = <FILE>;
			fclose(FILE);
			chomp @list;

			foreach $open (@list) {
				fopen(FILE2,"$members/$open.dat");
				@trash = <FILE2>;
				fclose(FILE);
				chomp @trash;

				fopen(FILE2,">$members/$open.dat");
				foreach(@trash) {
					++$counter;
					if($counter == 5) { # Clear the old member group ;)
						if($admingrp{$_}) { $grp = 'Administrator'; }
							else { $grp = $_; }
						$members{$_} .= "$open,";
						print FILE2 "\n";
						next;
					}
					print FILE2 "$_\n";
				}
				fclose(FILE2);
				$counter = 0;
			}

			$count2 = 0;
			foreach(@ranks) {
				++$counter;
				($name,$reparse) = split(/\|/,$_);
				if($counter == 1) {
					($color,$star,$starcount) = split(',',$reparse);
					$members{'Administrator'} =~ s/,\Z//g;
					$newfile = <<"EOT";
Administrator => {
name = '$name'
star = '$star'
starcount = '$starcount'
team = '1'
color = '$color'
level = '1'
manager = ($members{'Administrator'})
members = ($members{'Administrator'})
}\n
EOT
					$newgroup{'Administrator'} = 'Administrator';
				} elsif($counter == 7) {
					($team,$star,$starcount) = split(',',$reparse);
					$newfile .= <<"EOT";
Moderators => {
name = '$name'
star = '$star'
starcount = '$starcount'
team = '$team'
level = '1'
}\n
EOT
				} else {
					($ip,$mod,$st,$m,$pro,$star,$team,$color,$cal,$admin,$count,$starcount) = split(',',$reparse);
					++$count2;

					if($count eq '' && $counter < 7) { next; } # These groups were disabled.

					$newfile .= "$count2 => {\n";
					$name2 = $name;
					$name =~ s/\'/&#8217;/g;

					$newfile .= "name = '$name'\n";
					$newfile .= $color ? "color = '$color'\n" : '';
					$newfile .= $team ? "team = '$team'\n" : '';

					$newfile .= $star ? "star = '$star'\n" : '';
					$newfile .= $starcount ? "starcount = '$starcount'\n" : '';
					$newfile .= $count ? "pcount = '$count'\n" : '';

					# Permissions
					if($counter > 7) {
						$newgroup{$name} = $count2;
						$newfile .= $ip ? "ip = '$ip'\n" : '';
						$newfile .= $mod ? "moderate = '$mod'\n" : '';
						$newfile .= $st ? "sticky = '$st'\n" : '';
						$newfile .= $m ? "modify = '$m'\n" : '';
						$newfile .= $pro ? "profile = '$pro'\n" : '';
						$newfile .= $cal ? "cal = '$cal'\n" : '';
					}

					# Finish group setup with members allowed
					if($count eq '') {
						$newfile .= "level = '1'\n";

						$members{$name2} =~ s/,\Z//g;
						$newfile .= "manager = ()\n";
						$newfile .= "members = ($members{$name2})\n";
					}
					$newfile .= "}\n\n";
				}
			}

			fopen(FILE,">$prefs/Ranks2.txt");
			print FILE $newfile;
			fclose(FILE);

			fopen(FILE,"$boards/bdindex.db");
			@file = <FILE>;
			fclose(FILE);
			chomp @file;
			$newfile = '';
			foreach(@file) {
				$mgroups = '';
				($t1,$t2,$t3,$t4,$t5,$t6,$t7,$t8,$t9,$t10,$mgroups2,$t12,$t13,$t14) = split('/',$_);
				foreach(split(',',$mgroups2)) { $mgroups .= "$newgroup{$_},"; }
				$mgroups =~ s/,\Z//g;
				$newfile .= "$t1/$t2/$t3/$t4///$t7/$t8/$t9/$t10/$mgroups/$t12/$t13/$t14\n";
			}
			fopen(FILE,">$boards/bdindex.db");
			print FILE $newfile;
			fclose(FILE);

			fopen(FILE,"$boards/bdscats.db");
			@file = <FILE>;
			fclose(FILE);
			chomp @file;
			$newfile = '';
			foreach(@file) {
				$mgroups = '';
				($t1,$t2,$mgroups2,$t4,$t5,$t6) = split(/\|/,$_);
				foreach(split(',',$mgroups2)) { $mgroups .= "$newgroup{$_},"; }
				$mgroups =~ s/,\Z//g;
				$newfile .= "$t1|$t2|$mgroups|$t4|$t5|$t6\n";
			}
			fopen(FILE,">$boards/bdscats.db");
			print FILE $newfile;
			fclose(FILE);

			unlink("$prefs/Ranks.txt");
			$converted .= "<li>Boards Database rebuilt ...</li>";
		}

		# Search for converted theme(s)
		require("$code/Themes.pl");
		ThemeResearch();
		$converted .= "<li>Convert old default template to new format ...</li>";
	}
}

sub CloseSetup { # Be smart: close this install ... =)
	open(FILE,">$prefs/Version.txt");
	print FILE "$versionnum";
	close(FILE);
}

sub Step1 {
	$nodir .= "<li><span style=\"width: 150px\">Prefs</span><b> Currently set to:</b> $prefs</li>" if(!-e("$prefs"));
	$nodir .= "<li><span style=\"width: 150px\">Messages</span><b> Currently set to:</b> $messages</li>" if(!-e("$messages"));
	$nodir .= "<li><span style=\"width: 150px\">Members</span><b> Currently set to:</b> $members</li>" if(!-e("$members"));
	$nodir .= "<li><span style=\"width: 150px\">Boards</span><b> Currently set to:</b> $boards</li>" if(!-e("$boards"));
	$nodir .= "<li><span style=\"width: 150px\">Languages</span><b> Currently set to:</b> $languages</li>" if(!-e("$languages"));
	$nodir .= "<li><span style=\"width: 150px\">Avatars</span><b> Currently set to:</b> $avdir</li>" if(!-e("$avdir"));
	$nodir .= "<li><span style=\"width: 150px\">uploads</span><b> Currently set to:</b> $uploaddir</li>" if(!-e("$uploaddir"));
	$nodir .= "<li><span style=\"width: 150px\">template</span><b> Currently set to:</b> $templates</li>" if(!-e("$templates"));

	if($nodir) {
		$nodir =~ s/, \Z//g;
		$nodir = <<"EOT";
 <div class="badinstall">
  <strong class="large">WARNING!</strong><br />
  Your forum <i>may</i> not work properly if you continue. Setup recommends editing the path to directories in Settings.pl and then refreshing this page until this message disappears. There was a problem verifying that the following directories exist:<br />
  <div class="blockquote">
   $nodir
  </div>
  The following may help you figure out what your paths are:
  <div class="blockquote">
   <strong>Document Root:</strong> $ENV{'DOCUMENT_ROOT'}<br />
   <strong>Script name:</strong> $0
  </div>
  Please note that not <i>all</i> server report the above information correctly.<br /><br />
  <strong>For the quickest support on the <a href="http://www.eblah.com/forum/">E-Blah Support Forum</a>, PLEASE copy and past <i>everything</i> in this red box.</strong>
 </div>
EOT
		$fataldie = qq~<strong class="badcolor">Your install may not work or complete correctly (see error above).</strong><br /><br />~;
	}
		else {
			$nodir = <<"EOT";
 <div class="goodinstall">
  <strong class="large">Directory Success!</strong><br />
  Setup has verified that all the directories appear to exist on the server (they may not be writeable though). Setup will <i>attempt</i> to chmod these directories before continuing (to make them writeable). However, it is recommended that you chmod the directories and files as shown in the install documentation before continuing. Again, setup will <i>attempt</i> to chmod these directories for you; <strong>however</strong>, there is no guarantee that it will work.
 </div>
EOT
		}

	if(-e("$prefs/Ranks.txt")) { inst_error('This forum needs to be upgraded, not installed.'); }
	if(-e("$prefs/Ranks2.txt")) { inst_error('This forum appears to have already been installed.'); }

	$path = $ENV{'PATH_INFO'};
	$path =~ s/(Setup.pl|Setup.cgi)//g;

	header('Administrator Information');
	print <<"EOT";
<div class="win2 header">
 Administrator Information
</div>
<div class="blockquote">
 $nodir
 <br />
 Setup needs the following information before it can continue ...
</div>

<form action="$scriptname?step-2/" method="post">
 <table cellpadding="6" cellspacing="1" class="border" width="750">
  <tr>
   <td class="catbg" colspan="2"><b>Basic Forum Information</b></td>
  </tr><tr>
   <td class="win2">
    <table cellpadding="6" cellspacing="0" width="100%">
     <tr>
      <td width="250"><b>Forum Name:</b></td>
      <td width="250"><input type="text" name="forumname" value="$ENV{'SERVER_NAME'} Forum" class="textinput" size="40"></td>
     </tr><tr>
      <td width="250"><b>Forum Cookie Prefix:</b></td>
      <td width="250"><input type="text" name="cookpre" value="eblah" class="textinput" size="10"></td>
     </tr><tr>
      <td width="250"><b>Full URL (DIR) Path to Blah.pl:</b></td>
      <td width="250"><input type="text" name="realurl" value="http://$ENV{'SERVER_NAME'}$path" class="textinput" size="40"></td>
     </tr><tr>
      <td colspan="2" class="win smalltext">This is the <b>best guess</b> and may not be correct! Look over this path and correct it if need be.</td>
     </tr>
    </table>
   </td>
  </tr><tr>
   <td class="catbg" colspan="2"><b>Basic Administrator Account</b></td>
  </tr><tr>
  <td class="win">
   <table cellpadding="6" cellspacing="0" width="100%">
    <tr>
     <td><b>Administrator screen name:</b></td>
      <td><input type="text" name="screenname" value="Administrator" size="30" class="textinput"></td>
     </tr>
      <td colspan="2" class="win2 smalltext">Please note that you can use <b>ONLY</b> the screen name you enter here to login to the forums after setup has been completed.</td>
     </tr><tr>
      <td width="250"><b>Password:</b></td>
      <td width="250"><input type="password" name="pw" value="admin" maxlength="8" class="textinput"></td>
     </tr><tr>
      <td><b>Password (confirm):</b></td>
      <td><input type="password" name="cpw" value="admin" maxlength="8" class="textinput"></td>
     </tr><tr>
      <td colspan="2" class="win2 smalltext">The default password is <b>admin</b>. <b>DO NOT</b> keep this the default. You can change this after the forum has been installed.</td>
     </tr><tr>
      <td><b>Administrator e-mail address:</b></td>
      <td><input type="text" name="email" value="admin\@mysite.com" size="30" class="textinput"></td>
     </tr>
    </table>
   </td>
  </tr><tr>
   <td class="catbg" colspan="2"><b>Default Forum Theme</b></td>
  </tr><tr>
   <td class="win">
    <table cellpadding="6" cellspacing="0" width="100%">
     <tr>
      <td colspan="3" class="win2 smalltext">Please select the theme you would like to use on your forum. The theme can be changed to another one or modified after E-Blah has been installed. You can also find more themes at <a href="http://www.blahdocs.com">BlahDocs.com</a>.</td>
     </tr><tr>
       <td style="text-align: center" colspan="3"><img src="$templatesu/X2/preview.gif" alt="" /><br /><input type="radio" name="theme" value="X2" checked="checked" /> X2</td>
     </tr>
    </table>
   </td>
  </tr><tr>
   <td class="catbg" colspan="2"><b>Completion</b></td>
  </tr><tr>
    <td class="win2">
    <table cellpadding="6" cellspacing="0" width="100%">
     <tr>
      <td colspan="2" class="win smalltext">After you click "Save and Finish Install", E-Blah will be installed and files will be copied onto your server by this Setup script. Please only click the button <b>once</b>. The setup will only take a second, after which you will be able to access your forum.</td>
     </tr><tr>
      <td colspan="2" align="center"><div width="100%" style="padding: 5px;">$fataldie<input type="submit" value="Save and Finish Install" style="width: 100%" class="button"></div></td>
     </tr>
    </table>
   </td>
  </tr>
 </table>
</form>
<br />

<div class="win2 header">
 Technical Support
</div>
<div class="blockquote">
 If you have any problems or questions about installing E-Blah and would like assistance, please <a href="http://www.eblah.com/forum/">go to the E-Blah Technical Support Forums</a>.
</div>
EOT
	footer();
}

sub Step2 {
	if(-e("$prefs/Ranks.txt")) { inst_error('This forum needs to be upgraded, not installed.'); }
	if(-e("$prefs/Ranks2.txt")) { inst_error('This forum appears to have already been installed.'); }

	inst_error("Invalid information in form submitted") if($FORM{'screenname'} !~ /\A[0-9A-Za-z%+,-\.@†^_ &nbsp;]+\Z/ || $FORM{'screenname'} eq '' || length($FORM{'screenname'}) > 30);
	inst_error("Invalid information in form submitted") if($FORM{'pw'} eq '' || length($FORM{'pw'}) > 8);
	inst_error("Invalid information in form submitted") if($FORM{'cpw'} eq '');
	inst_error("Invalid information in form submitted") if($FORM{'email'} eq '' || length($FORM{'email'}) > 60 || $FORM{'email'} !~ /\A([0-9A-Za-z\._\-]{1,})@([0-9A-Za-z\._\-]{1,})+\.([0-9A-Za-z\._\-]{1,})+\Z/);
	inst_error("Invalid information in form submitted") if($FORM{'cpw'} ne $FORM{'pw'});

	$email = lc($FORM{'email'});

	@prefslist   = ('.htaccess','Active.txt','AdminLog.txt','Attachments.txt','BMail.txt','Censor.txt','ClickLog.txt','Events.txt','IpLog.txt','ips.txt','MaxLog.txt','News.html','News.txt','Ranks2.txt','Refer.txt','ReportPM.txt','RTemp.txt','smiley.txt','Smilies.html','ThemesList.txt','MessageIcons.txt','stopwords.txt');
	@boardslist  = ('.htaccess','bdindex.db','bdscats.db','gb.msg','gb.ino','Stick.txt','Messages.db');
	@memberslist = ('.htaccess','1.dat','1.log','LastMem.txt','List.txt','List2.txt');
	# Get the list of files to write to durring install ...
	WriteFiles();

	# Chmod the directories ...
	chmod 0777, $prefs,$boards,$members,$messages,$boards,$uploaddir,$templates;
	chmod 0666, "$root/Settings.pl";
	chmod 0755, "$root/Blah.pl"; # This might help some people ...

	foreach(@prefslist) {
		fopen(FILE,">$prefs/$_") || inst_error('Cannot write to /Prefs, please check your Settings.pl file and try again.');
		print FILE $files{"$_"};
		fclose(FILE);
	}
	foreach(@boardslist) {
		fopen(FILE,">$boards/$_") || inst_error('Cannot write to /Boards, please check your Settings.pl file and try again.');
		print FILE $files{"$_"};
		fclose(FILE);
	}
	foreach(@memberslist) {
		fopen(FILE,">$members/$_") || inst_error('Cannot write to /Members, please check your Settings.pl file and try again.');
		print FILE $files{"$_"};
		fclose(FILE);
	}

	$possible = '123456789abcdefghijklmnopqrstuvwxyzABCDFGJL^(@&!)(*^)(#*_!=MNPQRSTWXY23456789';
	$temp1 = 0;
	$captcha_random = '';
	while($temp1 < 20) { $captcha_random .= substr($possible, int(rand(length($possible))), 1); ++$temp1; }

	fopen(SETTINGS,">$root/Settings.pl");
	$savesettings = <<"EOT";
####################################################
# E-Blah Bulliten Board Systems               2006 #
####################################################
# This file was created by the setup.              #
#                                                  #
# YOU SHOULD NEVER EDIT THIS FILE BY HAND          #
####################################################

\$bversion = 2;      # POST-SETUP Version

####### Directories Sets #######
\$root = "$root";
\$code = "$code";
\$boards = "$boards";
\$prefs = "$prefs";
\$members = "$members";
\$messages = "$messages";
\$images = "$images";
\$buttons = "$buttons";
\$simages = "$simages";
\$avsurl = "$avsurl";
\$avdir = "$avdir";
\$realurl = "$FORM{'realurl'}";
\$bdocsdir = "$bdocsdir";
\$languages = "$languages";
\$templates = "$templates";
\$templatesu = "$templatesu";
\$modsdir = "$modsdir";
\$bdocsdir2 = "$bdocsdir2";
\$regto = qq*$FORM{'screenname'}*;
\$eadmin = q*$email*;
\$cookpre = qq*$FORM{'cookpre'}*;
\$mailuse = 1;
\$smaill = "/usr/sbin/sendmail";
\$emailsig = q*This e-mail was sent via E-Blah.*;
\$maintancer = qq~This board is being upgraded.~;
\$uploaddir = "$uploaddir";
\$uploadurl = "$uploadurl";
\$maxsize = "1";
\$maxsize2 = ".25";
\$upbc = 1;
\$noguestp = 1;
\$al = 1;
\$whereis = 1;
\$showmove = 1;
\$apic = 1;
\$hmail = 1;
\$slpoller = 1;
\$BCSmile = 1;
\$BCLoad = 1;
\$showreg = 1;
\$maxsig = "500";
\$maxmess = 15;
\$maxdis = 30;
\$mbname = q*$FORM{'forumname'}*;
\$picheight = "100";
\$picwidth = "100";
\$btod = 1;
\$amar = 1;
\$sauser = 1;
\$mmpp = 25;
\$iptimeout = 5;
\$vhtdmax = 50;
\$htdmax = 25;
\$totalpp = 10;
\$showdes = 1;
\$showtheme = 1;
\$sview = 1;
\$showactive = 1;
\$logactive = 1;
\$reversesum = 1;
\$languagep = "English";
\$nocomma = ',';
\$polltop = 1;
\$pollops = "7";
\$quickreply = 1;
\$gmaxsmils = 200;
\$maxmesslth = 50000;
\$maxsumc = "40";
\$upevents = 7;
\$disablesn = 1;
\$disabledel = 1;
\$eclick = 0;
\$uextlog = 0;
\$kelog = 0;
\$logip = 0;
\$logcnt = "60";
\$logdays = 365;
\$activeuserslog = 15;
\$newsshow = 5;
\$newslength = 200;
\$ensids = 0;
\$menutext = 2;
\$indextext = 0;
\$posttext = 0;
\$gdisable = 1;
\$captcha_random = "$captcha_random";
EOT
	$savesettings =~ s~\\~/~sig; # Get rid of {x}:\ with Win32 systems
	print SETTINGS $savesettings;
	fclose(SETTINGS);
	unlink("$root/Settings_Default.pl");

	CloseSetup();

	header('Installation Complete');
	print <<"EOT";
<div class="win2 header">
 Items Completed
</div>
<div class="blockquote">
 <li>Prepared and created your user login ...</li>
 <li>Create the E-Blah database ...</li>
 <li>Created files needed to initialize E-Blah ...</li>
</div>

<div class="win2 header">
 Install Complete
</div>
<div class="blockquote" id="setup-options">
 <strong>Congratulations!</strong><br /><br />
 Your forum has been installed successfully.<br /><br />
 You <b>do not</b> need to run this install script again. You should remove Setup.pl from your server before you run E-Blah.<br /><br />
 <a href="$scriptname?step-3/a-upgrade/">Delete Setup Files and go to Your Forum</a>
</div>
EOT
	footer();
}

sub Step3 {
	chmod 0777, "$root/$scriptname";
	unlink("$root/$scriptname") || inst_error('Could not remove setup files from the server. Please remove Setup.pl manually.');
	header('Setup Complete');
	print <<"EOT";
<div class="win2 header">
 Removal Successful ...
</div>
<div class="blockquote" id="setup-options">
 $scriptname has been removed from the server. It is recommended that you refresh this page to ensure it was, indeed, deleted successfully.  If it was not, you should remove it via FTP before using your forum.<br /><br />
 <a href="./$blahname">Go to your Forum</a>
</div>
EOT
	footer();
}

sub header {
	($title) = $_[0];

	print "Content-type: text/html; charset=utf-8\n\n";
	print <<"EOT";
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN"
"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
<head>

<title>$title</title>

<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />

<!--[if lt IE 7]>
<script defer type="text/javascript" src="/blahdocs/pngfix.js"></script>
<![endif]-->
<style type="text/css">
/* Global Table Settings */
body, table, td {
	font-family: Verdana;
	font-size  : 11px;
	color      : #1D1F22;
	margin     : 0px;
	line-height: 1.5;

}

body {
	background-color: #F1F1F1;
}

.catbg {
	font-family     : Verdana, Helvetica;
	font-size       : 12px;
	color           : #000000;
	font-weight     : bold;
}

/* Colors */
.catbg {
	font-family: Verdana, Helvetica, Arial;
	font-size  : 12px;
	color      : #000;
	font-weight: bold;
	background: #E0EDFF;
}

.win {
	background: #FCFDFF;
}

.win2 {
	background: #F9FBFF;
}

.header {
	background: #C6E0FF;
	font-weight: bold;
	font-size: 12px;
	padding: 10px;
}

.border {
	border: 2px solid #4385DB;
	background-color: #4385DB;
}

.smalltext { /* Small font text size, can also change color, etc */
	font-weight: normal;
	font-size  : 9px;
	line-height: 1.5;
}

/* Links */
a, a:link, a:active, a:visited {
	text-decoration: none;
	color          : #36383B;
	font-family    : Verdana, Helvetica;
	font-weight    : bold;
}

a:hover {
	text-decoration: none;
	color          : #1A1016;
	font-family    : Verdana, Helvetica;
	font-weight    : bold;
}

/* Forms */
.upload, input, textarea, select { /* .checkboxinput also allowed */
	color           : #000;
	background-color: #F2F6FF;
	font-family     : Verdana, Helvetica, Times;
	font-size       : 10px;
	border          : 1px #4385DB solid;
	border-width    : 1px;
}

textarea {
	padding    : 3px;
	line-height: 130%;
}

input {
	text-indent : 2px;
	margin: 0px;
	padding: 7px;
}

form, input {
	margin-top: 0px;
}

form {
	margin-bottom: 0px;
}

.blockquote {
	margin      : 20px;
	margin-left : 40px;
	margin-right: 40px;
	text-align  : justify;
}

#setup-options a, #setup-options a:link, #setup-options a:active, #setup-options a:visited {
	text-decoration : none;
	text-align      : center;

	color           : #36383B;

	font-family     : Verdana, Helvetica;
	background-color: #EDEDED;
	font-weight     : normal;
	padding         : 10px;
	border          : 1px solid #4385DB;
	width           : 100%;
	
	font-size: 18px;
}

#setup-options a:hover {
	text-decoration : none;
	text-align      : center;
	color           : #36383B;
	font-family     : Verdana, Helvetica;
	background-color: #EDEDED;
	font-weight     : bold;
	padding         : 10px;
	border          : 1px solid #4385DB;
	width           : 100%;

}

.badinstall {
	background-color: #FFF5F5;
	padding         : 5px;
	border          : 1px solid #293B2A;
	color           : #FF2723;
}

.badcolor { color: #FF2723; }

.goodinstall {
	background-color: #DEE8DF;
	padding         : 5px;
	border          : 1px solid #293B2A;
	color           : #293B2A;
}

.large {
	font-size: 18px;
}

/* Default Theme Layout */
#container {
	width: 95%;
	margin: auto;
	padding: 0;
	border: 3px solid #FFBF00;
	margin-top: 0;
	border-top: 0;
	margin-bottom: 10px;
	background: #FFF;
}

#copyright {
	width: 95%;
	margin: auto;
}

#title {
	background-color: #FFF;
	background: url('/blahdocs/template/X2/images/top_grad.gif');

	font-size: 30px;
	font-weight: bold;
	text-align: left;
	padding: 25px;
}

#menu-container {
	border-top: 1px solid #FFBF00;
	border-bottom: 1px solid #FFBF00;
	background: #FFFBF7;
}

#content {
	clear: both;
	padding: 10px;
}

#user-info {
	float: right;
	text-align: left;
	font-size: 11px;
	font-weight: normal;
	background: #FFFBF7;
	padding: 12px;
	border: 1px dotted #FFBF00;
	border-top: 0;
	border-right: 0;
}

/* Global Table Settings */
body, table, td {
	font-family: Verdana, Helvetica, Arial;
	font-size  : 11px;
	line-height: 1.3;
	color      : #1D1F22;
}

body {
	background-color: #F1F1F1;
	margin          : 0;
	text-align      : center;
}

table {
	margin-left : auto;
	margin-right: auto;
}

img { border: 0px; }
</style>

</head>

<body>
<div id="container">
	<div id="user-info">
		 $version Install Sub-system
	</div>
	<div id="title">
		$title
	</div>

	<div id="menu-container">
		<table cellpadding="10" cellspacing="0"><tr><td>E-Blah Install and Upgrade System</td></tr></table>
	</div>

	<div id="content">
		<table width="100%" cellpadding="4" cellspacing="1" class="border"><tr><td class="win">
EOT
}

sub footer {
	print <<"EOT";
	</td></tr></table>
	</div>
</div>

<div id="copyright" class="smalltext">
	<span style="float: left">$copyright</span>
	<span style="float: right"><a href="http://validator.w3.org/check/referer" onclick="target='_blank';"><img src="/blahdocs/images/xhtml.png" alt="Valid XHTML" title="Valid XHTML" /></a> <a href="http://jigsaw.w3.org/css-validator/check/referer" onclick="target='_blank';"><img src="/blahdocs/images/css.png" alt="Valid CSS" title="Valid CSS" /></a></span><br /><br />
</div>
</body>
</html>
EOT
	exit;
}

sub WriteFiles {
	$time = time;

	# Prefs DIR
	$files{'Ranks2.txt'} = <<"EOT";
Administrator => {
name = 'Administrator Group'
level = '1'
star = 'stype1.png'
starcount = '5'
color = 'red'
team = '1'
manager = (1)
members = (1)
}

Moderators => {
name = 'Board Moderator'
level = '1'
star = 'stype2.png'
starcount = '5'
team = '1'
}

1 => {
name = 'Maximum Member'
star = 'stype3.png'
starcount = '5'
pcount = '500'
}

2 => {
name = 'Big Member'
star = 'stype3.png'
starcount = '4'
pcount = '200'
}

3 => {
name = 'Medium Member'
star = 'stype3.png'
starcount = '3'
pcount = '100'
}

4 => {
name = 'Minimum Member'
star = 'stype3.png'
starcount = '2'
pcount = '50'
}

5 => {
name = 'Baby Member'
star = 'stype3.png'
starcount = '1'
pcount = '-1'
}
EOT
	$files{'Censor.txt'} = <<"EOT";
ass|a**
bitch|b****
fuck|f***
pussy|girl private
pussie|girl private
pussies|girls privates
vagina|girl private
dick|private
punkass|punka**
shit|mess
asshole|a**hole
fucker|f***er
nigger|black person
nigga|black person
dike|d**e
fag|f**
faggot|f*g**t
EOT
	$files{'News.html'} = <<"EOT";
<table cellpadding="4" cellspacing="1" width="100%" bgcolor="<blah v="$border">">
 <tr>
  <td bgcolor="<blah v="$win1">">
   <table cellpadding="0" cellspacing="0" width="100%">
    <tr>
     <td><font size="2"><b><img src="<blah v="$images">/<blah v="$micon">.gif">  <a href="<blah v="$totalurl">"><blah v="$messtitle"></b></font></td>
     <td align="right"><font size="1"><blah v="$sdate"><br><blah v="$usertxt">: <blah v="$userpost"></font></td>
    </tr>
   </table>
  </td>
 </tr><tr>
  <td bgcolor="<blah v="$win2">"><font size="1"><blah v="$message"><hr color="<blah v="$border">" class="hr" size="1"><a href="<blah v="$totalurl">"><blah v="$commenttxt"></a> (<blah v="$replies">)</font></td>
 </tr>
</table><br>
EOT
	$files{'RTemp.txt'} = <<"EOT";
Although the moderators and administrator of this forum try their best to keep this forum free of any offensive content, there may be small, isolated incidents in which it is posted, and you as a user, accesses it. While we will try to remove such content before it is accessed by you or other users, it is impossible for us to keep track on each message posted on this forum at every moment of the day. If such content is posted, we will either edit or remove the post, and the appropriate action will be taken towards the user. You, therefore, acknowledge that all material posted on these forums express the views and opinions of the user which made the post and not the administrators, moderators, or system administrator (unless the posts are made by these people); therefore we cannot, and will not be held liable for such content that is posted on these forums.<br /><br />Upon registering, you agree to never use this forum for any vulgar, false, sexually oriented, threatening, obscene, abusive, hateful, libelous, or anything that violates ANY acceptable laws; and you also agree to never hack, or attempt to hack into any area of this forum. You also agree never to post any copyrighted material, which you do not expressly own the copyright to, or that you do not have the authorization to use. Advertisements, spam (or useless information posted often), solicitation, and chain letters ARE NOT allowed on this forum. Failure to abide by these terms will subject your account to an immediate and permanent banning from our forum, and, depending on the severity of the incident, we may contact your internet service provider (ISP). For this reason, your IP address is logged each time you post a message, login or logout of the forum and each click is logged for a certain amount of time. This information will be expressly used to assist us if there are any attempts to hack into certain areas of this forum and may be used to contact your ISP upon breaking this agreement.<br /><br />We agree to never sell or disclose any private information that you submit to us. Once you have successfully registered, you will be given a public profile, which allows everyone to see the various information that you submit to us; however, you are not required to disclose any of this information. You will be allowed to privatize certain information (such as your e-mail address), and you are not obligated to provide us with any personal information, which includes but is not limited to your gender, birth date, and name. While we agree never to sell any information, you provide to us, we will not be held responsible for any information that may be compromised by someone whom may hack into your account. It is highly recommended you use a password that is longer than six (6) characters and is a combination of letters and numbers. If your account has been hacked into, notify the system administrator immediately and we will look further into the matter, and adequate punishment will be given.<br /><br />This forum system uses two methods of logging in, cookies and session identification (SID). If you use cookies to login, the forum will save your username, encrypted password, and board passwords to your computer in the form of a &quot;Cookie&quot;. The other method, session identification, will store your current session on this server using your IP address, username, encrypted password, and any board passwords you may use while using your session. If you use session identification, you will be logged out after three (3) hours of inactivity.<br /><br />By clicking register below, you agree to be bound by these terms and conditions as long as you hold this username and failure to do so may result in severe consequences.
EOT
	if($FORM{'theme'} eq '') { $FORM{'theme'} = 'X'; }
	$THEME{$FORM{'theme'}} = 1;
	$files{'ThemesList.txt'} = <<"EOT";
X2|$THEME{'X2'}
EOT
	$files{'Smilies.html'} = <<"EOT";
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
     "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title><blah v="$title"></title>
<link rel="stylesheet" type="text/css" href="<blah v="$templatesu">/<blah v="$dtheme">/template.css" />
</head>
<body>
<blah main>
<br />
<font size="1">
<blah v="$copyright"><br />
</font>
</body>
</html>
EOT

	# Boards DIR
	$files{'bdindex.db'} = <<"EOT";
gb/Chit chat about anything.//General Discussion/guest,validating,member/member,guest,validating/guest,validating,member////guest,member,validating//guest,member,validating///validating,guest,member/
EOT
	$files{'bdscats.db'} = <<"EOT";
General Boards|gc|member,guest,validating|gb
EOT

	# Members DIR
	$files{'1.dat'} = <<"EOT";
password = |$FORM{'pw'}|
sn = |$FORM{'screenname'}|
email = |$email|
posts = |0|
registered = |$time|
timezone = |0|
dateformat = |0|
timeformat = |0|
lastactive = |$time|
EOT
	$files{'LastMem.txt'} = <<"EOT";
1
1
EOT
	$files{'List.txt'} = "1\n";
	$files{'List2.txt'} = "1|$FORM{'screenname'}|0|$time||$email|\n";
	$files{'.htaccess'} = "deny from all\n";

	$files{'MessageIcons.txt'} = <<"EOT";
|lamp.png|Lamp
|question.png|Question
|news.png|News
|thumbup.png|Thumb Up
|thumbdown.png|Thumb Down
|ban.png|X
|smiley.png|Smiley
|angry.png|Angry
|lol.png|Laughing Out Loud
|open_thread.png|Folder
|warning.png|Warning
EOT

$files{'stopwords.txt'} = <<"EOT";
a
able
about
above
according
accordingly
across
actually
after
afterwards
again
against
ain't
all
allow
allows
almost
alone
along
already
also
although
always
am
among
amongst
an
and
another
any
anybody
anyhow
anyone
anything
anyway
anyways
anywhere
apart
appear
appreciate
appropriate
are
aren't
around
as
aside
ask
asking
associated
at
available
away
awfully
be
became
because
become
becomes
becoming
been
before
beforehand
behind
being
believe
below
beside
besides
best
better
between
beyond
both
brief
but
by
c'mon
c's
came
can
can't
cannot
cant
cause
causes
certain
certainly
changes
clearly
co
com
come
comes
concerning
consequently
consider
considering
contain
containing
contains
corresponding
could
couldn't
course
currently
definitely
described
despite
did
didn't
different
do
does
doesn't
doing
don't
done
down
downwards
during
each
edu
eg
eight
either
else
elsewhere
enough
entirely
especially
et
etc
even
ever
every
everybody
everyone
everything
everywhere
ex
exactly
example
except
far
few
fifth
first
five
followed
following
follows
for
former
formerly
forth
four
from
further
furthermore
get
gets
getting
given
gives
go
goes
going
gone
got
gotten
greetings
had
hadn't
happens
hardly
has
hasn't
have
haven't
having
he
he's
hello
help
hence
her
here
here's
hereafter
hereby
herein
hereupon
hers
herself
hi
him
himself
his
hither
hopefully
how
howbeit
however
i'd
i'll
i'm
i've
ie
if
ignored
immediate
in
inasmuch
inc
indeed
indicate
indicated
indicates
inner
insofar
instead
into
inward
is
isn't
it
it'd
it'll
it's
its
itself
just
keep
keeps
kept
know
knows
known
last
lately
later
latter
latterly
least
less
lest
let
let's
like
liked
likely
little
look
looking
looks
ltd
mainly
many
may
maybe
me
mean
meanwhile
merely
might
more
moreover
most
mostly
much
must
my
myself
name
namely
nd
near
nearly
necessary
need
needs
neither
never
nevertheless
new
next
nine
no
nobody
non
none
noone
nor
normally
not
nothing
novel
now
nowhere
obviously
of
off
often
oh
ok
okay
old
on
once
one
ones
only
onto
or
other
others
otherwise
ought
our
ours
ourselves
out
outside
over
overall
own
particular
particularly
per
perhaps
placed
please
plus
possible
presumably
probably
provides
que
quite
qv
rather
rd
re
really
reasonably
regarding
regardless
regards
relatively
respectively
right
said
same
saw
say
saying
says
second
secondly
see
seeing
seem
seemed
seeming
seems
seen
self
selves
sensible
sent
serious
seriously
seven
several
shall
she
should
shouldn't
since
six
so
some
somebody
somehow
someone
something
sometime
sometimes
somewhat
somewhere
soon
sorry
specified
specify
specifying
still
sub
such
sup
sure
t's
take
taken
tell
tends
th
than
thank
thanks
thanx
that
that's
thats
the
their
theirs
them
themselves
then
thence
there
there's
thereafter
thereby
therefore
therein
theres
thereupon
these
they
they'd
they'll
they're
they've
think
third
this
thorough
thoroughly
those
though
three
through
throughout
thru
thus
to
together
too
took
toward
towards
tried
tries
truly
try
trying
twice
two
un
under
unfortunately
unless
unlikely
until
unto
up
upon
us
use
used
useful
uses
using
usually
value
various
very
via
viz
vs
want
wants
was
wasn't
way
we
we'd
we'll
we're
we've
welcome
well
went
were
weren't
what
what's
whatever
when
whence
whenever
where
where's
whereafter
whereas
whereby
wherein
whereupon
wherever
whether
which
while
whither
who
who's
whoever
whole
whom
whose
why
will
willing
wish
with
within
without
won't
wonder
would
would
wouldn't
yes
yet
you
you'd
you'll
you're
you've
your
yours
yourself
yourselves
zero
EOT
}

sub Language { # Future: Language selector? Maybe.  Prolly not soon.
	1;
}

sub error {
	print "Content-type: text/html\n\n";
	print "There was an error with part of the E-Blah system core (incorrect directory specified and/or incomplete file upload, perhaps?). $!";
	return(0);
}
1;