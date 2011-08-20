/**********************************************************
 * Common JS function calls.                              *
 * Copyright © 2001-2007 E-Blah.                          *
 * Part of the E-Blah Software.  Released under the GPL.  *
 *                        Last Update: September 17, 2007 *
 **********************************************************/

// AJAX: developer.apple.com/internet/webcontent/xmlhttpreq.html

var req;
function EditMessage(url,saveopen,savemessage,messageid) {

	EditMessage2(url,saveopen,savemessage);

	function EditMessage2(url,saveopen,savemessage,messageid) {
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
			if(saveopen == 1) { req.send("message="+encodeURIComponent(savemessage)); }
			else if(saveopen == 2) {
				req.send(savemessage);
			} else { req.send('TEMP'); }
		} else { alert('There was an error loading this page.'); }
	}

	function processReqChange() {
		if(req.readyState != 4) { document.getElementById(messageid).innerHTML = '<div class="loading">&nbsp;</div>'; }
		if(req.readyState == 4) {
			if (req.status == 200) {
				document.getElementById(messageid).innerHTML = req.responseText;
			} else { alert('There was an error loading this page.'); }
		}
	}
}

// Let's do some menus ...
// Some code based from: www.quirksmode.org/js/findpos.html

function findPosX(obj) {
	var curleft = 0;
	if(obj.offsetParent) {
		while (obj.offsetParent) {
			curleft += obj.offsetLeft
			obj = obj.offsetParent;
		}
	}
	else if(obj.x)
		curleft += obj.x;
	return curleft;
}

function findPosY(obj,plussize) {
	var curtop = plussize;
	if(navigator.userAgent.indexOf("Firefox") != -1) { curtop = (curtop/2); }
	if(navigator.userAgent.indexOf("IE") != -1) { curtop = (curtop+12); }
	if(obj.offsetParent) {
		while (obj.offsetParent) {
			curtop += obj.offsetTop
			obj = obj.offsetParent;
		}
	}
	else if(obj.y)
		curtop += obj.y;
	return curtop;
}

// Creating Menus ...
function CreateMenus(obj,plussize,JSinput) {
	var newX = findPosX(obj);
	var newY = findPosY(obj,plussize);
	var x = document.getElementById('menu-eblah');
	x.style.top = newY + 'px';
	x.style.left = newX + 'px';
	document.getElementById('menu-eblah').innerHTML = ConstructLinks(JSinput);
	document.getElementById('menu-eblah').style.visibility = '';
}

function ClearMenu() {
	document.getElementById('menu-eblah').innerHTML = '';
	document.getElementById('menu-eblah').style.visibility = 'hidden';
}

function ConstructLinks(JSinput) {
	GetLinks(JSinput);
	var link = '';
	for(x in MenuItems) {
		link += '<div style="padding: 5px;" class="win3">' + MenuItems[x] + '</div>';
	}

	return(link);
}

// Image Resize; from Martin's Mod for E-Blah

function resizeImg() {
	var _resizeWidth = 750;
	var ResizeMsg = 'Click to view original size ...';

	var _resizeClass = 'imgcode';
	var imgArray = document.getElementsByTagName('img');

	for(var i = 0; i < imgArray.length; i++) {
		var imgObj = imgArray[i];
		
		if(imgObj.className == _resizeClass && imgObj.width > _resizeWidth) {
			imgObj.style.width = _resizeWidth + 'px';
			imgObj.onclick = ImagecodeWinOpen;
			imgObj.title = ResizeMsg;
			imgObj.style.cursor = 'pointer';
		}
	}
}

function ImagecodeWinOpen(e) {

	var img = (e)?e.target.src:window.event.srcElement.src;
	
	var w = window.open('','IMG','titlebar,scrollbars,resizable');
	if (w) {
		w.document.write('<html><body><div align="center"><a href="#" onclick="window.close(); return false"><img src="'+img+'"></a></div></body></html>');
		w.document.close();
	}
}

window.onload = resizeImg;