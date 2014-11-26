---
layout: post
title: 浮点数指令
categires:
- ASM
---

FLD相当于PUSH指令，只不过PUSH是压入到堆栈中，而FLD是压入到ST0-ST7这8个80位的浮点寄存器中

FILD整数入栈指令
	
	#include <stdio.h>
	
	int main()
	{
		
		double f1 = 666.886;
		int i = 2;
	
		f1 = f1 + i;//如果后面的是一个常量，那么编译时候可能会将常量当做浮点数来编译，所以后面使用int变量
	
	
		
		return 0;
	}
	/*
	00410668  |.  C745 F8 0C022>MOV DWORD PTR SS:[EBP-8],872B020C
	0041066F  |.  C745 FC 16D78>MOV DWORD PTR SS:[EBP-4],4084D716
	00410676  |.  C745 F4 02000>MOV DWORD PTR SS:[EBP-C],2
	;如果将这条指令手动改为FLD DWORD PTR SS:[EBP-C]，那么我们可以看到在ST0寄存器中存放的不是2 而是2.8025969286496337920E-45，这就是FILD的用处
	0041067D  |.  DB45 F4       FILD DWORD PTR SS:[EBP-C]
	00410680  |.  DC45 F8       FADD QWORD PTR SS:[EBP-8]
	00410683  |.  DD5D F8       FSTP QWORD PTR SS:[EBP-8]
	*/
	
FSTP相当于POP指令，不过POP是从堆栈中弹出，而FSTP是从ST0-ST7中弹出

FADD相当于ADD指令，不过他是累加到ST0寄存器中

FADD DWORD PTR SS:[EBP-4]

这条语句的含义是将[EBP-4]处的值与ST0寄存器中的值相加，结果放到ST0寄存器中

	ST0=ST0+[EBP-4]

FSUB相当于SUB指令

	FSUB 操作数；ST0=ST0-操作数

FMUL相当于MUL

	FMUL 操作数；ST0=ST0*操作数

FDIV不说了，一样的

	FDIV 操作数；ST0=ST0/操作数

CVTTPS2PI指令

	CVTTPS2PI MM0,DQWORD PTR SS:[ebp]  ;必须要有[], []中可以使任意寄存器[eax]
