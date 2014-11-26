---
layout: post
title: fcntl设置非阻塞文件描述符
categories:
- LINUX
tags:
- fcntl
---


    int fd = socket(AF_INET, SOCK_STREAM, 0);
    int old_option = fcntl(fd, F_GETFL);
    int new_option = old_option | O_NONBLOCK;
    fcntl(fd, F_SETFL, old_option);
    
