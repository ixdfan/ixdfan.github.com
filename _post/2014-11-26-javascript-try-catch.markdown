---
layout: post
title: javascript中的try与catch
categories:
- JAVASCRIPT
---


javascript中的try与c++中的有点不同，结构如下:

	try {
	//可能发生错误的代码
	}
	catch(err) {  //err不能少
	document.write(err.description);
	}


实例代码

	<html>
		<head>
		
		<script type="text/javascript">
		var txt=""
		
		function message()
		{
		try {
			/* 本来应该是alert的，不小心写成了abclert了 */
		   abclert("Welcome guest!")
   		}
		
		catch(err) {
		   txt="本页中存在错误。\n\n"
		
		   txt+="错误描述：" + err.description + "\n\n"
		
		   txt+="点击“确定”继续。\n\n"
		
		   alert(txt)
		}
		
		}
		
		</script>
		</head>
		
		<body>
		    <input type="button" value="查看消息" onclick="message()" />
		</body>
	</html>
	

如果 confirm 方法的返回值为 false，代码会把用户重定向到其他的页面。如果 confirm 方法的返回值为 true，那么代码什么也不会做。


<html>
	<head>
	<script type="text/javascript">
	var txt=""
	
	function message() {
	
	try {
	  adddlert("Welcome guest!")
	}
	
	catch(err) {
	
	  txt="There was an error on this page.\n\n"
	
	  txt+="Click OK to continue viewing this page,\n"
	
	  txt+="or Cancel to return to the home page.\n\n"
	
	  if(!confirm(txt)) {
	    document.location.href="http://www.ucshell.com/"
	    }
		
	  }
	}
	</script>
	
	</head>
		<body>
		<input type="button" value="View message" onclick="message()" />
		</body>
	</html>

-------------------------------------------------------------------------------

利用throw来创建异常
	
	<html>
	
	<body>
	<script type="text/javascript">
	var x=prompt("Enter a number between 0 and 10:","")
   	try {

	if(x>10) 
		throw "Err1"
	else if(x<0)
		throw "Err2"
	} 

	catch(er) {

	if(er=="Err1") 
		alert("Error! The value is too high")

	if(er == "Err2") 
		alert("Error! The value is too low") 
   	}
	
	</script>
	</body>

	</html>
	


