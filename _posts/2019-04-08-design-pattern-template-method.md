---
title        : "设计模式之模板模式"
author       : ahcming
description  : 
date         : 2019-04-08 09:55
layout       : post
tag          : ["work", "original", "design pattern"]
blog         : true
---

## 模式介绍

模板模式也是很常见的一种模式, 尤其是在框架中使用; 

在模板类中, 实现功能的通用完整流程, 然后把一些特殊的定制化功能放到子类中; 父类+具体的子类, 就是一个具体的完整实现;

这样可以把公共代码抽取到父类, 可以减少代码的冗余; 
其次, 整个功能集的实现从整体上比较统一, 把不同的部分放到相应的子类中实现, 每个子类的实现过程类似于填空, 通过用类来对实现进行区分, 便于管理, 理解, 扩展

## 代码实现

```java
public abstract class AbstractBiz {

    /**
     * 完整的业务的逻辑
     */
    public void completeBiz() {
        // step1

        // common logic

        specialBiz();
        
        // stepX
    }

    public abstract void specialBiz();
}
```

```java
public class ConcreteBiz extends AbstractBiz {

    /**
     * 每个具体的业务类里实现自己特殊的业务逻辑
     */ 
    public void specialBiz() {

    }
}
```

## 典型应用

- JDK集合框架里有很Abstract*的例子, 在此`AbstractQueue`为例说明下

```java
public boolean add(E e) {
    if (offer(e))
        return true;
    else
        throw new IllegalStateException("Queue full");
}

public E remove() {
    E x = poll();
    if (x != null)
        return x;
    else
        throw new NoSuchElementException();
}
```

可以看到`add`与`remove`方法的实现都是基于更原子的方法`offer`与`poll`
`offer`与`poll`的实现则跟具体的子类相关, 而`add`与`remove`可以做到与子类无关, 所以抽象到父类里

这里可能更多体现的是多个小方法组合来完成更高级的功能

- AbstractQueuedSynchronizer

整个Java并发包的基石AQS, ReentrantLock, Semaphore, CountDownLatch, ThreadPoolExecutor这些重要的并发类都是基于AQS实现
其中`acquire`方法就是获取共享资源的

```java
public final void acquire(int arg) {
    if (!tryAcquire(arg) &&
        acquireQueued(addWaiter(Node.EXCLUSIVE), arg))
        selfInterrupt();
}
```

`tryAcquire`是接口方法, 由各自子类实现, 标准的模板模式实现