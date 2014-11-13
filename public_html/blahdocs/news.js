// News Script
// Taken from JavaScript Source: http://javascript.internet.com/scrolls/multiple-message-scroller.html
// Pause effect taken from - Pausing updown message scroller - © Dynamic Drive DHTML code library (www.dynamicdrive.com)

//configure the below five variables to change the style of the scroller
var sdelay='3000' //delay between msg scrolls. 3000=3 seconds.
var swidth='100%'
var sheight='40'
var sspeed='2'

var singletext=new Array()

if (singletext.length>1)
	i=1
else
	i=0

function ns4marquee(whichlayer){
	ns4layer=eval(whichlayer)
	if (ns4layer.top>0&&ns4layer.top<=sspeed){
		ns4layer.top=0
		setTimeout("ns4marquee(ns4layer)",sdelay)
		setTimeout("ns4marquee(ns4layer)",sdelay)
		return
	}
	if (ns4layer.top>=sheight*-1){
		ns4layer.top-=sspeed
		setTimeout("ns4marquee(ns4layer)",100)
	}
	else{
		ns4layer.top=sheight
		ns4layer.document.write(singletext[i])
		ns4layer.document.close()
		if (i==singletext.length-1)
			i=0
		else
			i++
		}
	}

function ns6marquee(whichdiv){
ns6div=eval(whichdiv)
if (parseInt(ns6div.style.top)>0&&parseInt(ns6div.style.top)<=sspeed){
ns6div.style.top=0+"px"
setTimeout("ns6marquee(ns6div)",sdelay)
return
}
if(parseInt(ns6div.style.top)>=ns6div.offsetHeight*-1){
ns6div.style.top=parseInt(ns6div.style.top)-sspeed+"px"
}
else{
ns6div.style.top=sheight+"px"
ns6div.innerHTML=singletext[i]
if (i==singletext.length-1)
i=0
else
i++
}
setTimeout("ns6marquee(ns6div)",100)
}

function iemarquee(whichdiv){
	iediv=eval(whichdiv)
	if (iediv.style.pixelTop>0&&iediv.style.pixelTop<=sspeed){
		iediv.style.pixelTop=0
		setTimeout("iemarquee(iediv)",sdelay)
		setTimeout("iemarquee(iediv)",sdelay)
		return
	}
	if (iediv.style.pixelTop>=sheight*-1){
		iediv.style.pixelTop=iediv.style.pixelTop-=sspeed
		setTimeout("iemarquee(iediv)",100)
	}
	else{
		iediv.style.pixelTop=sheight
		iediv.innerHTML=singletext[i]
		if (i==singletext.length-1)
			i=0
		else
			i++
		}
	}

function start(){
	if (document.all){
		ieslider1.style.top=sheight
		iemarquee(ieslider1)
	}
	else if (document.layers){
		document.ns4slider.document.ns4slider1.top=sheight+"px"
		document.ns4slider.document.ns4slider1.visibility='show'
		ns4marquee(document.ns4slider.document.ns4slider1)
	}
	else if (document.getElementById&&!document.all){
		document.getElementById('ns6slider1').style.top=sheight
		ns6marquee(document.getElementById('ns6slider1'))
	}
	i=1
}