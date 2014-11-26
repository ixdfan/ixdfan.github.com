---
layout: post
title: 查看系统的各种资源限制
description:  
modified: 
categories: 
- TOOL
tags:
- 
---

	[root@ linux-2.6.24]# cat /proc/self/limits 
	Limit                     Soft Limit           Hard Limit           Units     
	Max cpu time              unlimited            unlimited            seconds   
	Max file size             unlimited            unlimited            bytes     
	Max data size             unlimited            unlimited            bytes     
	Max stack size            8388608              unlimited            bytes     
	Max core file size        0                    unlimited            bytes     
	Max resident set          unlimited            unlimited            bytes     
	Max processes             15455                15455                processes 
	Max open files            1024                 4096                 files     
	Max locked memory         65536                65536                bytes     
	Max address space         unlimited            unlimited            bytes     
	Max file locks            unlimited            unlimited            locks     
	Max pending signals       15455                15455                signals   
	Max msgqueue size         819200               819200               bytes     
	Max nice priority         0                    0                    
	Max realtime priority     0                    0                    
	Max realtime timeout      unlimited            unlimited            us        

可以看到栈的最大值为8388608,约为8M,最大的进程数为15455,最大打开文件数为1024

栈的查看可以使用ulimit

	[root@ Linux]# ulimit -s
	8192

8192=838808/1024
