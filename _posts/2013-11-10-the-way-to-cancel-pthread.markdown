---
author: UCSHELL
comments: true
date: 2013-11-10 06:03:38+00:00
layout: post
slug: '%e7%ba%bf%e7%a8%8b%e4%b8%89%e7%ba%bf%e7%a8%8b%e7%9a%84%e5%8f%96%e6%b6%88'
title: 线程的取消
wordpress_id: 932
categories:
- 线程
tags:
- 线程
---

取消线程的运行

    
    int pthread_cancel(pthread_t thread);


pthread_cnacel函数等效于要被取消的线程自己调用pthread_exit(PTHREAD_CANCELED);



实例：

    
    void* tfn1(void* arg)
    {
            printf("new thread\n");
            sleep(10);
    }
    int main()
    {
            pthread_t tid;
            void* res;
            int err;
    
            err = pthread_create(&tid, NULL, &tfn1, NULL);
            if(0 != err){
                    printf("can't create thread %s\n", strerror(err));
                    exit(1);
            }
            err = pthread_cancel(tid);
            if(0 != err){
                    printf("can't cancel thread %s\n", strerror(err));
                    exit(1);
            }
            err = pthread_join(tid, &res);
            if(0 != err){
                    printf("can't join thread %s\n", strerror(err));
                    exit(1);
            }
    
            if(PTHREAD_CANCELED == res)
                    printf("thread %u use has been canceled\n", (unsigned)tid);
            else
                    printf("err\n");
            return 0;
    }



 

线程退出函数

如同进程一样，一个线程在退出时也可以调用用户设置好的函数，这些函数称为线程清理函数，记录在栈中。

使用pthread_cleanup_push函数添加一个清理程序记录；

使用pthread_clearup_pop函数调用清理程序。

    
    void pthread_cleanup_push(void (*routine)(void *), void *arg);
    void pthread_cleanup_pop(int execute);


pthread_cleanup_push的第一个参数是指向清理程序，清理程序是一个没有返回值的函数，参数为一个指针，第二个参数实际就是清理函数的参数；

##### 注意：

清理函数的执行顺序和设置顺序刚好相反；

**pthread_cleanup_push与pthread_cleanup_pop是一个宏，必须配对使用**

	pthread_cleanup_push(handle, 0)；

表示当有pthread_exit或pthread_cancel时候便会触发这个函数，使其调用handle函数，当使用return正常退出线程时候不会触发handle函数
pthread_cleanup_pop的参数表示是否执行栈顶的清理函数，参数为0时，表示不执行清理程序，但是将栈顶的清理程序记录出栈(删除)；参数非0时，表示执行栈顶函数，执行后函数也会出栈；


pthread_cleanup_push函数会在一下三种情况下执行:
**(1).调用pthread_exit时；使用return不会调用**
**(2).线程被其他线程取消pthread_cancel；**
**(3).使用非零参数调用pthread_cleanup_pop函数时；**


    
    void cleanup(void* arg)
    {
            printf("No.%d clean-up procdure\n", *((int*)arg));
    }
    /*return正常退出线程，没有调用cleanup函数*/
    void* tfn1(void* arg)
    {
            int b = 1;
            printf("the first thread\n");
            pthread_cleanup_push(cleanup, &b);
    
            int a = 2;
            pthread_cleanup_push(cleanup, &a);
            return NULL;
            pthread_cleanup_pop(0);
            pthread_cleanup_pop(0);
    
    }
    /*pthread_exit退出线程*/
    void* tfn2(void* arg)
    {
            int a = 1;
    
            printf("the second thread\n");
            pthread_cleanup_push(cleanup, &a);
    
            a = 2;
            pthread_cleanup_push(cleanup, &a);
    
            pthread_exit(NULL);
            pthread_cleanup_pop(0);
            pthread_cleanup_pop(0);
    
            return NULL;
    }
    /*pthread_cleanup_pop函数调用cleanup函数*/
    void* tfn3(void* arg)
    {
            int a = 1;
            printf("the third thread\n");
            pthread_cleanup_push(cleanup, &a);
    
            int b = 2;
    
            pthread_cleanup_push(cleanup, &b);
            pthread_cleanup_pop(1);
    
            printf("ready to sleep\n");
            sleep(10);
    
            pthread_cleanup_pop(0);
    
            return NULL;
    }
    
    int main(void)
    {
            pthread_t tid1, tid2, tid3, tid4;
            int err;
    
            err = pthread_create(&tid1, NULL, tfn1, NULL);
            if(0 != err){
                    perror("can't create thread1");
                    exit(1);
            }
    
            err = pthread_join(tid1, NULL);
            if(0 != err){
                    perror("can't join thread1");
                    exit(1);
            }
    
            err = pthread_create(&tid2, NULL, tfn2, NULL);
            if(0 != err){
                    perror("can't create thread2");
                    exit(1);
            }
    
            err = pthread_join(tid2, NULL);
            if(0 != err){
                    perror("can't join thread2");
                    exit(1);
            }
    
            err = pthread_create(&tid3, NULL, tfn3, NULL);
            if(0 != err){
                    perror("can't create thread3");
                    exit(1);
            }
    
            sleep(1);
            err = pthread_cancel(tid3);
            if(0 != err){
                    perror("can't cancel thread3");
                    exit(1);
            }
    
            err = pthread_join(tid3, NULL);
            if(0 != err){
                    perror("can't join thread3");
                    exit(1);
            }
    
            return 0;
    }


可以看到只有return和pthread_cleanup_pop(0)没有调用clean函数


编程实例：

    
    pthread_mutex_t mutex;
    
    void* runadd(void* d)
    {
            int i = 0;
            while(1){
                    pthread_mutex_lock(&mutex);
                    if(i > 100){
                            pthread_exit(NULL);
                    }
                    printf("ID: %d %d\n", 1, i += 2);
                    pthread_mutex_unlock(&mutex);
            }
    }
    void* runeven(void* d)
    {
            int i = 0;
            while(1){
                    pthread_mutex_lock(&mutex);
    //              if(i > 100){
    //                      pthread_exit(NULL);
    //              }
                    printf("ID: %d %d\n", 2, i++);
                    pthread_mutex_unlock(&mutex);
            }
    }
    int main()
    {
            pthread_t tadd, teven;
            pthread_mutex_init(&mutex, 0);
            pthread_create(&tadd, NULL, runadd, NULL);
            pthread_create(&teven, NULL, runeven, NULL);
    
            pthread_join(tadd, NULL);
            pthread_join(teven, NULL);
            pthread_mutex_destroy(&mutex);
    
            return 0;
    }


为什么要加上pthread_mutex_lock系列函数呢？

因为如果不加，很有可能会出现类似与113的输出；

比如线程1使用printf刚打印了1，此时线程突然切换到线程2，而线程2也刚好要printf，接着刚刚的打印出13,所以打印出了113 2的情况，所以要加锁！

在runadd线程中当i > 100的时候执行pthread_exit退出线程，而此时mutex是已经加过锁的，此时为0，当线程runeven想要加锁时候发现mutex没有被解锁，所以他无法执行，所以也就不能再输出了，可以看到在线程输出102时候，线程变全部阻塞了！所以我们应该将pthread_exit放到pthread_mutex_unlock之后，这样才不会造成死锁

使用return正常退出线程是不会触发handle函数的，可以自己修改一下验证

 

    
    int pthread_kill(pthread_t thread, int sig);


pthread_kill用于向线程发送信号，thread所指定的线程必须与调用线程在同一个进程中；
**如果 sig 为零，将执行错误检查，但并不实际发送信号。此错误检查可用来检查 tid 的有效性。**

    
    int pthread_sigmask(int how, const sigset_t *set, sigset_t *oldset);


pthread_sigmask更改或检查调用线程的信号掩码。

how 可以为以下值之一：
* SIG_BLOCK。向当前的信号掩码中添加 new，其中 new 表示要阻塞的信号组。
* SIG_UNBLOCK。从当前的信号掩码中删除 new，其中 new 表示要取消阻塞的信号组。
* SIG_SETMASK。将当前的信号掩码替换为 new，其中 new 表示新的信号掩码。

当 set 的值为 NULL 时，how 的值没有意义，线程的信号掩码不发生变化。

要查询当前已阻塞的信号，请将 NULL 值赋给 set 参数。

除非 old 变量为 NULL，否则 old 指向用来存储以前的信号掩码的空间。


