+++
title = "Getting around lousy software"
slug = "2007-05-15-getting-around-lousy-software"
published = 2007-05-15T11:21:00-07:00
author = "Emil"
tags = []
+++
I like HP's printers, but absolutely hate their software. Here's a list
of problems I've had with them off the top of my head:  
  

-   Software assumes you can connect to the printer at all times - if
    you're not, periodic episodes of 100% CPU utilization occurs.
    Disabling WIA (Image Acquisition Service) cured that problem.
-   Software periodically crashes for no particular reason, and when not
    using the software actively. I believe this is related to the
    "always connected" issue above.
-   Software works about 50% of the time when scanning.  
-   Software is extremely slow to shutdown and sometimes refuses to do
    so
-   Software blue screens the machine
-   Software that likes to update itself but usually can't connect
    either due to firewalls (despite proper proxy config) or some other
    reason  
-   Software allows copying data off a memory card inserted into the
    printer, but does not copy/set a create date on the files, which
    crashes lots of other applications  

I haven't seen the last problem for a while, and a higher % of the
issues I see seem to revolve around scanning functionality. I've been
trying to document a way to consistently scan without spending an hour
trying to do it, and I've finally found the way...avoid the software as
much as possible. Here's my current method:  

1.  Insert memory card into printer
2.  Scan document and send the scan to the memory card
3.  Copy the files from the memory card to the computer
4.  Use a "touch" utility to set the create date on the file to avoid
    the last problem above

As a software guy, this stuff probably bothers me more than most people.
I can't imagine trying to work around all these issues if I were a
normal person - I'd probably try to scan once or twice and then return
the product. I understand the need for HP to ship early and ship often,
but you need a complete product...not 75% of one (hardware and
half-working software).
