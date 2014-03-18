---
author: UCSHELL
comments: true
date: 2013-11-05 02:57:00+00:00
layout: post
slug: '%e5%ba%93%e6%96%87%e4%bb%b6%e7%9b%b8%e5%85%b3%e7%9a%84%e9%97%ae%e9%a2%98'
title: 库文件相关的问题
wordpress_id: 898
categories:
- GDB
tags:
- GDB
---


    root@localhost 04]# ldd ./main
    	libtest.so => not found
            linux-gate.so.1 =>  (0x0051f000)
            libpthread.so.0 => /lib/libpthread.so.0 (0x009a2000)
            libm.so.6 => /lib/libm.so.6 (0x00976000)
            libc.so.6 => /lib/libc.so.6 (0x007dd000)
            /lib/ld-linux.so.2 (0x007bb000)


ldd命令检查程序需要那些相关的库，如果有操作系统可以在何处找到他们

可以看到程序是在/lib/目录下找到C库

但是对与libtest.so库没有找到，这个库是我们自己写成的，在目录/work/test中

要解决这个问题就要向搜索路径中添加/work/test


    
    
    [root@localhost 04]# LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/work/test
    [root@localhost 04]# export LD_LIBRARY_PATH
    
    
    
    root@localhost 04]# ldd ./main
    	libtest.so => /work/test
            linux-gate.so.1 =>  (0x0051f000)
            libpthread.so.0 => /lib/libpthread.so.0 (0x009a2000)
            libm.so.6 => /lib/libm.so.6 (0x00976000)
            libc.so.6 => /lib/libc.so.6 (0x007dd000)
            /lib/ld-linux.so.2 (0x007bb000)
    


对于开源软件中可能源代码与配套的构建脚本(配置文件)找不到某些必要的库，试图通过LD_LIBRARY_PATH设置可能失败。

原因通常在与配置文件调用名位pkgconfig的程序，这个程序会从某些元数据文件中接受关于库的信息，这样的文件后缀位.pc，前缀是库的名字。

例如libgcj.pc包含了文件libgcj.so的位置。

pkgconfig搜索.pc文件的默认目录取决与pkgconfig本身的位置。

例如程序位于/usr/lib中则搜索/usr/lib，如果所所需的库是/usr/local/lib，则仅仅这个目录就不够了。

为了解决这个问题，就要设置环境变量PKG_CONFIG_PATH

    
    
    PKG_CONFIG_PATH=/usr/lib/pkgconfig:/usr/local/lib/pkgconfig
    exprot PKG_CONFIG_PATH
    
