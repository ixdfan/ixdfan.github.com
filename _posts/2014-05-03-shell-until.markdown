---
layout: post
title: until语法
description: 
modified: 
categories: 
- shell
tags:
- 
---

	until
		命令表1
	test 表达式 
	do
		命令表2
	done

* 命令表1在循环开始前执行，且每一次循环结束后再次执行

* 表达式作为循环控制条件.

* do..done之间为until循环的循环体，每次循环时执行其中的命令表2

* until循环结束后将执行done后的语句


until执行的步骤:

执行命令表1，并检测表达式的值，若表达式非0,则执行循环体命令表2一次，然后返回再次执行命令表1，并再次检验表达式的值，反复，直到表达式为0,循环结束



	#!/bin/bash
	i=1
	echo "enter N"
	read N
	until
		echo "hello"	#hello输出次数比下面的echo多1
	test $i -gt $N	#检测条件是i<N就执行
	do
		RESULT=`expr $i \* $i`	
		echo "$i--------------$RESULT"
		i=$(($i+1))
	done
	
