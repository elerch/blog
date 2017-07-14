+++
date = "2017-07-13T16:43:28-07:00"
draft = true
title = "First Thoughts on Rust"

+++

I've read the [Rust book][rb] a year ago but never actually programmed Rust in anger
until this past week. I intend to do more with [Rust][r], but wanted to document my
initial thoughts on the language as a consumer, partly for posterity, partly to
avoid stockholm syndrome, and partly I think it might be useful to anyone on
the Rust team interested in the [out of box experience with the language][rd].

I believe that my background and experience is relevant, as I'll discuss later
in some of these points. I've been coding as a student and professional over
the past 30 years in a variety of languages. I've dabbled in systems programming,
done a bit of embdedded, but for the most part stuck with application programming.
With that said...

The Good
--------

* Type inference

I kept putting in type information, only later to take them out when I realized
the type inference is actually pretty awesome.

* Borrow checker

While I kept hearing a bunch of horror stories about fighting the borrow checker,
in my experience this was **not** an issue. I just rolled through my coding
without too much issue and did not scratch my head much over borrow checker
errors.

* Compiler errors

The non-issues with the borrow checker might be due in part to the clarity of
the compiler errors. I found them downright enjoyable, and outside of them
actually fixing my code for me, I didn't see much room for improvement. I think
the borrow checker problems people had were due in part to the old error messages,
but I think the [overhaul](https://blog.rust-lang.org/2016/08/10/Shape-of-errors-to-come.html)
in 1.12 might have been a large part of fixing the issues as well as the
perception.

* Pattern matching

I **love** working in a language with good pattern matching. I didn't get a
chance to use it all that much (thanks partly to the ? operator), but in my
small amount of use it was a delight.

The weird
---------

* unwrap()

I found I was adding unwrap() **everywhere**. I can't say this is good or bad -
the nice thing about it is it forced me to understand where things could
blow up on me. The downside is that I had to type it, then read it, all the
time. This might be an area where Rust could improve with a bit of simple
syntactic sugar - just a character or something so I'm still forced to think
about what I'm doing without having to read past it every 15 seconds.

Things that struck me as sub-optimal
------------------------------------

* Errors

One of the most difficult challenges was around error handling. Clearly the
language itself has been struggling with this for some time. I had a small
function (10 LoC or so) that I wanted to read from a file and parse the data.
Either the read or the parsing could fail, and each would provide a different
Error type. Rust's handling of a situation like this frankly sucks.  There is a
relatively new [? operator][rfc-error] that is actually really quite cool. It
reduces a ton of boilerplate code and will basically either return an error
from the function if an error occurred during the call, or it will proceed.
Upon return from the call you'll end up with a Result type that must be
unwrapped with unwrap(), but otherwise Bob's your uncle. This works great
**if**:

  * You only do this once in a function
  * You do it multiple times with the same error type

If you don't follow either of these, the compiler has no way to infer the Error
type that could be returned. The only answer today is to write a **ton** of
boilerplate. How much boilerplate? Well, there's so much boilerplate that
the real solution today is to skip the whole process and just use the
third party crate [error-chain](https://github.com/brson/error-chain). While
this is a great library, it should absolutely not be necessary. Also consider
it doesn't solve all the boilerplate. I still needed:

```rust
#[macro_use]
extern crate error_chain;

mod error {
    use std;
    use serde_json;

    error_chain!{
        foreign_links {
            IoError(std::io::Error);
            JsonError(serde_json::error::Error);
        }
    }
}
```

In my code. For those keeping score, that's 11 lines of boilerplate code, **and
an external crate** all to manage the fact that two things might error in a
function that currently consists of 7 lines of code. Folks, that be crazy.

* Strings

So I have a 100 LoC program, and even there I need 3 different string types.
What a pain! Here are the three types I used and why:

   * str. This is a Rust primitive. It's immutable and stack-allocated UTF-8.
     Some functions require str.
   * String. This is part of std. It's mutable and heap allocated UTF-8. Some
     functions require String, not str.
   * OSString. Also part of std. It's immutable and "a bunch of bytes as
     provided by the OS". Anything dealing with files, for instance, will need
this.

At one point I literally ended up with this line of code:

```rust
rc.insert(servicename.into_string().unwrap(), newestserviceentry.to_str().unwrap().to_string());
```

That seems beyond silly. I get where Rust feels it's required and I understand
that fundamentally all three string types serve a unique purpose, but can we
not do any better in 2010? At the very least the compiler should be able to
determine whether or not a string is being mutated and "do the right thing",
thereby preserving Rust's "zero cost abstraction" philosophy and removing one
of the string types. This constantly tripped me up.

Bottom Line
-----------

I think Rust has a bright future. The icky parts are fixable and/or livable,
and the roadmap is already looking to address some of the sharp edges. I look
forward to working with the language, though almost certainly in a primary way,
for a long time.

For those interested, the code I wrote was to process AWS CLI model files
(the files used to describe all the service commands, parameters and help text -
the cli itself is basically just an execution engine). It can be found
as [cli-model-parser](https://github.com/elerch/cli-model-parser) on github
and it's still pretty raw but handled what I needed at the time. I'll be doing
at least a little bit more to it and might be doing a lot, depending on how
things go. This write-up was based on commits up to
[f73e371](https://github.com/elerch/cli-model-parser/commit/f73e371e6fbe317b262de5c3688eb89949b0f296).

[r]: https://www.rust-lang.org/
[rb]: https://doc.rust-lang.org/book/
[rd]: https://github.com/rust-lang/rust-roadmap/issues/3 "Rust should have a lower learning curve"
[rfc-error]: https://github.com/rust-lang/rfcs/pull/243 "First-class error handling..."
