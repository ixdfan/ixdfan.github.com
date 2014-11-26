---
layout: post
title: 非阻塞connect的实现
tags: [connect,nonblock]
---
**当非阻塞的socket调用connect，而连接又没有立即建立时候，这时候connect出错，设置errno的值为EINPROGRESS。**

在这种情况下，我们可以调用select或是poll等函数来监听这个连接失败的socket上的可写事件。

当select、poll等函数返回后，再利用getsockopt来读取错误码并清除该socket上的数据，如果错误码是0，则表示连接建立成功，否则连接建立失败。

利用上面的非阻塞connect方式，我们就能同时发起多个连接并一起等待。



	
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
	
	#define BUFFER_SIZE	1024
	int setnonblocking(int fd)
	{
		int old_option = fcntl(fd, F_GETFL);
		int new_option = old_option | O_NONBLOCK;
		fcntl(fd, F_SETFL, new_option);
		return old_option;
	}
	
	/*time是超时时间，函数成功则返回已经处于连接状态的socket，失败则返回-1*/
	int unblock_connect(const char* ip, int port, int time) 
	{
		int ret = 0;
		struct sockaddr_in address;
		bzero(&address, sizeof(address));
		address.sin_family = AF_INET;
		address.sin_port  = htons(port);
		inet_pton(AF_INET, ip, &address.sin_addr);
		
		
		int sockfd = socket(AF_INET, SOCK_STREAM, 0);
		int fdopt = setnonblocking(sockfd);
		
		ret = connect(sockfd, (struct sockaddr*)&address, sizeof(address));
		if (ret == 0) {
			/*连接成功则恢复sockfd的属性，并立刻返回*/
			printf("connect with server immediately\n");
			fcntl(sockfd, F_SETFL, fdopt);
			return sockfd;
		} else if (errno != EINPROGRESS) {
				printf("not EINPROGRESS\n");
				exit(-1);
			/*
	 		*如果连接没有建立，那么只有当errno为EINPROGRESS时候
			*才表示连接还在进行，否则就出错返回
			*/
		}
		
		
		fd_set readfds;
		fd_set writefds;
		struct timeval timeout;	
		
	
		FD_ZERO(&readfds);	
		FD_ZERO(&writefds);	
		FD_SET(sockfd, &writefds);
		
		timeout.tv_sec = time;
		timeout.tv_usec = 0;
		
		ret = select(sockfd + 1, NULL, &writefds, NULL, &timeout);
		if (ret <= 0) {	/* 超时或是是出错都立刻返回 */
			printf("connection time out\n");
			close(sockfd);
			return -1;
		}
		
		if (!FD_ISSET(sockfd, &writefds)) {
			printf("no events on sockfd found\n");
			close(sockfd);
			return -1;
		}
		
		
		int error = 0;
		socklen_t length = sizeof(errno);
	
		/* getsockopt来获取并清除sockfd上的错误 */	
		if (getsockopt(sockfd, SOL_SOCKET, SO_ERROR, &error, &length) < 0) {
			printf("getsockopt error");
			close(sockfd);
			return -1;
		}
		
		/* errno不为0则表示出错 */
		if (error != 0) {
			printf("connection failed after select with the error:%d\n", error);
			close(sockfd);
			return -1;
		}
	
		/* 连接成功 */	
		printf("connection ready after select with the socket: %d\n", sockfd);	
		send(sockfd, "12", 3, 0);
		fcntl(sockfd, F_SETFL, fdopt);
		return sockfd;
	
		
	}
	
	
	int main(int argc, char** argv)
	{
		const char* ip = "127.0.0.1";
		int port = 80;
		
		int sockfd = unblock_connect(ip, port, 10);
		
		if (sockfd < 0) {
			return 1;
		}
		close(sockfd);
		
		return 0;
	}
	
	
#####但是以上的代码存在移植性的问题:
* 非阻塞的socket可能导致connect始终失败
* select对处于EINPROGRESS状态下的socket可能不起作用
* 对于出错的socket，getsocketopt在有些系统上返回-1，但是有点系统上(比如伯克利的UNIX)上返回0


