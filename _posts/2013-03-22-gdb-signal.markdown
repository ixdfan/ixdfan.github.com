---
layout: post
title:  在gdb中发送信号
description: 
modified: 
categories: 
-  THE LINUX
tags:
- GDB

---

在gdb中如果直接使用Ctrl+c则会将信号直接传递给gdb，有时候我们希望将信号传递给调试中的程序;

我们可以直接使用gdb中自带的signal命令来向程序发送某个信号



	void handle(int s)
	{
		printf("信号干扰\n");	
	}
	
	int main(int argc, char** argv)
	{
		sigset_t sigs;
		sigemptyset(&sigs);
		signal(SIGINT, handle);
	
		sigsuspend(&sigs);
		printf("over\n");
	
		return 0;
	}
	
	
	

	[root@ signal]# gdb main -q
	Reading symbols from /root/work/High/signal/main...done.
	(gdb) b main
	Breakpoint 1 at 0x80484e0: file sigsuspend2.c, line 24.
	(gdb) b sigsuspend
	Breakpoint 2 at 0x8048390
	(gdb) r
	Starting program: /root/work/High/signal/main 
	
	Breakpoint 1, main (argc=1, argv=0xbffff2c4) at sigsuspend2.c:24
	24              sigemptyset(&sigs);
	Missing separate debuginfos, use: debuginfo-install glibc-2.18-11.fc20.i686
	(gdb) n
	25              signal(SIGINT, handle);
	(gdb) n
	27              sigsuspend(&sigs);
	(gdb) n
	
	Breakpoint 2, 0xb7e34f50 in sigsuspend () from /lib/libc.so.6
	(gdb) signal SIGINT
	Continuing with signal SIGINT.
	信号干扰
	
	Breakpoint 2, 0xb7e34f50 in sigsuspend () from /lib/libc.so.6
	(gdb) 
	
	

直接使用signal发送对应的信号即可;

另一种方法是使用handle命令:

handle命令可控制信号的处理，他有两个参数，一个是信号名，另一个是接受到信号时该作什么。几种可能的参数是：

nostop 接收到信号时，不要将它发送给程序，也不要停止程序。

stop 接受到信号时停止程序的执行，从而允许程序调试；显示一条表示已接受到信号的消息（禁止使用消息除外）

print 接受到信号时显示一条消息

noprint 接受到信号时不要显示消息（而且隐含着不停止程序运行）

pass 将信号发送给程序，从而允许你的程序去处理它、停止运行或采取别的动作。

nopass 停止程序运行，但不要将信号发送给程序。

例如，假定你截获SIGPIPE信号，以防止正在调试的程序接受到该信号，而且只要该信号一到达，就要求该程序停止，并通知你。要完成这一任务，可利用如下命令：

	(gdb) handle SIGPIPE stop print

##### 注意:
UNIX的信号名总是采用大写字母！

