---
layout: post
title: nginx模块--handler|filter|upstream
description: 
modified: 
categories: 
- Nginx 
tags:
- 模块
---

Nginx的模块根据主要功能分为以下四个类别:

#### 1.handlers:
协同完成客户端请求的处理、产生响应数据

#### 2.filter:
对handlers产生的响应数据做各种过滤处理(增删改)，例如ngx_http_not_module_filter_module，对待响应的数据进行顾虑检测，如果通过时间戳判断出前后两次请求的响应数据没有任何实质改变，那么就直接响应"304 Not Modified"标识，让客户端使用本地缓存即可，而原本待发送的响应数据将被清除

#### 3.upstream:
如果存在后端真实服务器，Nginx可以利用upstream做反向代理，对客户端发起的请求只负责转发，也包括对服务器响应数据的回转

#### 4.load-balance:
在Nginx充当中间代理角色的时候由于后端真实服务器往往多于一个，对于某一次客户端的请求选择对应的后端服务器进行处理。



nginx的所有代码都是以模块的形式进行组织，nginx的模块结构体ngx_module_s封装模块

	111 struct ngx_module_s {
	112     ngx_uint_t            ctx_index;						/*	当前模块在同类模块中的序号	*/
	113     ngx_uint_t            index;							/*	当前模块在所有模块中的序号	*/
	114 
	115     ngx_uint_t            spare0;							
	116     ngx_uint_t            spare1;							
	117     ngx_uint_t            spare2;								
	118     ngx_uint_t            spare3;	
	119 
	120     ngx_uint_t            version;							/*		当前模块版本号			*/
	121     
	122     void                 *ctx;								/*	指向当前模块特有数据		*/
	123     ngx_command_t        *commands;							/*	指向当前模块配置项解析数组	*/
	124     ngx_uint_t            type;								/*			模块类型			*/
	125
				/*	以下是回调函数	*/
	126     ngx_int_t           (*init_master)(ngx_log_t *log);
	127 
	128     ngx_int_t           (*init_module)(ngx_cycle_t *cycle);
	129 
	130     ngx_int_t           (*init_process)(ngx_cycle_t *cycle);
	131     ngx_int_t           (*init_thread)(ngx_cycle_t *cycle);
	132     void                (*exit_thread)(ngx_cycle_t *cycle);
	133     void                (*exit_process)(ngx_cycle_t *cycle);
	134 
	135     void                (*exit_master)(ngx_cycle_t *cycle);
	136 
	137     uintptr_t             spare_hook0;
	138     uintptr_t             spare_hook1;
	139     uintptr_t             spare_hook2;
	140     uintptr_t             spare_hook3;
	141     uintptr_t             spare_hook4;
	142     uintptr_t             spare_hook5;
	143     uintptr_t             spare_hook6;
	144     uintptr_t             spare_hook7;
	145 };

type值只有5中可能

		type的值				ctx指向数据类型

	NGX_CORE_MODULE				ngx_core_module_t
	
	NGX_EVENT_MODULE			ngx_event_module_t
	
	NGX_CONF_MODULE				NULL
	
	NGX_HTTP_MODULE				ngx_http_module_t
	
	NGX_MAIL_MODULE				ngx_mail_module_t


ctx指向的数据类型中基本都是一些回调函数,这些回调函数会在其模块对应的配置文件解析过程前/中/后被适时调用,做一些内存准备,初始化,配置值检测,初始值填充与合并,回调函数挂载等初始工作.

以ngx_http_core_module模块为例,其type类型为NGX_HTTP_MODULE,ctx指向的ngx_http_module_t结构体变量ngx_http_core_module_ctx

	786 static ngx_http_module_t  ngx_http_core_module_ctx = {
	787     ngx_http_core_preconfiguration,        /* preconfiguration */
	788     NULL,                                  /* postconfiguration */
	789 
	790     ngx_http_core_create_main_conf,        /* create main configuration */
	791     ngx_http_core_init_main_conf,          /* init main configuration */
	792 
	793     ngx_http_core_create_srv_conf,         /* create server configuration */
	794     ngx_http_core_merge_srv_conf,          /* merge server configuration */
	795     
	796     ngx_http_core_create_loc_conf,         /* create location configuration */
	797     ngx_http_core_merge_loc_conf           /* merge location configuration */
	798 };  


根据后面的英文注释,我们可以很明显的看出各个回调函数的回调时机,例如ngx_http_core_preconfiguration将会在http块配置解析之前被调用

	118 static char *
	119 ngx_http_block(ngx_conf_t *cf, ngx_command_t *cmd, void *conf)
	120 {
				....
	228         /*  在解析之前调用  */
	229         if (module->preconfiguration) {
	230             if (module->preconfiguration(cf) != NGX_OK) {
	231                 return NGX_CONF_ERROR;
	232             }
	233         }
	234     }
	235 
	236     /* parse inside the http{} block */
	237 
	238     cf->module_type = NGX_HTTP_MODULE;
	239     cf->cmd_type = NGX_HTTP_MAIN_CONF;
	240     /*  开始解析    */
	241     rv = ngx_conf_parse(cf, NULL);
	

可以看到在函数ngx_http_block中确实是在解析前调用了preconfiguration函数


#### handle模块
对于客户端的HTTP请求,Nginx将其整个过程细分为了多个阶段,每一个阶段都可以有零到多个回调函数专门处理,我们自己写handler模块时候必须将模块功能处理函数挂载到正确的阶段点上.

http请求的整个处理过程一共分为11个阶段,每个阶段对应的处理功能都比较单一,这样使得Nginx模块代码更为内聚,这11个阶段是Nginx处理客户端请求的核心所在,在实际处理过程中,因为等待时间或内部转跳或子请求等会导致这些阶段被返回执行,但是在任何时刻,对末个指定的客户端请求而言,对应的request对象总是处于某个确切的阶段;

	序号			阶段宏名				阶段描述
	0		NGX_HTTP_POST_READ_PHASE				请求头读取完成之后的阶段
	1		NGX_HTTP_SERVER_REWRITE_PHASE	server内请求地址重写阶段
	2		NGX_HTTP_FIND_CONFIG_PHASE		配置查找阶段
	3		NGX_HTTP_REWIRET_PHASE			location内请求地址重写阶段
	4		NGX_HTTP_POST_REWRITE_PHASE		请求地址重写完成之后的阶段
	5		NGX_HTTP_PREACCESS_PHASE		访问权限检查准备阶段
	6		NGX_HTTP_ACCESS_PHASE			访问权限检查阶段
	7		NGX_HTTP_POST_ACCESS_PHASE		访问权限检查完成之后阶段	
	8		NGX_HTTP_TRY_FILES_PHASE		配置项try_files处理阶段
	9		NGX_HTTP_CONTENT_PHASE			内容产生阶段
	10		NGX_HTTP_LOG_PHASE				日志模块处理阶段
	

##### NGX_HTTP_READ_PHASE:

当Nginx成功收到一个客户端请求后(即函数accept正确返回对应的套接字描述符,链接建立),针对该请求所做的第一个实际工作就是读取客户端发来的请求头内容,如果在这个阶段挂上一个对应的回调函数,那么在Nginx读取并解析完客户端请求头内容后,就会执行这些回调函数.

##### NGX_HTTP_SERVER_REWRITE_PHASE:

与NGX_HTTP_REWIRET_PHASE都属于地址重写,也都是针对rewrite模块而设定的阶段,前者用于server上下文的地址重写,后者用于location上下文里的地址重写,为什么需要两个地址重写阶段?因为在rewrite模块的相关指令(rewrite,if,set等)即可用于server上下文,又可以用于location上下文,在客户端请求被Nginx接收后,首先做server查找与定位,在定位到server(如果没有就是默认server)后执行NGX_HTTP_SERVER_REWRITE_PHASE阶段上的回调函数,然后在进入到下一阶段NGX_HTTP_FIND_CONFIG_PHASE;

具体的流程是:
								ngx_http_find_virtual_server()
	客户端请求	-->	读取&解析请求头		----> server定位与查找	---->NGX_HTTP_POST_READ_PHASE	---->	NGX_HTTP_SERVER_REWRITE_PHASE
	accept			ngx_http_process_request_headers


##### NGX_HTTP_FIND_CONFIG_PHASE:

该阶段不能挂载任何回调函数,因为他们永远不会被执行,该阶段是完成Nginx的特定任务,即进行location定位,只有把当前请求对应的location找到,才能从该location上下文中取出更多精确的用户配置值,做后续的处理

##### NGX_HTTP_REWIRET_PHASE:

经过上个阶段的处理,Nginx已经定位到当前请求的对应的location上,此时进入NGX_HTTP_REWIRET_PHASE进行地址重写,和第一阶段的地址重写没有太多区别,唯一区别在于定义在location里的地址重写规则只会对被定位到当前locatino的请求才生效,意思就是他们的作用域不同.

##### NGX_HTTP_POST_REWRITE_PHASE:

该阶段在基尼下嗯地址重写之后,具体是在location请求地址重写阶段之后,这个阶段不会执行任何回调函数,它本身也是完成Nginx特定任务,即检查当前请求时候做了过多的内部转跳,我们不能让对一个请求的处理在Nginx内转跳很多次甚至是死循环,每转跳一次基本所有的流程都要重新走一遍,这是非常消耗性能的,如果转跳次数超过限定值NGX_HTTP_MAX_URI_CHANGES(宏值为10),那么就直接返回状态码500给客户端提示当前服务器发生内部错误,这种情况多半是配置文件写的有问题.

##### NGX_HTTP_PREACCESS_PHASE+NGX_HTTP_ACCESS_PHASE+NGX_HTTP_POST_READ_PHASE:

做访问权限检查的前期中期后期工作,其中后期工作是固定的,判断前面访问权限检查的结果,其中后期工作是固定的,判断前面访问权限检查的结果(状态码存放在字段r->access_code中),如果当前请求没有访问权限,那么直接返回状态403错误,所以这个阶段也无法去挂载额外的回调函数

NGX_HTTP_TRY_FILES_PHASE是针对配置项try_files的特定处理阶段,所以也无法挂载额外回调函数

NGX_HTTP_LOG_PHASE是针对日志模块的特定处理阶段,所以也无法挂载额外回调函数


一般情况下,我们自己定义模块的回调函数都是挂载在NGX_HTTP_CONTENT_PHASE阶段,因为大部分业务都是在修改http响应数据,nginx自身产生响应内容的模块ngx_http_static_module等也都挂载在这个阶段.

大多数情况下,功能模块会在其对应配置解析完成后去回调对应函数,也就是说ngx_http_module_t结构体的postconfiguration字段指向的函数内将当枪模块的回调功能函数挂载到这11个阶段中的一个上

	17 ngx_http_module_t  ngx_http_static_module_ctx = {
	18     NULL,                                  /* preconfiguration */
	19     ngx_http_static_init,                  /* postconfiguration */
	20 
	21     NULL,                                  /* create main configuration */
	22     NULL,                                  /* init main configuration */
	23 
	24     NULL,                                  /* create server configuration */
	25     NULL,                                  /* merge server configuration */
	26 
	27     NULL,                                  /* create location configuration */
	28     NULL                                   /* merge location configuration */
	29 };


	270 static ngx_int_t
	271 ngx_http_static_init(ngx_conf_t *cf)
	272 {
	273     ngx_http_handler_pt        *h;
	274     ngx_http_core_main_conf_t  *cmcf;
	275 
	276     cmcf = ngx_http_conf_get_module_main_conf(cf, ngx_http_core_module);
	277 
			/*	h对应这cmcf->phases数组的[NGX_HTTP_CONTENT_PHASE]的空闲位置	*/
	278     h = ngx_array_push(&cmcf->phases[NGX_HTTP_CONTENT_PHASE].handlers);
	279     if (h == NULL) {
	280         return NGX_ERROR;
	281     }
	282		/*	向数组中添加了回调函数	*/ 
	283     *h = ngx_http_static_handler;
	284 
	285     return NGX_OK;
	286 }

可以看到在模块ngx_http_static_module的postconfiguration回调函数ngx_http_static_init内,将ngx_http_static_module模块的核心功能函数ngx_http_static_handler挂载在http请求处理流程的NGX_HTTP_CONTENT_PHASE阶段,这样,当一个客户端的http静态页面请求发送送到Nginx服务器,Nginx就能够调用到我们这里注册的ngx_http_static_handler函数;

各个模块将其自身的功能函数挂载在cmcf->phases之后如图所示:

![014]({{ site.img_url}}/2014/05/014.png)


回调函数会根据选用模块的不同而不同,这些回调函数的调用也是有条件的,调用后要做一些根据返回值的结果的处理,比如某次处理能否进入阶段NGX_HTTP_CONTENT_PHASE的回调函数中处理,还需要一个事前判断,所以函数ngx_http_init_phase_handlers里对所有这些回调函数进行一次重组,结果如图:

![015]({{ site.img_url}}/2014/05/015.png)

可以看到ngx_http_static_module之前要运行checker函数ngx_http_core_content_phase.

ngx_http_init_phase_handlers对回调函数进行了重组,利用ngx_http_phase_handler结构体数组将这些回调函数进行了重组,不仅仅加上了回调函数的条件判断checker函数,还通过next字段,将原本的二维数组实现转化为可以直接在以为数组内不跳动,二维数组的遍历需要两层循环,而遍历以为数组只要一层循环.


对http请求分阶段处理的核心函数

	864 void
	865 ngx_http_core_run_phases(ngx_http_request_t *r)
	866 {
	867     ngx_int_t                   rc;
	868     ngx_http_phase_handler_t   *ph;
	869     ngx_http_core_main_conf_t  *cmcf;
	870 
	871     cmcf = ngx_http_get_module_main_conf(r, ngx_http_core_module);
	872 
	873     ph = cmcf->phase_engine.handlers;
	874 
	875     while (ph[r->phase_handler].checker) {
	876 
	877         rc = ph[r->phase_handler].checker(r, &ph[r->phase_handler]);
	878 
	879         if (rc == NGX_OK) {
	880             return;
	881         }
	882     }
	883 }
	
r->phase_handler表示当前处理的序号,对一个客户端请求处理的最开始时刻,该值就是0,while循环判断如果存在checker函数(末尾数组元素的checker是NULL),那么就调用该checker函数并有可能进行调用对应的回调函数

以NGX_HTTP_ACCESS_PHASE阶段的ngx_http_core_access_phase函数为例:

	1088 ngx_int_t
	1089 ngx_http_core_access_phase(ngx_http_request_t *r, ngx_http_phase_handler_t *ph)
	1090 {
	1091     ngx_int_t                  rc;
	1092     ngx_http_core_loc_conf_t  *clcf;
	1093 
			/*	如果非主请求,自然不必进行访问权限检查,直接进入下一阶段	*/
	1094     if (r != r->main) {
	1095         r->phase_handler = ph->next;	/*	直接进入下一阶段	*/
	1096         return NGX_AGAIN;
	1097     }
	1098 
	1099     ngx_log_debug1(NGX_LOG_DEBUG_HTTP, r->connection->log, 0,
	1100                    "access phase: %ui", r->phase_handler);
	1101 
			/*	否则要进行访问权限检查,执行回调	*/
	1102     rc = ph->handler(r);
	1103 
			/*	条件处理表示当前回调拒绝处理或是不符合它的处理条件,将会尝试使用下一个回调函数	*/
	1104     if (rc == NGX_DECLINED) {
	1105         r->phase_handler++;		/*	使用下一个回调函数	*/
	1106         return NGX_AGAIN;
	1107     }
	1108 
			/*	表示当前回调需要再次处理或者是已经成功处理	*/
	1109     if (rc == NGX_AGAIN || rc == NGX_DONE) {
				/*	
				*	直接返回会导致ngx_http_core_run_phases的循环处理退出,
				*	这表示状态机的继续处理需要等待更进一步的事件发生
				*	可以是子请求结束,socket描述符变得写可,超时等
				*	并且在进入到状态机处理函数时,仍将从当前回调开始
				*/
	1110         return NGX_OK;
	1111     }
	1112 
	1113     clcf = ngx_http_get_module_loc_conf(r, ngx_http_core_module);
	1114 
	1115     if (clcf->satisfy == NGX_HTTP_SATISFY_ALL) {
	1116 
	1117         if (rc == NGX_OK) {
	1118             r->phase_handler++;
	1119             return NGX_AGAIN;
	1120         }
	1121 
	1122     } else {
	1123         if (rc == NGX_OK) {
	1124             r->access_code = 0;
	1125 
	1126             if (r->headers_out.www_authenticate) {
	1127                 r->headers_out.www_authenticate->hash = 0;
	1128             }
	1129 
	1130             r->phase_handler = ph->next;
	1131             return NGX_AGAIN;
	1132         }
	1133 
	1134         if (rc == NGX_HTTP_FORBIDDEN || rc == NGX_HTTP_UNAUTHORIZED) {
	1135             r->access_code = rc;
	1136 
	1137             r->phase_handler++;
	1138             return NGX_AGAIN;
	1139         }
	1140     }
	1141 
	1142     /* rc == NGX_ERROR || rc == NGX_HTTP_...  */
			/*	一下是对发生错误的处理	*/
	1143 
	1144     ngx_http_finalize_request(r, rc);
	1145     return NGX_OK;
	1146 }



handler函数返回值的含义:

	返回值							含义
	NGX_OK							当前阶段已经被成功处理,必须进入到下一个阶段
	NGX_DECLINED					当前回调不出里当前情况,进入下一个回调处理
	NGX_AGAIN						当前处理所需资源不足,需要等待依赖事件发生
	NGX_DONE						当前处理结束,需要等待进一步事件发生后做处理
	NGX_ERROR\NGX_HTTP_...			当前回调处理发生错误,需要进入异常处理流程

由于回调函数的返回值会影响到统一阶段的后续回调函数的处理与否,Nginx采用先进后出的方案,即先注册的模块,其回调函数反而后执行,所以回调函数或者说是模块的先后顺序非常重要,以NGX_HTTP_CONTENT_PHASE阶段的三个回调函数为例

在objs/ngx_modules.c中可以看到

	18 extern ngx_module_t  ngx_http_static_module;
	19 extern ngx_module_t  ngx_http_autoindex_module;
	20 extern ngx_module_t  ngx_http_index_module;

这三个模块的注册先后顺序,而前面图中的调用顺序确实相反的,即ngx_http_index_module-->ngx_http_autoindex_module-->ngx_http_static_module的顺序执行,这个顺序是合理的.比如我们打开Nginx服务器,直接访问一个目录,那么Nginx先是查看当前目录下是否存在index.html/index.htm/index.php之类的默认显示页面,这是回调函数ngx_http_index_module的工作,如果不存在这样的页面查看是否允许显示列表页面,这属于ngx_http_autoindex_module函数的工作,而ngx_http_static_handler回调函数则是根据客户端静态页面请求查找对应的页面文件并组成待响应内容.

可以看到虽然这三个函数都是挂载在NGX_HTTP_CONTENT_PHASE阶段,但是各自实现的功能却存在先后关系,如果ngx_http_autoindex_module在ngx_http_index_module之前,那么对于本来存在默认显示页面的目录进行列表显示,这显然是错误的.


#### filter模块

对于http请求处理handlers产生的响应内容,在输出到客户端之前需要做过滤处理,这些过滤处理对于完成功能的增强实现与性能的提升是非常有必要的.例如ngx_http_chunked_filter_module用来支持HTTP1.1协议的chunk功能.ngx__http_not__modified_filter_module过滤模块使得客户端使用本地缓存来提高性能,这些都需要过滤模块的支持.

由于响应数据包含响应头和响应体,所以与之对应,Filter模块必须提供处理响应头的header过滤功能函数或者提供处理响应体body过滤功能函数,或者两者皆有.

所有的header过滤功能函数和body过滤功能函数会分别组成各自的两条过滤链,如图:
	
![016] ({{ site.img_url}}/2014/05/016.png)

文件ngx_http.c中

	72 ngx_int_t  (*ngx_http_top_header_filter) (ngx_http_request_t *r);
	73 ngx_int_t  (*ngx_http_top_body_filter) (ngx_http_request_t *r, ngx_chain_t *ch);

这是整个Nginx范围内可见的全局变量,然后在每一个filter模块内,我们还可以看到类似定义(如果当前模块只有header过滤功能函数或是之后body过滤功能函数,那么如下定义也只用对应的变量)

	233 static ngx_http_output_header_filter_pt  ngx_http_next_header_filter;
	234 static ngx_http_output_body_filter_pt    ngx_http_next_body_filter;

注意static,也就是说这两个变量属于模块范围内的可见局部变量,有了这些函数指针变量,在各个filter模块的postconfiguration回调函数内,全局变量与局部变量巧妙赋值最终形成了两条过滤链


	40 extern ngx_module_t  ngx_http_header_filter_module;
	41 extern ngx_module_t  ngx_http_chunked_filter_module;
	42 extern ngx_module_t  ngx_http_range_header_filter_module;
	43 extern ngx_module_t  ngx_http_gzip_filter_module;
	44 extern ngx_module_t  ngx_http_postpone_filter_module;
	45 extern ngx_module_t  ngx_http_ssi_filter_module;
	46 extern ngx_module_t  ngx_http_charset_filter_module;
	47 extern ngx_module_t  ngx_http_userid_filter_module;
	48 extern ngx_module_t  ngx_http_headers_filter_module;
	
	objs/modulus.c 中ngx_http_header_filter_module是具有header过滤功能函数的序号最小的过滤模块,我们以ngx_http_header_filter_module为例,其postconfiguration回调函数如下:

	617 static ngx_int_t
	618 ngx_http_header_filter_init(ngx_conf_t *cf)
	619 {
	620     ngx_http_top_header_filter = ngx_http_header_filter;
	621 
	622     return NGX_OK;
	623 }


此时ngx_http_top_header_filter指向了ngx_http_header_filter,接着nginx初始化在继续执行到下一序号的带有header过滤功能函数的过滤模块的postconfiguration回调函数中;

	232 static ngx_int_t
	233 ngx_http_chunked_filter_init(ngx_conf_t *cf)
	234 {
	235     ngx_http_next_header_filter = ngx_http_top_header_filter;
	236     ngx_http_top_header_filter = ngx_http_chunked_header_filter;
	237 
	238     ngx_http_next_body_filter = ngx_http_top_body_filter;
	239     ngx_http_top_body_filter = ngx_http_chunked_body_filter;
	240 
	241     return NGX_OK;
	242 }

可以看到这时候

![017]({{ site.img_url }}/2014/05/017.png)

其他模块类似,最终形成了完整的header过滤链,body过滤链的形成也是类似,两条过滤链形成后,其对应的调用入口分别在ngx_http_send_header和函数ngx_http_output_filter内

	1889 ngx_int_t
	1890 ngx_http_send_header(ngx_http_request_t *r)
	1891 {
	1892     if (r->err_status) {
	1893         r->headers_out.status = r->err_status;
	1894         r->headers_out.status_line.len = 0;
	1895     }
	1896 	/*	调用header链	*/
	1897     return ngx_http_top_header_filter(r);	
	1898 }


	1901 ngx_int_t
	1902 ngx_http_output_filter(ngx_http_request_t *r, ngx_chain_t *in)
	1903 {
	1904     ngx_int_t          rc;
	1905     ngx_connection_t  *c;
	1906 
	1907     c = r->connection;
	1908     
	1909     ngx_log_debug2(NGX_LOG_DEBUG_HTTP, c->log, 0,
	1910                    "http output filter \"%V?%V\"", &r->uri, &r->args);
	1911 
			/*	调用body链表	*/
	1912     rc = ngx_http_top_body_filter(r, in);
	1913 
	1914     if (rc == NGX_ERROR) {
	1915         /* NGX_ERROR may be returned by any filter */
	1916         c->error = 1;
	1917     }
	1918 
	1919     return rc;
	1920 }

这两个函数主要通过链表的连头函数指针全局变量进入到两条过滤链内,进而依次执行链上的各个函数,例如ngx_http_top_header_filter指向的是ngx_http_not_module_filter_module函数,因此进入该函数内执行,在该函数执行的过程中又会根据情况,继续通过当前模块内的函数指针局部变量ngx_http_next_header_filter间接的去调用到header过滤链的下一个过滤函数,这对过滤链的前后承接是非常必要的.


		/*	局部变量函数指针	*/
	49 static ngx_http_output_header_filter_pt  ngx_http_next_header_filter;
	50 
	51 
		/*	
		*	ngx_http_next_header_filter指针现在初始化函数中被设定
		*	之后才在ngx_http_not_modified_header_filter中被调用	
		*/
	52 static ngx_int_t
	53 ngx_http_not_modified_header_filter(ngx_http_request_t *r)
	54 {
	55     if (r->headers_out.status != NGX_HTTP_OK
	56         || r != r->main
	57         || r->headers_out.last_modified_time == -1)
	58     {
	59         return ngx_http_next_header_filter(r);
	60     }
	61 
	62     if (r->headers_in.if_unmodified_since) {
	63         return ngx_http_test_precondition(r); 
	64     }
	65 
	66     if (r->headers_in.if_modified_since) {
	67         return ngx_http_test_not_modified(r);
	68     }
	69 
	70     return ngx_http_next_header_filter(r);
	71 }

		/*	
		*	ngx_http_next_header_filter指针现在初始化函数中被设定
		*	之后才在ngx_http_not_modified_header_filter中被调用	
		*/
	136 static ngx_int_t
	137 ngx_http_not_modified_filter_init(ngx_conf_t *cf)
	138 {
	139     ngx_http_next_header_filter = ngx_http_top_header_filter;
	140     ngx_http_top_header_filter = ngx_http_not_modified_header_filter;
	141 
	142     return NGX_OK;
	143 }


更具HTTP协议具备的响应头来影响或决定响应体的内容的特点,一般是先对响应头进行过滤,根据头过滤处理返回值在对响应体进行过滤处理,如果在响应头过滤处理出错或是某些特定的情况下,响应体过滤处理可以不用再进行.

#### upstream模块

upstream模块与具体协议无关,除了支持HTTP,还支持FASTCGI等协议

upstream的典型应用就是反向代理,其配置文件如下:

	http {
	.....
	
		#都是在本机运行
		upstream backend {
			server localhost:8000;
			server localhost:9000;
		}

		server {
			listen 80;
			...

			location / {
				#禁用nginx反向代理的缓存功能,保证客户端的每次请求都被转发到后端真实服务器上
				proxy_buffering off;
				#此配置项将当前请求反向代理到URL参数指定的服务器上,URL可以是主机名或是ip加端口的形式
				proxy_pass	http://backend;
			}
		}
	}







