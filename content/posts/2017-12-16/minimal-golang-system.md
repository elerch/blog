---
title: "Minimal Golang System"
date: 2017-12-16T09:45:30-08:00
draft: false
---
I've been doing some experimentation with creating bare bones systems. These
come with a minimal of operational issues - fewer moving parts requires less
upkeep, have less code for security issues, etc.

[Golang](https://golang.org/) is a fantastic language for this, as it is
easy in Go to produce a statically linked binary (outside of Windows). Due
to the nature of Windows some dynamic linking is necessary. A static binary
(admittedly lacking C support) can be generated with a command similar to this:

```
CGO_ENABLED=0 GOOS=linux go build -a .
```

To package, we'll focus first on the container experience. [Docker](https://docker.com)
is ubiquituos at this point. [rkt](https://coreossomething)
is another alternative but this system is docker compatible so we'll focus on
docker.

The container runtime here does most of the heavy lifting for us. Containers
share the kernel of the operating system, so as long as the system is statically
linked, we don't need much from the rest of the ecosystem. For a simple project
we need only the kernel and possibly (probably) some networking. The runtime
generally provides this, so we can get away with the following:

```Dockerfile
FROM scratch

COPY mybinary /mybinary

RUN mybinary
```

This results in a super-small image with very little going on, even less than
[alpine linux](https://www.alpinelinux.org). Of course, as with all things
container-based, we are dependent on the kernel used by the host OS. Sometimes,
we need ssl support, which requires additional infrastructure in the container.
For that, all we should need to do is copy the certs we need into the container
in the expected place:

```
COPY ca-certificates.crt /etc/ssl/certs/
```

To achieve better isolation and build repeatability, we need only contain the
kernel being used. This, while significantly harder, is achievable. As this
will run on bare metal or a hypervisor, we will need to tailor the solution
to the underlying environment.

The process was pretty well documented by earlier work, so I will instead focus
on the changes I've made to achieve a single-use virtual machine, rather than
an entire [Linux from Scratch](https://sites.google.com/site/4utils/articles/minimal_linux_system/minimal-linux-system-from-scratch)
built out. Before proceeding it's worth skimming the link above to get a feel
of the process, at least up to the point of installing and configuring
busybox, which we won't need. I'll describe the differences here.

First, sections 1 and 2 are interesting and work flawlessly but are unnecessary.
If you're working with QEMU, you can simply create the disk image, attach that
image to another QEMU instance with a running Linux OS, and partition/format
the block device from within that instance. There is no need for all the fancy
loopback mounting and offset calculations. I feel going through the guide helped
me learn a lot, but if you just want to get things done and you have a Linux VM
already you can save a ton of time by simply partitioning/formatting within another
VM. With this process, you can also use the grub that's likely already in your
Linux VM to copy stage1, stage2 and e2fs_stage1_5 over into the /boot/grub
directory on the target device (QEMU raw image file). You can also install
grub directly onto the device without going through the boot floppy procedure.

I found the most difficult part of the process to be getting the right kernel
compilation options. I haven't created a minimum configuration yet, but the
firecracker VM team has done quite a bit of work in this area, so starting
with [their config](https://github.com/firecracker-microvm/firecracker/blob/master/resources/microvm-kernel-config)
is a good starting point.
