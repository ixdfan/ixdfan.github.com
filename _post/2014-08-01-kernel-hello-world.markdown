---
layout: post
title: 内核编程入门
description:  
modified: 
categories: 
- KERNEL
tags:
- 
---

编写一个hello模块

##### 第一步:构造Linux模块的框架

	
	/*	头文件init.h包含了宏__init和__exit	*/
	#include <linux/init.h>
	/*	所有模块都要使用头文件module.h，这个文件必须被包含进去	*/
	#include <linux/module.h>
	/*	头文件kernel.h包含了常用的内核函数	*/
	#include <linux/kernel.h>
	
	MODULE_LICENSE("GPL");		/*	公共许可证*/
	
	/*	模块的初始化函数	*/
	static int __init hello_init(void){
	  printk(KERN_ALERT "Hello, World\n");
	  return 0;
	}
	
	/*	模块的退出和清理函数	*/
	static void __exit hello_cleanup(void)
	{
	  printk(KERN_ALERT "Goodbye!\n");
	  
	}
	
	/*	驱动程序初始化入口点,对于内置模块，内核在引导时调用该入口点
	*	对于可加载模块则在该模块插入内核时才调用
	*/
	module_init(hello_init);
	/*	对于可加载的模块，内核会在此处调用cleanup_module()函数
	*	对于内置模块，就没有什么作用了
	*/
	module_exit(hello_cleanup);
	


在该驱动程序中，仅有一个初始化点(moudle_init函数)和一个清理点(module_exit函数),加载或卸载模块时候，内核会寻找这些函数

##### 第二步:编译模块


Makefile：

	obj-m += hello.o
	PWD:=$(shell pwd)
	LINUX_KERNEL_PATH:=/usr/src/kernels/`uname -r`
	
	all:
		$(MAKE) -C $(LINUX_KERNEL_PATH) SUBDIRS=${PWD} modules
		
	
	clean:
		rm -rf *.o *.core *.mod.c *.order *.symvers

-C选项告诉make程序在读取Makefile或做其他事情之前，先要改变Linux源目录，上面的是$(LINUX_KERNEL_PATH)所代表的目录

#####注意:
文件名一定要是Makefile，而不是makefile，否则会报错
有的同学可能/usr/src/kernels/下是空的，你可以安装kernel-devel即可

	[root@ hello]# make
	make -C /usr/src/kernels/`uname -r`   SUBDIRS=/root/work/kernel/hello modules
	make[1]: Entering directory `/usr/src/kernels/3.11.10-301.fc20.i686'
	Building modules, stage 2.
	MODPOST 1 modules
	make[1]: Leaving directory `/usr/src/kernels/3.11.10-301.fc20.i686'

此时形成了hello.ko模块

##### 第三步:运行代码

将新的模块插入到内核中,可以使用insmod命令
	
	insmod hello.ko

使用lsmod来检查模块是否被正确的插入到了内核中
	
	[root@ hello]# lsmod  | more 
	Module                  Size  Used by
	hello                  12396  0 


使用dmesg查看刚刚模块输出的信息
	
	[root@ hello]# dmesg | grep Hello
	[22489.052660] Hello, World

移除模块使用rmmod+模块名

	[root@ hello]# rmmod hello 
	[root@ hello]# dmesg | grep Good
	[22669.525695] Goodbye!


