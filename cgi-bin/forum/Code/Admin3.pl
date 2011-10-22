#############################################
# E-Blah Bulletin Board Systems        2008 #
#############################################
# Copyright (c) 2001 - 2008 E-Blah.         #
#############################################

is_admin();
CoreLoad('Members',1);

sub ACL {
	is_admin(-1);
	
	if($URL{'acl'} eq 'save') {
		my($levels);

		for($x = 1; $x <= 6; $x++) {
			for($y = $x+.1; $y <= $x+1; $y = $y+.1) {
				if($subcategories{$y} eq '') { next; }
				if($FORM{$y}) { $levels .= $y.','; }
			}
		}

		$levels =~ s/,\Z//g;

		if($URL{'e'} eq 'new' || $URL{'e'} eq '') { $URL{'e'} = time; }

		if($FORM{'name'} eq ' ' || $FORM{'name'} eq '' || $FORM{'name'} eq '  ') { $FORM{'name'} = 'Untitled'; } # Used in place of error: don't add to lng list
		$FORM{'name'} = Format($FORM{'name'});
		$FORM{'name'} =~ s/\'/&#8217;/g;

		$added = 0;
		$counter = 0;
		foreach $curline (@acls) {
			if($curline =~ /(.+?) => \{/) { $curread = $1; }
			if($curline eq '}') {
				if($added && $curread eq $URL{'e'}) { next; }
				$curread = '';
			}
			++$counter;
			if($counter == @acls) {
				$curline = "$curline\n\n$URL{'e'} => {";
				$curread = $URL{'e'};
			}
			if($URL{'e'} eq $curread && !$added) {
				$added = 1;
				if($FORM{'delete'} ne '') { next; }

				$newlines .= "$curline\n";
				$newlines .= "name = '$FORM{'name'}'\n";
				$newlines .= "level = '$levels'\n";

				$newlines .= "}\n\n";
				next;
			} elsif($URL{'e'} eq $curread) { next; }
			$newlines .= "$curline\n";
		}
		$newlines =~ s/\n\n\Z/\n/g;

		if($newlines eq '') {
			$newlines = <<"EOT";
$URL{'e'} => {
name = '$FORM{'name'}'
level = '$levels'
}
EOT
		}

		fopen(FILE,">$prefs/ACL.txt");
		print FILE $newlines;
		fclose(FILE);

		redirect("$surl\lv-admin/a-memgrps/p-edit/group-$URL{'group'}/");
	}

	$title = $memtext[267];
	headerA();

	$URL{'e'} = 'new' if($URL{'e'} eq '');

	if($URL{'e'} ne 'new') { $delete = qq~ <input type="submit" value=" $memtext[42] " name="delete" />~; }

	$ebout .= <<"EOT";
<form action="$surl\lv-admin/a-acl/e-$URL{'e'}/group-$URL{'group'}/acl-save/" id="admin" method="post" enctype="multipart/form-data">
<table cellpadding="5" cellspacing="1" class="border" width="100%">
 <tr>
  <td class="titlebg">$memtext[267]</td>
 </tr><tr>
  <td class="win3">
   <table cellspacing="0" cellpadding="5" class="innertable">
	<tr>
	 <td>$memtext[268]</td>
	</tr><tr>
	 <td><img src="$images/admincenter/warnhigh.png" class="centerimg" alt="" /> $memtext[269]</td>
    </tr><tr>
	 <td><img src="$images/admincenter/warnmed.png" class="centerimg" alt="" /> $memtext[270]</td>
    </tr><tr>
	 <td><img src="$images/admincenter/warnlow.png" class="centerimg" alt="" /> $memtext[271]</td>
	</tr>
   </table>
  </td>
 </tr><tr>
  <td class="win2" style="padding: 10px">$memtext[272]<br /><br /><input type="text" name="name" size="40" value="$aclvalues{$URL{'e'}}{'name'}" /></td>
 </tr>
EOT

	foreach(split(',',$aclvalues{$URL{'e'}}{'level'})) {
		$checked{$_} = ' checked="checked"';
	}

	for($x = 1; $x <= 6; $x++) {
		($name,$image) = split(/\|/,$categories{$x});
		$ebout .= <<"EOT";
<tr>
 <td class="catbg"><img src="$images/admincenter/$image" class="centerimg" alt="" /> <strong>$name</strong></td>
</tr><tr>
 <td class="win">
  <table cellspacing="0" cellpadding="8" class="innertable">
EOT

		for($y = $x+.1; $y <= $x+1; $y = $y+.1) {
			if($subcategories{$y} eq '') { next; }
			($name,$url,$warn) = split(/\|/,$subcategories{$y});
			if($warn == 1) { $warn = qq~<img src="$images/admincenter/warnhigh.png" class="centerimg" alt="" /> ~; }
			elsif($warn == 2) { $warn = qq~<img src="$images/admincenter/warnmed.png" class="centerimg" alt="" /> ~; }
			elsif($warn == 3) { $warn = qq~<img src="$images/admincenter/warnlow.png" class="centerimg" alt="" /> ~; }
				else { $warn = ''; }

			$ebout .= <<"EOT";
<tr>
 <td><input type="checkbox" name="$y" value="1"$checked{$y} /></td>
 <td><strong>$y</strong> $warn$name</td>
</tr>
EOT
		}
		$ebout .= <<"EOT";
  </table>
 </td>
</tr>
EOT
		$show = 0;
	}

	$ebout .= <<"EOT";
 <tr>
  <td class="win3"><input type="submit" value=" $memtext[59] " name="submit" /> <input type="reset" value=" $memtext[60] " name="reset" />$delete</td>
 </tr>
</table>
</form>
EOT

	footerA();
	exit;
}

sub MemGrps {
	is_admin(3.1);

	if($URL{'p'} eq 'edit') { EditGrps(); }

	$title = $memtext[186];
	headerA();

	$ebout .= <<"EOT";
<table cellpadding="5" cellspacing="1" class="border" width="500">
 <tr>
  <td class="titlebg">$title</td>
 </tr><tr>
  <td class="win">$memtext[187]</td>
 </tr><tr>
  <td class="win2" style="padding: 0px;">
   <table cellpadding="6" cellspacing="1" width="100%">
    <tr>
     <td class="catbg">$memtext[188]</td>
    </tr><tr>
     <td>
EOT
	foreach(@fullgroups) {
		if($permissions{$_,'pcount'} ne '') { next; }
		$team = $permissions{$_,'team'} ? qq~<img src="$images/team.gif" alt="" /> ~ : '';
		$ebout .= qq~<div style="margin-bottom: 4px"><span style="width: 15px"><img src="$images/nopic.gif" style="zindex: 5; background-color: $permissions{$_,'color'}" height="10" width="10" alt="" /></span> <span style="width: 15px">$team</span><a href="$surl\lv-admin/a-memgrps/p-edit/group-$_/">$permissions{$_,'name'}</a></div>~;
	}

	$ebout .= <<"EOT";
     </td>
    </tr><tr>
     <td class="catbg">$memtext[189]</td>
    </tr><tr>
     <td>
EOT

	foreach(@fullgroups) {
		if($permissions{$_,'pcount'} eq '') { next; }
		$team = $permissions{$_,'team'} ? qq~<img src="$images/team.gif" alt="" /> ~ : '';
		$ebout .= qq~<div style="margin-bottom: 4px"><span style="width: 15px"><img src="$images/nopic.gif" style="zindex: 5; background-color: $permissions{$_,'color'}" height="10" width="10" alt="" /></span> <span style="width: 15px">$team</span><a href="$surl\lv-admin/a-memgrps/p-edit/group-$_/">$permissions{$_,'name'}</a></div>~;
	}
	$ebout .= <<"EOT";
     </td>
    </tr><tr>
     <td class="win center"><strong><a href="$surl\lv-admin/a-memgrps/p-edit/group-new/">$memtext[190]</a></strong></td>
    </tr>
   </table>
  </td>
 </tr>
</table>
EOT

	footerA();
	exit;
}

sub EditGrps {
	is_admin(3.1);

	if(!$permissions{$URL{'group'},'name'} && $URL{'group'} ne 'new') { error($memtext[191]); }

	if($URL{'s'}) {
		if($URL{'group'} eq 'new') {
			$URL{'group'} = 1;
			while($permissions{$URL{'group'},'name'} ne '') { ++$URL{'group'}; }
		}
		$added = 0;
		$counter = 0;
		foreach $curline (@globalgroups) {
			if($curline =~ /(.+?) => \{/) { $curread = $1; }
			if($curline eq '}') {
				if($added && $curread eq $URL{'group'}) { next; }
				$curread = '';
			}
			++$counter;
			if($counter == @globalgroups) {
				$curline = "$curline\n\n$URL{'group'} => {";
				$curread = $URL{'group'};
			}
			if($URL{'group'} eq $curread && !$added) {
				$added = 1;
				if($FORM{'delete'} ne '' && $URL{'group'} ne 'Administrator' && $URL{'group'} ne 'Moderators') { next; }
				if($FORM{'groupname'} eq ' ' || $FORM{'groupname'} eq '  ') { $FORM{'groupname'} = 'Untitled'; } # Used in place of error: don't add to lng list
				$FORM{'groupname'} = Format($FORM{'groupname'});
				$FORM{'groupname'} =~ s/\'/&#8217;/g;
				$FORM{'desc'} = Format($FORM{'desc'});
				$FORM{'desc'} =~ s/\'/&#8217;/g;

				$newlines .= "$curline\n";
				$newlines .= "name = '$FORM{'groupname'}'\n";

				$newlines .= $FORM{'color'} ? "color = '$FORM{'color'}'\n" : '';
				$newlines .= $FORM{'colorcodes'} ? "colorcodes = '1'\n" : '';
				$newlines .= $FORM{'team'} ? "team = '$FORM{'team'}'\n" : '';
				$newlines .= $FORM{'coverup'} ? "coverup = '$FORM{'coverup'}'\n" : '';

				# Group setup
				if($FORM{'posts'} eq '' && $URL{'group'} ne 'Moderators') {
					$newlines .= $FORM{'desc'} ? "desc = '$FORM{'desc'}'\n" : '';
					$newlines .= $FORM{'accepting'} ? "accepting = '$FORM{'accepting'}'\n" : '';
					$newlines .= $FORM{'hidden'} ? "hidden = '$FORM{'hidden'}'\n" : '';
				}

				if($FORM{'mainstar'} eq 'OTHER') { $FORM{'mainstar'} = $FORM{'otherstar'}; }
				$newlines .= $FORM{'mainstar'} ? "star = '$FORM{'mainstar'}'\n" : '';
				$newlines .= $FORM{'maincount'} ? "starcount = '$FORM{'maincount'}'\n" : '';
				$newlines .= $FORM{'posts'} ? "pcount = '$FORM{'posts'}'\n" : '';

				# Permissions
				if($URL{'group'} ne 'Administrator' && $URL{'group'} ne 'Moderators') {
					$newlines .= $FORM{'ip'} ? "ip = '$FORM{'ip'}'\n" : '';
					$newlines .= $FORM{'mod'} ? "moderate = '$FORM{'mod'}'\n" : '';
					$newlines .= $FORM{'st'} ? "sticky = '$FORM{'st'}'\n" : '';
					$newlines .= $FORM{'m'} ? "modify = '$FORM{'m'}'\n" : '';
					$newlines .= $FORM{'pro'} ? "profile = '$FORM{'pro'}'\n" : '';
					$newlines .= $FORM{'cal'} ? "cal = '$FORM{'cal'}'\n" : '';
					$newlines .= $FORM{'acl'} ? "acl = '$FORM{'acl'}'\n" : '';
				}

				# Finish group setup with members allowed
				if($FORM{'posts'} eq '') {
					$FORM{'level'} = $FORM{'level'} ? $FORM{'level'} : 0;
					$newlines .= "level = '$FORM{'level'}'\n";

					$newlines .= "manager = ($permissions{$URL{'group'},'manager'})\n";
					$newlines .= "members = ($permissions{$URL{'group'},'members'})\n";
					if($FORM{'accepting'}) { $newlines .= "waiting = ($permissions{$URL{'group'},'waiting'})\n"; }
				}
				$newlines .= "}\n\n";
				next;
			} elsif($URL{'group'} eq $curread) { next; }
			$newlines .= "$curline\n";
		}
		$newlines =~ s/\n\n\Z/\n/g;
		fopen(FILE,">$prefs/Ranks2.txt");
		print FILE $newlines;
		fclose(FILE);

		redirect("$surl\lv-admin/a-memgrps/");
	}

	$IP{$permissions{$URL{'group'},'ip'}}        = ' checked="checked"';
	$MOD{$permissions{$URL{'group'},'moderate'}} = ' checked="checked"';
	$ST{$permissions{$URL{'group'},'sticky'}}    = ' checked="checked"';
	$M{$permissions{$URL{'group'},'modify'}}     = ' checked="checked"';
	$PRO{$permissions{$URL{'group'},'profile'}}  = ' checked="checked"';
	$CAL{$permissions{$URL{'group'},'cal'}}      = ' checked="checked"';
	$T{$permissions{$URL{'group'},'team'}}       = ' checked="checked"';
	$CC{$permissions{$URL{'group'},'colorcodes'}}  = ' checked="checked"';
	$HIDDEN{$permissions{$URL{'group'},'hidden'}}  = ' checked="checked"';
	$LEVEL{$permissions{$URL{'group'},'level'}}    = ' selected="selected"';
	$ACCEPT{$permissions{$URL{'group'},'accepting'}} = ' selected="selected"';
	$ACL{$permissions{$URL{'group'},'acl'}} = ' selected="selected"';
	$COVER{$permissions{$URL{'group'},'coverup'}} = ' checked="checked"';

	$star = $permissions{$URL{'group'},'star'};
	if($star ne 'stype1.png' && $star ne '' && $star ne 'stype2.png' && $star ne 'stype3.png' && $star ne 'stype4.png' && $star ne 'stype5.png' && $star ne 'nopic.gif') { $ostar = $star; $star = 'OTHER'; }
	$STAR{$star} = ' selected="selected"';

	if($URL{'group'} ne 'Administrator' && $URL{'group'} ne 'Moderators') { $noadmin = "PostsOnly();"; }
	if($URL{'group'} ne 'Moderators') { $nomod = "ColorPreview();"; }
	if($URL{'group'} ne 'new' && $URL{'group'} ne 'Administrator' && $URL{'group'} ne 'Moderators') { $delete = qq~ <input type="submit" value=" $memtext[42] " name="delete" />~; }

	if($URL{'group'} eq 'new') { $membergroupid = $memtext[258]; }
		else { $membergroupid = $URL{'group'}; }

	$title = $memtext[186];
	headerA();
	$ebout .= <<"EOT";
<script type="text/javascript">
//<![CDATA[
function cin() {
	previewvar = '';
	if(document.forms['admin'].maincount.value > 25) { document.forms['admin'].maincount.value = "25"; }
	for(i = 1; i <= document.forms['admin'].maincount.value; i++) {
		if(document.forms['admin'].mainstar.value != 'OTHER' && document.forms['admin'].mainstar.value != '') { previewvar = '<img src="$images/'+document.forms['admin'].mainstar.value+'" alt="" />'+previewvar; }
		else if(document.forms['admin'].otherstar.value != '') { previewvar = '<img src="$images/'+document.forms['admin'].otherstar.value+'" alt="" />'+previewvar; }
	}
	document.getElementById('mainjunks').innerHTML = previewvar;
}

function ColorPreview() {
	if(document.forms['admin'].color.value == '') { valy = ''; } else { valy = document.forms['admin'].color.value; }
	document.getElementById('colorpreview').innerHTML = '<strong style="color: '+valy+'">$memtext[180]</strong> <span style="padding: 5px; background-color: '+valy+'"> &nbsp; </span>';
}

function PostsOnly() {
	if(document.getElementById) { openItem = document.getElementById('postsdisabled'); openItem2 = document.getElementById('postsdisabled2'); openItem3 = document.getElementById('postsdisabled3'); openItem4 = document.getElementById('postsdisabled4'); openItem5 = document.getElementById('postsdisabled5'); openItem6 = document.getElementById('postsdisabled6'); }
	else if (document.all){ openItem = document.all['postsdisabled']; openItem2 = document.all['postsdisabled2']; openItem3 = document.all['postsdisabled3']; openItem4 = document.all['postsdisabled4']; openItem5 = document.all['postsdisabled5']; openItem6 = document.all['postsdisabled6']; }
	else if (document.layers){ openItem = document.layers['postsdisabled']; openItem2 = document.layers['postsdisabled2']; openItem3 = document.layers['postsdisabled3']; openItem4 = document.layers['postsdisabled4']; openItem5 = document.layers['postsdisabled5']; openItem6 = document.layers['postsdisabled6']; }

	if(document.forms['admin'].posts.value == '') { ShowType = ""; ShowOther = 'none'; }
		else { ShowType = "none"; ShowOther = ''; }
	if(openItem.style) { openItem.style.display = ShowType; openItem2.style.display = ShowType; openItem3.style.display = ShowType; openItem4.style.display = ShowOther; openItem5.style.display = ShowType; openItem6.style.display = ShowType; }
		else { openItem.visibility = "show"; openItem2.visibility = "show"; openItem3.visibility = "show"; openItem4.visibility = "show"; openItem5.visibility = "show"; openItem6.visibility = "show"; }
}

function EditACL() {
	if(document.forms['admin'].acl.value != '') { return(document.forms['admin'].acl.value); } else { return('new'); }
}
//]]>
</script>
<form action="$surl\lv-admin/a-memgrps/p-edit/s-2/group-$URL{'group'}/" id="admin" method="post" enctype="multipart/form-data">
<table cellpadding="5" cellspacing="1" class="border" width="600">
 <tr>
  <td class="titlebg">$title</td>
 </tr><tr>
  <td class="win smalltext">$memtext[38]</td>
 </tr><tr>
  <td class="catbg smalltext"><strong>$memtext[39]</strong></td>
 </tr><tr>
  <td class="win2">
   <table width="100%" cellpadding="5" cellspacing="0">
    <tr>
     <td style="width: 200px"><strong>$memtext[173]:</strong></td>
     <td colspan="2"><input type="text" name="groupname" value="$permissions{$URL{'group'},'name'}" size="35" /></td>
    </tr><tr>
     <td style="width: 200px"><strong>$memtext[259]:</strong></td>
     <td colspan="2">$membergroupid</td>
    </tr>
EOT
	if($URL{'group'} ne 'Moderators') {
		$ebout .= <<"EOT";
    <tr id="postsdisabled3">
     <td style="width: 200px" class="vtop"><strong>$memtext[192]:</strong></td>
     <td colspan="2"><textarea name="desc" cols="1" rows="1" style="width: 95%; height: 45px;">$permissions{$URL{'group'},'desc'}</textarea></td>
    </tr>
EOT
	}
	if($URL{'group'} ne 'Administrator' && $URL{'group'} ne 'Moderators') {
		$ebout .= <<"EOT";
    <tr id="postsdisabled4">
     <td colspan="3" class="center"><br />$memtext[193]<br /><br /></td>
    </tr><tr>
     <td style="width: 200px"><strong>$memtext[179]</strong></td>
     <td class="vtop" colspan="2"><input type="text" name="posts" value="$permissions{$URL{'group'},'pcount'}" size="3" onchange="PostsOnly()" /> $memtext[181]</td>
    </tr>
EOT
	}
	if($URL{'group'} ne 'Moderators') {
		$ebout .= <<"EOT";
    <tr>
     <td colspan="3" class="win">
      <table width="100%" cellpadding="0" cellspacing="5">
       <tr>
        <td style="width: 200px"><img src="$images/team.gif" alt="" /> <strong>$memtext[57]</strong></td>
        <td colspan="2"><input type="checkbox" value="1" name="team"$T{'1'} /></td>
       </tr><tr>
        <td style="width: 200px"><strong>$memtext[28]:</strong></td>
        <td><input type="text" value='$permissions{$URL{'group'},'color'}' name="color" size="15" onchange="ColorPreview()" /></td>
        <td class="center" id="colorpreview">Color</td>
       </tr><tr>
        <td style="width: 200px"><strong>$memtext[257]</strong></td>
        <td colspan="2"><input type="checkbox" value="1" name="colorcodes"$CC{'1'} /></td>
       </tr>
      </table>
     </td>
    </tr>
EOT
	}
	$ebout .= <<"EOT";
    <tr class="win">
     <td style="width: 200px;"><strong>$memtext[260]</strong></td>
     <td class="vtop" colspan="2"><input type="checkbox" value="1" name="coverup"$COVER{'1'} /></td>
    </tr><tr>
     <td style="width: 200px" class="vtop"><strong>$memtext[174]:</strong></td>
     <td><select name="mainstar" onchange="cin()">
      <option value="stype1.png"$STAR{'stype1.png'}>$memtext[175] 1</option>
      <option value="stype2.png"$STAR{'stype2.png'}>$memtext[175] 2</option>
      <option value="stype3.png"$STAR{'stype3.png'}>$memtext[175] 3</option>
      <option value="stype4.png"$STAR{'stype4.png'}>$memtext[175] 4</option>
      <option value="stype5.png"$STAR{'stype5.png'}>$memtext[175] 5</option>
      <option value="OTHER"$STAR{'OTHER'}>$memtext[176]</option>
      <option value=""$STAR{''}>$memtext[177]</option>
     </select> x <input type="text" size="3" name="maincount" value="$permissions{$URL{'group'},'starcount'}" onchange="cin()" /><div class="smalltext"><strong>$memtext[176]:</strong> images / <input type="text" value="$ostar" name="otherstar" onchange="cin()" /></div></td>
     <td><span id="mainjunks"></span></td>
    </tr>
   </table>
  </td>
 </tr>
</table>
<br />
<table cellpadding="4" cellspacing="1" class="border" width="600">
 <tr>
  <td class="win center"><input type="submit" value=" $memtext[59] " name="submit" /> <input type="reset" value=" $memtext[60] " name="reset" />$delete</td>
 </tr>
</table>
<br />
<table cellpadding="5" cellspacing="1" class="border" width="600">
 <tr>
  <td class="titlebg">$memtext[43]</td>
 </tr><tr>
  <td class="win smalltext">$memtext[183]</td>
 </tr><tr>
  <td class="win2" style="padding: 0">
   <table width="100%" cellpadding="7" cellspacing="1">
    <tr id="postsdisabled6">
     <td colspan="2" class="win smalltext"><strong>$memtext[194]</strong></td>
    </tr>
EOT
	if($URL{'group'} ne 'Moderators') {
		$ebout .= <<"EOT";
    <tr id="postsdisabled">
     <td class="smalltext"><strong>$memtext[195]</strong><br />$memtext[196]</td>
     <td class="right"><select name="accepting"><option value="0"$ACCEPT{0}>$memtext[197]</option><option value="1"$ACCEPT{1}>$memtext[198]</option><option value="2"$ACCEPT{2}>$memtext[199]</option></select></td>
    </tr><tr id="postsdisabled2">
     <td class="smalltext"><strong>$memtext[244]</strong><br />$memtext[243]</td>
     <td class="right vtop"><input type="checkbox" name="hidden" value="1"$HIDDEN{1} /></td>
    </tr>
EOT
	}
	$ebout .= <<"EOT";
    <tr id="postsdisabled5">
     <td class="smalltext"><strong>$memtext[200]:</strong><br />$memtext[201]</td>
     <td class="right vtop"><input type="text" name="level" value="$permissions{$URL{'group'},'level'}" size="4" /></td>
    </tr>
EOT
	if($URL{'group'} ne 'Administrator' && $URL{'group'} ne 'Moderators') {
		$ebout .= <<"EOT";
    <tr>
     <td colspan="2" class="win smalltext"><strong>$memtext[262]</strong></td>
    </tr><tr>
     <td class="smalltext">$memtext[263]</td>
     <td class="right"><select name="acl"><option value="">$memtext[264]</option>
EOT

		foreach(@totalacl) {
			$ebout .= qq~<option value="$_"$ACL{$_}>$aclvalues{$_}{'name'}</option>~;
		}

		$ebout .= <<"EOT";
      </select>
	 </td>
    </tr><tr>
     <td class="smalltext">$memtext[265]</td>
     <td class="right"><a href="#" onclick="javascript:location = '$surl\v-admin/a-acl/e-' + EditACL() + '/group-$URL{'group'}/'">$memtext[266]</a></td>
    </tr><tr>
     <td colspan="2" class="win smalltext"><strong>$memtext[185]</strong></td>
    </tr><tr>
     <td class="smalltext"><strong>$memtext[47]</strong></td>
     <td class="right"><input type="checkbox" name="ip" value="1"$IP{1} /></td>
    </tr><tr>
     <td class="smalltext">$memtext[48]</td>
     <td class="right"><input type="checkbox" name="mod" value="1"$MOD{1} /></td>
    </tr><tr>
     <td class="smalltext"><strong>$memtext[49]</strong></td>
     <td class="right"><input type="checkbox" name="st" value="1"$ST{1} /></td>
    </tr><tr>
     <td class="smalltext"><strong>$memtext[50]</strong></td>
     <td class="right"><input type="checkbox" name="m" value="1"$M{1} /></td>
    </tr><tr>
     <td class="smalltext"><strong>$memtext[51]</strong></td>
     <td class="right"><input type="checkbox" name="pro" value="1"$PRO{1} /></td>
    </tr><tr>
     <td class="smalltext">$memtext[147]</td>
     <td class="right"><input type="checkbox" name="cal" value="1"$CAL{1} /></td>
    </tr>
EOT
	}
	$ebout .= <<"EOT";
   </table>
  </td>
 </tr>
</table>
</form>
<script type="text/javascript">//<![CDATA[
cin();$noadmin$nomod
//]]></script>
EOT
	footerA();
	exit;
}

sub Mailing {
	is_admin(3.2);

	if($URL{'p'} == 2) { Mailing2(); }

	foreach $group (@fullgroups) {
		if($permissions{$group,'members'}) {
			$addmems = '';
			foreach(split(',',$permissions{$group,'members'})) {
				$groupmembers{$_} .= "$group,";

				$addmems .= "u_$_,";
			}
			$inputs .= qq~<input type="hidden" id="a_$group" value="$addmems" />~;
			$selectors .= qq~- <a href="javascript:GroupChooser('a_$group')">$permissions{$group,'name'}</a><br />~;
		}
	}

	$fulllist = '';
	fopen(FILE,"$members/List.txt");
	@mlist = <FILE>;
	fclose(FILE);
	chomp @mlist;
	foreach(@mlist) {
		GetMemberID($_);
		if($memberid{$_}{'ml'} || $memberid{$_}{'status'} eq 'DISABLE') { next; }

		++$counter;
		$total .= qq~<option value="$_" id="u_$_">$memberid{$_}{'sn'}</option>~;
		$allusers .= "u_$_,";
		$fulllist .= "$memberid{$_}{'email'}; ";
	}
	$fulllist =~ s/; \Z//;

	$title = $memtext[64];
	headerA();
	$ebout .= <<"EOT";
<script type="text/javascript">
//<![CDATA[
function GroupChooser(valy) {
	count = 1;

	if(document.getElementById(valy)) {
		junk = document.getElementById(valy).value.split(',');

		for(n = 0; n < junk.length; n++) {
			if(document.getElementById(junk[n])) { document.getElementById(junk[n]).selected = true; }
		}
	}
}
//]]>
</script>
<script src="$bdocsdir/bc.js" type="text/javascript"></script>
<form action="$surl\lv-admin/a-mailing/p-2/" method="post" enctype="multipart/form-data" onsubmit="document.getElementById('submit').disabled = true;" id="post">
<table cellpadding="5" cellspacing="1" class="border" width="98%">
 <tr>
  <td class="titlebg">$title</td>
 </tr><tr>
  <td class="win2">$inputs<input type="hidden" id="a_all" value="$allusers" />
   <table width="100%" cellpadding="0" cellspacing="4">
    <tr>
     <td style="width: 40%" class="vtop">
      <table width="100%" cellpadding="5" cellspacing="1" class="border">
       <tr>
        <td class="win">
         <table cellpadding="4" cellspacing="0" width="100%">
          <tr>
           <td class="center"><select name="emails" size="10" style="width: 300" multiple="multiple">$total</select></td>
          </tr><tr>
           <td class="win2 smalltext"><strong>$memtext[240]:</strong><br />$selectors<br />- <a href="javascript:GroupChooser('a_all')">$memtext[241]</a></td>
          </tr>
         </table>
        </td>
       </tr>
      </table>
     </td>
     <td style="width: 60%" class="vtop">
      <table width="100%" cellpadding="5" cellspacing="1" class="border">
       <tr>
        <td class="win">
         <table cellpadding="4" cellspacing="0" width="100%">
          <tr>
           <td style="width: 30%" class="vtop right"><strong>$memtext[69]:</strong></td>
           <td><a href="javascript:use('[face=Verdana]','[/face]');"><img src="$images/face.gif" alt="$var{'8'}" /></a>
            <a href="javascript:use('[b]','[/b]');"><img src="$images/bold.gif" alt="$var{'10'}" /></a>
            <a href="javascript:use('[i]','[/i]');"><img src="$images/italics.gif" alt="$var{'11'}" /></a>
            <a href="javascript:use('[u]','[/u]');"><img src="$images/underline.gif" alt="$var{'12'}" /></a>
            <a href="javascript:use('[left]','[/left]');"><img src="$images/left.gif" alt="$var{'13'}" /></a>
            <a href="javascript:use('[center]','[/center]');"><img src="$images/center.gif" alt="$var{'14'}" /></a>
            <a href="javascript:use('[right]','[/right]');"><img src="$images/right.gif" alt="$var{'15'}t" /></a><br />
            <a href="javascript:use('[pre]','[/pre]');"><img src="$images/pre.gif" alt="$var{'16'}" /></a>
            <a href="javascript:use('[s]','[/s]');"><img src="$images/strike.gif" alt="$var{'17'}" /></a>
            <a href="javascript:use('[url]','[/url]');"><img src="$images/url.gif" alt="$var{'21'}" /></a>
            <a href="javascript:use('[mail]','[/mail]');"><img src="$images/email_click.gif" alt="$var{'22'}" /></a>
            <a href="javascript:use('[img]','[/img]');"><img src="$images/img.gif" alt="$var{'23'}" /></a>
            <a href="javascript:use('[hr]');"><img src="$images/hr.gif" alt="$var{'25'}" /></a>
            <a href="javascript:use('[list]\\n[*]','\\n[/list]');"><img src="$images/list.gif" alt="$var{'18'}" /></a>
           </td>
          </tr>
         </table>
        </td>
       </tr><tr>
        <td class="win2">
         <table cellpadding="4" cellspacing="0" width="100%">
          <tr>
           <td class="right" style="width: 30%"><strong>$memtext[68]:</strong></td>
           <td><input type="text" name="subject" maxlength="50" size="35" /></td>
          </tr><tr>
           <td class="vtop right" style="width: 30%"><strong>$memtext[70]:</strong></td>
           <td class="vtop"><textarea name="message" cols="1" rows="1" style="width: 95%; height: 90px;"></textarea></td>
          </tr><tr>
           <td colspan="2" class="smalltext">$memtext[71]</td>
          </tr>
         </table>
        </td>
       </tr>
      </table>
     </td>
    </tr>
   </table>
  </td>
 </tr><tr>
  <td class="win center"><input type="submit" id="submit" name="submit" value=" $memtext[72] " /></td>
 </tr>
</table>
</form>
<br />
<table cellpadding="5" cellspacing="1" class="border" width="98%">
 <tr>
  <td class="titlebg">$memtext[261]</td>
 </tr><tr>
  <td class="win3"><textarea cols="1" rows="1" style="width: 99%; height: 90px;">$fulllist</textarea></td>
 </tr>
</table>
EOT
	footerA();
	exit;
}

sub Mailing2 {
	is_admin(3.2);

	@emails = split(',',$FORM{'emails'});
	if(@emails < 1) { error($gtxt{'bfield'}); }

	$subject = $FORM{'subject'};
	if($subject eq '') { error($gtxt{'bfield'}); }
	$message = Format($FORM{'message'});
	error($gtxt{'long'}) if(length($message) > $maxmesslth && $maxmesslth);

	if($message eq '') { error($gtxt{'bfield'}); }
	if($al) {
		$message =~ s~([^\w\"\=\[\]]|[\n\b]|\A)\\*(\w+://[\w\~\.\;\:\$\-\+\!\*\?/\=\&\@\#\%]+\.[\w\~\;\:\$\-\+\!\*\?/\=\&\@\#\%,.]+[\w\~\;\:\$\-\+\!\*\?/\=\&\@\#\%])~$1<a href="$2"$blanktarget>$2</a>~isg;
		$message =~ s~([^\"\=\[\]/\:\.(\://\w+)]|[\n\b]|\A)\\*(www\.[^\.][\w\~\.\;\:\$\-\+\!\*\?/\=\&\@\#\%]+\.[\w\~\;\:\$\-\+\!\*\?/\=\&\@\#\%\,]+[\w\~\;\:\$\-\+\!\*\?/\=\&\@\#\%])~$1<a href="http://$2"$blanktarget>$2</a>~isg;
	}
	$message =~ s~\[b\](.*?)\[/b\]~<strong>$1</strong>~gsi;
	$message =~ s~\[i\](.*?)\[/i\]~<i>$1</i>~gsi;
	$message =~ s~\[u\](.*?)\[/u\]~<u>$1</u>~gsi;
	$message =~ s~\[s\](.*?)\[/s\]~<s>$1</s>~gsi;
	$message =~ s~\[size=(.*?)\](.*?)\[/size\]~<span style="font-size: $1px">$2</span>~gsi;
	$message =~ s~\[img\]http://(.*?)\[/img\]~<img src="http://$1" alt="" />~gsi;
	$message =~ s~\[url=http://(.*?)\](.*?)\[/url\]~<a href="http://$1">$2</a>~gsi;
	$message =~ s~\[url\]http://(.*?)\[/url\]~<a href="http://$1">$1</a>~gsi;
	$message =~ s~\[left\](.+?)\[/left\]~<div style="text-align: left">$1</div>~gsi;
	$message =~ s~\[right\](.+?)\[/right\]~<div style="text-align: right">$1</div>~gsi;
	$message =~ s~\[center\](.+?)\[/center\]~<div style="text-align: center">$1</div>~gsi;
	$message =~ s~\[pre\](.+?)\[/pre\]~<pre>$1</pre>~gsi;

	$message =~ s~\[face=(.+?)\](.+?)\[/face\]~<span style="font-family: $1">$2</span>~gsi;
	$message =~ s~\[color=(.+?)\](.+?)\[/color\]~<span style="color: $1">$2</span>~gsi;
	$message =~ s~\[hr\]~<hr />~gsi;
	$message =~ s~\[mail\](.+?)\[/mail\]~<a href="mailto:$1">$1</a>~gsi;
	$message =~ s~\[mail=(.+?)\](.+?)\[/mail\]~<a href="mailto:$1">$2</a>~gsi;
	if($message =~ /\[list\]/) {
		$message =~ s~\[list\](.+?)\[/list\]~<ul>$1</ul>~gsi;
		$message =~ s~\[\*\]~<li>~gsi;
	}
	foreach (@emails) {
		GetMemberID($_);
		$message2 = $message; # Temp
		$message =~ s~\[username\]~$_~gsi;
		$message =~ s~\[screenname\]~$memberid{$_}{'sn'}~gsi;
		$message =~ s~\[password\]~$memberid{$_}{'password'}~gsi;
		$message =~ s~\[email\]~$memberid{$_}{'email'}~gsi;
		smail($memberid{$_}{'email'},$subject,$message,$memberid{$username}{'sn'});
		$message = $message2; # Restore Original
	}
	redirect("$surl\lv-admin/r-3/");
}

sub Validate {
	is_admin(3.5);

	if($URL{'p'} == 2) { Validate2(); }
	fopen(FILE,"$members/List.txt");
	@list = <FILE>;
	fclose(FILE);
	chomp @list;
	foreach(@list) {
		GetMemberID($_);
		if($memberid{$_}{'status'}) { $memberid{$_}{'status'} =~ s/\|/&#124;/gsi; push(@members,"$memberid{$_}{'status'}|$_"); ++$type{$memberid{$_}{'status'}}; }
	}
	@members = sort{$a cmp $b} @members;

	$title = $memtext[73];
	headerA();
	$ebout .= <<"EOT";
<script type="text/javascript">
//<![CDATA[
function deleteme(user) {
 if(window.confirm("$memtext[161]")) { location = "$surl\lv-admin/a-validate/p-2/u-"+user+'/delete-1/'; }
}
//]]>
</script>
<table cellpadding="4" cellspacing="1" class="border" width="600">
 <tr>
  <td class="titlebg"><strong><img src="$images/profile_sm.gif" alt="" /> $title</strong></td>
 </tr><tr>
  <td class="win smalltext">$memtext[155]</td>
 </tr><tr>
  <td class="win2"><table cellpadding="5" cellspacing="0" width="98%"><tr>
EOT
	foreach(sort{$b <=> $a} @members) {
		($atype,$uname) = split(/\|/,$_);
		if(!$noshow{$atype}) {
			if($counter == 1) { $ebout .= "<td>&nbsp;</td></tr><tr>"; $counter = 0; }
			if($counter == 2) { $ebout .= "</tr><tr>\n"; $counter = 0; }
			if($atype eq 'ADMIN') { $type = $memtext[149]; }
			elsif($atype eq 'EMAIL&#124;ADMIN') { $type = $memtext[150]; }
			elsif($atype eq 'EMAIL') { $type = $memtext[151]; }
				else { $type = $memtext[152]; }
			$ebout .= <<"EOT";
$next<td colspan="2" class="win smalltext"><strong>$type</strong> ($type{$atype})</td></tr><tr>
EOT
			++$add;
			$noshow{$atype} = 1;
		}
		$datereg = get_date($memberid{$uname}{'registered'});
		$ebout .= <<"EOT";
$next<td style="width: 50%"><strong>$userurl{$uname}</strong> <a href="mailto:$memberid{$uname}{'email'}"><img src="$images/email_sm.gif" alt="" /></a><br /><span class="smalltext"><strong>$memtext[153]:</strong> $datereg<br />&nbsp;&#149; <a href="$surl\lv-admin/a-validate/p-2/u-$uname/">$memtext[83]</a><br />&nbsp;&#149; <a href="javascript:deleteme('$uname');">$memtext[162]</a></span><br /><br /></td>
EOT
		++$counter;
		if($counter == 2) { $next = "</tr><tr>\n"; $counter = 0; } else { $next = ''; }
	}
	if($counter == 1) { $ebout .= "<td>&nbsp;</td></tr>"; }
	if(!$add) {
		$ebout .= <<"EOT";
<td colspan="2">$memtext[84]</td></tr>
EOT
	}
	$ebout .= <<"EOT";
  </table></td>
 </tr>
</table>
EOT
	footerA();
	exit;
}

sub Validate2 {
	is_admin(3.5);

	if($URL{'delete'}) {
		CoreLoad('Moderate');
		KillGroups($URL{'u'},3);
	}
		else {
			GetMemberID($URL{'u'});

			if($memberid{$URL{'u'}}{'status'} eq 'ADMIN') {
				$subject = $memtext[156];
				$message = qq~$memtext[157] "$mbname".<br /><br /><a href="$rurl">$mbname</a><br /><br />$gtxt{'25'}~;
			}

			SaveMemberID(
				$URL{'u'},
				%addtoID = (
					'status'     => '',
					'validation' => ''
				)
			);

			smail($memberid{$URL{'u'}}{'email'},$subject,$message);
		}

	redirect("$surl\lv-admin/a-validate/");
}

sub RemoveMembers {
	is_admin(3.3);

	if($URL{'p'}) { RemoveMembers2(); }
	$title = $memtext[146];
	headerA();
	$ebout .= <<"EOT";
<script type="text/javascript">
//<![CDATA[
function check() {
 for(i = 0; i < document.forms['admin'].elements.length; i++) {
  if(document.forms['admin'].c.checked) { document.forms['admin'].elements[i].checked = true; }
   else { document.forms['admin'].elements[i].checked = false; }
 }
}
function ConfirmSubmit() {
	if(window.confirm('$memtext[172]')) { return true; } else { return false; }
}
//]]>
</script>
<form action="$surl\lv-admin/a-removemembers/p-2/" method="post" id="admin" onsubmit="return ConfirmSubmit()">
<table class="border" cellpadding="4" cellspacing="1" width="98%">
 <tr>
  <td class="titlebg"><strong><img src="$images/profile_sm.gif" alt="" /> $title</strong></td>
 </tr><tr>
  <td class="win smalltext">$memtext[135]</td>
 </tr><tr>
  <td class="win2">
   <table cellpadding="8" cellspacing="0" width="100%">
    <tr>
     <td style="width: 225px" class="catbg smalltext"><strong>$memtext[115]</strong></td>
     <td style="width: 200px" class="catbg smalltext"><strong>$memtext[163]</strong></td>
     <td style="width: 200px" class="catbg smalltext"><strong>$memtext[171]</strong></td>
     <td style="width: 20px" class="catbg smalltext"><strong>$memtext[2]</strong></td>
    </tr>
EOT
	fopen(FILE,"$members/List.txt");
	@list = <FILE>;
	fclose(FILE);
	chomp @list;

	foreach(@list) {
		GetMemberID($_);
		if(!$memberid{$_}{'sn'}) { next; }
		if($FORM{'email'} && $memberid{$_}{'email'} !~ /$FORM{'email'}/i) { next; }
		if($FORM{'name'} && ($memberid{$_}{'sn'} !~ /$FORM{'name'}/i && $_ !~ /$FORM{'name'}/i)) { next; }

		push(@tlist,$_);
	}

	$thelist = @tlist || 1;
	$tstart = $URL{'s'} || 0;
	$end = $URL{'s'}+50;
	$tstart = (int($tstart/50)*50);

	$pagecount = 1;
	for($i = 0; $i < $thelist; $i += 50) {
		if($i == $tstart || $thelist < 50) { $pagelinks .= "<strong>$pagecount</strong>, "; }
			else { $pagelinks .= qq~<a href="$surl\lv-admin/a-removemembers/s-$i/">$pagecount</a>, ~; }
		++$pagecount;
	}
	$pagelinks =~ s/, \Z//gsi;

	@list = ();
	for($i = 0; $i < @tlist; ++$i) {
		if($i <= $end && $i >= $tstart) { push(@list,$tlist[$i]); }
	}

	foreach(@list) {
		$check = $_ ne $username ? qq~<input type="checkbox" name="$_" value="1" />~ : '';

		if($memberid{$_}{'lastactive'}) { $lastactive = get_date($memberid{$_}{'lastactive'}); }
			else { $lastactive = "Unknown"; }
		$ebout .= <<"EOT";
    <tr>
     <td class="smalltext">$check $userurl{$_} &nbsp; (<i>$_</i>)</td>
     <td class="win smalltext"><a href="mailto:$memberid{$_}{'email'}"><img src="$images/email_sm.gif" alt="" />&nbsp; $memberid{$_}{'email'}</a></td>
     <td class="smalltext">$lastactive</td>
     <td class="win smalltext right">$memberid{$_}{'posts'}</td>
    </tr>
EOT
	}
	if(@list == 0) {
		$ebout .= <<"EOT";
<tr>
 <td colspan="4" class="center"><br /><strong>$memtext[170]</strong><br /><br /></td>
</tr>
EOT
	}

	$ebout .= <<"EOT";
   </table>
  </td>
 </tr><tr>
  <td class="win">
   <table cellpadding="0" cellspacing="0" width="100%"><tr>
    <td style="width: 25px"><input type="checkbox" name="c" value="1" onclick="check();" /></td>
    <td class="smalltext"><strong>$gtxt{17}:</strong> $pagelinks</td>
    <td class="right" style="width: 270px"><input type="submit" value="$memtext[137]" /></td>
   </tr></table>
  </td>
 </tr>
</table>
</form><br />
<form action="$surl\lv-admin/a-removemembers/" method="post">
<table class="border" cellpadding="4" cellspacing="1" width="98%">
 <tr>
  <td class="catbg"><strong>$memtext[144]</strong></td>
 </tr><tr>
  <td class="win2">
   <table cellpadding="8" cellspacing="0">
    <tr>
     <td style="width: 200px" class="right smalltext"><strong>$memtext[145]:</strong></td>
     <td><input type="text" name="name" /></td>
    </tr><tr>
     <td class="right smalltext"><strong>$memtext[163]:</strong></td>
     <td><input type="text" name="email" /></td>
    </tr><tr>
     <td>&nbsp;</td>
     <td><input type="submit" value=" $memtext[143] " /></td>
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

sub RemoveMembers2 {
	is_admin(3.3);

	while(($deluser,$t) = each(%FORM)) {
		if($deluser eq $username) { next; }
		$killymems .= "$deluser,";
		$good = 1;
	}
	if(!$good) { error($gtxt{'bfield'}); }
	CoreLoad('Moderate');
	KillGroups($killymems,2);
	redirect("$surl\lv-admin/r-3/");
}

sub ExtendProfile  {
	is_admin(3.6);

	if($URL{'p'} eq 'save') { ExtendProfile2(); }

	$title = "Extra Profile Options";
	headerA();
	fopen(FILE,"$prefs/ProfileSections.txt");
	@profilesections = <FILE>;
	fclose(FILE);
	chomp @profilesections;

	fopen(FILE,"$prefs/ProfileSubsections.txt");
	@sections = <FILE>;
	fclose(FILE);
	chomp @sections;
	foreach(@sections) {
		($id,$grpname) = split(/\|/,$_);
		$sections{$id} = $_;
		push(@grps,"$id|$grpname");
	}

	fopen(FILE,"$prefs/ProfileVariables.txt");
	@sections = <FILE>;
	fclose(FILE);
	chomp @sections;
	foreach(@sections) {
		($t,$id) = split(/\|/,$_);
		$option{$id} = $_;
	}

	foreach(@profilesections) {
		($sectid,$sectionname,$sortedids) = split(/\|/,$_);

		push(@sects,"$sectid|$sectionname");
	}

	$ebout .= <<"EOT";
<form action="$surl\lv-admin/a-extend/p-save/" method="post">
EOT

	foreach(@profilesections) {
		($sectid,$sectionname,$sortedids) = split(/\|/,$_);

		$ssopt = '';

		++$countar;

		foreach $temp (@sects) {
			($tsectid,$tsectname) = split(/\|/,$temp);
			$selected = '';
			$selected = ' selected="selected"' if($tsectid eq $sectid);
			$ssopt .= qq~<option value="$tsectid"$selected>$tsectname</option>~;
		}

		$ebout .= <<"EOT";
<table cellpadding="5" cellspacing="1" class="border" width="98%">
 <tr>
  <td colspan="2" class="titlebg"><span style="float: right" class="lessimp">Section Name</span><input type="input" name="top_$sectid" value="$sectionname" size="30"> order <input type="text" name="counter_$sectid" value="$countar" /></td>
 </tr>
EOT

		foreach $sidss (split(/\//,$sortedids)) {
			($t,$subsectionname,$options,$image) = split(/\|/,$sections{$sidss});
			$ebout .= <<"EOT";
 <tr>
  <td colspan="2" class="catbg"><span style="float: right" class="lessimp">Sub-section Name</span><img src="$images/subdown.gif" alt="" /> <input type="input" name="mid_$t" value="$subsectionname" size="30"> under <select name="section_$t">$ssopt</select></td>
 </tr><tr>
  <td class="win2 vtop right" style="width: 35px"><img src="$images/subdown.gif" alt="" />&nbsp;</td>
  <td class="win" style="padding: 0px">
   <table cellpadding="5" cellspacing="0" width="100%">
    <tr class="win3">
     <td class="smalltext"><strong>Grouping Name</strong></td>
	 <td class="smalltext center"><strong>ID</strong></td>
	 <td class="smalltext center"><strong>Variable Name</strong></td>
	 <td class="smalltext center"><strong>Option Type</strong></td>
	 <td class="smalltext center"><strong>Allowed Values</strong></td>
	 <td class="smalltext right"><strong>Section</strong></td>
	</tr>
EOT
			@options = ();
			foreach $opts (split(/\//,$options)) { push(@options,$option{$opts}); }
			@sections = sort {$a cmp $b} @sections;

			$groups = '';

			foreach $tsect (@grps) {
				($tid,$tname) = split(/\|/,$tsect);
				if($tid eq $t) { $selected = ' selected="selected"'; } else { $selected = ''; }
				$groups .= qq~<option value="$tid"$selected>$tname</option>~;
			}

			foreach $topts (@options) {
				($subsubsect,$optionvar,$option,$type,$values) = split(/\|/,$topts);
					if($subsubsect ne $oldvalue) { $oldvalue = $subsubsect; $ebout .= qq~<tr><td class="catbg" colspan="6">$subsubsect</td></tr>~; }
					%select = ();
					$select{$type} = ' selected="selected"';
					$values =~ s/\//\n/g;

					$ebout .= <<"EOT";
    <tr>
     <td><input type="input" name="low_$optionvar" value="$subsubsect" /></td>
     <td class="center">$optionvar</td>
     <td class="center"><input type="input" name="option_$optionvar" value="$option" /></td>
     <td class="center"><select name="type_$optionvar"><option value="1"$select{1}>Checkbox</option><option value="2"$select{2}>Text Input</option><option value="3"$select{3}>Select</option><option value="4"$select{4}>Textarea</option></select></td>
     <td class="center"><textarea style="width: 100%;" name="input_$optionvar">$values</textarea></td>
	 <td class="right"><select name="group_$optionvar">$groups</select></td>
    </tr>
EOT
			}
			$ebout .= <<"EOT";
    <tr>
	 <td class="catbg" colspan="6">New Variable</td>
	</tr><tr class="win4">
     <td><input type="input" name="new_low_$t" value="" /></td>
     <td class="center">*</td>
     <td class="center"><input type="input" name="new_option_$t" value="" /></td>
     <td class="center"><select name="new_type_$t"><option value="1">Checkbox</option><option value="2">Text Input</option><option value="3">Select</option><option value="4">Textarea</option></select></td>
     <td class="center"><textarea style="width: 100%;" name="new_input_$t"></textarea></td>
	 <td></td>
    </tr>
   </table>
  </td>
 </tr>
EOT
			$ebout .= qq~~;
		}
		$ebout .= <<"EOT";
 <tr>
  <td colspan="2" class="catbg"><span style="float: right" class="lessimp">Sub-section Name</span><img src="$images/subdown.gif" alt="" /> * <input type="input" name="mid_new_$sectid" value="" size="30"> under $sectionname</td>
 </tr>
</table><br />
EOT
	}

	++$countar;

	$ebout .= <<"EOT";
<table cellpadding="5" cellspacing="1" class="border" width="98%">
 <tr>
  <td colspan="2" class="titlebg"><span style="float: right" class="lessimp">Section Name</span>* <input type="input" name="top_new_new" value="" size="30"> order <input type="text" name="counter_new_new" value="$countar" /></td>
 </tr>
</table>
<br />
<table cellpadding="5" cellspacing="1" class="border" width="98%">
 <tr>
  <td class="center win"><input type="submit" value="Save" /></td>
 </tr>
</table>
</form>
EOT

	footerA();
	exit;
}

sub ExtendProfile2 {
	is_admin(3.6);

	my($opts);

	while(($name,$id) = each(%FORM)) {
		($type,$goesto,$newobs) = split("_",$name);

		if($goesto eq 'new' && $newobs eq 'new' && $type eq 'top') {
			if($type ne 'top' || $FORM{'top_new_new'} eq '') { next; }
			$hrmp = int(rand(time));
			push(@sectionsmap,qq~$FORM{'counter_new_new'}|$hrmp|$FORM{'top_new_new'}~);
			next;
		}
		elsif($goesto eq 'new' && $type eq 'mid') {
			next if($FORM{"mid_new_$newobs"} eq '');
			$id = int(rand(time));
			$sectiondata{$newobs} .= "$id/";
			push(@subsectmap,qq~$id|$FORM{"mid_new_$newobs"}~);
			next;
		}
		elsif($type eq 'new' && $goesto eq 'option') {
			next if($FORM{"new_option_$newobs"} eq '');
			$goesto = int(rand(time));
			$optiongroups{$newobs} .= "$goesto/";
			$opts .= qq~$FORM{"new_low_$newobs"}|$goesto|$FORM{"new_option_$newobs"}|$FORM{"new_type_$newobs"}|$FORM{"new_input_$newobs"}\n~;
			next;
		} elsif($type eq 'top') {
			next if($id eq '');
			push(@sectionsmap,qq~$FORM{"counter_$goesto"}|$goesto|$id~);
			next;
		} elsif($type eq 'section') {
			if($FORM{"mid_$goesto"} eq '') { next; }
			$sectiondata{$id} .= "$goesto/";
			next;
		} elsif($type eq 'mid') {
			push(@subsectmap,"$goesto|$id");
			next;
		} elsif($type eq 'option') {
			#if($FORM{"mid_$FORM{"group_$goesto"}"} eq '') { next; }

			if($FORM{"option_$goesto"} eq '') { next; }

			$FORM{"input_$goesto"} =~ s/\///g;
			$FORM{"input_$goesto"} =~ s/\n/\//g;
			$FORM{"input_$goesto"} =~ s/\r//g;
			$opts .= qq~$FORM{"low_$goesto"}|$goesto|$FORM{"option_$goesto"}|$FORM{"type_$goesto"}|$FORM{"input_$goesto"}\n~;
			$optiongroups{$FORM{"group_$goesto"}} .= qq~$goesto/~;
			next;
		}
	}

	fopen(FILE,">$prefs/ProfileVariables.txt");
	print FILE "$opts";
	fclose(FILE);

	fopen(FILE,">$prefs/ProfileSubsections.txt");
	foreach(@subsectmap) {
		($subid,$subname) = split(/\|/,$_);
		$optiongroups{$subid} =~ s/\/\Z//g;
		print FILE "$subid|$subname|$optiongroups{$subid}\n";
	}
	fclose(FILE);

	fopen(FILE,">$prefs/ProfileSections.txt");
	foreach(sort {$a <=> $b} @sectionsmap) {
		($t,$goesto,$id) = split(/\|/,$_);
		$sectiondata{$goesto} =~ s/\/\Z//g;
		print FILE "$goesto|$id|$sectiondata{$goesto}\n";
	}
	fclose(FILE);

	redirect("$surl\lv-admin/a-extend/");
}
1;