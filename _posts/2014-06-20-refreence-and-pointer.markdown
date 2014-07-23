---
layout: post
title: 引用与指针的区别
description:  
modified: 
categories: 
- C\C++
tags:
- 
---

#### 引用与指针的区别

1. 引用总是指向某个对象，定义引用时没有初始化是错误的。
2. 赋值行为的差异:给引用赋值修改的是该引用锁关联对象的值，而不是去引用另外一个对象。引用已经初始化，终身不变


======================

一个关于typedef与指针的问题

	typedef string* pstring;
	const pstring cstr;

请问cstr变量的类型:

很多人会认为真正的类型是

	const string* cstr;

即const pstring是一个指针，指向string类型的const对象，但是这是错误的

错误原因在于将typedef当作了文本扩展，声明const pstring时，const修饰的是pstring的类型，这是一个指针，所以const修饰的是一个指针，所以声明语句是将cstr定义为指向string类型对象的const指针，这个定义等价于:

	string* const cstr;
