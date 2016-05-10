+++
date = "2016-04-19T14:11:16-07:00"
draft = false
title = "Running Windows 10 on AWS EC2"

+++

Getting Windows 10 on EC2 isn't difficult, but perusing the [documentation]
can lead to confusion.

You can't mount an ISO to an empty VM the way you might do in [VirtualBox],
so this process requires a local copy of the VM to be created, then
using the aws ec2 import-image command to create the AMI. When done,
not only will the image be ready for EC2, but it will be detected as
Windows by AWS and be configured such that it has many of the same
AWS-specific features as other Windows AMIs provided by Amazon.

* Create a new Windows VM using VirtualBox
   - Make sure to choose VHD as the disk image format
* Install Windows 10 within the VirtualBox VM as normal.
   Note that a fresh install will format the VHD as MBR,
   which is the only partition format supported on AWS
* Shut down the VM and upload the vhd file to an S3 bucket
* Create a json file describing the VHD. This usually looks something like this:
```
[{
  "Description": "Windows 10 Base Install",
  "Format": "vhd",
  "UserBucket": {
    "S3Bucket": "mybucket",
    "S3Key": "Win10.vhd"
  }
}]
```
* Import using the CLI: aws ec2 import-image --description "Windows 10" --disk-containers file://containers.json
* The import task will have been created, but the actual import will
   take a while. To check progress, use: 
```
aws ec2 describe-import-image-tasks
```
* Once the AMI created, start instance as normal using your new ami

**Update 2016-05-10**: If you want to remote in, don't forget to setup the
OS to allow remote desktop prior to copying the VHD!

[documentation]: http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/UsingImportImage.html
[VirtualBox]: https://www.virtualbox.org/
