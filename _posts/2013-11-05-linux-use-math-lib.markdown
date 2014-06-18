---
author: UCSHELL
comments: true
date: 2013-11-05 01:16:58+00:00
layout: post
slug: linux%e4%b8%8b%e4%bd%bf%e7%94%a8%e6%95%b0%e5%ad%a6%e5%87%bd%e6%95%b0%e7%9a%84%e9%97%ae%e9%a2%98
title: linux下使用数学函数的问题
wordpress_id: 891
categories:
- LINUX
---


    int main()
    {
        printf("sqrt(4) = %lf\n", sqrt(4));
        return 0;
    }


编译运行

    [root@localhost work]# cc math.c -omain -g
    /tmp/ccG3M9ln.o: In function `main':
    /root/work/t.c:9: undefined reference to `sqrt'
    collect2: ld 返回 1
    
================================================

	undefined reference to `sqrt'

在linux下使用数学函数时候会提示undefined reference to ……

这是因为没有链接数学库导致的，只要在编译的时候加上-lm即可

================================================

    [root@localhost work]# cc t.c -omain -lm -g
    [root@localhost work]# ./main
    sqrt(4) = 2.000000;
    
================================================
