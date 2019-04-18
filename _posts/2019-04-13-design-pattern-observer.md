---
title        : "设计模式之观察者模式"
author       : ahcming
description  : 
date         : 2019-04-13 09:55
layout       : post
tag          : ["work", "original", "design pattern"]
blog         : true
---

## 模式介绍

在这种模式下, 产生事件/状态改变的称为事件源, Observable; 对事件关心, 要进行处理的称为订阅者, Subscriber;
Subscriber需要先对Observable的事件进行订阅(subscribe), 当Observable的事件真正发生的时候, Observable会通知所有Subscriber进行处理;

说起来比较绕口, 以警察和小偷的例子来类比, 小偷就是Observable, 小偷可以产生偷东西的事件; 警察就是Subscriber, 负责处理偷东西的案件(事件); 那订阅动作怎么实现呢?
警察跟小偷说, 你下次偷东西的时候告诉我一声, 听起来很魔幻, 但在现实中不能实现的事情在编程世界里是可以的

观察者模式把事件发生与事件处理逻辑进行解耦, 可以大大提升代码的结构清晰度, 以及扩展性; 

试想下以下场景: 
    用户支付成功, 订单状态变为支付成功

我们需要做什么事呢? 

- 返回当前订单状态, 客户端需要交互提示
- 通知发货, 必须的
- 给用户发积分, 蚂蚁积分, 提升粘性
- 可能还有促销活动奖励, 根据当前的运营配置的活动发放相应奖励
- 监控, 是否有失败, 超时
- 统计, 支付完成率, 今日PV, DAU
- 可能还有其它业务处理

我们来考虑下这个场景的实现方式

### 每个功能一个个添加, 直接强撸
- 首先, 肯定能实现, 没问题
- 核心业务与非核心业务混杂在一起
    + 核心业务(发货, 用户发积分, 活动奖励), 非核心的(监控, 统计功能)
    + 如果非核心业务出了异常, 导致后面的核心代码没调用, 往轻了说是BUG, 往大了说是事故; 你说我把非核心代码都try/catch起来, 这就是项目约定, 所有组员都要知道并遵守, 增加了沟通成本; 然后代码更臃肿难看了; 以后要增加新逻辑, 谁来判断是不是核心业务? 该放哪里? 如果作者走了, 谁还敢动这块祖传代码? 
    + 不好优化, 非核心业务可能性能低下, 拖累整体方法的TPS
    + 业务级别不同, 注定实现风格不同, 混在一起容易干扰, 实现不彻底; 核心业务要保证数据一致性, 数据充分检查, 失败重试; 非核心业务可以允许失败, 异步处理
- 扩展性
    + 可以预想, 可能还有很多其它功能都想在支付成功之后触发, 那这里是不是经常修改? 而这块又是核心功能, 如何保证核心功能的稳定

### 观察者方式

- 把发货, 发积分, 活动奖励, 监控, 统计等等分别定义成一个个Subscriber, 需要try/catch, 异步化的都在自己的Subscriber里完成
- 然后订阅支付成功事件
- 在支付成功的方法里, 只同步处理当前调用者关心的逻辑, 如订单状态; 并通知所有Subscriber

这样重构之后, 支付成功方法的实现就非常简单清晰; 而每个其它逻辑都是一个Subscriber, 通过类名就能大致了解Subscriber的功能, 以后扩展也无须修改支付成功方法;
整个代码结构无论是组织性, 还是单个类的维护成本, 都要好的多

## 代码实现

事件源

```java
public class Event {
    // 事件体定义
}
```

订阅者

```java
public class Subscriber {

    public void process(Event event) {
        // 开始处理事件
    }

}
```

观察者
```java
public class Observable {
    private List<Subscriber> subscribers = new ArrayList();

    public void subscribe(Subscriber subscriber) {
        subscribers.add(subscriber);
    }

    public void eventHappen() {
        // 事件发生
        Event event = happend(); 

        // 通知警察
        for(Subscriber subscriber : subscribers) {
            subscriber.process(event);
        }
    }
}
```

## 典型应用

- AWT, Swing
    
事件监听模型最早出自awt程序的开发; 通用作法就是对每个控件的每个事件实现对应的`Listener`接口

- EventBus

Guava里观察者模式的优雅的实现

- MessageQueue

也算是典型应用了, 这里的事件源就是生产者, 事件就是消息, 订阅者自然就是消费者