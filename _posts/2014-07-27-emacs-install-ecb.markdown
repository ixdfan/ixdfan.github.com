---
layout: post
title: emacs24安装ecb与cedet
categories:
- EMACS
tags:
- emacs
---

今天想要在emacs上安装ecb，然后下载了ecb，但是发现其以来与cedet，所以又下载了cedet-1.1,安装cedet-1.1的时候没有问题，但是make ecb的时候出现问题了，大体意思就是说cedet-1.1太新了，不支持。

####解决方法:
修改ecb-upgrade.el文件中

	(defconst ecb-required-cedet-version-max '(1 0 4 9))
	改成
	(defconst ecb-required-cedet-version-max '(1 1 4 9))

但是运行仍然提示错误

	Error:Symbol's value as variable is void: stack-trace-on-error

在配置文件中加入即可

	(setq stack-trace-on-error t)
