---
author: UCSHELL
comments: true
date: 2013-09-17 08:58:10+00:00
layout: post
slug: stringsize_type%e7%b1%bb%e5%9e%8b
title: string与string::size_type类型
wordpress_id: 633
categories:
- THE C\C++
---

前几天在百度上还有人提问关于size_type类型的，没怎么在意，以为就是一个返回类型的定义，今天无意间看到了官方的说法！

string初始化的几种方式：

===========================================

    string s1;
    stirng s1(s1);
    string s3 = s1;
    string s4("hello world");
    string s5(3, "test");	//初始化s5为含有3个test的副本

===========================================

string对象的特点：
1. 读取并忽略开头的所有空白符(空格，换行，制表)
2. 读取字符直到再次遇到空白字符，读取终止

===========================================

    s.empty();
    s.size();
    s[n];
    s1 + s2;
    s1 = s2;
    v1 == v2;
    !=、<、<=、>、>=
===========================================

**string::size()成员函数的返回值不是整形数值，size()返回的类型为size_type类型的值。**

size_type是一个unsigned类型的某个类型。

**注意：**任何存储stirng的size操作结果的变量必须为string::size_type类型

**特别注意**：不要把size()的返回值赋给一个int变量。

===========================================

    
    for(string::size_type ix = 0; ix != str.size(); ix++)
      			str[ix] = '*'


stirng下标的操作符最好也是一个size_type类型的值，当然整形也是可以的

===========================================

string对象和字符串字面量的链接

    
    string s1 = "hello";
    string s2 = "world";
    string s3 = s1 + ",";
    string s4 = "hello" + ',';//错误
    string s5 = s1 + "," + "world"
    string s6 = "hello" + "," + s2;


===========================================

**注意**：进行string对象和字符串字面量混合链接操作时，**+操作符的左右操作数中必须至少有一个是string类型的对象**。所以s4的初始化是错误的。
