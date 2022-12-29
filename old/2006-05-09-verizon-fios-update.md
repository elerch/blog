+++
title = "Verizon FIOS Update"
slug = "2006-05-09-verizon-fios-update"
published = 2006-05-09T16:24:00-07:00
author = "Emil"
tags = []
+++
Ugh...so some mixed results in the really high speed world. Got FIOS
installed cinco de Mayo and all was great - for a day and a half. On
Sunday we started having problems (no access at all), and to make things
worse, the phone number that was given on literally every page of our
welcome guide and used in the "Need Help? We're on call for you 24x7"
section of our welcome letter got us nowhere. We were both completely
unsuccessful finding the right path to get to 24x7 support, and a
complaint letter has been drafted.  
  
On Monday (afternoon) I got a chance to call during business hours and
got routed around. I now have the super-secret tech support number of
888-339-7333. I'm not sure how this relates, but there is another number
of 888-991-4999 that someone called "FIOS Service" (compare with "FIOS
Tech Support" for the other number). They fixed us at the time by doing
something on their end, which I now suspect was that they rebooted the
box on the outside of the house. I asked at the time, but the guy on the
phone didn't know - he was relaying between me and the network people.  
  
So, all was good...until this morning at 6AM when I had a meeting with
India. Using [Vonage](http://www.vonage.com), not having broadband is
like, really a downer, and I went back to my Comcast broadband for the
phone call (and for data while working this morning). This time, I had
download speeds of anywhere between 2-5Mbps, but almost no upload (about
60kbps). The speeds kept varying wildly, and over the course of the next
hour or so, they gradually got a little better. Latency was no problem
at all, but I was getting a lot of dropped packets as well. This was
really weird.  
  
I called Verizon about 8AM and they rebooted the box outside, and it was
better, but still not "right". It took about 40 minutes for me to
convince them that it was not a problem with my computer (they remote
connected to two of my machines and ran optimizers and stuff). In their
defense, everything they could see (which was to the box outside the
house) looked ok on their diagnostics. They finally decided it was weird
enough to send someone out. Oddly, as the morning drug on, my speeds
were still intermittent, but they were slowly getting better.  
  
The technicians (yeah, two of them - pretty cool) got here about 10:30
and they took a look at the box outside as well as one of my machines.
The one technician ran a ping test on the first hop router while the guy
at the box outside my house noticed that the wires in the RJ45 connector
didn't have a firm connection. Bingo - this explains the problems! In
cold weather (overnight, early in the morning) the metal wires
contracted, making the slighly unfirm connection really, really shaky,
to the point where it just wouldn't do anything anymore. Upload speed
was effected because it was one of the TX wires...pretty wild.  
  
So they fixed the connector problem, but the speed is still not quite
"right". They take a closer look at my setup, and they say, "who
installed this? The installer used internal wiring, which is Cat 3, not
Cat 5!". After wiring up a new (Cat 5) outlet the problem is now fixed
and I have some killer broadband.  
  
As a reward for any west coast people reading this far, the Verizon guys
on the way out the door mentioned to me that on the east coast, what I
pay ($44.95/mo) gets you 20Mbps/5Mbps (vs. my 15Mbps/2Mbps), and that
should be rolled out here as well at some point....
