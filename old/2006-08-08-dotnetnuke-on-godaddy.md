+++
title = "dotnetnuke on GoDaddy"
slug = "2006-08-08-dotnetnuke-on-godaddy"
published = 2006-08-08T12:25:00-07:00
author = "Emil"
tags = []
+++
In my last post I mentioned bethanycommunity.net web site. In getting it
working, I had to get [dotnetnuke](http://www.dotnetnuke.com) installed
and running on the root directory of the site. Doing this on
[godaddy](http://www.godaddy.com) was quite an interesting feat and
required some changes to the dotnetnuke source code. I hope their latest
version helps fix that problem. There are some instructions on doing
this [here](http://www.northernstarsolutions.com/Default.aspx?tabid=61).
I found they got me close, but the installer was still a problem, and
hence the (temporary) source code changes to skip over some of DNN's
more dangerous install behavior.  
  
Some people think that this is GoDaddy's problem and people should be
able to create very insecure sites, but I side with GoDaddy that
normally applications should not need to update their core configuration
files and place files in their production directories.
