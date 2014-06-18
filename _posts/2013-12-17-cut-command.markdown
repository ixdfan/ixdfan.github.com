---
author: UCSHELL
comments: true
date: 2013-12-17 04:33:52+00:00
layout: post
slug: cut%e5%91%bd%e4%bb%a4
title: cut命令
wordpress_id: 1280
categories:
- TOOL
---

cut命令:cut命令可以从一个文本文件或者文本流中提取文本列。

	-b:表示字节
	-c:表示字符
	-f:表示字段
	-d:规定了cut命令接受的字段分隔符
	-f:规定了cut命令获取的字段列

/etc/passwd中的内容如下：
root:x:0:0:root:/root:/bin/bash
共有7个字段，用6个冒号分隔开，每个字段分别表示为：
用户名：加密格式的口令：UID：GID：全面账户或其他说明：HOME目录：登录shell

    
    [root@localhost 02]# cut -d ':' -f 1,7 /etc/passwd | grep bash
    root:/bin/bash
    mysql:/bin/bash
    oracle:/bin/bash
    [root@localhost 02]# cut -d ':' -f 1,6,7 /etc/passwd | grep bash | cut -d ':' -f 1,6
    root
    mysql
    oracle
    [root@localhost 02]# cut -d ':' -f 1,6,7 /etc/passwd | grep bash | cut -d ':' -f 1,2
    root:/root
    mysql:/var/lib/mysql
    oracle:/home/oracle


-d ':'的含义是使用冒号作为cut的分隔符

-f 1,7的含义使得cut截取第一列和第七列

cut -d ':' -f 1,6,7 /etc/passwd | grep bash | cut -d ':' -f 1,2

表示先取得1,6,7列，使用bash过滤，然后将以冒号作为分隔符，将结果的1,2列都打印出来

========================================================================
