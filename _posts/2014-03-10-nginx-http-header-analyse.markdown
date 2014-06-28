---
layout: post
title: nginx获取HTTP头部信息
categories:
- Nginx
---

获取HTTP头部

    
    struct ngx_http_request_s {
    	……
    
    	ngx_buf_t                        *header_in;
    
    	ngx_http_headers_in_t             headers_in;
    
    	……
    }


其中head_in指向Nginx收到的未经解析的HTTP头部(也就是接受HTTP头部的缓冲区)  
header_in存储的是经过解析过的HTTP头部

===============================================================================

获取HTTP头部时，直接使用r->headers_in的相应成员就可以了。
ngx_http_headers_in_t 的结构如下:

    
         
    typedef struct {
    	/*所有解析过的HTTP头都在headers链表中，可以使用遍历的方法获得所有HTTP头部
    	注意 headers中每一个元素都是ngx_table_elt_t成员*/	
    	ngx_list_t                        headers;
    
    	/*以下的所有ngx_table_elt_t成员都是RFC中规定的HTTP头部，实际都是指向headers链表中相应的成员
    	当他们为NULL时表示没有解析到相应的HTTP头部*/
    	ngx_table_elt_t                  *host;
    	ngx_table_elt_t                  *connection;
    	ngx_table_elt_t                  *if_modified_since;
    	ngx_table_elt_t                  *if_unmodified_since;
    	ngx_table_elt_t                  *user_agent;
    	ngx_table_elt_t                  *referer;
    	ngx_table_elt_t                  *content_length;
    	ngx_table_elt_t                  *content_type;
    
    	ngx_table_elt_t                  *range;
    	ngx_table_elt_t                  *if_range;
    
    	ngx_table_elt_t                  *transfer_encoding;
    	ngx_table_elt_t                  *expect;
    
    	#if (NGX_HTTP_GZIP)
    		ngx_table_elt_t                  *accept_encoding;
    		ngx_table_elt_t                  *via;
    	#endif
    
    
    	ngx_table_elt_t                  *keep_alive;
    
    	#if (NGX_HTTP_PROXY || NGX_HTTP_REALIP || NGX_HTTP_GEO)
    		ngx_table_elt_t                  *x_forwarded_for;
    	#endif
    
    	#if (NGX_HTTP_REALIP)
    		ngx_table_elt_t                  *x_real_ip;
    	#endif
    
    	#if (NGX_HTTP_HEADERS)
    		ngx_table_elt_t                  *accept;
    		ngx_table_elt_t                  *accept_language;
    	#endif
    
    	#if (NGX_HTTP_DAV)
    		ngx_table_elt_t                  *depth;
    		ngx_table_elt_t                  *destination;
    		ngx_table_elt_t                  *overwrite;
    		ngx_table_elt_t                  *date;
    	#endif
    
    	/*以下为非RFC规定的标准头*/
    	ngx_str_t                         user;
    	ngx_str_t                         passwd;
    
    	ngx_array_t                       cookies;
    
    	ngx_str_t                         server;
    	off_t                             content_length_n;
    	time_t                            keep_alive_n;
    
    	unsigned                          connection_type:2;
    
    	/*一下七位标志是HTTP框架根据浏览器传来的useragent头部判断浏览器的类型，
    	对应的值为1则表示为该类型浏览器发送的请求*/
    	unsigned                          msie:1;
    	unsigned                          msie6:1;
    	unsigned                          opera:1;
    	unsigned                          gecko:1;
    	unsigned                          chrome:1;
    	unsigned                          safari:1;
    	unsigned                          konqueror:1;
    } ngx_http_headers_in_t;


===============================================================================  
遍历headers链表获取非RFC标准HTTP头  
实例:  
尝试在用户请求中找到"Rpc-Description"头部，首先判断其值是否为"uploadFile",在决定后续的行为

    
    /*链表首个节点的地址*/
    ngx_list_part_t* part = &r->headers_in.headers.part;	
    /*首个节点中数组的地址*/
    ngx_table_elt_t* header = part->elt;
    
    for(i=0;  ; i++){
    	if(i >= part->nelf){	/*i达到了数组中元素个数*/
    		if(part->next == NULL){	/*如果没有下一个节点break*/
    			break;
    		}
    
    	part- = part->next;
    	header = part->elts;
    	i = 0;	
    
    	}
    
    	/*hash为0表示不合法的头部*/
    	if(header[i].hash == 0){
    		continue;
    	}
    
    	if(0 = ngx_strncmp(header[i].key.data, 
    		(u_char*)"Rpc-Description", header[i].key.len)){
    
    		if(0 == ngx_strncmp(header[i].value.data, 
    			"uploadFile", header[i].value.len)){
    
    			do something;
    		}
    	}
    
    }

  
对于常见的HTTP头部，直接获取r->header_in中已经由HTTP框架解析过的成员即可  
对于不常见的HTTP头部，需要遍历r->header_in.headers链表才能获得  

备注:
链表的遍历参看 [[Nginx学习]ngx_list_t结构](http://ucshell.com/archives/1317)
