---
author: UCSHELL
comments: true
date: 2013-09-27 02:39:32+00:00
layout: post
slug: fcntl%e8%ae%be%e7%bd%ae%e9%9d%9e%e9%98%bb%e5%a1%9e%e6%96%87%e4%bb%b6%e6%8f%8f%e8%bf%b0%e7%ac%a6
title: fcntl设置非阻塞文件描述符
wordpress_id: 1336
categories:
- THE LINUX
tags:
- fcntl
---


    int fd = socket(AF_INET, SOCK_STREAM, 0);
    int old_option = fcntl(fd, F_GETFL);
    int new_option = old_option | O_NONBLOCK;
    fcntl(fd, F_SETFL, old_option);
    
