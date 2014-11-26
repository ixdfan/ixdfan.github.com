---
layout: post
title: gethostbyxxx与xxxprotoxxx函数
categories:
- LINUX
tags:
- gethostbyxxx
- xxxprotoxxx
---

==========================================

什么是可重入函数与不可重入函数？

在实时系统中，常常会有多个任务调用同一个函数的情况，如果这个函数是不可重入的函数的话，那么不同的任务调用这个函数的时候可能修改其他任务调用这个函数的数据，从而导致不可预料的后果。

所谓的可重入是指一个可以被多个任务调用的过程，任务在调用时不必担心数据是否会出错。不可重入函数在实时系统设计中被视为不安全的函数

满足下列条件的函数是不可重入函数：

(1).函数体内使用了静态的数据结构

(2).函数体内调用了malloc或是free函数

(3).函数体内调用了标准IO函数

==========================================

    
    void sethostent(int stayopen);
    void endhostent(void);
    
    struct hostent *gethostbyname(const char *name);
    struct hostent *gethostbyaddr(const void *addr,
                                         socklen_t len, int type);


第一个参数指向一个struct in_addr的结构，需要将查询主机的ip填写到这个结构中

第二个参数len表示第一个参数所指向的区域的大小

第三个参数typd指定要查询主机IP地址的类型IPV4就是AF_INET

==========================================

注意：

**gethostbuname与gethostbyaddr是不可重入的函数，由于传出值为一块静态的内存地址，当另一次查询到来的时候这块区域会被占用**

==========================================

    
    struct hostent
    {
    	char* h_name;
    	char** h_aliases;
    	int h_addrtype;
    	int h_length;
    	char** h_addr_list;
    };
    #define h_addr h_addr_list[0]  
    /*  为了向前兼容所定义的宏  */


h_name 主机的官方名称 如www.baidu.com

h_aliases 主机别名，可能有多个

h\_addrtype 主机地址的类型 AF\_INET位ipv4，AF_INET6为ipv6

h_length ip地址的长度对于ipv4来讲是4

h_addr_list 主机ip地址的链表，每一个都是h\_length的长度

**特别注意**:

h_addr_list的用法如下：

    
    printf("IP: %s\n", inet_ntoa(（struct in_addr*）h->h_addr));


每次用的时候都习惯直接输出h_addr，但这样是错误的

一定要注意,**不能直接输出h_addr**

==========================================

xxxprotoxxx函数

    
    void setprotoent(int stayopen);
    //打开文件/etc/protocols,当stayopen为1时，调用getprotobyname或者getprotobynumber查询协议时并不关闭文件
    
    void endprotoent(void);
    //关闭文件/etc/protocols
    
    struct protoent *getprotoent(void);
    //从文件/etc/protocols中读取一行并返回指向struct protoent的指针，不过需要实现打开/etc/protocols文件
    
    struct protoent *getprotobyname(const char *name);
    
    struct protoent *getprotobynumber(int proto);


==========================================

    
    struct protoent
    {
    	char* p_name;		/*   协议的官方名称	*/
    	char** p_aliases;	/*   别名列表		*/
    	int p_proto;		/*   协议的值		*/
    };


==========================================

gethostbyname实例：

    
    #include <netdb.h>
    #include <string.h>
    #include <stdio.h>
    int main()
    {
        char host[] = "www.baidu.com";
        struct hostent* ht = NULL;
    
        ht = gethostbyname(host);
        printf("type : %s\n", AF_INET == ht->h_addrtype ? "AF_INET" : "AF_INET6");
        printf("length : %s\n", ht->h_length);
    
        int i = 0;
        while(NULL != ht->h_addr_list[i])
        {
            printf("IP : %s\n", inet_ntoa((unsigned int*)ht->h_addr_list[i++]));
        }
    
        i = 0;
        while(NULL != ht->h_aliases[i])
        {
            printf("alias %d: %s\n", i, ht->h_aliases[i]);
        }
        return 0;
    }	return 0;
    }


==========================================

gethostbyname不可重入实例：

    
    #include <netdb.h>
    #include <string.h>
    #include <stdio.h>
    int main()
    {
        char host1[] = "www.baidu.com";
        char host2[] = "www.sohu.com";
        struct hostent* ht = NULL;
    
        struct hostent* ht1 = NULL;
        struct hostent* ht2 = NULL;
    
        ht1 = gethostbyname(host1); /*  www.baidu.com  */
        ht2 = gethostbyname(host2); /*  www.sohu.com   */
    
        int j = 0;
        for(j; j<2; j++)
        {
            if(0 == j)
                ht = ht1;
            else
                ht = ht2;
    
            if(ht)
            {
                int i = 0;
                printf("get the host : %s addr\n", ht == ht1 ? host1 : host2);
                printf("name : %s\n", ht->h_name);
    
                printf("type : %s\n", AF_INET == ht->h_addrtype ? "AF_INET" : "AF_INET6");
                printf("length : %s\n", ht->h_length);
    
                int i = 0;
                while(NULL != ht->h_addr_list[i])
                {
                    printf("IP : %s\n", inet_ntoa((unsigned int*)ht->h_addr_list[i++]));
                }
    
                i = 0;
                while(NULL != ht->h_aliases[i])
                {
                    printf("alias %d: %s\n", i, ht->h_aliases[i]);
                }
            }
        }
        return 0;
    }


可以看到输出的IP都是相同的，所以gethostbyname是不可重用的，可以看到www.sohu.com的信息都被www.baidu.com覆盖了

因此使用gethostbyname进行主机查询的时候函数返回后要马上将结果取出，否则会被后面的函数调用过程覆盖

==========================================

getprotobyname实例:

    
    #include <netdb.h>
    #include <stdio.h>
    
    int main()
    {
            const char* protocol_name[] = {"ip", "icmp", "udp", "tcp", NULL};
            setprotoent(1);//打开
            struct protoent* pt = NULL;
            int j = 0;
            while(NULL != protocol_name[j])
            {
                    int i = 0;
                    pt = getprotobyname((const char*)&protocol_name[j][0]);
                    if(NULL != pt)
                    {
                            printf("protocol name : %s,", pt->p_name);
                            if(NULL != pt->p_aliases)
                            {
                                    printf("aliases name : ");
                                    while(pt->p_aliases[i])
                                    {
                                            printf("%s ", pt->p_aliases[i]);
                                            i++;
                                    }
                                    printf(",value:%d\n", pt->p_proto);
                            }
                    }
                    j++;
            }
        endprotoent(); //关闭
            return 0;
    }
    
    }
