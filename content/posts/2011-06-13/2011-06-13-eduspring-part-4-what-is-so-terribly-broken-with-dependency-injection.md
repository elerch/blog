+++
title = "EduSpring Part 4: What is so terribly broken with Dependency Injection?"
slug = "2011-06-13-eduspring-part-4-what-is-so-terribly-broken-with-dependency-injection"
published = 2011-06-13T22:23:00.001000-07:00
author = "Emil Lerch"
tags = [ "EduSpring",]
+++
Move all the CS BS to the side.  This stuff doesn't work in the real
world.  And it's because of things that could have (and probably should
have) been fixed by uber-geeks 10+ years ago with fancy CompSci PhDs.
 And I'm talking about .Net specifically here, although I can throw the
same stones at Java.  Most (but not all) other languages have the same
problems I'll get on my soapbox about here.  
  
To do DI correctly, you have one of two options:  
  

1.  Your class has dependencies on properties/internal fields that
    implement Interfaces
2.  Your class has dependencies on properties/internal fields that
    implement base classes

In both cases, the contracts are relatively weak.  If you depend on a
method that requires an object and returns an object, there are lots of
things that can go wrong.  And you have no way of knowing whether it
will go wrong unless an until you run it - compile time checks don't
help.  Here's a short list of Murphy's law for a single method that
takes an object parameter and returns an object:

1.  Do you assume anything about the return value?  It might return what
    you expect, or might return null.  Or, it could throw an exception.
     Generally, experience with DI will teach you good defensive coding,
    but it does take work...
2.  Can the method handle null input values?  If it errors, is it going
    to return null or throw an exception?  If it throws, what kind of
    exception will it generate?
3.  Is the method you're calling going to muck with the object you pass
    in?  If it does alter properties, is that a problem?  What if you're
    not in control of the object, and the property this dependency
    decides it's OK to muck with throws an exception during the set
    operation?

Without some type of [design by
contract](http://en.wikipedia.org/wiki/Design_by_contract) construct
built into your language of choice, these questions become just the tip
of the iceberg.  Glancing through the Common Language Specification for
.NET, it appears that there is no built-in construct available in the
platform.  C\# provides a MS Research Code Contract construct in .NET 4,
but they feel hacky without being part of the language, and even more
hacky when implemented with IoC.  

  

Feel free to run through the Main method for FallaciesOfInterfaces for
concrete examples of how Murphy can strike.  This project will compile,
but will fail at almost every step.  Read through the comments and fix
the code one-by-one to get a sense of how, even with an IoC container
and good DI practices, everything must be tested.
