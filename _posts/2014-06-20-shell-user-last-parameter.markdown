---
layout: post
title: shell中获取最后一个参数
description:  
modified: 
categories: 
- SHELL
tags:
- 
---

$#代表传入的参数的个数,那么如何取得最后一个参数呢?

	#!/bin/bash

	echo "The last parameter is ${$#}"

但是执行结果显然是错误的将其改为${!#}即可正常显示

或先将$#赋值给变量,在使用${变量名}的方式也可以访问最后一个参数
