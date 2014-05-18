---
author: UCSHELL
comments: true
date: 2013-11-28 06:59:58+00:00
layout: post
slug: http%e5%8d%8f%e8%ae%ae
title: HTTP协议
wordpress_id: 1109
categories:
- 网络编程
tags:
- STL
---

====================================================================

http是一个基于请求与响应模式的、**无状态的、应用层的协议**，常基于TCP的连接方式，HTTP1.1版本中给出一种持续连接的机制。

HTTP URL (URL是一种特殊类型的URL，包含了用于查找某个资源的足够的信息)的格式如下：

	http://host[:port][abs_path]

http表示要通过HTTP协议来定位网络资源；

host表示合法的Internet主机域名或者IP地址；

port指定一个端口号，为空则使用缺省端口80；

abs_path指定请求资源的URL；

如果URL中没有给出abs_path，那么当它作为请求URL时，必须以“/”的形式给出，通常这个工作浏览器自动帮我们完成。

例如:

输入：www.baidu.com

浏览器自动转换成：
	http://www.baidu.com/
	http:192.168.128.128:8080/index.html

====================================================================

HTTP请求消息格式

HTTP请求由三部分组成:**请求行、消息报头、请求正文**

请求行以一个方法符号开头，以空格分开，后面跟着请求的URL和协议的版本;

格式如下：

Method Request-URL HTTP-Version CRLF

	Method表示请求方法；
	Request-URL是一个统一资源标识符；
	HTTP-Version表示请求的HTTP协议版本；
##### 注意：
除了作为结尾的CRLF外，不允许出现单独的CR或LF字符

====================================================================

请求方法都为大写，解释如下：
	GET 请求获取Request-URL所标识的资源
	POST 在Request-URL所标识的资源后附加新的数据//post的意思是传递
	HEAD 请求获取由Request-URL所标识的资源的响应消息报头
	PUT 请求服务器存储一个资源，并用Request-URL作为其标识
	DELETE 请求服务器删除Request-URL所标识的资源
	TRACE 请求服务器回送收到的请求信息，主要用于测试或诊断//trace追踪、回溯
	CONNECT 保留将来使用
	OPTIONS 请求查询服务器的性能，或者查询与资源相关的选项和需求

====================================================================

在浏览器的地址栏中输入网址的方式访问网页时，浏览器采用GET方法向服务器获取资源，

例如:
	GET /form.html HTTP/1.1 (CRLF)	

POST方法要求被请求服务器接受附在请求后面的数据，常用于提交表单。

	POST /reg.jsp HTTP/ (CRLF)
	Accept:image/gif,image/x-xbit,... (CRLF)
	...
	HOST:www.guet.edu.cn (CRLF)
	Content-Length:22 (CRLF)
	Connection:Keep-Alive (CRLF)
	Cache-Control:no-cache (CRLF)
	(CRLF) //该CRLF表示消息报头已经结束，在此之前为消息报头
	user=jeffrey&pwd=1234 //此行以下为提交的数据
	……

HEAD方法与GET方法几乎是一样的，对于HEAD请求的回应部分来说，它的HTTP头部中包含的信息与通过GET请求所得到的信息是相同的。利用这个方法，不必传输整个资源内容，就可以得到Request-URI所标识的资源的信息。该方法常用于测试超链接的有效性，是否可以访问，以及最近是否更新。

====================================================================

HTTP响应消息格式

在接收和解释请求消息后，服务器返回一个HTTP响应消息。

HTTP响应也是由三个部分组成，分别是:**状态行、消息报头、响应正文**

状态行格式如下：

	HTTP-Version Status-Code Reason-Phrase CRLF
	HTTP-Version表示服务器HTTP协议的版本；
	Status-Code表示服务器发回的响应状态代码；
	Reason-Phrase表示状态代码的文本描述。

====================================================================

状态代码有三位数字组成，第一个数字定义了响应的类别，且有五种可能取值：

	1xx：指示信息--表示请求已接收，继续处理
	2xx：成功--表示请求已被成功接收、理解、接受
	3xx：重定向--要完成请求必须进行更进一步的操作
	4xx：客户端错误--请求有语法错误或请求无法实现
	5xx：服务器端错误--服务器未能实现合法的请求

====================================================================

常见状态代码、状态描述、说明：
	200 OK //客户端请求成功
	400 Bad Request //客户端请求有语法错误，不能被服务器所理解
	401 Unauthorized //请求未经授权，这个状态代码必须和WWW-Authenticate报头域一起使用
	403 Forbidden //服务器收到请求，但是拒绝提供服务
	404 Not Found //请求资源不存在，例如：输入了错误的URL
	500 Internal Server Error //服务器发生不可预期的错误
	503 Server Unavailable //服务器当前不能处理客户端的请求，一段时间后， //可能恢复正常
例如：
	HTTP/1.1 200 OK （CRLF）

响应正文就是服务器返回的资源的内容
