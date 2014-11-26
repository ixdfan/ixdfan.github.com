---
layout: post
title: Connection Reset By Peer
categories:
- LINUX
tags:
- recvmsg
---

再使用recvmsg时遇到Connection Reset By Peer这个问题，一直以为是我的程序的问题，终于找到来答案

服务器向客户端发送了数据，客户端没有接收就关闭了，服务器readmsg就会发生Connection reset by peer错误。

================================================================

客户端调用close()时，服务器应该会读到一个EOF，read()返回0

Connection reset by peer 本质是收到一个标记了reset位的数据包。
这个错误的原因有几种：
1. connect到一个不存在的端口。
2. 对方故意发送RST包（一些网络破坏程序会这么干）。
3. 对方故障（中途掉线，程序重启）等原因，导致socket失效，或者不再是原来那个socket。（你遇到的应该就是这种）

##### 解决方案
TCP协议中有RST标志位, 不管原因是什么, 正确的判断返回值-1, errno != EINTR  && errno != EAGAIN就可以认定对端出错, 立即cloes即可.
