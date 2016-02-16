+++
date = "2016-02-16T13:35:02-08:00"
draft = false
title = "Consider a single container per virtual machine in production"

+++

[Containers] are a great unit of deployment. They're a great way to isolate
code, reduce attack areas, and, well, **contain** a service. When it comes
to deployment in production, operational attributes of containers must be
considered.

Container technology can enable significant density (described in terms of
containers per vm) while retaining isolation between services. However, is
this something we want to take advantage of operationally? Two significant
issues with pushing for >1 container per vm come to mind.

First, for security-sensitive workloads, container technology provides a
lesser security model than virtual machines on a hypervisor. A shared
kernel forces us to trust user mode container orchestration tools (e.g.
[Docker], the daemon of which still runs as root) and kernel level
constructs (e.g. [cgroups] and [namespaces]). Regardless of your feelings of
the maturity level of this code, the fact of the matter is that there is
simply a larger attack surface.

For this reason, only containers that implicitly trust each other can
feel free to share a virtual machine in production. However, should they?
The second consideration here is performance. For years we've been moving
as an industry to more granular, single purpose virtual machines. A mail
server, a web server with a single app or service, a database server, etc.
Does the logic here really change with the introduction of containers? I
believe the same reasons that push us toward single purpose virtual machines
still hold true for containers. It becomes exponentially more difficult
to deploy and manage virtual machines that contain mixed workloads. In
addition, you can no longer tailor the characteristics (network, disk, ram,
cpu) of the virtual machine to the workload, but need to pick general
configurations.

[Containers]: https://en.wikipedia.org/wiki/Software_container
[Docker]: https://www.docker.com/
[cgroups]: https://en.wikipedia.org/wiki/Cgroups
[namespaces]:  https://en.wikipedia.org/wiki/Linux_namespaces
