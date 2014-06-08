---
layout: post
title:  nginx进程间通信
description: 
modified: 
categories: 
- nginx 
tags:
- 
---

Nginx中采用的是socketpair来创建未命名套接字来进行父子进程之间通信的.

    22 typedef struct {
    23     ngx_pid_t           pid;
    24     int                 status;
    25     ngx_socket_t        channel[2];
    26 
    27     ngx_spawn_proc_pt   proc;
    28     void               *data;
    29     char               *name;
    30 
    31     unsigned            respawn:1;
    32     unsigned            just_spawn:1;
    33     unsigned            detached:1;
    34     unsigned            exiting:1;
    35     unsigned            exited:1;
    36 } ngx_process_t;

	47 #define NGX_MAX_PROCESSES         1024

	86 ngx_pid_t
	87 ngx_spawn_process(ngx_cycle_t *cycle, ngx_spawn_proc_pt proc, void *data,
	88     char *name, ngx_int_t respawn)
	89 {
	90     u_long     on;
	91     ngx_pid_t  pid;
	92     ngx_int_t  s;
	93 
	94     if (respawn >= 0) {
	95         s = respawn;
	96 
	97     } else {
	98         for (s = 0; s < ngx_last_process; s++) {
	99             if (ngx_processes[s].pid == -1) {
	100                 break;
	101             }
	102         }
	103 
	104         if (s == NGX_MAX_PROCESSES) {
	105             ngx_log_error(NGX_LOG_ALERT, cycle->log, 0,
	106                           "no more than %d processes can be spawned",
	107                           NGX_MAX_PROCESSES);
	108             return NGX_INVALID_PID;
	109         }
	110     }
	111 
	112 
	113     if (respawn != NGX_PROCESS_DETACHED) {
	114 
	115         /* Solaris 9 still has no AF_LOCAL */
	116 
	117             /*  建立父子间的通信socket  */
	118         if (socketpair(AF_UNIX, SOCK_STREAM, 0, ngx_processes[s].channel) == -1)
	119         {
	120             ngx_log_error(NGX_LOG_ALERT, cycle->log, ngx_errno,
				....
	186 
	187     pid = fork();
	188 
	189     switch (pid) {
	190 
	191     case -1:
	192         ngx_log_error(NGX_LOG_ALERT, cycle->log, ngx_errno,
	193                       "fork() failed while spawning \"%s\"", name);
	194         ngx_close_channel(ngx_processes[s].channel, cycle->log);
	195         return NGX_INVALID_PID;
	196 
	197     case 0:
	198         ngx_pid = ngx_getpid();
	199         proc(cycle, data);
	200         break;
	201 
	202     default:
	203         break;
	204     }

在调用fork之前,先使用socketpair创建一堆socket描述符放在变量ngx_processes[s].channel中(s代表在ngx_processes中第一个可用元素的下标, 例如产生第一个进程时候,可用元素的下标为0),在fork之后由于子进程继承了父进程的资源,那么父子进程就都有了着一对socket描述符,Nginx将channel[0]给父进程时候,channel[1]给子进程使用,这样分别错开了不同socket描述符,即可实现父子进程之间的双向通信.

除此之外各个子进程之间也可以进行双向通信,父子进程通信比较简单,而子进程之间通信channel的设定就涉及到了进程之间文件描述符的传递,因为虽然后生成的子进程通过继承的channel[0]能够向之前生成的子进程发送信息,但是在前生成的子进程无法获知在后生成的子进程的channel[0],而不能发送信息,所以在后生成的子进程必须利用已知的在前生成子进程的channel[0]进行主动告知.

	
	839 static void
	840 ngx_worker_process_init(ngx_cycle_t *cycle, ngx_uint_t priority)
	841 {
	969     for (n = 0; n < ngx_last_process; n++) {
	970 
	971         if (ngx_processes[n].pid == -1) {
	972             continue;
	973         }
	974 
	975         if (n == ngx_process_slot) {
	976             continue;
	977         }
	978 
	979         if (ngx_processes[n].channel[1] == -1) {
	980             continue;
	981         }
	982 
	983         if (close(ngx_processes[n].channel[1]) == -1) {
	984             ngx_log_error(NGX_LOG_ALERT, cycle->log, ngx_errno,
	985                           "close() channel failed");
	986         }
	987     }
	988 
	989     if (close(ngx_processes[ngx_process_slot].channel[0]) == -1) {
	990         ngx_log_error(NGX_LOG_ALERT, cycle->log, ngx_errno,
	991                       "close() channel failed");
	992     }
	993 
	994 #if 0
	995     ngx_last_process = 0;
	996 #endif
	997 
	998     if (ngx_add_channel_event(cycle, ngx_channel, NGX_READ_EVENT,
	999                               ngx_channel_handler)		/*	回调函数	*/
	1000         == NGX_ERROR)
	1001     {
	1002         /* fatal */
	1003         exit(2);

在子进程的启动初始化函数ngx_worker_process_init中,会将ngx_channel(也就是channel[1])加到读事件监听集中,对应的回调处理函数为ngx_channel_handler.


父进程fork生成一个新的子进程之后会立即通过ngx_pass_open_channel函数把这个子进程的相关信息告知给前面已经生成的子进程.

	435 static void 
	436 ngx_pass_open_channel(ngx_cycle_t *cycle, ngx_channel_t *ch)
	437 {
	438     ngx_int_t  i;
	439 
			/*	遍历整个进程表	*/
	440     for (i = 0; i < ngx_last_process; i++) {
	441 
				/*	如果遇到非存活的就直接跳过	*/
	442         if (i == ngx_process_slot
	443             || ngx_processes[i].pid == -1
	444             || ngx_processes[i].channel[0] == -1)
	445         {
	446             continue;
	447         }
	448 
	449         ngx_log_debug6(NGX_LOG_DEBUG_CORE, cycle->log, 0,
	450                       "pass channel s:%d pid:%P fd:%d to s:%i pid:%P fd:%d",
	451                       ch->slot, ch->pid, ch->fd,
	452                       i, ngx_processes[i].pid,
	453                       ngx_processes[i].channel[0]);
	454 
	455         /* TODO: NGX_AGAIN */
	456 
				/*	对存活的进程告知其channel	*/
	457         ngx_write_channel(ngx_processes[i].channel[0],
	458                           ch, sizeof(ngx_channel_t), cycle->log);
	459     }
	460 }


	13 ngx_int_t
	14 ngx_write_channel(ngx_socket_t s, ngx_channel_t *ch, size_t size,
	15     ngx_log_t *log)
	16 {
	17     ssize_t             n;
	18     ngx_err_t           err;
	19     struct iovec        iov[1];
	20     struct msghdr       msg;				/*	利用msghdr结构体来传递文件描述符	*/
	21 
	22 #if (NGX_HAVE_MSGHDR_MSG_CONTROL)
	23 
	24     union {
	25         struct cmsghdr  cm;
	26         char            space[CMSG_SPACE(sizeof(int))];
	27     } cmsg;
	28 
	29     if (ch->fd == -1) {
	30         msg.msg_control = NULL;
	31         msg.msg_controllen = 0;
	32 
	33     } else {
	34         msg.msg_control = (caddr_t) &cmsg;
	35         msg.msg_controllen = sizeof(cmsg);
	36 
	37         cmsg.cm.cmsg_len = CMSG_LEN(sizeof(int));
	38         cmsg.cm.cmsg_level = SOL_SOCKET;
	39         cmsg.cm.cmsg_type = SCM_RIGHTS;
	40 
	41         /*
	42          * We have to use ngx_memcpy() instead of simple
	43          *   *(int *) CMSG_DATA(&cmsg.cm) = ch->fd;
	44          * because some gcc 4.4 with -O2/3/s optimization issues the warning:
	45          *   dereferencing type-punned pointer will break strict-aliasing rules
	46          *
	47          * Fortunately, gcc with -O1 compiles this ngx_memcpy()
	* in the same simple assignment as in the code above
	49          */
	50 
	51         ngx_memcpy(CMSG_DATA(&cmsg.cm), &ch->fd, sizeof(int));
	52     }
	53 
	54     msg.msg_flags = 0;
	55 
	56 #else
	57 
	58     if (ch->fd == -1) {
	59         msg.msg_accrights = NULL;
	60         msg.msg_accrightslen = 0;
	61 
	62     } else {
	63         msg.msg_accrights = (caddr_t) &ch->fd;
	64         msg.msg_accrightslen = sizeof(int);
	65     }
	66 
	67 #endif
	68 
			/*	要传递的消息	*/
	69     iov[0].iov_base = (char *) ch;
	70     iov[0].iov_len = size;
	71 
	72     msg.msg_name = NULL;
	73     msg.msg_namelen = 0;
	74     msg.msg_iov = iov;
	75     msg.msg_iovlen = 1;
	76 
			/*	利用sendmsg来传递文件描述符	*/
	77     n = sendmsg(s, &msg, 0);
	78 
	79     if (n == -1) {
	80         err = ngx_errno;
	81         if (err == NGX_EAGAIN) {
	82             return NGX_AGAIN;
	83         }
	84 
	85         ngx_log_error(NGX_LOG_ALERT, log, err, "sendmsg() failed");
	86         return NGX_ERROR;
	87     }
	88 
	89     return NGX_OK;
	90 }


	17 typedef struct {
	18      ngx_uint_t  command;
	19      ngx_pid_t   pid;
	20      ngx_int_t   slot;		/*	全局的下标	*/
	21      ngx_fd_t    fd;			/*	channel[0]	*/
	22 } ngx_channel_t;


可以看到文件描述符的传递是通过sendmsg的方式来传递的,ch中包含了新创建文件描述符的pid,进程信息在全局数组里存储下标,socket描述符channel[0]的信息

NGX_WRITE_CHANNEL通过继承的CHANNEL[0]描述符进行信息告知,收到这些消息的子进程将执行设置号的回调函数NGX_CHANNEL_HANDLER,将新接收的子进程相关信息存储在全局变量NGX_PROCESSES中

	1071 static void
	1072 ngx_channel_handler(ngx_event_t *ev)
	1073 {
	1074     ngx_int_t          n;
	1075     ngx_channel_t      ch;
	1076     ngx_connection_t  *c;
	1077 
	1078     if (ev->timedout) {
	1079         ev->timedout = 0;
	1080         return;
	1081     }
	1082 
	1083     c = ev->data;
	1084 
	1085     ngx_log_debug0(NGX_LOG_DEBUG_CORE, ev->log, 0, "channel handler");
	1086 
	1087     for ( ;; ) {
	1088 
				/*	
				*	读取到发送的新建子进程的channel[0]
				*	从c->fd中读取到ch中去	
				*/
	1089         n = ngx_read_channel(c->fd, &ch, sizeof(ngx_channel_t), ev->log);
	1090 
	1091         ngx_log_debug1(NGX_LOG_DEBUG_CORE, ev->log, 0, "channel: %i", n);
	1092 
	1093         if (n == NGX_ERROR) {
	1094 
	1095             if (ngx_event_flags & NGX_USE_EPOLL_EVENT) {
	1096                 ngx_del_conn(c, 0);
	1097             }
	1098 
	1099             ngx_close_connection(c);
	1100             return;
	1101         }
	1102 
	1103         if (ngx_event_flags & NGX_USE_EVENTPORT_EVENT) {
	1104             if (ngx_add_event(ev, NGX_READ_EVENT, 0) == NGX_ERROR) {
	1105                 return;
	1106             }
	1107         }
	1108 
	1109         if (n == NGX_AGAIN) {
	1110             return;
	1111         }
	1112 
	1113         ngx_log_debug1(NGX_LOG_DEBUG_CORE, ev->log, 0,
	1114                        "channel command: %d", ch.command);
	1115 
	1116         switch (ch.command) {
	1117 
	1118         case NGX_CMD_QUIT:
	1119             ngx_quit = 1;
	1120             break;
	1121 
	1122         case NGX_CMD_TERMINATE:
	1123             ngx_terminate = 1;
	1124             break;
	1125 
	1126         case NGX_CMD_REOPEN:
	1127             ngx_reopen = 1;
	1128             break;
	1129 
	1130         case NGX_CMD_OPEN_CHANNEL:
	1131 
	1132             ngx_log_debug3(NGX_LOG_DEBUG_CORE, ev->log, 0,
	1133                            "get channel s:%i pid:%P fd:%d",
	1134                            ch.slot, ch.pid, ch.fd);
	1135 
					/*	将相关信息加入到全局数组中去	*/
	1136             ngx_processes[ch.slot].pid = ch.pid;
	1137             ngx_processes[ch.slot].channel[0] = ch.fd;
	1138             break;
	1139 
	1140         case NGX_CMD_CLOSE_CHANNEL:
	1141 
	1142             ngx_log_debug4(NGX_LOG_DEBUG_CORE, ev->log, 0,
	1143                            "close channel s:%i pid:%P our:%P fd:%d",
	1144                            ch.slot, ch.pid, ngx_processes[ch.slot].pid,
	1145                            ngx_processes[ch.slot].channel[0]);
	1146 
	1147             if (close(ngx_processes[ch.slot].channel[0]) == -1) {
	1148                 ngx_log_error(NGX_LOG_ALERT, ev->log, ngx_errno,
	1149                               "close() channel failed");
	1150             }
	1151 
	1152             ngx_processes[ch.slot].channel[0] = -1;
	1153             break;
	1154         }
	1155     }
	1156 }
	

	ngx_int_t
	94 ngx_read_channel(ngx_socket_t s, ngx_channel_t *ch, size_t size, ngx_log_t *log)
	95 {
	96     ssize_t             n;
	97     ngx_err_t           err;
	98     struct iovec        iov[1];
	99     struct msghdr       msg;
	100 
	101 #if (NGX_HAVE_MSGHDR_MSG_CONTROL)
	102     union {
	103         struct cmsghdr  cm;
	104         char            space[CMSG_SPACE(sizeof(int))];
	105     } cmsg;
	106 #else
	107     int                 fd;
	108 #endif
	109 
	110     iov[0].iov_base = (char *) ch;
	111     iov[0].iov_len = size;
	112 
	113     msg.msg_name = NULL;
	114     msg.msg_namelen = 0;
	115     msg.msg_iov = iov;
	116     msg.msg_iovlen = 1;
	117 
	118 #if (NGX_HAVE_MSGHDR_MSG_CONTROL)
	119     msg.msg_control = (caddr_t) &cmsg;
	120     msg.msg_controllen = sizeof(cmsg);
	121 #else
	122     msg.msg_accrights = (caddr_t) &fd;
	123     msg.msg_accrightslen = sizeof(int);
	124 #endif
	125 
	126     n = recvmsg(s, &msg, 0);
	127 
	128     if (n == -1) {
	129         err = ngx_errno;
	130         if (err == NGX_EAGAIN) {
	131             return NGX_AGAIN;
	132         }
	133 
	134         ngx_log_error(NGX_LOG_ALERT, log, err, "recvmsg() failed");
	135         return NGX_ERROR;
	136     }
	137 
	138     if (n == 0) {
	139         ngx_log_debug0(NGX_LOG_DEBUG_CORE, log, 0, "recvmsg() returned zero");
	140         return NGX_ERROR;
	141     }
	142 
	143     if ((size_t) n < sizeof(ngx_channel_t)) {
	144         ngx_log_error(NGX_LOG_ALERT, log, 0,
	145                       "recvmsg() returned not enough data: %uz", n);
	146         return NGX_ERROR;
	147     }
	148 
	149 #if (NGX_HAVE_MSGHDR_MSG_CONTROL)
	150 
	151     if (ch->command == NGX_CMD_OPEN_CHANNEL) {
	152 
	153         if (cmsg.cm.cmsg_len < (socklen_t) CMSG_LEN(sizeof(int))) {
	154             ngx_log_error(NGX_LOG_ALERT, log, 0,
	155                           "recvmsg() returned too small ancillary data");
	156             return NGX_ERROR;
	157         }
	158 
	159         if (cmsg.cm.cmsg_level != SOL_SOCKET || cmsg.cm.cmsg_type != SCM_RIGHTS)
	160         {
	161             ngx_log_error(NGX_LOG_ALERT, log, 0,
	162                           "recvmsg() returned invalid ancillary data "
	163                           "level %d or type %d",
	164                           cmsg.cm.cmsg_level, cmsg.cm.cmsg_type);
	165             return NGX_ERROR;
	166         }
	  	167 
	168         /* ch->fd = *(int *) CMSG_DATA(&cmsg.cm); */
	169 
	170         ngx_memcpy(&ch->fd, CMSG_DATA(&cmsg.cm), sizeof(int));
	171     }
	172 
	173     if (msg.msg_flags & (MSG_TRUNC|MSG_CTRUNC)) {
	174         ngx_log_error(NGX_LOG_ALERT, log, 0,
	175                       "recvmsg() truncated data");
	176     }
	177 
	178 #else
	179 
	180     if (ch->command == NGX_CMD_OPEN_CHANNEL) {
	181         if (msg.msg_accrightslen != sizeof(int)) {
	182             ngx_log_error(NGX_LOG_ALERT, log, 0,
	183                           "recvmsg() returned no ancillary data");
	184             return NGX_ERROR;
	185         }
	186 
	187         ch->fd = fd;
	188     }
	189 
	190 #endif
	191 
	192     return n;
	193 }
	

不过好像程序执行过程当中,子进程并没有向父进程发送任何消息,子进程之间也没有相互通信,还有一点有些想不通,在什么情况下子进程之间需要通信,或者说子进程之间要传递什么信息??

	
