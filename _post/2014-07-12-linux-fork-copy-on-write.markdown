---
layout: post
title: fork的写时复制机制
description:  
modified: 
categories: 
- LINUX
tags:
- 
---

fork使用写时复制(copy on wirte)使其更高效,主要的原理是将内存复制操作延迟到父进程或子进程向某个内存页面写入数据之前,在只读访问的情况下父进程和子进程可以共用同一内存页.
