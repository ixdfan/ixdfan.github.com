---
author: UCSHELL
comments: true
layout: post
title: nginx的ngx_list_t结构
categories:
- Nginx
---

ngx\_list_t是nginx封装的链表容器

    
    typedef struct ngx_list_part_s  ngx_list_part_t;
    
    struct ngx_list_part_s {
        void             *elts;	/*指向本节点中数组的首地址*/
        ngx_uint_t        nelts;	/*当前数组已经使用的容量*/
        ngx_list_part_t  *next;	/*下一个节点ngx_list_part_t的地址*/
    };
    
    typedef struct {
        ngx_list_part_t  *last;	/*指向链表最后一个数组元素*/
        ngx_list_part_t   part;	/*链表的首个元素*/
    
    	/*size * nalloc表示的是节点中数组的大小	*/
        size_t            size;	/*数组中每个元素的大小*/
        ngx_uint_t        nalloc;	/*数组中容纳元素的个数*/
    
        ngx_pool_t       *pool;
    } ngx_list_t;


注意:

ngx\_list\_t描述的是整个链表，而ngx\_list\_part\_t表示的是链表中的一个元素;
其中ngx\_list\_t不是一个单纯的链表，这个链表中的每个节点ngx\_list\_part\_t又是一个数组，拥有连续的内存;

它既依赖于ngx\_list\_t里的size和nalloc来表示数组的容量，同时又依靠每个ngx\_list\_part_t成员中nelts表示当前数组已经使用了多少容量

也就是说其实用户存储的东西放在链表的节点里的数组中

这样设计的好处:
* 链表中存储的元素是灵活的，可以是任何数据结构
* 小块的内存使用链表访问效率是低下的

============================================================

对链表遍历

    
    	ngx_list_part_t* part = &testlist.part;
    	ngx_str_t* str = part->elts;
    	for(i=0; ; i++){
    		/*i代表数组中元素个数，如果超过了个数，那么就要遍历下一个节点中的数组*/
    		if(i >= part->nelts){
    			if(part->next == NULL){
    				break;
    			}
    
    		part = part->next;
    		header = part->elts;
    
    		i = 0;
    		}
    	/*非常方便取得当前遍历到的链表元素*/
    	printf("list element: %*s\n", str[i].len, str[i].data);
    	}
