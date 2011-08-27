#############################################
# E-Blah Bulletin Board Systems        2008 #
#############################################
# Copyright (c) 2001 - 2008 E-Blah.         #
#############################################

use Time::Local 'timelocal';

CoreLoad('Calendar',1);

$mondaystart = 0; # Start on Monday .... probably DOES NOT work ...

{
	# Get the member group managers
	foreach(@fullgroups) {
		foreach $un (split(",",$permissions{$_,'manager'})) {
			$managers{$_,$un} = 1;
			$manager{$un} = 1;
		}
	}
}

sub CalendarLoad {
	my($mstart);
	if($URL{'a'} eq 'rss') { CalendarRSS(); }
	elsif($URL{'a'} eq 'search') { CalendarSearch(); }

	$tmonth = $URL{'month'} ? $URL{'month'}-1 : $Kmonth;
	$tyear = $URL{'year'} ? $URL{'year'} : $Kyear;
	eval { $mstart = timelocal(1,1,1,1,$tmonth,$tyear-1900,1); };

	GetBirthdays();
	GetEvents();

	$title = $calendar[66];
	header();

	$ebout .= <<"EOT";
<table cellpadding="0" cellspacing="0" width="100%">
 <tr>
  <td class="vtop" style="width: 75%">
EOT
	if($URL{'week'} ne '') {
		$ebout .= WeekView($mstart);
	} elsif($URL{'day'} ne '') {
		$ebout .= DayView($mstart);
	} else {
		$ebout .= MonthView($mstart);
		$ebout .= <<"EOT";
<form action="$surl\lv-cal/a-search/" method="post">
<table cellspacing="1" cellpadding="5" width="100%" class="border">
 <tr>
  <td class="titlebg">$calendar[114]</td>
 </tr><tr>
  <td class="win" style="padding: 0px">
   <table cellpadding="7" cellspacing="0" width="100%">
    <tr>
     <td style="width: 200px"><strong>$calendar[44]:</strong></td>
     <td><input type="text" name="title" size="35" /></td>
    </tr><tr>
     <td><strong>$calendar[115]:</strong></td>
     <td><input type="text" name="description" size="40" /></td>
    </tr><tr>
     <td><strong>$calendar[116]</strong></td>
     <td><input type="checkbox" name="personal" value="1" /></td>
    </tr><tr>
     <td><strong>$calendar[117]:</strong></td>
     <td><input type="text" name="startm" size="3" maxlength="2" /> - <input type="text" name="endm" size="3" maxlength="2" /></td>
    </tr><tr>
     <td><strong>$calendar[118]:</strong></td>
     <td><input type="text" name="starty" size="5" maxlength="4" /> - <input type="text" name="endy" size="5" maxlength="4" /></td>
    </tr><tr>
     <td class="win2" colspan="2"><input type="submit" value="$calendar[119]" /></td>
    </tr>
   </table>
  </td>
 </tr>
</table>
</form>
EOT
	}

	$ebout .= qq~</td><td>&nbsp;</td><td class="vtop">~;

	if(!$URL{'week'} && !$URL{'day'}) {
		$ebout .= MonthView(GetMonthData($mstart,1),1,$calendar[64])."<br />";
		$ebout .= MonthView(GetMonthData($mstart,2),2,$calendar[65])."<br />";
	} else {
		$ebout .= MonthView($mstart,1,$calendar[63],$URL{'week'}).'<br />';
	}
	OtherOptions($mstart);

	$ebout .= <<"EOT";
  </td>
 </tr>
</table>
EOT

	footer();
	exit;
}

sub DayView {
	my($dayview);
	my($getmonth) = @_;
	($day,$month,$year,$weekday,$yearday) = GetMonthData($getmonth);

	$dayview = <<"EOT";
<script type="text/javascript">
//<![CDATA[
function showid(id) {
	if(document.getElementById("event" + id).style.display == 'none') {
		document.getElementById("img" + id).src = "$images/minimize.gif";
		document.getElementById("event" + id).style.display = "";
	}
		else {
			document.getElementById("img" + id).src = "$images/expand.gif";
			document.getElementById("event" + id).style.display = "none";
		}
}
//]]>
</script>
<table cellpadding="5" cellspacing="1" class="border" width="100%">
 <tr>
  <td class="titlebg" colspan="8"><strong>$URL{'day'} $months[$month-1] $year</strong></td>
 </tr>
EOT
	$week = 1;
	$days = CheckDays($month-1,$year);
	$grrmonth = $month;

	for($i = $weekday; $i <= 7; $i++) {
		if($daycnt == $URL{'day'}) {
			$dayview .= <<"EOT";
 <tr>
  <td class="catbg center">$days[$i-1]</td>
 </tr><tr>
  <td class="win2" style="padding: 1px">
   <table cellpadding="5" cellspacing="0" width="100%">
EOT

			@events = GetPerDayEvent($daycnt, $i, $month, $year, $week, $getmonth, 1); # Day, Weekday, Month, Year, Week, timestamp, $array return

			chomp @events;

			if(@events) {
				foreach $ievents (@events) {
					($owner,$groups,$id,$start,$end,$repeatevery,$xdays,$bgcolor,$title,$desc,$startendtime) = split(/\|/,$ievents);
					push(@dayview,"$start|$end|$owner|$groups|$id|$repeatevery|$xdays|$bgcolor|$title|$desc|$startendtime");
				}

				foreach $ievents (sort {$a <=> $b} @dayview) {
					($start,$end,$owner,$groups,$id,$repeatevery,$xdays,$bgcolor,$title,$desc,$startendtime) = split(/\|/,$ievents);

					GetMemberID($owner);
					$desc = BC($desc);

					($stime,$etime) = split(/\//,$startendtime);

					if(!$stime) { $notime_date = 1; }

					$start = get_date($start,1,1);

					if(CalendarPermissions($groups,$owner,1)) { $modifyable = qq~<div style="float: right; text-align: right; width: 200px;"><a href="$surl\lv-mod/a-calendar/p-edit/n-$id/">$Pimg{'modify'}</a>$Pmsp2<a href="#" onclick="if(window.confirm('$calendar[67]')) { location='$surl\lv-mod/a-calendar/p-delete/n-$id/'; }">$Pimg{'remove'}</a></div>~; }

					if($memberid{$owner}{'sn'}) { $owner = $userurl{$owner}; }

					$dayview .= <<"EOT";
    <tr>
     <td class="win2" colspan="2" style="background-color:$bgcolor; padding: 5px;" onclick="javascript:showid('$id');">
      <div class="calendarevent" style="float: left;">$title</div>$modifyable
     </td>
     <td class="win2" style="background-color:$bgcolor; padding: 5px; width: 1px"><a href="#" onclick="javascript:showid('$id'); return false;"><img src="$images/expand.gif" id="img$id" alt="" /></a></td>
    </tr><tr style="display: none" id="event$id">
     <td class="win3 vtop" style="width: 250px">
      <table cellpadding="4" cellspacing="0" width="100%">
       <tr>
        <td><strong>$calendar[68]</strong></td>
       </tr><tr>
        <td class="win2">$owner</td>
       </tr><tr>
        <td><strong>$calendar[69]</strong></td>
       </tr><tr>
        <td class="win2">$start</td>
       </tr>
EOT
					if($end) {
						if(!$etime) {
							$notime_date = 1;
						}
						$end = get_date($end,1,1);
						$dayview .= <<"EOT";
       <tr>
        <td><strong>$calendar[70]</strong></td>
       </tr><tr>
        <td class="win2">$end</td>
       </tr>
EOT
					}
					if($repeatevery) {
						$dayview .= <<"EOT";
       <tr>
        <td class="center"><i>$calendar[71]</i></td>
       </tr>
EOT
					}
					$dayview .= <<"EOT";
      </table>
     </td>
     <td class="win vtop">$desc</td>
     <td class="win2" style="background-color:$bgcolor; padding: 5px; width: 1px">&nbsp;</td>
    </tr><tr>
     <td class="win3" style="height: 3px" colspan="3"></td>
    </tr><tr>
     <td class="border" style="height: 3" colspan="3"></td>
    </tr>
EOT
				}
			}
			last;
		}

		if($i == 7) { ++$week; $i = 0; }

		if($days == $daycnt) { last; }
		++$daycnt;
	}

	if($BirthDay{"$grrmonth|$daycnt"}) {
		$birthdays = qq~<ol type="$1">~;
		foreach(split(',',$BirthDay{"$grrmonth|$daycnt"})) {
			GetMemberID($_);
			$age = calage($memberid{$_}{'dob'});
			$birthdays .= "<li>".$userurl{$_}." - $calendar[72] $age $calendar[73]</li>";
		}
		$birthdays =~ s/, \Z//g;
		$birthdays .= "</ol>";
	}
	$BirthDayC{"$grrmonth|$daycnt"} = $BirthDayC{"$grrmonth|$daycnt"} || 0;

	$dayview .= <<"EOT";
    <tr>
     <td class="win2" style="height: 3px; padding: 10px" colspan="3">$calendar[74] $BirthDayC{"$grrmonth|$daycnt"} $calendar[75]<br />$birthdays</td>
    </tr>
   </table>
  </td>
 </tr>
</table>
EOT

	return($dayview);
}

sub MonthView {
	my($caladd,$monthview,$classes);
	my($getmonth,$quickview,$fulltext,$gettheweek) = @_;
	($day,$month,$year,$weekday,$yearday) = GetMonthData($getmonth); # Finally a lovely little area to pick this up at!

	$classes = $quickview ? ' class="smalltext"' : '';
	$specialwidth = !$quickview ? 14 : 13;

	if($fulltext ne '') { $fulltext = qq~<a href="$surl\lv-cal/month-$month/year-$year/" rel="nofollow">$fulltext</a>~; }

	$monthview .= <<"EOT";
<table cellpadding="5" cellspacing="1" class="border" width="100%">
 <tr>
  <td class="titlebg" colspan="8"><div style="float: left"$classes><strong><a href="$surl\lv-cal/month-$month/year-$year/" rel="nofollow">$months[$month-1] $year</a></strong></div><div style="float: right"$classes>$fulltext</div></td>
 </tr><tr>
  <td class="catbg">&nbsp;</td>
EOT
	for($i = 0; $i < 7; ++$i) {
		if($mondaystart) { $caladd = $i < 6 ? 1 : -6; } # May not work!
		$curday = !$quickview ? $days[$i+$caladd] : $smdlist[$i+$caladd];

		$monthview .= <<"EOT";
  <td class="catbg center" style="width: $specialwidth%"><div$classes><strong>$curday</strong></div></td>
EOT
	}
	if($mondaystart) { $weekday = $weekday >= 1 ? $weekday-1 : 6; }

	$monthview .= " </tr>";

	$specialheight = !$quickview ? 90 : 30;
	$fancyinside = !$quickview ? '&nbsp;&rsaquo;&nbsp;<br />&nbsp;&rsaquo;&nbsp;<br />&nbsp;&rsaquo;&nbsp;' : '&rsaquo;';

	$lweek = 0;
	if($weekday > 0) {
		$monthview .= <<"EOT";
 <tr>
  <td class="win center"><span style="font-size: 12px"$classes><strong><a href="$surl\lv-cal/month-$month/year-$year/week-1/" rel="nofollow">$fancyinside</a></strong></span></td>
  <td class="win3" style="height: $specialheight\lpx" colspan="$weekday">&nbsp;</td>
EOT

		$lweek = 1;
	}
	$days = CheckDays($month-1,$year);

	# Yay: It's time to start the rest of this biz (the days!)
	$week = 1;
	$daycnt = 1;
	for($i = $weekday+1; $i <= 7; $i++) {
		if($week != $lweek) {
			$monthview .= <<"EOT";
 <tr>
  <td class="win center" style="height: $specialheight\lpx"><span style="font-size: 12px"$classes><strong><a href="$surl\lv-cal/month-$month/year-$year/week-$week/" rel="nofollow">$fancyinside</a></strong></span></td>
EOT
			$lweek = $week;
		}

		$dayfade = '';
		if($Kday == $daycnt && $Kmonth == $month-1 && $Kyear == $year) { $dayfade = qq~ currentday~; }
			else {
				$style = !$quickview ? 'padding: 1px;' : '';
				if($week == $gettheweek) { $dayfade = ' currentday'; }
			}

		$events = GetPerDayEvent($daycnt, $i, $month, $year, $week, $getmonth); # Day, Weekday, Month, Year, Week, timestamp

		if($BirthDayC{"$month|$daycnt"}) { # This may be put into it's on sub
			$BirthDayL{"$month|$daycnt"} =~ s/\n\Z//g;
			$birthdays = qq~<div style="padding: 4px;">$BirthDayC{"$month|$daycnt"} $calendar[40]</div>~;
		}
			else { $birthdays = ''; }

		if($birthdays ne '' || $events ne '') { $dayurl = qq~<a href="$surl\lv-cal/month-$month/year-$year/day-$daycnt/" rel="nofollow">$daycnt</a>~; $newurl = qq~ onclick="location='$surl\lv-cal/month-$month/year-$year/day-$daycnt/'"~; $style .= " cursor: pointer"; } else { $dayurl = $daycnt; $newurl = ''; }

		if(!$quickview) {
			$monthview .= <<"EOT";
  <td class="win2$dayfade vtop" style="padding: 0px; height: $specialheight\lpx $style"$newurl>
    <div class="win right" style="padding: 5px;"><strong>$dayurl</strong></div>
    <div class="smalltext" style="margin: 0px;">$events$birthdays</div>
  </td>
EOT
		} else {
			$monthview .= <<"EOT";
  <td class="win2$dayfade center" style="$style"$newurl><div$classes>$dayurl</div></td>
EOT
		}

		if($i == 7 && $days > $daycnt) {
			++$week;
			$monthview .= '</tr>'; $i = 0;
		}
		if($days == $daycnt) { last; }
		++$daycnt;
	}

	if($i != 7) {
		$alldays = 7-$i;
		$monthview .= <<"EOT";
  <td class="win3 vtop" style="height: $specialheight\lpx" colspan="$alldays">&nbsp;</td>
EOT
	}

	$monthview .= <<"EOT";
 </tr>
</table><br />
EOT
	return($monthview);
}

sub WeekView {
	my($weekview);
	my($inputdate) = $_[0];

	($day,$month,$year,$weekday,$yearday) = GetMonthData($inputdate);

	$days = CheckDays($month-1,$year);

	$weekview .= <<"EOT";
<table cellpadding="5" cellspacing="1" class="border" width="100%">
 <tr>
  <td class="titlebg" colspan="2">$calendar[76]: $months[$month-1] $year</td>
 </tr>
EOT
	$daycnt = 1;
	$numweeks = 1;

	++$weekday;
	if($mondaystart) { $weekday = $weekday >= 1 ? $weekday-1 : 6; }

	for($i = $weekday; $i <= 7; $i++) {
		if($numweeks == $URL{'week'}) {
			if($mondaystart) {
				$dayview = $i < 7 ? $days[$i] : $days[0];
			} else { $dayview = $days[($i-1)]; }

			$events = GetPerDayEvent($daycnt, $i, $month, $year, $numweeks, $inputdate); # Day, Weekday, Month, Year, Week, timestamp

			if($BirthDay{"$month|$daycnt"}) {
				$birthdays = '';
				foreach(split(',',$BirthDay{"$month|$daycnt"})) {
					GetMemberID($_);
					$birthdays .= $userurl{$_}.', ';
				}
				$birthdays =~ s/, \Z//g;

				chomp $BirthDayL{"$month|$daycnt"};

				$birthdays = qq~<div style="padding: 4px"><strong>$calendar[77]:</strong> $birthdays</div>~;
			}
				else { $birthdays = ''; }

			if($birthdays ne '' || $events ne '') { $dayurl = qq~<a href="$surl\lv-cal/month-$month/year-$year/day-$daycnt/" rel="nofollow">$daycnt</a>~; $newurl = qq~ onclick="location='$surl\lv-cal/month-$month/year-$year/day-$daycnt/'"~; $style = "cursor: pointer"; } else { $dayurl = $daycnt; $newurl = ''; }

			$weekview .= <<"EOT";
    <tr>
     <td class="catbg" colspan="2"><strong>$days[$i-1]</strong></td>
    </tr><tr>
     <td class="win center" style="width: 50px; $style"$newurl><span style="font-size: 20px"><strong>$daycnt</strong></span></td>
     <td class="win2 vtop" style="width: 93%; padding: 1px;$style"$newurl>$events$birthdays</td>
    </tr>
EOT
			$weekshown = 1;
		}
		if($days == $daycnt) { last; }
		if($i == 7 && $days > $daycnt) {
			++$numweeks;
			$i = 0;
		}
		++$daycnt;
	}
	if(!$weekshown) {
		$weekview .= <<"EOT";
    <tr>
     <td class="win" colspan="2">$calendar[35]</td>
    </tr>
EOT
	}

	$weekview .= <<"EOT";
</table>
EOT
	return($weekview);
}

sub SimpleCalendar { # We need to keep this here for good old times sake ... get rid of this?
	return(MonthView(time,1));
}

sub GetPerDayEvent {
	my($tday,$tweekday,$tmonth,$tyear,$tweek,$ttime,$array) = @_;
	my($return,@tevents,@returnevents);

	$tmonth   -= 1;
	$tweekday2 = $tweekday-1;
	$tyear    -= 1900;

	while(($dates,$value) = each(%SpanEvent)) {
		chomp $dates;
		($start,$end) = split(',',$dates);

		if($start <= $ttime+(($tday-1)*86400) && $end > $ttime+(($tday-1)*86400)) { push(@tevents, $value); }
	}

	push(@tevents, (@{"EventsWeekYear_$tmonth\_$tweekday2\_$tweek"}, @{"EventsDayYear_$tmonth\_$tday"}, @{"EventsDayMonth_$tday"}, @{"FullEvent_$tday\_$tmonth\_$tyear"}, @{"EventsWeekWeek_$tweekday2"}, @{"EventsWeekMonth_$tweekday2\_$tweek"}));

	if(@tevents) {
		foreach $ievents (@tevents) {
			($owner,$groups,$id,$start,$end,$repeatevery,$xdays,$bgcolor,$title,$desc,$spandays) = split(/\|/,$ievents);

			if($start >= $ttime+(($tday)*86400)) { next; }
			if($end && $end <= $ttime+(($tday-1)*86400)) { next; }

			if($array) { push(@returnevents,$ievents); next; }

			if(length($title) > 25 && $URL{'month'} eq '') { $title2 = substr($title,0,20).'...'; } else { $title2 = $title; }

			($stime) = split("/",$spandays);
			if($stime) {
				($t,$mins,$hour) = localtime($start);

				$ampm = 'am';
				if($mins < 10) { $mins = "0$mins"; }
				if($hour == 12) { $ampm = 'pm'; }
				if($hour == 0) { $hour = 12; }
				if($hour > 12) {
					$hour -= 12;
					$ampm = 'pm';
				}

				$stime = "$hour:$mins$ampm ";
			}

			$return .= qq~<div style="background-color:$bgcolor; padding: 4px; margin-bottom: 1px;" title="$title"><span class="calendartime">$stime</span>$title2</div>~;
		}
	}

	return() if(!$return && !@returnevents);
	return($return) if(!$array);
	return(@returnevents) if($array);
}

sub CheckDays { # Exported from Routines finally ...
	my($qmon,$year) = @_;
	$number = (int($year/4)*4);
	if($qmon eq 0 || $qmon eq 2 || $qmon eq 4 || $qmon eq 6 || $qmon eq 7 || $qmon eq 9 || $qmon eq 11) { $days = 31; }
	elsif($qmon eq 3 || $qmon eq 5 || $qmon eq 8 || $qmon eq 10) { $days = 30; }
	elsif($qmon eq 1) { $days = $year == $number ? 29 : 28; }
	return($days);
}

sub OtherOptions {
	($t,$month,$year) = GetMonthData($_[0]);

	$sel{$month} = $yrs{$year} = ' selected="selected"';
	for($x = 1; $x <= 12; ++$x) { $current .= qq~<option value="$x"$sel{$x}>$months[$x-1]</option>\n~; }
	for($ye = -2; $ye < 3; $ye++) {
		$curyr = $year+$ye;
		if($curyr < 1995 || $curyr > 2015) { next; }
		$yearzz .= qq~<option value="$curyr"$yrs{$curyr}>$curyr</option>~;
	}

	$ebout .= <<"EOT";
<script type="text/javascript">
//<![CDATA[
function JumpTo(ghere,year) {
 location = "$surl\lv-cal/month-"+ghere+"/year-"+year+"/";
}
//]]>
</script>
   <table cellpadding="5" cellspacing="1" class="border" width="100%">
    <tr>
     <td class="titlebg"><strong>$calendar[37]</strong></td>
    </tr><tr>
     <td class="win" style="padding: 0px">
      <table cellpadding="5" cellspacing="0" width="100%">
       <tr>
        <td colspan="2" class="smalltext center win2" style="padding: 8px">$months[$month-1] $year</td>
       </tr><tr>
        <td class="smalltext"><strong>$calendar[38]:</strong></td>
        <td class="right"><select name="JumpZ" onchange="JumpTo(this.value,$year);">$current</select></td>
       </tr><tr>
        <td class="smalltext"><strong>$calendar[39]:</strong></td>
        <td class="right"><select name="JumpZ" onchange="JumpTo($month,this.value);">$yearzz</select></td>
       </tr><tr>
        <td colspan="2" class="smalltext center"><img src="$images/feed.png" class="centerimg" alt="" /> <a href="$surl\lv-cal/a-rss/">$calendar[113]</a></td>
       </tr>
EOT

	unless(!$enablecal && !$manager{$username} && !$calmod && !$members{'Administrator',$username}) {
		$ebout .= <<"EOT";
       <tr>
        <td colspan="2" class="center smalltext win3" style="padding: 8px"><a href="$surl\lv-mod/a-calendar/">$calendar[36]</a></td>
       </tr>
EOT
	}

	$ebout .= <<"EOT";
      </table>
     </td>
    </tr>
   </table>
EOT
}

sub GetBirthdays {
	fopen(FILE,"$members/List2.txt") || error($calendar[1]);
	@loadlist = <FILE>;
	fclose(FILE);
	chomp @loadlist;
	foreach(@loadlist) {
		($un,$sn,$t,$t,$bd) = split(/\|/,$_);
		next if($bd eq '');

		($bmon,$day,$year) = split("/",$bd);
		$bmon = sprintf("%.0f",$bmon);
		$day = sprintf("%.0f",$day);

		$BirthDayL{"$bmon|$day"} .= "$sn\n";
		$BirthDay{"$bmon|$day"} .= "$un,";
		++$BirthDayC{"$bmon|$day"};
	}
}

sub GetEvents {
	if($geteventsrun) { return(1); }

	fopen(FILE,"$prefs/Events2.txt");
	while(<FILE>) {
		chomp;
		($owner,$groups,$id,$start,$end,$repeatevery,$xdays,$bgcolor,$title,$desc,$timeenabled) = split(/\|/,$_);
		if(!CalendarPermissions($groups,$owner)) { next; }

		($t,$t,$t,$dada,$damo,$daye,$tweekday) = localtime($start); # *YAWN*
		($xdays,$weeknum) = split("/",$xdays);
		if($xdays == 2) { # Weekdays ... this is lame code
			if($repeatevery == 1) { # Week
				push(@{"EventsWeekWeek_$tweekday"},$_);
			} elsif($repeatevery == 2) { # Month
				push(@{"EventsWeekMonth_$tweekday\_$weeknum"},$_);
			} elsif($repeatevery == 3) { # Year
				push(@{"EventsWeekYear_$damo\_$tweekday\_$weeknum"},$_);
			}
		} elsif($xdays == 1) { # Days (1, 2, 3, ... etc)
			if($repeatevery == 2) { # Month -- we can't do weeks ... please!
				push(@{"EventsDayMonth_$dada"},$_);
			} elsif($repeatevery == 3) { # Year
				push(@{"EventsDayYear_$damo\_$dada"},$_);
				$blah .= "$_\n";
			}
		} else {
			$start -= 900000;
			if($end) { $SpanEvent{"$start,$end"} = "$_\n"; } # Check it out -- nice and simple!
				else {
					($t,$t,$t,$dada,$damo,$daye,$tweekday) = localtime($start); # *YAWN*
					push(@{"FullEvent\_$dada\_$damo\_$daye"},$_);
				}
		}

	}
	fclose(FILE);

	$geteventsrun = 1;
}

sub GetMonthData {
	my($mstart);
	my($indate,$lastnext) = @_;
	if(!$indate) { $indate = time; }
	my($t,$t,$t,$t,$tmonth,$tyear) = localtime($indate);

	if($lastnext) {
		$tmonth = $lastnext == 1 ? $tmonth-1 : $tmonth+1;
		if($tmonth < 0) { $tyear -= 1; $tmonth = 11; }
		if($tmonth > 11) { $tyear += 1; $tmonth = 0; }
	}

	eval { $mstart = timelocal(1,1,1,1,$tmonth,$tyear,1); };

	if($lastnext) { return($mstart); }

	my($t,$t,$t,$day,$month,$year,$weekday,$yearday) = localtime($mstart);

	$year += 1900;
	++$month;
	return($day,$month,$year,$weekday,$yearday);
}

sub CalendarEvents { # Ah, a manager.  Managers <3 you!
	is_member();
	if(!$enablecal && !$manager{$username} && !$calmod && !$members{'Administrator',$username}) { error($calendar[79]); }

	#### owner|groups|Event ID|Start Date/Time|End Date/Time|Repeat Every|X Days/Weekdays|Color|Title|Description|Start TIME[/]End Time   ####
	if($URL{'p'} eq 'edit') { EditEvent(); }
	elsif($URL{'p'} eq 'massdelete') { MassDeleteEvent(); }
	elsif($URL{'p'} eq 'delete') { DeleteEvent($URL{'n'}); }
	elsif($URL{'p'} eq 'save') { SaveEvent(); }

	$title = $calendar[78];
	header();
	$ebout .= <<"EOT";
<form action="$surl\lv-mod/a-calendar/p-massdelete/" method="post">
<table cellpadding="5" cellspacing="1" class="border" width="100%">
 <tr>
  <td class="titlebg">$title</td>
 </tr><tr>
  <td class="win" style="padding: 0px;">
   <table cellpadding="5" cellspacing="1" width="100%">
    <tr>
     <td class="catbg center" style="width: 150px">$calendar[80]</td>
     <td class="catbg center" style="width: 170px">$calendar[81]</td>
     <td class="catbg center" style="width: 150px"><a href="$surl\lv-mod/a-calendar/sort-date/">$calendar[82]</a></td>
     <td class="catbg">$calendar[83]</td>
     <td class="catbg center" style="width: 100px">Delete</td>
    </tr>
EOT

	fopen(FILE,"$prefs/Events2.txt");
	while(<FILE>) {
		chomp;
		($owner,$groups,$t,$edatez) = split(/\|/,$_); # GOD IS GOOD!

		if(!CalendarPermissions($groups,$owner,1)) { next; }

		if($URL{'sort'} eq 'date') { push(@events,"$edatez|$_"); }
			else { push(@events,"1|$_"); }
	}
	fclose(FILE);

	# Get Them Pages (that's copied and pasted ALL the time, haha)
	$mupp = 50;
	$maxmessages = @events || 1;
	if($maxmessages < $mupp) { $URL{'p'} = 0; }
	$tstart = $URL{'p'} || 0;
	$link = "$surl\v-mod/a-calendar/p";
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
	$pagelinks .= " ($var{'92'} ".($tstart+1)."-$end $var{'93'} ".@events.")";

	$i = $us = 0;
	if($URL{'sort'} ne '') { @events = sort {$b <=> $a} @events; }

	foreach(@events) { # The day of the Lord is coming! <-- soon!!
		++$i;
		if($i <= $end && $i > $tstart) { $us = 1; }
			else { if($us) { last; } next; }

		($t,$owner,$groups,$id,$start,$eend,$repeatevery,$xdays,$bgcolor,$title,$desc) = split(/\|/,$_);

		GetMemberID($owner);
		$rowspan = $desc ne '' ? 2 : 1;

		if($groups eq '') { $personal = qq~<div><i>$calendar[84]</i></div>~; } else { $personal = ''; }

		$notime_date = 1;
		$start = get_date($start,1,1);

		$userput = $userurl{$owner} ? $userurl{$owner} : $owner;

		$ebout .= <<"EOT";
    <tr>
     <td style="width: 150px" rowspan="$rowspan" class="win3 vtop center"><a href="$surl\lv-mod/a-calendar/p-edit/n-$id/">$Pimg{'modify'}</a>$Pmsp2<a href="#" onclick="if(window.confirm('$calendar[67]')) { location='$surl\lv-mod/a-calendar/p-delete/n-$id/'; }">$Pimg{'remove'}</a>$personal</td>
     <td style="width: 170px" class="win2 center">$userput</td>
     <td style="width: 150px" class="win2 center">$start</td>
     <td class="win2" style="background-color:$bgcolor"><div>$title</div></td>
     <td class="win3 center" rowspan="$rowspan"><input type="checkbox" name="$i" value="$id" /></td>
    </tr>
EOT
		if($desc ne '') {
			$desc = BC($desc);
			$ebout .= <<"EOT";
    <tr>
     <td colspan="2"><i>$desc</i></td>
    </tr>
EOT
		}
	}

	if(!@events) { $ebout .= qq~<tr><td colspan="4" class="center"><br />$calendar[85]<br /><br /></td></tr>~; }

	$ebout .= <<"EOT";
   </table>
  </td>
 </tr><tr>
  <td class="catbg smalltext"><div style="float: left"><img src="$images/add.gif" class="leftimg" alt="" /> <strong><a href="$surl\lv-mod/a-calendar/p-edit/n-new/">$calendar[87]</a></strong></div><div style="float: right"><input type="submit" onclick="if(!window.confirm('$calendar[67]')) { return false; }" value="Delete Checked Events" /></div></td>
 </tr><tr>
  <td class="catbg smalltext"><img src="$images/thread.png" class="leftimg" alt="" />&nbsp;<strong>$calendar[86]:</strong> $pagelinks</td>
 </tr>
</table>
</form>
EOT
	footer();
	exit;
}

sub CalendarPermissions {
	my($groups,$owner,$modify) = @_;
	my($allowmodify,$allowview);

	if(!$modify) { # Allow viewing?
		# Add users to their appropriate groups ...
		if($memberid{$username}{'sn'} eq '' && $username ne 'Guest') { $members{'validating',$username} = 1; }
		elsif($username eq 'Guest') { $members{'guest',$username} = 1; }
		elsif($memberid{$username}{'sn'} ne '') { $members{'member',$username} = 1; }

		if($groups ne '') {
			foreach $group (split(",",$groups)) {
				if($members{$group,$username}) { $allowview = 1; }
			}
		}
		if($owner eq $username) { $allowview = 1; }

		return($allowview);
	} else { # Allow Editing?
		if($groups ne '') {
			foreach $group (split(",",$groups)) {
				if($managers{$group,$username}) { $allowedit = 1; }
			}
		}

		if($calmod || $members{'Administrator',$username} || $username eq $owner) { $allowedit = 1; }

		return($allowedit);
	}
}

sub MassDeleteEvent {
	is_member();

	while(($value,$checker) = each(%FORM)) { DeleteEvent($checker,1); }

	redirect("$surl\lv-mod/a-calendar/");
}

sub DeleteEvent { # Events deletion API ...
	is_member();
	my($deleteid,$returnerror) = @_;
	my(@repost);

	fopen(FILE,"$prefs/Events2.txt");
	while(<FILE>) {
		chomp;
		($t1,$t2,$theid) = split(/\|/,$_);
		if($theid ne $deleteid) { push(@repost,$_); } else { $posta = $t1; $groupies = $t2; }
	}
	fclose(FILE);

	if(!CalendarPermissions($groupies,$posta,1)) {
		if(!$returnerror) { error($calendar[88],1); }
			else { return(0); }
	}

	fopen(FILE,">$prefs/Events2.txt");
	foreach(@repost) { print FILE "$_\n"; }
	fclose(FILE);

	if(!$returnerror) {
		redirect("$surl\lv-mod/a-calendar/"); # Send that user back to the event manager!
	} else { return(1); }
}

sub SaveEvent {
	is_member();

	fopen(FILE,"$prefs/Events2.txt");
	@events = <FILE>;
	fclose(FILE);
	chomp @events;
	foreach(@events) {
		($owner,$t,$id) = split(/\|/,$_);
		if($URL{'n'} == $id) { $event = $_; }
		++$ownercnt{$owner};
	}

	# Disallow users with X ammount of events ...
	unless($calmod || $members{'Administrator',$username} || $manager{$username}) {
		if($ownercnt{$username} > $enablecal && $URL{'n'} eq 'new') { error($calendar[112]); }
	}

	$stmins = $sthour = 1;
	if($FORM{'stmins'} ne '' && $FORM{'sthour'} ne '') {
		$sthour = $FORM{'sthour'};
		$stmins = $FORM{'stmins'};

		if($FORM{'ampmst'} == 2 && $sthour != 12) { $sthour += 12; }
		elsif($FORM{'ampmst'} == 1 && $sthour == 12) { $sthour = 0; }

		$starttime = 1;
	}

	eval { $mstart = timelocal(1,$stmins,$sthour,$FORM{'sday'},$FORM{'smonth'},$FORM{'syear'},1); };
	error($calendar[89]) if(!$mstart);

	if($FORM{'enddatec'}) {
		$endmins = $endhour = 1;
		if($FORM{'endmins'} ne '' && $FORM{'endhour'} ne '') {
			$endhour = $FORM{'endhour'};
			$endmins = $FORM{'endmins'};

			if($FORM{'ampmend'} == 2 && $endhour != 12) { $endhour += 12; }
			elsif($FORM{'ampmend'} == 1 && $endhour == 12) { $endhour = 0; }

			$endtime = 1;
		}

		eval { $mend = timelocal(1,$endmins,$endhour,$FORM{'eday'},$FORM{'emonth'},$FORM{'eyear'},1); };
		error($calendar[89]) if(!$mend);
		++$mend;
	}
	$spancolor = Format($FORM{'spancolor'});

	if($mend <= $mstart) { $FORM{'enddatec'} = ''; $mend = ''; $endtime = 0; }

	if($FORM{'recurc'}) {
		my($t,$t,$t,$wd) = GetMonthData($mstart);

		$days = CheckDays($FORM{'smonth'},$FORM{'syear'});

		($every,$daytype) = split(',',$FORM{'every'});

		$week = 1;
		$daycnt = 1;
		$wd = $mondaystart ? $wd-1 : $wd; # Grr at the funny calendar
		for($i = $wd; $i <= 7; $i++) {
			if($i == 7) {
				++$week;
				$i = 0;
			}
			if($days == $daycnt) { last; }
			if($daycnt == $FORM{'sday'}) { last; }
			++$daycnt;
		}

		$daytype .= "/$week";
	}

	$evtitle = Format($FORM{'evtitle'}) || error($gtxt{'bfield'});
	$message = Format($FORM{'message'}) || error($gtxt{'bfield'});
	$span    = Format($FORM{'span'});
	if($span > 6) { $span = 5; }

	if(length($message) > $maxmesslth && $maxmesslth) { error($gtxt{'bfield'}); }
	if(length($evtitle) > 60) { error($gtxt{'bfield'}); }

	fopen(FILE,"$prefs/Events2.txt");
	@file2 = <FILE>;
	fclose(FILE);
	chomp @file2;

	if($FORM{'groups'} ne '') {
		foreach(split(",",$FORM{'groups'})) {
			if(CalendarPermissions($_,'',1)) { $addinggroups .= "$_,"; }
		}
	}

	$addinggroups =~ s/,\Z//g;

	if($addinggroups eq '' && !$enablecal) { error($calendar[91]); }

	if($URL{'n'} eq 'new') {
		$id = time;
		@file = @file2;

		if(!$enablecal && !$manager{$username} && !$calmod && !$members{'Administrator',$username}) { error($calendar[79]); }

		push(@file,"$username|$addinggroups|$id|$mstart|$mend|$every|$daytype|$spancolor|$evtitle|$message|$starttime/$endtime");
	} else {
		foreach(@file2) {
			($daowner,$groups,$theid) = split(/\|/,$_);
			if($theid eq $URL{'n'}) {
				if(!CalendarPermissions($groups,$daowner,1)) { error($calendar[92]); }

				push(@file,"$username|$addinggroups|$theid|$mstart|$mend|$every|$daytype|$spancolor|$evtitle|$message|$starttime/$endtime");
				$yayfound = 1;
			} else { push(@file,$_); }
		}
		if(!$yayfound) { error($gtxt{'bfield'}); }
	}

	fopen(FILE,">$prefs/Events2.txt");
	foreach(@file) { print FILE "$_\n"; }
	fclose(FILE);

	redirect("$surl\lv-mod/a-calendar/"); # Go back to the event manager
}

sub EditEvent {
	is_member();

	fopen(FILE,"$prefs/Events2.txt");
	@events = <FILE>;
	fclose(FILE);
	chomp @events;
	foreach(@events) {
		($owner,$t,$id) = split(/\|/,$_);
		if($URL{'n'} == $id) { $event = $_; }
		++$ownercnt{$owner};
	}

	# Disallow users with X ammount of events ...
	unless($calmod || $members{'Administrator',$username} || $manager{$username}) {
		if($ownercnt{$username} > $enablecal && $URL{'n'} eq 'new') { error($calendar[112]); }
	}

	if($URL{'n'} ne 'new') {
		($owner,$groups,$t,$start,$end,$repeatevery,$xdays,$bgcolor,$evtitle,$desc,$startendtime) = split(/\|/,$event);

		if(!CalendarPermissions($groups,$owner,1)) { error($calendar[92]); }
	} elsif(!$enablecal && !$manager{$username} && !$calmod && !$members{'Administrator',$username}) { error($calendar[79]); }

	($starttime,$endtime) = split("/",$startendtime);

	$title = $calendar[93];
	header();

	CoreLoad('Post');
	if($BCLoad || $BCSmile) { BCWait(); }

	$ebout .= <<"EOT";
<form action="$surl\lv-mod/a-calendar/p-save/n-$URL{'n'}/" method="post" id="post" enctype="multipart/form-data">
<table cellpadding="5" cellspacing="1" class="border" width="950">
 <tr>
  <td class="titlebg">$title</td>
 </tr>
EOT

	if($username ne $owner && $URL{'n'} ne 'new') {
		GetMemberID($owner);

		$ebout .= <<"EOT";
 <tr>
  <td class="win currentday">$calendar[94] <i>$memberid{$owner}{'sn'}</i> $calendar[95]</td>
 </tr>
EOT
	}

	$ebout .= <<"EOT";
 <tr>
  <td class="catbg">$calendar[96]</td>
 </tr><tr>
  <td class="win">
   <table cellpadding="4" cellspacing="0" width="100%">
    <tr>
     <td style="width: 30%" class="right"><strong>$calendar[97]:</strong></td>
     <td><select name="smonth">
EOT
	if(!$start) { $start = time; }

	($t,$stmins,$sthour,$qday,$qmon,$qyear) = localtime($start);

	$mon{$qmon} = ' selected="selected"';
	for($i = 0; $i < 12; ++$i) {
		$ebout .= qq~<option value="$i"$mon{$i}>$months[$i]</option>~;
	}

	$ebout .= qq~</select> <select name="sday">~;

	$day{$qday} = ' selected="selected"';
	for($i = 1; $i < 32; ++$i) { $ebout .= qq~<option value="$i"$day{$i}>$i</option>~; }
	$ebout .= qq~</select> <select name="syear">~;

	$qyear += 1900;
	$yrs{$qyear} = ' selected="selected"';
	if($qyear == 1990) { $qyear = 2005; }
	for($ey = -2; $ey < 3; $ey++) {
		$curyr = $qyear+$ey;
		$ebout .= qq~<option value="$curyr"$yrs{$curyr}>$curyr</option>~;
	}
	if($end) { $enddatec{'1'} = ' checked="checked"'; }

	if($starttime) {
		$ampm = 1;
		if($stmins < 10) { $stmins = "0$stmins"; }
		if($sthour == 12) { $ampm = 2; }
		if($sthour == 0) { $sthour = 12; }
		if($sthour > 12) {
			$sthour -= 12;
			$ampm = 2;
		}
		$ampm{$ampm} = ' selected="selected"';
	} else { $stmins = $sthour = ''; }

	$ebout .= <<"EOT";
     </select></td>
    </tr><tr>
     <td>&nbsp;</td>
     <td><strong>$calendar[98]:</strong> <input type="text" name="sthour" value="$sthour" size="3" /> : <input type="text" name="stmins" value="$stmins" size="3" /> <select name="ampmst"><option value="1"$ampm{1}>am</option><option value="2"$ampm{2}>pm</option></select></td>
    </tr><tr>
     <td class="vtop right"><strong>$calendar[99]:</strong></td>
     <td>
      <table cellpadding="3" cellspacing="0" class="innertable">
       <tr>
        <td class="vtop"><input type="checkbox" name="enddatec" value="1" onclick="OpenTemp()"$enddatec{'1'} /></td>
        <td id="enddate"><select name="emonth">
EOT
	if(!$end) { $end = time; }

	($t,$endmins,$endhour,$qday,$qmon,$qyear) = localtime($end);

	$mon{$qmon} = ' selected="selected"';
	for($i = 0; $i < 12; ++$i) {
		$ebout .= qq~<option value="$i"$mon{$i}>$months[$i]</option>~;
	}

	$ebout .= qq~</select> <select name="eday">~;

	$day{$qday} = ' selected="selected"';
	for($i = 1; $i < 32; ++$i) { $ebout .= qq~<option value="$i"$day{$i}>$i</option>~; }
	$ebout .= qq~</select> <select name="eyear">~;
	$qyear += 1900;
	$yrs{$qyear} = ' selected="selected"';
	if($qyear == 1990) { $qyear = 2005; }
	for($ey = -2; $ey < 3; $ey++) {
		$curyr = $qyear+$ey;
		$ebout .= qq~<option value="$curyr"$yrs{$curyr}>$curyr</option>~;
	}

	if($endtime) {
		$ampm = 1;
		if($endmins < 10) { $endmins = "0$endmins"; }
		if($endhour == 12) { $ampm = 2; }
		if($endhour == 0) { $endhour = 12; }
		if($endhour > 12) {
			$endhour -= 12;
			$ampm = 2;
		}
		delete @ampm{keys %ampm};
		$ampm{$ampm} = ' selected="selected"';
	} else { $endmins = $endhour = ''; }

	$ebout .= <<"EOT";
         </select>
         <div style="margin-top: 5px;"><strong>$calendar[100]:</strong> <input type="text" name="endhour" value="$endhour" size="3" /> : <input type="text" name="endmins" value="$endmins" size="3" /> <select name="ampmend"><option value="1"$ampm{1}>am</option><option value="2"$ampm{2}>pm</option></select></div>
        </td>
       </tr>
      </table>
     </td>
    </tr><tr>
     <td style="width: 30%" class="right">&nbsp;</td>
     <td class="smalltext">$calendar[101]</td>
    </tr><tr>
     <td style="width: 30%" class="right"><strong>$calendar[102]:</strong></td>
     <td><input type="text" name="spancolor" value="$bgcolor" size="10" /></td>
    </tr><tr>
     <td style="width: 30%" class="right vtop"><strong>$calendar[58]:</strong></td>
     <td>
EOT
	if($calmod || $members{'Administrator',$username} || $manager{$username}) {
		foreach(split(",",$groups)) {
			$t2{$_} = ' selected="selected"';
		}

		$ebout .= qq~<select name="groups" size="5" multiple="multiple"><optgroup label="$calendar[60]">~;
		foreach(split(',',$groups)) { $t2{$_} = ' selected="selected"'; }

		if($calmod || $members{'Administrator',$username}) {
			push(@fullgroups,('member','validating','guest'));
			$permissions{'member','name'} = "All Members";
			$permissions{'validating','name'} = "Validating";
			$permissions{'guest','name'} = "Guests";
		}

		foreach(@fullgroups) {
			unless($calmod || $members{'Administrator',$username} || $managers{$_,$username}) { next; }

			if($_ eq 'Moderators') { next; }
			if($_ eq 'member') { $ebout .= qq~</optgroup><optgroup label="Non-Member Groups">~; }
			$ebout .= qq~<option value="$_"$t2{$_}>$permissions{$_,'name'}</option>~;
		}
		$ebout .= qq~</optgroup></select>~;
		if($enablecal) { $ebout .= qq~<div class="smalltext">$calendar[103]</div>~; }
	} else {
		$ebout .= $calendar[57]; # This is probably not needed any more
	}

	if($repeatevery && $xdays) { $recurc{'1'} = ' checked="checked"'; }
	($hrmp) = split("/",$xdays);

	$recur{$repeatevery,$hrmp} = ' selected="selected"';

	$desc = Unformat($desc);

	$ebout .= <<"EOT";
     </td>
    </tr><tr>
     <td style="width: 30%" class="right"><strong>$calendar[104]</strong></td>
     <td><input type="checkbox" name="recurc" value="1" onclick="OpenTemp()"$recurc{'1'} /></td>
    </tr><tr id="recur">
     <td style="width: 30%" class="right">&nbsp;</td>
     <td>
      <table class="innertable">
       <tr>
        <td>$calendar[106]
         <select name="every">
          <option value="1,2"$recur{1,2}>$calendar[107]</option>
          <option value="2,1"$recur{2,1}>$calendar[108]</option>
          <option value="2,2"$recur{2,2}>$calendar[109]</option>
          <option value="3,1"$recur{3,1}>$calendar[110]</option>
          <option value="3,2"$recur{3,2}>$calendar[111]</option>
         </select>
        </td>
       </tr>
      </table>
     </td>
    </tr>
   </table>
  </td>
 </tr><tr>
  <td class="catbg">$calendar[105]</td>
 </tr><tr>
  <td class="win">
   <table cellpadding="4" cellspacing="0" width="100%">
    <tr>
     <td style="width: 30%" class="right"><strong>$calendar[44]:</strong></td>
     <td><input type="text" name="evtitle" value="$evtitle" size="40" maxlength="60" /></td>
    </tr>
   </table>
  </td>
 </tr><tr>
  <td class="win" style="padding: 0px">
EOT
	if($BCLoad) { $bcload = BCLoad(); }
	$ebout .= <<"EOT";
	 <table cellpadding="0" cellspacing="0" width="100%">
	  <tr>
	   <td style="width: 70%; padding: 8px;"><textarea name="message" rows="12" cols="70" style="width: 98%">$desc</textarea></td>
	   <td class="win2 vtop">
EOT
	if($BCSmile) { $bcsmile = BCSmile(); }
	$ebout .= <<"EOT";
	</td>
    </tr>
   </table>
  </td>
 </tr><tr>
  <td class="center win2"><input type="submit" value=" $calendar[28] " name="submit" />$remove</td>
 </tr>
</table>
</form>
<script type="text/javascript">
//<![CDATA[
function OpenTemp() {
 if(document.getElementById) { openItem = document.getElementById('enddate'); openItem2 = document.getElementById('recur'); }
 else if (document.all){ openItem = document.all['enddate']; openItem2 = document.all['recur']; }
 else if (document.layers){ openItem = document.layers['enddate']; openItem2 = document.layers['recur']; }

 if(document.forms['post'].recurc.checked) { ShowType2 = ""; }
  else { ShowType2 = "none"; }

 if(document.forms['post'].enddatec.checked) { ShowType = ""; }
  else { ShowType = "none"; }

 if(openItem.style) { openItem.style.display = ShowType; openItem2.style.display = ShowType2; }
  else { openItem.visibility = "show"; openItem2.visibility = "show"; }
}
OpenTemp();
//]]>
</script>
EOT
	footer();
	exit;
}

sub UpcomingEvents {
	my($upeventstime) = $_[0];
	my(@events);

	for($i = 0; $i <= $upeventstime; ++$i) {
		$time = time + ($i*86400);
		($t,$t,$t,$day,$month,$year,$thisweekday,$yearday) = localtime($time);

		eval { $mstart = timelocal(1,1,1,1,$month,$year,1); };
		($t,$t,$t,$t,$t,$t,$monthstartday) = localtime($mstart);

		$weeknum = int( ($day + $monthstartday) / 7) + 1; # Weeknum

		foreach(GetPerDayEvent($day, $thisweekday+1, $month+1, $year+1900, $weeknum, $mstart, 1)) {
			push(@events,"$time|$_");
		}
	}

	return(@events);
}

sub CalendarRSS {
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
	GetEvents();
	@events = UpcomingEvents($upevents);
	foreach(@events) {
		($start,$owner,$groups,$id,$t,$end,$t,$t,$bgcolor,$title,$message) = split(/\|/,$_);
		if($ids{$id}) { next; } else { $ids{$id} = 1; }
		$notime_date = 1;
		$date = get_date($start,1,1);
		($t,$t,$t,$day,$month,$year,$wday) = localtime($start);
		$year += 1900;
		++$month;

		$message = BC($message);

		GetMemberID($owner);

		$userpost = $memberid{$owner}{'sn'} ? $memberid{$owner}{'sn'} : $owner;

		print <<"EOT";
  <item>
   <title>$title</title>
   <link>$rurl\v-cal/month-$month/year-$year/day-$day/</link>
   <pubDate>$sdays[$wday], $day $smonths[$month-1] $year 00:00:07</pubDate>
   <description><![CDATA[$message]]></description>
   <dc:creator>$userpost</dc:creator>
  </item>
EOT
	}

	print <<"EOT";
 </channel>
</rss>
EOT
exit;
}

sub CalendarSearch { # Rebirthing Now! RIGHT NOW!!!!!!
	$title = $calendar[114];
	header();

	$notitle = $nodesc = 0;
	if($FORM{'title'} eq '' || length($FORM{'title'}) < 3) { $notitle = 1; }
	if($FORM{'description'} eq '' || length($FORM{'description'}) < 3) { $nodesc = 1; }
	if($nodesc && $notitle) { error($calendar[120]); }

	fopen(FILE,"$prefs/Events2.txt");
	while(<FILE>) {
		chomp;
		($owner,$groups,$id,$start,$end,$repeatevery,$xdays,$bgcolor,$title,$desc,$timeenabled) = split(/\|/,$_);
		if(!CalendarPermissions($groups,$owner)) { next; }
		if($FORM{'personal'} && $owner ne $username) { next; }

		$notitle = $nodesc = 0;
		if($FORM{'title'} ne '' && $title !~ /\Q$FORM{'title'}\E/sig) { $notitle = 1; }
		if($FORM{'description'} ne '' && $desc !~ /\Q$FORM{'description'}\E/sig) { $nodesc = 1; }
		if($nodesc || $notitle) { next; }

		($t,$t,$t,$dada,$damo,$daye,$tweekday) = localtime($start); # *YAWN*
		($xdays,$weeknum) = split("/",$xdays);
		if($xdays == 2) { # Weekdays ... this is lame code
			if($repeatevery == 1) { # Week
				push(@{"EventsWeekWeek_$tweekday"},$_);
			} elsif($repeatevery == 2) { # Month
				push(@{"EventsWeekMonth_$tweekday\_$weeknum"},$_);
			} elsif($repeatevery == 3) { # Year
				push(@{"EventsWeekYear_$damo\_$tweekday\_$weeknum"},$_);
			}
		} elsif($xdays == 1) { # Days (1, 2, 3, ... etc)
			if($repeatevery == 2) { # Month -- we can't do weeks ... please!
				push(@{"EventsDayMonth_$dada"},$_);
			} elsif($repeatevery == 3) { # Year
				push(@{"EventsDayYear_$damo\_$dada"},$_);
			}
		} else {
			if($end) { $SpanEvent{"$start,$end"} = "$_\n"; } # Check it out -- nice and simple!
				else {
					push(@{"FullEvent\_$dada\_$damo\_$daye"},$_);
				}
		}
	}
	fclose(FILE);

	$startm = $FORM{'startm'} >= 1 && $FORM{'startm'} <= 12 ? $FORM{'startm'} : 1;
	$endm = $FORM{'endm'} >= 1 && $FORM{'endm'} <= 12 ? $FORM{'endm'} : 12;
	if($startm > $endm) { $startm = 1; $endm = 12; }

	$starty = $FORM{'starty'} >= 2005 && $FORM{'starty'} <= 2020 ? $FORM{'starty'} : 2005;
	$endy = $FORM{'endy'} >= 2005 && $FORM{'endy'} <= 2010 ? $FORM{'endy'} : 2010;
	if($starty > $endy) { $starty = 2005; $endy = 2010; }
	$starty -= 1900;
	$endy -= 1900;

	for($i = $startm-1; $i <= $endm-1; ++$i) {
		for($y = $starty; $y <= $endy; ++$y) {
			eval { $mstart = timelocal(1,1,1,1,$i,$y,1); };

			$maxdays = CheckDays($month,$year);
			for($d = 1; $d <= $maxdays; ++$d) {
				$mstart += 86400;

				($t,$t,$t,$day,$month,$year,$thisweekday,$yearday) = localtime($mstart);

				eval { $mstart2 = timelocal(1,1,1,1,$month,$year,1); };
				($t,$t,$t,$t,$t,$t,$monthstartday) = localtime($mstart2);

				$weeknum = int( ($day + $monthstartday) / 7) + 1; # Weeknum

				foreach(GetPerDayEvent($day, $thisweekday+1, $month+1, $year+1900, $weeknum, $mstart2, 1)) {
					($t,$t,$id) = split(/\|/,$_);
					if($used{$id}) { next; } else { $used{$id} = 1; }
					++$count;
					push(@events,"$mstart|$_");
				}
				if($count > 51) { last; }
			}
			if($count > 51) { last; }
		}
		if($count > 51) { last; }
	}

	$ebout .= <<"EOT";
<table cellpadding="5" cellspacing="1" width="100%" class="border">
 <tr>
  <td class="titlebg">Calendar Search</td>
 </tr><tr>
  <td class="win">
   <table cellpadding="8" cellspacing="0" width="100%">
    <tr>
     <td class="catbg" style="width: 200px">$calendar[82]</td>
     <td class="catbg" style="width: 25%">$calendar[44]</td>
     <td class="catbg">$calendar[115]</td>
    </tr>
EOT
	@colors = ('win','win2');
	$counter = 0;
	foreach(sort {$a <=> $b} @events) {
		($start,$owner,$groups,$id,$t,$end,$t,$t,$bgcolor,$title,$desc) = split(/\|/,$_);
		$notime_date = 1;
		$date = get_date($start,1,1);
		($t,$t,$t,$day,$month,$year) = localtime($start);
		$year += 1900;
		++$month;

		if($desc > 150) { $desc = substr($desc,0,150); $desc .= "..."; }
			else { $desc = BC($desc); }

		$ebout .= <<"EOT";
    <tr onclick="location='$surl\v-cal/month-$month/year-$year/day-$day/'">
     <td class="$colors[$counter % 2] vtop"><a href="$surl\v-cal/month-$month/year-$year/day-$day/">$date</a></td>
     <td class="$colors[$counter % 2] vtop">$title</td>
     <td class="$colors[$counter % 2] vtop">$desc</td>
    </tr>
EOT
		++$counter;
	}
	$ebout .= <<"EOT";
   </table>
  </td>
 </tr>
</table>
EOT
	footer();
	exit;
}
1;