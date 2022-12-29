+++
title = "Live Custom Domains vs. GMail Hosted"
slug = "2006-03-30-live-custom-domains-vs-gmail-hosted"
published = 2006-03-30T10:36:00-08:00
author = "Emil"
tags = []
+++
OK, so this is a bit bleeding edge, but very, very cool. Please take
this mini-review with a very large grain of salt because both services
are evolving fast.  
  
Both [Windows Live Custom Domains](http://domains.live.com) and [Gmail
For Your Domain](https://www.google.com/hosted) provide the same basic
functionality, which is the ability to use the corresponding company's
mail service (either Live Mail/Hotmail or GMail), to host the users in
your own domain.  
  
I've been doing something similar to this for my own email at my domain,
by setting up my accounts to forward messages to Windows Live Mail or
Gmail (depending on the account). The problem here is that:  
  

-   People you're sending mail to can figure out where the mail comes
    from (Hotmail/Live Mail uses Reply-To, Gmail sets the From: address
    but uses a Sender: address of Gmail that will show up in some mail
    clients as "on behalf of").
-   Only effective for your account - not everyone in the domain.

I credit Windows Live Custom Domains as having the first incarnation of
the service. Basically, you tell the DNS system that the mail server
(technically, this is changing your MX record) is not your hosting
provider's mail server, but rather it's Google's or Microsoft's mail
server. Some issues with any service like this:

-   There's no halfway - it's either everyone in the domain or noone
-   It's hard to change back

There's another issue that both services also have, at least right now,
which is the ability to pull in all your existing mail. Of course, I
believe both Hotmail and Gmail have the ability to pull from POP, so
there is at least that migration path.

For the tests, I registered a free .info domain (lerchweb.info) at
[1&1](http://www.1and1.com), a large hosting provider. I signed up for
the Google Beta and the Windows Live Custom Domains beta (internally
this is known as BYOD for Bring Your Own Domain). They both work
essentially the same, with the following differences:

-   Windows Live requires that each user establish a Hotmail/Windows
    Live account. So far (and this is preliminary), Google does not
    require this. I would give Google the edge on this point, but
    Windows Live may have a better privacy story to tell.
-   Google lets you brand GMail with your own domain logo. Very cool
    touch.
-   Google lets you import users from a spreadsheet (exported to CSV).
    Also very cool, and this is a new feature that Windows Live may
    replicate.
-   Google beta took me about a month to become a member. Windows Live
    Custom Domains was immediate.

It's hard to ignore my feelings about the actual mail system (I tend to
prefer Google), but judging on simply the domain hosting features, I
think I give this one to Windows Live Custom Domains, primarily because
it takes so long to get into Google's beta.

Next step is to get another free .info domain so I'm not repointing
things all the time so I can do more than a 24 hour evaluation. This
concept excites me, and I look forward to some cutthroat competition!
