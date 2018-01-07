---
layout: post
title: 利用UIWebView实现富文本编辑器
date: 2013-03-08 16:51:28
isOriginal: true
category: iOS-dev
tags:
 - UIWebView
 - iOS
 - javascript
keywords: UIWebView rich-text-editor iOS javascript
description: how to make a rich text editor in UIWebView
---

## 正文

最近的一个ipad项目有需求，需要在iOS客户端上实现一个笔记功能。由于之前的一个版本对于笔记的功能要求不高，我也只是用UITextView实现了简单的录入。但是接下来的一个版本对于笔记的功能则是希望有web端富文本编辑器的所见即所得的效果。

刚开始，我还以为只能通过Core Text实现。如果要考虑基于HTML实现录入内容的跨平台展现，可能还需要做一番HTML到NSAttributeString的对应转换，而且很多东西如复制要自己实现，比较麻烦。

后来，上网查阅了一番，经tx的[ayangxu][1]的PPT的提点，发现可以用UIWebView实现富文本编辑，而且现今比较知名的app--evernote，似乎就是利用了该技术。这点在我导出笔记文件enex并用编辑器打开发现webkit相关字眼之后也确实得到了验证。大体了解了相关原理，主要是利用了webkit支持HTML5属性contenteditable（就是前段时间讨论的比较热闹的话题--一行代码可把浏览器成变临时编辑器）。与Core Text相比，优点在于节省了需要自己实现HTML到Core Text的繁琐转换；缺点嘛，就是到时出来的HTML片段可能只有在safari浏览器中才表现正常。

权衡利弊，最终我还是决定用UIWebView来实现富文本编辑。这里先感叹下HTML5的强大。 ^_^

### 实现

参看国外某大大的《[iOS 5 Rich Text Editing Series][2]》，确实给了我很大的帮助。
仔细研读了一下其中的代码，我发现实现起来并不是我原本想象中的那么复杂。关键点概述如下：

1. 富文本片段状态的获取和实现都是基于webkit内建的富文本编辑器。

	编辑器的api可以参考w3c的《[HTML Editing APIs][3]》。如果觉得那个文档太复杂，也可以参考Firefox的[Midas]的api，如编辑相关的[command][4]。还有IE的[Command Identifiers][5]。至于webkit本身似乎相关的文档比较少，我没找到。
	
2. iOS端设置一个timer，可及时获取光标所在片段的文本状态。
3. 一些交互的操作，比如拖拽图片，光标定位，需要借助javascript，了解selection，range等对象的操作，相关api可以参考《[Gecko DOM Reference][6]》

注：	iOS端是利用UIWebView的`stringByEvaluatingJavaScriptFromString`方法与javascript交互。

参看[ayangxu][1]的PPT，他用了较多的hack方法，但目前实际实现过程中，我除了在去除键盘上的黑条用了一点取巧的办法，其他基本上使用的都是sdk的api，具体效果也还是可以接受的，不过还有待完善。

具体代码参看可以[点我][7]。

### 遇到的问题

[ayangxu][1]的PPT讨论了不少可能出现的问题（虽然我也没都遇到-。-）。我也顺便补充个小问题好了。

#### 弹出的UIMenuController

平常使用时，往往可以通过方法

`- (BOOL)canPerformAction:(SEL)action withSender:(id)sender;`

返回YES/NO，控制UIMenuController上系统menuItem的出现与否。但是对于UIWebView（iOS>=5），该方法不可行，系统menuItem始终会出现。原因在于决定其响应展示的view是UIWebBrowserView。虽然可以通过category覆盖相应的方法控制，但是该类是私有的，如果app要过审核的话，最好还是不要动它。

另外，UIWebView在ios5上使用时，弹出的UIMenuController的系统menuItem中没有BIU的选项。iOS6中则有，相当于有个二级菜单包含加粗，斜体和下划线。

## 引申

### UIWebView中javascript调试相关

当要写的javascript代码比较复杂时，尽管可以通过alert的方法调试，但是console的log等方法输出的信息，却是不可见的。还好stackoverflow上有人提供了一个[解决方案][8]，使得log的信息可以输出到xcode的debug终端。

###CoreText is better?

尽管用UIWebView比较容易实现富文本编辑，但实际开发过程中，我觉得对于UIWebView的可控性上感觉还是比较少。DTCoreText的作者就在《[UIWebView must die](http://www.cocoanetics.com/2011/01/uiwebview-must-die/)》中列举UIWebView的种种不是。看了[DTRichTextEditor](http://www.cocoanetics.com/2013/02/dtrichtexteditor-1-2/)的demo，至少可以确定Core Text是可行的。如果有机会的话，不妨了解一下Core Text的实现。

下面列举一些使用Core Text的富文本展示的项目，希望有所帮助。

* [DTCoreText](https://github.com/Cocoanetics/DTCoreText)
* [EGOTextView](https://github.com/enormego/EGOTextView)
* [JTextView](https://github.com/jeremytregunna/JTextView)
* [FTCoreText](https://github.com/FuerteInternational/FTCoreText)
* [RTLabel](https://github.com/honcheng/RTLabel)


[1]: http://f2e.us/slides/iOS_Rich_Editor/iOS_Rich_Editor.html#slide1 
[2]: http://ios-blog.co.uk/featured-posts/ios-5-rich-text-editing-series/
[3]: https://dvcs.w3.org/hg/editing/raw-file/tip/editing.html
[4]: https://developer.mozilla.org/en-US/docs/Rich-Text_Editing_in_Mozilla#Executing_Commands
[5]: http://msdn.microsoft.com/en-us/library/ms533049(v=vs.85).aspx
[6]: https://developer.mozilla.org/en-US/docs/Gecko_DOM_Reference
[7]: https://github.com/ddrccw/CCRichTextEditor
[8]: http://stackoverflow.com/questions/6508313/javascript-console-log-in-an-ios-uiwebview/6508343#6508343

[Midas]: https://developer.mozilla.org/en-US/docs/Midas
