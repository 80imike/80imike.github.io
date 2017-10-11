---
category: linux
title: Linux下配置多网卡多网关
date: 2017-10-11 09:00:00
tags: [linux, 技巧]
abbrlink:
updated:
toc_number: false
---

大家好，今天给大家介绍一下Linux下配置多网卡多网关的方法。@Hi-Linux

### 场景一 多运营商线路

比较典型的一种场景：一台 Linux 服务器上有三个网口并接入三个不同运营商的网络，以实现不同运营商用户访问其对应的网络线路，来减少网络延时。

服务器及对应网络信息如下：

一台 Ubuntu 16.04 server，这里一共使用三块网卡。假定网络信息如下：

<!-- more -->

网卡名称  | IP | 网关 | 备注 
---------|----------|---------|---------
 enp0s5  | 192.168.100.212 | 192.168.100.1  | 电信线路
 enp0s6  | 192.168.110.213 | 192.168.110.1  | 联通线路 
 enp0s7  | 192.168.120.214 | 192.168.120.1  | 教育网线路

> 这里 IP 只是为了区分各运营商线路做的示例，实际情况请以运营商给出的网络信息调整。

下面我们来看如何实现这样的需求：

在 Linux 下一台多网卡服务器不能同时配置两个及以上的默认网关，因为默认网关(Default Gateway)只能配置一个，通过 gateway 参数配置的网关在这里实际为默认路由。

这里通过配置 Linux 下策略路由来实现，通过原线路返回的策略路由可以实现多线多 IP 同时在线。让从同一运营商过来的请求由原运营商线路返回，比如：电信IP过来的请求按照电信路由返回，从网通IP过来的求从网通路由返回。

#### 配置网络

- 首先配置三块网卡的基本网络信息。

```
$ vim /etc/network/interfaces

auto enp0s5
iface enp0s5 inet static
address 192.168.100.212
netmask 255.255.255.0

auto enp0s6
iface enp0s6 inet static
address 192.168.110.213
netmask 255.255.255.0

auto enp0s7
iface enp0s7 inet static
address 192.168.120.214
netmask 255.255.255.0
```

- 重启网络

```
$ /etc/init.d/networking restart
```

- 查看配置好的网络情况

```
$ ip a|grep enp0s
2: enp0s5: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    inet 192.168.100.212/24 brd 192.168.100.255 scope global enp0s5
3: enp0s6: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    inet 192.168.110.213/24 brd 192.168.110.255 scope global enp0s6
4: enp0s7: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    inet 192.168.120.214/24 brd 192.168.120.255 scope global enp0s7
```

- 查看各网卡当前路由

```
$ ip route show
192.168.100.0/24 dev enp0s5  proto kernel  scope link  src 192.168.100.212
192.168.110.0/24 dev enp0s6  proto kernel  scope link  src 192.168.110.213
192.168.120.0/24 dev enp0s7  proto kernel  scope link  src 192.168.120.214
```

#### 增加路由表

Linux 中的路由由路由规则和路由表组成。路由规则指定当数据包满足规则时，应转交到哪个路由表；路由表根据数据包的信息，选择下一跳。

可通过 `ip rule` 看当前的路由策略，如:

```
$ ip rule
0:      from all lookup local
32766:  from all lookup main
32767:  from all lookup default
```

从这里也可以看出在内核中最多支持 32768 条路由规则。这里的 main 表是系统主要的路由表，所有的路由规则都写在这个表中。

- 查看 main 表 

```
$ ip route list table main
192.168.100.0/24 dev enp0s5  proto kernel  scope link  src 192.168.100.212
192.168.110.0/24 dev enp0s6  proto kernel  scope link  src 192.168.110.213
192.168.120.0/24 dev enp0s7  proto kernel  scope link  src 192.168.120.214
```

Linux 中支持 256 张路由表，编号为 0 到 255，可直接使用编号操作，也可使用编号的别名操作，编号和其别名的对应关系在 /etc/iproute2/rt_tables 文件中。

默认有 local,main,default 三个路由表，这三个路由表的名称命名就来自 /etc/iproute2/rt_tables。

```
$ cat /etc/iproute2/rt_tables
#
# reserved values
#
255	local
254	main
253	default
0	unspec
#
# local
#
#1	inr.ruhep
```

> 注：数字范围为0-255，但0、255、254、253是保留的，不能使用。

- 增加三个路由表

在 /etc/iproute2/rt_tables 配置文件里面添加三个不同的路由表别名。增加三个路由表分别是: enp0s5:ChinaTel、enp0s5:ChinaCnc、enp0s5:ChinaEdu。

```
$ echo "101 ChinaTel" >> /etc/iproute2/rt_tables
$ echo "102 ChinaCnc" >> /etc/iproute2/rt_tables
$ echo "103 ChinaEdu" >> /etc/iproute2/rt_tables
```

因为这三个路由表的只是用来响应来自不同接口的，所以只需要每个路由表里面建立默认网关即可。

```
$ ip route add default via 192.168.100.1 dev enp0s5 table ChinaTel
$ ip route add default via 192.168.110.1 dev enp0s6 table ChinaCnc
$ ip route add default via 192.168.120.1 dev enp0s7 table ChinaEdu
```

如果要指定某一源 IP，可以加上 `src` 参数。

```
$ ip route add default via 192.168.100.1 dev eth0 src 192.168.100.212 table ChinaTel
```

- 查看新增路由表中内容

```
$ ip route show table ChinaTel
default via 192.168.100.1 dev enp0s5

$ ip route show table ChinaCnc
default via 192.168.110.1 dev enp0s6

$ ip route show table ChinaEdu
default via 192.168.120.1 dev enp0s7
```

- 增加路由原路返回规则，使来自不同的口的走不同的路由表。 

```
$ ip rule add from 192.168.100.212 table ChinaTel 
$ ip rule add from 192.168.110.212 table ChinaCnc
$ ip rule add from 192.168.120.212 table ChinaEdu
```

> 注意：此处原路是广义上的说法，并不是请求的路径与响应的路径完全相同。

如果要指定规则优先级，可以加上 `pref` 参数。`pref` 即路由表内序号，如果不加 `pref`，则将在已有的规则最小序号前插入。

```
$ ip rule add from 192.168.100.212/32 table ChinaTel pref 100
```

- 查看新增的路由规则

```
$ ip rule
0:	from all lookup local
32763:	from 192.168.120.212 lookup ChinaEdu
32764:	from 192.168.110.212 lookup ChinaCnc
32765:	from 192.168.100.212 lookup ChinaTel
32766:	from all lookup main
32767:	from all lookup default
```

如果需要修改某一条路由规则，可根据优先级删除指定路由规则后重新增加：

```
$ ip rule del prio 32767
```

至此访问三个网段中的任意一个地址都能够连通了。即便是服务器上本身的默认路由都没有设置，也能够让外面的用户正常访问。如果你要在默认路由表增加一个默认路由，可以使用如下命令：

```
$ ip route add default via 192.168.100.1 dev enp0s5
$ ip route show table main
default via 192.168.100.1 dev enp0s5
192.168.100.0/24 dev enp0s5  proto kernel  scope link  src 192.168.100.212
192.168.110.0/24 dev enp0s6  proto kernel  scope link  src 192.168.110.213
192.168.120.0/24 dev enp0s7  proto kernel  scope link  src 192.168.120.214
```
> main 表是系统主要的路由表，所有的默认路由规则都写在这个表中。

#### 命令汇总

```
# 清空路由表ChinaTel
$ ip route flush table ChinaTel
# 为路由表 ChinaTel 添加默认路由 192.168.100.1
$ ip route add default via 192.168.100.1 dev enp0s5 table ChinaTel
# 根据源 IP 决定路由表
$ ip rule add from 192.168.100.212 table ChinaTel

# 清空路由表ChinaCnc
$ ip route flush table ChinaCnc
# 为路由表 ChinaCnc 添加默认路由 192.168.110.1
$ ip route add default via 192.168.110.1 dev enp0s6 table ChinaCnc
# 根据源 IP 决定路由表
$ ip rule add from 192.168.110.212 table ChinaCnc

# 清空路由表ChinaEdu
$ ip route flush table ChinaEdu
# 为路由表 ChinaEdu 添加默认路由 192.168.120.1
$ ip route add default via 192.168.120.1 dev enp0s7 table ChinaEdu
# 根据源 IP 决定路由表
$ ip rule add from 192.168.120.212 table ChinaEdu
```

#### 测试

- 验证从 192.168.100.212 的包的路由选择

```
$ ip route get 8.8.8.8 from 192.168.100.212

# 结果为
8.8.8.8 from 192.168.100.212 via 192.168.100.1 dev enp0s5
    cache
```

- 验证从 192.168.110.213 的包的路由选择

```
$ ip route get 8.8.8.8 from 192.168.110.213

# 结果为

8.8.8.8 from 192.168.110.213 via 192.168.110.1 dev enp0s6
    cache
```

- 验证从 192.168.120.214 的包的路由选择

```
$ ip route get 8.8.8.8 from 192.168.120.214

# 结果为

8.8.8.8 from 192.168.120.214 via 192.168.120.1 dev enp0s7
    cache
```

- 外部测试

```
$ ping  192.168.100.212
$ ping  192.168.110.213
$ ping  192.168.120.214
```

以上几个 IP 均能 Ping 通。

#### 保存路由设置

以上的路由设置会在系统或网络重启后被清理。因此需要将它保存下来，以防止系统或网络重启后失效。

**方法一（推荐）**

`ip route save` 可保存表的信息，如果表的项非常多，这个操作起来非常简单；`ip rule` 没有专门的保存命令，这里通过脚本实现。

先保存指定路由表的信息，这里以 ChinaTel 为例：

```
$ ip route save table ChinaTel > /root/route-ChinaTel.rules
```

恢复时可使用 

```
$ ip route flush table ChinaTel && ip route restore table ChinaTel < /root/route-ChinaTel.rules
```

对规则的保存可使用以下的小脚本

```
$ vim ip-rule-dump.sh

#!/bin/sh
# ip-rule-dump.sh
# 参数： table 编号或别名，无参数时 dump 除 local 之外的全部规则

# 获取 table 别名
if [ -n "$1" ]; then
    name=$(grep -v '^[[:blank:]]*#' /etc/iproute2/rt_tables |\
        grep "[[:blank:]]*$1[[:blank:]]" | head -n 1 | awk '{print $2}')
    [ -z "$name" ] && name="$1"
fi
[ -z "$name" ] && name=".*"

# 获取并使用别名过滤规则
ip rule show | grep -v  "^0:" | grep -oP "from.*[[:blank:]]$name[[:blank:]]$" |\
    sed -e 's/lookup/table/g'
```

给脚本赋予权限并保存指定的路由规则 

```
$ chmod +x ip-rule-dump.sh
$ ./ip-rule-dump.sh ChinaTel > /root/rule-ChinaTel.rules
```

对规则的恢复可使用以下的小脚本

```
$ vim ip-rule-restore.sh

#!/bin/sh
# ip-rule-restore.sh
# 参数： dump 文件路径

if [ -n "$1" ] && [ -f "$1" ]; then
    cat $1 | while read line; do
        sudo ip rule add $line
    done
fi
```

给脚本赋予权限并恢复指定的路由规则 

```
$ chmod +x ip-rule-restore.sh
$ ip rule del table ChinaTel >/dev/null 2>&1 || :
$ ./ip-rule-restore.sh /root/rule-ChinaTel.rules
```

开机加载

如果需要在网卡准备完成就加载，就需要在 /etc/network/interfaces 的对应网卡上，加上 post-up 的操作了，这里以加载电信路由信息为例：

```
$ iface enp0s5 inet static
...
post-up ( ip rule del table ChinaTel >/dev/null 2>&1 || : ) && \
        bash /root/ip-rule-restore.sh /root/rule-ChinaTel.rules && \
        ip route flush table ChinaTel && \
        ip route restore table ChinaTel < /root/route-ChinaTel.rules
```

**方法二**

直接把命令加入启动脚本中，以防止网络重启或系统重启后配置失效。

配置 networking 启动脚本文件 在结尾 `exit 0` 之前增加如下内容：

 - 如果是 ubuntu/debian，网络启动脚本是 /etc/init.d/networking 
 - 如果是 RedHat/centos，网络启动脚本是 /etc/rc.d/init.d/network

这里以 ubuntu 为例：

```
$ vi /etc/init.d/networking

ip route flush table ChinaTel
ip route add default via 192.168.100.1 dev enp0s5 table ChinaTel
ip rule add from 192.168.100.212 table ChinaTel
ip route flush table ChinaCnc
ip route add default via 192.168.110.1 dev enp0s6 table ChinaCnc
ip rule add from 192.168.110.212 table ChinaCnc
ip route flush table ChinaEdu
ip route add default via 192.168.120.1 dev enp0s7 table ChinaEdu
ip rule add from 192.168.120.212 table ChinaEdu
exit 0
```

退出并重启网络测试是否生效

```
$ /etc/init.d/networking restart
```

### 场景二 给指定网段分别设置网关

这种方法使用的是默认路由表，增加到指定网段的路由。

- 使用 route 指令

```
$ route add -net 192.168.100.0/24 gw 192.168.100.1 dev enp0s5
$ route add -net 192.168.110.0/24 gw 192.168.110.1 dev enp0s6
$ route add -net 192.168.120.0/24 gw 192.168.120.1 dev enp0s7
```

参数说明

> -net 设置到某个网段的路由
>
> -host 设置到某台主机的路由
>
> gw 出口网关 IP地址
>
> dev 出口网关 物理设备名

- 使用 ip 指令

```
# 推荐使用 replace 指令
$ ip route replace  192.168.100.0/24 via 192.168.100.1 dev enp0s5 onlink
$ ip route replace  192.168.110.0/24 via 192.168.110.1 dev enp0s6 onlink
$ ip route replace  192.168.120.0/24 via 192.168.120.1 dev enp0s7 onlink

# 直接使用 add 指令，会报 RTNETLINK answers: File exists 错。如果要使用 add 指令，可先删除原默认的路由规则后再增加。 
$ ip route del 192.168.100.0/24
$ ip route add 192.168.100.0/24 via 192.168.100.1 dev enp0s5 onlink
```

> 注意：一块网卡只能设置一个网关，多个网关会发生冲突而无法成功配置。

如需增加默认路由，可使用以下指令：

- 使用 route 指令

```
$ route add default gw 192.168.100.1 dev enp0s5
```

- 使用 ip 指令

```
$ ip route add  default via 192.168.100.1 dev enp0s5
```

如有多余的配置，可使用下面的命令进行删除路由。

- 使用 route 指令

```
$ route del -net 192.168.100.0/24 gw 192.168.100.1

或者

$ route del -net 192.168.100.0/24 dev enp0s5
```

- 使用 ip 指令

```
$ ip route del 192.168.100.0/24
```

###  参考文档

http://www.google.com
http://www.cnblogs.com/fengyc/p/6533112.html
https://github.com/ttop5/ttop5.github.io/issues/11
http://longwind.blog.51cto.com/419072/806302
http://blog.csdn.net/moreorless/article/details/5397427
http://memoryboxes.github.io/blog/2014/12/30/linuxshuang-wang-qia-shuang-lu-you-she-zhi/