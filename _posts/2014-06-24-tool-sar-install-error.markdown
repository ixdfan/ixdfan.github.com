---
layout: post
title: 首次执行sar显示错误
description:  
modified: 
categories: 
- TOOL
tags:
- 
---

安装sar(yum install sysstat)后首次执行sar却显示如下错误

	sar error
	Cannot open /var/log/sa/sa17: No such file or directory
	

可以按照如下的方法解决

	sar -o 17

17是当天的日期,同时也是错误提示中的数字:Cannot open /var/log/sa/sa17


