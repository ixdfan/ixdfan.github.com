---
layout: post
title:  shell中获取变量的长度
description: 
modified: 
categories: 
- shell 
tags:
- 
---

	var="1234567890"
	length=${#var}
	echo length


打印数组长度

	echo ${#array[*]}

打印数组中所有的值

	echo ${array[*]}
	或是
	echo ${array[@]}


列出数组索引

	echo ${!array[*]}
	或是
	echo ${!array[@]}
