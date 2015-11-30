# blog
Source for blog material

This is a [hugo](https://github.com/spf13/hugo) structure. On a unix-y system, create a new file with:

```
hugo new posts/`date +%Y-%m-%d`-My-Post-Title.md
```

Serve the site with:

```
hugo serve --theme=gindoro --buildDrafts
```

The [modified gindoro theme used for this site](https://github.com/elerch/gindoro)
should be cloned into the themes subdirectory.

Note that both this site and the modified gindoro theme requires hugo 0.15 or higher.
