+++
date = "2015-12-07T16:09:36-08:00"
draft = true
title = "Home Backup Strategy"

+++
Concerns:

* Rapid restoration of data in the event of an outage (RTO)
* Minimal data loss (RPO)
* Recovery from accidental deletes
* Recovery from malicious deletes, such as ransomware
* Recovery from cosmic ray damage on hard drive platters
* Recovery from total destruction of the house
* Recovery from a failed hard drive

These are all interrelated, so I cannot describe a single technology or 
procedure that covers each item in turn. Instead, I'll describe the solution
and discuss how it addresses each point.

First, the solution involves a local NAS with continous asynchronous backup
to Code42's CrashPlan servers in the cloud. This is the only portion of the
solution that includes a recurring cost, however, that could be eliminated if
I instead used their "backup to a friend" feature. However, the $5/month cost
is reasonable, especially for unlimited data. The continuous asynchronous
backup feature is nice in that it provides minimal data loss in the case of
an issue. The data loss is minimized to the time it takes any new/changed files
to transfer to the Internet. CrashPlan also provides access to previous versions
of files, so if ransomware encrypts my data or I accidentally delete a file,
I'm covered. It can also protect me from cosmic ray damage in certain
scenarios (basically, if I knew the damage had occurred). The downside,
however, is that this does not protect me from cosmic rays, nor does it allow
me a quick recovery time in the event of a loss of my data locally.

To handle the rest of the solution, I built a local NAS server using Ubuntu
using the ZFS file system. I'm interested in btrfs as a replacement, but this
is still experimental. ZFS has a lot of really cool features. One of the best
is also in btrfs, and that feature allows stored data to reheal through
checksums. This is in contrast to a RAID system which is focused on one or
more drive failures. In my ZFS "pool", I have created a software RAID level 5
called RAID-Z. This requires that I use 3 hard drives and can tolerate a failure
of 1 hard drive at a time without losing data.

This setup has (un)fortunately been tested. When I built the array, I purchased
three hard drives at the same time. This is generally not-advised, as the drives
therefore come from the same batch and are therefore more likely to fail at the
same time. This particular batch did have problems, but I was lucky to lose
one drive at a time over the course of a year. At no time did I lose any data,
although I did come close, mostly due to operator error.

Due to my use of /dev/sdb, /dev/sdc, etc naming, the drive order changed and I
repartitioned the incorrect job when I already had a failed drive. I learned the
hard way to use disk ids when assigning the drives to the ZFS pools. However,
I learned more about ZFS and came up with another way to reduce the recovery
time in the event of a loss of the array.

ZFS has a feature called snapshots, which are excellent for marking (and maybe
reverting to) a point of time of the system. Since ZFS is a COW (Copy on Write),
snapshots do not take disk space until you start to change data. To limit the
damage should I get hit with ransomware, I had already setup weekly snapshots
on my ZFS. I don't change a ton of data since the setup is mostly for pictures
and videos of the kids, so I stayed with weekly. However, snapshots have another
great use. You can "send" and "receive" deltas of your data between ZFS pools
without having to resort to any synchronization software. Armed with this
knowledge, I purchased a USB drive with enough storage space to hold my data,
created a ZFS pool with the single drive (this isn't about redundancy - this is
about minimizing down time in a catastrophic loss to the main array), and I
can now send my deltas to the external drive. I do not have this on a schedule
yet, but I should get this cron job up shortly.


