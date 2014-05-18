---
layout: post
title:  errno中的EINTR
description: 
modified: 
categories: 
-  THE LINUX
tags:
- errno
---

如果程序在执行处于阻塞状态当系统调用的时候接收到信号，并且我们为信号设置来信号处理函数，则默认情况下系统调用将被中断，并且errno被设置为EINTR，这种情况下直接忽略该信号即可！

我们可以使用sigaction函数为信号设置SA_RESTART标志以自动重启被该信号中断的系统调用;


