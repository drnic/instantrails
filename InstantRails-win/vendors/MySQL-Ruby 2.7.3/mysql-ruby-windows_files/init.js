function do_sIFR(){
		if(typeof sIFR == "function")
		{		
			if(isSIFRRolledBack){
				isSIFRRolledBack = false;
				
				/* section title */
				sIFR.replaceElement(named({sSelector:"#site-name", sFlashSrc:"/images/theme/tradegothic.swf", sColor:"#ffffff", sLinkColor:"#ffffff", sBgColor:"#A0B335", sHoverColor:"#f2f2f2", sWmode:"transparent"}));
				sIFR.replaceElement(named({sSelector:"#sub-title", sFlashSrc:"/images/theme/tradegothic.swf", sColor:"#ffffff", sLinkColor:"#ffffff", sBgColor:"#A0B335", sHoverColor:"#f2f2f2", sWmode:"transparent"}));

				/* normal posts styles */
				sIFR.replaceElement(named({sSelector:"#content #main .normal-post h1", sFlashSrc:"/images/theme/tradegothic.swf", sColor:"#731400", sLinkColor:"#731400", sBgColor:"#ffffff", sHoverColor:"#666666", sWmode:"transparent"}));
				sIFR.replaceElement(named({sSelector:"#content #main .normal-post h2", sFlashSrc:"/images/theme/tradegothic.swf", sColor:"#d26941", sLinkColor:"#d26941", sBgColor:"#ffffff", sHoverColor:"#666666", sWmode:"transparent"}));
				sIFR.replaceElement(named({sSelector:"#content #main .normal-post h3", sFlashSrc:"/images/theme/tradegothic.swf", sColor:"#d78807", sLinkColor:"#d78807", sBgColor:"#ffffff", sHoverColor:"#666666", sWmode:"transparent"}));
				sIFR.replaceElement(named({sSelector:"#content #main .normal-post h4", sFlashSrc:"/images/theme/tradegothic.swf", sColor:"#d7b741", sLinkColor:"#d7b741", sBgColor:"#ffffff", sHoverColor:"#666666", sWmode:"transparent"}));
				sIFR.replaceElement(named({sSelector:"#content #main .normal-post h5", sFlashSrc:"/images/theme/tradegothic.swf", sColor:"#333333", sLinkColor:"#333333", sBgColor:"#ffffff", sHoverColor:"#666666", sWmode:"transparent"}));
				sIFR.replaceElement(named({sSelector:"#content #main .normal-post h6", sFlashSrc:"/images/theme/tradegothic.swf", sColor:"#6a604f", sLinkColor:"#6a604f", sBgColor:"#ffffff", sHoverColor:"#666666", sWmode:"transparent"}));
				
				/* alternative posts styles */
				sIFR.replaceElement(named({sSelector:"#content #main .alternate-post h1", sFlashSrc:"/images/theme/tradegothic.swf", sColor:"#416219", sLinkColor:"#416219", sBgColor:"#ffffff", sHoverColor:"#666666", sWmode:"transparent"}));
				sIFR.replaceElement(named({sSelector:"#content #main .alternate-post h2", sFlashSrc:"/images/theme/tradegothic.swf", sColor:"#628636", sLinkColor:"#628636", sBgColor:"#ffffff", sHoverColor:"#666666", sWmode:"transparent"}));
				sIFR.replaceElement(named({sSelector:"#content #main .alternate-post h3", sFlashSrc:"/images/theme/tradegothic.swf", sColor:"#a0b335", sLinkColor:"#a0b335", sBgColor:"#ffffff", sHoverColor:"#666666", sWmode:"transparent"}));
				sIFR.replaceElement(named({sSelector:"#content #main .alternate-post h4", sFlashSrc:"/images/theme/tradegothic.swf", sColor:"#b5c364", sLinkColor:"#b5c364", sBgColor:"#ffffff", sHoverColor:"#666666", sWmode:"transparent"}));
				sIFR.replaceElement(named({sSelector:"#content #main .alternate-post h5", sFlashSrc:"/images/theme/tradegothic.swf", sColor:"#333333", sLinkColor:"#333333", sBgColor:"#ffffff", sHoverColor:"#666666", sWmode:"transparent"}));
				sIFR.replaceElement(named({sSelector:"#content #main .alternate-post h6", sFlashSrc:"/images/theme/tradegothic.swf", sColor:"#6a604f", sLinkColor:"#6a604f", sBgColor:"#ffffff", sHoverColor:"#666666", sWmode:"transparent"}));
				
				/* sidebar styles */
				sIFR.replaceElement(named({sSelector:"#sidebar h3", sFlashSrc:"/images/theme/tradegothic.swf", sColor:"#a1b436", sLinkColor:"#a1b436", sBgColor:"#ffffff", sHoverColor:"#666666", sWmode:"transparent"}));
				
				/* section title */
				sIFR.replaceElement(named({sSelector:"#content h2.section-title", sFlashSrc:"/images/theme/tradegothic.swf", sColor:"#d26941", sLinkColor:"#d26941", sBgColor:"#ffffff", sHoverColor:"#666666", sWmode:"transparent"}));
				
			}
		}
	}

function init(){
	/* these variables need to be global */
	isSIFRRolledBack = true;
	tempTimeout = false;
	isWidthChanged = false;
	contentElement = document.getElementById('content');
	contentWidth = contentElement.offsetWidth;
	bodyEl = document.getElementsByTagName('body')[0];

	if (checkClass(bodyEl, 'sIFROn')){
		window.onresize = evalResize;
		do_sIFR();
	}
	/* register rules */
	Behaviour.register(searchRules);
	Behaviour.register(styleSwitcherRules);
}

var isCommentFormToggled = false;
function toggleCommentForm(){
	if (!isCommentFormToggled){
		Effect.Appear('guest_email');
		Effect.Appear('guest_url');
		isCommentFormToggled = true;
	} else {
		Effect.Fade('guest_email');
		Effect.Fade('guest_url');
		isCommentFormToggled = false;
	}
}