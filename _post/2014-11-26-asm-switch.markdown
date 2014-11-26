---
layout: post
title: switch的逆向
categories:
- ASM
---

一般的switch的汇编框架
	
	int main()
	{
		int a = 3;
		switch (a) {
		case 1:
			printf("11");
			break;	//jmp end
		case 2:
			printf("11");
			break;	//jmp end
		case 3:
			printf("11");
			break;	//jmp end
		default:
			printf("default");
			break;	//jmp end
		}
	
		printf("End");
		return 0;
	}
	
	/*
	00401028  |.  C745 FC 03000>MOV DWORD PTR SS:[EBP-4],3               ;  int a = 3
	0040102F  |.  8B45 FC       MOV EAX,DWORD PTR SS:[EBP-4]
	00401032  |.  8945 F8       MOV DWORD PTR SS:[EBP-8],EAX             ;  int b = eax = a = 3
	00401035  |.  837D F8 01    CMP DWORD PTR SS:[EBP-8],1               ;  b == 1
	00401039  |.  74 0E         JE SHORT switch.00401049
	0040103B  |.  837D F8 02    CMP DWORD PTR SS:[EBP-8],2               ;  b == 2
	0040103F  |.  74 17         JE SHORT switch.00401058
	00401041  |.  837D F8 03    CMP DWORD PTR SS:[EBP-8],3               ;  b == 3
	00401045  |.  74 20         JE SHORT switch.00401067
	00401047  |.  EB 2D         JMP SHORT switch.00401076                ;  default
	00401049  |>  68 2C204200   PUSH OFFSET switch.??_C@_02PIFG@11?$AA@  ; /format = "11"
	0040104E  |.  E8 7D000000   CALL switch.printf                       ; \printf
	00401053  |.  83C4 04       ADD ESP,4
	00401056  |.  EB 2B         JMP SHORT switch.00401083                ;  break
	00401058  |>  68 2C204200   PUSH OFFSET switch.??_C@_02PIFG@11?$AA@  ; /format = "11"
	0040105D  |.  E8 6E000000   CALL switch.printf                       ; \printf
	00401062  |.  83C4 04       ADD ESP,4
	00401065  |.  EB 1C         JMP SHORT switch.00401083                ;  break
	00401067  |>  68 2C204200   PUSH OFFSET switch.??_C@_02PIFG@11?$AA@  ; /format = "11"
	0040106C  |.  E8 5F000000   CALL switch.printf                       ; \printf
	00401071  |.  83C4 04       ADD ESP,4
	00401074  |.  EB 0D         JMP SHORT switch.00401083                ;  break
	00401076  |>  68 20204200   PUSH OFFSET switch.??_C@_07FMEP@default?>; /format = "default"
	0040107B  |.  E8 50000000   CALL switch.printf                       ; \printf
	00401080  |.  83C4 04       ADD ESP,4
	00401083  |>  68 1C204200   PUSH OFFSET switch.??_C@_03HPMG@End?$AA@ ; /format = "End"
	00401088  |.  E8 43000000   CALL switch.printf                       ; \printf
	*/

-------------------------------------------------------------------------------

带有跳转表的switch

	int main()
	{
		int a = 3;
		switch (a) {
		
		case 1:
			printf("11");
			break;
		case 3:
			printf("11");
			break;	
		case 0x10:	
			printf("11");
			break;	
		case 0x20:
			printf("11");
			break;	
		case 0x22:
			printf("11");
			break;	
		default:
			printf("default");
			break;	
		}
	
		printf("End");
		return 0;
	}

	/*
	跳转表中写好了0x1,0x2,0x3....0x22之间所有数值要跳转的下标
	
	如果差值为0，则跳到跳转表中的下标0，差为2，则跳到跳转表中下标5，以此类推
	0040D836  00 05 01 05 05 05 05 05 05 05 05 05 05 05 05 02  
	0040D846  05 05 05 05 05 05 05 05 05 05 05 05 05 05 05 03  
	0040D856  05 04

    跳转表如下
	addr	  value     comment
	0040D81E  0040D7A6  switch.0040D7A6
	0040D822  0040D7B5  switch.0040D7B5
	0040D826  0040D7C4  switch.0040D7C4
	0040D82A  0040D7D3  switch.0040D7D3
	0040D82E  0040D7E2  switch.0040D7E2
	0040D832  0040D7F1  switch.0040D7F1
	
	*/
	
	/*
	0040D778  |.  C745 FC 03000>MOV DWORD PTR SS:[EBP-4],3               ;  a=3
	0040D77F  |.  8B45 FC       MOV EAX,DWORD PTR SS:[EBP-4]             ;  eax=a=3
	0040D782  |.  8945 F8       MOV DWORD PTR SS:[EBP-8],EAX             ;  b=3
	0040D785  |.  8B4D F8       MOV ECX,DWORD PTR SS:[EBP-8]             ;  ecx=b=3
	0040D788  |.  83E9 01       SUB ECX,1                                ;  获取该值在跳转表中的下标
	0040D78B  |.  894D F8       MOV DWORD PTR SS:[EBP-8],ECX             ;  b=a-1=2
	0040D78E  |.  837D F8 21    CMP DWORD PTR SS:[EBP-8],21              ;  判断该值得下标是否在下标表中
	0040D792  |.  77 5D         JA SHORT switch.0040D7F1                 ;  如果不在则直接跳到default中
	0040D794  |.  8B45 F8       MOV EAX,DWORD PTR SS:[EBP-8]             ;  eax=b=2;将该值在跳转表中的下标放到eax中
	0040D797  |.  33D2          XOR EDX,EDX                              ;  edx清空
	0040D799  |.  8A90 36D84000 MOV DL,BYTE PTR DS:[EAX+40D836]          ;  跳转表数组起始位置位于40D836，dl存放该值下标的位置
	0040D79F  |.  FF2495 1ED840>JMP DWORD PTR DS:[EDX*4+40D81E]          ;  跳转表起始位置位于40D81E处，edx是该值在转跳表中的下标，4*edx是该下标起始地址
	0040D7A6  |>  68 2C204200   PUSH OFFSET switch.??_C@_02PIFG@11?$AA@  ; /format = "11"
	0040D7AB  |.  E8 2039FFFF   CALL switch.printf                       ; \printf
	0040D7B0  |.  83C4 04       ADD ESP,4
	0040D7B3  |.  EB 49         JMP SHORT switch.0040D7FE
	0040D7B5  |>  68 2C204200   PUSH OFFSET switch.??_C@_02PIFG@11?$AA@  ; /format = "11"
	0040D7BA  |.  E8 1139FFFF   CALL switch.printf                       ; \printf
	0040D7BF  |.  83C4 04       ADD ESP,4
	0040D7C2  |.  EB 3A         JMP SHORT switch.0040D7FE
	0040D7C4  |>  68 2C204200   PUSH OFFSET switch.??_C@_02PIFG@11?$AA@  ; /format = "11"
	0040D7C9  |.  E8 0239FFFF   CALL switch.printf                       ; \printf
	0040D7CE  |.  83C4 04       ADD ESP,4
	0040D7D1  |.  EB 2B         JMP SHORT switch.0040D7FE
	0040D7D3  |>  68 2C204200   PUSH OFFSET switch.??_C@_02PIFG@11?$AA@  ; /format = "11"
	0040D7D8  |.  E8 F338FFFF   CALL switch.printf                       ; \printf
	0040D7DD  |.  83C4 04       ADD ESP,4
	0040D7E0  |.  EB 1C         JMP SHORT switch.0040D7FE
	0040D7E2  |>  68 2C204200   PUSH OFFSET switch.??_C@_02PIFG@11?$AA@  ; /format = "11"
	0040D7E7  |.  E8 E438FFFF   CALL switch.printf                       ; \printf
	0040D7EC  |.  83C4 04       ADD ESP,4
	0040D7EF  |.  EB 0D         JMP SHORT switch.0040D7FE
	0040D7F1  |>  68 20204200   PUSH OFFSET switch.??_C@_07FMEP@default?>; /format = "default"
	0040D7F6  |.  E8 D538FFFF   CALL switch.printf                       ; \printf
	0040D7FB  |.  83C4 04       ADD ESP,4
	0040D7FE  |>  68 1C204200   PUSH OFFSET switch.??_C@_03HPMG@End?$AA@ ; /format = "End"
	0040D803  |.  E8 C838FFFF   CALL switch.printf                       ; \printf
	*/

跳转表的计算方式:

跳转表下表表中元素个数为case中最大值-最小值的个数，首先将传入的值与case中最小的值相减，然后将其与跳转表中元素个数相比较(JA比较，所以没有负数之分)，如果大于元素个数，则直接跳到default，否则去跳转表下标表中获取该值对应跳转表中的下标，然后跳到跳转表中对应的位置上即可


##### 注意:

跳转表一般是在最小值与最大值相差不多的时候才会产生，相差的比较大的情况下一般是不会使用跳转表的


-------------------------------------------------------------------------------

#### switch的逆向
	
	00AC1014  |.  C745 FC 20000>MOV DWORD PTR SS:[EBP-4],20              ;  int a = 0x20 = 32
	00AC101B  |.  8B45 FC       MOV EAX,DWORD PTR SS:[EBP-4]             ;  eax = a
	00AC101E  |.  8945 F8       MOV DWORD PTR SS:[EBP-8],EAX             ;  int b = a = 0x20 = 32
	00AC1021  |.  8B4D F8       MOV ECX,DWORD PTR SS:[EBP-8]
	00AC1024  |.  83E9 09       SUB ECX,9                                ;  case中最小值为9
	00AC1027  |.  894D F8       MOV DWORD PTR SS:[EBP-8],ECX             ;  b=b-9=32-9=23=0x17
	00AC102A  |.  837D F8 08    CMP DWORD PTR SS:[EBP-8],8               ;  最大值-9=8，最大值为0x11
	00AC102E  |.  77 4A         JA SHORT switchCa.00AC107A               ;  default
	00AC1030  |.  8B55 F8       MOV EDX,DWORD PTR SS:[EBP-8]
	00AC1033  |.  FF2495 9C10AC>JMP DWORD PTR DS:[EDX*4+AC109C]          ;  跳转表共有9项，分别是9、10、11、12、13、14、15、16、17
	
	;case 11
	00AC103A  |>  68 FC20AC00   PUSH switchCa.00AC20FC                   ; /format = "aaa"
	00AC103F  |.  FF15 A420AC00 CALL DWORD PTR DS:[<&MSVCR90.printf>]    ; \printf
	00AC1045  |.  83C4 04       ADD ESP,4
	00AC1048  |.  EB 3E         JMP SHORT switchCa.00AC1088
	
	;case 15
	00AC104A  |>  68 0021AC00   PUSH switchCa.00AC2100                   ; /format = "aaaa"
	00AC104F  |.  FF15 A420AC00 CALL DWORD PTR DS:[<&MSVCR90.printf>]    ; \printf
	00AC1055  |.  83C4 04       ADD ESP,4
	00AC1058  |.  EB 2E         JMP SHORT switchCa.00AC1088
	
	;case 17
	00AC105A  |>  68 0821AC00   PUSH switchCa.00AC2108                   ; /format = "bbbb"
	00AC105F  |.  FF15 A420AC00 CALL DWORD PTR DS:[<&MSVCR90.printf>]    ; \printf
	00AC1065  |.  83C4 04       ADD ESP,4
	00AC1068  |.  EB 1E         JMP SHORT switchCa.00AC1088
	
	;case 9
	00AC106A  |>  68 1021AC00   PUSH switchCa.00AC2110                   ; /format = "xxxx"
	00AC106F  |.  FF15 A420AC00 CALL DWORD PTR DS:[<&MSVCR90.printf>]    ; \printf
	00AC1075  |.  83C4 04       ADD ESP,4
	00AC1078  |.  EB 0E         JMP SHORT switchCa.00AC1088
	
	;default
	00AC107A  |>  68 1821AC00   PUSH switchCa.00AC2118                   ; /format = "3333"
	00AC107F  |.  FF15 A420AC00 CALL DWORD PTR DS:[<&MSVCR90.printf>]    ; \printf
	00AC1085  |.  83C4 04       ADD ESP,4
	
	; switch之外的语句
	00AC1088  |>  68 2021AC00   PUSH switchCa.00AC2120                   ; /command = "pause"
	00AC108D  |.  FF15 9C20AC00 CALL DWORD PTR DS:[<&MSVCR90.system>]    ; \system
	
	; 转跳表如下
	00AC109C  00AC106A  switchCa.00AC106A		;9
	00AC10A0  00AC107A  switchCa.00AC107A		;10
	00AC10A4  00AC103A  switchCa.00AC103A		;11
	00AC10A8  00AC107A  switchCa.00AC107A		;12
	00AC10AC  00AC107A  switchCa.00AC107A		;13
	00AC10B0  00AC107A  switchCa.00AC107A		;14
	00AC10B4  00AC104A  switchCa.00AC104A		;15
	00AC10B8  00AC107A  switchCa.00AC107A		;16
	00AC10BC  00AC105A  switchCa.00AC105A		;17
	

	9跳到6A
	
	10,12,13,14,16都跳到7A,default
	
	11跳到3A
	
	15跳到4A
	
	17跳到5A
