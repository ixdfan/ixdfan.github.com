---
author: UCSHELL
comments: true
date: 2013-10-13 11:21:02+00:00
layout: post
slug: nginx%e5%ae%89%e8%a3%85%e8%bf%87%e7%a8%8b%e4%b8%ad%e7%9a%84%e5%87%a0%e4%b8%aa%e9%97%ae%e9%a2%98
title: Nginx安装过程中的几个问题
wordpress_id: 850
categories:
- Ngix
tags:
- Nginx
---

Nginx的安装问题
首先下载Nginx，为了学习我下载的是1.20版本的！

下载完成后解压编译

    tar zxvf nginx-1.20.tar.gz
    cd nginx-1.20
    ./configure
    make
    make install
    
但是编译出错了！错误内容如下

    ./configure: error: the HTTP rewrite module requires the PCRE library.
    You can either disable the module by using --without-http_rewrite_module
    option, or install the PCRE library into the system, or build the PCRE library
    statically from the source with nginx by using --with-pcre= option.
    
提示说是缺少一个PRCE库文件，那就下载库文件

	ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/
    
在这里可以下载，不知道为什么我的Chrome无法正常打开这个地址，换了一个就好了

PCRE库安装完成了！OK继续make install

OK!成功了！

执行一下

    [root@localhost sbin]# ./nginx
    ./nginx: error while loading shared libraries: libpcre.so.1: cannot open shared object file: No such file or directory
又出错了！！！！！！！

其实我觉得Linux哪都好就是这个软件安装很烦！

提示说libpcre.so.1找不到，使用ldd查看都要加载哪些！

    [root@localhost sbin]# ldd $(which /usr/local/nginx/sbin/nginx)
    linux-gate.so.1 => (0x00341000)
    libpthread.so.0 => /lib/libpthread.so.0 (0x00cf3000)
    libcrypt.so.1 => /lib/libcrypt.so.1 (0x0451e000)
    libpcre.so.1 => not found
    libcrypto.so.10 => /usr/lib/libcrypto.so.10 (0x00625000)
    libz.so.1 => /lib/libz.so.1 (0x00d10000)
    libc.so.6 => /lib/libc.so.6 (0x00b27000)
    /lib/ld-linux.so.2 (0x00b01000)
    libfreebl3.so => /lib/libfreebl3.so (0x045d5000)
    libdl.so.2 => /lib/libdl.so.2 (0x00cec000)

果真是libpcre.so.1 => not found

进入lib下手动添加链接

    [root@localhost sbin]# cd /lib
    [root@localhost sbin]# ls -l libprce.so.0.0.1
    [root@localhost sbin]# ln -s libprce.so.0.0.1 libprce.so.1
再次执行！OK了！

    [root@localhost sbin]# /usr/local/nginx/sbin/nginx
    root@localhost sbin]# ps -ef | grep nginx
    root 21083 1 0 19:04 ? 00:00:00 nginx: master process /usr/local/nginx/sbin/nginx
    nobody 21084 21083 0 19:04 ? 00:00:00 nginx: worker process
    root 21088 20915 0 19:04 pts/1 00:00:00 grep nginx
