---
layout: post
title: strcmp的构成
categories:
- ASM
---

	004011B0 >/$  8B5424 04     MOV EDX,DWORD PTR SS:[ESP+4]                                     ;  s1
	004011B4  |.  8B4C24 08     MOV ECX,DWORD PTR SS:[ESP+8]                                     ;  s2
	004011B8  |.  F7C2 03000000 TEST EDX,3
	004011BE  |.  75 3C         JNZ SHORT strcmp.004011FC
	004011C0  |>  8B02          /MOV EAX,DWORD PTR DS:[EDX]                                      ;  eax=s1
	004011C2  |.  3A01          |CMP AL,BYTE PTR DS:[ECX]                                        ;  低8位与s2中低8位比较
	004011C4  |.  75 2E         |JNZ SHORT strcmp.004011F4
	004011C6  |.  0AC0          |OR AL,AL                                                        ;  看al是否是数字0，即字符串结束符
	004011C8  |.  74 26         |JE SHORT strcmp.004011F0                                        ;  是否到了字符串尾部，到了则相等
	004011CA  |.  3A61 01       |CMP AH,BYTE PTR DS:[ECX+1]                                      ;  否则比较高8位
	004011CD  |.  75 25         |JNZ SHORT strcmp.004011F4
	004011CF  |.  0AE4          |OR AH,AH
	004011D1  |.  74 1D         |JE SHORT strcmp.004011F0
	004011D3  |.  C1E8 10       |SHR EAX,10                                                      ;  向右移动16位在比较高16位，但是高16为没有al、ah之类的寄存器，所以采用移位的方式
	004011D6  |.  3A41 02       |CMP AL,BYTE PTR DS:[ECX+2]
	004011D9  |.  75 19         |JNZ SHORT strcmp.004011F4
	004011DB  |.  0AC0          |OR AL,AL
	004011DD  |.  74 11         |JE SHORT strcmp.004011F0
	004011DF  |.  3A61 03       |CMP AH,BYTE PTR DS:[ECX+3]
	004011E2  |.  75 10         |JNZ SHORT strcmp.004011F4
	004011E4  |.  83C1 04       |ADD ECX,4
	004011E7  |.  83C2 04       |ADD EDX,4
	004011EA  |.  0AE4          |OR AH,AH
	004011EC  |.^ 75 D2         \JNZ SHORT strcmp.004011C0
	


