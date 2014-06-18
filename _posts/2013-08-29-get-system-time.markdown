---
author: UCSHELL
comments: true
date: 2013-08-29 07:45:52+00:00
layout: post
slug: '517'
title: 时间函数的使用
wordpress_id: 517
categories:
- C\C++
tags:
- 时间函数
---

获取时间

===========================================

    
     
    struct tm* t;
    timt_t tt;
    tt = time(NULL);                    /*<=====>time(tt);*/
    t = localtime(&tt);                 /*localtime是取得本地的时间*/
    printf("localtime: %04d-%02d-%02d %02d:%02d:%02d", t->tm_year+1900,
    		t->tm_mon+1, t->tm_mday,t->tm_hour, t->tm_min, t->tm_sec);
    /*年要加上1900， 月份是从0开始的所以要加1*/
    
    t = gmtime(&tt);					/*gmtime是取得国际标准时间*/
    printf("gmtime: %04d-%02d-%02d %02d:%02d:%02d", t->tm_year+1900, 
    		t->tm_mon+1, t->tm_mday,t->tm_hour, t->tm_min, t->tm_sec);
    
    /*ctime与asctime都是指向26个字节的字符串，注意包含来换行符*/
    /*Fri Aug 23 00:12:18 2013\n\0*/
    
    printf("ctime: %s", ctime(&tt));     /*ctime的参数是time_t*/
    printf("asctime: %s", asctime(t));   /*asctime的参数是struct tm*/
    
    char buf[50];
    strftime(buf, sizeof(buf), "%c", t); 


第一个参数是要存放的位置，第二个参数是最大存放的字符数，第三个参数是保存到buf中的格式%c是较常见的那种,最后一个是struct tm*类型的参数，如果buf的长度足够存放格式化结构以及一个NULL终止符，则返回的是buf中存放的字符数，不包含NULL，否则返回0

===========================================
