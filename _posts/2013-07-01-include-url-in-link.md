---
layout: post
title: 记分享模块开发遇到的几个问题
date: 2013-06-29 10:54:10
isOriginal: true
category: iOS-dev
tags:
 - iOS
 - url-encode
keywords: iOS url-encode
description: 记分享模块开发遇到的几个问题
---

## 正题

### Url Encode

#### 问题描述

给第三方分享链接的url传递的参数中包含自定义的url，其中自定义的url中包含`&`符号，导致最终在第三方web端分享界面显示时，缺少自定义url的`&`符号后面的内容。

#### 分析和处理

这个应该是一个典型的url encode的问题。

说到url encode。首先参考[rfc2396][1]和[rfc3986][2]。

```
The generic URI syntax consists of a hierarchical sequence of
components referred to as the scheme, authority, path, query, and
fragment.

URI         = scheme ":" hier-part [ "?" query ] [ "#" fragment ]
```

一般来说，一个url符合如上规范，是由多个component组成的。每个component中可能还包含子component，比如query中可能会有多个参数。因此，就规范定义了一些保留字符用来分割界定这些component，对应前面的例子就是参数之间的`&`符号。如果需要在传递的参数中包含保留字符，就需要url encode，把保留字符转义成`%HEXHEX`的格式。另外，还有非保留字符和包含有特定意义的标识数据（Identifying Data）。

非保留字符，相对于保留字符，在URI中没有需要保留的意义。[rfc2396][1]和[rfc3986][2]中都建议不要encode。

特定意义的标识数据（Identifying Data）。大部分情况下，URI中的非保留字符是基于US-ASCII编码解释的。但是实际系统中会有超出US-ASCII字符集以外编码的字，比如UTF8，GBK等。为了保证这些字在特定编码下的含义，就需要encode。
  
以下附上[rfc2396][1]和[rfc3986][2]的保留字符和非保留字符

[rfc2396][1] 中，

```
     reserved    = ";" | "/" | "?" | ":" | "@" | "&" | "=" | "+" |
                  "$" | ","
     unreserved  = alphanum | mark
     mark        = "-" | "_" | "." | "!" | "~" | "*" | "'" | "(" | ")"
```

[rfc3986][2] 中,

```
      reserved    = gen-delims / sub-delims
      gen-delims  = ":" / "/" / "?" / "#" / "[" / "]" / "@"
      sub-delims  = "!" / "$" / "&" / "'" / "(" / ")"
                  / "*" / "+" / "," / ";" / "="
      unreserved  = ALPHA / DIGIT / "-" / "." / "_" / "~"
```


回到我遇到的问题上来，`&`字符是保留字符，如果要作为参数的一部分，就需要在encode函数中的转义字符集中加上`&`字符。

有关objctive-c中如何使用转义函数，可以参考《[Objective C URL编码转换][3]》。写的有理有据，令人信服~

**最后，再补上一些使用url encode的注意点**

1. 如果url中要传递的参数比较多，并且有嵌套引用的情况，一定要注意参数不要被二次编码。
2. 不要被某些直接对整个url进行转义的例子迷惑（我被坑过T_T...），一定要理解哪些需要被转义哪些不需要被转义。
3. 由于历史原因，application/x-www-form-urlencoded类型的数据中编码的规则可能会有不同，比如空格会被编码成`+`而不是`%20`。

### Include Url In Mail Links

#### 问题描述

如何以mail links的形式，在邮件中添加超链接？

#### 分析和处理

mail links的格式，直接参考[官方文档][7]。

虽然说往常要在邮件中添加富文本是通过MFMailComposeViewController的`setMessageBody:isHTML:`方法，而且有能在邮件中添加附件的操作，也比较方便，但是这里主要是尝试在app crash的同时，能马上发邮件报告crash信息，并稍微丰富一下邮件内容。（当然，在app重新启动的同时，检测log后再发邮件也可以，不过这是另外的话题了。。。）

考虑到邮件的内容是富文本的，而且有`setMessageBody:isHTML:`这个方法，基本可以确定邮件的内容是html格式。不过，同样要注意的是前面提到的encode问题。

例子代码如下：

```objc

NSString *body = @"Hey!I wanted to send you this link to check out: <a href='http://www.google.com'>google</a>";
NSString *utfEncoded = [body stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]; 
NSString *urlString = [NSString stringWithFormat:@\"mailto:?subject=test&body=%@\", utfEncoded];
NSURL *url = [[NSURL alloc] initWithString:urlString];
[[UIApplication sharedApplication] openURL:url];

```


## 参考资料

1）[rfc2396][1]

2）[rfc3986][2]

3）[Objective C URL编码转换][3]

4）[URL Encoding][4]

5）[混亂的 URLEncode][5]

6）[Percent-encoding][6]

7）[MailLinks][7]

8）[include-url-in-email][8]

[1]: http://www.ietf.org/rfc/rfc2396.txt "rfc2396"
[2]: http://www.ietf.org/rfc/rfc3986.txt "rfc3986"
[3]: http://www.winddisk.com/2012/05/26/objective_c_url_encode/ "objective_c_url_encode"
[4]: http://www.cocoanetics.com/2009/08/url-encoding/ "url-encoding"
[5]: http://blog.ericsk.org/archives/1423 "混亂的 URLEncode"
[6]: http://en.wikipedia.org/wiki/Percent-encoding "Percent-encoding"
[7]: http://developer.apple.com/library/ios/#featuredarticles/iPhoneURLScheme_Reference/Articles/MailLinks.html "MailLinks"
[8]: http://iphonedevsdk.com/forum/iphone-sdk-development/9527-include-url-in-email.html "include-url-in-email"

