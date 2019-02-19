---
title        : Java Unsafe类使用说明
author       : ahcming
description  : 
date         : 2019-01-07 14:28
layout       : post
tag          : ["work", "original", "Java"]
blog         : true
---

Unsafe类完整限定名是sun.misc.Unsafe, 从包名可以看出, Unsafe并不符合J2SE的规范, 只是一个sun公司的内部实现

在JDK1.8版本里, 共计有88个native类型的API

Java并发包的实现都是基于Unsafe类, 其中使用最多的是以下几个API

- objectFieldOffset(field): 获取字段偏移量
- getXXXVolatile(obj, offset): 原子读
- compareAndSwapXXX(obj, offset, oldValue, newValue): CAS写

### 内存管理相关API ###

```java
/**分配内存*/
public native long allocateMemory(long bytes);

/**重新分配内存*/
public native long reallocateMemory(long address, long bytes);

public native void setMemory(Object target, long fieldOffset, long var4, byte var6);

public void setMemory(long var1, long var3, byte var5) {
    this.setMemory((Object)null, var1, var3, var5);
}

/**拷贝内存*/
public native void copyMemory(Object target, long fieldOffset, Object var4, long var5, long var7);

public void copyMemory(long var1, long var3, long var5) {
    this.copyMemory((Object)null, var1, (Object)null, var3, var5);
}

/**释放内存*/
public native void freeMemory(long var1);

public native long getAddress(long var1);

public native void putAddress(long var1, long var3);

public native int addressSize();

public native int pageSize();
```

### 操作类, 对象相关API ###

```java

// 获取静态字段的偏移量
public native long staticFieldOffset(Field staticField);

// 获取非静态字段的偏移量
public native long objectFieldOffset(Field objectField);

// 
public native Object staticFieldBase(Field staticField);

public native boolean shouldBeInitialized(Class<?> var1);

public native void ensureClassInitialized(Class<?> var1);

public native int arrayBaseOffset(Class<?> var1);

public native int arrayIndexScale(Class<?> var1);

public native Class<?> defineClass(String var1, byte[] var2, int var3, int var4, ClassLoader var5, ProtectionDomain var6);

public native Class<?> defineAnonymousClass(Class<?> var1, byte[] var2, Object[] var3);

public native Object allocateInstance(Class<?> var1) throws InstantiationException;

public native void throwException(Throwable var1);
```

### 读取内存中数据相关API 

API的形式如: `getXXX`

而每类get又有3种重载形式, 分别用于读取变量值, 工作内存里对象字段的值, 主存里对象的字段值; 

XXX代表类型, 有Byte, Boolean, Short, Char, Int, Float, Long, Double, Object, 共9类; 所以此块累计27个API

反射里读取数据就是基于以下API

```java
/**
 * 获取内存里XXX类型的值
 * 
 * address: 是数据在内存中的地址
 */ 
public native XXX getXXX(long address);

/**
 * 获取对象属性的值
 * object: 对象
 * fieldOffset: 字段在对象里的偏移量
 */ 
public native XXX getXXX(Object object, long fieldOffset);

/**
 * 从主存里获取对象属性的值
 * object: 对象
 * fieldOffset: 字段在对象里的偏移量
 */ 
public native XXX getXXXVolatile(Object object, long fieldOffset);
```

### 修改内存中数据相关API 

API的形式如: `putXXX`

而每类put又有3种重载形式, 分别用于修改变量值, 工作内存里对象字段的值, 主存里对象的字段值; 

XXX代表类型, 有Byte, Boolean, Short, Char, Int, Float, Long, Double, Object, 共9类; 所以此块也累计27个API

反射里写改数据就是基于以下API

```java
/**
 * 修改内存里XXX类型的值
 * XXX代表类型, 有Byte, Boolean, Short, Char, Int, Float, Long, Double, Object
 * address: 是数据在内存中的地址
 */ 
public native void putXXX(long address, XXX value);

/**
 * 修改对象属性的值
 * object: 对象
 * fieldOffset: 字段在对象里的偏移量
 */ 
public native void putXXX(Object object, long fieldOffset, XXX value);

/**
 * 修改主存里对象属性的值
 * object: 对象
 * fieldOffset: 字段在对象里的偏移量
 */ 
public native void putXXXVolatile(Object object, long fieldOffset, XXX value);

/**
 * 设置obj对象中offset偏移地址对应的int型field的值为指定值。
 * 这是一个有序或者有延迟的putIntVolatile方法，并且不保证值的改变被其他线程立即看到。
 * 只有在field被volatile修饰并且期望被意外修改的时候使用才有用
 */ 
public native void putOrderedInt(Object object, long fieldOffset, int value);

/**
 * 设置obj对象中offset偏移地址对应的long型field的值为指定值。
 * 这是一个有序或者有延迟的putLongVolatile方法，并且不保证值的改变被其他线程立即看到。
 * 只有在field被volatile修饰并且期望被意外修改的时候使用才有用
 */ 
public native void putOrderedLong(Object object, long fieldOffset, long value);

/**
 * 设置obj对象中offset偏移地址对应的Object型field的值为指定值。
 * 这是一个有序或者有延迟的putObjectVolatile方法，并且不保证值的改变被其他线程立即看到。
 * 只有在field被volatile修饰并且期望被意外修改的时候使用才有用
 */ 
public native void putOrderedObject(Object object, long fieldOffset, Object value);
```

### CAS操作相关API ###

CAS字面意思就是Compare And Swap

对应的API是

```java
public final native boolean compareAndSwapObject(Object target, long fieldOffset, Object oldValue, Object newValue);

public final native boolean compareAndSwapInt(Object target, long fieldOffset, int oldValue, int newValue);

public final native boolean compareAndSwapLong(Object target, long fieldOffset, long oldValue, long newValue);
```        

伪代码如下

```java
current_value = read_by_address(target, fieldOffset)
if(current_value == oldValue) {
    value = newValue;
    return true;
} else {
    // 什么都不做
    return false;
}
```

为什么Java的CAS原子操作要通过JNI调用C++的实现?

### 线程挂载相关API ###

LockSupport类的主要实现就是依赖以下2个API

```java

// 把当前线程挂起
public native void park(boolean isAbsolute, long time);

// 把指定线程唤醒
public native void unpark(Thread thread);
```

### 其它API ###

看API名字猜测跟ObjectMonitor, synchronized锁的实现有关或辅助使用

```java
public native void monitorEnter(Object var1);

public native void monitorExit(Object var1);

public native boolean tryMonitorEnter(Object var1);
```

### JDK原子类实现代码分析

以AtomicInteger为例

首先, 单独读和单独写操作, 源码很简单

```java
/**
 * 读取
 * 没有使用锁或同步的操作, 因为这个操作本身原子性的; 
 * 另外由于value使用了volatile修饰, 保证了可见性;
 * 有序性?
 */ 
public final int get() {
    return value;
}

public final void set(int newValue) {
    value = newValue;
}
```

读写操作, 要如何保证原子性, 相关的API有

- getAndSet
- getAndIncrement
- getAndDecrement
- incrementAndGet
- decrementAndGet
- getAndAdd
- addAndGet

底层都是调用了Unsafe.getAndAddInt, 具体实现如下:

```java
int oldValue;

do {
    // 获取当前atomicInteger对象主存里的value字段值
    oldValue = getIntVolatile(obj, offset);
} while(!compareAndSwapInt(obj, offset, oldValue, newValue)); // 通过CAS来更新主存里对象字段的值, 一直循环, 直到成功为止

// 返回旧值
return oldValue;
```

上面的实现有2个地方需要注意, 一个是使用了无限循环(也叫自旋)来检查CAS结果并且直到成功才退出, 这个有消耗并且不稳定; 
二是每次都是获取当前对象在内存里的真实值, 可能跟当前线程的值是不同的, 但是在此是满足API本身的语义要求的, 只要累加成功即可, 不能覆盖掉其它线程的修改结果; 
如果一定要从本线程内的当前值X改为Y, 就要使用`compareAndSet`, 由调用方自己确认有无修改成功


## 参考
- [JAVA中神奇的双刃剑--Unsafe](https://www.cnblogs.com/throwable/p/9139947.html)
