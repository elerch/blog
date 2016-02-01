+++
date = "2016-02-01T11:54:14-08:00"
draft = false
title = "blog comments"

+++

I've decided to add [Disqus] comments to the site. Having a blog without
comments is just...not a blog. That said, I'm not particularly happy with
the amount of overhead it adds to the page. My base configuration (no
images, no comments) involves a total of two requests to the site for
full rendering (three if you count favicon business, which I don't). 
The blog is delivered via AWS [S3] and [CloudFront], which gives me [CDN]
capabilities. Since I'm doing static generation, the site is pretty quick.
With Disqus, my request count balloons to 33 requests with a default
Disqus setup. I went through Disqus and turned off as much tracking
and things as I could, but I'm still at a 26 request baseline. 
Hopefully there are some settings to make this more minimal, since I'm
new to Disqus I haven't seen what I can tweak.

To keep the site minimal, I've configured Disqus only on the full post,
**not** the summary page. As an aside, I also don't run any tracking
software (e.g. Google Analytics). First, I don't want the overhead, and
second, I don't care to track my readers.


[Disqus]: https://disqus.com
[S3]: https://aws.amazon.com/s3/
[CloudFront]: https://aws.amazon.com/cloudfront/
[CDN]: https://en.wikipedia.org/wiki/Content_delivery_network
