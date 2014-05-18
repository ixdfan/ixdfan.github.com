---
author: UCSHELL
comments: true
date: 2013-12-01 05:51:59+00:00
layout: post
slug: stliterator
title: STL::iterator
wordpress_id: 1147
categories:
- STL
tags:
- STL
---

迭代器
STL的iterator是一种对象，其作用是用来遍历STL容器中的部分或全部元素，因此对于那些需要遍历的容器例如vector、list等，必须在容器的定义中内嵌自己的迭代器，该容器内嵌的迭代器提供一些基本操作符，例如*、++、==、!=、=一遍支持对STL容器的遍历等操作。

========================================================================

迭代器的分类：

STL中将迭代器分成5类：

	输入迭代器(inPut iterator)
	输出迭代器(outPut iterator)
	前向迭代器(forward iterator)
	双向迭代器(birectional iterator)
	随机访问迭代器(random access iterator)

========================================================================

输入迭代器(inPut iterator)：可用于读取容器中的元素，但是不能保证能支持容器的写入操作。

##### 必须满足:

	==、！=:具有相等和不相等操作符，用于比较两个迭代器。
	++:前置和后置的自增运算符
	*:读取元素的解引用操作符
	->:箭头操作符，可以对迭代器进行解引用

========================================================================

输出迭代器(outPut iterator)：可用于向容器中写入元素，但是不能保证能支持容器的读取操作。

##### 必须满足:

	++:前置和后置的自增运算符
	*:读取元素的解引用操作符
========================================================================
前向迭代器(forward iterator):可用读取或写入指定的容器，这类迭代器只会以一个方向遍历容器。

##### 必须满足:

	支持输入迭代器和输出迭代器的所有操作
	支持对同一个元素的多次读写
	可复制前向迭代器来记录序列中的一个位置，方便将来返回此位置
========================================================================

双向迭代器(birectional iterator):可用从两个方向读取和写入指定的容器。

##### 注意：STL所有标准库提供的迭代器都至少达到双向迭代器的要求!

必须满足:

	提供前向迭代器的全部操作
	--:双向迭代器还提供前置和后置的自减运算
========================================================================

随机访问迭代器(random access iterator):提供在常量时间内访问容器中任意位置的功能

必须满足:

	支持双向迭代器的全部功能
	<、<=、>、>=:支持这些关系操作符，用于比较两个迭代器的相对位置。
	+、+=、-、-=:支持迭代器与整形数值n之间的加法和减法操作符，可以使迭代器向前或后移动n个元素。
	-:支持两个迭代器之间的减法操作，可以得到连个迭代器之间的距离。
	[]:支持下标操作符[]

========================================================================

##### 总结:
* vector和deque提供的是随机访问迭代器，在定义算法时通常写作RandomAccessIterator；

* list提供的是双向迭代器，在定义算法时通常写作BidirectionaIterator；

* set/multiset、map/multimap提供的前向迭代器，在定义算法是写作ForwardIterator；

========================================================================

    
    #include vector
    using namespace std;
    
    int main()
    {
    	int ia[6] = {5, 7, 3, 4, 6, 9};
    	vector iv(ia, ia+6);
    	vector::iterator iter;
    	……
    	return 0;
    }


这段代码用'::'做前缀来声明迭代器iter，能声明一个对象，表明iterator是一个类，但是为什么要使用'::'呢？

    
    class A
    {
    	public:
    	typedef int INT;
    	class B{};
    };
    int main()
    {
    	A::INT i;
    	A::B b;
    }


这段代码定义了一个class A，然后又在class A中定义了一个INT类型，还定义了一个嵌套类class B，这时候，如果要在程序中使用class A中的INT类型或B类型去声明一个变量，就要加上一个'::'符号，表明这是在class A中声明的类型。

    
    class vector : protected _Vector_base<_Tp, _Alloc>
        {
          // Concept requirements.
          typedef typename _Alloc::value_type                _Alloc_value_type;
          __glibcxx_class_requires(_Tp, _SGIAssignableConcept)
          __glibcxx_class_requires2(_Tp, _Alloc_value_type, _SameTypeConcept)
    
          typedef _Vector_base<_Tp, _Alloc>                  _Base;
          typedef typename _Base::_Tp_alloc_type             _Tp_alloc_type;
    
        public:
          typedef _Tp                                        value_type;
          typedef typename _Tp_alloc_type::pointer           pointer;
          typedef typename _Tp_alloc_type::const_pointer     const_pointer;
          typedef typename _Tp_alloc_type::reference         reference;
          typedef typename _Tp_alloc_type::const_reference   const_reference;
          typedef __gnu_cxx::__normal_iterator<pointer, vector> iterator;	//迭代器


iterator是vector中定义的类型，事实上在STL的迭代器都是定义在某个容器类中的，他是专门为每一个容器类分别设计的。
每种容器都有自己的迭代器。所以声明一个vector类型的迭代器，就要使用vector中定义的迭代器类型。

    
    vector::iterator iter;


========================================================================
list迭代器

    
    #include list
    using namespace std;
    
    int main()
    {
    	int ia[6] = {5, 7, 3, 4, 6, 9};
    	list iv(ia, ia+6);
    	list::iterator iter;
    	……
    	return 0;
    }


========================================================================

其他容器的迭代器

deque容器也拥有属于自己的迭代器，定义在deque类中。

map/multimap和set/multiset是建立在红黑树基础上的。

stack、queue、priority_queue不允许遍历容器，只允许在容器的一端或两端操作元素，所以他们没有迭代器

========================================================================

以下是正确的：

    
    vector::iterator iter;
    list::iterator iter;
    deque::iterator iter;
    set::iterator iter;
    multiset::iterator iter;
    map<int, int>::iterator iter;
    mulitmap<int, int>::iterator iter;


========================================================================

以下是错误的：

    
    stack::iterator iter;
    queue::iterator iter;
    priority_queue::iterator iter;


========================================================================

容器的迭代器例子：

    
    void input(const vector& vec)
    {
         vector::iterator iter = vec.begin();
         ……
    }


这个函数的问题是vec是一个const引用，但是却试图在函数中用一个非const迭代器去绑定他。

如果允许这样做，那么就可以非常轻易的使用这个iterator来修改vector引用了，因此在编译时函数就会报错。

在vector、list、queue等源码中，每一个容器在定义一个iterator(用于修改数据)的同时，也会定义一个const iterator(用来保护数据)

##### 注意:

const容器只能使用const iterator去绑定。

========================================================================
