+++
title = "Probing support for architecture-specific native DLLs in .NET"
slug = "2014-06-13-probing-support-for-architecture-specific-native-dlls-in-net"
published = 2014-06-13T13:50:00.001000-07:00
author = "Emil Lerch"
tags = []
+++
[![](/posts/2014-06-13/thumbnails/2014-06-13-probing-support-for-architecture-specific-native-dlls-in-net-2500121593_7ecf3c51a5_z.jpg)](/posts/2014-06-13/2014-06-13-probing-support-for-architecture-specific-native-dlls-in-net-2500121593_7ecf3c51a5_z.jpg)  

Or...How I've tamed the Oracle beast
------------------------------------

Over the last couple decades, very little has changed with regards to
Oracle client software. Install hundreds of MB of code, update
network/admin/tnsnames.ora, and finally you can make a database
connection.

  

With a little (well, a lot) of elbow grease, I've made it possible for
.NET applications to run as "AnyCPU" and work in 32 or 64 bit process
space on either a 32 or 64 bit OS. It's still an 84MB download (mostly
due to a large dll containing all of Oracle's error messages), but it's
bin-deployable, and only 20MB more than the combination of installing
each of Oracle's "Instant Lite" processor-specific installation
packages. More importantly, since it's bin-deployed, you can have 32 and
64 bit processes running side by side on the same machine, something
that's been problematic to do with full client installs.

  

The fruits of my labor are now on the the NativeProbing repository on
GitHub: <https://github.com/elerch/NativeProbing>. The focus of the
repository is not on Oracle per-se, but my goal was to achieve XCopy
deployment for Oracle connectivity without massive installs or gnarly
configuration.

  

.Net assemblies are loaded through the Fusion process, and typically
follow a strict path through an AnyCPU chain, 64 bit chain or 32 bit
chain. If using the &lt;probing&gt; element to alter flow and add
platform-specific assemblies, the first time .NET hits an assembly not
matching the underlying processor architecture you'll get a
BadImageFormatException. This is especially nasty; running 32 bit on a
64 bit OS is not enough to see the exception, rather, you need to be 32
bit on a 32 bit OS with your 64 bit assemblies listed first in the
&lt;probing&gt; directory list. Therefore you need to hook into the
assembly resolution process itself similar to this
process: <http://stackoverflow.com/a/9951658/113225>

  

However, native libraries contain a special challenge. A different
Windows process kicks in when loading a native library, and in the case
of Oracle, the .Net assemblies used load native assemblies. My code on
GitHub therefore uses the SetDllDirectory kernel32.dll native function
to add the correct platform-specific directory to the list of paths to
check. The two techniques in concert work to automatically load the
appropriate DLLs.

  

More details of my travels are on
[GitHub](https://github.com/elerch/NativeProbing), but the bottom line
is that I have code that can augment the probing pipeline to include the
correct architecture specific DLLs. This can be used for any
architecture-specific DLLs with matching version numbers.
[SQLLite](https://system.data.sqlite.org/index.html/doc/trunk/www/downloads.wiki) is
a possible candidate for using a similar technique.

  

Of course, Oracle does **not** have matching version numbers, which is
where part two of this story unfolds. To make Oracle.DataAcess.dll work,
I had to resort to extreme measures. The details are on the
[OracleDLLHacking.md](https://github.com/elerch/NativeProbing/blob/master/AnyCPU/OracleDLLHacking.md)
file in my repository, but the high level process was this: 

  

1.  Disassemble Oracle.DataAccess.dll with ildasm
2.  Remove the public key token and change the version number in the IL
3.  Reverse the branch logic where an exception is thrown if the
    assembly is "incompatible" with the native code
4.  Reassemble the library with ilasm
5.  Repeat for the other processor architecture
