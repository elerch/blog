+++
title = "My Firefox tweaks"
slug = "2006-10-30-my-firefox-tweaks"
published = 2006-10-30T19:54:00-08:00
author = "Emil"
tags = []
+++
For speed, I've enabled
[pipelining](http://www.mozilla.org/projects/netlib/http/pipelining-faq.html).
Here's how:  

-   about:config in the address bar
-   type "pipelining" in the filter
-   set "network.http.pipelining" to true
-   set "network.http.pipelining.maxrequests" to 8
-   set "network.http.proxy.pipelining" to true

For access at Intel, I also turned on http authentication:  

-   set "network.automatic-ntlm-auth.trusted-uris" to "intel.com"
