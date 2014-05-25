---
layout: post
title:  map的使用
description: 
modified: 
categories: 
- STL
tags:
- map
---


map是关联容器，它提供一对一的数据处理能力，其中第一个可以叫做关键字，每个关键字只能出现一次，第二个叫关键字的值。

map使用红黑树来实现的，所以在map捏不所有的数据都是有序的。


#### map的插入

1.使用insert插入pair数据

	#include <iostream>
	#include <string>
	#include <map>
	
	using namespace std;
	
	int main(int argc, char** argv)
	{
		map<int, string> map_student;
		map_student.insert(pair<int, string>(1, "student_one"));
		map_student.insert(pair<int, string>(2, "student_two"));
		map_student.insert(pair<int, string>(3, "student_three"));
	
		map<int, string>::reverse_iterator reiter;
		map<int, string>::iterator iter;
	
		/*	正序输出	*/
		for (iter = map_student.rbegin(); iter != map_student.rend(); ++iter) {
			cout << iter->first << ":" << iter->second << endl;	
		}
		cout << "map.size() = " <<  map_student.size() << endl;

		/*	逆序输出	*/
		for (reiter = map_student.rbegin(); reiter != map_student.rend(); ++reiter) {
			cout << reiter->first << ":" << reiter->second << endl;	
		}
		return 0;
	}

2.使用insert插入value_type数据



	#include <iostream>
	#include <string>
	#include <map>
	
	using namespace std;
	
	int main(int argc, char** argv)
	{
	
		
	
		map<int, string> map_student;
		
		map_student.insert(map<int, string>::value_type(1, "student_one"));
		map_student.insert(map<int, string>::value_type(2, "student_two"));
		map_student.insert(map<int, string>::value_type(3, "student_three"));
	
		map<int, string>::iterator iter;
	
		for (iter = map_student.begin(); iter != map_student.end(); ++iter) {
			cout << iter->first << ":" << iter->second << endl;	
		}
	
		return 0;
	}


3.数组方式插入


	#include <iostream>
	#include <string>
	#include <map>
	
	using namespace std;
	
	int main(int argc, char** argv)
	{
		map<int, string> map_student;
		map_student[1] =  "student_one";
		map_student[2] =  "student_two";
		map_student[3] =  "student_three";
	
		map<int, string>::iterator iter;
	
		for (iter = map_student.begin(); iter != map_student.end(); ++iter) {
			cout << iter->first << ":" << iter->second << endl;	
		}
	
			/*	很少能够使用如下方法，除非是连续的	*/	
	//		int size = map_student.size();	
			/*	要从下标1开始，因为我们没有插入0	*/
	//		for (int index = 1; index <= size; ++index) {	
	//			cout << map_student[index] << endl;
	//		}
	
		return 0;
	}


以上三种方法都可以事项数据的插入，但是他们有一定的区别:

第一和第二种是完全一样的,使用insert插入数据，当map中有这个关键字的时候，insert是插入不了的，相当与不会执行。

数组方式则会修改已经存在的值


		map_student.insert(map<int, string>::value_type(2, "student_two"));
		map_student.insert(map<int, string>::value_type(2, "student_three"));

以上两条语句执行之后，map中2关键字对应的值还是student_two,也就是说第二条语句没有生效，这就涉及到如何判断insert语句是否成功插入的问题，可以使用pair来获取是否插入成功


	/*	通过insert_pair的第二个变量来知道是否插入成功，成功返回true，失败返回false，
		第一个变量返回的是map的迭代器		
	*/
	pair<map<int, string>::iterator, bool> insert_pair;
	map_student.insert(map<int, string>::value_type(2, "student_two"));
	insert_pair = map_student.insert(map<int, string>::value_type(2, "student_three"));
	
	if (insert_pair.second == false) {
		cout << "insert failed" << endl;
	}


数组中的插入会覆盖原来的

		map_student[2] =  "student_two";
		map_student[2] =  "student_three";

则map中的2对应的值变成了student_three;


#### map的大小

	int size = map_student.size();



#### map的遍历

map中提供了正向与反向迭代器可以使用;




#### 数据的查找
1.使用count

count是返回map中元素的个数，但是map不允许有重复的，所以count要么返回0,要么返回1
但是缺点是无法确定数据出现的位置。

	map_student.count(2)	/*	存在所有返回1	*/
	map_student.count(5)	/*	不存在所有返回0	*/

2.使用find

find返回的是一个迭代器，当数据出现时候，返回的是数据所在位置的迭代器，如果map中没有要查找的数据，它返回的迭代器就是end函数的迭代器。

	#include <iostream>
	#include <string>
	#include <map>
	
	using namespace std;
	
	int main(int argc, char** argv)
	{
		map<int, string> map_student;
		map_student.insert(pair<int, string>(1, "stuednt_one"));
		map_student.insert(pair<int, string>(2, "stuednt_two"));
		map_student.insert(pair<int, string>(3, "stuednt_three"));
	
		map<int, string>::iterator iter;
	
		iter = map_student.find(1);
		if (iter != map_student.end()) {
			cout << "find the value is " << iter->second << endl;
	
		} else {
			cout << "Do not find" << endl;
		}
		return 0;
	}


3.使用equal_range

lower_bound函数用来返回要查找关键字的下边界迭代器
upper_bound函数用来返回要查找关键字的上边界迭代器

如果map中已经插入了1,2,3,4的话，使用lower_bound(2)则返回2，upper_bound(2)返回的就是3

如果不存在upper_bound就返回迭代器指向end，如果不存在lower_bound就返回迭代器指向end.

例如upper_bound(4)就返回指向end的迭代器,lower_bound(0)返回的也是指向end的迭代器


equal_range返回一个pairpair中第一个变量是lower_bound返回的迭代其，第二个是upper_bound返回的迭代器，
如果这两个迭代器相等的话(就都是end)，则说明map中不出现这个关键字;如果存在的话其upper_bound与lower_bound一定不同

	#include <iostream>
	#include <string>
	#include <map>
	
	using namespace std;
	
	int main(int argc, char** argv)
	{
		map<int, string> map_student;
		map_student[1] =  "stuednt_one";
		map_student[2] =  "stuednt_two";
		map_student[3] =  "stuednt_three";
	
		map<int, string>::iterator iter;
	
		iter = map_student.lower_bound(2);
		cout << iter->second << endl;
	
		iter = map_student.lower_bound(3);
		cout << iter->second << endl;
	
		iter = map_student.upper_bound(1);
		cout << iter->second << endl;
	
		iter = map_student.upper_bound(2);
		cout << iter->second << endl;
	
		
		pair<map<int, string>::iterator, map<int, string>::iterator> map_pair;
		map_pair = map_student.equal_range(3);
	
		if (map_pair.first == map_pair.second) {
	
			cout << "do not find" << endl;
		
		} else {
			cout << "find" << endl;
		}
	
		/*	upper_bound(3)返回的是指向end的迭代器,一下是验证	*/
		cout << (map_pair.second == map_student.end() ? "end" : "other") << endl;
		return 0;
	}


####数据的清空与判断
清空map中的数据可以使用clear函数，判断map中是否有数据可以使用empty(),为空返回true

####数据的删除

	

	#include <iostream>
	#include <string>
	#include <map>
	
	using namespace std;
	
	int main(int argc, char** argv)
	{
		map<int, string> map_student;
		map_student.insert(pair<int, string>(1, "stuednt_one"));
		map_student.insert(pair<int, string>(2, "stuednt_two"));
		map_student.insert(pair<int, string>(3, "stuednt_three"));
		map_student.insert(pair<int, string>(4, "stuednt_four"));
	
		cout << "map.size() = " <<  map_student.size() << endl;

		/*	数据的删除使用迭代器	*/
		map<int, string>::iterator m_iter = map_student.find(1);
		if (m_iter != map_student.end()) {
			map_student.erase(m_iter);	
		}
		
		/*	直接使用关键字删除	
			如果删除了会返回1,否则返回0
		*/
		int ret = map_student.erase(2);

		/*	使用迭代器成片删除，删除的是一个前闭后开的区间	*/
		map_student.earse(map_student.begin(), map_student.end());
		cout << "map.size() = " <<  map_student.size() << endl;
		return 0;
	}


####排序
STL默认使用小于号排序的，对于常规类型没有问题，但是在用户自定义类型的情况下，排序就会出现问题，因为它没有小于号，所以编译不过去。

1.重载小于运算符

	#include <iostream>
	#include <string>
	#include <map>
	
	using namespace std;
	
	typedef struct student_info{
		int 		m_id;
		string 		m_name;

		/*	或者写成有原函数	*/	
		/*	自定义类型必须重载小于运算符	*/
		bool operator < (const student_info& info) const
		{
			if (m_id < info.m_id)
				return true;
			if (m_id == info.m_id) 	
				/*	如果id相同则按照名字比较	*/
				return m_name.compare(info.m_name) < 0;
	
			return false;
		}
	}student_info, *prt_student_info;
	
	
	int main(int argc, char** argv)
	{
		int size;
		map<student_info, int>	map_student;
		map<student_info, int>::iterator iter;
		student_info my_student;
		my_student.m_id = 1;
		my_student.m_name = "student_one";
	
		map_student.insert(pair<student_info, int>(my_student, 90));
	
		my_student.m_id = 2;
		my_student.m_name = "student_two";
		map_student.insert(pair<student_info, int>(my_student, 80));
	
		for (iter = map_student.begin(); iter != map_student.end(); iter++) {
			cout << iter->first.m_id << "	" << iter->first.m_name << "	" <<  iter->second << endl;
		}
	
		return 0;
	}
	
2.实现仿函数	

所谓的仿函数就是指在类中对()符号进行重载，使其具有与函数类似的功能

	class sort {
	public:
		/*	注意不是重载<，而是重载()	*/
	    bool operator()(student_info const & first, student_info const & second) const
		{   
			if (first.m_id < second.m_id)
				return true;
			if (first.m_id == second.m_id) 
				return first.m_name.compare(second.m_name) < 0;
			
			return false;
		}   
	};


	int main()
	{
		...	
		/*	并没有重载<，仅仅是实现了仿函数	*/
		map<student_info, int, sort>    map_student;
		...

	
	}

