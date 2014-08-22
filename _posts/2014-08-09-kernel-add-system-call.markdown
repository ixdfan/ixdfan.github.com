---
layout: post
title: 添加一个新的系统调用
description:  
modified: 
categories: 
- KERNEL
tags:
- 
---

添加新的系统调用步骤：
- 编写系统服务例程
- 添加系统调用号
- 修改系统调用表
- 重新编译内核

#### 编写系统服务例程

	asmlinkage long sys_hello(void)
	{
		printk("Hello!\n");
		return 0;
	}

sys_hello实习的功能仅仅是打印一条语句，没有任何参数，如果希望使用我们传递的参数，则sys_hello可以这样写:

	asmlinkage long sys_hello(const char __user* _name)
	{
		char* name;
		long ret;

        name = strndup_user(_name, PAGE_SIZE);
		if (IS_ERR(name)) {
			ret = PTR_ERR(name);
			goto error;
	    }
		printk("Hello! %s\n", name);
		return 0;

	error:
		return ret;
	}
在有参数传递的情况下，编写系统调用服务例程时候必须仔细检查所有参数是否有效，因为系统调用在内核空间中执行，如果不加限制任用用户应用传递进入内核，则系统安全与稳定性将收到影响。

参数检查中最重要的一项是检查用户应用提供的用户空间指针是否有效，例如sys_hello函数的参数是char类型指针，并且使用了__user标记进行修饰。__user标记表示所修饰的指针为用户空间指针，不能在内核空间直接引用，主要原因:
- 用户空间指针在内核空间可能是无效的
- 用户空间的内存是分页的，可能引起页错误
- 如果直接引用成功，就相当于用户空间可以直接访问内核空间，会产生安全问题。

因此，为了能够完成必须的检查，以及在内核空间和用户空间之间安全的传送数据，就需要使用内核提供的函数，例如strndup_user函数，从用户空间复制字符串name的内容


然后在include/linux/syscalls.h文件中添加原型声明:

	asmlinkage long sys_hello(void);

#### 添加系统调用号

每个系统调用都有一个独一无二的系统调用号，所以要更新

	/include/asm-i386/unistd.h

为hello系统调用添加一个系统调用号

	283 #define __NR_get_mempolicy  275
	284 #define __NR_set_mempolicy  276
	285 #define __NR_mq_open        277
	286 #define __NR_mq_unlink      (__NR_mq_open+1)
	287 #define __NR_mq_timedsend   (__NR_mq_open+2)
	288 #define __NR_mq_timedreceive    (__NR_mq_open+3)
	289 #define __NR_mq_notify      (__NR_mq_open+4)
	290 #define __NR_mq_getsetattr  (__NR_mq_open+5)
	291 #define __NR_sys_kexec_load 283
	292 #define __NR_hello          284
	
	/*将系统调用数加1,改为285*/
	293 #define NR_syscalls 285

#### 修改系统调用表

为了让系统调用处理程序system_call函数能够找到hello系统调用，我们还需要修改系统调用表sys_call_table，放入sys_hello函数地址

	884     .long sys_mq_timedsend
	885     .long sys_mq_timedreceive   /* 280 */
	886     .long sys_mq_notify
	887     .long sys_mq_getsetattr
	888     .long sys_ni_syscall        /* reserved for kexec */
	889     .long sys_hello             /* hello系统调用服务例程 */
hello服务例程被添加到了sys_call_table末尾

#### 重新编译内核

对hello系统调用测试

	#include <unistd.h>
	#include <sys/syscall.h>
	#include <sys/types.h>

	#define _NR_hello 284

	int main(int argc, char* argv)
	{
		syscall(__NR_hello);
		return 0;
	}

编译执行
