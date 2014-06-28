---
layout: post
title: errno中EAGAIN含义
categories:
- NETWORK
tags:
- EAGAIN
---

从字面上来看，是提示再试一次。这个错误经常出现在当应用程序进行一些非阻塞(non-blocking)操作(对文件或socket)的时候。

例如:

以O_NONBLOCK的标志打开文件socket，如果你连续read而没有数据可读。

此时程序不会阻塞起来等待数据准备就绪返回，read函数会返回一个错误EAGAIN，提示你的应用程序现在没有数据可读请稍后再试。

例如:

当一个系统调用(比如fork)因为没有足够的资源(比如虚拟内存)而执行失败，返回EAGAIN提示其再调用一次(也许下次就能成功)。

在linux进行非阻塞的socket接收数据时经常出现Resource temporarily unavailable，errno代码为11(EAGAIN)

这表明你在非阻塞模式下调用了阻塞操作，在该操作没有完成就返回这个错误，这个错误不会破坏socket的同步，不用管它，下次循环接着recv就可以。

**对非阻塞socket而言，EAGAIN不是一种错误**。在VxWorks和Windows上，EAGAIN的名字叫做**EWOULDBLOCK**。

如果出现EINTR即errno为4(EINTR)，错误描述Interrupted system call(系统调用)，不必管他，操作也应该继续。

最后，如果recv的返回值为0，那表明连接已经断开，我们的接收操作也应该结束。

