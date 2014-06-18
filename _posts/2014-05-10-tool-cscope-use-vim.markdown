---
layout: post
title:  cscope修改默认编辑器为vim
description: 
modified: 
categories: 
- TOOL 
tags:
- 
---

直接在.bashrc中加入

export EDITOR=/usr/bin/vim

EDITOR是在man cscope中提供的


执行cscope有时候会显示
	
	cscope: no source files found


可以使用cscope-indexer -r即可
