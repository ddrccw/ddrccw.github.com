---
layout: post
title: 在github上用jekyll搭建个人blog
date: 2012-08-13 21:37:13
isOriginal: true
category: Usage
tags:
 - github
 - github-pages
 - jekyll
keywords: github jekyll blog
description: Blogging with jekyll
---

## 前言

说起写个人blog，如果是在学生时代，我肯定会觉得不可思议，理由很简单--我很懒的动笔。但让我燃起写blog的决心，却还得从工作后开始说起。平常工作中，我难免会遇到各种各样的问题。有了问题，自然需要放狗搜索，一篇一篇的翻看过去。如果是过去，我如果看到好文会保存文章链接到书签，有时往往一个问题的解决会让我收集好多个书签，于是随着时间的延长，我的浏览器书签栏也越来越臃肿。更可恶的是，有时一个同样问题的解决，由于我个人理解的不够深入或记忆不足等原因，最终导致我又得打开一个个书签去看。这样与其浪费找同样问题的时间，还不如花点时间记点笔记整理一下思路来加深理解。由此权衡利弊，我不得不开始blog，理由同样很简单--想偷懒。

之前的一段时间，我曾用wordpress+nginx+mysql分别在win和linux下搭过一个blog。但自从我开始在mac下从事ios开发并接触了git期间，我偶然了解到大名鼎鼎的github可以针对个人或组织用jekll免费搭建站点。于是，我怀着好奇心，做了一番研究和尝试之后，最终我果断选择了jekyll。它吸引我的一个重要原因就是，让我能花更多的时间用来写文字，而只需要一些终端命令就能通过简洁的markdown语法实现很好的排版并合成页面。

## 正题

前面废话了一堆，现在开始动手搭blog。以下的步骤可能不太详细，但相信大体的流程还是清晰的。

### 1 申请一个github账户
这个应该不用解释了，有了账户就能建立两种page

1. user/organization page      `--用于个人和组织的主页`
2. project page                `--用于自己账户下对应项目的主页`

因为是个人blog，所以我选择1.
另外为了方便管理仓库，我使用ssh的方式来建立自己的电脑和github的连接，这样也省的每次更新的时候要输账户和密码。具体参考<https://help.github.com/articles/generating-ssh-keys>
### 2 基础篇

#### 2.1 rubyGem for installing jekyll 

谷歌了解了一下，Jekyll是一个简单的使用Ruby的文章内容生成器。看来要使用jekll之前还得先搞定ruby= =|||

由于我没接触过ruby，所以我在这里花点篇幅来介绍下如何安装ruby。

1) mac环境：

mac下ruby版本太低，要先升级。需要安装rvm。但是还要先解决curl证书问题。

a 获取curl证书 

```bash
curl http://curl.haxx.se/ca/cacert.pem>cacert.pem
```

b 设置相关的环境变量

```bash
export CURL_CA_BUNDLE=~/.ssh/cacert.pem
```

c 安装rvm并设置环境变量

```bash
curl -L get.rvm.io | bash -s stable [[ -s "/Users/<username>/.rvm/scripts/rvm" ]] && source "/Users/	<username>/.rvm/scripts/rvm"    #注意<username>替换成你自己的
```

d 安装ruby

>
1. Open Terminal
2. sudo rvm install 1.9.3
3. Now that Ruby is installed you can type the following command to use the 	newer version of Ruby: rvm use 1.9.3
4. To verify type: ruby -v
5. To make 1.9.3 the default: rvm --default 1.9.3

e 安装jekyll
	
有了ruby，安装jekyll水到渠成。

```bash
sudo gem install jekyll
```

#### 2.2 jekyll推荐工具

**2.2.1 安装rdiscount来解析markdown语言**

虽然jekyll默认用maruku来解析markdown语言,但都说用c语言实现的rdiscount解析器的速度更快，所以我也直接选择rdiscount。

```bash
sudo gem install rdiscount
```

//2018.1.6

官方参考配置使用kramdown

**2.2.2 pygments--支持语法高亮，要装python**

身为挨踢攻城狮的blog，难免要贴一些代码。jekyll虽然原生不支持高亮代码，但支持通过插件工具来高亮代码。[pygments][]就是一个比较流行的插件工具，它支持的语言种类相当丰富。

mac上它可以通过Macports和Homebrew,我习惯使用前者。

```bash
sudo port install python25 py25-pygments
sudo ln -s <py25-pygments> <pygments>  #非必须：因为jekyll只能识别pygments这个名称，但是port下来的可执行文件的名称可能并不是pygments，所以我在这里创建符号链接
```

//2015.6.25

~~jekyll升级到2.5.3后，pygments自带了，可以省略这步。~~	

//2018.1.6

官方参考配置使用rouge


#### 2.3 Last But Not The Least

有了前面的基础，可以说离成功建站只有一步之遥。有技术的web开发人士大可直接自己开发，但是我等菜鸟还是可以先clone借鉴一下别人的站点风格+.+。。。

下面以我自己的为例，纯属参考。

首先，可以在`https://github.com/mojombo/jekyll/wiki/Sites`找找看有没有自己喜欢的站点。

我的站点风格来自`http://bilalh.github.com`

**2.3.1 代码借鉴**

1. `git clone https://github.com/Bilalh/bilalh.github.com.git`
2. 安装必要的插件工具
	
	~~`sudo gem install nokogiri sass growl jekyll-pagination`~~

	~~`sudo gem install nokogiri sass growl`~~

	~~`sudo gem install nokogiri growl`~~

	`sudo gem install nokogiri growl jekyll-paginate //2018.1.6`

	//2013.9.15

	~~ps: 因为jekyll升级到1.2.1，导致jekyll-pagination在jekyll build失败的问题，处理方法参考<https://github.com/blackwinter/jekyll-pagination/issues/3>。我是在安装jekyll-pagination 0.0.4后，手动到目录修改它的pagination.rb代码为它在github上的最新代码即可。~~
	
	//2014.8.25
	
	~~因为jekyll升级到2.3.0后，自带一个`jekyll-paginate`，所以不再需要`jekyll-pagination`~~
	
	//2015.6.25

	jekyll升级到2.5.3后，`sass`也不再需要了

3. 按需更改
	- 与原作者相关的所有信息
	
		404.html、default.html等页面,当然主要是模板页。
		
	- 页面布局，相关代码
	
		原作者的blog内容比较多，有些页面我用不到就直接删了；还有原作者写了一些jekll插件，要使用它的就必须在_config.yml中将safe设置为false，因为github不支持自定义插件。
		
	- google analytics 和 disqus
	
		前者用来分析站点的相关信息，和seo有关，要埋上一些代码。后者是第三方的评论系统，在官网注册个账户，同样在网站里埋上一些代码即可。
		
**2.3.2 发布自己的blog**

1. 在自己的github上建个项目，并clone到本地。
2. 按照Bilalh的blog的设计思想，就是开个source分支来写blog的页面代码，再生成静态页面到master，最终push到github。稍等一会儿就可以通过github访问自己blog啦~~

### 3 使用篇

本人能力有限，在此贴出一些有用的站点，权当借鉴参考~~

1 可以了解jeklly的配置、目录结构意义等。

<https://github.com/mojombo/jekyll>

2 想自己写插件，还是乖乖学ruby好了。

<http://www.ruby-lang.org/en/>

3 简洁明了的markdown标记语言。

<http://daringfireball.net/projects/markdown/>

3 推荐写作工具

[mou](http://mouapp.com)：一个所见即所得的markdown编辑器。

[byword](http://bywordapp.com)：markdown编辑器，提供一个简洁的全屏幕打字界面，可以更加专注文字创作。

## 后序

终于成功地在github上搭起了blog，剩下的就需要自己坚持不懈地努力blog啦~~加油>_<

## 参考文献

1） [github pages help](https://help.github.com/categories/20/articles "github pages help") 

2） <http://stackoverflow.com/questions/6414232/curl-certificate-error-when-using-rvm-to-install-ruby-1-9-2>

3） <http://brandonbohling.com/2011/08/27/Installing-Jekyll-on-Mac/>

[pygments]: http://pygments.org "pygments"