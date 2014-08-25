---
layout: post
title: 播放器旋转问题小结
date: 2014-08-19 23:33:07
isOriginal: true
category: iOS-dev
tags:
 - orientation
keywords: orientation
description: tips on changing orientation
---


## 正题

### 问题描述

新版公开课app的iphone版只支持Portrait，但是现在的需求是要求课程详情页面里嵌着的播放器支持从小屏幕旋90度并变为全屏。

### 分析

这是一个典型的旋转相关的问题。根据具体的情况，一般可以分成两类：

1. 基于设备的系统事件通知来让页面响应旋转
	
	关于这一点，以前写过一篇[文章](http://ddrccw.github.io/2012/12/03/upgrade-to-ios6/)其实已经提到过了。关键就是对`top-most full-screen`VC的理解，这里也就不赘述了。

2. 无视设备的系统事件通知强制让页面旋转

	简单粗暴的描述一下就是即便通过设置开启竖屏锁定，也可以通过技术手段任意控制页面布局，而不受设备旋转事件的影响。
	
回到前面新版公开课描述的需求，其实也就是一个要求强制旋转的问题。再进一步细化一下要解决的问题，包括有两个方面：

1. 状态栏旋转

	参考《[RN-iOSSDK-6_0][1]》，里面有这么一段描述:
	
	>The `setStatusBarOrientation:animated:` method is not deprecated outright. It now works only if the `supportedInterfaceOrientations` method of the top-most full-screen view controller returns 0. This makes the caller responsible for ensuring that the status bar orientation is consistent.

	文中介绍到的`setStatusBarOrientation:animated:`方法，正是用来处理状态栏强制旋转滴~

2. 播放界面旋转并变为全屏

	通读一下《[IOS Orientation, 想怎么转就怎么转~~~][2]》和《[iOS旋转视图实践][3]》，基本可以确定需要通过UIView的transform来控制页面旋转方向。至于从小屏变化为全屏，显然是通过设置UIView的frame来实现。

另外需要考虑的是要保证上述两方面的变化动画时间的一致。因为UIApplication的`statusBarOrientationAnimationDuration`是只读的，因此实际的动画时间也需要以它为基准。

### 处理

经过前面的分析，解决思路也很清晰，强制旋转问题确实属于一个老生常谈的小问题。。。但是，有些时候不得不感叹“纸上学来终觉浅”，具体处理过程中如果不小心又会掉进奇怪的坑里呢。。

#### 状态栏旋转

尽管《[RN-iOSSDK-6_0][1]》里面提到使用`setStatusBarOrientation:animated:`的前提之一是`supportedInterfaceOrientations`要返回0，但是根据实际的实验，其实只要`shouldAutorotate`返回NO即可。

#### 播放器旋转并变为全屏

首先，看下接手公开课代码时看到的第一版代码，内容基本如下：

{% highlight objc %}
[UIView animateWithDuration:duration animations:^{
	CGSize size = [UIScreen mainScreen].bounds.size;
    playerView_.frame = CGRectMake(0, 0, size.height, size.width);
    self.navigationController.view.transform = CGAffineTransformMakeRotation(M_PI_2);
    CGRect frame = self.navigationController.view.bounds;
    self.navigationController.view.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.height, frame.size.width);
} completion:nil];
{% endhighlight %}

照前面的分析来说，这段代码似乎没有问题，而且正常流程下从点击课程进入课程详情页里操作播放器旋转并使之变为全屏也没出现问题，但是坑爹的是，当navigationController被present后，再操作播放器，结果竟然是navigationController转了90度，但是播放器的frame动画却没有起作用了。

由于第一版代码先入为主的影响，刚开始还为是transform作用的view不对，我又一级一级从UIWindow一直到playerView_的各层view做了transform的尝试，当然问题依然存在。。。后来过了一宿，冷静思考了一下（果然还是不能太钻牛角尖啊= =），隐约觉得transform和frame的动画相互影响了，所有也就有了下述代码：

{% highlight objc %}
[UIView animateWithDuration:0 animations:^{
	self.playerContainerView.transform = CGAffineTransformMakeRotation(M_PI_2);
} completion:^(BOOL finished) {
	[UIView animateWithDuration:duration animations:^{
		self.playerContainerView.frame = self.navigationController.view.bounds;
	}];
}];
{% endhighlight %}

上述代码解决了前面出现的问题，它和第一版的区别有：

1. 将transform和frame的动画拆到两个animate block中，这个也是最最关键的地方，虽然是看似很不起眼的一个处理，但是这里特别提一下，免得像我一样掉坑里浪费了时间。。

2. 仅对要旋转的view做transform，这里考虑的是影响最小化的问题。如果是对它的superview做transform，显然会让一些不需要旋转的view重复做layout，从而带来一些潜在的影响。另外，还有一个小注意点，因为transform的是要旋转的view，所以设置它的frame时，它的坐标系仍是以它的superview为基准的，而不是像第一版代码那种要对换height和width的值。

## 总结
	
总的来说问题不难，但是确实也让我找到一些思维痛点。看文章理解和实践起来确实是两码事，还是要多多coding啊！

## 参考资料

1） [RN-iOSSDK-6_0][1] 

2） [IOS Orientation, 想怎么转就怎么转~~~][2]

3） [iOS旋转视图实践][3]


[1]: https://developer.apple.com/LIBRARY/ios/releasenotes/General/RN-iOSSDK-6_0/index.html    "RN-iOSSDK-6_0"

[2]: http://www.cnblogs.com/jhzhu/p/3480885.html “IOS Orientation, 想怎么转就怎么转~~~”

[3]: http://rdc.taobao.org/?p=408 “iOS旋转视图实践”
