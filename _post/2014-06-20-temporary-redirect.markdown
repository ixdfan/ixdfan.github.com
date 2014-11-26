---
layout: post
title: 临时重定向与永久重定向
description:  
modified: 
categories: 
- SHELL
tags:
- 
---

#### 临时重定向

如果你要故意在脚本中生成错误消息,可以将单独的一行出处重定向到STDERR,只要使用输出重定向符号来将输出重定向到STDERR,在重定向到STDERR时候,必须在文件描述符前加入&

	echo "This is an error message" >& 2

##### 不加&就变成了将其重定向到文件2中了

此时,这条消息会在STDERR中显示,如果使用标准输出重定向到文件,会发现文件内容是空的,只有将执行结果的错误重定向到文件才会显示

======

#### 永久重定向

如果脚本中有大量数据需要重定向,那么重定向每个echo语句就很烦琐,可以使用exec命令告诉shell在脚本执行七剑重定向某个特殊的文件描述符


	#!/bin/bash
	#filename:
	
	exec 1>testout	将标准输出重定向到文件,一下内容都输入到了文件中去
	echo "This is a test of redirecting all output"
	echo "from a script to another file"
	echo "witout having to redirecting every individual line"

======

#### 在脚本中重定向输入	
	
	exec 0< testfile

这个命令会告诉shell它应该从文件testfile中获取输入,而不是STDIN,这个重定向只要在脚本需要输入时就会有作用

	#!/bin/bash

	exec 0<testfile
	count=1
	while read line		#read会不断从testfile中读取,直到读取完毕
	do 
		echo "Line #$count: $line"
		count=$[$count + 1]
	done
