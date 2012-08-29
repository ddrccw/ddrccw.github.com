---
layout: post
title: Vmware 8安装Lion
date: 2012-02-22 14:18:00
isOriginal: true
category: 日常
tags:
 - VMware
 - Lion
---


##1 前言##

苹果系统对Intel的CPU支持较好，以下的安装可能不适用于AMD的CPU（我的电脑是Inspiron 灵越™ 14R锋型版,win7 64位）

##2 准备##

* VMware-workstation-full-8.0.2-591240.exe      虚拟机软件
* [unlock-all-v102][1]  破解补丁，用于虚拟机安装Mac操作系统
* [Mac OSX Lion 10.7.3 Retail.dmg][2] 来自海盗湾的种子，下载Mac Lion正式版系统
* 7-zip  抽取数据用。
* ultraISO 将dmg转换成ISO

##3 步骤##

###3.1 安装虚拟机，并打好破解补丁。###

虚拟机安装就不多说了，打补丁前，请将以下服务先停止（运行services.msc，在“服务”中操作）。

* VMAuthdService           已停止
* VMnetDHCP                已停止
* VMUSBArbService          已停止
* VMwareNAT Service        已停止
* VMwareHostd              已停止

打补丁：以系統管理員身份執行 unlock-all-v102\windows里的install.cmd
然后再将先前停止的服务启动。

###3.2 提取mac系统文件并转成iso###
因为下好的Mac操作系统文件是dmg，需要先用7-zip打开，将Mac OSX Lion 10.7.3 Retail.dmg\InstallMacOSX.pkg\InstallESD.dmg其抽取出来

![alt 系统文件转换iso](/images/posts/vmware8-install-lion/3.2-1.jpeg "抽取dmg")

再利用ultraISO将该文件转换为ISO，菜单栏-》工具-》格式转换

![alt 系统文件转换iso](/images/posts/vmware8-install-lion/3.2-2.jpeg "dmg格式转换")

##3.3 安装mac lion系统##

###3.3.1 创建虚拟机###

1. 选择自定义创建

	![alt 选择自定义创建](/images/posts/vmware8-install-lion/3.3.1-1.1.png "选择自定义创建1")
	![alt 选择自定义创建](/images/posts/vmware8-install-lion/3.3.1-1.2.png "选择自定义创建2")

2. 设置好cpu，内存（>2G），网络，I/O控制器，磁盘（SCSI）用默认的，磁盘空间至少要20G

	![alt 基本设置](/images/posts/vmware8-install-lion/3.3.1-2.png "基本设置")

3. 创建完虚拟机后，需要对其进行设置

	![alt 其他设置](/images/posts/vmware8-install-lion/3.3.1-3.png "其他设置")

	* 要移除软盘驱动器，否则安装时会出问题。
	* 设置CD/DVD→高級设置→SCSI 0:2
	* 设置显卡→3D图形加速

###3.3.2 安装mac lion虚拟机###

0. 准备安装

	![alt 准备安装](/images/posts/vmware8-install-lion/3.3.2-0.jpeg "准备安装")

1. 设置完语言后，格式化磁盘，并分区。

	![alt 格式化分区](/images/posts/vmware8-install-lion/3.3.2-1.1.jpeg "格式化分区")

	![alt 格式化分区](/images/posts/vmware8-install-lion/3.3.2-1.2.jpeg "格式化分区")

2. 开始安装

	![alt 安装](/images/posts/vmware8-install-lion/3.3.2-2.1.jpeg "安装")

	![alt 安装](/images/posts/vmware8-install-lion/3.3.2-2.2.jpeg "安装")

	![alt 安装](/images/posts/vmware8-install-lion/3.3.2-2.3.jpeg "安装")

	![alt 安装](/images/posts/vmware8-install-lion/3.3.2-2.4.jpeg "安装")

	![alt 安装](/images/posts/vmware8-install-lion/3.3.2-2.5.jpeg "安装")

3. 建立好自己的账号，登陆后就可以开始体验了。

	![alt 体验](/images/posts/vmware8-install-lion/3.3.2-3.jpeg "体验")

##3.3.3  安装VMware Tools，是为了能够调整分辨率##

	安裝VMware Tools，需要加载unlock-all-v102\tools\darwin.iso鏡像文件。


![alt 其他](/images/posts/vmware8-install-lion/3.3.3-1.jpeg "其他")
![alt 其他](/images/posts/vmware8-install-lion/3.3.3-2.jpeg "其他")

	这样Mac系统就安装完了，好好玩吧^_^~~~~~~



[1]: http://pan.baidu.com/share/link?shareid=6830&uk=1678482707
[2]: http://pan.baidu.com/share/link?shareid=6831&uk=1678482707
