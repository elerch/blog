+++
date = "2016-02-01T13:40:16-08:00"
draft = false
title = "Static Site Deployment with 'git push' to GitHub"

+++

The process I've put together for publishing this blog allows for automatic
publish to the web as soon as I git commit/git push. This post describes
how this is done.

As background, this blog is hosted on Amazon Web Services' [S3] service with
CDN capabilities and SSL termination provided by [CloudFront] and [Amazon
Certificate Manager]. This last service is extremely new, to the point that
I obtained and assigned the certificate to CloudFront [the very day CloudFront
integration was available](https://aws.amazon.com/blogs/aws/new-aws-certificate-manager-deploy-ssltls-based-apps-on-aws/).
As such this was a last minute change. My original intent was to use 
[Let's Encrypt] free SSL certificates, but since ACM is also free and the
service renews certs automatically, this seemed to be the better way to go.

With hosting taken care of, my next goal was to automate publishes. I keep
the actual content of the blog on [GitHub] at https://github.com/elerch/blog.
GitHub has integration with AWS [SNS], so I can trigger a [Lambda] function
based on a push to GitHub (or a commit through the web). The process looks
like this: https://aws.amazon.com/blogs/compute/dynamic-github-actions-with-aws-lambda/

In my lambda function, I use the [GitHub REST API] to get the [repo archive].
From there, I can unpack the archive and copy it to S3, using [Reduced
Redundancy Storage] to save a few portions of a cent. Outside the cost
of S3, the whole process stays within free usage limits.

The lambda function, [CloudFormation] templates, and various scripts are
hosted on GitHub: https://github.com/elerch/blog-deploy/. I've also
created this diagram on [CloudCraft]:
 
{{< figure src="/posts/2016-02-01/blog-deployment.png" link="/posts/2016-02-01/blog-deployment.png" alt="Deployment" >}}

One thing I'd really like to do in the lambda function is pull out the
tight integration between the themes and the lambda function itself.
However, since I don't normally [change my theme](https://github.com/elerch/gindoro),
this will wait for another day. It would also be nice to extract the
actual build steps (extract archive/run hugo on extracted archive/
copy themes/copy output to S3) so that the lambda function can be used
for a wider array of [DevOps] scenarios.

[New Blog]: https://emil.lerch.org/new-blog/
[S3]: http://aws.amazon.com/s3/
[CloudFront]: http://aws.amazon.com/cloudfront/
[Amazon Certificate Manager]: https://aws.amazon.com/certificate-manager/
[Let's Encrypt]: https://letsencrypt.org/
[GitHub]: https://github.com
[SNS]: https://aws.amazon.com/sns/
[Lambda]: https://aws.amazon.com/lambda/
[GitHub REST API]: https://developer.github.com/v3/
[repo archive]: https://developer.github.com/v3/repos/contents/#get-archive-link
[Reduced Redundancy Storage]: http://docs.aws.amazon.com/AmazonS3/latest/dev/UsingRRS.html
[CloudFormation]: https://aws.amazon.com/cloudformation/
[CloudCraft]: https://cloudcraft.co/
[DevOps]: https://en.wikipedia.org/wiki/DevOps
