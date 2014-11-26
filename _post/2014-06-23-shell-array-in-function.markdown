---
layout: post
title: 在函数中使用数组
description:  
modified: 
categories: 
- SHELL
tags:
- 
---
#### 向函数传递数组

如果试图将数组变量当成一个函数参数,那么函数只会取得数组变量的第一个值

	#!/bin/bash
	
	function fun {
		echo "the parameters are: $@"
		thisarray=$1
		echo "The received array is ${thisarray[*]}"
	}
	
	myarray=(1 2 3 4 5)
	echo "The original array is : ${myarray[*]}"
	fun $myarray

	[root@ script]# ./test5
	The original array is : 1 2 3 4 5
	the parameters are: 1
	The received array is 1


要解决这个问题,必须将该数组变量的值分解为单个值然后将这些值作为函数参数使用,在函数内部,在将所有参数重组到新的数组变量中

	function fun {
		local newarray
		newarray=(`echo "$@"`)	#书上要求这样写
		#newarray=$@	#这样也可以
		echo "The new array value is ${newarray[*]}"
	}
	
	myarray=(1 2 3 4 5)
	echo "The original array is : ${myarray[*]}"
	fun ${myarray[*]}	#将每个元素都作为参数传过去

这个脚本使用$myarray变量来保存所有的数组元素,然后将其都放在该函数的命令行上,之后该函数从命令行参数重建该数组变量,在函数内部,数组正常使用

===================

####从函数返回数组

	#!/bin/bash
	
	function arraydblr {
		local origarray
		local newarray
		local elements
		local i
		original=(`echo "$@"`)
		newarray=(`echo "$@"`)
		elements=$[$# - 1]
	
		for ((i=0; i <= $elements; i++)) {
			newarray[$i]=$[ ${original[$i]} * 2]
		}
		echo ${newarray[*]}
	}
	
	myarray=(1 2 3 4 5)
	echo "The original array is : ${myarray[*]}"
	arg=`echo ${myarray[*]}`
	result=(`arraydblr $arg`)
	echo "the new array is : ${result[*]}"

该脚本用$arg变量将数组值传递给arraydblr函数,arraydblr函数将该数组重组到新的数组变量中,并将数组中的数值翻倍存到newarray,之后利用echo语句输出数组中的每个值,result利用arraydblr最后的输出重新生成新的数组
