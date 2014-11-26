---
layout: post
title:  sigaction的使用
description: 
modified: 
categories: 
- LINUX
tags:
- signal
---

使用sigaction的理由:

* 稳定性

* 增强功能

	int sigaction(int signum, const struct sigaction *act, struct sigaction *oldact);
	signum:要处理的信号
	act:处理函数及其参数
	oldact:返回原来处理函数的结构体，可以设置为NULL

	struct sigaction {
	void     (*sa_handler)(int);	/* 信号处理函数  */
	void     (*sa_sigaction)(int, siginfo_t *, void *);	/**/
	sigset_t   sa_mask;				/* 要屏蔽的信号 */	
	int        sa_flags;			/* 标记 */
	void     (*sa_restorer)(void);	/* 过时的保留参数，不会使用 */
	};

sa_flags的常用取值:
	
	SA_NOCLDSTOP:如果sigactino的参数sig是SIGCHLD，则shahi该标志时表示子进程暂停时不生成SIGCHLD信号
	SA_NOCLDWAIT:如果sigaction的参数sig是SIGCHLD，则设置该标识标识子进程结束时不产生僵尸进程
	SA_RESTART:重新调用被该信号终止的系统调用
	SA_NODEFER:当接收到信号并进入其信号处理函数时候，不会屏蔽该信号，默认情况下，我们希望处理一个信号时不再接收到同种信号，否则可能引发竞太条件


	void addsig(int sig)
	{
		
		struct sigaction sa;
		/* 一定要先清空 */
		memset(&sa, 0, sizeof(sa));
	
		/* sig_action是信号处理函数 */
		sa.sa_handler = sig_handler;
	
		sigempty(&sa.sa_mask);
		
		/* 屏蔽所有信号或者是某个信号 */
		sigfillset(&sa.sa_mask) 
		/* sigadd_set(&sa.sa_mask, SIGINT); */
	
		sa.sa_flags |= SA_RESTART;
		
		int ret = sigaction(sig, &sa, NULL);
		assert(ret != -1);
	
	}

	/* 使用方法 */
	addsig(SIGHUP);
	addsig(SIGCHLD);
	addsig(SIGINT);
