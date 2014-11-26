---
layout: post
title:  function
description: 
modified: 
categories: 
- shell
tags:
- 
---

函数定义的格式

	[function] 函数名
	{
		命令表
		[return]
	}
	

	[root@ 06]# function showuser()
	> {
	> date
	> echo -n "当前登录用户名: "
	> echo "$LOGNAME"
	> }
	[root@ 06]# showuser
	Mon May  5 10:57:48 CST 2014
	当前登录用户名: root

通过命令行定义的函数在用户推出登录时将自动删除，如果希望函数总是可用，而不是每次登录都要重新输入，可以将函数的定义放在~/.bash_profile中，使用sourc或.使之立即生效。



第一次写函数的时候出现了一下的错误

	syntax error: unexpected end of file



	#!/bin/bash
	
	function showmessage ()
	{
		echo "当前登录用户名: "
		echo "$LOGNAME "
	}
	
	echo "----第一次调用----"
	
	showmessage ()
	
	#echo "----第二次调用----"
	
错误就在于调用showmessage函数的时候加上了()，去掉括号就OK，真坑我！！！	


#### 函数参数的传递

函数可以通过位置变量来传递参数，位置变量是依据出现在函数名之后的参数的位置来确定的变量
	
	函数名 参数1 参数2 参数3

当函数被执行时，会将位置变量与调用该函数的命令行中的每一个参数关联，依次是

$1:对应第1个位置参数

$2:对应第2个位置参数

$3:对应第3个位置参数

......

$9:对应第9个位置参数


	#!/bin/bash
	
	function show ()
	{
		echo $a $b $c $d
		echo $1 $2 $3 $4
	}
	
	a=111
	b=222
	c=333
	d=444
	
	echo "Function Begin"
	show a b c d 
	echo "-------------"
	show $a $b $c $d 
	
	echo "Function End"


程序输出:
	

	[root@ 06]# ./func.sh
	Function Begin
	111 222 333 444
	a b c d		#这里$1 $2对应的是变量的名字，因为传入的并不是值$a
	-------------
	111 222 333 444
	111 222 333 444
	Function End



	#!/bin/bash
	#filename:
	
	function verify()
	{
		if [ "$1" = "root" -a "$2" = "1234" ] ; then
			echo "pass"
		else
			echo "Reject!wrong account!"
		fi
	}
		
	verify $1 $2	#将命令行中的参数传入




	#!/bin/bash
	
	function stringcat ()
	{
		echo $1$2
	}
	
	echo "Enter first string"
	read STR1
	echo "Enter second string"
	read STR2
	echo "stringcat..."
	stringcat STR1 STR2	#输出的是参数的名字
	stringcat $STR1 $STR2
	

	执行结果

	[root@ 06]# ./strcat.sh
	Enter first string
	123
	Enter second string
	456
	stringcat...
	STR1STR2
	123456


#### 函数的载入:

函数的定义可以放在~/.bash_profile文件中，或者是直接放入命令行中，也可以放在脚本文件中，可以通过source命令来把他们装入内存，以供当前脚本使用。


	#!/bin/bash
	#filename:square.sh
	
	function square
	{
		local temp
		let temp=$1*$1
		echo "$1平方是: $temp"
	}
	
	function cube
	{
		local temp
		let temp=$1*$1*$1
		echo "$1立方是: $temp"
	}
	
	

	#!/bin/bash
	#filename:source.sh
	
	source square.sh	#使用source命令将函数装入内存中去。
	echo "请输入一个整数:"
	read N
	i=1
	while [ $i -le $N ] 
	do
		square $i
		i=$(($i+1))
	done
	echo "-----------"
	i=1
	while [ $i -le $N ]
	do
		cube $i
		i=$(($i+1))
	done
	


#### 函数的删除

使用命令

	unset -f 函数名

可以从shell内存中删除函数

	declare -f
	查看内存中存在的shell函数


#### 函数的作用域

全局变量可以在主程序中定义，可以在函数中定义

	function testvar ()
	{
		a="这是在函数中定义的全局变量"
		echo "在函数中输出: $a"
	}

	testvar
	echo "在主程序中输出: $a"


在函数中使用关键字local声明的变量为函数的局部变量，局部变量的作用域限制在本函数内

	function testvar()
	{
		local a="这是在函数中定义的局部变量"
		echo "在函数中输出: $a"
	}

	testvar
	echo "在主程序中输出: $a"	# 执行时，$a为空


#### 函数嵌套

	function first 
	{
		function second 
		{
			function third 
			{
				echo "这是第三层"
			}

			echo "这是第二层"
			third
		}
		echo "这是第一层"
		second
	}

	echo "开始函数调用"
	first



	[root@ 06]# ./func.sh
	开始函数调用
	这是第一层
	这是第二层
	这是第三层
	
	
#### 函数的递归

	#!/bin/bash
	#filename:
	
	function reverse ()
	{
		local t
		echo $1
		if [ $1 -gt 0 ] ; then 
			t=$(($1-1))
			reverse $t
		fi
	}

reverse 10


