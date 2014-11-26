---
layout: post
title: 地址复用
categories:
- NETWORK
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
