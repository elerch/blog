+++
title = "EduSpring Part 1: Introduction"
slug = "2011-06-13-eduspring-part-1-introduction"
published = 2011-06-13T16:46:00-07:00
author = "Emil Lerch"
tags = [ "EduSpring",]
+++
I get quite a few questions about
[Spring.Net](http://springframework.net/), so I thought I'd put together
a VS Solution, presentation, and set of blog posts to provide some
background and details about what it is, why/when to consider using it,
and how to configure and debug the framework.  
  
A lot of this material will **not** be specific to Spring.Net, but
rather [Dependency
Injection](http://en.wikipedia.org/wiki/Dependency_injection) generally.
 To understand Spring.Net, you must be familiar with [Inversion of
Control](http://en.wikipedia.org/wiki/Inversion_of_control) and
Dependency Injection.  You can read about them on Wikipedia, but here's
a short summary:  
  
Inversion of Control: Flow of control of a system is inverted in
comparison to procedural programming  
Dependency Injection: A specific technique to achieve inversion of
control with respect to dependencies  
  
What this means in layman's terms is that instead of a program:  
  

1.  Starts up
2.  Creating new services for whatever needs to be done
3.  Using the services/doing the work
4.  Disposing of the services and returning the results

The program now does only what it's responsible.  Namely:

1.  Starts up
2.  Uses services that have been configured for its use/does the work
3.  Returns the results

This makes the program itself easier to test, simpler to code/maintain,
and separates infrastructural responsibilities (determine location of
services and creating them) from the business logic the program was
created to deliver.

  

The devil in these particular details are in \#2.  How does one create
and configure services for a program?  We can code this by hand, but
it's a lot of boring glue code, and doing it right is incredibly
difficult.  Enter the [IoC
container](http://www.martinfowler.com/articles/injection.html) - a
piece of pre-built code that will do this work for us.  Depending on the
application, we don't even need to use the container explicitly.  In a
system like [ASP.NET](http://www.asp.net/), we can use
[HttpModules](http://msdn.microsoft.com/en-us/library/system.web.ihttpmodule.aspx)
to intercept requests and wire dependencies automatically.

  

One significant problem with this approach are the complexity of
configuration.  Using Spring.net, I can have a dependency-injected
factory method to deliver an instance of an object used to populate a
property that will be injected into another object that will have
additional advice applied through Spring.Net's AOP module.  When that
fails, I might get a "node cannot be resolved for the specified context"
without any additional information pointing me to the cause of the
problem.  With flexibility comes complexity.

  

Another issue is a fundamental problem with .NET (C\# and VB and I
believe all .NET classes adhering to the
[CLI](http://www.ecma-international.org/publications/files/ECMA-ST/Ecma-335.pdf)).
 Interfaces are incomplete contracts.  

  

Finally, with regards to Spring.Net in particular, the framework can be
slow to move (IIS7 Integrated mode, introduced with Windows Server 2008
on Feb 27, 2008, gained support in Spring.Net 1.3.1 released December
10, 2010).  Also, no [Mono
support](http://forum.springframework.net/showthread.php?t=6875) exists
as of this writing.

  

Next up - some walkthrough code.
