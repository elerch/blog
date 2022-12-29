+++
title = "Determining internal vs. external email"
slug = "2007-08-26-determining-internal-vs-external-email"
published = 2007-08-26T18:57:00-07:00
author = "Emil"
tags = []
+++
I've been trying to get a good Outlook filter to determine internal from
external mail. You'd almost think this is a standard request, but it's
actually pretty difficult, especially at a large organization like
Intel. After some time trying to figure it out and following some [bad
advice from
Microsoft](http://office.microsoft.com/en-us/outlook/HA011502011033.aspx),
I ran across [Ray Jezek's Blog : Outlook Rules with
Exchange](http://blogs.geekdojo.net/jez/archive/2004/04/27/1782.aspx).  
  
The idea is fairly sound, but alas, does not work at Intel, where we
have many Exchange servers. When a message moves from one server to
another, the message gets Internet headers, so the idea of filtering a
message header for the word "Received" doesn't work.  
  
I tried other variations on this theme, though, and finally came up with
the solution. My rule now matches any message with a message header
containing the text of one of the servers listed in [Intel.com's MX
records](http://www.zoneedit.com/lookup.html?host=intel.com&type=MX&server=&forward=Look+it+up).
Internally, our mail will not use one of these hosts, so that's the only
sure-fire way to catch external, and only external email that I've
found. I suppose if the sender listed the IP address of the mail host my
rule would fail, but that's a risk I'm willing to take. ;-)
