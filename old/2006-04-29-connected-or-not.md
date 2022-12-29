+++
title = "Connected, or not?"
slug = "2006-04-29-connected-or-not"
published = 2006-04-29T14:31:00-07:00
author = "Emil"
tags = []
+++
I constantly struggle with the concept of connected vs. unconnected
operation. One thing I hate when traveling is that I don't have access
to many common applications (the system I am responsible for at work,
our bug tracking system, many, many random web sites, etc.). However, I
also do not like the idea of installing all kinds of applications on my
notebook and syncronizing all the time.  
  
For applications, I'm starting to come down on the side of building
interfaces based on the client. If your clients are all Windows, it
probably makes sense to go with a [.NET
ClickOnce](http://msdn.microsoft.com/msdnmag/issues/04/05/ClickOnce/)
application with [SQL
Everywhere](http://www.microsoft.com/sql/editions/sqlmobile/default.mspx)
as a local data store (of course, you get to have fun building in all
the syncronization). If your clients are not all Windows-based, then go
with a web application, and if the costs justify the it, build the click
once app as well for convenience.  
  
Similarly (and possibly a more complex problem), what to do about email?
Do you send that large attachment out? If you do, your
coworkers/friends/whatever will not be able to edit the document and
easily keep track of changes - you end up merging by hand constantly. If
you don't, your recipients do not have offline access and may have a
difficult time finding the document again. I don't have a good answer
for that, but I suspect that a really good answer would be worth money
to someone...
