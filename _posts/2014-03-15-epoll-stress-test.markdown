---
layout: post
title:  利用epoll进行压力测试
description: 
modified: 
categories: 
- THE Network 
tags:
- epoll
---

压力测试程序有很多中实现方式，比如I/O复用的方式，多线程、多进程并发编程方式，以及结合这些使用，不过单纯的I/O复用方式的施压程度是最高的，因为线程和进程的调度本身也要占用一定的CPU时间;

以前的程序都是在服务器端利用epoll进行IO复用，检测某个端口上是否有新的连接连接上来，有就将他加入epoll中监控，一旦发生读写事件就去处理;

在这个例子中利用将所有创建的sockfd都加入到epoll中，然后检测这些sockfd是否可读、可写，并做出相应的处理

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
	
	#define MAX_EVENTS_NUMBER 	10000
	#define BUF_SIZE		2048
	/*每个客户连接不停的向服务器发送这个请求*/
	static const char* request = "GET http://localhost/index.html HTTP/1.1\r\n
				Connection: keep-alive\r\n\r\nxxxxxxxxxxxxxx";
	
	int setnonblocking(int fd)
	{
		int old_option = fcntl(fd, F_GETFL);
		int new_option = old_option | O_NONBLOCK;
		fcntl(fd, F_SETFL, new_option);
		return new_option;
	}
	
	void addfd(int epoll_fd, int fd)
	{
		epoll_event event;
		event.data.fd = fd;
		event.events = EPOLLOUT | EPOLLET | EPOLLERR;
		epoll_ctl(epoll_fd, EPOLL_CTL_ADD, fd, &event);
		setnonblocking(fd);
	}
	
	/*	向服务器写入len字节的数据	*/
	bool write_nbytes(int sockfd, const char* buffer, int len)
	{
		int bytes_write = 0;	
		printf("write out %d bytes to socket %d\n", len, sockfd);
		
		while(1){
			bytes_write = send(sockfd, buffer, len, 0);
			
			if (bytes_write == -1) {
				return false;	
			} else if (0 == bytes_write) {
				return false;
			}
		/*
	 	* 如果buffer中数据长度超过缓冲区的长度，可能一次性发送不完，
		* 那么就要分多次发送，每次发送send能发送的最大长度，直到len的长度变为0,
		* 则表示buffer中的数据已经完全发送完了！
	 	* 考虑的非常周到
	 	*/	
			len -= bytes_write;
			buffer = buffer + bytes_write;
			
			if (len <= 0) {
				return true;
			}
		}
	}
	
	
	/*	从服务器读取数据	*/
	bool read_once(int sockfd, char* buffer, int len)
	{
		int bytes_read = 0;
		memset(buffer, 0, len);
		while(1) {
			bytes_read = recv(sockfd, buffer, len, 0);
			if (bytes_read == -1) {
				if(errno == EAGAIN || errno == EWOULDBLOCK) {
					//return true;	
					break;
				}
				return false;
		
			} else if (bytes_read == 0) {
			/*	return false;	*/
				//return true;
				break;
			}
			printf("read in %d bytes from socket %d with content: %s\n", bytes_read, 
				sockfd, buffer);
		}
		return true;
	}
	
	/*	向服务器发起num个TCP链接，我们通过改变num来调整测试压力	*/
	
	void start_conn(int epoll_fd, int num, const char* ip, int port)
	{
		int ret = 0;
		struct sockaddr_in address;
		memset(&address, 0, sizeof(address));
		address.sin_family = AF_INET;
		address.sin_port = htons(port);
		inet_pton(AF_INET, ip, &address.sin_addr);
	
		int i = 0;
		for(i = 0; i < num; i++){
	//		sleep(2);
			int sockfd = socket(AF_INET, SOCK_STREAM, 0);
			
			printf("create 1 sock\n");
			
			if (sockfd < 0) {
				printf("sockfd create error\n");
				continue;
			}
		
			if (connect(sockfd, (struct sockaddr*)&address, sizeof(address)) == 0) {
				printf("build connection %d\n", i);
				addfd(epoll_fd, sockfd);
			} else {
				perror("connect error:%s\n");
			}
		}
	}
	
	
	void close_conn(int epoll_fd, int sockfd)
	{
		epoll_ctl(epoll_fd, EPOLL_CTL_DEL, sockfd, 0);
		close(sockfd);
	}
	
	
	/*main ip port number*/
	int main(int argc, char** argv)
	{
		if (argc < 4) {
			printf("%s : ip port number\n", basename(argv[0]));
			exit(-1);
		}
	
		int epoll_fd = epoll_create(100);
		start_conn(epoll_fd, atoi(rgv[3]), argv[1], atoi(argv[2]));
		epoll_event events[MAX_EVENTS_NUMBER];
		
		char buffer[BUF_SIZE];
		
		while(1) {
			int fds = epoll_wait(epoll_fd, events, MAX_EVENTS_NUMBER, 20000);
			int i = 0;
			for (i; i < fds; i++) {
				int sockfd = events[i].data.fd;
				if (events[i].events & EPOLLIN) {
					if (!read_once(sockfd, buffer, 2048)) {
						close_conn(epoll_fd, sockfd);
					}
					/*如果有事件可读，那么读取完毕后在将这个描述符加入监控，监视他是否可写*/
					struct epoll_event event;	
					event.events = EPOLLOUT | EPOLLET | EPOLLERR;	
					event.data.fd = sockfd;
					epoll_ctl(epoll_fd, EPOLL_CTL_MOD, sockfd, &event);
	
				/*如果事件可写，那么在向描述符写完之后将这个描述符加入的监控中，监控他是否可读*/
				} else if (events[i].events & EPOLLOUT) {
					if (!write_nbytes(sockfd, request, strlen(request))) {
						printf("send request error\n");
						close_conn(epoll_fd, sockfd);
					}
					struct epoll_event event;		
					event.events = EPOLLIN | EPOLLET | EPOLLERR;
					event.data.fd = sockfd;	
					epoll_ctl(epoll_fd, EPOLL_CTL_MOD, sockfd, &event);
	
				} else if (events[i].events & EPOLLERR) {
					close_conn(epoll_fd, sockfd);
				}
			}
		}
	
		return 0;
	}
	
