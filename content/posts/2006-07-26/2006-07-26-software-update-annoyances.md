+++
title = "Software Update annoyances"
slug = "2006-07-26-software-update-annoyances"
published = 2006-07-26T15:37:00-07:00
author = "Emil"
tags = []
+++
My last post also reminded me that I've been meaning to post on another
subject - that of software updates. These are (sometimes) necessary and
usually desirable functionality, as long as they don't get in the way of
the user trying to do their job. As mentioned previously, I think Adobe
does a great job showing how **not** to do this (modal dialog box, even
when viewing in a browser, usually asks to install a bunch of unneeded
crap, etc.).  
  
One thing I see consistently done wrong in these update programs is the
fact that they tend to ask you to update when you start the program. If
a user started a program, do you think they want to update the program,
or use the program? (that's rhetorical) Unless the update is critical,
the update process should ask to update the program and/or its
components when the user requests shutdown of the program. Here's the
complete guidelines that I think should be followed:  
  

If the update isn't critical, wait until shutdown to request the update.
"Critical" updates include:

-   Security-related issues that can expose the user to remote attack
-   Stability issues that the user has experienced. You would know this
    only if a crash reporting facility exists and the user has opted
    into the use of the facility.

If critical, state so and offer the update on application start

On shutdown, ask the user to update, but close the application if no
reponse has been received after some time (how long?)

Only include updates for existing components - don't ask the user to
install Google Toolbar (unless of course the application that they're
updating is Google Toolbar)

Allow the user to choose which components to update. It's ok to use an
opt-out model for this. Include a "don't ask me again" facility along
with a way for the user to go back and install the "don't ask me again"
updates (e.g. through a specific update application menu item)

Try to avoid forcing an application restart. If you're shutting down the
application it may not be a big deal, but if the user selects that menu
item or the update is critical, this becomes important. It's really
important if the application is a service or an operating system. Yes,
Microsoft does a horrible job at this...

If you have multiple applications in your company, use a consistent
service that can update all applications. I do give credit to Microsoft
on this one as they are working on getting a single update service.
Ideally, there would be a single service/paradigm used across companies
(e.g. MSI/Installshield for installations). Market opportunity?

Of course, I could be wrong, but I don't think I am. Let me know.
