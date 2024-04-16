---
title: "unikernels"
date: 2024-04-09T17:15:30-07:00
draft: false
---

Unikernels
==========

I recently saw a [notice on Hacker News](https://news.ycombinator.com/item?id=39902949)
talking about [KraftCloud](https://kraft.cloud/). I've seen previous news about
[UniKraft](https://www.unikraft.io) and Unikernels in general and have more
than a passing interest in the technology. This news item had me take another
look at the state of the technology, and what I learned was interesting.

What is a Unikernel?
--------------------

Typically, an application runs on an operating system, which runs on hardware.
Sometimes, the operating system is running in a virtual machine, which is
supplied by another operating system (called a hypervisor), running on hardware.
Sometimes, the application is running in a container on and operating system.
Sometimes, containers and/or virtual machines can be nested. It all makes
sense based on what you need to do, but this can get confusing, and is often
unnecessary. For example, if I want a server that runs a microservice and
calls other microservices, do I really need a full operating system that has
everything needed to run the latest AAA game while watching streaming video
and chatting with my friends? By eliminating everything besides what we need
to run my microservice, we gain a lot:

* Less storage for the operating system, application, and dependencies
* Less memory usage as we lose all the stuff loaded "just in case"
* Less CPU as we don't have services we don't need
* Less attack surface for attackers to leverage
* Faster initialization (boot)
* Immutable deployment
* Performance through the ability to tailor the OS to the needs of the application

We can achieve these benefits in a few ways:

* Smaller docker images
* Stripped down operating systems
* Minimalistic hypervisors

But, there's another way. What if we build our application directly into our
operating system? This takes minimalism to the extreme, or logical confusion,
depending on your view. This idea has been around since the mid-90's, but
the term "Unikernel" appears to have been coined [in a 2013 paper](https://mort.io/publications/pdf/asplos13-unikernels.pdf).

Current Landscape
-----------------

Since 2013, several research projects have been created around Unikernels.
A good list [can be found on GitHub](https://github.com/cetic/unikernels#comparing-solutions).
You'll notice that on each kernel has a specific set of languages supported.
This is a major drawback to most Unikernels (yes...that's foreshadowing).
Since the application is literally compiled with the kernel, the kernel and
the application must be built together, at the same time, with a common set
of tools. Typically, the languages are fairly low level, primarily because
Unikernels must be written in languages that can speak to "hardware" (where
hardware might be a virtual machine provided by KVM, Xen, VirtualBox, Hyper-V).

In my opinion, this has been the major drawback that has kept Unikernels in
a niche space. Something for me personally to keep an eye on, but not a technology
to get excited about.

When I started to revisit the topic of Unikernels when this news from Unikraft
was announced, I took a peek, and noticed they are supporting "any" docker
application with their Unikernel. How does this work, if the application
is immutably bundled with the kernel?

I took a look, and there are three major Unikernel projects all trying to solve
the developer experience and operational experience for Unikernels. [OSv](https://github.com/cloudius-systems/osv)
was first announced in 2014, took a break from 2015-2018, and has been active
since. [Nanos](https://github.com/nanovms/nanos) and
[Unikraft](https://github.com/unikraft/unikraft) trace their roots back to 2017.
All three have this magical ability to run multiple languages...so what gives?

Enter Docker
------------

Docker has become enormously popular since its launch in 2013. Developers and
operations appreciated the benefits of reproducibility and immutability of
docker images. But Docker was interested in creating an open and level playing
field, and eventually standardized, in 2017, the format used to create docker
images. So, the industry had a standard format for reproducible images that
could be used for Unikernels, and Docker also reinforced the trend toward
Linux-based microservices.

Without talking to the people on these projects, my assumption is that, in
2017, a few folks had the idea to build a Unikernel with a standard application.
That application's responsibility would be to load and run Linux binaries.
Linux binaries use a standard [ELF binary format](https://en.wikipedia.org/wiki/Executable_and_Linkable_Format),
access the kernel through a [standardized set of syscalls](https://en.wikipedia.org/wiki/Linux_kernel_interfaces#System_call_interface_of_the_Linux_kernel),
and with OCI, have a standard way of packaging the binaries.

All three have gone down this path, and in 2020, unikernels were split, from
a taxonomy perspective, into ["Language-based unikernels" and "POSIX-like unikernels"](
https://dl.acm.org/doi/fullHtml/10.1145/3624486.3624492#sec-5). Evenutally,
researchers have said, "rather than create a Unikernel from the ground up
with Linux support, why don't we strip down Linux instead?". Thus was born,
in May 2023, the [UniKernel Linux project](https://dspace.mit.edu/bitstream/handle/1721.1/150839/3552326.3587458.pdf?sequence=1). I could not find boot time measurements
for this project, but the [Firecracker](https://firecracker-microvm.github.io/)
project claims to have a custom linux kernel booting in 125ms. I'm a bit skeptical
of the UKL's project ability to compete on that particular metric as Unikraft,
for example, claims boots in 6ms. My personal observations on Unikraft are that
6ms is, in fact, about correct.

Why, though, is it important to boot your machine this quickly? Well, the primary
thing for me is that 119ms, or the difference between boot times between
optimized Linux and, in this case, Unikraft, is also the difference between
providing a microservice that needs to run 100% of the time and one that can
simply boot up, serve a request, and then shut down completely...

Unikraft
--------

All three of what I consider to be the major players in the Unikernel space
offer the same features. All provide Linux binary support with an orchestrator
that provides someone with a CLI that feels like docker. Compiling a native
application (one that does not use the ELF loader and Linux syscall emulation)
is left for the truly daring in each. OSv and Nanos do not provide directions
for this at all, and while Unikraft does, I was unable to get a functional
kernel on my machine, which was probably the [same issue as reported here](
https://github.com/unikraft/unikraft/issues/1371). Of the three, I'm most
excited about Unikraft, for a few reasons:

1. They have a commercial business in the making, based on the core Unikernel
   technology. They need the open source kernel fast, compatible, and developer
   friendly to succeed. They have VC funding to pay people to make this happen,
   in addition to the open source community. The primary backer of Nanos sells
   command and control. The primary backer of OSv sells...nothing at the moment?
2. It seems like they have had a lot more momentum then the others.
3. They are still open to native apps, and their Linux binary support is
   [actually a separate repo from the core](https://github.com/unikraft/app-elfloader).

On their commercial offering, I joined the beta, and I'm impressed. The performance
was as advertised, the developer experience was great, and the "scale to zero"
works well. I haven't tried it myself yet, but "scale to zero" should also
work with non-HTTP connections. Their documentation describes what is effectively
a load balancer in front of your unikernel deployments, so a service is always
there to listen for new connections and trigger your unikernel.

Is it ready to use? I would say no, not yet, at least not in a general sense.
The idea here is to have Linux binaries "just work", and without support for
the `fork()` system call, we get pretty limited. If you craft your binary with
the assumption of working in Unikraft, then yes. But that's not their goal,
and it really shouldn't be ours. While I can't find it on Unikraft's roadmap,
one of their core team has stated that [fork is coming soon](
https://news.ycombinator.com/item?id=39904144). I know I will be watching this
space closely.
