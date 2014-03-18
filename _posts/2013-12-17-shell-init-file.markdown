---
author: UCSHELL
comments: true
date: 2013-12-17 02:25:21+00:00
layout: post
slug: shell%e5%90%af%e5%8a%a8%e6%96%87%e4%bb%b6%e7%9a%84%e5%bc%82%e5%90%8c
title: shell启动文件的异同
wordpress_id: 1250
categories:
- THE SHELL
---

启动文件：

一直以来都是按照网上的说法修改某某文件让他永久生效，今天终于看到来官方的说法了！

shell中使用一些启动文件来协助创建一个运行环境，其中每个文件都有特定的用途，对登录和交互换将的影响也各不相同。

**/etc目录下的文件提供全局设置，如果用户**

** 主目录下存在同名文件，它将覆盖全局设置;**

使用/bin/login读取/etc/passwd文件成功后，启动了一个交互登录shell。用命令行可以启动一个交互非登录shell。

非交互shell通常出现在shell脚本运行的时候，之所以称为非交互的，因为他在运行一个脚本，而且命令与面临之间并不等待用户的输入；

无论运行什么shell，文件/etc/environment都先运行。

/etc/environment设置例如最小搜索路径、时区、语言等用户环境，它只接受一下格式的数据

    
    name=


init开始的所有进程都要执行这个文件，他会影响所有的登录shell。

不同的shell执行的后续程序有所不同：

**$HOME/.login与$HOME/.profile和/etc/profile仅在登录的时候有效**

**/etc/目录下的文件提供全局设置，如果用户主目录下存在同名文件，他将会覆盖全局设置**

bash的启动文件

    
    /etc/profile		系统范围的默认值，大部分用来设置环境变量
    
    /etc/bashrc		特地与Bash，系统范围函数与别名
    
    $HOME/.bash_profile	用户定义的，环境默认设置，在每个用户的home目录下
    
    $HOME/.bashrc		用户定义的Bash初始文件
    
    $HOME/.bash_logout	登出文件，用户定义的指令文件，在登出Bash时候这个文件中个命令会被执行


**$HOME/.profile的优先级高于/etc/profile，这样用户登录时会自动加载环境变量的改变**
##### 注意：
$HOME变量的值是登录者的用户目录
