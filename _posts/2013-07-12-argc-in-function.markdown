---
author: UCSHELL
comments: true
date: 2013-07-12 15:51:00+00:00
layout: post
slug: test
title: 函数参数的传递顺序
wordpress_id: 207
categories:
- C\C++
tags:
- C
---

今天写程序时候遇到一个奇怪的问题, 查找了许久才找到问题所在, 原来是printf函数参数的传递顺序的问题！函数参数是从右向左传递， 这么简单的知识竟然忘记了， 看了真的要花时间好好的复习下基础内容了！
    # include <stdio.h>
    # include <stdlib.h>
    # include <unistd.h>
    # include <string.h>
    # include <sys/types.h>
    # include <sys/sem.h>
    # include <sys/socket.h>
    # include <netdb.h>
    int main()
    {
        struct hostent* ent;
        sethostent(1);
        ent = gethostbyname( "www.sina.com" );
        printf ( "host : %s\n" , ent->h_name);
        int i = 0;
        while (NULL!=ent->h_addr_list[i])
        {
            printf ( "IP[%d] : %hhu.%hhu.%hhu.%hhu\t\n" , i,
            ent->h_addr_list[i][0],
            ent->h_addr_list[i][1],
            ent->h_addr_list[i][2],
            /*=======错误处==========*/
            ent->h_addr_list[i++][3]);
        }
        i = 0;
        while (NULL!=ent->h_aliases[i])
        {
        	printf ( "aliases : %s\n" , ent->h_aliases[i++]);
        }
        endhostent();
        return 0;
    }

\================================================

    /*改为如下即可*/
    ent->h_addr_list[++i][0],
    ent->h_addr_list[i][1],
    ent->h_addr_list[i][2],
    ent->h_addr_list[i][3]);