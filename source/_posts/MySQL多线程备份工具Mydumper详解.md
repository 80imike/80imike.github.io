---
title: MySQL多线程备份工具Mydumper详解
tags:
  - MySQL
  - Linux
categories: MySQL
abbrlink: 26407
date: 2016-05-17 09:00:00
updated:
toc_number:
---

### Mydumper介绍

MySQL在备份方面包含了自身的mysqldump工具，但其只支持单线程工作，这就使得它无法迅速的备份数据。而mydumper作为一个实用工具，能够良好支持多线程工作，这使得它在处理速度方面十倍于传统的mysqldump。其特征之一是在处理过程中需要对列表加以锁定，因此如果我们需要在工作时段执行备份工作，那么会引起DML阻塞。但一般现在的MySQL都有主从，备份也大部分在从上进行，所以锁的问题可以不用考虑。这样mydumper能更好的完成备份任务。

Mydumper是一个针对MySQL和Drizzle的高性能多线程备份和恢复工具，开发人员主要来自MySQL,Facebook,SkySQL公司。
<!-- more -->
**Mydumper特性**

> 轻量级C语言写的
> 执行速度比mysqldump快10倍
> 事务性和非事务性表一致的快照(适用于0.2.2以上版本)
> 快速的文件压缩
> 支持导出binlog(新版本里已经不能备份binlog)
> 支持将备份文件切块
> 多线程备份(因为是多线程逻辑备份，备份后会生成多个备份文件)
> 多线程恢复(适用于0.2.1以上版本)
> 备份时对MyISAM表施加FTWRL(FLUSH TABLES WITH READ LOCK),会阻塞DML语句
> 以守护进程的工作方式，定时快照和连续二进制日志(适用于0.5.0以上版本)
> 开源 (GNU GPLv3)

Mydumper项目地址: https://launchpad.net/mydumper/

### Mydumper备份机制

#### Mydumper工作流程图

![](http://www.hi-linux.com/img/linux/mydumper.png)

**主要步骤概括**

- 主线程 FLUSH TABLES WITH READ LOCK, 施加全局只读锁，以阻止DML语句写入，保证数据的一致性
- 读取当前时间点的二进制日志文件名和日志写入的位置并记录在metadata文件中，以供即使点恢复使用
- N个（线程数可以指定，默认是4）dump线程 START TRANSACTION WITH CONSISTENT SNAPSHOT; 开启读一致的事物
- dump non-InnoDB tables, 首先导出非事物引擎的表
- 主线程 UNLOCK TABLES 非事物引擎备份完后，释放全局只读锁
- dump InnoDB tables, 基于事物导出InnoDB表
- 事物结束

**Mydumper的less locking模式**

Mydumper使用`--less-locking`可以减少锁等待时间，此时mydumper的执行机制大致为

- 主线程 FLUSH TABLES WITH READ LOCK(全局锁)
- Dump线程 START TRANSACTION WITH CONSISTENT SNAPSHOT;
- LL Dump线程 LOCK TABLES non-InnoDB(线程内部锁)
- 主线程UNLOCK TABLES
- LL Dump线程 dump non-InnoDB tables
- LL DUmp线程 UNLOCK non-InnoDB
- Dump线程 dump InnoDB tables
 

#### Mydumper备份所生成的文件

所有的备份文件在一个目录中，目录可以自己指定。

**目录中包含一个metadata文件**

- 记录了备份数据库在备份时间点的二进制日志文件名，日志的写入位置，如果是在从库进行备份，还会记录备份时同步至主库的二进制日志文件及写入位置

**每个表有两个备份文件**

- database.table-schema.sql 表结构文件
- database.table.sql 表数据文件
- 如果对表文件分片，将生成多个备份数据文件，可以指定行数或指定大小分片

**binary logs(新版已废弃)**

启用`--binlogs`选项后，二进制文件存放在binlog_snapshot目录下

**daemon mode**

- 在这个模式下，有五个目录0、1、binlogs、binlog_snapshot、last_dump。
- 备份目录是0和1，间隔备份，如果mydumper因某种原因失败而仍然有一个好的快照，当快照完成后，last_dump指向该备份。

### Mydumper安装

Mydumper使用C语言编写，使用glibc库。mydumper安装所依赖的软件包：`glibc`、 `zlib`、 `pcre`、 `pcre-devel`、 `gcc`、 `gcc-c++`、`cmake`、` make`、` mysql客户端库文件`。

**安装依赖包**

- Centos

```
$ yum install glib2-devel mysql-devel zlib-devel pcre-devel cmake
```

- Ubuntu

```
$ apt-get cmake make install libglib2.0-dev libmysqlclient15-dev zlib1g-dev libpcre3-dev g++
```

**编译安装**

```
$ wget https://launchpad.net/mydumper/0.9/0.9.1/+download/mydumper-0.9.1.tar.gz
$ tar xzvf mydumper-0.9.1.tar.gz
$ cd mydumper-0.9.1
$ cmake .
$ make
$ make install
```

安装完成后生成两个二进制文件mydumper和myloader位于/usr/local/bin目录下

**检查版本**

```
$ mydumper -V                    
mydumper 0.9.1, built against MySQL 5.6.29

$ myloader -V
myloader 0.9.1, built against MySQL 5.6.29
```
 
### Mydumper使用

Mydumper主要有以下两个命令：mydumper用于备份，myloader用于恢复。

**mydumper命令一览**

```
$ mydumper --help

Usage:
  mydumper [OPTION...] multi-threaded MySQL dumping

Help Options:
  -?, --help                  Show help options

-B, --database              要备份的数据库，不指定则备份所有库
-T, --tables-list           需要备份的表，名字用逗号隔开
-o, --outputdir             备份文件输出的目录
-s, --statement-size        生成的insert语句的字节数，默认1000000(这个参数不能太小，不然会报 Row bigger than statement_size for tools.t_serverinfo)
-r, --rows                  将表按行分块时，指定的块行数，指定这个选项会关闭 --chunk-filesize
-F, --chunk-filesize        将表按大小分块时，指定的块大小，单位是 MB
-c, --compress              压缩输出文件
-e, --build-empty-files     如果表数据是空，还是产生一个空文件（默认无数据则只有表结构文件）
-x, --regex                 支持正则表达式匹配'db.table',如mydumper –regex '^(?!(mysql|test))'
-i, --ignore-engines        忽略的存储引擎，用都厚分割
-m, --no-schemas            不备份表结构
-d, --no-data               不备份表数据
-G, --triggers              不备份触发器
-E, --events                不备份事件
-R, --routines              不备份存储过程和函数
-k, --no-locks              不使用临时共享只读锁，使用这个选项会造成数据不一致
--less-locking              减少对InnoDB表的锁施加时间（这种模式的机制下文详解）
-l, --long-query-guard      设定阻塞备份的长查询超时时间，单位是秒，默认是60秒（超时后默认mydumper将会退出）
--kill-long-queries         杀掉长查询 (不退出)
-b, --binlogs               导出binlog
-D, --daemon                启用守护进程模式，守护进程模式以某个间隔不间断对数据库进行备份
-I, --snapshot-interval     dump快照间隔时间，默认60s，需要在daemon模式下
-L, --logfile               使用的日志文件名(mydumper所产生的日志), 默认使用标准输出
--tz-utc                    设置时区，只有备份应用到不同时区的时使用。默认是--skip-tz-utc是关闭的
--skip-tz-utc               同上
--use-savepoints            使用savepoints来减少采集metadata所造成的锁时间，需要 SUPER 权限
--success-on-1146           Not increment error count and Warning instead of Critical in case of table doesn't exist
-h, --host                  连接的主机名
-u, --user                  备份所使用的用户
-p, --password              密码
-P, --port                  端口
-S, --socket                使用socket通信时的socket文件
-t, --threads               开启的备份线程数，默认是4
-C, --compress-protocol     压缩与mysql通信的数据
-V, --version               显示版本号
-v, --verbose               输出信息模式, 0 = silent, 1 = errors, 2 = warnings, 3 = info, 默认为 2
--lock-all-tables           锁全表，代替FLUSH TABLE WITH READ LOCK
-U, --updated-since         Use Update_time to dump only tables updated in the last U days
--trx-consistency-only      Transactional consistency only
```
 
**myloader命令一览**

```
$ myloader --help
Usage:
  myloader [OPTION...] multi-threaded MySQL loader 

-d, --directory                   备份文件的文件夹
-q, --queries-per-transaction     每次事物执行的查询数量，默认是1000
-o, --overwrite-tables            如果要恢复的表存在，则先drop掉该表，使用该参数，需要备份时候要备份表结构
-B, --database                    需要还原的数据库
-s, --source-db                   还原的数据库
-e, --enable-binlog               启用还原数据的二进制日志
-h, --host                        主机
-u, --user                        还原的用户
-p, --password                    密码
-P, --port                        端口
-S, --socket                      socket文件
-t, --threads                     还原所使用的线程数，默认是4
-C, --compress-protocol           压缩协议
-V, --version                     显示版本
-v, --verbose                     输出模式, 0 = silent, 1 = errors, 2 = warnings, 3 = info, 默认为2
```

### Mydumper实例

#### 备份实例 

备份wordpress库到/var/backup/wordpress文件夹中，并压缩备份文件

```
$ mydumper -u root -p root -h localhost -B wordpress -c -o /var/backup/wordpress
```

备份所有数据库，并备份二进制日志文件，备份至/var/backup/alldb文件夹

```
$ mydumper -u root -p root -h localhost -o /var/backup/alldb
```

备份wordpress.wp_posts表，且不备份表结构，备份至/var/backup/wordpress-01文件夹

```
$ mydumper -u root -p root -h localhost -B wordpress -T wp_posts -m -o /var/backup/wordpress-01
```

只导出数据不导出表结构

```
$ mydumper -h 127.0.0.1 -u root -p root --database wordpress --no-schemas
```

不指定输出目录会在当前目录下生成一个以当前时间命名的目录，类似`export-20160517-114713`


默认无数据则只有表结构文件，加上`--build-empty-files`参数后，即使是一张空表，仍然会创建一个文件。

```
$ mydumper -h 127.0.0.1 -u root -p root --build-empty-files
```

设置长查询的上限，如果存在比这个还长的查询则退出mydumper，也可以设置杀掉这个长查询

```
$ mydumper -h 127.0.0.1 -u root -p root --long-query-guard 300 --kill-long-queries
```

实现此功能需要指定`--long-query-guard`参数，后面加上限值即可。同时杀掉长查询，需要指定`--kill-long-queries`参数。

设置需要导出的列表`-–tables-list`，逗号分割

```
$ mydumper -h 127.0.0.1 -u root -p root --tables-list=test.mt_test,robin.test
```

只备份t_task和t_guid表

```
$ mydumper --database=tools --outputdir=/var/backup/tools/ --tables-list=t_task,t_guid
```

注意此参数需要加上数据库名字。执行完成后，在导出目录即可看到上述两张表的表结构以及数据。

通过regex设置正则表达式，需要设置数据库名字

```
$ mydumper -h 127.0.0.1 -u root -p root --regex="beebol.*|tools.*"
```

此功能跟上面的`-–tables-list`类似。

只备份以t_server开头的表

```
$ mydumper --database=tools --outputdir=/var/backup/tools/ --regex="tools.t_server*"
```

备份出了名称为tmp.*的表，并压缩备份文件

```
$ mydumper -u root -p 123456 -P 3306 -m -c -b --regex=tmp.* -B test -o /var/backup/tmp/
```

只备份abc、bcd、cde库

```
$ mydumper -u backup -p 123456  -h 192.168.180.13 -P 3306 -t 3 -c -l 3600 -s 10000000 -e --regex 'abc|bcd|cde' -o bbb/
```

不备份abc、mysql、test数据库

``` 
$ mydumper -u backup -p 123456  -h 192.168.180.13 -P 3306 -t 3 -c -l 3600 -s 10000000 -e --regex '^(?!(abc|mysql|test))' -o bbb/
```

把单表分成多个chunks

```
$ mydumper -h 127.0.0.1 -u root -p root --rows 2000
```

实现此功能，加上`--rows`参数。如果一张表的记录数超过设置的值，则这张表会拆分成多个SQL文件，命名规则如下：数据库名.表名.0000x.sql，x 从 0 开始。

过滤某个引擎的表

```
$ mydumper -h 127.0.0.1 -u root -p root -B test --ignore-engines=innodb
```

加上`--ignore-engines`参数后，指定的存储引擎就会被过滤，亦即不导出指定存储引擎的表。

查看详细日志

```
$ mydumper -h 127.0.0.1 -u root -p root -B test -v 3
```

加上-v参数即可查看日志，取值可以是 0、1、2、3，分别表示静默模式、只输出错误、只输出警告、详细信息，默认取值是2。

指定导出线程数

```
$ mydumper -h 127.0.0.1 -u root -p root -B test --threads 10
```
mydumper是多线程的。加上`--threads`参数后，可以指定线程数，如果导出的数据较多，建议指定此参数，并且设置一个合理的值。另外，加上此参数，明显导出速度快了很多，这就是多线程的优势。当然，多线程肯定会消耗更多的系统资源。

后台运行

```
$ mydumper -h 127.0.0.1 -u root -p root -B test --daemon
```

压缩导出的SQL文件

```
$ mydumper -h 127.0.0.1 -u root -p root -B test --compress
```

压缩后的SQL文件以.gz 结尾。我们可以使用gunzip命令来解压。具体用法是：`gunzip –c filename.gz > filename`

远程备份

```
$ mydumper -h 远程服务器地址 -u root -p root -o /var/backup/mydumper -v 3 -c 9 -C -e -t 8
```

#### 还原实例

```
$ myloader -u root -p root -h localhost -B wordpress -d /var/backup/wordpress
```

还原到另一台服务器

```
$ myloader -u root -p 123456 -h 192.168.200.25 -P 3307 -B wordpress -d /var/backup/wordpress
```

如表存在先删除

```
$ myloader -u root -p 123456 -h 192.168.200.25 -P 3306 -o -B wordpress -d /var/backup/wordpress
```

这里需要注意使用该参数，备份目录里面需要有表结构的备份文件。

### 参考文档

http://www.google.com
http://www.cnblogs.com/linuxnote/p/3817698.html
https://dbarobin.com/2015/04/07/mydumper/
http://www.cnblogs.com/zhoujinyi/p/3423641.html