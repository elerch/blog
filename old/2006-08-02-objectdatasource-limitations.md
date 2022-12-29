+++
title = "ObjectDataSource limitations"
slug = "2006-08-02-objectdatasource-limitations"
published = 2006-08-02T08:12:00-07:00
author = "Emil"
tags = []
+++
One of the more exciting things in Visual Studio 2005 for me was the
idea of an object data source for grids. Well, I'm not doing a lot of
hands on programming right now, and I finally got around to using it.
I'm not that thrilled. Here's a snippet from a [help
file](http://msdn2.microsoft.com/en-us/library/ms227436.aspx) that is my
current source of frustration:  
<span id="ctl00_LibFrame_MainContent"></span>

> <span id="ctl00_LibFrame_MainContent">The **ObjectDataSource** control
> will create an instance of the source object, call the specified
> method, and dispose of the object instance all within the scope of a
> single request, if your object has instance methods instead of
> **static** methods (**Shared** in Visual Basic). Therefore, your
> object must be stateless. That is, your object should acquire and
> release all required resources within the span of a single
> request.</span>

This pretty much means that they expect an object to be a pass through
to some other data source (XML, DB, etc.). I'm just capturing some
session information right now. I find it easier to create/populate an
object and databind directly then try to make an object that's specific
to this problem. I think for the time being I'll go that route...
