---
author: UCSHELL
comments: true
date: 2013-09-27 04:26:48+00:00
layout: post
slug: '%e5%9c%b0%e5%9d%80%e5%a4%8d%e7%94%a8'
title: 地址复用
wordpress_id: 1332
categories:
- 网络编程
tags:
- 地址复用
---

主要是对soket文件描述符进行设置，设置为SO_REUSEADDR即可

    
    int sockfd = socket(AF_INET， SOCK_STREAM, 0);
    if (-1 == sockfd) {
        perror("socket error");
        exit(-1);
    }
    int on = 1;
    if (-1 == setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR, &on, sizeof(on))) {
        perror("setsockopt error");
        exit(-1);
    }
    do something;
