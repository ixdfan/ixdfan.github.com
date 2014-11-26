---
layout: post
title: vs中使用def导出dll的问题
categories:
- WINAPI
---

在vs中直接在项目中添加def后是无效的，不会输出lib文件

直接在项目中添加def文件之后需要设置项目属性-配置属性-连接器-输入-模块定义文件中写入def的文件名称
