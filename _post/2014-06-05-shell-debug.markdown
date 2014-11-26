---
layout: post
title:  shell脚本的调试
description: 
modified: 
categories: 
- shell 
tags:
- 
---


=======

####1. 使用set命令

set命令设置选项-x或是xtrace时候,在运行脚本的时候除了正常的出处之外,还会显示出代码运行前每行代码的扩展命令和变量,方便的观察脚本运行的情况,确定出错的位置

如果在脚本文件中加入命令 set -x,那么在set之后执行的每一条命令以及加在命令行中的任何参数都会被显示处理.每一行之前都会加上加号(+),提示塔式跟踪输出的标识,shell中执行的shell跟踪命令会加两个加号即"++"



	#!/bin/bash
	#filename:debug.sh
	#set -x		#此时set -x被注释掉了

	echo -n "Can you write device drivers? "
	read answer
	answer=`echo $answer | tr [a-z] [A-Z]`		#小写转大写
	
	if [ "$answer" = Y ] ; then					#$answer要使用"",否则输入为空的时候会显示错误
	
	    echo "Wow, you must be very skilled"
	else
	
	    echo "Neither can I, I'm just an example shell script"
	fi

输出如下

	[root@ script]# ./debug.sh 
	Can you write device drivers? y
	Wow, you must be very skilled
	[root@ script]# ./debug.sh 
	Can you write device drivers? n
	Neither can I, I'm just an example shell script


取消set -x的注释

	#!/bin/bash
	#filename:debug.sh
	set -x		#取消注释				

	echo -n "Can you write device drivers? "
	read answer
	answer=`echo $answer | tr [a-z] [A-Z]`		#小写转大写
	
	if [ "$answer" = Y ] ; then			#$answer要使用"",否则输入为空的时候会显示错误
	
	    echo "Wow, you must be very skilled"
	else
	
	    echo "Neither can I, I'm just an example shell script"
	fi

输出如下
	
	[root@ script]# ./debug.sh 
	+ echo -n 'Can you write device drivers? '
	Can you write device drivers? + read answer			#前部分为正常的输出
	y
	++ echo y			#++表示在shell中执行shell命令的跟踪调用
	++ tr '[a-z]' '[A-Z]'
	+ answer=Y
	+ '[' Y = Y ']'
	+ echo 'Wow, you must be very skilled'
	Wow, you must be very skilled
	[root@ script]# ./debug.sh 
	+ echo -n 'Can you write device drivers? '
	Can you write device drivers? + read answer
	n
	++ tr '[a-z]' '[A-Z]'
	++ echo n
	+ answer=N
	+ '[' N = Y ']'
	+ echo 'Neither can I, I'\''m just an example shell script'
	Neither can I, I'm just an example shell script




set中关闭-x选项的方法是使用+x来关闭,这样就可以从某个点关闭选项,这在只需要调试一小段代码时候是非常有用的,只需要在代码错误区之前打开选项,在错误区域关闭选项就可以完成调试,这样就不会让程序显示一大堆无用信息

	#!/bin/bash
	#filename:debug.sh
	set -x				#开启

	echo -n "Can you write device drivers? "
	read answer
	answer=`echo $answer | tr [a-z] [A-Z]`		#小写转大写
	set +x				#在此处关闭, 一下内容不会跟踪
	if [ "$answer" = Y ] ; then					#$answer要使用"",否则输入为空的时候会显示错误
	
	    echo "Wow, you must be very skilled"
	else
	
	    echo "Neither can I, I'm just an example shell script"
	fi

输出

	[root@ script]# ./debug.sh 
	+ echo -n 'Can you write device drivers? '
	Can you write device drivers? + read answer			#前部分为正常的输出
	y
	++ echo y				#++表示在shell中执行shell命令的跟踪调用
	++ tr '[a-z]' '[A-Z]'
	+ answer=Y
	+ set +x				#set +x关闭了跟踪
	Wow, you must be very skilled
	[root@ script]# ./debug.sh 
	+ echo -n 'Can you write device drivers? '
	Can you write device drivers? + read answer
	n
	++ echo n
	++ tr '[a-z]' '[A-Z]'
	+ answer=N
	+ set +x
	Neither can I, I'm just an example shell script

=======================

####2. echo简单的输出

	#!/bin/bash
	#filename:debug.sh
	set -x				#开启

	echo -n "Can you write device drivers? "
	read answer
	answer=`echo $answer | tr [a-z] [A-Z]`		#小写转大写
	set +x				#在此处关闭, 一下内容不会跟踪
	if [ "$answer" = Y ] ; then					#$answer要使用"",否则输入为空的时候会显示错误
	
	    echo "Wow, you must be very skilled"
		echo "The answer is $answer"
	else
	
	    echo "Neither can I, I'm just an example shell script"
		echo "The answer is $answer"
	fi

但是这种方法很繁琐,每次用完后还要再删除echo的输出

=======================

####3. echo调试层次输出

	
	#!/bin/bash
	debug=1		#一键开启调试信息
	test "$debug" -gt 0 && echo "Debug is on"
	echo -n "Can you write device drivers? "
	read answer
	test "$debug" -gt 0 && echo "The answer is $answer"
	answer=`echo $answer | tr [a-z] [A-Z]`
	
	if [ "$answer" = Y ] ; then		
	
	    echo "Wow, you must be very skilled"
		test $debug -gt 0 && echo "The answer is $answer"
	else
	
	    echo "Neither can I, I'm just an example shell script"
		test $debug -gt 0 && echo "The answer is $answer"
	fi


使用debug来开启或是关闭调试信息的输出,并且可以按照层次来显示信息,例如test $debug -gt 2,则将debug改为对应层次的值即可实现不同层次的输出
