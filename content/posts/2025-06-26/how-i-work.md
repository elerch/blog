---
title: "How I work"
date: 2025-06-26T16:58:11-07:00
draft: false
---

How I work
==========

I had someone ask me a year or two "how do you work, exactly", because my setup
was strange and new to them. It's actually an interesting question, and it's
evolved over more time than I'd care to admit. Because it evolves, this post is
a snapshot in time, representing my setup as of mid 2025. I'll start with an
overview, before getting into the nitty gritty details.

Overview
--------

At work, I use a Windows virtual machine, using technology from [Amazon Workspaces](
https://aws.amazon.com/workspaces-family/workspaces/). This is a special Amazon
version we call "corporate workspaces", and gives me the freedom to run whatever
I need to as a client. I originally embraced it due to conflicts between
[Docker](https://www.docker.com/) and the Amazon VPN, but I found it useful to
use a desktop at home, and laptop when traveling.

At home, I have a primary desktop I use, and a couple secondary desktops that
are in use by other members of my family. One of these runs Windows for my son
to run some games, and the others all run Linux. I use the Windows desktop for
games sometimes, though I'm starting to play games on Linux. My work laptop is
a Mac that I use primarily for customer demos, testing, and bring it with me
occasionally traveling for the same reasons.

The rest of this post will primarily focus on Linux, although most of what I
write will also apply to Mac. Theoretically other operating systems such as
FreeBSD, but I haven't tested this, and my bootstrap script (more later), would
definitely need changes. Philosophically, I try to stick to as much
open source tooling as possible, and I value the ability to quickly get to
a familiar environment, and update to my latest set of tools, with no surprises.
Sticking to a combination of scripting and open source tools help immensely.
However, for work, this isn't possible and as a result, I don't even try.
Avoiding Outlook for instance is possible at Amazon, but it is too much work,
and I couldn't realistically function without Word and PowerPoint in my role.
My corporate workspace serves as a good partition, however, so I lean on that.
To have as much portability/flexibility, I want to be able to have the same
set of tools everywhere. Sometimes that means over ssh, so over time I've become
focused on CLI/TUI workflows.

With this in mind, my general approach to using software is the following
hierarchy, rated in order, so I will look for software starting at the top
of this list, and traverse down, stopping as soon as a suitable option is
available:

* Open source CLI
* Open source TUI
* Open source GUI
* Proprietary CLI
* Proprietary TUI
* Proprietary GUI

Because proprietary software is...proprietary, I trust it less, especially in
recent years as telemetry has gotten commonplace, and I just don't feel like
people should be recording my every move. Also, I can't tell what else the
software might be doing, and while Android and iOS have deep permission structures
with user consent, no such system is built into desktop operating systems. So,
with very few exceptions, I sandbox proprietary software in one of the following
ways:

* [Flatpak](https://www.flatpak.org/)
* [Distrobox](https://distrobox.it/)

At this time of this writing, I **believe** the only exception to the Flatpak/
Distrobox sandboxing is NVidia GPU drivers. And the only distrobox usage at this
time is for Amazon Workspaces. However...I do have one piece of Amazon software
(an unreleased product), installed through more native means. This is not
open source, but as an employee I actually do have access to the source code,
so it's mostly aligned with my philosophy.

For open source software, I will install CLI/TUI tools through [nix](https://nixos.org/),
and GUI tools through the following means, usually in this order:

* nix
* [AppImage](https://appimage.org/)
* Flatpak


I do not generally script most of my base OS installations, but I have [scripted
out base utilities](https://emil.lerch.org/bs.sh) to manage the rest of my setup.
This includes my home directory and configuration, including nix configuration
(but not the nix utility install). Using a random linux machine with internet
access, I can be productive with most of my tools after downloading and running
my bootstrap script. To get all the CLI/TUI tools I'm used to using, I can install nix
and type `nix-configure`, and any updates in my configuration are handled by
`mr up && nix-configure`. AppImages are installed via nix, and flatpak...I just
have a text file with common stuff. Workspaces is a manual process for the moment.

Nix focuses on determinism, so by centering as much on nix as possible, I
minimize the amount of surprises in my life. Moving from machine to machine, as
long as my configuration repositories are at the same commit, all my tools
will be at the same version, and I'll have all the same bugs/features in my tools
everywhere. For operating systems, I stick to Debian where possible, and install
as little on top of the base system as possible. The last time I rebuilt,
I captured a text file with the apt packages I install - it's about 26 items
to handle local hardware and a base X Windows configuration (I have not switched
to Wayland). However, my laptop runs [PopOS!](https://system76.com/pop/) which
is much more maximalist. I don't really care, because nix-installed tooling
takes precedence over whatever was installed out of the box.

How does this work? Part 1: Bootstrap and configuration
-------------------------------------------------------

Starting from the beginning, my bootstrap script, which hasn't changed since
2021, installs some important base utilities:

* [mr](http://source.myrepos.branchable.com/?p=source.git;a=blob_plain;f=mr;hb=HEAD)
* [vcsh, pinned to a prior commit](https://raw.githubusercontent.com/RichiH/vcsh/66944d009b8df64e0b2ddae757a83899ff8684b7/vcsh)
* git
* Other dependencies, if necessary

The other dependencies include curl (to download mr/vcsh), and perl (which mr uses).
vcsh, at the pinned commit, is a set of shell script. Beyond that commit it has
changed architecture. These two tools are critical to all my configuration, and
roughly follows the pattern outlined in the [advanced configuration of this
blog](https://germano.dev/dotfiles/#mr). tl;dr, vcsh allows me to manage
multiple git repositories in the same directory (here, `$HOME`), and mr
allows me to quickly manage multiple repositories in that directory. While I
end up with a lot of repositories (mr manages 39 repos at the time of writing),
I like the fact that I have a configuration repository for each tool I use,
rather than a single `dotfiles` repo as many recent tools [guide you to
using](https://www.chezmoi.io/quick-start/#start-using-chezmoi-on-your-current-machine).
I'm likely swimming upstream a bit here, but I am mostly happy with my setup.
My repos on github all have the prefix `vcsh_`, which was a mistake, and
[GitHub has special treatment for a `dotfiles` repo](https://burkeholland.github.io/posts/codespaces-dotfiles),
which is not incompatible with my setup, but I have not configured this as I
am not a huge codespaces user. I actually like the concept of codespaces, but
I always have my tools at my disposal. ;)

So...what are in these 39 repos? There are a few raw repos outside vcsh for things
like liquidprompt and zsh autosuggestions, but primarily these are configuration
files. Right now, I have 32 configuration repositories:

* Xmodmap
* Xresources
* alacritty
* aliases
* asoundrc
* awsaliases
* bash_profile
* bash_prompt
* bashrc
* commonrc
* desktop
* dunst
* exports
* fehbg
* functions
* ghostty
* gitconfig
* gtkrc-2.0
* i3config
* i3status
* liquidpromptrc
* mdlrc
* mlterm
* mr
* muttrc
* nix
* tmux.conf
* vim
* xinitrc
* xprofile
* zellij
* zshrc

Many of these I haven't touched for years. Several of them are for programs
I don't currently use (e.g. Alacritty). But they're all small and self-contained,
and if I cared, I could configure this out of mr easily enough. My bootstrap
clones the myrepos repo, then myrepos can do the heavy lifting from there.

How does this work? Part 2: Working with shells
-----------------------------------------------

mr manages my shell configuration. I prefer [zsh](https://en.wikipedia.org/wiki/Z_shell),
though I don't actually use many of its special features, but I love the history
sharing. However, zsh isn't usually the default when I'm encountering a new machine,
and I want to get from 0->productive as quickly as possible, so it's important
to me that bash work just fine. Today, bash and zsh look and feel nearly identical
to me.

The way this works is through the use of a common file that works for both
bash and zsh. Both `.bashrc` and `.zshrc` source this common `.commonrc` file,
and only commands that are specific to one shell or the other get put into `.bashrc`
and `.zshrc`. A nice effect of this is that when some utility I'm experimenting
with decides to spam my login scripts, it's another quick indication that
my files have been trashed. Right now, my bashrc is only 16 lines long, and
my zshrc is 41 lines, with nearly all my logic in commonrc. My other indication
is that all these files are in source control, so I can tell by vcsh that something
has been touched.

To handle local customization to my shells that I don't want propagated, my
`.commonrc` file ends up looking for and sourcing `.extra` and `.extraextra`
if they exist. These do not go into source control. The reason for two files here
has to do with `$PATH`. The first `.extra` file is designed to be the last thing
to mess with that variable, then `.extraextra` can be whatever else is necessary.

The rest is a bit boring as the script sets preferences, always following a
"if this tool is installed, prefer it, else look for the next tool" approach.
So things always work, but after I install a bunch of my favorite tools, I'll
get more and more power. `nix-configure` gets nearly all my favorite tools installed,
but nix is not worth bothering with on disposable cloud instances, for example,
so sometimes I'll `apt install` one or two tools I want, and let my rc scripts
get them preferred. Basically, this is [progressive
enhancement](https://en.wikipedia.org/wiki/Progressive_enhancement) adapted to
the command line.

The last thing of note here is that there is a great set of zsh functions/helpers/
plugins/themes called [oh my zsh](https://ohmyz.sh/) that my rc scripts use.
However, I found that oh my zsh almost works in bash as well. I have refactored
this so it [works on both shells](https://github.com/elerch/oh-my-bash-zsh), and
use my repository instead.

How does this work? Part 3: Getting my normal programs onboard
--------------------------------------------------------------

So far, I've covered basic bootstrap through mr. This gets me access to any
"unixy" terminal on Mac, Linux, BSDs, and even [Termux](https://termux.dev/en/)
on Android works after a few `pkg install` commands. I haven't tried but it
would likely work on [Cygwin in Windows](https://cygwin.com/) as well. This
works well because everything is text files and shell scripts, at least up
until now.

So...where do binaries come in? Today, this is through Nix. Before I extol the
virtues of Nix, I first want to discuss my severe discomfort with the tool:

* It is an OS (NixOS), a package manager, and a programming language.
  This causes a ton of confusion
* The sands shift...a lot. I am not a heavy user, and generally when I ask
  a search engine or AI how to do something, probably 90% of the time, the nix
  CLI will tell me I'm using a deprecated way of doing it. I love that nix
  keeps old versions of its reference manuals around, but often times the first
  search result will take me to "the documentation", but it's an older version
  of the docs that again...leads me to deprecated ways of doing things.
* Corollary to the above...there are two ways of doing things today between
  normal things and Nix Flakes. Flakes are super-useful, especially doing
  development. It's [stable](https://determinate.systems/posts/experimental-does-not-mean-unstable/),
  but requires one to add "experimental features" configuration to use.
* It's not kind to your machine. Nix package search is unusable without modern
  equipment, and I've had it consume all the memory on my low end equipment.
  Today, I consider nix search unusable (nix-search-cli works well, but requires
  Internet access). The nix store loves storage space as much as nix native
  search loves RAM, and it's super-easy to download the Internet and thrash
  your CPU when you install new packages (more on this later).

With that out of the way, why do I use nix (the package manager...and as little
of the programming language as possible)?

* All the machines I use, I know I get the same version of the software everywhere
* I have really good confidence everything will work
* Development environments can use nix, and I really like this workflow
* It handles much of the "find the right binaries for this system and wire it up"

This said, I do one "unnatural thing" with nix. Because NixOS doesn't really
like the way AppImages work, they instead [extract and wrap AppImage files
](https://nixos.org/manual/nixpkgs/stable/#sec-pkgs-appimageTools) with a fairly
involved process. I don't really have time for that, I don't use NixOS, and
don't really care to go through whatever work it would take to play nice. The
AppImages are all controlled by hash anyway, so they're still deterministic. With
that in mind, I have a few flakes that [avoid the wrapper, and just slap the
AppImage into place](https://git.lerch.org/lobo/chawan-flake/src/commit/974100f81d4377a9265d3ab6bf0f3d2c4b4f7e4d/flake.nix).
I'm sure purists hate this...but I'm a bit more pragmatic, and it works for me.

So...if I am going beyond "just get my shell configured in my way" on a machine,
my next steps after bootstrap + `mr up` is:

* Install nix (I use single-user, but I don't think it matters)
* Run `nix-configure`

`nix-configure` is a script that lands in `~/.local/bin`, and by default installs
all the things, subject to "I don't want monstrosities copied down from the
internet". There is a command line option on the script to say, "no, really,
download the Internet please", and that will get all the things that require
X Windows, etc. The difference between light and heavy is purely subjective.
I've also recently learned about nix builders and substituters (cache), and have
begun configuring them in. This, I hope, will help substantially with low-powered
machines like setting up and using a Raspberry Pi. Once I feel more comfortable
with this setup, it probably warrants a whole different blog post.

This works great for 95% of what I need to do. One sore spot for me is vim
(actually, [neovim](https://neovim.io/)). The neovim plugins I use always seem
to throw various errors, because they're not also locked into my system. This
is completely doable, but I have not gone through the effort of solving it.
Usually, I put up with the errors for a while, then get frustrated and try to
figure out what broke. Usually, it's a new change in a plugin that I haven't
bothered to update the corresponding config. Many times, it's some combination
of the following vim commands that fix the problem:

* `:PlugInstall`
* `:PlugUpdate`
* `:COQdeps`
* `:TSUpdate`
* Lastly, waiting a while while nvim-treesitter trashes your machine
  compiling a lot of language files
* Occasionally, `:checkhealth` tells me something useful

Treesitter is awesome, but walking up to new machines can be painful. It also
is usually the thing that messes with me, and usually I end up finding some
random breaking change they made in a GitHub issue or discussion, etc. For
instance, just now prepping this post, I learned in the last two months, treesitter
team decided to change the primary branch (but it's not yet the default on
GitHub), and changed the name of the configuration file that you need to
require in lua. Both of these seem fairly arbitrary breaking changes, and
both of which need detective work to track down why, once again, everything
is just broken.


How does this work? Part 4: Software development
------------------------------------------------

If you've read this far, and you have looked at [my nix configuration
repo](https://github.com/elerch/vcsh_nix/blob/master/.nix-flake/flake.nix), you
may have noticed the complete lack of any programming languages being installed.
I work in [Zig](https://ziglang.org/) a lot, and from time to time, I work
with go, Java, Python, Rust, Node, or a host of other things. So...how does
this work?

Enter [mise](https://mise.jdx.dev/). This is my newest addition, but it replaces
a similar tool called direnv. They both do the same thing, but I think mise
does it better. When I change directories, if mise sees a configuration file
in that directory, it will adjust the paths, set up environment variables, or
run Nix flakes (though that's a little unnatural at the moment) to get everything
set up the way that I need them for that project. Direnv just installed the tools,
but with mise, I have it configured to just warn me if a tool isn't installed,
so I don't have surprises if I'm just poking around, and I can choose to install
with `mise install` (this just looks at the configuration and installs/uses
the correct tools for the directory I'm in.

This works mostly great. One exception, is that I use vi for development, so if
for some reason, I would rather use a graphical editor (usually something like
VS Code, out of a Flatpak sandbox), well, this is a whole different problem.
Flatpak has "SDKs" that can be installed and manually configured, but right now,
it's kind of a pain and it's also too niche for me since I usually am at the
command line using neovim. So I ignore it.

Overall
-------

Is this perfect? Not by a long shot.

* Updates sometimes require `mr up` (to update mr repo itself) followed by `mr up` (to update the vcsh repos)
* Bouncing around machines often mucks with config, which then have conflicts I have to resolve on `mr up`
* I need a recent (within the last 4 years or so) version of git installed by the
  bootstrap process due to my `.gitconfig`
* Vim plugins (well, let's be honest, 99% just treesitter) are a hot mess that I
  don't have under control
* AppImage considerations mentioned above
* Nix still has a lot of downsides, and I haven't even touched on the pain that
  I find Nix, the programming language
* Mise + nix flakes are still emerging

But when it works, and actually, it works most of the time, it is pretty amazing.
All my configuration and tools are there, ready for me, and I can be productive
in less than a minute.
