---
layout: post
title:  diff与patch的使用
description: 
modified: 
categories: 
- shell
tags:
- 
---

	-a 将所有文件都看成文本形式，并对他逐行比较
	-b 忽略空格
	-B 忽略空白行
	-i 忽略大小写
	-r 比较目录时，递归比较子目录
	-N 比较目录时，如果一个文件只出现在第一个目录中，那么认为他在另外一个目录中也出现，并且为空。
	-u 输出统一文件的行数


	diff -aruN 旧的文件/目录 新的文件/目录 > patch文件


输出结果形式:

	n1 a n2:

表示第一个文件的n1行添加了....成为第二个文件的n2行

	n1,n2 c n3,n4:

表示将第一个文件的n1行到n2行(在'<'之后的内容)改变成第二个文件的n3到n4行(在'>'之后的内容)

	n1,n2 d n3:

表示第一个文件中n1到n2行删除成为文件2中的n3行

	[root@ Note]# diff student1 student2
	1,2c1,2
	< Bill is a tall man
	< Mike is Tom's brother
	---
	> Bill is Mary's brother
	> Mike is Bill's brother
	4c4
	< Jean is Mary's sister
	---
	> Jean is Bill's sister
	
	

	#对目录进行比较，只有.diff.swp和head是在note_2中没有的
	[root@ Note]# diff note_1 note_2
	Only in note_1: .diff.swp
	Only in note_1: head


通过比较文件形成差异文件，差异文件可以作为将来的补丁


	[root@ Note]# diff -ruN student1 student2 > file.diff
	[root@ Note]# cat file.diff 
	--- student1	2014-05-03 22:09:45.084310113 +0800
	+++ student2	2014-05-03 22:27:15.556463879 +0800
	@@ -1,4 +1,4 @@
	-Bill is a tall man
	-Mike is Tom's brother
	+Bill is Mary's brother
	+Mike is Bill's brother
	 Mary is a beautiful girl
	-Jean is Mary's sister
	+Jean is Bill's sister


	
patch:文件打补丁
patch命令来为文件打补丁，可以一次打多个补丁，通常用来为系统升级
首先通过命令diff，比较file1与file2的不同，并生成差异文件file.diff


patch命令里面的层数

参数-p来指定从第几层开始比较，比如有一个patch文件的补丁是这样的:

	[root@ Note]# cat test.patch 
	diff -aruN note_1/About_echo note_2/About_echo
	--- note_1/test/About_echo	2014-05-03 22:56:41.414170471 +0800
	+++ note_2/test/About_echo	2014-05-03 22:56:21.910019079 +0800

如果使用参数-p0,就表示从当前目录，找一个叫note_2的目录，再在在它下面找test目录在test目录下找一个叫做About_echo的文件

如果使用参数-p1,就表示忽略第一层，直接从当前目录找test目录，在其下面找一个叫做About_echo的文件这样就忽略了note_2的目录
