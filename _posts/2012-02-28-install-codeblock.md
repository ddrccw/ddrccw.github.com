---
layout: post
title: 开发利器codeblocks安装
date: 2012-02-22 21:18:00
isOriginal: true
category: c/c++
tags:
 - c/c++
 - codeblock
 - IDE
---


##1 介绍##

codeblocks是我开发c/c++时喜欢用的一款IDE，相比于vs安装时的庞大，它则小了很多，但它的功能却依然强大。它的调试是可视化的，相信这有助于增强工作效率。另外，我看中的则是它的跨平台性，如果编程得当的话，在window下的项目在linux下依然可用。这够强大吧。


##2 安装 for win##

###2.1 安装mingw###

下载安装工具mingw-get-inst-20111118.exe(http://sourceforge.net/projects/mingw/files/)，我选择的是联网安装（可能下的不是稳定版的，而是最新版的）。

装编译器（我选了c，c++，objc）,还有MSYS（cmd终端中也能使用linux的一些命令）

设置环境变量
{% highlight bash tabsize=4 %}
MINGW_PATH=D:\MinGW   #这个只是我的安装目录，还得注意版本号问题
C_INCLUDE_PATH=%MINGW_PATH%\include;%MINGW_PATH%\lib\gcc\mingw32\4.6.2\include
CPLUS_INCLUDE_PATH=%C_INCLUDE_PATH%
LIBRARY_PATH=%MINGW_PATH%\lib;%MINGW_PATH%\lib\gcc\mingw32\4.6.2
PATH=%MINGW_PATH%\bin;%MINGW_PATH%\libexec\gcc\mingw32\4.6.2;%MINGW_PATH%\msys\1.0\bin;%MINGW_PATH%\msys\1.0\sbin\awk
{% endhighlight %}

cmd中查看

g++ -v

linux各种命令尝试下

###2.2 完成codeblocks安装###

下载codeblocks-10.05-setup.exe（http://www.codeblocks.org/downloads/26）

安装好后，这时还是没有集成gdb

下载http://qp-gcc.googlecode.com/files/gdb-7.2.7z，将其中的内容解压至<mingw-dir>/bin

然后，在codeblocks的settings->compiler and debugger->debugger settings，如图

![alt setting](/images/posts/install-codeblocks.jpeg "setting")

这样设置好后，就可以在codeblocks下调试啦~~~~

关于集成调试的文章可参考
>http://code.google.com/p/qp-gcc/wiki/GDB


##3 安装for linux##

###3.1 xwWidget安装###

首先要确定pkg-config和gtk是否安装，以下主要是确认gtk+2.0
{% highlight bash tabsize=4 %}
pkg-config –modversion gtk+      #(查看1.2.x版本)
pkg-config –modversion gtk+-2.0  #(查看 2.x 版本)
pkg-config –list-all |grep gtk   #(查看是否安装了gtk)
{% endhighlight %}

或 
{% highlight bash tabsize=4 %}
ls /usr/lib/libwx_gtk*   #to verify the presence
{% endhighlight %}

如果不存在，我的操作是：
{% highlight bash tabsize=4 %}
yum install gtk+extra-devel     #<根据yum list gtk+*结果，32位i386或可能i686，64位x86_64>
yum install gtk+extra           #<根据yum list gtk+*结果，32位i386或可能i686，64位x86_64>
{% endhighlight %}

后者可能不需要（有待验证，下次如果再装时再确认，毕竟我是喜欢装的东西越少越好）。
而其中的一系列包中gtk2-devel这个可能是关键，以后也可以试下`yum install gtk2-devel`
或`yum install gtk+extra-devel.i686`

然后就是xwWidget安装了，[具体参考](http://wiki.codeblocks.org/index.php?title=Installing_Code::Blocks_from_source_on_Linux#Library_wxGTK_installation "codeblocks")
>####Building wxWidgets
>Here we will create a separate build directory instead of building from the src directory, so that we can easily rebuild with different options (unicode / ansi, monolithic / many libs, etc).
>The documentation says the default is for gtk2 to use unicode and wx > 2.5 to build as a monolithic library. This doesn’t appear to be the case, so these flags are passed to configure:

>>	`mkdir build_gtk2_shared_monolithic_unicode`

>>	`cd build_gtk2_shared_monolithic_unicode`

>>	`../configure --prefix=/opt/wx/2.8 \`

>>	`       --enable-xrc \`

>>	`       --enable-monolithic \`

>>	`       --enable-unicode`

>>	`make`

>>	`su`

>>	`make install`

>>	`exit`

>Add /opt/wx/2.8/bin to the PATH (if your shell is bash then edit /etc/profile or ~/.bash_profile) (On Suse 10.1 edit /etc/profile.local, it will only be available after a new login). An example PATH:
>
>	`export PATH=/usr/bin:/opt/wx/2.8/bin:$PATH`

>Add /opt/wx/2.8/lib to /etc/ld.so.conf (nano /etc/ld.so.conf), then run:
>
>	`ldconfig`
>	`source /etc/profile`

>That’s it. Now the linker will look in /opt/wx/2.8/lib for wx libraries and you will have a monolithic shared library unicode build.
>To check that things are working, type:
>
>	`wx-config --prefix`
>
>which should give you /opt/wx/2.8
>
>	`wx-config --libs`
>
>which should have at least:
>
>	`-L/opt/wx/2.8/lib -lwx_gtk2-2.8`

>but can contain other flags as well.
>
>	`which wx-config`
>
>should return /opt/wx/2.8/bin/wx-config


###3.2 安装codeblocks###

下载10.05源码或svn源码，解压至目录下
`./bootstrap`
注：

若报错 aclocal:configure.in:61: warning: macro `AM_OPTIONS_WXCONFIG’ not found in library
执行
{% highlight bash tabsize=4 %}
export ACLOCAL_FLAGS=”-I `wx-config –prefix`/share/aclocal”
{% endhighlight %}

或 
{% highlight bash tabsize=4 %}
echo `wx-config –prefix`/share/aclocal >> /usr/share/aclocal/dirlist
{% endhighlight %}

最后
{% highlight bash tabsize=4 %}
./configure –prefix=<dir>
make
make install
{% endhighlight %}
这样就安装完了。


###3.3 配置codeblocks###

配置文件在~/.codeblocks/ 下，将自己原先设置好的配置替换之。其中关于程序运行和调试的终端的说明(codeblocks默认的终端是xterm)如下:

1.  使用默认xterm
	如果你想使用默认的Xterm控制台，而系统没有安装可以在控制台输入

	`yum install xterm`

2.  使用gnome-terminal
	如果你想用系统终端，启动codeblocks，点击菜单栏 Settings ==> Environment settings
	把下面的“Terminal to launch console programs”的内容改成：

	`gnome-terminal -t $TITLE -x`

	就可以啦。
