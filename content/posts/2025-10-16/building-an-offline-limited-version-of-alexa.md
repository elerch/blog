---
title: "Building an offline, limited version of Alexa"
date: 2025-10-16T12:50:20-07:00
draft: false
---

Building an offline, limited version of Alexa
=============================================

(or how Belkin and Alexa conspired to nerd snipe me)
----------------------------------------------------

It all started when Belkin decided to [end wemo support](https://www.belkin.com/support-article/?articleNum=335419).
I am leery of things that require cloud support, whether they are [games](https://www.xda-developers.com/playable-canceled-games-that-leaked-online/),
or [devices](https://support.google.com/googlenest/answer/16233096?hl=en). I get that
business changes and these require ongoing investment from the company's perspective,
but my interests are unique and different from company interests, and I'm not into
obsolescence, especially of physical devices, that work just fine.

There is a disturbing trend of requiring more and more Internet access for things
that really don't need to, and I actively push against this in most cases. There
is no reason that I should need my Internet connection to be up and operable to
turn on/off my lights! The original Belkin Wemo was exciting, because it could
operate locally and [Amazon Alexa](https://www.amazon.com/b?node=21576558011),
though it is cloud-based, will connect to these devices without round tripping
to the cloud. If my Internet connection goes out, I still have a physical light
switch, and I could even use my phone with [Home Assistant](https://www.home-assistant.io/).
Under normal operation, I don't want Home Assistant in the mix, because it's
another point of failure, and the Home Assistant/Alexa integration utilizes
Home Assistant cloud, so now I need an Internet connection and 2 online services
to be operable...for my lights?!

Anyway, for a long time I was in a pretty happy state. I had local control of
many lights in my house, Alexa could control them, home assistant could monitor
and control them, and all was good. My main problem was getting new Wemo devices,
because the later generations of Wemo dropped the local support altogether, and
at least once I ended up paying 3x the price of the Internet-only device to get
an older device shipped to me. Later, I discovered [Tasmota](https://github.com/arendst/Tasmota),
which can pretend it is a Belkin Wemo device, and [CloudFree](https://cloudfree.shop/),
an online shop that ships pre-configured Tasmota-based devices, and about
half my light switches (and holiday light setups) use devices from them.

Conspiracy Theories Start Here!
-------------------------------

With this background, the news of Belkin's removal of Wemo support drops, and...
nothing changes. I have devices that work, I don't need the cloud, and unless
Amazon actively moves to remove the local Wemo control (possible, but unlikely),
my life literally does not change. Except...within two weeks of that announcement,
I have not one, but *two* Belkin Wemo light switches fail. Coincidence? I think
not! (just kidding, I'm sure it's a coincidence...but wow is that timing suspicious).

Time to migrate
---------------

So...I have two switches to replace. I happily go to CloudFree (actually...I
got replacements from Amazon). I did some research and apparently products from
Martin Gerry have Tasmota pre-flashed, so I got [two of them](https://www.amazon.com/dp/B0DP6NRLB8).
Mostly this had to do with...well, I didn't have a working light switch, so
I wanted it kind of...now.

I installed the light switches, gave them the same name, enabled MQTT (zero-configuration
for Home Assistant), Belkin Wemo support, and was up and running. With everything
except Alexa. Alexa saw the devices but considered them offline.

Investigations
--------------

Home assistant was fine. Operating the light switch was fine. Alexa saw them...fine.
But absolutely, and still to this day, refuse to operate them. After an inordinate
amount of time, I've learned why. While the IP address was the same, the name
was the same, everything was the same, there was one difference. In newer
Tasmota firmware, the Belkin support is on the same port as the web interface.
And Alexa stubbornly only likes to connect on (its original port? or does it have
to be 49152-49154?). So, either I move the literal switch web interface to that
port, or Alexa will refuse to operate it. At this point, I'm fully in both nerd-snipe
and stubborn mode, and I'll be damned that Alexa will tell me what I can or should
do with my devices.

A bit of technical background here...Alexa has always been a bit finicky with home
devices. When you ask Alexa to discover devices, it sends out a broadcast message
for UPnP discovery and listens for responses. In those responses, the Wemos provide
an XML response with a lot of details, including the URL with the port they
operate on. Because this is a broadcast message, with a larger wifi network and
a lot of devices, not all the device data is returned all the time, and that's...
a bit of a mess for Alexa. However, as far as I can tell, either Alexa a) ignores
at least the port portion of the url returned, or b) forever remembers the port
in your account settings somewhere, even after deleting the device and re-adding
it. Neither of which are ok to me.

Having some time, I decided to solve the problem with the nuclear option...

Replacing Alexa for device control
----------------------------------

This was a good personal/work project, as I am always looking for projects to
exercise generative AI for software development to help keep grounded in truth
on the state of the art, since I advise a lot people on this topic.

So, I pulled out my [coding assistant du jour](https://kiro.dev), and I worked
with the agent to create a specification. I planned to handle this in 2 parts:

* Develop a speech to text service that would listen to the microphone and
  get words
* Create a program to interpret the words, and when a device command was
  provided, well, it would command the device

I don't know anything about either audio processing, speech to text, or natural
language processing for parts of speech, but luckily I had the help of
various libraries and the collective knowledge of humankind wrapped in an LLM.

Step 1: Speech to Text
----------------------

Most modern suggestions will suggest the use of [Whisper](https://openai.com/index/whisper/)
for speech to text, but my needs are simple, English only common words, and as
such does not require that much complexity (or computing power). But speech
to text is a problem that's been worked on and solutions existed as far back
as [1997](https://en.wikipedia.org/wiki/Dragon_NaturallySpeaking) and probably
earlier. Ultimately, I found [Vosk](https://alphacephei.com/vosk/), which has
several models suitable for English, and used the 40M small model. Because I
like [Zig](https://ziglang.org), I instructed the agent to use that programming
language and pull in the necessary libraries, which included ALSA and Vosk.

Any time I run into incorporation of shared libraries, I struggle using AI
assistance, and this experience was similar. Ultimately I was able to convince
the AI to create a [zig build of alsa-lib](https://git.lerch.org/lobo/aycb-alsa-lib),
but ultimately failed to do something similar for Vosk, so ended up depending
on the pre-built binaries, both with Kiro and with the Amazon Q Developer CLI,
which at the time was using Claude Sonnet 4. Since then Sonnet 4.5 has come
out, and is a significant step up, but I'm still pessimistic. The Vosk build
is somewhat daunting with many dependencies, most of which are pinned versions
of forks of other libraries, and natively uses CMake.

I spent a fair amount of time cleaning up, but the AI definitely helped out
before I understood audio processing (I have learned a lot but am still a bit
shaky on the topic). At the end of the day, my biggest disappointment is
that I could not optimize this to work on the Raspberry Pi 3B+. I'm confident
a Pi 4 would work, but I only had a compute module on hand, and the microphone
wouldn't work with it due to USB support issues (and I have a weird carrier board).

Because of this I was faced with purchasing a Raspberry Pi, but ultimately
[this fanless N150](https://www.amazon.com/dp/B0F1CL4LTW) is about the same
cost, maybe slightly more, after fully kitting out the Pi. I suspect CPU
performance is only slightly more (well done, Pi!), but the I/O performance
will be significantly higher on the N150. At the end of the day, this part of
the process consumes 2-5% CPU and about 450MB RSS, so a Pi 4 should be
perfectly fine keeping up. The code lives here, and the program simply executes
a child process to hand off the text, so it's pretty modular:
https://git.lerch.org/lobo/stt. I'll also note that there are non-English
models for Vosk, so while it is not completely generic, it is far more useful
than my own "English only" requirement. The code is ok...I did a fair amount of
cleanup work from the AI, but then used AI again later in various forms, which
added functionality and some more stuff to clean up. In general, my pattern for
these things is to progressively take on more and more of the coding from the
AI. Here, that happened, but I let AI take on some larger tasks toward the end
as I learned more about audio processing through the issues I had with the Pi
3.

Step 2: Understanding the text
------------------------------

Step 1 might have had its complexities, but understanding the text is quite a bit
more complicated. Parsing the sentence was not actually the difficulty here, the
problem turned out to be learning through experience how words would be misheard
by the Vosk recognizer. A phrase like "turn off the bedroom like" doesn't make
any sense and will parse, but parse badly. So you need to look for these common
incorrect words and replace them, which itself can be a bit tricky. The amount
of tuning for both the replacement algorithm and the words themselves took maybe
15% of the overall project.

Again, AI helped with a lot of the stuff I didn't want to do. Zig's current
TLS implementation is not yet complete, for instance, so I needed:

* A custom download step using curl
* A custom program to tweak some of the downloaded code
* Get all this integrated into the zig build (build.zig)

At AWS we throw around the phrase "undifferentiated heavy lifting" a lot. The
download step is purely throw away code (once zig TLS is complete), and only
exercised during a build. It's necessary, but my idea of a quality bar on this
particular code is pretty much in the "does it work consistently? yeah? Then I
couldn't care less what it looks like" space. I ended up needing this on both
of these projects so I did clean it up a little bit, but otherwise, I just
let the AI "make it work". The "sed lite" that I had the AI write was kind of
the same idea. It was a one-off as I'd like to pretend this might actually build
on a Windows host (which has "curl" available enough to do the download), but
Windows to my knowledge does not have any kind of sed, real or pretend.

[Link](https://www.link.cs.cmu.edu/) was my answer to sentence "part of speech"
processing, and the code was very...researchy, but it worked, and it was damn
easy to compile. Nothing like a `Makefile` that compiles a bunch of c files to
objects, then link the objects into a library to make your day. Understanding
the data structures and nomenclature they use...that was a different matter, and
we were in way to niche of a space for the AI to help. But it was able to whip
up a [console-based sentence parsing diagram](https://git.lerch.org/lobo/pos/src/commit/5a38fd65c70e0c022324b6e1d8c4dbd26f48bce2/src/root.zig#L80-L216)
on the first try, which helped the debugging process a ton. Again, this was
just for debugging...so pretty much "does it work?" was my quality bar. It's a
big chunk of code I've not really looked at. On the other hand, I completely
wrote the word removal/replacement function as I experimented with different
versions of the phrases I'd like it to process. AFTER writing it, the AI got
hold of it, refactored it to my direction, and I used a copious amount of
`git add` to provide myself checkpoints if it trashed the code.

AI also did a pretty good job with sending of the commands to the Wemo device,
and I love AI for "here's some random protocol I may (or may not) know, but I
know you do. Just go write a function to use that protocol". My experience is
that it usually gets it right, or really close, on the first try. And since
this didn't need to be hooked up to a live microphone, it was pretty easy to
add a bunch of unit tests for various scenarios. Zig's `builtin.is_test` even
let me test that commands would be sent properly without actually sending
commands out on the network. Interestingly, AI was unable to reason through
that particular piece, but was able to run with the idea once I coded it.

Shipping
--------

The process for getting this out the door was pretty mundane. Compile the code
for a baseline x86 cpu in release mode, copy both the speech to text and parts
of speech (pos) binaries out, create a service user on the device and a systemd
unit. Nothing fancy. I purchased a cheap USB microphone and tested it, learning
a lot more about audio processing in the meantime (e.g. some mics report 1
channel, some report 2, and they have specific frequencies they can work at, so
you might need to down sample). I did a fair amount of tuning while my wife was
on a business trip, because this needs to be fairly reliable before she starts
using it. There were some problematic deadlocks, failure handling, etc, but one
major change I did was to switch from continuous speech detection to only
process audio once noise is detected. This was a major learning for me (audio
processing noob), and something that came up in an AI chat. It was nice to have
AI make this kind of major change to the codebase, and it continues to be a
pleasant AI experience. Often, significant refactorings...well, the effort
doesn't seem worth it, or we're too lazy or busy with other things, but I've
found it's much more likely for me to be willing to move, rename, and redesign
(beyond what refactoring tools can do) a load bearing central component of code
with 1000 references if I can tell AI to go do it while I work on something
else, knowing it won't stop until the build (and its tests) successfully
complete. I'm in cleanup mode for sure, but it will have done 90% of that work
for me. Ultimately, a week or so in, I was left with a couple things:

* Continued need for tuning all the ways it can mis-hear speech (this might
  be where Whisper does better?)
* I think there's a slow memory leak, which I ignored in favor of letting
  systemd just restart once/day

I haven't touched the thing in 3 months...it just...works. It's not generic
like Alexa, and the speech still isn't quite as robust, but it works!
