+++
title = "The constraint for route parameter 'httpMethod' on the route with URL '{controller}/{id}' must have a string value in order to use an HttpMethodConstraint."
slug = "2012-05-24-the-constraint-for-route-parameter-httpmethod-on-the-route-with-url-controller-id-must-have-a-string-value-in-order-to-use-an-httpmethodconstraint"
published = 2012-05-24T07:39:00-07:00
author = "Emil Lerch"
tags = []
+++
Wow...what did that mean?  Here I am, just using @Url.Action (and
BeginForm and any other method that walks the route table backwards).
 My application is RESTful, so most routes have an HttpMethodConstraint
so they only match if the method is correct.  
  
I could not wrap my head around this message and ended up using
[JustDecompile](http://www.telerik.com/products/decompiler.aspx) to pull
open System.Web.Routing and had a look at
the [HttpMethodConstraint](http://msdn.microsoft.com/en-us/library/system.web.routing.httpmethodconstraint) [Match](http://msdn.microsoft.com/en-us/library/system.web.routing.httpmethodconstraint.match) method.
 You'll note that
the [routeDirection](http://msdn.microsoft.com/en-us/library/system.web.routing.routedirection) parameter
tells the object whether to match based on an incoming request (the
normal case) or for Url Generation (used for Url.Action, BeginForm and
the like).  
  
Pulling open the source, I found this:  
  
  

        switch (routeDirection1)
        {
            case RouteDirection.IncomingRequest:
            {
                ICollection<string> allowedMethods = this.AllowedMethods;
                if (func == null)
                {
                    func = (string method) => string.Equals(method, httpContext.Request.HttpMethod, StringComparison.OrdinalIgnoreCase);
                }
                return allowedMethods.Any<string>(func);
            }
            case RouteDirection.UrlGeneration:
            {
                if (values.TryGetValue(parameterName, out obj))
                {
                    string str = obj as string;
                    if (str != null)
                    {
                        return this.AllowedMethods.Any<string>((string method) => string.Equals(method, str, StringComparison.OrdinalIgnoreCase));
                    }
                    else
                    {
                        object[] url = new object[2];
                        url[0] = parameterName;
                        url[1] = route.Url;
                        throw new InvalidOperationException(string.Format(CultureInfo.CurrentUICulture, RoutingResources.HttpMethodConstraint_ParameterValueMustBeString, url));
                    }
                }
                else
                {
                    return true;
                }
            }
        }

  
The RouteDirection.UrlGeneration case block represents what happens when
the HttpMethodConstraint is asked to match for a generated Url.  The
InvalidOperationException represents the error message we see on the
YSOD.  
  
Even this took me a bit to work through, but the bottom line is that
it's finding the parameter name from the route and looking for the value
of that parameter name from the input provided to it.  Given the
following route:  

        routes.MapRoute("UpdateByPut",
            "{controller}/{id}",
            new { action = "Update" },
            new { httpMethod = new HttpMethodConstraint("PUT") }
        );

  
HttpMethodConstraint will find httpMethod (this is the value of
parameterName in the code above), and look for a route value of
httpMethod, expecting it to be a string.  If it doesn't, it will throw
the exception.  So, using the route above with the following code:  
  

      @Url.Action("Show", "MyEntity", new { id = Model.Id })

  
Won't work.  Instead, you need this:  
  

      @Url.Action("Show", "MyEntity", new { id = Model.Id, httpMethod = "GET" })

  
Also note that the property name httpMethod in the @Url.Action line
above comes from the same property name I used in routes.MapRoute within
Global.asax.cs.  This is one of the few times that MVC cares about the
property name used on a constraint.    
  
Once you understand what the error message is trying to tell you it's
all pretty clear.  You just need to be a rocket scientist the first time
through.
