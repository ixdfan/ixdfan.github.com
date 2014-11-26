---
layout: post
title:  nginx的slab机制
description: 
modified: 
categories: 
- nginx
tags:
- 
---

Nginx的slab机制主要是两点:缓存与对齐;

缓存就是预先分配,提前申请号内存并对被踩做好划分形成内存池;

对齐就是内存的申请与分配总是按照2的幂次方进行,即内存的大小总是8,16,32,64等,例如虽然只申请33个字节内存,但是还是会分撇64字节大小的内存,虽然会浪费内存,但是对于性能有一个很高的提升,并且将内存碎片掌握在可控的范围之内.


nginx的slab机制主要是和共享内存一起使用,对于共享内存,nginx在解析配置文件时候,将即将使用的共享内存全部以list链表的形式组织在全局变量cf->cycle->shared_memory,然后进行统一的内存分配.slab机制就是对这些内存进行进一步的内部划分与管理


	917 static ngx_int_t
	918 ngx_init_zone_pool(ngx_cycle_t *cycle, ngx_shm_zone_t *zn)
	919 {
	920     u_char           *file;
	921     ngx_slab_pool_t  *sp;
	922 
	923     sp = (ngx_slab_pool_t *) zn->shm.addr;
	924 
	925     if (zn->shm.exists) {
	926 
	927         if (sp == sp->addr) {
	928             return NGX_OK;
	929         }
	930 
	931         ngx_log_error(NGX_LOG_EMERG, cycle->log, 0,
	932                       "shared zone \"%V\" has no equal addresses: %p vs %p",
	933                       &zn->shm.name, sp->addr, sp);
	934         return NGX_ERROR;
	935     }
	936 
	937     sp->end = zn->shm.addr + zn->shm.size;
	938     sp->min_shift = 3;
	939     sp->addr = zn->shm.addr;
	940 
	941 #if (NGX_HAVE_ATOMIC_OPS)
	942 
	943     file = NULL;
	944 
	945 #else
	946 
	947     file = ngx_pnalloc(cycle->pool, cycle->lock_file.len + zn->shm.name.len);
	948     if (file == NULL) {
	949         return NGX_ERROR;
	950     }
	951 
	952     (void) ngx_sprintf(file, "%V%V%Z", &cycle->lock_file, &zn->shm.name);
	953 
	954	#endif (ngx_shmtx_create(&sp->mutex, &sp->lock, file) != NGX_OK) {
	957         return NGX_ERROR;
  	958     }
   	959 
			/*	调用slab初始化操作	*/
    960     ngx_slab_init(sp);
	961 
	962     return NGX_OK;
   	963 }

ngx_init_zone_pool是在共享内存分配好之后进行的初始化调用,在函数中又会调用slab的初始化函数ngx_slab_init

	25 typedef struct {
	26     ngx_shmtx_sh_t    lock;
	27 
	28     size_t            min_size;			/*	固定值为8,最小划分块的大小,即1 << pool->min_shift	*/
	29     size_t            min_shift;			/*	固定值为3	*/
	30     
	31     ngx_slab_page_t  *pages;
	32     ngx_slab_page_t   free;
	33 
	34     u_char           *start;
	35     u_char           *end;
	36 
	37     ngx_shmtx_t       mutex;
	38 
	39     u_char           *log_ctx;
	40     u_char            zero;
	41 
	42     void             *data;
	43     void             *addr;
	44 } ngx_slab_pool_t;
	

共享内存的初始化布局图:

![001]({{ site.img_url }}/2014/06/001.png)

根据图片可以看到共享内存的开始部分内存已经被用作结构体ngx_slab_pool_t的存储空间,这相当于是slab的额外开销,因为任何一种管理机制都需要有自己的一些控制信息需要存储,所以这些内存的使用无法避免. 剩下的内存才是被管理的主体.

slab机制对内存进行两级管理,首先是page页,然后是page页内的slab块(简称为slot块),也就是说slot块是在page页内存的再一次管理

	76 void
	77 ngx_slab_init(ngx_slab_pool_t *pool)
	78 {
	79     u_char           *p;
	80     size_t            size;
	81     ngx_int_t         m;
	82     ngx_uint_t        i, n, pages;
	83     ngx_slab_page_t  *slots;
	84 
	85     /* STUB */

			/*	ngx_slab_max_size是slots分配和pages分配的分隔点,
			*	大于等于该值则要从pages里分配,其值为2048
			*/
	86     if (ngx_slab_max_size == 0) {		
	87         ngx_slab_max_size = ngx_pagesize / 2;
				/*	
				*	ngx_slab_exact_size的值为128,刚好能用一个uintptr_t类型的位图变量表示该页的划分;
				*	例如在4k的内存页,32位环境下,一个uintptr_t类型的位图变量最多可以对应表达32个划分块的状态
				*	所以要恰好完整的表示一个4K内存页的每一个划分块状态,	
				*	必须将这个4K内存页划分成32个块,即每块的大小为128
				*/
	88         ngx_slab_exact_size = ngx_pagesize / (8 * sizeof(uintptr_t));
	89         for (n = ngx_slab_exact_size; n >>= 1; ngx_slab_exact_shift++) {
	90             /* void */
	91         }
	92     }
	93     /**/
	94 
	95     pool->min_size = 1 << pool->min_shift;
	96 
	97     p = (u_char *) pool + sizeof(ngx_slab_pool_t);
	98     size = pool->end - p;
	99 
	100     ngx_slab_junk(p, size);
	101 
	102     slots = (ngx_slab_page_t *) p;
			/*	ngx_pagesize_shift值为12,对应ngx_pagesize(4096), 即4096=1<<12	*/
	103     n = ngx_pagesize_shift - pool->min_shift;
	104 
	105     for (i = 0; i < n; i++) {
	106         slots[i].slab = 0;
	107         slots[i].next = &slots[i];
	108         slots[i].prev = 0;
	109     }
	110 
	111     p += n * sizeof(ngx_slab_page_t);
	112 
	113     pages = (ngx_uint_t) (size / (ngx_pagesize + sizeof(ngx_slab_page_t)));
	114 
	115     ngx_memzero(p, pages * sizeof(ngx_slab_page_t));
	116 
	117     pool->pages = (ngx_slab_page_t *) p;
	118 
	119     pool->free.prev = 0;
	120     pool->free.next = (ngx_slab_page_t *) p;
	121 
	122     pool->pages->slab = pages;
	123     pool->pages->next = &pool->free;
	124     pool->pages->prev = (uintptr_t) &pool->free;
	125 
	126     pool->start = (u_char *)
	127                   ngx_align_ptr((uintptr_t) p + pages * sizeof(ngx_slab_page_t),
	128                                  ngx_pagesize);
	129 
			/*	
			*	在末尾如果不够一个page内存页,则会被浪费掉
			*	一下代码是对最终可用内存的调整
			*/
	130     m = pages - (pool->end - pool->start) / ngx_pagesize;
			/*	m > 0则说明对齐操作导致实际可用的内存页减少*/
	131     if (m > 0) {
	132         pages -= m;			/*	pages去掉多出的部分,则刚好组成实际最终可用的pages的个数	*/
	133         pool->pages->slab = pages;
	134     }
	135 
	136     pool->log_ctx = &pool->zero;
	137     pool->zero = '\0';
	138 }


slab机制对page页的管,初始结构如图:

![002]({{ site.img_url }}/2014/06/002.png)

#### page的静态管理
slab对page页的静态管理主要体现在ngx_slab_page_t[K]和page[K]这两个数组上;

	16 typedef struct ngx_slab_page_s  ngx_slab_page_t;
	17 
	18 struct ngx_slab_page_s {
	19     uintptr_t         slab;
	20     ngx_slab_page_t  *next;
	21     uintptr_t         prev;
	22 };
	23 
	
	
##### 注意:
1.对齐是指实际page内存页按照ngx_pagesize大小对齐,从图中可以看到,原本start是那个虚线箭头的位置,对齐后就是实现箭头所在的位置,对齐能提高对内存页的访问速度,但是有一些内存浪费,并且末尾可能因为不够一个page内存页而被浪费掉(因为对齐的缘故),所以在ngx_slab_init函数的最末尾有一次最终可用内存页的准确调整.

2.虽然一个页面管理结构(ngx_slab_page_t元素)与一个page内存页相对应,但因为有对齐消耗以及slot块管理结构体的占用(ngx_slab_page_t[n]数组),所以实际上页管理街头体数目比page页内存数目要多,即图中ngx_slab_page_t[N]到ngx_slab_pool_t[K-1]实际上没有对应的page页,所以这部分将会被忽视,虽然他们是存在的.

#### page的动态管理

动态管理即page页的申请和释放;

page页被申请或释放,那么就有了响应的状态,使用或空闲状态;

##### page空闲状态的管理

nginx对空闲page页进行链式管理,链表的头节点pool->free,初始状态下链表如图:

![003]({{ site.img_url }}/2014/06/003.png)

这是一个特别的链表,它的节点是一个数组,例如图中的ngx_slab_page_t数组就是一个链表节点,这个数组通过0号数组元素ngx_slab_page_t[0]接入到这个空闲page页链表内,整个数组的元素个数也记录在第0号元素的slab字段内


子进程1从共享内存中申请1页,状态如图:

![004]({{ site.img_url }}/2014/06/004.png)

子进程2从共享内存中申请2页,状态如图:

![005]({{ site.img_url }}/2014/06/005.png)

子进程有释放刚刚申请的1页

![006]({{ site.img_url }}/2014/06/006.png)

**释放page页被插入到链表头部**,如果子进程2接着释放其拥有的那2页内存,如图:

![007]({{ site.img_url }}/2014/06/007.png)

可以看到nginx对空闲page页的链式管理不会进行节点合并,不过没有关系,因为page也既不是slab机制的最小管理单元,也不是其主要分配单元


#### slab的第二级管理--slot块

slot块是对每一个page内存的内部管理,它将page页划分成很多个小块,各个page页的slot块大小可以不相等,但是同一个page页内slot块大小一定相等,page页的状态通过其所在链表即可表明是否空闲,但是page页内的各个slot块的状态却需要一个额外的标记,nginx中具体实现采用的是位图,即每个bit位标记一个对应slot块的状态,1为使用,0未空闲.

根据slot块大小的不同,每个page页可划分的slot块数也不同,从而需要的位图的大小也不同,每一个page页对应一个名为ngx_slab_page_t的管理结构,该结构体有一个uintptr_t类型的slab字段,在32位平台上uintptr_t占4个字节,即slba字段有32个bit位,如果page页划分的slot块数小于等于32,那么nginx直接利用该字段充当位图,在nginx内叫做exact划分,每个slot块的大小保存在全局变量ngx_slab_exact_size以及ngx_slab_exact_shift内.例如一个4k的page页,如果每个slot块大小为128字节,那么恰好可以分成32块.如图:


![008]({{ site.img_url }}/2014/06/008.png)

如果划分的每个slot块比ngx_slab_exact_size还大,那么意味着一个page也划分的slot块数更少,所以此时依然可以使用ngx_slab_page_t结构体的slab字段作为位图,但是由于比ngx_slab_exact_size大的情况有很多种,因此需要将其具体大小记录下来,这个值同样记录在slab字段内.怎么记录呢?由于划分的时候是按照2的幂次方进行增长的,所以比ngx_slab_exact_size还大,那至少是ngx_slab_exact_size的2倍,那么此时划分的至少要减少slot块的一半,因此利用slab字段的一般bit位即可完成表示所有slot块的状态;

具体的就是:slab字段的高端bit做位图,低端bit用于存储slot块大小.


如果申请的内存大于等于ngx_slab_max_size,那么nginx直接返回一个page整页,此时已经不存在slot块管理了

如果申请小于ngx_slab_exact_size时候,此时slot块的数目已经超过了slab位图可以表示的容量,比如按照8字节划分,那么1个4K的page页将会被划分成512块,表示slot块状态的位图也就需要512个bit位,一个slab字段明显是不够的,所以需要为位图另找存储空间,而slab字段仅仅用于存储slot块大小(仅仅存储其对应的位移数).

另找的位图存储空间就落在page页内,具体就是其划分的前面几个slot块内,例如512个bit位的位图即64字节,而一个slot块内有8个字节,所以就需要占用page页的前8个slot块做位图,一个按8字节划分slot块的page页初始状态如图:


![009]({{ site.img_url }}/2014/06/009.png)

由于前几个slot块一开始就被用作位图空间,所以必须将其对应的bit位设置为1,表示其状态为使用.其划分大小在slab字段内!

不论哪种情况,都有了slot块的大小以及状态,这样分配与释放就简单了!

#### page的链式管理

首先根据每页划分的slot块大小将各个page页加入到不同的链表内,即按照8,16,32,64,128,256,512,1024,2048一共是9条链,在ngx_slab_init中有对应的初始化

假设申请一块9字节的内存,那么slab机制将一共分配page那么多页,将它按照8字节做slot划分,并接入到链表slot[0]中

继续申请8字节的内存不会分配新的page页,除非刚刚那页pageA被使用完了,一旦页A被使用完了,它会被拆除链表

![010]({{ site.img_url }}/2014/06/010.png)

如果继续申请8字节的内存,那么nginx的slab机制必须分配新的page页(简称页B),此时页B会被加入到链表内,此时链表中只有一个节点,但是如果此时页A释放了末个slot块,它又会被加入到链表内,最终形成了两个节点的链表

![011]({{ site.img_url }}/2014/06/011.png)
