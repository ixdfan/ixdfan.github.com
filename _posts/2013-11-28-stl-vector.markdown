---
layout: post
title: STL::vector
categories:
- STL
tags:
- STL
---

vector容器分配的是一块连续的内存空间，每次容器的增长，并不是在原有连续的内存空间后在进行简单的叠加。按照内存分配的特点，它后面的内存恐怕早就分配给其他对象了，这时候**vector的增长策略是重新申请一块更大的新的内存，并把现有容器中的元素逐个复制过去，然后释放销毁旧的内存空间。**

##### 注意：
这个时候如果原先有一个迭代器指向vector的内部，则当vector容器增长后，这个迭代器就不再指向该容器了，因为**迭代器指向的是旧的内存，而旧的内存早就被销毁了，此时迭代器已经失效，所以当操作容器时候，迭代器要及时使用，而不要在对容器进行插入等操作后在使用迭代器。**

vector函数表

================================================================

assgin
    
    void assgin(const_iterator frist, const_iterator last);
    void assgin(size_type n, const T& x = T());

作用:

将区间[first, last)的元素赋值到当前vector容器中；

赋n个值位x的元素到vector容器中，这个函数将会清除掉vector容器以前的内容

================================================================

at

    reference at(size_type pos);
    const_reference at(size_type pos) const;

作用:

返回vector容器中指定pos位置元素的引用。

at()函数比[]运算符函数更安全，他不会访问到vector容器内越界的元素；

================================================================

back
    
    reference back();
    const_reference back() const;

作用:

返回vector容器中的最末尾的元素的引用

================================================================

begin
    
    iterator begin();
    const_iterator begin() const;

作用:

返回一个指向vector容器中其实元素的迭代器

================================================================

capacity
    
    size_type capacity();

作用:

返回vector容器在重新进行内存分配以前的能容纳元素的数量

================================================================

clear
    
    void clear();

作用:

删除vector中所有元素

================================================================

empty
    
    bool empty() const;

作用:

如果当前vector中没有容纳任何元素，则empty返回true

================================================================

end
   
    iterator end();
    iterator end() const;

作用:

返回指向vector容器中最后一个元素的下一个元素，例如[a, b)中指向b

================================================================

erase
    
    iterator erase(iterator it);
    iterator erase(iterator first, iterator last);

作用:

删除vector容器中it位置的元素，或者删除在first与last之间的元素；

函数返回的是指向vector容器中被删除的最后一个元素的下一个位置的迭代器

================================================================

front
    
    reference front();
    const_reference front() const;

作用:

返回vector容器中起始元素的位置

================================================================

get_allocator
    
    allocator_type get_allocator() const;

作用:

返回vector容器的内存分配器

================================================================

insert
    
    iterator insert(iterator it, const T& x = T());
    void insert(iterator it, size_type n, const T& x);
    void insert(iterator it, const_iterator first, const_iterator last);

作用:

在容器迭代器it指向的位置前插入值为x的元素，返回指向这个元素的迭代器；

在迭代器it指定的位置前插入n个值为x的元素；

在迭代器it制定的位置前插入区间[first, last)中所有的元素；

================================================================

max_size
    
    size_type max_size() const;

作用:

返回vector容器所能容纳的元素数量的最大值

================================================================

pop_back
    
    void pop_back();

作用:

删除vector容器最末尾的元素

================================================================

push_back
    
    void push_back(const T& x);

作用:

添加值为x的元素到vector中

================================================================

rbegin
    
    reverse_iterator rbegin();
    const_reverse_iterator rbegin() cosnt;

作用:

返回指向vector末尾的反向迭代器

================================================================

rend
    
    reverse_iterator rend();
    const_reverse_iterator rend() cosnt;

作用:

返回指向vector起始位置的反向迭代器

================================================================

reserve
    
    void reserve(size_type n);

作用:

为vector容器预留可以容纳n个元素的空间

================================================================

resize
    
    void resize(size_type n, T x = T())

作用:

改变vector容器的大小为n，且对新创建的元素赋值x

================================================================

size
    
    size_type size() const;

作用:

返回vector容器所容纳元素的数目

================================================================

swap
    
    void swap(vector& x);

作用:

交换当前vector容器与x容器中的元素，x是一个vector容器

================================================================

vector数据结构的说明：

**vector数据结构，采用的是连续的线性空间，属于线性存储。**

它采用3个迭代器_First、_Last、_End来指向分配来的线性空间的不同范围。

其中_First指向使用空间的头部；

_Last指向使用空间大小(size)的尾部；

_End指向使用空间容量(capacity)的尾部；

通过三个迭代器_First、_Last、_End可以方便的提供容器的头、尾、大小、容量等;

可以很容易的实现back() begin() capacity() empty erase() front() rbegin() rend() size()等函数；通常将vector的大小与容量之差成为vector的备份空间。备份空间主要是从性能上来考虑，比避免每加入一个元素就要重新分配一次空间，备份空间的存在将大大的提高vector的存储效率。

##### 注意：

**vector的增长是按照当前容量的一倍来增长的**
