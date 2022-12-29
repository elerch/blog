+++
title = "EduSpring Part 2: Simplifying dependencies"
slug = "2011-06-13-eduspring-part-2-simplifying-dependencies"
published = 2011-06-13T17:25:00-07:00
author = "Emil Lerch"
tags = [ "EduSpring",]
+++
[Last
time](http://emilsblog.lerch.org/2011/06/eduspring-part-1-introduction.html),
I introduced you to Spring, IoC, and Dependency Injection.  If you
haven't read that post, please do. This time, I'll start walking through
some of the code in the [accompanying GitHub
project](https://github.com/elerch/eduSpring).  The code is organized by
project in order of these posts.  Some conventions (specifically 1
class/file) have been ignored specifically to let the reader go through
in a linear manner.  All projects are setup as console applications.  
  
This time, I'll tackle the first project, "0 - Advantages of DI".  This
is one of the few projects I that will have more than one file to
peruse.  The first file is a baseline...how we would solve a particular
problem in a "traditional" procedural manner.  I've simulated a program
that calls a service (MyClass) that needs to authenticate the user prior
to performing some work on behalf of the caller.  If authentication
fails, it will throw an exception.  Here is the class:  
  

    /// 
        /// Simulates a typical class
        /// 
        public class MyClass
        {
            /// 
            /// Authentication provider.  We can't change this out for the production version 
            /// without changing source code and recompiling
            /// 
            private readonly MyAuthenticationProvider authenticationProvider = new MyAuthenticationProvider();

            // Comment the line above, uncomment and recompile for production.  
            // 
            // By recompiling, you won't know if you're testing the same
            // code that exists in production (did you just change this line, or something else too?)  Versions might 
            // be different, etc.
            //private readonly MyProductionAuthenticationProvider authenticationProvider = new MyProductionAuthenticationProvider();

            public void DoWork(string user, SecureString password)
            {
                if(!authenticationProvider.Authenticate(user,password).Identity.IsAuthenticated)
                    throw new SecurityException("Not authorized to perform this action");
                Thread.Sleep(3000);// Simulate some work
            }
        }

  
You'll notice that when we move this class into production, we have to
remember to swap out our authentication provider. In reality, the new
authentication provider might now call a central authentication
single-sign-on service through a web/rest service, might redirect the
user in order to change password, or any number of crazy things. For
these purposes, I just check that the password is "bar".  
  
The main point here is that we have to remember to swap, and we'll have
to recompile the application when we do that.  If we forget, anyone can
log in with anything and we'll happily give up the goods.  Since
everything has been "tested", it's likely we won't thoroughly check the
service (indeed, if we're on a production system, and this service's
purpose was to delete a bunch of accounts, we probably wouldn't test
it).  After deployment have two versions of the binary - one for
production, and one outside production.  Who is to say there aren't any
other changes in this code.  Now we have a maintenance problem too - we
can't assume the code is identical, and every time we deploy we run the
risk of missing this step.  But, it's simpler when we're coding it,
isn't it?  
  
If we could just pass this dependency into MyClass, we'll be in much
better shape.  At the minimum we can centralize the changes, and in the
best case we can move these changes out into a configuration file or
some other mechanism that doesn't require code changes for this simple
switch.  Enter the next file in this project - "1 -
WithDependencyInjection.cs".  Here are the contents:  
  

    /// 
        /// Simulates a typical class
        /// 
        public class MyClassWithDependencyInjection
        {
            /// 
            /// Authentication provider.  Because we use an interface, we no longer 
            /// need to change this code after it's been tested
            /// 
            private readonly IAuthenticate _authenticationProvider;

            /// 
            /// Constructor to establish this class' dependencies.  Since the 
            /// class is not "complete" (can't operate) without an authentication
            /// provider, we require an object up front.
            /// 
            /// public MyClassWithDependencyInjection(IAuthenticate authProvider)
            {
                if (authProvider == null)
                    throw new ArgumentNullException("authProvider");
                _authenticationProvider = authProvider;
            }

            public void DoWork(string user, SecureString password)
            {
                if (!_authenticationProvider.Authenticate(user, password).Identity.IsAuthenticated)
                    throw new SecurityException("Not authorized to perform this action");
                Thread.Sleep(3000);// Simulate some work
            }
        }

        /// 
        /// New Interface introduced.  Our two classes don't have a real-world inheritance relationship,
        /// but the authentication process is identical, so we build a contract
        /// 
        public interface IAuthenticate
        {
            IPrincipal Authenticate(string user, SecureString password);
        }

        class TestingAuthenticationProvider : IAuthenticate
        {
            public IPrincipal Authenticate(string user, SecureString password)
            {
                // Implementation for development
                return new GenericPrincipal(new GenericIdentity(user), new string[] { });
            }
        }

        class ProductionAuthenticationProvider : IAuthenticate
        {
            public IPrincipal Authenticate(string user, SecureString password)
            {
                if (user == "foo" && password.StringEquals("bar"))
                    return new GenericPrincipal(new GenericIdentity(user), new string[] { });
                return new GenericPrincipal(new GenericIdentity(""), new string[] { }); ;
            }
        }

  
Here, we've done the following things:  
  

1.  Introduced an interface for authentication and marked both providers
    as implementing the interface.  We could just as well have
    introduced a base class (concrete or abstract), but we have no
    default implementation, so an interface is probably best.
2.  Introduced a parameterized constructor for the main class.  Now this
    class lets the world know that it can't do it's job without a way to
    authenticate.  And it doesn't care how the authentication gets done,
    just that it **can** authenticate.

Back in the main program, we can now (sort of) demonstrate what we've
done.  Obviously without changing the code we can't demonstrate changing
the provider for MyClass, but we can demonstrate the DI approach to the
problem:

  

  

    static void Main(string[] args)
            {
                // Without DI
                new MyClass().DoWork("foo", new SecureString().Append("bar"));
                
                // With DI
                var testSystemProvider = new TestingAuthenticationProvider();
                var productionSystemProvider = new ProductionAuthenticationProvider();
                // The choice of test/production is now made here, outside of the class.  
                // The class shouldn't "care" who does the authentication work, it's job is to do other work
                // The new statement in the next line would be done through an IoC container (e.g. Spring) in a 
                // real environment.
                new MyClassWithDependencyInjection(testSystemProvider).DoWork("foo", new SecureString().Append("bar"));

                // Switch the constructor (in Spring.NET, done through a config file change) and now we're running against 
                // "production".  No recompile necessary
                new MyClassWithDependencyInjection(productionSystemProvider).DoWork("foo", new SecureString().Append("bar"));

                // We can also do this without a container.  Here, we'll get type information from the command line.
                // Change the provider type via project properties to see how this works.
                // The next line is basically what an IoC container would do
                var myAuthProvider = (IAuthenticate)Activator.CreateInstance(Type.GetType(args[0]));
                new MyClassWithDependencyInjection(myAuthProvider).DoWork("foo", new SecureString().Append("bar"));
            }

  
With dependency injection techniques, the caller can decide the
authentication mechanism.  Given a proper IoC container, this
configuration will be centralized, but for now, we can do it manually by
creating two objects, one of type TestingAuthenticationProvider and one
of type ProductionAuthenticationProvider.  These are passed into the
constructor for the DI class, and voilà, we can change the way
authentication works.  In the last two lines, I show how we can even
pass in the type name via the command line.  Now, for the first time, we
have the ability to change the way we authenticate without changing
code.  
  
...and that, folks, is all an IoC container is about.
