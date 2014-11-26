---
layout: post
title: makefile与vim联合使用
categories:
- vim
tags:
- vim
---


    /*main.c*/
    int main()
    {
      int m;
      m = n + m;
      m = m * m
      m = m++;
      return 0;
    }
    


makefile

    
    
    main:main.c
      cc main.c -omain
    


在vim中直接使用
:make

即可执行makefile文件，并且当main.c中出现错误时，按下ENTER回到编辑程序后，光标将会停留在第一条警告或是错误的代码上.

修复了这个错误后，可以使用

===================================================

:cc	显示当前警告或错误

:cnext	显示下一条警告或错误

:cprevious	显示上衣个警告或错误

===================================================

这三个命令都会将光标位于活动错误或警告的位置
