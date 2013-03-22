#!/usr/bin/perl

############################################################
# E-Blah Bulletin Board Systems          29 September 2012 #
############################################################
# Software Version: 10.3.7                                 #
# Project started : December 2001 by Justin                #
# Distributed by  : http://www.eblah.com                   #
# License         : http://www.eblah.com/license.php       #
############################################################
# This program is free software; you can redistribute it   #
# and/or modify it under the terms of the GNU General      #
# Public License as published by the Free Software         #
# Foundation; version 2 of the License.                    #
# This program is distributed in the hope that it will be  #
# useful, but WITHOUT ANY WARRANTY; without even the       #
# implied warranty of MERCHANTABILITY or FITNESS FOR A     #
# PARTICULAR PURPOSE.  See the GNU General Public License  #
# for more details.                                        #
############################################################
# Copyright (c) 2001 - 2012 E-Blah.                        #
############################################################
use CGI::Carp fatalsToBrowser;

# Global information:
$theblahver  = 16;
$version     = $versioncr = '10.3.7'; # Said Version; Copyright version

# Uncomment this for better time precision
#use Time::HiRes qw(time);

# Filename information
$scriptname = $scriptname || 'Blah.pl'; # Change name of Blah.pl
$modrewrite = $modrewrite || '?';       # Setting, mod_rewrite: on = '' | off = '?'

use Fcntl ':flock';

# Default language
$languagep = "English";
$languages = "./Languages";

require('Settings.pl');

require("$code/QuickCore.pl");
UFS();
CheckCookies();
GetThemes();

$language = "$languages/$languagep";
require("$language.lng");
require("$code/Routines.pl");
require("$code/Load.pl");

# Remove the theme variable for guests/search engines
redirect() if($URL{'theme'} && $username eq 'Guest');

# Load basic features we can use later
CreateGroups();
BoardCheck();
ClickLog();
AL();

GetMemberID($username) if($username ne 'Guest');

# Lets see if this user should have access ...
if(($maintance || $noguest) || $lockout || -e("$root/Maintance.lock")) { CoreLoad('BoardLock'); MainLO(); }
Ban();

sub UFS {
	my($query);
	@url = split(/\//,$ENV{'QUERY_STRING'});
	foreach (@url) {
		($action,$actiondo) = split(/-/,$_);
		$URL{$action} = $actiondo;

		if($action =~ /\&/) { $blockform = 1; } # Hack attemp, block forms!!
	}

	if(!$blockform) {
		if($ENV{'CONTENT_TYPE'} =~ /multipart\/form-data/) { # If it's an upload (uses CGI library) ...
			require CGI || error("CGI Load error"); import CGI qw(:standard);
			$form = new CGI;
			foreach $var ($form->param) {
				$output = join(',',$form->param($var));
				if(!$nouselist{$var}) { $FORM{$var} = $output; }
			}
		} else { # If it's not ...
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
	}
}

sub CoreLoad {
	my($temp1,$temp2) = @_;
	if($CoreLoaded{$temp1,$temp2}) { return(); }
	$CoreLoaded{$temp1,$temp2} = 1;
	if($temp2 == 1) { $load = "$language/$temp1.lng"; }
	elsif($temp2) { $load = $temp1; }
		else { $load = "$code/$temp1.pl"; }
	eval { require($load) };

	if($_[1] == 2) {
		if($@) { return(0); }
		return(1);
	}
	if($@) { error(qq~$rtxt[52]\n\n$load\n\n\[size=9\]$@\[/size\]~,2); }
}

{
	%LoadBoard = (
		'memberpanel' => 'MemberPanel,MemberPanel',
		'login'       => 'Login,Login',
		'mod'         => 'Moderate,Moderate',
		'register'    => 'Register,Register',
		'admin'       => 'AdminList,AdminList',
		'post'        => 'Post,Post',
		'ppoll'       => 'Poll,PPoll',
		'display'     => 'MessageDisplay,MessageDisplay',
		'mindex'      => 'MessageIndex,MessageIndex',
		'print'       => 'Print,PrintDisplay',
		'members'     => 'Members,Members',
		'report'      => 'Report,Report',
		'cal'         => 'Calendar,CalendarLoad',
		'download'    => 'Attach,Download',
		'stats'       => 'Stats,Stats',
		'search'      => 'Search,Search',
		'invite'      => 'Invite,Invite',
		'recommend'   => 'Recommend,Recommend',
		'mark'        => ',Mark',
		'shownews'    => 'Portal,Shownews',
		'portal'      => 'Portal,Portal',
		'tags'        => 'Tags,Tags'
	);

	if($LoadBoard{$URL{'v'}}) {
		($core,$sub) = split(',',$LoadBoard{$URL{'v'}});
		CoreLoad($core) if($core ne '');
		&$sub();
	} elsif($URL{'m'}) { CoreLoad('MessageDisplay'); MessageDisplay(); }
	elsif($URL{'b'}) { CoreLoad('MessageIndex'); MessageIndex(); }
		else {
			error($gtxt{'notfound'},0,1) if($URL{'v'} ne '');
			CoreLoad('BoardIndex'); LoadIndex();
		}
	exit;
}
1;