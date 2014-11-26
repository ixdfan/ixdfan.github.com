---
layout: post
title:  socket在什么情况下可读
description: 
modified: 
categories: 
- LINUX
tags:
- 
---

socket在什么情况下可读?
1. 接收缓冲区有数据，一定可读
2. 对方正常关闭socket，也是可读
3. 对于侦听socket，有新连接到达也可读
4. socket有错误发生，且pending～～～

引用unp的一段话 第六章 6.3节   
A socket is ready for reading if any of the following four conditions is true:

a.The number of bytes of data in the socket receive buffer is greater than or equal to the current size of the low-water mark for the socket receive buffer.

A read operation on the socket will not block and will return a value greater than 0

b.The read half of the connections is closed (i.e., A TCP connection that has received a FIN).

A read operation on the socket will not block and will return 0 (i.e., EOF)

c.The socket is a listening socket and the number of completed connection is nonzero. 

An accept on the listening socket will normally not block, although we will describe a   

d.A socket error is pending. A read operation on the socket will not block and will return

an error (-1) with errno set to the specific error condition

##### socket在下列的情况下可读: 

1. socket内核接受缓存区中的字节数大于等于其低水平位标记SO_RCVLOWAT,我们可以无阻塞的读取该socket，并且读操作返回的字节数大于0
2. socket通信的对方关闭连接，此时对该socket的读操作将返回0;
3. 监听socket上有新的连接请求
4. socket上有未处理的错误，我们可以使用getsockopt读取和清除该错误


##### socket在下列的情况下可写: 

1. socket内核发送缓冲区中的可用字节数大于或等于其低水位标记SO_SNDLOWAT,此时我们可以无阻塞的写该socket，并且写操作返回的字节数大于0 
2. socket的写操作被关闭，对写操作被关闭的socket执行写操作将触发一个SIGPIPE信号
3. socket使用非阻塞connect连接成功或者失败(超时)之后。
4. socket上有未处理的错误，我们可以使用getsockopt读取和清除该错误

在网络程序中select能处理的异常情况只有一种，socket上接收带外数据; 


