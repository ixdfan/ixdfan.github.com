---
layout: post
title: nginx的HTTP头的分析
categories:
- Nginx
---


    struct ngx_http_request_s {
    	……
    	ngx_uint_t                        method;	
    	ngx_uint_t                        http_version;
    
    	ngx_str_t                         request_line;
    	ngx_str_t                         uri;
    	ngx_str_t                         args;
    	ngx_str_t                         exten;
    	ngx_str_t                         unparsed_uri;
    
    	ngx_str_t                         method_name;
    	ngx_str_t                         http_protocol;
    
    	u_char                           *uri_start;
    	u_char                           *uri_end;
    	u_char                           *uri_ext;
    	u_char                           *args_start;
    	u_char                           *request_start;
    	u_char                           *request_end;
    	u_char                           *method_end;
    	u_char                           *schema_start;
    	u_char                           *schema_end;
    
    	……
    };


=========================================================================

##### 方法名的获取:

method是Nginx忽略大小写等情形解析出来的用户请求后得到的方法类型，取值范围如下:

    
    #define NGX_HTTP_UNKNOWN                   0x0001
    #define NGX_HTTP_GET                       0x0002
    #define NGX_HTTP_HEAD                      0x0004
    #define NGX_HTTP_POST                      0x0008
    #define NGX_HTTP_PUT                       0x0010
    #define NGX_HTTP_DELETE                    0x0020
    #define NGX_HTTP_MKCOL                     0x0040
    #define NGX_HTTP_COPY                      0x0080
    #define NGX_HTTP_MOVE                      0x0100
    #define NGX_HTTP_OPTIONS                   0x0200
    #define NGX_HTTP_PROPFIND                  0x0400
    #define NGX_HTTP_PROPPATCH                 0x0800
    #define NGX_HTTP_LOCK                      0x1000
    #define NGX_HTTP_UNLOCK                    0x2000
    #define NGX_HTTP_PATCH                     0x4000
    #define NGX_HTTP_TRACE                     0x8000


如果要了解用户请求中的HTTP方法时，应该使用r->method与对应的宏进行比较，这样是最快的，如果使用method_name成员与字符串做比较，那么效率会差很多。


还可以使用method_name取得请求中的方法名字符串，method_name是ngx_str_t类型的字符串，直接使用printf("%\*s", r->method.len, r->method.data)即可;

或者联合使用request_start与method_end取得方法名:

request_start指向用户请求的首地址，提示也是方法名的首地址;

method_end指向方法名的最后一个字符，注意这个与其他xx_end指针不同。

使用方法是从request_start开始向后遍历，直到地址与method_end相同为止，这段内存存储这方法名

##### 注意:
**Nginx为了避免不必要的内存开销，许多需要用到的成员都不是重新分配内存后存储的，而是直接指向用户请求中的相应地址;**

例如:

method_name.data、request_start这两个指针实际指向的都是同一地址，而且因为他们只是简单的内存指针，而不是真正的字符串指针，所以，不能直接将这些u_char*指针当作字符串来使用。

=========================================================================

#### URI

补充一点知识:什么是URI

Web上可用的每种资源 -HTML文档、图像、视频片段、程序等 - 由一个通用资源标识符（Uniform Resource Identifier, 简称"URI"）进行定位。

ngx_str_t类型的uri成员指向用户请求

u_char*类型的uri_start和uri_end与request_start和method_end的用法相同，

唯一的不同在于method_end指向方法名的最后一个字符，而uri_end指向URI结束后的下一个地址，也就是最后一个字符的下一个字符地址，这是大部分哦u_char*类型指针对xxx_start和xxx_end变量的用法

ngx_str_t类型的exten成员指向用户请求的文件扩展名，例如在访问"GET/a.txt HTTP/1.1"时，exten的值为{len=3, data='txt'}

当访问"GET/a HTTP/1.1"时，exten当值为空{len=0, data=NULL}

uri_ext指针指向当地址与extern.data相同

unparsed_uri表示没有进行URL解码的原始请求，例如，当uri为"/a b"时，unparsed_uri为"/a%20b"(空格字符做完编码后为%20)

=========================================================================

URL参数
arg指向用户请求的URL参素
args_start指向URL参数的起始地址，配合uri_end使用也可以获得URL参数

=========================================================================

协议版本
http_protocol指向用户请求中HTTP的起始地址。

http_version是Nginx解析过的协议版本，取值范围如下:

    
    #define NGX_HTTP_VERSION_9                 9
    #define NGX_HTTP_VERSION_10                1000
    #define NGX_HTTP_VERSION_11                1001


=========================================================================

使用request_start和request_end可以获取原始用户的请求行
