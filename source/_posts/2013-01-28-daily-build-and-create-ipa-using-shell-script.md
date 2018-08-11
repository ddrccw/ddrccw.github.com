---
layout: post
title: 使用shell脚本build并创建ipa文件
date: 2013-01-28 21:06:23
isOriginal: true
category: iOS-dev
tags:
 - shell
 - ipa
 - daily build
 - iOS
 - build setting
keywords: shell ipa daily build iOS
description: 使用shell脚本build并创建ipa文件
---


## 前言

由于项目引入了敏捷开发，需要每天build出一个ipa供QA测试。此前是使用Xcode先achive出一个文件，再在organizer->achives里发布ipa，一直感觉也没啥不方便的。直到某天，装了InstaSign，突然发现无法用之前的方法codesign自己的ipa（真是自作孽啊T ^ T..），网上有人说是修改了系统自带的codesign和codesign_allocate，重装xcode也没用。不过还好能build出自己项目的app，利用iTune，再创建一个ipa文件。但是这种不得已的办法，对于需要每天都打ipa包的俺来说，实在是太繁琐了。于是就有了利用shell脚本来创建ipa的想法，也就有了此文。

## 正文

放狗搜了一下，发现唐巧的那篇[《给iOS工程增加Daily Build》][1]比较完整的阐述了daily build的整个过程，这里也就不赘述了。关于我关心的部分，基本思想也很简单：

1. 利用xcodebuild，build出程序文件\<PRODUCT_NAME\>.app。
2. 再将程序文件\<PRODUCT_NAME\>.app里的所有文件，放入Payload文件夹下，利用zip将其打包出一个ipa文件。

### 失败的思路
既然是利用shell，刚开始，我很自然的想到能否在xcode的build phase里添加run script，希望能在build出app后直接利用zip打包。但是经过测试，发现脚本是在**“ProcessProductPackaging（添加embedded.mobileprovision）”和“CodeSign”**之前就开始运行了，显然这个时侯zip的ipa不是有效的ipa。

那么，能不能直接shell也自己实现**“ProcessProductPackaging（添加embedded.mobileprovision）”和“CodeSign”**呢？

codesign还好说，但是前者，我实在是搞不透它用了啥内建的工具。

无奈，此方案作罢。


### 真·解决方法

1）简单的方法

先利用xcodebuild进行build，因为生成的目录结构是可知的，所以在脚本中给变量设置好相关路径，参考前面介绍的[那篇文章][1]，定位到相关文件，从而zip出ipa也是理所当然的。

2）蛋疼的方法

其实build时，已经有变量可以告诉我们需要的路径，参考[《xcode build setting reference》][2]，只不过这些build setting的作用范围仅限于build阶段，也就是xcodebuild进程的执行期间。

不过还好xcodebuild有个-showBuildSettings的参数，可以输出相应configuration的build setting，那么问题的关键就在于如何获取build setting并让其作用于我用于打包的shell脚本。

注：	因为-showBuildSettings中的build dir是xcode为project生成的唯一的一个目录,其位于`~/Library/Developer/Xcode/DerivedData`下,而用脚本启动的xcodebuild的build dir是位于脚本所在的当前目录，所以还需要做一些替换，不能获取了直接用。

我写的shell脚本如下：

```bash

#  Created by chenche on 13-1-21.

#!/bin/bash

cnt=1
if [ $# -ne $cnt ]; then
	echo "error param num, only allow 1 params(case sensitive)!"
	echo "example:"
	echo "package <configration> "
	exit -1
fi

buildSettings=""

xcodebuild -configuration $1 -target <ProductName> -showBuildSettings | grep --color=never -E '=' | awk -F"=" -v currentPath=$PWD '{
	gsub(/[[:blank:]]*/,"",$1);       #去除$1中的所有blank
	sub(/^[[:blank:]|"]*/,"",$2);     #去除头的blank,以及头的双引号
	sub(/[[:blank:]|"]*$/,"", $2);    #去除尾的blank,以及尾的双引号

	#print "export "$1"=\134\""$2"\134\"";
	#print $1"=\134\""$2"\134\"";
	if (tmp == "" && $1=="BUILD_DIR"){
		tmp=$2;
		sub(/\/Products$/, "/", tmp);
		pattern=tmp"[Products|Intermediates]*";
		#print pattern;
		#print tmp;
	}
	else if (tmp !="") {
		#如果是给gsub传pattern参数，pattern参数的值无需在两端加"/"
		#pattern1 = "/Build/[Products|Intermediates]*";
		#pattern1 = "/Build\\\//";
		#print pattern1;
		r = match($2, tmp);
		if (tmp != "" && r) {
			#print tmp" $2="$2;
			gsub(pattern, currentPath"/build", $2);
			#gsub(/Build\/[Products|Intermediates]*/, "00000000", $2);
			#print $2;
		}
	}

	print $1"="$2;   #key=value
}' >buildTmp

while read buf
do
	#echo $c
	arr[$c]=$buf
	let "c = $c + 1"
done <buildTmp

rm -rf buildTmp

#只有awk支持关联数组，shell本身的数组不支持,仅支持数字的下标
#echo "array len:" $c

for((i=0;i<$c;i++));
do
	key=${arr[$i]/=*/}
	value=${arr[$i]/*=/}

	#UID is readonly
	if [ "$key" != "UID" ]; then
#		if [ -d "$value" ]; then
#			echo $key,$value
#		fi
		export $key="$value"
	fi
done

echo -e "\033[33;40;1m---------start building <ProductName>...---------\033[0m"
xcodebuild -configuration $1 -target <ProductName>
echo -e "\033[33;40;1m---------build over------------------------------\033[0m"

echo -e "\033[33;40;1m---------start packaging <ProductName>...--------\033[0m"

IPA_PATH=$SRCROOT/ipa
PAYLOAD_PATH=$IPA_PATH/Payload

mkdir -p $PAYLOAD_PATH
cp -r $TARGET_BUILD_DIR/$WRAPPER_NAME $PAYLOAD_PATH

cd $IPA_PATH
zip -r $PRODUCT_NAME.ipa *
mv $PRODUCT_NAME.ipa $SRCROOT
rm -rf $IPA_PATH

echo -e "\033[33;40;1m---------<ProductName>.ipa is done.-------------------\033[0m"

```

上述脚本的不足之处，大概在对于xcodebuild执行失败未作处理，还是会生成一个无效的ipa。虽然xcodebuild执行的成功会输出“\*\* BUILD SUCCEEDED \*\*”,但总感觉单纯的基于这点的判断有点不靠谱。故还是作罢了，人工判断好了。

## 引申

写脚本的过程中，我也碰到过一些问题，汇总如下：

1. 普通数组和关联数组
	
	所谓普通数组，下标是数字；关联数组类似字典，下标可以是数字或字符串。网上搜了不少资料，都说shell支持关联数组，但是实际写脚本的过程，发现mac下的bash还是只支持索引数组，awk命令倒是支持关联数组。
	
	另外，可以man bash，发现相关内容，也证实了如上观点：
	
	>An array is created automatically if any variable is assigned to using the syntax name[subscript]=value.  **The subscript is treated as an arithmetic expression that must evaluate to a number greater than or equal to zero.**

2. 环境变量
	
	环境变量只能从父进程到子进程单向继承。也就是说，子进程的环境变量不会影响父进程的。
	
	基于1、2，也就说明无法利用awk export相关build setting，影响打包的shell脚本进程。

3. 脚本和awk的信息交互
	
	a 脚本->awk

	* 利用export，实现环境变量的单向继承。
	* awk有个-v的参数，可以传递变量
	
	b awk->脚本

	* eval, 使用起来有点像javascript中的eval
	* 导出信息到临时文件，再利用临时文件获取相关信息
	
因为build setting里的值情况比较复杂，最终我还是选择了用临时文件的方式获取awk过滤出来的build setting信息，再在shell脚本中export。最终，这样就可以利用build setting的相关值了。

## 总结

好吧，其实我是在吐槽自己花了老长一段时间憋出shell脚本的艰辛历程。。。虽然有点小题大做，但好歹是复习巩固了一下shell的相关知识，也算没白费劲~~~~


[1]: http://blog.devtang.com/blog/2012/02/16/apply-daily-build-in-ios-project/ "tangqiao"

[2]: http://developer.apple.com/library/mac/#documentation/developertools/Reference/XcodeBuildSettingRef/0-Introduction/introduction.html "xcode build setting"