---
title        : "设计模式之构造器模式"
author       : ahcming
description  : 
date         : 2019-04-09 09:55
layout       : post
tag          : ["work", "original", "design pattern"]
blog         : true
---

## 模式介绍

这种模式也很常见及简单, 可以看看各种XXXBuilder的类

通常用来简化对象的创建, 尤其对象的初始化属性很多时; 
使用构建器模式可以把setXX方法变成链式调用也是常见手法

## 代码实现

我个人感觉这里没有定式的编写规则

```java
public class XXXBuilder {

    public XXXBuilder threads(int count) { 
        this.threads = count;   // 1. XXX有什么属性, XXXBuilder也要来一份; 这个方法也来一份
        return this;    // 2. 返回值是 XXXBuilder, 便于链式调用
    }

    // 其它属性的设置, 依次添加

    public XXX build() {
        XXX x = new XXX();
        x.setThreads(this.threads);

        return x;
    }
}
```

## 典型应用

- StringBuilder

- JMH里的OptionsBuilder

```java
Options opt = new OptionsBuilder()
        .include(StatBTest.class.getSimpleName())
        .threads(4)
        .forks(1)
        .build();
```