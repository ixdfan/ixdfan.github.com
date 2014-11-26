---
layout: post
title: 你不知道的宏
categories:
- C\C++
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
