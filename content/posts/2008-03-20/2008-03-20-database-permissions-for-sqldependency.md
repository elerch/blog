+++
title = "Database permissions for SQLDependency"
slug = "2008-03-20-database-permissions-for-sqldependency"
published = 2008-03-20T08:35:00-07:00
author = "Emil"
tags = [ "SQL",]
+++
While I like the idea of [SQL 2005 Query
notifications](http://www.google.com/url?sa=t&ct=res&cd=2&url=http%3A%2F%2Fmsdn2.microsoft.com%2Fen-us%2Flibrary%2Fms130764.aspx&ei=E4XiR9XkL4rAgwPD0fXLAQ&usg=AFQjCNFVAgsQ5pURZzpx_aiqE163Seci0w&sig2=QJL4QWmeS-YWhunMenehfw),
the setup restrictions and instructions are fairly opaque. Blah! I did
manage to get it working after noting all the [restrictions on the
query](http://msdn2.microsoft.com/en-us/library/aewzkxxh.aspx) in this
MSDN article, but then I made the mistake of removing dbo permissions
from the user, and was thrown into the mix again for another hour of
churning.  
  
[This blog
post](http://blogs.msdn.com/dataaccess/archive/2005/09/27/474447.aspx)
was pretty useful, but didn't go quite all the way. Later, I found [a
post describing more
details](http://forums.microsoft.com/MSDN/ShowPost.aspx?PostID=533779&SiteID=1)
after some searching, and came up with this set of grant statements to
make it work:  

-   GRANT ALTER ON SCHEMA :: \[schemaname\] TO \[Role\]
-   GRANT CREATE PROCEDURE TO \[Role\]
-   GRANT CREATE QUEUE TO \[Role\]
-   GRANT CREATE SERVICE TO \[Role\]
-   GRANT REFERENCES on
    CONTRACT::\[http://schemas.microsoft.com/SQL/Notifications/PostQueryNotification\]
    to \[Role\]
-   GRANT VIEW DEFINITION TO \[Role\]
-   GRANT SELECT to \[Role\]
-   GRANT SUBSCRIBE QUERY NOTIFICATIONS TO \[Role\]
-   GRANT RECEIVE ON QueryNotificationErrorsQueue TO \[Role\]
-   GRANT IMPERSONATE ON USER::DBO TO \[Role\]
