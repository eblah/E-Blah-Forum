#############################################
# E-Blah Bulletin Board Systems        2008 #
#############################################
# Copyright (c) 2001 - 2008 E-Blah.         #
#############################################

CoreLoad('Themes',1);

is_admin(2.1);

$themesupp = 3;

sub ThemeResearch {
	opendir(DIR,"$templates");
	@themesdir = readdir(DIR);
	closedir(DIR);

	$count = 0;
	$default = 0;
	foreach $t (@themesdir) {
		if($t eq '.' || $t eq '..' || $t eq 'News.html') { next; }

		$theme{$t,'images'}  = '';
		$theme{$t,'buttons'} = '';
		fopen(FILE,"$templates/$t/theme.dat");
		while(<FILE>) {
			$_ =~ /(.+?) = '(.+?)'/;
			$theme{$t,$1} = $2;
		}
		fclose(FILE);
		if($theme{$t,'name'} ne '') {
			++$count;
			push(@themes2,"$t|$theme{$t,'default'}|$theme{$t,'images'}|$theme{$t,'buttons'}");
			$lasttheme = $t;
		}
		if($theme{$t,'default'}) { $default = 1; }
	}

	@themes = @themes2;

	fopen(FILE,">$prefs/ThemesList.txt");
	foreach(@themes) { print FILE $_."\n"; }
	fclose(FILE);

	if(!$default) { ThemeDefault($lasttheme); }
}

sub ThemeDefault {
	if($_[0] ne '') { $URL{'ttheme'} = $lasttheme; }

	$save = '';
	$default = 0;
	fopen(FILE,"$prefs/ThemesList.txt");
	while(<FILE>) {
		chomp $_;
		($theme,$t2,$t3,$t4) = split(/\|/,$_);
		if($theme eq $URL{'ttheme'}) { $save .= "$theme|1|$theme{$theme,'images'}|$theme{$theme,'buttons'}\n"; $default = 1; }
			else { $save .= "$theme||$t3|$t4\n"; }
	}
	fclose(FILE);

	if(!$default && !$eblahsetupv) { error($themetxt[26]); }

	fopen(FILE,">$prefs/ThemesList.txt");
	print FILE $save;
	fclose(FILE);

	if($_[0] eq '' && !$eblahsetupv) { redirect("$surl\lv-admin/a-themesman/"); }
}

sub ThemeDelete {
	$save = '';

	if($theme{$URL{'ttheme'},'default'}) { error($themetxt[27]); }

	fopen(FILE,"$prefs/ThemesList.txt");
	while(<FILE>) {
		chomp $_;
		($theme) = split(/\|/,$_);
		if($theme ne $URL{'ttheme'}) { $save .= "$_\n"; }
			else { unlink("$templates/$theme/template.html","$templates/$theme/template.css","$templates/$theme/admintemplate.css","$templates/$theme/Smilies.html","$templates/$theme/theme.dat"); rmdir("$templates/$theme"); }
	}
	fclose(FILE);

	ThemeResearch();
}

sub ThemeManager {
	if($URL{'p'} eq 'edit' && $URL{'edit'} ne '') { ThemeEdit(); }
	if($URL{'p'} eq 'save' && $URL{'edit'} ne '') { ThemeSave(); }
	if($URL{'p'} eq 'delete') { ThemeDelete(); }
	if($URL{'p'} eq 'default') { ThemeDefault(); }

	$title = $themetxt[1];
	headerA();

	foreach $theme (@themes) {
		($themeid) = split(/\|/,$theme);
		fopen(FILE,"$templates/$themeid/theme.dat");
		while(<FILE>) {
			$_ =~ /(.+?) = '(.+?)'/;
			$theme{$themeid,$1} = $2;
		}
		fclose(FILE);
	}

	if($URL{'p'} eq 'readd') {
		ThemeResearch();

		$ebout .= <<"EOT";
<script type="text/javascript">
//<![CDATA[
alert("$themetxt[28]\\n\\n$count $themetxt[29]");
</script>
EOT
	}

	$ebout .= <<"EOT";
<script type="text/javascript">
//<![CDATA[
function ThemeOpener(valy,shornot) {
 if(document.getElementById) { openItem = document.getElementById(valy); }
 else if (document.all){ openItem = document.all[valy]; }
 else if (document.layers){ openItem = document.layers[valy]; }

 if(shornot) { ShowType = ""; davalue = '<a href="javascript:ThemeOpener(\\''+valy+'\\',\\'\\')"><img src="$images/minimize.gif" alt="" /></a>'; }
  else { ShowType = "none"; davalue = '<a href="javascript:ThemeOpener(\\''+valy+'\\',\\'1\\')"><img src="$images/expand.gif" alt="" /></a>'; }
 if(openItem.style) { openItem.style.display = ShowType; }
  else { openItem.visibility = "show"; }
  document.getElementById('sub_'+valy).innerHTML = davalue;
}

function deletebox(theme) {
	if(confirm("$themetxt[3]")) { location = '$surl\lv-admin/a-themesman/p-delete/ttheme-' + theme + '/'; }
}
//]]>
</script>

<table cellpadding="4" cellspacing="1" width="600" class="border">
 <tr>
  <td class="titlebg">$title</td>
 </tr><tr>
  <td class="win">
   <table width="100%" cellpadding="0" cellspacing="0">
EOT

	foreach(@themes) {
		($theme,$default) = split(/\|/,$_);
		$def = $default ? $themetxt[30] : '';

		$ebout .= <<"EOT";
    <tr>
     <td class="catbg" style="padding: 4px;" colspan="2"><div style="float: left"><span id="sub_$theme"><a href="javascript:ThemeOpener('$theme','1')"><img src="$images/expand.gif" alt="" /></a></span> <a href="$surl\lv-admin/a-themesman/p-edit/edit-$theme/">$theme{$theme,'name'}</a> <span class="smalltext">(ID: $theme)</span></div><div style="float: right;" class="smalltext right">$def</div></td>
    </tr><tr>
     <td class="win2 center" style="padding: 4px;" colspan="2">[ <a href="$surl\lv-admin/a-themesman/p-default/ttheme-$theme/">$themetxt[32]</a> | <a href="javascript:deletebox('$theme');">$themetxt[31]</a> ]</td>
    </tr><tr>
     <td id="$theme" style="display: none">
EOT
		if($theme{$theme,'desc'} ne '' || $theme{$theme,'author'} ne '' || $theme{$theme,'website'} ne '' || $theme{$theme,'copyright'} ne '' || $theme{$theme,'hidden'} ne '' || $theme{$theme,'version'} ne '') {
			$ebout .= qq~<table width="100%" cellpadding="4" cellspacing="0">~;
		}
		if($theme{$theme,'desc'}) {
			$ebout .= <<"EOT";
    <tr>
     <td style="width: 100px" class="vtop smalltext"><strong>$themetxt[33]</strong></td>
     <td class="smalltext">$theme{$theme,'desc'}</td>
    </tr>
EOT
		}
		if($theme{$theme,'author'}) {
			$ebout .= <<"EOT";
    <tr>
     <td class="smalltext"><strong>$themetxt[34]</strong></td>
     <td class="smalltext">$theme{$theme,'author'}</td>
    </tr>
EOT
		}
		if($theme{$theme,'website'}) {
			$ebout .= <<"EOT";
    <tr>
     <td class="smalltext"><strong>$themetxt[44]</strong></td>
     <td class="smalltext"><a href="http://$theme{$theme,'website'}"$blanktarget>$theme{$theme,'website'}</a></td>
    </tr>
EOT
		}
		if($theme{$theme,'copyright'}) {
			$ebout .= <<"EOT";
    <tr>
     <td class="smalltext"><strong>$themetxt[35]</strong></td>
     <td class="smalltext">$theme{$theme,'copyright'}</td>
    </tr>
EOT
		}
		if($theme{$theme,'version'}) {
			$ebout .= <<"EOT";
    <tr>
     <td class="smalltext"><strong>$themetxt[36]</strong></td>
     <td class="smalltext">$theme{$theme,'version'}</td>
    </tr>
EOT
		}
		if($theme{$theme,'hidden'}) {
			$ebout .= <<"EOT";
    <tr>
     <td class="smalltext center" colspan="2">$themetxt[48]</td>
    </tr>
EOT
		}

		if($theme{$theme,'desc'} ne '' || $theme{$theme,'author'} ne '' || $theme{$theme,'website'} ne '' || $theme{$theme,'copyright'} ne '' || $theme{$theme,'hidden'} ne '' || $theme{$theme,'version'} ne '') {
			$ebout .= qq~</table>~;
		}

		$ebout .= <<"EOT";
</td>
</tr>
EOT
	}

	$ebout .= <<"EOT";
   </table>
  </td>
 </tr><tr>
  <td class="catbg"><strong>$themetxt[37]</strong></td>
 </tr><tr>
  <td class="win2 center" style="padding: 20px;"><a href="$surl\lv-admin/a-themesman/p-readd/">$themetxt[38]</a> | <a href="$surl\lv-admin/a-themesman/p-edit/edit-new/">$themetxt[39]</a></td>
 </tr>
</table>
EOT
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

sub ThemeEdit {
	CoreLoad('Admin1',1);

	$title = $themetxt[40];
	headerA();

	if($URL{'edit'} ne 'new') {
		fopen(FILE,"$templates/$URL{'edit'}/theme.dat") || error($themetxt[26]);
		while(<FILE>) {
			$_ =~ /(.+?) = '(.+?)'/;
			$theme{$1} = $2;
		}
		fclose(FILE);

		fopen(FILE,"$templates/$URL{'edit'}/template.html");
		while(<FILE>) { chomp; $temps1 .= $_."\n"; }
		fclose(FILE);
		$temps1 = TempFormat($temps1);

		fopen(FILE,"$templates/$URL{'edit'}/Smilies.html");
		while(<FILE>) { chomp; $temps2 .= $_."\n"; }
		fclose(FILE);
		$temps2 = TempFormat($temps2);

		fopen(FILE,"$templates/$URL{'edit'}/admintemplate.css");
		while(<FILE>) { chomp; $temps3 .= $_."\n"; }
		fclose(FILE);
		$temps3 = TempFormat($temps3);

		fopen(FILE,"$templates/$URL{'edit'}/template.css");
		while(<FILE>) { chomp; $temps4 .= $_."\n"; }
		fclose(FILE);
		$temps4 = TempFormat($temps4);
	}

	$check1{$theme{'buttons'}} = ' checked="checked"';
	$check2{$theme{'images'}}  = ' checked="checked"';
	$check3{$theme{'preview'}} = ' checked="checked"';
	$check4{$theme{'hidden'}} = ' checked="checked"';
	$theme{'desc'} = Unformat($theme{'desc'});

	$ebout .= <<"EOT";
<script type="text/javascript">
//<![CDATA[
function GetTemplate(gettemplate,tempdesc,tempdesc2) {
	oldputaway = document.forms['themes'].putaway;
	tempeditor = document.forms['themes'].tempedit;

	// Lets put away the old ones ... and get rdy for new ones!
	if(oldputaway.value == 1) { document.forms['themes'].temp1.value = tempeditor.value; }
	else if(oldputaway.value == 2) { document.forms['themes'].temp2.value = tempeditor.value; }
	else if(oldputaway.value == 3) { document.forms['themes'].temp3.value = tempeditor.value; }
	else if(oldputaway.value == 4) { document.forms['themes'].temp4.value = tempeditor.value; }

	tempeditor.value = '$themetxt[51]';
	tempeditor.disabled = true;

	if(gettemplate == 1) { tempeditor.value = document.forms['themes'].temp1.value; }
	else if(gettemplate == 2) { tempeditor.value = document.forms['themes'].temp2.value; }
	else if(gettemplate == 3) { tempeditor.value = document.forms['themes'].temp3.value; }
	else if(gettemplate == 4) { tempeditor.value = document.forms['themes'].temp4.value; }
	if(gettemplate != 0) { tempeditor.disabled = false; }

	oldputaway.value = gettemplate;
	if(tempdesc) { document.getElementById('tempdesc').innerHTML = tempdesc; }

	if(document.getElementById) { openItem = document.getElementById('tempdesc2'); }
	else if (document.all){ openItem = document.all['tempdesc2']; }
	else if (document.layers){ openItem = document.layers['tempdesc2']; }

	if(tempdesc2) { ShowType = ""; }
		else { ShowType = "none"; }
	if(openItem.style) { openItem.style.display = ShowType; }
		else { openItem.visibility = "show"; }
}
//]]>
</script>

<form action="$surl\lv-admin/a-themesman/p-save/edit-$URL{'edit'}/" id="themes" method="post" onsubmit="GetTemplate(0)">
<table width="700" cellpadding="4" cellspacing="1" class="border">
 <tr>
  <td class="titlebg"><img src="$images/xx.gif" alt="" /> $title</td>
 </tr><tr>
  <td class="win">
   <table width="100%">
    <tr>
     <td style="width: 200px"><strong>$themetxt[41]</strong></td>
     <td><input type="text" name="name" value="$theme{'name'}" size="40" /></td>
    </tr><tr>
     <td class="vtop"><strong>$themetxt[33]</strong></td>
     <td><textarea name="desc" rows="1" cols="1" style="width: 400px; height: 50px">$theme{'desc'}</textarea></td>
    </tr><tr>
     <td><strong>$themetxt[34]</strong></td>
     <td><input type="text" name="author" value="$theme{'author'}" size="30" /></td>
    </tr><tr>
     <td><strong>$themetxt[44]</strong></td>
     <td>http:// <input type="text" name="website" value="$theme{'website'}" size="40" /></td>
    </tr><tr>
     <td><strong>$themetxt[35]</strong></td>
     <td><input type="text" name="copyright" value="$theme{'copyright'}" size="30" /></td>
    </tr><tr>
     <td><strong>$themetxt[36]</strong></td>
     <td><input type="text" name="version" value="$theme{'version'}" size="4" /></td>
    </tr><tr>
     <td><strong>$themetxt[46]</strong></td>
     <td class="smalltext"><input type="checkbox" name="preview" value="1"$check3{1} /> $themetxt[47]</td>
    </tr><tr>
     <td><strong>$themetxt[50]</strong></td>
     <td class="smalltext"><input type="checkbox" name="hidden" value="1"$check4{1} /> $themetxt[49]</td>
    </tr><tr>
     <td class="vtop"><strong>$themetxt[42]</strong></td>
     <td>
      <div><input type="checkbox" name="buttons" value="1"$check1{1} /> Buttons</div>
      <div><input type="checkbox" name="images" value="1"$check2{1} /> $themetxt[43]</div>
     </td>
    </tr>
   </table>
  </td>
 </tr>
</table>
<br />
<table width="700" cellpadding="0" cellspacing="1" class="border">
 <tr>
  <td class="titlebg" style="padding: 5px;">$admintxt[135]</td>
 </tr><tr>
  <td class="win2">
   <table cellpadding="0" cellspacing="0" width="100%">
    <tr>
     <td class="win vtop" style="width: 175px" rowspan="2"><input type="hidden" name="putaway" />
EOT
		if(!$advancedhtml) {
			$ebout .= <<"EOT";
     <div class="titlebg" style="padding: 5px;"><strong>HTML Templates</strong></div><div style="padding: 10px; line-height: 150%;">
     <a href="#bottom" onclick="GetTemplate('1','$admintxt[197]','1')">$admintxt[197]</a><input type="hidden" name="temp1" value="$temps1" /><br />
     <a href="#bottom" onclick="GetTemplate('2','$admintxt[138]','1')">$admintxt[138]</a><input type="hidden" name="temp2" value="$temps2" /><br /></div>
EOT
		}
		$ebout .= <<"EOT";
     <div class="titlebg" style="padding: 5px;"><strong>CSS Templates</strong></div><div style="padding: 10px; line-height: 150%;">
     <a href="#bottom" onclick="GetTemplate('3','$admintxt[193]','')">$admintxt[193]</a><input type="hidden" name="temp3" value="$temps3" /><br />
     <a href="#bottom" onclick="GetTemplate('4','$admintxt[192]','')">$admintxt[192]</a><input type="hidden" name="temp4" value="$temps4" /></div>
     </td>
     <td class="catbg" style="padding: 5px;"><strong><span id="tempdesc">$admintxt[195]</span></strong><div id="tempdesc2" class="smalltext" style="padding: 5px; display: none;">$admintxt[136]:<br />&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<i>&lt;blah v=&quot;</i><strong>\$variable</strong><i>&quot;&gt;</i></div></td>
    </tr><tr>
     <td class="vtop center" style="padding: 5px;"><textarea name="tempedit" cols="1" rows="1" style="width: 95%; height: 150px;"></textarea><br /></td>
    </tr>
   </table>
  </td>
 </tr><tr>
  <td class="win2 center" style="padding: 5px;"><input type="submit" name="submit" value=" $admintxt[139] " /></td>
 </tr>
</table>
</form>
<script type="text/javascript">
//<![CDATA[
GetTemplate(0);
//]]>
</script>
EOT
	footerA();
	exit;
}

sub ThemeSave {
	$counter = '';
	$new = '';

	$FORM{'name'} = Format($FORM{'name'});
	$FORM{'name'} =~ s/\'/&#8217;/g;
	$FORM{'desc'} = Format($FORM{'desc'});
	$FORM{'desc'} =~ s/\'/&#8217;/g;
	error($themetxt[45]) if($FORM{'name'} eq '');

	if($URL{'edit'} eq 'new') {
		$counter = 1;
		while(-e("$templates/$counter/theme.dat")) { ++$counter; }

		mkdir("$templates/$counter",0777);
		$new = 1;
	}

	$editfile = $counter ? $counter : $URL{'edit'};

	$newfile = "name = '$FORM{'name'}'\n";
	$newfile .= "desc = '$FORM{'desc'}'\n";
	$newfile .= $FORM{'author'} ? "author = '$FORM{'author'}'\n" : '';
	$newfile .= $FORM{'website'} ? "website = '$FORM{'website'}'\n" : '';
	$newfile .= $FORM{'copyright'} ? "copyright = '$FORM{'copyright'}'\n" : '';
	$newfile .= $FORM{'version'} ? "version = '$FORM{'version'}'\n" : '';
	$newfile .= $FORM{'images'} ? "images = '$FORM{'images'}'\n" : '';
	$newfile .= $FORM{'buttons'} ? "buttons = '$FORM{'buttons'}'\n" : '';
	$newfile .= $FORM{'preview'} ? "preview = '$FORM{'preview'}'\n" : '';
	$newfile .= $FORM{'hidden'} ? "hidden = '$FORM{'hidden'}'\n" : '';

	fopen(FILE,">$templates/$editfile/theme.dat");
	print FILE $newfile;
	fclose(FILE);

	if(!$advancedhtml) {
		fopen(FILE,">$templates/$editfile/template.html");
		print FILE $FORM{'temp1'};
		fclose(FILE);
	
		fopen(FILE,">$templates/$editfile/Smilies.html");
		print FILE $FORM{'temp2'};
		fclose(FILE);
	}

	fopen(FILE,">$templates/$editfile/admintemplate.css");
	print FILE $FORM{'temp3'};
	fclose(FILE);

	fopen(FILE,">$templates/$editfile/template.css");
	print FILE $FORM{'temp4'};
	fclose(FILE);

	$themes{$editfile,'buttons'} = $FORM{'buttons'};
	$themes{$editfile,'images'} = $FORM{'images'};

	ThemeResearch();

	redirect("$surl\lv-admin/a-themesman/");
}
1;