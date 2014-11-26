---
layout: post
title: Emacs的Org-mode的Todo简单使用
categories:
- EMACS
---


	
	C-S-RET 插入一个`* TODO`
	C-c C-j 切换到大纲模式
	C-c C-t 改变TODO状态
	C-u C-c C-t 手动改变TODO状态
	C-c C-s 插入开始时间
	C-c C-d 插入结束时间
	C-c C-n/p 移动到下/上一个标题
	C-c C-f/b 移动到同级下/上一个标题
	C-c C-u 跳到上一级标题
	
	S-TAB   循环展开各级标题
	Tab     展开当前标题
	
	
	M-RET 插入同级标题
	M-LEFT/RIGHT 升/降级当前标题
	M-UP/DOWN    移动同级标题子树
	
	`- [ ]` 来创建子任务
	
	例如:

	** 步骤
	   - [-] 步骤1
	     - [X] 步骤1.1
	     - [ ] 步骤1.2
	   - [X] 步骤2
	     - [X] 步骤2.1
	     - [X] 步骤2.2
	
	C-c C-c 改变[]内状态
	M-S-RET 增加一个子项



	
