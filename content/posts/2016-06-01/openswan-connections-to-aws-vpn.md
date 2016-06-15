+++
date = "2016-06-01T13:23:19-07:00"
draft = true
title = "openswan connections to aws vpn"

+++

# hi

```yaml
## general configuration parameters ##

config setup
        plutodebug=all
        plutostderrlog=/var/log/pluto.log
        protostack=netkey
        nat_traversal=yes
        virtual_private=%v4:10.0.0.0/8,%v4:192.168.0.0/16,%v4:172.16.0.0/12,!$RIGHT_SUBNET
        ## disable opportunistic encryption in Red Hat ##
        oe=off

conn AWS
        type=tunnel
        authby=secret
        auto=start
        ike=aes128-sha1
        ikelifetime=28800s
        salifetime=3600s
        dpddelay=10
        dpdtimeout=60
        dpdaction=restart_by_peer
        rekey=yes
        keyingtries=%forever
        ## phase 1 ##
        keyexchange=ike
        ## phase 2 ##
        phase2=esp
        phase2alg=aes128-sha1
        pfs=yes
        left=%defaultroute
        leftid=52.196.123.135       # Elastic/public IP of *this* instance. Also this is specfied as the customer gateway IP address https://ap-northeast-1.console.aws.amazon.com/vpc/home?region=ap-northeast-1#cgws
                                    # This could be anything - it's a way to identify itself when looking up the PSK in the secrets file
        leftnexthop=%defaultroute
        leftsubnet=10.0.0.0/24      # Private subnet where this instance resides
        right=52.196.160.248        # Public IP address of the other side (AWS VPN Tunnel endpoint #1)
        rightsubnet=10.1.0.0/24     # Private CIDR range for the AWS Subnet
        #leftsourceip=10.0.0.185     # May not be necessary - need to test, but this is the private IP of this instance
```

dflkj *hello* **adf**

Other things to note:

If deploying the VPN server on AWS:

    * Disable source ip check
    * Specify the VPN instance as the route for the foreign CIDR block in the source subnets
    * Make sure to open all TCP/UDP/ICMP traffic from the "local" subnet's SG to the SG of the VPN
    * Flow logs are your friend!

1. hi
2. there
3. wtf

https://clauseriksen.net/2011/02/02/ipsec-on-debianubuntu/
https://forums.aws.amazon.com/message.jspa?messageID=466186
https://docs.openvpn.net/how-to-tutorialsguides/administration/extending-vpn-connectivity-to-amazon-aws-vpc-using-aws-vpc-vpn-gateway-service/
http://xmodulo.com/create-site-to-site-ipsec-vpn-tunnel-openswan-linux.html
