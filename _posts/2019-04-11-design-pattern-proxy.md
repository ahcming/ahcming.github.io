---
title        : "设计模式之代理模式"
author       : ahcming
description  : 
date         : 2019-04-11 09:55
layout       : post
tag          : ["work", "original", "design pattern"]
blog         : true
---

## 模式介绍

代理模式主要作用是对现在功能的增强; 以买房中介为例, 真正提供房了是房地产商, 中介本身没有这个服务, 最终的服务还是由房地产商提供, 但是中介增加了这个买卖房子的效率

代理在外看起来跟真正做事的类是一样的, 所以一般是采用接口或类继承来约束;  

互联网有句名言, "没有什么问题是不能增加一层来解决的", 这个增加一层的常用实现就是代理模式

关于代理, 还有个动态代理的技术, 所谓动态, 指得是动态根据上下文参数来实现不同的增强实现, 例如AOP; 典型的技术框架有JDK动态代理及Cglib

## 代码实现

```java
public class Target {

    public void doSth() {
        // real service implment
    }

}
```

```java
public class TargetProxy extends Target {

    private Target real;

    /**
     * 方法调用前增强
     */ 
    void before() {

    }

    public void doSth() {
        before();

        real.doSth();

        after();
    }

    /**
     * 方法调用后增强
     */ 
    void after() {

    }
}
```

### 接口方式

- 通过接口来屏蔽实现细节, 是惯用的作法

### 继承的实现方式

- 当Target类是第三方的时候, 我们不能修改源码, 只能用继承
- Java是单继承的, 当TargetProxy还要其它类时, 就要取舍了

## 典型应用

- mybatis通过代理来实现事务控制

在`SqlSessionManager`类中, 所有的方法都转交给了`sqlSessionProxy`来完成, `sqlSessionProxy`又是通过JDK动态代理创建的

```java
this.sqlSessionProxy = (SqlSession) Proxy.newProxyInstance(
        SqlSessionFactory.class.getClassLoader(),
        new Class[]{SqlSession.class},
        new SqlSessionInterceptor());
```

这表明`sqlSessionProxy`把所有的事情都转给了`SqlSessionInterceptor`来处理

```java
private class SqlSessionInterceptor implements InvocationHandler {
  public SqlSessionInterceptor() {
      // Prevent Synthetic Access
  }

  @Override
  public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
    final SqlSession sqlSession = SqlSessionManager.this.localSqlSession.get();
    if (sqlSession != null) {
      try {
        return method.invoke(sqlSession, args);
      } catch (Throwable t) {
        throw ExceptionUtil.unwrapThrowable(t);
      }
    } else {
      try (SqlSession autoSqlSession = openSession()) {
        try {
          final Object result = method.invoke(autoSqlSession, args);
          autoSqlSession.commit();
          return result;
        } catch (Throwable t) {
          autoSqlSession.rollback();
          throw ExceptionUtil.unwrapThrowable(t);
        }
      }
    }
  }
}
```

整个代码的意思是, `localSqlSession`不为null, 无事务模式, 通过反射调用`localSqlSession`的方法
`localSqlSession`为null, 事务模式, 通过反射调用`autoSqlSession`的方法, 成功就commit, 异常就rollback;

通过动态代理截取所有SQL方法调用, 然后对目标方法的执行成功/异常分别执行相应的事务方法; 整个实现过程很经典

- AOP技术

这个已经是很完备的一套框架了, 有切点, 拦截条件表达式, 前拦截, 后拦截
