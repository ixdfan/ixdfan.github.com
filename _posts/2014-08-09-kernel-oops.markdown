---
layout: post
title: 内核的异常分析
description:  
modified: 
categories: 
- KERNEL
tags:
- 
---


造成oops的原因很多，最简单的就是指针访问小于0xc0000000的地址，因为那里是用户空间的地址，内核不能够访问。

	/*
	* error.c
	*/
	#include <linux/module.h>
	#include <linux/kernel.h>
	#include <linux/init.h>
	#include <linux/sched.h>
	#include <linux/tty.h>
	#include <linux/proc_fs.h>
	
	void D()
	{
	        int* p = NULL;
	        int a = 6;
	        printk("Functino D\n");
	        *p = a + 5;
	}
	
	void C()
	{
	        printk("Functino C\n");
	        D();
	}
	
	
	void B()
	{
	        printk("Functino B\n");
	        C();
	}
	
	
	void A()
	{
	        printk("Functino A\n");
	        B();
	}
	
	
	
	int proc_init(void)
	{
	        printk("hello\n");
	        A();
	        return 0;
	}
	
	void proc_exit(void)
	{
	        printk("GoodBye");
	}
	
	
	module_init(proc_init);
	module_exit(proc_exit);
	
	

加载模块后会出现错误如图

![006]({{site.img_url}}/2014/08/006.png)

#### 错误原因:

BUG:unable to handle kernel NULL pointer dereference at (NULL)

说明出错的原因是对空指针的非法访问

#### 错误位置

IP: [<f912702f>] D+0xf/0x20 [error]

显示的是错误位置在D函数偏移0xf处


#### 反汇编找出出错位置

	[root@ hello]# objdump -D -S error.ko > log
	[root@ hello]# vim log

	error.ko:     file format elf32-i386
	
	
	Disassembly of section .note.gnu.build-id:
	
	00000000 <.note.gnu.build-id>:
	   0:	04 00                	add    $0x0,%al
	   2:	00 00                	add    %al,(%eax)
	   4:	14 00                	adc    $0x0,%al
	   6:	00 00                	add    %al,(%eax)
	   8:	03 00                	add    (%eax),%eax
	   a:	00 00                	add    %al,(%eax)
	   c:	47                   	inc    %edi
	   d:	4e                   	dec    %esi
	   e:	55                   	push   %ebp
	   f:	00 d9                	add    %bl,%cl
	  11:	5b                   	pop    %ebx
	  12:	e3 6f                	jecxz  83 <A+0x3>
	  14:	36                   	ss
	  15:	f1                   	icebp  
	  16:	13 18                	adc    (%eax),%ebx
	  18:	47                   	inc    %edi
	  19:	4b                   	dec    %ebx
	  1a:	34 e2                	xor    $0xe2,%al
	  1c:	52                   	push   %edx
	  1d:	88 ef                	mov    %ch,%bh
	  1f:	f0                   	lock
	  20:	20                   	.byte 0x20
	  21:	b8                   	.byte 0xb8
	  22:	e2 f2                	loop   16 <.note.gnu.build-id+0x16>
	
	Disassembly of section .text:
	
	00000000 <cleanup_module>:
		A();
		return 0;
	}
	
	void proc_exit(void)
	{
	   0:	83 ec 04             	sub    $0x4,%esp
		printk("GoodBye");
	   3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
	   a:	e8 fc ff ff ff       	call   b <cleanup_module+0xb>
	}
	   f:	83 c4 04             	add    $0x4,%esp
	  12:	c3                   	ret    
	  13:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
	  19:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
	
	00000020 <D>:
	#include <linux/sched.h>
	#include <linux/tty.h>
	#include <linux/proc_fs.h>
	
	void D()
	{
	  20:	83 ec 04             	sub    $0x4,%esp
		int* p = NULL;
		int a = 6;
		printk("Functino D\n");
	  23:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
	  2a:	e8 fc ff ff ff       	call   2b <D+0xb>
		*p = a + 5;
	  2f:	c7 05 00 00 00 00 0b 	movl   $0xb,0x0
	  36:	00 00 00 
	}
	  39:	83 c4 04             	add    $0x4,%esp
	  3c:	c3                   	ret    
	  3d:	8d 76 00             	lea    0x0(%esi),%esi

可以看到D函数的起始位置是00000020,而其偏移0xf处就是0000002f处，此处代码为

	*p = a + 5;

所以可以看到出错的地方了

