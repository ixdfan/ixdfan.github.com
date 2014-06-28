---
layout: post
title: netfilter框架编程学习(一)
categories:
- LINUX
tags:
- netfilter
---

内核层的“Hello world”实例：

    
    /*
      hello.c
    */
    
    /*	内核的头文件	*/
    #include <linux/module.h>	
    #include <linux/init.h>
    
    /*	版权声明		*/
    MODULE_LICENSE("Dual BSD/GPL");
    
    /*	初始化模块	*/
    static int helloworld_init(void)
    {
            printk(KERN_ALERT "hello world modul init\n");
            return 0;
    }
    /*	内核模块加载函数	*/
    moudule_init(helloworld_init);
    
    /******************************************/
    
    /*	清理模块		*/
    static void helloworld_exit(void)
    {
            printk(KERN_ALERT "hello world modul exit\n");
    }
    /*	内核模块卸载函数	*/
    moudule_exit(helloworld_exit);
    
    /*作者、软件描述、版本、别名等声明信息*/
    MODULE_AUTHOR("pangxie009");
    MODULE_DESCRIPTION("Hello world ");
    MODULE_VERSION("0.0.1");
    MODULE_ALIAS("Example ");


========================================

可能看不到输出，可以使用dmesg命令得到内核中打印的信息

代码中的描述信息可以使用modinfo获得，如#modinfo hello.ko

已经加载的内核模块信息以及模块间的以来关系可以通过命令lsmod获得

========================================

    
    static int helloworld_init(void)
    {
            printk(KERN_ALERT "hello world modul init\n");
            return 0;
    }
    moudule_init(helloworld_init);


-----------------------------------------

也可以直接使用init_module函数来写

    
    int init_module()
    {
      printk(KERN_ALERT "hello world modul init\n");
      return 0;
    }

=========================================

    
    static void helloworld_exit(void)
    {
      printk(KERN_ALERT "hello world modul exit\n");
    }
    moudule_exit(helloworld_exit);


-----------------------------------------
也可以直接使用clean_module函数来写

    
    void cleanup_module()
    {
      printk(KERN_ALERT "hello world modul exit\n");
    }


========================================

**编译内核的Makefile有如下特殊的地方**：
1. 指定内核模块的编译文件和头文件的路径,因为头文件不是/usr/include/linux/下
而是/usr/src/kernels/2.6.32-358.el6.i686/include/linux/下的
2. 制定编译模块的名称
3. 给出当前模块的路径

========================================

Makefile文件：

    
    target = hello
    obj-m += $(target).o
    KERNELDIR = /lib/modules/`uname -r`/build
    main:
            make -C /$(KERNELDIR) M=`pwd` modules
    clean:
            make -C /lib/modules/`uname -r`/build M=`pwd` clean
    
    install:
            /sbin/insmod $(target).ko
    remove:
            /sbin/rmmod $(target)


================================================

obj-m制定编译模块的名称，在编译时候自动查找hello.c文件
,将其编译位hello.o,生成hello.ko.

当文件来自多个文件时,要用module-objs指定其文件名
例如内核模块由两个文件构成，file1.c与file2.c，则module-objs的规则如下：
modules-objs := file1.c file2.c

KERNELDIR指明了内核源代码树代码的路径，并且使用uname -r构建了此路径
uname提供用户系统的相关信息，-r选项打印出发布内核的信息

-C选项要求改变命令到之后所提供的KERNELDIR路径下，在那里发现内核顶层的Makefile
M=选项要求在建立内核模块前，回到指定的路径。一般使用pwd命令获得

install与remove来加载模块和卸载模块

在X-window下有可能看不到输出结果，可以使用dmesg命令与grep相结合的方式查看结果

================================================

netfilter的五个HOOK点的位置：

NF_IP_PRE_ROUTING：刚刚进入网络层的数据包通过此点(刚刚进行完版本号，校验
和等检测),目的地址转换在此点进行

NF_IP_LOCAL_IN：经路由查找后，送往本机的通过此检查点，INPUT包过滤在此点进行；

NF_IP_FORWARD：要转发的包通过此检测点，FORWARD包过滤在此点进行；

NF_IP_POST_ROUTING：所有马上便要通过网络设备出去的包通过此检测点，内置的源地址转换功能（包括地址伪装）在此点进行；

NF_IP_LOCAL_OUT：本机进程发出的包通过此检测点，OUTPUT包过滤在此点进行。

================================================

netfilter的钩子函数返回值:

NF_ACCEPT:继续传递，保持和原来传输的一致

NF_DROP:丢弃包，不再继续传递

NF_STOLEN:接管包，不再继续传递

NF_QUEUE:队列化包

NF_REPEAT:再调用一次钩子

================================================

    
    struct nf_hook_ops
    {
            struct list_head list;	/*钩子链表*/
            nf_hookfn *hook;	/*钩子处理函数*/
            struct module *owner;	/*模块所有者*/
            u_int8_t pf;		/*钩子的协议族*/
            unsigned int hooknum;	/*钩子的位置值*/
            int priority;		/*钩子的优先级，默认情况为继承优先级*/
    };


list:结构nf\_hook_ops构成一个链表，list是此链表的表头，将各个处理函数组成一张表,
初始值为{NULL, NULL};

hook:用户自定义的钩子函数，但是**它的返回值必须是**NF\_DROP、NF\_ACCEPT、NF\_STOLEN、NF\_QUEUE、NF\_REPEAT、NF_STOLEN之一

pf:协议族,表示这个HOOK属于哪个协议族,对IPV4来讲就是AF_INET

hooknum:用户想注册钩子的位置,取值为5个钩子NF_IP_PRE_ROUTING、NF_IP_LOCAL_IN、NF_IP_FORWARD、NF_IP_POST_ROUTING、NF_IP_LOCAL_OUT.一个挂节点可以挂接多个钩子函数，谁先被调用要看优先级

priority:优先级，取值越小优先接越高

================================================

注册的钩子函数的原型如下：

    
    typedef unsigned int nf_hookfn(unsigned int hooknum,
                                   struct sk_buff *skb,
                                   const struct net_device *in,
                                   const struct net_device *out,
                                   int (*okfn)(struct sk_buff *));


其中okfn函数是当回调函数为空时netfilter调用的处理函数

================================================

注册钩子函数:

    
    int nf_register_hook(struct nf_hook_ops *reg);


注销钩子函数

    
    void uf_unregister_hook(struct nf_hook_ops* reg);


当**成功注册时候返回为0，失败时候返回一个小于0的数**

================================================

注册回调函数时，要首先书写回调函数，将其挂接到nf_hook_ops链上，

如下：

    
    /*	回调函数		*/
    unsigned int hello_hook(unsigned int hooknum, 
    			struct sk_buff* skb;
    			const struct net_device* in,
    			const struct net_device *out,
                            int (*okfn)(struct sk_buff *))
    {
      printk(KERN_ALERT "hello world\n");
      return NF_ACCEPT;
    }
    
    /*	构建nf_hook_ops	*/
    struct nf_hook_ops hello_ops = {
      {NULL, NULL},hello_hook, AP_INET, NF_IP_POST_ROUTING, 0};
    
    /*	注册钩子函数	*/
    int init(void)
    {
      return nf_register_hook(&hello_ops);
    }
    modules_init(init);
    
    /*	注销钩子函数	*/
    void exit(void)
    {
      nf_unregister_hook(&hello_ops);
    }
    
    module_exit(exit);


================================================

netfilter还有一次性注册注销多个钩子的函数

    
    int nf_register_hooks(struct nf_hook_ops *reg, unsigned int n);
    void nf_unregister_hooks(struct nf_hook_ops *reg, unsigned int n);


其中参数reg输入的为一个数组，n为注册钩子的个数

================================================
