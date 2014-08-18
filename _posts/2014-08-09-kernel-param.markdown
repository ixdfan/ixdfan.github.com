---
layout: post
title: 模块的参数传递
description:  
modified: 
categories: 
- KERNEL
tags:
- 
---


module_param制定模块参数，模块参数用于在加载模块时传递参数给模块

module_parm(name, type, perm)

- name 是参数名称
- type 是参数类型
- perm是参数访问权限


type常见类型

- bool  布尔型
- int   整型
- charp 字符串


perm常用:

- S_IRUGO:任何用户都对/sys/module中出现的该参数具有读权限
- S_IWUSR:允许root用户修改/sys/modules中出现的该参数

	
	#include <linux/module.h>
	#include <linux/init.h>
	
	int age = 30;
	char* name = "hello";
	
	module_param(age, int, S_IRUGO);
	module_param(name, charp, S_IRUGO);
	static int __init param_init(void)
	{
		printk(KERN_EMERG"Age: %d\n", age);
		printk(KERN_EMERG"Name: %s\n", name);
		return 0;
	}
	
	static void __exit param_exit(void)
	{
		printk(KERN_INFO"Module Exit\n");
	
	}
	
	module_init(param_init);
	module_exit(param_exit);
	
加载
	[root@ hello]# insmod param.ko 
	[root@ hello]# 
	Message from syslogd@localhost at Fri Aug 15 12:38:48 2014 ...
	localhost klogd: [ 8977.569104] Age: 30
	
	Message from syslogd@localhost at Fri Aug 15 12:38:48 2014 ...
	localhost klogd: [ 8977.569111] Name: hello
	

*参数的使用:*

使用时候，不能向命令行一样直接传递参数，而是要[参数名=值]的形式来传递
	
	[root@ hello]# insmod param.ko age=1000
	[root@ hello]# 
	Message from syslogd@localhost at Fri Aug 15 12:41:52 2014 ...
	localhost klogd: [ 9161.606166] Age: 1000
	
	Message from syslogd@localhost at Fri Aug 15 12:41:52 2014 ...
	localhost klogd: [ 9161.606174] Name: hello

	[root@ hello]# insmod param.ko name="test"
	[root@ hello]# 
	Message from syslogd@localhost at Fri Aug 15 12:43:16 2014 ...
	localhost klogd: [ 9245.755232] Age: 30

	Message from syslogd@localhost at Fri Aug 15 12:43:16 2014 ...
	localhost klogd: [ 9245.755242] Name: test


module_param中的权限

	/*读写可执行RWX，U代表宿主*/
	#define S_IRWXU 00700
	/*只有读权限，USR为全写*/
	#define S_IRUSR 00400
	#define S_IWUSR 00200
	#define S_IXUSR 00100
	
	/*组用户*/
	#define S_IRWXG 00070
	#define S_IRGRP 00040
	#define S_IWGRP 00020
	#define S_IXGRP 00010
	
	/*other用户*/
	#define S_IRWXO 00007
	#define S_IROTH 00004
	#define S_IWOTH 00002
	#define S_IXOTH 00001
	
模块数组参数声明

	module_param_array(name, type, nump, perm)

nump:一般设置为NULL

	int array[2] = {100, 200};
	module_param_array(array, int, NULL, S_IRWXU)
	
	int __init param_init(void)
	{
		printk("%d, %d\n", array[0], array[1]);
	}
	
	insmod param.ko array=100, 300
	
直接为数组赋值即可


加载模块后会在/sys/module/module_name/parameters的文件夹

这个文件夹下存在的文件就是以你模块参数命名的，并且每个文件的属性与你设置的是相同的

可以使用

	echo 参数 > 参数所在的文件

可以在退出模块中打印一下参数查看是否修改成功了

模块参数:

内核提供了一种机制，在用户控件可以修改内核模块中全局变量的值

