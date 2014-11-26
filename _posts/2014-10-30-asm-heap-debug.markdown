--
layout: post
title: 堆的调试
categories:
- ASM
--

调试堆与调试栈不同，不能直接使用Ollydbg、Windbg，否则堆管理函数会检测到当前程序处于调试状态，而使用调试态堆管理策略

调试态堆管理策略和常态堆管理策略的差异:
- 调试堆不使用快表，只用空表分配
- 所有堆块都被加上多余的16字节尾部，用来防止溢出(防止程序溢出而不是溢出攻击)，包括8字节的0xAB和8字节0x00
- 块首的标志位不同


为了避免程序检测出调试器而使用调试堆管理策略所以我们在创建堆之后加入断点：_asm int 3，然后让程序单独执行,当程序将断点初始化完毕之后，断点会中断程序，调试器attach进程 就能看到真实的堆了

-------------------------------------------------------------------------------

	#include <windows.h>
	
	int main()
	{
		HLOCAL h1, h2, h3, h4, h5, h6;
		HANDLE hp;
	
		hp = HeapCreate(0, 0x1000, 0x10000);
		
		/* 人工断点 */
		__asm int 3
		
		h1 = HeapAlloc(hp, HEAP_ZERO_MEMORY, 3);
		h2 = HeapAlloc(hp, HEAP_ZERO_MEMORY, 5);
		h3 = HeapAlloc(hp, HEAP_ZERO_MEMORY, 6);
		h4 = HeapAlloc(hp, HEAP_ZERO_MEMORY, 8);
		h5 = HeapAlloc(hp, HEAP_ZERO_MEMORY, 19);
		h6 = HeapAlloc(hp, HEAP_ZERO_MEMORY, 24);
	
		HeapFree(hp, 0, h1);
		HeapFree(hp, 0, h3);
		HeapFree(hp, 0, h5);
		HeapFree(hp, 0, h4);
	
		return 0;
	
	}
	
-------------------------------------------------------------------------------

