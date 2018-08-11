---
layout: post
title: CocoaPods plugin开发
date: 2018-03-30 21:18:04
isOriginal: true
category: iOS-dev
tags:
 - CocoaPods
 - plugin
 - ruby
keywords: CocoaPods plugin ruby
description: 
---


# 前言

公司的项目构建使用的是CocoaPods工具，并且利用CocoaPods的插件机制对构建流程进行了深度定制。要了解公司项目的构建流程，势必要先了解一下Cocoapods的插件机制。刚好最近又要改一下同事写的插件，就搜了一下网上关于插件开发的资料，可惜网上的这块资料并不多，大多是插件的安装和使用教程。于是我就写了这篇文章来简单记录一下。当然，实际操作下来发现还是比较简单的。

# 插件

[cocoapods-plugins](https://github.com/CocoaPods/cocoapods-plugins)是CocoaPods团队提供的一个用来获取插件信息列表的插件，同时它也提供利用插件模板工程构建插件项目和插件发布的功能。

插件加载原理：CocoaPods插件管理器会通过RubyGems查找文件列表包含cocoapods_plugin.rb文件的gem包并加载。


## 插件工程创建和说明

```shell
pod plugins create NAME [TEMPLATE_URL]
```

运行上面的这串命令，可以直接创建一个工程，工程结构如下：
```bash
.
├── Gemfile
├── LICENSE.txt
├── README.md
├── Rakefile
├── cocoapods-demoplugin.gemspec
├── lib
│   ├── cocoapods-demoplugin
│   │   ├── command
│   │   │   └── demoplugin.rb
│   │   ├── command.rb
│   │   └── gem_version.rb
│   ├── cocoapods-demoplugin.rb
│   └── cocoapods_plugin.rb
└── spec
    ├── command
    │   └── demoplugin_spec.rb
    └── spec_helper.rb
```

`Gemfile`：插件工程本身是用[Bundler](http://bundler.io/)来管理项目依赖

`Rakefile`: `rake`默认执行spec目录下的spec文件执行用例自测

`cocoapods-demoplugin.gemspec`: 发布gem包需要的描述文件

`demoplugin.rb`: 插件实现文件

`demoplugin_spec.rb`: 默认帮你实现插件注册，可以在里面写用例测试插件

注意：如果插件创建时，你传入的NAME参数里的值包含大写，那么`rake`执行spec会不通过，似乎是因为pod的插件命令只支持小写，你需要把`demoplugin_spec.rb`里命令解析传的参数值改成小写

## 插件的开发和调试

1 开发

如上所述，默认的插件实现文件是`demoplugin.rb`

```ruby
module Pod
  class Command
    # This is an example of a cocoapods plugin adding a top-level subcommand
    # to the 'pod' command.
    #
    # You can also create subcommands of existing or new commands. Say you
    # wanted to add a subcommand to `list` to show newly deprecated pods,
    # (e.g. `pod list deprecated`), there are a few things that would need
    # to change.
    #
    # - move this file to `lib/pod/command/list/deprecated.rb` and update
    #   the class to exist in the the Pod::Command::List namespace
    # - change this class to extend from `List` instead of `Command`. This
    #   tells the plugin system that it is a subcommand of `list`.
    # - edit `lib/cocoapods_plugins.rb` to require this file
    #
    # @todo Create a PR to add your plugin to CocoaPods/cocoapods.org
    #       in the `plugins.json` file, once your plugin is released.
    #
    class Demoplugin < Command
      self.summary = 'Short description of cocoapods-demoplugin.'

      self.description = <<-DESC
        Longer description of cocoapods-demoplugin.
      DESC

      self.arguments = 'NAME'

      def initialize(argv)
        @name = argv.shift_argument
        super
      end

      def validate!
        super
        #help! 'A Pod name is required.' unless @name
      end

      def run
        UI.puts "Add your implementation for the cocoapods-demoplugin plugin in #{__FILE__}"
      end
    end
  end
end
```

看了一下其中的代码，可以知道插件命令实际上继承自[CLAide](https://github.com/CocoaPods/CLAide)的Command类。类里面就实现了3个方法，包含插件命令执行过程中的3个环节：初始化，命令参数验证，插件执行。同时注释里还提示Command可以有自己的subCommand。
好吧，代码看上去就是这么简单。。

2 调试

基本流程就是在spec文件`demoplugin_spec.rb`里写自测逻辑，通过`rake`命令执行验证。
在插件里，你可以hook到CocoaPods的任意模块，再配合rubymine写代码，就能很方便地深入了解CocoaPods机制。

# 总结

CocoaPods插件只是CocoaPods构建环节中的冰山一角。如果你想深入定制一些功能，学会定制插件很有必要。当然，继续深入了解CocoaPods作为oc，swift工程的包依赖管理器的设计，也是很有意义的。















