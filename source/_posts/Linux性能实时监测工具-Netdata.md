---
title: Linux性能实时监测工具-Netdata
tags:
  - Netdata
  - Linux
categories: Linux
abbrlink: 42392
date: 2016-04-05 09:00:00
updated:
---

### Netdata是什么

Netdata是一款Linux性能实时监测工具。

Netdata是一个高度优化的Linux守护进程，它为Linux系统，应用程序，SNMP服务等提供实时的性能监测。

它用可视化的手段，将被监测者最细微的细节，展现了出来。这样，你便可以清晰地了解你的系统和应用程序此时的状况。

GITHUB地址：https://github.com/firehol/netdata

![](https://www.hi-linux.com/img/linux/netdata1.gif)
<!-- more -->

使用此软件，你可以得到：

> 1.优美的界面：bootstrap框架下的控制界面
> 2.自定义的控制界面：你可以使用简单的HTML代码去自定义控制界面(不需要使用javascript)
> 3.极其的快速而高效：程序使用C进行编写(默认安装下，预计只有2%的单核CPU使用率和少许的内存使用率)
> 4.零配置：你只需要去安装它，接着它就会自动地监测一切数据
> 5.零依赖：它的静态网络文件和网络接口拥有自己的网络服务器
> 6.可扩展：用它自身的插件API(可以使用许多方式来制作它的插件，从bash到node.js),你可以检测任何可以衡量的数据。
> 7.可嵌入：它可以在任何Linux内核可以运行的地方运行

监测内容：

这是它目前检测的内容(大多数都不需要进行配置，安装后即可开始监测)

> 1.CPU的使用率,中断，软中断和频率(总量和每个单核)
> 2.RAM，互换和内核内存的使用率(包括KSM和内核内存deduper)
> 3.硬盘输入/输出(每个硬盘的带宽，操作，整理，利用等)
 
![](https://www.hi-linux.com/img/linux/netdata2.gif)
 
> 4.IPv4网络(数据包，错误，分片)：
> TCP：连接，数据包，错误，握手
> UDP:数据包，错误
> 广播：带宽，数据包
> 组播：带宽，数据包

![](https://www.hi-linux.com/img/linux/netdata3.gif)

> 5.Netfilter/iptables Linux防火墙(连接，连接跟踪事件，错误等)
> 6.IPv4/IPv6 networking 
> 7.进程(运行，受阻，分叉，活动等)
> 8.熵
> 9.NFS文件服务器，v2,v3,v4(输入/输出，缓存，预读，RPC调用)
> 10.网络服务质量(唯一一个可实时可视化网络状况的工具)

![](https://www.hi-linux.com/img/linux/netdata4.gif)

> 11.应用程序，通过对进程树进行分组(CPU,内存，硬盘读取，硬盘写入，交换，线程，管道，套接字等)

![](https://www.hi-linux.com/img/linux/netdata5.gif)

> 12.Apache Web服务器状态(v2.2, v2.4)
> 13.Nginx Web服务器状态
> 14.Mysql数据库(多台服务器，单个显示：带宽，查询/s, 处理者，锁，问题，临时操作，连接，二进制日志，线程，innodb引擎等)
> 15.ISC Bind域名服务器(多个服务器，单个显示：客户，请求，查询，更新，失败等)
> 16.Postfix邮件服务器的消息队列(条目，大小)
> 17.Squid代理服务器(客户带宽和请求，服务带宽和请求)
> 18.硬件传感器(温度，电压，风扇，电源，湿度等)
> 19.NUT UPSes(负载，充电，电池电压，温度，使用指标，输出指标)
> 
> 你可以监测任意数量的SNMP服务，不过你需要进行配置。
> 你可以对此软件进行扩展，可以使用任何语言编写插件，以此来从任何来源收集数据。


### 安装

#### 安装依赖包

运行netdata你必须先安装以下依赖包`git`, `make`, `gcc`, `autoconf`, `autogen`,`automake`,`pkg-config`.

以下为不同发行版本的安装方法

Debian / Ubuntu

```bash
apt-get install zlib1g-dev gcc make git autoconf autogen automake pkg-config
```

Centos / Redhat

```bash
yum install zlib-devel gcc make git autoconf autogen automake pkgconfig
```
**注：autogen需epel-testing源**

ArchLinux

```bash
pacman -S --needed base-devel libmnl libnetfilter_acct zlib
or run the following (and ignore the next section):
wget https://aur.archlinux.org/cgit/aur.git/snapshot/netdata.tar.gz
tar xf netdata.tar.gz && cd netdata/
makepkg -sri
```

#### 安装netdata

##### 下载源码

```bash
git clone https://github.com/firehol/netdata.git --depth=1
cd netdata
```

##### 编译

```bash
./netdata-installer.sh
```

默认安装位置

> It will be installed at these locations:
> 
>   - the daemon    at /usr/sbin/netdata
>   - config files  at /etc/netdata
>   - web files     at /usr/share/netdata
>   - plugins       at /usr/libexec/netdata
>   - cache files   at /var/cache/netdata
>   - log files     at /var/log/netdata


也可用`--install`修改安装位置

安装netdata到/opt/netdata下

```bash
./netdata-installer.sh --install /opt
```

更多安装选项：可使用`./netdata-installer.sh --install`查看.

##### 更新netdata

更新源代码

```bash
cd /path/to/netdata.git
git pull
```

重新编译和安装

```bash
./netdata-installer.sh
```

##### 启动和停止

启动NetData

```bash
/usr/sbin/netdata
```

停止NetData

```bash
killall netdata
```

加入开机启动

编辑`/etc/rc.local`加入以下行

```bash
vim /etc/rc.local
/usr/sbin/netdata
```

#### 访问netdata

默认编译安装完成后可用浏览器访问`http://localhost:19999/`
访问netdata的配置文件可访问`http://127.0.0.1:19999/netdata.conf`