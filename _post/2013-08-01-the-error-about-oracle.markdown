---
layout: post
title: ORACLE常见错误汇总
categories:
- MYSQL
tags:
- oracle
---

sqlplus 连接不上数据库用system登录提示 Connected to an idle instance信息

\>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

方法一：linux下进入oracle命令重新启动**前提是你配置了Oracle的服务**

1. 重启oracle服务：service oracle restart

2. 查看oracle状态 ：service oracle status

3. 查看oracle实例：echo $ORALCE_SID

\>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

方法二：进入sqlplus对数据库进行shutdown，startup启动。

sqlplu下启动oracle服务，切换到oracle用户
    
    root# suoracle
    oracle$ sqlplus "/as sysdba"
    Connected to an idle instance.
    SQL>startup
输出提示信息等。

\>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

使用edit命令时显示不出vim

    SQL> edit
    Wrote file afiedt.buf
    6
    
    ?

解决方法
SQL>define _editor=vim  
\>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
