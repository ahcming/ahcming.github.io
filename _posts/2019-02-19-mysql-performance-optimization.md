---
title        : "Mysql性能优化"
author       : ahcming
description  : 
date         : 2019-02-19 13:33
layout       : post
tag          : ["work", "original", "mysql"]
blog         : true
---

## 本文总结一些常见的Mysql优化思路及具体手段

## 优化方向
- 软件方面
    + 表创建时的考量
    + SQL优化的奇淫技巧
    + 索引层面
    + 分库分表
- Mysql方面
    + 升级
    + 连接数
    + 缓存
- 硬件方面
    + 硬盘
    + 内存
    + CPU
    + 网络

## 软件方面

软件方面是指我们使用Mysql的代码侧

我们可以从整个软件开发的过程来梳理下, 有哪些方面可以改进;

### 表创建时

建表是我们开始使用Mysql的开端, 我们要为之后的使用开个好的头

在此阶段我们需要考量的是:
- 给表选择个合适的引擎
- 主键
- 每列选择合适的类型及长度, 缺省的默认值
- 索引

> 表引擎

Mysql的表引擎有`InnoDB`, `MyISAM`, `Memory`, 常用的`InnoDB`与`MyISAM`区别如下:

| 比较维度 |         InnoDB        |        MyISAM         |
|:------:|:----------------------:|:---------------------:|
|   事务  |           支持          |        不支持         |
|   外键  |           支持          |        不支持         |
| 锁粒度   |          行锁          |         表锁          |
| 适应场景 | 大量的insert/update操作 | 大量的select/insert操作 |

一般来讲, 只有确定业务没有事务要求且主要以select为主才会选择`MyISAM`, 其它情况都是用`InnoDB`, 所以我们的选择空间并不大; 下面也以`InnoDB`为讨论对象.

> 主键

在建表时, 推荐保证表有主键列, 最好是`id unsigned bigint auto increment`, 这个是兼顾InnoDB聚集索引的特性, [参考](https://blog.csdn.net/jhgdike/article/details/60579883); 

阿里发布的Java开发规范里也有提到这点

```shell
9. 【强制】表必备三字段:id, gmt_create, gmt_modified。 
    说明:其中id必为主键，类型为unsigned bigint、单表时自增、步长为1。
    gmt_create, gmt_modified 的类型均为 date_time 类型，前者现在时表示主动创建，后者过去分词表示被 动更新
```

> 列的类型及长度, 默认值

其次, 每个列尽量选择合适的类型和长度; 合适的长度可以更省空间, 更能提升检索速度; [常见Mysql数据类型占用空间大小](/2019/04/04/mysql-data-info)

在具体实践中, 比如IP列, 如果明文保存, 使用varchar(15)就行了, 有些人甚至在程序里把ip转成long然后使用bigint存储, 查询的时候用inet_ntoa转换下;
比如最后修改时间列, 一般用TIMESTAMP, 还可自动更新; 一些status, category, type之类的数据, 推荐使用tinyint unsigned;

在建表时, 除了列的类型选择合适之外; 还有一点, 列不要使用null值, 有以下几个理由:

- 有null值的列, mysql索引不好优化; 后期对有null列增加索引不方便, 尤其是唯一索引
- 所有使用null的列都可以通过给个有意义的默认值来实现, 这样业务上更友好, 也不容易出错
- 在使用not in, != 等条件查询时, 统计聚合类查询时, 容易出错 [参考](https://www.cnblogs.com/balfish/p/7905100.html)
- is null, is not null 等语句是不走索引(待考证), [参考](https://www.jianshu.com/p/3cae3e364946)
- null是占用空间, 空值''反而不占用空间(待考证)

> 索引

在后面索引优化里再一起总结

### SQL优化

SQL优化主要是重构一些低效的写法, 或者写法没有命中索引; 首先介绍下explain命令

```shell
mysql> explain select * from user;
+----+-------------+-------+------------+------+---------------+------+---------+------+------+----------+-------+
| id | select_type | table | partitions | type | possible_keys | key  | key_len | ref  | rows | filtered | Extra |
+----+-------------+-------+------------+------+---------------+------+---------+------+------+----------+-------+
|  1 | SIMPLE      | user  | NULL       | ALL  | NULL          | NULL | NULL    | NULL |    1 |   100.00 | NULL  |
+----+-------------+-------+------------+------+---------------+------+---------+------+------+----------+-------+
```

我们关注的目标列是type, key, key_len, rows, Extra

type列表示我们这条SQL走的查询类型, 常用类型如下:

- const: 常量级, 一般都是主键查询; 性能非常好, 我们的目标
- ref: 索引, 一般是索引查询命中; 性能很好, 我们的目标
- range: 索引, 一般是索引范围查询命中; 性能还可以, 我们的目标
- index: 全索引查询; 性能渣渣, 尽量避免, 除非索引很小
- ALL: 全表查询; 性能渣渣渣渣, 尽量避免, 除非表很小

key列如果有值, 表示使用的索引名; 当表有多条索引时, 用来判断是否使用了我们期望的索引

key_len列表示索引的长度, 如果有些列的前缀区分度很大, 我们可以使用该列的部分值而非全列

rows列表示该SQL检索的行数; 首先, 这个值应该越小越好; 其次, explain返回的只是个估计值, 只能做参考

Extra列里有些信息对我们优化还是有很大帮助的

- Using filesort: 发生了硬盘或内存排序,一般是由order by 或 group by触发的
- Using temporary :使用了临时表,通常和filesort一起发生
- Using where: 数据库服务层从存储引擎提取了数据又进行了一次条件过滤

SQL的优化依据和方向就是explain命令的结果

1. type值不是const, ref, range
    1. 索引存不存在; 如果索引不存在, 添加索引, 重复步骤1
    2. 索引存在; 分析为什么没有走索引, 修改SQL写法, 重复步骤1; 一般都是SQL写法问题, 下面会通过一些典型案例说明
    3. SQL是不是太复杂, 大SQL, 要不要拆分
2. type值是const, ref, range; rows很大
    1. 是不是索引列区分度不大; 分析数据
    2. 是不是表数据太大; 分库分表
3. type值是const, ref, range; rows很小; 完美, 结束

SQL这块有太多的坑可以踩, 但是也很零散没有系统性, 现在列举一些典型的, 持续补充中

> 子查询替换为join方式

> 分页查询优化

> 大SQL分拆成多个小SQL


### 索引层面优化

索引是数据库提升检索速度的重要技术; 


### 分库分表



## 参考

- [mysql 字段定义不要用null的分析](https://www.cnblogs.com/balfish/p/7905100.html)
- [MySQL中NULL对索引的影响](https://www.jianshu.com/p/3cae3e364946)