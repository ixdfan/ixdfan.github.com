---
layout: post
title: nginx开启目录显示
description: 
modified: 
categories: 
- Nginx 
tags:
- 
---

主要是三个选项

	autoindex on;					#开启nginx目录浏览功能
	autoindex_exact_size off;		#文件大小从KB显示
									#默认为on，显示文件确切大小，单位是bytes
									#off，显示文件大概大小，单位是最方便读的
	autoindex_localtime on;			#显示文件修改时间为服务器本地时间

具体在配置文件中的使用如下:

	worker_processes  2;  
	error_log  logs/error.log debug;    
	
	
	events {
		worker_connections  1024;   
	}   
	
	
	http {
		include       mime.types;      
		default_type  application/octet-stream;
	
		server {
			listen       80;
			listen 		127.0.0.1:8080;
			server_name  localhost;
	
				location / { 
					root   html;
					index  index.html index.htm;
	
					autoindex on;					#开启nginx目录浏览功能
					autoindex_exact_size off;		#文件大小从KB显示
													#默认为on，显示文件确切大小，单位是bytes
													#off，显示文件大概大小，单位是最方便读的

					autoindex_localtime on;			#显示文件修改时间为服务器本地时间
				}
			
			error_page 404 /404.html;
			error_page 500 502 503 504 /50x.html;
	
			location = /50x.html {
				root html;
			}
		}
	}   
	
