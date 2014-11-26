---
layout: post
title: Emacs中编码的转换
categories:
- EMACS
---

在Linux下的Emacs中写了文件在Windows下用Emacs看中文总是乱码的，还是编码的问题

如何解决?

- `(set-language-environment "utf-8")`

- `set-language-environment Ret utf-8 Ret revert-buffer`

- 文件中写入 `-*- coding: chinese-gb18030; -*-`
