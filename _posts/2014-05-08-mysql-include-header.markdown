---
layout: post
title:  将mysql的头文件加入自动搜索
description: 
modified: 
categories: 
- mysql
tags:
- 
---

gcc 在编译时如何去寻找所需要的头文件：

命令行参数-I

然后找gcc的环境变量 C_INCLUDE_PATH,CPLUS_INCLUDE_PATH,OBJC_INCLUDE_PATH

再找以下目录

	/usr/include
	/usr/local/include
	/usr/lib/gcc-lib/i386-linux/2.95.2/include
	/usr/lib/gcc-lib/i386-linux/2.95.2/../../../../include/g++-3
	/usr/lib/gcc-lib/i386-linux/2.95.2/../../../../i386-linux/include

如果只对当前用户有效在Home目录下的.bashrc或.bash_profile里增加下面的内容(对所有用户有效则是在/etc/profile):

	#在PATH中找到可执行文件程序的路径。
	export PATH =$PATH:$HOME/bin
	
	#gcc找到头文件的路径
	C_INCLUDE_PATH=/usr/include/libxml2:/MyLib
	export C_INCLUDE_PATH
	
	#g++找到头文件的路径
	CPLUS_INCLUDE_PATH=$CPLUS_INCLUDE_PATH:/usr/include/libxml2:/MyLib
	export CPLUS_INCLUDE_PATH
	
	#找到动态链接库的路径
	LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/MyLib
	export LD_LIBRARY_PATH
	
	#找到静态库的路径
	LIBRARY_PATH=$LIBRARY_PATH:/MyLib
	export LIBRARY_PATH

直接在.bashrc中加入:

	C_INCLUDE_PATH=/usr/include/mysql	#mysql.h的路径
	export C_INCLUDE_PATH	

因为我的C_INCLUDE_PATH原来没有值，所以直接给它赋值
