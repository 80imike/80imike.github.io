---
category: MySQL
title: MySQL正式发布高可用架构——MySQL InnoDB Cluster
date: 2017-05-02 09:00:00
tags: [技巧, MySQL]
abbrlink:
updated:
toc_number: false
---

MySQL的高可用架构无论是社区还是官方，一直在技术上进行探索，这么多年提出了多种解决方案，比如`MMM`、 `MHA`、`NDB Cluster`、`Galera Cluster`、`InnoDB Cluster`、`PhxSQL`、`MySQL Fabric`。

最近Oracle的MySQL团队发布了`InnoDB Cluster`的GA(General Availability)版本。

`MySQL InnoDB Cluster`是`MySQL`的一套完整的、全栈的高可用解决方案。这个解决方案的目标是：让用户很容易就能把多个MySQL实例集成在一起提供冗余，来支持MySQL数据库高可用的特性。

<!-- more -->

**MySQL InnoDB Cluste技术架构**

![](https://www.hi-linux.com/img/linux/mysql-innodb-cluster.jpg)

`MySQL InnoDB Cluste`架构图

MySQL InnoDB Cluster解决方案由下面三个不同产品和技术组成的：

- 支持Group Replication的MySQL 5.7+服务器

`Group Replication`是一种可用于实现容错系统的技术。通过`Group Replication`来将数据复制到集群的所有成员，同时提供容错、自动故障转移和弹性扩展等重要特性。

- MySQL Shell 1.0+

通过内置的`AdminAPI`来创建和管理整个InnoDB集群。

- MySQL Router 2.1+

MySQL Router是Mysql-Proxy的替代方案，MySQL Router是处于应用Client和DB Server之间的轻量级代理程序，提供了应用程序与后端数据库的透明路由。MySQL Router确保客户端请求是负载均衡的，在任何数据库故障的情况下，都会传输到正确的服务器。

更多信息可参考：

http://mysqlserverteam.com/mysql-innodb-cluster-ga/
https://dev.mysql.com/doc/refman/5.7/en/mysql-innodb-cluster-userguide.html
