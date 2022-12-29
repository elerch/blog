+++
title = "Installing Cyanogenmod 7.2 on Verizon Droid 2 Running 2.3.4"
slug = "2012-12-14-installing-cyanogenmod-7-2-on-verizon-droid-2-running-2-3-4"
published = 2012-12-14T10:48:00.002000-08:00
author = "Emil Lerch"
tags = []
+++
[They said it couldn't be
done](http://wiki.cyanogenmod.org/wiki/Motorola_Droid_2:_Full_Update_Guide).
 If you install 2.3.4 OTA update from Verizon, you were stuck with a
version that was un-rootable.  And rooting is the first step in getting
a custom Android build on a phone.  Specifically:  

> There is currently (as of May 2012) no way to root a Droid 2 with this
> system version.

As a word of warning, the procedures for getting Cyanodenmod are as
scary as the link above, and with 2.3.4, you're really in the deep end.
 Here's a summary of what I did.  I'm not providing step-by-step
directions for two reasons; first, if you can't get there from the
summary, you're probably in over your head and you have a good chance of
bricking your phone.  Secondly, I am providing links to my source
materials with more details.  I'm also taking you through the method I
went, which generally used tools rather than adb commands/doing it by
hand.  I purchased two of the tools...I think the $8 I spent was worth
it, but go read the wiki if you want to do it the hard way.  

### Rooting

The rooting procedures on the Cyanogenmod wiki don't work, obviously.
 What you need to do is download this
iso: <http://www.mediafire.com/?mim304k214kl41h>.  MD5
is 7baee9c34f6ef7ad0b4fa219ae387c68.  The forum post regarding this is
here: <http://androidforums.com/droid-x-all-things-root/603489-how-root-2-3-4-4-5-621-magic-md5-does-not-require-milestone-sbf.html>.

  

The ISO can be burned to a bootable CD or USB (using
[Unetbutin](http://unetbootin.sourceforge.net/unetbootin-windows-latest.exe)).
 I went the USB route.  Once booting off the USB, the scripts on the ISO
walk you through what needs to be done.  This was by far the easiest
part of the install.

### Custom Recovery ROM and Bootloader

Not having gone down these paths before, I didn't have a conceptual
understanding of how Android boot works.  That turns out to be pretty
important at this point, and it tripped me up for a bit.

1.  Bootloader is run, presumably by the hardware
2.  Bootloader looks around, checks out everything, and loads the ROM
    image.  Depending on the environment it can run the recovery ROM or
    the normal boot ROM (your phone).

So, now that the phone is rooted, we need a custom bootloader because
the Android one will verify that it's the Verizon image, and we don't
want that.  We need a custom recovery ROM as well...one that will let us
flash new Android versions.  So, the next step is to install the Droid 2
Recovery Bootstrap by
ClockworkMod: <http://market.android.com/details?id=com.koushikdutta.droid2.bootstrap>.
 Also install the ROM
Manager: <https://play.google.com/store/apps/details?id=com.koushikdutta.rommanager.license&feature=more_from_developer#?t=W251bGwsMSwxLDEwMiwiY29tLmtvdXNoaWtkdXR0YS5yb21tYW5hZ2VyLmxpY2Vuc2UiXQ..>

  

Use the ROM Manager to Flash ClockworkMod Recovery.  Once that's done,
install the Recovery Bootstrap (remember, we need the Bootstrap to let
us get into our shiny new Recovery).  I missed this part and I kept
going into the Android recovery...it was very confusing.

### Prepping and Hacking the Cyanogen install

Download:

1.  Cyanogen latest
    version: <http://wiki.cyanogenmod.org/wiki/Devices_Overview#Motorola_Droid_2>.
     Right now, this is 7.2.0, available
    at: <http://get.cm/get/jenkins/2824/cm-7.2.0-droid2.zip>
2.  Google apps (gets you the
    market): <http://goo-inside.me/gapps/gapps-gb-20110828-signed.zip>.
     That is the mirror link as the primary didn't work for me.  The
    cyanogenmod page on this is
    at: <http://wiki.cyanogenmod.org/wiki/Latest_Version#Google_Apps>

Copy the Google apps zip file to the SD card.  I don't know if this
needs to be in the root directory, but Cyanogen instructions mention
putting it into root.  It's certainly easier, anyway.

  

**Don't copy the Cyanogen zip file to the SD card yet.  **Our last step
in this path is that there is a safety check in the install to verify
the kernel version so it doesn't accidentally brick your phone.  With
2.3.4 we're safe, but Cyanogen doesn't know this.  So, you need to unzip
the Cyanogen zip file above, and alter the /system/etc/check\_kernel
script (with a decent text editor - not notepad).  Wipe out everything
except the first line.  Then the second line should be simply "exit 0".
 More details are
here: <http://forum.cyanogenmod.org/topic/50469-installing-cm-from-234/#entry335479>

  

Zip the file with the changed script and put it on your SD card from the
phone.  

### Installing Cyanogen

Reboot the phone into ClockworkMod recovery by first powering down.
 Then hold power and the X key on the keyboard until it comes up.
 You'll see ClockworkMod come up (maybe).  I remember having an issue
where nothing seems to happen.  If you have that problem, hit both
volume keys at the same time (if that fails, just play around with
volume a bit).  You'll then see shiny new text from ClockworkMod
recovery, and maybe even an error message.  

  

At this point, it took me a while to figure out, and the ROM manager was
useless for me.  The directions and forums don't know a whole lot about
that error message.  You're **supposed** to be able to use up/down
volume to arrow around the options, and power selects the option you
want.  However, power just made the phone go blank for me.  I
**think** what's happening is that the droid 2 does not have /dev/tty0
and there is a bug in the recovery ROM where the power button selects
/dev/tty0 as the device when pressed.  However, there is another way to
navigate...

  

What I **finally figured out** is that navigation can operate with the
keyboard.  Slide it open, and left = up, right = down (which makes sense
since you have the phone in portrait mode.  Up = right, Enter = enter,
and Del = back.  This knows where the screen is, and I'm sure it's much
more pleasant than trying to navigate around selecting files with volume
keys/power.

  

With that working, you can perform the following steps:

1.  Back up your existing ROM
2.  Select and install the Cyanogen ROM
3.  Select and install the Google Apps ROM (I think this just unpacks
    apks and puts them in a special directory, but I'm not sure).  I
    thought it was way weird I was installing two ROMs.
4.  Lastly, wipe all cache/data.  I don't remember if I performed
    factory reset - I think I did **not**.  Apparently the phone will
    get into a "boot loop" unless this step is performed, but if you
    forget for some reason, you can get out of that
    problem: <http://forum.xda-developers.com/showthread.php?t=1832130>

Congrats, Cyanogen is installed!  It's like a brand new phone, so you'll
have to sign in, install apps, yada yada.

### Other thoughts

I noticed the Alt Lock button does not work after I installed.
 Apparently this is a special Motorola hardware key and cannot be used
by Cyanogen.  However, pressing Alt twice will do the same thing...I'm
sure that's a default Android behavior I had no idea about.  I am also
missing the Motorola calendar widget terribly, but I'm sure I'll find a
suitable replacement.  Cyanogen is so much better/faster.  They really
had me at "Add Access Point" in the wireless settings. ;-)  
  

#### Update

I noticed that my WiFi does not seem to connect. It connects but the
advanced settings says IP address unavailable. I tried a custom kernel
but to no avail. It appears to be a dhcp problem only, and I think it is
a problem with cm 7.2. I have worked around the problem by using a
static IP address and DNS server, but the static DNS settings in the
settings don't seem to work. Instead I installed [Set
DNS](http://www.google.com/url?sa=t&rct=j&q=set%20dns%20android&source=web&cd=1&cad=rja&ved=0CDIQFjAA&url=https%3A%2F%2Fplay.google.com%2Fstore%2Fapps%2Fdetails%3Fid%3Duk.co.mytechie.setDNS%26hl%3Den&ei=o8rgULfkEIyyqAHRvoDgAg&usg=AFQjCNH1ntGZvyswfVMGi7p1o2f_NMzBYg&sig2=v3R48xbCfBSQRE7lheDDuw&bvm=bv.1355534169,d.aWM) and
that works properly. For WiFi hotspot support I installed [Barnacle WiFi
tether](http://www.google.com/url?sa=t&rct=j&q=barnacle%20wifi%20tether&source=web&cd=1&cad=rja&ved=0CDIQFjAA&url=https%3A%2F%2Fplay.google.com%2Fstore%2Fapps%2Fdetails%3Fid%3Dnet.szym.barnacle%26hl%3Den&ei=W8vgULidF8uLrQG2moDgDw&usg=AFQjCNEp_MFCsxl_uO7sdCVHLVCrsQXnxA&sig2=OUj3wib0TEHOEH-BHfaSgw&bvm=bv.1355534169,d.aWM),
but I haven't had a chance to play with it too much.
