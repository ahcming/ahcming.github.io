---
title        : "设计模式之策略模式"
author       : ahcming
description  : 
date         : 2019-04-06 09:55
layout       : post
tag          : ["work", "original", "design pattern"]
blog         : true
---

## 模式介绍

策略模式就相当于有一个锦囊团, 每当遇到什么问题, 就从锦囊团取一个"妙计"来解决问题

所以我们要先对所有的可能问题分别实现相应的`解决策略`, 外部根据当前的条件, 选择相应的策略; 

合理的使用策略模式, 可以避免多重条件判断, 把每一个if分支的逻辑放到对应的一个策略实现类中, 虽然代码量没有减少, 但单个策略类代码更清晰好维护, 扩展也方便

## 代码实现

```java
public interface PayStrategy {

    /**
     * 支付
     */ 
    void pay(int amount);

    /**
     * 策略生效的条件
     */ 
    boolean support();
}

public class AliPay implements PayStrategy {
    public void pay(int amount) {
        System.out.println("使用支付宝支付了" + amount + "元钱");
    }

    public boolean support() {
        // 支付宝有余额
        return aliPayHasDeposit();
    }
}

public class CreditCardPay implements PayStrategy {
    public void pay(int amount) {
        System.out.println("使用信用卡支付了" + amount + "元钱");
    }

    public boolean support() {
        // 有信用卡
        return hasCard();
    }
}

public class CashPay implements PayStrategy {
    public void pay(int amount) {
        System.out.println("使用现金支付了" + amount + "元钱");
    }

    public boolean support() {
        // 有现金
        return hasCash();
    }
}

public class NoPay implements PayStrategy {
    public void pay(int amount) {
        System.out.println("老板, 我没带钱, 不要了");
    }

    public boolean support() {
        // 有现金
        return true;
    }
}
```

使用用例

```java
public class Context {

    private PayStrategy strategy;

    private List<PayStrategy> defaultStrategys = Arrays.asList(new AliPay(), new CashPay(), new CreditCardPay(), new NoPay());

    public Context() {
    }

    public Context(PayStrategy strategy) {
        this.strategy = strategy;
    }

    public void pay(int amount) {
        // 通过这样, 可以避免的多重if判断, 后续的扩展点也很清楚
        for(PayStrategy strategy : defaultStrategys) {
            if(strategy.support()) {
                strategy.pay(amount);
            }
        }
    }

    public void specificPay(int amount) {
        strategy.pay(amount);
    }

    public static void main(String[] args) {
        Context ctx = new Context();
    }

    public static void payWithIf(int amount) {
        Context ctx;
        if(aliPayHasDeposit()) { // 支付宝有余额, 就用支付宝付款吧
            ctx = new Context(new AliPay());
        } else if(hasCash()) { // 有现金
            ctx = new Context(new CashPay());
        } else if(hasCard()) { // 有信用卡
            ctx = new Context(new CreditCardPay());
        } else { // 没办法没带钱, 算了
            ctx = new Context(new NoPay());
        }

        ctx.specificPay(10);
    }
}
```

实际中, 策略模式有很多变种, 或跟其它模式组合使用, 比如工厂模式, 组合模式

## 典型应用
