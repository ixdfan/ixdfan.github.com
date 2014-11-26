---
layout: post
title: C风格的for
description:  
modified: 
categories: 
- SHELL
tags:
- 
---


c语言风格的for循环格式如下:

	for (( variable assigment; condition; iteration process))

####注意:
C语言风格的for与bash中的for有些不同,主要是一下不同:
#####1.给变量赋值可以有空格
#####2.条件中的变量不以$开头
#####3.迭代过程不用expr格式
	
	#!/bin/bash
	#filename:
	
	for (( i = 1; i <= 10; i++))
	do
		echo "The next number is $i"
	done

使用多个变量

	#!/bin/bash
	#filename:
	
	for (( a = 1, b = 10; a <= 10 && b >= 4; a++, b++))
	do
		echo "$a - $b"
	done





