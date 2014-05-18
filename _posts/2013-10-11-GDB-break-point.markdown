---
author: UCSHELL
comments: true
date: 2013-10-11 06:22:10+00:00
layout: post
slug: gdb%e9%ab%98%e7%ab%af%e8%b0%83%e8%af%95%e4%ba%8c
title: GDB调试(二):断点相关
wordpress_id: 826
categories:
- GDB
tags:
- GDB
---

GDB断点相关

在GDB中删除断点

如果确认不在需要当前断点时，那么可以删除该断点。

GDB中有两个用来删除断点的命令。

delete用来基于标示符删除断点

=============================================================

    delete breakpoint_list 删除使用数字标示符表示的断点。
    
    delete 2 删除第二个断点
    
    delete 2 4 删除第二四个断点

##### 注意：

delete不带参数 删除所有断点

clear不带参数 清除GDB将执行的下一个指令处的断点，主要适用于要删除GDB已经到达的断点的状况。

=============================================================

在GDB中禁用断点

每个断点都可以禁用或启用，只有遇到启用的断点时候GDB才会暂停程序的执行。他会忽略禁用的断点；

如果要保留断点以便以后使用暂时又不希望GDB停止执行，可以暂时禁用他们在以后需要时在执行！

    disable breakpoint-list 禁用断点
    enable breakpoint-list 启用断点

    disable 3 禁用第三个断点
    enable 3 5 启用第三和第五个断点

##### 注意：
disable不带任何参数将禁用所有断点
enable不带任何参数将启用所有断点

    enable one：在断点下次引起GDB暂停执行后被禁用，命令形式：
    enable once breakpoint-list
    enable once 3 会使得断点3在下次导致GDB停止程序后被禁用而不是删除，与tbreak非常类似，但tbreak是删除！

=============================================================

条件断点

	break break-args if (condition)

其中break-args是可以传递给break用来指定断点的任何参数
conditon是布尔表达式,condition的括号是可选的

例如：

    
    
    for(i=0; i<70000; ++i)
    {
    	sum = i;			//第十行
    }
    
    break 10 if (i==70)
    break main if (argc > 1)
    
    break 180 if (string==NULL && i < 0)
    break test.c:34 if (x&y;) == 1
    break myfunc if i % (j + 3) != 0
    break 44 if (strlen(mystring) == 0)
    break test.c:myfunc if (! check_variable_sanity(i))
    


=============================================================

info breakpoints命令(i b)的解释


* Num:断点的标识符
* Address:内存中设置断点的位置
* Type:断点的类型，是断点、监视点、还是捕获点
* Enb:启用状态，说明断点当前是启用的还是禁用的
* Disp:每个断点都有一个部署，知识断点下次引起GDB暂停程序的执行后该断点会发生什么；
主要为一下三种类型：
1. keep:保持，下次到底断点后不会删除断点，属于默认部署 
2. del:删除，下次到达断点后删除该断点，使用tbreak创建的断点都是这样的断点
3. dis:下次到达断点时候会禁用该断点，enable once设置的断点

-------------------------------------------------------------------------------------------

最后可以看到显示出每个断点引起GDB停止执行了多少次，如果循环中有一个断点，这个命令会马上告诉你到目前为止循环执行了多少次迭代，非常好用

=============================================================

使用continue继续执行直到遇到下一个断点或程序结束

continue n 表示忽略下面n个断点。例如：

continue 3 意思就是继续执行并忽略下面的n个断点

=============================================================

**finish**命令的作用是GDB恢复执行，直到恰好当前函数执行完毕后为止。

比如进入了一个函数中单步调试找打了错误，想要直接跳出这个函数到main中调用函数的下一行那么就可
以使用finish

比如本来你希望用next直接执行完函数但是不小心使用了step，那么你可以使用finish直接从函数返回

比如在递归中finish将带你到递归的上一层，因为每次调用都被看做是在自己范围内的函数调用，每个函数都有自己的帧栈。

如果在递归层次较高时完全退出递归函数，那么更适合使用临时断点和continue组合或是使用until命令。

=============================================================

**until**(简写为u)通常是在不进一步在函数中暂停的情况下完成当前函数的执行。
until通常用来不进一步在循环中暂停的情况来完成正在执行的循环

比如:

    
    int i = 99999;
    while(i)
    {
    	printf("i = %d\n", i);
    }
    future code……
    ……


假设GDB在while处有一个断点上停止，现在打算离开循环去调试future code 处的代码！
但是问题是i相当的大，但不能使用finish，因为finish会直接执行future code代码，将我们带出函数；
此时我们可以在future code处设置一个断点并使用continue；
但是这恰恰就是until能够处理的代码；
使用until会执行循环的其余部分，让GDB在循环后面的第一行代码(就是futrue code)处暂停

=============================================================

until可以接受源代码中位置作为参数，与break类似

    until 17
    until swap
    until swapflaw.c:17
    until swapflaw.c:swap
一直执行到swap的入口处停止
