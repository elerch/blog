---
title: 'Zig build, and how I created a "universal lambda" function'
date: 2023-05-07
draft: false
---

`zig build` overview for zig 0.11.0, and how I created a "universal lambda" function
====================================================================================

Having worked with zig starting in 0.9.0, the language, compiler, and build system
have come a long way. While still lacking documentation and stability, it feels
productive, and with the 0.11.0 release, I have stopped reaching for the latest
master branch builds.

One of the properties of Zig, for both good and bad, is that it contains everything
needed for development. That means that while Zig is a language, it is also
a build system, and with 0.11.0, a package manager. In fact, some people ignore
the language entirely, with the exception of what is needed to build using zig.
Lacking documentation however, it has taken me a while to really get in depth
in the build system. I sense others are in a similar position. This, therefore,
is my attempt to provide an overview.

Note that this post covers a snapshot in time, and some areas of the build, and
in particular details I will cover regarding the MVP package manager features,
will change significantly over the next few releases.

Terminology
-----------

Let's start with some terminology, which has changed in 0.11.0. Quoting from
[Issue 14307](https://github.com/ziglang/zig/issues/14307):

* Package: A directory of files, uniquely identified by a hash of all files. Packages can export any number of compilation artifacts and modules
* Dependency: A directed edge between packages. A package may depend on any number of packages. A package may be a dependency of any number of packages
* Module: A directory of files, along with a root source file that identifies the file referred to when the module is used with @import
* Compilation artifact: a static library, a dynamic library, an executable, or an object file

You'll note that the word "package" and "module" in particular are very similar.
A package has uses a hash for caching/download purposes. A module, however, is
really interested on what you can import with the `@import` keyword. This will
remain confusing when using 0.11.0, because even if you understand the difference,
the terminology has not been fully updated in the standard library.

What happens at `zig build`?
----------------------------

With terminology behind us, let's cover the mechanics of the `zig build` command.
Conceptually, the following process is followed:

1. `build.zig.zon` file is read. Packages described in the file will be fetched
   if they do not exist in cache.
2. A `build` executable (literally named "build") will be compiled
3. The build command will be run. The command will create a directed acyclic graph
   of "Steps" that must be executed to accomplish the end result(s). The steps
   will then be executed in what is termed a "make phase".

This means that zig code is run at three stages in the build:

1. Compile time code during the compilation of the `build` executable
2. Run time code during the "build phase" while running the `build` executable
3. Run time code during the "make phase" while running the `build` executable

### Step 1: Package fetch

Currently, step 1 includes package fetch. This process reads `build.zig.zon`,
and I do not currently believe there is a way to override this name. Currently,
this process eagerly fetches all URLs embedded in this file, then applies
a hash algorithm to all files unpacked. We are in the MVP Package Manager
territory here, so things are rather fragile. For instance, [tarballs support
a limited subset of capabilities](https://git.lerch.org/lobo/aws-sdk-for-zig/commit/eb91d40edf9ebb7b47d8fd958762b0341a6be2b6),
and the internal file layout is [hard coded to strip 1 level of directories](https://github.com/ziglang/zig/blob/0.11.x/src/Package.zig#L696).
If you're using GitHub, this is just fine. For those pushing the limits, be
aware of these limitations, and especially that most of these internals are
likely to change.

### Step 1: Package fetch...the big lie

Packages are packages, but with `build.zig.zon`, they are not just packages. They
also become modules. The package name defined in `build.zig.zon` also becomes
a magical module with a root source file identified as `build.zig`. This can
cause confusion on terminology, but is also **intended** and **super handy**.
It is also super confusing, because if I have a dependent package in
`build.zig.zon` called "dep", and that package exports a module called "dep",
I can `@import("dep")` in my `build.zig`, but unless I call `exe.addModule` or
`lib.addModule` in my build.zig, the same `@import("dep")` in my actual code
will fail. This is super-obvious if and only if you understand pretty much everything
I've written above this paragraph.

> As a side note, packages are stored in the global zig cache. On Linux, this
> is, by default, `$HOME/.cache/zig`. Inside that directory, a directory named
> simply "p" holds the packages. In there, you will see directories named by the
> hash that matches `build.zig.zon`. The reason all this is important, is that
> once in the cache directory, the hash is not verified again. This enables
> us to go muck around with the files in there without penalty...a very handy
> fact to know if you're debugging some package's behavior when it is used
> in a consuming application!

Because there is no way in the build itself (step 2 of our `zig build` procedure)
to use a module, we are given a way here to access our dependency, or at least
the `build.zig` of a dependency. This allows build time access to our packages,
which we can then leverage to do such things as "reference a dependency, and
use their build helpers to tweak or reconfigure our own build". This enables
some powerful capabilities, as I will show in my example below.

### Step 2: Compiling the `build` executable

What's in `build.zig` is pretty boilerplate. However, there is no `main()`
function. If this is an executable, where is `main()`? This could be hard coded
in the compiler, but zig finds a different way. You can technically override
this with command line flags, though you [don't](https://github.com/zigtools/zls/issues/1020)
[want to](https://github.com/search?q=repo%3Azigtools%2Fzls+build+runner&type=issues).
Running `zig build` will create a build with the main entrypoint defined in
[build_runner.zig](https://github.com/ziglang/zig/blob/0.11.x/lib/build_runner.zig),
which subsequently references your own `build.zig`.

Because zig code always has comptime also as a possibility, we end up with 1
comptime execution and 2 runtime passes logically (as described below). As an
aside, comptime in zig must support all compilation targets. Zig does not want
compilation to be OS or Processor specific!

### Step 3: Running the `build` executable.

With the executable compiled, the last step is to run the build. Ultimately,
this executes the code in `build.zig`. This code doesn't actually do anything
tangible, however. What it does it provides a dependency graph, to let the build
know that when a user provides a target/goal/step of, for instance `run`, we
should find that run step, then back track to determine all the prerequisite
steps needed (and in what order) to make the end goal work. Let's look at a
quick example. To follow along at home, simply `zig init-exe` and look closely
at `build.zig`, lines 32-53:

```zig
    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = b.addRunArtifact(exe);

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
```

The comments are added by `zig init-exe`, but if you're trying to get some
stuff done, you may not have taken the time to really think about it. Let's
start from the top. `zig build` does not have any step targets. So, it will run
the "install step" by default. It is the same as `zig build install`. You can
actually put as many build steps as you'd like on the command line. `zig build
install uninstall run test` is perfectly valid. What we show above, though, is
the code for the run step. The run step itself does nothing put put 'run' on
the help menu and makes it a valid target. Again, this ***does nothing***. What
actually makes it do something, is the very last line of code. That line of
code connects the command line step to the command that actually runs the code.
The code can't run without the code being built, so we see that
`run_cmd.step.dependOn(b.getInstallStep())` to let the build system know that
a) first we install (compile and put the binary in the output directory), b)
then we run, then c) we "do nothing" but complete the run step.

Only after the graph has been completed, the build will determine (starting
from the command line), which steps the user is requesting, and will use the
graph to define an ordering. With zig 0.11.0, steps can now execute in
parallel. The actual execution of these steps is considered the `make phase`
and runs the required steps, in order, based on the user input. As an example,
`zig build` implies the "install step". But a common command would be `zig
build run`, that has at its goal to perform the `run step` (which depends on
the install step). Again, a user is **not** limited to a single end goal, so
you can, for instance, specify `zig build test run` on the command line.

If you're doing a lot of fancy build stuff, one frustration might be the use
(or lack thereof) of modules in the build phase. The lib/exe `addModule`
functions are for the compilation of the target code, not for the build itself!
This is mostly ok, as a package has a module available at build (via build.zig),
so defining a `pub fn` in build.zig can then reference whatever you want.
However, it currently limits chained dependencies, so an `@import` of `dep-of-dep`
in package `dep` is not possible in the main project unless `dep-of-dep` is also
in the main project's `build.zig.zon`. I am fairly confident this will be fixed
(maybe while introducing other problems?) in zig 0.12.0.

An example: A "universal lambda function"
-----------------------------------------

I have created a package [universal-lambda-zig](https://git.lerch.org/lobo/universal-lambda-zig)
that leverages these features to allow minimal changes to a typical console
"hello world" that can be run in multiple environments. This includes all
zig targets, including WASM/WASI, AWS Lambda, my own home grown web server,
and Cloudflare. These environments are all wildly different from each
other. Consider:

* console exes run `main()` front to back, then exit
* WASM/WASI do the same as above, but are highly sandboxed, and have no threading
* AWS Lambda runs functions based on a bootstrap executable that, when run,
  makes a web request to a server that issues instructions. In the universal
  lambda implementation, this bootstrap process calls the client code in process
  (no `exec` calls).
* My own web server relies on discovering a function in a dynamic library, then
  calling it
* Cloudflare relies on a JavaScript wrapper that calls a WASM/WASI file and
  marshalls the appropriate input/output/arguments/environment

By adding a reference into `build.zig.zon`, then calling a "configureBuild"
function, the universal lambda project has a view to the build process, can add
modules, etc. From the application's main source file (by default `src/main.zig`),
you can access the universal lambda module and register your handler. From there,
the package and module can take over:

### Console application and WASM/WASI

All the universal lambda package needs to do here is get pass control back
to the application. The build:

* Adds modules for use by the application

The module:

* Reads standard input
* Calls the handler
* Writes handler output to standard output

WASM/WASI is just slightly different, because the module won't compile by default
due to the fact that `std.http.Server.Response` is used in the event handler
context object. A little comptime magic is used to escape that problem.

### AWS Lambda

The design of AWS Lambda is pretty unique. Here, we need to take the application's
handler and bundle it with an http client to deal with all the Lambda internals.
To me, the service seems over-engineered, but I'm not on that team and I'm sure
they have good reasons for all that. Anyway, this was my original goal, so it's
still full of hacks and learnings. The biggest of which is that the build portion
is actually using the AWS CLI and not making good use of the make phase, at all.
There are current package manager limitations with transitive dependencies that
are preventing me from putting this into the ideal state. Also, AWS doesn't yet
universally support TLS 1.3, which is the only secure protocol supported by the
http client in zig 0.11.0. I plan to re-address this with zig 0.12.0, by which
time I believe both issues will be fixed. In the meantime, it's hacky, relies
on the AWS CLI, and is coded to not even show the options if you are running
anything other than Linux (other POSIX OS's like mac, *BSD, etc should work,
but hasn't been tested). The build:

* Adds modules for use by the application
* Sets up steps to package, set up permissions, deploy, and run the function
  using `addSystemCommand` which creates steps in the graph to run system
  commands. This is how we get to the AWS CLI

Fundamentally, in lambda, `bootstrap` is still a command line executable, so
we don't need to do any magic there, but we do need to insert a whole http thing...

The module:

* `run` in the module, which is called by the application, becomes 500 lines
  of code and tests designed to integrate our application to the AWS Lambda system.
  It spins up a loop, requesting data from a web server (endpoint is passed
  via environment variables). Full docs are here: https://docs.aws.amazon.com/lambda/latest/dg/runtimes-custom.html
* When data is returned from Lambda's web server, the module passes that data as
  event data to the application's handler, and provide the raw response object
  as context
* After the handler returns, we take the response and post it to the appropriate
  Lambda endpoint
* Errors are caught and similarly posted to the Lambda error endpoint
* Loop continues

### Flexilib

The design of my personal web server is to allow a set of independently developed
(but trusted) projects to plug in as a single process. The goal is to eliminate
managing lots of processes and their associated memory requirements by allowing
me to slap together a bunch of disparate microservices and run them together.
There is no assumption of security boundaries within the system. It is similar to,
but more flexible than how Redis handles modules. This is a little different,
because in this case, our package needs to modify the build much more
substantially. The build:

* Adds modules for use by the application
* ***Changes*** the install output from an executable to a shared library
  (note - I think this is a mistake, and ultimately the package should probably
  add an **additional** build artifact. This would allow things like `zig build
  run flexilib` to work properly)
* ***Changes*** the root source file for the build to its own flexilib.zig
* Adds a module for the application code. flexilib.zig can then utilize that module
* Adds code to be compiled into the library. The code exports the necessary
  flexilib functions. Those functions handle marshalling into more zig-friendly
  data formats (flexilib uses C calling conventions)


The module:

* Doesn't truly exist in the traditional manner at the moment. It really
  doesn't do anything other than exist to allow the build to work
* The request handler ignores the application's main function and just looks
  for a function named "handler". I think this could be fixed by providing a
  run function, calling the application's main function on first use, then
  utilizing our own run function to simply set a variable for the handler.
  But this remains a TODO for now.

### Cloudflare

There are a couple options for Cloudflare worker support. Cloudflare workers
operate in V8 sandboxes (called "isolates"). Since we're in V8, we're firmly
in web technology land. This gives us the following options:

* Compile zig to Javascript. I don't know if this has been done, but it seems...rough
* Compile zig to wasm, provide a Javascript wrapper to wasm functions, and run
  the handler through this infrastructure. This...seemed interesting and I did
  consider it. Fundamentally, it's not too different from what we're doing with
  Flexilib above. Compile the code as a library, expose the application's handler
  as a wasm export, then put some JS goo around it.
* Compile zig to wasm/wasi, and use Cloudflare's experimental wasi support
  to run it. This option was ultimately chosen, as it was much more straightforward.
  The main drawback here is the experimental tag.

With the option chosen, the implementation was nearly identical to just a straight
WASM/WASI compile from our first foray above. The primary changes were in the
build:

* Adds modules for use by the application
* Adds a Cloudflare deploy step to the dependency graph, which:
  * Modifies a built-in wrapper Javascript `index.js` to refer to the
    build output's wasm file
  * Combines `index.js` into another wrapper that has the necessary wasi
    interface goo (leveraged from Cloudflare's Wrangler and cloudflare wasi
    projects)
  * Determines the appropriate Cloudflare account
  * Uploads the worker, along with `memfs.wasm`, needed by Cloudflare's wrapper
    and the build output wasm file to Cloudflare
  * Enables the worker if needed (only necessary if the worker is being created)

This took quite a bit of work, but was straightforward in terms of a) understanding
the apis and interactions and b) understanding the structure of various open
source Cloudflare projects.

The module is identical to the console application above:

* Reads standard input
* Calls the handler
* Writes handler output to standard output

Conclusion
----------

While the zig build system and package manager are powerful, there remain some
edge cases. I was pleasantly surprised how functional and flexible the system
was. In terms of "MVP", I'd say that the bar has been hit. There are two
primary issues remaining:

* Transitive dependencies, especially at build time. My Cloudflare build process
  for example, really should be another package. The problem is that I can't really
  do a package of a package, at build time, without adding the dependency directly
  to the application code. Ultimately, the application's `build.zig.zon` currently
  requires a dependency for the flexilib interface, which is the result of this
  issue and shouldn't be needed. Zig 0.12.0 is addressing this
* Pathing problems. Adding the package's module for use of the application
  requires an "anonymous module", with the source file residing in the package
  just fetched. One could argue that this should be a recognized use case, and
  it may be in the future. In the meantime, I need to know the location the
  package's files without relying on knowledge of the zig cache or the hash
  of the package. Right now, there's a bit of an ugly hack that triggers the
  build system to initialize the correct dependency, then pokes into the file
  system looking for a file we recognize in the dependency's location. The
  hack itself is a bit less hacky in 0.12.0, but the whole thing makes me want
  to take a shower.

Outside these two issues, I find it amazing how much I was able to twist and
turn the build and runtime behavior from code outside the application. Quite an
MVP, and looking forward to 0.12.0!

For further reading on zig build system, take a look at: https://zig.news/edyu/zig-package-manager-wtf-is-zon-2-0110-update-1jo3

The article takes a slightly different angle than I have here. I have also
heard that with 0.12.0, we are likely to get more documentation around the build
system. Definitely looking forward to that!
