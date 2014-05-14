---
layout: post
title: 自动作业处理
description: 
modified: 
categories: 
- shell 
tags:
- 
---

##### crontab

启动crontab进程
	
	service crontab start

停止crontab进程

	service crontab stop

重新启动crontab进程
	
	service crontab restart


crontab的选项

	crontab [-u user] [-e] [-l] [-r] [-i]

-e	编辑用户的crontab文件

-l	列出用户在crontab中设定的任务

-r 	删除用户在crontab中的任务

-i	交互模式，删除用户设定的任务前进行提示

-u user



	# Example of job definition:
	# .---------------- minute (0 - 59)
	# |  .------------- hour (0 - 23)
	# |  |  .---------- day of month (1 - 31)
	# |  |  |  .------- month (1 - 12) OR jan,feb,mar,apr ...
	# |  |  |  |  .---- day of week (0 - 6) (Sunday=0 or 7) OR sun,mon,tue,wed,thu,fri,sat
	# |  |  |  |  |
	# *  *  *  *  * user-name  command to be executed


分钟:每小时第几分钟执行，取值0-59

小时:每天第几小时执行，取值0-23

日期:每月第几天执行，取值0-31

月份:每年的第几月执行，取值0-12或英文缩写May、Feb、Nov等

星期:每周第几天执行，取值0-6或英文缩写Sun、Mon、Tue

用户:执行该命令的用户，root等

命令:定期执行的命令，date等

在时间域中，可以使用'-'代表一段时间，例如在小时后输入6-12表示每小时的6、7、8、9、10、11、12分钟;

可以使用'*'表示全部时间，例如在日期字段输入'*'则表示每个月的每一天都执行该命令;

使用','表示特定时间，例如:在月份中输入'3,5,12',则表示一年的3月、5月、12月;

使用'/'表示每隔,例如:在分钟字段中输入*/5表示每隔5分钟。


修改crontab文件之后不需要重新启动crontab服务程序，crontab会自动根据文件内容刷新任务里表


实例:
	
使用crontab -e添加新的任务

每隔5分钟将系统时间写入~/work/cron_test

	*/5 * * * * date >> ~/work/cron_test

每月的3日23:30自动删除/var/log/httpd目录下所有文件

	30 23 3 * * root rm -rf /var/log/httpd/*

每隔5分钟查询一次系统中当前运行的进程，并保存到~/work/cron_test

	*/5 * * * * * ps aux > ~/work/cron_test

每周一的1:00 3:00 8:00各自查询一次根目录结构，并保存到~/work/cron_test

	0 1,3,8 * * * ls -l > ~/work/cron_test



不带-u选项使用crontab命令，系统默认认为当前用户创建任务，如果为其他用户设定只要在-u后面指定用户，例如，编辑用户Test的任务时候

	#crontab -e -u Test


-l选项可以列出所有任务的列表，例如列出root用户的列表


#### at

at也是一种任务管理工具，不过与crontab不同的是，at命令设置的任务只在某个时刻执行，并且只执行一次，如果要使用at命令调度程序，必须先启动atd守护进程,atd启动之后可以使用at命令设定任务

	at [-c] [-V] [-q queue] [-f file] [-m] [-l] [-d] [-v] TIME

-m:	当指定的任务被完成之后，将给用户发送邮件，即使没有标准输出;

-l: 等同于atq命令

-d: 等同于atrm命令

-v: 显示任务被执行的时间

-V: 版本信息

-q queue: 	使用指定的队列

-f file: 	从指定文件读入任务，而不是从标准输入读入

TIME:		指定任务执行的时间



	#输入命令后使用Ctrl+D退出at模式
	#00:02执行ls -l，并保存
	[root@ Note]# at 00:02
	at> ls -l > ~/work/at
	at> <EOT>
	job 5 at Thu May  8 00:02:00 2014
	[root@ Note]#


时间的设定可以是多种格式,例如:
8:50pm、+10days、tomorrow、now、noon、midnight等

	#一分钟后执行某命令
	[root@ Note]# at +1

	#明天下午4点执行某任务
	[root@ Note]# at 4pm tomorrow

	#两天后早上九点执行
	[root@ Note]# at 9am+2days

	#查询已分配的任务
	[root@ Note]# at -l

#### batch命令:批处理

batch命令用来实现批处理，即一次连接执行多个命令


	[root@ batch]# ls
	test1.doc  test2.doc  test3.doc
	#批处理，删除当前目录下test1.doc test2.doc文件
	[root@ batch]# batch
	at> rm test1.doc
	at> rm test2.doc
	at> <EOT>
	job 8 at Wed May  7 00:13:00 2014
	[root@ batch]# ls
	test3.doc
	
