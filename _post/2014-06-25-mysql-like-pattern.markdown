---
layout: post
title: 在like中使用通配符
description:  
modified: 
categories: 
- MYSQL
tags:
- 
---

	%				替代一个或多个字符
	_				仅替代一个字符
	[character]		替代其中的任意字符

	[^character]	#非其中任意字符
	[!character]	#同上

	
like操作符用于在where子局中搜索列中指定的模式

	MariaDB [employees]> select * from employees where last_name like "Simm%n" limit 10;
	+--------+------------+------------+-----------+--------+------------+
	| emp_no | birth_date | first_name | last_name | gender | hire_date  |
	+--------+------------+------------+-----------+--------+------------+
	|  11153 | 1957-02-01 | Honglan    | Simmen    | M      | 1990-02-13 |
	|  14971 | 1955-04-07 | Fan        | Simmen    | M      | 1985-12-02 |
	|  15432 | 1963-01-13 | Adib       | Simmen    | F      | 1986-04-16 |
	|  20150 | 1959-11-15 | Dulce      | Simmen    | M      | 1989-06-20 |
	|  21794 | 1958-05-11 | Margo      | Simmen    | F      | 1986-07-03 |
	|  24615 | 1962-10-23 | Arra       | Simmen    | M      | 1988-07-09 |
	|  26052 | 1964-01-13 | Nathan     | Simmen    | F      | 1987-06-09 |
	|  27085 | 1962-09-24 | Irena      | Simmen    | M      | 1985-07-16 |
	|  28068 | 1964-02-28 | Taisook    | Simmen    | M      | 1988-05-18 |
	|  28478 | 1953-11-15 | Chiradeep  | Simmen    | M      | 1986-02-18 |
	+--------+------------+------------+-----------+--------+------------+


如果使用not like则显示的就是非like中的模式

	MariaDB [employees]> select * from employees where last_name not like "Simm%" limit 10;
	+--------+------------+------------+-----------+--------+------------+
	| emp_no | birth_date | first_name | last_name | gender | hire_date  |
	+--------+------------+------------+-----------+--------+------------+
	|  10001 | 1953-09-02 | Georgi     | Facello   | M      | 1986-06-26 |
	|  10003 | 1959-12-03 | Parto      | Bamford   | M      | 1986-08-28 |
	|  10004 | 1954-05-01 | Chirstian  | Koblick   | M      | 1986-12-01 |
	|  10005 | 1955-01-21 | Kyoichi    | Maliniak  | M      | 1989-09-12 |
	|  10006 | 1953-04-20 | Anneke     | Preusig   | F      | 1989-06-02 |
	|  10007 | 1957-05-23 | Tzvetan    | Zielinski | F      | 1989-02-10 |
	|  10008 | 1958-02-19 | Saniya     | Kalloufi  | M      | 1994-09-15 |
	|  10009 | 1952-04-19 | Sumant     | Peac      | F      | 1985-02-18 |
	|  10010 | 1963-06-01 | Duangkaew  | Piveteau  | F      | 1989-08-24 |
	|  10011 | 1953-11-07 | Mary       | Sluis     | F      | 1990-01-22 |
	+--------+------------+------------+-----------+--------+------------+



	MariaDB [employees]> select * from employees where first_name like "_eorgi" and last_name="Facello";
	+--------+------------+------------+-----------+--------+------------+
	| emp_no | birth_date | first_name | last_name | gender | hire_date  |
	+--------+------------+------------+-----------+--------+------------+
	|  10001 | 1953-09-02 | Georgi     | Facello   | M      | 1986-06-26 |
	|  55649 | 1956-01-23 | Georgi     | Facello   | M      | 1988-05-04 |
	+--------+------------+------------+-----------+--------+------------+

	_匹配了一个字符

