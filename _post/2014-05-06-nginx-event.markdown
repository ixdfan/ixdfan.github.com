---
layout: post
title:  Nginx的IO多路复用
description: 
modified: 
categories: 
- nginx
tags:
- 
---

Nginx是以事件驱动的，也就是说nginx内部流程向前推进基本都是靠各种事件的发生来驱动，否则nginx将一直阻塞在函数epoll_wait和sigsuspend这样的系统调用上，nginx工作进程关注的事件有两类:IO事件与定时器事件。

##### IO复用模型
无论是哪种IO复用模型，基本原理都是相同的，他们都能让应用程序同时对多个IO端口进行监控以判断其上的操作是否可以进行，达到时间复用的目的(单位时间内，可以同时监控很多)。

这个例子非常的形象:

如果要监控10根来自不同地方的水管(IO端口)是否有水流达到(是否可读)，那么需要10个人来做这件事情(10个线程或10处代码)，如果利用某种技术(比如摄像头)把10根水管的状态统一传达到某个点，那么就只需要1人在那个点进行监控就行了，类似于select或是epoll这样的多路IO复用机制就好比是摄像头的功能，他们能把多个IO端口的情况反馈到同一处，比如某个特定的文件描述符上，这样应用程序只需要对应的select或是epoll_wait调用阻塞关注这一处即可.


不同平台支持不同的IO多路复用模型，Nginx对这些IO多路复用模型进行封装和使用，IO多路复用模型被封装在一个叫做ngx_event_atcionts_t的结构体中，该结构体中包含的字段主要就是回调函数

	230 typedef struct {
		
			/*	将某个描述符的某个事件(可读/可写)添加到多路复用的监控	*/
	231     ngx_int_t  (*add)(ngx_event_t *ev, ngx_int_t event, ngx_uint_t flags);
			/*	将某个描述符的某个事件(可读/可写)从多路复用的监控中删除	*/
	232     ngx_int_t  (*del)(ngx_event_t *ev, ngx_int_t event, ngx_uint_t flags);
	233	
			/*	启用对某个事件的监控	*/
	234     ngx_int_t  (*enable)(ngx_event_t *ev, ngx_int_t event, ngx_uint_t flags);

			/*	禁用对某个指定事件的监控	*/
	235     ngx_int_t  (*disable)(ngx_event_t *ev, ngx_int_t event, ngx_uint_t flags);
	236 
			/*	将指定连接关联的描述符加入到多路复用监控里	*/
	237     ngx_int_t  (*add_conn)(ngx_connection_t *c);

			/*	将指定连接关联的描述符从多路复用监控里删除	*/
	238     ngx_int_t  (*del_conn)(ngx_connection_t *c, ngx_uint_t flags);
		
	239		/*	仅仅对kqueue才会用到这个接口，所以没什么用	*/ 
	240     ngx_int_t  (*process_changes)(ngx_cycle_t *cycle, ngx_uint_t nowait);
				
			/*	阻塞等待时间发生，对发生的时间进行逐个处理	*/
	241     ngx_int_t  (*process_events)(ngx_cycle_t *cycle, ngx_msec_t timer,
	242                    ngx_uint_t flags);
	243 
			/*	初始化	*/
	244     ngx_int_t  (*init)(ngx_cycle_t *cycle, ngx_msec_t timer);
			/*	回收资源	*/
	245     void       (*done)(ngx_cycle_t *cycle);
	246 } ngx_event_actions_t;
	247 
	248 
	249 extern ngx_event_actions_t   ngx_event_actions;

由于多路复用模型各自具体的实现不同，上面列出的接口可能在Nginx的IO多路复用处理模块里没有对应的处理，但几个最近本的接口例如add/del/process_events肯定会有实现的。

为了方便使用任何一种事件处理机制，Nginx定义一个类型为ngx_event_actions_t的全局变量ngx_event_actions，并且定义了几个宏


	448 #define ngx_process_changes  ngx_event_actions.process_changes
	449 #define ngx_process_events   ngx_event_actions.process_events
	450 #define ngx_done_events      ngx_event_actions.done
	451 
	452 #define ngx_add_event        ngx_event_actions.add
	453 #define ngx_del_event        ngx_event_actions.del
	454 #define ngx_add_conn         ngx_event_actions.add_conn
	455 #define ngx_del_conn         ngx_event_actions.del_conn


这样Nginx要将某个时间添加到多路复用监控里，只需要调用ngx_add_event()即可，至于这个函数对应到哪个具体的IO多路复用模块上，就不必关心！

ngx_add_event()函数是如何关联到具体的IO多路复用处理模块上的呢？

关键在于全局变量ngx_event_actions的值，为全局变量ngx_event_actions进行赋值出现在各个时间处理模块的初始化函数内,例如epoll模块。

	491 typedef struct {
	492     ngx_str_t              *name;
	493 
	494     void                 *(*create_conf)(ngx_cycle_t *cycle);
	495     char                 *(*init_conf)(ngx_cycle_t *cycle, void *conf);
	496 
	497     ngx_event_actions_t     actions;	/*	action的定义在上面，成员主要是一些回调函数	*/
	498 } ngx_event_module_t;



	149 ngx_event_module_t  ngx_epoll_module_ctx = {
	150     &epoll_name,
	151     ngx_epoll_create_conf,               /* create configuration */
	152     ngx_epoll_init_conf,                 /* init configuration */
	153     
	154     {
				/*	与ngx_event_actions_t中的函数一一对应	*/
	155         ngx_epoll_add_event,             /* add an event */
	156         ngx_epoll_del_event,             /* delete an event */
	157         ngx_epoll_add_event,             /* enable an event */
	158         ngx_epoll_del_event,             /* disable an event */
	159         ngx_epoll_add_connection,        /* add an connection */
	160         ngx_epoll_del_connection,        /* delete an connection */
	161         NULL,                            /* process the changes */
	162         ngx_epoll_process_events,        /* process the events */
	163         ngx_epoll_init,                  /* init the events */
	164         ngx_epoll_done,                  /* done the events */
	165     }
	166 };  



	288 static ngx_int_t
	289 ngx_epoll_init(ngx_cycle_t *cycle, ngx_msec_t timer)
	290 {
	291     ngx_epoll_conf_t  *epcf;
	292 
	293     epcf = ngx_event_get_conf(cycle->conf_ctx, ngx_epoll_module);
	294 
	295     if (ep == -1) {
	296         ep = epoll_create(cycle->connection_n / 2);
	297 
	298         if (ep == -1) {
	299             ngx_log_error(NGX_LOG_EMERG, cycle->log, ngx_errno,
	300                           "epoll_create() failed");
	301             return NGX_ERROR;
	302         }
	303 
	304 #if (NGX_HAVE_FILE_AIO)
	305 
	306         ngx_epoll_aio_init(cycle, epcf);
	307 
	308 #endif
	309     }
	310 
	311     if (nevents < epcf->events) {
	312         if (event_list) {
	313             ngx_free(event_list);
	314         }
	315 
	316         event_list = ngx_alloc(sizeof(struct epoll_event) * epcf->events,
	317                                cycle->log);
	318         if (event_list == NULL) {
	319             return NGX_ERROR;
	320         }
	321     }
	322 
	323     nevents = epcf->events;
	324 
	325     ngx_io = ngx_os_io;
	326 
			/*	全局变量关联上来了,这个ngx_epoll_module_ctx.action是一个结构体	*/
	327     ngx_event_actions = ngx_epoll_module_ctx.actions;
	328 
	329 #if (NGX_HAVE_CLEAR_EVENT)
	330     ngx_event_flags = NGX_USE_CLEAR_EVENT
	331 #else
	332     ngx_event_flags = NGX_USE_LEVEL_EVENT
	333 #endif
	334                       |NGX_USE_GREEDY_EVENT
	335                       |NGX_USE_EPOLL_EVENT;
	336 
	337     return NGX_OK;
	338 }


327行就是对epoll模块的ngx_event_actions赋值，而在其他时间处理模块的初始化函数内也可以看到这样的赋值语句，所以一旦指定了nginx使用某个事件处理模块，经过事件处理模块的初始化后，就把全局变量ngx_event_actions指向了他的封装，比如ngx_add_event()调用的就是上面的ngx_epoll_add_event()函数

设定nginx使用那个事件处理机制是通过在event块中使用use指令来指定的，该配置指令对应的处理函数为ngx_event_use()函数


经过相关验证，比如检验该指定模块是否存在后，就会将对应的事件处理模块序号记录到efc->use中，如果不进行主动指定，则nginx会根据当前系统平台选择一个合适的事件处理模块，并且同样把模块序号记录在efc->use中，相关函数是ngx_event_core_init_conf

工作进程的初始化函数ngx_worker_process_init函数中会调用时间核心模块的初始化函数ngx_event_process_init,在该函数中根据ecf->use的值来调用对应的时间处理模块的初始化函数,例如epoll模块的ngx_epoll_init模块



	584 ngx_event_process_init(ngx_cycle_t *cycle)
	585 {
	586     ngx_uint_t           m, i;
	587     ngx_event_t         *rev, *wev;
	588     ngx_listening_t     *ls;
	589     ngx_connection_t    *c, *next, *old;
	590     ngx_core_conf_t     *ccf;
	591     ngx_event_conf_t    *ecf;
	592     ngx_event_module_t  *module;
	593 
	594     ccf = (ngx_core_conf_t *) ngx_get_conf(cycle->conf_ctx, ngx_core_module);
	595     ecf = ngx_event_get_conf(cycle->conf_ctx, ngx_event_core_module);
	596 
	597     /*  
	598      *      1。只有在多进程的模型下
	599      *      2. worker进程数大于1
	600      *      3. 手动开启负载均衡     如果没有指定，则默认设置为开启模式
	601      *      满足以上三个条件才会开启负载均衡
	602     */
	603     if (ccf->master && ccf->worker_processes > 1 && ecf->accept_mutex) {
	604         ngx_use_accept_mutex = 1;   /*  开启负载均衡    */
	605         ngx_accept_mutex_held = 0;
	606         ngx_accept_mutex_delay = ecf->accept_mutex_delay;
	607 
	608     } else {
	609         ngx_use_accept_mutex = 0;   /*  没有开启    */
	610     }
	611 
	612 #if (NGX_THREADS)
	613     ngx_posted_events_mutex = ngx_mutex_init(cycle->log, 0);
	614     if (ngx_posted_events_mutex == NULL) {
	615         return NGX_ERROR;
	616     }
	617 #endif
	618 
	619     if (ngx_event_timer_init(cycle->log) == NGX_ERROR) {
	620         return NGX_ERROR;
	621     }
	622 
				/*	遍历查找对应的模块	*/
	623     for (m = 0; ngx_modules[m]; m++) {
				/*	首先类型要为NGX_EVENT_MODULE	*/
	624         if (ngx_modules[m]->type != NGX_EVENT_MODULE) {
	625             continue;
	626         }
	627 
	628         /*  然后在同类模块中的编号要相等 */
	629         if (ngx_modules[m]->ctx_index != ecf->use) {
	630             continue;
	631         }
	632 
	633         module = ngx_modules[m]->ctx;			/*	对应模块特有的数据	*/
	634 
	635         if (module->actions.init(cycle, ngx_timer_resolution) != NGX_OK) {
	636             /* fatal */
	637             exit(2);
	638         }
	639 
	640         break;
	641     }
	642 
		
	
	543 typedef struct {
	544     ngx_uint_t    connections;		/*	 连接池的大小	*/
	544     ngx_uint_t    use;				/* 	选用的事件模块在同类事件模块中的序号	*/
	545     ngx_flag_t    multi_accept;		/* 	标志位，如果为1，则表示在接收到一个新连接事件时，一次性建立尽可能多的连接	*/
	546     /*	标识位，为1表示启用负载均衡锁	*/
	547     ngx_flag_t    accept_mutex;
	    	/*
	    	*	负载均衡锁会使有些worker进程在拿不到锁时延迟建立新连接
	  		*	accept_mutex_delay就是这段延迟时间的长度
	    	*/
	548     ngx_msec_t    accept_mutex_delay;
	549    u_char       *name; 				/*	 所选用事件模块的名字，它与use成员是匹配的	*/
	550 #if (NGX_DEBUG)   
	551     ngx_array_t   debug_connection;
	552 #endif
	553 } ngx_event_conf_t;



![013]({{ site.img_url }}/2014/05/013.png )

