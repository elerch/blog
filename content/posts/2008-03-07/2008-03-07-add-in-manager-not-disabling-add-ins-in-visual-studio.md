+++
title = "Add-in manager not disabling add-ins in Visual Studio?"
slug = "2008-03-07-add-in-manager-not-disabling-add-ins-in-visual-studio"
published = 2008-03-07T11:15:00-08:00
author = "Emil"
tags = []
+++
I stumbled across this problem today, and found an interesting feedback
page to Microsoft regarding the issue:
<http://connect.microsoft.com/VisualStudio/feedback/ViewFeedback.aspx?FeedbackID=105560>  
  
Workaround:  
  

-   Regedit:
    HKEY\_LOCAL\_MACHINE\\SOFTWARE\\Microsoft\\VisualStudio\\8.0\\AddIns
-   Go into the add-in key you're interested in disabling
-   Manually set the LoadBehavior entry to 0x0
