---
layout: post
title: 客户区坐标转换为屏幕坐标
Categories:
- WINAPI
---

	void OnButtonUp(HWND hWnd, UINT nMsg, WPARAM wParam, LPARAM lParam)
	{
		//创建弹出式菜单
		HMENU hPopMenu = CreatePopupMenu();
		//增加菜单项
		AppendMenu(hPopMenu, MF_STRING, 1001, L"测试");
		AppendMenu(hPopMenu, MF_SEPARATOR, 0, NULL);
		AppendMenu(hPopMenu, MF_STRING, 1002, L"退出");
		
		POINT point = {0};
		//获取客户区坐标
		point.x= LOWORD(lParam);
		point.y= HIWORD(lParam);
		//转化成屏幕位置
		ClientToScreen(hWnd, &point);
	
		//显示菜单,x,y坐标是对于屏幕的坐标
		TrackPopupMenu(hPopMenu, TPM_LEFTALIGN, point.x, point.y, 0, hWnd/*需要哪个窗口处理*/, NULL);
	
	}
	
