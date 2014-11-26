---
layout: post
title: 关于SIGHUP信号
description:  
modified: 
categories: 
- LINUX
tags:
- 
---

记得之前看过有一道面试题目,问为什么远程登录到服务器上执行的某个程序,如果链接突然断开,程序就会被终止呢??

因为链接突然断开会导致中断挂起,产生了SIGHUP信号,bash收到SIGHUP信号它会退出,但是在退出之前,他会将SIGHUP信号传给shell启动的所有进程(例如刚刚执行的那个程序),由于进程中默认没有对SIGHUP信号做处理,所以程序会被终止!

我们可以使用nohup命令使程序不会被终止

nohup命令运行了一个命令来阻断所有发送给该进程的SIGHUP信号,这会在推出终端会话时候阻止进程退出

 $ nohup ./test.sh &

与普通的后台进程一样,但是使用nohup命令,如果关闭该会话,脚本会忽略任何中断会话发过来的SIGHUP信号

由于nohup会从终端解除进程的关联,进程会丢掉STDOUT和STDERR的链接,为了保存该命令产生的输出,nohup命令会自动将STDOUT和STDERR的消息重定向到文件nohup.out中,nohup.out中通常包含了发送到终端显示器上的所有输出

SIGHUP是终端挂起时产生的信号,在Nginx中利用SIGHUP信号来无需退出重新读取配置文件


