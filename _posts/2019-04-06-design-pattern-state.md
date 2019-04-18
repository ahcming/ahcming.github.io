---
title        : "设计模式之状态模式"
author       : ahcming
description  : 
date         : 2019-04-06 09:55
layout       : post
tag          : ["work", "original", "design pattern"]
blog         : true
---

## 模式介绍

目前理解还不深, 待定

## 代码实现

```java
public interface BizState {

    void justDoIt();
}

public class StateBlock implements BizState {
    public void justDoIt() {
        System.out.println("block状态时, 完成要做的事!");
    }
}

public class StateRun implements BizState {
    public void justDoIt() {
        System.out.println("runnable状态时, 完成要做的事!");
    }
}

public class StateDefault implements BizState {
    public void justDoIt() {
        System.out.println("default状态时, 完成要做的事!");
    }
}
```

```java
public class Context {
    private BizState state;

    public Context() {
        state = new StateDefault();
    }

    public void block() {
        state = new StateBlock();
    }

    public void run() {
        state = new StateRun();
    }

    public void justDoIt() {
        state.justDoIt();
    }
}
```

从中也可以看出, 把所有状态抽象成一个接口; 
每个状态要单独实现状态接口, 并在Context中添加相应的切换方法
以后新增状态时, 重复上面的步骤;

所有的状态都通过`Context`对外负责沟通, 具体使用哪个状态实现类都由`Context`管理

## 典型应用
