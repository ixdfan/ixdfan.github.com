---
layout: post
title: bkdr哈希
description:  
modified: 
categories: 
- ALGORITHM
tags:
- 
---

据说bkdr哈希是字符串日常应用中最好的哈希方法，简单容易记忆，效率高！

    #include <iostream>
    #include <string>
    using namespace std;
    
    unsigned int BKDRHash(const char *str)
    {
    	unsigned int seed = 131; 
    	/*	 31 131 1313 13131 131313 ..	*/
    	unsigned int hash = 0;
    
    	while (*str) {   
    		hash = hash * seed + (*str++);
    	}   
    	return (hash & 0x7FFFFFFF);
    }
    
    int main()
    {
    	string word[7] = {
    			"test",
    			"tets",
    			"ttsw",
    			"wode",
    			"helo",
    			"say",
    			"men"
    	};
    	
    	unsigned int hash[7] = {0};
    	
    	for (int i = 0; i < 7; i++) {
    		hash[i] = BKDRHash(word[i].c_str());
    	}
    
    	for (int i = 0; i < 7; i++) {
    		cout << word[i] << "==>"  << hash[i] << endl;
    	}
    	return 0;
    
    }
