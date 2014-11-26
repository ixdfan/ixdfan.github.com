---
layout: post
title: 使用for遇到的问题
description:  
modified: 
categories: 
- SHELL
tags:
- 
---


在一个带有for的程序中,如下

	#!/bin/bash
	#filename:
	
	for test in I don't know if this'll work
	do
		echo "word: $test"
	done


输出的结果却是这样的

	[root@ script]# ./test.sh 
	word: I
	word: dont know if thisll
	word: work

for默认使用空格来区分每个值的,但是遇到了',就会出问题了!

解决方法:

	#!/bin/bash
	#filename:
	
	for test in I don\'t know if "this'll" work
	do
		echo "word: $test"
	done

使用反斜杠和""均可以解决问题


有时候有的词本身就带有空格,例如

	#!/bin/bash
	#filename:
	
	for test in Nevada New York North Carolina
	do
		echo "word: $test"
	done


像New York,North Carolina就是一个词组,但是这样输出的结果并不是我们期望的

解决办法:如果单独的数据值中有空格,使用双引号将这些值圈起来

	#!/bin/bash
	#filename:
	
	for test in Nevada "New York" "North Carolina"
	do
		echo "word: $test"
	done

#### 注意:
当在某个值的两边使用双引号时候,shell不会将双引号当成值的一部分
