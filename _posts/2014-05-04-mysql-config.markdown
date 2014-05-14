---
layout: post
title:  mysql的基本配置
description: 
modified: 
categories: 
-  Mysql
tags:
- 
---

##### Mysql的密码修改:

	#mysqladmin -u root password 123456

连接Mysql数据库

	#mysql -u root -p 然后输入密码


显示数据库列表:

	>show databases;
	#默认自带两个数据库mysql和test，mysql中存储用户相关信息


选择一个数据库

	>use mysql;


查看一个数据库中所有的表
	
	>show tables;

删除所有的数据表:
	
	>drop table worker;

	如果不能肯定一个表是否存在，可以在drop语句中增加if exists 语句

	>drop table if exists worker

删除数据库:

	>drop database company;

#### 注意:都是drop，不是delete

