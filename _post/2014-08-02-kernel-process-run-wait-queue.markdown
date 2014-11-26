---
layout: post
title: 运行队列与等待队列
description:  
modified: 
categories: 
- KERNEL
tags:
- 
---


调度程序操作的对象是一个叫做运行队列的结构，系统中每个CPU都有一个运行队列，运行队列中的核心数据结构是两个按照优先级排序的数组，其中一个包含了活跃进程，另一个包含了到期进程。通常一个活跃进程运行固定一段时间(时间片长度或称时间片)，然后被插入到期数组取等待更多CPU时间。

*当活跃数组为空时，调度程序通过交换活跃数组和到期数组的指针来交换两个数组，然后调度程序开始执行新活跃数组中的进程*

运行队列由两个数组组成
- 活跃进程数组
- 到期进程数组

运行队列中的优先数组定义如下:

    192 struct prio_array {
	193     unsigned int nr_active;/*计数器，记录优先数组中的进程个数*/
	194     unsigned long bitmap[BITMAP_SIZE];/*记录数组中的优先级*/
    195     struct list_head queue[MAX_PRIO];/*存储进程链表的数组*/
    196 };

bitmap的实际长度取决于系统中无符号长整形的大小，它始终足够存放MAX_PRIO个位，也可能会更长

queue每个链表存放特定优先级的进程，因此queue[0]就是存放所有优先级位0的进程的链表，queue[1]就是存放所有优先级位1的进程的链表

![003]({{site.img_url}}/2014/08/003.png)


-------------------------------------------------------------------------------

#### 从等待中醒来或者激活

当一个进程调用fork时候就创建了新的进程，新创建的进程需要被调度才能访问CPU，这是通过do_fork来完成的


在do_fork中调用函数copy_process，copy_process函数又调用sched_fork,以便将进程初始化为即将插入运行队列的状态

*sched_fork函数用于调度程序初始化新创建的进程*

    872 void fastcall sched_fork(task_t *p)
    873 {
    874     /*
    875      * We mark the process as running here, but have not actually
    876      * inserted it onto the runqueue yet. This guarantees that
    877      * nobody will actually run it, and a signal or other external
    878      * event cannot wake it up and insert it on the runqueue either.
    879      */
	880     p->state = TASK_RUNNING;/* 标记为运行状态 */

在do_fork和copy_process对进程是否正确被创建进行检验之前，向将其标记为运行状态，以确保没有其他事件能把该进程插入运行队列并运行它。当验证通过后，do_fork会调用wake_up_forked_process把新进程真正添加到运行队列中取


	881     INIT_LIST_HEAD(&p->run_list);/* 初始化进程的run_list字段 */
    882     p->array = NULL;
    883     spin_lock_init(&p->switch_lock);

当新进程被激活时候，它的run_list字段被链接到运行队列中某个优先级数组的队列结构中，把进程的array域设置位NULL，表示进程不再运行队列的任何一个优先级数组中



    884 #ifdef CONFIG_PREEMPT
    885     /*
    886      * During context-switch we hold precisely one spinlock, which
    887      * schedule_tail drops. (in the common case it's this_rq()->lock,
    888      * but it also can be p->switch_lock.) So we compensate with a count
    889      * of 1. Also, we want to start with kernel preemption disabled.
    890      */
    891     p->thread_info->preempt_count = 1;
    892 #endif
    893     /*
    894      * Share the timeslice between parent and child, thus the
    895      * total amount of pending timeslices in the system doesn't change,
    896      * resulting in more scheduling fairness.
    897      */
	898     local_irq_disable(); /* 禁用本地中断 */
    899     p->time_slice = (current->time_slice + 1) >> 1;/*使用移位方法给子进程划分父进程的一部分时间片，*/
	900     /*
    901      * The remainder of the first timeslice might be recovered by
    902      * the parent if the child exits early enough.
    903      */
    904     p->first_time_slice = 1;     /*新进程的第一个时间片被设置位1,因为此时它还没有被运行，*/
    905     current->time_slice >>= 1;   /*父进程时间片减少一半，因为上面已经给子进程了一个*/
    906     p->timestamp = sched_clock();/*其时间戳被初始化成以纳秒位单位的当前时间*/
		    
		    /* 如果父进程时间片是1,那么划分之后父进程就没有剩余的时间运行，
			*  而父进程是调度程序的当前进程，因此需要找一个新的进程来运行
			*/
	907     if (!current->time_slice) {
		    
    908         /*
    909          * This case is rare, it happens when the parent has only
    910          * a single jiffy left from its timeslice. Taking the
    911          * runqueue lock is not a problem.
    912          */
    913         current->time_slice = 1;

为了确保调度其程序不受干扰的选择一个新进程，应该禁止内核被抢占，调度操作完成后，则启用抢占并恢复本地中断

    914         preempt_disable();
	915         scheduler_tick(0, 0);/* 使得调用程序找到新的进程 */
    916         local_irq_enable();  /* 恢复本地中断 */
    917         preempt_enable();
    918     } else
    919         local_irq_enable();
    920 }
   

此处，新创建进程初始化与调度程序相关的变量(例如时间片),并让初始时间片位父进程剩余时间片的一半，内核强迫进程交出一部分CPU时间，将其分配给子进程，防止进程占有大块的处理器时间，如果一个进程被给予了一个固定不变的时间片，恶意进程可能会生出许多子进程，从而快速贪婪的占据CPU。

进程成功初始化并且初始化验证成功之后，do_fork会调用wake_up_forked_process();

    928 void fastcall wake_up_forked_process(task_t * p)
    929 {
    930     unsigned long flags;
		    /* 锁住运行队列的结构，对运行队列的任何操作必须在上锁的情况下进行 */
    931     runqueue_t *rq = task_rq_lock(current, &flags);
	932     /*
		    * 之前的sched_fork函数已经将进程的状态设置位TASK_RUNNING，
		    * 如果不是这个状态则报错,抛出一个bug通知
		    */
    933     BUG_ON(p->state != TASK_RUNNING);
    934

下面调度程序计算父进程和子进程的睡眠平均值，睡眠平均值就是每个进程睡眠所花时间和进程运行所花时间的比值，它随着进程睡眠时间增加而增加，随着进程运行时每个定时器的节拍而减少。

交互式进程或是IO密集型进程在等待输入上花费大部分时间，他们的睡眠平均值通常很高。

非交互式进程或是CPU密集型进程在使用CPU上花费大部分时间，这些进程的睡眠平均值比较低

因为用户想要看到他们的输入结果，例如敲击键盘或是移动鼠标，因此交互式进程被赋予了非交互式进程更多的调度优势。具体而言当交互式时间片到期以后，调度程序把它重新插入到活跃的优先级数组中，为了防止交互进程创建一个非交互子进程，从而占有一个不相称的CPU份额，这些公式用来降低父进程和子进程的睡眠平均值。如果新创建进程是交互的，它立刻去睡眠足够长的时间，重新获得本已经失去的所有调度优势。

	935     /*
    936      * We decrease the sleep average of forking parents
    937      * and children as well, to keep max-interactive tasks
    938      * from forking tasks that are max-interactive.
    939      */
    940     current->sleep_avg = JIFFIES_TO_NS(CURRENT_BONUS(current) *
    941         PARENT_PENALTY / 100 * MAX_SLEEP_AVG / MAX_BONUS);
    942 
    943     p->sleep_avg = JIFFIES_TO_NS(CURRENT_BONUS(p) *
    944         CHILD_PENALTY / 100 * MAX_SLEEP_AVG / MAX_BONUS);
    945 
    946     p->interactive_credit = 0;
    947

effective_prio修改进程的静态优先级，它返回一个100-139(MAX_RT_PRIO到MAX_PRIO-1)的优先级。基于进程以前使用CPU的情况以及用于睡眠的时间，进程的静态优先级卡一增加或减少一个不大于5的数值，但是总是保持在刚刚的范围内，就是我们使用命令行中的nice的值，它可以在-20~19之间变化(最高优先级到最低优先级)，nice优先级0对应静态优先级的120

	948     p->prio = effective_prio(p);
		    /* 将进程的CPU属性设置成当前CPU */
    949     set_task_cpu(p, smp_processor_id());
    950

array指向运行队列中的优先级数组，如果当前进程没有指向一个优先级数组，那就意味着当前进程已经完成或者正在睡眠。如果是这样的话，当前进程的runlist字段就不在运行队列的优先级数组的队列中，所以list_add_tail就会失败

    951     if (unlikely(!current->array))
		        /*__activeate_task的作用是将子进程直接加入运行队列中，不用取管父进程 */
    952         __activate_task(p, rq);/* 当前进程如果处于已经完成或者睡眠，那么就将新进程直接添加到运行队列中，并且不需要涉及它的父进程 */
    953     else {
		        /* 如果父进程在运行，那么子进程复制父进程的调度信息 */
    954         p->prio = current->prio;
    955         list_add_tail(&p->run_list, &current->run_list);
    956         p->array = current->array;
    957         p->array->nr_active++;
    958         rq->nr_running++;
    959     }
		    /* 解锁 */
    960     task_rq_unlock(rq, &flags);
    961 }

通常情况下，当前进程正在运行队列中等待CPU时间时，新进程被添加到优先级数组位p->prio的队列，添加了新进程的数组其进程计数器nr_active要加1,运行队列也要让他的进程计数器nr_running加1,也就是说某优先级数组中多了一个进程，运行队列中也多了一个进程，所以都要加1,最后将队列解锁


    366 static inline void __activate_task(task_t *p, runqueue_t *rq)
    367 {
    368     enqueue_task(p, rq->active);
    369     rq->nr_running++;
    370 }
_activate_task()将给定进程p放到运行队列rq中的活跃优先级数组中，并且把运行队列的nr_running加1,nr_running是表示运行队列上进程总数的计数器

enqueue_task的作用是将进程p放入到优先级数组array中

	311 static void enqueue_task(struct task_struct *p, prio_array_t *array)
	312 {
		    /*进程的run_list被添加到优先级为p->prio数组的队尾*/
    313     list_add_tail(&p->run_list, array->queue + p->prio);
		    /*设置优先级为p->prio的优先级数组位图，当调度程序运行时，就能看到有一个进程正在以优先级p->prio运行*/
    314     __set_bit(p->prio, array->bitmap);
		    /*增加优先级数组array的进程计数器，表示该数组中又增加了一个新进程*/
	315     array->nr_active++;
		    /*设置进程的数组指针p->array指向数组array */
    316     p->array = array;
    317 }


简单的来说，添加一个新进程的操作如下:
进程被放置在运行队列优先级数组中的某个prio链表末尾，这个prio链表由进程的优先级来决定，然后进程在他的数据结构中记录优先级数组的位置以及它所在链表的位置。
   
    70 /**
    71  * list_add_tail - add a new entry
    72  * @new: new entry to be added
	73  * @head: list head to add it before
    74  *
    75  * Insert a new entry before the specified head.
    76  * This is useful for implementing queues.
    77  */
		/* sturct list_head结构指向等待队列中第一个和最后一个进程
		*/
    78 static inline void list_add_tail(struct list_head *new, struct list_head *head)
    79 {
    80     __list_add(new, head->prev, head);
    81 }
   


-------------------------------------------------------------------------------

#### 等待队列

当进程等待一个外部事件发生时()，就把它从运行队列删除并放到等待队列上，将自己设置为TASK_INTERRUPTIBLE或是TASK_UNINTERRUPTIBLE,等待队列是一个wait_queue_t结构的双向链表。设置wait_queue_t结构是为了保存等待进程所需要的所有信息。等待一个特定外部事件的所有进程被放置到同一个等待队列中，当某个等待队列上的进程被唤醒时，该进程检查他所等待的条件，如果是它所需要的条件，那么就从等待队列中删除自己并将自己设置为TASK_RUNNING。如果不是他所需要的条件，就继续睡眠。

当父进程想要获知他所创建的子进程的状态时候，sys_wait4()系统调用使用等待队列。

##### 注意:
等待外部事件的进程，不再处于运行队列中，进程睡眠以后，他就被从运行队列中删除，从而位另外一个进程让出CPU控制权，它此时可能处于TASK_INTERRUPTIBLE或是TASK_UNINTERRUPTIBLE状态。


等待队列是wait_queue_t结构的双向链表，wait_queue_t结构中有指向阻塞进程task结构的指针，每个链表以wait_queue_head_t结构开头，该结构标记链表的头部，并存放wait_queue_t链表的自选锁，自选锁卡一防止wait_queue_t的额外竞争条件。

![004]({{site.img_url}}/2014/08/004.png)

    19 typedef struct __wait_queue wait_queue_t;
	
	21 int default_wake_function(wait_queue_t *wait, unsigned mode, int sync, void *key);
	
    23 struct __wait_queue {
		   /*
		   * 可以存放值WQ_FLAG_EXCLUSIVE(0X01)或是～WQ_FLAG_EXCLUSIVE(0)，
		   * WQ_FLAG_EXCLUSIVE标志这个进程为独占式进程
		   */
    24     unsigned int flags;
    25 #define WQ_FLAG_EXCLUSIVE   0x01
		   /*指向被加入到等待队列上的进程的进程描述符*/
    26     struct task_struct * task;
		   /*存放函数的结构，该函数用于唤醒等待队列上的进程，默认是default_wake_function*/
    27     wait_queue_func_t func;
		   /*该结构包含两个指针，分别指向等待队列中的前一个进程和后一个进程*/
    28     struct list_head task_list;
    29 };


    28 struct list_head {
    29     struct list_head *next, *prev;
    30 };


	20 typedef int (*wait_queue_func_t)(wait_queue_t *wait, unsigned mode, int sync, void *key);
wait是指向等待队列的指针，mode可以是TASK_INTERRUPTIBLE或者是TASK_UNINTERRUPTIBLE，sync表示唤醒是否应该被同步


__wait_queue_head结构是等待队列链表的表头
    30 
    31 struct __wait_queue_head {
		   /*每个链表有一个锁，使得向等待队列添加或删除数据时候能够同步*/
    32     spinlock_t lock;
		   /*这个结构指向等待队列中第一个和最后一个进程*/
    33     struct list_head task_list;
    34 };
    35 typedef struct __wait_queue_head wait_queue_head_t;
    36 


#### 进程的睡眠
进程让自己睡眠涉及到对模个wait_event*宏的调用或是通过以下步骤完成:
- 通过声明等待队列，进程利用DECLARE_WAITQUEUE_HEAD继续睡眠
- 利用add_wait_queue或add_wait_queue_exclusive将自己加入等待队列
- 将进程状态变为TASK_INTERRUPTIBLE或是TASK_UNINTERRUPTIBLE
- 检测外部事件，如果外部事件还没有发生，则调用schedule(),将当前进程从CPU上换下
- 外部事件发生后，把进程设置位TASK_RUNNING状态。
- 通过调用remove_wait_queue从等待队列中删除自己


#### 添加到等待队列

有两个函数卡一向等待队列中添加睡眠进程
- add_wait_queue()
- add_wait_queue_exclusive()

他们分别对应两种类型的睡眠进程
- 非独占式等待进程:所等待的条件返回时不被其他进程所共享
- 独占式等待进程:等待一个其他进程可能正在等待的条件，这就可能产生一个竞态条件。

add_wait_queue向等待队列插入一个非独占式进程，非独占式进程是指在任何条件下，当等待的事件完成时就被内核唤醒的进程，这个函数设置等待队列结构中的flags字段，表示将睡眠进程的标志设置为!WQ_FLAG_EXCLUSIV(值0)，同时设置等待队列锁，以避免终端访问同一个队列而产生竞态条件，之后将wait_queue_t结构加入等待队列链表，并从等待队列中恢复锁，使得其他进程卡一使用。

     98 void fastcall add_wait_queue(wait_queue_head_t *q, wait_queue_t * wait)
     99 {
    100     unsigned long flags;
    101 
    102     wait->flags &= ~WQ_FLAG_EXCLUSIVE;
    103     spin_lock_irqsave(&q->lock, flags);
    104     __add_wait_queue(q, wait);
    105     spin_unlock_irqrestore(&q->lock, flags);
    106 }


add_wait_queue_exclusive()函数向等待队列插入一个独占式进程，他把等待队列结构的flags字段相应位设置为1,并且与add_wait_queue()大致相同的独占方式进程操作


	110 void fastcall add_wait_queue_exclusive(wait_queue_head_t *q, wait_queue_t * wait)
    111 {
    112     unsigned long flags;
    113 
    114     wait->flags |= WQ_FLAG_EXCLUSIVE;
    115     spin_lock_irqsave(&q->lock, flags);
    116     __add_wait_queue_tail(q, wait);
    117     spin_unlock_irqrestore(&q->lock, flags);
    118 }


有一个例外，add_wait_queue_exclusive将独占进程添加到队列的末尾，这意味着在一个特定的等待队列里，非独占式进程在前面，独占式进程在后面，这个次序也就是等待队列中的进程被唤醒的次序

    87 static inline void __add_wait_queue(wait_queue_head_t *head, wait_queue_t *new)
    88 {
    89     list_add(&new->task_list, &head->task_list);
    90 }

	65 static inline void list_add(struct list_head *new, struct list_head *head)
    66 {
		  /*head->pre指向链表队尾，head->next指向链表首元素*/
    67     __list_add(new, head, head->next);
    68 }

	47 static inline void __list_add(struct list_head *new,
    48                   struct list_head *prev,
    49                   struct list_head *next)
    50 {
    51     next->prev = new;
    52     new->next = next;
    53     new->prev = prev;
    54     prev->next = new;
    55 }   


	95 static inline void __add_wait_queue_tail(wait_queue_head_t *head,
	96                         wait_queue_t *new)
	97 {
	98     list_add_tail(&new->task_list, &head->task_list);
	99 }

    78 static inline void list_add_tail(struct list_head *new, struct list_head *head)
    79 {
		  /*将new插入到head->prev之后，head之前，也就是链表末尾*/
    80     __list_add(new, head->prev, head);
    81 }
   

可以看到在一个特定的等待队列里，非独占式进程在前面，独占式进程在后面


#### 等待事件

进程的睡眠涉及到wait_event*宏的调用，wait_event*接口包括:
- wait_event()
- wait_event_interruptible()
- wait_event_interruptible_timeout()


![005]({{site.img_url}}/2014/08/005.png)

wait_event是对__wait_event()的包装，只有当满足条件的时候,才会退出循环
    137 #define wait_event(wq, condition)                   \
    138 do {                                    \
    139     if (condition)                          \
    140         break;                          \
    141     __wait_event(wq, condition);                    \
    142 } while (0)

    121 #define __wait_event(wq, condition)                     \
    122 do {                                    \
		    /*建立并初始化一个等待队列*/
    123     wait_queue_t __wait;                        \
    124     init_waitqueue_entry(&__wait, current);             \
    125                                     \
		    /*将wq加入到等待队列中*/
	126     add_wait_queue(&wq, &__wait);                   \
		    /*死循环，只有当condtion成立之后才会退出*/
	127     for (;;) {                          \
		        /*在阻塞前设置当前进程的状态位TASK_UNINTERRUPTIBLE*/
    128         set_current_state(TASK_UNINTERRUPTIBLE);        \
		        /*条件满足后才能跳出循环*/
    129         if (condition)                      \
    130             break;                      \
		        /*执行到这里说明调价没有满足，则利用schedule()将CPU让给其他进程*/
    131         schedule();                     \
    132     }                               \
		    /*如果条件满足了设置状态位TASK_RUNNING并从等待队列中删除*/
	133     current->state = TASK_RUNNING;                  \
    134     remove_wait_queue(&wq, &__wait);                \
    135 } while (0)
    136

remove_wait_queue会在删除描述符前为等待队列枷锁，在返回之前再为其解锁

	120 #define set_current_state(state_value)      \
	121     set_mb(current->state, (state_value))
	将当前进程的状态设置位state_value


wait_event_interruptible是这三个接口中唯一具有返回值的接口，如果一个信号中断了等待时间，这个返回值就是ERESTARTSYS,否则，如果条件处理就返回0
    165 #define wait_event_interruptible(wq, condition)             \
    166 ({                                  \
    167     int __ret = 0;                          \
    168     if (!(condition))                       \
    169         __wait_event_interruptible(wq, condition, __ret);   \
    170     __ret;                              \
    171 })
    172 

    143 
    144 #define __wait_event_interruptible(wq, condition, ret)          \
    145 do {                                    \
    146     wait_queue_t __wait;                        \
    147     init_waitqueue_entry(&__wait, current);             \
    148                                     \
    149     add_wait_queue(&wq, &__wait);                   \
    150     for (;;) {                          \
		        /*设置状态位TASK_INTERRUPTIBLE*/
    151         SET_CURRENT_STATE(TASK_INTERRUPTIBLE);          \
    152         if (condition)                      \
    153             break;                      \
		        /*signal_pending用于等待发送给当前进程的信号*/
    154         if (!signal_pending(current)) {             \
    155             schedule();                 \
    156             continue;                   \
    157         }                           \
    158         ret = -ERESTARTSYS;                 \
    159         break;                          \
    160     }                               \
		    /*收到信号或是满足条件*/
    161     current->state = TASK_RUNNING;                  \
    162     remove_wait_queue(&wq, &__wait);                \
    163 } while (0)
    164 

		/*timeout是int类型的值，传递的是超时时间*/
	196 #define wait_event_interruptible_timeout(wq, condition, timeout)    \
    197 ({                                  \
    198     long __ret = timeout;                       \
    199     if (!(condition))                       \
    200         __wait_event_interruptible_timeout(wq, condition, __ret); \
    201     __ret;                              \ 
    202 })

	/*ret是超时时长*/
	173 #define __wait_event_interruptible_timeout(wq, condition, ret)      \
    174 do {                                    \
    175     wait_queue_t __wait;                        \
    176     init_waitqueue_entry(&__wait, current);             \
    177                                     \
    178     add_wait_queue(&wq, &__wait);                   \
    179     for (;;) {                          \
    180         set_current_state(TASK_INTERRUPTIBLE);          \
    181         if (condition)                      \
    182             break;                      \
    183         if (!signal_pending(current)) {             \
		            /*调用的是schedule_timeout*/
    184             ret = schedule_timeout(ret);            \
	                /*超时*/
    185             if (!ret)                   \
    186                 break;                  \
    187             continue;                   \
    188         }                           \
		        /*收到信号*/
    189         ret = -ERESTARTSYS;                 \
    190         break;                          \
    191     }                               \
		    /*超时或是收到信号*/
    192     current->state = TASK_RUNNING;                  \
    193     remove_wait_queue(&wq, &__wait);                \
    194 } while (0) 
    195                             

#### 进程的唤醒

进程必须被唤醒以检查它等待的条件是否成立，进程可以自己睡眠，但是不能自己唤醒自己！

    107 void FASTCALL(__wake_up(wait_queue_head_t *q, unsigned int mode, int nr, void *key));
    108 extern void FASTCALL(__wake_up_locked(wait_queue_head_t *q, unsigned int mode));
    109 extern void FASTCALL(__wake_up_sync(wait_queue_head_t *q, unsigned int mode, int nr));
    111 #define wake_up(x)          __wake_up(x, TASK_UNINTERRUPTIBLE | TASK_INTERRUPTIBLE, 1, NULL)
    112 #define wake_up_nr(x, nr)       __wake_up(x, TASK_UNINTERRUPTIBLE | TASK_INTERRUPTIBLE, nr, NULL)
    113 #define wake_up_all(x)          __wake_up(x, TASK_UNINTERRUPTIBLE | TASK_INTERRUPTIBLE, 0, NULL)
    114 #define wake_up_all_sync(x)         __wake_up_sync((x),TASK_UNINTERRUPTIBLE | TASK_INTERRUPTIBLE, 0)
    115 #define wake_up_interruptible(x)    __wake_up(x, TASK_INTERRUPTIBLE, 1, NULL)
    116 #define wake_up_interruptible_nr(x, nr) __wake_up(x, TASK_INTERRUPTIBLE, nr, NULL)
    117 #define wake_up_interruptible_all(x)    __wake_up(x, TASK_INTERRUPTIBLE, 0, NULL)
    118 #define wake_up_locked(x)       __wake_up_locked((x), TASK_UNINTERRUPTIBLE | TASK_INTERRUPTIBLE)
    119 #define wake_up_interruptible_sync(x)   __wake_up_sync((x),TASK_INTERRUPTIBLE, 1)

	/*
	* mode表示将要唤醒的线程类型(由线程的状态来标志)，nr_exclusive表示是独占式唤醒还是非独占式唤醒
	* - 独占式唤醒(nr_exclusive=0)将唤醒等待队列中所有进程(包括独占和非独占式进程)
	* - 非独占式唤醒智慧唤醒一个独占式进程和所有非独占式进程
	*/
    2393 void fastcall __wake_up(wait_queue_head_t *q, unsigned int mode,
    2394                 int nr_exclusive, void *key)
    2395 {
    2396     unsigned long flags;
	2397 
    2398     spin_lock_irqsave(&q->lock, flags);/*设置自选锁*/
    2399     __wake_up_common(q, mode, nr_exclusive, 0, key);
    2400     spin_unlock_irqrestore(&q->lock, flags);/*解除自选锁*/
    2401 }

	/*
	* sync表示唤醒是否应该同步
	*/
    2370 static void __wake_up_common(wait_queue_head_t *q, unsigned int mode,
    2371                  int nr_exclusive, int sync, void *key)
    2372 {
    2373     struct list_head *tmp, *next;
	2374     /*扫描等待队列的每一项，这是循环的开始*/
    2375     list_for_each_safe(tmp, next, &q->task_list) {
    2376         wait_queue_t *curr;
    2377         unsigned flags;
		         /*list_entry宏返回tmp变量所存放的等待队列结构的地址*/
    2378         curr = list_entry(tmp, wait_queue_t, task_list);
    2379         flags = curr->flags;
		         /*wait_queue_t的func字段，默认情况下调用default_wake_function*/
    2380         if (curr->func(curr, mode, sync, key) &&
    2381             (flags & WQ_FLAG_EXCLUSIVE) &&
    2382             !--nr_exclusive)
		         /*
				 * 如果被唤醒的是第一个独占式进程，则循环终止
				 * 因为所有独占进程都排在队列的末尾，当在等待队列中遇到第一个独占式进程后，剩余的所有进程也是独占式的
				 * 因此我们不应该唤醒他们，所以要跳出循环
				 */
    2383             break;
    2384     }
    2385 }


    2353 int default_wake_function(wait_queue_t *curr, unsigned mode, int sync, void *key)
    2354 {
    2355     task_t *p = curr->task;
    2356     return try_to_wake_up(p, mode, sync);
    2357 }
