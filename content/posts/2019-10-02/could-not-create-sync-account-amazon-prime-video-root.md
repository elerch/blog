---
title: "COULD_NOT_CREATE_SYNC_ACCOUNT Amazon Prime Video, and why root access is important"
date: 2019-07-30T16:16:48-07:00
draft: false
---

Early this year, an automatic upgrade to my Amazon Prime Video application
was installed. I was happily enjoying Mission Impossible, Season 1, downloaded
to the device for use on planes, but the next time I opened the application,
I was greeted with "COULD_NOT_CREATE_SYNC_ACCOUNT", and the Prime Video app
refused to load. Well, so be it...I moved on to other, likely more productive,
usage of my airplane time. However, this error message bugged me, and a 50-ish
minute show is pretty good for taxi+takeoff+climbout to 10k ft (also,
10k feet descend to final approach and landing). So, it stayed in the back of
my mind.

Fast forward a couple months later, maybe in the summer, and I contacted
Amazon Prime Video support. Amazon support is appropriately customer-obsessed,
and the engineer was relatively helpful, but clearly followed a script that
I've played through before. Of course, I got to the point of "reset your
Android device to factory settings", at which point I pulled my "no way" card.
Support did fall down somewhat at this point, where I was promised a follow-up
to my issue, but this did not occur.

A couple months later still, this problem still bothered me. For reasons, I
actually had access to the source code for the application (actually, library)
that produced this error message, but ultimately this wasn't important, other
than to point out the fact that I spent some crazy side time working out how
to build the application and all dependent libraries. It was a great learning
experience, but ultimately it wasn't the easy path here.

I started to consider what the error message was trying to tell ~me~ a developer,
and it dawned on me that they were talking about the Android accounts feature.
I looked at my phone, another Android device, and noticed that indeed, there
was an "Amazon Video Sync" account listed in the "Accounts" section of the
settings. I had never created this account manually, so the upgrade clearly
tried to install this account programmatically and had failed. Ok, now **that**
I can work with...

The account had no settings, but in my further research I found that this is
super-useful from Prime Video's perspective. Android handles all the ugly work
of connectivity and retries and exponential fallback with jitter, battery
saving, etc., and simply calls into the class when everything is good to go.
Then Amazon Prime can sync. It's totally cool here to download videos and
whatnot based on a sync provider. Android Prime Video is just trying to install
the sync provider, and cannot. It needs this, ostensibly to download videos,
but due to the failure, it cannot proceed and fails. All reasonable, my only
question being - should a missing sync provider really fail online viewing? It
seems this should be limited to download for offline videos.

ok, so the application can't install the sync provider. Let's dive in for why.
So, I first tried to install manually. This was interesting. The account
settings in Android simply hung when I tried to add the account manually.
Well, this is interesting...

## Root access required

A few [DuckDuckGo](https://duckduckgo.com) searches later, and I find that
deep in the depths of Android, two files control the sync providers shown
on the screen (and presumably in the APIs of Android). These are, at least on
my machine, though I think it varies by Android version:

* /data/system_de/0/accounts_ce.db
* /data/system/sync/accounts.xml

So...the two files worked together. Using [termux](https://termux.com/) with
the [sqlite3](https://sqlite.org/index.html)
package installed, I opened the database. This stuff is a good way to mess up
your system, so I'm not providing further instructions on how this is done.
A quick ``select * from accounts`` yielded 35 accounts, 34 of which were
affiliated with Amazon Prime Video, the "name" field varied between
'Amazon Video Sync *n*' and 'hollywood-sync-account_*n*', with the latter being
more recent, but also interchanged with a "AmazonSyncAccount-<guid>_*n*'. This
was clearly a result of my multiple attempts to fix the problem. I created
a backup of the database, ran a ``delete from accounts where _id > 1`` (your
id will **obviously** vary), and the table looked good. I double checked all
the other tables in that database, but nothing else looked out of line.

A reboot later and a running of Amazon Prime Video and...no love. Something so
obviously wrong had been fixed, but I still had the same error. I checked the
database, and sure enough, I had a new entry, but things were still off. So,
I deleted again, then checked the accounts.xml file. The last entry in the
XML was an account named "Amazon Video Sync", so I deleted that file in
**addition** to the relevant accounts table in accounts_ce.db. I rebooted,
and tried Amazon Prime Video. Voila, everything worked.

## Morals of the story

There are several morals that I'll explicitly mention here:

1. Something in the fall of 2018 or spring of 2019 changed in Amazon Prime
   Video Android app changed (probably the name of the sync provider) that
   threw things out of whack in the Android sync provider configuration that
   neither the UI nor the APIs were ready for.
2. "Factory Reset" is a really poor answer to an issue like "I can't open
   my app anymore".
3. Root access is important. I understand the customer service anti-pattern
   here, but honestly, they're our devices. Provide a "this will void your
   warranty" or whatever, but fixing this issue required either factory
   reset or root access to fix. It's much better to let technically savvy
   users fix their problems. [LineageOS](https://www.lineageos.org/) gets this right.
4. The Unix philosopy rules. Text files, or even sql lite databases to control
   the system makes it easy to safe-heal. Don't hide everything behind APIs
   on a local system.
5. Clear error messages allow self-maintenance. Even to me, an experienced dev,
   albeit without a lot of Android app experience, did not recognize this error
   for a while. In retrospect I feel I should have figured this out earlier,
   but consider the use case. I have multiple "downloaded video watching"
   options between [Netflix](https://www.netflix.com/),
   [Plex](https://www.plex.tv/), and [Google Play](https://play.google.com/store/movies),
   so this was bothersome but not a high priority for me. I fixed this on
   my birthday as I had blocked a good portion of my birthday to focus on
   low priority nagging technical issues...
