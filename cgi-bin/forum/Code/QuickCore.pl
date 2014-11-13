#############################################
# E-Blah Bulletin Board Systems        2008 #
#############################################
# Copyright (c) 2001 - 2008 E-Blah.         #
#############################################
# Part of the E-Blah Core                   #
#############################################

{
	$pwcry = 'ya'; # If 'ya' is changed, change this also! This is conversion key!
	$pwlength = $encryption == 2 ? 20 : 8; # Max password length, 20 = MD5 encryption style; 8 = other

	$uflock = 1; # File Locking (Dis|En)abler
	$fopen  = 2;
	$fclose = 8;
}

sub fopen {
	my($fh,$fn) = @_;

	if($fn =~ m~/\.\./~) {
		eval { error("OPEN_ERROR",2); };
		die "\n\nYou MUST use absolute paths.\n\n";
	}

	if($debug >= 2) { ++$openedfiles; $openedfilenames .= "$fn ($fh)<br />\n"; }

	open($fh,$fn);
	if($uflock) {
		flock($fh,$fopen);
		seek($fh,0,0);
	} else { return(1); }
}

sub fclose {
	my($fh) = $_[0];
	if($uflock) { flock($fh,$fclose); }
	close($fh);
}

sub CheckCookies { # Find users cookies/SID
	foreach(split(/; /,$ENV{'HTTP_COOKIE'})) {
		$_ =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
		($cname,$cval) = split(/=/);
		$Blah{$cname} = $cval;
	}

	$sessionEnabled = 0;
	if($Blah{"$cookpre\_pw"} && ($ensids == 0 || $ensids == 1)) {
		$password = $Blah{"$cookpre\_pw"};
		$username = $Blah{"$cookpre\_un"};
	} else {
		if($ensids) {
			eval { require("CGI/Session.pm"); };
			if($Blah{"$cookpre\_session"} ne '' && !$@) {
				$session = new CGI::Session("driver:File", $Blah{"$cookpre\_session"}, {Directory=>"$prefs/Sessions"});
	
				$username = $session->param('username');
				$password = $session->param('password');
	
				$sessionEnabled = 1;
			}
		}
	}
	GetUser() if($username ne 'Guest');
	if($URL{'theme'} && $username ne 'Guest') { $usert .= "theme-$URL{'theme'}/"; }

	$scripturl = "$scriptname$modrewrite\lb-$URL{'b'}/$usert";
	$surl = $scriptname.$modrewrite.$usert;
	$rurl = $realurl.$scriptname;

	$rurl .= $modrewrite if($modrewrite eq '?');
}

sub GetUser {
	fopen(FILE,"$members/$username.dat") or $username = "Guest";
	while($iddata = <FILE>) {
		chomp $iddata;
		$iddata =~ /^(.+?) = \|(.+?)\|\Z/g;
		$tempid{$username}{$1} = $2;
	}
	fclose(FILE);

	if($username ne 'Guest') {
		$memberid{$username}{'md5upgrade'} = $tempid{$username}{'md5upgrade'};
		if($yabbconver) { $cryptpw = $tempid{$username}{'password'}; } else { $cryptpw = Encrypt($tempid{$username}{'password'}); }
		if($password ne $cryptpw) { $username = 'Guest'; return(); }

		if($tempid{$username}{'status'}) { $lockuserout = 1; } # Lock user out ...

		$pmdisable = 1 if($tempid{$username}{'pmdisable'});

		@blockedusers = split(/\|/,$tempid{$username}{'blockedusers'});

		$languagep = $tempid{$username}{'lng'} if($tempid{$username}{'lng'} && -e("$languages/$tempid{$username}{'lng'}.lng"));
		$memberid{$username}{'theme'} = $tempid{$username}{'theme'};

		$memberid{$username}{'timeformat'} = $tempid{$username}{'timeformat'};
		$memberid{$username}{'dateformat'} = $tempid{$username}{'dateformat'};
		$memberid{$username}{'timezone'} = $tempid{$username}{'timezone'};
		$memberid{$username}{'dst'} = $tempid{$username}{'dst'};
		$memberid{$username}{'posts'} = $tempid{$username}{'posts'};
		$memberid{$username}{'status'} = $tempid{$username}{'status'};
	}
}

sub Encrypt {
	if($yabbconver) {
		if($md5upgrade) { $encryption = $memberid{$username}{'md5upgrade'} ? 2 : 1; }
		if($encryption == 2) { # What method?
			require Digest::MD5;
			import Digest::MD5 qw(md5_hex);
			$crypted = md5_hex($_[0]);
			if($memberid{$username}{'salt'}) { $crypted = md5_hex($crypted, $memberid{$username}{'salt'}); }
		} else { $crypted = crypt($_[0],$pwcry); }
	} else { $crypted = $_[0]; }
	return($crypted);
}

sub GetThemes() {
	if($URL{'theme'}) { $memberid{$username}{'theme'} = $URL{'theme'}; }

	fopen(FILE,"$prefs/ThemesList.txt");
	@themes = <FILE>;
	fclose(FILE);
	chomp @themes;
	foreach(@themes) {
		($theme,$default,$timages,$tbuttons) = split(/\|/,$_);
		$theme{$theme,'images'} = $timages;
		$theme{$theme,'buttons'} = $tbuttons;
		$theme{$theme,'default'} = $default;
		if($default && ($memberid{$username}{'theme'} eq '' || !$showtheme)) { $dtheme = $theme; }
		if($theme eq $memberid{$username}{'theme'} && $showtheme) { $dtheme = $theme; }
		if($dtheme eq '') { $dtheme = $theme; }
	}

	$oimages = $images; $obuttons = $buttons;

	if($theme{$dtheme,'images'})  { $images = "$templatesu/$dtheme/images"; }
	if($theme{$dtheme,'buttons'}) { $buttons = "$templatesu/$dtheme/buttons"; }
}
1;