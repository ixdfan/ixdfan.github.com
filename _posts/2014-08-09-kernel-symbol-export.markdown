---
layout: post
title: 内核符号表的导出
description:  
modified: 
categories: 
- KERNEL
tags:
- 
---

#### 内核符号导出的步骤
- 1.定义要导出的函数
- 2.使用EXPORT_SYMBOL(函数名)导出定义的内核符号


	/*
	* calculate.c
	*/
	#include <linux/init.h>
	#include <linux/module.h>
	
	int add_integar(int a, int b)
	{
		return a + b;
	}
	
	int sub_integar(int a, int b)
	{
		return a - b;
	}
	
	static int __init sys_init(void)
	{
		return 0;
	}
	
	static void __exit sys_exit(void)
	{
		
	}

	/*导出符号表add_integar和sub_integar*/
	//EXPORT_SYMBOL(add_integar);
	//EXPORT_SYMBOL(sub_integar);
	
	module_init(sys_init);
	module_exit(sys_exit);
	
	/*
	* int.c
	*/
	#include <linux/init.h>
	#include <linux/module.h>
	
	extern int add_integar(int a, int b);
	extern int sub_integar(int a, int b);
	
	
	static int __init int_init(void)
	{
		int a = 1;
		int b = 2;
		int c = add_integar(a, b);
		sub_integar(a, b);
		printk("add_integar(1, 2) = %d\n", c);
		return 0;
	}
	
	static void __exit int_exit(void)
	{
		
	}
	
	module_init(int_init);
	module_exit(int_exit);


此时有两个模块分别是calculate模块和int模块，但是int模块中声明的函数add_integar和sub_integar函数不是在另一个文件中，而是在另一个模块中！

分别编译两个模块，将calculate模块先加载，然后在加载int模块，会看到出现错误
	
	[root@ hello]# insmod calculate.ko 
	[root@ hello]# insmod int.ko 
	insmod: ERROR: could not insert module int.ko: Unknown symbol in module

意思是加载int.ko时候在int模块中有未知的符号表即函数add_integar和函数sub_integar，因为这两个函数在另一个模块中，我们又没有对其进行导出所以出现错误


-------------------------------------------------------------------------------

查看导出了那些符号表

文件/proc/kallsyms就是导出的符号表

	[root@ hello]# cat /proc/kallsyms  | more
	c0400000 T startup_32
	c0400000 T _text
	c04000e0 t bad_subarch
	c04000e0 W xen_entry
	c04000e4 T start_cpu0
	c04000f4 T startup_32_smp
	c0400110 t default_entry
	c0400188 t enable_paging
	c0400203 t is486
	c040025c t verify_cpu
	c04002a6 t verify_cpu_noamd
	c04002e4 t verify_cpu_clear_xd
	c04002f3 t verify_cpu_check
	c0400325 t verify_cpu_sse_test
	c040034b t verify_cpu_no_longmode
	c0400352 t verify_cpu_sse_ok
	c0400358 T _stext
	c0400360 T do_one_initcall
	c04004f0 t match_dev_by_uuid
	c0400520 T name_to_dev_t
	c04008c0 T calibrate_delay
	c0400df0 T lgstart_cli
	c0400dfa T lgend_cli
	c0400dfa T lgstart_pushf
	c0400dff T lgend_pushf
	c0400e00 T lg_irq_enable
	c0400e17 t send_interrupts
	c0400e24 T lg_restore_fl
	c0400e34 T lguest_iret
	c0400e39 T lguest_noirq_start
	c0400e41 T lguest_noirq_end
	c0400e50 t __raw_callee_save_save_fl
	c0400e58 t __raw_callee_save_irq_disable
	c0400e60 t save_fl
	c0400e70 t irq_disable
	c0400e90 t lguest_load_idt
	

	[root@ hello]# cat /proc/kallsyms  | grep add_integar
	f7d27000 t add_integar	[calculate]
	[root@ hello]# cat /proc/kallsyms  | grep sub_integar
	f7d27010 t sub_integar	[calculate]

虽然可以找到add_integar这些函数，但是其并没有被导出

去掉calculate.c中的注释，重新编译并加载

	[root@ hello]# cat /proc/kallsyms | grep add_integar
	f7e49024 r __ksymtab_add_integar	[calculate]
	f7e49040 r __kstrtab_add_integar	[calculate]
	f7e48000 T add_integar	[calculate]
	[root@ hello]# cat /proc/kallsyms | grep sub_integar
	f7e4902c r __ksymtab_sub_integar	[calculate]
	f7e49034 r __kstrtab_sub_integar	[calculate]
	f7e48010 T sub_integar	[calculate]


其中__ksymtab_add_integar表明内核符号add_integar已经导出

此时在加载int模块则正确
