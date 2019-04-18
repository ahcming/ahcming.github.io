---
title        : "设计模式之迭代器模式"
author       : ahcming
description  : 
date         : 2019-04-09 09:55
layout       : post
tag          : ["work", "original", "design pattern"]
blog         : true
---

## 模式介绍

迭代器模式就是用来遍历一个集合的方式; 

在Java中, 我们可以对任何一个数据结构只要实现了Iterable接口, 就可以使用`for-each`语法遍历该数据集合

```java
for(E e : myADT) {
    process(e);
}
```

那为什么我们不直接用`for`循环来遍历集合, 而还要搞个`Iterator`呢, 跟集合相比`Iterator`有2个优点:
- iterator没有长度的限制, 所以可以表示无穷的数列
- iterator摆脱了数据底层存储结构的限制, 可以是Collection的子类, 可以是自定义数据结构

Iterator里最主要的方法是`hasNext`与`next`, 根据当前的状态, `hasNext`来判断有无下元素, `next`转移到下一状态; 
通过这2个方法就可以遍历整个数据, 类似代码如下

```java
for(Iterator<T> it = collection.iterator(); it.hasNext( ); ) {
    T element = it.next();
    process(element);
}
```

最好的写法还是用`for-each`, 只要懂的`for-each`的底层实现跟上面的写法是相同的



如果我们的方法需要数据集里每个元素进行处理, 最好的方法是传一个`Iterator`对象而非`Collection`对象, 有以下2点考虑:

- 使用`Iterator`可以摆脱数据结构的约束, 可以是自定义数据结构, 也可以是JDK Collection框架里的类型, 灵活度更高
- 可以表示无穷的数列, 比如质数数列, 使用`Iterator#next`可以一直获取下去, 只要在next方法里正确实现获取下一质数; Collection就做不到这一点

## 代码实现

在此贴出JDK里Iterable与Iterator的源码

```java
public interface Iterable<T> {

    Iterator<T> iterator();
}
```

```java
public interface Iterator<E> {
    boolean hasNext();

    E next();
}
```

## 典型应用

- `HasMap`的`HashIterator`, `EntryIterator`, `KeyIterator`, `ValueIterator`

通过定义`EntryIterator`, `KeyIterator`, `ValueIterator`来实现`entrySet`, `keys`, `values`方法

- `LinkedHashMap`的`LinkedHashIterator`

`LinkedHashMap`的定义是按数据插入顺序或最后访问顺序排序

`LinkedHashMap`的底层数据存储还是`HashMap`, 但是维护一条链表

```java
/**
 * The head (eldest) of the doubly linked list.
 */
transient LinkedHashMap.Entry<K,V> head;

/**
 * The tail (youngest) of the doubly linked list.
 */
transient LinkedHashMap.Entry<K,V> tail;
```

通过此链表来实现插入顺序或最后访问顺序排序的功能

而具体的实现就在`LinkedHashIterator`, 使用`Iterator`模式