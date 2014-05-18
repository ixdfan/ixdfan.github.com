---
author: UCSHELL
comments: true
date: 2013-09-27 15:51:27+00:00
layout: post
slug: fork%e5%87%bd%e6%95%b0%e8%af%a6%e8%a7%a3
title: fork函数详解
wordpress_id: 760
categories:
- THE LINUX
tags:
- fork
---

一个现有的进程可以调用fork函数创建一个新进程，由fork创建的新进程被称为子进程。fork函数被调用一次但是返回两次。两次返回的唯一区别在于子进程中返回0，父进程返回子进程的ID。 子进程是父进程的副本，它将获得父进程的数据空间、堆、栈等资源的副本。 注意：子进程持有的是上述存储空间的副本，这意味着父子进程之间不能共享这些空间，他们之间共享的只有代码段。

======================================================================

**fork将子进程ID返回给父进程的理由**： 因为一个进程的子进程可以有多个，并且没有一个函数使一个进程可以获得所有子进程的进程ID

** fork使子进程返回值为0的理由**： 一个进程只会有一个父进程，所以任何时候都可以使用getppid获取其父进程的进程ID。

======================================================================

**vfork与fork的异同:**

1. fork():子进程拷贝父进程的数据段，代码段
vfork():子进程与父进程共享数据段.
2. fork():父子进程的执行次序不确定.
vfork():**保证子进程先运行，在调用exec或exit之前与父进程数据是共享的,在它调用exec 或exit之后父进程才可能被调度运行**。
3. **vfork()保证子进程先运行，在她调用exec或exit之后父进程才可能被调度运行。**
**如果在调用这两个函数之前子进程依赖于父进程的进一步动作，则会导致死锁。**
4. 当需要改变共享数据段中变量的值，则拷贝父进程。

================================================================

fork与fork的相同点： 

两者被调用一次，但是返回两次。
两次返回的唯一区别是子进程的返回值是0，父进程的返回值是子进程的进程ID。

####注意: 

不管是vfork还是fork，其子进程中调用exec函数执行另一个程序时，该进程则完全有新程序替代，而新程序则从main函数开始执行。

但是，因为调用exec函数并不创建新进程，所以前后进程的ID并未改变，exec知识用另一个新程序替换了当前进程的正文、数据、堆和栈。

================================================================

**fork产生错误原因**主要是两个：

EAGAIN：**达到进程数上限.**
ENOMEM：**没有足够空间给一个新进程分配.**

    
    int glob = 6;
    
    int main()
    {
    	int var;
    	pid_t pid;
    
    	var = 88;
    	printf("before vfork\n");
    	if( (pid = fork()) < 0)
    	{
    		perror("fork error");
    	}
    	else if(0 == pid)
    	{
    		glob++;
    		var++;
    		_exit(0);
    	}
    	printf("pid = %d, glob = %d, var = %d\n", getpid(), glob, var);
    	return 0;
    }
    
    [root@localhost 03]# ./main
    before vfork
    pid = 12642, glob = 6, var = 88


子进程对glob和var做了增1操作，结果改变了父进程中的变量的值，因为子进程在父进程的地址空间中运行。

**注意此处使用的是_exit而不是exit,因为\_exit是直接进入内核的，并不会执行标准IO的冲洗操作。**

exit相关的区别请参照[《exit系列函数》](http://ucshell.com/archives/781) 如果调用exit而不是\_exit那么输出的结果是不确定的！它依赖于标准IO库的实现，可能输出没有变化，可能看不到输出。如果调用exit而该实现仅仅冲洗所有标准IO流，则输出与\_exit是完全相同的！ 如果该实现也要关闭IO流，那么表示标准输出FILE对象的相关存储区也会被清零，因为子进程借用了父进程的空间地址，所以父进程恢复运行并调用printf时候就不会有任何输出，printf就会返回-1； 注意父进程的STDOUT_FILENO(1)仍旧有效,因为子进程得到的是父进程的文件描述符数组的副本

================================================================

    
    int global = 4;
    int main()
    {
            pid_t      pid;
            int        var = 5;
            if((pid = vfork()) < 0){
                    printf("vfork error\n");
                    exit(-1);
            }else if(0 == pid){
                    ++global;
                    --var;
    		printf("global = %x, var = %x\n", &global, &var);
                    printf("Child changed the var and global\n");
                    _exit(0);
            }
            else{
    		printf("global = %x, var = %x\n", &global, &var);
                    printf("Parnet didn't changed the var ang global\n");
            }
            printf("global = %d, var = %d\n", global, var);
    
            return 0;
    }



    
    [root@localhost 07]# ./main
    global = 8049778, var = bf969e8c
    Child changed the var and global
    global = 8049778, var = bf969e8c
    Parnet didn't changed the var ang global
    global = 5, var = 4


global与var的值改变了，证明**vfork并不是复制父进程中的数据区，而是与父进程共享数据段**
