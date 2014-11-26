---
layout: post
title: wc命令
categories:
- TOOL
---

wc的使用

wc命令提供了文本行数、单词数、字符数的统计
	-c	显示字符数
	-l	显示行数
	-w	显示单词数

wc的高级使用

	[root@localhost 02]# find /etc -iname "*.conf" | wc -l
	410
	[root@localhost 02]# grep bash /etc/passwd | wc -l
	3

	find /etc -iname "*.conf" | wc -l

统计显示 /etc/文件下的所有.conf文件的数量

	grep bash /etc/passwd | wc -l
找出/etc/passwd文件中包含字符串bash的行的个数

##### 注意：
grep string | wc -l在grep中已经集成了，通过参数-c来实现
	grep -c来统计输出的行数

	[root@localhost 02]# grep -c bash /etc/passwd
	3

wc来统计多个文件
    
    
    [root@localhost 02]# wc /etc/*rc
       87   355  2682 /etc/bashrc
       72   204  1602 /etc/csh.cshrc
       26    80  1323 /etc/drirc
       42   114   942 /etc/inputrc
        8    16   271 /etc/kde4rc
        7     6   204 /etc/kderc
       22   120  1127 /etc/ksysguarddrc
       67   317  1909 /etc/mail.rc
      266  1294  7846 /etc/nanorc
      104   261  2872 /etc/pinforc
      104   402  2617 /etc/rc
       64   282  1962 /etc/vimrc
       64   282  1962 /etc/virc
      125   794  4479 /etc/wgetrc
     1058  4527 31798 total
    
