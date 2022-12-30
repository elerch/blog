+++
title = "Total application design: circa 2011"
slug = "2011-06-05-total-application-design-circa-2011"
published = 2011-06-05T23:01:00-07:00
author = "Emil Lerch"
tags = []
+++
Working with a few recent projects I'm getting pretty close to a nice
boilerplate for a "standard" web application built with the latest
technologies.  Subject to client restraints, here's the stack:  

-   UI and middle tier: [ASP.NET MVC3](http://www.asp.net/mvc) (using
    VS2010 SP1).  Note that this requires .NET 4, which has some nice
    features (I love Tuples) but I don't think is completely necessary
    otherwise.  SP1 is important, which I'll mention later.  For
    smaller-ish applications I've been moving away from multiple
    projects in a solution, mainly because I haven't been seeing a ton
    of real business logic besides authorization, and I've been able to
    productize many ancillary functions into separate DLLs.  Razor view
    engine is used, and templates are updated to mirror
    [Html5Boilerplate.com](http://html5boilerplate.com/)'s templates.
    jQuery is applied unobtrusively.
-   Data access: [Fluent NHibernate](http://fluentnhibernate.org/).
     This is integrated in such a way that depending on your needs, you
    don't need to add a direct reference to it, though.  References are
    needed for access to NHibernate advanced queries and the Linq
    provider.
-   URL Rewriting: [UrlRewriter.Net](http://urlrewriter.net/). This is
    used for css/js versioning.  A
    [URLHelper](http://msdn.microsoft.com/en-us/library/system.web.mvc.urlhelper.aspx)
    extension method appends the current version number (derived at
    build time from source control) for the application to the script or
    CSS filename, and the rewriter strips it back off.  We probably
    could use MVC3 routes here, but it seems overkill for something that
    could be handled by simple Url rewriting.
-   Dependency Injection: [Spring.net](http://www.springframework.net/).
     Any DI/IOC container would work here.  Again, the integration with
    spring is very lightweight and easily replaceable.  One strike
    against Spring.Net is the lack of support for Mono, but this hasn't
    been an issue in the environments with which I've been working.
-   Other tools: [Dotless](http://www.dotlesscss.org/) is used in a
    development-time capacity to generate CSS, with
    [Chirpy](http://chirpy.codeplex.com/) ([customized](https://hg01.codeplex.com/forks/etlerch/directorybasedsettingswithinchirp))
    to keep the development experience smooth.  A handful of other
    custom DLLs and build tools keep the project structure relatively
    vanilla.  [Hudson](http://hudson-ci.org/) is used for continuous
    integration.

I'm putting together a NuGet package with this build.  When this is
complete, I'll post an update.

  

Other technologies/tools on the radar are [Entity
Framework](http://msdn.microsoft.com/en-us/library/aa697427(v=vs.80).aspx)
(NHibernate replacement) and [Castle
Windsor](http://www.castleproject.org/) (IoC container that supports
Mono).  [DotNetOpenAuth](http://www.dotnetopenauth.net/) is under
consideration as a standard way to pull in authentication and
authorization functions.
