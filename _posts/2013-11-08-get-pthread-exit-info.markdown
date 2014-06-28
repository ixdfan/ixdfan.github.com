---
layout: post
title: 线程退出以及获取退出信息
categories:
- 线程
tags:
- 线程
---

线程终止
========================================================================

#### 线程退出的方式有3种：
1. 线程体函数执行结束，线程自行退出

2. 线程被另一个线程所取消，类似于一个进程被另一个进程使用kill函数杀死

3. 线程主动退出，类似于一个进程调用了exit

========================================================================

    
    void pthread_exit(void *retval);


pthread_exit函数的参数为一个指针，这个指针所指向的区域存储退出信息，该信息类似于传递给一个新线程的参数，如果有多个参数可以组织成一个结构体。

**一个线程的结束信息有两种：**
* 一种是线程函数返回所指向的区域，可以取得线程体函数的返回值；
* 一种是pthread\_exit函数所指向的区域，可得到pthread_exit函数所设置的退出信息；

一个线程结束运行后，其结束信息的地址被保存在内核中，其他的线程可以引用此线程的结束信息。
使用pthread_join函数访问指定线程的结束信息，

    
    int pthread_join(pthread_t thread, void **retval);


pthread\_join的第一个参数为要取得结束信息的线程id，如果线程尚在运行，那么pthread_join就会导致调用线程(主线程)阻塞,直到指定线程结束为止。

第二个参数为双指针，**pthread\_join从内核中的到指定线程的结束信息的地址，内核会设置线程结束信息，所以我们要指向地址而不是指向信息，因为刚开始pthread_join的时候还没有信息，所以我们要信息的地址;**
**如果多个线程等待同一个线程终止(pthread_join)，则所有等待线程将一直等到目标线程终止。然后，一个等待线程成功返回。其余的等待线程将失败并返回 ESRCH 错误。**

========================================================================

##### 注意：
**如果指定的线程ID与调用线程不属于同一个进程，那么pthread_join就会出错返回；**

**如果线程由于线程体函数返回或是调用pthread_exit函数退出，则retval就指向退出信息的首地址，**

** 如果线程由于被其他线程取消而退出，则retval就会被设置为PTHREAD_CANCELED；**

如果对返回信息并不关心，可以将retval设置为NULL，这样仅仅等待执行线程结束执行；

========================================================================

    
    void* tfn1(void* arg)
    {
            printf("the first\n");
            return (void*)1;
    }
    
    void* tfn2(void* arg)
    {
            printf("the second\n");
            pthread_exit((void*)3);
            printf("should not be here\n");
    }
    void* tfn3(void* arg)
    {
            printf("the third, sleep 5 seconds");
            sleep(5);
            return NULL;
    }
    
    int main(void)
    {
            pthread_t tid1, tid2, tid3;
            void* res = NULL;
            int err;
    
            err = pthread_create(&tid1, NULL, tfn1, NULL);
            if(0 != err){
                    printf("can't create thread %s\n", strerror(err));
                    exit(1);
            }
    
            err = pthread_join(tid1, &res);
            if(0 != err){
                    printf("can't join thread %s\n", strerror(err));
                    exit(1);
            }
    
            printf("result from thd1: %d\n", (unsigned)res);
    
            err = pthread_create(&tid2, NULL, tfn2, NULL);
            if(0 != err){
                    printf("can't create thread %s\n", strerror(err));
                    exit(1);
            }
    
            err = pthread_join(tid2, &res);
            if(0 != err){
                    printf("can't join thread %s\n", strerror(err));
                    exit(1);
            }
    
            printf("result from thd2: %d\n", (unsigned)res);
    
            err = pthread_create(&tid3, NULL, tfn3, NULL);
            if(0 != err){
                    printf("can't create thread %s\n", strerror(err));
                    exit(1);
            }
    
            err = pthread_join(tid3, &res);
            if(0 != err){
                    printf("can't join thread %s\n", strerror(err));
                    exit(1);


=================================================================================================

获取线程正确退出信息

在线程结束运行后，内核中保存的仅仅是退出信息存储区域的首地址，但是没有将退出信息保存到内核中，因此在线程退出运行后，保存的退出信息的内存区域仍然是有效的，所以**不能将退出信息存储在局部变量中，应该使用动态分配内存或是全局变量**

=================================================================================================

    
    struct a{
            int b;
            int c;
    }r3;
    void* tfn1(void* arg)
    {
            struct a r1;
            printf("the first one\n");
            r1.b = 10;
            r1.c = 11;
            return (&r1);//save local var;
    }
    
    void* tfn2(void* arg)
    {
            struct a* r2;
            printf("the second one\n");
            r2 = malloc(sizeof(struct a));
            printf("structure at %x\n", r2);
    
            r2->b = 10;
            r2->c = 11;
    
            return (void*)r2;
    }
    void* tfn3(void* arg)
    {
            printf("the third one\n");
            r3.b = 10;
            r3.c = 11;
    
            return (void*)(&r3);
    }
    void* tfn4(void* arg)
    {
            struct a* r4 = (struct a*)arg;
    
            printf("the fourth one\n");
    
            r4->b = 10;
            r4->c = 11;
    
            return (void*)(r4);
    }
    
    int main(void)
    {
            pthread_t tid1, tid2, tid3, tid4;
            void* res = NULL;
            int err;
    
            err = pthread_create(&tid1, NULL, tfn1, NULL);
            if(0 != err){
                    printf("can't create thread %s\n", strerror(err));
                    exit(1);
            }
    
            err = pthread_join(tid1, &res);
            if(0 != err){
                    printf("can't join thread %s\n", strerror(err));
                    exit(1);
            }
    
            printf("1st result :  %d, %d\n", ((struct a*)res)->b, ((struct a*)res)->c);
    
            err = pthread_create(&tid2, NULL, tfn2, NULL);
            if(0 != err){
                    printf("can't create thread %s\n", strerror(err));
                    exit(1);
            }
    
            err = pthread_join(tid2, &res);
            if(0 != err){
                    printf("can't join thread %s\n", strerror(err));
                    exit(1);
            }
    
            printf("2nd result :  %d, %d\n", ((struct a*)res)->b, ((struct a*)res)->c);
            free(res);
    
            err = pthread_create(&tid3, NULL, tfn3, NULL);
            if(0 != err){
                    printf("can't create thread %s\n", strerror(err));
                    exit(1);
            }
    
            err = pthread_join(tid3, &res);
            if(0 != err){
                    printf("can't join thread %s\n", strerror(err));
                    exit(1);
            }
    
            printf("3rd result : %d, %d\n", ((struct a*)res)->b, ((struct a*)res)->c);
    
    	struct a mem；
    	err = pthread_create(&tid4, NULL, tfn4, &mem);
            if(0 != err){
                    printf("can't create thread %s\n", strerror(err));
                    exit(1);
            }
    
            err = pthread_join(tid4, &res);
            if(0 != err){
                    printf("can't join thread %s\n", strerror(err));
                    exit(1);
            }
    	free(res);
            printf("4th result : %d, %d\n", ((struct a*)res)->b, ((struct a*)res)->c);
            return 0;
    }



    
    [root@localhost 02]# ./main
    the first one
    1st result :  -1216734352, 4001536
    the second one
    structure at b6c00468
    2nd result :  10, 11
    the third one
    3rd result : 10, 11
    the fourth one
    4th result : 10, 11


可以看到第一个线程的退出信息是一些垃圾值，因为该线程使用了局部变量存储退出信息，后面三个分别使用了动态内存，全局变量和main函数的局部变量来存储退出信息

##### 注意:
**如果主线程仅仅调用了 pthread_exit，则仅主线程本身终止,进程及进程内的其他线程将继续存在,所有线程都已终止时，进程也将终止。**

    
    void* tfn1(void* arg)
    {
            printf("this is first thread\n");
            sleep(10);
    }
    
    void* tfn2(void* arg)
    {
            printf("this is second thread\n");
            sleep(10);
    
    }
    
    int main()
    {
            pthread_t       first,
                            second;
    
            pthread_create(&first, NULL, tfn1, NULL);
            pthread_create(&second, NULL, tfn2, NULL);
    
            pthread_exit(NULL);
            printf("main pthread : %lu\n", pthread_self());
            pthread_join(first, NULL);
            pthread_join(second, NULL);
    
            return 0;
    }



    
    [root@localhost 07]# ./main
    this is second thread
    this is first thread


可以看到主线程中没有输出内容

=======================================================================================================
