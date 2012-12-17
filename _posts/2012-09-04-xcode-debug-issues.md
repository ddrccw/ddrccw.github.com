---
layout: post
title: iOS开发过程中常见的debug技巧
date: 2012-09-04 16:21:55
isOriginal: true
category: iOS-dev
tags:
 - iOS
 - debug
 - gdb
 - lldb
 - Xcode
keywords: iOS debug gdb lldb Xcode
description: Xcode debug issues
---

## 前言

记得刚学ios那会儿，我还不会用debug工具。编程时，最痛苦的莫过于程序莫名其妙的在main函数crash，其中，SIGABRT、EXC_BAD_ACCESS、Assertion failure等情况居多。虽然也看了一些资料，但是一直也没怎么系统的整理过相关知识，故特此整理一下。

## 正文

虽然有高手可以纯粹用[gdb][]直接调试，但我等菜鸟还是利用一下Xcode的提供的图形界面，保证一下工作效率:P

### 1 异常捕捉

想必这也是最最基本的步骤，在Xcode导航栏找到断点导航栏，如图添加Exception breakpoint

![alt exception](/images/posts/xcode-debug-issue/1.1.jpeg "exception")

如果想有针对性的步骤异常，比如Objective-C exception，可以如图添加symbolic breakpoint

![alt symbolic](/images/posts/xcode-debug-issue/1.2.jpeg "symbolic")

有了上述的操作，大部分的crash都会定位到相应的代码位置。

### 2 巧用寄存器参数

在汇编语言中，[Function prologue](!http://en.wikipedia.org/wiki/Function_prologue)会准备好函数要用到的栈和寄存器，而寄存器中包含有传递给函数的参数信息。我们可以利用这部分信息进一步诊断异常。

到目前为止，由于iOS 模拟器是以i386（32位）模式运行在os x系统上，而iOS设备是基于arm结构的处理器，
参考[官方文档](http://developer.apple.com/library/ios/#technotes/tn2239/_index.html)和[这篇文章][1]，我们可以在gdb或lldb中print一些信息

|                | arm | i386 (before prolog)	| i386 (after prolog) 
| -------------- | --- | ------------| ------- 
| previous frame | po $lr | - | po \*(id\*)($ebp) 
| return address / receiver | po $r0 | po \*(id\*)($esp) | po \*(id\*)($ebp + 4) 
| 1st parameter / SEL  | p (SEL)$r1 | p \*(SEL\*)($esp + 4) | p \*(SEL\*)($ebp + 8) 
| 2nd parameter  | po $r2 | po \*(id\*)($esp + 8) | po \*(id\*)($ebp + 12) 
| 3rd parameter  | po $r3 | po \*(id\*)($esp + 12) | po \*(id\*)($ebp + 16) 
| ... and so on  | po \*(id\*)($sp + 4n) n>=0 | po \*(id\*)($esp + 4n) n>=4 | po \*(id\*)($ebp + 4n) n>=5 


另外，函数返回的结果也会保留在寄存器中，在arm和i386中分别对应($r0)和（$eax）。

上述的寄存器（$r0或$eax）中，可能的情况（仅涉及我遇到过的情况）是

* 一个NSException

	在gdb或lldb中，尝试一下`po [$reg]` 或访问相关属性 `po [$reg class]` 、`po [$reg name]`、 `po [$reg reason]`

* 一些状况的描述

	以我在给项目添加GHUnit做单元测试的过程中遇到的问题为例，当我自以为已经成功引入GHUnit，尝试运行相应的Target时，Xcode直接在main.m中报错
	
	`Assertion failure in int UIApplicationMain(int, char **, NSString *, NSString *)(), /SourceCache/UIKit_Sim/UIKit-1912.3/UIApplication.m:1601`

	咋看之下，确实没啥头绪，只知道这里有问题，当我在终端输入
`po $eax`后，便显示出详细的原因:

	`(unsigned int) $2 = 109471968 Unable to instantiate the UIApplication delegate instance. No class named GHUnitIOSAppDelegate is loaded.`

	通过这个提示，我才想起来忘记添加编译链接需要的-ObjC -all_load

### 3 系统环境变量使用

#### 1） BSD提供的debug辅助功能

比较常用的是MallocStackLogging

>
Record backtraces for each memory block to assist memory debugging tools; if the block is allocated and then immediately freed, both entries are removed from the log, which helps reduce the size of the log

它主要提供的是memory allocator的相关信息，你也可以`man malloc`查看其他环境变量的应用。

#### 2） obj-c Foundation提供的debug辅助功能

比较常用的是NSZombieEnabled，设为YES，则可以很容易debug给一个已经释放的对象发送消息有关的问题。
原理嘛，就是让deallocated的对象并没有真正的被deallocated，从而让系统能够检测到zombie对象，而执行断点指令。

适用条件：
>NSZombieEnabled also affects Core Foundation objects as well as Objective-C objects. However, you'll only be notified when you access a zombie Core Foundation object from Objective-C, not when you access it via a CF API.

#### 3）实践应用

Xcode中，如图1，在xcode菜单栏->product->edit scheme，可以添加相应的环境变量

![alt env](/images/posts/xcode-debug-issue/3.1.jpeg "env")

或如图2，也可以在Diagnostics中直接勾选相应的选项

![alt Diagnostics](/images/posts/xcode-debug-issue/3.2.jpeg "Diagnostics")

实际开发过程中，EXC_BAD_ACCESS，objc_msgSend相关的crash往往可以利用上述的两个环境变量检测问题。例如下述代码

{% highlight objc %}
NSObject *o = [NSObject new];  
NSMutableArray *test = [[NSMutableArray alloc] initWithCapacity:1];
[test release];
[test addObject:o];
[o release];
{% endhighlight %}

开启NSZombieEnabled，可以获得信息：

`2012-09-04 17:21:55.925 test[1705:11303] *** -[__NSArrayM addObject:]: message sent to deallocated instance 0x741fc40`

开启MallocStackLogging，在gdb（不是lldb）终端输入

`shell malloc_history 1786 0x741fc40  --1786 "app_pid"; 0x741fc40 "deallocated instance"`

就可以获得一份有关malloc的详细信息。

### 4 进阶操作

看了前面提到某高手[gdb][]调试过程，你应该也了解了gdb的强大，想熟练使用gdb的相关命令，请参看：

<http://sourceware.org/gdb/download/onlinedocs/gdb/index.html>

另外，Xcode默认使用lldb也很强大，这里也提供一个gdb和lldb的命令对照表

<http://lldb.llvm.org/lldb-gdb.html>

最后，apple提供的测试工具也给我们能够可视化调试提供了不少便利

<http://developer.apple.com/library/ios/#DOCUMENTATION/DeveloperTools/Conceptual/InstrumentsUserGuide/Introduction/Introduction.html>



## 总结

要真真正正的做好debug的方方面面也不是一件容易的活儿。虽然可能%20的手段，足以应付你的编程任务（至少对我来说是这样的），但是剩下的%80了解一下也无妨，肯定是有所裨益的 ^_^

## 参考资料

1） [iOS Debugging Magic](http://developer.apple.com/library/ios/#technotes/tn2239/_index.html)

2） <http://cocoadev.com/wiki/NSZombie>

3） [objc_explain_So_you_crashed_in_objc_msgSend](http://sealiesoftware.com/blog/archive/2008/09/22/objc_explain_So_you_crashed_in_objc_msgSend.html)

4） [http://www.clarkcox.com/blog/2009/02/04/inspecting-obj-c-parameters-in-gdb/][1]

5） <http://www.raywenderlich.com/10209/my-app-crashed-now-what-part-1>

[1]: http://www.clarkcox.com/blog/2009/02/04/inspecting-obj-c-parameters-in-gdb/

[gdb]: http://www.mikeash.com/pyblog/friday-qa-2011-06-17-gdb-tips-and-tricks.html "gdb"