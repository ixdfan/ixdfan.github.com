---
layout: post
title:  IPC之共享内存
description: 
modified: 
categories: 
- LINUX
tags:
- 

---
共享内存是最高效的IPC机制，因为它不涉及进程之间的任何数据传输，但是这种高效带来的问题是，我们必须使用其他辅助手段来同步进程对共享内存的访问，否则会产生竞态条件，因此共享内存一般和其他进程间通信方式一起使用。


##### 共享内存编程模型:

* 创建共享内存得到一个ID(shmget)
* 挂载:将ID映射到虚拟地址上(shmat)
* 使用虚拟地址访问内核的共享内存
* 卸载:须在虚拟地址(shmdt)
* 删除:删除共享内存(shmctl)




	[root@ ~]# ipcs                                                                                                      
	
	------ Message Queues --------
	key        msqid      owner      perms      used-bytes   messages    
	
	------ Shared Memory Segments --------
	key        shmid      owner      perms      bytes      nattch     status      
	0x00000000 131072     root       600        393216     2          dest         
	0x00000000 229377     root       600        8388608    2          dest         
	0x00000000 458754     root       600        524288     2          dest         
	0x00000000 360451     root       600        1048576    2          dest         
	0x00000000 491524     root       600        4194304    2          dest         
	0x00000000 524293     root       600        393216     2          dest         
	0x00000000 622598     root       600        393216     2          dest         
	0x00000000 688136     root       600        2097152    2          dest         
	
	------ Semaphore Arrays --------
	key        semid      owner      perms      nsems     




其中Shared Memory Segments是共享内存的相关信息

shmid:共享内存id
owner:创建者
perms:权限
nattch:显示有几个进程挂载在共享内存上
status:共享内存状态



	int shmget(key_t key, size_t size, int shmflg);
	key:键值，用来标识一段全局唯一的共享内存
	size:共享内存的大小，单位是字节，如果是新创建共享内存，size必须指定大小;如果是获取已存在的共享内存则可以将size设置为0
	shmflg:支持SHM_HUGETLB和SHM_NORESERVE
	SHM_HUGETLB:类似mmap中的MAP_HUGETLB，系统将使用大页面来为共享内存分配空间
	SHM_NORESERVE:类似mmap的MAP_NORESERVE,不为共享内存保留交换分区(swap)，这样当物理内存不足的时候对该共享内存执行写操作将触发SIGSEGV信号;
	

##### 为什么需要key呢?
当A进程创建一个共享内存，同时返回一个ID，当B想要访问整个共性内存时候如何访问呢？A中得到的ID B进程无法知晓，但是只能通过ID去访问共享内存，因此A、B约定，B可以不使用A中的ID，而使用key即可。

A进程利用key来建立ID，B进程根据key得到的一定是A创建的ID！

整个key系统中唯一，key一旦确定，ID就确定了，使用key来产生ID，则整个key就与ID绑定到了一起。

通过key一定可以找到对应的ID，不会找到别人的ID，因此key是两进程间约定的访问共享内存的快捷方式，原因在于整个ID不确定，所以要通过一个定植来找到ID

#### 注意:
key需要具有唯一性，如果自己命名，无法保证key的唯一性，但是计算机中的文件与目录是唯一的，于是可以将其转化为一个唯一的整数，这个函数叫ftok，将一个文件转换为一个唯一的key，key是个整数

通常以项目目录作为产生key的共同凭证



	key_t ftok(const char *pathname, int proj_id);
	pathname:路径
	proj_id:整数控制因子，建议值0-255之间，用来保证产生唯一个ID


创建方法:
	key_t key;
	key = ftok(".", 255);
	int shmid;
	if (-1 == key) {
		shmid = shmget(key, 4, IPC_CREATE | IPC_EXECL | 0666);
		if (-1 == shmid) {
			
		}
	}
	
	
共享内存被创建/获取后，我们并不能立即访问它，而是需要首先将它关联到进程的地址空间中去，使用完共享内存后，我们也需要将它从进程地址空间中分离。

       void *shmat(int shmid, const void *shmaddr, int shmflg);
       int shmdt(const void *shmaddr);
	




