---
title: Linux下使用Rinetd来实现端口转发
tags:
  - rinetd
  - Linux
categories: rinetd
abbrlink: 29683
date: 2016-05-16 09:00:02
updated:
toc_number:
---

Linux下端口转发一般都使用iptables来实现，使用iptables可以很容易将TCP和UDP端口从防火墙转发到内部主机上。但是如果需要将流量从专用地址转发到不在您当前网络上的机器上，可尝试另一个应用层端口转发程序Rinetd。Rinetd短小、高效，配置起来比iptables也简单很多。

Rinetd是为在一个Unix和Linux操作系统中为重定向传输控制协议(TCP)连接的一个工具。Rinetd是单一过程的服务器，它处理任何数量的连接到在配置文件etc/rinetd中指定的地址/端口对。尽管rinetd使用非闭锁I/O运行作为一个单一过程，它可能重定向很多连接而不对这台机器增加额外的负担。
<!-- more -->
### 安装

- 通过包安装

**CentOS**

官方源中不具有Rinetd，所以需要先安装三方源。

**配置三方源**

32位系统

```
$ vim /etc/yum.repos.d/nux-misc.repo

[nux-misc]
name=Nux Misc
baseurl=http://li.nux.ro/download/nux/misc/el6/i386/
enabled=0
gpgcheck=1
gpgkey=http://li.nux.ro/download/nux/RPM-GPG-KEY-nux.ro
```

64位系统

```
$ vim  /etc/yum.repos.d/nux-misc.repo:

[nux-misc]
name=Nux Misc
baseurl=http://li.nux.ro/download/nux/misc/el6/x86_64/
enabled=0
gpgcheck=1
gpgkey=http://li.nux.ro/download/nux/RPM-GPG-KEY-nux.ro
```

**安装Rinetd**

```
$ yum --enablerepo=nux-misc install rinetd
```

**Ubuntu**

```
$ apt-get install rinetd
```

- 编译安装

```
$ wget http://www.boutell.com/rinetd/http/rinetd.tar.gz
$ mkdir  -p /usr/man/man8   #默认会把man文件放么/usr/man/man8下面，如果没有这个目录会报目前不存在，但不影响使用. 
$ make && make install
```
  
### 配置

配置端口转发的配置文件在`/etc/rinetd.conf`


**配置文件格式**

```
[bindaddress] [bindport] [connectaddress] [connectport]
绑定的地址    绑定的端口  连接的地址      连接的端口

[Source Address] [Source Port] [Destination Address] [Destination Port]
源地址            源端口         目的地址               目的端口
```

在每一单独的行中指定每个要转发的端口。源地址和目的地址都可以是主机名或IP地址，IP 地址0.0.0.0将rinetd绑定到任何可用的本地IP地址上。例如：`0.0.0.0 8080 www.hi-linux.com 80`

**配置规则**

```
$ vim /etc/rinetd.conf

0.0.0.0 8080 172.19.94.3 8080
0.0.0.0 2222 192.168.0.103 3389
1.2.3.4 80 192.168.0.10 80
allow *.*.*.*
logfile /var/log/rinetd.log
```

说明

> 0.0.0.0表示本机绑定所有可用地址
> 将所有发往本机8080端口的请求转发到172.19.94.3的8080端口
> 将所有发往本机2222端口的请求转发到192.168.0.103的3389端口
> 将所有发往1.2.3.4的80端口请求转发到192.168.0.10的80端口
> allow设置允许访问的ip地址信息,`*.*.*.*`表示所有IP地址
> logfil设置打印的log的位置
 
### 运行

- 启动Rinetd

**脚本启动**

```
$ /etc/init.d/rinetd start
```

**手动启动**

编译安装不自带脚本

```
$ /usr/sbin/rinetd -c /etc/rinetd.conf
```

- 关闭rinetd

**脚本关闭**

```
$ /etc/init.d/rinetd stop
```

**手动关闭**

编译安装不自带脚本

```
$ pkill rinetd
```

- 注意事项

> 1.rinetd.conf中绑定的本机端口必须没有被其它程序占用
> 2.运行rinetd的系统防火墙应该打开绑定的本机端口
> 3.不支持FTP的跳转

### 参考文档

https://www.douban.com/note/527117358/
http://pvbutler.blog.51cto.com/7662323/1621753
http://blog.csdn.net/wang7dao/article/details/8498530