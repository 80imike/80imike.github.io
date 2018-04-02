---
category: MySQL
title: 推荐一款 MySQL 表结构自动同步工具——mysql-schema-sync
date: 2018-03-22 09:00:00
tags: [Linux, MySQL]
abbrlink:
updated:
toc_number: false
---

mysql-schema-sync 是一款使用 Go 开发跨平台的 MySQL 表结构自动同步工具。主要用于解决多个环境数据库表结构不同步问题。 

mysql-schema-sync 支持功能：

- 同步新表
- 同步字段 变动：新增、修改
- 同步索引 变动：新增、修改
- 支持预览（只对比不同步变动）
- 邮件通知变动结果
- 支持屏蔽更新表、字段、索引、外键
- 支持本地比线上额外多一些表、字段、索引、外键

项目地址：https://github.com/hidu/mysql-schema-sync

<!-- more -->

### 安装

mysql-schema-sync 的安装非常简单，开箱即用。

```
# 安装 Go
$ apt-get install golang-go

# 建立 GOPATH 目录
$ mkdir $HOME/mysql-schema-sync

# 设置 GOPATH 并把 $GOPATH/bin 目录加入到 $PATH 变量，便于使用下面的二进制程序。
$ vim ~/.bash_profile
export GOPATH=$HOME/mysql-schema-sync
export PATH="$PATH:$GOPATH/bin"

# 下载软件包
$ go get -u github.com/hidu/mysql-schema-sync
```

> 注：GOPATH 是作为编译后二进制的存放目的地和 import 包时的搜索路径。GOPATH 之下主要包含三个目录: bin、pkg、src。
>
>- src 存放源代码（比如：.go .c .h .s等）。
>- pkg 存放编译后生成的文件（比如：.a）。
>- bin 存放编译后生成的可执行文件。

### 配置

mysql-schema-sync 默认配置文件是 config.json，默认在 src/github.com/hidu/mysql-schema-sync/ 目录里。

```
$ ls src/github.com/hidu/mysql-schema-sync/
check.sh  config.json  create_dest.sh  fmt.sh  Godeps  internal  LICENSE  main.go  README.md  vendor
```

- 配置文件示例

```
$ cd src/github.com/hidu/mysql-schema-sync/
$ vim config.json

{
     "source":"root:000000@(127.0.0.1:3306)/wordpress",
     "dest":"root:000000@(127.0.0.1:3306)/wordpress_new",
     "alter_ignore":{
        "tb1*":{
            "column":["aaa","a*"],
            "index":["aa"],
            "foreign":[]
        }
     },
     //  tables: table to check schema,default is all.eg :["order_*","goods"]
     "tables":[],
     "email":{
         "send_mail":true,
         "smtp_host":"smtp.163.com:25",
         "from":"xxx@163.com",
         "password":"xxx",
         "to":"xxx@qq.com"
     }
}
```

- 主要配置项说明

```
source: 设置同步的源数据库的相关信息。
dest: 设置同步的目标数据库的相关信息。
alter_ignore：忽略指定的表或字段，表名为 tableName，可以配置 column 和 index，支持通配符 *。
tables：配置需要同步的表，为空则是不限制。数组格式，eg: ["goods","order_*"]。
email：配置发送邮件通知的相关信息，当运行失败或者有表结构变化的时候你可以收到邮件通知。
```

### 运行

- mysql-schema-sync 命令使用语法

```
$ mysql-schema-sync# mysql-schema-sync  --help
Usage of mysql-schema-sync:
  -conf string
    	json config file path (default "./config.json")
  -dest string
    	mysql dsn dest,eg test@(127.0.0.1:3306)/imis
  -drop
    	drop fields,index,foreign key
  -mail_to string
    	overwrite config's email.to
  -source string
    	mysql dsn source,eg: test@(10.10.0.1:3306)/test
	when it is not empty ignore [-conf] param
  -sync
    	sync shcema change to dest db
  -tables string
    	table names to check
	eg : product_base,order_*

mysql schema sync tools 0.3
https://github.com/hidu/mysql-schema-sync/
```

- mysql-schema-sync 参数说明

```
-conf string 指定配置文件名称。
-dest string 指定同步的目的数据库,eg：root:000000@(127.0.0.1:3306)/wordpress。
-source string 指定同步的源数据库 eg：root:000000@(127.0.0.1:3306)/wordpress_new。该项不为空时，忽略读入 -conf 参数项。
-drop 是否对本地多出的字段和索引进行删除，默认值为否。
-sync 是否将修改同步到目标数据库中去，默认值为否。
-tables string 待检查同步的数据库表，为空则是全部。eg : product_base,order_*。
```

- 预览并生成变更SQL

默认情况下，不会直接把变更应用到目标数据库的。

```
$ mysql-schema-sync -conf config.json > db_alter.sql  2>/dev/null 
$ cat db_alter.sql

-- Table : wp_2_options
-- Type  : alter
-- RealtionTables :
-- SQL   :
ALTER TABLE `wp_2_options`
ADD `addnewfield2` int(11) DEFAULT NULL;
```

- 直接生成变更并同步到目标库

```
$ mysql-schema-sync -conf config.json -sync
```

- 同时同步到多个目标库

官方有提供一个 SHELL 脚本 `check.sh` 可以同时在多个库间同步。只需为要同步的多个库生成多个以 .json 为后缀的配置文件，`check.sh` 脚本会依次运行每份配置。

脚本默认在当前目录调用 mysql-schema-sync，这里需要根据实际情况修改下：

```
$ cat check.sh
...

for f in `ls *.json`
do
     mysql-schema-sync -conf $f -sync
done
...
```

运行脚本，完成后会在当前目录的 log 目录下记录每次运行后的日志。 

```
$ bash check.sh
```

- 定时完成数据库同步

如果你需经常定时同步数据库，可以按下格式配置一个计划任务：

```
30 * * * * cd /your/path/xxx/ && bash check.sh >/dev/null 2>&1
```

### 参考文档

http://www.google.com
https://github.com/hidu/mysql-schema-sync




