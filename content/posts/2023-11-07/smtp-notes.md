---
title: 'SMTP and email notes'
date: 2023-11-07
draft: false
---

SMTP and email notes
====================

This is a general post to document what I've been learning while setting up my
own email server. It's been a long time since working with SMTP directly,
especially with things like SPF, DMARC, and DKIM. A few general feelings
of this process:

* It's not terrible! Running your own server is something that general Internet
  advice says DO NOT DO. But that advice, at least so far, seems wrong. I can
  send to gmail without issue, and get 10/10 on [mail-tester.com](https://mail-tester.com)
* There's a lot of bad advice on the Internet
* The system is not magic
* It's pretty flexible
* Security has improved a lot since the days of "telnet to port 25"!

Let's start with security, because with all the spam out there, email kind of
begins and ends there

Security
--------

Let's start with "telnet to port 25". Port 25 is in use, but connections can
be TLS encrypted over that port. From the server side, we can require it.
Also, authentication of course. TLS on all the other ports, and encryption
in transit is covered.

Connecting to other servers, services also check other things. In order of
importance, I find quite a bit of poor advice on the Internet.

* Reverse DNS, or PTR records

Unlike what I read before hand, **these are critical**. Basically, you can
have a  near perfect score, and nobody will deliver your email without this.
Of course, it's the owner of the IP range that needs to do this, so setting
that up will vary based on the hosting provider you use.

* DMARC, SPF, DKIM

Only DKIM is marginally a problem. SPF, and especially DKIM, provide indications
of the integrity of the mail. DMARC is simply there to define your policy of
what should be done should SPF or DKIM fail. That's the high level, but a good
first read on these technologies is [here on Cloudflare](https://www.cloudflare.com/learning/email-security/dmarc-dkim-spf/).

DKIM is the most finicky, mostly because you have to have everything aligned for
it to work. But, it's basic cryptography. You store the public key in DNS,
along with a "selector", and your server software signs the email with the
private key. The email header describes what other headers are part of the
signature, so your email can be sent through 10 relays and it doesn't matter
at all unless one of them messes with those headers or the email itself.

The most fun thing IMHO is that selector. I was initially confused why that's
needed, but the answer is relatively simple. If you use multiple servers or
services, you don't need to pass multiple keys around. You can also have multiple
private keys to do rotation. The server provides the selector in the DKIM
header, so the domain lookup will find the right DNS record for that particular
email. More on this later, but it makes things pretty flexible.

* Hosting provider

This gets a bit tough. The big cloud providers all have various restrictions
on using their servers to send email. I'm sure they want good IP reputation
(see below), but I suspect other reasons exist and I don't want to speculate
too much. I believe DigitalOcean and Vultr will allow it, but ultimately I found
[George DC](https://www.georgedatacenter.com/) had a pretty good deal, and is
fine with sending email, as long as it's not for spam. I even submitted a ticket
to update the reverse DNS and it was done in about an hour.

* IP reputation

I haven't had to worry about this too much, but I did notice two or three hits
on IP reputation lists. They were old and it probably doesn't matter, but I
wanted to know how to clean that up. It's both easy and painful. Easy, because
you typically just need to go to the place that claims you have a nefarious
IP address and click a button to delist. Painful because you have to do it
at every place that reports your IP address, and many of those sites need you
to establish an account. One required me to submit a ticket (which seems to have
been handled without human intervention). Note that I did not try to use my
home Internet connection for any experimentation - the Internet says that's a
really bad idea, and I tend to agree it's probably not worth trying.

Software
--------

I'm using [docker-mailserver](https://github.com/docker-mailserver/docker-mailserver),
which sets up most things for you. At the moment they seem to be transitioning
some of the component software, but the docs were reasonable and it's possible
to make basically whatever configuration changes you need. They don't hide
their component software, so if you want to make changes, you'll be digging
into postfix, dovecot, etc. documentation. But, postfix in particular is
a good battle tested server that is extremely flexible. Your mileage may vary,
especially since this does not include any kind of web-based email interface. I
don't really need that, but if you do, there are other alternatives to consider
like mailcow. I cannot vouch for anything else though - if I want web-based,
I can just connect my [nextcloud](https://nextcloud.com/) server's mail app
to it through IMAP.

Advanced terminology and use cases
----------------------------------

I'm interested in something called "split routing", where one mail server
handles some email, and forwards the rest to another mail server. SMTP is
actually very decentralized, though, so the idea of "this is your mail server"
isn't actually really a thing. Yes, there is a mail server that hosts your
mail box, but really, anyone can do anything. The flexibility can be confusing,
but it's also pretty powerful.

One thing that I have really comes to terms with is the idea of an MTA, or
mail transfer agent. Typically, we talk about mail servers, but technically,
they are mail transfer agents. A mail comes in, and if the software knows that
the mail is stored locally, that's where it transfers it to. Otherwise, it
determines the next place to go to. Whether that mail comes in from an IMAP
connection, SMTP, or another SMTP server, is immaterial really. It just matters
"where does this mail need to go". In postfix, this means that all we need to
do for "split routing" is define overrides in transport maps for emails we
want to override. Literally...that's it. The stuff we don't override goes
to where it's supposed to go to. With a lot of help from [LinuxBabe](https://www.linuxbabe.com/mail-server/postfix-transport-map-relay-map-flexible-email-delivery),
I set up split routing, and it basically looks like this:

* My DNS MX record is my server
* I signed up with [kingmailer.org](kingmailer.org) for a trial. They tell me
  to go set up an MX record. I *IGNORE* that.
* I set up a `kingmailer@` email address on my domain, in kingmailer.
* I set up a `user@` email address on my domain, but only on my own server

Note, that at this point, kingmailer doesn't know there's another mail server,
and does not know about `user@` email address. Right now, the server that
DNS points at, which will handle **all** email, has no idea of a `kingmailer@`
email address. Time to make it aware.

docker-mailserver has a mechanism for overrides, so this bit is specific to that
software, but I simply dump a `postfix-main.cf` into the configuration directory,
with a single line:

```
transport_maps = texthash:/tmp/docker-mailserver/postfix-transport_map.cf
```

docker-mailserver default docker compose file will mount a config volume in that
location. The transport map itself is also relatively simple:

```
kingmail@example.com     smtp:[kingmailer.org]
```

Inbound emails will still be rejected though because there is no local account,
so using `docker exec -it mailserver setup add email kingmail@example.com` makes
quick work of that. All that script does though is add a line to the account
configuration and ask postfix to reload.


...and...that's it! Because I specify the server here (with square brackets to
prevent more processing), my server will not bother looking at MX records, it
will just send the mail to the right place.  LinuxBabe recommends adding your
domains into this map with a value of local, and I played around with that, but
kept getting errors. Leaving it out seems to work just fine, and my assumption
is that the default, at least in docker-mailserver, is not a `local` transport.

One thing I really wanted to do, but again, it goes against the general wisdom
of the Internet, is get a unified inbox in my actual email client. I've gone
back to mutt (actually, [neomutt](https://neomutt.org)) which has the disadvantage
of that HTML email is inconvenient, but also has a strong advantage in that
HTML email is inconvenient. So many trackers, etc that are no longer automatically
triggered. I've been working with neomutt over IMAP with gmail for over a year
now, and rarely need the actual web version. "Clicking links" is something
that's not as pleasant as I would like, but all in all, I'm not sure HTML email
was all that great an idea in the first place. ;-)

Mutt/Neomutt don't really handle a unified inbox very well, so I figured out
a way to do this by syncronizing my postfix data directly into my mail directory,
thus violating not one, but two pieces of generally accepted wisdom. First,
"you really don't want to have two accounts in the same mail directory", and
second, "don't use [syncthing](https://www.syncthing.net) to synchronize a
subdirectory of a synchronized directory". The latter came as a warning message
directly in the UI of the software, so that was a little scary, but I'm ok...
more on this in a second.

The first advice was legitimate. My mail directories use [isync (aka
mbsync)](https://isync.sourceforge.io/) to synchronize all my imap folders in
Gmail to my local storage. If I'm going to keep the mail separated, I don't
want my postfix mail to get uploaded, so I needed mbsync to ignore the postfix
mail. I also needed syncthing to ignore gmail-sourced mail. I have decades of
email in gmail, and I do not need that on my VPS with only 40GB disk. For the
first problem, I actually forked the isync source code at the latest release,
then added a [3 line patch](https://git.lerch.org/lobo/isync/commit/6faf91a8068a14ce0fd5ac9695b567a569cad2c1)
to look for a substring of the file name, and ignore it. As all postfix-sourced
email ends up with the server host name in the file name (but Gmail does not),
I could use that to let mbsync ignore my postfix data. On the syncthing side,
I used the following ignore pattern:

```
??????????.*.????????????,U=*:?,*
dovecot*
```

That first pattern looks nuts, but I basically tried to scope to exactly what
matched the mbsync stuff. The dovecot line is due to some dovecot accounting
files (I've been saying postfix, but the files are actually managed by dovecot,
which also handles imap).

The last issue is the syncthing warning about syncing a subfolder of a synced
folder. This is ok in this circumstance. I'm sharing my overall mail folder
with every device I want to use neomutt on (this allows me offline access when
I'm traveling). However, just my inbox folder/subfolders is being synced to
my mail server, and shouldn't be shared anywhere else. Mutt/neomutt can happily
think it's working with a local mail directory, while everything I do is
transparently synced back to gmail (for gmail-based email), or to my mail server
(for email stored there).

Tools
-----

I mentioned [kingmailer](https://kingmailer.co/) a couple times. I'm sure there
are a bunch of reasonable services, but kingmailer had a 14 day trial that did
everything needed to get comfortable with the process.

Debugging DKIM (is my DNS updated properly? Am I loading the right private key?
What about that bug in docker-mailserver where the config doesn't persist
properly? Is docker-mailserver using OpenDKM or rspamd?) was a bit painful. I
found https://appmaildev.com/en/dkim pretty useful. It's a bare bones site, but
is not restricted to three tests a day the way mail-tester is. They also have
SPF and DomainKeys tests, but I didn't need them. For a more general test
(everything, not just DKIM), I used https://www.gmass.co/analyze, which also
avoids the mail-tester restrictions. Eventually though, you really need to test
with https://www.mail-tester.com, because that seems to be the gold standard
for determining proper setup. If you're scoring 10/10 on that site, which you
really should be, and your email isn't going through, the problem is them, not
you.

All inbound email is managed via MX records for the domain. I use
[Cloudflare](https://www.cloudflare.com) for that.

Georgedatacenter, as mentioned above, has been good so far. Debian and docker
provide the remaining software stack.

Results
-------

After testing this process thoroughly, I've moved the lerch.org mail to use this
set up. Now I have docker-mailserver handling my own email (inbound and outbound),
and push the rest of my family off to gmail. If the server goes down for some
reason, the fall back MX (mail server, mail exchange), remains gmail, so they
will pick it up. Any email I try to send will fail until I reconfigure or bring
my server up, but that's ok by me.

It is interesting to see the connections from various servers coming through my
new mail server. There sure is a fair amount of spam. But so far (only a couple
hours, granted), I've yet to see any spam get to my inbox. I'll post an update
if this all turns out to be a terrible idea, but so far I'm looking at all this
advice on the Internet "you don't want to host your own mail server" and saying,
"really? This doesn't seem too bad.".

If you've followed along this far, I assume you're curious, so here's a full
diagram of my email setup. I still have some fine-tuning to do, but I'm pretty
happy with it. One note - another piece of advice you see a lot is to use
[notmuch](https://notmuchmail.org/) to allow easier searching. I find this
less than optimal for two reasons. 1) your inbox in (neo)mutt becomes effectively
read only, and 2) the search index is a massive single file, so synchronizing it
is a bit painful. I instead 95% rely on (neo)mutt's built-in search, which is
nice and fast if you stick to what's in subject or headers (just from?), and
use a special command that performs a notmuch-based search on my server if
I need something fancy. The server index is kept up to date as email comes in.

```goat
          +-------------------------------+             Syncthing (maildir)
Primary   |                               |<-----------------------------------+
--------->| MX Priority 0: my mail server |                                    |
          |                               |<--------------------------+        |
          +---------------+---------------+       SMTP (msmtp)        |        |
                  ^       |                                           |        |
                  |       |                                           |        |
    +-------------+-+     |                                           |        |
    | Mobile Device |     |Email other                                |        |
    | (Imap client) |     |than "me"                                  |        |
    +-------------+-+     |                                           |        |
                  |       |                                           |        |
                  v       v                                           |        v
               +----------------------+                            +--+------------+
 Group email   |                      |       IMAP (mbsync)        |  Home Server  |
-------------->| MX Priority 1: Gmail |<-------------------------->|(go-imapnotify,|
 Primary if    |                      |                            |notmuch,msmtp) |
 server unavail+----------------------+                            +---------------+
                                                                      ^    ^    ^
                                                                      |    |    |   Syncthing
                                                              +-------+    |    +--------+
                                                              |            |             |
                                                              v            v             v
                                                        +-----------+ +-----------+ +-----------+
                                                        |  Device   | |  Device   | |  Device   |
                                                        | (neomutt) | | (neomutt) | | (neomutt) |
                                                        +-----------+ +-----------+ +-----------+
```
