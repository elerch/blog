+++
title = "Back in a flash"
slug = "2006-08-15-back-in-a-flash"
published = 2006-08-15T12:02:00-07:00
author = "Emil"
tags = []
+++
There's a new performance feature in Windows Vista that has piqued my
curiosity. The feature is based on pre-fetching (where programs are
loaded into memory or in an area on your disk before you run it, because
the system knows you usually run the program).  
  
There are some other enhancements to the pre-fetch feature, but the
interesting one to me has been coined as
[ReadyBoost](http://articles.techrepublic.com.com/5100-10877_11-6060817.html).
This feature uses flash memory (like a USB drive or compact flash card),
and loads the pre-fetch information on the memory. The concept is that
this will make your system faster.  
  
Knowing that USB drives are slower than hard drives, I found the claim
curious. It turns out that the way they access the data must be in
smaller chunks. While flash memory is slower, the access time is much
faster. There are several assumptions that vary the analysis fairly
significantly, but my most pessimistic assumptions say that any file
smaller than 100k is better off on flash memory. My most optimistic
assumptions say that any file smaller than 500k is better off. Over
those sizes, a hard drive will be faster (assuming that you keep your
disk [defragmented](http://en.wikipedia.org/wiki/Defragmentation)).
