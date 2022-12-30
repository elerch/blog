+++
title = "Supporting Multiple Databases in Applications"
slug = "2011-03-29-supporting-multiple-databases-in-applications"
published = 2011-03-29T08:48:00.001000-07:00
author = "Emil Lerch"
tags = []
+++
In general, having a persistence-ignorant application provides a lot of
flexibility.  Allowing us to easily port between various RDBMS’s, NoSQL
data stores, text files, the cloud, or simply storing our data on
papyrus managed and maintain by a group of beer-making monks provides us
with tangible opportunities to cross-sell our (non-hosted) application
to multiple clients.

As any write once, run anywhere scheme, support for multiple databases
can be notoriously difficult.  Consider the following SQL Server T-SQL
code:

![](/posts/2011-03-29/2011-03-29-supporting-multiple-databases-in-applications-Table%20name%20sensitivity.png)

Wait…what?  I just created FOO, yet SQL Server is telling me that the
table foo doesn’t exist.  What’s going on?  In this case, the database
[default
collation](http://msdn.microsoft.com/en-us/library/ms175835.aspx) has
been changed to Latin1\_General\_Bin, a binary collation, so FOO !=
‘foo’.  As a result, the following query also provides no results:

![](/posts/2011-03-29/2011-03-29-supporting-multiple-databases-in-applications-Case%20sensitivity%20at%20data%20level.png)

To get any data back from this table, we need to match exactly:

![](/posts/2011-03-29/2011-03-29-supporting-multiple-databases-in-applications-Sucess.png)

Great, so I’ve jacked the default installation collation in SQL Server. 
Not a lot of people or organizations do this?  But…is this an academic
exercise?  If you want to support multiple databases and clients, the
answer is a resounding NO.  Consider:

1.  Some organizations may want the application to work on a database
    with binary collation.  Rare, but it could happen.
2.  Organizations might be using another database, and not all databases
    are case insensitive, even by default.

If you want a portable application, \#2 is your much more concerning
issue.  Recently I verified default installations on a number of popular
database systems to determine what behavior they produced.  Here are my
findings (in alphabetical order):

<table>
<tbody>
<tr class="odd">
<td></td>
<td>Table/Column Names</td>
<td>Data</td>
</tr>
<tr class="even">
<td>Oracle</td>
<td>Insensitive</td>
<td>Sensitive</td>
</tr>
<tr class="odd">
<td>Postgres</td>
<td>Insensitive</td>
<td>Sensitive</td>
</tr>
<tr class="even">
<td>MySQL</td>
<td>Sensitive</td>
<td>Insensitive</td>
</tr>
<tr class="odd">
<td>SQLLite</td>
<td>Insensitive</td>
<td>Sensitive</td>
</tr>
<tr class="even">
<td>SQL Server</td>
<td>Insensitive</td>
<td>Insensitive</td>
</tr>
</tbody>
</table>

The most curious finding is MySQL.  I’d love to know what reasoning was
used to come to the conclusion that Table and Column names should be
case sensitive, but data should be considered insensitive.  In any case,
programming for the least common denominator requires handling these
situations. 

Ideally you’d leave the SQL to an ORM.  If your application is unlikely
to switch database platforms and an ORM is out of the question, I’d
recommend a RDBMS-specific data access layer.  If you’re application
absolutely must have a generic data layer, though, you must keep this in
mind as part of design.
