---
layout: post
title: 在越狱设备上如何方便地主动更新测试版本app
date: 2014-04-13 14:02:53
isOriginal: true
category: iOS-dev
tags:
 - iOS
 - jailbreak
 - beta-test
keywords: iOS jailbreak beta-test
description: 
---

## 前言

之前有段时间申请到qq测试版本，在使用过程中，发现qq测试版本的升级过程有点小意思。看过之前写的《[再谈使用shell脚本build并创建ipa文件][0]》或者网上其他类似文章关于over-the-air分发app的应该都知道，常见的app分发需要用户跳到专门的下载页面去获取新版的app，但是qq测试版本的升级体验则不同，同样是主动提示更新，但它只要在alert上点击确定就可以马上下载安装最新的测试版本，省略了跳转的步骤。个人感觉这样在体验上蛮好，所以就尝试研究了一下。

## 正文

### 为什么

看下文之前，估计还是有人会问为什么会有这样奇怪的需求。这里我觉得还是从用户体验的角度上理解比较简单，个人觉得它可以用在如下两个地方：

1. 公测。类似qq这种用户量大的app，每个新功能的推出都可能造成比较大的影响。为了提早获得市场反馈，针对性的邀请一些使用越狱设备的用户提前使用新功能，进而获取相关的使用数据来改进最终发布的版本上的功能是有必要的。
2. 内测。相比以前需要相关的app使用者定期的去固定的页面获取最新的测试版本，主动提示更新并下载自然方便了许多，进而也就提高大家的工作效率。

上述两个需求通过app store的发布方式显然是无法满足的，一方面，app store 不会让带测试字样的app审核通过，另一方面，app store发布的速度实在不可控。。。另外，据说TestFlight支持邀请用户的功能，我没试过也就没有发言权啦:p

### 怎么做

其实最基本的原理还是over-the-air的那套机制，只不过稍微深入地挖掘一下其中的一些可控之处，权当抛砖引玉~

#### 越狱检测

关于这点，网上应该有不少文章介绍了。

1. 某女程序媛的《[越狱检测／越狱检测绕过——xCon][1]》这篇文章写得蛮好的。另外，她blog里面提到的一本书《O'Reilly.Hacking.and.Securing.iOS.Applications》如果有时间的话，应该读一读学习下。

2. 吴发伟翻译的《[iOS应用程序安全][2]》系列亦可一读。

3. 《[Bypassing Jailbreak Detection][3]》则写得比较概括点。

另外，点击[此处][4]，则是我参考几篇文章实现简单检测的一些code。

注：在6.1.x的越狱设备上，我用尝试在private目录中写入文件的方式检测似乎不行。

#### 后台服务

对移动端而言，只要明白如何发一个正确的请求即可。ipa的请求校验和传输更多的需要后台服务的支持。

其实，要实现qq那种效果的下载，最最基本的是要模拟常规安装页面那里的点击下载请求。在app中添加代码如下：

{% highlight objc tabsize=4 %}
NSString *serviceUrl = @"itms-services://?action=download-manifest&url=<plist-encoded-url>";
[[UIApplication sharedApplication] openURL:[NSURL URLWithString:serviceUrl]];
{% endhighlight %}

其他只需要沿用《[再谈使用shell脚本build并创建ipa文件][0]》中产出的相关文件及部署。那么这样看是不是很简单，如果只是内测用的话，到这里其实也就差不多了。但是从公测的角度上看，对安全比较敏感的童鞋应该不会止步于此。

**可控之处**

前面提到的可控之处，其实也就在于那个url的使用。用Charles捕捉一下请求，可以发现上述两行代码交给iOS处理后的结果，就是利用里面的url参数发了个GET请求，最终在response的body里面返回指定的plist文件。

同理，你可以发现plist里面的ipa以及icon的url也是可以操作的，其中ipa的url会发一个HEAD和一个GET请求（需要在GET请求中返回ipa包数据），icon的url则是会发一个GET请求。

既然url可以定制，相信后台童鞋也可以利用起来做检验或其他操作。

这里直接附上我写的一个简单[demo][5] :）

## 总结

总之，原理是十分简单的，但是如何换种思维来改进用户体验确实是一个值得思考的问题~

## 参考

1）[http://danqingdani.blog.163.com/blog/static/1860941952012102122847478/][1]

2）[http://wufawei.com/2013/11/ios-application-security-24/][2]

3）[http://theiphonewiki.com/wiki/Bypassing_Jailbreak_Detection "Bypassing_Jailbreak_Detection][3]


[0]: {% post_url 2013-09-16-daily-build-and-create-ipd-using-shell-script-2 %}

[1]: http://danqingdani.blog.163.com/blog/static/1860941952012102122847478/ "danqingdani.blog.163.com"

[2]: http://wufawei.com/2013/11/ios-application-security-24/ "wufawei.com"

[3]: http://theiphonewiki.com/wiki/Bypassing_Jailbreak_Detection "Bypassing_Jailbreak_Detection"

[4]: https://gist.github.com/ddrccw/8412847 "Jailbreak_Detection"

[5]: https://github.com/ddrccw/DistributionDemo "DistributionDemo"