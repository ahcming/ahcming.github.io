---
title        : "Mysql InnoDB引擎的一些使用总结"
author       : ahcming
description  : 
date         : 2019-04-04 12:39
layout       : post
tag          : ["work", "original", "mysql"]
blog         : true
---

## InnoDB索引树

先上图, InnoDB索引树大概长这样:
![mysql innodb index](/assets/images/mysql/innodb-index.png)

InnoDB的索引采用的是B+树数据结构, 聚集索引, 每个索引分别对应一颗索引树

其中主键索引树的叶子结点里存储的是每行数据

> InnoDB的表必须要有主键; 如果没有主键, InnoDB会隐式指定一列做为主键, 不可见

非主键索引树的叶子节点存储的是主键索引的指针

[聚集索引对非聚集索引的优势](https://www.cnblogs.com/shijingxiang/articles/4743324.html) 参见这篇文章

## 估算指定表结构最优性能的最大行数

现在我们来估算最大高度为3层的B+索引树能够检索的最大的行数

假设非叶子节点能存储N个指针, 每个叶子节点能存储M条数据;

对于3层聚集索引树, Level1, Level2都是非叶子节点, Level3是叶子结点;
那Level1层都是非叶子节点, 并且只有1个根节点, 里面包含了N个指向Level2的指针;
Level2层最多有N个节点, 每个节点最多包含N个指向Level3的指针;
Level3层最多则有N*N个节点, 每个节点包含M条数据;
所以整个3层的索引树一共能检索`N x N x M`条数据, 那这个值大概是多少呢?

索引树中每一个节点的大小是16K, 可通过以下命令查询; 

```shell
mysql> show variables like 'innodb_page_size';
+------------------+-------+
| Variable_name    | Value |
+------------------+-------+
| innodb_page_size | 16384 |
+------------------+-------+
```

[page size的大小对性能影响](https://www.linuxidc.com/Linux/2012-09/70716.htm)

所以我们可以大致认为:

> N = 16384 / 索引大小

> M = 16384 / 数据大小

只要我们知道了表每行的数据大小及索引大小, 就能大概估算出单表的最大行数了; 下一小节就说明了单条数据大小及索引大小怎么查

下面我们来开始估算, 假设表每行数据大小1K, 主键列采用bigint, 则

> M=16K/1K=16条

bigint大小8byte, 加上指针本身的大小6byte, 则

> N=(16K/14B) = 1170个

> 每个非叶子节点上有1170个主键值, 检索时使用二分查找法, 性能可以忽略吗?

最佳性能的最大行数大概为2000W:

> 1170x1170x16==21902400

表空间大概是20G

> 21902400/1024/1024==20.8GB

而整个Level0, Level1层占用的存储空间为18.29M, 索引存储效率也是很高效: 

> (1 + 1170) * 1170 * 14B/1024/1024 = 18.29MB 

类似我们可以计算, 当树的高度为4时, 索引树非叶子节点总大小: 

> (1 + 1170 + 1170 * 1170) * 1170 * 14B/1024/1024 = 6114MB

可检索的行数, 将近256亿条; bigint已经不够用~~

> 1170 * 1170 * 1170 * 16 = 25625808000

整个表空间达到23.86TB

> 1170 * 1170 * 1170 * 16 * 1K / 1024/1024/1024=23.86

### 查看表的行大小, 索引大小

```shell
-- 实际中把table_schema, TABLE_NAME换成你自己的db, table即可

select ENGINE, TABLE_ROWS, AVG_ROW_LENGTH, DATA_LENGTH, INDEX_LENGTH/TABLE_ROWS as AVG_INDEX_LENGTH, INDEX_LENGTH, DATA_FREE, AUTO_INCREMENT, (DATA_LENGTH+INDEX_LENGTH)/1024/1024 as "SIZE (MB)", UPDATE_TIME
from information_schema.tables 
where table_schema='mysql' and TABLE_NAME='help_relation'; 
```

输出如下

```shell
+--------+------------+----------------+-------------+-----------------+--------------+-----------+----------------+------------+-------------+
| ENGINE | TABLE_ROWS | AVG_ROW_LENGTH | DATA_LENGTH | MAX_DATA_LENGTH | INDEX_LENGTH | DATA_FREE | AUTO_INCREMENT | SIZE (MB)  | UPDATE_TIME |
+--------+------------+----------------+-------------+-----------------+--------------+-----------+----------------+------------+-------------+
| InnoDB |       1425 |             57 |       81920 |               0 |            0 |   4194304 |           NULL | 0.07812500 | NULL        |
+--------+------------+----------------+-------------+-----------------+--------------+-----------+----------------+------------+-------------+
```

## 怎么查看InnoDB索引树高度, page level

首先要查看表的根节点编号

```sql
SELECT b.name, a.name, index_id, type, a.space, a.PAGE_NO
FROM information_schema.INNODB_SYS_INDEXES a, information_schema.INNODB_SYS_TABLES b
WHERE a.table_id = b.table_id AND a.space <> 0;
```

在最新版本Mysql里, 需要用以下SQL查询

```sql
SELECT b.name, a.name, index_id, type, a.space, a.PAGE_NO
FROM information_schema.INNODB_INDEXES a, information_schema.INNODB_TABLES b
WHERE a.table_id = b.table_id AND a.space <> 0;
```

输出如下:

```shell
+----------------+-----------+----------+------+-------+---------+
| name           | name      | index_id | type | space | PAGE_NO |
+----------------+-----------+----------+------+-------+---------+
| sys/sys_config | PRIMARY   |      139 |    3 |     1 |       4 |
| study/userinfo | PRIMARY   |      142 |    3 |     3 |       4 |
| study/userinfo | idx_uid   |      143 |    0 |     3 |       5 |
| study/user     | PRIMARY   |      140 |    3 |     2 |       4 |
| study/user     | udx_login |      144 |    2 |     2 |       6 |
| study/user     | idx_uid   |      141 |    0 |     2 |       5 |
+----------------+-----------+----------+------+-------+---------+
```

PAGE_NO列就每个表里每个索引的根结点编号; 从上面的结果也可以看出, 主键的Page Number都是4

因为主键索引B+树的根页在整个表空间文件中的第4个页开始，所以可以算出它在文件中的偏移量：16384*4=65536（16384为页大小）。

另外根据《InnoDB存储引擎》中描述在根页的64偏移量位置前2个字节，保存了page level的值，因此我们想要的page level的值在整个文件中的偏移量为：16384*4+64=65536+64=65600，前2个字节中。

接下来我们用hexdump工具，查看user表空间文件指定偏移量上的数据：

```shell
$ hexdump -s 65600 -n 10 user.ibd 
0010040 00 00 00 00 00 00 00 00 00 8c                  
001004a
```

查询结果是`00 00`, 所以page level为0 + 1 = 1

## 实验

为了让实验更有说服力和真实感, 参照真实的业务设计了一张评论表

```sql
CREATE TABLE `comment` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '评论ID',
  `article` int NOT NULL DEFAULT 0 COMMENT '文章ID',
  `author` varchar(7) NOT NULL DEFAULT '' COMMENT '作者ID',
  `reply_id` bigint unsigned NOT NULL DEFAULT 0 COMMENT '回复的评论ID',
  `reply_author` varchar(7) NOT NULL DEFAULT '' COMMENT '回复的评论作者ID',
  `upload_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '发表时间',
  `content` varchar(1024) NOT NULL DEFAULT '' COMMENT '评论内容',
  `like` int NOT NULL DEFAULT 0 COMMENT '点赞数',
  `dislike` int NOT NULL DEFAULT 0 COMMENT '点踩数',
  `status` tinyint DEFAULT 0 COMMENT '1为审核中，0为正常评论',
  `media_ids` varchar(256) DEFAULT NULL COMMENT '评论引用的媒体id,多个用逗号分隔',
  `type` tinyint DEFAULT NULL COMMENT '评论类型，0：不带图，1：系统图，2：自定义图',
  `ip` varchar(15) NOT NULL DEFAULT '' COMMENT '评论者IP',
  `device` varchar(32) NOT NULL DEFAULT '' COMMENT '评论者设备号',
  PRIMARY KEY (`id`),
  INDEX `idx_article` (`article`),
  INDEX `idx_author` (`author`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;
```

然后写个脚本, 往表里插入50000条数据, 估算出每行数据的平均大小

```shell
select ENGINE, TABLE_ROWS, AVG_ROW_LENGTH, DATA_LENGTH, INDEX_LENGTH/TABLE_ROWS as AVG_INDEX_LENGTH, INDEX_LENGTH, DATA_FREE, AUTO_INCREMENT, (DATA_LENGTH+INDEX_LENGTH)/1024/1024 as "SIZE (MB)", UPDATE_TIME
from information_schema.tables 
where table_schema='study' and TABLE_NAME='comment2'; 

+--------+------------+----------------+-------------+------------------+--------------+-----------+----------------+-------------+---------------------+
| ENGINE | TABLE_ROWS | AVG_ROW_LENGTH | DATA_LENGTH | AVG_INDEX_LENGTH | INDEX_LENGTH | DATA_FREE | AUTO_INCREMENT | SIZE (MB)   | UPDATE_TIME         |
+--------+------------+----------------+-------------+------------------+--------------+-----------+----------------+-------------+---------------------+
| InnoDB |      49329 |            223 |    11026432 |          85.6914 |      4227072 |   3145728 |          50001 | 14.54687500 | 2019-04-04 22:42:59 |
+--------+------------+----------------+-------------+------------------+--------------+-----------+----------------+-------------+---------------------+
```

那M=16 * 1024 / 223 = 73; 

- 当page level=1时, 应该最多只能存储73行(level0下面直接挂行数据)
- 当page level=2时, 应该最多只能存储1100 * 73行
- 当page level=3时, 应该最多只能存储1100 * 1100 * 73行

实验结果:

- level1大概能存储90行左右
- level2大概能存储72000行
- level3验证到了3000W, 插入需要半小时, 高度还是3; 后面的不想跑了

数据没有完全对上, 说明这之间还有其它知识不知道; 但数量级是对的, 说明上面的理论大体没有错, 用来估算单表行数没什么问题

## 参考
- [InnoDB一棵B+树可以存放多少行数据？](http://www.cnblogs.com/leefreeman/p/8315844.html)
- [查看 InnoDB表中每个的索引高度](https://mp.weixin.qq.com/s/1-gJLMq3RBllgaWWB149Hg?)
- [MySQL的InnoDB索引原理详解](https://www.cnblogs.com/shijingxiang/articles/4743324.html)
- [MySQL中MyISAM和InnoDB的索引方式以及区别与选择](https://blog.csdn.net/ljfphp/article/details/80029968)
