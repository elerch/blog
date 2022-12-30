+++
title = "Enabling Quartz jobs in ASP.NET applications that will run despite restart"
slug = "2013-01-11-enabling-quartz-jobs-in-asp-net-applications-that-will-run-despite-restart"
published = 2013-01-11T16:29:00.003000-08:00
author = "Emil Lerch"
tags = []
+++
With IIS 7.5, you can now [auto-start applications and have them
continuously
run](http://weblogs.asp.net/scottgu/archive/2009/09/15/auto-start-asp-net-applications-vs-2010-and-net-4-0-series.aspx).
 However,
implementing [System.Web.Hosting.IProcessHostPreloadClient](http://msdn.microsoft.com/en-us/library/system.web.hosting.iprocesshostpreloadclient.aspx)
means having a Process method with some significant restrictions.  In a
[Spring.Net](http://www.springframework.net/) environment, the IOC
Container's context is not yet started, and it will fail in [rather
spectacular
ways](http://stackoverflow.com/questions/13162545/handler-extensionlessurlhandler-integrated-4-0-has-a-bad-module-managedpipeli)
if you try to crank it up with a hack.  Even if you manage to do this,
Quartz does not start up, so your jobs still will fail to run.  
  
I spent some time on this problem and discovered that I do have access
to [System.Web.HttpRuntime.AppDomainAppVirtualPath](http://msdn.microsoft.com/en-us/library/system.web.httpruntime.appdomainappvirtualpath.aspx),
which allows us to automatically fire an initial request at the app
automatically, if we're careful.  This will crank up Application\_Start
and the rest of the Spring (and Quartz) machinery, allowing us to keep
an app running 100% of the time.  This initial request, however, will be
thrown away, even if fired asynchronously, if initiated during the
Preload() method.  I ended up using a thread to get around this problem,
allowing the requests to fire 500ms after the Preload method runs.  
  
In certain cases, we can't just use
http://localhost/*yourvirtualpathhere*.  You might have multiple sites
listening to different host headers, or you might be running SSL and
don't want to hit the application using localhost.  To cover those
cases, I devised a web.config appSettings scheme where additional URLs
can be applied to Preload (space delimited).  You can also specify an IP
address or machine name, so the web.config can stay static but different
URLs can be applied as you move through environments.  Here is the
code:  
  
  

    public class Preloader : System.Web.Hosting.IProcessHostPreloadClient
        {
            public void Preload(string[] parameters)
            {
                var uris = System.Configuration.ConfigurationManager.AppSettings["AdditionalStartupUris"];
                StartupApplication(AllUris(uris));
            }

            public void StartupApplication(IEnumerable<Uri> uris)
            {
                new System.Threading.Thread(o =>
                {
                    System.Threading.Thread.Sleep(500);
                    foreach (var uri in (IEnumerable<Uri>)o) {
                        var client = new System.Net.WebClient();
                        client.DownloadStringAsync(uris.First());
                    }
                }).Start(uris);
            }

            public IEnumerable<Uri> AllUris(string userConfiguration)
            {
                if (userConfiguration == null)
                    return GuessedUris();
                return AllUris(userConfiguration.Split(' ')).Union(GuessedUris());
            }

            private IEnumerable<Uri> GuessedUris()
            {
                string path = System.Web.HttpRuntime.AppDomainAppVirtualPath;
                if (path != null)
                    yield return new Uri("http://localhost" + path);
            }

            private IEnumerable<uri> AllUris(params string[] configurationParts)
            {
                return configurationParts
                    .Select(p => ParseConfiguration(p))
                    .Where(p => p.Item1)
                    .Select(p => ToUri(p.Item2))
                    .Where(u => u != null);
            }

            private Uri ToUri(string value)
            {
                try {
                    return new Uri(value);
                }
                catch (UriFormatException) {
                    return null;
                }
            }

            private Tuple<bool string> ParseConfiguration(string part)
            {
                return new Tuple<bool, string>(IsRelevant(part), ParsePart(part));
            }

            private string ParsePart(string part)
            {
                // We expect IPv4 or MachineName followed by |
                var portions = part.Split('|');
                return portions.Last();
            }

            private bool IsRelevant(string part)
            {
                var portions = part.Split('|');
                return
                    portions.Count() == 1 ||
                    portions[0] == System.Environment.MachineName ||
                    HostIpAddresses().Any(a => a == portions[0]);
            }

            private IEnumerable<string> HostIpAddresses()
            {
                var adaptors = System.Net.NetworkInformation.NetworkInterface.GetAllNetworkInterfaces();
                return adaptors
                        .Where(a => a.OperationalStatus == System.Net.NetworkInformation.OperationalStatus.Up)
                        .SelectMany(a => a.GetIPProperties().UnicastAddresses)
                        .Where(a => a.Address.AddressFamily == System.Net.Sockets.AddressFamily.InterNetwork)
                        .Select(a => a.Address.ToString());
            }
        }
