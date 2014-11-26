---
layout: post
title:  同时处理TCP和UDP
description: 
modified: 
categories: 
- LINUX
tags:
- TCP
- UDP

---

以前所接触到当服务器程序都只监听一个端口，在实际应用中，有不少服务器程序能够同时监听多个端口;

从bind系统调用当参数来看，一个socket只能与一个socket地址(ip + 端口)绑定，也就是说一个socket只能监听一个端口;

所以如果想要同时监听多个端口，就必须建立多个socket并将他们分别绑定到各个端口上去，这样服务器就需要同时管理多个监听socket，I/O复用也就有了用武之地;

另外即使是同一个端口，如果服务器要同时处理该端口上的TCP和UDP请求，则也要创建两个不同的socket:
* 流socket
* 数据报socket
并将他们都绑到该端口上！代码如下:


	/*
	*同时处理TCP与UDP请求的简单回射服务器 
	*/
	#include <sys/types.h>
	#include <sys/socket.h>
	#include <netinet/in.h>
	#include <assert.h>
	#include <sys/epoll.h>
	#include <arpa/inet.h>
	#include <fcntl.h>
	#include <unistd.h>
	#include <stdio.h>
	#include <errno.h>
	#include <string.h>
	#include <stdlib.h>
	#include <pthread.h>
	
	#define MAX_EVENT_NUMBER 1024
	#define TCP_BUFFER_SIZE  512
	#define UDP_BUFFER_SIZE  1024
	
	int setnonblocking(int fd) 
	{
		int old_option = fcntl(fd, F_GETFL);
		int new_optin = old_option | O_NONBLOCK;
		fcntl(fd, F_SETFL, new_optin);
		return old_option;
	}
	
	void addfd(int epollfd, int fd)
	{
		epoll_event event;
		event.data.fd = fd;
		event.events = EPOLLIN | EPOLLET;	
		epoll_ctl(epollfd, EPOLL_CTL_ADD, fd, &event);
		setnonblocking(fd);
	}

	int main(int argc, char** argv)
	{
		const char* ip = "127.0.0.1";
		int port = 80;
		
		int ret = 0;
	
		struct sockaddr_in address;
		memset(&address, 0, sizeof(address));
		
		address.sin_family = AF_INET;
		address.sin_port  = htons(port);
		inet_pton(AF_INET, ip, &address.sin_addr);
		
		/* TCP socket */
		int listenfd = socket(AF_INET, SOCK_STREAM, 0);
		assert(-1 != listenfd);
		
		ret = bind(listenfd, (struct sockaddr*)&address, sizeof(address));
		assert(-1 != ret);
		
	
	
		ret = listen(listenfd, 5);
		assert(-1 != ret);
		
		memset(&address, 0, sizeof(address));
		address.sin_family = AF_INET;
		address.sin_port  = htons(port);
		inet_pton(AF_INET, ip, &address.sin_addr);
	
		/* UDP socket  */
		int udpfd = socket(AF_INET, SOCK_DGRAM, 0);
		assert(udpfd != -1);
		
		ret = bind(udpfd, (struct sockaddr*)&address, sizeof(address));
		assert(udpfd != -1);
		assert(ret != -1);
	
		epoll_event events[MAX_EVENT_NUMBER];
		int epollfd = epoll_create(5);
		assert(epollfd);
		
		/*将TCP socket和UDP socket都注册,监控是否可写 */	
		addfd(epollfd, listenfd);	
		addfd(epollfd, udpfd);	
		
		
		while(1) {
			int number = epoll_wait(epollfd, events, MAX_EVENT_NUMBER, -1);
			assert(number >= 0);
				
			int i = 0;
			for(i; i < number; i++) {
				int sockfd = events[i].data.fd;
				if(sockfd == listenfd) {
					struct sockaddr_in client_address;
					socklen_t client_addrlength = sizeof(client_address);
					int connfd = accept(listenfd, (struct sockaddr*)&client_address, &client_addrlength);
					
					/* 将链接上来的TCP链接connfd加入epoll中 */
					addfd(epollfd, connfd);	
	
					/* 如果发生事件的是UDP socket就说明有数据需要读取,UDP是无链接的 */
				} else if (sockfd == udpfd) {
					printf("UDP link\n");
					char buf [UDP_BUFFER_SIZE];
					memset(buf, 0, UDP_BUFFER_SIZE);
	
					struct sockaddr_in client_address;
					socklen_t client_addrlength = sizeof(client_address);
				
					ret = recvfrom(udpfd, buf, UDP_BUFFER_SIZE -1, 0, 
							(struct sockaddr*)&client_address, &client_addrlength);
					if (ret > 0) {
						/*		UDP_BUFFER_SIZE	??	*/
						printf("recv UDP data: \n%s\n", buf);
						sendto(udpfd, buf, ret, 0, 
							(struct sockaddr*)&client_address, client_addrlength);
					}
				 
				/* 如果不是UDP socket上的事件又不是TCP socket上的事件，那就是TCP客户连接可读 */
				} else if (events[i].events & EPOLLIN) {
					char buf[TCP_BUFFER_SIZE];
					while(1) {
						memset(buf, 0, TCP_BUFFER_SIZE);
						ret = recv(sockfd, buf, TCP_BUFFER_SIZE - 1, 0);
						if (ret < 0) {
							if (errno == EAGAIN || errno == EWOULDBLOCK) {
								printf("TCP read over\n");
								break;
							}
							close(sockfd);
							break;
			
						} else if (ret == 0) {
							close(sockfd);				
		
						} else {
							printf("recv TCP data:\n %s\n", buf);
							send(sockfd, buf, ret, 0);					
						}
					}
				}
			}
		}
	
		
	
	
		close(listenfd);
		close(epollfd);
		
		return 0;
	}
	
	
	
	
