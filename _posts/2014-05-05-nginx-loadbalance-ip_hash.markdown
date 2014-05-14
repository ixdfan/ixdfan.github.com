---
layout: post
title:  nginx负载均衡--ip_hash的实现
description: 
modified: 
categories: 
- Nginx
tags:
- 负载均衡
---

根据IP的哈希值来获取对应的后端服务器，Nginx1.2.0仅支持IPv4

加权轮询是Nginx负载均衡的基础策略，所以一些初始化工作，比如配置值转储(配置文件中相关值存储到变量中),所以其他策略可以直接复用加权轮询的初始化工作。


path:src/http/modules/ngx_http_upstream_ip_hash_module.c

#### 初始化工作
	79 ngx_int_t
	80 ngx_http_upstream_init_ip_hash(ngx_conf_t *cf, ngx_http_upstream_srv_conf_t *us)
	81 {
			/*	直接使用round_robin的全局初始化	*/
	82     if (ngx_http_upstream_init_round_robin(cf, us) != NGX_OK) {
	83         return NGX_ERROR;
	84     }
	85 	
			/*	设定客户端请求到来时候的初始化函数	*/
	86     us->peer.init = ngx_http_upstream_init_ip_hash_peer;
	87 
	88     return NGX_OK;
	89 }

第86行是针对单个请求进行初始化的回调函数指针，当一个客户请求过来时，就调用ngx_http_upstream_init_ip_hash_peer做初始化。



#### 选择后端服务器

客户端请求到来后，函数ngx_http_upstream_ip_hash_module进行初始化，它调用了加权轮询策略的初始函数ngx_http_upstream_init_round_robin_peer，之所以这样是因为在多次哈希选择失败之后，*Nginx将会选择策略退化为加权轮询*,针对IP哈希锁做的初始化工作主要是将对应的客户端IP转存出来。


	92 static ngx_int_t
	93 ngx_http_upstream_init_ip_hash_peer(ngx_http_request_t *r,
	94     ngx_http_upstream_srv_conf_t *us)
	95 {
	96     u_char                                 *p;
	97     struct sockaddr_in                     *sin;
	98     ngx_http_upstream_ip_hash_peer_data_t  *iphp;
	99 
	100     iphp = ngx_palloc(r->pool, sizeof(ngx_http_upstream_ip_hash_peer_data_t));
	101     if (iphp == NULL) {
	102         return NGX_ERROR;
	103     }
	104 
	105     r->upstream->peer.data = &iphp->rrp;
	106 
	107     if (ngx_http_upstream_init_round_robin_peer(r, us) != NGX_OK) {
	108         return NGX_ERROR;
	109     }
	110		
			/*	设置回调函数	*/			/*	获取使用ip_hash策略	*/
			/*	修改了原本在ngx_http_upstream_init_round_robin_peer函数中的值	*/
	111     r->upstream->peer.get = ngx_http_upstream_get_ip_hash_peer;
	112 
	113     /* AF_INET only */	/*	仅仅支持IPV4	*/
	114 
	115     if (r->connection->sockaddr->sa_family == AF_INET) {
	116 
	117         sin = (struct sockaddr_in *) r->connection->sockaddr;
	118         p = (u_char *) &sin->sin_addr.s_addr;

				/*	哈希方法仅仅需要ip地址的前三个字节即可	*/
	119         iphp->addr[0] = p[0];
	120         iphp->addr[1] = p[1];
	121         iphp->addr[2] = p[2];
	122 
	123     } else {
				/*	IPV6的全部置为0,都分配到同一台机器了	*/
	124         iphp->addr[0] = 0;
	125         iphp->addr[1] = 0;
	126         iphp->addr[2] = 0;
	127     }
	128 
			/*	哈希初始值	*/
	129     iphp->hash = 89;
	130     iphp->tries = 0;
			/*	哈希失败20次以上就会退化成加权轮询模式，调用iphp->get_rr_peer	*/
	131     iphp->get_rr_peer = ngx_http_upstream_get_round_robin_peer;
	132 
	133     return NGX_OK;
	134 }
	
	

函数ngx_http_upstream_get_ip_hash_peer的实现

	/*	选择后端服务器	*/
	137 static ngx_int_t
	138 ngx_http_upstream_get_ip_hash_peer(ngx_peer_connection_t *pc, void *data)
	139 {
	140     ngx_http_upstream_ip_hash_peer_data_t  *iphp = data;
	141 
	142     time_t                        now;
	143     uintptr_t                     m; 
	144     ngx_uint_t                    i, n, p, hash;
	145     ngx_http_upstream_rr_peer_t  *peer;
	146 
	147     ngx_log_debug1(NGX_LOG_DEBUG_HTTP, pc->log, 0,
	148                    "get ip hash peer, try: %ui", pc->tries);
	149 
	150     /* TODO: cached */
	151		
			/*	哈希失败20次以上，或是单机模式	*/
	152     if (iphp->tries > 20 || iphp->rrp.peers->single) {
				/*	退化为加权轮询	*/
	153         return iphp->get_rr_peer(pc, &iphp->rrp);
	154     }
	155 
	156     now = ngx_time();
	157 
	158     pc->cached = 0;
	159     pc->connection = NULL;
	160 
			/*		iphp->hash初始值为89，质数		*/
	161     hash = iphp->hash;
	162 
	163     for ( ;; ) {
	164 
				/*	一下是哈希的计算方法	*/
				/*	只需要ip的前三个字节所以i < 3	*/
	165         for (i = 0; i < 3; i++) {
	166             hash = (hash * 113 + iphp->addr[i]) % 6271;
	167         }
	168 
				/*	p就是最后的哈希值，得到的p一定小于机器数量	*/
	169         p = hash % iphp->rrp.peers->number;
	170 			
				/*	检测p机器在位图中是否被使用过了	*/
	171         n = p / (8 * sizeof(uintptr_t));
	172         m = (uintptr_t) 1 << p % (8 * sizeof(uintptr_t));
	173 
				/*	对应的位为0表示没有使用过	*/
	174         if (!(iphp->rrp.tried[n] & m)) {
	175 
	176             ngx_log_debug2(NGX_LOG_DEBUG_HTTP, pc->log, 0,
	177                            "get ip hash peer, hash: %ui %04XA", p, m);
	178 
	179             peer = &iphp->rrp.peers->peer[p];
	180 
	181             /* ngx_lock_mutex(iphp->rrp.peers->mutex); */
	182				
					/*	如果机器可用，break便会跳出执行代码207行代码	*/
	183             if (!peer->down) {
	184 
	185                 if (peer->max_fails == 0 || peer->fails < peer->max_fails) {
	186                     break;
	187                 }
	188 
	189                 if (now - peer->checked > peer->fail_timeout) {
	190                     peer->checked = now;
	191                     break;
	192                 }
	193             }
	194 
	195             iphp->rrp.tried[n] |= m;
	196 
	197             /* ngx_unlock_mutex(iphp->rrp.peers->mutex); */
	198 
	199             pc->tries--;
	200         }
	201			
				/*	失败了20次机上就退化	*/
	202         if (++iphp->tries >= 20) {
	203             return iphp->get_rr_peer(pc, &iphp->rrp);
	204         }
	205     }
	206 
	207     iphp->rrp.current = p;
	208 
	209     pc->sockaddr = peer->sockaddr;
	210     pc->socklen = peer->socklen;
	211     pc->name = &peer->name;
	212 
	213     /* ngx_unlock_mutex(iphp->rrp.peers->mutex); */
	214 
	215     iphp->rrp.tried[n] |= m;
	216     iphp->hash = hash;
	217 
	218     return NGX_OK;
	219 }

哈希的计算很简单，就是通常的哈希规则，也就是相关数值，比如3、89、113、6271都是质数，这样使得哈希结果更加散列;

根据哈希值得到被选中的后端服务器，判断其是否可用，如果可用则break跳出，执行207行代码，否则将可重试次数减少1,再在上次哈希结果hash的基础上再进行哈希(就是那个for死循环的作用)！

![005]({{ site.img_url }}/2014/05/005.png)

