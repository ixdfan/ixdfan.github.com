---
layout: post
title:  nginx负载均衡--加权轮询的实现
description: 
modified: 
categories: 
-  Nginx
tags:
- 负载均衡
---


nginx根据每个工作进程的当前压力调整他们获取监听套接口的机率，那些当前比较空闲的工作进程有更多机会获取到监听套接口，从而当客户端的请求到达后也就相应的被他捕获并处理。这是客户端请求在多个Nginx进程之间的均衡。


如果Nginx是以反向代理的形式配置运行，那么对于请求的实际处理需要转发到后端服务器进行，如果后端服务器有多台，如何选择一个合适的后端服务器来处理当前请求，这就是通常所说的负载均衡。

可以看到这两个均衡是不相互冲突而且能同时生效。

负载均衡是指将负载尽量均衡的分摊到多个不同的服务单元(比如多个后台服务器),以保证服务的可用和可靠性，提供给客户更好的用户体验。负载均衡的直接作用只有一个，尽量发挥多个服务单元的整体效能，实现1+1=2甚至大于2的效果。

nginx提供的负载均衡策略主要包括:

#####加权轮询、weight、IP哈希、fair、一致哈希

其中fair和一致哈希都是第三方模块提供的，加权轮询、weight和IP哈希是Nginx内置的策略;


####加权轮询(默认)

每个请求按照时间顺序逐一分配到不同的后端服务器，如果后端服务器down掉，则自动踢出这台服务器;默认每个权重都是1;


#### weight

与加权轮询配合使用，其实就是自己指定了轮询机率，weight和访问比率成正比，weight越大访问次数越多,用于后端服务器性能不均的情况;

#### ip_hash

每个请求按照ip的哈希结果分配，每个访客固定访问一个后端服务器



Nginx默认采用的是加权轮询策略，如果要采用IP哈希策略，就必须在Nginx的配置文件中通过配置指令ip_hash明确指定(最好放在其他server指令之前，以便检查server的配置选项是否合理)

	upstream backend{   
		ip_hash;
		server 192.168.8.1:8000; 
		server 192.168.8.2:9000;
	}   


	
	/*	通过执行不同的初始化函数，在后续实际负载时候采用的策略也就不同了	*/
	4651 static char *
	4652 ngx_http_upstream_init_main_conf(ngx_conf_t *cf, void *conf)
	4653 {
	4665 	......
	4666     for (i = 0; i < umcf->upstreams.nelts; i++) {
	4667 
	4668         /* ngx_http_upstream_init_round_robin是加权轮询 */
	4669         /* 如果用户没有做任何策略选择，那么负载均衡策略的初始化函数就是round_robin */
				 /* 否则的话就执行对应的uscfp[i]->peer.init_upstream指针函数 */
				 /* 如果有配置ip_hash指令，则也就是行数ngx_http_upstream_init_ip_hash() */
	4670         init = uscfp[i]->peer.init_upstream ? uscfp[i]->peer.init_upstream:
	4671                                             ngx_http_upstream_init_round_robin;
	4672	......
	4673 


#### 准备工作:

	upstream backend {
		server	backend1.example.com	weight=5;
		server	127.0.0.1:8080	max_fails=3 fail_timeout=30s;
		server	UNIX:/temp/backend3	backup;
		server	192.168.0.1:9000 down;
	}
	指定的server可以是域名、ip或是UNIX域，他们代表不同的后端服务器

	weigth:权重，默认是1,与加权轮询策略配合使用

	max_fails与fail_timeout:他们需要配合使用，默认值分别是1和10s

	具体的含义是:
	如果某台服务器在fail_timeout时间内发生了max_fails次失败连接，那么该后端服务器在这fail_timeout时间内就不再残余被选择，直到fail_timeout时间后才重新加入从而有机会被再次选择，简单点就是先休息下，一会在工作。

	backup:备机，平常不被选择，之后当其他所有非备机全部不可用(比如繁忙或宕机)时才会被使用。
	
	down:主动标识其为宕机状态，不参与被选择

#### 注意:
* backup选项不能用于ip_hash中，因为他会扰乱哈希的结果而违背ip_hash策略的初衷;

* 某些参数只能和策略配合使用，如果发现某参数没有生效，则应该检测一下这一点，在配置解析过程中，这些选项设置都被转换为Nginx内部对应的变量值;

path:/src/http/ngx_http_upstream.h

	87 typedef struct {
	88     ngx_addr_t                      *addrs;
	89     ngx_uint_t                       naddrs;
	90     ngx_uint_t                       weight;
	91     ngx_uint_t                       max_fails;
	92     time_t                           fail_timeout;
	93 
	94     unsigned                         down:1;
	95     unsigned                         backup:1;
	96 } ngx_http_upstream_server_t;

addrs是一个数组指针，这是因为一个域名可以对应这多个IP地址;

数组的元素由naddrs指定;

域名解析中Nginx直接采用gethostbyname()阻塞函数获取，所以如果Nginx启动过程中发现卡住情况，可以检查下配置文件是否有配置域名并且系统当前的DNS解析是否正常。


以下代码主要在/src/http/ngx_http_upstream_round_robin.h|c中

	17 typedef struct {
		/*	基本socket信息		*/
  	18     struct sockaddr                *sockaddr;
   	19     socklen_t                       socklen;
    20     ngx_str_t                       name;
	21 	/* 当前权重值和设定权重值 */
 	22     ngx_int_t                       current_weight;
	23     ngx_int_t                       weight;
	24 	/* 失败次数和访问次数	 */	
	25     ngx_uint_t                      fails;
		/*	失败访问时间，用于计算超时	*/
	26     time_t                          accessed;
	27     time_t                          checked;
	28 	/*	失败次数上限和失败时间阀值	*/
	29     ngx_uint_t                      max_fails;
	30     time_t                          fail_timeout;
	31  /* 服务器是否被标记了down，标记了就不参与选择 */ 
	32     ngx_uint_t                      down;          /* unsigned  down:1; */
	33     
	34 #if (NGX_HTTP_SSL)
	35     ngx_ssl_session_t              *ssl_session;   /* local to a process */
	36 #endif
	37 } ngx_http_upstream_rr_peer_t;

	current_weight和weight的主要区别是前者为权重排序的值，随着处理请求会动态变化，后面是配置文档中的值，用于恢复初始状态。

		/*	注意:与上面的不同，上面是peer_t，下面是peers_t*/
	40 typedef struct ngx_http_upstream_rr_peers_s  ngx_http_upstream_rr_peers_t;
	41     
	42 struct ngx_http_upstream_rr_peers_s {
	43     ngx_uint_t                      single;        /* unsigned  single:1; */
	44     ngx_uint_t                      number;        /*  后台服务器的台数   */
	45     ngx_uint_t                      last_cached;
	46 
	47  /* ngx_mutex_t                    *mutex; */
	48     ngx_connection_t              **cached;
	49     
	50     ngx_str_t                      *name;
	51 
	52     ngx_http_upstream_rr_peers_t   *next;
	53 
	54     ngx_http_upstream_rr_peer_t     peer[1];
	55 };
	56 
	57 
	58 typedef struct {
	59     ngx_http_upstream_rr_peers_t   *peers;
	60     ngx_uint_t                      current;
	61     uintptr_t                      *tried;
	62     uintptr_t                       data;
	63 } ngx_http_upstream_rr_peer_data_t;
						   



	
	加权轮询实现代码
	598 static ngx_uint_t
	599 ngx_http_upstream_get_peer(ngx_http_upstream_rr_peers_t *peers)
	600 {
	601     ngx_uint_t                    i, n, reset = 0;
	602     ngx_http_upstream_rr_peer_t  *peer;
	603 
	604     peer = &peers->peer[0];
	605 
	606     for ( ;; ) {
	607			/*	i是后台机器的下标	*/ 
	608         for (i = 0; i < peers->number; i++) {
	609				/* 	如果权重小于等于0,就跳过	 */ 
	610             if (peer[i].current_weight <= 0) {
	611                 continue;            
	612             }
	613    
	614             n = i;
	615   		
					/*	while查找当前权重最大的后端机器	*/
	616             while (i < peers->number - 1) {
	617 
	618                 i++;
	619 
	620                 if (peer[i].current_weight <= 0) {
	621                     continue;            
	622                 }
	623 
	624                 if (peer[n].current_weight * 1000 / peer[i].current_weight
	625                     > peer[n].weight * 1000 / peer[i].weight)
	626                 {
	627                     return n;            
	628                 }
	629 
	630                 n = i;               
	631             }
	632				
					/*	如果while找到了current_weight>0的机器，则返回*/
	633             if (peer[i].current_weight > 0) {
	634                 n = i;
	635             }
	636 
	637             return n;
	638         }
	639				
				/*	以下代码是恢复状态	*/
	640         if (reset++) {
	641             return 0;
	642         }
	643 		
				/*	peer[i].weigth是配置文件中手工设定的权重值	*/
	644         for (i = 0; i < peers->number; i++) {
	645             peer[i].current_weight = peer[i].weight;	
	646         }
	647     }
	648 }



ngx_http_upstream_init_round_robin()函数根据用户的配置执行不同的代码，用户配置有两种情况
	
	第一种情况:
	
	upstream backend {
		server 127.0.0.1:9001	backup;
		server 127.0.0.1:9000	weight=5;
		server 127.0.0.1:8000	max_fails=3 fail_timeout=30s;
		server 127.0.0.1:7000	max_fails=1 fail_timeout=10s;
	}
		proxy_pass backend;

		对应代码if (us->servers) {...}这一段

	第二种情况:

		proxy_pass localhost:4000	#后面直接接后端服务器地址

		对应代码后半部分

	/*  将配置解析后的结果转存到对应的变量  */
	/*  创建后端服务器列表，将非后备服务器与后备服务器分开进行各自单独的列表    */
	/*  每个后端服务器使用结构体ngx_http_upstream_rr_peer_t对应 */
	/*	非后备服务器列表挂载在us->ps.data字段下*/
	/*	后备服务器列表挂载在非后备服务器列表head域中的next字段下*/

	31 ngx_int_t
	32 ngx_http_upstream_init_round_robin(ngx_conf_t *cf,
	33     ngx_http_upstream_srv_conf_t *us)
	34 {
	35     ngx_url_t                      u;
	36     ngx_uint_t                     i, j, n;
	37     ngx_http_upstream_server_t    *server;
	38     ngx_http_upstream_rr_peers_t  *peers, *backup;
	39		/*	初始化操作	*/ 
	40     us->peer.init = ngx_http_upstream_init_round_robin_peer;
	41		/*	适用于情况一*/ 
	42     if (us->servers) {
	43         server = us->servers->elts;
	44 
	45         n = 0;
	46 
	47         for (i = 0; i < us->servers->nelts; i++) {
	48             if (server[i].backup) {	
	49                 continue;
	50             }
	51 
	52             n += server[i].naddrs;
	53         }
	54 
	55         if (n == 0) {
	56             ngx_log_error(NGX_LOG_EMERG, cf->log, 0,
	57                           "no servers in upstream \"%V\" in %s:%ui",
	58                           &us->host, us->file_name, us->line);
	59             return NGX_ERROR;
	60         }
	61		 
	62         peers = ngx_pcalloc(cf->pool, sizeof(ngx_http_upstream_rr_peers_t)
	63                               + sizeof(ngx_http_upstream_rr_peer_t) * (n - 1));
	64         if (peers == NULL) {
	65             return NGX_ERROR;
	66         }
	67 			/*	如果只有一台服务器(非后备和后备服务器一共一台)则会对齐机型标识，
					这样在后续用户请求的时候更本无需在做选择，直接使用这一台即可*/
	68         peers->single = (n == 1);
	69         peers->number = n;
	70         peers->name = &us->host;
	71 
	72         n = 0;
	73			/*	将解析后的结果存储到对应的变量之中	*/ 
	74         for (i = 0; i < us->servers->nelts; i++) {
	75             for (j = 0; j < server[i].naddrs; j++) {
	76                 if (server[i].backup) {	
	77                     continue;	/* 对与后备的服务器暂不操作 */
	78                 }
	79 
	80                 peers->peer[n].sockaddr = server[i].addrs[j].sockaddr;
	81                 peers->peer[n].socklen = server[i].addrs[j].socklen;
	82                 peers->peer[n].name = server[i].addrs[j].name;
	83                 peers->peer[n].max_fails = server[i].max_fails;
	84                 peers->peer[n].fail_timeout = server[i].fail_timeout;
	85                 peers->peer[n].down = server[i].down;
	86                 peers->peer[n].weight = server[i].down ? 0 : server[i].weight;
	87                 peers->peer[n].current_weight = peers->peer[n].weight;
	88                 n++;
	89             }
	90         }
	91 
	92         us->peer.data = peers;	/*	peers是非后备服务器列表	*/

	93			/*	对peers列表中的服务器按照权重进行排序*/ 
	94         ngx_sort(&peers->peer[0], (size_t) n,
	95                  sizeof(ngx_http_upstream_rr_peer_t),
	96                  ngx_http_upstream_cmp_servers);
	97 
	98         /* backup servers */
	99 
	100         n = 0;
	101 
	102         for (i = 0; i < us->servers->nelts; i++) {
	103             if (!server[i].backup) {
	104                 continue;	/* 对非后备服务器不进行操作	*/
	105             }
	106 
	107             n += server[i].naddrs;
	108         }
	109 
	110         if (n == 0) {
	111             return NGX_OK;
	112         }
	113 		/*	后备服务器的列表空间	*/
	114         backup = ngx_pcalloc(cf->pool, sizeof(ngx_http_upstream_rr_peers_t)
	115                               + sizeof(ngx_http_upstream_rr_peer_t) * (n - 1));
	116         if (backup == NULL) {
	117             return NGX_ERROR;
	118         }
	119 		/*	why???	*/
	120         peers->single = 0;
	121         backup->single = 0;
	122         backup->number = n;
	123         backup->name = &us->host;
	124 
	125         n = 0;
	126 
	127         for (i = 0; i < us->servers->nelts; i++) {
	128             for (j = 0; j < server[i].naddrs; j++) {
	129                 if (!server[i].backup) {
	130                     continue;	/* 跳过非后备服务器 */
	131                 }
	132 
	133                 backup->peer[n].sockaddr = server[i].addrs[j].sockaddr;
	134                 backup->peer[n].socklen = server[i].addrs[j].socklen;
	135                 backup->peer[n].name = server[i].addrs[j].name;
	136                 backup->peer[n].weight = server[i].weight;
	137                 backup->peer[n].current_weight = server[i].weight;
	138                 backup->peer[n].max_fails = server[i].max_fails;
	139                 backup->peer[n].fail_timeout = server[i].fail_timeout;
	140                 backup->peer[n].down = server[i].down;
	141                 n++;
	142             }
	143         }
	144 
	145         peers->next = backup;	/* 	后备服务器	*/
	146 		/* 对后备服务器进行权重排序	 */
	147         ngx_sort(&backup->peer[0], (size_t) n,
	148                  sizeof(ngx_http_upstream_rr_peer_t),
	149                  ngx_http_upstream_cmp_servers);
	150 
	151         return NGX_OK;
	152     }
	153 
	154 
	155     /* an upstream implicitly defined by proxy_pass, etc. */
	156		/*	实用于情况2，对于直接在proxy_pass等指令之后直接指定后端服务器地址的处理方式*/ 
	157     if (us->port == 0 && us->default_port == 0) {
	158         ngx_log_error(NGX_LOG_EMERG, cf->log, 0,
	159                       "no port in upstream \"%V\" in %s:%ui",
	160                       &us->host, us->file_name, us->line);
	161         return NGX_ERROR;
	162     }
	163 
	164     ngx_memzero(&u, sizeof(ngx_url_t));
	165 
	166     u.host = us->host;
	167     u.port = (in_port_t) (us->port ? us->port : us->default_port);
	168 
	169     if (ngx_inet_resolve_host(cf->pool, &u) != NGX_OK) {
	170         if (u.err) {
	171             ngx_log_error(NGX_LOG_EMERG, cf->log, 0,
	172                           "%s in upstream \"%V\" in %s:%ui",
	173                           u.err, &us->host, us->file_name, us->line);
	174         }
	175 
	176         return NGX_ERROR;
	177     }
	178 
	179     n = u.naddrs;
	180 
	181     peers = ngx_pcalloc(cf->pool, sizeof(ngx_http_upstream_rr_peers_t)
	182                               + sizeof(ngx_http_upstream_rr_peer_t) * (n - 1));
	183     if (peers == NULL) {
	184         return NGX_ERROR;
	185     }
	186 
	187     peers->single = (n == 1);
	188     peers->number = n;
	189     peers->name = &us->host;
	190 
	191     for (i = 0; i < u.naddrs; i++) {
	192         peers->peer[i].sockaddr = u.addrs[i].sockaddr;
	193         peers->peer[i].socklen = u.addrs[i].socklen;
	194         peers->peer[i].name = u.addrs[i].name;
	195         peers->peer[i].weight = 1;
	196         peers->peer[i].current_weight = 1;
	197         peers->peer[i].max_fails = 1;
	198         peers->peer[i].fail_timeout = 10;
	199     }
	200 
	201     us->peer.data = peers;
	202 
	203     /* implicitly defined upstream has no backup servers */
	204 
	205     return NGX_OK;
	206 }


![001]({{ site.img_url }}/2014/05/001.png)


当全局初始准备工作做好以后，当一个客户请求过来时候，Nginx就要选择适合的后端服务器来处理该请求，在正式开始选择前，Nginx还要单独为本轮选择做一些初始化，比如设置回调函数,回调函数是在每个请求选择后端服务器之前被调用。
	
#### 注意:
针对一个客户端请求，Nginx会进行多次尝试，尝试全部失败才会返回502错误，所以要注意一轮选择与一次选择的区别。

#### 选择后端服务器

	/*	选择后端服务器	*/
	221 ngx_int_t
	222 ngx_http_upstream_init_round_robin_peer(ngx_http_request_t *r,
	223     ngx_http_upstream_srv_conf_t *us)
	224 {
	225     ngx_uint_t                         n;
	226     ngx_http_upstream_rr_peer_data_t  *rrp;
	227 	
	228     rrp = r->upstream->peer.data;
	229 
	230     if (rrp == NULL) {
	231         rrp = ngx_palloc(r->pool, sizeof(ngx_http_upstream_rr_peer_data_t));
	232         if (rrp == NULL) {
	233             return NGX_ERROR;
	234         }
	235 
	236         r->upstream->peer.data = rrp;
	237     }
	238		
			/*	非后备服务器	*/
	239     rrp->peers = us->peer.data;
	240     rrp->current = 0;
	241		
			/*	n要选择后备服务器和非后备服务器中数量较大的那一个	*/
	242     n = rrp->peers->number;
	243 
	244     if (rrp->peers->next && rrp->peers->next->number > n) {
	245         n = rrp->peers->next->number;
	246     }
	247 
	248     if (n <= 8 * sizeof(uintptr_t)) {
	249         rrp->tried = &rrp->data;
	250         rrp->data = 0;
	251 
	252     } else {
	253         n = (n + (8 * sizeof(uintptr_t) - 1)) / (8 * sizeof(uintptr_t));
	254 
	255         rrp->tried = ngx_pcalloc(r->pool, n * sizeof(uintptr_t));
	256         if (rrp->tried == NULL) {
	257             return NGX_ERROR;
	258         }
	259     }

	260		/*	设置回调函数	*/
	261     r->upstream->peer.get = ngx_http_upstream_get_round_robin_peer;	/*	对后端服务器进行一次选择	*/ 
	262     r->upstream->peer.free = ngx_http_upstream_free_round_robin_peer;
			/*	初始状态	*/
	263     r->upstream->peer.tries = rrp->peers->number;
	264 #if (NGX_HTTP_SSL)
	265     r->upstream->peer.set_session =
	266                                ngx_http_upstream_set_round_robin_peer_session;
	267     r->upstream->peer.save_session =
	268                                ngx_http_upstream_save_round_robin_peer_session;
	269 #endif
	270 
	271     return NGX_OK;
	272 }
	273 

#### 注意:

rrp->tried是一个位图，用来标识在一轮选择中多个后端服务器是否已经被选择过;

例如:

假设有3台后端服务器，此时来了一个客户端请求，因此Nginx要针对该请求进行一轮选择，第一次选择了第一台服务器，结果后续连接失败，因此需要进行第二次选择，此时就不能在选择第一台服务器了，因为它已经被选择并尝试过了，所以只能选择第二台或第三台服务器，这个位图只是针对本轮选择，也就是如果又来了一个客户端请求，那么针对它的一轮选择对应的rrp->tried位图又是全新的，如果后端服务器个数少于一个nt类型变量可以表示的范围(32位就是32台)(因为要同时让非后备服务器和后备服务器两个列表都能使用，所以取两个列表中个数较大的那个值)，那么就直接使用已有的指针类型的data变量做位图即可，否则使用ngx_pcalloc函数申请对应的内存空间。



	/*	对后端服务器进行一次选择	*/
	/*	关于前面的last_cached相关代码是未实现的陈旧代码，不用去管它	*/
	376 ngx_int_t
	377 ngx_http_upstream_get_round_robin_peer(ngx_peer_connection_t *pc, void *data)
	378 {
	379     ngx_http_upstream_rr_peer_data_t  *rrp = data;
	380 
	381     time_t                         now;
	382     uintptr_t                      m;
	383     ngx_int_t                      rc;
	384     ngx_uint_t                     i, n;
	385     ngx_connection_t              *c;
	386     ngx_http_upstream_rr_peer_t   *peer;
	387     ngx_http_upstream_rr_peers_t  *peers;
	388 
	389     ngx_log_debug1(NGX_LOG_DEBUG_HTTP, pc->log, 0,
	390                    "get rr peer, try: %ui", pc->tries);
	391 
	392     now = ngx_time();
	393 
	394     /* ngx_lock_mutex(rrp->peers->mutex); */
	395 
	396     /*  未实现的陈旧代码，不用去管他    */
	397     if (rrp->peers->last_cached) {
	398 
	399         /* cached connection */
	400			...... 
	415     }
	416 
	417     pc->cached = 0;
	418     pc->connection = NULL;
	419 
	420     /*  判断是否只有一台后端服务器  */
	421     if (rrp->peers->single) {
	422         peer = &rrp->peers->peer[0];
	423 
	424     } else {
	425 
	426         /* there are several peers */
	427 	
				/*	判断是否是第一次选择,第一次选择的机器数量就是后端服务器的数量*/
				/*	表示在连接一个远端服务器时，当前连接出现异常失败后可以重试的次数，
					也就是允许的最多失败次数,第一次链接时候可以重试的次数就是主机数	*/
	428         if (pc->tries == rrp->peers->number) {	/*	number是后端服务器的个数	*/
	429 
	430             /* it's a first try - get a current peer */
	431 
	432             i = pc->tries;
	433 
	434             for ( ;; ) {
						/*	返回权值最大的服务器下标，rrp->current是经过选择的后端服务器的下标	*/
	435                 rrp->current = ngx_http_upstream_get_peer(rrp->peers);	/*	get_peer是加权轮选的具体实现	*/
	436 				/*	
	437                 ngx_log_debug2(NGX_LOG_DEBUG_HTTP, pc->log, 0,
	438                                "get rr peer, current: %ui %i",
	439                                rrp->current,
	440                                rrp->peers->peer[rrp->current].current_weight);
	441
						/*	如果机器数大于了32,那么就返回的是该后端服务器在位图中的第几个int块中，小于32就返回0	*/
	442                 n = rrp->current / (8 * sizeof(uintptr_t));
	
						/*	m代表的是该后端服务器在位图中的第几位	*/
	443                 m = (uintptr_t) 1 << rrp->current % (8 * sizeof(uintptr_t));
	444 
						/*	对rrp->tried的具体使用	*/
						/* 	判断tried位图中该机器是否可用，如果tried[n]为0则表示可用	*/
						/*	位图标记过的就不要再去选择了，处于down机状态的也被排除	*/
	445                 if (!(rrp->tried[n] & m)) {
	446                     peer = &rrp->peers->peer[rrp->current];
	447						
	448                     if (!peer->down) {		/*	非down	*/ 
	449								
								/*	一段时间内的最大失败次数进行判断	*/
	450                         if (peer->max_fails == 0
	451                             || peer->fails < peer->max_fails)	/*	fails是已经失败的次数*/
	452                         {
	453                             break;	
	454                         }
	455 
	456                         if (now - peer->checked > peer->fail_timeout) {
	457                             peer->checked = now;
	458                             break;
	459                         }
	460							
								/*	有问题的服务器，将权重设为0，让他先休息一会	*/
	461                         peer->current_weight = 0;
	462 
	463                     } else {	/*	down设置位图标记???	*/
	464                         rrp->tried[n] |= m;		/*	设置位图标记	*/
	465                     }
	466						
							/*	如果执行到这里说明没有执行break,表示检验不通过	*/
							/*	tries表示该连接失败，可以重试机器数-1			*/
	467                     pc->tries--;	
	468                 }
	469					
						/*	如果没有可以重试的机器了则错误	*/
	470                 if (pc->tries == 0) {
	471                     goto failed;
	472                 }
	473 
	474                 if (--i == 0) {
	475                     ngx_log_error(NGX_LOG_ALERT, pc->log, 0,
	476                                   "round robin upstream stuck on %ui tries",
	477                                   pc->tries);
	478                     goto failed;
	479                 }
	480             }
	481				/*	break直接跳出来，当前权重减一，时时改变	*/ 
	482             peer->current_weight--;
	483 
	484         } else {
	485 
					/*	非第一次进行选择,不是使用轮询，而是利用current进行遍历了	*/
	486             i = pc->tries;
	487 
	488             for ( ;; ) {
						/*rrp->current此时是之前返回的权值最大的服务器下标+1(如果是第二次的话)*/
	489                 n = rrp->current / (8 * sizeof(uintptr_t));
	490                 m = (uintptr_t) 1 << rrp->current % (8 * sizeof(uintptr_t));
	491 
	492                 if (!(rrp->tried[n] & m)) {
	493 
	494                     peer = &rrp->peers->peer[rrp->current];
	495						
							/*	与上面的判断类似	*/
	496                     if (!peer->down) {
	497 
	498                         if (peer->max_fails == 0
	499                             || peer->fails < peer->max_fails)
	500                         {
	501                             break;
	502                         }
	503 
	504                         if (now - peer->checked > peer->fail_timeout) {
	505                             peer->checked = now;
	506                             break;
	507                         }
	508 
	509                         peer->current_weight = 0;
	510 
	511                     } else {
	512                         rrp->tried[n] |= m;
	513                     }
	514 
	515                     pc->tries--;
	516                 }
	517 
	518                 rrp->current++;		/*	没有释放，所以要在这里自增	*/
	519 
						/*	超过主机数量，就要从头开始	*/
	520                 if (rrp->current >= rrp->peers->number) {
	521                     rrp->current = 0;
	522                 }
	523					
						/*	可以尝试的主机数为0	*/
	524                 if (pc->tries == 0) {
	525                     goto failed;
	526                 }
	527 
	528                 if (--i == 0) {
	529                     ngx_log_error(NGX_LOG_ALERT, pc->log, 0,
	530                                   "round robin upstream stuck on %ui tries",
	531                                   pc->tries);
	532                     goto failed;
	533                 }
	534             }
	535			 	
					/*	权重值减少一	*/
	536             peer->current_weight--;
	537         }
	538			/*	无论是第一次还是第二次，都要将选择了的进行标记	*/ 
	539         rrp->tried[n] |= m;
	540     }
	541 
	542     pc->sockaddr = peer->sockaddr;
	543     pc->socklen = peer->socklen;
	544     pc->name = &peer->name;
	545 
	546     /* ngx_unlock_mutex(rrp->peers->mutex); */
	547 
	548     if (pc->tries == 1 && rrp->peers->next) {
	549         pc->tries += rrp->peers->next->number;
	550 
	551         n = rrp->peers->next->number / (8 * sizeof(uintptr_t)) + 1;
	552         for (i = 0; i < n; i++) {
	553              rrp->tried[i] = 0;
	554         }
	555     }
	556 
	557     return NGX_OK;
	558	
		/*	使用后备服务器(如果有的话)对错误情况进行处理	*/
	559 failed:
	560 
	561     peers = rrp->peers;
	562 	
			/*	如果非后备服务器都出错了，
				此时如果有后备服务器就切换到后备服务器
				如果连后备服务器都搞不定就返回NGX_BUSY	
			*/
	563     if (peers->next) {
	564 
	565         /* ngx_unlock_mutex(peers->mutex); */
	566 
	567         ngx_log_debug0(NGX_LOG_DEBUG_HTTP, pc->log, 0, "backup servers");
	568 
	569         rrp->peers = peers->next;
	570         pc->tries = rrp->peers->number;
	571 		
				/*	rrp->peers->number是后备服务器的数量	*/
	572         n = rrp->peers->number / (8 * sizeof(uintptr_t)) + 1;
	573         for (i = 0; i < n; i++) {
	574              rrp->tried[i] = 0;	/*	位图清0	*/
	575         }
	576 
				/*	
					对后备服务器执行函数ngx_http_upstream_get_round_robin_peer
					对后备服务器进行相关非后备服务器的类似操作
					如果连后备服务器都失败则rc==NGX_BUSY
				*/
	577         rc = ngx_http_upstream_get_round_robin_peer(pc, rrp);
	578				 
	579         if (rc != NGX_BUSY) {
	580             return rc;
	581         }
	582 
	583         /* ngx_lock_mutex(peers->mutex); */
	584     }
	585 
	586     /* all peers failed, mark them as live for quick recovery */
	587 
	588     for (i = 0; i < peers->number; i++) {
	589         peers->peer[i].fails = 0;
	590     }
	591 
	592     /* ngx_unlock_mutex(peers->mutex); */
	593 
	594     pc->name = peers->name;
	595 
	596     return NGX_BUSY;
	597 }

核心流程:

![002]({{ site.img_url }}/2014/05/002.png)


对于只有一台后端服务器的情况，Nginx直接选择它并返回，如果有多台后端服务器，对于第一次选择，Nginx会循环调用函数ngx_http_upstream_get_peer()按照各台服务器的当前值进行选择，如果第一次选择的服务器因链接失败或是其他情况导致需要重新选择另外一台服务器，Nginx采用的就是简单的遍历，起始节点为rrp->current，但是这个值会在对第一次选择结果进行释放时自增1,也就是说起始节点和第一次选择节点并没有重复。

图中没有给出对非后备服务器全部选择failed失败的情况，如果出现这种情况，则此时将尝试后备服务器，同样是对服务器列表进行选择，所以处理的情况与非后备服务器相似，只是将相关变量进行了切换,如果此时后备服务器也选择失败，那么函数将返回NGX_BUSY，这意味这没有后端服务器来处理该请求，Nginx将获得502错误，Nginx可以直接将这个错误发送到客户端，或者对它做替换处理。



#### 后端服务器的权值计算

	600 static ngx_uint_t
	601 ngx_http_upstream_get_peer(ngx_http_upstream_rr_peers_t *peers)
	602 {
	603     ngx_uint_t                    i, n, reset = 0;
	604     ngx_http_upstream_rr_peer_t  *peer;
	605 
	606     peer = &peers->peer[0];
	607 
	608     for ( ;; ) {
	609 
	610         for (i = 0; i < peers->number; i++) {
	611				
					/*	已经休息的服务器不用计算	*/
	612             if (peer[i].current_weight <= 0) {
	613                 continue;
	614             }
	615 
	616             n = i;
	617 
	618             while (i < peers->number - 1) {
	619 
	620                 i++;
	621 				
						/*	
							如果都小于0,则都跳过了，此时i等于peers->number-1，
							在执行for中的i++，i变为peers->number
						*/

	622                 if (peer[i].current_weight <= 0) {
	623                     continue;		
	624                 }
	625 
						/*	权重的核心计算	
							初始状态中peer[n].current_weight等于peer[n].weight
							peer[i].current_weight等于peer[i].weight
							乘以1000的目的是避免浮点运算，直接将除数放大1000倍，也就是间接的将精度提升到小数点后三位
							由于是比较大小，所以同时提高1000倍不会影响结果。
						*/
	626                 if (peer[n].current_weight * 1000 / peer[i].current_weight
	627                     > peer[n].weight * 1000 / peer[i].weight)
	628                 {
	629                     return n;
	630                 }
	631 
	632                 n = i;
	633             }
	634 
	635             if (peer[i].current_weight > 0) {
	636                 n = i;
	637             }
	638				/*	如果权值都小于0,此处不会被执行	*/ 
	639             return n;
	640         }	/*	for结束	*/
	641
				/*	当所有权值都小于0的时候，将他们进行重置，重置为配置文件中的权值	*/
	642         if (reset++) {
	643             return 0;
	644         }
	645			/*	重置权值	*/ 
	646         for (i = 0; i < peers->number; i++) {
	647             peer[i].current_weight = peer[i].weight;
	648         }
	649     }
	650 }


假设有三台后端服务器A、B、C,他们的初始权值为5、3、1,则初始状态中peer[n].current_weight等于peer[n].weight并且peer[i].current_weight等于peer[i].weight，所以Nginx选择服务器C，不过随着后续current_weight权重的改变，各个服务器的权值将会发生变化，客户端的请求也会按照5:3:1的形式分布到A、B、C上，并且相对空闲的服务器会有更多机会被选中


#### 释放后端服务器

分两种情况:

1.连接后端服务器并且正常处理当前客户请求后释放后端服务器。这种的处理工作比较简单。

2.在某一轮选择中，某次选择的服务器因连接失败或请求处理失败二需要重新进行选择。这就需要一些额外的处理了。


	653 void
	654 ngx_http_upstream_free_round_robin_peer(ngx_peer_connection_t *pc, void *data,
	655     ngx_uint_t state)
	656 {
	657     ngx_http_upstream_rr_peer_data_t  *rrp = data;
	658 
	659     time_t                       now;
	660     ngx_http_upstream_rr_peer_t  *peer;
	661 
	662     ngx_log_debug2(NGX_LOG_DEBUG_HTTP, pc->log, 0,
	663                    "free rr peer %ui %ui", pc->tries, state);
	664
			/*	正常情况，直接返回了，对应情况1	*/
	665     if (state == 0 && pc->tries == 0) {
	666         return;
	667     }
	668 
	669     /* TODO: NGX_PEER_KEEPALIVE */
	670 
	671     if (rrp->peers->single) {
	672         pc->tries = 0;
	673         return;
	674     }
	675 
	676     peer = &rrp->peers->peer[rrp->current];
	677
			/*	一下都是对失败情况进行处理,对应情况2		*/
	678     if (state & NGX_PEER_FAILED) {
	679         now = ngx_time();
	680 
	681         /* ngx_lock_mutex(rrp->peers->mutex); */
	682 
	683         peer->fails++;				/*	已经失败的次数	*/
	684         peer->accessed = now;
	685         peer->checked = now;
	686 		
				/*	设置了max_fails非0的话，默认就是1	*/
	688             peer->current_weight -= peer->weight / peer->max_fails;
	689         }
	690 
	691         ngx_log_debug2(NGX_LOG_DEBUG_HTTP, pc->log, 0,
	692                        "free rr peer failed: %ui %i",
	693                        rrp->current, peer->current_weight);
	694			
				/*	权重<0也将它置0,让他去休息吧！	*/
	695         if (peer->current_weight < 0) {
	696             peer->current_weight = 0;
	697         }
	698 
	699         /* ngx_unlock_mutex(rrp->peers->mutex); */
	700
	701     } else {
	702 
	703         /* mark peer live if check passed */
	704			/*	???		*/ 
	705         if (peer->accessed < peer->checked) {
	706             peer->fails = 0;
	707         }
	708     }
	709 
	710     rrp->current++;	/*	自增1，current与第二次选择有关，可以看下第二次选择	*/
	711		
			/*	越界了，重新置为0,从头开始选择服务器	*/
	712     if (rrp->current >= rrp->peers->number) {
	713         rrp->current = 0;
	714     }
	715		/*	可以尝试的次数又减少了	*/ 
	716     if (pc->tries) {
	717         pc->tries--;
	718     }
	719 
	720     /* ngx_unlock_mutex(rrp->peers->mutex); */
	721 }

如果连接失败(不管是连接失败还是请求处理失败)，此时需要更新fails等变量;

如果成功，则需要判断一个fail_timeout时间段已过，才能重置fails的值，如果不这样做，那么可能得到值两个错误

要么将当前fail_timeout时间段内的失败次数统计错误，要么将当前fail_timeout时间段内的失败次数累加到下一个fail_timeout时间段。




默认情况下。在一轮选择中，如果是链接错误或者是链接超时导致的失败，那么Nginx会尽量尝试每一台后端服务器进行请求处理，直到全部失败才会返回502错误。当然在配置文件中可以修改，例如proxy_next_upstream或是fastcgi_next_upstream.

例如:	

	fastcgi_next_upstream http_404;

使得Nginx仅仅在上一台后端服务器返回404错误的情况下，才会尝试重新选择，否中直接返回对应的错误，500或是502。
也就是说只有返回的错误类型与指定的相同，才会尝试重新选择。

这部分由ngx_http_upstream_next来实现


	2814 static void
	2815 ngx_http_upstream_next(ngx_http_request_t *r, ngx_http_upstream_t *u,
	2816     ngx_uint_t ft_type)
	2817 {
					......
					/*	全部尝试完毕了，或者是u->conf->next_upstream与配置文件中指定的类型不同	*/
	2883         if (u->peer.tries == 0 || !(u->conf->next_upstream & ft_type)) {
	2884 	
					/*	最终的返回	*/
	2904             ngx_http_upstream_finalize_request(r, u, status);
	2905             return;
	2906         }
	2907     }


整个加权轮询的大体流程图:
	
![003]({{ site.img_url }}/2014/05/003.png)



