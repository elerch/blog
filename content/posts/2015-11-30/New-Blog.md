+++
date = "2015-11-30T09:22:24-08:00"
draft = false
title = "New Blog"

+++

I am transitioning to a new blog host and new, well, everything
regarding my blog. I had the following goals when creating this new blog site:

* Remove dependence on blogger.com
* Change the url. It's now more common to **not** have "blog" in the url
* Reduce the page size/number of requests
* Improve the speed of the site (see above, plus CDN)
* SSL everywhere

This is still a work in progress and the styling will be updated
moving forward, but I'm a fan of dark themes, so this is roughly where
I'm going.

As part of this change, I've embraced [hugo](https://github.com/spf13/hugo)
as a static site generator. I like hugo for a number of reasons:

* It's fast
* It requires no third party software (like [Jekyl](https://jekyllrb.com/) requires Ruby). Important since I might author in Windows, Mac, or online
* It's written in [golang](https://golang.org/), which appeals to my inner tech core
* It's easy to use, especially with github gist support in 0.15!

My old authoring process was completely online in blogger. This site
is now in [github](https://github.com/elerch/blog), so I can still author
online or offline at any time. Publishing is still a work in progress
and will be fodder for another post.

# Things I'm thrilled about

The size/speed of the site is fantastic. When I host the site I'll
put things on a CDN as well, but I'm glad to go from 94 requests (and console errors):
{{< figure src="/posts/2015-11-30/before.png" link="/posts/2015-11-30/before.png" alt="Before" >}}

To 2:
{{< figure src="/posts/2015-11-30/after.png" link="/posts/2015-11-30/after.png" alt="After" >}}

I also get to remove the dependency on [SyntaxHighlighter](http://alexgorbatchev.com/SyntaxHighlighter/manual/files/shcore.js.html).
This is a great library but loading it all the time when I just needed
it for certain posts was a bear. Instead, I'll be using [Github Gists](https://gist.github.com/).

# Things I'm still tweaking

* Font. I wanted to avoid a web font due to the extra request,
but I'm not sure that's possible. I'm just not happy with Arial/Verdana or Georgia on the Serif side
* Sizing. I increased the font size from the original [gindoro](https://github.com/cdipaolo/gindoro)
theme when tweaking my [fork](https://github.com/elerch/gindoro). Since the point is
to have a blog, and the point of a blog is to read it, why not make the
size relatively large? Anyway, I'm still tweaking spacing and such as
a result.
* Flair. The site might be minimal, but maybe a bit too minimal.
* Comments. I'd like to enable comments without a lot of ceremony.
Currently I don't have comments, but am considering [Disqus](https://disqus.com/) or [Discourse](http://www.discourse.org)

# Things I want improved

I'd like for hugo to support explicit image sizing and relative urls
for images. On this post, I had to specify the full public url on the
image tags, and height/width directives do not pass through. Since hugo
is open source, that would be a great pull request in my spare time.
