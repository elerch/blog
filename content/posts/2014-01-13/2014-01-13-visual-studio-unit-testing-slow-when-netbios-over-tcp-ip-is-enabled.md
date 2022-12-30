+++
title = "Visual Studio unit testing slow when NetBIOS over TCP/IP is enabled"
slug = "2014-01-13-visual-studio-unit-testing-slow-when-netbios-over-tcp-ip-is-enabled"
published = 2014-01-13T19:01:00.003000-08:00
author = "Emil Lerch"
tags = []
+++
[According to MS
Connect](http://connect.microsoft.com/VisualStudio/feedback/details/768230/slow-running-in-test-runner),
this doesn't happen. People have reported it, however, in VS 2010, 2012,
and I've experienced the problems in VS 2013. It's also listed at this
StackOverflow
question: <http://connect.microsoft.com/VisualStudio/feedback/details/768230/slow-running-in-test-runner>  
  
I've now added this handy PowerShell command to my "initialize a new
machine" setup PowerShell script:  
  
<span style="font-family: Courier New, Courier, monospace;">\# Disable
NetBios over TCP/IP on all interfaces</span>  
<span style="font-family: Courier New, Courier, monospace;">\# to
prevent weird Visual Studio slowdowns during unit tests</span>  
<span
style="font-family: Courier New, Courier, monospace;">Get-ChildItem
hklm:system/currentcontrolset/services/netbt/parameters/interfaces
| foreach{ $item = $\_; Set-ItemProperty -Path
($item.ToString().Replace("HKEY\_LOCAL\_MACHINE", "hklm:")) -Name
NetbiosOptions -Type DWord -Value 2 -ea "SilentlyContinue" } </span>
