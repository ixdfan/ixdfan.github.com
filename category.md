---
layout: page
permalink: /category/
title: Category
modified: 9-9-2013
image:
  feature: texture-feature-02.jpg
  credit: Texture Lovers
  creditlink: http://texturelovers.com
---


{% for category in site.categories %}
<h2><a name={{ category | first }}>{{ category | first }}<span style="margin-left:5px;">({{ category | last | size }})</span></a></h2>
<ul class="arc-list">
{% for post in category.last %}
<li style="width:600px;line-height:24px;"><a href="{{ post.url }}" style="border:none;">{{ post.title }}</a><span style="float:right;">{{ post.date | date:"%d/%m/%Y"}}</span></li>
{% endfor %}
</ul>
{% endfor %}
