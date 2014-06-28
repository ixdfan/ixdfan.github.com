---
layout: post
title: trap处理信号
description:  
modified: 
categories: 
- SHELL
tags:
- 
---

trap命令允许指定shell脚本要观察那些Linux信号并从shell中拦截,如果脚本收到了trap命令中列出来的信号,他会阻止信号被shell处理,并在本地处理

trap的命令格式:
	
	trap "commands" signals

	[root@ script]# cat test.sh 
	#!/bin/bash
	#filename:
	
	trap "echo 'Sory! I have trapped Ctrl-C'" SIGINT SIGTERM
	echo "This is a test program"
	count=1
	while [ $count -le 10 ]
	do
		echo "Loop #$count"
		sleep 5
	done
	echo This is the end of the test program

trap命令会在每次检测到SIGINT或SIGTERM信号时候显示一行简单的文本,捕获这些信号会组织用户使用Ctrl+C命令来停止程序

	[root@ script]# ./test.sh 
	This is a test program
	Loop #1

	^CSory! I have trapped Ctrl-C
	Loop #2
	^CSory! I have trapped Ctrl-C
	Loop #3
	^CSory! I have trapped Ctrl-C
	Loop #4
	^CSory! I have trapped Ctrl-C
	Loop #5
	^CSory! I have trapped Ctrl-C
	Loop #6
	^CSory! I have trapped Ctrl-C
	Loop #7
	^CSory! I have trapped Ctrl-C
	Loop #8
	^CSory! I have trapped Ctrl-C
	Loop #9
	^CSory! I have trapped Ctrl-C
	Loop #10
	^CSory! I have trapped Ctrl-C
	This is the end of the test program


=====================

#### 捕获脚本的退出

要捕获shell脚本的推出,只要在trap命令后加入EXIT信号即可


	#!/bin/bash

	trap "echo ByeBye" EXIT

	count=1
	while [ $count -le 5 ]
	do
		echo "Loop #$count"
		sleep 3
		count=$[$count + 1]
	done

当脚本正常推出时候,shell会执行trap指定的命令,EXIT捕获即使是在提前推出脚本时也会工作.例如使用Ctrl+C发送SIGINT信号,脚本退出,但是在脚本退出前,shell执行了trap指令

==========

#### 移除捕获
可以使用单破折线作为命令,后面跟要移除的信号来移除这一组信号捕获,将其恢复到正常状态

	#!/bin/bash

	trap "echo ByeBye" EXIT
	count=1
	while [ $count -le 5 ]
	do
		echo "Loop #$count"
		sleep 3
		count=$[$count + 1]
	done
	trap -EXIT
	echo "I just removed the trap"

一旦信号捕获被移除了,脚本会忽略该信号,但是如果在捕捉被移除前收到信号,脚本就会在trap命令中处理它



