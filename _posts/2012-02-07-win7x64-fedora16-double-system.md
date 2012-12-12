---
layout: post
title: win7x64+fedora16双系统安装
date: 2012-02-07 20:18:00
isOriginal: true
category: Usage
tags:
 - linux
 - fedora
 - win7
 - dual-system
keywords: linux fedora win7 双系统
description: win7x64+fedora16双系统安装
---


##1 前言##

win7的安装想必是最简单的，这里也不赘述了。由于是第一次尝试双系统安装，故本文主要记录的是双系统的安装过程。


##2 准备##

* Fedora-16-x86_64-DVD.iso（3.49G），由于机子支持64位，所以就准备安装64位的fedora（dvd版，不是604m的Fedora-16-x86_64-Live-Desktop.iso）
* 一个u盘（>=4G）或一个足够大的移动硬盘。
* 本机硬盘要有至少20G的空间装fedora（实际上我分了50G来装）


##3 安装##

###3.1 最简单但也不推荐的方法###

首先，使用liveusb-creator把镜像写入U盘。之后还要放iso到存储介质，这里分两种情况。

1. 如果你的u盘足够大，请直接将iso再拷入到u盘。
2. 如果你的u盘不够大，需要在本机的硬盘上或外接的移动硬盘另外分出一块足够大的分区，来放iso。根据网上的资料，都是分区必须为fat32 文件系统，不能为ntfs文件系统（我也是这样照做的，如果有机会我会试下ntfs的可行性），但是win7环境下，似乎处理比较麻烦。我是借助 wince系统来分出一块fat32的分区的。

然后，修改U盘下/syslinux/syslinux.cfg，改成append initrd=initrd.img linux askmethod（这样安装过程就不会需要联网）。

最后，插上u盘，先选择从u盘启动，在接下来的安装界面选择hard drive安装


###3.2  直接从u盘安装###

需要一个软件easyBCD。

利用虚拟光驱从iso中抽取出isolinux下vmlinuz和initrd.img，将这两个文件和iso共同放在u盘的根目录下。

然后打开EasyBCD，选择 Add New Entry — NeoGrub — Install

![alt easyBCD](/images/posts/win7x64-fedora16-double-system/3.2-1.png "easyBCD")

再点configure,在弹出来的 menu.lst  里添加：

{% highlight bash tabsize=4 %}
title install fedora 16                      #启动项里会多出的一项
kernel (hd1,0)/vmlinuz linux askmethod       #不需要联网安装
initrd (hd1,0)/initrd.img
{% endhighlight %}

注：硬盘的表示法说明如下
>IDE接口中的整块硬盘在Linux系统中可以表示为/dev/hd[a-z]，比如/dev/hda，/dev/hdb … … ，也可以表示为hd[0-n] ，其中n是一个正整数，比如hd0,hd1,hd2 … …
>
>硬盘的分区也有两种表示方法，一种是/dev/hd[a-z]X，这个a-z表示a、b、c……z ，X是一个从1开始的正整数；比如/dev/hda1，/dev/hda2 …. /dev/hda6，/dev/hda7 … … 值得注意的是/dev/hd[a-z]X，如果X的值是1到4,表示硬盘的主分区（包含扩展分区）；逻辑分区从是从5开始的，比如/dev/hda5肯定 是逻辑分区了。同理，还有另外一种表示方法 (hd[0-n],y)【y>=0】。
>
>http://www.linuxsir.org/main/node/127?q=node/127#1

这里附上另外两种写法，不知是否与前者等价，以后有机会测试一下
{% highlight bash tabsize=4 %}
title install fedora 16
kernel (sd1,0)/vmlinuz linux askmethod
initrd (sd1,0)/initrd.img
{% endhighlight %}
或
{% highlight bash tabsize=4 %}
title fedora 16
root (hd0,0)
kernel /vmlinuz repo=hd:/dev/sdb:/
initrd /initrd.img
boot
{% endhighlight %}

其实上面的这些几行都可以待到从usb引导后到grub的终端中再写。

成功从usb引导后，会来看到以下几个界面。

![alt usb引导](/images/posts/win7x64-fedora16-double-system/3.2-2.png "usb引导")
![alt usb引导](/images/posts/win7x64-fedora16-double-system/3.2-3.png "usb引导")

注意要在接下来的界面，选择好iso所在的磁盘分区（要结合自己的情况哦）。

![alt usb引导](/images/posts/win7x64-fedora16-double-system/3.2-4.png "usb引导")

做好上述这些，从u盘引导安装基本差不多了，剩下的就是fedora的安装了。

我选择的是自定义分区，需要给bios boot 分2m的空间，/boot 分了256m（应该够用了，据说是只要1-2百兆就可以了），swap分了4G（因为我的内存是这么大），/home分了10G（这个看你需求），剩下的都给了/目录。

注意在选择引导区的时候要选择/boot，不要选默认的。

安装结束后，启动项里还不会有fedora，还需要借助easyBCD，制作好一个启动项，如下

![alt bootstrap](/images/posts/win7x64-fedora16-double-system/3.2-5.png "bootstrap")

