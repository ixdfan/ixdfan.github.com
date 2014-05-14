---
layout: post
title: Nginx负载均衡--客户端请求的均衡与惊群问题
description: 
modified: 
categories: 
- Nginx
tags:
- 负载均衡
---

一般情况下，配置Nginx执行时候，工作进程会有多个，由于各个工作进程相互独立的接收客户端请求、处理、响应，所以就出现了负载不均衡的情况，比如极端的情况会是1个工作进程当前有3000个请求等待处理;而另一个进程当前也之后300个请求等待处理。

#### 客户端请求均衡

#####惊群问题

Nginx工作进程的主要任务就是处理事件，而事件的最初源头来自监听套接口，所以一旦末个工作进程独自拥有末个监听套接口，那么所有来自该监听套接口的客户端请求都将被这个工作线程处理。

如果多个工作进程同时拥有某个监听套接字，那么一旦该监听套接字出现某客户端请求，此时就将引发所有拥有该监听套接字的工作进程去争抢这个请求，但是能够抢到的肯定只有某一个工作进程，而其他工作进程注定无功而返，这就是惊群现象。

在高版本的Linux内核中已经解决了这个问题。


Nginx中有一个ngx_use_accept_mutex的全局变量，这个变量可以说是Nginx均衡措施的根本所在，该变量是一个整形变量。

 	54 ngx_uint_t            ngx_use_accept_mutex;


ngx_use_accept_mutex变量的赋值在ngx_event_process_init中，也就是每个工作进程开始时的初始化函数。

调用关系如下:
	
	ngx_worker_process_cycyle()--->ngx_worker_process_init()--->ngx_event_process_init()


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
	597     if (ccf->master && ccf->worker_processes > 1 && ecf->accept_mutex) {
	598         ngx_use_accept_mutex = 1;
	599         ngx_accept_mutex_held = 0;
	600         ngx_accept_mutex_delay = ecf->accept_mutex_delay;
	601 
	602     } else {
	603         ngx_use_accept_mutex = 0;
	604     }


可以看到(1)只有在多进程的模型下，并且(2)工作进程数大于1的情况下，(3)用户配置开启负载均衡的情况下,才会设置开启负载均衡。否则是不开启的(ngx_use_accept_mutex为0)

对于ecf->accept_mutex主要是提供用户便利，可以让用户关闭该功能，因为难保某些情况下因为本身的消耗得不偿失。所以可以让用户关闭这个功能。

这个字段默认为1,在初始化函数ngx_event_core_init_conf()内;

	1252     ngx_conf_init_value(ecf->multi_accept, 0);
	1253     ngx_conf_init_value(ecf->accept_mutex, 1);	/*	将accept_mutex设置为1.	*/
	1254     ngx_conf_init_msec_value(ecf->accept_mutex_delay, 500);


将ngx_use_accept_mutex值设置为1,也就开启了Nginx负载均衡策略，此时在每个工作进程的初始化函数ngx_event_process_init内，所有监听套接字都不会被加入到工作进程的事件监控机制里了


	826         rev->handler = ngx_event_accept;
	827			
				/*	如果开启了负载均衡，就跳过，不会将其加入到事件监控	*/
	828         if (ngx_use_accept_mutex) {
	829             continue;
	830         }
	831 
	832         if (ngx_event_flags & NGX_USE_RTSIG_EVENT) {
	833             if (ngx_add_conn(c) == NGX_ERROR) {
	834                 return NGX_ERROR;
	835             }
	836 
				/*	没有开启，就将其加入到事件监控中去	*/
	837         } else {
	838             if (ngx_add_event(rev, NGX_READ_EVENT, 0) == NGX_ERROR) {
	839                 return NGX_ERROR;
	840             }
	841         }



真正将监听套接口加入到时间监控机制实在函数ngx_process_event_and_timers函数中.

工作进程的主要一个执行体就是一个无限for循环，而该循环内最重要的调用就是ngx_process_event_and_timers。

在该函数内动态的添加与删除监听套接口是一种很灵活的方式。

如果当前的工作的负载均衡比较小，就将监听套接字加入到自身的事件监控机制中，从而带来新的客户端请求;

如果当前工作进程负载比较大，就将套接字从自身的事件监控机制中删除，避免引入新的客户端请求而带来的更大的负载。

当然，加入、删除需要锁机制来做互斥与同步，既要避免监听套接字同时被加入到多个进程的事件监控机制里，又要避免监听套接字在某一时刻没有任何进程监控。




#### 负载均衡
##### post事件处理机制

nginx设计了两个队列:ngx_posted_accept_events(存放新链接事件的队列)和ngx_posted_events队列(存放普通事件的队列)，这两个队列都是ngx_event_t类型的双链表。



	200 void
	201 ngx_process_events_and_timers(ngx_cycle_t *cycle)
	202 {
	203     ngx_uint_t  flags;
	204     ngx_msec_t  timer, delta;
	205 
	206     if (ngx_timer_resolution) {
	207         timer = NGX_TIMER_INFINITE;
	208         flags = 0;
	209 
	210     } else {
	211         timer = ngx_event_find_timer();
	212         flags = NGX_UPDATE_TIME;
	213 
	214 #if (NGX_THREADS)
	215 
	216         if (timer == NGX_TIMER_INFINITE || timer > 500) {
	217             timer = 500;
	218         }
	219 
	220 #endif
	221     }
	222		
			/*	负载均衡的真正实现	*/
			/*	必须开启了才可以使用	*/
	223     if (ngx_use_accept_mutex) {
				/*	ngx_accept_disabled>0则处于过载状态	*/
	224         if (ngx_accept_disabled > 0) {
					/*	没有去抢那把锁，而是静静的去处理原来的负载，所以说自减1	*/
	225             ngx_accept_disabled--;
	226 
				/*	否则便是没有过载	*/
	227         } else {
					/*	没有过载就努力去争取锁	*/
	228             if (ngx_trylock_accept_mutex(cycle) == NGX_ERROR) {
	229                 return;
	230             }
	231					
					/*	争取失败，判断是否本来就拥有锁	*/
					/*	如果当前拥有锁，那么就给flags加入标识NGX_POST_EVENTS,表示所有发生的事件都将咽喉处理	*/
	232             if (ngx_accept_mutex_held) {
	233                 flags |= NGX_POST_EVENTS;
	234 
	235             } else {
	236                 if (timer == NGX_TIMER_INFINITE
	237                     || timer > ngx_accept_mutex_delay)
	238                 {
	239                     timer = ngx_accept_mutex_delay;
	240                 }
	241             }
	242         }
	243     }	// if end
	244 
	245     delta = ngx_current_msec;
	246			
			/*	这个函数将所有的事件缓存了	*/
	247     (void) ngx_process_events(cycle, timer, flags);
	248 
	249     delta = ngx_current_msec - delta;
	250 
	251     ngx_log_debug1(NGX_LOG_DEBUG_EVENT, cycle->log, 0,
	252                    "timer delta: %M", delta);
	253 
			/*	
				如果其不为空链表，则处理新建链接的缓存事件
				ngx_epoll_process_events函数中对这个链表进行了缓存，使得其不为空
				先处理新建链接上的事件缓存，在处理其他的事件缓存
			
			*/
	254     if (ngx_posted_accept_events) {
	255         ngx_event_process_posted(cycle, &ngx_posted_accept_events);
	256     }
	257 
			/*	处理完后就赶紧释放锁	*/
	258     if (ngx_accept_mutex_held) {
	259         ngx_shmtx_unlock(&ngx_accept_mutex);
	260     }
	261 
	262     if (delta) {
	263         ngx_event_expire_timers();
	264     }
	265 
	266     ngx_log_debug1(NGX_LOG_DEBUG_EVENT, cycle->log, 0,
	267                    "posted events %p", ngx_posted_events);
	268
			/*	处理原本延时的事件队列(如果有的话)	*/
	269     if (ngx_posted_events) {
	270         if (ngx_threaded) {
	271             ngx_wakeup_worker_thread(cycle);
	272 
	273         } else {
	274             ngx_event_process_posted(cycle, &ngx_posted_events);
	275         }
	276     }
	277 }


ngx_accept_disabled的值的含义

	18 void
	19 ngx_event_accept(ngx_event_t *ev)
	20 {
	107         ngx_accept_disabled = ngx_cycle->connection_n / 8
	108                               - ngx_cycle->free_connection_n;
	109 

其中ngx_cycle->connection_n表示一个工作进程的最大可承受连接数，可以通过配置文件的work_connections指令配置，默认值是512,在函数ngx_event_core_init_conf()中

	13 #define DEFAULT_CONNECTIONS  512

	1156 static char *
	1157 ngx_event_core_init_conf(ngx_cycle_t *cycle, void *conf)
	1158 {
			/*	默认初始化成512了	*/
	1244     ngx_conf_init_uint_value(ecf->connections, DEFAULT_CONNECTIONS);
	1245     cycle->connection_n = ecf->connections;

另一个ngx_cycle->free_connection_n表示当前可用连接数，假设当前活动连接数为x，那么该值为ngx_cycyle->connection_n - x;
所以此时ngx_accept_disabled的值为:

	ngx_accept_disabled	= ngx_cycle->connection_n/8 - (ngx_cycle->connection_n - x)
						= x - (ngx_cycle->connection_n * 7/8)

如果ngx_accept_disabled > 0表示过载，意思就是x - (ngx_cycle->connection_n * 7/8) > 0，也就是说当前活动连接数(x)的值如果超过ngx_cycle->connection_n的7/8，则表示发生过载。变量ngx_accept_disabled将大于0,并且该值越大表示过载越大，当前进程负载越重。

当工作进程的负载达到这个临界点的时候他就不会尝试去获取互斥锁，从而让新来的负载可以均衡到其他工作进程。


可以看到只有在开启了负载均衡(ngx_use_accept_mutex=1)后才会生效。

首先判断变量ngx_accept_disabled是否大于0来判断当前进程是否已经过载。为什么这样继续向下看;

当处于过载状态的时候，所做的工作是使ngx_accept_disabled自减1,这表示既然经过了一轮处理，那么负载一定是减小的，所以要相应改变ngx_accept_disabled的值。

经过一段时间ngx_accept_disabled将会降到0以下，便又可以去争取新的请求连接。
所以如下文所说的最大可承受连接数的7/8便是一个负载均衡点，当某进程的负载达到了这个临界点的时候它就不会去尝试获取互斥锁，从而让新增加的负载可以均衡到其他工作进程上去。


如果进程并没有处理过载状态，那么就会去争锁，实际上争取的是套接字接口的监控权，争锁成功就会把所有监听套接字加入到自身的事件监控机制中(如果原本不在);

如果争锁失败就会将所有监听套接字从自身的时间监控机制里删除(如果原本有的话),

注意:是所有套接字，因为他们总是作为一个整体本加入或是删除


NGX_POST_EVENTS标记表示所有发生的事件都将会延后处理,因为要尽快的释放锁。

#### 任何架构设计都必须遵守的约定，就是持锁者必须尽量缩短自身持有锁的时间,所以发生的大部分事件都要延迟到释放锁之后再去处理，以便把锁尽快释放，缩短自身持有锁的时间可以让其他进程尽可能的有机会获取到锁。

如果当前进程没有获取到锁，那么就将监控机制阻塞点(例如epoll_wait)的超时时间限制在一个比较短的时间范围内，也就是ngx_accept_mutex_delay，默认是500毫秒.超时时间短了，所以超时更快，那么也就可以更频繁的从阻塞中跳出，也就有更多的机会去争取到锁了。



	294 ngx_int_t
	295 ngx_trylock_accept_mutex(ngx_cycle_t *cycle)
	296 {
	297     if (ngx_shmtx_trylock(&ngx_accept_mutex)) {
	298 
	299         ngx_log_debug0(NGX_LOG_DEBUG_EVENT, cycle->log, 0,
	300                        "accept mutex locked");
	301 
	302         if (ngx_accept_mutex_held
	303             && ngx_accept_events == 0
	304             && !(ngx_event_flags & NGX_USE_RTSIG_EVENT))
	305         {
	306             return NGX_OK;
	307         }
	308 
	309         if (ngx_enable_accept_events(cycle) == NGX_ERROR) {
	310             ngx_shmtx_unlock(&ngx_accept_mutex);
	311             return NGX_ERROR;
	312         }
	313 
	314         ngx_accept_events = 0;
	315         ngx_accept_mutex_held = 1;
	316 
	317         return NGX_OK;
	318     }
	319 
	320     ngx_log_debug1(NGX_LOG_DEBUG_EVENT, cycle->log, 0,
	321                    "accept mutex lock failed: %ui", ngx_accept_mutex_held);
	322 
	323     if (ngx_accept_mutex_held) {
	324         if (ngx_disable_accept_events(cycle) == NGX_ERROR) {
	325             return NGX_ERROR;
	326         }
	327 
	328         ngx_accept_mutex_held = 0;
	329     }
	330 
	331     return NGX_OK;
	332 }

ngx_trylock_accept_mutex的内部流程
![006]({{ site.img_url }}/2014/05/006.png)



拥有锁的进程对时间的处理，也就是之前所说的延迟处理，当一个事件发生时候，一般处理(不做延迟的话)会立即调用事件对应的回调函数，而延迟处理则会将该时间以链表的形式缓存起来

在函数ngx_process_events_and_timers中的ngx_process_events函数已经将所有事件都缓存了起来，接下来先处理新建链接

		static ngx_int_t
	558 ngx_epoll_process_events(ngx_cycle_t *cycle, ngx_msec_t timer, ngx_uint_t flags)
	559 {
				......
					/*	如果标记了延迟处理，则执行事件缓存	*/
	672             if (flags & NGX_POST_EVENTS) {
	673                 queue = (ngx_event_t **) (rev->accept ?
	674                                &ngx_posted_accept_events : &ngx_posted_events);
							/*	
									将其添加到ngx_posted_accept_events链表中
									新建连接事件，就是监听套接字上发生的可读事件
									在ngx_process_events_and_timers中的ngx_posted_accept_events就不为空了
							*/
	675 
	676                 ngx_locked_post_event(rev, queue);
	677 
					/*	否则直接调用对应的回调函数	*/
	678             } else {
	679                 rev->handler(rev);
	680             }
	681         }
	682 
	683         wev = c->write;
	684 
	685         if ((revents & EPOLLOUT) && wev->active) {
	686 
	687             if (c->fd == -1 || wev->instance != instance) {
	688 
	689                 /*
	690                  * the stale event from a file descriptor
	691                  * that was just closed in this iteration
	692                  */
	693 
	694                 ngx_log_debug1(NGX_LOG_DEBUG_EVENT, cycle->log, 0,
	695                                "epoll: stale event %p", c);
	696                 continue;
	697             }
	698 
	699             if (flags & NGX_POST_THREAD_EVENTS) {
	700                 wev->posted_ready = 1;
	701 
	702             } else {
	703                 wev->ready = 1;
	704             }
	705				/*	对于标记了的单独进行处理	*/ 
	706             if (flags & NGX_POST_EVENTS) {
	707                 ngx_locked_post_event(wev, &ngx_posted_events);
	708 
	709             } else {
	710                 wev->handler(wev);
	711             }
	712         }
	713     }
	714 
	715     ngx_mutex_unlock(ngx_posted_events_mutex);
	716 
	717     return NGX_OK;
	718 }



ngx_process_events_and_timers函数中先处理新建连接缓存事件链表ngx_posted_accept_events，此时还不能释放锁，因为我们还在处理监听套接字上的事情，还要读取上面的请求数据，所以此时必须独占，一旦缓存的新链接事件表被全部处理完了就必须马上释放现有的锁了，因为连接套接字只可能被某一个进程自始至终占用，不会出现进程之间的相互冲突，所以对于链接套接口上事件ngx_posted_events的处理可以在释放锁之后进行，虽然对于他们的具体处理与响应是非常消耗时间的，但是在此之前已经释放了持有的锁，所以即使是慢一点也不会影响到其他进程，最多客户感觉慢了一点吧！


### 注意:
1.如果在办理新建链接时间的过程中，在监听套接字上又来了新的请求的时候怎么办？

当前进程只会处理已经缓存的事件，新的请求将会被阻塞在监听套接字中，由于监听套接字是以水平方式加入到时间监控机制中的，所以等到下一轮的被那个进程争取到锁并且加到时间监控机制里时候才会被触发从而被抓取出来。

2.第259行ngx_shmtx_unlock(&ngx_accept_mutex)只是释放锁，而并没有将监听套接字从事件监控机制中删除，所以有可能在接下来处理ngx_posted_events缓存时间的过程中，互斥锁被另外一个进程争抢到并且把所有的监听套接字加入到他的事件监控机制里面，因此严格来说，在同一时刻，监听套接字可能被多个进程拥有，但是在同一时刻，监听套接字只可能被一个进程监控(也就是epoll_wait这种)，因此进程在处理完ngx_posted_events缓存事件后去争抢锁，发现锁被其他进程占用而争用失败，会把所有监听套接字从自身的事件监控机制里删除，然后才进行事件监控。但在同一时刻，监听套接字只能被一个进程监控，这也就意味着Nginx根本不会受到惊群问题的影响。


