---
layout: post
title: 内核中内存的分配
description:  
modified: 
categories: 
- KERNEL
tags:
- 
---

内核中内存分配:

kmalloc/kfree(申请的物理地址连续，所以一般用于申请较小空间时候使用)

vmalloc/vfree(申请到的物理地址空间可能不连续，通常申请较大空间时候使用)

__get_free_pages/free_pages


void *kmalloc(size_t size, gfp_t flags)

flags：

- GFP_KERNEL:分配内存，分配过程中可能导致睡眠(中断上下文中是不允许睡眠的，内核的调度机制就是中断，如果在中断时候睡眠了那么中断就没法返回，就没有办法产生新的中断)

- GFP_ATOMIC:分配过程中不会导致睡眠

- GFP_DMA:申请到的内存通常位于0~16M空间，用于做DMA数据传输
- __GFP_HIGHMEM:申请高端内存，物理地址896M以上的就是高端内存

例如:
kmalloc需要连续20m空间，但是此时没有连续的20M空间，

- GFP_KERNEL会睡眠，直到有了20M空间为止
- GFP_ATOMIC则立即返回错误


如果kmalloc时候如果分配正确，则返回地址，如果错误，则返回错误编号

	kernelkmalloc = kmalloc(100, GFP_KERNEL)

	if (IS_ERR(kernelkmalloc)) 
	{
		printk("kmalloc failed!\n");
		return PTR_ERR(kernelkmalloc);
		/*PTR_ERR获取错误编号*/
	}

用IS_ERR来检测是否出错，使用PTR_ERR来获取错误编号


	unsigned long __get_free_pages(gfp_t gfp_mask, unsigned int order)

	void free_pages(unsigned long addr, unsigned int order)

gfp_mask与kmalloc中的flags相同涵义

order:请求或释放页数的2的幂

例如，申请1页order就是0，申请2页，oder就是1




	/*
	* memory.c
	*/
	#include <linux/init.h>
	#include <linux/module.h>
	#include <linux/slab.h>
	#include <linux/fs.h>
	#include <linux/vmalloc.h>
	
	MODULE_LICENSE("GPL");
	
	#define PAGE_NUM 4
	
	unsigned char* kernelkmalloc=NULL;
	unsigned char* kernelpagemem = NULL;
	unsigned char* kernelvmalloc = NULL;
	
	int __init kernelspace_init(void)
	{
	        int ret = -ENOMEM;
	        kernelkmalloc = (unsigned char*)kmalloc(100, GFP_KERNEL);
	        if (IS_ERR(kernelkmalloc)) {
	                printk("kmalloc failed!\n");
	                ret = PTR_ERR(kernelkmalloc);
	                goto failure_kmalloc;
	        }
	        printk("kmalloc space : 0x%lx!\n", (unsigned long)kernelkmalloc);
	
	        kernelpagemem = (unsigned char*)__get_free_pages(GFP_KERNEL, PAGE_NUM);
	
	        if (IS_ERR(kernelpagemem)) {
	                printk("get_free_pages failed!\n");
	                ret = PTR_ERR(kernelpagemem);
	                goto failure_get_free_pages;
	        }
	        printk("get_free_pages address: 0x%lx!\n", (unsigned long)kernelpagemem);
	
	        kernelvmalloc = (unsigned char*)vmalloc(1024*1024);
	
	        if (IS_ERR(kernelvmalloc)) {
	                printk("vmalloc failed!\n");
	                ret = PTR_ERR(kernelvmalloc);
	                goto failure_vmalloc;
	        }
	        printk("vmalloc address: 0x%lx!\n", (unsigned long)kernelpagemem);
	
	
	
	        return 0;
	failure_vmalloc:
	        free_pages((unsigned long)kernelpagemem, PAGE_NUM);
	failure_get_free_pages:
	        kfree(kernelkmalloc);
	failure_kmalloc:
	        return ret;
	
	
	}
	
	void __exit kernelspace_exit(void)
	{
	        vfree(kernelvmalloc);
	        free_pages((unsigned long)kernelpagemem, PAGE_NUM);
	        kfree(kernelkmalloc);
	
	}
	
	module_init(kernelspace_init);
	module_exit(kernelspace_exit);
	
可以看到分配的空间都是介于3G-4G之间的空间
