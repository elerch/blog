+++
title = "Home network"
slug = "2007-06-15-home-network"
published = 2007-06-15T13:37:00-07:00
author = "Emil"
tags = []
+++
In addition to all the [recent house
changes](http://emilsblog.lerch.org/2007/06/aaaahhhhh.html), I've been
reconfiguring the home network to improve a couple things, and it's been
quite the saga. Here's what I wanted to fix:  

1.  Move off of [WEP](http://en.wikipedia.org/wiki/WEP) security in
    favor of [WPA2](http://en.wikipedia.org/wiki/WPA2). This is not just
    for better security, but because, at least for [my
    router](http://www.dlink.com/products/?pid=530), you cannot use WEP
    if you want to support
    [802.11n](http://en.wikipedia.org/wiki/802.11) clients. I don't have
    any yet, but don't want to be prevented from the faster speeds,
    either.
2.  Provide wireless coverage in the kitchen nook. This is the only area
    of the house I ever have problems with, and while I don't sit there
    and use a computer, anyone we have over tends to do just that.
3.  Provide a stronger wireless connection for the
    [TiVo](http://www.tivo.com/), which would stop the problem of my
    mp3's pausing during playback and really, really slow transfers of
    shows from computer to TiVo.
4.  Spend no money  

One slight problem with \#4 is that the [wireless adapter I
use](http://www.amazon.com/D-Link-DWL-122-802-11b-Mbps-Adapter/dp/B0000A55BE)
is not the official [Tivo Wireless
Adapter](http://www.amazon.com/TiVo-Wireless-Network-Adapter-AG0100/dp/B000ER5G6C)
(which didn't exist a couple years ago). TiVo [doesn't support WPA in
adapters other than their official
one](http://www.engadget.com/2006/11/06/tivo-raises-rates-limits-wpa-to-own-wifi-adaptor/),
so it created a problem.  
  
Well, I had gotten an offer from [Fon](http://www.fon.com/) to "upgrade"
my Fon router to a [La
Fonera](https://shop.fon.com/FonShop/shop/US/ShopController?view=product&product=PRD-001)
for free. I originally signed up in order to get the very nice [Linksys
WRT54GL](http://en.wikipedia.org/wiki/WRT54G), and was thinking about
repurposing it once fulling my obligation was over, so this was an
opportunity to repurpose the Linksys early.  
  
Unfortunately, what I needed from the Linksys was to create a wireless
to wireless bridge. This would connect to the 802.11n/g/b network with
WPA2 as a client (direct wired not an option if I were going to solve
problems 2 and 3). It would also work as an AP broadcasting on 802.11g/b
with WEP to let the TiVo work. I took a look at a [wireless distribution
system](http://en.wikipedia.org/wiki/Wireless_Distribution_System) to do
this, but all settings must be shared, and I needed to have different
security.  
  
[DD-WRT](http://dd-wrt.com/) did not allow this setup, but I was pointed
out to a [beta version of
v24](http://dd-wrt.com/dd-wrtv2/down.php?path=downloads%2Fbeta%2FGENERIC%20BROADCOM%20%28Linksys%2CAsus%20etc.%29%2Fdd-wrt.v24%20beta%2F2007%20-%200516%2F&download=dd-wrt.v24_vpn_wrt54g.bin)
that has this bridging feature, which they call the [Universal Wireless
Repeater](http://www.dd-wrt.com/wiki/index.php/Universal_Wireless_Repeater).
The beta version worked, but in order to get traffic from my main router
to route to the Linksys, I needed a [static
route](http://en.wikipedia.org/wiki/Static_routing) to be configured.
This [feature only became
available](ftp://ftp.dlink.com/Gateway/dir655/Firmware/dir655_releasenotes_103.txt)
for my DLink router a few weeks before, so I [went through the
upgrade](http://support.dlink.com/products/view.asp?productid=DIR%2D655)
and I was finally all set up.  
  
In testing, I found one more problem. The protocol TiVo uses for
transfer of TV shows (but not anything else) [requires the TiVo to be on
the same subnet as the
server](http://galleon.tv/component/option,com_joomlaboard/Itemid,26/func,view/catid,30/id,407/).
Bummer. Everything else works great, and at this point I'm resigned to a
second transfer (server-&gt;Laptop-&gt;TiVo) to accomplish that.  
  
As an aside, although I love my TiVo, unless something changes, I'll be
forced to move on at some point, based partly on issues like this, and
partly on the lack of HD support without shelling out a ton of money on
a series 3 and paying a monthly subscription fee (I have a lifetime
subscription). While I think that [Media
Center](http://www.microsoft.com/windows/products/windowsvista/features/details/mediacenter.mspx)
is complex, expensive, and unstable for consumers, it's likely HD
support will be cheaper unless TiVo lowers prices, and I'm sure things
will get more stable in Media Center world as we move forward.  
  
Yikes...long post. Anyway, here's a picture of where I ended up.  
  
[![](../images/thumbnails/2007-06-15-home-network-Home+Network.jpg)](../images/2007-06-15-home-network-Home+Network.jpg)
