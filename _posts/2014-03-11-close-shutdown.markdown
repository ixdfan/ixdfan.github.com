---
layout: post
title: close与shutdown关闭连接 
description: 
modified: 
tags: [close,shutdown]
---

关闭连接实际上是关闭该连接对应的socket;

使用close系统调用并非总是立即关闭一个连接，而是将引用计数减一。**只有当*fd的引用计数为0的时候才真正关闭连接*

在多进程中，一次fork系统调用默认将父进程中打开的socket的引用计数加1。**因此我们必须在父进程和子进程中都对该socket执行close调用才能真正将连接关闭**

如果无论如何都要立即终止连接(而不是将socket的引用计数减一)，可以使用shutdown系统调用，相对与close来讲shutdown是专门为网络编程设计的

	#include <sys/socket.h>
	int shutdown(int sockfd, int howto)

howto参数决定了shutdown的行为
1. **SHUT_RD**:  关闭sockfd上读的这一半，引用程序不能再针对socket文件描述符执行读操作，并且该socket接受缓冲区中的数据都被丢弃;
2. **SHUT_WR**: 关闭sockfd上写的这一半，sockfd的发送缓冲区中的数据会在真正关闭连接之前全部发送出去，应用程序不可以在对该socket文件描述符执行写操作，这种情况下处于半关闭状态
3. **SHUT_RDWR**: 同时关闭sockfd上的读和写


shutdown可以分别关闭socket上的读和写或者都关闭，close在关闭连接时只能将socket上的读和写同时关闭。


