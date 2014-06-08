---
layout: post
title:  sed error:unterminated `s' command
description: 
modified: 
categories: 
- shell 
tags:
- 
---

	#include <stdio.h>
	#include <stdlib.h>
	#include <string.h>
	
	long int power(int, int);
	
	int main(){
		int base, n;
		scanf("%d, %d\n", &base, &n);
		printf("the power is: %d\n", power(base, n));
		return 0;
	}
	
	long int power(int base, int n)
	{
		return base^n;
	}


	[root@ sed]# sed -e 's/\(incl\)ude/\1UDE' main.c
	sed: -e expression #1, char 19: unterminated `s' command
	[root@ sed]# sed -e 's/\(incl\)ude/\1UDE/' main.c		#原来是忘记加尾部的/
	#inclUDE <stdio.h>
	#inclUDE <stdlib.h>
	#inclUDE <string.h>
	
	long int power(int, int);
	
	int main(){
		int base, n;
		scanf("%d, %d\n", &base, &n);
		printf("the power is: %d\n", power(base, n));
		return 0;
	}
	
	long int power(int base, int n)
	{
		return base^n;
	}

inclUDE <string.h>

