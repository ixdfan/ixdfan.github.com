---
layout: post
title: gcc常用命令
categories:
- TOOL
tags:
- gcc
---

1.gcc -E source_file.c

-E，只执行到预编译。直接输出预编译结果。

2.gcc -S source_file.c

-S，只执行到源代码到汇编代码的转换，输出汇编代码。

3.gcc -c source_file.c

-c，只执行到编译，输出目标文件。

4.gcc (-E/S/c/) source_file.c -o output_filename

-o, 指定输出文件名，可以配合以上三种标签使用。

-o 参数可以被省略。这种情况下编译器将使用以下默认名称输出：

-E：预编译结果将被输出到标准输出端口（通常是显示器）

-S：生成名为source_file.s的汇编代码

-c：生成名为source_file.o的目标文件。

无标签情况：生成名为a.out的可执行文件。

5.gcc -g source_file.c

-g，生成供调试用的可执行文件，可以在gdb中运行。由于文件中包含了调试信息因此运行效率很低，且文件也大不少。

这里可以用strip命令重新将文件中debug信息删除。这是会发现生成的文件甚至比正常编译的输出更小了，这是因为strip把原先正常编译中的一些额外信息（如函数名之类）也删除了。用法为 strip a.out

6.gcc -s source_file.c

-s, 直接生成与运用strip同样效果的可执行文件（删除了所有符号信息）。

7.gcc -O source_file.c

-O（大写的字母O），编译器对代码进行自动优化编译，输出效率更高的可执行文件。

-O 后面还可以跟上数字指定优化级别，如：

gcc -O2 source_file.c

数字越大，越加优化。但是通常情况下，自动的东西都不是太聪明，太大的优化级别可能会使生成的文件产生一系列的bug。一般可选择2；3会有一定风险。

8.gcc -Wall source_file.c

-W，在编译中开启一些额外的警告（warning）信息。-Wall，将所有的警告信息全开。

-w,关闭全部警告

9. gcc source_file.c -L/path/to/lib -lxxx -I/path/to/include

-l, 指定所使用到的函数库，本例中链接器会尝试链接名为libxxx.a的函数库。

-L，指定函数库所在的文件夹，本例中链接器会尝试搜索/path/to/lib文件夹。

-I, 指定头文件所在的文件夹，本例中预编译器会尝试搜索/path/to/include文件夹。


linux中

gcc是个编译器

ld才是连接器

windows中为CEL与LINK
