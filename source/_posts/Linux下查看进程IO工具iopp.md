---
title: Linux下查看进程IO工具iopp
tags:
  - iopp
  - Linux
categories: iopp
abbrlink: 41926
date: 2016-05-31 09:00:00
updated:
toc_number:
---

Linux下的IO检测工具最常用的是`iostat`，不过`iostat`只能查看到总的IO情况。如果要细看具体那一个程序点用的IO较高，可以使用`iotop` 。不过`iotop`对内核版本和Python版本有要求，虽然目前主流的CentOS和Ubuntu版本上都适用。不过考虑到其无法适用的场景，推荐个可以查看程序IO使用情况的工具`iopp`作为替代方案。

iopp目前有两个版本的，一个是C语言的，一个是C++的。两个版本各有所长，本文将分别介绍两个版本iopp的安装和使用。

### iopp C语言版本

`iopp`是一个基于C语言开发的工具，它的作者是Mark Wong，代码仅有532行，非常简洁。

<!-- more -->

iopp的项目地址：https://github.com/markwkm/iopp

#### 安装iopp

**安装编译工具**

```
$ yum install cmake
```

**编译安装iopp**

```
$ git clone https://github.com/markwkm/iopp.git
$ cd iopp
$ cmake CMakeLists.txt
$ make && make install
```

如需指定安装位置，可按如下方法

```
# 指定安装的目标路径到/usr/bin下
$ make install DESTDIR=/usr
```

注：默认安装目录位置为`/bin/iopp`

#### 使用iopp

**iopp语法**

```
$ iopp --help
usage: iopp -h|--help
usage: iopp [-ci] [-k|-m] [delay [count]]
            -c, --command display full command line       #显示完整命令行
            -h, --help display help                       #显示帮助信息
            -i, --idle hides idle processes               #隐藏空闲进程
            -k, --kilobytes display data in kilobytes     #以KB为单位显示数据
            -m, --megabytes display data in megabytes     #以MB为单位显示数据
            -u, --human-readable display data in kilo-, mega-, or giga-bytes #以方便读的方式显示数据
```


**列出进程并隐藏I/O空闲的进程**

```
$ iopp -i -k -c 1
  pid    rchar    wchar    syscr    syscw      rkb      wkb     cwkb command
  pid    rchar    wchar    syscr    syscw      rkb      wkb     cwkb command
 9311       31        0        0        0        0        0        0 iopp
  pid    rchar    wchar    syscr    syscw      rkb      wkb     cwkb command
 9311       31        0        0        0        0        0        0 iopp
  pid    rchar    wchar    syscr    syscw      rkb      wkb     cwkb command
 9311       31        0        0        0        0        0        0 iopp
  pid    rchar    wchar    syscr    syscw      rkb      wkb     cwkb command
 9311       31        0        0        0        0        0        0 iopp
  pid    rchar    wchar    syscr    syscw      rkb      wkb     cwkb command
 9311       31        0        0        0        0        0        0 iopp
  pid    rchar    wchar    syscr    syscw      rkb      wkb     cwkb command
 9311       31        0        0        0        0        0        0 iopp
  pid    rchar    wchar    syscr    syscw      rkb      wkb     cwkb command
  395        0        0        0        0        0        4        0 jbd2/dm-0-8
 1229        0        1        0        0        0        8        0 auditd
 1251        0        0        0        0        0        4        0 /sbin/rsyslogd
 1498      110        0        0        0        0        4        0 crond
 9311       31        0        0        0        0        0        0 iopp
```

iopp输出的结果也比较清晰易懂，简单解释下

> pid 进程ID
> rchar 将要从磁盘读取的字节数
> wchar 已经写入或应该要写入磁盘的字节数
> syscr 读I/O次数
> syscw 写I/O次数
> rbytes 真正从磁盘读取的字节数
> wbytes 真正写入到磁盘的字节数
> cwbytes 因为清空页面缓存而导致没有发生操作的字节数
> command 执行的命令


### iopp C++语言版本

iopp的实现原理非常简单，无非是遍历/proc/pid/io文件，读取出结果后，再通过进一步计算得出。大部分时候，我们只关注参数rbytes和wbytes两部分，基于此需求就产生了一个基于c++优化的iopp。

项目地址：https://github.com/hackerforward/iopp


#### 安装iopp

**安装编译工具**

```
$ yum install make
```

**编译安装iopp**

```
$ git clone https://github.com/hackerforward/iopp  
$ cd iopp
$ make
```

编译完成后，在当前目录生成一个iopp二进制文件

```
$ ls
curControl.h  iopp  iopp.cc  makefile  README.md
```

#### 使用iopp

C++版iopp使用起来简单粗暴，直接运行就可以了，如下

![](http://hi-linux.com/img/linux/iopp-cpp.jpg)

输出结果是时时刷新的。

### 参考文档

http://www.google.com/
https://github.com/hackerforward/iopp
https://github.com/markwkm/iopp
http://imysql.com/2014/10/12/using-iopp-instead-of-iotop.shtml
http://www.361way.com/linux-iopp/3583.html