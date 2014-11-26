---
layout: post
title: mov与lea的区别
categories:
- ASM
---

mov是将一个操作数的值传给另个一个操作数

lea是将一个操作数的地址传给另一个操作数


	mov eax, [0x40000]
	;eax中是地址0x40000内存中的值，假设0x40000中内容为100，则eax=100
	lea eax, [0x40000]
	;eax中的值是0x40000这个地址
