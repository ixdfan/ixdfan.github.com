---
layout: post
title: Fedora19安装Monaco字体
categories:
- TOOL
---

最近使用终端发现字体有一种说不出来的别扭，以前看到过一篇文章是推荐编程字体的！

找了一下，就是Monaco字体，原来是苹果系统专用的！

字体下载:
http://www.gringod.com/wp-upload/MONACO.TTF

安装

    
    
    cd /usr/share/fonts/
    
    sudo cp $HOME/MONACO.TTF .      #拷贝MONACO字体到/usr/share/fonts/文件中
    
    sudo fc-cache -v -f .
    
