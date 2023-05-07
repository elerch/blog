---
title: "Simplifying our tool chain: First steps"
date: 2023-04-22
draft: false
---

Simplifying our tool chain: First steps
=======================================

This is part of an ongoing series:

* [Part 1: Exploring embedded programming with the Sipeed M0S with the BL616 microprocessor](/exploring-embedded-programming-with-sipeed-m0s-bl616/)
* [Part 2: Getting to hello world with Sipeed m0s (BL616)](/getting-to-hello-world-with-sipeed-m0s-bl616/)
* Part 3: Simplifying the tool chain: First steps
* [Part 4: Simplifying the tool chain: Wrap up](/simplifying-our-tool-chain-wrap-up/)
* [Part 5: Learning the SDK and USB protocol](/learning-the-sdk-and-usb-protocol//)
* [Part 6: Wrapping up our exploration: A mini shell](wrapping-up-our-exploration-a-mini-shell/)

Before going any further, the fact that I now have a bunch of random binaries
downloaded from the Internet on my machine, and 2GB of downloaded SDKs, I really
want to deal with that issue.

First on the list...the Sipeed SDK can be removed. We're getting hello world
through the Bouffalo SDK, and while there are differences that we haven't completely
figured out, let's remove 1GB of stuff from my machine until it's needed.

Secondly, the flash software. This is [closed source](https://github.com/bouffalolab/bouffalo_sdk/issues/93)
(but distributed in an Apache 2.0 licensed repo), but if we run `strings BLFlashCommand-ubuntu`
on it, we'll see that it's clearly a [pyinstaller](https://pyinstaller.org) executable. Anyone else
more than a little concerned it is closed source for "security"? Anyway, time for
some reverse engineering. We'll get to (a similar implementation of) the
the flash loader in Python, giving us a) source code we can examine b) smaller
disk footprint, and c) access to more platforms. [The MCU side of this was done](https://lupyuen.github.io/articles/loader)
using [Ghidra](https://ghidra-sre.org/), which was cool, but I think we can
get better fidelity this way.

Reversing BLFlashCommand
------------------------

Easy part. Go to https://pyinstxtractor-web.netlify.app/, and process the
executable. We'll get a zip file of the original pyc and system libraries.
Now we can ditch the system libraries because we'll just use the system
interpreter and libraries.

Python decompilers are kind of fickle, so let's figure out the *EXACT* version
of Python that created these. It turns out, the first two bytes indicate that
exact version. We'll run `od -x BLFlashCommand.pyc |head` and get the following:

```
0000000 0d42 0a0d 0000 0000 0000 0000 0000 0000
0000020 00e3 0000 0000 0000 0000 0000 0500 0000
0000040 4000 0000 7300 00b8 0000 0064 005a 0164
0000060 0264 016c 015a 0164 0264 026c 025a 0164
0000100 0264 036c 035a 0164 0264 046c 045a 0164
0000120 0264 056c 055a 0164 0264 066c 065a 0164
0000140 0264 076c 075a 0164 0364 086c 096d 095a
0000160 0001 0164 0464 0a6c 0b6d 0b5a 0001 0164
0000200 0564 0c6c 0d6d 0d5a 0001 0664 0764 0084
0000220 0e5a 0047 0864 0964 0084 0964 0665 0f6a
```

That `0d42` converts to decimal 3394, which we can look up at https://github.com/python/cpython/blob/main/Lib/importlib/_bootstrap_external.py#L339
to find it was Python 3.7b5. This was the last of the Python 3.7 bytecode versions,
so we know it was a production version of 3.7, and beyond that, it shouldn't matter.

Decompilers are an inexact science, so let's get to work. First, we need to
distill to exactly what we need. We dumped all the dynamic libraries (on linux,
everything *.so can go. The high level action plan is:

1. Remove all the standard library stuff, so we are at least focusing on additional code
2. Decompile the rest with [Uncompyle6](https://pypi.org/project/uncompyle6/). Ignore all failures
3. Create a brand new directory
4. Copy BLFlashCommand.py into the new directory
5. Establish a Python virtual environment in the new directory and activate it
6. Run `python3 BLFlashCommand.py` and catch the error
7. Fix the error, go to step 6 until no errors

This is easier than it sounds, and ultimately I switched to [decompyle3](https://pypi.org/project/decompyle3/)
and [created a docker image to help](https://github.com/elerch/python37-decompilers).
The errors, generally, will fall into one of the following categories:

* Missing import: copy the py file from the corresponding decompiled directory
* Missing import, that import is a library in [PyPi](https://pypi.org): add a reference to
  requirements.txt, run `pip install -r requirements.txt`. Note that figuring
  out the right library is a bit tricky, but helping us is the version numbers
  in the decompiled source code
* Import conflict: This happens when, for instance `base.py` and a directory `base`
  both existed and were copied over. We need to delete `base.py`. Python's error
  messages were a bit confusing when this occurred in nested directories
* Syntax error: Decompilation error. Ultimately, I found several decompilers
  and had to pick one that worked.

Eventually it ran as far as providing usage information, so I ran it with the
same arguments as I saw out of `make flash`. This gave me a new error related
to config files, which I located in the SDK directory and pulled in.

Next, we have a partially working flash command that successfully spins eating
memory. Time to bust out some normal debugging skills and get to work. And now
that I've found 3 decompilers, I can compare their output to locate potential
sources of errors. To help me with this, I built a [docker image with all three
compilers](https://github.com/elerch/python37-decompilers). I just ran this on
all relevant `pyc` files so I'd have versions to compare.

We'll skip the gory details here, but a few hours later, I have a fully working,
"open source" version of the BLFlashCommand flash command, located here:
https://git.lerch.org/lobo/blflashcommand. The spinning and eating memory, for
the curious, was a problem in the configuration parser. I ultimately threw away
all the code there and replaced it with Python standard library stuff.

You can see the changes I've made to the decompilation output (including one
file that was nearly completely removed and replaced with a small shim) in the
change logs on that repo.

The next step should be comparatively easy. Swap out the remaining usage of
binary blobs in the toolchain.
