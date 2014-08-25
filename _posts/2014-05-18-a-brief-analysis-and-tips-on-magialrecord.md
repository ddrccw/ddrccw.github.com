---
layout: post
title: 浅析MagicalRecord
date: 2014-05-18 16:16:53
isOriginal: true
category: iOS-dev
tags:
 - MagicalRecord
 - core data
keywords: MagicalRecord core data
description: 浅析MagicalRecord
---

## 前言

从云课堂ipad版本的初步引入到iphone版本的全面使用，不得不说[MagicalRecord][1]是一个十分有用的可以让开发人员快速上手复杂core data技术的开源库。趁着iphone版app审核，我也刚好抽空总结一下自己对[MagicalRecord][1]的认识。

## 正文

[MagicalRecord][1]基于Core Data框架，提供了一系列category方法和类能很方便地操作持久层数据。关于它的使用，官网上有例子，而且也很简单，这里不赘述，具体可以参看《[Magical Record: how to make programming with Core Data pleasant][2]》和《[MagicalRecord Tutorial for iOS][3]》。因为开发中的[MagicalRecord][1]3.0会有比较大的变化，这里先说明一下，下文的相关阐述均基于2.2的版本。

### 基本功能

从目录结构上看，简单的分有core和Categories两块。

* categories里面主要是对core data中`NSManagedObject，NSManagedObjectContext、NSManagedObjectModel、NSPersistentStore和NSPersistentStoreCoordinator`对象的方法扩展。
* core里面则是定义了一个MagicalRecord类，更多的从[core data stack][4]的角度，利用categories里的一些方法，全局性的管理。

从使用core data最最基本的过程上看，一般我们是先创建一个[core data stack][4]，然后在不同的context中，对数据对象增删改查。

* Categories模块相对比较底层，主要负责对context对象，以及context中的对象的维护。另外，还有一个特殊的模块是关于数据导入，一般是在处理完json数据获得NSDictionary和NSArray后，希望快速的将数据转成`NSManagedObject`对象时使用。具体使用可以参考《[IMPORTING DATA MADE EASY
][5]》。

	实际使用过程中，由于后台数据结构定义的比较灵活，我也只是简单的使用其中的数据映射功能，即mappedKeyName的使用。
	
* Core模块则是主要负责[core data stack][4]的创建和销毁（包括model version的merge），以及save操作的管理（其实save本质上是context控制的，但是为什么要设计在core模块中呢，这点会具体在后续的文字中体现）。


### 设计思想

#### core data stack

从`MagicalRecord+Setup.h`提供的几个setup方法依次层层深入，基本可以确定[MagicalRecord][1]中建议使用的[core data stack][4]模型是core data官方文档中介绍的最基本的模型，如下图

![alt coreDataStack](/images/posts/a-brief-analysis-and-tips-on-magialrecord/coreDataStack.png "coreDataStack")

即单个Persistent Object Store只对应单个Persistent Store Coordinator的模型。当然，这个只是它预先提供的一个实现。如果利用好categories模块的一些方法，我们还可以构建更加灵活的模型，这点会在后面谈扩展性的时候再说明。

#### context的管理

context的管理我觉得是最最核心的部分，因为它一方面涉及了性能上的问题，另一方面也涉及了如何保证不同context中数据一致性的问题。

***多个context的意义及常规设计***

虽然官例[CoreDataBooks](https://developer.apple.com/library/ios/samplecode/CoreDataBooks/Introduction/Intro.html)采用的是单个context的设计，但是这个设计显然并未充分发挥core data的强大功能，不足以满足复杂app的数据操作需求。一般常见的情况是，我们在增删改查数据的同时，需要尽可能的减少对UI的block。

关于这多个context的设计模式，我强烈建议读一下这两篇文章《[Multi-Context CoreData][6]》和《[Zarra on Locking][7]》。这里引用一下其中提到的三种设计模式，如下图。

1. The “Traditional” Multi-Context Approach
	
	![alt “Traditional”](/images/posts/a-brief-analysis-and-tips-on-magialrecord/Traditional.png "Traditional")

2. Parent/Child Contexts

	![alt “Parent-Child”](/images/posts/a-brief-analysis-and-tips-on-magialrecord/Parent-Child.png "Parent-Child")

3. Asynchronous Saving

	![alt “Asynchronous-Saving”](/images/posts/a-brief-analysis-and-tips-on-magialrecord/Asynchronous-Saving.png "Asynchronous-Saving")

再结合《[Concurrent Core Data Stacks – Performance Shootout][8]》（如果对更底层的细节分析感兴趣，可以继续看《[Backstage with Nested Managed Object Contexts][9]》）一文分析，基本可以确信前面提到的三种设计中，2的设计不太建议。1的设计可以兼容ios3，性能较快，但是未用到core data在iOS 5引入的新特性（Parent/Child Contexts），维护多个context相对比较麻烦。3的设计使得维护多个context更简单，但带来的是性能上的部分牺牲。

***MagicalRecord的实现***

前面说了一堆常见的多个context的设计模式，再来看看[MagicalRecord][1]又是如何设计的呢？

使用[MagicalRecord][1]的过程中必然会涉及这么几个context：

* rootSavingContext
* defaultContext
* 基于上述两种context，会频繁创建的child context

其中除了defaultContext是`NSMainQueueConcurrencyType`，其他的context均是`NSPrivateQueueConcurrencyType`

简单用图表示如下：
	
![alt “magicalRecord-context”](/images/posts/a-brief-analysis-and-tips-on-magialrecord/magicalRecord-context.png "magicalRecord-context")

注：连接线均表示Parent-Child的关系。

单看左边一条线，是不是很像前面提到设计模式3--Asynchronous Saving（好吧，其实就是它= =）。再看右边的child moc和左边的defaultContext的关系，咋看之下和设计模式1大不相同，但深入代码一看，还是有着某种共通之处。不过两个moc的通信，不单单通过直接的notification，而是借助rootSavingContext做了个中转。其中child moc通过save，将数据同步给rootSavingContext，而defaultContext则通过observer的方式，在rootSavingContext发生变化后做merge保证同步。这部分的设计思想，在`NSManagedObjectContext+MagicalRecord.m`文件中得到体现。

同样地，上述设计模式仅是[MagicalRecord][1]的默认模式。如果你有自己的想法，完全可以利用[MagicalRecord][1]提供的各种categories方法，设计适合自己的模式。

***多线程下context的管理***

众所周知，core data中NSPersistentStoreCoordinator的访问不是线程安全的。那么，简单的基于不同线程，然后创建相应的context是可行的吗？

看了一下源码`NSManagedObjectContext+MagicalThreading.m`,[MagicalRecord][1]也确实是这样设计的，只不过在main thread时，它会直接使用defaultContext；而非main thread下，会根据映射表判断是否需要基于defaultContext创建child context，也就是上图中的左边那层关系。但是这种设计其实存在着一些隐患。尤其对于刚接触[MagicalRecord][1]的开发人员，很容易忘乎所以的使用categories里提供的各种不用关心context创建的（即基于thread创建context）方法对数据增删查改。为啥说成隐患，因为有很大一部分情况下，操作数据是在UI展示那里处理的，也就是main thread的情况下，频繁的用那些api在defaultContext中save数据极有可能block UI（还记得defaultContext是`NSMainQueueConcurrencyType`么）。

还好[MagicalRecord][1]针对常规的情况提供了另外一条save数据的途径，也就是`MagicalRecord+Actions.m`里提供的一些非基于当前线程创建context的方法。其本质上也就是上图中右边的那条路线。

关于这块设计的利弊，可以看[MagicalRecord][1]作者自己的[观点](http://saulmora.com/2013/09/15/why-contextforcurrentthread-doesn-t-work-in-magicalrecord/)。另外，[MagicalRecord 3.0](https://github.com/magicalpanda/MagicalRecord/wiki/Upgrading-to-MagicalRecord-3.0)里，save的设计也发生了变更，和2.x之前版本比较，估计会有较大的不同。

建议：对应count，find操作直接使用defaultContext应该不会太大影响性能，但是一旦你要做save操作，请务必使用`MagicalRecord+Actions.m`里提供的那些非基于当前线程创建context的save方法。

### 限制与扩展性

这里所谓的限制是指你直接使用默认的实现而不做任何额外的定制。这方面，个人觉得[core data stack][4]的默认实现虽然满足基本需求，但对于某些项目来说，可能还存在多个sqlite或一个PersistentStoreCoordinator同时有多个不同的PersistentStore等这样一些更复杂的模式。针对这些情况，就需要你自己来设计具体的代码啦。不过还好[MagicalRecord][1]的实现大部分采用category的形式，所以扩展起来也很便利。

#### category 

实际项目中，我尝试在三个地方做了点简单的扩展。

1. 数据import
	
	客户端有个managed object(简称mo)会在接口m和接口n（均返回json数据）中共用，mo的某个property a相应的有两个mapkey a1和a2（map时的优先级a1>a2）。正常逻辑中，a1用于m，a2用于n。但是实际情况是，由于后端接口要保证数据兼容性，接口n中同时包含了a1和a2都可以map到值的两个字段，更恶心的是只有a2对应的字段是有正确的值的，a1对应的字段值是null，因此基于map的优先级，使用import的方法总是取a1对应的null（import时会认为`[NSNull null]`是有效的值，并最终将value赋值成nil）。
	
	虽然调整两者的优先级可以解决这个问题，但谁又能保证接口m不会存在同样的问题呢，所以我就参考[MagicalRecord][1]的方式，给NSManagedObject创建了一个category，增加了数据的预处理函数，保证能先把没用的`[NSNull null]`统一处理成nil值，那么在后续的import过程中也就避免了上述情况。
	
2. 分页操作
	
	形式上[MagicalRecord][1]对数据的操作行为很像数据库，但它竟然没提供分页相关的操作。基于某些需求，我也就顺便参考了它的代码风格，补充了一些分页操作函数。

3. core data stack

	实际开发过程中，可以发现有些对象数据不需要存入数据库，那么[MagicalRecord][1]的默认的[core data stack][4]模型也就不足以满足需求。不过还好一个PersistentStoreCoordinator同时支持多个PersistentStore，也就是说可以同时有`NSSQLiteStoreType`和`NSInMemoryStoreType`。了解了这一点后，剩下的也就是需要稍微利用一下[MagicalRecord][1]的一些方法自己实现整个stack的setup，实现起来并不复杂~

### 总结

[MagicalRecord][1]确实是一个值得使用的开源库。但是在便利地使用它的同时，一定也要相应的了解一下其中的设计，做到扬长避短，物尽其用:)

## 参考

1）[https://github.com/magicalpanda/MagicalRecord][1]

2）["Magical Record: how to make programming with Core Data pleasant"][2]

3）[magicalrecord-tutorial-ios][3]

4）[coreDataStack][4]

5）[IMPORTING DATA MADE EASY][5]

6）[Multi-Context CoreData][6]

7）[Zarra on Locking][7]

8）[Concurrent Core Data Stacks – Performance Shootout][8]

9）[Backstage with Nested Managed Object Contexts][9]

[1]: https://github.com/magicalpanda/MagicalRecord "MagicalRecord"

[2]: http://yannickloriot.com/2012/03/magicalrecord-how-to-make-programming-with-core-data-pleasant/#sthash.n5uCiXVB.dpbs "Magical Record: how to make programming with Core Data pleasant"

[3]: http://www.raywenderlich.com/56879/magicalrecord-tutorial-ios "magicalrecord-tutorial-ios"

[4]: https://developer.apple.com/library/ios/documentation/DataManagement/Devpedia-CoreData/coreDataStack.html "coreDataStack"

[5]: http://www.cimgf.com/2012/05/29/importing-data-made-easy/ "IMPORTING DATA MADE EASY"

[6]: http://www.cocoanetics.com/2012/07/multi-context-coredata/ "Multi-Context CoreData"

[7]: http://www.cocoanetics.com/2013/02/zarra-on-locking/ "Zarra on Locking"

[8]: http://floriankugler.com/blog/2013/4/29/concurrent-core-data-stack-performance-shootout "Concurrent Core Data Stacks – Performance Shootout"

[9]: http://floriankugler.com/blog/2013/5/11/backstage-with-nested-managed-object-contexts "Backstage with Nested Managed Object Contexts"

