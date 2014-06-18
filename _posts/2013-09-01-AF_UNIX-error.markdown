---
author: UCSHELL
comments: true
date: 2013-09-01 13:25:44+00:00
layout: post
slug: '%e4%bd%bf%e7%94%a8af_unix%e4%b8%ad%e7%94%b1%e5%a4%b4%e6%96%87%e4%bb%b6%e5%bc%95%e5%8f%91%e7%9a%84%e9%94%99%e8%af%af'
title: 使用AF_UNIX中由头文件引发的错误
wordpress_id: 539
categories:
- LINUX
---

今天使用unix域函数时候出现了一大屏奇怪的错误，程序很简单，程序本身是没有什么错误的！问题的关键就是头文件,我使用sockaddr\_un的地址与AF_UNIX来编写，但是我的头文件中有<netinet/in.h>这个文件,就是这个文件导致的错误，为了找出这个错误，我把头文件一个一个的注释掉来排查，终于找到了错误，只要把# include <netinet/in.h>去掉就可以了，这也是经验吧，以后写**网络通信时候就不要加<linux/un.h>** ，**本地通信的时候就不要加<*/in.h>**

**<netinet/in.h>与<linux/in.h>同时使用也会造成错误**

**同时头文件的先后顺序也可能造成一些错误**

    
     
    # include <unistd.h>
    # include <stdio.h>
    # include <signal.h>
    # include <stdlib.h>
    # include <sys/types.h>
    # include <sys/socket.h>
    # include <linux/un.h>
    # include <string.h>
    # include <errno.h>
    # include <fcntl.h>
    # include <sys/ipc.h>
    # include <sys/mman.h>
    # include <sys/shm.h>
    # include <linux/in.h>
    //# include <netinet/in.h>
    static void display_err(const char* on_what)
    {
            perror(on_what);
            exit(1);
    }
    
    int main(int argc, char** argv)
    {
            int error;
            int sock_unix;
            struct sockaddr_un addr_unix;
            int len_unix;
            const char path[] = "./test";
    
            sock_unix = socket(AF_UNIX, SOCK_STREAM, 0);
            if(-1 == sock_unix)
            {
                    display_err("socket()");
            }
    
            memset(&addr_unix, 0, sizeof(addr_unix));
    
            addr_unix.sun_family = AF_LOCAL;
    //      strcpy();
            memcpy(addr_unix.sun_path, path, strlen(path));
            len_unix = sizeof(struct sockaddr_un);
    
            error = bind(sock_unix, (struct sockaddr*)&addr_unix, len_unix);
    
            if(-1 == error)
            {
                    display_err("bind()");
            }
            close(sock_unix);
            unlink(path);
    
            return 0;
    }


错误代码如下
    
    [root@localhost network]# cc sock_unix.c -omain
    In file included from /usr/include/arpa/inet.h:23,
    from include.h:16,
    from sock_unix.c:1:
    /usr/include/netinet/in.h:34: 错误：枚举‘IPPROTO_IP’重声明
    /usr/include/linux/in.h:26: 附注：‘IPPROTO_IP’的上一个定义在此
    /usr/include/netinet/in.h:38: 错误：枚举‘IPPROTO_ICMP’重声明
    /usr/include/linux/in.h:27: 附注：‘IPPROTO_ICMP’的上一个定义在此
    /usr/include/netinet/in.h:40: 错误：枚举‘IPPROTO_IGMP’重声明
    /usr/include/linux/in.h:28: 附注：‘IPPROTO_IGMP’的上一个定义在此
    /usr/include/netinet/in.h:42: 错误：枚举‘IPPROTO_IPIP’重声明
    /usr/include/linux/in.h:29: 附注：‘IPPROTO_IPIP’的上一个定义在此
    /usr/include/netinet/in.h:44: 错误：枚举‘IPPROTO_TCP’重声明
    /usr/include/linux/in.h:30: 附注：‘IPPROTO_TCP’的上一个定义在此
    /usr/include/netinet/in.h:46: 错误：枚举‘IPPROTO_EGP’重声明
    /usr/include/linux/in.h:31: 附注：‘IPPROTO_EGP’的上一个定义在此
    /usr/include/netinet/in.h:48: 错误：枚举‘IPPROTO_PUP’重声明
    /usr/include/linux/in.h:32: 附注：‘IPPROTO_PUP’的上一个定义在此
    /usr/include/netinet/in.h:50: 错误：枚举‘IPPROTO_UDP’重声明
    /usr/include/linux/in.h:33: 附注：‘IPPROTO_UDP’的上一个定义在此
    /usr/include/netinet/in.h:52: 错误：枚举‘IPPROTO_IDP’重声明
    /usr/include/linux/in.h:34: 附注：‘IPPROTO_IDP’的上一个定义在此
    /usr/include/netinet/in.h:56: 错误：枚举‘IPPROTO_DCCP’重声明
    /usr/include/linux/in.h:35: 附注：‘IPPROTO_DCCP’的上一个定义在此
    /usr/include/netinet/in.h:58: 错误：枚举‘IPPROTO_IPV6’重声明
    /usr/include/linux/in.h:39: 附注：‘IPPROTO_IPV6’的上一个定义在此
    /usr/include/netinet/in.h:64: 错误：枚举‘IPPROTO_RSVP’重声明
    /usr/include/linux/in.h:36: 附注：‘IPPROTO_RSVP’的上一个定义在此
    /usr/include/netinet/in.h:66: 错误：枚举‘IPPROTO_GRE’重声明
    /usr/include/linux/in.h:37: 附注：‘IPPROTO_GRE’的上一个定义在此
    /usr/include/netinet/in.h:68: 错误：枚举‘IPPROTO_ESP’重声明
    /usr/include/linux/in.h:41: 附注：‘IPPROTO_ESP’的上一个定义在此
    /usr/include/netinet/in.h:70: 错误：枚举‘IPPROTO_AH’重声明
    /usr/include/linux/in.h:42: 附注：‘IPPROTO_AH’的上一个定义在此
    /usr/include/netinet/in.h:82: 错误：枚举‘IPPROTO_PIM’重声明
    /usr/include/linux/in.h:44: 附注：‘IPPROTO_PIM’的上一个定义在此
    /usr/include/netinet/in.h:84: 错误：枚举‘IPPROTO_COMP’重声明
    /usr/include/linux/in.h:46: 附注：‘IPPROTO_COMP’的上一个定义在此
    /usr/include/netinet/in.h:86: 错误：枚举‘IPPROTO_SCTP’重声明
    /usr/include/linux/in.h:47: 附注：‘IPPROTO_SCTP’的上一个定义在此
    /usr/include/netinet/in.h:88: 错误：枚举‘IPPROTO_UDPLITE’重声明
    /usr/include/linux/in.h:48: 附注：‘IPPROTO_UDPLITE’的上一个定义在此
    /usr/include/netinet/in.h:90: 错误：枚举‘IPPROTO_RAW’重声明
    /usr/include/linux/in.h:50: 附注：‘IPPROTO_RAW’的上一个定义在此
    /usr/include/netinet/in.h:93: 错误：枚举‘IPPROTO_MAX’重声明
    /usr/include/linux/in.h:52: 附注：‘IPPROTO_MAX’的上一个定义在此
    /usr/include/netinet/in.h:143: 错误：‘struct in_addr’重定义
    /usr/include/netinet/in.h:226: 错误：‘struct sockaddr_in’重定义
    /usr/include/netinet/in.h:252: 错误：‘struct ip_mreq’重定义
    /usr/include/netinet/in.h:261: 错误：‘struct ip_mreq_source’重定义
    /usr/include/netinet/in.h:288: 错误：‘struct group_req’重定义
    /usr/include/netinet/in.h:297: 错误：‘struct group_source_req’重定义
    /usr/include/netinet/in.h:311: 错误：‘struct ip_msfilter’重定义
    /usr/include/netinet/in.h:332: 错误：‘struct group_filter’重定义
    In file included from /usr/include/netinet/in.h:356,
    from /usr/include/arpa/inet.h:23,
    from include.h:16,
    from sock_unix.c:1:
    /usr/include/bits/in.h:107: 错误：‘struct ip_mreqn’重定义
    /usr/include/bits/in.h:115: 错误：‘struct in_pktinfo’重定义
