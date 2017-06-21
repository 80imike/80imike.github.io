---
category: MySQL
title: MySQL 5.7多源复制实践
date: 2017-06-21 9:00:00
tags: [MySQL,技巧]
abbrlink:
updated:
toc_number: false
---

MySQL 5.7发布后，在复制方面有了很大的改进和提升。比如开始支持多源复制 (multi-source) 以及真正的支持多线程复制了。多源复制可以使用基于二进制日志的复制或者基于事务的复制。下面我们讲讲如何配置基于二进制日志的多源复制。

### 什么是多源复制

首先，我们需要清楚几种常见的复制模式：

1）一主一从
2）一主多从
3）级联复制
4）multi-master

MySQL 5.7 之前只能实现一主一从、一主多从或者多主多从的复制。如果想实现多主一从的复制，只能使用 MariaDB，但是 MariaDB 又与官方的 MySQL 版本不兼容。

MySQL 5.7 开始支持了多主一从的复制方式，也就是多源复制。MySQL 5.7 版本相比之前的版本，无论在功能还是性能、安全等方面都已经有不少的提升。

<!-- more -->

首先，我们需要清楚 `multi-master` 与 `multi-source` 复制不是一样的。`multi-master` 复制通常是环形复制，你可以在任意主机上将数据复制给其他主机。

![](https://www.hi-linux.com/img/linux/mysql-multi-source-1.jpg)

`multi-source` 是不同的。简单的说，多源复制就是将多个主库同步到一个从库上面，从而增加从的利用率，节省了机器。如下图：

![](https://www.hi-linux.com/img/linux/mysql-multi-source-2.jpg)

**多源复制使用场景**

- 数据分析部门会需要各个业务部门的部分数据做数据分析，这个时候就可以用到多源复制把各个主数据库的数据复制到统一的数据库中。

- 在从服务器进行数据汇总，如果我们的主服务器进行了分库分表的操作，为了实现后期的一些数据统计功能，往往需要把数据汇总在一起再统计。

- 在从服务器对所有主服务器的数据进行备份，在MySQL 5.7之前每一个主服务器都需要一个从服务器，这样很容易造成资源浪费，同时也加大了DBA的维护成本，但MySQL 5.7引入多源复制，可以把多个主服务器的数据同步到一个从服务器进行备份。

**使用多源复制的必要条件**

不管是使用基于二进制日志的复制或者基于事务的复制，要开启多源复制功能必须需要在从库上设置 `master-info-repository` 和 `relay-log-info-repository` 这两个参数。

这两个参数是用来存储同步信息的，可以设置的值为 `FILE` 和 `TABLE` ，默认值是 `FILE`。比如 `master-info` 就保存在 `master.info` 文件中, `relay-log-info` 保存在 `relay-log.info` 文件中，如果服务器意外关闭，正确的 `relay-log-info` 没有来得及更新到 `relay-log.info` 文件，这样会造成数据丢失。

为了数据更加安全，通常设为 `TABLE`。这些表都是 `innodb` 类型的，支持事务。相对文件存储安全得多。在 MySQL 库下可以看见这两个表信息，分别是 `mysql.slave_master_info` 和 `mysql.slave_relay_log_info`。

这两个参数也是可以动态调整的。

```
SET GLOBAL master_info_repository = 'TABLE';
SET GLOBAL relay_log_info_repository = 'TABLE';
```

如果要启用 `enhanced multi-threaded slave `(多线程复制)，可以设置以下参数

```
slave-parallel-type=LOGICAL_CLOCK
slave-parallel-workers=8
relay_log_recovery=ON
```

如果SLAVE已经为开启状态，那么需要首先关闭SLAVE(STOP SLAVE;)。

### 配置多源复制

#### 环境准备

这里一共使用了三台机器，MySQL版本都为5.7.18。

| 机器名 | IP地址 | MySQL角色 |
|---|---|---|
| dev-master-01 | 192.168.2.210 | MySQL 主库 |
| dev-node-01 | 192.168.2.211 | MySQL 主库 |
| dev-node-02 | 192.168.2.212 | MySQL 从库 |

#### 安装MySQL

MySQL安装比较简单，官方都有提供不同系统的相应软件源。这里以 Ubuntu 16.04 系统为例：

- 从MySQL官方网站下载APT源

```
$ wget https://dev.mysql.com/get/mysql-apt-config_0.8.6-1_all.deb
```

更多软件源可参考：`http://dev.mysql.com/downloads/repo/apt/`，如果是 `CentOS/RHEL` 系统可参考官方文档：`https://dev.mysql.com/doc/refman/5.7/en/linux-installation-yum-repo.html`

- 安装MySQL软件源并更新

```
$ dpkg -i mysql-apt-config_0.8.6-1_all.deb
$ apt-get update
```

- 安装MySQL Server和MySQL Client

```
$ apt-get install mysql-server mysql-client
```

- 启动MySQL Server

```
$ service mysql start
```

- 检查MySQL Server是否成功启动

```
$ service mysql status
● mysql.service - MySQL Community Server
   Loaded: loaded (/lib/systemd/system/mysql.service; enabled; vendor preset: enabled)
   Active: active (running) since Mon 2017-06-12 17:16:09 CST; 32s ago
  Process: 10442 ExecStart=/usr/sbin/mysqld --daemonize --pid-file=/var/run/mysqld/mysqld.pid (code=exited, status=0/SUCCESS)
  Process: 10399 ExecStartPre=/usr/share/mysql/mysql-systemd-start pre (code=exited, status=0/SUCCESS)
 Main PID: 10446 (mysqld)
    Tasks: 27
   Memory: 190.8M
      CPU: 362ms
   CGroup: /system.slice/mysql.service
           └─10446 /usr/sbin/mysqld --daemonize --pid-file=/var/run/mysqld/mysqld.pid
```

#### 配置MySQL多源复制

- 修改MySQL主配置文件

配置 MySQL 多源复制，主要是需要在 MySQL 从服务器的主配置文件 `[mysqld]` 段中添加以下两行：

```
$ vim /etc/mysql/mysql.conf.d/mysqld.cnf

master-info-repository = table
relay-log-info-repository = table
```

MySQL主服务器配置片断

以 `dev-master-01` 为例，另一台 Master 也是类似的配置方法。

```
$ vim /etc/mysql/mysql.conf.d/mysqld.cnf

server-id = 1
log-bin = /var/log/mysql/mysql-bin
log_bin_index = /var/log/mysql/mysql-bin.index
expire_logs_days = 30
max_binlog_size  = 100M
binlog_format = ROW
```

MySQL从服务器配置片断

```
$ vim /etc/mysql/mysql.conf.d/mysqld.cnf

server-id = 3
log-slave-updates = true
skip-slave-start = true
expire_logs_days = 30
max_binlog_size  = 100M
log-bin = /var/log/mysql/mysql-bin
relay-log = /var/log/mysql/relay-log
relay-log-index = /var/log/mysql/relay-log-index
relay-log-info-file = /var/log/mysql/relay-log.info
master-info-repository = table
relay-log-info-repository = table
report-port = 3306
report-host = 192.168.2.212
replicate-do-db = master1
replicate-do-db = master2
replicate_wild_do_table=master1.%
replicate_wild_do_table=master2.%
```

注：`server-id` 每台必须配置为不一样，比如 `dev-master-01` 为1，`dev-node-01` 为2，`dev-node-02` 为3。这里没有给出全部配置，其它请根据实际情况自行配置。


- 重启MySQL服务器

```
$ service mysql restart
```

- 创建具有复制权限的用户

在两台 MySQL Master 上创建

```
mysql> grant replication slave on *.* to 'repl'@'192.168.2.%' identified by '000000';
mysql> flush privileges;
```

- 从库分别连接至两个主库

MySQL 5.7 有了通信渠道的概念，每一个通信渠道都是一个从服务器到主服务器获得二进制日志的链接。这意味着每个通信渠道都得有一个 `IO_THREAD`。对于每一个主服务器，我们需要运行不同的 `CHANGE MASTER` 命令和`FOR CHANNEL` 这个参数来分别提供不同通信链接名字。

下面开始设置需要同步的源，同步两个主服务器的数据到从服务器上。

设置同步源到 Master1 (在 MySQL 从服务器上执行)

```
mysql> CHANGE MASTER TO MASTER_HOST='192.168.2.210',
MASTER_USER='repl',
MASTER_PORT=3306,
MASTER_PASSWORD='000000',
MASTER_LOG_FILE='mysql-bin.000001',
MASTER_LOG_POS=1 FOR CHANNEL 'master1';
```

设置同步源到 Master2 (在 MySQL 从服务器上执行)

```
mysql> CHANGE MASTER TO MASTER_HOST='192.168.2.211',
MASTER_USER='repl',
MASTER_PORT=3306,
MASTER_PASSWORD='000000',
MASTER_LOG_FILE='mysql-bin.000001',
MASTER_LOG_POS=1 FOR CHANNEL 'master2';
```

启动所有SLAVE

```
mysql> START SLAVE;
```

也可以单独启动需要同步的通道。

```
mysql> START SLAVE FOR CHANNEL 'master1';
mysql> START SLAVE FOR CHANNEL 'master2';
```

停止和 RESET 复制的命令也同 START 类似，可以操作所有的，也可以操作单个通道。

查看SLAVE信息

```
mysql> SHOW SLAVE STATUS\G

...
Slave_IO_Running: Yes
Slave_SQL_Running: Yes
...
```

确认 `Slave_IO_Running` 和 `Slave_SQL_Running` 两个参数都为 Yes 状态。

如果要查看单一信道的复制的详细状态，可以使用以下命令：

```
mysql> SHOW SLAVE STATUS FOR CHANNEL 'master1'\G;
```

#### 测试多源复制

- 在主库(dev-master-01)实例创建一些数据。

```
mysql> create database master1;
mysql> use master1;
mysql> CREATE TABLE `test1` (`id` int(11) DEFAULT NULL,`count` int(11) DEFAULT NULL);
mysql> insert into test1 values(1,1);
```

- 在主库(dev-node-01)实例创建一些数据。

```
mysql> create database master2;
mysql> use master2;
mysql> CREATE TABLE `test2` (`id` int(11) DEFAULT NULL,`count` int(11) DEFAULT NULL);
mysql> insert into test2 values(1,1);
```

- 在从库(dev-node-02)实例检查数据是否成功复制。

```
mysql> select * from master1.test1;
+------+-------+
| id   | count |
+------+-------+
|    1 |     1 |
+------+-------+
1 row in set (0.00 sec)

mysql> select * from master2.test2;
+------+-------+
| id   | count |
+------+-------+
|    1 |     1 |
+------+-------+
1 row in set (0.00 sec)
```

- 查看复制管理视图

列出所有的复制信道的复制状态概况：

![](https://www.hi-linux.com/img/linux/mysql-multi-source-3.png)

在 `performance_schema` 库中，提供了复制相关的一些视图，可供查看复制相关的信息。

```
mysql> use performance_schema;
mysql> show tables like '%repl%';
+-------------------------------------------+
| Tables_in_performance_schema (%repl%)     |
+-------------------------------------------+
| replication_applier_configuration         |
| replication_applier_status                |
| replication_applier_status_by_coordinator |
| replication_applier_status_by_worker      |
| replication_connection_configuration      |
| replication_connection_status             |
| replication_group_member_stats            |
| replication_group_members                 |
+-------------------------------------------+
8 rows in set (0.00 sec)
```

这些表里分别有多源通道的配置信息和多源通道的状态信息，另外还有连接配置信息和连接状态信息，如果配置了多线程复制的话，还会有多线程配置信息和多线程状态信息。

### 其它一些需要注意的点

- 初次配置耗时较长，需要将各个 master 的数据 dump 下来，再 source 到 slave 上。
- 需要考虑各 master 数据增长频率，slave 的数据增长频率是这些数据的总和。如果太高，会导致大量的磁盘IO，造成数据更新延迟，最严重的是会影响正常的查询。
- 如果多个主数据库实例中存在同名的库，则同名库的表都会放到一个库中；
- 如果同名库中的表名相同且结构相同，则数据会到一起；如果结构不同，则先建的有效。

### 参考文档

http://www.google.com
http://www.ywnds.com/?p=7154
http://blog.itpub.net/27808137/viewspace-1848036/
http://www.cnblogs.com/xuanzhi201111/p/5151666.html
https://dev.mysql.com/doc/refman/5.7/en/replication-options-slave.html
