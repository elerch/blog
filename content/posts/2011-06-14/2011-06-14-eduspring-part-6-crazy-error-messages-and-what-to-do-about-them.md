+++
title = "EduSpring Part 6: Crazy Error Messages and What to do about them"
slug = "2011-06-14-eduspring-part-6-crazy-error-messages-and-what-to-do-about-them"
published = 2011-06-14T09:36:00-07:00
author = "Emil Lerch"
tags = [ "EduSpring",]
+++
Because Spring will create most of your objects up front, a simple error
in the configuration Xml can have disastrous effects.  This, in my
opinion, is the \#1 reason people fear Spring.

  

Here are a few error messages I've seen, and their corresponding
solutions:

-   **The virtual path '/currentcontext.dummy' maps to another
    application, which is not allowed**: This error message usually
    means you've deployed the application to a server, but forgotten to
    make the virtual directory an application in IIS.  Spring performs a
    server.Transfer() call to "~/currentcontext.dummy" to get all the
    dependency wiring done correctly before another server.Transfer()
    brings the request back to the right place.
-   **no application context for virtual path**:  This error message
    tells you that there's no spring configuration setup at all.
-   **Resource handler for the 'web' protocol is not defined**:  This
    message tells you that the httpModule is not active.  Add the
    spring.net HttpModule into the appropriate section of web.config
    (system.web for IIS6, system.webserver for IIS7).
-   **Could not load type from assembly**:  This may or may not have
    anything to do with Spring, so take a look a the stack trace.  If
    you see Spring.Core (specifically
    Spring.Core.TypeResolution.TypeResolver.Resolve) in the trace, you
    can be fairly certain you misspelled a type name in the
    configuration.
-   **node cannot be resolved for the specified context**: Spring tried
    to assign an object or value to a property, but the property doesn't
    exist on the object.  It's likely you misspelled the property name,
    or maybe you refactored, removed the property, but forgot to update
    the spring configuration.

Things to check if your dependency is showing up as null:

-   Is your configuration binding the right type?  For example, if your
    property is a string, and you're assigning a stringbuilder to it,
    Spring will just ignore the assignment.
-   You're missing the object definition in the spring configuration.
-   You're missing the property definition in the spring configuration.
-   Did you commit the cardinal sin of DI?  Do not use new MyType()!

Take a look through
[web.config](https://github.com/elerch/eduSpring/blob/master/4%20-%20Debugging%20Web%20Applications/Web.config)
and
[spring.config](https://github.com/elerch/eduSpring/blob/master/4%20-%20Debugging%20Web%20Applications/spring.config)
of the [Debugging Web
Applications](https://github.com/elerch/eduSpring/tree/master/4%20-%20Debugging%20Web%20Applications)
project in the [eduSpring](https://github.com/elerch/eduSpring) project
on GitHub for troubleshooting examples.  There are several errors
scattered throughout the two configuration files, and the errors are
fully documented.

  

Also note that the best way to work through the troubleshooting
procedure is to correct each issue in turn, shut down the integrated web
server and F5 to view the next error.

  

Setting up Spring.Net's verbose logging is also shown in the web.config.
 You might notice that the actual project references do not include
anything except standard ASP.NET DLLs.  Spring, Common Logging, and
Log4Net must exist in the bin directory at run time, but no project
references are actually required.  With VS 2010 SP1 or higher, we can
put these semi-dependent DLLs in a special folder called
\_bin\_deployableAssemblies and the build procedure will copy them in
place.
