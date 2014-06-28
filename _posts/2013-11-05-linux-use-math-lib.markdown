---
layout: post
title: linux下使用数学函数的问题
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
