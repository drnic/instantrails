var detect = navigator.userAgent.toLowerCase();
var OS,browser,version,total,thestring;

if (checkIt('konqueror'))
{
	browser = "Konqueror";
	OS = "Linux";
}
else if (checkIt('safari')) browser = "Safari"
else if (checkIt('omniweb')) browser = "OmniWeb"
else if (checkIt('opera')) browser = "Opera"
else if (checkIt('webtv')) browser = "WebTV";
else if (checkIt('icab')) browser = "iCab"
else if (checkIt('msie')) browser = "Internet Explorer"
else if (!checkIt('compatible'))
{
	browser = "Netscape Navigator"
	version = detect.charAt(8);
}
else browser = "An unknown browser";

if (!version) version = detect.charAt(place + thestring.length);



function checkIt(string)
{
	place = detect.indexOf(string) + 1;
	thestring = string;
	return place;
}


function evalResize(){
	newWidth = contentElement.offsetWidth;
	if (newWidth != contentWidth && !isWidthChanged) {
		isWidthChanged = true;
		isSIFRRolledBack = true;
		sIFR.rollback();
	}
	if (browser == "Internet Explorer"){
		if(tempTimeout){clearTimeout(tempTimeout);}
		tempTimeout = setTimeout(resetSIFR, 500);
	} else {
		resetSIFR();
	}
}
function resetSIFR(){
	if(isWidthChanged){
		do_sIFR();
		isWidthChanged = false;
		contentWidth = contentElement.offsetWidth;
	}
}