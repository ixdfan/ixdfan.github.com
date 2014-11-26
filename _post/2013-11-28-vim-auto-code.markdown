---
layout: post
title: vim自动建立代码
categories:
- vim
tags:
- vim
---

:h template
查看模板的用法，可以看到
 
    
    To read a skeleton (template) file when opening a new file: >
    
    :autocmd BufNewFile  *.c      0r ~/vim/skeleton.c
    :autocmd BufNewFile  *.h      0r ~/vim/skeleton.h
    :autocmd BufNewFile  *.java   0r ~/vim/skeleton.java
    


如果你想要让vim自动不全一些代码，比如.c文件的代码

你可以写一个.c文件

例如：

    
    
    /*main.c*/
    #include <stdio.h>
    #include <stdlib.h>
    
    int main()
    {
    
      return 0;
    }
    


然后将main.c移动到~/vim/文件夹下，在~/.vimrc中设置如下

    
    
        autocmd BufNewFile *.c 0r ~/vim/main.c
    


含义：新建".c"文件时，自动用模版文件"~/vim/main.c"替换
注意："0r"这个不是"or"而是"零r"
