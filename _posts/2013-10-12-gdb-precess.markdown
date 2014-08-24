---
layout: post
title: GDB调试(三)：多进程调试
categories:
- GDB
tags:
- GDB
---

GDB高端调试(三)——多进程的调试

在多进程当中想要使用GDB调试程序中调用fork派生出的子进程，但是会发现GDB调试的仍然还是父进程，其子进程的执行无法调试。

如果你在子进程的代码中加了断点，那么执行到此断点的时候子进程会受到一个SIGTRAP信号而终止！

如何调试多进程呢?

=================================================================

主要有两种方法：
##### 1. attach 子进程方法(也可以是gdb -p pid)
##### 2. follow-fork-mode 方法

=================================================================


    
    /*测试用例*/
    void function()
    {
    	printf("this is a function!\n");
    }
    
    int main()
    {
    	pid_t pid;
    	if((pid = fork()) < 0)
    	{
    		perror("fork error!");
    	}
    	else if(0 == pid)
    	{
    		sleep(60);/*注意*/
    		printf("this is a child process\n");
    		function();
    		exit(0);
    	}
    	else
    	waitpid(pid, 0, 0);
    	return 0;
    }


=================================================================

注意处标识的sleep(60)其实就为了调试而加入的！

让子进程sleep60秒，这个就是调试的关键！

为什么要子进程刚开始执行就sleep呢？因为我们要利用子进程sleep的这段时间内找出子进程的PID！

再用GDB的attach

方法依附带该进程上！

=================================================================
步骤:

1. 编译：
	
	[root@localhost GDB]# cc gdb.c -omain -g
    
2. 运行：
    
	[root@localhost GDB]# ./main

3. 查找进程ID

	[root@localhost GDB]# ps a

4. 运行GDB

	[root@localhost GDB]# gdb
	(gdb)attach PID
	(gdb)stop /*这个是非常重要的，必须先暂停你在设置一些断点*/
	(gdb)break function /*在function函数上设置断点*/
	(gdb)continue
	**也可以直接使用gdb -p pid** 这两种方法都可以
	/*遇到断点后进行单步调试*/

=================================================================

follow-fork-mode的用法：
	
    set follow-fork-mode [parent | child]
    parent:fork之后继续调试父进程，子进程不受影响
    child:fork之后继续调试子进程，父进程不受影响

如果需要调试子进程
	
    (gdb)set follow-fork-mode child

并在子进程代码设置断点

detach-on-fork参数，知识GDB在fork之后是否断开(detach)某个进程的调试，或都交由GDB控制；

    set detach-on-fork [on | off]

on:断开调试follow-fork-mode指定的进程

off:GDB将控制父进程和子进程，follow-fork-mode指定的进程将被调试，另一个进程处于暂停状态。

=================================================================

总结:
##### 1. follow-fork-mode方法：方便易用，对系统内核和GDB版本有限制，适合于较为简单的多进程系统

##### 2. attach子进程方法：灵活强大，但需要添加额外代码，适合于各种复杂情况，特别是守护进程
