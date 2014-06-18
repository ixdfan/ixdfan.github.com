---
author: UCSHELL
comments: true
date: 2014-02-26 13:12:28+00:00
layout: post
slug: fedora19%e5%ae%89%e8%a3%85monaco%e5%ad%97%e4%bd%93
title: Fedora19安装Monaco字体
wordpress_id: 1329
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
    
