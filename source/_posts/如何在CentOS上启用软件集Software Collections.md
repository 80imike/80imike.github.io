---
title: 如何在CentOS上启用软件集Software Collections
tags:
  - Centos
  - Linux
categories: Centos
abbrlink: 62916
date: 2016-05-09 09:00:00
updated:
toc_number:
---
### 什么是SCL

SCL项目主页：https://www.softwarecollections.org/

SCL(Software Collections)可以让你在同一个操作系统上安装和使用多个版本的软件，而不会影响整个系统的安装包。SCL为社区的以下需求而设计：创建和使用软件集合生产系统、概念验证系统、开发测试平台。SCL目前已经支持Fedora和RHEL(衍生版本如CentOS也包含在内)。

SCL的创建就是为了给RHEL/CentOS用户提供一种以方便、安全地安装和使用应用程序和运行时环境的多个(而且可能是更新的)版本的方式，同时避免把系统搞乱。与之相对的是第三方源，它们可能会在已安装的包之间引起冲突。
<!-- more -->

现有软件选集

现在有以下软件选集可供CentOS 6.5或以上版本应用

Ruby 1.9.3 (ruby193)
Python 2.7 (python27)
Python 3.3 (python33)
PHP 5.4 (php54)
Perl 5.16.3 (perl516)
Node.js 0.10 (nodejs010)
MariaDB 5.5 (mariadb55)
MySQL 5.5 (mysql55)
PostgreSQL 9.2 (postgresql92)

更多的软件集可参看这里：https://www.softwarecollections.org/en/scls/


### 安装SCL

在CentOS下访问SCL，需要安装CentOS Software Collections。它是CentOS Extras软件库的一部份，并可通过以下指命进行安装

Centos 7

```
$ yum install centos-release-scl
```

Centos 6

```
$ yum install centos-release-SCL
```

注意：Centos6和Centos7的包名是区分大小写的！

要启用和运行SCL中的应用，你还需要安装下列包

```
$ sudo yum install scl-utils scl-utils-build
```

### SCL的设置及启用

SCL设置步骤非常简单

#### SCL语法

```
$ scl --help
usage: scl <action> [<collection>...] <command>
   or: scl -l|--list [<collection>...]
   or: scl register <path>
   or: scl deregister <collection> [--force]

Options:
    -l, --list            list installed Software Collections or packages
                          that belong to them
    -h, --help            display this help and exit

Actions:
    enable                calls enable script from Software Collection
                          (enables a Software Collection)
    <SCL script name>     calls arbitrary script from a Software Collection
```


#### 浏览可用的版本

```
$ yum list available | grep scl
$ yum --disablerepo="*" --enablerepo="*scl*" list available
```

#### 搜索SCL中的包

```
$ yum --disablerepo="*" --enablerepo="*scl*" search <keyword>
```

#### 启用一个已经安装的SCL包

需要在每个命令中使用scl命令显式启用它(即想在哪条命令中使用SCL中的包，就得通过scl命令执行该命令)

```
$ scl enable <scl-package-name> <command>
```

如果想在启用的包时执行多条命令，你可以像下面那样创建一个启用SCL的bash会话

```
$ scl enable <scl-package-name> bash
```

### SCL使用实例

- 以要安装Python 3.3为例

#### 安装Python集合

```
$ yum install python33-*
```

#### 查看从SCL中安装的包的列表

```
$ scl --list
python33
```

在安装python33包后检查默认的python版本，你会发现默认的版本并没有改变

```
$ python --version
Python 2.6.6
```

SCL的优点之一就是安装其中的包不会覆盖任何系统文件，并且保证不会引起与系统中其它库和应用的冲突。

#### 开始使用SCL

你可以使用以下三种方法来启用SCL

##### 运行一个命令

```
$ scl enable python33 ./hello.py
```

##### 启动一个会话

```
$ scl enable python33 bash
```

- 以要安装Apache 2.4为例

#### 安装Apache集合

```
yum install httpd24*
```

#### 启动一个服务器

```
$ chkconfig httpd24-httpd on
$ /etc/init.d/httpd24-httpd start
```


更详细的SCL指南，参考官方的[快速入门指南](https://www.softwarecollections.org/en/docs/)


### 参考文档

http://www.google.com
http://xmodulo.com/enable-software-collections-centos.html
https://linux.cn/article-6776-1.html
https://wiki.centos.org/zh/AdditionalResources/Repositories/SCL

