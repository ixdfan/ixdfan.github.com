---
layout: post
title:  shell比较运算的错误
description: 
modified: 
categories: 
- shell 
tags:
- 
---



	#!/bin/bash
	#filename:ifelse.sh
	
	a=$1
	if [ $a = "YES" -o $a = "yes" ]; then
		echo "yes"
	else
		if [ $a = "NO" -o $a = "no" ];then
			echo "no"
		else
			echo "error"
		fi
	fi
	
	
以上代码看似是没有问题的，但是执行会显示too many arguments

	[root@ 05]# ./ifelse.sh 
	./ifelse.sh: line 5: [: too many arguments
	./ifelse.sh: line 8: [: too many arguments
	error
	

原因在于输入的没有参数使得$1为空白，由于没有使用双引号，所以bash认为放括号中变量过多，可以使用双引号将变量扩起来


	#!/bin/bash
	#filename:
	
	a=$1
	if [ "$a" = "YES" -o "$a" = "yes" ]; then
		echo "YES"
	else
		if [ "$a" = "NO" -o "$a" = "no" ]; then
			echo "NO"
		else
			echo "error"
		fi
	fi
