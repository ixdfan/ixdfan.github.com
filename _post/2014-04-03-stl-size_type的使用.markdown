---
layout: post
title:  map中size_type的使用
description: 
modified: 
categories: 
- stl 
tags:
- 
---

	#include <iostream>
	#include <string>
	#include <map>
	
	using namespace std;
	
	int main(int argc, char** argv)
	{
		map<int, int> m;
		map<int, int>::size_type size;
		size = m.max_size();
	
		cout << "The maxmum possible length of the map is " << size << endl; 
	
		return 0;
	}



