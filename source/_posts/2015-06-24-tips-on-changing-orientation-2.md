---
layout: post
title: 再谈iOS旋转视图开发
date: 2015-06-24 13:22:22
isOriginal: true
category: iOS-dev
tags:
 - iOS
 - orientation
 - rotation
keywords: iOS rotation 旋转
description: 云课堂，公开课，中国大学mooc播放学习页面三种旋转方式的实现讨论

---

## 前言

经过了[云课堂][1]，[公开课][2]，[中国大学mooc][3]三种旋转需求的考（zhe）验（mo），也踩过了好多坑。虽然之前有写过一篇[文章][4]已经小结过一些问题，但现在再读，感觉还探讨地不够，故又补上一篇，希望能就此彻底做个了结。当然，也希望读过此文的童鞋能少走些弯路。。

注：此文提到的旋转包括页面和状态栏

## 正题

### 3种需求

3个app的旋转需求实现难度可以说是从易到难。

#### 云课堂

云课堂的需求和实现最简单。相信大部分的app都是这个需求。

需求：进入播放页面默认横屏，同时支持页面自动旋转。

实现：因为是基于设备的系统事件通知来让页面响应旋转，所以关键是只要设置好`- (BOOL)shouldAutorotate`、`- (NSUInteger)supportedInterfaceOrientations`、`- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation`等几个函数即可。

#### 公开课

公开课的需求和实现较云课堂来说要求要高一些。

需求：旋转的控制交给用户选择，而不是受系统控制。

实现：属于要无视设备的系统事件通知强制让页面旋转，具体可以参看[前文][4]

#### 中国大学mooc

中国大学mooc的要求最高，是上述两种情况的结合体

需求：

1. 进入播放页面默认横屏，同时支持页面自动旋转;

2. 页面旋转不受系统自带的竖排锁定按钮控制，但是用户可以锁定旋转方向。

实现：

本质上来讲，它的实现是公开课方案的加强版。同样要无视设备的系统事件，而且是基于自定义的设备事件通知页面强制旋转。

强制旋转方式同公开课，但是实际开发过程中未遇到[前文][4]提到的需要强制把transform和frame的动画拆到两个animate block的问题，囧rz。。。关于自定义设备旋转通知，利用core motion来检测计算，具体代码是基于网上找的某段代码改的（抱歉忘了原作者是谁。。），代码查看请猛击[这里](https://github.com/ddrccw/CCRotation/blob/master/CCRotation/CCRotation/UIViewController%2BCCRotation.m)。

### 一个坑引发的系列惨案

前面概述了我经历过的一些开发需求，下面重点讲一下我在开发过程中遇到的一个坑。

#### 坑

相信开发过强制旋转的童鞋，应该都遇到过这么一个令人抓狂的问题：

原本在iOS8之前都是运行正常的代码，在iOS 8上运行强制旋转过后，屏幕的部分区域不能响应你的touch（没错，就是有些区域的按钮不能点了。。）。情况如图(别人画的)：

![alt normal](/images/tips-on-changing-orientation-2/problem.png "fuck")

在stackoverflow上一搜，也可以搜出一堆，比如[这个][5]，[这个](http://stackoverflow.com/questions/26037472/uiwindow-with-wrong-size-when-using-landscape-orientation)，还有[这个](http://stackoverflow.com/questions/25963101/unexpected-nil-window-in-uiapplicationhandleeventfromqueueevent)。

一度也怀疑是否是自己的代码哪里写的不对。直到官方贴出iOS 8.3的这个[升级说明](https://support.apple.com/kb/DL1806?locale=zh_CN)，基本可以确信这个是iOS 8.3以前的系统bug（iOS 8 bug好多？！也难怪iOS 9要专注于系统稳定性和优化）

那么，直接用iOS 8以前的代码，在iOS8.3之后的系统上是不是直接运行也就没有问题了呢？答案是否定的。因为iOS 8以前，window的frame和StatusBarOrientation无关，始终都是Portrait的，但是iOS 8以后window的frame和StatusBarOrientation有关，会随着StatusBarOrientation的变化而变化。如果你用到了window的frame，那么必然还是会有影响的。

这里我做了一个[demo][7]，大家可以在iOS(-∞,8), [8, 8.3), [8.3, +∞)这三种情况的系统上运行一下，体会一下这个坑。。。

#### 思路

既然知道坑的存在，那么又该如何解决呢？

1. A模式（window-viewController-view）

	一般来说，待旋转的页面往往在window(无论是默认的window，还是你自己创建的window)下某个viewController内，而上述的bug也是发生在这种情况下。

2. B模式（window-view）

	偶然的一次搜索让我看到这个[帖子][6]，有人提到直接把待旋转的页面`addSubview`到window中（注：不要设置rootViewController）,可以避免出现上述的bug。我在[demo][7]中试了一下确实如此，然而遗憾的是，该方案反而会在[8.3, +∞)的系统上出现点击区域不全的问题。。。

总之，我表示目前我还找不到一个简单的通用方法。。以下是我觉得设计代码时，可以考虑的思路

![alt normal](/images/tips-on-changing-orientation-2/mind.png "mind")

**也就是说，保证强制旋转可行性的问题，是在保证全部区域可点的前提下，同时考虑是否要需要旋转状态栏的问题。要根据实际需求，针对不同的系统版本写兼容性代码。**

#### 连锁反应

1. `- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation`的影响。A模式下旋转页面和状态栏。如果是整个viewController被present，那么它在dimiss前，要保证状态栏的方向和`- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation`一致，否则在[8, 8.3)会发现dismiss后presentingViewController的方向会受影响。可以在[demo][7]试试哦+_+
2. alert view的展示和状态栏的方向有关。如果你仅需要旋转页面而不转状态栏只是隐藏，那么在A模式下旋转了页面后，alert view的展示会是个问题。
3. 如果alert view是定制的，那么请同时考虑1，2问题所带来的影响。对于前者，取决于你的alert view是否需要支持`preferredInterfaceOrientationForPresentation`;对于后者，你要让你的alert view判断好它所处的当前viewController的真实展示方向，不能简单通过状态栏判断哦。

## 总结
	
要想获得旋转问题（尤其是强制旋转）的完美解决，目前我觉得需要一定的开发成本，所以应该需要根据需求做出一点取舍吧^_^

## 参考资料


1） [http://stackoverflow.com/questions/28684976/ios8-how-to-show-a-different-view-controller-when-the-phone-rotates-to-landscap?lq=1][5] 

2） [http://forum.unity3d.com/threads/problem-with-changing-screen-orientation.274056/][6]

[1]: https://itunes.apple.com/cn/app/wang-yi-yun-ke-tang-for-iphone/id880452926?mt=8

[2]: https://itunes.apple.com/cn/app/id415424368?mt=8

[3]: https://itunes.apple.com/cn/app/id977883304

[4]: https://ddrccw.github.io/2014/08/19/2014-08-19-tips-on-changing-orientation/

[5]: http://stackoverflow.com/questions/28684976/ios8-how-to-show-a-different-view-controller-when-the-phone-rotates-to-landscap?lq=1

[6]: http://forum.unity3d.com/threads/problem-with-changing-screen-orientation.274056/

[7]: https://github.com/ddrccw/testRotate
