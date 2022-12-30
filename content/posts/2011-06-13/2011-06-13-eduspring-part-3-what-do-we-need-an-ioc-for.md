+++
title = "EduSpring Part 3: What do we need an IoC for?"
slug = "2011-06-13-eduspring-part-3-what-do-we-need-an-ioc-for"
published = 2011-06-13T22:05:00-07:00
author = "Emil Lerch"
tags = [ "EduSpring",]
+++
This post is part of a
[series](http://emilsblog.lerch.org/search/label/EduSpring) on
Spring.NET. I recommend starting at the beginning if you haven't
already.  Also, I am walking through code in the [accompanying GitHub
project](https://github.com/elerch/eduSpring).  
  
Last time, I walked through why we might want to use dependency
integration.  Outside the authentication example, here are a few other
examples:  
  

-   Authentication
-   Authorization
-   SMTP settings
-   Payment gateways
-   Business rules (rule engine style)
-   Branding

This time, I'd like to explore how an IoC container actually does its
job.  By understanding how the IoC does its job, we can understand the
value that it adds to our solutions. In the project "[2 -
IocWithoutSpring](https://github.com/elerch/eduSpring/tree/master/2%20-%20IocWithoutSpring)"
on GitHub, you'll see a quick, hand-coded IoC container.  It's amazingly
brilliant (insert sarcasm here) and also relatively close to what a real
IoC container does (really).  Here is the IocContainer class in all it's
glory:  
  

    class IoCContainer
        {
            private readonly IDictionary _allObjects = new Dictionary();

            public T GetObject(string objectName)
            {
                return (T)_allObjects[objectName];
            }

            public void Initialize()
            {
                // Wouldn't it be nice if we could configure this through 
                // app.config or web.config?  Spring does that!
                _allObjects.Add("myObject", new ClassA());
            }
        }

  
Most IoC containers work in a similar manner. There's some sort of
initialization function, and there's some sort of GetObject method.
 Internally, all it does is "new up" all the classes you've defined and
shoves them in a global dictionary object.  The rest, as they say, is
window dressing.  As you see in the comment, once you've built an IoC
container, you can think of all kinds of cool things to do.  It would be
really nice if you could configure from web.config/app.config, or maybe
a separate XML file, or maybe the database, or maybe all of them?  What
if you added the ability to set properties on the objects, not just
create them?  How about the ability to create an object based on the
state of another object (Spring calls this a factory method).  How
about defining objects in one place, and values for properties in
another?  IoC containers have all this stuff, and it's built for
you...there's no reason to reinvent the wheel.  
  
But at the end of the day, remember: An IoC container, at its heart, is
a Dictionary&lt;string, object&gt;.  And that's all, folks.  Another key
thing to remember, especially in a stateless ASP.NET scenario, is that
those objects exist during the lifetime of the application.  This is a
performance gain (no GC stepping in, no creation of multiple objects),
and a bug factory if you assume your objects are going to be created,
used once, and destroyed.  
  
More goodies are in the [main
file](https://github.com/elerch/eduSpring/blob/master/2%20-%20IocWithoutSpring/IoCWithoutSpring.cs)
if you read the comments, but I'll explore them more in depth in later
posts.
