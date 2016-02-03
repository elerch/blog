+++
date = "2016-02-02T16:53:08-08:00"
draft = true
title = "index.html behavior with S3 and Cloudfront"

+++

index.html is an interesting beast in S3. S3 is an object store. It is often
mistaken for a filesystem, but it is not. It is also **not** a web server,
though it can [pretend to be]. 

CloudFront is a CDN, and as such, it is also not a web server, though it
does serve web content to users. All this makes for a strange situation for
our friend, index.html.

index.html is generally used as a default document in web servers. So, if I
visit https://example.com/ (and you are using SSL, right?), the web server on
example.com will search the filesystem for a file named index.html in the root
directory. Assuming it exists, the contents of that file will be read and sent
to the browser. This behavior also applies to subdirectories, so if the
directory on the server is at /var/www and you have a file /var/www/my-test/index.html,
the url https://example.com/my-test/ will operate and display the contents
of the file.

Because this behavior is so common, S3 website hosting mimicks this behavior.
This is fantastic, but also confuses things when using CloudFront with an
[S3 Origin]. One might expect index.html behavior to work the same way, and in
a way, it does. If I setup CloudFront for the domain example.com and visit
https://example.com/, the index.html file will be fetched from S3 by CloudFront
and delivered as we expect. However, this behavior is a one-off by CloudFront.
If I visit https://example.com/my-test/, the object in my bucket with the
key my-test/index.html will **not** be fetched.

How do we get around this? The first and easiest way is to simply create links
to my-test/index.html rather than my-test/. This makes for ugly URLs though.
Alternatively, we can treat S3 as a custom origin. From CloudFront's perspective,
it's now treating S3 as it would treat any web server that might be doing any
kind of processing. This works great, but comes with a couple downsides.
First, you can't lock down your S3 Bucket, so people could bypass the CDN
and hit the S3 bucket URL directly. Secondly, S3 website hosting doesn't
support SSL, so you're left with a solution that is not encrypted end to end.
It's possible, though highly unlikely, that a man in the middle could alter
your content between S3 and the CloudFront edge location. I hope at some
point S3 website hosting supports SSL and eliminates this problem.

[pretend to be]: http://docs.aws.amazon.com/AmazonS3/latest/dev/WebsiteHosting.html
[S3 Origin]: http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/DownloadDistS3AndCustomOrigins.html
