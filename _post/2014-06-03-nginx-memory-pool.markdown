---
layout: post
title:  nginx内存池
description: 
modified: 
categories: 
- nginx 
tags:
- 
---

#### 内存池的创建

nginx封装了一个ngx_pool_t类型的内存池.

内存池的初始函数


	20 #define NGX_MAX_ALLOC_FROM_POOL  (ngx_pagesize - 1)
	21 
	22 #define NGX_DEFAULT_POOL_SIZE    (16 * 1024)
	23 
	24 #define NGX_POOL_ALIGNMENT       16

	
内存池的创建

	16 ngx_pool_t *
	17 ngx_create_pool(size_t size, ngx_log_t *log)
	18 {
	19     ngx_pool_t  *p;
	20 
			/*	分配size大小的内存, 按照16字节对齐	*/
	21     p = ngx_memalign(NGX_POOL_ALIGNMENT, size, log);
	22     if (p == NULL) {
	23         return NULL;
	24     }
			/*	此时已经申请了内存区域,类型为ngx_pool_t,这样的一块内存就可以用作内存池的一个内存分配模块	*/
	25 
	26     p->d.last = (u_char *) p + sizeof(ngx_pool_t);	
			/*	最开始创建时,内存从last处分配,也就是从ngx_pool_t头结束位置开始分配	*/
			/*	成员初始化操作	*/
	27     p->d.end = (u_char *) p + size;		/*	可用的内存大小就是size, 但是开头部分被ngx_pool_t占用了	*/
	28     p->d.next = NULL;		/*	此时还没有别的节点	*/
	29     p->d.failed = 0;			/*	申请分配失败次数初始为0	*/
	30 
	31     size = size - sizeof(ngx_pool_t);
			/*	max的最大值为ngx_pageszie-1	*/
	32     p->max = (size < NGX_MAX_ALLOC_FROM_POOL) ? size : NGX_MAX_ALLOC_FROM_POOL;
	33 
	34     p->current = p;
	35     p->chain = NULL;
	36     p->large = NULL;
	37     p->cleanup = NULL; 
	38     p->log = log;
	39		/*	返回指向分配好的内存空间的指针	*/ 
	40     return p;
	41 }
	42 
	
	
	/*	如果定义了NGX_HAVE_POSIX_MEMALIGN或者是NGX_HAVE_MEMALIGN就执行对齐操作,否则就是简单的分配内存	*/
	29 #if (NGX_HAVE_POSIX_MEMALIGN || NGX_HAVE_MEMALIGN)
	30 
	31 void *ngx_memalign(size_t alignment, size_t size, ngx_log_t *log);
	32 
	33 #else
	34 
	35 #define ngx_memalign(alignment, size, log)  ngx_alloc(size, log)
	36 
	37 #endif

	49 #if (NGX_HAVE_POSIX_MEMALIGN)
  	50 
	51 void *
    52 ngx_memalign(size_t alignment, size_t size, ngx_log_t *log)
	53 {
	54     void  *p;
	55     int    err;
	56 
	57     err = posix_memalign(&p, alignment, size);
	58 
	59     if (err) {
	60         ngx_log_error(NGX_LOG_EMERG, log, err,
	61                       "posix_memalign(%uz, %uz) failed", alignment, size);
	62         p = NULL;
	63     }
	64 
	65     ngx_log_debug3(NGX_LOG_DEBUG_ALLOC, log, 0,
	66                    "posix_memalign: %p:%uz @%uz", p, size, alignment);
	67 
	68     return p;
	69 }
	70 
	71 #elif (NGX_HAVE_MEMALIGN)
	72 
	73 void *
	74 ngx_memalign(size_t alignment, size_t size, ngx_log_t *log)
	75 {
	76     void  *p;
	77 
	78     p = memalign(alignment, size);
	79     if (p == NULL) {
	80         ngx_log_error(NGX_LOG_EMERG, log, ngx_errno,
	81                       "memalign(%uz, %uz) failed", alignment, size);
	82     }
	83 
	84     ngx_log_debug3(NGX_LOG_DEBUG_ALLOC, log, 0,
	85                    "memalign: %p:%uz @%uz", p, size, alignment);
	86 
	87     return p;
	88 }
	89 
	90 #endif
	  

	/*	仅仅是简单的分配了内存	*/
	17 void *
	18 ngx_alloc(size_t size, ngx_log_t *log)
	19 {
	20     void  *p;
	21 
	22     p = malloc(size);		/*	不会进行对齐操作	*/
	23     if (p == NULL) {
	24         ngx_log_error(NGX_LOG_EMERG, log, ngx_errno,
	25                       "malloc(%uz) failed", size);
	26     }
	27 
	28     ngx_log_debug2(NGX_LOG_DEBUG_ALLOC, log, 0, "malloc: %p:%uz", p, size);
	29 
	30     return p;
	31 }


	/*	数据块结构同时该结构维护整个内存池中的各个节点	*/
	49 typedef struct {
	50     u_char               *last;		/*	当前内存分配结束位置,即下一段可分配内存的起始位置	*/
	51     u_char               *end;		/*	内存池结束位置	*/
	52     ngx_pool_t           *next;		/*	链接到下一个内存池	*/
	53     ngx_uint_t            failed;	/*	该内存池对于请求分配失败的次数	*/
	54 } ngx_pool_data_t;

	/*	该结构维护整个内存池的头部信息	*/
	57 struct ngx_pool_s {
	58     ngx_pool_data_t       d;			/*	数据块	*/
	59     size_t                max;		/*	数据块的大小,即小块内存的最大值	*/
	60     ngx_pool_t           *current;	/*	保存当前内存池的地址	*/
	61     ngx_chain_t          *chain;
	62     ngx_pool_large_t     *large;		/*	大块内存结构,超过max的内存请求都会在这里	*/
	63     ngx_pool_cleanup_t   *cleanup;	/*	内存池在释放的时候需要释放的资源	*/
	64     ngx_log_t            *log;
	65 };
	
![012]({{ site.img_url }}/2014/06/012.png)


可以看到创建的内存池被结构体ngx_pool_t占了开头的部分(额外开销overhead),nginx实际从该内存池里分配空间的起始位置从p->d.last开始,随着内存池空间的对外分配,last指向会向后移动.

========

#### 内存池的使用

内存池创建好之后如何向内存池申请内存空间呢?以下为从内存池中分配空间的函数

	/*	对外可用的就是前4个	*/
	/*	获取的内存是对齐的	*/
	void *ngx_palloc(ngx_pool_t *pool, size_t size)					
	/*	获取的内存不是对齐的	*/
	void *ngx_pnalloc(ngx_pool_t *pool, size_t size)
	/*	直接调用ngx_palloc,然后执行清零操作	*/
	void *ngx_pcalloc(ngx_pool_t *pool, size_t size)
	/*	分配size大小内存,并按照alignment对齐,然后挂载到pool中的large下	*/
	void *ngx_pmemalign(ngx_pool_t *pool, size_t size, size_t alignment)
	/*	被static修饰,一般就是内掉函数,不会被外部使用	*/
	static void *ngx_palloc_block(ngx_pool_t *pool, size_t size);
	static void *ngx_palloc_large(ngx_pool_t *pool, size_t size);



		/*  向上取整, 对齐内存指针,加快存取速度	*/
	99 #define ngx_align_ptr(p, a)                                                   \
	100     (u_char *) (((uintptr_t) (p) + ((uintptr_t) a - 1)) & ~((uintptr_t) a - 1))

	/*	ngx_palloc是从pool内存池中分配size大小的内存空间	*/
	116 void *
	117 ngx_palloc(ngx_pool_t *pool, size_t size)
	118 {
	119     u_char      *m;
	120     ngx_pool_t  *p;
	121 
			/*	
			*	要分配的空间size <= pool->max,即小于等于内存池总大小或者说是1页内存(4k-1)
			*	那么就可以从内存池中分配,这个分配的内存不一定来自当前内存池节点
			*	因为可能当前内存池里可用内存空间大小小于size,此时需要调用ngx_palloc_large申请一个新的同等大小的内存池节点
			*	然后从这个内存池节点里分配储size大小的内存空间
			*/
	122     if (size <= pool->max) {		/*	如果分配小块内存	*/
	123 
	124         p = pool->current;			
				/*	
				*	从pool->current指针指向的内存池(链表)节点开始使用循环遍历以后的各个节点,
				*	找到满足申请大小的内存空间
				*/
	125 
	126         do {
					/*	对齐处理	*/
					/*	#define NGX_ALIGNMENT sizeof(unsigned long )	*/
					/*	此时m为p->d.last开始的对齐NGX_ALIGNMENT的内存地址	*/
	127             m = ngx_align_ptr(p->d.last, NGX_ALIGNMENT);
	128 
	129             if ((size_t) (p->d.end - m) >= size) {		/*	如果可以分配的空间满足申请的大小size就直接分配	*/
	130                 p->d.last = m + size;
	131 
	132                 return m;
	133             }
	134 
	135             p = p->d.next;	/*	去下一个节点中去寻找	*/
	136 
	137         } while (p);		/*	没有找到的话	*/	
	138 		/*	重新进行内存块(节点)的分配	*/
	139         return ngx_palloc_block(pool, size);
	140     }
	141		/*	大块内存的分配	*/ 
	142     return ngx_palloc_large(pool, size);
	143 }


##### ngx_palloc_block主要做两件事情:

#####1. 将新内存池节点链接到上一个内存池节点的p->d.next字段下形成单链表
	
新链表节点的加入是在链表尾部加入的,并且我们可以看到新建立的内存池节点的overhead都只有结构体ngx_pool_data_t,因为一个内存池没有必要有多个ngx_pool_t结构,一个ngx_pool_t维护整个(单个链表所有节点)内存池的头部结构

#####2. 根据需要移动内存池描述结构体ngx_pool_t的current字段

这个字段记录了后续从该内存池分配内存的起始内存池节点,也就是说从这个字段指向的内存池节点开始搜索可以分配的内存

	/*	在pool内存池中新分配一个块节点	*/
	176 static void *
	177 ngx_palloc_block(ngx_pool_t *pool, size_t size)
	178 {
	179     u_char      *m;
	180     size_t       psize;
	181     ngx_pool_t  *p, *new, *current;
	182		/*	psize为pool节点的大小,并且这个pool应该是首节点的位置	*/ 
	183     psize = (size_t) (pool->d.end - (u_char *) pool);
	184		/*	分配psize大小的内存空间形成新的节点	*/ 
	185     m = ngx_memalign(NGX_POOL_ALIGNMENT, psize, pool->log);
	186     if (m == NULL) {
	187         return NULL;
	188     }
	189		/*	new是新分配节点的地址	*/ 
	190     new = (ngx_pool_t *) m;
	191 
	192     new->d.end = m + psize;
	193     new->d.next = NULL;
	194     new->d.failed = 0;
	195 
	196     m += sizeof(ngx_pool_data_t);
	197     m = ngx_align_ptr(m, NGX_ALIGNMENT);	/*	对齐操作,m此时为可供使用的内存的起始地址	*/
	198     new->d.last = m + size;					/*	分配之前分配失败的size	*/
	199 
	200     current = pool->current;
	201 
	202     for (p = current; p->d.next; p = p->d.next) {
				/*	p->d.failed从0开始的, 0, 1, 2, 3, 4, 5,共6个数,
				*	所以如果从当前内存池节点分配内存总失败次数大于等于6次
				*	就将current字段移动到下一个内存池节点,如果下一个内存池节点failed也大于等于6次,在找下一个
				*	如果最后一个仍然是failed次数大于等于6次,那么current字段则指向刚刚新分配的内存池节点
				*/
	203         if (p->d.failed++ > 4) {
	204             current = p->d.next;
	205         }
	206     }
	207		/*	将新分配节点挂接在链表的末尾	*/ 
	208     p->d.next = new;
	209		/*	如果最后一个失败次数failed>5,那么将current指向新的节点	*/ 
	210     pool->current = current ? current : new;
	211 	/*	返回新分配节点m	*/
	212     return m;		
	213	}


![013]({{ site.img_url }}/2014/06/013.png)
	
	/*	大块内存的分配	*/
	216 static void *
	217 ngx_palloc_large(ngx_pool_t *pool, size_t size)
	218 {
	219     void              *p;
	220     ngx_uint_t         n;
	221     ngx_pool_large_t  *large;
	222 	/*	直接分配需要的内存大小,size>max	*/
	223     p = ngx_alloc(size, pool->log);
	224     if (p == NULL) {
	225         return NULL;
	226     }
	227 
	228     n = 0;
	229 
	230     for (large = pool->large; large; large = large->next) {
	231         if (large->alloc == NULL) {
	232             large->alloc = p;		/*	将新分配的大块内存挂接到pool->large->alloc字节上	*/
	233             return p;
	234         }
	235			/*	
				*	该段代码循环三次,如果在三次内碰到大块内存链表上某个节点为NULL,
				*	那么就直接将各个节点的数据指向上面申请好的空间并返回	
				*/ 
	236         if (n++ > 3) {
	237             break;
	238         }
	239     }
	240		/*	如果大块内存链表上节点数超过3个,就不再向后遍历
			*	直接重新申请一块大小为ngx_pool_large_t结构体大小内存,建立一个新的节点
			*/ 
			/*	可是如果有节点(超过3)释放了内存怎么办??	*/
	241     large = ngx_palloc(pool, sizeof(ngx_pool_large_t));
	242     if (large == NULL) {
	243         ngx_free(p);
	244         return NULL;
	245     }
	246 	/*	将申请好的节点插入到大内存链表的开头,返回申请的内存空间起始地址 */
	247     large->alloc = p;			/*	p接入到节点large->alloc内	*/
	248     large->next = pool->large;	/*	链表的插入	*/
	249     pool->large = large;
	250 	
	251     return p;
	252 }

![014]({{ site.img_url }}/2014/06/014.png)



##### 为什么要将pool->max字段的最大值限制在一页内存??

这个字段是区分小块内存与大块内存的临界,所以原因在于只有当分配的内存空间小于一页时候才有缓存的必要(想内存池去申请),否则的话还不如直接利用系统函数malloc想操作系统申请

========

#### 内存池的销毁

	32 typedef struct ngx_pool_cleanup_s  ngx_pool_cleanup_t;
	33 
	34 struct ngx_pool_cleanup_s {
	35     ngx_pool_cleanup_pt   handler;	/*	handler是对数据进行处理的数据处理函数	*/
	36     void                 *data;		/*	要清除的数据	*/
	37     ngx_pool_cleanup_t   *next;  	/*	下一个将要被清除的内存数据	*/
	38 };
	39 
	40 
	41 typedef struct ngx_pool_large_s  ngx_pool_large_t;
	42 
	43 struct ngx_pool_large_s {
	44     ngx_pool_large_t     *next;
	45     void                 *alloc;
	46 };
	
	44 void
	45 ngx_destroy_pool(ngx_pool_t *pool)
	46 {
	47     ngx_pool_t          *p, *n;
	48     ngx_pool_large_t    *l;
	49     ngx_pool_cleanup_t  *c;
	50 
			/*	遍历内存池的各个节点的清除处理函数,然后调用清除函数完成数据的清理	*/
	51     for (c = pool->cleanup; c; c = c->next) {
	52         if (c->handler) {	/*	c->handler是回调函数	*/
	53             ngx_log_debug1(NGX_LOG_DEBUG_ALLOC, pool->log, 0,
	54                            "run cleanup: %p", c);
	55             c->handler(c->data);
	56         }
	57     }
	58 
			/*	释放大内存	*/
	59     for (l = pool->large; l; l = l->next) {
	60 
	61         ngx_log_debug1(NGX_LOG_DEBUG_ALLOC, pool->log, 0, "free: %p", l->alloc);
	62 
	63         if (l->alloc) {		/*	释放节点占用的内存空间	*/
	64             ngx_free(l->alloc);
	65         }
	66     }
	67 
	68 #if (NGX_DEBUG)
	69 
	70     /*
	71      * we could allocate the pool->log from this pool
	72      * so we cannot use this log while free()ing the pool
	73      */
	74 
	75     for (p = pool, n = pool->d.next; /* void */; p = n, n = n->d.next) {
	76         ngx_log_debug2(NGX_LOG_DEBUG_ALLOC, pool->log, 0,
	77                        "free: %p, unused: %uz", p, p->d.end - p->d.last);
	78 
	79         if (n == NULL) {
	80             break;
	81         }
	82     }
	83 
	84 #endif
	85 
			/*	将内存池本身的空间释放掉,或者叫做释放各个内存池节点	*/
	86     for (p = pool, n = pool->d.next; /* void */; p = n, n = n->d.next) {
	87         ngx_free(p);
	88 
	89         if (n == NULL) {
	90             break;
	91         }
	92     }
	93 }
	94 

	19 #define ngx_free          free	/*	就是简单的free	*/
不管通过哪种方式申请的内存,都使用这个函数来释放,对于在各个不同的场合下从内存池中申请的内存空间释放的时机是不一样的,并且只有大数据内存才能直接调用ngx_free来进行释放,其他的释放都要交给内存池销毁

可以看到nginx仅仅提供对大块内存的释放(ngx_free),二没有提供对小块内存的释放,这就以为着从内存池中分配出去的内存不会在回收到内存池中,而只有在销毁整个内存池时候,所有这些内存才会回收到系统内存中去;

这样设计的原因在与服务器应用特殊性,即阶段与时效,对于其处理的业务逻辑有明确的阶段,而每一节点又有明确的时效,所以nginx可以针对阶段来分配内存池,针对时效来销毁内存池,例如:当一个阶段(例如request处理)开始就创建对应的内存池,而当这个阶段结束后就销毁其对应的内存池,由于这个阶段有严格的时效性,即在一段时间后,一定会因正常处理或异常错误或超时等原因二结束,所以不会出现nginx长时间占据大量无用内存池的情况,所以在其阶段过程中没有必要去回收小块内存,最后结束时候一起回收更加方便

	/*	内存池重置函数	*/
	96 void
	97 ngx_reset_pool(ngx_pool_t *pool)
	98 {
	99      ngx_pool_t        *p;
	100     ngx_pool_large_t  *l;
	101		/*	首先将挂接在大块内存释放	*/ 
	102     for (l = pool->large; l; l = l->next) {
	103         if (l->alloc) {
	104             ngx_free(l->alloc);
	105         }
	106     }
	107 
	108     pool->large = NULL;		/*	重置	*/
	109 
			/*	将last指针指向刚刚分配时候的位置	*/
	110     for (p = pool; p; p = p->d.next) {
	111         p->d.last = (u_char *) p + sizeof(ngx_pool_t);
	112     }
			/*	其他的内存不用改变,在使用的过程中会被覆盖	*/
	113 }

	

