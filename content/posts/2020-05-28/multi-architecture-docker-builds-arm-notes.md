---
title: "Multi-architecture docker builds: notes on ARM"
date: 2020-05-28T16:16:48-07:00
draft: true
---

Multi-architecture docker builds: notes on ARM
==============================================

There are significant dragons in trying to support a wide variety of ARM chips.
There are also a significant number of dragons in multi-architecture Docker
builds. This post gathers some of my experiences working with multi-architecture
docker builds.

ARM has emerged as an important processor architecture. Combining the [ARM
Architecture](https://en.wikipedia.org/wiki/ARM_architecture)/ISA, for which a
license can be purchased, with custom silicon, several companies have had
a lot of success in the market:

* Low cost system on a chip (SOC), like [Raspberry Pi](https://www.raspberrypi.org) devices
* Android and iPhone devices
* AWS, through custom [Graviton](https://aws.amazon.com/ec2/graviton/) chips
* Apple [M1](https://en.wikipedia.org/wiki/Apple_M1) Macs

My hope is that another up and coming processor, [RISC-V](https://en.wikipedia.org/wiki/RISC-V),
gets equivalent market penetration. The advantages of this
[ISA](https://en.wikipedia.org/wiki/Instruction_set_architecture) basically
comes down to the fact that it is a [RISC](https://en.wikipedia.org/wiki/Reduced_instruction_set_computer)
architecture, consistent and [open source](https://en.wikipedia.org/wiki/Open_source).
But ARM is a great step as many companies can (and have) licensed ARM
architectures, and as such multiple competing implementations exist.

Linux processor architectures:
------------------------------

Using `uname -m` will provide the CPU architecture on [POSIX systems](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/uname.html).

On my [Raspberry Pi Zero](https://www.raspberrypi.org/pi-zero-w/), we see
something like this:

``sh
$ uname -m
armv6l
``

We can now translate this to:

`Arm`: Obviously, this is ARM
`v6`: version 6. Generally version 5, 6, 7 and 8 are still supported in 2021.
`l`: little [endian](https://en.wikipedia.org/wiki/Endianness), which is fairly common

In ARM-land, the issue of whether or not the CPU has a hardware floating point
unit is a big deal. Generally processors that you see will be "hf" in 2020,
but you cannot count on it, especially in low end or embedded devices.

For ARM 64 bit architectures, this command will simply provide the output
"aarch64".

I believe mostly `uname -m` for linux would found via the following search
across its source code: https://github.com/torvalds/linux/search?p=1&q=UTS_MACHINE.
This would surface all the definitions for the variable UTS_MACHINE, which is in
turn pulled when running `uname -m`. ARM being a little different, ARM 32 bit
is a calculated value that doesn't show up in these results. Take a look at
https://github.com/torvalds/linux/blob/95f05058b2bbe3b85c8617b961879e52f692caa5/arch/arm/Makefile
for a reasonable picture of the 32 bit landscape for ARM.


Debian architecture names
-------------------------

Debian (and derivatives, like Ubuntu), being such a huge portion of the linux
landscape, we need to consider their architectures. These are defined via their
[ports](https://www.debian.org/ports/#portlist-released). Most relevant ARM
ports are officially supported. Here is the list, descriptions taken directly
from the page:

* armel: The oldest of the current Debian ARM ports supports little-endian
         ARM CPUs compatible with the v5te instruction set.
* armhf: A lot of modern 32-bit ARM boards and devices ship with a
         floating-point unit (FPU), but the Debian armel port doesn't take
         much advantage of it. The armhf port was started to improve this
         situation and also take advantage of other features of newer ARM CPUs.
         The Debian armhf port requires at least an ARMv7 CPU with Thumb-2
         and VFPv3-D16 floating point support.
* arm64: Version 8 of the ARM architecture included AArch64, a new 64-bit
         instruction set. Since Debian 8.0, the arm64 port has been included
         in Debian to support this new instruction set on processors such as
         the Applied Micro X-Gene, AMD Seattle and Cavium ThunderX.

In Debian-land, armhf= armv7 32 bit

Unofficially, there is also:

* arm: This port runs on a variety of embedded hardware, like routers
       or NAS devices. The arm port was first released with Debian 2.2,
       and was supported up to and including Debian 5.0, where it was replaced
       with armel. 
* armeb: ARM, software Emulated floating point, Big endian. I have seen
        references to this, but not seen any in the wild.

32 bit architectures
--------------------

These are important when building for compatibility across a wide spectrum of
devices:

* arm5: I believe this is mostly obsolete
* arm6: Used on Raspberry Pi Zero/Zero W and some low end and/or old android phones
        Few docker containers support this architecture
* arm7: Considered "hard float" by most, and seems to be the most popular in the wild
* arm8: This can work for 32 or 64 bit, but generally 64 bit is used for v8-specific builds

In docker, these are all considered "arm" architecture. Docker has introduced
a concept called "variant". In docker hub, you will see arm7, for instance,
noted as "linux/arm/armv7" In docker hub, you will see arm7, for instance,
noted as "linux/arm/v7". This last portion is the variant.

64 bit architectures
--------------------

Arm64/Aarch64 seems a lot more consistent. Since 2011, there has been only
arm8.x, and software compiled for arm8/arm64/aarch64 only seems to need one
variant. Arm64/aarch64 is used [depending on who you are](https://stackoverflow.com/questions/31851611/differences-between-arm64-and-aarch64)

Raspbian and Debian [disagree](https://raspberrypi.stackexchange.com/questions/87392/pi1-armv6-how-to-disable-armhf-packages/87403#87403)
on what armhf mean. Basically Raspbian says 'armhf' includes any arm processor
with hard float. Debian uses armhf to mean arm7+ 32 bit architectures.
However, arm8+ are 64 bit, so armhf in Debian realistically means just

``
readelf -A /proc/self/exe | grep Tag_ABI_VFP_args && echo 'Hard floating point'
``
If this command outputs a line "Hard floating point", Raspian will
use armhf packages. However, debian requires arm7 to use armhf packages.

Docker is a mess because arm variant detection [basically does not exist](
https://github.com/moby/moby/issues/37647)

Building an image
-----------------

Sticking to the Docker ecosystem, I've had some success with multi-architecture
docker builds generally following the advice on this page:
https://medium.com/@artur.klauser/building-multi-architecture-docker-images-with-buildx-27d80f7e2408

Gotchas I've run into:

* Everything with multi-architecture images is experimental. You need a recent
  operating system, a recent docker, a recent kernel, and you need to enable
  experimental features. There is even a table on the post above that walks
  through this. If you're host environment doesn't match a working configuration
  from the [table in the blog post](https://miro.medium.com/max/700/1*7L3hU-9LIFY9LU-rrTmfXg.png),
  then go back and fix that first, or you will be frustrated. Follow this
  carefully - even on a pretty modern system (debian buster new install)
  I needed to run their "fix-it script", and even that script needed some tweaks.
* Once you have qemu-static and all the configuration, it's pretty seamless to
  run programs compiled for another architecture. It can get super confusing as
  everything "works", but then on deploy, it doesn't, because qemu stepped in
  during your testing and you didn't even realize it. `file` is your friend,
  docker pull is **not**.
* `docker pull --architecture` works as you expect, but if you, for instance,
  do `docker pull --architecture linux/aarch64 myimage:latest`, then later
  do `docker pull myimage:latest` expecting amd64 (for Intel or AMD CPUs),
  you will *not get what you expect*. Docker will happily look at its cache
  and say "yeah, I've already got that image" and serve up the wrong CPU
  architecture. And you won't notice until much later when everything is
  broken and you're stuck in the office while your team is out drinking
  (best case) or hovering over your shoulder (worst).


This post is also useful: https://www.docker.com/blog/multi-arch-build-and-images-the-simple-way/
However, it also focuses on buildx, which is a docker cli plugin (another
piece of software to install, and only enabled with `DOCKER_CLI_EXPERIMENTAL=enabled`.

Because I like [podman](https://podman.io) due to its lack of daemon and
rootless containers, I've taken a shot at making this work there as well.
The good news is that the manifest commands are similar (though not identical).
The bad news is that pulling different architecture images just seems like
a broken situation. I'm sure it can be fixed, but my current [drone](https://www.drone.io)
install is on docker proper, so I haven't had a chance to investigate yet.
