---
layout: post
title: sed批量修改文件中的名字
categories: 
- sed
tags:
- 
---

比如我们想批量将文件中的某个单词例如shell替换成my_shell,此时可以使用sed

	sed -i "s/shell/my_shell/g" `grep -l "\<shell\>" *`

grep  -l表示找到含有shell的文件后仅仅显示文件名

sed -i 表示直接将指令插入到符合的行后
