---
title        : "设计模式之工厂方法模式"
author       : ahcming
description  : 
date         : 2019-04-07 09:55
layout       : post
tag          : ["work", "original", "design pattern"]
blog         : true
---

## 模式介绍

属于创建型模式的一种, 可以简单的理解为, 给一个指令返回我们想要对象实例; 类似如下代码

```java
object = factory.get(type);
```

从广义上讲, 有返回值的方法, 都能算上工厂方法(是否太宽泛...)

通过工厂模式, 可以屏蔽对象的创建细节; 
可以减轻创建负担, 比如创建完之后需要做些通用的工作, 如依赖注入, 创建对象的数量控制; 
对调用者而言提供一致的API方式, 也是很友好的

## 代码实现

首先我们来看看常见工厂类是怎么调用的

```java
product = factory.get(type)
```

或

```java
product = factory.get(name)
```

在工厂里, 根据type/name返回一个确定的product, 你可以建立一个map来维护这个对应关系, 也可以通过反射; 
由于返回值的类型都是product, 所以我们需要一个product类型的接口或父类或抽象类, 如

```java
public abstract class AbstractProduct {

    /**
     * 共性方法, 所以子类都需要
     */ 
    public void generality() {

    }

    /** 
     * 特性方法, 每个子类实现
     */ 
    public abstract void features();
}
```

然后就分别实现每个子类的

```java
public class ProductA extends AbstractProduct {
    public void features() {
        // TODO: add implements
    }
}
```

## 典型应用

- 加密算法工厂

```java
MessageDigest digest = MessageDigest.getInstance("algorithm")
```

典型的工厂应用, 通过算法名返回真正的算法对象

- Spring里著名的IOC工厂

```java
bean = applicationContext.getBean("beanName")
```

通过bean的名字返回IOC里的真实bean对象, 并且返回的对象完成了依赖注入, 减轻了我们创建对象的负担

- Java nio里的`ByteBuffer`

ByteBuffer有2个核心的实现, `HeapByteBuffer`与`DirectByteBuffer`, 这2个类你去看JDK源码会发现都是包级别的, 我们是不能手动创建的,
只能通过`ByteBuffer#allocate`和`ByteBuffer#allocateDirect`方法来创建

这里采用工厂模式的目的, 我个人觉得是屏蔽`HeapByteBuffer`与`DirectByteBuffer`的实现细节, 提升框架安全

- Object Pool

对象池框架, 一般用在对象的创建比较重, 通常用在各种连接池管理, 如redis连接池, MySQL连接池; 
对象池主要管理对象的初始化数量, 最大数量, 获取/归还, 扩容/缩容策略及时机, 淘汰算法, 阻塞/非阻塞模式等等

对象池主要是解决了对象的创建和维护负担, 并不是在多个实现类之间无缝切换, 并非很严禁的工厂模式代码, 要灵活变通, 要学其神而非形
