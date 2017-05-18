---
title: MySQL不同复制模式下忽略某些binlog事件方法
tags:
  - MySQL
  - Linux
categories: MySQL
abbrlink: 43579
date: 2016-03-21 09:00:02
updated:
---

在MySQL复制中，如何忽略slave节点上发生的主键冲突、数据不存在等错误。

在MySQL复制中，如果slave节点上遇到错误，比如数据不存在或者主键冲突等错误时，想要忽略这些错误，可以采用以下几种方法：

### 1、未启用GTID模式时

只需通过设定 SQL_SLAVE_SKIP_COUNTER 的值，即可忽略一些复制事件。例如：<!-- more -->

#### 需要先关闭SLAVE服务

```bash
root@imysql.com [test]> STOP SLAVE;
```
####  忽略N个事件（event），通常一个SQL是一个事件
```bash
root@imysql.com [test]> SET SQL_SLAVE_SKIP_COUNTER=N;
```
####  再次启动SLAVE服务
```bash
root@imysql.com [test]> START SLAVE;
```
### 2、启用GTID模式时

启用GTID，想要忽略某些错误事件就稍微麻烦一点点了。
首先，我们需要先查看当前SLAVE复制的进度：

```bash
mysql> SHOW SLAVE STATUS\G
```
从中看到，当前SLAVE复制的GTID进展是：
```bash
Slave_IO_Running: Yes
Slave_SQL_Running: No
Last_Errno: 1062
Last_Error: …Duplicate…key ‘PRIMARY’, Error_code: 1062;…
Master_UUID: f2b6c829-9c87-11e4-84e8-deadeb54b599
Retrieved_Gtid_Set: 3a16ef7a-75f5-11e4-8960-deadeb54b599:1-283,f2b6c829-9c87-11e4-84e8-deadeb54b599:1-33
Executed_Gtid_Set: 3a16ef7a-75f5-11e4-8960-deadeb54b599:1-283,f2b6c829-9c87-11e4-84e8-deadeb54b599:1-31
Auto_Position: 1
```
从上面的信息可以看到，当前从MASTER取到了1-33的事务列表，并且已执行（看Executed_Gtid_Set）到了31这个事务GTID位置，在这下一个位置（32）上发生错误。

这时候，我们需要手工调整SLAVE已清除的GTID列表 GTID_PURGED，人为通知SLAVE哪些事务已经被清除了，后续可以忽略：
```bash
root@imysql.com [test]> STOP SLAVE;
root@imysql.com [test]> RESET MASTER;
root@imysql.com [test]> SET @@GLOBAL.GTID_PURGED = “3a16ef7a-75f5-11e4-8960-deadeb54b599:1-283,f2b6c829-9c87-11e4-84e8-deadeb54b599:1-32”;
root@imysql.com [test]> START SLAVE;
```
上面这些命令的用意是，忽略 f2b6c829-9c87-11e4-84e8-deadeb54b599:32 这个GTID事务，下一次事务接着从 33 这个GTID开始，即可跳过上述错误。

### 3、无论是否启用GTID，使用pt-slave-restart工具

首先不得不说，percona toolkit工具集对DBA而言实在太方便了。pt-slave-restart工具的作用是监视某些特定的复制错误，然后忽略，并且再次启动SLAVE进程(Watch and restart MySQL replication after errors)。
简单用法示例：

#### 忽略所有1062错误，并再次启动SLAVE进程
```bash
[yejr@imysql.com ]# pt-slave-resetart -S./mysql.sock —error-numbers=1062
```
#### 检查到错误信息只要包含 test.yejr，就一概忽略，并再次启动SLAVE进程
```bash
[yejr@imysql.com ]# pt-slave-resetart -S./mysql.sock —error-text=”test.yejr”
```
综上，我们虽然可以利用工具来快速忽略复制错误，但还是要掌握如何人为忽略复制错误的方法，在没有工具的时候也能了然于胸。

转载自：http://imysql.com/2015/09/07/mysql-faq-howto-ignore-replication-errors.shtml