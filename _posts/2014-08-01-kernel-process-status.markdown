---
layout: post
title: 进程的状态转化
description:  
modified: 
categories: 
- KERNEL
tags:
- 
---

进程状态的转换图

![002]({{ site.img_url }}/2014/08/002.png)


##### 注意:
进程就绪状态和运行状态，其标志都是TASK_RUNNING

        | 起始状态             | 结束状态             | 状态转换原因                                   |
        | TASK_RUNNING         | TASK_UNINTERRUPTIBLE | 进程进入等待队列                       |
        | TASK_RUNNING         | TASK_INTERRUPTIBLE   | 进程进入等待队列                       |
        | TASK_RUNNING         | TASK_STOPPED         | 进程接收到SIGSTOP信号，或者进程被跟踪 |
        | TASK_RUNNING         | TASK_ZOMBLE          | 进程被杀死，但其父进程还没有调用sys_wait4 |
        | TASK_INTERRUPTIBLE   | TASK_STOPPED         | 收到信号时                                |
        | TASK_UNINTERRUPTIBLE | TASK_STOPPED         | 被唤醒                                      |
        | TASK_UNINTERRUPTIBLE | TASK_RUNNING         | 进程获得等待资源                       |
        | TASK_INTERRUPTIBLE   | TASK_RUNNING         | 进程获得等待资源或是收到信号后被设置为运行状态 |
        | TASK_RUNNING         | TASK_RUNNING         | 由调度进程移入移除                    |
 

#### 从就绪态到运行态
从就绪态到运行态的抽象状态转换并步对应实际linxu进程状态转换，因为进程的状态实际上没有发生变化，进程仍然处于TASK_RUNNING状态，然而，进程确实进入了运行队列，并真正在CPU上执行

- 从TASK_RUNNING到TASK_RUNNING
linux对当前正在使用CPU的进程没有给出一个明确的状态，即使进程已经离开就绪队列，并且它的上下文正在执行，进程也一直保持着TASK_RUNNING状态，调度程序从运行队列中选择进程

-------------------------------------------------------------------------------

#### 从运行态到就绪态
在这种情况下即使进程本身发生了变化，进程状态也不会改变，进程的抽象状态转换有助于我们理解，当进程从由CPU运行到进程运行队列时候发生了状态转换，经历了从运行到就绪的过程

- 从TASK_RUNNING到TASK_RUNNING
由于Linux没有为在CPU中执行的程序的上下文设置一个单独的状态，因此此时进程不会经历一个明显的Linux状态转换，还依然处于TASK_RUNNING状态


-------------------------------------------------------------------------------

#### 从运行态到阻塞态
当进程变为阻塞时，他可能处于如下某个状态:

- TASK_INTERRUPTIBLE
- TASK_UNINTERRUPTIBLE
- TASK_ZOMBIE
- TASK_STOPPED


- TASK_RUNNING到TASK_INTERRUPTIBLE
这种状态通常由IO函数阻塞引起，因为这种函数必须等待一个事件或是资源，对于一个进程来说，处于TASK_INTERRUPTIBLE状态意味着进程肯定不再运行队列中，因为它还没有就绪。

如果进程的资源变得可用(时间或硬件),或者一个信号到来时候，处于TASK_INTERRUPTIBLE状态的进程就会被唤醒。

例如子进程访问磁盘上的一个文件，磁盘驱动程序负责通知设备何时准备好要访问的数据，驱动程序中有一部分类似于下面的代码：


	while (1) {
		if (resource_available)
			break;
		set_current_stat(TASK_INTERRUPTIBLE);
		schedule();
	}
	set_current_stat(TASK_RUNNING);

当进程执行open调用时候，它将会进入TASK_INTERRUPTIBLE状态，然后schedule将会把它从CPU上换下来，并选择运行队列中的另外一个进程作为运行进程。在资源变为可用的时候，该进程终止循环并把其状态设置位TASK_RUNNING，这样该进程就又被放回运行队列，进程可以在运行队列中等待，直到调度程序认为轮到它执行为止！


interruptible_sleep_on函数可以将TASK_INTERRUPTIBLE状态
	
    2504 void fastcall __sched interruptible_sleep_on(wait_queue_head_t *q)
    2505 {
    2506     SLEEP_ON_VAR
    2507 
    2508     current->state = TASK_INTERRUPTIBLE;
    2509 
    2510     SLEEP_ON_HEAD
    2511     schedule();
    2512     SLEEP_ON_TAIL
    2513 }

SLEEP_ON_HEAD和SLEEP_ON_TAIL宏分别完成向等待队列中添加和删除一个进程

SLEEP_ON_VAR宏初始化进程的等待队列入口，使得可以向等待队列中添加进程


- 从TASK_RUNNING到TASK_UNINTERRUPTIBLE

除了当进程处于内核态时候不会收到信号的影响外，TASK_UNINTERRUPTIBLE状态与TASK——INTERRUPTIBLE状态类似。这个状态是在调用do_fork创建进程时，为进程设置的默认状态。

    2532 void fastcall __sched sleep_on(wait_queue_head_t *q)
    2533 {
    2534     SLEEP_ON_VAR
    2535 
    2536     current->state = TASK_UNINTERRUPTIBLE;
    2537 
    2538     SLEEP_ON_HEAD
    2539     schedule();
    2540     SLEEP_ON_TAIL
    2541 }
    

- 从TASK_RUNNING到TASK_ZOMBIE

处于TASK_ZOMBIE状态的进程叫做僵死进程，每个进程在它生命周期中都要经历这个状态，进程处于这种状态的时长依赖于他的父进程

系统不能杀死僵死进程，因为它实际上就是死的，只能等待被释放的进程描述符

TASK_ZOMBIE是一个临时状态，处于这种状态的进程不会在运行，只能转换到TASK_STOPPED状态

- 从TASK_RUNNING到TASK_STOPPED
这种转换会在两种情况下出现，

-- 第一种情况是正在被调试器或跟踪程序处理的进程

-- 第二种情况是进程收到SIGSTOP或者某种停止信号


- 从TASK_UNINTERRUPTIBLE或TASK_INTERRUTIBLE到TASK_STOPPED

TASK_STOPPED管理SMP系统中的进程或正在处理信号的进程，当一个进程收到一个唤醒信号时，或是内核明确要求进程不响应任何事情时(如果进程被设置位TASK_INTERRUPTIBLE状态，他会响应其他事情的)，进程就被设置为TASK_STOPPED状态。

与TASK_ZOMBIE状态进程不同，TASK_STOPPED状态进程可以接收到KILL信号

-------------------------------------------------------------------------------
#### 从阻塞态到就绪态

当进程得到等待的数据或是硬件的时候，将会从阻塞态转换到就绪态，这一状态转换对应着两种状态转换，分别是从TASK_INTERRUPIBLE到TASK_RUNNING状态和从TASK_UNINTERRUPTIBLE状态到TASK_RUNNING

