---
layout: post
title: 查看mysql表结构
description:  
modified: 
categories: 
- MYSQL
tags:
- 
---


查看一个表有那些字段,各个字段的类型是什么?

可以使用一下三种方法

####	show columns from table_name;
####	descript table_name;
####	desc table_name;

	MariaDB [employees]> show columns from employees;
	+------------+---------------+------+-----+---------+-------+
	| Field      | Type          | Null | Key | Default | Extra |
	+------------+---------------+------+-----+---------+-------+
	| emp_no     | int(11)       | NO   | PRI | NULL    |       |
	| birth_date | date          | NO   |     | NULL    |       |
	| first_name | varchar(14)   | NO   |     | NULL    |       |
	| last_name  | varchar(16)   | NO   |     | NULL    |       |
	| gender     | enum('M','F') | NO   |     | NULL    |       |
	| hire_date  | date          | NO   |     | NULL    |       |
	+------------+---------------+------+-----+---------+-------+
	6 rows in set (0.00 sec)

	MariaDB [employees]> desc employees;
	+------------+---------------+------+-----+---------+-------+
	| Field      | Type          | Null | Key | Default | Extra |
	+------------+---------------+------+-----+---------+-------+
	| emp_no     | int(11)       | NO   | PRI | NULL    |       |
	| birth_date | date          | NO   |     | NULL    |       |
	| first_name | varchar(14)   | NO   |     | NULL    |       |
	| last_name  | varchar(16)   | NO   |     | NULL    |       |
	| gender     | enum('M','F') | NO   |     | NULL    |       |
	| hire_date  | date          | NO   |     | NULL    |       |
	+------------+---------------+------+-----+---------+-------+
	6 rows in set (0.04 sec)





