---
author: UCSHELL
comments: true
date: 2013-11-05 02:34:45+00:00
layout: post
slug: gdb%e8%b0%83%e8%af%95%e4%ba%94%ef%bc%9a%e5%a4%9a%e7%ba%bf%e7%a8%8b%e8%b0%83%e8%af%95
title: GDB调试(五)：多线程调试
wordpress_id: 894
categories:
- GDB
tags:
- GDB
---

GDB线程调试命令

info threads:列出所有线程相关信息

bt:查看当前所在线程的函数帧

thread 3:跳到线程3中

break 88 if thread 3:当线程3到达88行时候停止
break 88 thread 3 if x==y: 当线程3到达88行时，并且如果x与y想等，那么就停止

    
    [root@localhost 04]# gdb main  
    (gdb) r 100 2 
    Starting program: /root/work/GDB/04/main 100 2
    [Thread debugging using libthread_db enabled] 
    [New Thread 0xb7fe0b70 (LWP 4157)]            
    [New Thread 0xb75dfb70 (LWP 4158)] #有新 线程创建了，GDB会提示我们
    ^C                                 #使用Ctrl+C终断线程          
    Program received signal SIGINT, Interrupt.    
    0x00110424 in __kernel_vsyscall ()            
    
    (gdb) info thread
      3 Thread 0xb75dfb70 (LWP 4158)  0x00110424 in __kernel_vsyscall ()
      2 Thread 0xb7fe0b70 (LWP 4157)  0x00110424 in __kernel_vsyscall ()
    * 1 Thread 0xb7fe2b30 (LWP 4156)  0x00110424 in __kernel_vsyscall ()
    #星号代表当前所在线程
    (gdb) bt                                                            
    #0  0x00110424 in __kernel_vsyscall ()                              
    #1  0x009a910d in pthread_join () from /lib/libpthread.so.0         
    #2  0x0804872c in main (argc=3, argv=0xbffff264) at perim.c:80  
    (gdb) thread 2
    [Switching to thread 2 (Thread 0xb7fe0b70 (LWP 4230))]#0  0x00110424 in __kernel_vsyscall ()                                                                            
    (gdb) bt                                                                            
    #0  0x00110424 in __kernel_vsyscall ()                                              
    #1  0x009af019 in __lll_lock_wait () from /lib/libpthread.so.0                      
    #2  0x009aa430 in _L_lock_677 () from /lib/libpthread.so.0                          
    #3  0x009aa301 in pthread_mutex_lock () from /lib/libpthread.so.0                   
    #4  0x080485ee in worker (tn=0) at perim.c:47                                       
    #5  0x009a8a49 in start_thread () from /lib/libpthread.so.0                         
    #6  0x008bfaae in clone () from /lib/libc.so.6                                      
    (gdb) info thread
      3 Thread 0xb75dfb70 (LWP 4158)  0x00110424 in __kernel_vsyscall ()
    * 2 Thread 0xb7fe0b70 (LWP 4157)  0x00110424 in __kernel_vsyscall ()
      1 Thread 0xb7fe2b30 (LWP 4156)  0x00110424 in __kernel_vsyscall ()
    (gdb) thread 3
    [Switching to thread 3 (Thread 0xb75dfb70 (LWP 4231))]#0  0x00110424 in __kernel_vsyscall ()                                                                            
    (gdb) bt                                                                            
    #0  0x00110424 in __kernel_vsyscall ()                                              
    #1  0x009af019 in __lll_lock_wait () from /lib/libpthread.so.0                      
    #2  0x009aa430 in _L_lock_677 () from /lib/libpthread.so.0                          
    #3  0x009aa301 in pthread_mutex_lock () from /lib/libpthread.so.0                   
    #4  0x080485ee in worker (tn=1) at perim.c:47                                       
    #5  0x009a8a49 in start_thread () from /lib/libpthread.so.0                         
    #6  0x008bfaae in clone () from /lib/libc.so.6     
    








