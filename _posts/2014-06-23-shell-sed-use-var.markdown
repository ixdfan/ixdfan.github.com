---
layout: post
title: sed中使用变量
description:  
modified: 
categories: 
- SED
tags:
- 
---

经常使用sed的常量替换,今天用到了变量,但是突然他就不好使了!


	echo "http://www.abc.com/index.html" | sed 's#/index.html##'

这样直接使用是没有问题的,但是我想将其作为变量使用,以便灵活的修改内容

	var="/index.html"
	echo "http://www.abc.com/index.html" | sed 's#$var##'

这样就不行了!


解决办法
		
		sed 's#'$var'##'即可
或
		sed "s#$var##"	
		这个就相当与是echo中的双引号

