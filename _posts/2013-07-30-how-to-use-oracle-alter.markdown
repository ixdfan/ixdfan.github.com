---
author: UCSHELL
comments: true
date: 2013-07-30 08:54:00+00:00
layout: post
slug: oracle%e4%b8%adalter%e7%9a%84%e7%94%a8%e6%b3%95%e8%af%a6%e8%a7%a3
title: ORACLE中ALTER的用法详解
wordpress_id: 249
categories:
- THE DATEBASE
tags:
- alter
- oracle
- proc
---

今天在看书的时候对照着书上的ALTER语句执行但就是错误,搞了半天才知道原来是书上的代码错了, DROP时候少了一个COLUMN,所以执行错误。趁机对ALTER进行一下总结。   

ALTER TABLE语句用于修改已经存在的表的设计。   
\>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>   
语法：   

    ALTER TABLE table ADD COLUMN field type[(size)] [NOT NULL] [CONSTRAINT index]
    
    ALTER TABLE table ADD CONSTRAINT multifieldindex
    
    ALTER TABLE table DROP COLUMN field
    
    ALTER TABLE table DROP CONSTRAINT indexname

\>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>   

说明：   
* table参数用于指定要修改的表的名称。

* DD COLUMN为SQL的保留字，使用它将向表中添加字段。

* ADD CONSTRAINT为SQL的保留字，使用它将向表中添加索引。

* DROP COLUMN 为SQL的保留字，使用它将向表中删除字段。(我就是这里出错,书上的代码没加COLUMN )

* DROP CONSTRAINT为SQL的保留字，使用它将向表中删除索引。

* field指定要添加或删除的字段的名称。

* type参数指定新建字段的数据类型。

* size参数用于指定文本或二进制字段的长度。

* indexname参数指定要删除的多重字段索引的名称。   

\>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>   

用sql*plus或第三方可以运行sql语句的程序登录数据库：   

\>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>   

    ALTER TABLE (表名) ADD (列名 数据类型);
    
    ALTER TABLE (表名) MODIFY (列名 数据类型);
    
    ALTER TABLE (表名) RENAME COLUMN (当前列名) TO (新列名); /////不需要括号
    
    ALTER TABLE (表名) DROP COLUMN (列名);
    
    ALTER TABLE (当前表名) RENAME TO (新表名);   
\>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>   
如：   

    Alter Table Employ Add (weight Number(38,0)) ;
    
    Alter Table Employ Modify (weight Number(13,2)) ;
    
    Alter Table Emp Rename Cloumn weight To weight_new ;
    
    ALTER TABLE emp DROP COLUMN weight_new ;
    
    ALTER TABLE bouns RENAME TO bonus_new;   
\>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>   
增加一个列：   

	ALTER TABLE 表名 ADD(列名 数据类型);   
如：   

	ALTER TABLE emp ADD(weight NUMBER(38,0));   
\>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>   
修改一个列的数据类型(一般限于修改长度，修改为一个不同类型时有诸多限制): 

	ALTER TABLE 表名 MODIFY(列名 数据类型);   
如：   
	
    ALTER TABLE emp MODIFY(weight NUMBER(3,0) NOT NULL);   
\>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>   
给列改名：   

	ALTER TABLE 表名 RENAME COLUMN 当前列名 TO 新列名;   
如：   

	ALTER TABLE emp RENAME COLUMN weight TO weight_new;   
\>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>   
删除一个列：   
	
    ALTER TABLE 表名 DROP COLUMN 列名;   
如：   

	ALTER TABLE emp DROP COLUMN weight_new;   
\>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>   
将一个表改名：   
	
    ALTER TABLE OLDNAME RENAME TO NEWNAME;
	或者
    RENAME OLDNAME TO NEWNAME;   
如：   

	ALTER TABLE bouns RENAME TO bonus_new   
\>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
