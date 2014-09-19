---
layout: post
title: shell中的IFS
description:  
modified: 
categories: 
- SHELL 
tags:
- IFS
---

IFS最有用的是可以使得for命令将文件中的每一行都当作单独的一个条目来处理

默认情况下,bash会将一下字段刚做字段分隔符:

- 空格
- 制表符
- 换行符

IFS称为内部字段分隔符(internal field separator).IFS环境变量定义了bash中作用字段分隔符的一系列字符

如果bash在数据中看到了以上任意一个,它就会假定你在列表中开始了一个新的数据段.在处理含有空格的数据(例如文件名)时候非常麻烦

要解决这个问题,可以在shell脚本中临时更改IFS环境变量的值来限制被bash当作字段分隔符的字符

例如:修改IFS的值使其只能识别换行符

	IFS=$'\n'		#这个写法有点奇怪

将以上语句加入到脚本中,告诉bash在数据值中忽略空格和制表符


	[root@ script]# cat test.sh 
	#!/bin/bash
	#filename:
	#IFS=$'\n'

	FILE="city"
	for test in `cat $FILE`
	do
		echo "word: $test"
		done

	[root@ script]# cat city 
	Beijing 
	New York
	[root@ script]# ./test.sh 
	word: Beijing
	word: New
	word: York


加入IFS=$'\n'之后的输出

	[root@ script]# ./test.sh 
	word: Beijing 
	word: New York


有时候需要用完之后还要改回IFS的默认值,那么可以在改变IFS之前将其保存

	IFS.OLD=$IFS
	IFS=$'\n'
	...
	IFS=$IFS.OLD


=======

如果你要遍历一个文件中使用冒号分割的值(例如/etc/passwd),那么就可以将IFS的值设定为冒号

	IFS=:

指定多个IFS字符,直接在其后添加即可,例如指定换行,冒行,分号,双引号
	
	IFS=$'\n':;"		#直接在其之后写即可


=======

#### 利用IFS处理文件

	[root@ script]# cat test.sh  
	#!/bin/bash
	#filename:

	IFS=$'\n'	#作用于第一个for循环
	for entry in `cat /etc/passwd`
	do
		echo "Values in $entry"
		IFS=:	#作用于第二个for循环
		for value in $entry
		do
			echo "$value"
		done
	done

	[root@ script]# ./test.sh  
	Values in root:x:0:0:root:/root:/bin/bash
	root
	x
	0
	0
	root
	/root
	/bin/bash
	Values in bin:x:1:1:bin:/bin:/sbin/nologin
	bin
	x
	1
	1
	bin
	/bin
	/sbin/nologin

这个脚本中对于两个for循环,采用两个IFS,对于第一个for,会解析/etc/passwd中的每一行,第二个for会解析储每行中每个单独的值


