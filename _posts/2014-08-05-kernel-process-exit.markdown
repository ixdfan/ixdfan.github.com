---
layout: post
title: 进程的终止
description:  
modified: 
categories: 
- KERNEL
tags:
- 
---

进程可以显式、主动的终止，也可以隐式、主动的终止或者被动终止。

主动终止可以通过两种途径实现:
* 从main函数返回(隐式) 
* 调用exit() (显式)

从主函数执行一个返回实际上转化为对exit()的调用，链接程序在这类情况下会引入对exit的调用

进程的被动终止可以通过三种途径来实现
* 进程可能收到自己不能处理的信号
* 进程在内核态执行时产生一个异常
* 进程可能收到SIGABRT信号或是其他终止信号



对进程的终止如何处理取决于父进程是否消亡
* 先于父进程终止 
* 在父进程之后终止

对于第一种情况，子进程变为僵尸进程，知道父进程调用wait()或是waitpid()

对于第二种情况，init进程将成为子进程的新父进程

当任何进程终止的时候，内核都要查看一边所有活着的进程，核实将要终止的进程是否是某个活着的进程的父进程，如果是，内核就将其子进程的父进程PID修改为1

exit()函数或调用sys_exit系统调用


	 832 asmlinkage long sys_exit(int error_code)
	 833 {
			 /*	可以看到退出码有效值最大位0xff=255,并且保存在左移8位中	*/
	 834     do_exit((error_code&0xff)<<8);
	 835 }

sys_exit的工作仅仅是将退出码转换成内核要求的格式并调用do_exit()


		/*	参数code中包含了进程返回给父进程的退出代码,在左移8位中存储	*/
	768 asmlinkage NORET_TYPE void do_exit(long code)
	769 {
			/*	获取当前进程的进程描述符	*/
	770     struct task_struct *tsk = current;
	771 
			/*	确保退出进程没有处于中断处理中	*/
	772     if (unlikely(in_interrupt()))
	773         panic("Aiee, killing interrupt handler!");
			/*	确保退出进程不是idle进程(pid = 0)	*/
	774     if (unlikely(!tsk->pid))
	775         panic("Attempted to kill the idle task!");
			/*	确保退出进程不是init进程，init进程只有在系统关闭时候才能被杀死	*/
	776     if (unlikely(tsk->pid == 1))
	777         panic("Attempted to kill init!");
	778     if (tsk->io_context)
	779         exit_io_context();
			/*	
			*	将进程的进程结构flags设置位PF_EXITING，这表明进程正在关闭,
			*	设置标志有助于防止多余的处理,免得到时候内核其他部分也来凑热闹
			*/
	780     tsk->flags |= PF_EXITING;
	781     del_timer_sync(&tsk->real_timer);
	782 
	783     if (unlikely(in_atomic()))
	784         printk(KERN_INFO "note: %s[%d] exited with preempt_count %d\n",
	785                 current->comm, current->pid,
	786                 preempt_count());
	787 
	788     profile_exit_task(tsk);
	789 
			/*	
			*	如果进程正在被追踪并且已经设置了PT_TRACE_EXIT标志，
			*	那么就传递返回代码并通知父进程	
			*/
	790     if (unlikely(current->ptrace & PT_TRACE_EXIT)) {
	791         current->ptrace_message = code;
	792         ptrace_notify((PTRACE_EVENT_EXIT << 8) | SIGTRAP);
	793     }
	794 
	795     acct_process(code);
			/*
			*	代码用于清理与回收进程已经使用过并且以后不会在使用的资源
			*/
			/*	释放分配给进程的内存,并释放进程相关的mm_struct	*/
	796     __exit_mm(tsk);	
	797		
			/*	将进程从所有IPC信号量中分离出来	*/ 
	798     exit_sem(tsk);	
			/*	释放分配给进程的所有文件，减少文件描述符的计数 */
	799     __exit_files(tsk);	
			/*	释放所有文件系统数据	*/
	800     __exit_fs(tsk);		
	801     exit_namespace(tsk);
	802     exit_thread();
	803 #ifdef CONFIG_NUMA
	804     mpol_free(tsk->mempolicy);
	805 #endif
	806 
			/*	
			*	如果进程是一个会话首进程，它极可能拥有一个控制终端或是tty
			*	这个函数把会话首进程从他的控制终端tty中分离出来
			*/
	807     if (tsk->signal->leader)
	808         disassociate_ctty(1);
	809 
			/*	减少模块的引用计数	*/
	810     module_put(tsk->thread_info->exec_domain->module);
	811     if (tsk->binfmt)
	812         module_put(tsk->binfmt->module);
	813 
			/*	在task_struct的exit_code中设置退出代码*/
	814     tsk->exit_code = code;
			/*	
			*	向父进程发送SIGCHLD信号，告诉父进程自己正在退出，并设置进程状态位TASK_ZOMBIE
			*	同时跟新父子进程的亲属关系
			*/
	815     exit_notify(tsk);	
			/*	切换到其他进程，僵死状态的进程不会在被调度*/
	816     schedule();
	817     BUG();
	818     /* Avoid "noreturn function does return".  */
	819     for (;;) ;
	820 }
	


exit_notify的主要作用
- 在进程退出之前为其子进程重新寻找父进程
- 在子进程退出时候必须向父进程发送相关信号

	637 static void exit_notify(struct task_struct *tsk)
	638 {
	639     int state;
	640     struct task_struct *t; 
	641 
	642     if (signal_pending(tsk) && !tsk->signal->group_exit
	643         && !thread_group_empty(tsk)) {
	644         /*
	645          * This occurs when there was a race between our exit
	646          * syscall and a group signal choosing us as the one to
	647          * wake up.  It could be that we are the only thread
	648          * alerted to check for pending signals, but another thread
	649          * should be woken now to take the signal since we will not.
	650          * Now we'll wake all the threads in the group just to make
	651          * sure someone gets all the pending signals.
	652          */
	653         read_lock(&tasklist_lock);
	654         spin_lock_irq(&tsk->sighand->siglock);
	655         for (t = next_thread(tsk); t != tsk; t = next_thread(t))
	656             if (!signal_pending(t) && !(t->flags & PF_EXITING)) {
	657                 recalc_sigpending_tsk(t);
	658                 if (signal_pending(t))
	659                     signal_wake_up(t, 0);
	660             }
	661         spin_unlock_irq(&tsk->sighand->siglock);
	662         read_unlock(&tasklist_lock);
	663     }
	664 
	665     write_lock_irq(&tasklist_lock);
	666 
	667     /*
	668      * This does two things:
	669      *
	670      * A.  Make init inherit all the child processes
	671      * B.  Check to see if any process groups have become orphaned
	672      *  as a result of our exiting, and if they have any stopped
	673      *  jobs, send them a SIGHUP and then a SIGCONT.  (POSIX 3.2.2.2)
	674      */
	675 
			/*	为孤儿进程重新寻找父进程	*/
	676     forget_original_parent(tsk);
	677     BUG_ON(!list_empty(&tsk->children));
	678 
	679     /*
	680      * Check to see if any process groups have become orphaned
	681      * as a result of our exiting, and if they have any stopped
	682      * jobs, send them a SIGHUP and then a SIGCONT.  (POSIX 3.2.2.2)
	683      *
	684      * Case i: Our father is in a different pgrp than we are
	685      * and we were the only connection outside, so our pgrp
	686      * is about to become orphaned.
	687      */
	688 
	689     t = tsk->real_parent;
	690 
	691     if ((process_group(t) != process_group(tsk)) &&
	692         (t->signal->session == tsk->signal->session) &&
	693         will_become_orphaned_pgrp(process_group(tsk), tsk) &&
	694         has_stopped_jobs(process_group(tsk))) {
	695         __kill_pg_info(SIGHUP, (void *)1, process_group(tsk));
	696         __kill_pg_info(SIGCONT, (void *)1, process_group(tsk));
	697     }
	698 
	699     /* Let father know we died 
	700      *
	701      * Thread signals are configurable, but you aren't going to use
	702      * that to send signals to arbitary processes. 
	703      * That stops right now.
	704      *
	705      * If the parent exec id doesn't match the exec id we saved
	706      * when we started then we know the parent has changed security
	707      * domain.
	708      *
	709      * If our self_exec id doesn't match our parent_exec_id then
	710      * we have changed execution domain as these two values started
	711      * the same after a fork.
	712      *  
	713      */
	714 
	715     if (tsk->exit_signal != SIGCHLD && tsk->exit_signal != -1 &&
	716         ( tsk->parent_exec_id != t->self_exec_id  ||
	717           tsk->self_exec_id != tsk->parent_exec_id)
	718         && !capable(CAP_KILL))
	719         tsk->exit_signal = SIGCHLD;
	720 
	721 
	722     /* If something other than our normal parent is ptracing us, then
	723      * send it a SIGCHLD instead of honoring exit_signal.  exit_signal
	724      * only has special meaning to our real parent.
	725      */
	726     if (tsk->exit_signal != -1 && thread_group_empty(tsk)) {
	727         int signal = tsk->parent == tsk->real_parent ? tsk->exit_signal : SIGCHLD;
	728         do_notify_parent(tsk, signal);
	729     } else if (tsk->ptrace) {
	730         do_notify_parent(tsk, SIGCHLD);
	731     }
	732 
	733     state = TASK_ZOMBIE;
	734     if (tsk->exit_signal == -1 && tsk->ptrace == 0)
	735         state = TASK_DEAD;
	736     tsk->state = state;
	737     tsk->flags |= PF_DEAD;
	738 
	739     /*
	740      * Clear these here so that update_process_times() won't try to deliver
	741      * itimer, profile or rlimit signals to this task while it is in late exit.
	742      */
	743     tsk->it_virt_value = 0;
	744     tsk->it_prof_value = 0;
	745     tsk->rlim[RLIMIT_CPU].rlim_cur = RLIM_INFINITY;
	746 
	747     /*
	748      * In the preemption case it must be impossible for the task
	749      * to get runnable again, so use "_raw_" unlock to keep
	750      * preempt_count elevated until we schedule().
	751      *
	752      * To avoid deadlock on SMP, interrupts must be unmasked.  If we
	753      * don't, subsequently called functions (e.g, wait_task_inactive()
	754      * via release_task()) will spin, with interrupt flags
	755      * unwittingly blocked, until the other task sleeps.  That task
	756      * may itself be waiting for smp_call_function() to answer and
	757      * complete, and with interrupts blocked that will never happen.
	758      */
	759     _raw_write_unlock(&tasklist_lock);
	760     local_irq_enable();
	761 
	762     /* If the process is dead, release it - nobody will wait for it */
	763     if (state == TASK_DEAD)
	764         release_task(tsk);
	765 
	766 }
	




-------------------------------------------------------------------

通知父进程和sys_wait4()

当一个进程终止时，就要通知它的父进程，在这之前，进程处于僵死状态，除了进程描述符仍然保留外，它的所有资源都已经归还内核。当子进程终止时，父进程收到内核发送给他的SIGCHLD信号


当父进程想要收到通知时就要调用wait(),父进程可以通过不执行中断处理程序来忽略信号，也可以改为选择在任何时刻调用wait()或waitpid()

wait函数主要有下面两个作用
- 获知进程消亡的消息
- 消除进程的所有痕迹

父进程可以调用wait函数

	pid_t wait(int *stat_loc);
	pid_t waitpid(pid_t pid, int *stat_loc, int options);
	pid_t wait3(int *status, int options,
				struct rusage *rusage);
	pid_t wait4(pid_t pid, int *status, int options,
				struct rusage *rusage);

每个函数有一次调用sys_wait4(),大部分的通知会在sys_wait4中产生

如果进程调用wait函数族中一个函数，那么他会被阻塞，直到它的某个子进程终止，或者如果子进程已经终止(或其父进程已经没有其他子进程)，该进程就立刻返回


	/*	参数依次为目标进程的PID、存放子进程退出状态的地址、传给sys_wait4的标志已经存放子进程资源使用的信息地址	*/
	1091 asmlinkage long sys_wait4(pid_t pid,unsigned int __user *stat_addr, int options, struct rusage __user *ru)
	1092 {
			/*	声明一个等待队列	*/
	1093     DECLARE_WAITQUEUE(wait, current);
	1094     struct task_struct *tsk;
	1095     int flag, retval;
	1096 
			/*	检查错误条件，如果传递给sys_wait4的参数options是无效的，那么将返回一个错误码EINVAL	*/
	1097     if (options & ~(WNOHANG|WUNTRACED|__WNOTHREAD|__WCLONE|__WALL))
	1098         return -EINVAL;
	1099 	/*	将进程加入该等待队列	*/
	1100     add_wait_queue(&current->wait_chldexit,&wait);
	1101 repeat:
			/*	flag变量初始值被设置为0，一旦发现wait参数pid和调用进程的某个子进程的pid匹配，就要修改这个变量	*/
	1102     flag = 0;
			/*	将当前进程状态设置TASK_INTERRUPTIBLE,也就是阻塞该进程	*/
	1103     current->state = TASK_INTERRUPTIBLE;
	1104     read_lock(&tasklist_lock);
	1105     tsk = current;
			
	1106     do {
	1107         struct task_struct *p;
	1108         struct list_head *_p;
	1109         int ret;
	1110 
				/*	对进程的子进程列中中每个进程重复操作
				*	父进程此时仍然是TASK_INTERRUPTIBLE状态，父进程在等待子进程退出	
				*/
	1111         list_for_each(_p,&tsk->children) {
	1112             p = list_entry(_p,struct task_struct,sibling);
	1113 
	1114             ret = eligible_child(pid, options, p);
					/*	确定被传递的pid参数是否合理	*/
	1115             if (!ret)
	1116                 continue;
	1117             flag = 1;
	1118 
					/*	检查进程的每个子进程的状态，仅当子进程停止或是僵死时才进行这种处理,否则什么也不做	*/
	1119             switch (p->state) {
	1120             case TASK_STOPPED:		
					/*	如果使用了UNTRACED选项，且子进程是TASK_STOPPED状态，意味着进程由于跟踪而未被停止	*/
	1121                 if (!(options & WUNTRACED) &&
	1122                     !(p->ptrace & PT_PTRACED))
	1123                     continue;
	1124                 retval = wait_task_stopped(p, ret == 2,
	1125                                stat_addr, ru);
	1126                 if (retval != 0) /* He released the lock.  */
	1127                     goto end_wait4;
	1128                 break;
	1129             case TASK_ZOMBIE:
	1130                 /*
	1131                  * 如果子进程是TASK_ZOMBIE状态，则撤销它
	1132                  */
	1133                 if (ret == 2)
	1134                     continue;
	1135                 retval = wait_task_zombie(p, stat_addr, ru);
	1136                 if (retval != 0) /* He released the lock.  */
	1137                     goto end_wait4;
	1138                 break;
	1139             }
	1140         }
	1141         if (!flag) {
	1142             list_for_each (_p,&tsk->ptrace_children) {
	1143                 p = list_entry(_p,struct task_struct,ptrace_list);
	1144                 if (!eligible_child(pid, options, p))
	1145                     continue;
	1146                 flag = 1;
	1147                 break;
	1148             }
	1149         }
	1150         if (options & __WNOTHREAD)
	1151             break;
	1152         tsk = next_thread(tsk);
	1153         if (tsk->signal != current->signal)
	1154             BUG();
	1155     } while (tsk != current);
			/*	do-while循环检测到自己还是当前进程时只执行一次循环，当是其他进程时候就继续循环	*/

	1156     read_unlock(&tasklist_lock);
	1157     if (flag) {
	1158         retval = 0;
	1159         if (options & WNOHANG)
	1160             goto end_wait4;
	1161         retval = -ERESTARTSYS;
	1162         if (signal_pending(current))
	1163             goto end_wait4;
	1164         schedule();
	1165         goto repeat;
	1166     }
			
			/*	如果执行到这里，说明参数制定的pid不是所调用进程的子进程然会-ECHILD错误码	*/
	1167     retval = -ECHILD;
	1168 end_wait4:
			/*	此时子进程列表处理完毕，所有需要撤销的子进程都已经撤销，父进程的阻塞被解除,重新设置其状态位TASK_RUNNING	*/
	1169     current->state = TASK_RUNNING;
			/*	等待队列被删除	*/
	1170     remove_wait_queue(&current->wait_chldexit,&wait);
	1171     return retval;
	1172 }

