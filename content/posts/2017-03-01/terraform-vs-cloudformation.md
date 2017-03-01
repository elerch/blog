+++
draft = true
date = "2017-03-01T14:17:24-08:00"
title = "Terraform vs CloudFormation"

+++

Recently there have been discussions about the advantages and disadvantegs
of using Hashicorp's [Terraform](https://www.terraform.io/) vs
[AWS CloudFormation](https://aws.amazon.com/cloudformation/) for
infrastructure as code on AWS. While these products change continuously,
here's a snapshot summarization of the advantages of each system.

AWS Cloudformation
------------------

* **Tighter integration with AWS Services:** In my opinion, this is the biggest
  draw to using CloudFormation. You simply can't use Terraform for things
  like [AWS Service Catalog](https://aws.amazon.com/servicecatalog/).
  Service Catalog in particular is a huge benefit to acheiving agility with
  control, and to avoid using it simply because your processes are
  Terraform-based would be a shame.
* **IAM-based access control:** This is another example of the integration
  story, but if you're already heavily invested in AWS it's nice to not
  have to learn a different access control mechanism.
* **Has a GUI:** If you're into that sort of thing, it's nice to not be
  forced to use the command line.
* **Feature support:** For new services and features, AWS CloudFormation
  generally has support prior to Terraform. While there are exceptions to this,
  fundamentally CloudFormation has an edge as the service is inside AWS
  and thus has advance notice of all new services and features. Often
  CloudFormation support is included with the launch of a new service or
  feature. At the time of this writing, IPv6 VPC support is in CloudFormation
  but Terraform does not yet support it.

Terraform
---------

* **count=*n* and pre-built functions:** CloudFormation
  has some functions, but Terraform goes further, and count=*n* is
  simply fantastic.
* **Inspect current state:** In many cases you shouldn't need to guess
  about your current environment, but if you're mixing and matching
  various templates or you're the type of organization that occassionally
  breaks the rules and allows some manual configuration, the ability
  to define a template that can dynamically compensate for differences in
  the environment is pretty powerful.
* **Multiple account support:** You might be able to do this in CloudFormation,
  but it's complicated and a bit hackish.
* **Multiple region support:** See above

Mythical Advantage of Terraform
-------------------------------

One advantage I **hear** about Terraform but completely discard is the ability
to support multiple clouds. While this is true, the reality is that each
cloud works differently and makes different engineering tradeoffs, has
different feature sets, etc. In the end there's no magic bullet for deploying
infrastructure seamlessly across different cloud service providers. You
**might** be able to get away with an automated translation of one to another,
but you'll either have to architect for the lowest common denominator or
you'll lose something in translation. In the end organizations that try
always end up maintaining two sets of templates.

Other approaches
----------------

I do know of some folks that are using [Troposphere](https://github.com/cloudtools/troposphere)
with some success. This provides some benefits in terms of imperative
programming and the full power of Python.

Final thoughts - for now
------------------------

Most people I work with get by with CloudFormation in
[YAML](https://aws.amazon.com/about-aws/whats-new/2016/09/aws-cloudformation-introduces-yaml-template-support-and-cross-stack-references/).
This keeps the implementation simple and allows full integration and (mostly)
faster resource support. Both Terraform and CloudFormation change often,
but this is the state of things on March 1st, 2017.

