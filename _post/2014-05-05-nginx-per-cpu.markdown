---
layout: post
title:  nginx的多核绑定
description: 
modified: 
categories: 
- Nginx
tags:
- 
---

#### 多核绑定

对于多核平台的优化，最核心的思路就是per-cpu处理，这样才能做到性能按cpu线性扩展。

nginx在多核平台上针对负载均衡和优化所做的工作，就是提供了worker_cpu_affinity配置指令，该指令可以将工作进程固定在指定的CPU核上运行，这个又叫做cpu亲和性;

CPU亲和性就是让某一段代码/数据尽量的在指定的一个或几个cpu核心上长时间运行/计算的机制。

nginx将工作进程绑定到指定cpu是cpu affinity的一种应用

nginx中配置cpu亲和性的使用配置首先根据系统CPU个数设定工作进程数目，我的CPU是4核，所以就设定为4,一般工作进程数目与CPU数目一致，否则太多可能导致进程切换频繁，使得整体性能下降。

让0号工作进程运行在0号cpu上，一号进程运行在1号cpu上

可以在配置文件中使用
	
	5 worker_processes  4;					#指定4个工作进程
	6 worker_cpu_affinity 01 10 100 1000;	#指定各个工作进程使用哪个CPU

worker_cpu_affinity指令的配置值是位图表示法，从前往后分别是0号工作进程、1号工作进程的CPU二进制掩码(各个掩码之间使用空格隔开)，所以这里0号工作进程的CPU掩码为01,表示使用0号cpu，1号工作进程的cpu掩码为10,表示使用1号cpu，如果某个工作进程的掩码是11,则表示既使用0号CPU又使用1号cpu。

其中PSR代表的是cpu编号，可以看到4个worker进程分别在0-3的cpu上
	[root@ sbin]# ps -elHF | grep UID  | grep -v grep
	F S UID        PID  PPID  C PRI  NI ADDR SZ WCHAN    RSS PSR STIME TTY          TIME CMD

	[root@ sbin]# ps -elHF | grep nginx | grep -v grep
	1 S root      3473     1  0  80   0 -  1032 sigsus   480   2 10:15 ?        00:00:00   nginx: master process ./nginx
	5 S nobody    3474  3473  0  80   0 -  1076 SyS_ep   828   0 10:15 ?        00:00:00     nginx: worker process
	5 S nobody    3475  3473  0  80   0 -  1076 SyS_ep   828   1 10:15 ?        00:00:00     nginx: worker process
	5 S nobody    3476  3473  0  80   0 -  1076 SyS_ep   828   2 10:15 ?        00:00:00     nginx: worker process
	5 S nobody    3477  3473  0  80   0 -  1076 SyS_ep   828   3 10:15 ?        00:00:00     nginx: worker process


或者直接使用命令

	ps -eo pid,args,psr来查看那个每个进程所属CPU

-o指定了ps的输出参数
