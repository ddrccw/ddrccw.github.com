---
layout: post
title: unit testing in xcode
date: 2013-04-07 09:38:52
isOriginal: true
category: iOS-dev
tags:
 - Unit-testing
 - iOS
 - OCUnit
 - GHUnit
 - OCMock
keywords: Unit-testing iOS OCUnit GHUnit OCMock 
description: unit testing in xcode
---

## 前言

每次在xcode上建立一个new project，都会看到一个选项提示是否"Include Unit tests"。基于一些考虑，我也确实未在项目中使用过。如今，随着我开发学习的深入，一方面了解了一些TDD的概念，另一方面也确实在一些开源项目(如asi-http-request)中看到Unit test的身影。看来似乎有必要学习一下iOS开发的一些unit test知识，故也就有了此文。

## 正文

参考iOS开发单元测试的入门文章《[unit-testing-in-xcode-4-quick-start-guide][1]》，主要有两个比较常见的框架：OCUnit和GHUnit。另外还有一个单元测试中专门用于Mock对象的OCMock。下面容我一一道来。

### OCUnit

OCUnit是apple官方的单元测试框架，它的优点就是和xcode集成较好；缺点嘛，就是每次cmd+U执行test，所有的用例都会跑一遍，并且缺少相应的界面进行管理（只是在终端中输出）。试想一下，如果用例很多，开发过程中有时候只是反复跑某个case，而你需要在终端的所有输出中找那个case的结果，肯定会比较不方便。

#### 关于使用

可以参看《[Xcode Unit Testing Guide][2]》,OCUnit提供两种单元测试

1. Logic tests，顾名思义，只是测试代码逻辑，无关界面元素

	>These tests check the correct functionality of a unit of code by itself (not in an app). With logic tests you can put together specific test cases to exercise a unit of code. You can also use logic tests to perform stress-testing of your code to ensure that it behaves correctly in extreme situations that are unlikely in a running app. These tests help you produce robust code that works correctly when used in ways that you did not anticipate.

2. Application tests，appdelegate是有值的, app是运行状态的，所以可以测试ui的变化等

	>These tests check units of code in the context of your app. You can use application tests to ensure that the connections of your user-interface controls (outlets and actions) remain in place, and that your controls and controller objects work correctly with your object model as you work on your app. You can also use these tests to perform hardware testing, such as getting the location of the device on which your app is running.

**注意点**

1. Logic tests和Application tests针对模拟器都是可以进行的，但Logic tests在真机设备上是无法进行的。

2. 在给项目添加单元测试时，尽管可以单独为单元测试建立一个scheme，测试人员可以只关注针对该scheme编写测试用例。但开发人员使用单元测试时，更倾向于在项目自身的scheme中包含单元测试模块，如图

	![alt scheme](/images/unit-testing-in-xcode/scheme.png "scheme")
	
	在项目的scheme中添加单元测试的target依赖关系，这样就省的要在单元测试和项目的scheme之间进行频繁切换。
      
3. 添加application tests的target后，一定要记得设置该target的building setting
	* Bundle Loader的值

		+ iOS: $(BUILT_PRODUCTS_DIR)/\<app_name\>.app/\<app_name\>

		+ Mac: $(BUILT_PRODUCTS_DIR)/\<app_name\>.app/Contents/MacOS/<\app_name\>

	* Test Host的值
	
		$(BUNDLE_LOADER)

	设置好后，编译测试用例时就不用在build phases->compile sources里添加所有与用例有关的code文件，只需添加有直接关系即用例中用到的对象结构代码。

### GHUnit

[GHUnit]是第三方的开源框架。一方面它弥补了之前提到的OCUnit的不足之处，单元测试时它提供了一个专门的界面来管理测试用例。可以一次只运行某个case。另一方面，它还提供其他的一些强大功能，比如可直接在终端命令行进行单元测试。

引入GHUnit可以参考[文档][3], 下述两点千万不能遗漏：

* 因为GHUnit自带了一个界面来显示Unit Test，需要删除xxxxTests目录下的AppDelegate.h/.m,另外还需要修改其中的main.m 

	+ 删除 #import "AppDelegate.h"

    + 修改
    
		`return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class])); `
    	

		为
    	

		`return UIApplicationMain(argc, argv, nil, @“GHUnitIOSAppDelegate”);`
    	
* 在xxxxTest Target的Building Setting中的Other Linker Flags中添加-ObjC -all_load

还有一点是文档中未写明的，但实际引入过程中会报的问题：

```bash
Undefined symbols for architecture i386:
  "_CACurrentMediaTime", referenced from:
      _GHRunForInterval in GHUnitIOS(GHTestUtils.o)
      _GHRunUntilTimeoutWhileBlock in GHUnitIOS(GHTestUtils.o)
ld: symbol(s) not found for architecture i386
clang: error: linker command failed with exit code 1 (use -v to see invocation)
```
    
只要添加QuartzCore.framework即可。

ps:直接利用源码build framework

* `git clone https://github.com/gabriel/gh-unit.git`
* 在`gh-unit/Project-iOS/`下make，build的framework位于`gh-unit/Project-iOS/build/Framework/GHUnitIOS.framework`

#### 关于使用

* 测试用例的写法可以参考`gh-unit/Tests`中的写法，还有《[guide_testing Document][4]》，

* 利用终端make test时，可能遇到的问题和处理，可参考[issue 96][5]

* 有得必有失，GHUnit无法和OCUnit一样利用bundle loader，需要在其Target->Build Phases->Compile Sources中引入所有与测试用例有关的项目代码。

### OCMock

[Mock Object]技术是单元测试里的一种常见技术。简单的理解就是，在test某块代码逻辑时，通过方便的Mock代码逻辑所依赖的外部对象（可以是未开发完的），进而减少依赖，让测试者能更专注于测试待测试的单元。OCMock则是objective-c开发中对[Mock Object]的一种实现。

引入OCMock，请移步参看[官网](http://ocmock.org/ios/ "ocmock")。如果没耐心看的话，iOS中使用OCMock也可以参考下面的流程：

1. 可以[down](http://ocmock.org/download/)一份库文件或选择运行git目录Tools里的build.rb，在Products目录下可以找到build出的库文件。
2. 在用于Test的Target中添加OCMock的头文件（Header Search Path）和OCMock的静态库。
3. 同样需要在Other Linker Flags中添加-ObjC -all_load（其实官方文档推荐用-force_load, 能指定路径载入，详情请见《[Apple's Technical Q&A QA1490](http://developer.apple.com/library/mac/#qa/qa1490/_index.html "Apple's Technical Q&A QA1490")》）

#### 关于使用

因为我的经验也不是很多，就先简单引用下[OCMock作者](http://erik.doernenburg.com/2008/07/testing-cocoa-controllers-with-ocmock/ "Testing Cocoa Controllers with OCMock")总结的一种应用模式吧 :)

>
>In summary, testing controllers becomes relatively easy when we follow this pattern:
>
>1. Replace all UI elements with mocks; using key-value coding to access the outlets.
>2. Set up stubs with return values for UI elements that the controller will query.
>3. Set up expectations for UI elements that the controller should manipulate.
>4. Invoke the method in the controller.
>5. Verify the expectations.

## 参考文档

1）[http://www.raywenderlich.com/3716/unit-testing-in-xcode-4-quick-start-guide][1]

2）[Xcode Unit Testing Guide][2]

3）[GHUnit docs][3]

4）[GHUnit guide testing][4]

5）[Command Line Tests Fail -- Xcode 4.5][5]

6）[Building Objective-C static libraries with categories][6]


[1]: http://www.raywenderlich.com/3716/unit-testing-in-xcode-4-quick-start-guide "unit-testing-in-xcode-4-quick-start-guide"

[2]: http://developer.apple.com/library/mac/#documentation/developertools/Conceptual/UnitTesting/00-About_Unit_Testing/about.html#//apple_ref/doc/uid/TP40002143-CH1-SW1 "Xcode Unit Testing Guide"

[3]: http://gabriel.github.io/gh-unit/docs/ "GHUnit docs"

[4]: http://gabriel.github.com/gh-unit/docs/appledoc_include/guide_testing.html "guide testing"

[5]: https://github.com/gabriel/gh-unit/issues/96 "issues"

[6]: http://developer.apple.com/library/mac/#qa/qa1490/_index.html "Building Objective-C static libraries with categories"

[GHUnit]: https://github.com/gabriel/gh-unit "GHUnit"
[Mock Object]: http://en.wikipedia.org/wiki/Mock_object "Mock Object"



