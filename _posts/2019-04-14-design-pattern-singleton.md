---
title        : "设计模式之单例模式"
author       : ahcming
description  : 
date         : 2019-04-14 09:55
layout       : post
tag          : ["work", "original", "design pattern"]
blog         : true
---

## 模式介绍

单例模式是指整个类只有一个实例对象

一般用于减少重量级对象频繁创建的开销; 或对象太多, 减少内存占用

## 代码实现

### 方法一: 饿汉式

```java
public class Singleton1 {

    private final static Singleton1 INSTANCE = new Singleton1();

    private Singleton1(){}

    public static Singleton1 getInstance(){
        return INSTANCE;
    }
}
```

优点: 实现简单

缺点: 类装载阶段完成对象创建; 如果类一直没有使用, 会浪费内存

### 方法二: 懒汉式

```java
public class Singleton2 {

    private static Singleton2 singleton;

    private Singleton2() {}

    public static Singleton2 getInstance() {
        if (singleton == null) {
            singleton = new Singleton2();   // 线程不安全; 可能会创建多个
        }
        return singleton;
    }
}
```

优点: Lazy Loading

缺点: 多线程不安全

### 方法三: 懒汉式-方法级同步

```java
public class Singleton3 {

    private static Singleton3 singleton;

    private Singleton3() {}

    public static synchronized Singleton3 getInstance() {
        if (singleton == null) {
            singleton = new Singleton3();
        }
        return singleton;
    }
}
```

优点: 在上面的懒汉式基础上加了synchronized, 保证了线程安全

缺点: 性能太低, 即使已经创建好了, 每次执行`getInstance`方法还是要获取锁

### 方法四: 懒汉式-双重检测

```java
public class Singleton4 {

    private static volatile Singleton4 singleton;   // volatile作用?

    private Singleton4() {}

    public static Singleton4 getInstance() {
        if (singleton == null) {
            synchronized (Singleton4.class) {
                if (singleton == null) {
                    singleton = new Singleton4();
                }
            }
        }
        return singleton;
    }
}
```

优点: 线程安全, 性能好, Lazy Loading

缺点: 实现复杂

### 方法五: 静态内部类

```java
public class Singleton5 {

    private Singleton5() {}

    private static class SingletonInstance {
        private static final Singleton5 INSTANCE = new Singleton5();
    }

    public static Singleton5 getInstance() {
        return SingletonInstance.INSTANCE;
    }
}
```

通过JVM的`静态属性只会在类加载时初始化一次`规则保证了INSTANCE的线程安全

优点: 线程安全, Lazy Loading, 无锁, 实现较双重检验简单

### 方法六: 枚举方法

```java
public enum  SingletonFactory {

    XXXHolder(new XXX()),       // 注意, 只要SingletonFactory类被加载, 里面所有枚举的instance就创建了
    YYYHolder(new YYY()),       // 注意, 如果想分别Lazy Loading, 就分开创建不同的枚举工厂类
    ;

    private Object instance;

    private SingletonFactory(Object instance) {
        this.instance = instance;
    }

    public <T> T getInstance() {
        return (T)instance;
    }
}
```

优点: 线程安全, Lazy Loading, 无锁, 实现简单

## 典型应用

- 减少对象内存占用
    + Spring里的IOC Bean默认都是单例模式
- 创建成本比较重的对象
    + Mybatis里SqlSessionFactory对象
- 减少多线程竞争
    + 待补充
