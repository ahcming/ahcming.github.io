---
title        : "设计模式之适配器模式"
author       : ahcming
description  : 
date         : 2019-04-12 09:55
layout       : post
tag          : ["work", "original", "design pattern"]
blog         : true
---

## 模式介绍

适配器模式就是把不同的数据源全部整成统一的格式, 每一种数据源对应一个适配器

比如我想要类型是T, 结果有多个数据源(假设3个吧), 返回的的类型是R1, R2, R3; 

为了保证本层代码的结构, 我们增加一层适配器层, 每个数据源对应一个适配器, 主要逻辑就是把R1, R2, R3分别转换成T; 

以后每新增一个数据源, 就增加一个对应的适配器;

扩展性好, 屏蔽了与业务无关的数据转换; 

我觉得现实中最好的类比就是鞋子, 每个人的脚就是不同的数据类型, 通过鞋子(适配大地, 路面)这个适配器, 完美解决不同路面情况

还有插座适配器, 此处应该有图

## 代码实现

我想的样子

```java
public interface Target {

    public T request() {}
}
```

实际的样子

```java
public class Adaptee {

    public R1 specialRequest() {}
}
```

中间和稀泥

```java
public class Adapter implements Target {

    private Adaptee ada;

    public T request() {
        R1 r1 = ada.specialRequest();

        T t = convert(r1);

        return t;
    }

    T convert(R1 r) {}
}
```

## 典型应用

- Spring RequestMappingHandlerAdapter

    待补充

- slf4j里的adapter

    `Log4jLoggerAdapter`与`MDCAdapter`