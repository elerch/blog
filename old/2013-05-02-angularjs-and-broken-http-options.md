+++
title = "AngularJS and broken http options"
slug = "2013-05-02-angularjs-and-broken-http-options"
published = 2013-05-02T18:19:00-07:00
author = "Emil Lerch"
tags = []
+++
Complicating the [HTML5 routing and IE9
issue](http://emilsblog.lerch.org/2013/05/angularjs-html5-routing-and-ie9.html)
was the fact that AngularJS looks fundamentally broken regarding
behavior around http settings.  Our server offers [content
negotiation](https://en.wikipedia.org/wiki/Content_negotiation), so an
application url for /widgets requesting a content
[Accept](http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.1)
header of text/html will result in the server sending HTML for the set
of widgets it knows about.  If, however, the Accept type header is set
to application/json, the server will respond with a json object with an
array property containing widget data.  
  
Our first problem is that a user browsing the site will want a full HTML
page while Angular provides no facility (that I've found) for specifying
an element in a full page to gather for the view.  It expects an HTML
fragment consisting of a single root element.  To tackle this problem,
we added an "X-Partial" header to let the server know to include only
the partial content.  
  
This worked fine and setting the $http settings is [clearly
documented](http://docs.angularjs.org/api/ng.$http)...but also starts to
have a code smell.  The
[$routeProvider](http://docs.angularjs.org/api/ng.$routeProvider)
doesn't seem to have a way to specify http settings, so the only way to
set headers is by setting http defaults.  
  
As it turns out, while they are named defaults, they are not, in fact,
defaults.  [Deep in the code of
AngularJS](https://github.com/angular/angular.js/blob/a348e90aa141921b914f87ec930cd6ebf481a446/src/ng/http.js#L655),
you'll see the following calls:
