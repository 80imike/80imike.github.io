---
title: MySQL的增强型语法高亮终端-MyCli
tags:
  - MyCli
  - Linux
categories: MyCli
abbrlink: 23030
date: 2016-05-19 09:00:00
updated:
toc_number:
---
### MyCli简介

MyCli是一个MySQL的命令行客户端，可以实现自动补全(auto-completion)和语法高亮。MyCli也可用于MariaDB和Percona。

项目地址：http://mycli.net/

**特性**

- MyCli使用[Python Prompt Toolkit](https://github.com/jonathanslenders/python-prompt-toolkit/)编写。
- 支持语法高亮
- 当你输入SQL关键字，数据库的表格和列时可自动补全。
- 智能补全(默认启用)，会提示文本感应的(context-sensitive)补全。
- 配置文件在第一次启动时，自动创建在`~/.myclirc`

<!-- more -->

**效果展示**

![](https://www.hi-linux.com/img/linux/mycli.gif)

### MyCli安装

如果你已会安装Python包，那就简单了

```
$ pip install mycli
```

如果你是在OS X平台，那就用homebrew

```
$ brew update && brew install mycli
```

### MyCli使用

```
$ mycli --help                        
Usage: mycli [OPTIONS] [DATABASE]

Options:
  -h, --host TEXT               Host address of the database.
  -P, --port INTEGER            Port number to use for connection. Honors
                                $MYSQL_TCP_PORT
  -u, --user TEXT               User name to connect to the database.
  -S, --socket TEXT             The socket file to use for connection.
  -p, --password TEXT           Password to connect to the database
  --pass TEXT                   Password to connect to the database
  --ssl-ca PATH                 CA file in PEM format
  --ssl-capath TEXT             CA directory
  --ssl-cert PATH               X509 cert in PEM format
  --ssl-key PATH                X509 key in PEM format
  --ssl-cipher TEXT             SSL cipher to use
  --ssl-verify-server-cert      Verify server's "Common Name" in its cert
                                against hostname used when connecting. This
                                option is disabled by default
  -v, --version                 Version of mycli.
  -D, --database TEXT           Database to use.
  -R, --prompt TEXT             Prompt format (Default: "\t \u@\h:\d> ")
  -l, --logfile FILENAME        Log every query and its results to a file.
  --defaults-group-suffix TEXT  Read config group with the specified suffix.
  --defaults-file PATH          Only read default options from the given file
  --auto-vertical-output        Automatically switch to vertical output mode
                                if the result is wider than the terminal
                                width.
  -t, --table                   Display batch output in table format.
  --warn / --no-warn            Warn before running a destructive query.
  --local-infile BOOLEAN        Enable/disable LOAD DATA LOCAL INFILE.
  --login-path TEXT             Read this path from the login file.
  --help                        Show this message and exit.
```

### MyCli示例

- 用root登陆到数据库

```
$ mycli -h localhost -u root -p123
Version: 1.7.0
Chat: https://gitter.im/dbcli/mycli
Mail: https://groups.google.com/forum/#!forum/mycli-users
Home: http://mycli.net
Thanks to the contributor - www.mysqlfanboy.com
mysql root@localhost:(none)> 
```

- 用root登陆并连接到数据库tpcc

```
$ mycli mysql://root@localhost:3306/tpcc
Version: 1.7.0
Chat: https://gitter.im/dbcli/mycli
Mail: https://groups.google.com/forum/#!forum/mycli-users
Home: http://mycli.net
Thanks to the contributor - Magnus udd
mysql root@localhost:tpcc>
```
### 参考文档

http://www.google.com
http://mycli.net/
https://github.com/dbcli/mycli
https://linux.cn/article-5934-1.html
