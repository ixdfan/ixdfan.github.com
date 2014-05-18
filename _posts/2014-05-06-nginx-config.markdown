---
layout: post
title: nginx配置解析 
description: 
modified: 
categories: 
- Nginx
tags:
- 
---

为了统一配置项目的解析，nginx利用ngx_command_s数据类型对所有的nginx配置项目进行统一的描述
	
	78 struct ngx_command_s {
	79     ngx_str_t             name;			/*	配置名	*/
	80     ngx_uint_t            type;			/*	表示配置值的类型	*/

			/*	对应配置指令的回调函数	*/
	81     char               *(*set)(ngx_conf_t *cf, ngx_command_t *cmd, void *conf);
	82     ngx_uint_t            conf;
	83     ngx_uint_t            offset;		/*	指向转换后控制值的存放位置	*/
	84     void                 *post;			/*	在大多数情况下都为NULL	*/
	85 };
	86 
	87 #define ngx_null_command  { ngx_null_string, 0, NULL, 0, 0, NULL }

		
		/*	这个数组对所有可能出现的配置项进行描述，设定对应的回调函数	*/
	33 static ngx_command_t  ngx_core_commands[] = {
	34 
	35         /*  设置所有可能出现的配置项的回调函数以及其他对应的处理    */
	36     { ngx_string("daemon"),
	37       NGX_MAIN_CONF|NGX_DIRECT_CONF|NGX_CONF_FLAG,
	38       ngx_conf_set_flag_slot,
	39       0,
	40       offsetof(ngx_core_conf_t, daemon),
	41       NULL },
	42 
	43     { ngx_string("master_process"),
	44       NGX_MAIN_CONF|NGX_DIRECT_CONF|NGX_CONF_FLAG,
	45       ngx_conf_set_flag_slot,
	46       0,
	47       offsetof(ngx_core_conf_t, master),
	48       NULL },
	49 
	50     { ngx_string("timer_resolution"),
	51       NGX_MAIN_CONF|NGX_DIRECT_CONF|NGX_CONF_TAKE1,
	52       ngx_conf_set_msec_slot,
	53       0,
	54       offsetof(ngx_core_conf_t, timer_resolution),
	55       NULL },
	56 
	57     { ngx_string("pid"),
	58       NGX_MAIN_CONF|NGX_DIRECT_CONF|NGX_CONF_TAKE1,
	59       ngx_conf_set_str_slot,
	60       0,
	61       offsetof(ngx_core_conf_t, pid),
	62       NULL },
	63 
	64     { ngx_string("lock_file"),
	65       NGX_MAIN_CONF|NGX_DIRECT_CONF|NGX_CONF_TAKE1,
	66       ngx_conf_set_str_slot,
	67       0,
	68       offsetof(ngx_core_conf_t, lock_file),
	69       NULL },
	70 
	71     { ngx_string("worker_processes"),
	72       NGX_MAIN_CONF|NGX_DIRECT_CONF|NGX_CONF_TAKE1,
	73       ngx_conf_set_num_slot,
	74       0,
	75       offsetof(ngx_core_conf_t, worker_processes),
	76       NULL },
	77 
	78     { ngx_string("debug_points"),
	79       NGX_MAIN_CONF|NGX_DIRECT_CONF|NGX_CONF_TAKE1,
	80       ngx_conf_set_enum_slot,
	81       0,
	82       offsetof(ngx_core_conf_t, debug_points),
	83       &ngx_debug_points },
	84 
	85     { ngx_string("user"),
	86       NGX_MAIN_CONF|NGX_DIRECT_CONF|NGX_CONF_TAKE12,
	87       ngx_set_user,
	88       0,
	89       0,
	90       NULL },
	91 
	92     { ngx_string("worker_priority"),
	93       NGX_MAIN_CONF|NGX_DIRECT_CONF|NGX_CONF_TAKE1,
	94       ngx_set_priority,
	95       0,
	96       0,
	97       NULL },
	98 
	99     { ngx_string("worker_cpu_affinity"),
	100       NGX_MAIN_CONF|NGX_DIRECT_CONF|NGX_CONF_1MORE,
	101       ngx_set_cpu_affinity,
	102       0,
	103       0,
	104       NULL },
	105 
	106     { ngx_string("worker_rlimit_nofile"),
	107       NGX_MAIN_CONF|NGX_DIRECT_CONF|NGX_CONF_TAKE1,
	108       ngx_conf_set_num_slot,
	109       0,
	110       offsetof(ngx_core_conf_t, rlimit_nofile),
	111       NULL },
	112 
	113     { ngx_string("worker_rlimit_core"),
	114       NGX_MAIN_CONF|NGX_DIRECT_CONF|NGX_CONF_TAKE1,
	115       ngx_conf_set_off_slot,
	116       0,
	117       offsetof(ngx_core_conf_t, rlimit_core),
	118       NULL },
	119 
	120     { ngx_string("worker_rlimit_sigpending"),
	121       NGX_MAIN_CONF|NGX_DIRECT_CONF|NGX_CONF_TAKE1,
	122       ngx_conf_set_num_slot,
	123       0,
	124       offsetof(ngx_core_conf_t, rlimit_sigpending),
	125       NULL },
	126 
	127     { ngx_string("working_directory"),
	128       NGX_MAIN_CONF|NGX_DIRECT_CONF|NGX_CONF_TAKE1,
	129       ngx_conf_set_str_slot,
	130       0,
	131       offsetof(ngx_core_conf_t, working_directory),
	132       NULL },
	133 
	134     { ngx_string("env"),
	135       NGX_MAIN_CONF|NGX_DIRECT_CONF|NGX_CONF_TAKE1,
	136       ngx_set_env,
	137       0,
	138       0,
	139       NULL },
	140 
	141 #if (NGX_THREADS)
	142 
	143     { ngx_string("worker_threads"),
	144       NGX_MAIN_CONF|NGX_DIRECT_CONF|NGX_CONF_TAKE1,
	145       ngx_conf_set_num_slot,
	146       0,
	147       offsetof(ngx_core_conf_t, worker_threads),
	148       NULL },
	149 
	150     { ngx_string("thread_stack_size"),
	151       NGX_MAIN_CONF|NGX_DIRECT_CONF|NGX_CONF_TAKE1,
	152       ngx_conf_set_size_slot,
	153       0,
	154       offsetof(ngx_core_conf_t, thread_stack_size),
	155       NULL },
	156 
	157 #endif
	158 
	159       ngx_null_command
	160 };


以daemon配置名为例，当遇到配置文件中的daemon项目名时，nginx就会调用ngx_conf_set_flag_slot()回调函数来对其项目值进行解析，并根据是on还是off来将ngx_core_conf_t的daemon的字段值设置为1或0,这样就完成了配置项目信息到nginx内部实际值的转换过程

其中ngx_command_s结构体中的type字段指定该配置项的多种相关信息。

##### 配置的类型:

NGX_CONF_FLAG表示该配置项目是一个布尔类型的值，例如daemon就是一个布尔类型的配置项目，其值为on或off;

NGX_CONF_BLOCK表示该配置项目为负载配置项，因此有一个由大括号组织起来的多值块，比如配置项http、event等。


##### 配置项目的配置值的token个数:

NGX_CONF_NOARGS、NGX_CONF_TAKE1、NGX_CONF_TAKE2......NGX_CONF_TAKE7分别表示该配置项的配置值没有token、1个、2个......7个token;


NGX_CONF_TAKE12、NGX_CONF_TAKE123、NGX_CONF_1MORE表示这些配置项的配置值的token个数不定，分别为1个或2个、1个或2个或3个、1个以上;

##### 该配置项目所处的上下文:

NGX_MAIN_CONF:配置文件最外层，不包含期内的类似于http这样的配置块内部，即不向内延伸，其他上下文都有这个特性;

NGX_EVENT_CONF:event的配置块

NGX_HTTP_MAIN_CONF:HTTP配置块

NGX_HTTP_SRV_CONF:HTTP的server指令配置块

NGX_HTTP_LOC_CONF:HTTP的location指令配置块

......等等




post字段在大多数情况下都为NULL，但是在某些特殊配置项中也会指定其值，而且多为回调函数指针。

每个模块都把自己锁需要的配置项目对应的ngx_command_s结构图变量组成一个数组，以ngx_xxx_xxx_commands的形式命名，该数组以元素ngx_null_command作为结束标识


#### 配置文件解析流程

假设以命令

	nginx -c /usr/local/niginx/conf/nginx.conf

启动nginx
	
nginx.conf的内容如下:

	

	worker_processes  2;
	error_log  logs/error.log debug;	
	
	
	events {
	    worker_connections  1024;	
	}
	
	
	http {
	    include       mime.types;		# 文件类型
	    default_type  application/octet-stream;
	
	    server {
	        listen       8888;
	        server_name  localhost;
	
	        location / {
	            root   html;
	            index  index.html index.htm;
	        }
			error_page 404 /404.html
			error_page 500 502 503 504 /50x.html

			location = /50x.html {
				root html;
			}
		}
	}

	在函数ngx_conf_parse处下断点，我们可以看到ngx_conf_parse有两个参数

	Breakpoint 1, ngx_conf_parse (cf=cf@entry=0xbffff0c0, filename=filename@entry=0x80e3aa8) at src/core/ngx_conf_file.c:104
	104	src/core/ngx_conf_file.c: No such file or directory.
	Missing separate debuginfos, use: debuginfo-install glibc-2.18-11.fc20.i686 nss-softokn-freebl-3.15.2-2.fc20.i686 pcre-8.33-2.fc20.1.i686 zlib-1.2.8-3.fc20.i686
	(gdb) p *filename
	$2 = {len = 32, data = 0x80e3aff "/usr/local/nginx/conf/nginx.conf"}

第二个参数filename街头体中保存这配置文件路径的字符串

	ngx_str_t的定义
	16 typedef struct {
	17     size_t      len;
	18     u_char     *data;
	19 } ngx_str_t;


ngx_conf_parse()函数是执行配置文件解析的关键函数

ngx_conf_parse总体将配置内容的解析过程分为三部分

1.判断当前解析状态

2.读取配置标记token

3.读取了合适数量的标记token后对其进行实际的处理，也就是将配置值转换为Nginx内对应控制变量的值。

	103 ngx_conf_parse(ngx_conf_t *cf, ngx_str_t *filename)
	104 {
	105     char             *rv;
	106     ngx_fd_t          fd;
	107     ngx_int_t         rc;
	108     ngx_buf_t         buf;
	109     ngx_conf_file_t  *prev, conf_file;
			/*	三种状态	*/
	110     enum {
	111         parse_file = 0,
	112         parse_block,
	113         parse_param
	114     } type;
	115 
	116 #if (NGX_SUPPRESS_WARN)
	117     fd = NGX_INVALID_FILE;
	118     prev = NULL;
	119 #endif
	120 
			/*	首先判断路径是否存在	*/
	121     if (filename) {
	122 
	123         /* open configuration file */
	124 
	125         fd = ngx_open_file(filename->data, NGX_FILE_RDONLY, NGX_FILE_OPEN, 0);
	126         if (fd == NGX_INVALID_FILE) {
	127             ngx_conf_log_error(NGX_LOG_EMERG, cf, ngx_errno,
	128                                ngx_open_file_n " \"%s\" failed",
	129                                filename->data);
	130             return NGX_CONF_ERROR;
	131         }
	132 
	133         prev = cf->conf_file;
	134 
	135         cf->conf_file = &conf_file;
	136 
	137         if (ngx_fd_info(fd, &cf->conf_file->file.info) == -1) {
	138             ngx_log_error(NGX_LOG_EMERG, cf->log, ngx_errno,
	
	139                           ngx_fd_info_n " \"%s\" failed", filename->data);
	140         }
	141 
				/*	cf->conf_file->buffer将直接使用buf	*/
	142         cf->conf_file->buffer = &buf;
	143 			
				/*	分配buf的空间	*/
	144         buf.start = ngx_alloc(NGX_CONF_BUFFER, cf->log);
	145         if (buf.start == NULL) {
	146             goto failed;
	147         }
	148 
	149         buf.pos = buf.start;
	150         buf.last = buf.start;
	151         buf.end = buf.last + NGX_CONF_BUFFER;	/*	指定buf的空间范围,到end结束	*/
	152         buf.temporary = 1;
	153 
	154         cf->conf_file->file.fd = fd;
	155         cf->conf_file->file.name.len = filename->len;
	156         cf->conf_file->file.name.data = filename->data;
	157         cf->conf_file->file.offset = 0;
	158         cf->conf_file->file.log = cf->log;
	159         cf->conf_file->line = 1;
	160 
				/*	设置状态标记	*/
	161         type = parse_file;		
	162 
				/*	读取复杂配置项目，一般是递归调用ngx_conf_parse所以filename一般设置为空???	*/
	163     } else if (cf->conf_file->file.fd != NGX_INVALID_FILE) {
	164 
	165         type = parse_block;
	166 
			/*	这个到底是怎么判断的???	*/	
	167     } else {
	168         type = parse_param;
	169     }
	170 
	171 
	172     for ( ;; ) {
		
				/*	循环从配置文件里读取token	*/
	173         rc = ngx_conf_read_token(cf);
	174 
	175         /*
	176          * ngx_conf_read_token() may return
	177          *
	178          *    NGX_ERROR             there is error
	179          *    NGX_OK                the token terminated by ";" was found
	180          *    NGX_CONF_BLOCK_START  the token terminated by "{" was found
	181          *    NGX_CONF_BLOCK_DONE   the "}" was found
	182          *    NGX_CONF_FILE_DONE    the configuration file is done
	183          */
	184 
	185         if (rc == NGX_ERROR) {
	186             goto done;
	187         }
	188 
	189         if (rc == NGX_CONF_BLOCK_DONE) {
	190 
	191             if (type != parse_block) {
	192                 ngx_conf_log_error(NGX_LOG_EMERG, cf, 0, "unexpected \"}\"");
	193                 goto failed;
	194             }
	195 
	196             goto done;
	197         }
	198 
	199         if (rc == NGX_CONF_FILE_DONE) {
	200 
	201             if (type == parse_block) {
	202                 ngx_conf_log_error(NGX_LOG_EMERG, cf, 0,
	203                                    "unexpected end of file, expecting \"}\"");
	204                 goto failed;
	205             }
	206 
	207             goto done;
	208         }
	209 
	210         if (rc == NGX_CONF_BLOCK_START) {
	211 
	212             if (type == parse_param) {
	213                 ngx_conf_log_error(NGX_LOG_EMERG, cf, 0,
	214                                    "block directives are not supported "
	215                                    "in -g option");
	216                 goto failed;
	217             }
	218         }
	219 
	220         /* rc == NGX_OK || rc == NGX_CONF_BLOCK_START */
	221 
	222         if (cf->handler) {
	223 
	224             /*
	225              * the custom handler, i.e., that is used in the http's
	226              * "types { ... }" directive
	227              */
	228 
	229             rv = (*cf->handler)(cf, NULL, cf->handler_conf);
	230             if (rv == NGX_CONF_OK) {
	231                 continue;
	232             }
	233 
	234             if (rv == NGX_CONF_ERROR) {
	235                 goto failed;
	236             }
	237 
	238             ngx_conf_log_error(NGX_LOG_EMERG, cf, 0, rv);
	239 
	240             goto failed;
	241         }
	242 
	243 
	244         rc = ngx_conf_handler(cf, rc);
	245 
	246         if (rc == NGX_ERROR) {
	247             goto failed;
	248         }
	249     }
	250 
	251 failed:
	252 
	253     rc = NGX_ERROR;
	254 
	255 done:
	256 
	257     if (filename) {
	258         if (cf->conf_file->buffer->start) {
	259             ngx_free(cf->conf_file->buffer->start);
	260         }
	261 
	262         if (ngx_close_file(fd) == NGX_FILE_ERROR) {
	263             ngx_log_error(NGX_LOG_ALERT, cf->log, ngx_errno,
	264                           ngx_close_file_n " %s failed",
	265                           filename->data);
	266             return NGX_CONF_ERROR;
	267         }
	268 
	269         cf->conf_file = prev;
	270     }
	271 
	272     if (rc == NGX_ERROR) {
	273         return NGX_CONF_ERROR;
	274     }
	275 
	276     return NGX_CONF_OK;
	277 }
	278 
	

进入ngx_conf_parse函数后，第一步要做的是判断当前解析过程处于一个什么样的状态，有三种可能

##### parse_file: 正要解析一个配置文件
此时参数filename指向一个配置文件路径字符串，需要函数ngx_conf_parse()打开该文件并获取相关的文件信息(比如文件描述符)以便下面代码读取文件内容并进行解析。除了在上面Nginx启动时候开始配置文件解析属于这种情况外，还有当遇到include指令时候也要以这种状态调用ngx_conf_parse函数，因为include指令表示一个新的配置文件要开始解析，此时type=parse_file

##### parse_block: 正要解析一个复杂配置项

此时配置文件已经打开并且也已经对文件进行了解析，当遇到复杂的配置项例如events或是http时候，这些复杂配置项的处理函数又会递归调用ngx_conf_parse函数，此时解析的内容还是来自当前的配置文件，因此无需在打开它，此时type=parse_block;

##### parse_param: 主要开始解析命令行参数配置项值

在对用户通过命令行-g参数输入的配置信息进行解析时候处于这种状态，比如: nginx -g 'daemon on'.nginx在调用ngx_conf_parse函数对命令行参数配置信息'daemon on'进行解析时候就是这种状态，type=parse_param

当判断好解析状态之后就开始读取配置文件内容，配置文件都是由一个个token组成，因此接下来应该是循环从配置文件里读取token，主要有函数ngx_conf_read_token来实现

		/*	buf的结构	*/
	18 typedef struct ngx_buf_s  ngx_buf_t;
	19 
	20 struct ngx_buf_s {
	21     u_char          *pos;
	22     u_char          *last;
	23     off_t            file_pos;            
	24     off_t            file_last;  
	25    
	26     u_char          *start;         /* start of buffer */
	27     u_char          *end;           /* end of buffer */  
	28     ngx_buf_tag_t    tag;
	29     ngx_file_t      *file;
	30     ngx_buf_t       *shadow;
	31    
	32    
	33     /* the buf's content could be changed */
	34     unsigned         temporary:1;         
	35                 
	36     /*
	37      * the buf's content is in a memory cache or in a read only memory
	38      * and must not be changed
	39      */
	40     unsigned         memory:1;
	41    
	42     /* the buf's content is mmap()ed and must not be changed */
	43     unsigned         mmap:1;
	44                 
	45     unsigned         recycled:1;
	46     unsigned         in_file:1;
	47     unsigned         flush:1;
	48     unsigned         sync:1;
	49     unsigned         last_buf:1;
	50     unsigned         last_in_chain:1;     
	51 
	52     unsigned         last_shadow:1;       
	53     unsigned         temp_file:1;         
	54 
	55     /* STUB */ int   num;
	56 };



	434 static ngx_int_t
	435 ngx_conf_read_token(ngx_conf_t *cf)
	436 {
	437     u_char      *start, ch, *src, *dst;
	438     off_t        file_size; 
	439     size_t       len;
	440     ssize_t      n, size;
	441     ngx_uint_t   found, need_space, last_space, sharp_comment, variable;
	442     ngx_uint_t   quoted, s_quoted, d_quoted, start_line;
	443     ngx_str_t   *word;
	444     ngx_buf_t   *b;
	445 
	446     found = 0;
	447     need_space = 0;
	448     last_space = 1;
	449     sharp_comment = 0;
	450     variable = 0; 
	451     quoted = 0;
	452     s_quoted = 0;
	453     d_quoted = 0;
	454 
	455     cf->args->nelts = 0;
	456     b = cf->conf_file->buffer;
	457     start = b->pos;
	458     start_line = cf->conf_file->line;
	459 
	460     file_size = ngx_file_size(&cf->conf_file->file.info);
	461 
	462     for ( ;; ) {
	463 
	464         if (b->pos >= b->last) {
	465 
	466             if (cf->conf_file->file.offset >= file_size) {
	467 
	468                 if (cf->args->nelts > 0 || !last_space) {
	469 
	470                     if (cf->conf_file->file.fd == NGX_INVALID_FILE) {
	471                         ngx_conf_log_error(NGX_LOG_EMERG, cf, 0,
	472                                            "unexpected end of parameter, "
	473                                            "expecting \";\"");
	474                         return NGX_ERROR;
	475                     }
	476 
	477                     ngx_conf_log_error(NGX_LOG_EMERG, cf, 0,
	478                                   "unexpected end of file, "
	479                                   "expecting \";\" or \"}\"");
	480                     return NGX_ERROR;
	481                 }
	482 
	483                 return NGX_CONF_FILE_DONE;
	484             }
	485 
	486             len = b->pos - start;
	487 
	488             if (len == NGX_CONF_BUFFER) {
	489                 cf->conf_file->line = start_line;
	490 
	491                 if (d_quoted) {
	492                     ch = '"';
	493 
	494                 } else if (s_quoted) {
	495                     ch = '\'';
	496 
	497                 } else {
	498                     ngx_conf_log_error(NGX_LOG_EMERG, cf, 0,
	499                                        "too long parameter \"%*s...\" started",
	500                                        10, start);
	501                     return NGX_ERROR;
	502                 }
	503 
	504                 ngx_conf_log_error(NGX_LOG_EMERG, cf, 0,
	505                                    "too long parameter, probably "
	506                                    "missing terminating \"%c\" character", ch);
	507                 return NGX_ERROR;
	508             }
	509 
	510             if (len) {
	511                 ngx_memmove(b->start, start, len);
	512             }
	513 
	514             size = (ssize_t) (file_size - cf->conf_file->file.offset);
	515 
	516             if (size > b->end - (b->start + len)) {
	517                 size = b->end - (b->start + len);
	518             }
	519 
	520             n = ngx_read_file(&cf->conf_file->file, b->start + len, size,
	521                               cf->conf_file->file.offset);
	522 
	523             if (n == NGX_ERROR) {
	524                 return NGX_ERROR;
	525             }
	526 
	527             if (n != size) {
	528                 ngx_conf_log_error(NGX_LOG_EMERG, cf, 0,
	529                                    ngx_read_file_n " returned "
	530                                    "only %z bytes instead of %z",
	531                                    n, size);
	532                 return NGX_ERROR;
	533             }
	534 
	535             b->pos = b->start + len;
	536             b->last = b->pos + n;
	537             start = b->start;
	538         }
	539 
	540         ch = *b->pos++;
	541 
	542         if (ch == LF) {
	543             cf->conf_file->line++;
	544 
	545             if (sharp_comment) {
	546                 sharp_comment = 0;
	547             }
	548         }
	549 
	550         if (sharp_comment) {
	551             continue;
	552         }
	553 
	554         if (quoted) {
	555             quoted = 0;
	556             continue;
	557         }
	558 
	559         if (need_space) {
	560             if (ch == ' ' || ch == '\t' || ch == CR || ch == LF) {
	561                 last_space = 1;
	562                 need_space = 0;
	563                 continue;
	564             }
	565 
	566             if (ch == ';') {
	567                 return NGX_OK;
	568             }
	569 
	570             if (ch == '{') {
	571                 return NGX_CONF_BLOCK_START;
	572             }
	573 
	574             if (ch == ')') {
	575                 last_space = 1;
	576                 need_space = 0;
	577 
	578             } else {
	579                  ngx_conf_log_error(NGX_LOG_EMERG, cf, 0,
	580                                     "unexpected \"%c\"", ch);
	581                  return NGX_ERROR;
	582             }
	583         }
	584 
	585         if (last_space) {
	586             if (ch == ' ' || ch == '\t' || ch == CR || ch == LF) {
	587                 continue;
	588             }
	589 
	590             start = b->pos - 1;
	591             start_line = cf->conf_file->line;
	592 
	593             switch (ch) {
	594 
	595             case ';':
	596             case '{':
	597                 if (cf->args->nelts == 0) {
	598                     ngx_conf_log_error(NGX_LOG_EMERG, cf, 0,
	599                                        "unexpected \"%c\"", ch);
	600                     return NGX_ERROR;
	601                 }
	602 
	603                 if (ch == '{') {
	604                     return NGX_CONF_BLOCK_START;
	605                 }
	606 
	607                 return NGX_OK;
	608 
	609             case '}':
	610                 if (cf->args->nelts != 0) {
	611                     ngx_conf_log_error(NGX_LOG_EMERG, cf, 0,
	612                                        "unexpected \"}\"");
	613                     return NGX_ERROR;
	614                 }
	615 
	616                 return NGX_CONF_BLOCK_DONE;
	617 
	618             case '#':
	619                 sharp_comment = 1;
	620                 continue;
	621 
	622             case '\\':
	623                 quoted = 1;
	624                 last_space = 0;
	625                 continue;
	626 
	627             case '"':
	628                 start++;
	629                 d_quoted = 1;
	630                 last_space = 0;
	631                 continue;
	632 
	633             case '\'':
	634                 start++;
	635                 s_quoted = 1;
	636                 last_space = 0;
	637                 continue;
	638 
	639             default:
	640                 last_space = 0;
	641             }
	642 
	643         } else {
	644             if (ch == '{' && variable) {
	645                 continue;
	646             }
	647 
	648             variable = 0;
	649 
	650             if (ch == '\\') {
	651                 quoted = 1;
	652                 continue;
	653             }
	654 
	655             if (ch == '$') {
	
	656                 variable = 1;
	657                 continue;
	658             }
	659 
	660             if (d_quoted) {
	661                 if (ch == '"') {
	662                     d_quoted = 0;
	663                     need_space = 1;
	664                     found = 1;
	665                 }
	666 
	667             } else if (s_quoted) {
	668                 if (ch == '\'') {
	669                     s_quoted = 0;
	670                     need_space = 1;
	671                     found = 1;
	672                 }
	673 
	674             } else if (ch == ' ' || ch == '\t' || ch == CR || ch == LF
	675                        || ch == ';' || ch == '{')
	676             {
	677                 last_space = 1;
	678                 found = 1;
	679             }
	680 
	681             if (found) {
	682                 word = ngx_array_push(cf->args);
	683                 if (word == NULL) {
	684                     return NGX_ERROR;
	685                 }
	686 
	687                 word->data = ngx_pnalloc(cf->pool, b->pos - start + 1);
	688                 if (word->data == NULL) {
	689                     return NGX_ERROR;
	690                 }
	691 
	692                 for (dst = word->data, src = start, len = 0;
	693                      src < b->pos - 1;
	694                      len++)
	695                 {
	696                     if (*src == '\\') {
	697                         switch (src[1]) {
	698                         case '"':
	699                         case '\'':
	700                         case '\\':
	701                             src++;
	702                             break;
	703 
	704                         case 't':
	705                             *dst++ = '\t';
	706                             src += 2;
	707                             continue;
	708 
	709                         case 'r':
	710                             *dst++ = '\r';
	711                             src += 2;
	712                             continue;
	713 
	714                         case 'n':
	715                             *dst++ = '\n';
	716                             src += 2;
	717                             continue;
	718                         }
	719 
	720                     }
	721                     *dst++ = *src++;
	722                 }
	723                 *dst = '\0';
	724                 word->len = len;
	725 
	726                 if (ch == ';') {
	727                     return NGX_OK;
	728                 }
	729 
	730                 if (== '{') {
	731                    return NGX_CONF_BLOCK_START;
	732                 }
	733
	734						found = 0;
	735				}
	736         }
	737     }
	738 }
	

ngx_conf_read_token会对配置文件进行逐个字符扫描并解析出单个的token，但是这个函数并不会去频繁的读取配置文件，它每次从文件内读取足够多的内容以填满一个大小为NGX_CONF_BUFFER(4096)的缓冲区(除了最后一次，配置文件本身剩余内容不足4096)，这个缓冲区在函数内申请并保存到引用变量cf->conf_file->buffer中，函数ngx_conf_read_token将会返回使用该缓存区，缓存区也有一些状态。

#####1.初始状态

函数ngx_conf_parse()内申请缓冲区后的初始状态

![007]({{ site.img_url }}/2014/05/007.png)

#####2.处理过程的中间状态

有一部分配置内容已经被解析为一个个token并保存起来，而有一部分内容主要被组合成token，还有一部分内容等待处理

![008]({{ site.img_url }}/2014/05/008.png)

![009]({{ site.img_url }}/2014/05/009.png)

![010]({{ site.img_url }}/2014/05/010.png)

![011]({{ site.img_url }}/2014/05/011.png)


