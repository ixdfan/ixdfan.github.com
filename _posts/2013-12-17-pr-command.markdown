---
author: UCSHELL
comments: true
date: 2013-12-17 04:36:15+00:00
layout: post
slug: pr%e5%91%bd%e4%bb%a4
title: pr命令
wordpress_id: 1285
categories:
- TOOL
---

pr命令：
	-l:在默认情况下pr中每个页面会包含66行文本，可以使用-l选项来进行指定每个页面的函数
	-h:选项，用户可以自定义标题，一般来讲每页的标题就是这个文档的文件名
	-t:使pr命令不显示标题
	-num:直接使用数字，表示用多少行来打印


    
    
    [root@localhost 02]# pr -h "CONF" test.txt
    
    
    2013-10-30 14:16                       CONF                       Page 1     
    如果不使用-h那么页面则会使用test.txt作为标题
    


pr还可以将文本分列打印

	[root@localhost 02]# pr -2 -h "CONF" test.txt
	则会打印成为两列


    
	    [root@localhost 02]# pr -5 -t linux.wiki 
	    Linux         term          computer      on            kernel.
	    is            referring     operating     the
	    a             to            systems       Linux
	    generic       Unix-like     based
	    [root@localhost 02]# cat linux.wiki
	    Linux
	    is
	    a
	    generic
	    term
	    referring
	    to
	    Unix-like
	    computer
	    operating
	    systems
	    based
	    on
	    the
	    Linux
	    kernel.
    
