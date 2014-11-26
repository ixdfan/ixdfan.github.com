---
layout: post
title: 系统变量current的使用
description:  
modified: 
categories: 
- KERNEL
tags:
- 
---

current系统变量指向当前执行程序的task_struct，内核是一系列有序而不断变化的连环结构，随着程序运行这些结构而被创建与销毁
可以通过查看task_struct结构来使用其中的变量，比如我们就使用了pid和comm

	/*
	* currentptr.c
	* 内核版本号 3.11.10
	* 显示当前进程的名字，父进程的名字
	*/
	#include <linux/module.h>
	#include <linux/kernel.h>
	#include <linux/init.h>
	#include <linux/sched.h>
	#include <linux/tty.h>
	
	
	void tty_write_message1(struct tty_struct*, char* );
	void tty_write_message1(struct tty_struct* tty, char* msg)
	{
		if (tty && tty->ops->write)
		{
			tty->ops->write(tty, msg, strlen(msg));
			
		}
		return ;
	}
	
	static int my_init(void)
	{
		char* msg = "Hello tty!";
		printk("Hello, from the kernel...\n");
		
		printk("parent pid = %d(%s)\n", current->parent->pid, current->parent->comm);
		printk("currnet pid = %d(%s)\n", current->pid, current->comm);
	
		/*	获取该程序所在tty，并将msg在tty上打印出来	*/
		tty_write_message1(current->signal->tty, msg);
		return 0;
	}
	
	
	static void my_cleanup(void)
	{
		printk("Goodbye, from the kernel...\n");
	}
	
	module_init(my_init);
	module_exit(my_cleanup);
	
	

Makefile:

	obj-m += currentptr.o
	PWD:=$(shell pwd)
	LINUX_KERNEL_PATH:=/usr/src/kernels/`uname -r`  #3.11.10-301.fc20.i686
	
	all:
		$(MAKE) -C $(LINUX_KERNEL_PATH) SUBDIRS=${PWD} modules
		
	
	clean:
		rm -rf *.o *.core *.mod.c *.order *.symvers	*.ko


dmesg中输出的结果

	[17611.767639] Hello, from the kernel...
	[17611.767641] parent pid = 1624(bash)
	[17611.767642] currnet pid = 26777(insmod)

