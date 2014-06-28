---
layout: post
title: 关于memset的详细用法
categories:
- C\C++
tags:
- memset
---

今天在写程序时候无意间发现自己对memset使用错误， 经过查找才知道原来自 己对于memset的理解一直就是错误的

==========================================================

功能： 
	void *memset(void *s, int ch, unsigned n); 

将s所指向的某一块内存中的每个字节的内容全部设置为ch指定的ASCII值, 块的大小由第三个参数指定,这个函数通常为新申请的内存做初始化工作,其返回值为指向S的指针。




==========================================================

    #include <string.h>
    #include <stdio.h>
    #include <memory.h>

    int main( void)
    { 　　
        char buffer[] = "Hello world\n"; 　
        printf ("Buffer before memset: %s\n", buffer);
        memset (buffer, '*',strlen(buffer) ); 
        printf ("Buffer after memset: %s\n", buffer);
        
        return 0;
    }

输出结果：  
Buffer before memset: Hello world  
Buffer after memset: \*\*\*\*\*\*\*\*\*\*\*

===========================================================

编译平台： 　　Microsoft Visual C++ 6.0

也不一定就是把内容全部设置为ch指定的ASCII值，而且该处的ch可为int 或者其他类型，并不一定要是char类型。例如下面这样：


	int array[5] = {1,4,3,5,2}; 
    for (int i = 0; i < 5; i++) 
        cout<<array[i]<<   " "   ; 
    cout<<endl; 
    
    memset(array, 0, 5*sizeof   (   int   )); 
    
    for(int k = 0; k < 5; k++) 
   		cout<<array[k]<<   " "   ; 
    cout<<endl; 

输出的结果就是：   
1 4 3 5 2   
0 0 0 0 0   
后面的表大小的参数是以字节为单位，所以，对于int或其他的就并不是都乘默认的1（字符型）了。而且不同的机器上int的大小也可能不同，所以最好用sizeof（）。


要注意的是，*memset是对字节进行操作，所以上述程序如果改为*

    int array[5] = {1,4,3,5,2};
    for ( int i = 0; i < 5; i++)
        cout<<array[i]<< " " ;
    cout<<endl;
    
    memset (array,1,5* sizeof ( int )); // 注意 这里与上面的程序不同
    for ( int k = 0; k < 5; k++)
   		cout<<array[k]<< " " ;
    cout<<endl;


输出的结果就是：   
　　1 4 3 5 2   
　　16843009 16843009 16843009 16843009 16843009   
　　为什么呢？   
　　因为memset是以字节为单位就是对array指向的内存的5个字节进行赋值，每个都用ASCII为1的字符去填充，转为二进制后，1就是00000001,占一个字节。一个INT元素是4字节，合一起就是00000001000000010000000100000001，就等于16843009，就完成了对一个INT元素的赋值了。




**所以用memset对非字符型数组赋初值是不可取的！ **

　　例如有一个结构体Some x，可以这样清零：   
　　memset( &x, 0, sizeof(Some) );   
　　如果是一个结构体的数组Some x[10]，可以这样：   
　　memset( x, 0, sizeof(Some)*10 );

\>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

1.void *memset(void *s,int c,size_t n)   
总的作用：将已开辟内存空间 s 的首 n 个字节的值设为值 c。

\>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  
2.例子   
    main(){   
    char *s="Golden Global View";   
    clrscr();   
    memset(s,'G',6);//貌似这里有点问题//   
    printf("%s",s);   
    getchar();   
    return 0;   
    }　   
【应该是没有问题的，字符串指针一样可以，并不是只读内存，可以正常运行】

\>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
3.memset() 函数常用于内存空间初始化。如：   

    char str[100];   
    memset(str,0,100);
\>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
4.memset()的深刻内涵：
用来对一段内存空间全部设置为某个字符，一般用在对定义的字符串进行初始化为'memset(a, '\0', sizeof(a));  
　　memcpy用来做内存拷贝，你可以拿它拷贝任何数据类型的对象，可以指定拷贝的数据长度；例：   
	
    char a[100], b[50];   
	memcpy(b, a, sizeof(b)); //注意如用sizeof(a)，会造成b的内存地址溢出。

\>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>   
　　strcpy就只能拷贝字符串了，它遇到'\0'就结束拷贝；例：   
  
    char a[100], b[50];   
    strcpy(a,b);   

如用strcpy(b,a)，要注意a中的字符串长度（第一个'\0'之前）是否超过50位，如超过，则会造成b的内存地址溢出。

\>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>   

5.补充：某人的一点心得   
memset可以方便的清空一个结构类型的变量或数组。   
如：  

	struct sample_struct   
    {   
    char csName[16];   
    int iSeq;   
    int iType;   
    };   

对于变量   

	struct sample_strcut stTest;   
一般情况下，清空stTest的方法：   

    stTest.csName[0]='\0';   
    stTest.iSeq=0;   
    stTest.iType=0;   
    
用memset就非常方便：   

	memset(&stTest,0,sizeof(struct sample_struct));   
如果是数组：   

	struct sample_struct TEST[10];   
则   

	memset(TEST,0,sizeof(struct sample_struct)*10);

\>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	
    
