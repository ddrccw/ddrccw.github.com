---
layout: post
title: 升级app到ios6
date: 2012-12-02 22:45:29
isOriginal: true
category: iOS开发
tags:
 - ios6
 - upgrade
 - UINavigationBar
keywords: upgrade ios6 rotation 旋转 UINavigationBar
description: 
---

## 前言

手头上的项目开发时原本跑的板子是ipad2（ipad5.1.1），但考虑到客户那边到时会购买新的ipad，势必要让现阶段的代码能够在ios6上运行，故花了点时间做了一下适配工作。已下讨论到的问题仅在我的适配过程中遇到，并不涵盖升级app到ios6的全部问题。

## 正题

### 旋转

参考[RN-iOSSDK-6_0][1]，在<ios6的版本中，UIViewController类中提供`shouldAutorotateToInterfaceOrientation: `的方法告诉系统实现的VC支持什么方向的旋转。但在ios6中，旋转支持的判断则不会涉及到开发过程中的每个VC，责任更多的推到了上游。

一方面，系统会从app提供的info.plist文件和app的delegate类的`application:supportedInterfaceOrientationsForWindow: `方法中获取旋转支持的信息。当然，后者优先级大于前者。

另一方面，系统会从**root**或**top-most full-screen**的VC的`supportedInterfaceOrientationsForWindow: `和 `shouldAutorotate` 方法获取旋转支持的信息。所谓**root**，就是一定要在app delegate类中设置rootViewController。**top-most full-screen**则很有迷惑性，你可能会想当然的以为是自己在屏幕上看到的app当前全屏状态的那个VC。其实不然，如果你用了UINavigationController或其他类似的容器类时，那些容器类才是真正的**top-most full-screen**的VC。

实际适配过程中，一是我的UINavigationController本身也是位于其他自定义的容器类A中，二是实际主要展示的界面内容却又是在UINavigationController的子VC中。所以为了让app支持旋转，我需要让系统知道UINavigationController的子VC旋转支持的方向。有了思路，剩下的就好办。分别实现容器类A，UINavigationController类，显示内容的VC类的`supportedInterfaceOrientationsForWindow: ` 和 `shouldAutorotate` 方法。虽然系统只会问容器类A，但我只要从容器类A一级一级往下询问即可。

注：UINavigationController需要子类化或一个Category类才能重写那两个方法。

### 导航条自定义背景

由于项目设计需要，同一个navigationController的不同层次的导航条背景有些许不同，并且设计师提供的只是一小段图片（需要将图片平铺）。

切换背景倒是没什么问题，无非是在viewWillAppear中，利用self.navigationController.navigationBar（不是[UINavigationBar appearance]）的`setBackgroundImage:forBarMetrics: `方法更改。

但是关键的是在平铺图片的时候出了点麻烦。。。ios5中没有任何问题，在demo程序中如图1，

![alt normal](/images/posts/upgrade-to-ios6/2.1.png "正常情况")

然而在ios6中出现了诡异的问题，导航条背景出错了，如图2，

![alt weird](/images/posts/upgrade-to-ios6/2.2.png "诡异情况")

刚开始还以为是代码错了，后来经过多番排查测试，才发现问题出在图片上。一般来说设计师出的图如果不是透明的，会在保存png图片时把透明度一项去除掉，这样的图相比使用了alpha通道的图会小不少。ios6估计底层改了一些代码，由于给的图比较小，又没有alpha通道，导致出现了图2的情况。

解决方法：给图片添加上alpha通道或把可以平铺的图片尺寸加大即可。

ps：
起初，还怀疑是代码问题，顺便试了一下[UINavigationBar appearance]的`setBackgroundImage:forBarMetrics: `方法，该方法是修改全局的导航条背景，并且需要在viewDidLoad之前使用,而在viewDidLoad中使用时，不影响当前的导航条。 

### handle low memory warning

<iOS6

当内存不够时，系统会先调用didReceiveMemoryWarning，其中调用super的该方法会让系统根据当前view的情况（比如是否在屏幕上），决定释放VC的view。如果要释放view，便会依次调用viewWillUnload和viewDidUnload。一般来说，可以在viewWillUnload和viewDidUnload中释放与view相关的对象（这些对象往往可以在viewDidLoad中重新构建）。而因为在vc的view仍在屏幕上时，仍可能接收low memory warning，所以不在didReceiveMemoryWarning释放view相关的对象，但可以释放一些不重要的数据结构。

\>=iOS6

当内存不够时，系统将只会调用didReceiveMemoryWarning。根据[文档][2]
>
The memory used by a view to draw itself onscreen is potentially quite large. However, the system automatically releases these expensive resources when the view is not attached to a window. The remaining memory used by most views is small enough that it is not worth it for the system to automatically purge and recreate the view hierarchy.

view相关对象的内存管理似乎交给了系统，而didReceiveMemoryWarning依然重点关注释放那些不重要的数据结构。当然，想要显式释放view相关对象也是可以的，请参考

{% highlight objc tabsize=4 %}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Add code to clean up any of your own resources that are no longer necessary.
    if ([self.view window] == nil)
    {
        // Add code to preserve data stored in the views that might be
        // needed later.
 
        // Add code to clean up other strong references to the view in
        // the view hierarchy.
        self.view = nil;
        self.otherView = nil;  //add by me
    }
}
{% endhighlight %}
					
适配过程，只要参考上面的说明更改即可。我的app内存要求不高，所以暂时不采用显式管理的方法。

## 总结
	
总的来说，目前还算比较顺利的升级了app。另外，photoshop知识有待加强，有空需要补一补>_<

## 参考资料

1） [RN-iOSSDK-6_0][1] 

2） <http://stackoverflow.com/questions/8257556/ios-5-curious-about-uiappearance/>

3） [navi-demo](http://pan.baidu.com/share/link?shareid=154803&uk=1678482707/ "navi-demo")

4） WWDC 2012 Session 236 - The Evolution of View Controllers on iOS

5） <http://stackoverflow.com/questions/4354332/didreceivememorywarning-and-viewdidunload>

6） <http://stackoverflow.com/questions/5069978/didreceivememorywarning-viewdidunload-and-dealloc>


[1]: https://developer.apple.com/library/ios/#releasenotes/General/RN-iOSSDK-6_0/_index.html    "RN-iOSSDK-6_0"

[2]: http://developer.apple.com/library/ios/#featuredarticles/ViewControllerPGforiPhoneOS/ViewLoadingandUnloading/ViewLoadingandUnloading.html#//apple_ref/doc/uid/TP40007457-CH10-SW1
    "view controller programming guide for iOS"
