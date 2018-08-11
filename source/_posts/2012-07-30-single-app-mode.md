---
layout: post
title: single app mode
date: 2012-07-30 14:18:00
isOriginal: true
category: iOS-dev
tags:
 - iOS
 - IPCU
keywords: iOS IPCU
description: single app mode
---


所谓的single app mode, 就是让iOS设备只运行指定的app，同时让物理的home键失效, 让使用者无法退出相应的app。咋看之下，或许这种模式显得很不符合用户的使用习惯。但具体考虑还是存在适合使用这种mode的情况，如企业用户app，教育类app, 信息展示app或儿童使用的app。

[iOS 6][1]已经准备提供Guided Access，其描述如下：

>iOS 6 comes with even more features to make it easier for people with vision, hearing, learning, and mobility disabilities to get the most from their iOS devices. Guided Access helps students with disabilities such as autism remain on task and focused on content. It allows a parent, teacher, or administrator to limit an iOS device to one app by disabling the Home button, as well as restrict touch input on certain areas of the screen. VoiceOver, the revolutionary screen reader for blind and low-vision users, is now integrated with Maps, AssistiveTouch, and Zoom. And Apple is working with top manufacturers to introduce Made for iPhone hearing aids that will deliver a power-efficient, high-quality digital audio experience.

那么iOS 6之前的版本按理说应该没有提供这种模式，然而去apple体验店看看其ipad上展示产品信息的app，你会纳闷得发现它确实很像前面提到的single app mode，难道其中有什么玄机，带着这个疑问，我开始在网上搜寻答案。

经过一番搜索，在万能的stackoverflow上，确实有达人给出了一些线索。

## 1. disable home button##
首先，这里需要了解《应用程序分发和部署问题》中提到的 iphone 配置实用工具（IPCU）以及配置描述文件的概念。

然后，准备好配置文件, 因为在此主要关注如何disable home button，所以暂且取名为[disable_home_button.mobileconfig][4]， 内容如下：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"]]>
	<dict>
	    <key>PayloadContent</key>
		<array>
			<dict> 
				<key>PayloadDescription</key>            
				<string>Disables home</string>
				<key>PayloadDisplayName</key>
				<string>Home Button Lock</string>
				<key>PayloadIdentifier</key>
				<string>com.myorg.kiosk</string>
				<key>PayloadOrganization</key>
				<string>My Org</string>
				<key>PayloadType</key>  
				<string>com.apple.defaults.managed</string>
				<key>PayloadUUID</key>
				<string>B2D02E2D-BAC5-431B-8A29-4B91F71C9FC1</string>
				<key>PayloadVersion</key>
				<integer>1</integer>
				<key>PayloadContent</key>
				<array>
					<dict>                    
						<key>DefaultsDomainName</key>
						<string>com.apple.springboard</string>
						<key>DefaultsData</key>
						<dict>                    
							<key>SBStoreDemoAppLock</key>
							<true/>                    
						</dict>
					</dict>
				</array>
			</dict>
		</array>
		<key>PayloadDescription</key>
		<string>Disables Home Button</string>
		<key>PayloadDisplayName</key> 
		<string>Home Button Lock</string>
		<key>PayloadIdentifier</key>
		<string>com.myorg</string>    
		<key>PayloadOrganization</key>
		<string>My Org</string>
		<key>PayloadType</key>
		<string>Configuration</string>
		<key>PayloadUUID</key>  
		<string>614D1FE3-F80D-4643-AF6B-D10C4CC8737A</string>
		<key>PayloadVersion</key>    
		<integer>1</integer>
	</dict>
</plist>
```

由于该配置文件中包含有IPCU不能处理的payload项，所以配置文件的部署要通过其他途径，较为可行的是《应用程序分发和部署问题》中提到的 over-the-air 分发profile and configuration。

ps：

1 具体的项目中，为了防止配置项被移除，最好通过加密只允许授权移除。具体的加密相关payload项，参考[Enterprise_Deployment_Guide][2]

2 移除该配置描述文件，需要通过IPCU，或重启进入General再移除


最后，安装mobileconfig后，需要重新启动设备，在运行相应的app。

注意：上述步骤只是保证了运行一个app后，无法通过home键回到springboard。所以部署时，不要运行不相关的app。一旦运行错了，需要重新启动，进行相关操作。


## 2. app crash的处理##

### 2.1 可行的方案探讨###

一中提到的方法，只是disable home button，而app crash的情况毕竟在所难免。就算经过一的处理，app crash后仍然能回到springboard。所以为了保证，始终运行一个app，需要寻求一种方案，在app crash之后能重新启动app。其中就需要了解custom url scheme。利用一个restart app来[重启][3]crash 的app。

![alt illustration](/images/single-app-mode.png "crash 处理概图")

>Armed with this simple idea, the implementation is straightforward:
>
>   1. Register the “restart” protocol in the Trampoline app.
>   2. In the Kiosk app’s crash handler, launch the restarter:
>
>		[sharedApp openURL:[NSURL URLWithString:@"restart://"]]
>   3. In the Trampoline app (e.g. in -viewDidAppear:), relaunch the crashed app:
>
>		[sharedApp openURL:[NSURL URLWithString:@"mykioskapp://"]]

### 2.2 crash的捕捉###
   
**//todo**


*****

## 参考文献:##

1) [iOS 6的介绍][1]

2) [企业开发部署指南][2]

3) [app开发高级技巧][3]

4) [http://stackoverflow.com/questions/5011774/lock-down-iphone-ipod-ipad-so-it-can-only-run-one-app/8994690#8994690][4]

5) [http://zchristopoulos.com/2012/02/how-to-disable-ipad-home-button-kioskstore-demo-mode/][5]

6) [https://blog.compeople.eu/apps/?p=275][6]


[1]: http://www.apple.com/ios/ios6/    "iOS 6"
[2]: http://manuals.info.apple.com/en_US/Enterprise_Deployment_Guide.pdf   "企业开发部署指南"
[3]: http://developer.apple.com/library/ios/#documentation/iphone/conceptual/iphoneosprogrammingguide/AdvancedAppTricks/AdvancedAppTricks.html#//apple_ref/doc/uid/TP40007072-CH7-SW50    "app开发高级技巧"
[4]: http://stackoverflow.com/questions/5011774/lock-down-iphone-ipod-ipad-so-it-can-only-run-one-app/8994690#8994690
[5]: http://zchristopoulos.com/2012/02/how-to-disable-ipad-home-button-kioskstore-demo-mode/
[6]: https://blog.compeople.eu/apps/?p=275

