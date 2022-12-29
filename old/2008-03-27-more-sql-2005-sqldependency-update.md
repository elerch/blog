+++
title = "More SQL 2005: SqlDependency update"
slug = "2008-03-27-more-sql-2005-sqldependency-update"
published = 2008-03-27T08:24:00-07:00
author = "Emil"
tags = [ "SQL",]
+++
While SQL Server data update notifications through the SqlDependency
object seemed like a great idea, I now believe the architecture is
fundamentally flawed...I'm looking forward to changes in this area to
make the feature more robust in the next release(s) of SQL Server and/or
the .NET Framework. Here are some of the problems I've run into:  

-   [Massive
    amounts](http://www.codeproject.com/KB/database/SqlDependencyPermissions.aspx)
    of [required
    permissions](http://emilsblog.lerch.org/2008/03/database-permissions-for-sqldependency.html)
    in the default run mode
-   Query types available are [incredibly
    restrictive](http://msdn2.microsoft.com/en-us/library/aewzkxxh.aspx)  
-   [Ineffective tear down of
    resources](http://blogs.msdn.com/remusrusanu/archive/2007/10/12/when-it-rains-it-pours.aspx),
    again, in default run mode, with no programatic workaround. (The
    worst part? The problem is actually most acute while doing active
    development...)  
-   [Severe
    ramifications](http://blogs.msdn.com/remusrusanu/archive/2007/10/12/when-it-rains-it-pours.aspx)
    for any issue, whether caused by environment or poor coding  
-   Complex (and maybe unusable) [setup for custom service/queue
    implementation](http://www.sqlskills.com/blogs/bobb/2006/06/28/PreprovisioningAndSqlDependency.aspx)
    to alleviate the first two issues. I never really even figured out
    that setup when operating in a non-default schema in a restricted
    permission environment.

This feature is a great concept, but with an implementation that
severely limits its use. My recommendation is to avoid this
functionality in nearly all cases. In my current project, I've moved to
a custom cache implementation that checks last modified date across all
all lookup tables and clears the cache of all out of date lists. If
something happens in between checks, we'll just have to deal with that.
