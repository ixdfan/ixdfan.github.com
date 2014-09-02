---
layout: post
title: 内核中的链表
description:  
modified: 
categories: 
- KERNEL
tags:
- 
---

内核中的链表是一个非常神奇的东西.内核链表是一个双向链表

	struct list_head {
		struct list_head *next, *prev;
	};


#### 内核链表的使用

-------------------------------------------------------------------------------

1.初始化链表头

	static inline void INIT_LIST_HEAD(struct list_head *list)
	{
		list->next = list;
		list->prev = list;
	}

-------------------------------------------------------------------------------

2.插入节点
	
	/* new是新建立的节点 */
	static inline void list_add(struct list_head *new, struct list_head *head)
	{
		/* 可以看到这个是插入到了链表的前面 */
		__list_add(new, head, head->next);
	}
	
	static inline void __list_add(struct list_head *new,
				      struct list_head *prev,
				      struct list_head *next)
	{
		next->prev = new;
		new->next = next;
		new->prev = prev;
		prev->next = new;
	}
	
	static inline void list_add_tail(struct list_head *new, struct list_head *head)
	{
		/* 这个是插入的链表的结尾 */
		__list_add(new, head->prev, head);
	}



-------------------------------------------------------------------------------

3.链表节点删除
	
	static inline void __list_del(struct list_head * prev, struct list_head * next)
	{
		next->prev = prev;
		prev->next = next;
	}
	
	static inline void __list_del_entry(struct list_head *entry)
	{
		__list_del(entry->prev, entry->next);
	}
	
	static inline void list_del(struct list_head *entry)
	{
		__list_del(entry->prev, entry->next);
		entry->next = LIST_POISON1;
		entry->prev = LIST_POISON2;
	}
	
	
-------------------------------------------------------------------------------

4.链表的遍历

	/* pos每次返回链表中每个节点的list所在的位置 */
	#define list_for_each(pos, head) \
		for (pos = (head)->next; pos != (head); pos = pos->next)
		
	#define list_entry(ptr, type, member) \
		container_of(ptr, type, member)

		
	#define container_of(ptr, type, member) ({			\
		const typeof( ((type *)0)->member ) *__mptr = (ptr);	\
		(type *)( (char *)__mptr - offsetof(type,member) );})

	/* pos就是你要访问的结构体的地址，head是链表的头节点的地址，member代表list_head在结构体中的名字 */
	#define list_for_each_entry(pos, head, member)				\
		for (pos = list_entry((head)->next, typeof(*pos), member);	\
		     &pos->member != (head); 	\
		     pos = list_entry(pos->member.next, typeof(*pos), member))


	

container_of不是很好理解，container_of的实际作用其实就是已知结构中list的地址，求出这个结构开始的地址
    
    |------|------>??
    |  S   |
    |------|
    |      |
    |------|------>0x100
    | list |
    |------|

	

	/* 例如输入的ptr = 0x100, type=struct employee, member=list*/
	#define container_of(ptr, type, member) ({

	const typeof( ((type *)0)->member ) *__mptr = (ptr);	
	转换为
	const typeof( ((struct employee*)0)->list)* __mptr = (0x100);
	typeof的作用是取类型
	struct list_head* __mptr = (0x100);

	如果上面的还不好理解的话，可以再简单一点:


	int a;/* 假如a位于0x10000位置*/
	char* p;
	p = &a;

	等价于

	p = (char*)0x10000;

	表示认为0x10000位置放的是一个字符，同样我们也可以假设0位置放的是一个字符;

	p = (char*)0x0;

	这就是struct list_head* __mptr = (0x100);的含义

	((struct employee*)0)->list的含义就是假设在0位置放置有一个struct employee类型的变量。
	知道这个struct employee的地址了，就能够使用成员变量。

	typeof( ((struct employee*)0)->list)的作用是取得成员变量的类型，list的类型是struct list_head;

	重新定义一个list_head的指针用于保存链表中成员变量list的地址
	const typeof( ((type *)0)->member ) *__mptr = (ptr);
	重新定义一个临时变量作用如同于MAX宏中的临时变量的作用，用于消除某些歧义;


	/* list在变量中的地址 - list在struct employee的偏移地址 = structemployee的开始地址 */
	(type *)( (char *)__mptr - offsetof(type,member) );})

	
	#define offsetof(TYPE, MEMBER) ((size_t) &((TYPE *)0)->MEMBER)

	&((struct employee*)0)->list;
	假设0的位置放置的是struct employee,那么就可以找到成员变量的地址，利用成员变量的地址-0就是成员变量位于结构体中的偏移值！不需要去管什么对齐补齐的！计算机会为我们直接获取地址！


-------------------------------------------------------------------------------

list_for_each+list_for_entry

	/*
	 * 内核链表的使用
	*/
	#include <linux/init.h>
	#include <linux/list.h>
	#include <linux/module.h>
	#include <linux/slab.h>
	
	MODULE_LICENSE("GPL");
	
	#define EMPLOYEE_NUM 10
	
	struct employee 
	{
		char name[20];
		int id;
		int salary;
		int age;
		struct list_head list;
	};
	
	/* 链表头节点 */
	struct list_head employee_list;
	struct employee* employeep = NULL;
	struct employee* employee_tmp = NULL;
	static int __init my_list_init(void)
	{
		/* 注意:局部变量最好放到前面，否则可能会有不确定的问题 */
		int i = 0;
		/* 初始化链表头节点 */
		INIT_LIST_HEAD(&employee_list);
		employeep = kmalloc(sizeof(struct employee)*EMPLOYEE_NUM, GFP_KERNEL);
		if (IS_ERR(employeep)) {
			printk("<0>kmalloc failed!\n");
			return -ENOMEM;
		}		
	
		memset(employeep, 0, sizeof(struct employee));
	
		/* 初始化每个struct */	
	 	for (i = 0; i < EMPLOYEE_NUM; ++i) {
			sprintf(employeep[i].name, "employee%d", i);
			employeep[i].id = 100 + i;
			employeep[i].salary = 1000 + i;
			/* 将数据添加到链表 */
			list_add(&((employeep+i)->list), &employee_list);
		}
		
		struct list_head* pos = NULL;

	    /* 链表节点的遍历 */
		/* pos就是每个节点中list的地址 */
		list_for_each(pos, &employee_list) {
			/* pos代表已知地址，第二个参数是要求哪个结构体的地址，
			   第三个代表pos在employee结构中哪个成员 */
			/* 其实就是利用已知的list地址，利用减法求结构的开始地址 */
			employee_tmp = list_entry(pos, struct employee, list);
			printk("<0>employee Name: %s\t ID: %d\t salary : %d\n", 
				   employee_tmp->name, 
				   employee_tmp->id, 
				   employee_tmp->salary);
		}
	
		return 0;
	}
	
	
	static void __exit my_list_exit(void) 
	{
		int i = 0;
		for (; i < EMPLOYEE_NUM; ++i) {
			/* 要删除节点的list的地址 */
			list_del(&(employeep[i].list));
		}
		
		kfree(employeep);
	}
	
	
	module_init(my_list_init);
	module_exit(my_list_exit);
	

-------------------------------------------------------------------------------
list_for_each_entry的使用

	/*
	 * 内核链表的使用
	*/
	#include <linux/init.h>
	#include <linux/list.h>
	#include <linux/module.h>
	#include <linux/slab.h>
	
	MODULE_LICENSE("GPL");
	
	#define EMPLOYEE_NUM 10
	
	struct employee 
	{
		char name[20];
		int id;
		int salary;
		int age;
		struct list_head list;
	};
	
	/* 链表头节点 */
	struct list_head employee_list;
	struct employee* employeep = NULL;
	struct employee* pos = NULL;
	static int __init my_list_init(void)
	{
		/* 注意:局部变量最好放到前面，否则可能会有不确定的问题 */
		int i = 0;
		/* 初始化链表头节点 */
		INIT_LIST_HEAD(&employee_list);
		employeep = kmalloc(sizeof(struct employee)*EMPLOYEE_NUM, GFP_KERNEL);
		if (IS_ERR(employeep)) {
			printk("<0>kmalloc failed!\n");
			return -ENOMEM;
		}		
	
		memset(employeep, 0, sizeof(struct employee));
	
		/* 初始化每个struct */
		
	 	for (i = 0; i < EMPLOYEE_NUM; ++i) {
			sprintf(employeep[i].name, "employee%d", i);
			employeep[i].id = 100 + i;
			employeep[i].salary = 1000 + i;
			/* 将数据添加到链表 */
			list_add(&((employeep+i)->list), &employee_list);
		}
		
		
		list_for_each_entry(pos, &employee_list, list) {
				/* pos代表已知地址，第二个参数是要求哪个结构体的地址，
			   第三个代表pos在employee结构中哪个成员 */
			/* 其实就是利用已知的list地址，利用减法求结构的开始地址 */
			printk("<0>employee Name: %s\t ID: %d\t salary : %d\n", 
				   pos->name, 
				   pos->id, 
				   pos->salary);
		}
	
		return 0;
	}
	
					
	static void __exit my_list_exit(void) 
	{
		int i = 0;
		for (; i < EMPLOYEE_NUM; ++i) {
			/* 要删除节点的list的地址 */
			list_del(&(employeep[i].list));
		}
		
		kfree(employeep);
	}
	
	
	module_init(my_list_init);
	module_exit(my_list_exit);
	
