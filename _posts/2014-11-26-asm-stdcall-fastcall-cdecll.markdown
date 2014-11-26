---
layout: post
title: cdecll/stdcall/fastcall
categories:
- ASM
---

	int  __cdecl  add1(int a,int b)
	{
		return a+b;
	}
	/*
	00401030 >/> \55            PUSH EBP
	00401031  |.  8BEC          MOV EBP,ESP
	00401033  |.  83EC 40       SUB ESP,40
	00401036  |.  53            PUSH EBX
	00401037  |.  56            PUSH ESI
	00401038  |.  57            PUSH EDI
	00401039  |.  8D7D C0       LEA EDI,DWORD PTR SS:[EBP-40]
	0040103C  |.  B9 10000000   MOV ECX,10
	00401041  |.  B8 CCCCCCCC   MOV EAX,CCCCCCCC
	00401046  |.  F3:AB         REP STOS DWORD PTR ES:[EDI]
	00401048  |.  8B45 08       MOV EAX,DWORD PTR SS:[EBP+8]
	0040104B  |.  0345 0C       ADD EAX,DWORD PTR SS:[EBP+C]
	0040104E  |.  5F            POP EDI
	0040104F  |.  5E            POP ESI
	00401050  |.  5B            POP EBX
	00401051  |.  8BE5          MOV ESP,EBP
	00401053  |.  5D            POP EBP
	00401054  \.  C3            RETN								;区别
	*/
	
	int  __stdcall  add2(int a,int b)
	{
		return a+b;
	}
	
	/*
	00401060 >/> \55            PUSH EBP
	00401061  |.  8BEC          MOV EBP,ESP
	00401063  |.  83EC 40       SUB ESP,40
	00401066  |.  53            PUSH EBX
	00401067  |.  56            PUSH ESI
	00401068  |.  57            PUSH EDI
	00401069  |.  8D7D C0       LEA EDI,DWORD PTR SS:[EBP-40]
	0040106C  |.  B9 10000000   MOV ECX,10
	00401071  |.  B8 CCCCCCCC   MOV EAX,CCCCCCCC
	00401076  |.  F3:AB         REP STOS DWORD PTR ES:[EDI]
	00401078  |.  8B45 08       MOV EAX,DWORD PTR SS:[EBP+8]
	0040107B  |.  0345 0C       ADD EAX,DWORD PTR SS:[EBP+C]
	0040107E  |.  5F            POP EDI
	0040107F  |.  5E            POP ESI
	00401080  |.  5B            POP EBX
	00401081  |.  8BE5          MOV ESP,EBP
	00401083  |.  5D            POP EBP
	00401084  \.  C2 0800       RETN 8									;区别
	
	*/
	
	/*
		RETN的含义是
		pop eip
	
		RETN 8的含义是
		pop eip
		add esp, 8
	*/
	
	int __fastcall add3(int a, int b)
	{
		return a + b;
	}
	/*																;  call会执行push eip则esp-4
	00401090 >/> \55            PUSH EBP							;  esp-4
	00401091  |.  8BEC          MOV EBP,ESP							;  位置1
	00401093  |.  83EC 48       SUB ESP,48							;  虽然此处分配了48字节，但是在下面给还原了
	00401096  |.  53            PUSH EBX
	00401097  |.  56            PUSH ESI
	00401098  |.  57            PUSH EDI
	00401099  |.  51            PUSH ECX
	0040109A  |.  8D7D B8       LEA EDI,DWORD PTR SS:[EBP-48]
	0040109D  |.  B9 12000000   MOV ECX,12
	004010A2  |.  B8 CCCCCCCC   MOV EAX,CCCCCCCC
	004010A7  |.  F3:AB         REP STOS DWORD PTR ES:[EDI]
	004010A9  |.  59            POP ECX
	004010AA  |.  8955 F8       MOV DWORD PTR SS:[EBP-8],EDX
	004010AD  |.  894D FC       MOV DWORD PTR SS:[EBP-4],ECX
	004010B0  |.  8B45 FC       MOV EAX,DWORD PTR SS:[EBP-4]
	004010B3  |.  0345 F8       ADD EAX,DWORD PTR SS:[EBP-8]
	004010B6  |.  5F            POP EDI
	004010B7  |.  5E            POP ESI
	004010B8  |.  5B            POP EBX                                  
	004010B9  |.  8BE5          MOV ESP,EBP							;  此处还原ESP到了位置1
	004010BB  |.  5D            POP EBP								;  此处还原了EBP，pop执行esp+4
	004010BC  \.  C3            RETN								;  pop eip则esp+4,此时栈恢复了
	*/
	
	int __fastcall add4(int a, int b, int c, int d, int e)
	{
		return a + b + c + d + e;
	}
	/*
	0040D4D0 >/> \55            PUSH EBP
	0040D4D1  |.  8BEC          MOV EBP,ESP
	0040D4D3  |.  83EC 48       SUB ESP,48
	0040D4D6  |.  53            PUSH EBX
	0040D4D7  |.  56            PUSH ESI
	0040D4D8  |.  57            PUSH EDI
	0040D4D9  |.  51            PUSH ECX
	0040D4DA  |.  8D7D B8       LEA EDI,DWORD PTR SS:[EBP-48]
	0040D4DD  |.  B9 12000000   MOV ECX,12
	0040D4E2  |.  B8 CCCCCCCC   MOV EAX,CCCCCCCC
	0040D4E7  |.  F3:AB         REP STOS DWORD PTR ES:[EDI]
	0040D4E9  |.  59            POP ECX
	0040D4EA  |.  8955 F8       MOV DWORD PTR SS:[EBP-8],EDX
	0040D4ED  |.  894D FC       MOV DWORD PTR SS:[EBP-4],ECX
	0040D4F0  |.  8B45 FC       MOV EAX,DWORD PTR SS:[EBP-4]			;  ECX
	0040D4F3  |.  0345 F8       ADD EAX,DWORD PTR SS:[EBP-8]			;  EDX
	0040D4F6  |.  0345 08       ADD EAX,DWORD PTR SS:[EBP+8]			;  3
	0040D4F9  |.  0345 0C       ADD EAX,DWORD PTR SS:[EBP+C]			;  4
	0040D4FC  |.  0345 10       ADD EAX,DWORD PTR SS:[EBP+10]			;  5
	0040D4FF  |.  5F            POP EDI
	0040D500  |.  5E            POP ESI
	0040D501  |.  5B            POP EBX
	0040D502  |.  8BE5          MOV ESP,EBP
	0040D504  |.  5D            POP EBP
	0040D505  \.  C2 0C00       RETN 0C									; 使用了RETN 0C的方式恢复栈
	*/
	
	
	int main()
	{
		add1(1, 2);
	
		add2(3, 4);
	
		add3(1, 2);
		
		add4(1, 2, 3, 4, 5);
		return 0;
	}
	
	/*
	0040D4E8  |.  6A 02         PUSH 2
	0040D4EA  |.  6A 01         PUSH 1
	0040D4EC  |.  E8 143BFFFF   CALL cdecall.00401005					;  __cdecl add1
	0040D4F1  |.  83C4 08       ADD ESP,8								;  栈平衡，push两次，所以esp+8达到栈平衡
	0040D4F4  |.  6A 04         PUSH 4									;  使用栈来传递
	0040D4F6  |.  6A 03         PUSH 3
	0040D4F8  |.  E8 0D3BFFFF   CALL cdecall.0040100A					;  __stdcall add2， 没有栈平衡
	0040D4FD  |.  BA 02000000   MOV EDX,2								;  __fastcall直接使用寄存器来传递参数
	0040D502  |.  B9 01000000   MOV ECX,1								;  由于没有用到栈来传递参数，所以也就没有栈平衡
	0040D507  |.  E8 083BFFFF   CALL cdecall.00401014					;  __fastcall add3
	
	0040D54C  |.  6A 05         PUSH 5									;  超过2个参数的时候还是要使用栈的
	0040D54E  |.  6A 04         PUSH 4
	0040D550  |.  6A 03         PUSH 3
	0040D552  |.  BA 02000000   MOV EDX,2
	0040D557  |.  B9 01000000   MOV ECX,1
	0040D55C  |.  E8 B83AFFFF   CALL cdecall.00401019					; RETN 0C
	0040D561  |.  33C0          XOR EAX,EAX								;  没有add esp，那么一定是在函数内使用了retn num的形式来恢复栈平衡
	
	
	*/



__cdecll:VC中默认使用的是的方式

__stdcall: API函数约定

__fastcall:直接用寄存器传递参数，由于寄存器相对于栈(存储器)速度要快上许多，所以这类的调用约定叫fastcall
