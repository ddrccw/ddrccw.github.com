---
layout: post
title: 利用源码的方式导入ZBar作为第三方library
date: 2012-05-25 18:18:00
isOriginal: true
category: iOS-dev
tags:
 - iOS
 - ZBar
keywords: iOS ZBar
description: 利用源码的方式导入ZBar作为第三方library
---


## 背景 ##

项目中需要扫描的功能，网上搜索了一番，发现[zbar][]和[zxing](http://code.google.com/p/zxing/)的使用比较普遍。但由于zxing的obj-c自带的封装只支持qrcode, 而项目中会需要扫描多种一维码和二维码。所以最终选择了[zbar][]。

文中阐述引用的[zbar][]原生的代码是[zbar]1.2.2，实验的ios版本为5

## 目的 ##

由于[zbar][]使用 GNU LGPL 2.1协议，提供的sdk相关文档只是介绍了通过静态库的方式来添加进现有的项目。为了能针对相应的实际情况，更好的了解和学习zbar源码，故尝试了如下方法，保证成功引入项目的同时，又能方便查看其源码。

## 开始导入zbar ##

### 1 准备 ###

下载[源码包](http://sourceforge.net/projects/zbar/files/zbar/0.10/zbar-0.10.tar.bz2/download),将相关的代码文件导入到Xcode项目中。

* zbar 相关的c api           
	./zbar
* zbar 相关的c/c++ header    
	./include
* zbar iphone的obj-c code and related header  
	./iphone

### 2 在Xcode项目中的步骤 ###

**1. 在Header Search Paths中添加包含zbar源码和头文件的路径**

**2. 在Build setting中添加user-defined setting，如下图：**

![alt user-defined-setting](/images/import-zbar-source-code/2.2.jpeg "user-defined-setting")

>***EXCLUDED_SOURCE_FILE_NAMESany***
>
>iOS simulator sdk
>    `ZBarReaderViewImpl_Capture.m ZBarCaptureReader.m`
>
>any iOS sdk
>    `ZBarReaderViewImpl_Simulator.m`
>
>GCC_MODEL_TUNING `G5`
>
>PREBINDING `NO`
>
>USE_HEADERMAP `NO`


**3. 添加zbar依赖的类库**

   * AVFoundation.framework (weak)
   * CoreMedia.framework (weak)
   * CoreVideo.framework (weak)
   * QuartzCore.framework
   * libiconv.dylib

**4. 在prefix.pch 中添加相应的头文件**
```objc
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreVideo/CoreVideo.h>
#import "ZBarSDK.h"       //zbar sdk required
```

**5. 确定哪些是要编译的源码**

1. 明确需要编译的源码

    ![alt required-compile](/images/import-zbar-source-code/2.5.jpeg "required-compile")

2. 明确不需要编译的

* ./zbar/window 
* ./zbar/window.c
* ./zbar/video
* ./zbar/video.c
* ./zbar/processor
* ./zbar/processor.c
* ./zbar/jpeg.c
* ./zbar/svg.c
* ./zbar/pdf417.c

***ps:***

建议产品环境还是通过上述方法先利用源码编译一个静态库，再结合相关的项目使用

[zbar]: http://zbar.sourceforge.net "zbar"
