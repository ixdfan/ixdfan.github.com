---
layout: post
title: bind与connect错误的原因
description: 
modified: 
tags: [linux,bind]
---


bind常见的两种错误errno是EACCESS和EADDRINUSE
* EACESS,被绑定的地址是受保护的地址，仅仅超级用户能够访问，比如普通用户将socket绑定到漠哥知名服务端口(0-1023)上时，就会返回EACCESS
* EADDRINUSE,被绑定的地址正在使用中，比如将socket绑定到一个处于TIME-WAIT状态的socket地址

connect常见的两种错误errno是ECONNREFUESD和ETIMEOUT
* ECONNREFUESD目标端口不存在，连接被拒绝
* ETIMEOUT连接超时
