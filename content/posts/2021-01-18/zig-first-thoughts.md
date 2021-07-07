---
title: "First thoughts on Zig"
date: 2021-01-18T12:23:18-07:00
draft: false
---

First thoughts on Zig
=====================

I encountered [Zig](https://www.ziglang.org) a while ago and it intrigued me.
It's intrigued me enough to write a
[small utility program for personal use](https://github.com/elerch/event-processor)
and now an [SDK for AWS](https://github.com/elerch/aws-sdk-for-zig), with
some contributions to upstream projects along the way. All told I've written
more than 10k lines of code in the language (current net code count is just shy,
but I've done a lot of refactoring!). My current opinion is that zig, for me
is a great blend of high level/low level with a focus on efficiency. My intent
at this time is to use zig whenever possible.

If I can try to summarize the goals of the language, it would be this:

Provide a **systems programming** programming language that:
  * Is better defined than C
  * Has first class support for cross-compilation (both OS and processor types)
  * Provides a high degree of safety
  * Can be used for embedded (bare metal/no OS) development

Provide a **general purpose** programming language that:
  * Doesn't need garbage collection
  * Is simple
  * Generates small/fast executables

When working in the language it sometimes feels like I'm programming in
[go](https://golang.org) and sometimes in [c](...). I like the "simplicity"
of the language, but more on that later.

Should you use it? Probably not...but that's due to its one fatal flaw right
now, which is that it's just not baked yet. At the time of this writing,
it is at version 0.8.0 and sees hundreds of commits per week. Some of these
are breaking changes, and depending on your needs, some features may be
missing or broken. Documentation of the standard library is a lot of "go read
the source code". Parts of the language and library don't follow naming
conventions or idioms that are still evolving and changing in the language.

Comparison to other languages
-----------------------------

I mentioned above it sometimes feels like go and sometimes like c. I think
spiritually these are zig's closest languages, and I've heard zig described
as one of the languages that are trying to be "a better C". If we remove
garbage collection from go, we get to something pretty close to zig. So, I think
these two languages are a good place to start:

**Go**

Like go, zig is a simple language. Its [grammar](https://ziglang.org/documentation/0.8.0/#Grammar)
is currently 554 lines. If you understand go, you can get to zig (mostly) by:

* Removing closures
* Removing garbage collection
* Removing goroutines
* Removing tabs ;-)
* Adding spaces
* Adding a sane error handling mechanism
* Adding "generics" (more later)
* Adding first class embedded development

[For loops](https://ziglang.org/documentation/0.8.0/#for) in zig reminds me of
the [range-for](https://tour.golang.org/moretypes/16) loop in go. However, zig
uses the same capture syntax from for loops in its while loops, if statements
and switches, which gives a nice consistency to the language. Declaring public
things in zig is explicit, unlike the capitalization-based concept of go.
Personally I like the explicit way of doing things, but I see the rationale of
go here. zig also disallows tabs in the source code, which is also my jam, but
it certainly bothers some.

Also worth noting is binary size. As of go 1.15, a hello world, even without CGO
Enabled, is just shy of 2MB. there is an [epic
issue](https://github.com/golang/go/issues/6853) talking about this. zig's
hello world, built in default debug mode is 570k.  Switching to release mode
will give you a 69k binary that when stripped will be approximately 2k. While
memory utilization is of course variable, I've directly converted a go program
to zig and easily seen a 10x improvement on that front. When you have to
allocate/deallocate memory yourself, you'll be a lot more careful. A notable
advantage of go over zig is that the compiler is super-fast in comparison.

Of note, since zig is pretty new, it's important to be able to interface with
C libraries. Zig makes this more or less seamless, and since
[zig can be used as a drop in replacement for cc](https://andrewkelley.me/post/zig-cc-powerful-drop-in-replacement-gcc-clang.html),
this can be done with the same zig download  you use to compile zig code.
In my SDK, I had to work around 
[zig's lack of direct bitfield](https://github.com/ziglang/zig/issues/1499)
support. The solution here was to simply drop a C file in the middle
of my project and have zig compile it with everything else. Using C from Go
feels like a bolt-on compared to zig, and is much harder.

**C**

Like C, zig is focused on portability across operating systems and hardware.
In 0.8.0, it has [Tier 1](https://ziglang.org/download/0.8.0/release-notes.html#Tier-1-Support)
support for 8 architectures and 4 Operating Systems in addition to freestanding/
bare metal development. Tier 2 support adds 3 more Operating Systems plus UEFI,
and 3 additional hardware architectures. However, C leaves a lot of underspecified
behavior, which makes a lot of compiler differences. This may not be entirely
fair as zig only has a single compiler implementation, but the expectation
is that the language prevents a lot of undefined behavior. Nulls, for example,
must be explicitly allowed, and will be checked. Undefined variables are
possible, but also checked by the compiler to be defined before use. Zig
also adds `defer` and `errdefer`, which provide the ability to handle a lot
of memory (or other resource) deallocation edge cases.

**Rust**

Rust tries to find "zero-cost abstractions" to provide memory safety in an
object oriented environments. I think of the language as C++, but with memory
safety and without a lot of cruft that C++ started with and has gotten worse
over time. Like zig, cross-compilation of Rust is easy. Like Go, incorporation
of C libraries requires more work than zig. Because Rust has a first-class
concept of memory "ownership", allowing Rust to control allocation and
de-allocation of memory. In zig, all memory allocation and deallocation is
explicit. Zig's approach can be painful at times compared to Rust, but this
pain also forces the programmer to consider allocations carefully and in
practice probably reduces the working set of many programs. It also means that
segfaults are part of life, as are memory leaks, although zig test and choosing
the right allocator can help debug leaks.  Rust is much more complicated than
zig, and compilations are much slower. The toolchain is also much heavier, with
image on-disk size of 806MB for docker 1.53-alpine version. Zig's toolchain,
uncompressed on disk weighs in around 300MB by comparison.

**Other**

Sorry, other languages, you get bucketed here. Java and C# can join most
of the go discussion, except that these are true object oriented languages,
while zig is procedural. Functional languages have great attributes and I like
them a lot, but they are typically divorced from the hardware they are running
on, while with zig this is decidedly not the case.


memory
------

Memory management, without a garbage collector, is clearly a focus of the
language. Allocations and deallocations are explicit just as in C. However, zig
has an approach that works well for managing deallocations to prevent a lot of
issues. In zig, you can return an error, which feels a little bit like
exceptions in languages like C# or Java. In fact, zig has a keyword `try` that
will automatically return an error if an error occurs within the expression,
and a keyword `catch` that will allow you to "handle" an error. To avoid
missing a deallocation for exceptional situations, you can use `defer`
statements for deallocation (or tear down for other resources). For situations
where returned memory will be owned by the caller, another keyword `errdefer`
can be used. This statement basically says, "If an error happens in this
function, deallocate/deinitialize, otherwise the caller is responsible". In
practice, this works really well once you start getting the hang of it. I have,
however, had my share of segfaults and memory leaks in testing before
understanding how to build tests and structure allocators to detect leaks.

safety
------

Zig has an ongoing effort to improve safety, so this section will change a lot
as the language evolves. Right now, there are built in test facilities around
memory leaks. There are checks for buffer overruns and integer overflows. There
are pointer alignment checks, asynchronous checks, and array bounds checks.
Much more is planned, and the project culture is to eliminate as many "foot guns"
as possible in most scenarios. It is possible to turn checks off in lieu of
performance and executable size, though that isn't recommended. Null values
must be explicit, as are undefined variables.

async
-----

Async operations are designed to be transparent. Unlike many languages, a
function is free to do its own thing, then suddenly find itself executed
asynchonously. There are some subtle differences between zig, and say, Rust
here in terms of implementation as well, but the philosophy in zig is to
allow a lot of code reuse, and the async approach enables that, as does
its comptime behavior, as I will talk about next.


comptime (and generics)
-----------------------

Comptime is the most unique part of the language IMHO. Functions can run at
runtime or at compile time (comptime) "without knowing the context". These
quotes are pretty important, because in my experience, compile time code is
super powerful, but as a programmer you absolutely have to consider both
compile and runtime behavior of functions as well as the partial compilation of
functions that result in part compile, part runtime behavior. Used well, the
ability to run arbitrary code at compile time is an incredibly powerful tool.
But understanding how this works and how to take advantage of it is easily the
biggest learning curve of the language. The success of the language, in my
opinion, hinges primarily on two factors. First, zig might be too late. As an
industry, Rust might be "good enough", and zig may not get traction as a
result. Secondly, comptime semantics might be too hard to reason about, or
alternatively, might be the killer feature the industry has been waiting for.

As an example, you may be coding away and ultimately write a function that
starts looping through the fields of an enum because you're doing some light
metaprogramming. My recent example here is using enum values as switches to
a command line program. Anything metaprogramming becomes comptime. First,
you'll get an error you probably don't understand. The solution is to use an
inline for, which you'll eventually figure out, but understanding what the
compiler may be beyond some new programmers. This is complicated by the fact
that throwing in some "printf debugging" won't do you any good because that,
of course, is runtime, so you need to use `@compileLog` statements instead,
which can look **really** weird when doing a `zig build` command.

The other aspect of this that concerns me is that the system is so powerful
that it may make IDEs unable to assist the programmer. For example, zig has
`anytype`, which is kind of equivalent to `var` in many languages and is
usually used for function parameters. It basically says, "I don't want to
worry about the type of this thing right now - I know what I'm doing". anytype
will get replaced with the actual type at compile time, so you don't lose
safety information, but in order for an IDE or language server to provide
completion information, the code needs to be fully evaluated, including all
call sites. As a practical matter, I don't believe I've seen any intelligent
completion based on anytype parameters, only my brain saying "I know it's
anytype but the thing I get will have a function foo() on it".

The nice thing about comptime, though, is the power it provides (or promises).
There are still gaps here, big ones like the inabillity to allocate memory
at comptime. These plan to be fixed, but even without memory allocation amazing
things are currently possible, like the ability to parse json data at
compile time. This pushes a lot more computation up front and makes executables
much faster as a result. It also allows generics in what is otherwise a
"generics-free" language, because the return type for a function, for instance,
can be calculated by another function that runs at comptime! It's amazing, and
I've already overused this several times before ultimately backing down to
go a more pedestrian path.

"feel"
------

Let's get some of the bad out of the way first. Error messages...omg. To zig's
credit, it does a fantastic job providing the detail you sometimes need.
But let's look at an example I hit all the time. This line of code prints
as you would expect:

```zig
std.log.info("All your codebase are belong to us.", .{});
```

If I wanted to print a value, I could say:

```zig
std.log.info("All your codebase are belong to us. foo={s}", .{foo});
```

But if I forget to put in the `{s}`, like this:
```zig
std.log.info("All your codebase are belong to us. foo=", .{foo});
```

I will get a screenful of the error return trace including all 12 calls that
were in the chain, even if this is only in the main function. You get used
to it, but it leaves you with a certain sense of dread seeing these types
of errors.

That's cosmetic, but one thing that's a bit more tangible is something I miss
from a few other languages, most notably Rust. That is, when coding I sometimes
really just want everything to be an expression. Zig has an example of returning
from a block, for instance, that just feels a bit wonky. This example is
in the current documentation for example:

```zig
// use compile-time code to initialize an array
var fancy_array = init: {
    var initial_value: [10]Point = undefined;
    for (initial_value) |*pt, i| {
        pt.* = Point{
            .x = @intCast(i32, i),
            .y = @intCast(i32, i) * 2,
        };
    }
    break :init initial_value;
};
```

While I'm glad this is possible, Rust would handle that by just ending
here with a last line of `initial_value`, indicating that the block's "value"
is initial_value. This feels a bit more natural to me, though I'm sure there
are lots of reasons why other parts of zig make this undesirable or impossible.
I'm not a language designer, but I do get to write words on the Internet. ;-)

The focus of the language is currently on building a self-hosted compiler, so
it's not really fair to pick on other things quite yet, but I'll take a quick
shot anyway. The standard library really needs some attention. It is inconsistent,
even with regards to naming standards, and is poorly documented. The idioms
used are also inconsistent, which I believe leads to confusion. I hope that
the core team can get some focus time on it soon.

Which brings me to one of the bright spots, actually, which is the community.
I've lurked on IRC, seen the Issue and PR traffic, and seen the twitter threads.
Andrew and it seems everyone involved with the language is passionate and
helpful to anyone regardless of their knowledge of zig. I've yet to see a
hostile attitude from any zig contributor.

