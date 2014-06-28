---
layout: post
title:  sigprocmask函数
description: 
modified: 
categories: 
- LINUX
tags:
- signal
---

	int sigprocmask(int how, const sigset_t *set, sigset_t *oldset);
	参数how表示使用方式
	set指向要操作的信号集合
	oldset上次设置的信号集合，通常设置为NULL 

how可以有一下参数:

* SIG_BLOCK:屏蔽一个信号集

* SIG_UNBLOCK:解除一个或多个屏蔽信号集

* SIG_SETMASK:修改一个信号的屏蔽，将原来的信号屏蔽解除，加入新的信号屏蔽集合


#### 编程步骤:
##### 1.声明一个信号集合
##### 2.加入屏蔽信号
##### 3.屏蔽信号
##### 4.解除屏蔽


##### 信号集合维护函数:
* 清空集合:sigemptyset

* 添加信号到集合:sigaddset

* 从集合删除一个信号:sigdelset

* 添加所有信号到集合:sigfillset

* 判断某个信号是否在集合中:sigismember

* 返回正在屏蔽的信号集合:sigpending

* 信号屏蔽的切换:sigsuspend


##### 实例:


	int main(int argc, char** argv)
	{
		int sum = 0;
		int i;
		sigset_t sigs;
		sigemptyset(&sigs);
		sigaddset(&sigs, SIGINT);
		sigprocmask(SIG_BLOCK, &sigs, NULL);

		for (i = 0; i < 10; i++) {
			sleep(10);
				
		}
	
	
		sigprocmask(SIG_UNBLOCK, &sigs, NULL);
		printf("OK\n");
			
	
		return 0;
	}


sleep过程中使用ctrl+c则OK不会输出，因为信号解除屏蔽后，信号马上被触发，信号调用中断，所以OK不会输出

sigpending检测正在屏蔽的信号

	int main(int argc, char** argv)
	{
		int sum = 0;
		int i;
		sigset_t sigs;
		sigset_t sigp;
		sigemptyset(&sigs);
		sigemptyset(&sigp);
		sigaddset(&sigs, SIGINT);
		sigprocmask(SIG_BLOCK, &sigs, NULL);
	
		for (i = 0; i < 10; i++) {
			sigpending(&sigp);	
			if (sigismember(&sigp, SIGINT)) {
				printf("SIGINT在排队\n");	
			}
			sleep(1);
		}
	
		sigprocmask(SIG_UNBLOCK, &sigs, NULL);
		printf("OK\n");
			
	
		return 0;
	}
	
	执行使用ctrl+c
	[root@ signal]# ./main
	^CSIGINT在排队
	SIGINT在排队
	SIGINT在排队
	SIGINT在排队
	SIGINT在排队
	SIGINT在排队
	SIGINT在排队
	SIGINT在排队
	SIGINT在排队

	一直输出"SIGINT在排队"因为SIGINT信号发生后没有进行处理，所以SIGINT一直存在


	int sigsuspend(const sigset_t *mask);

屏蔽新信号，解除原信号屏蔽，sigsuspend与sigprocmask配合使用的效果非常好
当你发送mask中的信号的时候，这个函数不会响应，但当你发送mask意外的信号的时候，整个函数就会响应

#### 注意:

* sigsuspend是阻塞函数，对参素集合的信号屏蔽，但是对参数中没有的信号不会屏蔽，只有当未屏蔽的信号处理函数调用完毕之后，sigsuspend才会返回

* sigismember返回1表明信号在信号集中;返回0说明不在;返回-1说明错误


#### sigsuspend返回条件

* 信号发生且信号是非屏蔽信号

* 信号必须有信号处理函数，且处理函数返回后，sigsuspend才会返回

##### 如果发送一个没有处理函数的信号，则因为没有处理函数进程会中断


	void handler(int s)
	{
		printf("非屏蔽信号发生\n");	
	}
	
	int main(int argc, char** argv)
	{
		signal(SIGUSR1, handler);
	
		sigset_t sigs;
		sigemptyset(&sigs);
		sigaddset(&sigs, SIGINT);
	
		printf("屏蔽开始\n");
	
		sigsuspend(&sigs);
	
		printf("屏蔽结束\n");
		
	
		return 0;
	}

	运行同时发送usr1信号 kill -s 10 pid
	[root@ signal]# ./main
	屏蔽开始
	非屏蔽信号发生
	屏蔽结束

	如果执行ctrl+\则直接
	[root@ signal]# ./main
	屏蔽开始
	^\Quit


##### sigsuspend设置新屏蔽信号，保留旧的屏蔽信号，并且当sigsuspendfanti时，恢复屏蔽旧的信号



	void handler(int s)
	{
		printf("抽空处理中\n");	
	}
	int main(int argc, char** argv)
	{
		signal(SIGINT, handler);
		int sum = 0;
		int i;
		
		sigset_t sigs;
		sigset_t sigp;
		sigset_t sigq;
		sigemptyset(&sigs);
		sigemptyset(&sigp);
		sigemptyset(&sigq);
	
		sigaddset(&sigs, SIGINT);
		sigprocmask(SIG_BLOCK, &sigs, NULL);
	
		for (i = 0; i < 10; i++) {
			sigpending(&sigp);	
			if (sigismember(&sigp, SIGINT)) {
				printf("SIGINT在排队\n");	
				sigsuspend(&sigq);
			}
			sleep(1);
		}
	
		sigprocmask(SIG_UNBLOCK, &sigs, NULL);
		printf("OK\n");
			
	
		return 0;
	}

	执行时使用Ctrl+c
	[root@ signal]# ./main
	^CSIGINT在排队
	抽空处理中
	^CSIGINT在排队
	抽空处理中
	OK


在没有sigsuspend的程序中，当信号发生时候，他可能在for循环的任意位置去调用处理函数，无法确定到底在哪里中断，而这段代码中处理函数一定是在sigsuspend储调用的，因此此时sigsuspend(&sigq)屏蔽空信号，也就是任何信号都没有屏蔽，此时便会调用对应的处理函数。

sigsuspend之后又会恢复到原来的屏蔽信号，这样便将中断限制了在某个固定的位置，没有sigsuspend的代码与有sigsuspend的区别就在于中断的可控性.


##### 注意:
对于多线程的情况下，进程可能在for循环任意位置中断去处理对应的信号，因此无论在哪里处理，for循环都被中断了，在任意位置被中断，这种中断将会是致命的。




	void handle(int s)
	{
		printf("信号干扰\n");	
	}
	
	int main(int argc, char** argv)
	{
		sigset_t sigs;
		sigemptyset(&sigs);
		signal(SIGUSR1, handle);
	
		sigsuspend(&sigs);
		printf("over\n");
	
		return 0;
	}
	
	
执行程序可以看到程序在sigsuspend处挂起;
此时sigsuspend类似与pause;
但是pause是受信号影响的;

使用sigaddset(&sigs, SIGINT)，执行Ctrl+c则无法起作用;
sigsuspend此时相当于一个增强版的pause，整个sigsuspend不会收到SIGINT信号的干扰;
但是对于非屏蔽的信号，他还是会中断的。

##### 信号中断是在sigsuspend内部调用的还是在其返回后才调用的呢？
假如不掉用中断，sigsuspend便不会返回，因此信号处理的调用一定是在sigsuspend内部调用的，也就是说handle是在sigsuspend内部调用的。

##### 注意:信号中断的是函数而不是进程




