---
title: "Recreating The Bad White House Chart In ggplot"
author: "Colin Fraser"
date: '2022-01-28'
slug: []
tags:
- r
- data-visualization
- ggplot2
categories: []
---

The White House Twitter account posted a bad chart today.

![The Bad Chart](images/FKHaZFyWYAAP962.jpeg)

In case you can't see it, the chart is bad because the Y-axis counts by 1's up to 5.0, and then inexplicably switches to .5's. I tweeted that I would not even know how to make such a chart.

 {{% tweet 1486773908502024192 %}} 
 
Unless the White House is drawing charts by hand in PowerPoint or something (which is possible), it would actually very hard to make a chart that does this. Most plotting software works hard to make sure that plot axes are drawn to some scale.

This of course made me want to see if I could recreate the plot in ggplot2. It turns out that it is possible, and although you have to really shoehorn it in there, ggplot2 is flexible enough to do it relatively straightforwardly.

