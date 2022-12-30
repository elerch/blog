+++
title = "Working with a feature branch in Subversion (TortoiseSVN on Windows)"
slug = "2010-03-09-working-with-a-feature-branch-in-subversion-tortoisesvn-on-windows"
published = 2010-03-09T08:51:00-08:00
author = "Emil"
tags = []
+++
Branching and merging is one of the most nerve-racking activities for
people working with Subversion.  Unlike Mercurial and other DVCS where
branching and merging is commonplace, typical workflows in Subversion do
not include this activity.  As a result, the terminology is typically
confusing, the massive number of changes can be scary, and a lot of
people are so concerned about "getting it right" that they typically
just avoid the practice altogether and work completely outside of source
control.  That, of course, is the exact opposite of what we need when
working on an important design spike or critical new feature.  
  
 Conceptually, what we want with a design spike or large new feature is
to:  
  

-   Create a new branch for the change
-   Work in the new branch, committing early and often
-   Periodically pull in (merge) the changes from the project trunk
-   When complete, reintegrate the branch into the trunk

For these instructions, I assume that you have a subversion repository
checked out and you're actively working on the trunk.  
  
<span style="font-size: large;">**Creating a new branch:**</span>  

[![](/posts/2010-03-09/thumbnails/2010-03-09-working-with-a-feature-branch-in-subversion-tortoisesvn-on-windows-Magical+Snap+-+2010.03.09+08.17+-+003.png)](/posts/2010-03-09/2010-03-09-working-with-a-feature-branch-in-subversion-tortoisesvn-on-windows-Magical+Snap+-+2010.03.09+08.17+-+003.png)

1.   Right-click on the directory you want to branch.  Pick the
    Branch/Tag operation.
2.  On the branch/tag screen, enter a new branch (typically the
    repository has a /branches folder as well as a /trunk folder).  The
    new branch is typically /branches/*mynewbranch*, where the branch
    name itself is a folder that does not exist in the repository.
3.  In this scenario, you will also want to choose "switch working copy
    to new branch/tag".  We'll be doing work on the new feature or
    design change immediately, so this tells subversion that any new
    commits will be on that other branch.

[![](/posts/2010-03-09/thumbnails/2010-03-09-working-with-a-feature-branch-in-subversion-tortoisesvn-on-windows-Magical+Snap+-+2010.03.09+08.22+-+004.png)](/posts/2010-03-09/2010-03-09-working-with-a-feature-branch-in-subversion-tortoisesvn-on-windows-Magical+Snap+-+2010.03.09+08.22+-+004.png)

 At this point you'll want to take note of the revision number that had
the last changes.  
  
<span style="font-size: large;"></span>  
<span style="font-size: large;">**Work in the new branch, committing
early and often**</span>  
  
This is standard subversion behavior.  
  
<span style="font-size: large;">**Periodically pull in (merge) the
changes from the project trunk**</span>  
  
You'll want to keep track of the last revision you've pulled changes
from.  In the beginning, this revision number is the revision that
represented the branch itself.  
  

[![](/posts/2010-03-09/thumbnails/2010-03-09-working-with-a-feature-branch-in-subversion-tortoisesvn-on-windows-Magical+Snap+-+2010.03.09+08.32+-+005.png)](/posts/2010-03-09/2010-03-09-working-with-a-feature-branch-in-subversion-tortoisesvn-on-windows-Magical+Snap+-+2010.03.09+08.32+-+005.png)

1.  Pick the Merge tool off the TortoiseSVN menu.
2.  Choose the "Merge a range of revisions" from the first screen of the
    wizard.
3.  In the "URL to merge from", choose the trunk.
4.  In the Revision range to merge, the best approach is to be precise. 
    Put in the last revision number that was merged (e.g. if you
    branched when the repository was at revision 10, put in 11-HEAD). 
    You can leave this blank, but we want to avoid merging a change
    twice.  You may need to look at the log to help find the right
    revisions.

[![](/posts/2010-03-09/thumbnails/2010-03-09-working-with-a-feature-branch-in-subversion-tortoisesvn-on-windows-Magical+Snap+-+2010.03.09+08.37+-+006.png)](/posts/2010-03-09/2010-03-09-working-with-a-feature-branch-in-subversion-tortoisesvn-on-windows-Magical+Snap+-+2010.03.09+08.37+-+006.png)

Hit next and do a test merge just to be sure before performing the
actual merge.  All other settings can be left at their defaults.  Note
that the merge is done in your working directory, so you'll have a bunch
of local changes to test and commit on your branch.  
  
<span style="font-size: large;">**Reintegrate the branch into the
trunk**</span>  

[![](/posts/2010-03-09/thumbnails/2010-03-09-working-with-a-feature-branch-in-subversion-tortoisesvn-on-windows-Magical+Snap+-+2010.03.09+08.47+-+007.png)](/posts/2010-03-09/2010-03-09-working-with-a-feature-branch-in-subversion-tortoisesvn-on-windows-Magical+Snap+-+2010.03.09+08.47+-+007.png)

1.  Commit all branch changes
2.  Switch the working directory back to the trunk.  This is done via
    the TortoiseSVN switch command.
3.  Pick the Merge command off the TortoiseSVN menu as before.  This
    time, however, we'll pick the "Reintegrate a branch" option.
4.  In the "From URL" field, put the URL to the branch you've finished
    working on.
5.  Test the merge and if happy, perform the merge, test the changes,
    and commit to the trunk.

[![](/posts/2010-03-09/thumbnails/2010-03-09-working-with-a-feature-branch-in-subversion-tortoisesvn-on-windows-Magical+Snap+-+2010.03.09+08.48+-+008.png)](/posts/2010-03-09/2010-03-09-working-with-a-feature-branch-in-subversion-tortoisesvn-on-windows-Magical+Snap+-+2010.03.09+08.48+-+008.png)
