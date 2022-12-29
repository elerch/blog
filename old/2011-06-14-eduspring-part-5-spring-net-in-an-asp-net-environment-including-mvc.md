+++
title = "EduSpring Part 5: Spring.Net in an ASP.NET environment (including MVC)"
slug = "2011-06-14-eduspring-part-5-spring-net-in-an-asp-net-environment-including-mvc"
published = 2011-06-14T07:49:00-07:00
author = "Emil Lerch"
tags = [ "EduSpring",]
+++
This post is part of a
[series](http://emilsblog.lerch.org/search/label/EduSpring) on
Spring.NET. I recommend starting at the beginning if you haven't
already.  Also, I am walking through code in the [accompanying GitHub
project](https://github.com/elerch/eduSpring).  
  
By now, you should have the basics of DI, IoC, and the benefits and
drawbacks of the approach.  Now, I'll introduce you to the architecture
of Spring.NET in an ASP.NET environment.  I'm sure a lot of other IoC
frameworks operate in a similar manner.  If not, you can add code to
make them work that way. ;-)  
  
If you look at the
[IocWithoutSpring](https://github.com/elerch/eduSpring/tree/master/2%20-%20IocWithoutSpring)
project, you'll see this Main function:  
  

    static void Main(string[] args)
            {
                //These two lines are handled by the Spring.NET HttpModule
                var container = new IoCContainer();
                container.Initialize();

                // These two lines are also handled by the HttpModule by a special 
                // syntax in the spring configuration
                var service = new DoSomeWork();
                service.Worker = container.GetObject("myObject");

                // This is what the ASP.NET Framework would do
                Console.WriteLine("The output is: " + service.DoTheWork());
            }

  
Most of the time, creation of the IoC container itself is a single
dependency that's particularly hard to get rid of without writing some
reflection-style glue code.  Ideally, we want our objects to be
completely ignorant of this container, though.  In ASP.NET, the
web.config provides us with the concept of an HttpModule, which will
look at every request coming from into the web server and have an
opportunity to do something with it.  Taking advantage of this feature,
the Spring.Net team wrote an ASP.NET HttpModule that will do just that,
so the first two lines of main (instantiation and initialization of the
container) are handled by the ASP.NET framework.  Awesome!  
  
Now our Spring.Net dictionary is populated, assuming we have a valid
configuration.  I'll address more about the pain points of Spring
configuration later, but this very early creation of lots of objects is
one of the main frustrations of people who want to use Spring.Net.  The
next question is, what about setting up dependencies in ASPX pages?  
  
Technically speaking, the ASP.NET framework parses an ASPX file (or MVC
view) and code-generates a class.  On each request, it creates an
instance of this class and allows it to process the request, before
destroying the object.  Very stateless, but this creation and
destruction of classes rubs against IoC's
Dictionary&lt;string,object&gt; heart.  
  
If you [read this contract from the other
side](http://blogs.msdn.com/b/oldnewthing/archive/2008/05/28/8555658.aspx)
(a.k.a. how would I solve this problem if I were writing Spring.Net),
you can imagine yourself writing
a [PageHandlerFactory](http://msdn.microsoft.com/en-us/library/system.web.ui.pagehandlerfactory.aspx) that can
deliver the aspx page class with dependencies already injected.  There
are two problems you have to solve, however:  
  

1.  What name do you use to look up the object?
2.  How do you deal with request-specific data?

The answer to \#1 is relatively obvious if you look at the problem from
the perspective of Spring.  The object doesn't really have a name, so we
leave that blank, and the [virtual
path](http://msdn.microsoft.com/en-us/library/ms178116.aspx) (~/page.aspx)
is used as the type of the object since someone configuring the object
will not know the type ASP.NET generates.  The actual type name needs to
be figured out by Spring.  The answer to the second question runs a bit
contrary to what I've been discussing so far.

  

In the examples so far, the initialization method of the IoC container
has created all the objects in configuration and put them in its
internal dictionary.  However, there's no reason that the objects need
to be created right away, nor do they have to be held in the dictionary.
 In the case of this PageHandlerFactory, objects are created and
configured at the time of the request, not at initialization.  However,
dependencies follow the normal rules.
