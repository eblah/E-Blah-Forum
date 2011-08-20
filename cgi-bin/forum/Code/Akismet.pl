#############################################
# E-Blah Bulletin Board Systems        2008 #
#############################################
# Copyright (c) 2001 - 2008 E-Blah.         #
#############################################
# Akismet Spam Checker for E-Blah           #
# Based loosly off of Net::Akismet module   #
#############################################

use LWP::UserAgent;
use HTTP::Request::Common;

$ua = LWP::UserAgent->new();

$ua->agent("E-Blah/$version");

sub AkismetCheck {
	my($inputuser,$inputcomment,$inputemail) = @_;

	$response = $ua->request(
		POST "http://$akismetkey.rest.akismet.com/1.1/comment-check",
		[
			blog                 => $rurl,
			user_ip              => $ENV{'REMOTE_ADDR'},
			user_agent           => $ua->agent(),
			referrer             => $ENV{'HTTP_REFERER'},
			comment_type         => 'comment',
			comment_author       => $inputuser,
			comment_author_email => $inputemail,
			comment_content      => $inputcomment
		]
	);

	($response && $response->is_success() && $response->content() eq 'false') or return(0); # Spam

	return(1); # Ham
}

sub AkismetVerify {
	my($tempkey) = $_[0];

	$response = $ua->request(
		POST 'http://rest.akismet.com/1.1/verify-key',
		[
			key  => $tempkey,
			blog => $rurl
		]
	);

	($response && $response->is_success() && $response->content() eq 'valid') or return(0); # Cannot validate

	return(1); # Valid key
}
1;