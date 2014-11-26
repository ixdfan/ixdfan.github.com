---
layout: post
title:  简单的心跳包机制
description: 
modified: 
categories: 
- linux
tags:
- 
---

心跳包通常用于长连接的保持

心跳包机制像心跳一样每个固定时间发送一次,依次来告诉服务器,我还活着,通常是用来保持长连接的;

通常的做法是在一定的时间间隔内发送一个空包给客户端,客户端收到后返回一个空包給服务器,如果在一定时间内没有收到客户端发送来的反馈包,哪就表名客户端掉线了!


步骤:

##### 1.客户端定时发送一个心跳包给服务器,同时启动超时定时器
##### 2.服务器收到客户端的心跳包之后返回一个包
##### 3.客户端收到服务器的应答后说明服务器正常,重置超时计时器
##### 4.如果客户端超时定时器超时后依然没有收到服务器的响应,就说明服务器挂了

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
	#include <sys/time.h>
	
	#define MAXBUF 	1024
	
	
	int
	main(int argc, char **argv)
	{
	    int             sockfd;
	    int             len;
	    struct sockaddr_in dest;
	    char            buffer[MAXBUF];
	    char            heartbeat[20] = "hello server";
	
	    fd_set          rfds;
	    struct timeval  tv;
	    int             retval,
	                    maxfd = -1;
	
	    const char     *ip = "127.0.0.1";
	    int             port = 80;
	
	    sockfd = socket(AF_INET, SOCK_STREAM, 0);
	    assert(sockfd != -1);
	
	    bzero(&dest, sizeof(dest));
	    dest.sin_family = AF_INET;
	    dest.sin_port = htons(port);
	    inet_pton(AF_INET, ip, &dest.sin_addr);
	
	    int ret = connect(sockfd, (struct sockaddr *) &dest, sizeof(dest));
	    assert(ret != -1);
	
	    printf ("%s","ready to start chatting\n direct input messages and enter to send message to the server\n "); 
	
	    while (1) {
		FD_ZERO(&rfds);
		FD_SET(0, &rfds);
		maxfd = 0;
	
		FD_SET(sockfd, &rfds);
	
		if (maxfd > sockfd) {
		    maxfd = sockfd;
		}
	
		tv.tv_sec = 2;
		tv.tv_usec = 0;
	
		retval = select(maxfd + 1, &rfds, NULL, NULL, &tv);
		assert(retval != -1);
	
		/*
		 * 定时2s，retval=0表示时间用完 
		 */
		if (retval == 0) {
		    len = send(sockfd, heartbeat, strlen(heartbeat), 0);
	
		    if (len < 0) {
			printf
			    ("message '%s'failed to send!\n the error code is %d,, error message %s\n",
			     heartbeat, errno, strerror(errno));
			break;
	
		    } else {
			// printf("news : %s send, sent a total of %d bytes\n",
			// heartbeat, len);
			continue;
		    }
	
	
		} else {
		    if (FD_ISSET(sockfd, &rfds)) {
			bzero(buffer, MAXBUF + 1);
			len = recv(sockfd, buffer, MAXBUF, 0);
	
			if (len > 0) {
			    printf
				("successfully received the message:%s, %d bytes of data\n",
				 buffer, len);
	
	
			} else {
	
			    if (len < 0) {
				printf
				    ("failed to receive the message!\nthe error code is %d, error message is %s\n",
				     errno, strerror(errno));
			    } else {
				printf("chat to terminal\n");
				break;
			    }
			}
	
		    }
	
		    if (FD_ISSET(0, &rfds)) {
			bzero(buffer, MAXBUF);
			fgets(buffer, MAXBUF, stdin);
	
			if (!strncasecmp(buffer, "quit", 4)) {
			    printf("own request to terminat the chat\n");
			    break;
			}
	
			len = send(sockfd, buffer, strlen(buffer) + 1, 0);
			assert(len >= 0);
	
			printf("news %s send, sent a total %d bytes\n", buffer,
			       len);
		    }
	
	
		}
	
	
	    }
	
	    close(sockfd);
	
	    return 0;
	}
	
