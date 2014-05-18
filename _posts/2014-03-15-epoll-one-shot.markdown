---
layout: post
title:  EPOLLONESHOT事件
description: 
modified: 
categories: 
- THE LINUX 
tags:
- epoll

---

在使用ET模式，一个socket上的某个事件可能被触发多次，在并发程序中就会引起一个问题;

比如一个线程在读取完某个socket上的数据后开始处理这些数据，而在数据的处理过程中该socket上又有新数据可读(EPOLLIN再次被触发)，此时另外一个线程被唤醒来读取这些新的数据。于是就出现了两个线程操作同一个socket的局面。

我们期望的是一个socket链接在任一时候都只被一个线程处理，这一点我们可以使用epoll的EPOLLONESHOT事件来处理

对于注册了EPOLLONESHOT事件的文件描述符，操作系统最多触发其上注册的一个可读、可写或者异常事件，并且只触发一次;

除非我们使用epoll_ctl函数重置该文件描述符上注册的EPOLLONESHOT事件;

这样当一个线程在处理某个socket时，其他线程是不可能有机会操作该socket的;

注册了EPOLLONESHOT事件的socket一旦被某个线程处理完毕，该线程就应该立即重置这个socket上的EPOLLONESHOT事件，以确保这个socket下一次可读时，其EPOLLIN事件能被触发，进而让其他工作线程偶机会继续处理这个socket


	#include <sys/types.h>
	#include <sys/socket.h>
	#include <netinet/in.h>
	#include <arpa/inet.h>
	#include <assert.h>
	#include <stdio.h>
	#include <unistd.h>
	#include <errno.h>
	#include <string.h>
	#include <fcntl.h>
	#include <stdlib.h>
	#include <sys/epoll.h>
	#include <pthread.h>
	
	#define MAX_EVENT_NUMER		1024
	#define BUFFER_SIZE 		10
	
	struct fds{
		int epollfd;
		int sockfd;
	};
	
	int setnonblocking(int fd) 
	{
		int old_option = fcntl(fd, F_GETFL);
		int new_option = old_option | O_NONBLOCK;
		fcntl(fd, F_SETFL, new_option);
		return old_option;
	}
	
	
	void addfd(int epollfd, int fd, bool oneshot)
	{
		epoll_event event;	
		event.data.fd = fd;
		event.events = EPOLLIN;// | EPOLLET;
	
		if (oneshot) {
			event.events |=  EPOLLONESHOT;
			
		}
		epoll_ctl(epollfd, EPOLL_CTL_ADD, fd, &event);
		setnonblocking(fd);
	}
	
	void reset_oneshot(int epollfd, int fd)
	{
		epoll_event event;
		event.data.fd = fd;
		event.events = EPOLLIN | EPOLLET | EPOLLONESHOT;
		epoll_ctl(epollfd, EPOLL_CTL_ADD, fd, &event);
	}
	
	void* worker(void* arg) 
	{
		int sockfd = ((fds*)arg)->sockfd;
		int epollfd =((fds*)arg)->epollfd;
		printf("start new thread to receive data on fd: %d\n", sockfd); 
		char buf[BUFFER_SIZE];
		memset(buf, 0, BUFFER_SIZE);
	
		/*	要全部读取完毕才可以	*/	
		while (1) {
			int ret = recv(sockfd, buf, BUFFER_SIZE - 1, 0);
			if(0 == ret) {
				close(sockfd);
				printf("foreiner closed the connection\n");
				break;
			} else if (ret < 0) {
				if (errno == EAGAIN) {
			/*	当读取完毕的时候要重新设置epollfd	*/
					reset_oneshot(epollfd, sockfd);	
					printf("read later\n");
					break;
				}
			} else {
				printf("get connect:\n %s\n", buf);
				sleep(5);
			}
		}
		printf("end thread receiving data on fd: %d\n", sockfd);
	}
	
	
	int main(int argc, char** argv)
	{
		const char* 		ip 	= "127.0.0.1";
		int 			port 	= 80;
		int 			ret	= 0;
		struct sockaddr_in 	address;
		bzero(&address, sizeof(address));
		
		address.sin_family 	= AF_INET;
		address.sin_port 	= htons(port);
		inet_pton(AF_INET, ip, &address.sin_addr);
		
		int listenfd = socket(AF_INET, SOCK_STREAM, 0);
		assert(-1 != listenfd);
		
		int on 	= 1;
		ret = setsockopt(listenfd, SOL_SOCKET, SO_REUSEADDR, &on, sizeof(on));
		assert(-1 != ret);
			
		ret = bind(listenfd, (struct sockaddr*)&address, sizeof(address));
		assert(-1 != ret);
		
		ret = listen(listenfd, 5);		
		assert(-1 != ret);
	
		epoll_event events[MAX_EVENT_NUMER];
		int epollfd = epoll_create(5);
		assert(-1 != epollfd);
		
		addfd(epollfd, listenfd, false);	
		
	
		while (1) {
			int ret = epoll_wait(epollfd, events, MAX_EVENT_NUMER, -1);
			if (ret < 0) {
				printf("epoll_wait failure\n");
				break;
			}
		
			for(int i =0; i < ret; i++) {
				int sockfd = events[i].data.fd;
				
				if (sockfd == listenfd) {
					struct sockaddr_in client_address;
					socklen_t client_addrlength = sizeof(client_address);
					int connfd = accept(listenfd, (struct sockaddr*)&client_address, &client_addrlength);	
					addfd(epollfd, connfd, true);
				} else if (events[i].events & EPOLLIN) {
					pthread_t thread;
					fds fds_for_new_worker;		
					fds_for_new_worker.epollfd = epollfd;
					fds_for_new_worker.sockfd = sockfd;
					pthread_create(&thread, NULL, worker, &fds_for_new_worker);
					
				} else {
					printf("something else happened\n");
				}
			}
		}
	
	
		close(listenfd);
		close(epollfd);
		return 0;
	
		
	}


从工作线程函数worker来看，如果一个工作线程处理完某个socket上的一次请求(我们用休眠5s来模拟这个过程)之后，有接收到该socket上心的客户请求，则该线程将继续为这个socket服务。并且因为该socket上注册了EPOLLONESHOT事件，其他线程没有机会接触这个socket，如果工作线程等待5s后仍然没有受到该socket上的下一批客户数据，则它就昂放弃为该socket服务，同时他调用reset_oneshot函数来重置该socket上注册事件，这将使epoll有机会再次检测到该socket上的EPOLLIN事件，进而使得其他线程有机会为该socket服务;
尽管一个socket在不同事件可能被不同的的线程处理，但同一时刻肯定只有一个线程在为它服务，这就保证了连接的完整性，从而避免了很多可能的竞态条件



