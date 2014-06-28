---
layout: post
title: 修改Linux默认编码
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
