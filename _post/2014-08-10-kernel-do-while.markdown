---
layout: post
title: 内核中的do_while(0)的作用
description:  
modified: 
categories: 
- KERNEL
tags:
- 
---


例如有一个宏

	#define FILL(n, val)	\
	do {			\
		memset(p, val, n);	\
		p += n;		\
	} while(0)		\

例子:

	if (flag == 1) 
		FILL(10, 100);
	
	这个会被替换成
	if (flag == 1) 
		do {			\
			memset(p, val, n);	\
			p += n;		\
		} while(0)		\

如果没有do...while(0)的话

	if (flag == 1) 
		memset(p, val, n);	
		p += n;
		
则memset可能会执行，p+=n必定会执行

