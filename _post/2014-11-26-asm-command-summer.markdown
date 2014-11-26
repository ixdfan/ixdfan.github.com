---
layout: post
title: 汇编常用指令
categories:
- ASM
---

-------------------------------------------------------------------------------

#### mov与movsx、movzx的区别

	movsx 操作数A，操作数B
	movzx 操作数A，操作数B

##### 注意：
完成小存储单元向大存储单元的数据传送，例如

	movsz ebx, bx
	movzx ebx, ax
	movsx eax, bx

-------------------------------------------------------------------------------

movsx、movzx、mov的区别
- movsx、movzx操作数B所占空间必须小于操作数A，等于也是错误的
- mov指令时原值传送，而movsx与movzx有可能会改动

-------------------------------------------------------------------------------

movsx与movzx的区别
- movsx将操作数B的符号位扩展为操作数A中剩下的空间，如果符号位为1则全部填充为1，如果是0则和movzx相同作用
- movzx用0来填充操作数A余下的空间


-------------------------------------------------------------------------------

#### lea指令

	lea 操作数A，操作数B

将操作数B的有效地址传送到操作数A寄存器中,*操作数A必须是寄存器(32位上必须是32为寄存器)*


-------------------------------------------------------------------------------

#### 条件转移

	cmp 操作数A，操作数B
如同sub，但是不会改变操作数A，会影响标记寄存器

##### JE/JZ  相等转跳（ZF=1进行转跳）

	//如果eax和ebx相等则je转跳到addr
	cmp eax, ebx
	je addr
	//如果eax和ebx相等(zf标记为1)je转跳
	cmp eax, ebx
	jz addr


##### JNGE/JL 小于则转跳(SF=1进行跳转)

jnge 不大于等于(小于)跳转

jl   小于跳转

##### JLE/JNG 小于等于则转跳(SF=1或ZF=1或OF=1则进行跳转)


#### 无符号跳转

JA/JNBE 大于则跳转

JA与JG的区别
	
	#include <stdio.h>
	
	int main()
	{
		
		int a = 3;
		int b = 5;
		
		unsigned int a2 = a;
		unsigned int b2 = b;
		
		if (a <= b) {		//使用jg
			printf("条件不成立未跳转");
		}
		
		printf("条件成立跳转");
		
		printf("Next");
		
		if (a2 <= b2) {		//使用ja
			printf("条件不成立未跳转");
		}
		
		printf("条件成立跳转");
		return 0;
	}
		
	/*
	0040D738  |.  C745 FC 03000000    MOV DWORD PTR SS:[EBP-4],3				
	0040D73F  |.  C745 F8 05000000    MOV DWORD PTR SS:[EBP-8],5				
	0040D746  |.  8B45 FC             MOV EAX,DWORD PTR SS:[EBP-4]
	0040D749  |.  8945 F4             MOV DWORD PTR SS:[EBP-C],EAX
	0040D74C  |.  8B4D F8             MOV ECX,DWORD PTR SS:[EBP-8]
	0040D74F  |.  894D F0             MOV DWORD PTR SS:[EBP-10],ECX
	0040D752  |.  8B55 FC             MOV EDX,DWORD PTR SS:[EBP-4]
	0040D755  |.  3B55 F8             CMP EDX,DWORD PTR SS:[EBP-8]
	0040D758  |.  7F 0D               JG SHORT cmp.0040D767			
	0040D75A  |.  68 1C204200         PUSH OFFSET cmp.??_C@_03DNBD@end?$AA@    ; /format = "条件不成立未跳转"
	0040D75F  |.  E8 2C39FFFF         CALL cmp.printf                          ; \printf
	0040D764  |.  83C4 04             ADD ESP,4
	0040D767  |>  68 CC2F4200         PUSH OFFSET cmp.??_C@_0N@DIFL@?L?u?$LM?$>; /format = "条件成立跳转"
	0040D76C  |.  E8 1F39FFFF         CALL cmp.printf                          ; \printf
	0040D771  |.  83C4 04             ADD ESP,4
	0040D774  |.  68 BC2F4200         PUSH OFFSET cmp.??_C@_04CIMM@Next?$AA@   ; /format = "Next"
	0040D779  |.  E8 1239FFFF         CALL cmp.printf                          ; \printf
	0040D77E  |.  83C4 04             ADD ESP,4
	0040D781  |.  8B45 F4             MOV EAX,DWORD PTR SS:[EBP-C]
	0040D784  |.  3B45 F0             CMP EAX,DWORD PTR SS:[EBP-10]
	0040D787  |.  77 0D               JA SHORT cmp.0040D796						;此处使用的是JA
	0040D789  |.  68 1C204200         PUSH OFFSET cmp.??_C@_03DNBD@end?$AA@    ; /format = "条件不成立未跳转"
	0040D78E  |.  E8 FD38FFFF         CALL cmp.printf                          ; \printf
	0040D793  |.  83C4 04             ADD ESP,4
	0040D796  |>  68 CC2F4200         PUSH OFFSET cmp.??_C@_0N@DIFL@?L?u?$LM?$>; /format = "条件成立跳转"
	0040D79B  |.  E8 F038FFFF         CALL cmp.printf                          ; \printf
	*/



	#include <stdio.h>
		
	int main()
	{
		
		int a = 3;
		int b = -5;
		
		unsigned int a2 = a;
		unsigned int b2 = b;
		
		if (a <= b) {		//使用jg
			printf("条件不成立未跳转");
		}
		
		printf("条件成立跳转");
		
		printf("Next");
		
		if (a2 <= b2) {		//使用ja
			printf("条件不成立未跳转");
		}
		
		printf("条件成立跳转");
		return 0;
	}
	

	/*
	0040D738  |.  C745 FC 03000000    MOV DWORD PTR SS:[EBP-4],3
	0040D73F  |.  C745 F8 FBFFFFFF    MOV DWORD PTR SS:[EBP-8],-5
	0040D746  |.  8B45 FC             MOV EAX,DWORD PTR SS:[EBP-4]
	0040D749  |.  8945 F4             MOV DWORD PTR SS:[EBP-C],EAX
	0040D74C  |.  8B4D F8             MOV ECX,DWORD PTR SS:[EBP-8]
	0040D74F  |.  894D F0             MOV DWORD PTR SS:[EBP-10],ECX
	0040D752  |.  8B55 FC             MOV EDX,DWORD PTR SS:[EBP-4]
	0040D755  |.  3B55 F8             CMP EDX,DWORD PTR SS:[EBP-8]
	0040D758  |.  7F 0D               JG SHORT cmp.0040D767                    ;会转跳
	0040D75A  |.  68 1C204200         PUSH OFFSET cmp.??_C@_03DNBD@end?$AA@    ; /format = "条件不成立未跳转"
	0040D75F  |.  E8 2C39FFFF         CALL cmp.printf                          ; \printf
	0040D764  |.  83C4 04             ADD ESP,4
	0040D767  |>  68 CC2F4200         PUSH OFFSET cmp.??_C@_0N@DIFL@?L?u?$LM?$>; /format = "条件成立跳转"
	0040D76C  |.  E8 1F39FFFF         CALL cmp.printf                          ; \printf
	0040D771  |.  83C4 04             ADD ESP,4
	0040D774  |.  68 BC2F4200         PUSH OFFSET cmp.??_C@_04CIMM@Next?$AA@   ; /format = "Next"
	0040D779  |.  E8 1239FFFF         CALL cmp.printf                          ; \printf
	0040D77E  |.  83C4 04             ADD ESP,4
	0040D781  |.  8B45 F4             MOV EAX,DWORD PTR SS:[EBP-C]
	0040D784  |.  3B45 F0             CMP EAX,DWORD PTR SS:[EBP-10]
	0040D787  |.  77 0D               JA SHORT cmp.0040D796                    ;不会转跳,无符号-5是一个非常大的值，远远大于3de值
	0040D789  |.  68 1C204200         PUSH OFFSET cmp.??_C@_03DNBD@end?$AA@    ; /format = "条件不成立未跳转"
	0040D78E  |.  E8 FD38FFFF         CALL cmp.printf                          ; \printf
	0040D793  |.  83C4 04             ADD ESP,4
	0040D796  |>  68 CC2F4200         PUSH OFFSET cmp.??_C@_0N@DIFL@?L?u?$LM?$>; /format = "条件成立跳转"
	0040D79B  |.  E8 F038FFFF         CALL cmp.printf                          ; \printf
	*/

##### JNC没有进位时候跳转（CF=0跳转）

	JE/JZ	    ZF=1	
	JNE/JNZ	    ZF=0	
	有符号条件转移			
	JG/JNLE	    ZF=0&&SF=OF	
	JGE/JNL	    SF= OF	y
	JL/JNGE	    SF!=OF	
	JLE/JNG	    ZF=1 || SF!=OF	
	无符号条件转移			
	JA/JNBE	    CF=0 &&ZF=0	
	JNB/JAE/JNC	CF=0 	
	JB/JNAE/JC	CF=1 	
	JBE/JNA	    CF=1 or ZF=1	



##### SETE/SETZ

	SETZ AL

SETE的作用是将标记寄存器中ZF的值保存

	SETE 8位寄存器
	SETE AL; 将ZF中的数值保存到AL中
	SET BYTE PTR DS:[EBX]

	SETE EAX ;错误，后面只能接8位寄存器

SETE主要用于取反

	XOR EAX, EAX
	CMP DWORD PTR SS:[EBP-4], 0    ;CMP之后ZF中保存了[EBP-4]
	SETE AL

这样EAX中就保存了取反后的数字

SETE与SETZ是等价的

SETNE/SETNZ与SETE/SETZ是相反的,将ZF标志位取反后保存

#####注意:
NOT是按位取反是~，SETE的取反是!a(结果是0或是1)

##### SETG/SETL(大于小于运算)

	SETG AL(只能是8位寄存器)

如果ZF==0&&SF==0&&OF==0(小于时候可能会产生溢出)，则AL=1
	
	int a = 5;
	int c = a > 1;//此时便会有SETG产生
	int d = a < 1;

	SETL AL(只能是8位寄存器)

SF==1 或者 OF==1 时 cl=1;

##### SETGE/SETLE


-------------------------------------------------------------------------------

#### 字符串相关指令

##### REPNE/REPNZ
ECX!=0 and ZF==0则循环执行

REPNE/REPNZ后面一般跟SCASB/SCASW/SCASD/CMPS/CMPD/CMPW指令

#####REPE/REPZ
ECX!=0 and ZF==1则循环执行


#####CLD/STD
	CLD:将DF置0
	STD:将DF置1

##### LOOP/LOOPD
当ECX不为0的时候就转跳

##### STOSB(AL)/STOSW(AX)/STOSD(EAX)
串填充指令

	REP STOSW DWORD PTR ES:[EDI]

REP只有当ECX为0的时候才执行下一条语句

	STOSW DWORD PTR ES:[EDI]

将[EDI]位置赋值为EAX中的值，并且EDI=EDI+4,可以用来清空数组

##### LODSB/LODSW/LODSD
作用相当于

	MOV AL, BYTE PTR [ESI]; esi=esi+sizeof(byte)
                                                                                                                                                                                                                          
