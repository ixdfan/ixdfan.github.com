---
author: UCSHELL
comments: true
date: 2013-10-11 06:24:31+00:00
layout: post
slug: '%e4%bf%ae%e6%94%b9linux%e9%bb%98%e8%ae%a4%e7%bc%96%e7%a0%81'
title: 修改Linux默认编码
wordpress_id: 828
categories:
- TOOL
---
##### 方法1:
    vi /etc/sysconfig/
    
默认为:

	LANG="en_US.UTF-8"
    
修改为:

	LANG="zh_CN.UTF-8"

##### 方法2：

    vi /etc/profile
    export LC_ALL="zh_CN.UTF-8"
    export LANG="zh_CN.UTF-8"
