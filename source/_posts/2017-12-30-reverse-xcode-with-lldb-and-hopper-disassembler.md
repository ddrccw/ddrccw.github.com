---
layout: post
title: 小试Xcode逆向：app内存监控原理初探
date: 2017-12-30 19:50:14
isOriginal: true
category: iOS-dev
tags:  
 - iOS
 - lldb
 - Xcode
 - hopper disassembler
keywords: lldb Xcode hopper disassembler reverse
description: 
---

# 前言

最近看到公司同事的《iOS内存那些事》系列文章，其中的一篇文章讲了他在研究WebKit中内存管理的时候，发现可以用phys_footprint来衡量内存，其结果和xcode debug显示的值基本一致。文章通读下来，收获颇丰~回味之余，突然脑洞了一下，为啥不直接逆向一下Xcode，学习一下xcode debug app时它是怎么实现内存监控的？刚好最近在自学逆向知识，顺便也来练练手~

# 动手实践

### 准备一个小项目
运行一下，我们可以在debug面板看到memory report信息
![undefined](/images/reverse-xcode-with-lldb-and-hopper-disassembler/debug.png){:height="100%" width="100%"}


### lldb和hopper的使用
* 通过如下操作，我们可以直接attach Xcode调试

```bash
➜  ~ lldb -n Xcode
(lldb) process attach --name "Xcode"
Process 969 stopped
* thread #1, queue = 'com.apple.main-thread', stop reason = signal SIGSTOP
    frame #0: 0x00007fffe2bcb34a libsystem_kernel.dylib`mach_msg_trap + 10
libsystem_kernel.dylib`mach_msg_trap:
->  0x7fffe2bcb34a <+10>: retq
    0x7fffe2bcb34b <+11>: nop

libsystem_kernel.dylib`mach_msg_overwrite_trap:
    0x7fffe2bcb34c <+0>:  movq   %rcx, %r10
    0x7fffe2bcb34f <+3>:  movl   $0x1000020, %eax          ; imm = 0x1000020
Target 0: (Xcode) stopped.

Executable module set to "/Applications/Xcode.app/Contents/MacOS/Xcode".
Architecture set to: x86_64h-apple-macosx.
(lldb) c
Process 969 resuming
(lldb)
```

* 来到Xcode debug面板，可以直接看到app运行时的内存信息。先小试一下那个内存信息栏能否响应点击操作。加个断点，尝试点击一下那个内存栏，bingo，顺利跑到断点处~

```bash
(lldb) b -[NSResponder mouseUp:]
Breakpoint 1: where = AppKit`-[NSResponder mouseUp:], address = 0x00007fffcb070177
Process 969 stopped
* thread #1, queue = 'com.apple.main-thread', stop reason = breakpoint 1.1
    frame #0: 0x00007fffcb070177 AppKit`-[NSResponder mouseUp:]
AppKit`-[NSResponder mouseUp:]:
->  0x7fffcb070177 <+0>: pushq  %rbp
    0x7fffcb070178 <+1>: movq   %rsp, %rbp
    0x7fffcb07017b <+4>: popq   %rbp
    0x7fffcb07017c <+5>: jmp    0x7fffcaf94724            ; forwardMethod
Target 0: (Xcode) stopped.(lldb)
```

因为Xcode肯定是x86_64架构编译的，所以通过`po $rdi`，可以看到点击方法的对象是`<NSTextField: 0x7fb7aed38280>`。 第一直觉告诉我，NSTextField是不是类似于UITextField，有text属性可以被赋值？查看了一下apple文档，它的父类` NSControl`有个`stringValue`属性可以设置，设断点，发现面板上内存变化时，断点触发了，`bt`一下，可以看到如下信息(注意，要先确定触发断点的是展示内存的那个NSTextField)

```bash
(lldb) bt
* thread #1, queue = 'MainQueue: -[DBGLLDBSession processProfileDataString:]_block_invoke', stop reason = breakpoint 1.1
  * frame #0: 0x00007fffcaef1897 AppKit`-[NSControl setStringValue:]
    frame #1: 0x0000000125f5b305 DebuggerUI`__54-[DBGGaugeMemoryEditor _setupTopSectionComponentViews]_block_invoke + 955
    frame #2: 0x0000000106e49e36 DVTFoundation`-[DVTObservingBlockToken observeValueForKeyPath:ofObject:change:context:] + 610
    frame #3: 0x00007fffced5035d Foundation`NSKeyValueNotifyObserver + 350
    frame #4: 0x00007fffced4fbf4 Foundation`NSKeyValueDidChange + 486
    frame #5: 0x00007fffcee8e867 Foundation`-[NSObject(NSKeyValueObservingPrivate) _changeValueForKeys:count:maybeOldValuesDict:usingBlock:] + 944
    frame #6: 0x00007fffced1395d Foundation`-[NSObject(NSKeyValueObservingPrivate) _changeValueForKey:key:key:usingBlock:] + 60
    frame #7: 0x00007fffced7c23b Foundation`_NSSetObjectValueAndNotify + 261
    frame #8: 0x0000000106e8a742 DVTFoundation`__DVTDispatchAsync_block_invoke + 97
    frame #9: 0x00007fffe2a77524 libdispatch.dylib`_dispatch_call_block_and_release + 12
    frame #10: 0x00007fffe2a6e8fc libdispatch.dylib`_dispatch_client_callout + 8
    frame #11: 0x00007fffe2a849a0 libdispatch.dylib`_dispatch_queue_serial_drain + 896
    frame #12: 0x00007fffe2a77306 libdispatch.dylib`_dispatch_queue_invoke + 1046
    frame #13: 0x00007fffe2a7b908 libdispatch.dylib`_dispatch_main_queue_callback_4CF + 505
    frame #14: 0x00007fffcd35bbc9 CoreFoundation`__CFRUNLOOP_IS_SERVICING_THE_MAIN_DISPATCH_QUEUE__ + 9
    frame #15: 0x00007fffcd31cc0d CoreFoundation`__CFRunLoopRun + 2205
    frame #16: 0x00007fffcd31c114 CoreFoundation`CFRunLoopRunSpecific + 420
    frame #17: 0x00007fffcc87cebc HIToolbox`RunCurrentEventLoopInMode + 240
    frame #18: 0x00007fffcc87ccf1 HIToolbox`ReceiveNextEventCommon + 432
    frame #19: 0x00007fffcc87cb26 HIToolbox`_BlockUntilNextEventMatchingListInModeWithFilter + 71
    frame #20: 0x00007fffcae15a54 AppKit`_DPSNextEvent + 1120
    frame #21: 0x00007fffcb5917ee AppKit`-[NSApplication(NSEvent) _nextEventMatchingEventMask:untilDate:inMode:dequeue:] + 2796
    frame #22: 0x000000010743d98e DVTKit`-[DVTApplication nextEventMatchingMask:untilDate:inMode:dequeue:] + 390
    frame #23: 0x00007fffcae0a3db AppKit`-[NSApplication run] + 926
    frame #24: 0x00007fffcadd4e0e AppKit`NSApplicationMain + 1237
    frame #25: 0x00007fffe2aa4235 libdyld.dylib`start + 1
    frame #26: 0x00007fffe2aa4235 libdyld.dylib`start + 1
```

从函数调用栈上，我们可以看出，NSTextField值的变化是通过kvo某个值实现的。`image lookup -rn '\[DBGGaugeMemoryEditor\ `，可以发现它位于`/Applications/Xcode.app/Contents/PlugIns/DebuggerUI.ideplugin/Contents/MacOS/DebuggerUI`, 把二进制文件拖到hooper里看一下`-[DBGGaugeMemoryEditor _setupTopSectionComponentViews]_block_invoke`的实现。

￼![undefined](/images/reverse-xcode-with-lldb-and-hopper-disassembler/code.png){:height="100%" width="100%"}

通过查看相应的实现，可以知道是它通过debugSession实例获取相关信息的，再结合调用栈信息，debugSession肯定就是DBGLLDBSession。同样的，通过lldb，我们可以找到DBGLLDBSession位于`/Applications/Xcode.app/Contents/PlugIns/DebuggerLLDB.ideplugin/Contents/MacOS/DebuggerLLDB`，企图通过hooper看看它的实现，然而并没看出啥有用信息。只能继续尝试lldb断点。`po $rdx`打印它的参数，似乎出了一串奇怪的字符串？！

```shell
(lldb) b -[DBGLLDBSession processProfileDataString:]
Breakpoint 3: where = DebuggerLLDB`-[DBGLLDBSession processProfileDataString:], address = 0x0000000115f99c52
(lldb) c
Process 4489 resuming
Process 4489 stopped
* thread #30, name = '<DBGLLDBSessionThread (pid=51274)>', stop reason = breakpoint 3.1
    frame #0: 0x0000000115f99c52 DebuggerLLDB`-[DBGLLDBSession processProfileDataString:]
DebuggerLLDB`-[DBGLLDBSession processProfileDataString:]:
->  0x115f99c52 <+0>: push   rbp
    0x115f99c53 <+1>: mov    rbp, rsp
    0x115f99c56 <+4>: push   r15
    0x115f99c58 <+6>: push   r14
Target 0: (Xcode) stopped.
(lldb) po $rdi
<DBGLLDBSession: 0x7f9c998bec90>

(lldb) po $rdx
num_cpu:8;host_user_ticks:3332988;host_sys_ticks:2148237;host_idle_ticks:23546214;elapsed_usec:1513647973058229;task_used_usec:43128;thread_used_id:1;thread_used_usec:841463;thread_used_name:;thread_used_id:4;thread_used_usec:595;thread_used_name:;thread_used_id:5;thread_used_usec:2130;thread_used_name:576562546872656164;thread_used_id:6;thread_used_usec:3012;thread_used_name:636f6d2e6170706c652e75696b69742e6576656e7466657463682d746872656164;thread_used_id:11;thread_used_usec:255;thread_used_name:;total:17179869184;used:14274596864;rprvt:0;purgeable:0;anonymous:57823232;energy:98435210380;
```

### google大法，lldb源码查看

随便抽了一个关键字`host_sys_ticks`，google了一下，发现这串字符，竟然来自lldb项目里的debugserver！先查看了一下本机的lldb版本（lldb-900.0.45），在apple open source的[官网](https://opensource.apple.com/tarballs/lldb/)上没找到这个版本的lldb。无奈下只能去[lldb官网](https://lldb.llvm.org/source.html)clone了一份最新的代码，虽然不知道apple是基于哪个lldb版本开发的，但是看最新的实现总不会错~

通过查看debugserver源码，可以发现前面那串字符串是在`std::string MachTask::GetProfileData(DNBProfileDataScanType scanType)`生成的，[里面](https://github.com/llvm-mirror/lldb/blob/master/tools/debugserver/source/MacOSX/MachTask.mm)有各种profile信息，比如cpu，memory等。

**大胆猜想一下，Xcode的内存监控正是定时通过获取debugserver的这个方法的信息来展示的！！！**



另外，关于debugserver，可以看[这里](http://iphonedevwiki.net/index.php/Debugserver)的介绍。简单来说，它是运行在ios上的一个可以接受lldb前端命令的『远程调试』服务器。在越狱设备上，可以通过它做很多trick，这里暂且不表。


# 验证

### 初步
扒出memory profile的[代码实现](https://github.com/llvm-mirror/lldb/blob/master/tools/debugserver/source/MacOSX/MachVMMemory.cpp)如下：

```c
static void GetPurgeableAndAnonymous(task_t task, uint64_t &purgeable,
                                     uint64_t &anonymous) {
#if defined(TASK_VM_INFO) && TASK_VM_INFO >= 22

  kern_return_t kr;
  mach_msg_type_number_t info_count;
  task_vm_info_data_t vm_info;

  info_count = TASK_VM_INFO_COUNT;
  kr = task_info(task, TASK_VM_INFO_PURGEABLE, (task_info_t)&vm_info,
                 &info_count);
  if (kr == KERN_SUCCESS) {
    purgeable = vm_info.purgeable_volatile_resident;
    anonymous =
        vm_info.internal + vm_info.compressed - vm_info.purgeable_volatile_pmap;
  }

#endif
}
```

再看看前面获取的anonymous的字节值，57823232对应的正是55.1445007MB，即debug内存面板展示的值！

这里再附上同事发现的WebKit内存计算公式，可以比较一下理解，具体参看[这里](https://raw.githubusercontent.com/apple/darwin-xnu/master/osfmk/kern/task.c)，搜索一下`phys_footprint`便知。

`phys_footprint = (internal - alternate_accounting) + (internal_compressed - alternate_accounting_compressed) + iokit_mapped + purgeable_nonvolatile + purgeable_nonvolatile_compressed + page_table`

### 具体

本来按理说是应该直接把上述代码拷出来具体执行进一步确认一下。但是意外的找到了一个偷懒的方法。既然Xcode是通过debugserver获取到相关信息，那么有没有办法直接和debugserver交互来获取信息呢？

继续翻看了一下lldb代码，lldb前端确实就存在相应的命令来触发debugserver执行。

通过代码可以发现`std::string MachTask::GetProfileData(DNBProfileDataScanType scanType)`会在`RNBRemote`接受到消息包`qGetProfileData`时执行，而lldb原来可以直接通过`process plugin packet send`命令来给debugserver发送包命令。

换句话说，也就是直接在Xcode终端直接执行命令验证
![undefined](/images/reverse-xcode-with-lldb-and-hopper-disassembler/result.png){:height="100%" width="100%"} 

结合lldb脚本的使用，目测验证起来并不难。

当然，最终可能还是要直接拷出一下那段代码验证一下，这个后面有空再试试。


# 总结

* 虽然咋看下来全文一路顺畅，但是作为一名逆向新手，中间还是遇到了不少问题，不过收获也是很大滴~
* lldb和hopper确实很强大，深入学习一下lldb源码还是有必要的，其中还是有不少有趣的地方值得挖掘。
* 通过Xcode debug机制的原理探寻，我们可以学习它的profile实现并且自己撸一遍做一套性能监控.

# 参考文献

<https://store.raywenderlich.com/products/advanced-apple-debugging-and-reverse-engineering>