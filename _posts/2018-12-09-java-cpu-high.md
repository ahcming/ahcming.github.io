---
title        : "线上JAVA进程CPU高处理过程"
author       : ahcming
description  : 
date         : 2018-12-09 14:50
layout       : post
tag          : ["work", "original", "jvm"]
blog         : true
---

前几日,收到线程服务器CPU超过50%的报警, 赶紧秒开VPN登上服务器

### top
首先通过top命令, 查看服务器的各项指标, 比如CPU使用情况, 内存使用情况, 服务器的负载; 

<img src="/assets/images/linux/linux-top.png" width="650" height="400" alt="top" />

由于当时情况紧急,没空截图, 当时的情况是负载在7~10之间, CPU使用率在400~600%, 内存率正常

找到进程ID, 比如3233, 再找到进程内负载比较高的线程ID

> top -Hp 3233

<img src="/assets/images/linux/linux-top-Hp.png" width="650" height="400" alt="top" />

可以看出CPU占用高的线程ID, 此处是20981, 20974, 20975, 20976, 20977, 20978, 20979, 20980

```
  PID USER      PR  NI    VIRT    RES    SHR S %CPU %MEM     TIME+ COMMAND                                                                                  
20981 tomcat    20   0 14.139g 8.988g  14200 R 99.9 28.8  79:53.47 java                                                                                     
20974 tomcat    20   0 14.139g 8.988g  14200 R 99.9 28.8  79:56.24 java                                                                                     
20975 tomcat    20   0 14.139g 8.988g  14200 R 99.9 28.8  79:53.03 java                                                                                     
20976 tomcat    20   0 14.139g 8.988g  14200 R 99.9 28.8  79:53.09 java                                                                                     
20977 tomcat    20   0 14.139g 8.988g  14200 S 99.9 28.8  79:54.50 java                                                                                     
20978 tomcat    20   0 14.139g 8.988g  14200 R 99.9 28.8  79:53.72 java                                                                                     
20979 tomcat    20   0 14.139g 8.988g  14200 R 99.9 28.8  79:53.73 java                                                                                     
20980 tomcat    20   0 14.139g 8.988g  14200 R 99.9 28.8  79:53.85 java                                                                                     
20946 tomcat    20   0 14.139g 8.988g  14200 S  0.0 28.8   0:00.00 java  
```

### jstack

CPU高, 一般是有进程在进行密集计算, 比如无限循环, 频繁进行JSON序列化反序列化, 或者图形计算; 

这些情况都是不正常的, 99.99999%都是我们的代码有问题, 那我们怎么定位到问题代码呢

我们自然的想法是如果我们能获取此时是哪个线程, 最好能具体到哪个类, 哪个方法, 这样排查的范围就可以大大缩小了

jstack命令就能把java进程内部的线程信息以调用栈的形式dump出来

> jstack 3233 > /tmp/3233.log

<img src="/assets/images/linux/java-stack.png" width="650" height="400" alt="jstack" />

从中我们可以看出此时java进程里的所有线程, 每个线程的状态, 线程ID(截图里的nid)

此处有一点小小问题, jstack里线程ID是16进制, 而top显示的是10进制, 我们需要把top的线程ID转成16进制; 转换方法有很多, 我喜欢用python的print方法

假设3233内的有问题线程ID是30417 

<img src="/assets/images/linux/python-print.png" width="650" height="100" alt="python print" />

然后我们在3233.log文件里搜索76d1一下, 幸运的话能看到具体的类和方法名了

#### Unable to open socket file: target process not responding or HotSpot VM not loaded

在实际环境中, 为了保证服务器安全, 服务器上的每个进程或实例都是用单独的用户权限管理, 比如nginx就是用nginx组的nginx用户启动停止, tomcat就是用tomcat组的tomcat用户管理
而我们开发登录线上服务器一般是以自己名字命令的用户, 这个时候, 如果我们直接使用 jstack {tomcat_pid}, 会提示

```text
{tomcat_pid}: Unable to open socket file: target process not responding or HotSpot VM not loaded
The -F option can be used when the target process is not responding
```

如果这个时候, 我们按提示,简单粗暴的使用 

> jstack -F {tomcat_pid} 

也能导出数据, 但是导出的线程信息里是没打印nid信息的, 这样还是不方便我们定位问题

解决方法有2个:
+ 切tomcat用户执行
+ 使用超级管理员权限

> su - tomcat -c "jstack {tomcat_pid} > /tmp/{tomcat_pid}.log"

而一般像nginx, tomcat这样的用户都是没有分配登录权限的, 也就是没有分配shell, 我们还需要去修改/etc/passwd里的配置; 

每一步都不舒坦啊, 搞程序的就是这样的, 遇到困难不要慌, 不要退缩, 要告诉自己, 这是学习的好机会

`纸上得来终觉浅, 绝知此事需躬行`

### jstat

当然我就没那么幸运了, 我的线程ID在jstack文件里找到的是GC进程的ID, 也就是说JVM一直在执行GC导致CPU占用高, 那怎么查看当前进程的gc情况呢

#### -gc

jstat -gc 工具可以打印出JVM里堆空间各个区分配的内存大小, 已使用的内存大小, GC的次数, 累计耗时信息

我们通过各个区的大小和增长速度, 大致可以判断出是有内存泄漏还是区分配大小是否合理

```shell
jstat -gc {pid} {interval}
```

<img src="/assets/images/linux/java-jstat-gc.png" width="1200" height="250" alt="jstat-gc" />

各列含义说明:
- S0C: Survivor0区的容量 #C是Capacity, 容量的意思, 单位:字节, 下同
- S1C: Survivor1区的容量
- S0U: Survivor0区的使用量 # U是used, 使用量的意思, 单位:字节, 下同
- S1U: Survivor1区的使用量
- EC: Eden区的容量
- EU: Eden区的使用量
- OC: Old区的容量
- OU: Old区的使用量
- MC: Method区的容量
- MU: Method区的使用量
- CCSC: 类区的容量
- CCSU: 类区的使用量
- YGC: 从进程启动到现在累计Young GC次数; 如果两次打印之间, 数字增加了, 表明刚刚发生了一次YGC
- YGCT: 从进程启动到现在累计Yong GC耗时, 单位:秒
- FGC: 从进程启动到现在累计Full GC次数; 如果两次打印之间, 数字增加了, 表明刚刚发生了一次FGC
- FGCT: 从进程启动到现在累计Full GC耗时
- GCT: 从进程启动到现在累计总GC耗时

#### -gcutil

-gc显示的每个区的大小, -gcutil可以看到每个区的使用比例, 可以从另外一个维度来看每个区的使用情况

```shell
jstat -gcutil {pid} {interval}
```

<img src="/assets/images/linux/java-jstat-gcutil.png" width="700" height="160" alt="jstat-gcutil" />


各列含义说明:
- S0: Survivor0区使用率 
- S1: Survivor1区使用率, Survivor0区与Survivor1区总有一个是空的
- E: Eden区使用率
- O: Old区使用率
- M: Method区使用率
- CCS: 类区使用率
- YGC: 从进程启动到现在累计Young GC次数; 如果两次打印之间, 数字增加了, 表明刚刚发生了一次YGC
- YGCT: 从进程启动到现在累计Yong GC耗时, 单位:秒
- FGC: 从进程启动到现在累计Full GC次数; 如果两次打印之间, 数字增加了, 表明刚刚发生了一次FGC
- FGCT: 从进程启动到现在累计Full GC耗时
- GCT: 从进程启动到现在累计总GC耗时

#### -gccause

gccause可以查看最近2次gc发生的原因

```shell
jstat -gccause {pid} {interval}
```

<img src="/assets/images/linux/java-jstat-gccause.png" width="930" height="200" alt="jstat-gccause" />

各列含义说明(S0,S1,E,O,M,CCS,YGC,YGCT,FGC,FGCT,GCT跟gcutil的含义相同):
- LGCC: 上一次gc发生的原因
- GCC: 本次gc发生的原因

一般gc原因的解释, [参考](https://blog.csdn.net/foolishandstupid/article/details/78078238):
- No GC: 没有发生GC
- _java_lang_system_gc: 通过代码显示调用System.gc()触发; 还有一种情况是，在visualvm等软件上通过JMX监控时有点击触发SystemGC的按钮
- _jvmti_force_gc: JVMTI（JVM Tool Interface）是 Java 虚拟机所提供的 native 编程接口; 通过jvmti方式触发的GC
- _gc_locker: 当最后一个位于jni临界区内的线程退出临界区时，发起一次CGCause为_gc_locker的GC
- _heap_inspection: 这个类型主要是jmap -hisot:live命令时会触发
- _heap_dump:
- _wb_young_gc:
- _allocation_failure: 这个就是常见的内存分配失败触发的GC。比如在new 对象时
- _metadata_GC_threshold: 这个用于在metaspace区域分配时分配不下，从而触发的GC
- _cms_initial_mark, _cms_final_remark: 这2个就是对于设置的CMS回收器时，有一个background式的回收时的初始标记和最终标记阶段
- _cms_concurrent_mark: cms的background式GC
- _adaptive_size_policy: 这个在ps中动态调整堆以及各个区大小时用到
- _g1_inc_collection_pause: 这个是设置的G1回收器时，若分配不下触发的GC的cause
- _g1_humongous_allocation: 这个用于分配超大对象失败时触发GC
- _last_ditch_collection:  这个也是用于在metaspace区域分配不下时，最后的一次回收

FGC会Stop-the-World, 如果频繁的发生FGC会让大部分的线程都处于WAIT状态, 时间一长整个服务器的负载开始上升, 整个Java进程的TPS下降, 而外部的请求数却没有减少并响应时长开始增加甚至出现超时现象

而我当时看到的FGC每2秒就执行一次, 而且FGC之后, Old区的使用率并没有下降多少, gc的原因都是Allocation Failure

一般频繁发生FGC要么堆空间配置不合理, 要么代码有内存有泄漏, old区被打满且FGC后, 内存无法释放 

首先怀疑代码有无内存泄漏, 现在只能出最后的大招了, 把java内存快照dump出来分析分析

### jmap

```shell
jmap -dump:format=b,file=filname {pid}
```

结果dump出来的文件足足有11个G, 压缩后也有2G, 下载速度300+K/s, 需要1个半小时, 头疼!!!

没办法, 吹出去的牛跪着也要实现, 慢慢下载吧, 期间网络中断2次, 花了5,6个小时终于download了下来

### jhat, jvisualvm, jprofiler

你以为这就完了吗? 打开一看就知道问题在哪里了吗? No

因为dump文件太大, 我用了jhat, jvisualvm都多次把我本机打成了OOM; 我只能把我本机的16G内存分配14个G给jvisualvm, 等了半个小时才打开

> jvisualvm -J-xmx14g

你以为这就完了吗? no, 每个按钮点一下又要等半小时, 实在受不了, 求教同行, 得知有个神器叫jprofiler, 赶紧下载之, 又是贼慢; 
但好歹是唯一的希望, 只要让我看到dump里的对象是啥, 我就能定位这个内存泄漏的原因

好不容易等到jprofiler下载完成, 又过了半小时终于打开了dump文件, 现在的问题只剩下怎么从打开的面板里分析出哪些对象是异常的

你以为打开之后, 就一目了然了看出哪里内存泄漏了吗? too young ~~ 

一般是从对象大小, 对象个数维度来分析; 
- 如果有个对象是自定义类, 且数量很多, 应该是重点分析目标; 
- 如果有Map对象很大, 也是重点考查目标
- char[], String很多, 就比较麻烦了, 因为这个基础类型, 数量多也可能是正常的情况, 就只能仔细分析了

最后, 即便我们有这么多工具, 还是未必能找到BUG, 现实就是这么令人沮丧 

唯有努力学习, 夯实基本功, 才能在下一次与BUG的交手中, 一击必杀, God Luck!

### 参考:
- [jvm源码阅读笔记7](https://blog.csdn.net/foolishandstupid/article/details/78078238)
- [jmap命令](https://www.cnblogs.com/kongzhongqijing/articles/3621163.html)
- [jstat命令](https://www.cnblogs.com/parryyang/p/5772484.html)
- [java垃圾回收算法](https://blog.csdn.net/zhq200902/article/details/55104277)