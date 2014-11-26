---
layout: post
title: unicode编码的问题
categories:
- WINAPI
---

今天使用UNICODE编码的时候总是有错误，
	
    #include "stdafx.h"
    #define UNICODE
    #include <tchar.h>

    #include <windows.h>
   			
	void PrintConsole()
	{
	
		HANDLE hOut = GetStdHandle(STD_OUTPUT_HANDLE);
		TCHAR* pszText = TEXT("我是程序员\n");
		WriteConsoleW(hOut, pszText, wcslen(pszText), NULL, NULL);
		getchar();
	}
	
	int main(int argc, char* argv[])
	{
	
		PrintConsole();
	
	
		return 0;
	}

错误信息如下



	Compiling...
	char.cpp
	C:\Users\Administrator\Desktop\MFC\Wchar\char\char.cpp(83) : error C2664: 'wcslen' : cannot convert parameter 1 from 'char *' to 'const unsigned short *'
	        Types pointed to are unrelated; conversion requires reinterpret_cast, C-style cast or function-style cast
	Error executing cl.exe.
	
	char.exe - 1 error(s), 0 warning(s)
	

重新改了头文件的位置

	
    #include "stdafx.h"

    #include <windows.h>
   	#define UNICODE
    #include <tchar.h>
		
	void PrintConsole()
	{
	
		HANDLE hOut = GetStdHandle(STD_OUTPUT_HANDLE);
		TCHAR* pszText = TEXT("我是程序员\n");
		WriteConsoleW(hOut, pszText, wcslen(pszText), NULL, NULL);
		getchar();
	}
	
	int main(int argc, char* argv[])
	{
	
		PrintConsole();
	
	
		return 0;
	}

错误信息如下:

	
	Compiling...
	char.cpp
	C:\Users\Administrator\Desktop\MFC\Wchar\char\char.cpp(82) : error C2440: 'initializing' : cannot convert from 'unsigned short [7]' to 'char *'
	        Types pointed to are unrelated; conversion requires reinterpret_cast, C-style cast or function-style cast
	C:\Users\Administrator\Desktop\MFC\Wchar\char\char.cpp(83) : error C2664: 'wcslen' : cannot convert parameter 1 from 'char *' to 'const unsigned short *'
	        Types pointed to are unrelated; conversion requires reinterpret_cast, C-style cast or function-style cast
	Error executing cl.exe.

简直就是崩溃了，后来终于找到了原因

	
    #include "stdafx.h"
    #define UNICODE
	#include <windows.h>
    #include <tchar.h>


原来头文件的位置要这么写
