---
layout: post
title: 内核Makefile的编写
categories: 
- KERNEL
tags:
- 
---

	ifneq (($KERNELRELEASE),)
	#第一次进入Makefile时候KERNELRELEASE是空值，所以会执行else
	obj-m := hello
	
	else
	
	#内核的目录
	KDIR := /lib/modules/$version/build
	
	all:
		#-C表示进入到其后的目录中，使用该目录中的Makefile来编译
		#M表示的是你要编译的模块的为止
		#modules是Makefile中的目标
		make -C $(KDIR) M=$(PWD) modules
		#执行后会再次进入本Makefile文件，此时KERNELRELEASE不为空
	clean:
		rm -rf *.o *.ko
	
	endif

-------------------------------------------------------------------------------

多个源文件时候Makefile的编写

	ifneq ($(KERNELRELEASE),)

	#obj-m决定编译出的内核模块的名字 
    #hello.ko就会是你编译出模块的名字
	obj-m := hello.o
	#hello-objs中-objs是固定的，但是前面必须与obj-m后的对应
	#hello模块是由main.o和add.o组成的
	hello-objs := main.o add.o

	#例如
	#obj-m := mymodules.o
	#mymodules-objs := main.o add.o
	
	else
	
	#内核的目录
	KDIR := /lib/modules/$version/build
	
	all:
		#-C表示进入到其后的目录中，使用该目录中的Makefile来编译
		#M表示的是你要编译的模块的为止
		#modules是Makefile中的目标
		make -C $(KDIR) M=$(PWD) modules
		#执行后会再次进入本Makefile文件，此时KERNELRELEASE不为空
	clean:
		rm -rf *.o *.ko
	
	endif

-------------------------------------------------------------------------------

#### 模块的安装与卸载

- insmod 安装模块
- rmmod  卸载模块
- lsmod  显示已经安装的模块
- modprobe 安装模块

insmode与modprobe都是加载模块，但是modprobe会根据文件

	/lib/modules/$version/modules.dep
查看要加载的模块是否依赖于其他模块，如果是，则modprobe会首先找到这些模块，将他们加载到内核中

例如模块a依赖模块b1-b10，那么使用insmod加载模块a就要先手动加载模块b1-b10，一个一个加载，最后在加载模块a，使用modprobe在加载模块a时自动加载b1-b10
