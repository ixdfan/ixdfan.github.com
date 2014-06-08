---
layout: post
title:  kernel中min宏函数
description: 
modified: 
categories: 
- kernel 
tags:
- 
---

	#define min(x,y) ({ \
	    const typeof(x) _x = (x);   \
		const typeof(y) _y = (y);   \
		(void)(&_x == &_y); 		\		
		_x < _y ? _x : _y;})

sizeof(x)的作用是测量x的大小,typedef(x)的作用自然是获取x变量的类型
			
(void)(&_x == &_y)这句话的作用是用来判断类型是否一致的!之前一直没有搞明白这句话的用处!

例如,我们定义了两个变量

	int 	in = 5;
	char	ch = '6';

	if (&in == &ch);	

如果这样比较的话编译器会告诉你两种指针的类型不相同,会有警告或是错误提示

例如以下程序:

	[root@ work]# cat test.c 
	#include <stdio.h>
	
	#define min(x,y) ({ \
		const typeof(x) _x = (x);   \
		const typeof(y) _y = (y);   \
		(void)(&_x == &_y); 		\		
		_x < _y ? _x : _y;})
	
	Int main(int argc, char** argv)
	{
		int a = 1;
		double d = 2;
		printf("%lf\n", min(a, d));
		return 0;
	}

   [root@ work]# cc test.c -omain
   test.c:6:24: warning: backslash and newline separated by space [enabled by default]
   (void)(&_x == &_y);   \  
   ^
   test.c: In function ‘main’:
   test.c:6:13: warning: comparison of distinct pointer types lacks a cast [enabled by default]
   (void)(&_x == &_y);   \  
   ^
   test.c:13:18: note: in expansion of macro ‘min’
   printf("%lf\n", min(a, d));



