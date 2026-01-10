---
title: "wttr.in"
date: 2026-01-09T14:43:51-08:00
draft: false
---

wttr.in
=======

This is another heavy AI-assisted coding post...sorry about that. But, while
AI is featured in the story, it's not the point of the story. For a long time,
I have been a fan of [wttr.in](https://github.com/chubin/wttr.in). I'm posting
the github link here instead of the production site, mostly because it takes
5-10 seconds for me recently (I don't remember this before?). The concept is
really cool (who doesn't like weather you can use from your terminal). I cloned
it with the intention of self-hosting it, and...learned a lot.

Installing
----------

So, the intro of the readme says in part:

> Originally started as a small project, a wrapper for wego, intended to demonstrate the power of the console-oriented services

That shows. Here's the (AI-generated) request flow from wttr.in. It actually get's a bit more involved than even this:

```
Client Request
    ↓
Go Proxy (port 8082) - LRU cache + prefetch
    ↓ (cache miss)
Python Backend (port 8002) - Flask/gevent
    ↓
Location Resolution (GeoIP/IP2Location/IPInfo)
    ↓
Weather API (met.no or WorldWeatherOnline)
    ↓
Format & Render (ANSI/HTML/PNG/JSON/Prometheus)
    ↓
Response (cached with TTL 1000-2000s)
```

So, we have a go program, with it's own cache. Then a python backend, which, if
memory serves, also has a cache. However, depending on the format you're
looking for, it's either a) rendering itself, or b) kind of sort of skips all
this and just calls a fork of "wego", which, as mentioned in the readme, this
was originally the plan as a wrapper. All that other stuff kind of organically
grew over time. Self hosting ultimately wasn't terrible, but it wasn't pleasant
either. Several API keys, and paid services, etc. Also, two separate sets of
caching layers, each in their own directory, made creating a dockerfile...well,
weird.

A hard blocker
--------------

Once installed, I ran into a firm block for me. The default (only at the time I
think?) service was a paid weather service. That makes no sense for me as a
single user. So, I put my ~money~ time where my mouth is, and
[picked up the pen](https://github.com/chubin/wttr.in/pull/532) to implement
met.no as a weather source. They don't even require an API key, just "be nice",
which is awesome. I didn't realize about this wego thing, so while met.no worked
fine for my purposes, the full rendering was always different from the custom
rendering that I was using, and I never really bothered to track it down. In the
last 3 weeks, I've learned that's because wego is a very different pipeline,
and uses its own web service configuration!

5 years go by
-------------

This has all been bugging me for...well, 5 years. On my long term todo list
was to help clean this organically grown architecture and simplify it, make
it self-hosted friendly, etc. So I find myself with some spare time over Christmas
break, and I have a codebase and an AI to help do a lot of typing. So I ask the
AI to build a plan based on a new, simplified architecture, and we work together
to come up suitable. It's original estimate was 10 weeks for a full rewrite.
I have a few missing features (i18n, PNG support, Moon endpoint...but moon phase
*is* supported, and wttr.in compatible json, as my json is a met.no passthrough).

Starting out
------------

I asked the AI for a plan. I wanted this built in zig (of course). I wanted a
vastly simplified architecture. At the end of the day, a single caching layer
(vs Go+python each with their own) in a single directory. Everything will be
self-contained, with the goal as a single static binary. Spoiler: I've achieved
this, even with the first pass of png support. I wanted a coherent organized
code base (still some rough edges there imo), and critically, I wanted unit
tests everywhere. The AI made up a goal of 80% test coverage, and my coverage
report currently says I'm at 85%. I had it document the current architecture
and the target architecture, so I could argue and eventually just edit the
target architecture for future use. Then, I let it rip.

First pass (6hrs)
-----------------

I got something functional, but there was a lot of cleanup to be done. In 6 hours
of work, mostly me arguing with the AI, I had a full working (but admittedly
buggy, and with structural deficiencies) implementation of most of the main
features. This was literally "close enough for government work", that I felt
able to delete all the python/go in the directory to focus on the zig
implementation. Any other discrepancies, I'd compare to the live https://wttr.in/
site or pull up the github repository. And I have to say, the live site...I'm
not sure if it's a result of the architecture, zig, or simply that I'm only
serving 1 req/sec, but the performance difference between this code and the
live site really made me reluctant to check out the live site unless absolutely
necessary.

Refining (15hrs)
----------------

My process for AI use on greenfield is often like this. Spend 5-10 minutes
getting the AI and I on the same page for what needs to be done. Then let it
write whatever it wants, just make it work. Then start in on the more detailed
work, where I still use AI (more later), but I start getting a lot more hands-on.
Typically, I think of this the same way I imagine a carpenter would. Chainsaws,
then more specific tools, followed by sanding, staining, etc. This initial
pass at this was about 15 hours. Life then intervened, and I took a 2 week
break.

Finishing up (1 week)
---------------------

After the break, I spent a few hours every day for about a week, and wrapped
it up. At this point, AI was still heavily assisting me, but I was no longer
checking in any code that I didn't code review and hand-edit to something I would
have authored directly. I literally said to myself on more than one occasion,
"this works, but it doesn't look like code *I* would write", and I'd change
it. Sometimes I'd get into heated arguments with the AI, to the point where
once my wife came downstairs and asked why I was typing SO DAMN LOUDLY. I had to
tell her that was me yelling at the AI.

**Things that were super helpful:**

* Large refactorings: Once all the unit tests were in, the AI could cut through
  these like butter, but I did have to make sure it was very clear when it could
  and could not adjust test expectations. An easy way to get tests to pass is
  to just adjust the expectations!
* Suggestions on where to start: I don't know anything about calculating moon
  phases or dawn/dusk/sunrise/sunset. The AI gave me a good overview, then
  pointed me to C code in both cases. And it was able to quickly integrate them
  into the project for me.
* Giving me multiple suggestions. Not sure of a design approach, or a name? Ask
  the AI for 3. Ask it to explain the tradeoffs of each, and what its suggestion
  is. I took the suggestion only maybe half the time, but the process helped me
  think through everything.
* Doing a lot of work quickly. Even if I know it's going to be terrible, I'd
  rather have it write 20 unit tests, and then go fix the `std.testing.expect(response != null)`
  than to have to write all the boilerplate and setup stuff 20 times myself.
  Keep in mind here, that part of writing the tests might be (sometimes large)
  refactoring to components to allow for things like test mocks, or to separate
  things doing IO from pure functions. I knew that whenever the AI finished,
  the build and the tests would succeed, and I would just play quality control.

**Where I struggled:**

* Visual stuff: It was easy to get it to get something visible, but getting it
  *right* was a whole different matter. I had a day-long argument about whether
  monospaced ascii was aligned when it include the lighting bolt (⚡) character.
  Even when I provided the string in a test expectations, it just refused.
  Eventually, I got it to tell me why, and it's not for the reason you might
  expect (multi-byte unicode characters). No, it boiled down to "crappy terminals
  don't know how to display this character, so it should take up two cells.
  Therefore, the right thing to do is to remove a padding space". ok, wow...
  so after telling it that I don't care about buggy terminals, that's on them,
  it was able to align things correctly. Once all the proper mocking code was
  in place and I had (hand coded) the proper unit tests, this problem went
  away.
* Adding new zig dependencies: This is a nit, but it consistently screws up
  a simple `zig fetch --save`. After this bit me twice (noticed it in CI), I
  learned I could do the command myself much more quickly than having it botched
  and either not catching it or having to argue about it.
* Style: The AI really wanted to make subdirectories. It really liked to do
  things like have a `geoip.zig` file with a `GeoIp` struct inside it (the
  zig way is to call it `GeoIp.zig`, and the file *becomes* the struct, but the
  AI struggles with that concept. The AI really wants to put braces around
  everything.
* Code duplication: I'm not a hard core DRY person, but the AI thinks nothing
  of writing the same code 15 times in 15 different places. This can introduce
  a lot of specific bugs and sometimes lead to dead code. I'm still thinking
  of the three different caches in the system, which each have their own
  implementation, and wondering if it's appropriate. I think it is, as each
  have unique aspects to the data, but I'm not 100%.
* Terrible test expectations: This was just consistently terrible, and eventually
  *my* expectations were that for unit tests I would just need the AI to blast
  out some stuff, then I would do the final work on asserting the right 
  expectations myself.
* Ignoring instructions: Sometimes the AI would simply ignore me, or not do
  the research (file reading) I would have expected it to. This was the most
  frustrating thing, and I think it boils down to "my context was getting too
  long". I learned to restart my session, and keep sessions focused on one task.
  If I asked it to refactor something, add in two different pieces of new
  functionality, I would be in for trouble.
* Systems work: This was a user-facing application, and there is a lot of prior
  art for application-level stuff, so I had a pretty good experience. But
  whenever I use AI for systems level things (e.g. unikernels), it goes bad
  in a hurry. I don't even try much there.

Conclusions and future work
---------------------------

This was a good experience, and I'm really excited to do almost a full rewrite
in about 2 weeks. I have a docker image for this, that is from the scratch
image with two files - the binary and TLS certificates. Adding PNG support, the
biggest remaining feature, looks to retain these properties. My prompt for
the png support literally started with "What would you suggest for png generation?",
and in 30 minutes I have something working (to be clear, the output is terrible).
I suspect I'll learn a lot about PNGs in the next few days, but I am certain I'll
finish this feature a lot faster than I would have before AI. I will also,
of course, make sure the owner of wttr.in knows about this in case there's
any interest in...a full rewrite of the code into a language they've likely
never used?

Oh...and the repo is at https://git.lerch.org/lobo/wttr

You can try it out at https://wttr.lerch.org/
