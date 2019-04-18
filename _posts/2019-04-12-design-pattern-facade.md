---
title        : "设计模式之门面模式"
author       : ahcming
description  : 
date         : 2019-04-12 09:55
layout       : post
tag          : ["work", "original", "design pattern"]
blog         : true
---

## 模式介绍

门面模式, 也有叫外观模式; 

当我们的业务由多个子系统/子业务/子模块组成时, 利用门面模式, 可以简化我们方法调用

门面模式同适配器模式最大的区别在于意图不同, 适配器的意思是把目标类型都转成想要的类型; 
而门面模式是简化系统的调用, 对外提供一个一致的API, 甚至屏蔽内部系统的组成; 

跟组合模式的区别? 

我们在WEB开发时, 每个Service的方法, 就是调用若干个Dao方法来实现一个功能, 从这个意义上讲, Service就是门面模式

## 代码实现

```java
public class BizFacade {

    private SubModuleA moduleA;

    private SubModuleB moduleB;

    private SubModuleC moduleC;

    public void biz() {
        moduleA.call();

        moduleB.invoke();

        moduleC.run();
    }
}
```

## 典型应用

- Web MVC里Service, Dao通用实现