+++
title = "Yet more SQL 2005 fun: Developing search procs"
slug = "2008-03-27-yet-more-sql-2005-fun-developing-search-procs"
published = 2008-03-27T08:47:00.001000-07:00
author = "Emil"
tags = [ "SQL",]
+++
A common pattern in applications is to have a search stored procedure
work as the backend for a search screen. If a term has not been passed
by the user, the intent is that there is no filter on the results for
that parameter. Here's a [great
article](http://www.sommarskog.se/dyn-search.html) discussing the ways
that this can be acheived. I'm a personal fan of the COALESCE statement
talked about in the
[static](http://www.sommarskog.se/dyn-search.html#static) discussion.  
  
One area that was not discussed in the article was the idea of having
similar functionality with a list of filters (e.g. filter to these
specific books in the library). I found a [pretty good
article](http://weblogs.asp.net/jgalloway/archive/2007/02/16/passing-lists-to-sql-server-2005-with-xml-parameters.aspx)
talking about SQL 2005's use of Xml parameters to do this - Xml's main
benefit being that it's more designed for this use case than a delimited
string. However, the same problem now applies...what if I either have a
list of books, or don't pass anything, meaning I want to search across
all books?  
  
My solution was to grab all the data from the reference table and build
my own Xml string. Then I could use it in the main select statement:  
  
<span style="color: rgb(51, 51, 255);">IF </span>@param<span
style="color: rgb(102, 102, 102);"> is null </span>  
<span style="color: rgb(51, 51, 255);">SET </span>@param =  
(<span style="color: rgb(51, 51, 255);">SELECT </span>1 <span
style="color: rgb(51, 51, 255);">AS </span>Tag,0 <span
style="color: rgb(51, 51, 255);">AS </span>Parent,MyElementName <span
style="color: rgb(51, 51, 255);">AS </span>\[Root!1!string!element\]  
<span style="color: rgb(51, 51, 255);">FROM </span>sourcetable <span
style="color: rgb(51, 51, 255);">FOR XML EXPLICIT</span>)  
  
<span style="color: rgb(51, 51, 255);">SELECT</span>...  
<span style="color: rgb(51, 51, 255);">WHERE</span>...  
...<span style="color: rgb(51, 51, 255);">AND </span>  
FieldName <span style="color: rgb(51, 51, 255);">IN </span>  
(<span style="color: rgb(51, 51, 255);">SELECT </span>Field.value(<span
style="color: rgb(255, 0, 0);">'.'</span>,<span
style="color: rgb(255, 0, 0);">'VARCHAR(max)'</span>) FinalName  
<span style="color: rgb(51, 51, 255);">FROM </span>@param.nodes(<span
style="color: rgb(255, 0, 0);">'//string'</span>) <span
style="color: rgb(51, 51, 255);">AS </span>Table(Field))  
  
I'm sure this wouldn't perform well with large tables, but my reference
tables are fairly small (&lt;100 rows each), and it works great.  
  
FYI: Here is an example COALESCE statement for the standard filters:  
  
table <span style="color: rgb(102, 102, 102);">LIKE </span><span
style="color: rgb(255, 0, 0);">'%'</span> + <span
style="color: rgb(153, 51, 153);">COALESCE</span>(@Name,
fac.FacilityName ) + <span style="color: rgb(255, 0, 0);">'%'</span>
