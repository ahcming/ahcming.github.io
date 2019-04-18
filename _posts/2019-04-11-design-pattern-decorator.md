---
title        : "设计模式之装饰模式"
author       : ahcming
description  : 
date         : 2019-04-11 09:55
layout       : post
tag          : ["work", "original", "design pattern"]
blog         : true
---

## 模式介绍

装饰模式也是属于对现在类功能增强的一种模式

跟代理模式最大的不同在于, 装饰类与做事类方法的签名可以不一致, 限制更宽泛; 更多的区别参照代码来体会

## 代码实现

功能1

```java
public class FunctionLevel1 {

    public void doSth() {
        // 功能只能做到level1程度
    }
}
```

```java
public class FunctionLevel2 {
    private FunctionLevel1 level1;

    public FunctionLevel2(FunctionLevel1 level1) {
        this.level1 = level1;
    }

    public void doSthEnhance() {
        // 对level1#doSth再增强
        // 达到level2程度
    }
}
```

```java
public class FunctionLevel3 {
    private FunctionLevel2 level2;

    public FunctionLevel3(FunctionLevel2 level2) {
        this.level2 = level2;
    }

    public void doSthEnhanceEnhance() {
        // 对level1#doSth再增强增强
        // 达到level3程度
    }
}
```

调用代码如下:

```java
Function func = new FunctionLevel3(new FunctionLevel2(new FunctionLevel1()));
func.doSthEnhanceEnhance();
```

跟代理模式很相似, 跟代理模式最大的区别是:

- 代理模式一般只有一个真正做事的类, 所以一般在代理类中写死, 更关心的是对代理方法前后的处理
- 装饰模式是一个增强链, 每一层对前一层进行增强, 更体现实现分层的理念

## 典型应用

- Java IO框架

一个Reader的构建方法

```java
Reader reader = new BufferedReader(new InputStreamReader(new FileInputStream(new File("/tmp/aa.txt"))));
```

通过装饰模式, 底层的IO读取是`FileInputStream`, 是stream模式, byte流, 核心API如下

```java
public int read(byte b[], int off, int len) throws IOException
```

这样做效率不高, 使用`InputStreamReader`来对`FileInputStream`增强, char流, 增加了解码功能, 核心API如下

```java
public int read(char[] var1, int var2, int var3) throws IOException;
```

而`BufferedReader`又对`InputStreamReader`增强, 增加了Buffer功能, 进一步增加性能
