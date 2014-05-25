---
author: UCSHELL
comments: true
date: 2013-09-21 03:09:52+00:00
layout: post
slug: '%e4%bd%a0%e4%b8%8d%e7%9f%a5%e9%81%93%e7%9a%84%e5%ae%8f'
title: 你不知道的宏
wordpress_id: 717
categories:
- THE C\C++
---



    
    #define swap(x, y)	( (x) = (x) + (y) - ( (y) = (x) ) )//交换两个数的宏
    
===============================================

	#define STR(x)  #x
    #define WELCOME(who) welcome##who()	//注意： WELCOME(who)之间不能有空格
    void welcomestudent()
    {
            puts("welcome student");
    }
    void welcometeacher()
    {
            puts("welcome teacher");
    }
    
    int main()
    {
    	printf("%s",STR(HELLO));
            WELCOME(teacher);
            return 0;
    }

===============================================

关于'#'与'##'

'#'的作用是将参数变换成对应的字符串

'##'的作用是连接字符，起拼接作用

===============================================

#### 注意：

宏只是起**简单的替换作用**，宏的使用要加全长括号

即每一个参数都要用括号括起来，整体也要加括号

宏一般使用大写

===============================================
