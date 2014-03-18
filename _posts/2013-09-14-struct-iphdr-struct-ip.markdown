---
author: UCSHELL
comments: true
date: 2013-09-14 02:40:35+00:00
layout: post
slug: struct-iphdr%e4%b8%8estruct-ip%e7%9a%84%e5%8c%ba%e5%88%ab
title: struct iphdr与struct ip的区别
wordpress_id: 596
categories:
- THE LINUX
tags:
- iphdr
---

ip头结构

====================================================

    
    struct iphdr{
    #if defined(__LITTLE_ENDIAN_BITFIELD)
    	 __u8    ihl:4,
                    version:4;
    #elif defined (__BIG_ENDIAN_BITFIELD)
            __u8    version:4,
                    ihl:4;
    #else
    #error  "Please fix <asm/byteorder.h>"
    #endif
            __u8    tos;
            __be16  tot_len;
            __be16  id;
            __be16  frag_off;
            __u8    ttl;		
            __u8    protocol;
            __sum16 check;
            __be32  saddr;
            __be32  daddr;
    };

ttl：生存时间字段设置了数据报可以经过的最多路由器数

如果设为0，数据包无法穿越本机

设为1数据包无法穿过路由器，

设为2数据包无法穿越第二个路由器

以此类推

ihl：ip头的长度。**单位是32bit(也就是4字节)**，用来表示IP层头部占32 bit字的数目，所以如果想要表示成字节的话要乘以4

tot_len：报文的总长度,包括IP头

====================================================

    
    struct ip
      {
    #if __BYTE_ORDER == __LITTLE_ENDIAN
        unsigned int ip_hl:4;               /* header length */
        unsigned int ip_v:4;                /* version */
    #endif
    #if __BYTE_ORDER == __BIG_ENDIAN
        unsigned int ip_v:4;                /* version */
        unsigned int ip_hl:4;               /* header length */
    #endif
        u_int8_t ip_tos;                    /* type of service */
        u_short ip_len;                     /* total length */
        u_short ip_id;                      /* identification */
        u_short ip_off;                     /* fragment offset field */
    #define IP_RF 0x8000                    /* reserved fragment flag */
    #define IP_DF 0x4000                    /* dont fragment flag */
    #define IP_MF 0x2000                    /* more fragments flag */
    #define IP_OFFMASK 0x1fff               /* mask for fragmenting bits */
        u_int8_t ip_ttl;                    /* time to live */
        u_int8_t ip_p;                      /* protocol */
        u_short ip_sum;                     /* checksum */
        struct in_addr ip_src, ip_dst;      /* source and dest address */
      };


**struct iphdr与struct ip的主要区别**：

struct iphdr是在linux下定义的IP头

BSD中使用的是struct ip

假如使用sruct iphdr在linux中使用没有问题，但是到了BSD中就会报错了

参看：http://forums.freebsd.org/showthread.php?t=21960

    struct iphdr is a linux style definition of IP header,it holds same data structure as BSD struct ip.

===========================================

开始的时候被大小端的定义把自己给绕弄糊涂了，不知道version与inl在内存的位置如何

最后才记起当时学汇编时候的小端的例子，

小端是从小向大分配地址，两字节中，高8位在后，低8位在前

大端是从大向小分配地址，两字节中，高8位在前，低8为在后

===========================================
小端
    低                   高
    -------------------------------
    | ihl 	| 	version |
    --------------------------------

大端
    高                    低
    -------------------------------
    | version 	| 	ihl |
    --------------------------------

===========================================
