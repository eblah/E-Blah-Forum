#############################################
# E-Blah Bulletin Board Systems        2008 #
#############################################
# Copyright (c) 2001 - 2008 E-Blah.         #
#############################################

is_admin(1.8);
CoreLoad('SourceCodeMod',1);

%Actions = (
	1 => 'After',
	2 => 'Replace',
	3 => 'Before'
);

sub SourceMod {
	if($URL{'p'} eq 'install') { Installer(); }
	elsif($URL{'p'} eq 'edit') { CreateMod(); }
	elsif($URL{'p'} eq 'edit2') { CreateMod2(); }
	elsif($URL{'p'} eq 'browser') { Browser(); }
	elsif($URL{'p'} eq 'upload') {
		$time = time;
		$FORM{'upload'} =~ s/\cM//g;

		foreach $buff (split(/\n/,$FORM{'upload'})) {
			if($buff =~ /<(.*?)="(.*?)">/) {
				$item{$1} = $2;
			}
		}

		if($item{'modname'} eq '') { error($sourcecode[87]); }
		fopen(FILE,">$modsdir/$time.v2m");
		print FILE $FORM{'upload'};
		fclose(FILE);

		redirect("$surl\lv-admin/a-sourcemod/");
	}
	elsif($URL{'p'} eq 'remove') { unlink("$modsdir/$URL{'m'}.v2m","$modsdir/$URL{'m'}.installed"); $sourceremove = qq~<table class="border" cellpadding="4" cellspacing="1" width="700"><tr><td class="win smalltext center"><strong>$URL{'m'} $sourcecode[86]</strong></td></tr></table><br />~; }

	$title = $sourcecode[1];
	headerA();
	$ebout .= <<"EOT";
<script type="text/javascript">
//<![CDATA[
function clear(mod) {
 if(window.confirm("$sourcecode[85]")) { location = "$surl\lv-admin/a-sourcemod/p-remove/m-"+mod+"/"; }
}
//]]>
</script>
$sourceremove
<table cellpadding="5" cellspacing="1" class="border" width="98%">
 <tr>
  <td class="titlebg">$title</td>
 </tr><tr>
  <td class="win">
   <table cellpadding="4" cellspacing="1" width="100%">
EOT
	opendir(DIR,"$modsdir/");
	@mods = readdir(DIR);
	closedir(DIR);
	foreach(@mods) {
		if($_ =~ m/(.*)(.v2m)/) {
			$quickmod = $1;
			fopen(FILE,"$modsdir/$_");
			@mod = <FILE>;
			fclose(FILE);
			chomp @mod;

			foreach $buff (@mod) {
				if($buff =~ /<(.*?)="(.*?)">/) {
					$item{$1} = $2;
				}
			}
			if($item{'modname'} eq '') { $item{'modname'} = $1; }

			if(!-e("$modsdir/$quickmod.installed")) { $install = $sourcecode[88]; }
				else { $install = $sourcecode[112]; }

			$ebout .= <<"EOT";
    <tr>
     <td class="win2"><strong>$item{'modname'}</strong> -- <a href="$surl\lv-admin/a-sourcemod/p-install/m-$1/">$install</a> | <a href="$surl\lv-admin/a-sourcemod/p-install/m-$1/test-1/">$sourcecode[89] $install</a> | <a href="$surl\lv-admin/a-sourcemod/p-edit/m-$1/">$sourcecode[90]</a> | <a href="javascript:clear('$1')">$sourcecode[91]</a></td>
    </tr><tr>
     <td>
      <table cellpadding="5" class="innertable">
       <tr>
        <td colspan="2">$item{'desc'}</td>
       </tr>
EOT
			if($item{'author'} ne '') {
				$ebout .= <<"EOT";
       <tr>
        <td><strong>$sourcecode[92]:</strong></td>
        <td>$item{'author'}</td>
       </tr>
EOT
			}
			if($item{'version'} ne '') {
				$ebout .= <<"EOT";
       <tr>
        <td><strong>$sourcecode[93]:</strong></td>
        <td>$item{'version'}</td>
       </tr>
EOT
			}
			if($item{'boardversion'} ne '') {
				$ebout .= <<"EOT";
       <tr>
        <td><strong>$sourcecode[94]:</strong></td>
        <td>$item{'boardversion'}</td>
       </tr>
EOT
			}
			if($item{'site'} ne '') {
				$ebout .= <<"EOT";
       <tr>
        <td><strong>$sourcecode[95]:</strong></td>
        <td>$item{'site'}</td>
       </tr>
EOT
			}
			$ebout .= <<"EOT";
      </table>
     </td>
    </tr>
EOT
			$modfound = 1;
		}
	}

	if(!$modfound) { $ebout .= qq~<tr><td>$sourcecode[96]</td></tr>~; }

	$ebout .= <<"EOT";
   </table>
  </td>
 </tr><tr>
  <td class="win3 center"><a href="$surl\lv-admin/a-sourcemod/p-edit/">$sourcecode[97]</a></td>
 </tr>
</table><br />
<form action="$surl\lv-admin/a-sourcemod/p-upload/" method="post">
<table cellpadding="5" cellspacing="1" class="border" width="98%">
 <tr>
  <td class="titlebg">$sourcecode[98]</td>
 </tr><tr>
  <td class="win smalltext">$sourcecode[99]</td>
 </tr><tr>
  <td class="win2 center"><textarea name="upload" rows="1" cols="1" style="width: 95%; height: 100px;"></textarea></td>
 </tr><tr>
  <td class="win3 center"><input type="submit" value="$sourcecode[100]" /></td>
 </tr>
</table>
</form>
EOT
	footerA();
	exit;
}

sub OpenMod {
	fopen(FILE,"$modsdir/$_[0].v2m");
	@mod = <FILE>;
	fclose(FILE);
	chomp @mod;

	foreach $filemod (@mod) {
		if($filemod =~ /^<openfile="(.*?)" writes="(.*?)">$/) {
			$openfile = $1;
			$temp = $2;

			if($_[1]) {
				$openfile =~ s/^Code\//$code\//gsi;
				$openfile =~ s/^Root\//$root\//gsi;
				$openfile =~ s/^Languages\//$languages\//gsi;
			}

			$eachwrite{$openfile} = $temp;
			push(@filewrites,"$openfile");
		} elsif($filemod =~ /^<mod search="(.*?)">$/ && $openfile) {
			$record = $1;
		} elsif($filemod =~ /^<\/mod (.*?)>$/) {
			$record = '';
			$record2 = '';
		} elsif($record) {
			$search{$openfile,$record} .= "$filemod\r";
		} elsif($filemod =~ /^<mod write="(.*?)" action="(.*?)">$/ && $openfile) {
			if($record) { error("Mod not complete."); }
			$record2 = $1;
			$type{$openfile,$record2} .= $2;
		} elsif($record2) {
			$write{$openfile,$record2} .= "$filemod\r";
		} elsif($filemod =~ /^<(.*?)="(.*?)">$/) {
			$item{$1} = $2;
		}
	}
}

sub Installer {
	if(-e("$modsdir/$URL{'m'}.installed")) { $deinstall = 1; }
	OpenMod($URL{'m'},1);

	$title = $sourcecode[101];
	headerA();

	$ebout .= <<"EOT";
<table cellpadding="4" cellspacing="1" class="border" width="98%">
 <tr>
  <td class="titlebg">$title</td>
 </tr><tr>
  <td class="catbg smalltext">$sourcecode[102]</td>
 </tr><tr>
  <td class="win">
   <table cellpadding="5" cellspacing="1" width="100%">
EOT

	foreach $opened (@filewrites) {
		$red = 0;
		fopen(FILE,"$opened") or $red = 1;
		@modify = <FILE>;
		fclose(FILE);
		chomp @modify;
		foreach $though (@modify) { $file{$opened} .= "$though\r"; }
		$file{$opened} =~ s/\r\Z//g;

		if($red) { $red = "red dotted"; } else { $red = "black solid"; }

		$ebout .= <<"EOT";
    <tr>
     <td class="win2" style="border: 1px $red; padding: 8px"><strong>$sourcecode[103]:</strong> $opened &nbsp;($eachwrite{$opened} $sourcecode[104])</td>
    </tr><tr>
     <td><div style="border: 1px black solid; padding: 8px;">
EOT

		$counter = 0;
		while($eachwrite{$opened} != $counter) {
			++$counter;

			if($deinstall) {
				$search = $write{$opened,$counter};
				$write  = $search{$opened,$counter};
				$search2 = $write{$opened,$counter};
				$write2  = $search{$opened,$counter};

			} else {
				$search = $search{$opened,$counter};
				$write  = $write{$opened,$counter};
				$search2 = $search{$opened,$counter};
				$write2  = $write{$opened,$counter};
			}
			$search =~ s/\r\Z//g;
			$write  =~ s/\r\Z//g;
			$search2 =~ s/\r/\n/g;
			$write2  =~ s/\r/\n/g;

			$test = Format($search2);
			$test =~ s/\t/&nbsp; /g;
			$ebout .= "<strong>$sourcecode[105]:</strong><blockquote>$test</blockquote>";
			$test = Format($write2);
			$test =~ s/\t/&nbsp; /g;
			$ebout .= "<strong>$Actions{$type{$opened,$counter}}:</strong><blockquote>$test</blockquote>";

			# After
			if($deinstall && $type{$opened,$counter} == 1) {
				$trash = "$write\r$search";
				if($file{$opened} =~ s~\Q$trash\E~$write~g) { $bad = 0; }
					else { $bad = 1; }
			} elsif($type{$opened,$counter} == 1) {
				if($file{$opened} =~ s~\Q$search\E~$search\r$write~g) { $bad = 0; }
					else { $bad = 1; }
			}

			# Replace
			if($type{$opened,$counter} == 2) {
				if($file{$opened} =~ s~\Q$search\E~$write~g) { $bad = 0; }
					else { $bad = 1; }
			}

			# Before
			if($deinstall && $type{$opened,$counter} == 3) {
				$trash = "$search\r$write";
				if($file{$opened} =~ s~\Q$trash\E~$search~g) { $bad = 0; }
					else { $bad = 1; }
			} elsif($type{$opened,$counter} == 3) {
				if($file{$opened} =~ s~\Q$search\E~$write\r$search~g) { $bad = 0; }
					else { $bad = 1; }
			}

			if($bad) { $error = 1; $e{$filemod} = 1; $ebout .= qq~<div style="border: 1px red dotted; padding: 5px;"><strong><span style="color: red">--&#187; $sourcecode[23]</span></strong></div><br />~; }
				else { $ebout .= qq~<div style="border: 1px green dotted; padding: 5px;"><strong>--&#187; $sourcecode[22]</strong></div><br />~; }
		}
		$ebout .= "</div></td></tr>";

		$file{$opened} =~ s/\r/\n/g;
	}

	if($URL{'override'} || (!$error && !$URL{'test'})) {
		foreach $opened (@filewrites) {
			rename($opened,"$opened.".time);

			fopen(FILE,">$opened");
			print FILE "$file{$opened}";
			fclose(FILE);

			if($deinstall) { unlink("$modsdir/$URL{'m'}.installed"); }
				else {
					fopen(FILE,">$modsdir/$URL{'m'}.installed");
					print FILE "1";
					fclose(FILE);
				}
		}
		$preform = $sourcecode[106];
	} elsif(!$error && $URL{'test'}) { $preform = $sourcecode[107].qq~ <strong><a href="$surl\lv-admin/a-sourcemod/p-install/m-$URL{'m'}/">$sourcecode[113]</a></strong>.~; }
	if($error && $URL{'override'}) { $preform = $sourcecode[108]; }
	elsif($error) { $preform = $sourcecode[109]; }
	if(!$URL{'override'} && $error) {
		$preform .= qq~$sourcecode[110]<a href="$surl\lv-admin/a-sourcemod/p-install/m-$URL{'m'}/override-1/">$sourcecode[111]</a>.~;
	}

	if(!$error) { $color = 'green'; } else { $color = 'red'; }

	$ebout .= <<"EOT";
  </td>
 </tr><tr>
  <td class="win3 center" style="border: 1px $color solid; padding: 8px;">$preform</td>
 </tr>
</table>
EOT
	footerA();
	exit;

}

sub FormatQ {
	$_[0] =~ s/&/\&amp;/g;
	$_[0] =~ s/</&lt;/g;
	$_[0] =~ s/>/&gt;/g;
	$_[0] =~ s/\r/\n/g;
	$_[0] =~ s/\cM//g;
	return($_[0]);
}

sub CreateMod {
	if($FORM{'folder'} ne '' && $FORM{'spec'} ne '') { $URL{'f'} = "$FORM{'folder'}/$FORM{'spec'}"; }

	if($URL{'m'} eq '') {
		$title = $sourcecode[13];
		headerA();
		$ebout .= <<"EOT";
<script type="text/javascript">
//<![CDATA[
function Submit() {
 document.forms['mod'].submit.disabled = true;
}
//]]>
</script>
<form action="$surl\lv-admin/a-sourcemod/p-edit/m-new/" id="mod" method="post" onsubmit="Submit()">
<table class="border" cellpadding="4" cellspacing="1" width="600">
 <tr>
  <td class="titlebg"><strong><img src="$images/open_thread.gif" alt="" /> $title</strong></td>
 </tr><tr>
  <td class="win smalltext">$sourcecode[35]</td>
 </tr><tr>
  <td class="win2">
   <table cellpadding="4" cellspacing="0" width="100%">
    <tr>
     <td class="right smalltext"><strong>$sourcecode[67]:</strong></td>
     <td><input type="text" name="modname" value="$item{'modname'}" size="50" /></td>
    </tr><tr>
     <td class="right smalltext"><strong>$gtxt{'36'}:</strong></td>
     <td><input type="text" name="author" value="$item{'author'}" size="40" /></td>
    </tr><tr>
     <td class="right smalltext"><strong>$sourcecode[69]:</strong></td>
     <td><input type="text" name="site" value="$item{'site'}" size="35" /></td>
    </tr><tr>
     <td class="right smalltext"><strong>$sourcecode[70]:</strong></td>
     <td><input type="text" name="version" value="$item{'version'}" size="13" /></td>
    </tr><tr>
     <td class="right smalltext"><strong>$sourcecode[71]:</strong></td>
     <td><input type="text" name="boardversion" value="$item{'boardversion'}" size="13" /></td>
    </tr><tr>
     <td class="right vtop smalltext"><strong>$sourcecode[72]:</strong></td>
     <td><textarea name="desc" rows="4" cols="70">$item{'desc'}</textarea></td>
    </tr>
   </table></td>
 </tr><tr>
  <td class="win center"><input type="submit" value=" $sourcecode[37] " name="submit" /></td>
 </tr>
</table>
</form>
EOT
		footerA();
		exit;
	} elsif($URL{'m'} eq 'new') {
		$author       = FormatQuick($FORM{'author'});
		$modname      = FormatQuick($FORM{'modname'});
		$version      = FormatQuick($FORM{'version'});
		$boardversion = FormatQuick($FORM{'boardversion'});
		$site         = FormatQuick($FORM{'site'});
		$desc         = FormatQuick($FORM{'desc'});

		$FORM{'modname'} =~ s/[#%+,\\\/:?"<>'|@^\$\&~'\]\[\;{}!`=-]//gsi;
		$FORM{'modname'} =~ s/\ //gsi;
		if($FORM{'modname'} eq '') { error($sourcecode[39]); }
		if(-e("$modsdir/$FORM{'modname'}.v2m")) { error($sourcecode[38]); }
		fopen(FILE,">$modsdir/$FORM{'modname'}.v2m");
		print FILE qq~<author="$author">
<modname="$modname">
<version="$version">
<boardversion="$boardversion">
<site="$site">
<desc="$desc">~;
		fclose(FILE);
		redirect("$surl\lv-admin/a-sourcemod/p-edit/m-$FORM{'modname'}/");
	}
	if(!-e("$modsdir/$URL{'m'}.v2m")) { error($sourcecode[40]); }
	$fileedit = $URL{'f'};
	$fileedit =~ s/\~/\//g;

	$title = $sourcecode[42];
	headerA();
	if($URL{'d'} ne '' && $URL{'f'} eq '') { $ebout .= qq~<table class="border" cellpadding="4" cellspacing="1" width="700"><tr><td class="win smalltext center"><strong><img src="$images/warning_sm.png" alt="" /> &nbsp; $sourcecode[81] &nbsp; <img src="$images/warning_sm.png" alt="" /></strong></td></tr></table><br />~; }
	$ebout .= <<"EOT";
<form action="$surl\lv-admin/a-sourcemod/p-edit2/m-$URL{'m'}/f-$URL{'f'}/d-$URL{'d'}/n-$URL{'n'}/" method="post">
<table class="border" cellpadding="4" cellspacing="1" width="98%">
 <tr>
  <td class="titlebg" colspan="2"><strong><img src="$images/open_thread.gif" alt="" /> $title</strong></td>
 </tr><tr>
  <td class="win smalltext" colspan="2">$sourcecode[43]</td>
 </tr><tr>
  <td class="win2" colspan="2"><strong><img src="$images/open_thread.gif" alt="" /> $sourcecode[44]:</strong> "$fileedit" <strong>$sourcecode[45]:</strong> "$URL{'m'}"<br /><span class="smalltext">&nbsp; &nbsp; &nbsp;<strong>- <a href="$surl\lv-admin/a-sourcemod/p-browser/m-$URL{'m'}/">$sourcecode[46]</a></strong></span></td>
 </tr>
EOT
	OpenMod($URL{'m'});
	foreach $files (@filewrites) {
		$files2 = $files;
		$files2 =~ s/\//\~/g;
		$filemod .= qq~<strong><a href="$surl\lv-admin/a-sourcemod/p-edit/m-$URL{'m'}/f-$files2/">$files</a> ($eachwrite{$files} $sourcecode[47])</strong><br />~;

		$count = 0;
		if($files eq $fileedit) {
			while($eachwrite{$files} != $count) {
				++$count;
				$acts .= qq~<a href="$surl\lv-admin/a-sourcemod/p-edit/m-$URL{'m'}/f-$URL{'f'}/d-$type{$files,$count}/n-$count/">$Actions{$type{$files,$count}}</a> -&rsaquo; $sourcecode[48] $count<br />~;

				if($URL{'n'} == $count) {
					$search  = FormatQ($search{$files,$count});
					$changes = FormatQ($write{$files,$count});
					$delete  = qq~ <input type="submit" value=" $sourcecode[49] " name="delete" />~;
				}
			}
		}
	}

	$changes =~ s/\n\Z//g;
	$search  =~ s/\n\Z//g;

	if(!$filemod) { $filemod = $sourcecode[50]; }
	if($URL{'d'} && $URL{'f'}) {
		if($URL{'d'} == 1) { $action = $sourcecode[51]; }
		elsif($URL{'d'} == 3) { $action = $sourcecode[52]; }
			else { $action = $sourcecode[53]; }
		$preform = <<"EOT";
$sourcecode[54]<br />
<textarea name="searchfor" rows="5" cols="112">$search</textarea><br /><br />

$action<br />
<textarea name="action" rows="5" cols="112">$changes</textarea><br /><br />
<input type="submit" value=" Save Action " name="submit" />$delete<br />
<br /><span class="smalltext"><strong>$sourcecode[55]:</strong> (\\t) $sourcecode[56]</span>
EOT
	} else { $preform = $sourcecode[57]; }

	$item{'desc'} = Unformat($item{'desc'});

	if(!$acts) { $acts = $sourcecode[58]; }
	$ebout .= <<"EOT";
 <tr>
  <td class="catbg"><strong>$sourcecode[59]</strong></td>
  <td class="catbg" style="width: 20%"><strong>$sourcecode[60]</strong></td>
 </tr><tr>
  <td class="win2 smalltext vtop">$preform</td>
  <td class="win smalltext vtop" style="width: 20%">$acts</td>
 </tr><tr>
  <td class="catbg smalltext" colspan="2"><strong>$sourcecode[61]</strong></td>
 </tr><tr>
  <td class="win2 smalltext" colspan="2"><strong>- <a href="$surl\lv-admin/a-sourcemod/p-edit/m-$URL{'m'}/f-$URL{'f'}/d-1/">$sourcecode[63]</a><br />- <a href="$surl\lv-admin/a-sourcemod/p-edit/m-$URL{'m'}/f-$URL{'f'}/d-3/">$sourcecode[62]</a><br />- <a href="$surl\lv-admin/a-sourcemod/p-edit/m-$URL{'m'}/f-$URL{'f'}/d-2/">$sourcecode[64]</a></strong></td>
 </tr>
</table>
</form><br />
<table class="border" cellpadding="4" cellspacing="1" width="98%">
 <tr>
  <td class="catbg smalltext" colspan="2"><strong>$sourcecode[65]</strong></td>
 </tr><tr>
  <td class="win smalltext" colspan="2">$filemod</td>
 </tr><tr>
  <td class="catbg smalltext" colspan="2"><strong>$sourcecode[66]</strong></td>
 </tr><tr>
  <td class="win2" colspan="2">
   <form action="$surl\lv-admin/a-sourcemod/p-edit2/m-$URL{'m'}/f-$URL{'f'}/crap-1/" method="post">
   <table cellpadding="3" cellspacing="0">
    <tr>
     <td class="right smalltext"><strong>$sourcecode[67]:</strong></td>
     <td><input type="text" name="modname" value="$item{'modname'}" size="50" /></td>
    </tr><tr>
     <td class="right smalltext"><strong>$gtxt{'36'}:</strong></td>
     <td><input type="text" name="author" value="$item{'author'}" size="40" /></td>
    </tr><tr>
     <td class="right smalltext"><strong>$sourcecode[69]:</strong></td>
     <td><input type="text" name="site" value="$item{'site'}" size="35" /></td>
    </tr><tr>
     <td class="right smalltext"><strong>$sourcecode[70]:</strong></td>
     <td><input type="text" name="version" value="$item{'version'}" size="13" /></td>
    </tr><tr>
     <td class="right smalltext"><strong>$sourcecode[71]:</strong></td>
     <td><input type="text" name="boardversion" value="$item{'boardversion'}" size="13" /></td>
    </tr><tr>
     <td class="right vtop smalltext"><strong>$sourcecode[72]:</strong></td>
     <td><textarea name="desc" rows="3" cols="50">$item{'desc'}</textarea></td>
    </tr><tr>
     <td colspan="2"><input type="submit" name="submit" value=" $sourcecode[73] " /></td>
    </tr>
   </table>
   </form>
  </td>
 </tr>
</table>
EOT
	footerA();
	exit;
}

sub CreateMod2 {
	OpenMod($URL{'m'});
	$URL{'f'} =~ s/\~/\//g;

	$FORM{'searchfor'} =~ s/\(\\t\)/\t/gsi;
	$FORM{'searchfor'} =~ s/\cM//gsi;
	$FORM{'action'} =~ s/\(\\t\)/\t/gsi;
	$FORM{'action'} =~ s/\cM//gsi;
	$FORM{'action'} =~ s/\r/\n/gsi;

	foreach $files (@filewrites) {
		$temp = $eachwrite{$files};
		if($eachwrite{$files} == 1 && $files eq $URL{'f'} && $FORM{'delete'}) { next; }
		if($FORM{'delete'} && $files eq $URL{'f'}) { $temp = $eachwrite{$files}-1; }
		if($URL{'n'} eq '' && $files eq $URL{'f'}) { $temp = $eachwrite{$files}+1; }
		if($URL{'crap'}) { $temp = $eachwrite{$files}; }

		$writetofile .= qq~<openfile="$files" writes="$temp">\n~;

		$count = 0;
		$numbers = 0;
		while($eachwrite{$files} != $count) {
			++$count;
			if($URL{'n'} == $count && $files eq $URL{'f'}) {
				$search{$files,$count} = $FORM{'searchfor'};
				$write{$files,$count}  = $FORM{'action'};

				# Fix the input ...
				$search{$files,$count} =~ s/\cM//gsi;
				$write{$files,$count}  =~ s/\cM//gsi;

				if($FORM{'delete'}) { next; }
				++$numbers;
			} else {
				$search{$files,$count} =~ s/\r\Z//gsi;
				$write{$files,$count}  =~ s/\r\Z//gsi;
				++$numbers;
			}

			$search{$files,$count} =~ s/\r/\n/gsi;
			$write{$files,$count}  =~ s/\r/\n/gsi;
			$writetofile .= qq~<mod search="$numbers">\n$search{$files,$count}\n</mod end>\n~;
			$writetofile .= qq~<mod write="$numbers" action="$type{$files,$count}">\n$write{$files,$count}\n</mod end>\n~;
		}

		if($URL{'n'} eq '' && $files eq $URL{'f'}) {
			if($URL{'crap'} == 1) { next; }
			++$numbers;
			$writetofile .= qq~<mod search="$numbers">\n$FORM{'searchfor'}\n</mod end>\n~;
			$writetofile .= qq~<mod write="$numbers" action="$URL{'d'}">\n$FORM{'action'}\n</mod end>\n~;

			$numberyep = 1;
		}
	}

	if(!$numberyep && $URL{'f'} ne '' && $URL{'n'} eq '') {
		if($URL{'crap'} != 1) {
			$writetofile .= qq~<openfile="$URL{'f'}" writes="1">\n~;
			$writetofile .= qq~<mod search="1">\n$FORM{'searchfor'}\n</mod end>\n~;
			$writetofile .= qq~<mod write="1" action="$URL{'d'}">\n$FORM{'action'}\n</mod end>\n~;
		}
	}

	$changes =~ s/\n\Z//g;
	$search  =~ s/\n\Z//g;

	if($URL{'crap'} == 1) {
		$author       = FormatQuick($FORM{'author'});
		$modname      = FormatQuick($FORM{'modname'});
		$version      = FormatQuick($FORM{'version'});
		$boardversion = FormatQuick($FORM{'boardversion'});
		$site         = FormatQuick($FORM{'site'});
		$desc         = FormatQuick($FORM{'desc'});
	} else {
		$author       = $item{'author'};
		$modname      = $item{'modname'};
		$version      = $item{'version'};
		$boardversion = $item{'boardversion'};
		$site         = $item{'site'};
		$desc         = $item{'desc'};
	}


	fopen(FILE,">$modsdir/$URL{'m'}.v2m");
	print FILE qq~<author="$author">
<modname="$modname">
<version="$version">
<boardversion="$boardversion">
<site="$site">
<desc="$desc">

$writetofile~;
	fclose(FILE);

	$URL{'f'} =~ s/\//\~/g;
	redirect("$surl\lv-admin/a-sourcemod/p-edit/m-$URL{'m'}/f-$URL{'f'}/");
}

sub FormatQuick {
	($temp) = $_[0];
	$temp =~ s/&/\&amp;/g;
	$temp =~ s/</&lt;/g;
	$temp =~ s/>/&gt;/g;
	$temp =~ s/\cM//g;
	$temp =~ s/\n/<br \/>/g;
	$temp =~ s/\|/\&#124;/g;
	$temp =~ s/"/\&quot;/g;
	$temp =~ s/  / &nbsp;/gi;
	$temp =~ s/\t/ &nbsp; &nbsp; /gi;
	return $temp;
}

sub Browser {
	opendir(DIR,"$code/");
	@directory = readdir(DIR);
	closedir(DIR);
	foreach(@directory) {
		if(-d("$root/$_") || $_ eq '.' || $_ eq '.htaccess' || $_ eq '..') { next; }
		$codedir .= qq|<a href="$surl\lv-admin/a-sourcemod/p-edit/f-Code~$_/m-$URL{'m'}/">$_</a><br />|;
	}
	opendir(DIR,"$root/");
	@directory = readdir(DIR);
	closedir(DIR);
	foreach(@directory) {
		if(-d("$root/$_") || $_ eq '.' || $_ eq '.htaccess' || $_ eq '..' || $_ eq 'Boards' || $_ eq 'Code' || $_ eq 'Members' || $_ eq 'Messages' || $_ eq 'Prefs' || $_ eq 'Themes' || $_ eq 'Mods') { next; }
		$rootdir .= qq|<a href="$surl\lv-admin/a-sourcemod/p-edit/f-Root~$_/m-$URL{'m'}/">$_</a><br />|;
	}
	opendir(DIR,"$language/");
	@directory = readdir(DIR);
	closedir(DIR);
	$lngdir = qq|<a href="$surl\lv-admin/a-sourcemod/p-edit/f-Languages~$languagep.lng/m-$URL{'m'}/">$languagep.lng</a><br />|;
	foreach(@directory) {
		if(-d("$root/$_") || $_ eq '.' || $_ eq '.htaccess' || $_ eq '..' || $_ eq 'Boards' || $_ eq 'Code' || $_ eq 'Members' || $_ eq 'Messages' || $_ eq 'Prefs' || $_ eq 'Themes' || $_ eq 'Mods') { next; }
		$lngdir .= qq|<a href="$surl\lv-admin/a-sourcemod/p-edit/f-Languages~$languagep~$_/m-$URL{'m'}/">$languagep/$_</a><br />|;
	}	opendir(DIR,"$language/");
	$title = $sourcecode[74];
	headerA();
	$ebout .= <<"EOT";
<form action="$surl\lv-admin/a-sourcemod/p-edit/m-$URL{'m'}/" method="post">
<table class="border" cellpadding="4" cellspacing="1" width="400">
 <tr>
  <td class="titlebg"><strong><img src="$images/open_thread.gif" alt="" /> $title</strong></td>
 </tr><tr>
  <td class="catbg"><strong>&bull; $sourcecode[75]: Root</strong></td>
 </tr><tr>
  <td class="win smalltext">$rootdir</td>
 </tr><tr>
  <td class="catbg"><strong>&bull; $sourcecode[75]: Code</strong></td>
 </tr><tr>
  <td class="win smalltext">$codedir</td>
 </tr><tr>
  <td class="catbg"><strong>&bull; $sourcecode[75]: Languages/$languagep</strong></td>
 </tr><tr>
  <td class="win smalltext">$lngdir</td>
 </tr><tr>
  <td class="catbg"><strong>&bull; $sourcecode[76]</strong></td>
 </tr><tr>
  <td class="win2">
   <table cellpadding="4" cellspacing="0">
    <tr>
     <td class="right"><strong>$sourcecode[77]:</strong></td>
     <td><select name="folder"><option value="Root">Root</option><option value="Code">Code</option><option value="Languages">Languages</option><option value="">$sourcecode[82]</option></select></td>
    </tr><tr>
     <td class="right"><strong>$sourcecode[78]:</strong></td>
     <td><input type="text" name="spec" /></td>
    </tr><tr>
     <td class="right" colspan="2"><input type="submit" value=" $sourcecode[79] " name="dir" /></td>
    </tr>
   </table>
  </td>
 </tr>
</table>
</form>
EOT
	footerA();
	exit;
}
1;