+++
draft = true
title = "Moving AWS images into Govcloud"
date = "2017-01-09T15:27:50-08:00"

+++

If you have worked with [AWS GovCloud](https://aws.amazon.com/govcloud-us/),
you know it is a very different region from most other AWS regions. It
requires a seperate account, linked to a standard AWS account, and uses
IAM users only - root users are not allowed at all. This has always been
a best practice, but in GovCloud, you have no choice.

GovCloud also has fewer services than other regions. At the time of this
writing, [AWS Marketplace](https://aws.amazon.com/marketplace/) is one
of the services that is missing. This creates a problem in GovCloud
because many high quality AMIs are distributed for free but are only
available in Marketplace.

To work around this, it is possible to move instances into GovCloud, though
it is a bit convoluted. First, before doing anything, make **absolutely**
sure you are within the terms of the license agreement moving images
this way.

Once the legality of doing this has been verified, the overall process
is straightforward but somewhat lengthy. Here I will cover specifics for
Linux, though Windows should follow the same high level approach.

Launch Your Instance in Commercial
----------------------------------

You will want to actually launch the instance from the marketplace. At the
time of this writing, GovCloud has a single region in Oregon called
us-gov-west-1. You will want to be as physically close to the target
GovCloud region as possible for reasons that will become clear, so the
best place to launch your instance is us-west-2 (Oregon).

Configure your instance in Commercial
-------------------------------------

Next, you will want to configure your instance. This is an optional step.
As a proof of concept, I created a Centos 7 base image from the
marketplace for this purpose. As a base image, I did not want to actually
configure it. What little was done (basically configuration of the ssh key)
would need to be undone if I want to make it useful to others. But you
can take this time to do whatever configuration you would like.

Stop your instance in Commercial
--------------------------------

Next, we will stop this instance. What we are looking for is the underlying
EBS root volume (this procedure only works with EBS-backed AMIs).

Start another instance in Commercial
------------------------------------

Now, we can start another instance. We will need to attach two additional
EBS volumes after the fact. The first must be larger than our target
instance volume, the second attachment will be the target instance root
volume. At this point, you will should have 3 volumes on the instance:

  * (root)
  * Large volume (xvdf)
  * Root volume of target instance (xvdg)

Image the target and copy to image to GovCloud
----------------------------------------------

With the volumes attached (but not mounted), we will want to get an image
file of the root volume. This is the **whole volume**, not an individual
partition. Likewise, for the throwaway "large volume", you do not really
need to partition it as we will be discarding it soon. The commands look
like this:

```
sudo mkfs -t ext4 /dev/xvdf
sudo mount /dev/xvdf /mnt
sudo dd if=/dev/xvdg of=/mnt/myimage.img bs=1M
aws s3 cp /mnt/myimage.img s3://yourgovcloudbucket/
```

Note that prior to the aws s3 command you should be doing an aws configure
command to setup credentials (access key/secret key) for GovCloud.

At this point, you have a bit-for-bit copy of your commerical image in
a GovCloud S3 bucket, so the data is in the correct region. Everything
in commercial can now be terminated/deleted.

Rehydrate image in GovCloud
---------------------------

We will want to now launch an instance in GovCloud to finish this
process. In addition we will want two additional EBS volumes in the
same manner as described above:

  * (root)
  * Large volume (xvdf)
  * Root volume of target instance (xvdg)

The third volume should be the exact size of the original volume from
the commercial region. Once launched with EBS volumes attached, we
can re-hydrate the volume to make it bootable once again:

```
sudo mkfs -t ext4 /dev/xvdf
sudo mount /dev/xvdf /mnt
# Note you might need permissions to create/write files to /mnt
aws s3 cp s3://yourgovcloudbucket/myimage.img /mnt 
sudo dd if=/mnt/myimage.img of=/dev/xvdg bs=1M
```

At this point, this instance can be shut down and the large EBS volume
(formerly known as xvdf) can be deleted. However, we want to create
a snapshot of the rehydrated root volume of the target instance
(formerly known as xvdg). From this snapshot, we can use the console
or the command line to create an AMI. From the console, right click the
EBS Snapshot and choose "Create Image".

Done
----

And...we are done. One thing to note is that unless you have reconfigured
the instance you will need to log in with the ssh key you originally
specified in the commercial region as that key will now be "baked in"
to the AMI.

