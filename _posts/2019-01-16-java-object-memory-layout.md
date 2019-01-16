---
title        : "Java对象内存布局"
author       : ahcming
description  : 
date         : 2019-01-16 10:41
layout       : post
tag          : ["work", "original", "jvm"]
blog         : true
---

首先直接抛出问题

- Unsafe.getInt(obj, fieldOffset)中的fieldOffset是什么, 类似还有compareAndSwapX(obj, fieldOffset, oldValue, newValue)? 
- 如何实现原子读, 原子写的
- Java反射是怎么实现
- Java synchronized锁是如何实现

要解答这些问题, 需要了解Java对象内存布局

## Java对象内存布局

主要分为对象头和实例数据2部分

对象头又分成Mark Word和Class Metadata Pointer2部分

实例数据就是对象里定义的Field列表, 顺序并非严格按照源码里声明的顺序(但有一定的规则), 
Unit的起始位置相对于对象的位置就是字段的偏移量, 字段的偏移量需要满足内存对齐的要求

普通对象的内存整体布局

```shell
+-------------+------------------+
|             |     Mark Word    |
| Object Head +------------------+
|             | Metadata Pointer |
+-------------+------------------+
|             |       Unit       |
|  Instance   +------------------+
|             |       ...        |
|   Data      +------------------+
|             |       Unit       |
+-------------+------------------+
```

数组对象的内存布局

```shell
+-------------+------------------+
|             |     Mark Word    |
|             +------------------+
| Object Head | Metadata Pointer |
|             +------------------+
|             |   array length   |
+-------------+------------------+
|             |       Unit       |
|  Instance   +------------------+
|             |       ...        |
|   Data      +------------------+
|             |       Unit       |
+-------------+------------------+
```

下面逐一介绍每部分的结构及作用

### Mark Word

任何Java对象都有此部分信息及内存消耗, 这部分归JVM管理,JDK层面无API修改此部分数据

这里主要记录对象锁信息和GC标记, 32bit虚拟机与64位虚拟机给Mark Word区域分配的空间分为是32bit和64bit

但为了最大效率使用这部分空间, Mark Word的结构是非固定的

比如在32bit虚拟机中, 对于无锁态类型的对象, 其中25位用来存储hashcode; 

而在偏向锁类型的对象中, 23bit用来记录当前获取锁的线程ID

32bit的JDK结构如下:

```shell
+--------+-----------------------+-------+----------+------------------+--------------+
| 锁状态 |         23bit         |  2bit |   4bit   | 1bit(是否偏向锁) | 2bit(锁标志) |
+--------+-----------------------+-------+----------+------------------+--------------+
| 无锁态 |        对象的Hascode          | 分代年龄 |        0         |      01      |
+--------+-------------------------------+----------+------------------+--------------+
|轻量级锁|                   指向栈中锁记录的指针                      |      00      |
+--------+-------------------------------------------------------------+--------------+
|重量级锁|                 指向互斥量(重量级锁)的指针                  |      10      |
+--------+-------------------------------------------------------------+--------------+
| GC标记 |                              空                             |      11      |
+--------+-------------------------------------------------------------+--------------+
| 偏向锁 |     线程ID            | Epoch | 分代年龄 |        1         |      01      |
+--------|-----------------------+-------+----------+------------------+--------------+

```

Java中任何对象都可以用来做锁, synchronized关键字底层实现原理跟Mark Word相关

在JDK1.6之前, synchronized实现的锁是重量级, 性能较差(锁状态切换,涉及OS的线程在用户态与系统态之间切换)

在1.6之后, 针对各种场景进行优化, 如偏向锁, 轻量级锁(自旋锁), synchronized的性能也有了很大提升, 并且synchronized的使用比Lock要简单安全, 所以JDK推荐优先使用synchronized; 并且由于synchronized语义比较明确, 后续还有优化的空间

由于本文重点不在说明synchronized的实现原理, 想了解更多可以参考zejian大神的这篇文章[深入理解Java并发之synchronized实现原理](https://blog.csdn.net/javazejian/article/details/72828483), 附上一张大神绘制的图以表敬意

![线程获取锁过程](/assets/images/java/java-object-monitor.png)

### Class Metadata Pointer

主要是获取对象的一些元信息, 比如类名, 包名, 字段列表, 方法列表等等

### Instance Data

这里就是每个对象实例数据, 具体点就是对象里每个字段的值或数组对象里每个元素的值; 
既然有值就一定会有类型, 在Java里数据类型分为基本类型与引用类型

#### 数据类型

对于基本类型, 每种类型的占用空间大小如下, 单位B

```shell
+------+---------+-------+------+-----+-------+------+--------+
| byte | boolean | short | char | int | float | long | double |
+------+---------+-------+------+-----+-------+------+--------+
|  1   |    1    |   2   |   2  |  4  |   4   |   8  |    8   |
+------+---------+-------+------+-----+-------+------+--------+
```

而对于Reference类型, 一般跟OS的位数相同, 在64bit的操作系统上, 就是64位长度, 也就8B, 同理在32bit的虚拟机里就是4B; 
这样对于有些从32位虚拟机移植过来的程序, 可能内存开销增加了50%以上; 

所以Java提供了一个启动参数用来设置Reference的大小, 也就是内存地址压缩, 默认是开启压缩的; 
注意: 地址压缩只是针对64位虚拟机的引用类型的优化

开启参数
> -XX:+UseCompressedOops

关闭参数
> -XX:-UseCompressedOops

差别就在那个+和-

#### 内存对齐

内存对齐是提升程序性能的关键, 具体原因可以参考文章后面的附录, 也可以自行检索

简单的理解就是: 如果变量的内存地址是类型长度的整数倍, CPU只需一次访问即可; 
否则就要多次访问并把每次结果进行拼接才能获得最终值

看看最上面的对象结构里的实例数据部分, 我按照自己的理解画成了一个个Unit

每个Unit里面可放一个或多个Field, 同一个Unit里的类型可以不同, 但是长度必须相同, 比如byte和boolean, short和char可以放在一起 

对齐规则:
> 上一数据结束位置 % 类型长度 == 0

需要补齐的大小
> 类型长度 - 上一数据结束位置 % 类型长度

比如对于一个long类型的字段来说, 如果当前的偏移量是12, 那么 12 % 8 != 0, 不对齐, 需要padding=8-12*8=4bit;

具体可以见下面的例子

#### 字段偏移量

每个对象在内存都有一个内存地址, 通过内存地址+类型, 我们就可以取出对象的值; 对于对象里的字段, 也是相似操作
地址的值一般来讲也是比较长的, 如果每个对象的字段地址都是用真实的地址值, 也比较浪费内存;
所以Java里采用了字段偏移量来实现, 可以理解为相对于对象起始位置的距离, 要获取真实地址只需要

> FieldAddress = ObjectAddress + objectFieldOffset

由于Java里字段又分为类字段(静态的, 跟类相关)和实例字段(非静态, 跟对象相关), 对于静态字段

> StaticFieldAddress = ClassAddress + staticFieldOffset

我们可以通过`Unsafe.objectFieldOffset(Field)`来获取一个对象的字段偏移量,
通过`Unsafe.staticFieldOffset(Field)`来获取一个类的字段偏移量

字段偏移量的值可以通过以下数学归纳法计算:

如果是第一个字段
> fieldOffset1 = ObjectHeaderLength

在64bit, 地址压缩的情况下, 对象头长度是12byte(8byte mark word + 4byte metadata pointer); 

同理, 地址不压缩对象头长度是16byte(8byte mark word + 8byte metadata pointer)

如果是非第一个字段
> fieldOffset1 = 上一数据结束位置 + padding = 上一个字段的偏移量 + 上一个字段的长度 + padding

如果fieldOffset1可以对齐field的类型长度, 则field的偏移量地址=fieldOffset1

如果fieldOffset1不能对齐field的类型长度, 则field的偏移量地址=fieldOffset1+padding

判断是否对齐及padding的计算参见上一节`内存对齐`

最终的计算结果跟3个因素相关
- 内存对象字段排序, 这个在下一节重点说明
- 补齐(Padding)
- 地址压缩

#### 字段的排序规则
1. 排序规则的目的是尽可能减少Padding
2. 先基本类型, 再引用类型; 先长后短, 长度相同就按声明顺序 
3. 基本类型先大后小(8,4,2,1), 但有例外

Java类型的长度无非是1byte,2byte,4byte,8byte这4种, 实例的数据也就是这4值的各种组合; 
先长后短还是先短后长并不能减少Padding的浪费, 
但是先长后短可以减少内存碎片化, 或者说是连续的内存地址空间, 因为Padding的部分都在对象的尾部(理解可能有误)

在于64bit压缩情况下, 对象头是12byte, 如果对象有3个Field, 分别是int, long, boolean; 

如果严格按照先大后小, 则应该是long, int, boolean; 按照上一节偏移量的计算:

> offset1 = 12

而long是8byte, 12%8!=0, 需要padding=8-12%8=4byte; 整个内存布局大概类似如下:
```shell
+----------------------+---------------+------------+-----------+---------------+---------------+
| Object Head 12 bit   | padding 4 bit | long 8 bit | int 4 bit | boolean 1 bit | padding 3 bit |
0                      12              16           24          28              29              32
```
累计padding=4+3=7bit, 仔细分析, 在这种场景下, 还有更好的排列可以节省掉第一个padding

我们可以把后面的int放到空缺的4bit里, 反正这4bit不用白不用, 即如下布局

```shell
+----------------------+-----------+------------+---------------+---------------+
| Object Head 12 bit   | int 4 bit | long 8 bit | boolean 1 bit | padding 3 bit |
0                      12          16           24              25              28
```

这就是规则3的例外情况, 对于这空缺的4bit, 优先拿4bit类型的数据来填充, 次之2bit, 次之1bit; 如果都没有, 那就只能浪费了

对于64bit地址压缩的JVM, 内存对象字段大概是如下布局:
 
```shell
+----------------------------+
|           4 byte           |
+----------------------------+
|   Object Header  12 byte   |
|     Mark Word     8 byte   |
|  Metadata Pointer 4 byte   |
+----------------------------+
|   int or float    4 byte   |
+----------------------------+
|   long or double  8 byte   |
+----------------------------+
|   int or float    4 byte   |
+----------------------------+
|   char or short   2 byte   |
+----------------------------+
|   byte or boolean 1 byte   |
+----------------------------+
|   Reference       4 byte   |
+----------------------------+
```

对于64bit非地址压缩的JVM, 内存对象字段大概是如下布局:

```shell
+----------------------------+
|           8 byte           |
+----------------------------+
|   Object Header  16 byte   |
|     Mark Word     8 byte   |
|  Metadata Pointer 8 byte   |
+----------------------------+
|   long or double  8 byte   |
+----------------------------+
|   int or float    4 byte   |
+----------------------------+
|   char or short   2 byte   |
+----------------------------+
|   byte or boolean 1 byte   |
+----------------------------+
|   Reference       8 byte   |
+----------------------------+
```

以下通过代码来对上面的规则做一个证明

```Java
public class MemoryLayout {
    private String name;
    private int age;
    private boolean sex;
    private byte young;

    public static void main(String[] args) {
        long ageOffset = getFieldOffset("age");
        long sexOffset = getFieldOffset("sex");
        long youngOffset = getFieldOffset("young");
        long nameOffset = getFieldOffset("name");

        System.out.println("--> " + ageOffset);
        System.out.println("--> " + sexOffset);
        System.out.println("--> " + youngOffset);
        System.out.println("--> " + nameOffset);
    }

    public static long getFieldOffset(String fieldName) {
        try {
            Field field = MemoryLayout.class.getDeclaredField(fieldName);
            return UnsafeKit.getUnsafe().objectFieldOffset(field);
        } catch (Exception e) {
            throw new RuntimeException("not exist field [" + fieldName + "] in MemoryLayout");
        }
    }
}
```

我的JVM环境是64bit, 默认地址压缩, 程序的输出结果是:
```
--> 12
--> 16
--> 17
--> 20
```

1. 数值分别表示每个字段的偏移量
2. 每个字段的偏移量跟源码里的声明顺序并不一致, 按先基本类型, 再引用类型, 先大后小的规则, 字段的顺序是: age, sex, young, name
3. age是第一个字段, 所以偏移量就是对象头大小, 在64bit地址压缩的JVM里就是12
5. sex的计算过程: 上一个字段的偏移量 + 上一个字段的长度=12+4=16, boolean类型1bit, 16%1==0, 内存对齐, 所以结果就是16
6. young的计算过程: 上一个字段的偏移量 + 上一个字段的长度=16+1=17, byte类型1bit, 17%1==0, 内存对齐, 所以结果就是17
7. name的计算过程: 上一个字段的偏移量 + 上一个字段的长度=17+1=18, 引用类型4bit, 18%4!=0, 不对齐需要padding 4-18%4=2bit, 所以结果是18+2=20

### 总结

- Java所有对象都是有个ObjectHead, 由JVM维护; 主要用于锁及GC相关的
- 为了提升Java读写效率, Java所有字段在内存中需要内存对齐
- 为了减少Padding消耗, Java对对象的字段进行了一定规则的重排序
- 通过Java地址+字段的偏移量, 就可以操作内存里的数据; 整个Unsafe类就是基于这个来实现原子读写
- Java反射就是用Unsafe实现, 来直接操作数据
- 整个Java并发包都是基于Unsafe来实现并发安全, 包括但不限于: AQS, CAS, Lock, 信号量, Condition

## 参考
- [java对象在内存中的结构（HotSpot虚拟机）](https://www.cnblogs.com/duanxz/p/4967042.html)
- [深入理解Java并发之synchronized实现原理](https://blog.csdn.net/javazejian/article/details/72828483)
- [Java直接内存对齐(Memory Alignment)](https://www.jdon.com/48256)
- [轻松搞定内存对齐](https://blog.csdn.net/qq_31821675/article/details/72853551)
- [可能是把Java内存区域讲的最清楚的一篇文章](https://cloud.tencent.com/developer/article/1193412)
