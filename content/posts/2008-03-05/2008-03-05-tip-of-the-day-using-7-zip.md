+++
title = "Tip of the day using 7-Zip"
slug = "2008-03-05-tip-of-the-day-using-7-zip"
published = 2008-03-05T07:28:00-08:00
author = "Emil"
tags = [ "Tools",]
+++
I just stumbled across some interesting behavior in 7-Zip. Not sure why
this is how it works, but if you drag and drop a file from 7-Zip into a
directory to extract, the extract will first go to the temporary
directory and then be copied over into the destination file. If you
click the "Extract" button and select the directory, the file is
extracted directly in the destination directory.
