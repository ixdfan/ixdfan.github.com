---
author: UCSHELL
comments: true
date: 2014-02-25 01:37:25+00:00
layout: post
slug: fedora19%e5%ae%89%e8%a3%85fcitx%e8%be%93%e5%85%a5%e6%b3%95
title: fedora19安装fcitx输入法
wordpress_id: 1310
categories:
- TOOL
---

今天终于装上了久违的fcitx，之前没有安装成功，今天终于成功啦！fcitx果然比ibus好用的很，
哇哈哈！

    
    
    yum remove ibus
    yum install fcitx*
    
    im-chooser      #选择fcitx输入法
    
    vim .bashrc
    export XMODIFIERS="@im=fcitx"
    export QT_IM_MODULE=fcitx
    export GTK_IM_MODULE=fcitx
    
    vim /etc/profile
    export XMODIFIERS="@im=fcitx"
    export QT_IM_MODULE=fcitx
    export GTK_IM_MODULE=fcitx
    
    logout
    
    



OK！！！

现在好像可以不用卸载ibus了

配置以允许使用 iBus 之外的输入法：

	gsettings set org.gnome.settings-daemon.plugins.keyboard active false

第一次logout时候弹出一个提示说什么input method not use之类的话，然后我发现我之前在gnome-session-properties中设置了fcitx自启动，所以导致冲突了，只要取消即可。

但是使用Ctrl+Space仍然是没有办法调用fcitx，网上查了很多相关的问题，终于找到了解决方法，原来是gnome中设置默认的输入法切换也是Ctrl+Space，与fcitx configuration中的又冲突了，所以将keyboard中的shortcut中的typing中的关于Ctrl+Space的设置Disable就可以使用了！
