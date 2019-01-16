---
title        : Java Unsafe类使用说明
author       : ahcming
description  : 
date         : 2019-01-07 14:28
layout       : post
tag          : ["work", "note", "name"]
blog         : true
---

Java并发包中实现原子安全的基石就是Unsafe类

Unsafe类完整限定名是sun.misc.Unsafe, 从包名可以看出, Unsafe并不符合J2SE的规范, 只是一个sun公司的内部实现

### CAS原子操作相关API ###

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


### 内存管理相关API ###

```
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


### 操作类, 对象, 属性 ###

```java

public native long staticFieldOffset(Field staticField);

public native long objectFieldOffset(Field objectField);

public native Object staticFieldBase(Field staticField);

public native boolean shouldBeInitialized(Class<?> var1);

public native void ensureClassInitialized(Class<?> var1);

public native int arrayBaseOffset(Class<?> var1);

public native int arrayIndexScale(Class<?> var1);

public native Class<?> defineClass(String var1, byte[] var2, int var3, int var4, ClassLoader var5, ProtectionDomain var6);

public native Class<?> defineAnonymousClass(Class<?> var1, byte[] var2, Object[] var3);

public native Object allocateInstance(Class<?> var1) throws InstantiationException;

public native void throwException(Throwable var1);

public native int getInt(Object target, long fieldOffset);

public native void putInt(Object target, long fieldOffset, int newValue);

public native Object getObject(Object target, long fieldOffset);

public native void putObject(Object target, long fieldOffset, Object newValue);

public native boolean getBoolean(Object target, long fieldOffset);

public native void putBoolean(Object target, long fieldOffset, boolean newValue);

public native byte getByte(Object target, long fieldOffset);

public native void putByte(Object target, long fieldOffset, byte newValue);

public native short getShort(Object target, long fieldOffset);

public native void putShort(Object target, long fieldOffset, short newValue);

public native char getChar(Object target, long fieldOffset);

public native void putChar(Object target, long fieldOffset, char newValue);

public native long getLong(Object target, long fieldOffset);

public native void putLong(Object target, long fieldOffset, long newValue);

public native float getFloat(Object target, long fieldOffset);

public native void putFloat(Object target, long fieldOffset, float newValue);

public native double getDouble(Object target, long fieldOffset);

public native void putDouble(Object target, long fieldOffset, double newValue);
```

### 线程挂载相关API ###

```java
public native void park(boolean isAbsolute, long time);

public native void unpark(Thread thread);
```


### 其它API ###

```java
public native void monitorEnter(Object var1);

public native void monitorExit(Object var1);

public native boolean tryMonitorEnter(Object var1);
```


## 参考
- [JAVA中神奇的双刃剑--Unsafe](https://www.cnblogs.com/throwable/p/9139947.html)
