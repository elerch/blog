---
title: "Neomutt setup"
date: 2024-01-13T11:43-08:00
draft: false
---

Neomutt
=======

In my [last post](https://emil.lerch.org/smtp-and-email-notes/) I mentioned I am
using neomutt for email. This seems completely archaic...how can one do this in
modern times? Wasn't this built for pre-world wide web times, before HTML was
even invented?

Well, yes, but it can still handle all the modern crazy, and for those not
afraid of a terminal and keyboard, it has several advantages:

1. "Modern" mail clients don't work in the terminal
2. "Modern" mail clients need to be driven by using the mouse. In fairness, both
   Outlook and GMail have copius keyboard shortcuts, but they are clearly mouse-first
3. "Modern" mail clients take a lot more memory. All my mail, starting from the '90s,
   is available to me in neomutt. Memory usage is 339M (RSS). Opening gmail,
   once my fan spins down and my browser is responsive again, creates a tab that
   consumes 800M. Outlook on my work machine has 59 threads consuming 589M working
   set (833M private bytes virtual memory)
4. "Modern" mail clients [include tracking](https://proton.me/blog/outlook-is-microsofts-new-data-collection-service).
5. "Modern" mail clients display html emails that include tracking mechanisms
   so marketers can determine open rates for email.

ok, so if these advantages are interesting, the question naturally becomes,
"how on earth do you deal with email, 99% of which these days is html?". This is
a good question, and to be clear here, I'm only going to address **inbound**
email. When I send email, it's text only...I have need to format email probably
less than once/year, even at work. If I ever have that need for personal email,
I'll likely just use nextcloud or something. I haven't even run into the issue.

At a high level, this the combination of technology I use:

1. Mail client: neomutt
2. Terminal image support: This is provided through
   [sixel](https://en.wikipedia.org/wiki/Sixel) support. I used to use
   [st](https://st.suckless.org/), now I use [mlterm](https://github.com/arakiken/mlterm).
   They both have advantages/disadvantages. Honestly, I have yet to really find
   a terminal I'm 100% happy with. More full featured (but heavier weight)
   sixel-enabled terminals can be found at https://www.arewesixelyet.com/.
   Common terminals for normal people are xterm, iTerm2, and konsole. Also,
   tmux and Visual Studio Code both support sixels.
3. Terminal based browser: [w3m](https://github.com/tats/w3m). I'm not particular
   on this, it's possible that lynx or something else might work...I just don't
   do a lot of terminal-based web browsing here, I just want to view an email,
   but graduate to a normal browser for normal browsing.

For a while I had a basic setup going, but I re-visited recently and I now have
a configuration I'm pretty happy with. A lot of the credit goes to [this
reddit post](https://www.reddit.com/r/commandline/comments/z7vkwn/how_can_i_use_w3m_with_html_that_has_images_in/),
and the information below is largely a re-post of the comment I made there.

With the software above installed, the configuration needs to be set up. `~/.mailcap`
is a configuration file that describes what should happen when a mail client
sees various types of mail. This drives a lot of the behavior. I've created a
mailcap file that looks like the following:

```
# The first one here is triggered when going in to view the attachments, then pressing 'm' on the text/html
# -sixel changes w3m behavior a bit. Without it, images will show up, but only when you do something to the screen
# having the option shows the images immediately
text/html;                         w3m -sixel -o auto_image=TRUE -o display_image=1 -T text/html %s; nametemplate=%s.html; needsterminal

# This second one is chosen by auto_view due to the copiousoutput tag
text/html;                         w3m -I %{charset} -T text/html -cols 140 -o display_link_number=1 -dump; copiousoutput

# The third, non-existent one is going in to view the attachments,
# then press 'V' on the text/html attachment, which opens in a proper browser
```

The comments above should be pretty clear, but this gives me the following behavior in neomutt:

* `<Enter>` from the index, shows HTML through w3m, with links at the bottom.
  No images or color. This is fine for 90% of my needs, and is privacy respecting.
  This behavior is driven from neomutt auto view, which looks for the
  `copiousoutput` attribute, which needs to be the **second** entry in mailcap
  (otherwise it would be the default for everything, which I don't want)
* Going into the attachment list (`v` from the index) and using `<Enter>`
  or `m` on the text/html opens in w3m, in full glory, with all images. Oddly,
  I thought I needed `m` in this situation, and was surprised to find out
  `<Enter>` works. This will send tracking pixel data and whatever other
  crazy the sender is doing, but I have to take affirmative action to view
  email in this way.
* Going into the attachment list (`v` from the index) and using `V` on the
  text/html will open in my actual browser, which seems necessary for a lot
  of unsubscribe links in particular for some reason

The last bullet (using `V` on the attachment list) is enabled through the
following macro defined in my neomutt config (I use ~/.config/mutt/muttrc) as
my configuration theoretically will work in either mutt or neomutt:

    macro attach 'V' "<pipe-entry>iconv -c --to-code=UTF8 > ~/.cache/mutt-mail.html<enter><shell-escape>open ~/.cache/mutt-mail.html<enter>"

I also have `confirm_qq false` defined in `.w3m/config`. This simply prevents
w3m from confirming I want to quit.

This seems pretty good so far and gives me a nice way to progressively handle my html mail:

* 90% of the time, I just hit `<Enter>`. I can see the link text, and I don't send pixel tracking data
* 8%, go into attachment list and hit `<Enter>` to see images. At this point,
  I'm sending tracking data, which I'm consciously doing in a trade off for
  information I find more valuable
* 2%, go into attachment list and hit `V` because I really need to interact
  with this thing beyond w3m. Usually unsubscribe links, but it could also
  be newsletters with links to source material (w3m is usually good enough
  for this though)

That's it! In the end, it's not a lot of magic config, but it's clearly tricky
to work out. Also, this works well for how I work...others are looking for
different user experience, and will probably not like this setup...
