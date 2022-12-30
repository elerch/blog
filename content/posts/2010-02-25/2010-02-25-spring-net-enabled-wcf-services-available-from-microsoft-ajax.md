+++
title = "Spring.Net-enabled WCF Services available from Microsoft Ajax"
slug = "2010-02-25-spring-net-enabled-wcf-services-available-from-microsoft-ajax"
published = 2010-02-25T17:39:00-08:00
author = "Emil"
tags = []
+++
[![](/posts/2010-02-25/thumbnails/2010-02-25-spring-net-enabled-wcf-services-available-from-microsoft-ajax-Magical+Snap+-+2010.02.25+16.58+-+005.png)](/posts/2010-02-25/2010-02-25-spring-net-enabled-wcf-services-available-from-microsoft-ajax-Magical+Snap+-+2010.02.25+16.58+-+005.png)

Implementing Spring.NET WCF services is fairly straightforward.  
  
Implementing MS Ajax WCF services is also straightforward, if you pick
the right New Item to add from Visual Studio.  
  
The complication comes in when you want a Spring.NET WCF service that
handles calls from Microsoft Ajax controls.  This method will let you
add them.   
  
Step 1. Add new "Ajax-Enabled WCF Service"  
  
  

[![](/posts/2010-02-25/thumbnails/2010-02-25-spring-net-enabled-wcf-services-available-from-microsoft-ajax-Magical+Snap+-+2010.02.25+16.59+-+006.png)](/posts/2010-02-25/2010-02-25-spring-net-enabled-wcf-services-available-from-microsoft-ajax-Magical+Snap+-+2010.02.25+16.59+-+006.png)

  
  
  

Step 2. Create your methods, test and make sure all base functionality
is working.  This sample is for a CascadingDropDown control from the
Ajax Control Toolkit, but any control will work.

  

[![](/posts/2010-02-25/thumbnails/2010-02-25-spring-net-enabled-wcf-services-available-from-microsoft-ajax-Magical+Snap+-+2010.02.25+17.03+-+007.png)](/posts/2010-02-25/2010-02-25-spring-net-enabled-wcf-services-available-from-microsoft-ajax-Magical+Snap+-+2010.02.25+17.03+-+007.png)  
  
  
  

[![](/posts/2010-02-25/thumbnails/2010-02-25-spring-net-enabled-wcf-services-available-from-microsoft-ajax-Magical+Snap+-+2010.02.25+17.06+-+011.png)](/posts/2010-02-25/2010-02-25-spring-net-enabled-wcf-services-available-from-microsoft-ajax-Magical+Snap+-+2010.02.25+17.06+-+011.png)

Step 3. Introduce an interface to use for the methods.  Spring.Net
requires an interface, and this is the crux of the problem.  Here I've
created IMyAjaxService.  
  
  

Step 4. Move the \[ServiceContract(Namespace = "")\] from the class to
the interface

[![](/posts/2010-02-25/thumbnails/2010-02-25-spring-net-enabled-wcf-services-available-from-microsoft-ajax-Magical+Snap+-+2010.02.25+17.09+-+012.png)](/posts/2010-02-25/2010-02-25-spring-net-enabled-wcf-services-available-from-microsoft-ajax-Magical+Snap+-+2010.02.25+17.09+-+012.png)  
  

Step 5. Move the \[OperationContract\] tags from the methods on the
class to the interface method definitions

  

 [![](/posts/2010-02-25/thumbnails/2010-02-25-spring-net-enabled-wcf-services-available-from-microsoft-ajax-Magical+Snap+-+2010.02.25+17.10+-+013.png)](/posts/2010-02-25/2010-02-25-spring-net-enabled-wcf-services-available-from-microsoft-ajax-Magical+Snap+-+2010.02.25+17.10+-+013.png)

  

Step 6. Change web.config endpoint contract (xpath =
/configuration/system.serviceModel/services/service/endpoint) to
reference the interface  
  

[![](/posts/2010-02-25/thumbnails/2010-02-25-spring-net-enabled-wcf-services-available-from-microsoft-ajax-Magical+Snap+-+2010.02.25+17.13+-+015.png)](/posts/2010-02-25/2010-02-25-spring-net-enabled-wcf-services-available-from-microsoft-ajax-Magical+Snap+-+2010.02.25+17.13+-+015.png)

  
  
Step 7: Test. The test should work, without dependency injection from
Spring.Net.  Now we have a WCF service that responds to Ajax, but has
the interface definitions just the way Spring likes them.  
  

<span class="underline"><span style="font-size: large;">Wiring in
Spring</span></span>

  
For Spring.NET to handle WCF, you need .NET 3.0 or higher, and you need
Spring.Net 1.3.0 or higher.  You'll need the following DLLs available
for binding (either your bin directory or the GAC):  
  

-   Spring.Core.dll from the 2.0 folder
-   Spring.Web.dll from the 2.0 folder
-   Spring.Services.dll from the 3.0 folder

In the Service you've created, edit the markup and add
Factory="Spring.ServiceModel.Activation.ServiceHostFactory" onto the
end, like so:  
  

[![](/posts/2010-02-25/thumbnails/2010-02-25-spring-net-enabled-wcf-services-available-from-microsoft-ajax-Magical+Snap+-+2010.02.25+17.14+-+016.png)](/posts/2010-02-25/2010-02-25-spring-net-enabled-wcf-services-available-from-microsoft-ajax-Magical+Snap+-+2010.02.25+17.14+-+016.png)

This will get Spring.Net into the activation pipeline for the service.  
  
Lastly, you'll add the new object to spring configuration.  It is <span
style="background-color: white;">CRITICAL that the OBJECT ID MATCH THE
SERVICE NAME FROM WEB.CONFIG.  The Spring.Net documentation mentions
this, but I don't think they mention it very loudly.  The type
information is exactly as you'd expect: the type for the WCF service
class.</span>  
<span style="background-color: white;">  
</span>  
Also CRITICAL:  Add singleton="false" to the object definition for
Spring for your new object
