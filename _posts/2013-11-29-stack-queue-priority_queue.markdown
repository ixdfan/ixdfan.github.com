---
author: UCSHELL
comments: true
date: 2013-11-29 12:53:01+00:00
layout: post
slug: stack-queue-priority_queue
title: stack queue priority_queue
wordpress_id: 1136
categories:
- STL
tags:
- STL
---

stack、queue、priority_queue

stack、queue是以deque的数据结构为基础的，并且修改了符合stack和queue的需要，这种修改了修改了其他组件的接口形成另一种风格的组件一般称为适配器，stack、queue与vector的priority_queue都应该归于适配器，而不是容器。

=======================================================================

stack是建立在deque的基础上的，对应着数据结构中的栈，是一种先进后出(FILO)的数据结构，除了在stack的最顶端压栈和出栈来操作元素以外，没有任何办法存取stack的元素。

stack不允许对容器遍历,也不允许通过其他方式存取元素，只有pop、push等简单操作，

所以stack没有迭代器，不能用迭代器来操作stack.

stack是建立在的deque的基础上的，他将deque的双向接口一端封闭，只允许在另一端来操作元素。

stack是连续性的空间，不过这种连续性也是一种假象。

=======================================================================
	empty():堆栈为空则返回真
	pop():移除栈顶元素
	push():在栈顶增加元素
	size():返回栈中元素的个数
	top():返回栈顶元素
=======================================================================

##### queue是建立在deque数据结构基础之上的，这里的queue对应数据结构中的队列，是一种先进先出(FIFO)的数据结构。

##### 除了在deque的最顶端和最底端操作元素外，没有任何办法来存取queue中的元素。

##### queue不允许对容器的遍历操作，也没有迭代器，不允许使用迭代器来操作queue；

##### queue是连续性的空间，不过这种连续性也是一种假象。

=======================================================================
	back():返回最后一个元素
	empty():队列为空则返回真
	front():返回第一个元素
	pop():移除栈顶元素
	push():在栈顶增加元素
	size():返回栈中元素的个数
=======================================================================

vector的priority_queue

priority_queue是以vector的数据结构为基础的，并且修改了符合priority_queue的需要。

priority_queue(优先队列)是建立在vector数据结构之上的，priority_queue是有优先权值的queue，它只允许在容器的两端操作元素，但它并非像queue那样先进先出，他设置了一个优先权，优先权大的先出。

比如从容器的一段输入:4、2、8、7

这时候经过优先权从另一端去除的元素顺序是8、7、4、2

除了在priority_queue的最顶端和最顶端操作元素外，没有任何办法来存取priority_queue中的元素。

priority_queue不允许对容器的遍历操作。所以也没有迭代器。

priority_queue的出列顺序是按照less来设定优先权，也就是元素值最大的先出列，如果此时不用默认的less，而是在程序中声明priority_queue时采用greater，则priority_queue中最小值的元素先出列
    
    /*默认情况下的采用less设定优先权*/
    #include iostream
    #include string
    #include queue
    #include vector
    using namespace std;
    
    int main()
    {
            priority_queue<int, vector > ipqueue;
            ipqueue.push(4);
            ipqueue.push(2);
            ipqueue.push(8);
            ipqueue.push(7);
    
            while(ipqueue.size()){
                    cout << ipqueue.top() << ',';
    
                    ipqueue.pop();
            }
            return 0;
    }
  
    输出: 8,7,4,2

=======================================================================
    
    /*设定了greater则不适用默认优先权*/
    #include iostream
    #include string
    #include queue
    #include vector
    using namespace std;
    
    int main()
    {
            priority_queue<int, vector, greater > ipqueue;
            ipqueue.push(4);
            ipqueue.push(2);
            ipqueue.push(8);
            ipqueue.push(7);
    
            while(ipqueue.size()){
                    cout << ipqueue.top() << ',';
    
                    ipqueue.pop();
            }
            return 0;
    }
   
    输出: 4,2,7,8


=======================================================================

##### 注意：
priority_queue的头文件也是queue

priority_queue与queue的数据结构不一样，priority_queue是建立在vector数据结构基础上的，所以是真正的连续空间！

=======================================================================
	empty():优先队列为空则返回真
	pop():删除第一个元素
	push():加入一个元素
	size():返回优先队列中元素的个数
	top():返回优先队列中有最高优先级的元素
=======================================================================
