---
author: UCSHELL
comments: true
date: 2013-07-31 03:07:00+00:00
layout: post
slug: linux%e4%b8%8bproc%e7%bc%96%e8%af%91%e7%9a%84%e9%94%99%e8%af%af%e6%80%bb%e7%bb%93
title: LINUX下PRO*C编译的错误总结
wordpress_id: 300
categories:
- THE C&amp;C++
- THE CODING
tags:
- proc
---

今天在CentOS上用proc预编译一个pc文件的时候刷刷地出了几屏错误信息，最前面的部分如下：   

    Pro*C/C++: Release 11.2.0.1.0 - Production on Thu Mar 15 22:07:26 2012
    
    Copyright (c) 1982, 2009, Oracle and/or its affiliates. All rights reserved.
    
    System default option values taken from: /opt/app/oracle/product/11.2.0/precomp/admin/pcscfg.cfg
    
    Error at line 30, column 10 in file /usr/include/sched.h   
    #include <stddef.h>   
    .........1   
    PCC-S-02015, unable to open include file   
    Syntax error at line 201, column 37, file /usr/include/bits/sched.h:   
    Error at line 201, column 37 in file /usr/include/bits/sched.h   
    extern int __sched_cpucount (size_t __setsize, const cpu_set_t *__setp)   
    ....................................1   
    PCC-S-02201, Encountered the symbol "__setsize" when expecting one of the following:, )   
看这个错误信息，就是找不到stddef.h。

用locate命令查找stddef.h，可以找到如下stddef.h:

    /usr/src/kernels/2.6.32-358.el6.i686/include/linux/stddef.h   
    /usr/lib/gcc/i686-redhat-linux/3.4.6/include/stddef.h   
    /usr/lib/gcc/i686-redhat-linux/4.4.4/include/stddef.h   
    /usr/include/linux/stddef.h

没有在/usr/include下的，那就要看看 **/opt/oracle/102/precomp/adminpcscfg.cfg** 里面有没有包含上述的几个目录:

    cat /opt/app/oracle/product/11.2.0/precomp/admin/pcscfg.cfg   
    sys_include=($ORACLE_HOME/precomp/public,/usr/include,/usr/lib/gcc-lib/x86_64-redhat-linux/3.2.3/include,/usr/lib/gcc/x86_64-redhat-linux/4.1.1/include,/usr/lib64/gcc/x86_64-suse-linux/4.1.0/include,/usr/lib64/gcc/x86_64-suse-linux/4.3/include)   
    ltype=short   
可以看出它包含了redhat, suse linux的路径，而CentOS上有所不同。比较上面找到的记录stddefh的路径，第4个和原来包含的 redhat,suselinux的路径类似。 检查该stddef.h，也确实包含size\_t的定义。因此就把sys_include 改为：

    sys_include=(/opt/oracle/102/precomp/public,/usr/include/linux,/usr/src/kernels/2.6.32-358.el6.i686/include/linux,/usr/lib/gcc/i686-redhat-linux/4.4.4/include)
    
    ltype=short

再次预编译，不再有上面的错误。

\>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

gcc -I${ORACLE_HOME}/rdbms/public -I${ORACLE_HOME}/rdbms/demo -L${ORACLE_HOME}/lib -lclntsh xxxxx.c

**-I (大写的i ) 指定 h 文件的位置**   
**-L 动态链接库的位置**   
-lclntsh 动态链接 libclntsh.so clntsh -> client shared library

>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

编译 proc 出现   
undefined reference to `ECPGget_sqlca'

增加参数 : -lecpg   
出现 undefined reference to `sqlcxt'   
使用参数 -lclntsh
