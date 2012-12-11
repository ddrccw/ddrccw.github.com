---
layout: post
title: Google Objective-C Style Guide学习笔记
date: 2012-11-25 19:10:53
isOriginal: true
category: iOS开发
tags:
 - Objective-c
 - iOS
 - Google
 - code-style
keywords: Objective-c iOS Goole code-style
description: learn from Google Objective-C Style Guide
---

##前言

之前拜读了《clean code》一书，在它的前言里看到了这样一句经典的话：

`The only valid measurement of code quality: WTF/min`

译：`衡量代码质量的唯一有效标准：WTF/min`

当时顿时就笑喷了，但静下心来一想，虽然可能有些夸张，但是也确实有道理。回想以前接手过的历史遗留代码，有看过比较厉害的前辈，纵然不使用注释，但代码看起来却也让人十分清爽。有的同一个项目但是因为有多人开发，代码风格迥异。更有甚者，即便是同一个人写的几段代码，竟然也能变异出几种风格，看的我甚是蛋疼。。。
虽然说像geek一样编码，可能是一件十分cool的事，但落实到现实团队合作中，我觉得还是要统一风格才好。毕竟，一个良好的code style也是一个程序员的基本功吧。至少，我不想让下一任接我活的兄弟因此而"记恨于我" ^_^ ~~

##正题
某天刷weibo发现[程序员的那些事](http://weibo.com/u/2093492691)推荐[《google code style》](http://code.google.com/p/google-styleguide/)，遂花点时间学习了一下 [《C++ Style Guide》](http://google-styleguide.googlecode.com/svn/trunk/cppguide.xml)，
[《Objective-C Style Guide》](http://google-styleguide.googlecode.com/svn/trunk/objcguide.xml)。

**已下仅记录部分参考借鉴的知识点**

1. 缩进，2个空格 ；行宽，80字节

	考虑到obj-c较长的命名规则，并且实际开发的代码可能来着iMac或MBP，为了照顾MBP的小屏幕，这个还是有必要的。
	
2. 文件名前缀

	一般应用程序的代码，不需要前缀，但是在多个app中会共享的代码，还是需要前缀。
	
3. 混合编程时
	
	@implementation中采用obj-c风格；实现c++类方法时采用c++风格。

4. 实例变量
	
	除了配合@property使用的实例变量延续开头带下划线的风格，其他的均采用结尾带下划线的风格。

5. 对象所有关系
	
	CoreFoundation,c++和非obj-c对象的实例变量的指针用`__strong`和`__weak`表示是否需要retain。CoreFoundation和非obj-c对象无论是否使用arc或gc，都应该显式地进行内存管理。
	
6. 保持api的简洁性

	obj-c的所有方法都是public，尽管利用private category来写method可以避免在public header暴露所有方法，但并不会让method真的变得private
	
7. 头文件引入

	obj-c/obj-c++ header用#import，标准c、c++ header用#include（为防止重复引用，设置#define guard，其命名规则为`<project>_<path>_<filename>_H_`）
	
8. 避免在init和dealloc中使用访问器
	
	因为子类实例可能在init和dealloc时存在状态的不一致
	
9. dealloc中实例变量的顺序和@interface中的顺序一致(lz是先private，再public)

10. 避免抛出obj-c的异常

	避免，但要随时准备catch第三方或系统调用抛出的异常。当写obj-c++代码中要抛出obj-c的异常时，代码中基于栈的对象不会调用析构函数，所以在obj-c++代码中要抛出obj-c异常，则不应该在@try，@catch，@final的block中包含基于栈的对象。建议在obj-c++中如果一定要抛异常，使用c++的异常。

	关于异常的使用，google似乎是从项目之间的整合考虑，可以参考
	
	[http://google-styleguide.googlecode.com/svn/trunk/cppguide.xml#Exceptions](http://google-styleguide.googlecode.com/svn/trunk/cppguide.xml#Exceptions)

11. BOOL 陷阱--这一段估计google自己没更新
	
	文档中说BOOL在obj-c中是unsigned char，但在<obj/obj.h>中发现BOOL应该是signed char，要指正一下。
	
	BOOL类型的值可以是除了YES（1）和NO（0）以外的其他值。
	
	- 根据[c99 Std 6.3.1.2](http://c0x.coding-guidelines.com/6.3.1.2.html) 
	
		`When any scalar value is converted to _Bool, the result is 0 if the value compares equal to 0; otherwise, the result is 1`

		故，BOOL与_Bool/bool可以安全转换
		
	- Boolean是unsigned char，boolean_t一般为int，均不可于BOOL安全转换
	
	基于上述两点
	
	- 逻辑运算符（&&，||，!）运算BOOL是合法的
	- 函数返回的值也必须是可以安全转换为BOOL类型的（尤其是在转换数组大小，指针，位运算结果时要注意）
	- 不要直接和YES比较BOOL类型的值



