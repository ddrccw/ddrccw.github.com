---
layout: post
title: 关于NSDate的tips
date: 2012-12-30 19:10:17
isOriginal: true
category: iOS-dev
tags:
 - iOS
 - NSDate
 - NSDateFormatter
 - UTC 
 - GMT
keywords: ios NSDate NSCalendar NSDateComponents NSDateFormatter UTC GTM
description: tip on date
---

## 前言

最近看了一些开源Calendar的实现，里面有不少关于NSDate与NSCalendar、 NSDateComponents、 NSDateFormatter等对象的转换，看着看着又差点把自己绕晕了。想起过去曾解决过的界面显示的时间与服务器端传过来的时间不一致的问题，看来有必要做个了断了。嘿嘿。

## 正题

### 一些基本概念

+ NSDate是基于[GMT]()（[UTC]()），参考文档

	>The sole primitive method of NSDate, timeIntervalSinceReferenceDate, provides the basis for all the other methods in the NSDate interface. This method returns a time value relative to an absolute reference date—the first instant of 1 January 2001, GMT.
	
+ 格林尼治标准时间（[GMT][]）与 世界标准时间（[UTC][]）

	简单的理解，两者都是世界时间计算的标准，区别是精度上，UTC更精确些。因而UTC现在也多用来代替GMT。

+ 区域设置（[locale][]）与 时区（[timezone][]）

	个人理解，区域设置关注的是界面上的格式的显示，包含日期、货币等格式。时区则是使用同一时间的具体区域。两者千万不能等同，具体见后面说明。

	ps：具体到开发过程中，在ios设备上的设置app，通用->多语言环境->区域格式（不是语言），可以更改locale的配置(影响 [NSLoale currentLocale])，通用->日期与时间，可以设置具体的时区，默认是自动设置(影响 [NSTimeZone systemTimeZone])。另外，ios模拟器上只能设置区域格式，时区则始终是自动设置的。
	
### 结合例子说明

#### 例子

代码如下：

```objc
 NSLog(@"current locale(%@) and timezone(%@)", [[NSLocale currentLocale] localeIdentifier], [NSTimeZone systemTimeZone]);
 NSCalendar *calendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
 NSDate *date = [NSDate date];
 NSLog(@"defaut description:%@", date);  //因为date是GMT，显示为当前时区时间-8h
 NSLog(@"current locale description:%@", [date descriptionWithLocale:[NSLocale currentLocale]]);  //显示当前时区时间

 //calendar是基于当前时区的，date是GMT，comps是返回date+8的当前时区的时间
 NSDateComponents *comps = [calendar components:(NSYearCalendarUnit |
                                                 NSMonthCalendarUnit |
                                                 NSDayCalendarUnit |
                                                 NSHourCalendarUnit |
                                                 NSMinuteCalendarUnit |
                                                 NSSecondCalendarUnit)
                                       fromDate:date];
 comps.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
 NSLog(@"timezone=%@, comps=%@", comps.timeZone, comps);
 //calendar是基于当前时区的，返回的date是GMT，故显示的时间减去8h
 NSLog(@"calendar date default:%@", [calendar dateFromComponents:comps]);

 NSString *dateString = @"2012-12-28 18:00:00";  
 NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
 formatter.locale = [NSLocale currentLocale];
 [formatter setTimeStyle:kCFDateFormatterShortStyle]; //影响时分秒格式
 [formatter setDateStyle:NSDateFormatterLongStyle];   //影响年月日格式
 NSLog(@"%@", [formatter stringFromDate:date]);

 formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
 //formatter的默认timezone是当前时区的，Date是基于GMT的，显示的是当前时区的
 NSLog(@"default locale(%@) timezone(%@) formatter(date to string):%@",
       formatter.locale.localeIdentifier,
       formatter.timeZone,
       [formatter stringFromDate:date]);
 //formatter的默认timezone是当前时区的，dateString则对应时区理解为当前时区的，Date是基于GMT的，故显示的时间减去8h
 NSLog(@"default locale(%@) timezone(%@) formatter(string to date):%@",
       formatter.locale.localeIdentifier,
       formatter.timeZone,
       [formatter dateFromString:dateString]);

 formatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];  //GMT ~ UTC
 //formatter的timezone是GMT，date是GMT，故显示的是GMT
 NSLog(@"customize locale(%@) timezone(%@) formatter(date to string):%@",
       formatter.locale.localeIdentifier,
       formatter.timeZone,
       [formatter stringFromDate:date]);
 //formatter的timezone是GMT，dateString则对应时区理解为GMT, date是GMT，故显示的是GMT的
 NSLog(@"customize locale(%@) timezone(%@) formatter(string to date):%@",
       formatter.locale.localeIdentifier,
       formatter.timeZone,
       [formatter dateFromString:dateString]);
```

结果如下：
```bash
2012-12-31 14:15:06.900 DateTest[1281:707] current locale(zh_CN) and timezone(Asia/Shanghai (CST (China)) offset 28800)
2012-12-31 14:15:06.903 DateTest[1281:707] defaut description:2012-12-31 06:15:06 +0000
2012-12-31 14:15:06.906 DateTest[1281:707] current locale description:2012年12月31日星期一 中国标准时间下午2时15分06秒
2012-12-31 14:15:06.910 DateTest[1281:707] timezone=GMT (GMT) offset 0, comps=<NSDateComponents: 0xee664f0>
    TimeZone: GMT (GMT) offset 0
    Calendar Year: 2012
    Month: 12
    Day: 31
    Hour: 14
    Minute: 15
    Second: 6
2012-12-31 14:15:06.911 DateTest[1281:707] calendar date default:2012-12-31 14:15:06 +0000
2012-12-31 14:15:06.917 DateTest[1281:707] 2012年12月31日 下午2:15
2012-12-31 14:15:06.919 DateTest[1281:707] default locale(zh_CN) timezone(Asia/Shanghai (CST (China)) offset 28800) formatter(date to string):2012-12-31 14:15:06
2012-12-31 14:15:06.921 DateTest[1281:707] default locale(zh_CN) timezone(Asia/Shanghai (CST (China)) offset 28800) formatter(string to date):2012-12-28 10:00:00 +0000
```

### 关键点

1. NSDate始终是基于GMT的，与系统时区的设置无关。
2. NSDateComponents只是某个具体时间点（概念意义上的时间，不是NSDate型数据）的具体部分的组成，同样是与系统时区的设置无关。
3. 在NSDate与其他类型数据（如NSDateComponents，NSString）的转换过程中，负责转换的实例（如NSCalendar，NSDateFormatter）的timezone，默认值会受系统时区的设置影响，同时该属性是用来理解要转换成NSDate型数据的源数据的时区或NSDate型数据要转换成的目标数据的时区。比如 date to string，最终date会转换为NSDateformatter的timezone对应的时间string。
4. 尽管NSDate可以通过locale，打印相应的timezone的时间，但不代表locale和timezone是有直接关系的。上述例子NSDateFormatter的使用就说明了这点，timezone的设置才是NSDate型数据是否需要加减时间的关键。但是locale的设置会影响显示，比如fomatter格式说明符包含"eeee"，locale为zh_CN，则会显示"星期一"。

## 引申

1. 在与后台的交互过程中，传递时间参数是很常见的。时间参数所基于的时区必须搞清楚，还有对于不同的时间数据存储类型，要小心因为时区的设置不当而导致时间计算出错，而在展示上出现偏差。

2. c/c++对于时间的处理虽然比较繁琐，但也相对直白一些，因为时间的处理基本集中在struct tm 和 time_t比较底层的数据类型上。

## 参考资料

1）[GMT][]

2）[UTC][]

3）[locale][]

4）[timezone][]

5）<http://www.cplusplus.com/reference/ctime/>

6）[Formatting Dates and Times](http://userguide.icu-project.org/formatparse/datetime)

7）[NSDateFormatter and Internet Dates](http://developer.apple.com/library/ios/#qa/qa1480/_index.html)

[GMT]: http://zh.wikipedia.org/wiki/GMT
[UTC]: http://zh.wikipedia.org/wiki/UTC
[locale]: http://zh.wikipedia.org/wiki/区域设置
[timezone]: http://zh.wikipedia.org/wiki/时区
