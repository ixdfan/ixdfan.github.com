---
layout: post
title: 内核中经常出现的宏
description:  
modified: 
categories: 
- KERNEL
tags:
- 
---

#### __init

__init告诉编译器相关的函数或变量仅仅用于初始化。编译器将标有__init的所有代码存储到特殊的内存段中，初始化结束后就释放这段内存

__init表示其后的函数位于代码段中的初始化代码段，初始化代码段中的函数只执行一次，执行后就回收这段内存



__exit和__exitdata仅仅用于退出和关闭例程，一般在注销设备驱动程序时候才使用


#### likely()和unlikely()

宏likely()和unlikely()提示编译器和芯片集，它尝试预测即将到来的命令，以便达到最快的速度。

宏likely()和unlikely()允许开发者通过编译器告诉CPU:某一段代码很可能被执行，因而应该被预测到;某一段代码很可能不被执行，不必预测

例如以下代码:

	90 asmlinkage long sys_gettimeofday(struct timeval __user *tv, struct timezone __user *tz)
	91 {
			/*tv非空是可能的*/
	92     if (likely(tv != NULL)) {
	93         struct timeval ktv;
	94         do_gettimeofday(&ktv);
	95         if (copy_to_user(tv, &ktv, sizeof(ktv)))
	96             return -EFAULT;
	97     }
			/*tz非空是不可能的*/
	98     if (unlikely(tz != NULL)) {
	99         if (copy_to_user(tz, &sys_tz, sizeof(sys_tz)))
	100             return -EFAULT;
	101     }
	102     return 0;
	103 }

获得时间的系统调用可能(likely)有一个非空的timeval结构，如果他为空，那么就没有办法填入所请求的时间，时区timezone结构不可能是非空(unlikely),这段话的意思其实就是我们通常更多的是查询时间，很少会查询时区


#### IS_ERR和PTR_ERR

宏IS_ERR将负的错误号编码成指针，宏PTR_ERR将该指针恢复成错误号

	19 static inline long PTR_ERR(const void *ptr)
	20 {
	21     return (long) ptr;
	22 }
	23 
	24 static inline long IS_ERR(const void *ptr)
	25 {
	26     return (unsigned long)ptr > (unsigned long)-1000L;
	27 }
	
