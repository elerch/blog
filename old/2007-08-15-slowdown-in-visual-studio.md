+++
title = "Slowdown in Visual Studio"
slug = "2007-08-15-slowdown-in-visual-studio"
published = 2007-08-15T16:24:00-07:00
author = "Emil"
tags = []
+++
The other day I had a sudden and mysterious slowdown in compile times
within Visual Studio. When I didn't see an associated CPU spike during
the compile, I increased the verbosity of the compiler and checked the
output, only to see it pausing at a file copy.  
  
Here I had added my project's SQL Express database to a library
directory rather than the web site, so studio dutifully copied the
database over. All this was fine, except that during development, I bulk
loaded a ton of data, and the file was now about 240MB.  
  
Note to self...don't copy 240MB database files as part of your compile.
;-)
