---
title: "Gitea actions and build badges"
date: 2022-09-26:23:18-07:00
draft: false
---

Gitea actions and build badges
==============================

Gitea actions, at the time of this writing, are new. A
[feature preview blog post](https://blog.gitea.io/2022/12/feature-preview-gitea-actions/)
was released in December 2022, and as I write this, Gitea 1.19 RC0 was only published
a few days ago in late February 2023.

There is much work to be done to make the feature complete, but I am excited to
adopt it as quickly as possible. I have been interested in simplifying my
self-hosted setup and removing [Drone.io](https://drone.io)
due to the [licensing weirdness](https://woodpecker-ci.org/faq#why-is-woodpecker-a-fork-of-drone-version-08).
I also never automated the reconnection needed between drone and Gitea
after a host server reboot/power outage/docker upgrade. Also, I have been
impressed with the success of [GitHub Actions](https://docs.github.com/en/actions)
and its adoption in other systems like [Amazon CodeCatalyst](https://aws.amazon.com/blogs/devops/using-github-actions-with-amazon-codecatalyst/).
Gitea is the third system I've used/been involved with that has embraced the
actions format, so it has some industry momentum.

Feature state of Gitea actions
------------------------------

Gitea actions, as it says in the blog post, is in a fairly preliminary state.
Here is a short list of what is **NOT** in Gitea 1.19 RC0, nor do I believe
these will be in 1.19:

* [Cron jobs](https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows#schedule): [PR](https://github.com/go-gitea/gitea/pull/22751)
* An API
* Build badges
* Artifacts
* Services
* Documentation (for the most part, you can follow GitHub actions documentation though)
* [Pull request support](https://github.com/go-gitea/gitea/issues/22958)

More details are available on the [master issue](https://github.com/go-gitea/gitea/issues/13539).

Gitea is also riding a fine line of "this is gitea, not github", and "we want to
allow users to copy over their github actions workflows". Some differences to be
aware of:

* Gitea actions are in the folder `.gitea/workflows` rather than `.github/workflows`
* Gitea actions [uses](https://github.com/go-gitea/gitea/issues/13539) property
  looks at gitea.com, not github.com. Gitea has copied over all GitHub owned
  actions, but GitHub marketplace actions won't work without fully specifying
  the URL
* Based on the two above, you might assume that everything has been renamed. But
  for compatibility, that's not true. So in your workflow yaml, you still reference
  `${{ github.<property> }}`. I suspect they'll probably eventually allow use
  of either GitHub or gitea, but that's just me gazing into a crystal ball.

Secrets, happily, work just great, and all the other pieces are there, so for a simple,
"I'm not going to push this thing too hard", it works.

Bugs and other weirdness
------------------------

Gitea actions build runner is still pretty new. It doesn't support [running as
a container](https://gitea.com/gitea/act_runner/issues/8), but I don't seem
to have a problem running it in a container as long as I mount the docker
socket.

However, I did find that trying to use ${{ github.server_url }} in my workflow
files resulted in an empty string. I can see the code that sets that property,
and my configuration is set properly as far as I can tell, so I'm not sure
if this is a bug or a user error. The environment variable `$GITHUB_SERVER_URL`
**is** set though, so I've just used that.

So for a minimal setup, keep the above in mind, don't push the boundaries too
far, and all is good. But...I really wanted build badge support. Coming from
drone.io this is a feature I had. GitHub has it. Pretty much every system has
it. I'm sure Gitea will eventually include it. But right now, no such thing
exists. So, time to code a workaround.

Getting build badge support
---------------------------

A couple things, before getting started.

* I'm looking to enable build badge support for my public repos. I don't really
  care about private repos
* I am confident that this will be built in to gitea proper, so a hacky short-term
  workaround is fine.
* There's no API support
* I don't want anything elaborate

So with that in mind, I've turned to the following services to build something
in a couple hours:

* [Shields.io](https://shields.io/) to provide the imagery
* [Cloudflare workers](https://workers.cloudflare.com/) and Cloudflare generally
  for DNS and proxy support

My plan was relatively simple:

* Setup a custom subdomain [actions-status.lerch.org](https://actions-status.lerch.org)
  that has all requests handled by Cloudflare workers
* Use a worker to probe the gitea interface, scrape the HTML (YUCK! But there's no API...),
  and determine the latest build status
* Build the appropriate URL to shields.io and fetch the output
* Return the output to the caller

Two hours later, I came up with this solution, which works pretty well. One thing
I noticed it doesn't do is differentiate between a canceled workflow and a
failed one. It turns out, the HTML is identical on the summary screen, so another
call would be needed to determine "canceled", and covering that edge case didn't
seem all that necessary.

If you're interested in a similar solution, make sure you change `git.lerch.org`
below. Also, the badge styling may not be your cup of tea so to speak, so you
may want to update the lines where the `badgeUrl` variable is set starting at
line 44.

I kind of like using the gitea logo on the badge. I feel kind of happy that I'm
likely the first person to use a gitea badge build based on a gitea actions
run on a project. You can see the badge in action on my [aws-sdk-for-zig
project page](https://git.lerch.org/lobo/aws-sdk-for-zig/) or it's [GitHub
mirror](https://github.com/elerch/aws-sdk-for-zig).

**NOTE** This was done with [Gitea 1.19 RC0](https://github.com/go-gitea/gitea/releases/tag/v1.19.0-rc0).
Because HTML returned is so fragile, it's ~~possible~~probable that the web
page scraping breaks with other versions. With any luck, an API will be available
before that happens, but who knows. To save you reading the code, the technique
used is to visit the URL `https://git.lerch.org/<owner>/<repo>/actions?state=closed[&workflow=<workflow>.yaml]`.
When the html is returned, the code finds the first instance of an element
with a `commit-status` CSS class, then captures whether it should be red or green
(these are the names of two other CSS classes used). Green is success, red
is either failed or canceled. All this fragility is in the `parseResponse`
function starting line 19 below.

```javacript
export default {
  async fetch(request, env) {
    const getOrigin = function(components) {
        console.log(components);
        const owner = components[1];
        const repo = components[2];
        let workflow = components.length >= 4 ? components[3] : "";
        if (workflow && !workflow.endsWith('.yaml')){
          workflow = workflow + '.yaml';
        }
        console.log('owner: ' + owner);
        console.log('repo: ' + repo);
        console.log('workflow: ' + workflow);
        console.log('workflow length: ' + workflow.length);
        const query = '?state=closed' + (workflow ? `&workflow=${workflow}` : '');
        return `https://git.lerch.org/${owner}/${repo}/actions${query}`;
    }

    const parseResponse = function(text) {
      const regexp = /commit-status.*icon (green|red)/;
      const match = text.match(regexp);
      console.log(match);
      if (!match) { return null };
      const textStatus = match[1];
      if (textStatus === 'green') return 'succeeded';
      if (textStatus === 'red') return 'failed';
      console.log('unexpected action icon status: ' + textStatus);
      return null;
    }

    try {
      const { pathname } = new URL(request.url);
      const components = pathname.split("/");
      if (components.length < 3 || !components[2]){
        return new Response("usage: /<owner>/<repo>[/workflow]\nNOTE: workflow does not require .yaml extension", {status: 404});
      }
      const origin = getOrigin(components);
      console.log(origin);
      const originResponse = await fetch(origin);
      if (originResponse.status != 200){
        return originResponse;
      }
      const status = parseResponse(await originResponse.text());
      let badgeUrl = 'https://img.shields.io/badge/build-';
      if (!status) {
        badgeUrl += 'unknown-blueviolet'
      }
      badgeUrl += status + '-';
      badgeUrl += (status === 'succeeded' ? 'success' : 'red');
      badgeUrl += '?logo=gitea';
      console.log(badgeUrl);
      return fetch(badgeUrl);
    } catch(e) {
      return new Response(e.stack, { status: 500 })
    }
  }

}
```
