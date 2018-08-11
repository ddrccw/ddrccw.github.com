---
layout: post
title: 再谈使用shell脚本build并创建ipa文件
date: 2013-09-16 00:05:41
isOriginal: true
category: iOS-dev
tags:
 - shell
 - ipa
 - daily build
 - iOS
 - build setting
keywords: shell ipa daily build iOS
description: 再谈使用shell脚本build并创建ipa文件
---

## 前言

关于这个话题，其实在《[使用shell脚本build并创建ipa文件][0])》一文中已经记录过一次。之所以老调重弹，也是因为在新项目的使用过程中，发现那个脚本尚有改进的余地。

## 正文

首先，要感谢lexrus的[ios-makefile][2]项目，里面确实有不少可以借鉴学习的地方。虽然那个项目提供的脚本包含了一些蛮有用的功能，但是结合到我现在做的项目，还是有些不能满足我的需求。本来想偷懒直接用来着，看来还是得改改orz。。

### 需求

**基本的需求**

就是[前文][0]所实现的内容：能够从代码产出一份ipa，并且能通过相应的web页面安装。

**额外的需求**

随着app的版本升级，用户群中是可能同时存在多个版本的。因为不像企业类型app，可以通过MDM强制客户端升级，而且强制升级的体验不是很好，所以用户客户端的版本升级是不可控的，开发以及测试人员能保障的就是让版本升级后app能够正常使用，因而，挨个的从历史版本升级到最新版本的测试是必要的。但是app一但提交到app store，历史版本就不见了，所以不能指望app store，需要在每次完成一次版本后，做一份ipa等文件的快照，方便后续的升级测试。

总之一句话概括需求，就是需要做简单的版本分发管理。

### 解决方案

针对第一个需求，网上找的大部分脚本基本够用。

针对第二个需求，其实思路也很简单，就是多维护一个页面入口，提供对历史版本的访问。

下面记录一下我在实际项目中采用的解决方案。

a) 为了方便管理，我直接通过我的开发机搭建web服务。感谢ML自带Apache HTTP Server，搭建web服务很简单。这里推荐一个小工具[web sharing][3]，我就直接通过它来开关web服务:)

b) 将[这里][1]的3个文件，放到项目的目录下，配置好里面的相关参数。运行makefile里的命令，顺利的话，最后会在web服务的目录下看到如下结构：

```
	<webRoot>/
		<project_name>/                 #测试   最新版本
		<project_name-distribution>/    #线上
									<Vx.x.x>/   #历史版本
									latest/     #最新版本
```
	
在项目中，我习惯分发两类的ipa。一类是单纯利用测试环境数据的版本，另一类就是接近或直接使用线上环境数据的版本。只有对后者我会每次在上线后用稳定代码编译一份留存。
	
c) 最后将其编译结果提示的url告诉测试的小伙伴们，步骤基本也就差不多啦。

**ps：关于那3个文件的介绍**

a. package.sh 

	核心文件，包含编译，打包，生成html页面，以及将最终产出的文件部署到对应目录的功能
		
b. Makefile
	
	基于package.sh的一组命令。
		
c. package.plist
		
	因为分发的两类ipa可以是不同的sheme编译出来的，为了方便同步两个scheme的通用信息，比如version number和build number，所以就考虑使用这个公共的plist文件来共享。

## 引申

1. 使用scheme，build setting编译不同版本
	
	虽然默认的项目模板是一个target对应两套configurations来管理，但是开发过程中总觉得快速切换debug和release还是不怎么方便，所以我采用的是至少通过两个scheme的方式，分别对应debug和release，前者可能会加入一些类似DCIntrospect这种用来专门调试用的第三方库，后者则是保证代码最精简地引入。 另外说是“至少”，是考虑到可能还有其他的需求需要单独使用scheme。不过这里还有个小坑，就是添加新代码文件的时候，可能忘了在相应的target中添加(使用release版本bug bash过程中出现过的一个crash就是因为这点)。所有建议使用默认的sheme做release用，后加的scheme做开发用，在某种程度上减少这种失误的出现概率。
	
	如果只是通过编译来划分版本，其实用不同的configuration settings file也是可以达到管理的目的的。这里也就不赘述。
	
	《[How We Built Facebook for iOS][5]》(要翻墙)中分享的关于multiple builds只是简单的提到用不同的provision file，可能他们的版本控制更严格吧，具体俺们也不知道啦~~
	
2. 图片处理
	
	让icon带上build number信息的convert命令，是来自安装的ImageMagick，使用请参考[官网使用说明][4]。

3. version number & build number

	两者分别对应CFBundleShortVersionString、CFBundleVersion。
	
	前者对于用户而言是最直观的，在每次准备release到app store前，做一次变化，比较普遍的是设置成三位，格式如下
	>{MajorVersion}.{MinorVersion}.{Revision}
	>
	> * Major version - Major changes, redesigns, and functionality changes
	> * Minor version - Minor improvements, additions to functionality
	> * Revision - A patch number for bug-fixes

	后者更多的是对开发测试者而言更有意义，用以区分编译的版本。有的人喜欢做个shell在xcode build时自动递增。但我在项目中使用时，主要是在发布测试版时，才变化该值。因为开发者自己测试时，使用的肯定都是最新的代码，个人感觉build number对我没啥用。但是发布测试就不一样了，有时测试人员忘记更新最新版，会拿旧版跟你报bug，为了明确他们使用的编译版本，这时利用好build number可以免除一些不必要的沟通。以上只是我个人开发过程中使用的规则。当然，使用的原则还是怎么方便就怎么用：）。
	
	推荐看下《[Version vs build in XCode 4][6]》中的讨论，应该会有所收获。
	
	另外，如果CFBundleVersion是自增的数字，发布时新版的CFBundleVersion不比旧版的大的话，会提交失败。这里也顺便记录一下。

## 参考
	
1）[https://gist.github.com/ddrccw/6596464][1]

2）[https://github.com/lexrus/ios-makefile][2]

3）[http://clickontyler.com/web-sharing][3]

4）[http://www.imagemagick.org/Usage][4]

5）[http://www.youtube.com/watch?v=I5RqcYzrY4Y][5]

6）[http://stackoverflow.com/questions/6851660/version-vs-build-in-xcode-4][6]

7）<http://stackoverflow.com/questions/7281085/whats-the-difference-between-version-number-in-itunes-connect-bundle-versio>

8）<http://www.blog.montgomerie.net/easy-iphone-application-versioning-with-agvtool>

9）<http://chanson.livejournal.com/125568.html>


[0]: http://ddrccw.github.io/2013/01/29/daily-build-and-create-ipa-using-shell-script/

[1]: https://gist.github.com/ddrccw/6596464 "new package shell"

[2]: https://github.com/lexrus/ios-makefile "ios-makefile"

[3]: http://clickontyler.com/web-sharing/  "web-sharing"

[4]: http://www.imagemagick.org/Usage/ "imagemagick usage"

[5]: http://www.youtube.com/watch?v=I5RqcYzrY4Y "How We Built Facebook for iOS"
[6]: http://stackoverflow.com/questions/6851660/version-vs-build-in-xcode-4


