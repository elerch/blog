---
title: "Simplifying our tool chain: Wrap up"
date: 2023-04-26
draft: false
---

Simplifying our tool chain: Wrap up
===================================

This is part of an ongoing series:

* [Part 1: Exploring embedded programming with the Sipeed M0S with the BL616 microprocessor](/exploring-embedded-programming-with-sipeed-m0s-bl616/)
* [Part 2: Getting to hello world with Sipeed m0s (BL616)](/getting-to-hello-world-with-sipeed-m0s-bl616/)
* [Part 3: Simplifying the tool chain: First steps](/simplifying-our-tool-chain-first-steps/)
* Part 4: Simplifying the tool chain: Wrap up

"The next step should be comparatively easy. Swap out the remaining usage of
binary blobs in the toolchain." - me, last week

Well, that was **NOT** comparatively easy, not by a long shot. It was difficult
enough that I had to ask myself, "so, what exactly is the goal here?". To that
question, I came up with the following answer:

* Reduce disk space usage for all the bits needed to build/flash
* Ensure all build/flash tooling is based on open source
* Get a way to easily use the SDK without a bunch of downloads and setup on the developer machine

Of these three objectives, I can confidently say I've fully accomplished one of
them, and partially accomplished another.

Last time, we managed an open source version of the flash tool. With this in
hand, I assumed that we could use a different C compiler (different version
of gcc, or maybe even clang) to compile. The logic was, if I could compile
with clang, I could compile with zig, and I could write embedded code on the
BL616 with zig, which would be way cool. I still have a plan to get there, but
it clearly will not be easy.

What I found in the process is that this is likely possible, but probably not
desirable. The version of gcc recommended by the Bouffalo SDK is the [Xuantie
T-Head Gnu Toolchain](https://github.com/T-head-Semi/xuantie-gnu-toolchain).
This is a fork of another [Risc-V collaboration project](https://github.com/riscv-collab/riscv-gnu-toolchain)
to enable Risc-V compilation.

Gcc itself, as well as clang, support Risc-V, so compilation is not a problem.
However, the T-Head version supports the RISC-V p extension opcodes enabled
on the BL616. Also, it supports specific tuning for the processor with a
proprietary mtune option.

Undeterred, I plowed ahead, only to be met with changes that were made to system
includes in the forked toolchain. I was starting to get into some really hairy
stuff that I did not want to maintain. I needed a new approach.

That new approach would be "make sure that there are no binary blobs in the
T-Head toolchain, compile it from scratch, and shove it in a docker container".
As it turns out, this was very possible and the results are in [my github
repo here](https://github.com/elerch/xuantie-gnu-toolchain-docker). Compiling
the code took over an hour, but at the end of the process I got a good base
image.

The next step was to utilize this base image and load, modify, and configure
the SDK, decompiled post processing tool, and decompiled flash tool from the
previous work. At the end of the day, we have a [docker image](https://github.com/elerch/bouffalo_open_sdk)
that can be used in place of make, built with nearly all open source.

Using this image will consume slightly less disk space (1.8GB vs 2GB), but
we now have an easy way to use the SDK without a bunch of downloads. Unfortunately,
we're not purely open source. The WiFi and BLE drivers remain proprietary,
but everything else is now open.

Using the image to create a project
-----------------------------------

The downside to containerizing the SDK is that we now, in our project, need
to reference what I'll call "magical things". Generally I don't like magic,
but in this case, I'll accept it. But in the process of working through all
the kinks in the container images, I've gained an understanding of the
auxiliary files in the project. Here's a tour:

* Makefile: make will call cmake to make Makefiles, which end up in a `build/`
            directory. This Makefile is pure boilerplate and can be used from
            project to project with no changes. But the file must be there
            so the initial make command kicks off the chain.

* CMakeLists.txt: This is a lot of boilerplate, but does specify the source
                  files, include and main file for the project. It also
                  specifies the project name. Generally will not be touched
                  beyond an initial commit, except maybe to add source files.

* proj.conf: This is included by CMakeLists, and is intended to set variables
             indicating which additional libraries we want to bring in. It is
             a bit dubious that something like CherryUSB, which is a different
             library and repository, is just included in this SDK, but I don't
             want to re-think that right now.

* flash_prog_cfg.ini: This is used by the flash program, specifying the entry
                      address and a few other variables. It's almost all
                      boilerplate, but you the filedir variable will need to
                      change from project to project.

Once these files and your source code is in place, we're ready to build. As
long as docker is installed, we can use the following command to build the
project:

```
docker run --rm -t -v $(pwd):/build git.lerch.org/lobo/bouffalo_open_sdk:2f6477f BOARD=bl616dk CHIP=bl616
```

Once that is complete, we can use this command to flash to the device:

```
docker run --rm --device /dev/ttyACM0 -v $(pwd):/build git.lerch.org/lobo/bouffalo_open_sdk:2f6477f flash BOARD=bl616dk CHIP=bl616 COMX=/dev/ttyACM0
```

One permissions note: if using docker proper (rather than podman), build output
will be owned by root. Using `-u $(id -u):$(id -g)` as part of the docker commands
above will address that.

With this done, let's get back to the actual code. The code from part 1, slimmed
down by this exercise, can be found on GitHub, and because we'll use this code
moving forward, here is the link to the current commit: https://github.com/elerch/bl616-usb-cdc-acm/tree/7267d81b861d6c41a64bd69ca670bc38e4939070
