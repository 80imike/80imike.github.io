---
category: 工具
title: 推荐一款支持 SQL/NoSQL 数据库的通用命令行工具 USQL
date: 2018-06-22 09:00:00
tags: [Linux, 工具]
abbrlink:
updated:
toc_number: false
---

`USQL` 是一个使用 Go 语言开发的支持 SQL/NoSQL 数据库的通用命令行工具，支持多种主流的数据库软件。比如：PostgreSQL、MySQL、Oracle Database、SQLite3、Microsoft SQL Server 以及许多其它的数据库（包括 NoSQL 和非关系型数据库）。

`USQL` 的灵感来自 PostgreSQL 的 PSQL，`USQL` 支持大多数 PSQL 的核心特性，比如：设置变量、反引号参数。并具有 PSQL 不支持的其它功能，如语法高亮、基于上下文的自动补全和多数据库支持等。

项目地址：https://github.com/xo/usql

### 安装 USQL

由于 `USQL` 使用 Go 语言开发，具备了良好的跨平台特性。`USQL` 安装非常简单，官方也提供二进制、Homebrew、Scoop等多种安装方式。这里我们就使用最具通用性的二进制方式安装，以 Linux 平台为例：

```
$ wget https://github.com/xo/usql/releases/download/v0.7.0/usql-0.7.0-linux-amd64.tar.bz2
$ tar xjvf usql-0.7.0-linux-amd64.tar.bz2
$ sudo mv usql /usr/local/bin
```

如果你使用其它平台，可根据实际情况在官方[下载页面](https://github.com/xo/usql/releases)下载对应版本。

<!-- more -->

### USQL 用法

- USQL 命令行语法

```
$ usql --help
usql, the universal command-line interface for SQL databases.

usql 0.7.0
Usage: usql [--command COMMAND] [--file FILE] [--output OUTPUT] [--username USERNAME] [--password] [--no-password] [--no-rc] [--single-transaction] [--set SET] DSN

Positional arguments:
  DSN                    database url

Options:
  --command COMMAND, -c COMMAND
                         run only single command (SQL or internal) and exit
  --file FILE, -f FILE   execute commands from file and exit
  --output OUTPUT, -o OUTPUT
                         output file
  --username USERNAME, -U USERNAME
                         database user name [default: mike]
  --password, -W         force password prompt (should happen automatically)
  --no-password, -w      never prompt for password
  --no-rc, -X            do not read start up file
  --single-transaction, -1
                         execute as a single transaction (if non-interactive)
  --set SET, -v SET      set variable NAME=VALUE
  --help, -h             display this help and exit
  --version              display version and exit
```

- USQL 支持的反斜杠命令

```
$ usql
Type "help" for help.

(not connected)=> \?
General
  \q                    quit usql
  \copyright            show usql usage and distribution terms
  \drivers              display information about available database drivers
  \g [FILE] or ;        execute query (and send results to file or |pipe)
  \gexec                execute query and execute each value of the result
  \gset [PREFIX]        execute query and store results in usql variables

Help
  \? [commands]         show help on backslash commands
  \? options            show help on usql command-line options
  \? variables          show help on special variables

Query Buffer
  \e [FILE] [LINE]      edit the query buffer (or file) with external editor
  \p                    show the contents of the query buffer
  \raw                  show the raw (non-interpolated) contents of the query buffer
  \r                    reset (clear) the query buffer
  \w FILE               write query buffer to file

Input/Output
  \echo [STRING]        write string to standard output
  \i FILE               execute commands from file
  \ir FILE              as \i, but relative to location of current script

Transaction
  \begin                begin a transaction
  \commit               commit current transaction
  \rollback             rollback (abort) current transaction

Connection
  \c URL                connect to database with url
  \c DRIVER PARAMS...   connect to database with SQL driver and parameters
  \Z                    close database connection
  \password [USERNAME]  change the password for a user
  \conninfo             display information about the current database connection

Operating System
  \cd [DIR]             change the current working directory
  \setenv NAME [VALUE]  set or unset environment variable
  \! [COMMAND]          execute command in shell or start interactive shell

Variables
  \prompt [TEXT] NAME   prompt user to set internal variable
  \set [NAME [VALUE]]   set internal variable, or list all if no parameters
  \unset NAME           unset (delete) internal variable
```

- USQL 目前支持的数据库类型

| Database (scheme/driver)     | Protocol Aliases [real driver]        |
|------------------------------|---------------------------------------|
| Microsoft SQL Server (mssql) | ms, sqlserver                         |
| MySQL (mysql)                | my, mariadb, maria, percona, aurora   |
| Oracle (ora)                 | or, oracle, oci8, oci                 |
| PostgreSQL (postgres)        | pg, postgresql, pgsql                 |
| SQLite3 (sqlite3)            | sq, sqlite, file                      |
| Amazon Redshift (redshift)   | rs [postgres]                         |
| CockroachDB (cockroachdb)    | cr, cockroach, crdb, cdb [postgres]   |
| MemSQL (memsql)              | me [mysql]                            |
| TiDB (tidb)                  | ti [mysql]                            |
| Vitess (vitess)              | vt [mysql]                            |
| Google Spanner (spanner)     | gs, google, span (not yet public)     |
| MySQL (mymysql)              | zm, mymy                              |
| PostgreSQL (pgx)             | px                                    |
| Apache Avatica (avatica)     | av, phoenix                           |
| Apache Ignite (ignite)       | ig, gridgain                          |
| Cassandra (cql)              | ca, cassandra, datastax, scy, scylla  |
| ClickHouse (clickhouse)      | ch                                    |
| Couchbase (n1ql)             | n1, couchbase                         |
| Cznic QL (ql)                | ql, cznic, cznicql                    |
| Firebird SQL (firebirdsql)   | fb, firebird                          |
| Microsoft ADODB (adodb)      | ad, ado                               |
| ODBC (odbc)                  | od                                    |
| OLE ODBC (oleodbc)           | oo, ole, oleodbc [adodb]              |
| Presto (presto)              | pr, prestodb, prestos, prs, prestodbs |
| SAP HANA (hdb)               | sa, saphana, sap, hana                |
| Snowflake (snowflake)        | sf                                    |
| VoltDB (voltdb)              | vo, volt, vdb                         |

### USQL 使用实例

#### 连接到不同数据库

这里演示几个常用数据库连接方法，其它数据库也类似：

- 连接到一个 MySQL 数据库

```
# 使用默认信息连接到数据库
$ usql my://
# 使用用户名和密码连接到指定的数据库
$ usql my://user:pass@host/dbname
# 使用用户名、密码和端口连接到指定的数据库
$ usql mysql://user:pass@host:port/dbname
# 使用指定的套接字连接数据库
$ usql /var/run/mysqld/mysqld.sock
```

- 连接到一个 PostgreSQL 数据库

```
# 使用默认信息连接到数据库
$ usql pg://
# 使用用户名和密码连接到指定的数据库
$ usql pg://user:pass@host/dbname
# 使用用户名、密码和端口连接到指定的数据库
$ usql postgres://user:pass@host:port/dbname
# 使用指定的套接字连接数据库
$ usql /var/run/postgresql
```

- 连接到一个 Oracle 数据库

```
# 使用默认信息连接到数据库
$ usql or://
# 使用用户名和密码连接到指定的数据库
$ usql or://user:pass@host/sid
# 使用用户名、密码和端口连接到指定的数据库
$ usql oracle://user:pass@host:port/sid
```

- 连接到一个 SQL Server 数据库

```
# 使用默认信息连接到数据库
$ usql ms://
# 使用用户名和密码连接到指定的数据库
$ usql ms://user:pass@host/dbname
# 使用用户名、密码和端口连接到指定的数据库
$ usql mssql://user:pass@host:port/dbname
# 使用用户名和密码连接到指定实例的数据库
$ usql ms://user:pass@host/instancename/dbname
```

#### 执行查询和命令

以下例子均在 MySQL 数据库环境以执行。

- 创建一个名为 test 的数据库，并在这个数据库中建立的名为 test 的表中新增一行数据。

```
$ usql my://root:000000@localhost
Connected with driver mysql (5.7.18-log)
Type "help" for help.

my:root@localhost=> create database test;
CREATE DATABASE 1
my:root@localhost=> use test;
USE
my:root@localhost=> CREATE TABLE IF NOT EXISTS `test`(
my:root@localhost(>    `test_id` INT,
my:root@localhost(>    `name` VARCHAR(100) NOT NULL
my:root@localhost(> )ENGINE=InnoDB DEFAULT CHARSET=utf8;
CREATE TABLE
my:root@localhost=> insert into test (test_id, name) values (1, 'hello');
INSERT 1
my:root@localhost=> select * from test;
  test_id | name
+---------+-------+
        1 | hello
(1 rows)
```

- 连接到一个 MySQL 数据库并运行一个名为 script.sql 的脚本

```
$ usql my://root:000000@localhost/wordpress -f script.sql
 id  | post_author |           post_date
+-----+-------------+-------------------------------+
  673 |           1 | 2007-01-22 06:31:27 +0800 CST
  675 |           1 | 2007-01-22 06:36:39 +0800 CST
(2 rows)
```

接下来我们再举几个使用内置命令进行操作的例子。

- 打印并执行缓充区中的 SQL 语句

```
my:root@localhost=> select *
my:root@localhost-> from test
my:root@localhost-> \p
select *
from test
my:root@localhost-> \g
  test_id | name
+---------+-------+
        1 | hello
(1 rows)
```

- 快速切换到另一个数据库连接

```
ms:mike@192.168.100.210:1433/testdb=> \c my://root:000000@localhost/wordpress
Connected with driver mysql (5.7.18-log)
my:root@localhost/wordpress=> select * from wp_postmeta limit 5;
  meta_id | post_id | meta_key | meta_value
+---------+---------+----------+------------+
        1 |       1 | views    |     185245
        2 |       2 | views    |       5659
        3 |       3 | views    |       2197
        4 |       4 | views    |       1739
        5 |       5 | views    |       2002
(5 rows)
```

- 使用变量进行条件查询

```
# 设置变量
my:root@localhost/wordpress=> \set meta 2179
# 查看当前已设置的变量
my:root@localhost/wordpress=> \set
meta = '2179'
# 使用变量做为条件进行查询
my:root@localhost/wordpress=> select * from wp_postmeta where meta_value=:'meta';
  meta_id | post_id | meta_key | meta_value
+---------+---------+----------+------------+
      156 |     163 | views    |       2179
      203 |     211 | views    |       2179
(2 rows)
```

> 变量调用支持 :NAME、:'NAME'、和 :"NAME" 这三种方式进行调用。

-  使用反引号参数

```
my:root@localhost/wordpress=> \echo Welcome `echo $USER` -- 'currently:' "(" `date` ")"
Welcome root -- currently: ( Tue Jun 19 13:47:31 CST 2018 )
```

反引号参数的执行结果也可以直接设置为一个变量的值：

```
my:root@localhost=> \set MYVAR `date "+%Y-%m-%d"`
my:root@localhost=> \echo :MYVAR
2018-06-19
my:root@localhost=> select id,post_author,post_date  from wp_posts where post_date < :'MYVAR'  limit 2;
  id  | post_author |           post_date
+-----+-------------+-------------------------------+
  673 |           1 | 2007-01-22 06:31:27 +0800 CST
  675 |           1 | 2007-01-22 06:36:39 +0800 CST
(2 rows)
```

### 参考文档

http://www.google.com
https://github.com/xo/usql