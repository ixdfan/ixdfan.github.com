---
layout: post
title: 覆盖性加载
description: 
modified: 
categories: 
-  security
tags:
- 
---



今天看到了一个非常非常非常非常好的隐藏目录的方法,使人难以访问.

例如我们可以创建/opt/tmp目录.并将所有的工具都放在该目录下,然后切换到这个目录,运行要运行的程序


	[root@ tmp]# pwd
	/opt/tmp
	[root@ tmp]# ls
	ping.sh  su.sh
	[root@ tmp]# ./ping.sh &
	[1] 4362
	[root@ tmp]# 

做完这些工作之后,我们需要在/opt/tmp上加载一个新的文件系统,比如一个多余的分区或是tmpfs文件系统
	
	
	[root@ tmp]# mount size=100 -t tmpfs /opt/tmp/
	[root@ tmp]# ls
	ping.sh  su.sh
	[root@ tmp]# pwd
	/opt/tmp
	[root@ tmp]# touch test
	[root@ tmp]# ls
	ping.sh  su.sh  test


由于我们没有离开过/opt/tmp目录,所以对其中的内容仍然拥有完成的访问权限,并且lsof会将原来的/opt/tmp目录当作是前面启动的程序及其锁打开文件的所在位置,但是新的进程无法访问其中的任何东西

	[root@ tmp]# lsof -c ping.sh 
	COMMAND  PID USER   FD   TYPE DEVICE  SIZE/OFF    NODE NAME
	ping.sh 4362 root  cwd    DIR  253,1      4096 1048358 /opt/tmp
	ping.sh 4362 root  rtd    DIR  253,1      4096       2 /
	ping.sh 4362 root  txt    REG  253,1    911720 2094276 /usr/bin/bash
	ping.sh 4362 root  mem    REG  253,1 106070928 2102940 /usr/lib/locale/locale-archive
	ping.sh 4362 root  mem    REG  253,1   2064488 2095852 /usr/lib/libc-2.18.so
	ping.sh 4362 root  mem    REG  253,1     17912 2095931 /usr/lib/libdl-2.18.so
	ping.sh 4362 root  mem    REG  253,1    135216 2096544 /usr/lib/libtinfo.so.5.9
	ping.sh 4362 root  mem    REG  253,1     26252 2098767 /usr/lib/gconv/gconv-modules.cache
	ping.sh 4362 root  mem    REG  253,1    150572 2095672 /usr/lib/ld-2.18.so
	ping.sh 4362 root    0u   CHR  136,3       0t0       6 /dev/pts/3
	ping.sh 4362 root    1u   CHR  136,3       0t0       6 /dev/pts/3
	ping.sh 4362 root    2u   CHR  136,3       0t0       6 /dev/pts/3
	ping.sh 4362 root  255r   REG  253,1        43 1048359 /opt/tmp/ping.sh
	[root@ tmp]# pwd
	/opt/tmp
	[root@ tmp]# ls

lsof表示文件是在/opt/tmp/中,但是就是显示不出来,是不是很爽呢?

恢复隐藏的目录

	[root@ tmp]# mount
	proc on /proc type proc (rw,nosuid,nodev,noexec,relatime)
	sysfs on /sys type sysfs (rw,nosuid,nodev,noexec,relatime)
	devtmpfs on /dev type devtmpfs (rw,nosuid,size=989192k,nr_inodes=215247,mode=755)
	securityfs on /sys/kernel/security type securityfs (rw,nosuid,nodev,noexec,relatime)
	tmpfs on /dev/shm type tmpfs (rw,nosuid,nodev)
	devpts on /dev/pts type devpts (rw,nosuid,noexec,relatime,gid=5,mode=620,ptmxmode=000)
	tmpfs on /run type tmpfs (rw,nosuid,nodev,mode=755)
	tmpfs on /sys/fs/cgroup type tmpfs (rw,nosuid,nodev,noexec,mode=755)
	cgroup on /sys/fs/cgroup/systemd type cgroup (rw,nosuid,nodev,noexec,relatime,xattr,release_agent=/usr/lib/systemd/systemd-cgroups-agent,name=systemd)
	pstore on /sys/fs/pstore type pstore (rw,nosuid,nodev,noexec,relatime)
	cgroup on /sys/fs/cgroup/cpuset type cgroup (rw,nosuid,nodev,noexec,relatime,cpuset)
	cgroup on /sys/fs/cgroup/cpu,cpuacct type cgroup (rw,nosuid,nodev,noexec,relatime,cpuacct,cpu)
	cgroup on /sys/fs/cgroup/memory type cgroup (rw,nosuid,nodev,noexec,relatime,memory)
	cgroup on /sys/fs/cgroup/devices type cgroup (rw,nosuid,nodev,noexec,relatime,devices)
	cgroup on /sys/fs/cgroup/freezer type cgroup (rw,nosuid,nodev,noexec,relatime,freezer)
	cgroup on /sys/fs/cgroup/net_cls type cgroup (rw,nosuid,nodev,noexec,relatime,net_cls)
	cgroup on /sys/fs/cgroup/blkio type cgroup (rw,nosuid,nodev,noexec,relatime,blkio)
	cgroup on /sys/fs/cgroup/perf_event type cgroup (rw,nosuid,nodev,noexec,relatime,perf_event)
	/dev/mapper/fedora-root on / type ext4 (rw,relatime,data=ordered)
	systemd-1 on /proc/sys/fs/binfmt_misc type autofs (rw,relatime,fd=35,pgrp=1,timeout=300,minproto=5,maxproto=5,direct)
	debugfs on /sys/kernel/debug type debugfs (rw,relatime)
	tmpfs on /tmp type tmpfs (rw)
	hugetlbfs on /dev/hugepages type hugetlbfs (rw,relatime)
	configfs on /sys/kernel/config type configfs (rw,relatime)
	mqueue on /dev/mqueue type mqueue (rw,relatime)
	sunrpc on /var/lib/nfs/rpc_pipefs type rpc_pipefs (rw,relatime)
	sunrpc on /proc/fs/nfsd type nfsd (rw,relatime)
	/dev/sda12 on /boot type ext4 (rw,relatime,data=ordered)
	/dev/mapper/fedora-home on /home type ext4 (rw,relatime,data=ordered)
	gvfsd-fuse on /run/user/0/gvfs type fuse.gvfsd-fuse (rw,nosuid,nodev,relatime,user_id=0,group_id=0)
	/dev/sdb4 on /run/media/root/FEDORA-LIVE type vfat (rw,nosuid,nodev,relatime,fmask=0022,dmask=0077,codepage=437,iocharset=ascii,shortname=mixed,showexec,utf8,flush,errors=remount-ro,uhelper=udisks2)
	size=100 on /opt/tmp type tmpfs (rw,relatime)

此时最后一行显示出了这个挂载点,我们需要将其卸载

	[root@ tmp]# ls
	ping.sh  su.sh  test
	[root@ tmp]# cd ..			#一旦离开目录就没有访问权限了
	[root@ opt]# cd tmp/
	[root@ tmp]# ls
	[root@ tmp]# cd ../		
	[root@ opt]# 
	[root@ opt]# umount tmp/
	[root@ opt]# cd tmp/
	[root@ tmp]# ls
	ping.sh  su.sh  test
	[root@ tmp]# 


