---
layout: post
title: 使用c连接到mysql数据库
description: 
modified: 
categories: 
- Mysql
tags:
- 
---

#### mysql_init():准备连接

	MYSQL*	mysql_init(MYSQL* mysql)

实例:
	
	/*	test.c	*/
	#include <stdio.h>
	#include <mysql.h>	/*	头文件不一定是这个	*/

	int main() 
	{
		MYSQL conn;

		if (mysql_init(&conn) == NULL) {
			printf("mysql_init error\n");
			exit(-1);
		}
		mysql_close(&conn);

		return 0;
	}

使用gcc编译的时候，必须指定mysql.h所在的路径，并加入mysqlclient库
	
	cc test.c -omain -I/usr/include/mysql -L/usr/lib/mysql -lmysqlclient 

-I致命mysql.h所在的路径;

—L指定库文件的路径

-l使用库


#### mysql_real_connect()

	MYSQL* mysql_real_connect(MYSQL* mysql, const char* host, const char* user, 
							  const char* passwd, const char* db, unsigned int port, 
							  const char* unix_socket, unsigned long client_flag)

第一个参数是handle，就是mysql_init返回的handle;

第五个参数是db_name，也可以将其设为NULL，然后使用mysql_select_db()来选择数据库;

第六个参数是MYSQL Server的连接池，一般设置为MYSQl_PORT;

第六个参数一般设置为NULL;

第七个参数包含压缩协议，查询协议，加密协议等，一般设置为0;

实例:

	/*	test.c	*/
	#include <stdio.h>
	#include <mysql.h>	

	int main() 
	{
		MYSQL 		conn;

		if (mysql_init(&conn) == NULL) {
			printf("mysql_init error\n");
			exit(-1);
		}


		if (NULL == mysql_real_connect(&conn, "localhost", "user", "123456", 
										"company", MYSQL_PORT, NULL, 0)) 
		{
			printf("connection error\n");
			exit(-1);
		
		}
		printf("Connection ok\n");
		mysql_close(&conn);
		return 0;
	}

#### 查询数据库

当成功连接mysql之后，可以使用mysql_query或是mysql_real_query来查询数据库，但是mysql_query不能处理binary data(例如图片),如果包含binary data，则必须使用mysql_real_query，这个函数需要提供程序字串的长度


	int mysql_query(MYSQL *mysql, const char *query)
	int mysql_real_query(MYSQL *mysql, const char *query, unsigned long length) 

查询成功则返回0,否则返回非0;

如果查询语句并没有结果返回，例如delete/update/insert等，mysql_query被执行后便完成了整个操作;

如果要执行insert/show/describe等，在存取结果前，必须使用mysql_store_result建立result handle;

	MYSQL_RES* mysql_store_result(MYSQL* mysql)

实例:
	/*	test.c	*/
	#include <stdio.h>
	#include <mysql.h>	

	int main() 
	{
		MYSQL 		conn;
		MYSQl_RES*	result;

		if (mysql_init(&conn) == NULL) {
			printf("mysql_init error\n");
			exit(-1);
		}


		if (NULL == mysql_real_connect(&conn, "localhost", "user", "123456", 
										"company", MYSQL_PORT, NULL, 0)) 
		{
			printf("connection error\n");
			exit(-1);
		
		}
		printf("Connection ok\n");

		mysql_query(&conn, "select * from worker");
		result = mysql_store_result(&conn)

		mysql_free_result(result);
		mysql_close(&conn);

		return 0;
	}


#####注意:
mysql_result是一个指针，因为mysql_store_result会自动分配内存存储查询结果，所以在后面要执行mysql_free_result(MYSQL_RES*)来释放内存


#### 提取查询结果:

提前接过钱必须使用mysql_store_result分配内存给查询结果，然后利用mysql_fetch_row逐行提取数据。
结果的行数和列数可以使用mysql_num_rows和mysql_num_fields来获取;

	MYSQL_ROW mysql_fetch_row(MYSQL_RES* result)

MYSQL_RES是一个数组结构，数组中每一个元素依次为该行的字段value;


实例:

	
	#include <stdio.h>
	#include <stdlib.h>
	#include <mysql.h>	
	
	int main() 
	{
		MYSQL 		conn;
		MYSQL_RES*	result;
		MYSQL_ROW 	row;
		int 		num_row,
					num_col,
					i,
					j;
	
		if (mysql_init(&conn) == NULL) {
			printf("mysql_init error\n");
			exit(-1);
		}
	
	
		if (NULL == mysql_real_connect(&conn, "localhost", "root", "ucshell", 
										"company", MYSQL_PORT, NULL, 0)) 
		{
			printf("connection error\n");
			exit(-1);
		
		}
		printf("Connection ok\n");
	
		if (0 != mysql_query(&conn, "select * from worker") ) {
			printf("query error\n");
			exit(-1);
		}
	
	
		result = mysql_store_result(&conn);
	
		/*	这个函数容易忘记结尾的s，只要记住行有很多行，就是复数(非单数)的意思，就不会忘记最后的s了	*/
		num_row = mysql_num_rows(result);		/*	获取行数	*/
		num_col = mysql_num_fields(result);		/*	获取列数	*/
	
		for (i = 0; i < num_row; i++) {
			row = mysql_fetch_row(result);		/*	row是一个数组，每一个元素就是对应的字段的值	*/
	
			for (j = 0; j < num_col; j++) {
				printf("%-20s	", row[j]);
			}
			printf("\n");
		}
	
	
	
		mysql_free_result(result);
		mysql_close(&conn);
	
		return 0;
	}
	
	
####注意:
如果数据库很大，而又没有使用mysql_free_result释放内存的话，则很容易发送内存泄漏
