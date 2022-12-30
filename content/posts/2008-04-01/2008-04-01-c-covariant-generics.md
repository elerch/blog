+++
title = "C# Covariant Generics"
slug = "2008-04-01-c-covariant-generics"
published = 2008-04-01T08:28:00-07:00
author = "Emil"
tags = [ "C#",]
+++
Sorry for the highly technical posts...lighter stuff to come!  
  
This has really been bugging me on my current project. In an object
oriented system, if one class inherits from another (e.g. "Cat" inherits
from "Animal"), and a method expects to receive the base class as a
parameter, it is safe to send in a subtype. In my example, a method
operating on "Animal" can take "Cat" safely. This is sometimes called
"downcasting".  
  
This behavior should extend to generic types. Again, in my example, if a
method expects a List of Animals, I should be able to pass in a List of
Cats. However, C\# does not allow this behavior (but the CLR does).
Bah!  
  
Here is some more background I've dug up on the issue:  

-   [MS Research
    article](http://research.microsoft.com/research/pubs/view.aspx?type=inproceedings&id=1215)
-   [Google Groups
    discussion](http://groups.google.com/group/microsoft.public.dotnet.languages.csharp/browse_thread/thread/b47879b2fecdf61a)
