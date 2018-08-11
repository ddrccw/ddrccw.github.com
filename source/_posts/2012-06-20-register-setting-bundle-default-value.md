---
layout: post
title: 获取Settings bundle中预定义的默认值
date: 2012-06-20 15:18:00
isOriginal: true
category: iOS-dev
tags:
 - iOS
 - Settings.bundle
keywords: iOS Settings.bundle
description: 所谓的Settings Bundle就是把一个名为Settings.bundle的文件放置于你的app的根目录下。该文件可以被系统的Settings.app所用，来配置你自己的app的一些设置。

---


## 1 背景 ##

所谓的Settings Bundle就是把一个名为Settings.bundle的文件放置于你的app的根目录下。该文件可以被系统的Settings.app所用，来配置你自己的app的一些设置。
具体介绍参考[Implementing an iOS Settings Bundle](http://developer.apple.com/library/ios/#DOCUMENTATION/Cocoa/Conceptual/UserDefaults/Preferences/Preferences.html#//apple_ref/doc/uid/10000059i-CH6-SW5)

## 2 问题描述 ##

理想情况下，我们希望app安装完好，然后直接进入能载入一些相关配置，如果有默认配置值，则直接加以应用。
然而开发过程中，在xcode中设置setting bundle里一些配置项的默认值后，运行app，通过`[[NSUserDefaults standardUserDefaults] objectForKey:@"demokey"]`的方法（注：在setting.app中设置的值是可以通过该方法获取的），却获取不了先前预定义的默认值。虽然在setting.app中可以看到设置的默认值。

## 3 解决方法 ##

经过一番查询，可以得出结论目前ios sdk (<= 5.1.1)未提供直接获取默认值的方法，需要自己实现。如下：

```objc
- (void)registerDefaultsFromSettingsBundle {
    [[NSUserDefaults standardUserDefaults] registerDefaults:[self defaultsFromPlistNamed:@"Root"]];
}

- (NSDictionary *)defaultsFromPlistNamed:(NSString *)plistName {
    NSString *settingsBundle = [[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"bundle"];
    NSAssert(settingsBundle, @"Could not find Settings.bundle while loading defaults.");

    NSString *plistFullName = [NSString stringWithFormat:@"%@.plist", plistName];

    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:[settingsBundle stringByAppendingPathComponent:plistFullName]];
    NSAssert1(settings, @"Could not load plist '%@' while loading defaults.", plistFullName);

    NSArray *preferences = [settings objectForKey:@"PreferenceSpecifiers"];
    NSAssert1(preferences, @"Could not find preferences entry in plist '%@' while loading defaults.", plistFullName);

    NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
    for(NSDictionary *prefSpecification in preferences) {
        NSString *key = [prefSpecification objectForKey:@"Key"];
		if(key){
			id value = [prefSpecification objectForKey:@"DefaultValue"];
			if(value) {
				[defaults setObject:value forKey:key];
			} 
		}

        NSString *type = [prefSpecification objectForKey:@"Type"];
        if ([type isEqualToString:@"PSChildPaneSpecifier"]) {
            NSString *file = [prefSpecification objectForKey:@"File"];
            NSAssert1(file, @"Unable to get child plist name from plist '%@'", plistFullName);
            [defaults addEntriesFromDictionary:[self defaultsFromPlistNamed:file]];
        }

    }

    return defaults;
}
```

**说明**

上述方法支持从setting bundle中获取配置的默认值，并且setting bundle在setting.app的main panel中可以包含多个child panel。
只需要在
`- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions`
中调用一次,随后就可以直接利用NSUserDefaults获取默认值。
相关讨论具体参看[stackoverflow](http://stackoverflow.com/questions/510216/can-you-make-the-settings-in-settings-bundle-default-even-if-you-dont-open-the)
