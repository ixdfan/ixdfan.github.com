---
layout: post
title: if-else的逆向
categories:
- ASM
---
	
	001A1000  /$  55            PUSH EBP
	001A1001  |.  8BEC          MOV EBP,ESP
	int a, b, c
	/*
	001A1003  |.  83EC 0C       SUB ESP,0C                               
	001A1006  |.  68 F4201A00   PUSH ifelse01.001A20F4                   ; /format = "begin"
	001A100B  |.  FF15 A0201A00 CALL DWORD PTR DS:[<&MSVCR90.printf>]    ; \printf
	001A1011  |.  83C4 04       ADD ESP,4
	*/
	a = 1;
	b = 2;
	c = 3;
	/*
	001A1014  |.  C745 FC 01000>MOV DWORD PTR SS:[EBP-4],1               
	001A101B  |.  C745 F8 02000>MOV DWORD PTR SS:[EBP-8],2
	001A1022  |.  C745 F4 03000>MOV DWORD PTR SS:[EBP-C],3
	*/

	if (a > b) {
		printf("a >ｂ");
	}
	/*
	001A1029  |.  8B45 FC       MOV EAX,DWORD PTR SS:[EBP-4]             ;  eax = 1
	001A102C  |.  3B45 F8       CMP EAX,DWORD PTR SS:[EBP-8]             ;  cmp [ebp-4], [ebp-8]
	001A102F  |.  7E 10         JLE SHORT ifelse01.001A1041              ;  小于等于则转跳
	001A1031  |.  68 FC201A00   PUSH ifelse01.001A20FC                   ; /format = "a>b"
	001A1036  |.  FF15 A0201A00 CALL DWORD PTR DS:[<&MSVCR90.printf>]    ; \printf
	001A103C  |.  83C4 04       ADD ESP,4
	*/
	/* if直接执行else代码之后的代码
	001A103F  |.  EB 0E         JMP SHORT ifelse01.001A104F
	*/
	else {
		printf("b >= a");
	}
	/*
	001A1041  |>  68 00211A00   PUSH ifelse01.001A2100                   ; /format = "b>=a"
	001A1046  |.  FF15 A0201A00 CALL DWORD PTR DS:[<&MSVCR90.printf>]    ; \printf
	001A104C  |.  83C4 04       ADD ESP,4
	*/
	/*
	001A104F  |>  8B4D F4       MOV ECX,DWORD PTR SS:[EBP-C]
	001A1052  |.  3B4D F8       CMP ECX,DWORD PTR SS:[EBP-8]
	*/
	if (c > b) {
		/*
		001A1055  |.  7E 46         JLE SHORT ifelse01.001A109D
		001A1057  |.  8B55 F4       MOV EDX,DWORD PTR SS:[EBP-C]
		001A105A  |.  3B55 FC       CMP EDX,DWORD PTR SS:[EBP-4]
		*/
		
		if (c > a) {
			/*
	        001A105D  |.  7E 20         JLE SHORT ifelse01.001A107F
			001A105F  |.  8B45 FC       MOV EAX,DWORD PTR SS:[EBP-4]
			001A1062  |.  50            PUSH EAX                                 ; /<%d>
			001A1063  |.  8B4D F4       MOV ECX,DWORD PTR SS:[EBP-C]             ; |
			001A1066  |.  51            PUSH ECX                                 ; |<%d>
			001A1067  |.  8B55 F8       MOV EDX,DWORD PTR SS:[EBP-8]             ; |
			001A106A  |.  52            PUSH EDX                                 ; |<%d>
			001A106B  |.  8B45 F4       MOV EAX,DWORD PTR SS:[EBP-C]             ; |
			001A106E  |.  50            PUSH EAX                                 ; |<%d>
			001A106F  |.  68 08211A00   PUSH ifelse01.001A2108                   ; |format = "%d>%d,%d>%d"
			001A1074  |.  FF15 A0201A00 CALL DWORD PTR DS:[<&MSVCR90.printf>]    ; \printf
			001A107A  |.  83C4 14       ADD ESP,14
			001A107D  |.  EB 1E         JMP SHORT ifelse01.001A109D              ; else之后的代码
			*/
			printf("%d>%d, %d>%d", c, b, c, a);
		} else {
			/*
			001A107F  |>  8B4D FC       MOV ECX,DWORD PTR SS:[EBP-4]
			001A1082  |.  51            PUSH ECX                                 ; /<%d>
			001A1083  |.  8B55 F4       MOV EDX,DWORD PTR SS:[EBP-C]             ; |
			001A1086  |.  52            PUSH EDX                                 ; |<%d>
			001A1087  |.  8B45 F8       MOV EAX,DWORD PTR SS:[EBP-8]             ; |
			001A108A  |.  50            PUSH EAX                                 ; |<%d>
			001A108B  |.  8B4D F4       MOV ECX,DWORD PTR SS:[EBP-C]             ; |
			001A108E  |.  51            PUSH ECX                                 ; |<%d>
			001A108F  |.  68 14211A00   PUSH ifelse01.001A2114                   ; |format = "%d>%d,%d<=%d"
			001A1094  |.  FF15 A0201A00 CALL DWORD PTR DS:[<&MSVCR90.printf>]    ; \printf
			001A109A  |.  83C4 14       ADD ESP,14
			*/
			printf("%d>%d, %d<=%d", c, b, c, a);
		}
		/*
		001A109D  |>  33C0          XOR EAX,EAX
		*/
	}
	001A109F  |.  8BE5          MOV ESP,EBP
	001A10A1  |.  5D            POP EBP
	001A10A2  \.  C3            RETN
	
