---
layout: post
title: MSG_OOB的使用
description: 
modified: 

tags: [MSG_OOB]
---
UDP没有实现带外数据，TCP也没有真正实现带外数据，不过TCP利用头部的紧急指针标志和紧急指针两个字段，给应用程序提供了一种紧急方式；

TCP的紧急方式利用传输普通数据的连接来传输紧急数据，这种紧急数据的含义和带外数据类似，因此，将TCP紧急数据成为带外数据。

##### TCP发送带外数据的过程:
假设一个进程已经往某个TCP连接的发送缓冲中写入了N字节的普通数据，并等待其发送。在数据发送前，该进程又向这个连接写入3字节的带外数据"abc".此时，待发送的TCP报文段的头部将被设置URG标记，并且紧急指针被设置为指向最后一个带外数据的下一个字节(减去当前TCP报文段的序号值得到其头部中的紧急偏移值)

							TCP发送缓冲区
	---------------------------------------------------------------------
	|第一字节|				|第N字节		| a | b | c(OOB) | 紧急指针|
    ---------------------------------------------------------------------
    
从图中可以看到，发送端一次发送的多字节的带外数据中只有最后一个字节被当做带外数据(字母c)，而其他数据(a和b)本当成普通数据。

如果TCP模块以多个TCP报文段来发送图中的TCP发送缓冲区中的内容，则每个TCP报文段豆浆被设置URG标志，并且他们的紧急指针指向同一个位置(数据流中带外数据的下一个位置)，但是只有一个TCP报文段真正携带带外数据。

##### TCP接收带外数据的过程:
TCP接收端只有在接收到紧急指针标志时才检查紧急指针，然后根据紧急指针所指的位置确定带外数据的位置，并将它读入一个特殊的缓冲区，**这个缓冲区只有一个字节，称带外缓存**，如果上层应用程序设置没有及时将带外数据从带外缓冲中读出，则后续的带外数据(如果有的话)将覆盖它。

##### SO_OOBINLINE选项:

前面讨论的带外数据的接收过程是TCP模块接收带外数据的默认方式，如果我们给TCP连接设置了SO_OOBINLINEE选项，则带外数据将和普通数据一样被TCP模块存放在TCP接收缓冲区中，此时应用程序要像读取普通数据一样来读取带外数据，这种情况下如何区分带外数据和普通数据?可以使用紧急指针来指出带外数据的位置。


	/* 发送带外数据 */
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
	
	int main(int argc, char** argv)
	{
		const char* ip = "127.0.0.1";
		int port = 9999;
		
		struct sockaddr_in server_address;
		memset(&server_address, 0, sizeof(server_address));
		
		server_address.sin_family = AF_INET;
		server_address.sin_port = htons(port);
		inet_pton(AF_INET, ip, &server_address.sin_addr);
		
		int sockfd = socket(AF_INET, SOCK_STREAM, 0);
		assert(sockfd != -1);
		
		if (connect(sockfd, (struct sockaddr*)&server_address, sizeof(server_address)) < 0) {
			perror("connect failed\n");
	
		} else {
			const char* oob_data = "abc";
			const char* normal_data = "123";
			send(sockfd, normal_data, strlen(normal_data), 0);
			send(sockfd, oob_data, strlen(oob_data), MSG_OOB);
			send(sockfd, normal_data, strlen(normal_data), 0);
		}
		
		close(sockfd);
	
		return 0;
	}
	
	
	
	/* 接受带外数据 */
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
	
	#define BUF_SIZE 1024
	int main(int argc, char** argv)
	{
		const char* ip = "127.0.0.1";
		int port = 9999;
		
		struct sockaddr_in address;
		memset(&address, 0, sizeof(address));
		
		address.sin_family = AF_INET;
		address.sin_port = htons(port);
		inet_pton(AF_INET, ip, &address.sin_addr);
		
		int sockfd = socket(AF_INET, SOCK_STREAM, 0);
		assert(sockfd != -1);
		
		int ret = bind(sockfd, (struct sockaddr*)&address, sizeof(address));
		assert(ret != -1);
		
		ret = listen(sockfd, 5);
		assert(ret != -1);
		
		struct  sockaddr_in client;
		socklen_t client_length = sizeof(client);
		
		int connfd = accept(sockfd, (struct sockaddr*)&client, &client_length);
		if (connfd < 0) {
			printf("accept error\n");
	
		} else {
			char buf[BUF_SIZE];
	
			memset(buf, 0, BUF_SIZE);
			ret = recv(connfd, buf, BUF_SIZE-1, 0);
			assert(ret > 0);
			printf("get %d bytes of normal data:\n%s\n", ret, buf);
	
				
			memset(buf, 0, BUF_SIZE);
			ret = recv(connfd, buf, BUF_SIZE-1, MSG_OOB);
			assert(ret > 0);
			printf("get %d bytes of oob data:\n%s\n", ret, buf);
			
			
			memset(buf, 0, BUF_SIZE);
			ret = recv(connfd, buf, BUF_SIZE-1, 0);
			assert(ret > 0);
			printf("get %d bytes of normal data:\n%s\n", ret, buf);
		
			close(connfd);
		}
		close(sockfd);
		
		
		return 0;
	}
	

##### 程序执行结果:
	
	get 3 bytes of normal data:
	123
	get 1 bytes of oob data:
	c
	get 2 bytes of normal data:
	ab

由此可见，客户端发送给服务器的3字节带外数据"abc"中，仅有最后一个字符'c'被服务器真正当成了带外数据接收;

并且服务器对正常数据的接收被带外数据截断，也就是说前一部分正常数据"123ab"和后续正常数据"123"是不能被一个recv调用全部读出的。
	
##### tcpdump抓包结果:

	15:49:07.237438 IP 127.0.0.1.54354 > 127.0.0.1.distinct: Flags [S], seq 3396511771, win 43690, options [mss 65495,sackOK,TS val 6665585 ecr 0,nop,wscale 7], length 0
		0x0000:  4500 003c 1d6a 4000 4006 1f50 7f00 0001
		0x0010:  7f00 0001 d452 270f ca72 a81b 0000 0000
		0x0020:  a002 aaaa fe30 0000 0204 ffd7 0402 080a
		0x0030:  0065 b571 0000 0000 0103 0307
	15:49:07.237459 IP 127.0.0.1.distinct > 127.0.0.1.54354: Flags [S.], seq 12605814, ack 3396511772, win 43690, options [mss 65495,sackOK,TS val 6665585 ecr 6665585,nop,wscale 7], length 0
		0x0000:  4500 003c 0000 4000 4006 3cba 7f00 0001
		0x0010:  7f00 0001 270f d452 00c0 5976 ca72 a81c
		0x0020:  a012 aaaa fe30 0000 0204 ffd7 0402 080a
		0x0030:  0065 b571 0065 b571 0103 0307
	15:49:07.237478 IP 127.0.0.1.54354 > 127.0.0.1.distinct: Flags [.], ack 1, win 342, options [nop,nop,TS val 6665585 ecr 6665585], length 0
		0x0000:  4500 0034 1d6b 4000 4006 1f57 7f00 0001
		0x0010:  7f00 0001 d452 270f ca72 a81c 00c0 5977
		0x0020:  8010 0156 fe28 0000 0101 080a 0065 b571
		0x0030:  0065 b571
	15:49:07.237521 IP 127.0.0.1.54354 > 127.0.0.1.distinct: Flags [P.], seq 1:4, ack 1, win 342, options [nop,nop,TS val 6665586 ecr 6665585], length 3
		0x0000:  4500 0037 1d6c 4000 4006 1f53 7f00 0001
		0x0010:  7f00 0001 d452 270f ca72 a81c 00c0 5977
		0x0020:  8018 0156 fe2b 0000 0101 080a 0065 b572
		0x0030:  0065 b571 3132 33
	15:49:07.237532 IP 127.0.0.1.54354 > 127.0.0.1.distinct: Flags [P.U], seq 4:7, ack 1, win 342, urg 3, options [nop,nop,TS val 6665586 ecr 6665585], length 3
		0x0000:  4500 0037 1d6d 4000 4006 1f52 7f00 0001
		0x0010:  7f00 0001 d452 270f ca72 a81f 00c0 5977
		0x0020:  8038 0156 fe2b 0003 0101 080a 0065 b572
		0x0030:  0065 b571 6162 63
	
	
通过tcpdump抓取的数据来看，可以看到标志U，这表示在TCP头部设置了紧急标志，"urg 3"是紧急偏移值，他指出带外数据在字节流中的位置的下一个位置是7，其中的4是该TCP报文段的序号值相对与初始序号值的偏移，因此带外数据是字节流中第6个字符，也就是字符"c"

##### 注意:

flags参数只对send和recv的当前调用有效，我们也可以使用setsockopt永久的改变socket的某些属性;


在实际的应用中我们通常是没有办法预期带外数据何时到来的！

Linux内核检测到TCP紧急标记时，将通知应用程序有带外数据需要接受;

内核同志应用程序带外数据到达的两种常见方式是:
** * I/O复用产生的异常事件**
** * SIGURG信号**

但是，即使应用程序得到了有带外数据需要接受的通知，还需要知道带外数据在数据流中具体的位置，才能准确接受带外数据

	#include <sys/socket.h>
	int sockatmark(int sockfd);

sockatmark判断sockfd是否处于带外标记，即下一个读取到的数据是否是带外数据。
* 如果是sockatmark返回1，此时我们便可以使用带有MSG_OOB标志的recv调用来接受带外数据.
* 如果不是则返回0


	/* 利用异常事件来读取MSG_OOB信息 */
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
	
	int main(int argc, char** argv)
	{
	
		const char* ip = "127.0.0.1";
		int port = 80;
		int ret = 0;
		struct sockaddr_in address;
		memset(&address, 0, sizeof(address));
		
		address.sin_family = AF_INET;
		address.sin_port = htons(port);
		inet_pton(AF_INET, ip, &address.sin_addr);
		
		int listenfd = socket(AF_INET, SOCK_STREAM, 0);
		assert(-1 != listenfd);
		
		ret = bind(listenfd, (struct sockaddr*)&address, sizeof(address));
		assert(-1 != ret);
		
		ret = listen(listenfd, 5);
		assert(ret != -1);
		
		struct sockaddr_in client_address;
		socklen_t client_addresslength = sizeof(client_address);
		int connfd = accept(listenfd, (struct sockaddr*)&client_address, &client_addresslength);
		
		if (connfd < 0 ) {
			printf("errno is : %d\n", errno);
			close(listenfd);
		}
	
		
		char buf[1024];
		fd_set read_fds;
		fd_set exception_fds;
		FD_ZERO(&read_fds);
		FD_ZERO(&exception_fds);
		
		while(1) {
			memset(buf, 0, sizeof(buf));
			
			FD_SET(connfd, &read_fds);
			FD_SET(connfd, &exception_fds);
		
			ret = select(connfd + 1, &read_fds, NULL, &exception_fds, NULL);
			if (ret < 0) {
				printf("selection failure\n");
				break;
			}
			
			if (FD_ISSET(connfd, &read_fds)) {
				ret = recv(connfd, buf, sizeof(buf) - 1, 0);
				if (ret <= 0) {
					break;
				}
				printf("get %d bytes of normal data: %s\n", ret, buf);
			} else if (FD_ISSET(connfd, &exception_fds)) {
			
				ret = recv(connfd, buf, sizeof(buf) - 1, MSG_OOB);
				if (ret <= 0) {
					break;
				} 
				printf("get %d bytes of oob data: %s\n", ret, buf);
			}
				
		}
	
		close(connfd);
		close(listenfd);
			
		return 0;
	}





