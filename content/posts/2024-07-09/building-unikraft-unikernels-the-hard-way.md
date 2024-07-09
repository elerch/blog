---
title: "Building Unikraft unikernels the hard way"
date: 2024-07-09T14:14:48-07:00
draft: false
---

Building Unikraft unikernels the hard way
=========================================

You'll note from my last post that unikernels have a number of advantages for
building services, and [Unikraft (the company)](https://www.unikraft.io/) is making a run for
a commercial offering based on the [Unikraft open source microkernel](https://github.com/unikraft/unikraft/).

Of course, they're doing what they should be doing. Make a unikernel that can
run linux binaries without modification. But that is dull and boring, and
introduces a ton of overhead[^overhead]! Can we do better, but ignoring all that, and
embracing the inner workings of the microkernel build system?

Can we do it with [Zig](https://www.ziglang.org)?

Of course we can! Let's go play

Getting started
---------------

First things first...let's get hello world going. All this is easiest on Linux
or macOS, and if using the cloud you need to make sure you have access to kvm, which may
not be the easiest thing, nor the cheapest. Windows with WSL2 should also work,
but I have only done any of this on Linux. Once you determine where you're going
to try this stuff, you'll want to get [QEMU](https://www.qemu.org/download/#linux)
installed, as well as [kraftkit](https://github.com/unikraft/kraftkit). Kraftkit
has a few dependencies...if I remember correctly, I had most of what I needed
on a default debian distribution except flex, bison and libncurses-dev (needed
for `kraft menu` command). From there, you'll want to clone the
[unikraft catalog](https://github.com/unikraft/catalog/).

Hello world!
------------

The catalog is set up with a number of examples in the `examples/` directory.
**THIS IS NOT WHERE WE WILL PLAY!**. These examples are the boring, "build a
regular Linux application and watch it work" stuff. We want the hard mode,
advanced, expert stuff, which is located in the `native/` directory. That's where
all the cool kids hang out, and we want to party there.

In that directory, there is a helloworld-c directory. Go into that directory,
and do a `kraft build` and `kraft run`. Make sure to choose qemu/x86_64 when asked.
I'll wait. ;)

Once you've done that, you should see something like the following (I've modified
the config, so the header will likely look different):

```
Learn how to package your unikernel with: kraft pkg --help
■▖   ▖■       _ _               __ _
■▚   ■▞  ___ (_) | __ __  __ _ ´ _) :_
▀■   ■▄ ´ _ `| | |/ /  _)´ _` | |_|  _)
▄▀▄ ▗▀▄| | | | |   (| | | (_) |  _) :_
 ▚▄■▄▞ ._, ._:_:_,\_._,  .__,_:_, \___)
                 Calypso 0.17.0~1a9f80b
Hello, World!
```

What the heck just happened?
----------------------------

ok, so we have a bunch of things that just went on. kraftkit did a bunch of magic
for us, not all of which I understand quite yet, but here's the high level:

* Read the `Kraftfile` in the directory
* Wrote a kernel configuration into `.config.<appname>_<vmm>-<cpu arch>`
  (which in this case means `.config.helloworld_qemu-x86_64`)
* Pull the correct OCI images necessary to build the unikernel
* Build the microkernel, using `Makefile.uk` effectively as an included `Makefile` from
  the main Makefile from the OCI image. `Makefile.uk` includes our `helloworld.c`
* Take the build unikernel image, and lauch QEMU, specifying that kernel image
  should be used during the virtual machine boot

From a developer point of view, the important things to know right now are:

* It begins with `Kraftfile`, but we can largely ignore that unless we want to
  upgrade the base code we're building against
* Our `Makefile.uk` file is pulled into the overall Makefile, so we can make
  changes to the build here
* There's a config file for the build

Unikraft is focused primarily on the "run stock off the shelf linux applications"
use case, we need to be aware that documentation here is scant, so be prepared
to dig, and also maybe read some source code. Originally, they did not have
the ability to run Linux binaries, so the build system as described here is all
they had. As a result, some material I've found, while useful, is also out of
date. [This presentation](https://wiki.xenproject.org/images/2/23/Unikraft-buildsystem-compressed.pdf)
helped **a lot**.

Upgrading the base code
-----------------------

Let's get a simple thing out of the way first. How do I upgrade to a new version
of Unikraft? This was a problem I had in the last 3 months, as the version of
Unikraft I was working with did not seem to play nicely with any version of QEMU
that I tried. Luckily, there is a Unikraft version in the `Kraftfile`. So, I thought,
the answer was "change that version number and rebuild". Without detailed logging,
it looked like it worked. It did not.

It turns out, that even after `kraft clean`, there is a cache of build artifacts,
and the version specified in `Kraftfile` is ignored. The solution is to `rm -rf .unikraft`,
and this will force re-reading Kraftfile and pulling a new version. Another problem
is that arbitrary version shas as implied by the [documentation](https://unikraft.org/docs/cli/reference/kraftfile/v0.6#setting-a-specific-version)
is not actually possible. It appears as though the versions (or SHAs) you can use
the ones specified in the unikraft manifest file at this link:
https://manifests.kraftkit.sh/unikraft.yaml. This...took me a while to work out.

I haven't done anything cool yet!
---------------------------------

Well, you sort of have. But that aside, I get it. We have learned a bit about
how all this works, and now, with that knowledge, we can get cracking. If you
want to skip **way ahead**, you can look at my [example repository](https://git.lerch.org/lobo/unikraft-zig-native-hello).

The first thing I thought was "hey, I've now got a working application. Maybe the
easiest approach is to compile a static library, and just link it in". I like
easy, so that's what I tried.

First attempt was to fire up `zig init` on a subdirectory, add a line in
`build.zig` to specify that we want to link with libc (`lib.linkLibC`), build
it with `zig build`, and copy the static library from `zig-out/lib` into my
directory. ok, this is a good start, but now I need to link it. How is that
done? Well, I have a `Makefile.uk`, and that presentation from 2019 I found,
and this gave me enough to stumble my way through. The trick is to add my
library in the `Makefile.uk` like so:

```Makefile
UK_ALIBS-y += $(APPHELLOWORLD_BASE)/libziggy.a
```

My file was called libziggy.a, for no real good reason. After doing this,
progress! And by progress, I mean a bunch of linker errors.

Seeing all the undefined symbols, I first noticed there were zig-specific
symbols the linker was trying to resolve. Well, that won't work, but I also
know how to deal with that. Another edit to `build.zig` to specify that we
want the compiler runtime built in (`lib.bundle_compiler_rt = true`),
and we were on our way...to more failures. Specifically, we were now missing
the following symbols:

* mmap64
* dl_iterate_phdr
* getcontext
* sigaction
* write
* close
* realpath
* read
* msync
* munmap
* environ
* openat64
* flock
* fstat64
* dl_iterate_phdr
* getenv
* isatty

That is painful, but manageable. Later I learned that these are not all **used**
at runtime, but they are referenced in the library, and so must exist. To address
this, I spent a bit of time in the man pages, looking up function signatures and
adding empty implementations for each of the functions above. You can see that
work [here](https://git.lerch.org/lobo/unikraft-zig-native-hello/src/branch/master/undefined.c)
if needed, or want to copy it in as you're following along. You will also note
that these aren't really blank implementations. Each one will output
"unsupported function <function name> called", then force a segfault to make
sure the VM crashes. That way we know what's missing and can fix it.

After doing this, I needed a way to get `undefined.c` built and linked. We
already know how to do this, we can just copy and paste into `Makefile.uk`:

```Makefile
APPHELLOWORLD_SRCS-y += $(APPHELLOWORLD_BASE)/undefined.c
```

With that...success! The kernel is built and ready to run. As always, my code
is guaranteed to run the first time without any bugs. Especially "hello world"...

Why I can has no cheezburger?
-----------------------------

...and, crash. But! The crash was not the terrible looping crash in QEMU that I
had seen in the old version. We got past that after running their sample.

What was wrong, took me a while to figure out. I should note what the code
I wrote actually **does**. `zig init` provides a library with an `add` function.
I modified that function with a logging statement (uncreatively another "hello
world"), and I called add from `helloworld.c`, which looks like this:

```c
#include <stdio.h>

extern int add(int, int);

int main(void)
{
    int result = add(2, 2);
    printf("Hello, World! 2+2=");
    char buffer[10];
    for (int i = 0; i < 10; i++ ) buffer[i] = 0;
    buffer[0] = '0' + result;
    puts(buffer);

return 0;
}
```

The buffer stuff is dumb of course, but I didn't want to mess with any additional
libc functions or memory allocations or...anything. Just plain, dumb c outside
of what I was testing.

Eventually, I noticed that if I compiled my zig library in any release mode
(e.g. `zig build -Doptimize=ReleaseSafe`), it would actually work! And by work,
I mean crash on my `write()` call in `undefined.c`. Without my logging statement,
I could actually add 2 + 2 (I won't spoil the answer here...you'll need to compile
you're own unikernel and run it with QEMU to find out what that equals!),
and not crash. So more progress, but clearly more to do.

I put my Debug mode crash problem on a shelf, and decided to compile in release
mode for the time being. I know my library was eventually calling write, so I
just needed to implement `write()`. This eventually turned out to be the wrong
assumption, but I went down that path, pulled out my ancient c coding skills,
and got fancy about it:

```c
#define ANSI_COLOR_RED     "\x1b[31m"
#define ANSI_COLOR_GREEN   "\x1b[32m"
#define ANSI_COLOR_YELLOW  "\x1b[33m"
#define ANSI_COLOR_BLUE    "\x1b[34m"
#define ANSI_COLOR_MAGENTA "\x1b[35m"
#define ANSI_COLOR_CYAN    "\x1b[36m"
#define ANSI_COLOR_RESET   "\x1b[0m"

size_t write(int fd, const char *buf, size_t count){
    UNUSED(fd);
    UNUSED(buf);
    UNUSED(count);
    char *color;
    switch (fd) {
        case 1: // stdout
            color = ANSI_COLOR_RESET;
            break;
        case 2:
            color = ANSI_COLOR_RED;
            break;
        default:
            printf("write called on unsupported file descriptor: ");
            char fd_buf[10] = "fd = ";
            fd_buf[5] = '0' + fd;
            fd_buf[6] = 0;
            puts(fd_buf);
            SEGFAULT();
            break;
    }
    if (fd != 1) printf(color);
    if (fd == 2) printf("(stderr): ");
    printf("%.*s", (int)count, buf);
    if (fd != 1) printf(ANSI_COLOR_RESET);
    return count;
}
```

Once I worked through this, as long as I built with `zig build -Doptimize=ReleaseSafe`,
I was chillin'!

I really can't write to the console? How is helloworld.c doing this?
--------------------------------------------------------------------

ok, so I know helloworld.c is writing to the console. They're using `puts`, but
console output is a clear use case, so it must be that Unikraft has solved this
problem in the aggregate. What gives?

A bunch of research later, and some blog post, it might have been [this guide](
https://unikraft.org/guides/internals), but I'm not 100% sure, and I started
really poking through `kraft menuconfig`. Stumbling into their "Library Configuration"
section, I struck pay dirt. `posix-tty` said "Support for stdin/out/err", and
when I turned that on, I got a build error. This...was a good thing, because
specifically it was complaining about duplicate a duplicate symbol name for
`write()`. I `#ifdef`'d my way around the build error, and got output! So,
turning on the correct options in the Library Configuration section **should**
eliminate my need for `undefined.c` entirely. This is still on my TODO list, or
at least setting up the correct `#ifdef` statements and error messages is on
my TODO list. I'd love to be able to take a default Unikraft configuration and
just run zig code. Also, I like that my `stdout` shows up in red.

Loose ends
----------

Two things were left to do. 1) track down Debug mode builds, and 2) compile
and run "the zig way", which is `zig build` and `zig build run`. For debug mode,
the problem eventually traced to the libc call `gettid()`, which is implemented
if you turn on the new posix-process stuff in `kraft menuconfig`. But zig does
not call that, preferring the direct Linux syscall, and I haven't figured out
the Linux syscall shim in Unikraft yet. Zig does not call it, as zig supports
glibc going back to a time when `gettid()` did not exist in libc. It only looks
for the current thread ID when performing locks in Debug mode, which happens to
happen when performing a log function call. So...that's the root cause, but
I don't really have a reasonable path forward, other than [asking other zig
contributors what they think](https://github.com/ziglang/zig/issues/20546).

Compiling and running was much more straightforward. I will spare the details
here, but my [build.zig](https://git.lerch.org/lobo/unikraft-zig-native-hello/src/branch/master/build.zig)
in the example repo has the details. Note that I'm not doing anything special
to avoid dependencies on the system, so you still need QEMU and kraftkit
installed. But I do have a (mostly) working `zig build distclean` build step
that will also remove the cached `.unikraft` directory that really confused
my debugging.

[^overhead]: I'm kidding/not kidding on the overhead. In the grand scheme of things,
     unikernels eliminate so much traditional overhead, the small amount of extra
     time to parse and load elf binaries and provide the other compatibility is fine
     for most use cases.

