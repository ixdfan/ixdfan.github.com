---
layout: post
title:  解决vsftpd无法上传文件的问题
description: 
modified: 
categories: 
- LINUX
tags:
- 
---

将vsftp的配置文件/etc/vsftpd/vsftpd.conf中该设置的都设置了，但是上传文件时候就是不成功,如下:

	ftp> mput rc.tar.gz 
	mput rc.tar.gz? y
	227 Entering Passive Mode (127,0,0,1,141,205).
	553 Could not create file.


vsftp的默认目录在/var/ftp，只要将这个目录的权限改成0777即可
	
	chmod 0777 /var/ftp

	ftp中哪个目录中中如果无法上传就只要修改这个目录的权限即可


