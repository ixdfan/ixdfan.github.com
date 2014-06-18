---
author: UCSHELL
comments: true
date: 2013-08-02 16:13:59+00:00
layout: post
title: TCP编程RECV的错误
categories:
- LINUX
tags:
- recv
---

在Linux网络编程中，有一个非常隐蔽的但是又非常容易犯错的要点！那就是recv函数！
昨天写了个简单的聊天程序的服务器端和客户端，但是昨天还有些小错误没有修改，就是发送时候有时候会出现乱码，一开始我以为是终端编码的问题，今天稍微修改了一下，没想到问题更大了！！

以下是没有修改时服务器端代码和客户端代码
    # include <stdio.h>
    # include <string.h>
    # include <unistd.h>
    # include <sys/socket.h>
    # include <sys/select.h>
    # include <signal.h>
    # include <fcntl.h>
    # include <sys/types.h>
    # include <netinet/in.h>
    # include <stdlib.h>
    # define MAXC 100
    # define MAXBUF 1024
    int main()
    {
        int sfd;
        int fdall[MAXC];
        int count;
        struct sockaddr_in addr;
        fd_set fds;
        int maxfd;
        int i, j;
        char buf[MAXBUF];
        int r;
        int len;  
        socklen_t addrlen;
        char ip[20] = "127.0.0.1";
        char message[MAXBUF];
        unsigned int port;
        struct sockaddr_in caddr;
        if(-1 == (sfd = socket(AF_INET, SOCK_STREAM, 6)))
        {
            perror("socket error!"); 
            exit(-1);
        }
         printf("socket success!\n"); 
        //memset(ip, 0, sizeof(ip)); 
        //printf("请输入服务器ip:"); 
        //scanf("%s", ip); 
        printf("请输入服务器端口:"); 
        scanf("%d", &port); 
        
        addr.sin_family = AF_INET;
        addr.sin_port = htons(port); 
        inet_aton(ip, &addr.sin_addr);
        
        if(-1 == (bind(sfd, (struct sockaddr*)&addr, sizeof(addr))))
        {
            perror("bind error!");
            exit(-1);
        }
        printf("bind success!\n");
        
        if(-1 == (r = listen(sfd, 10)))
        {
            perror("listen error!");
            exit(-1);
        }
        printf("listen success!\n");
        
        count = 0;
        maxfd = 0;
        FD_ZERO(&fds);
        for(i=0; i<MAXC; i++)
        {
            fdall[i] = -1;
        }
        
        while(1)
        {
            FD_ZERO(&fds);
            maxfd = 0;
            FD_SET(sfd, &fds);//必须将服务器描述符加入到集合中
            maxfd = sfd;
            //将对应的连接上的客户端加入到集合中去
            for(i=0; i<count; i++)
            {
                if(-1 != fdall[i])
                {
                    FD_SET(fdall[i], &fds);
                    maxfd = fdall[i] > maxfd ? fdall[i] : maxfd;
                }
            }
            //select对集合进行监控
            if(-1 == (r = select(maxfd+1, &fds, 0, 0, 0)))
            {
                perror("system crash!\n");
                exit(-1);
            }
            printf("select success!\n");  
        
            //服务器描述符发生变化说明有客户连接上
            if(FD_ISSET(sfd, &fds))   
            {
                addrlen = sizeof(caddr);
                if(-1 == (fdall[count] = accept(sfd, (struct sockaddr*)&caddr, &addrlen)))
                {
                    perror("accept error!");
                    exit(-1);
                }
                printf("A Client Connect...\n");
                count++;
            }  
            
            for(i=0; i<count; i++)
            {
                //判断发来消息的那个描述符并接受消息
                if(-1  != fdall[i] && FD_ISSET(fdall[i], &fds))  
                {  
                    r = recv(fdall[i], buf, sizeof(buf), 0);
                    if(-1 == r)
                    {
                        perror("TEN NET IS ERROR!");
                        close(fdall[i]);
                        fdall[i] = -1;
                        break;
                    }
                    else if(0 == r)
                    {
                        printf("Client exit");
                        close(fdall[i]);
                        fdall[i] = -1;
                        break;
                    }
                    else
                    {
                    //纯属无聊，为了美观一下
                        strcat(message, "[ "); 
                        strcat(message, (const char*)inet_ntoa(caddr.sin_addr));
                        strcat(message, " ]: "); 
                        strcat(message, buf);
                //循环对在线的客户端进行消息发送
                        for(j=0; j<count; j++)
                        {
                            if(-1 != fdall[j])
                            {
                                send(fdall[j], message, len, 0);
                            }  
                        }
                    }
                }
            }
        }  
        return 0;
    }



## 客户端
    
    # include <stdio.h>
    # include <string.h>
    # include <unistd.h>
    # include <sys/socket.h>
    # include <sys/select.h>
    # include <signal.h>
    # include <fcntl.h>
    # include <sys/types.h>
    # include <netinet/in.h>
    # include <stdlib.h>
    # define MAXC 100
    # define MAXBUF 1024
    //对僵死进程回收
    void handle(int s)
    {
        int status;
        wait(&status);
        printf("资源回收中\n");
        exit(-1);
    }
    int main()
    {
        struct sockaddr_in addr;
        int sfd;
        int cfd;
        int r;
        char ip[20] = "127.0.0.1";
        unsigned int port;   
        int len;  
        signal(SIGCHLD, handle);
        if(-1 == (sfd = socket(AF_INET, SOCK_STREAM, 0)))
        {
            perror("socket error!");
            exit(-1);
        }
        printf("socket success!\n");
    //  memset(ip, 0, 20);
    //  printf("输入链接者IP:");
    //  scanf("%s", ip);
        printf("输入端口号:");
        scanf("%d", &port);
        printf("%s:%d\n", ip, port);
        addr.sin_family = AF_INET;
        addr.sin_port = htons(port);
        inet_aton(ip, &addr.sin_addr);//error!
        
        if(-1 == (r = connect(sfd, (struct sockaddr*)&addr, sizeof(addr))))
        {
            perror("connect error!");
            exit(-1);
        }
        printf("connect success!\n");
        
        if(fork())
        {
            // 父进程输入、发送消息
            char buf[256];
            while(1)
            {
                if(-1 == (r = read(0, buf, 254)))
                {
                    perror("read error!");
                }
                buf[r-1] = '\0';
            
                if(-1 == send(sfd, buf, sizeof(buf), 0))
                {
                    perror("send message error!");
                }
            }
        }
        else
        {
            //子进程接受服务器发来的消息
            char buf[256];
            while(1)
            {
                
                if(-1 == (r = recv(sfd, buf, len, MSG_WAITALL)))
                {
                    printf("recv message error!\n");
                    break;
                }
                if(0 == r)
                {
                    printf("Server close\n");
                    break;
                }
                printf("%s\n", buf);  
            }
            //子进程跳出循环直接结束
            exit(0);
        }
        return 0;
    }










对于TCP编程来讲，它的消息是以SOCK_STREAM(流)的方式来发送的，也就是说消息之间没有东西来标记他们之间的分隔
比如你尝试利用一方循环发送'Hello'消息，一方来循环recv(fd, buf, sizeof(buf), 0)接受消息并答应，结果发现每次打印出来的Hello的个数是没有规律的！
也就是说它直接从流中去取得，取得多少算多少，问题就出现了！当我们发送四个字节的时候它能够将四个字节都填充满在返回吗？就是为了防止出现这种情况所以在recv中才多出了一个选项MSG_WAITALLL

开始还好，但是后来客户端消息出现了乱码，当时我就想可能是因为没有指定MSG_WAITALL造成的
    # include <stdio.h>
    # include <string.h>
    # include <unistd.h>
    # include <sys/socket.h>
    # include <sys/select.h>
    # include <signal.h>
    # include <fcntl.h>
    # include <sys/types.h>
    # include <netinet/in.h>
    # include <stdlib.h>
    # define MAXC 100
    # define MAXBUF 1024
    int main()
    {
        int sfd;
        int fdall[MAXC];
        int count;
        struct sockaddr_in addr;
        fd_set fds;
        int maxfd;
        int i, j;
        char buf[MAXBUF];
        int r;
        int len;  
        socklen_t addrlen;
        char ip[20] = "127.0.0.1";
        char message[MAXBUF];
        unsigned int port;
        struct sockaddr_in caddr;
        if(-1 == (sfd = socket(AF_INET, SOCK_STREAM, 6)))
        {
            perror("socket error!"); 
            exit(-1);
        }
         printf("socket success!\n"); 
        //memset(ip, 0, sizeof(ip)); 
        //printf("请输入服务器ip:"); 
        //scanf("%s", ip); 
        printf("请输入服务器端口:"); 
        scanf("%d", &port); 
        
        addr.sin_family = AF_INET;
        addr.sin_port = htons(port); 
        inet_aton(ip, &addr.sin_addr);
        
        if(-1 == (bind(sfd, (struct sockaddr*)&addr, sizeof(addr))))
        {
            perror("bind error!");
            exit(-1);
        }
        printf("bind success!\n");
        
        if(-1 == (r = listen(sfd, 10)))
        {
            perror("listen error!");
            exit(-1);
        }
        printf("listen success!\n");
        
        count = 0;
        maxfd = 0;
        FD_ZERO(&fds);
        for(i=0; i<MAXC; i++)
        {
            fdall[i] = -1;
        }
        
        while(1)
        {
            //Init the variable!
            FD_ZERO(&fds);
            maxfd = 0;
            FD_SET(sfd, &fds);
            maxfd = sfd;
            
            //Init the Client 
            for(i=0; i<count; i++)
            {
                if(-1 != fdall[i])
                {
                    FD_SET(fdall[i], &fds);
                    maxfd = fdall[i] > maxfd ? fdall[i] : maxfd;
                }
            }
            
            //start select
            if(-1 == (r = select(maxfd+1, &fds, 0, 0, 0)))
            {
                perror("system crash!\n");
                exit(-1);
            }
            printf("select success!\n");  
            //sfd
            if(FD_ISSET(sfd, &fds))   
            {
                addrlen = sizeof(caddr);
                if(-1 == (fdall[count] = accept(sfd, (struct sockaddr*)&caddr, &addrlen)))
                {
                    perror("accept error!");
                    exit(-1);
                }
                printf("A Client Connect...\n");
                count++;
            }  
            
            for(i=0; i<count; i++)
            {
                if(-1  != fdall[i] && FD_ISSET(fdall[i], &fds))  
                {
                    r = recv(fdall[i], &len, sizeof(len), MSG_WAITALL);
                    if(-1 == r)
                    {
                        perror("TEN NET IS ERROR!");
                        close(fdall[i]);
                        fdall[i] = -1;
                        break;
                    }
                    else if(0 == r)
                    {
                        perror("Client exit");
                        close(fdall[i]);
                        fdall[i] = -1;
                        break;
                    }
                    
                    r = recv(fdall[i], buf, len, MSG_WAITALL);
                    if(-1 == r)
                    {
                        perror("TEN NET IS ERROR!");
                        close(fdall[i]);
                        fdall[i] = -1;
                        break;
                    }
                    else if(0 == r)
                    {
                        printf("Client exit");
                        close(fdall[i]);
                        fdall[i] = -1;
                        break;
                    }
                    else
                    {
                        strcat(message, "[ "); 
                        strcat(message, (const char*)inet_ntoa(caddr.sin_addr));
                        strcat(message, " ]: "); 
                        strcat(message, buf);
                
                        for(j=0; j<count; j++)
                        {
                            if(-1 != fdall[j])
                            {
                                len = strlen(message)+1;
                                send(fdall[j], &len, sizeof(len), 0);
                                send(fdall[j], message, len, 0);
                            }  
                        }
                    }
                }
            }
        }  
        return 0;
}


客户端
    
    # include <stdio.h>
    # include <string.h>
    # include <unistd.h>
    # include <sys/socket.h>
    # include <sys/select.h>
    # include <signal.h>
    # include <fcntl.h>
    # include <sys/types.h>
    # include <netinet/in.h>
    # include <stdlib.h>
    void handle(int s)
    {
        int status;
        wait(&status);
        printf("资源回收中\n");
        exit(-1);
    }
    int main()
    {
        struct sockaddr_in addr;
        int sfd;
        int cfd;
        int r;
        char ip[20] = "127.0.0.1";
        unsigned int port;   
        int len;  
        signal(SIGCHLD, handle);
        if(-1 == (sfd = socket(AF_INET, SOCK_STREAM, 0)))
        {
            perror("socket error!");
            exit(-1);
        }
        printf("socket success!\n");
    //  memset(ip, 0, 20);
    //  printf("输入链接者IP:");
    //  scanf("%s", ip);
        printf("输入端口号:");
        scanf("%d", &port);
        printf("%s:%d\n", ip, port);
        addr.sin_family = AF_INET;
        addr.sin_port = htons(port);
        inet_aton(ip, &addr.sin_addr);//error!
        
        if(-1 == (r = connect(sfd, (struct sockaddr*)&addr, sizeof(addr))))
        {
            perror("connect error!");
            exit(-1);
        }
        printf("connect success!\n");
        
        if(fork())
        {
            signal(SIGCHLD, handle);
            char buf[256];
            while(1)
            {
                if(-1 == (r = read(0, buf, 254)))
                {
                    perror("read error!");
                }
                buf[r-1] = '\0';
                len = strlen(buf)+1;      //错误
                if(-1 == send(sfd, &len+1, sizeof(len), 0))
                {
                    perror("send len error!");
                }
                if(-1 == send(sfd, buf, len, 0))
                {
                    perror("send message error!");
                }
            }
        }
        else
        {
            char buf[256];
            while(1)
            {
                
                if(-1 == (r = recv(sfd, &len, sizeof(len), MSG_WAITALL)))   
                {
                    printf("recv len error!\n");
                    break;
                }
                if(0 == r)
                {
                    printf("服务器关闭\n");
                    break;
                }
                if(-1 == (r = recv(sfd, buf, len, MSG_WAITALL)))
                {
                    printf("recv message error!\n");
                    break;
                }
                if(0 == r)
                {
                    printf("服务器关闭\n");
                    break;
                }
                printf("%s\n", buf);  
            }
            exit(0);
        }
        return 0;
    }

好了，执行后发现更完蛋了，服务器中只能接受客户端第一次发的消息，我调试了好多遍，把代码从头读了好多遍,还是没有找到，本来想用GDB调试一下，但是太懒也感觉GDB不是很方便，然后就用的标准输出法，对服务器、客户端各个要点都加上了输出，客户端消息发送时没有问题的， 最终定位到了服务器端recv message处，recv好像是没有执行，然后我就想，recv好像不执行，那它应该在阻塞等待？那么我发送的消息长度有问题？？然后对应着我找到了客户端的send语句，果然，是len的长度的问题，本来我想的是len = strlen(buf)，所以我在发送的时候就写成了len+1，为了将消息最后的'\0'也发送过去。

谁知我却多加了1，结果导致接受到的数据应该发送的长度比原长度多了1，因此无论如何服务器都接受不到，所以产生了错误！

最后做一个总结:

**1、在TCP编程中，要注意recv后一定要使用MSG_WAITALL，如果不加MSG_WAITALL,那么不出错还好，一旦出错，打死你你都找不到哪里出错了！(这是老师的原话)**

**2、在TCP编程中一旦出现消息发送错了、乱码的情况，先查找recv是不是MSG_WAITALL,在查看你的send发送的数据的长度有没有错**


