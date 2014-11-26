---
layout: post
title: javascript中的正则
categories:
- JAVASCRIPT
---

RegExp对象的方法
- test()
- exec()
- compile()

-------------------------------------------------------------------------------

test方法检索字符串中指定值，返回值为true或是false

	var pattern=new RegExp("text");
	document.write(pattern.test("The word things text life  free")); 

输出为true

-------------------------------------------------------------------------------

exec方法检索字符串中的指定值。返回值是被找到的值。如果没有发现匹配，则返回 null。

	var pattern=new RegExp("text");
	result = document.write(pattern.exec("The word things text life  free"));
result中的内容为text

RegExp对象第二个参数是表示检索方式例如g就是搜索全部

	var pattern=new RegExp("text", "g");
	do {
		result = pattern.exec("The text things text life  free");
		document.write(result);
	} while (result != null); //null为小写，大写的不行

输出为:

	texttextnull

-------------------------------------------------------------------------------

compile用于改变RegExp

	var pattern = new RegExp("text");
	document.write(pattern.exec("The word things text life  free"));

	pattern.compile("test");
   	document.write(pattern.exec("The word things text life  free"));

输出为:

	truefalse
