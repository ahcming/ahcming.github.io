---
title        : "设计模式之责任链模式"
author       : ahcming
description  : 
date         : 2019-04-10 09:55
layout       : post
tag          : ["work", "original", "design pattern"]
blog         : true
---

## 模式介绍

该模式的精髓在于Chain, 链式; 在链条上的每一个环, 就是一个单独的处理逻辑; 只有把链条上的每个环都执行过之后, 业务才算执行完成

通过这种方式, 我们可以很灵活的增加一环, 以及调整环在链条的位置

## 代码实现

```java
public interface Handler {

    public Response handle(Request request) ;
}
```

```java
public class Handler1 implements Handler {

    private Handler next;

    public Response handle(Request request) {

        // before

        Response resp = next.handler(request);

        // after 

        return resp;
    }
}
```

还有种更经典的实现

```java
public interface Filter {
    void doFilter(ServletRequest request, ServletResponse response, FilterChain chain) throws IOException, ServletException;
}
```

然后添加自己的业务过滤器

```java
public class XXXFilter implements Filter {

    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain) throws IOException, ServletException {
        // before filter code

        // next filter
        chain.doFilter(request, response);

        // after filter code
    }
}
```

大家可以猜测下`FilterChain`是怎么实现遍历`Filter`的

## 典型应用

- Servlet Filter组件; 类似还有拦截器组件

参见上面的示例代码
