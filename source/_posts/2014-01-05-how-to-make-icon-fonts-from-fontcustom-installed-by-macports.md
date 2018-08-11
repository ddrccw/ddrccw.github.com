---
layout: post
title: Macports安装fontcustom制作中文图标字体
date: 2014-01-05 20:47:06
isOriginal: true
category: iOS-dev
tags:
 - macports
 - fontcustom
 - icon-fonts
 - iOS 
keywords: macports fontcustom icon-fonts iOS
description: Macports安装fontcustom制作中文图标字体
---


## 前言

最近在公司前端群里看到了关于图标字体的文章分享，不禁想到了之前star的[fontdiao][1]项目中的关于中文图标的使用。那个项目中介绍的工具通过Homebrew安装较为容易，但是MacPorts安装起来的则有些问题。因为我一直用的MacPorts，而且当时也没在网上搜到相关的解决办法，遂搁置了下来。最近刚好有空闲时间，就趁机研究了一下。

## 正文

### 安装fontcustom
首先追本溯源，制作图标字体的关键是[fontcustom][2]。从它的安装说明中可以看到它的显式依赖东东有fontforge，ttfautohint。

#### fontforge

安装这个库是最折腾的。虽然port上可以安装上，但是实际配合fontcustom使用时会报错

```ruby
       debug  Copyright (c) 2000-2012 by George Williams.
               Executable based on sources from 14:57 GMT 31-Jul-2012-ML-NoPython.
               Library based on sources from 14:57 GMT 31-Jul-2012.
              /Users/ddrccw/.rvm/gems/ruby-2.0.0-p247/gems/fontcustom-1.3.1/lib/fontcustom/scripts/generate.py 行: 2 Undefined variable: import
       error  `fontforge` compilation failed.
```

看样子似乎是port安装的fontforge不支持Python导致的原因。无奈之下，只有选择从源码安装。

** 第一关 **

从[这里](http://sourceforge.net/projects/fontforge/files/fontforge-source/ "fontforge-source")下fontforge源码和[这里](http://sourceforge.net/projects/freetype/files/freetype2/ "freetype2")下freetype2的源码(因为fontforge的编译也需要freetype2的源码)。虽然实际上fontforge的[依赖](http://fontforge.org/source-build.html#Dependencies "Dependencies")有很多，但还好前面port的时候也下好了相关依赖的库文件，唯一还需要安装的依赖库是pango(同样是源码编译需要)，这个也能从port上安装。另外，如果你需要fontforge运行有UI界面，还需要X11，这个可从[这里](http://xquartz.macosforge.org/trac/wiki/Releases "xquartz")下载。

这里小结一下源码安装fontforge需要准备的步骤：

* 下载fontforge源码和freetype2的源码
* port install fontforge pango，然后port uninstall fontforge（因为会和源码安装的冲突）
* 下载XQuartz并安装（可选）

经过上面步骤，第一关也就是fontforge的源码编译前`./configure`的过程可以保证通过。

** 第二关 **

接下来就是编译。编译过程会出现两个问题。注：如果你使用的是lion下的xcode 4.x可能不会有下述问题。

1）第一个问题，有3个c文件（fontforge/macbinary.c fontforge/startui.c gutils/giomime.c）会编译失败，参考如下：

```c

giomime.c:68:10: fatal error: '/Applications/Xcode.app/Contents/Developer/Headers/FlatCarbon/Files.h' file not found
#include </Applications/Xcode.app/Contents/Developer/Headers/FlatCarbon/Files.h>
         ^
1 error generated.

```

显然这是头文件的问题。因为原先代码引用的头文件从MacOSX10.8.sdk开始位置发生了变化。解决方法，要么参考[fontforge.patch][3]改相关源文件，要么直接用MacOSX10.7.sdk来编译。建议前者的说。

如果你选择后者，请走下列步骤：

* 获得一份MacOSX10.7.sdk

	因为最新的xcode 5不包含MacOSX10.7.sdk，所以你需要从xcode 4.6.x的`Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs`目录中找到MacOSX10.7.sdk，并拷贝一份出来。说句题外话，为了减少sdk文件对xcode的依赖，我单独把它放到一个文件夹下，然后在xcode 5的和前面提到的同样路径的目录中做了一个软连接，让xcode 5能找到它。

* 保证编译时能找到MacOSX10.7.sdk

	将MacOSX10.7.sdk/Developer做个软连接（注意使用绝对路径，不然有坑。。）到根目录的/Developer即可。

2)第二个问题，其编译报错如下：

```c

/System/Library/Frameworks/ApplicationServices.framework/Frameworks/ATS.framework/Headers/SFNTLayoutTypes.h:1791:41: error: typedef redefinition with different types ('struct AnchorPoint' vs 'struct anchorpoint')
typedef struct AnchorPoint              AnchorPoint;
                                        ^
./splinefont.h:512:3: note: previous definition is here
} AnchorPoint;
  ^
```


同样，原因是显而易见的，即存在结构体重复定义的问题。要么参考这位老兄的[做法](https://github.com/Homebrew/homebrew/issues/18046#issuecomment-14355327)，改动一下fontforge/startui.c这个文件即可。要么用MacOSX10.7.sdk来编译。

最后说到这里，你可能会疑问Homebrew是怎么处理的。参考Homebrew的[fontforge.rb](https://github.com/Homebrew/homebrew/blob/d73a1502848808c764023ef1f8d7af514cfef5b9/Library/Formula/fontforge.rb "fontforge.rb")，因为包管理工具不会去改源码(吐槽一下：fontforge确实一年多没release新版本了。。)，所以它的选择是对`fontforge/macbinary.c fontforge/startui.c gutils/giomime.c`这三个文件单独用MacOSX10.7.sdk编译。另外可以在[#issues-13635](https://github.com/Homebrew/homebrew/issues/13635)看到相关的讨论。

### ttfautohint

ttfautohint在MacPorts上是找不到的，所以请去[这里](http://sourceforge.net/projects/freetype/files/ttfautohint/ "ttfautohint")下载编译好的二进制文件，放到系统找得到的bin目录下即可，比如`/opt/local/bin/`。

准备好了fontforge，ttfautohint，最后`gem install fontcustom`就ok了。

### 制作图标字体

其实经过前面的折腾，剩下的基本就so easy了。主要就是准备好svg，写好yml配置文件，最后用fontcustom compile一遍即可，具体请参考[fontcustom](https://github.com/FontCustom/fontcustom "fontcustom")。但是结合到实际移动端项目中，这也才是第一步。关键是如何利用fontcustom的模板功能生成移动端能用的代码。

就iOS开发而言，你可以通过继承的方式或Category的方式扩展对象。

* [ios-fontawesome][2]项目就采用继承的方式实现对图标字体的利用，不过没提供模板，你只能用现成的图标字体。

* [fontdiao][1]项目则是采用Category的方式，而且也提供了模板，不过它的配置不适用于最新版的fontcustom，这个需要替换配置，也不难。最后替换它的svg为自己项目的svg（这里我用[iconmoon](http://icomoon.io/app/#/select "iconmoon")的svg实验了一下，发现不一定要照它说明的使用300x300的svg文件），然后compile一下，也就达到自定义图标字体的目的了，而且也提供了配套的ios代码文件。

当然你也可以参考这两个项目，实现自己的代码：）

## 参考

1）[https://github.com/lexrus/fontdiao][1]

2）[https://github.com/alexdrone/ios-fontawesome] [2]

3）[https://github.com/FontCustom/fontcustom/][3]

4）[https://gist.github.com/ummels/3419350][4]



[1]: https://github.com/lexrus/fontdiao "fontdiao"

[2]: https://github.com/alexdrone/ios-fontawesome "ios-fontawesome"

[3]: https://github.com/FontCustom/fontcustom/ "fontcustom"

[4]: https://gist.github.com/ummels/3419350 "fontforge.patch"
