+++
date = "2016-02-08T14:19:43-08:00"
draft = false
title = "Xen on AWS EC2"

+++

Since I'm working for [AWS], I want to understand fundamentally the workings
of the open source [Xen Hypervisor]. I also want to dig more deeply into
the emerging [Unikernel] ecosystem. Of course, I want to do this on
[Amazon EC2], because generally I prefer to assume my laptop is ephemeral and
could be lost, stolen, dropped, etc. However, Xen doesn't nest well, so putting
Xen in a virtual machine on top of Xen is a little bit crazy-talk.

Undaunted, I searched around, finally bumping into an old research project
at Cornell called [Xen Blanket] that aims to do just this. The [instructions]
are old for an old version of Xen and CentOS. So old that it took me two
runs to get it right. This [course lab] was more explicit and ultimately I
compared the directions and kind of ran through both sets of instructions
together. 

At the end of the day, I ended up with an older version of CentOS with an
older version of Xen installed. This was all in us-east-1 (Virginia) region,
and since I live in Oregon I migrated the AMI over to us-west-2 (Oregon).
If you would like to play around with Xen for Unikernel development or
any other reason, I've created AMIs in us-east-1 and us-west-2 and made
them public. Once launched, use your ssh key with the 'root' user.

The following links will start the launch wizard in the console with these AMIs. 

* us-east-1 AMI (ami-fd2a0197): https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#LaunchInstanceWizard:ami=ami-fd2a0197
* us-west-2 AMI (ami-bf2fcedf): https://console.aws.amazon.com/ec2/v2/home?region=us-west-2#LaunchInstanceWizard:ami=ami-bf2fcedf

[AWS]: https://aws.amazon.com
[Xen Hypervisor]: http://xenproject.org
[Amazon EC2]: https://aws.amazon.com/ec2/
[Unikernel]: https://en.wikipedia.org/wiki/Unikernel
[Xen Blanket]: https://code.google.com/archive/p/xen-blanket/
[instructions]: http://xcloud.cs.cornell.edu/code/README.txt
[course lab]: http://www.cs.cornell.edu/courses/cs6410/2013fa/lab0b.htm

