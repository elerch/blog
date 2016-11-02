+++
title = "Installation of Arch Linux on a USB stick with UEFI and legacy BIOS Support"
draft = false
date = "2016-11-01T19:28:18-07:00"

+++

I tend to move around machines quite a bit, especially when traveling.
As such, I thought it would be useful to have a portable environment on
a USB stick. Since I don't know what type of machine I would be walking
up to, this needed to support UEFI and BIOS. I wanted an actual **install**
on a USB stick, not simply a live environment.

I chose Arch linux because I like the lightweight do-it-yourself
philosophy and had heard good things about the pacman package manager.
I had some previous experience with it as well and it was overall a positive
experience. I remain concerned that the overall linux community doesn't
consider arch, so updates may break things. Time will tell on this.

It took a while and I learned a **ton**, including that certain hardware
[will not work](https://www.amazon.com/review/R2VFHAYPJIC9YB/ref=cm_cr_rdp_perm)
with at least the UEFI on Macs. Those that are interested, btw, should
use the [Samsung Flash Drive Fit](https://www.amazon.com/Samsung-Flash-Drive-MUF-64BB-AM/dp/B013CCTNKU/ref=cm_cr-mr-title)
instead.

I created a [gist of my efforts](https://gist.github.com/elerch/678941eb670324ffc3f261eabba81310),
which I'll continue to maintain as a living document. I will not,
however, include packages I install for my own use so I can keep
the gist as more of a base install step-by-step.

I'm also working on making my USB multi-boot, but most other Linux
distros assume during install that they should install a bootloader,
etc., which would mess with my setup. I have a plan, however, so
stay tuned...

