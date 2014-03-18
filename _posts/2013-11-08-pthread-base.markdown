---
author: UCSHELL
comments: true
date: 2013-11-08 04:48:45+00:00
layout: post
slug: '%e7%ba%bf%e7%a8%8b%e4%b8%80%e5%9f%ba%e7%a1%80'
title: 线程(一):基础
wordpress_id: 917
categories:
- 线程
tags:
- 线程
---

===================================================================================
线程的概念：
一个进程中每一个线程都有自己的运行环境上下文，包括线程ID、一组寄存器的值、堆、栈、信号屏蔽字等。

**进程间所有的资源都被线程所共享，包括可执行的程序代码、全局变量、堆、栈、文件描述符。**

** 线程之间的堆栈式独立的！**

##### 注意：
* 由于引入了线程的概念，所以操作系统中的执行实体不在是进程，而是线程。
* 进程是系统资源分配的最小单位，线程是系统进程调度的单位。

Linux中的线程是一个轻量级的进程

===================================================================================

##### 线程的优势：
1. 线程共享进程地址空间内的所有资源，所以线程之间的通信时非常方便的。
同样的任务如果使用多进程编程模型，就必须使用操作系统提供的进程间通信方式。其效率和程序设计的复杂度都会受很大的影响。执行多个任务的线程协调起来非常的方便，提高了效率也降低了编程的复杂度。
2. 多个线程处理不同的任务，增加了程序的并发性，使程序高效的执行。
例如：外排序的实例中，呆排序的数据过于庞大，无法一次读取到内存中操作时，则需要先将数据读入内存，进行排序后输出到磁盘，这样程序的绝大部分时间都是浪费在输入输出(I/O操作)上,使得CPU处于空闲状态。如果使用多线程编程模型可以改善这个问题，可以创建三个进程，一个线程从磁盘读入数据，一个线程负责将数据排序，一个线程负责将排好序的数据输出。
在交互式程序中创建一个单独的线程接受用户输入的命令，并创建另一个线程来对这些命令进行处理。
浏览器就是采用这种方式，一个线程处理用户输入(鼠标或键盘)，一个线程负责显示请求站点发回的数据，剩下的线程分别就收不同的数据包。

===================================================================================

线程标识符的类型为pthread_t

    
    pthread_t pthread_self(void);


使用pthread_self来查看线程ID

##### 注意：
**pthread_t的类型为unsigned long int，所以在打印的时候要使用%lu方式，否则将产生奇怪的结果。**

比较两个线程ID是否相等

    
    int pthread_equal(pthread_t t1, pthread_t t2);


如果相等则返回0，不相等则返回非0值

实例：

    
    	pthread_t pid;
    	tid = pthread_self;
    	if(0 == pthread_equal(save_tid, tid))
    		……
    	else
    		……


===================================================================================

线程的创建：

    
    int pthread_create(pthread_t *thread, const pthread_attr_t *attr,void *(*start_routine) (void *), void *arg);


##### 注意:
start_routine函数的类型必须是void* ()(void*)类型的函数

##### 注意：
**如果pthread_create函数(所有线程系列函数)创建成功则返回0，但是如果线程失败，返回的是错误编号，而不是像Linux其他函数一样返回-1并设置errno。
这种规律适合于线程中所有函数。**

===================================================================================
实例：

    
    void* thfun(void* arg)
    {
            pid_t pid;
            pthread_t tid;
    
            pid = getpid();
            tid = pthread_self();
            printf("the new pthread pid is : %u,tid is %u\n",
                    (unsigned int)pid, (unsigned int)tid);
            return NULL;
    }
    int main()
    {
            pid_t pid;
            int err;
            pthread_t tid, mtid;
    
            pid = getpid();
            mtid = pthread_self();
            err = pthread_create(&tid, NULL, thfun, NULL);
    
            if(err){
                    printf("can't create thread %s\n", strerror(err));
                    exit(1);
            }
            sleep(1);
            printf("the main pthread : pid id :%u, tid is %u\n",
                            (unsigned int)pid, (unsigned int)mtid);
            return 0;
    }


===================================================================================

    
    /*
    	向线程函数传递多个参数；
    	多线程共享文件句柄
    */
    typedef struct arg_struct
    {
            int* heap;
            int* stack;
    }ARG;
    FILE* fp = NULL;
    void* thfn(void* arg)
    {
            ARG* p = (ARG*)arg;
    
            (*p->heap)++;
            (*p->stack)++;
    
            fprintf(fp, "new thread heap : %d stack : %d\n",
                    *(p->heap)), *(p->stack);
            printf("the new thread done\n");
            return NULL;
    }
    
    int main()
    {
            pthread_t tid, tid2;
            ARG arg;
            int* heap;
            int stack;
            int err;
    
            heap = (int*)malloc(sizeof(int));
            if(NULL == heap){
                    perror("fail to malloc");
                    exit(1);
            }
    
            *heap = 2;
            stack = 3;
    
            arg.heap = heap;
            arg.stack = &stack;
    
    	/*此为wb，原因就是多进程共享文件句柄*/
            if((fp = fopen("test.txt", "wb")) == NULL){
                    perror("fail to open");
                    exit(1);
            }
    
            err = pthread_create(&tid, NULL, thfn, &arg);
            if(0 != err){
                    printf("can't create thread %s\n", strerror(err));
                    exit(1);
            }
    
            sleep(10);
            (*heap)++;
            stack++;
    
            fprintf(fp, "main thread: heap : %d stack : %d\n",
                                            *(arg.heap), *(arg.stack));
            printf("the main thread done\n");
    
            fclose(fp);
            free(heap);
    
            return 0;
    }



    
    cat test.txt
    new thread heap : 3 stack : 4
    main thread: heap : 4 stack : 5


================================================================================

从结果看以知道，文件中有线程输入的内容，所以新线程和进程(主线程)公用文件描述符、文件对象和数据段；

由于堆栈数据在函数thfn中自增会影响到主线程，所以新线程和进程公用堆和栈。

因此我们可以得出结论：

* 进程中的地址空间对于任意一个线程来讲都是开放的！

================================================================================

** 现在也可以解释为什么线程系列处理函数不设置errno变量，而是采用返回错误号的原因了。
**

** 由于线程可以随意访问进程的环境变量，所以当多个线程出错时候，errno变量的值将被多次覆盖，进程检查到的只是最后一个线程出错的原因 **

** 归根结底，还是由于线程出错和检查errno变量两个操作不是原子操作，因此线程系列处理函数只返回错误号，不会设置errno **

================================================================================
