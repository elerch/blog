+++
title = "Intermittent Operation Aborted Errors in IE when using MS Ajax"
slug = "2009-07-08-intermittent-operation-aborted-errors-in-ie-when-using-ms-ajax"
published = 2009-07-08T22:50:00.001000-07:00
author = "Emil"
tags = []
+++
This issue has been plaguing our project: operation aborted errors,
intermittent in nature, occurring sometimes as little as once/week. Even
in IE 8 there were issues, although thankfully not the crazy dialog box
we see in IE 6 and 7.  
  
It turns out that the problem is due to a bug in Ajax itself. I won't go
into all the details, since they're covered very well in these two blog
posts:  

-   First post with background:
    <http://seejoelprogram.wordpress.com/2008/06/08/when-sysapplicationinitialize-causes-operation-aborted-in-ie/>  
-   Second post with bug fixes to the original bug fix:
    [http://seejoelprogram.wordpress.com/2008/10/03/fixing-sysapplicationinitialize-again/](http://www.blogger.com/post-create.g?blogID=6692354#%20http://seejoelprogram.wordpress.com/2008/10/03/fixing-sysapplicationinitialize-again/)  

I didn't particularly care for the recommended way of packaging the fix,
so instead I've used built-in ASP.NET Ajax functionality to override the
default script delivery. I also updated the fixed functions to work for
all versions of Ajax (at the time of this writing - currently Ajax
bundled with .NET 3.5 SP1 and below). First, here are the updated
functions:  
  

-   Sys$\_Application$initialize:  

         function Sys$_Application$initialize() {
             if(!this._initialized && !this._initializing) {
                 this._initializing = true;
                 var u = window.navigator.userAgent.toLowerCase(),
                     v = parseFloat(u.match(/.+(?:rv|it|ml|ra|ie)[\/: ]([\d.]+)/)[1]);

                 var initializeDelegate = Function.createDelegate(this, this._doInitialize);

                 if (/WebKit/i.test(u) && v < 525.13)
                 {
                     this._load_timer = window.setInterval(function()
                     {
                         if (/loaded|complete/.test(document.readyState))
                         {
                             initializeDelegate();
                         }
                     }, 10);
                 }
                 else if (/msie/.test(u) && !window.opera)
                 {
                     document.attachEvent('onreadystatechange',
                         function (e) {
                             if (e && arguments.callee && document.readyState == 'complete') {
                                 document.detachEvent('on'+e.type, arguments.callee);
                                 initializeDelegate();
                             }
                         }
                     );
                     if (window == top) {
                         (function () {
                             try {
                                 document.documentElement.doScroll('left');
                             } catch (e) {
                                 setTimeout(arguments.callee, 10);
                                 return;
                             }
                             initializeDelegate();
                         })();
                     }

                 }
                 else if (document.addEventListener
                     &&  ((/opera\//.test(u) && v > 9) ||
                         (/gecko\//.test(u) && v >= 1.8) ||
                         (/khtml\//.test(u) && v >= 4.0) ||
                         (/webkit\//.test(u) && v >= 525.13))) {
                     document.addEventListener("DOMContentLoaded", initializeDelegate, false);
                 }
                 else
                 {
                     $addHandler(window, "load", initializeDelegate);
                 }
             }
         }

      

-   Sys$\_Application$\_doInitialize():  

         function Sys$_Application$_doInitialize() {
           if (this._initialized) {
            return;
           }
           Sys._Application.callBaseMethod(this, 'initialize');
           if (this._load_timer !== null)
           {
            clearInterval(this._load_timer);
            this._load_timer = null;
           }
           var handler = this.get_events().getHandler("init");
           if (handler) {
            this.beginCreateComponents();
            handler(this, Sys.EventArgs.Empty);
            this.endCreateComponents();
           }
           if (Sys.WebForms) {
            if (this._onPageRequestManagerBeginRequest) this._beginRequestHandler = Function.createDelegate(this, this._onPageRequestManagerBeginRequest);
            if (this._beginRequestHandler) Sys.WebForms.PageRequestManager.getInstance().add_beginRequest(this._beginRequestHandler);
            if (this._onPageRequestManagerEndRequest) this._endRequestHandler = Function.createDelegate(this, this._onPageRequestManagerEndRequest);
            if (this._endRequestHandler) Sys.WebForms.PageRequestManager.getInstance().add_endRequest(this._endRequestHandler);
           }

           if (this.get_stateString){
            var loadedEntry = this.get_stateString();
            if (loadedEntry !== this._currentEntry) {
             this._navigate(loadedEntry);
            }
           }
           this.raiseLoad();
           this._initializing = false;
          }

      

-   Sys$\_Application$\_loadHandler():  

         function Sys$_Application$_loadHandler() {
          if(this._loadHandlerDelegate) {
           Sys.UI.DomEvent.removeHandler(window, "load", this._loadHandlerDelegate);
           this._loadHandlerDelegate = null;
          }
          this._initializing = true;
          this._doInitialize();
         }

      

  
  
Next, here is how I overrode how the framework delivers the script:  
  

      <ajaxtoolkit:toolkitscriptmanager runat="server" enablepartialrendering="true" id="ScriptManager">
           <scripts>
               <asp:scriptreference name="MicrosoftAjax.js" assembly="System.Web.Extensions, Version=3.5.0.0, Culture=neutral, PublicKeyToken=31BF3856AD364E35" path="~/js/MicrosoftAjax-withFix.js">
           </scripts>
      </ajaxToolkit:ToolkitScriptManager>

  
You do not need to use the ToolKitScriptManager - you can also do it
this way:  
  

       <asp:scriptmanager runat="server" enablepartialrendering="true" id="ScriptManager">
           <scripts>
    <asp:scriptreference name="MicrosoftAjax.js" assembly="System.Web.Extensions, Version=3.5.0.0, Culture=neutral, PublicKeyToken=31BF3856AD364E35" path="~/js/MicrosoftAjax-withFix.js">
           </scripts>
       </asp:ScriptManager>

  
Note that you can replace ~/js with the directory of your choosing.  
  
Be aware that when the framework loads the file, it automatically adds
.debug or .release onto the end of the file name, so the final file
reference provided will be either MicrosoftAjax-withFix.debug.js or
MicrosoftAjax-withFix.release.js.  
  
If you don't want to bother incorporating these fixes into .NET 3.5 SP1
Ajax files, feel free to download them from here:  
  

-   Debug version:
    <http://lerch.org/js/MicrosoftAjax-WithFix.debug.js>  
-   Release version (simply a minified version of the debug js - run
    through [YUI
    Compresssor](http://developer.yahoo.com/yui/compressor/)):
    <http://lerch.org/js/MicrosoftAjax-WithFix.release.js>
