+++
title = "AngularJs HTML5 routing and IE9"
slug = "2013-05-02-angularjs-html5-routing-and-ie9"
published = 2013-05-02T17:05:00.001000-07:00
author = "Emil Lerch"
tags = []
+++
We seem to be pushing the limits of [AngularJS](http://angularjs.org/),
and we've only started using it. The framework is very promising but
definitely very new and a little rough in some areas.  
  
[![](../images/2013-05-02-angularjs-html5-routing-and-ie9-StatCounter-browser_version_partially_combined-US-monthly-201205-201304.jpeg)](http://gs.statcounter.com/#browser_version_partially_combined-US-monthly-201205-201304)We'd
like to [avoid hash
urls](http://isolani.co.uk/blog/javascript/BreakingTheWebWithHashBangs)
in our solutions. The backend can respond to our routes just fine, and
our backend framework is able to serve up the correct content (not
necessarily the same content) for any area of the application. Using
HTML5 mode and the [history.pushState](http://caniuse.com/#feat=history)
api, we can get clean URLs and no 404 errors on refresh...awesome.  
  
**Enter, IE9 (top light blue line)**. Our current browser standards are
IE9+, Desktop/Android Chrome, FF, and IOS Safari. All browsers support
history.pushState except IE9. The browser has had a recent significant
drop in usage, but we can't ignore it quite yet.  
  
At first, we thought we could set $locationProvider.html5Mode(true) and
it would either a) break in IE9 calling a function that didn't exist
(but we could define as window.location.assign(url)), or b) do a
browser-based redirect based on
[window.location.assign](https://developer.mozilla.org/en-US/docs/DOM/window.location).
 Well,
[RTFM](http://docs.angularjs.org/guide/dev_guide.services.$location):
 what it does is actually relatively painful.  It falls back to hashbang
syntax.  This is similar to
[history.js](http://balupton.github.io/history.js/demo/), and IMHO, is
broken in the same way as that library.  Now you have URLs you can't
share between browsers without crazy (and slow) workarounds.  
  
I tried to work around the problem by providing a history.pushState
implementation.  This fooled Angular into thinking it was compliant, but
caused some redirect loops and ultimately didn't work out.  Next, I
tried first intercepting routeChangeStart and [calling
event.preventDefault to no
avail](https://github.com/angular/angular.js/issues/2109), then
locationChangeStart also without success (I'm informed [this does
work](http://stackoverflow.com/a/13963919/113225), but for some reason I
didn't see it, at least not in IE9).  
  
Finally, it hit me...since we're not programmatically changing locations
(just using [anchor
tags](http://docs.angularjs.org/api/ng.directive:a)), we could simply
determine if [pushState is
available](http://stackoverflow.com/a/10647429/113225) and perform the
following functions if it is not:  
  

1.  **Avoid defining any routes with the route provider**
2.  Take our [&lt;script id='whateverroutewearecurrentlyon'
    type='text/ng-template'/&gt;](http://stackoverflow.com/a/10647429/113225)
    that is automatically generated on the backend for the current URL
    and manually add it to the ng-view element.
3.  Remove the ng-view attribute (for completeness) and add an
    ng-controller attribute pointing to the controller for the current
    route.
4.  Disable any pre-loading for pages other than the one on which we
    reside.

This technique can only work in a pretty specific set of circumstances,
but I think a properly designed backend system should be able to meet
the criteria:

1.  Any URL used by history.pushState actually generates appropriate
    content from the server.
2.  The server at any URL provides the page layout and the application
    code.  Providing the current page content in the script tag is nice
    (that's what we do) but it's not strictly required (\#2 above could
    be done via Ajax).
3.  The application code is light enough that you (and your users) can
    put up with full page loads in non-compliant browsers until users
    upgrade.  I wouldn't want to try this technique on gmail. ;-)

I [reject Quora on
principal](http://www.hanselman.com/blog/IdLikeToUseTheWebMyWayThankYouVeryMuchQuora.aspx),
but at least now we have an answer to ["Can we develop an AngularJS
application which supports IE 7+ but does not have hash or hashbang
urls?"](http://www.quora.com/AngularJS/Can-we-develop-an-AngularJS-application-which-supports-IE-7+-but-does-not-have-hash-or-hashbang-urls).
