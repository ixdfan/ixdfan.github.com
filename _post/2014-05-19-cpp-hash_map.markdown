---
layout: post
title: c++中的hash_map
description:  
modified: 
categories: 
- C\C++
tags:
- 
---

#### map与hash_map

	#include <iostream>
	#include <string>
	#include <map>
	#include <cstring>
	using namespace __gnu_cxx;
	
	using namespace std;

	int main()
	{
		map<string, string> name;
		name["first"] = 1;
		name["second"] = 2;
		name["third"] = 3;

		if(name.find("second") != name.end()) {
			cout << name["second"] << endl;
		}

		if(name.find("ten") != name.end()) {
			cout << name["ten"] << endl;
		}

		return 0;
	}

map的用法非常的简单，直接就是key-value的形式插入到map中,map底层使用的是红黑树来实现，红黑树也是二叉查找树的一种，所以即使100万记录，也只要20次左右的比较即可找到结果

#### hash_map的原理:

hash_map使用hash table来实现，hash table的优点在于O(1)查找，缺点是内存占用比较多

hash_map初始化首先分配内存形成一个足够大的数组，然后使用hash函数将key映射到数组中,将key-value放入到数组元素中。


hash_map的关键在于hash函数和比较函数，这两个也是hash_map中需要指定的参数

	#include <iostream>
	#include <string>
	#include <map>
	#include <cstring>
	using namespace __gnu_cxx;
	
	using namespace std;

	int main()
	{
		hash_map<int, string> name;
		name[1] = 1;
		name[3] = 2;
		name[2] = 3;

		if(name.find(2) != name.end()) {
			cout << name[2] << endl;
		}

		if(name.find(3) != name.end()) {
			cout << name[3] << endl;
		}

		return 0;
	}

以上代码看此与之前的map差不多，但是使用的pair是(int, string).

hash_map的声明如下:

	81   template<class _Key, class _Tp, class _HashFn = hash<_Key>,
	82        class _EqualKey = equal_to<_Key>, class _Alloc = allocator<_Tp> >
	83     class hash_map


	hash_map<int, string> name;
	等价
	hash_map<int, string, hash<int>, equal_to<int>> name;

hash<int>如下:
	67   template<class _Key>
	68     struct hash { };
	69 
	135   template<>
	136     struct hash<int>
	137     { 
	138       size_t
	139       operator()(int __x) const		/*	重载()符号	*/
	140       { return __x; }
	141     };


默认提供了一下的struct hash<>特化版本

	struct hash<char*>
	struct hash<const char*>
	struct hash<char>
	struct hash<unsigned char>
	struct hash<signed char>
	struct hash<short>
	struct hash<unsigned short>
	struct hash<int>
	struct hash<unsigned int>
	struct hash<long>
	struct hash<unsigned long>

也就是说key如果是以上类型，就会自动调用对应的struct hash

如果key不是以上类型，那么就没有对应的struct hash可以调用，这时候就需要自己来写hash函数,hash函数的形式要求与上面的相同
	
	struct hash_string 
	{
		size_t operator() (const string& str)	const	/*	必须是const类型的	*/
		{
			/*	bkdr_hash	*/
			unsigned int hash = 0;
			int seed = 131;
	
			int i = 0;
			while (str[i])
			{
				hash = str[i] * seed + hash;
				++i;
			}
	
			return (0x7fffffff & hash);
			
		}
	}

##### 注意: 
自己实现哈希函数时候必须与系统默认格式相同;特别是operator函数必须是const修饰


equal_to是比较函数


	113   template<typename _Arg1, typename _Arg2, typename _Result>
	114     struct binary_function
	115     {
	116       /// @c first_argument_type is the type of the first argument
	117       typedef _Arg1     first_argument_type;
	118   
	119       /// @c second_argument_type is the type of the second argument
	120       typedef _Arg2     second_argument_type;
	121   
	122       /// @c result_type is the return type
	123       typedef _Result   result_type;
	124     };
	203   template<typename _Tp>
	204     struct equal_to : public binary_function<_Tp, _Tp, bool>
	205     {
	206       bool
	207       operator()(const _Tp& __x, const _Tp& __y) const
	208       { return __x == __y; }
	209     };

可以看到对于常规类型equal_to都可以解决，但是对于自定义类型，equal_to就无能为力了！

所以对于自定义类型的数据，要自己重写比较函数

可以在自定义类型中写入operator==函数

	class A
	{
		int first;
		int second;
		...
		bool operator== (const A& a) const
		{
			return first == a.first;	
		}
		...
	}

或者是重写一个比较函数

	struct compare
	{
		bool operator() (const string& a, const string& b) const
		{
			return a == b;
		}
	};


	int main()
	{
	
	
		hash_map<string, string, hash_string, compare> name;
		name["first"] = "first";
		name["second"] = "second";
		name["third"] = "thirs";
	
		if (name.find("first") != name.end()) {
			cout << name["first"]  << endl;
		}
		return 0;
	}
	
	

#### hash_map与map的区别:

hash_map需要hash函数，需要支持==操作符号;map只需要支持小于符号

hash_map使用hash table实现的，map使用的是红黑树
