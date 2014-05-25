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
				......
	158 
	159       ngx_null_command	/*	以它结尾	*/
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

每个模块都把自己所需要的配置项目对应的ngx_command_s结构体变量组成一个数组，以ngx_xxx_xxx_commands的形式命名，该数组以元素ngx_null_command作为结束标识


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
					/*	type具体的含义见下文	*/
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
				/*	
				*	这个主要是针对类似 text/html html htm;之类不定配置项,这些配置项众多且变化不定,
				*	但格式统一,一般是以key/values的形式存在的	
				*	nginx只是将其拷贝到对应的变量内,所以此时一般提供一个统一的handler便是cf->handler
				*	比如type指令的处理函数ngx_http_core_types就会将cf->handler赋值为ngx_http_core_types
				*/
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
				/*	
				*	配置转换的核心函数 
				*	两个参数分别是cf和rc
				*	cf中包含了很多参数,比如要转换的token就保存在cf->args中
				*	rc记录的是最近一次ngx_conf_read_token函数返回值
				*/
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
	726                 if (ch == ';') {					/*	返回表示读取完一个简单配置项的标记	*/
	727                     return NGX_OK;
	728                 }
	729 
	730                 if (== '{') {
	731                    return NGX_CONF_BLOCK_START;		/*	返回开始读取负载配置项的标记	*/
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

有一部分配置内容已经被解析为一个个token并保存起来，而有一部分内容主要被组合成token，还有一部分内容等待处理,已解析的字符和已扫描的字符都属于已处理的字符，但是已解析的字符已经被作为token额外保存起来，所以这些字符已经没有什么用处了，而已扫描的字符表示这些字符还没有组成一个完成的token，所以他们不能被丢弃。

![008]({{ site.img_url }}/2014/05/008.png)

#####3.缓存区中字符都处理完状态

缓存区中字符都处理完时，需要继续从打开的配置文件中读取新的内容到缓存中此时的临界状态如图:

![009]({{ site.img_url }}/2014/05/009.png)

因为解析过的字符已经没有什么用了，所以我们将已经扫描但是还没有组成token的字符移动到缓存的前面，然后从配置文件读取内容填满缓存区剩下的空间。

![010]({{ site.img_url }}/2014/05/010.png)

对于最后一次读取，无法填满缓冲区的情况如下

![011]({{ site.img_url }}/2014/05/011.png)

ngx_conf_read_token在读取了合适数量的标记token之后就开始下一个步骤，对这些标记进行实际的处理，读到多少才算合适呢？

对于简单配置项，读取其全部标记，也就是遇到配置项结束标记分号为止;此时一条简单配置项的所有标记都已经被读取并存放在cf->args数组内，因此可以开始下一步，即执行回调函数进行实际性的解析处理;

对于负载配置项则是读取完其配置块内所有的标记，即遇到大括号{为止，此时负载配置项处理函数所需要的标记都已经读取到，而对于配置块{}内的标记将在接下来的函数ngx_conf_parse递归调用中继续处理，这是个反复的过程，当然如果配置文件出错就会直接返回了。


ngx_conf_parse函数识别并将token缓存到cf->args数组中,首先对配置文件临时缓存区内容调整,接着通过缓冲区从前往后扫描整个配置文件的内容,对每一个字符与前面已经扫描字符的组合进行有效性检测并进行一些状态旗标设置,比如d_quoted旗标置1则表示当前处于双引号字符串后,last_space置1则表示当前一个字符为空白字符,这些旗标能够大大方便接下来的字符有效性组合检测.

再接下来就是判断当前已经扫描字符是否能够组成一个token标记,两个双引号,两个单引号,两个空白字符之间的字符就能组成一个token标记,此时cf->args数组内申请对应的存储空间并机型token标记字符串拷贝,从而完成了一个token标记的解析与读取工作,此时根据情况要么继续进行下一个token标记的解析与读取,要么返回到ngx_conf_parse函数进行实际处理.



	13 typedef struct ngx_conf_s        ngx_conf_t;

	166 struct ngx_conf_s {
	167     char                 *name;  		/*	没有使用	*/
	168     ngx_array_t          *args;  		/*	指令的参数	*/
	169 
	170     ngx_cycle_t          *cycle; 		/*	指向系统参数，在系统整个运行过程中，	*/
	171                                  		/*	需要使用的一些参数、资源需要统一的管理	*/
	172     ngx_pool_t           *pool;  		/*	内存池	*/
	173     ngx_pool_t           *temp_pool;	/*	分配临时数据空间的内存池	*/
	174     ngx_conf_file_t      *conf_file;	/*	配置文件的信息	*/
	175     ngx_log_t            *log; 			/*	日志		*/
	176 
	177     void                 *ctx;  		/*	模块的配置信息	*/
	178     ngx_uint_t            module_type; 	/*	当前指令的类型	*/
	179     ngx_uint_t            cmd_type; 	/*	命令的类型	*/
	180 
	181     ngx_conf_handler_pt   handler; 		/*	指令处理函数，有自己行为的在这里实现	*/
	182     char                 *handler_conf; /*	指令处理函数的配置信息	*/
	183};

	16 // 动态数组
	17 struct ngx_array_s {
	18     						
	19     void        *elts; 		/*	elts指向数组的首地址 */
	20     
	21     ngx_uint_t   nelts; 		/* nelts是数组中已经使用的元素个数	*/
	22     
	23     size_t       size; 		/* 每个数组元素占用的内存大小 */
	24     
	25     ngx_uint_t   nalloc;		/* 当前数组中能够容纳元素个数的总大小 */
	26     
	27     ngx_pool_t  *pool;		/* 内存池对象	*/
	28 };
	29 


以下是在ngx_conf_parse函数中打印的一些内容

	(gdb) p (*cf->args)->nelts
	$6 = 2
	(gdb) p *((ngx_str_t*)((*cf->args)->elts))
	$7 = {len = 16, data = 0x80e33d8 "worker_processes"}
	(gdb) p *((ngx_str_t*)((*cf->args)->elts+sizeof(ngx_str_t)))
	$8 = {len = 1, data = 0x80e33ea "2"}
	(gdb) p (*cf->args)->elts
	$9 = (void *) 0x80e3388
	(gdb) p (*cf->args)->nelts
	$10 = 2
	(gdb) p filename
	$11 = (ngx_str_t *) 0x80e2ac8
	(gdb) p *filename
	$12 = {len = 32, data = 0x80e2b1f "/usr/local/nginx/conf/nginx.conf"}
	(gdb) 



此时解析转换所需要的token都已经被保存到cf->args中了,接下来要将这些token转换为nginx内控制变量的值,ngx_conf_handler函数的作用便是如此

nginx的每一个配置指令都对应一个ngx_command_s数据类型变量,记录这该配置指令的回调函数,转换值的存储位置等,而每一个模块又都把自身锁相关的所有指令以数组的形式组织起来,所以ngx_conf_handler首先做的就是查找当前指令所对应的ngx_command_s变量,通过循环遍历各个模块的指令数组即可,nginx的所有模块也是用数组形式组织的,

	281 static ngx_int_t
	282 ngx_conf_handler(ngx_conf_t *cf, ngx_int_t last)
	283 {
	284     char           *rv;
	285     void           *conf, **confp;
	286     ngx_uint_t      i, multi;
	287     ngx_str_t      *name;
	288     ngx_command_t  *cmd;
	289 
			/*	以work_process为例,elts类型为ngx_str_t	*/
	290     name = cf->args->elts;
	291 
	292     multi = 0;
	293 
			/*	遍历各个模块,数组中结尾的是空结构的哨兵	*/
	294     for (i = 0; ngx_modules[i]; i++) {
	295 
	296         /* look up the directive in the appropriate modules */
	297 
				/*	
				*	一定是在NGX_CONF_MODULE类型的模块中找
				*	并且模块类型与cf->module_type的类型必须相同	
				*/
	298         if (ngx_modules[i]->type != NGX_CONF_MODULE
	299             && ngx_modules[i]->type != cf->module_type)
	300         {
	301             continue;
	302         }
	303 
	304         cmd = ngx_modules[i]->commands;
	305         if (cmd == NULL) {
	306             continue;
	307         }
	308 
	309         for ( /* void */ ; cmd->name.len; cmd++) {
	310				
					/*	首先比较长度,长度不同没有必要再去比较了	*/
	311             if (name->len != cmd->name.len) {
	312                 continue;
	313             }
	314 
					/*	长度相同在比较具体的字符是否相同	*/
	315             if (ngx_strcmp(name->data, cmd->name.data) != 0) {
	316                 continue;
	317             }
	318 
	319 
	320             /* is the directive's location right ? */
	321 
	322             if (!(cmd->type & cf->cmd_type)) {
	323                 if (cmd->type & NGX_CONF_MULTI) {
	324                     multi = 1;
	325                     continue;
	326                 }
	327 
	328                 goto not_allowed;
	329             }
	330 
	331             if (!(cmd->type & NGX_CONF_BLOCK) && last != NGX_OK) {
	332                 ngx_conf_log_error(NGX_LOG_EMERG, cf, 0,
	333                                   "directive \"%s\" is not terminated by \";\"",
	334                                   name->data);
	335                 return NGX_ERROR;
	336             }
	337 
	338             if ((cmd->type & NGX_CONF_BLOCK) && last != NGX_CONF_BLOCK_START) {
	339                 ngx_conf_log_error(NGX_LOG_EMERG, cf, 0,
	340                                    "directive \"%s\" has no opening \"{\"",
	341                                    name->data);
	342                 return NGX_ERROR;
	343             }
	344 
	345             /* is the directive's argument count right ? */
	346 
	347             if (!(cmd->type & NGX_CONF_ANY)) {
	348 
	349                 if (cmd->type & NGX_CONF_FLAG) {
	350 
	351                     if (cf->args->nelts != 2) {
	352                         goto invalid;
	353                     }
	354 
	355                 } else if (cmd->type & NGX_CONF_1MORE) {
	356 
	357                     if (cf->args->nelts < 2) {
	358                         goto invalid;
	359                     }
	360 
	361                 } else if (cmd->type & NGX_CONF_2MORE) {
	362 
	363                     if (cf->args->nelts < 3) {
	364                         goto invalid;
	365                     }
	366 
	367                 } else if (cf->args->nelts > NGX_CONF_MAX_ARGS) {
	368 
	369                     goto invalid;
	370 
	371                 } else if (!(cmd->type & argument_number[cf->args->nelts - 1]))
	372                 {
	373                     goto invalid;
	374                 }
	375             }
	376 
	377             /* set up the directive's configuration context */
	378 
	379             conf = NULL;
	380 
	381             if (cmd->type & NGX_DIRECT_CONF) {
	382                 conf = ((void **) cf->ctx)[ngx_modules[i]->index];
	383 
	384             } else if (cmd->type & NGX_MAIN_CONF) {
	385                 conf = &(((void **) cf->ctx)[ngx_modules[i]->index]);
	e if (cf->ctx) {
	388                 confp = *(void **) ((char *) cf->ctx + cmd->conf);
	389 
	390                 if (confp) {
	391                     conf = confp[ngx_modules[i]->ctx_index];
	392                 }
	393             }
	394 
	395             rv = cmd->set(cf, cmd, conf);
	396 
	397             if (rv == NGX_CONF_OK) {
	398                 return NGX_OK;
	399             }
	400 
	401             if (rv == NGX_CONF_ERROR) {
	402                 return NGX_ERROR;
	403             }
	404 
	405             ngx_conf_log_error(NGX_LOG_EMERG, cf, 0,
	406                                "\"%s\" directive %s", name->data, rv);
	407 
	408             return NGX_ERROR;
	409         }
	410     }
	411 
	412     if (multi == 0) {
	413         ngx_conf_log_error(NGX_LOG_EMERG, cf, 0,
	414                            "unknown directive \"%s\"", name->data);
	415 
	416         return NGX_ERROR;
	417     }
	418 
	419 not_allowed:
	420 
	421     ngx_conf_log_error(NGX_LOG_EMERG, cf, 0,
	422                        "\"%s\" directive is not allowed here", name->data);
	423     return NGX_ERROR;
	424 
	425 invalid:
	426 
	427     ngx_conf_log_error(NGX_LOG_EMERG, cf, 0,
	428                        "invalid number of arguments in \"%s\" directive",
	429                        name->data);
	430 
	431     return NGX_ERROR;
	432 }

以worker_processes为例,当查找到worker_processes配置指令对应的ngx_command_s变量时,就开始调用回调函数进行处理

	 70     { ngx_string("worker_processes"),
	 71       NGX_MAIN_CONF|NGX_DIRECT_CONF|NGX_CONF_TAKE1,
	 72       ngx_conf_set_num_slot,	/*		worker_processes的回调函数set 	*/
	 73       0,
	 74       offsetof(ngx_core_conf_t, worker_processes),
	 75       NULL },

worker_processes的回调函数是ngx_conf_set_num_slot,它的主要作用是找到在将cf中值的存储的位置,然后利用ngx_atoi来将字符串转换为数字,存储到对应的位置

	1203 char *
	1204 ngx_conf_set_num_slot(ngx_conf_t *cf, ngx_command_t *cmd, void *conf)
	1205 {
	1206     char  *p = conf;
	1207 
	1208     ngx_int_t        *np;
	1209     ngx_str_t        *value;
	1210     ngx_conf_post_t  *post;
	1211 
	1212	/*	找到存储位置	*/ 
	1213     np = (ngx_int_t *) (p + cmd->offset);
	1214 
	1215     if (*np != NGX_CONF_UNSET) {
	1216         return "is duplicate";
	1217     }
	1218 
	1219     value = cf->args->elts;
			/*	value[0]存储的是worker_processes及其长度,value[1]中存储的就是worker_processes之后的配置参素	*/
	1220     *np = ngx_atoi(value[1].data, value[1].len); //把value后面的buffer强制转为一个str
	1221     if (*np == NGX_ERROR) {
	1222         return "invalid number";
	1223     }

	1224	/*		post多数情况下都是NULL	*/ 
	1225     if (cmd->post) {
	1226         post = cmd->post;
	1227         return post->post_handler(cf, post, np);
	1228     }
	1229 
	1230     return NGX_CONF_OK;
	1231 }


nginx配置文件解析的流程图如下:

![012]({{ site.img_url }}/2014/05/012.png)
