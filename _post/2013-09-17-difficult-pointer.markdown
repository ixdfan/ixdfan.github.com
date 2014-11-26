---
layout: post
title: 一个有点绕的指针
categories:
- C\C++
tags:
- 指针
---


    int ia[3][4] = {
            {0, 1, 2, 3},
            {1, 2, 3, 4},
            {2, 3, 4, 5}
    };
    typedef int int_array[4];
    int_array* ip = ia;
    
    for(int_array* p = ia; p != ia+3; ++p)
    {
          for(int* q = *p; q != *p+4; ++q)
          {
            cout << *q << endl;
          }
    }
    


===============================================

ip是一个指针，指向一个含有四个元素的int型数组

ia其实是ia[0]的地址

ia[0]的类型是int [4]

ia的类型就是是指向含有四个元素的int型数组

*p其实就是ia[0];他是一个含有四个元素的指针！

好久没看这么绕的东西了！！！
