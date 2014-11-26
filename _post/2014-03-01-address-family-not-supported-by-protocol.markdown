---
layout: post
title: Address family not supported by protocol
categories:
- NETWORK
---

今天看非阻塞connect时候自己写了一个小例子，结果却出现了


> Address family not supported by protocol


看到这个提示一下了懵掉了！这又是怎么回事！
我以为是那里写错了又重新写了一个connect的例子，结果还是一样的错误！

    
    int main(int argc, char** argv)
    {
            const char* ip = "127.0.0.1";
            int port = 80; 
            struct sockaddr_in address;
            address.sin_family = AF_INET;
            address.sin_port = htons(port);
            inet_pton(AF_INET, "127.0.0.1", &address.sin_addr);
    /*      inet_pton(AF_INET, "127.0.0.1", (struct sockaddr*)&address);  */
    
            int sockfd = socket(AF_INET, SOCK_STREAM, 0); 
            assert(-1 != sockfd);
    
            int ret = connect(sockfd, (struct sockaddr*)&address, sizeof(address));
    
            if (-1 == ret) {
                    perror("connect error");
                    exit(-1);
            }
    
            char buf[100] = "this is a test line";
            int len = strlen(buf);
    
            ret = send(sockfd, buf, len + 1, 0); 
            if (ret != len + 1) {
                    perror("send eror");
                    exit(-1);
            }
    
            close(sockfd);
            return 0;
    }


我随手一写就写成了

	inet_pton(AF_INET, "127.0.0.1", (struct sockaddr*)&address);

老了老了！记忆力不行了！
