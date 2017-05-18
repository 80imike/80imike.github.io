---
category: docker
title: flannel原理简析及安装
date: 2017-04-19 09:00:00
tags: [flannel, docker]
abbrlink:
updated:
toc_number: false
---

flannel是CoreOS提供用于解决Dokcer集群跨主机通讯的覆盖网络工具。它的主要思路是：预先留出一个网段，每个主机使用其中一部分，然后每个容器被分配不同的ip；让所有的容器认为大家在同一个直连的网络，底层通过`UDP/VxLAN`等进行报文的封装和转发。

flannel项目地址：https://github.com/coreos/flannel

### flannel架构介绍

flannel默认使用8285端口作为`UDP`封装报文的端口，VxLan使用8472端口。

<!-- more -->

![](https://www.hi-linux.com/img/linux/flannel-01.png)

那么一条网络报文是怎么从一个容器发送到另外一个容器的呢？

1. 容器直接使用目标容器的ip访问，默认通过容器内部的eth0发送出去。
1. 报文通过`veth pair`被发送到`vethXXX`。
1. `vethXXX`是直接连接到虚拟交换机`docker0`的，报文通过虚拟`bridge docker0`发送出去。
1. 查找路由表，外部容器ip的报文都会转发到`flannel0`虚拟网卡，这是一个`P2P`的虚拟网卡，然后报文就被转发到监听在另一端的`flanneld`。
1. `flanneld`通过`etcd`维护了各个节点之间的路由表，把原来的报文`UDP`封装一层，通过配置的`iface`发送出去。
1. 报文通过主机之间的网络找到目标主机。
1. 报文继续往上，到传输层，交给监听在8285端口的`flanneld`程序处理。
1. 数据被解包，然后发送给`flannel0`虚拟网卡。
1. 查找路由表，发现对应容器的报文要交给`docker0`。
1. `docker0`找到连到自己的容器，把报文发送过去。

### flannel安装配置

**环境准备**

一共三台机器：一个etcd集群，三台机器安装flannel和Docker。

|节点名称|IP地址|软件环境|
|---|---|---|
|etcd1|192.168.2.210|etcd、flannel、docker|
|etcd2|192.168.2.211|etcd、flannel、docker|
|etcd3|192.168.2.212|etcd、flannel、docker|

**安装etcd**

关于etcd的安装使用已经在「[etcd使用入门](https://www.hi-linux.com/posts/40915.html)」和「[通过静态发现方式部署etcd集群](https://www.hi-linux.com/posts/49138.html)」中做了比较详细的讲解，如果你还不会安装etcd可先阅读下这两篇文章。这里就不再重复讲解了。

**安装flannel**

三个节点都需安装配置flannel，这里以etcd1节点为例。

flannel和etcd一样，直接从官方下载二进制执行文件就可以用了。当然，你也可以自己编译。

```
$ curl -L https://github.com/coreos/flannel/releases/download/v0.7.0/flannel-v0.7.0-linux-amd64.tar.gz -o flannel.tar.gz
$ mkdir -p /opt/flannel
$ tar xzf flannel.tar.gz -C /opt/flannel
```
解压后主要有`flanneld`、`mk-docker-opts.sh`这两个文件，其中`flanneld`为主要的执行文件，sh脚本用于生成Docker启动参数。

**配置flannel**

由于`flannel`需要依赖`etcd`来保证集群IP分配不冲突的问题，所以首先要在`etcd`中设置 `flannel`节点所使用的IP段。

```
$ etcdctl --endpoints "http://etcd1.hi-linux.com:2379" \
set /coreos.com/network/config '{"NetWork":"10.0.0.0/16", "SubnetMin": "10.0.1.0", "SubnetMax": "10.0.20.0"}'

{"NetWork":"10.0.0.0/16", "SubnetMin": "10.0.1.0", "SubnetMax": "10.0.20.0"}
```

flannel预设的`backend type`是udp，如果想要使用`vxlan`作为`backend`，可以加上`backend`参数：

```
$ etcdctl --endpoints "http://etcd1.hi-linux.com:2379" \
set /coreos.com/network/config '{"NetWork":"10.0.0.0/16", "Backend": {"Type": "vxlan"}}'
```

> flannel backend为vxlan比起预设的udp性能相对好一些。

**启动flannel**

- 命令行方式运行

```
$ /opt/flannel/flanneld --etcd-endpoints="http://etcd1.hi-linux.com:2379" --ip-masq=true >> /var/log/flanneld.log 2>&1 &
```

- 后台服务方式运行

给flannel创建一个systemd服务，方便以后管理。创建flannel配置文件:

```
$ cat <<EOF | sudo tee /etc/systemd/system/flanneld.service
[Unit]
Description=Flanneld
Documentation=https://github.com/coreos/flannel
After=network.target
Before=docker.service

[Service]
User=root
ExecStart=/opt/flannel/flanneld \
--etcd-endpoints="http://etcd1.hi-linux.com:2379,http://etcd2.hi-linux.com:2379,http://etcd3.hi-linux.com:2379" \
--iface=192.168.2.210 \
--ip-masq
Restart=on-failure
Type=notify
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
```

> 注意：`--iface`参数为要绑定的网卡的IP地址，请根据实际情况修改。

**启动flannel服务**

```
$ systemctl start flanneld
```

flannel启动过程解析

flannel服务需要先于Docker启动。flannel服务启动时主要做了以下几步的工作：

- 从etcd中获取network的配置信息。
- 划分subnet，并在etcd中进行注册。
- 将子网信息记录到`/run/flannel/subnet.env`中。

**验证flannel网络**

在etcd1节点上看etcd中的内容

```
$ etcdctl  --endpoints "http://etcd1.hi-linux.com:2379" ls /coreos.com/network/subnets

/coreos.com/network/subnets/10.0.2.0-24
```

查看flannel0的网络情况：

```
$ ifconfig flannel0
flannel0  Link encap:UNSPEC  HWaddr 00-00-00-00-00-00-00-00-00-00-00-00-00-00-00-00
          inet addr:10.0.2.0  P-t-P:10.0.2.0  Mask:255.255.0.0
          UP POINTOPOINT RUNNING NOARP MULTICAST  MTU:1472  Metric:1
          RX packets:85 errors:0 dropped:0 overruns:0 frame:0
          TX packets:75 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:500
          RX bytes:7140 (7.1 KB)  TX bytes:6300 (6.3 KB)
```

可以看到flannel0网卡的地址和etcd中存储的地址一样，这样flannel网络配置完成。

**配置Docker**

在各个节点安装好以后最后要更改`Docker`的启动参数，使其能够使用`flannel`进行IP分配，以及网络通讯。

`flannel`运行后会生成一个环境变量文件，包含了当前主机要使用`flannel`通讯的相关参数。

- 查看flannel分配的网络参数

```
$ cat /run/flannel/subnet.env

FLANNEL_NETWORK=10.0.0.0/16
FLANNEL_SUBNET=10.0.2.1/24
FLANNEL_MTU=1472
FLANNEL_IPMASQ=true
```

- 创建Docker运行参数

使用flannel提供的脚本将subnet.env转写成Docker启动参数，创建好的启动参数位于`/run/docker_opts.env`文件中。

```
$ /opt/flannel/mk-docker-opts.sh -d /run/docker_opts.env -c

$ cat /run/docker_opts.env
DOCKER_OPTS=" --bip=10.0.2.1/24 --ip-masq=false --mtu=1472"
```

- 修改Docker启动参数

修改docker的启动参数，并使其启动后使用由flannel生成的配置参数，修改如下:

```
# 编辑 systemd service 配置文件
$ vim /lib/systemd/system/docker.service
# 在启动时增加flannel提供的启动参数
ExecStart=/usr/bin/dockerd $DOCKER_OPTS
# 指定这些启动参数所在的文件位置(这个配置是新增的，同样放在Service标签下)
EnvironmentFile=/run/docker_opts.env
```

然后重新加载systemd配置，并重启`Docker`即可

```
$ systemctl daemon-reload
$ systemctl restart docker
```

此时可以看到`docker0`的网卡ip地址已经处于`flannel`网卡网段之内。

```
$ ifconfig flannel0
flannel0  Link encap:UNSPEC  HWaddr 00-00-00-00-00-00-00-00-00-00-00-00-00-00-00-00
          inet addr:10.0.2.0  P-t-P:10.0.2.0  Mask:255.255.0.0
          UP POINTOPOINT RUNNING NOARP MULTICAST  MTU:1472  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:500
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)

$ ifconfig docker0
docker0   Link encap:Ethernet  HWaddr 02:42:cf:87:3c:f7
          inet addr:10.0.2.1  Bcast:0.0.0.0  Mask:255.255.255.0
          UP BROADCAST MULTICAST  MTU:1500  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)
```

到此节点etcd1的flannel安装配置完成了，其它两节点按以上方法配置完成就行了。


### 测试flannel

三台机器都配置好了之后，我们在三台机器上分别开启一个docker容器，测试它们的网络是否可相互联通的。

**etcd1**

```
$ docker run -it  busybox sh

# 查看容器IP
$ cat /etc/hosts
10.0.2.2	9de86bfde6cc
```

**etcd2**

```
$ docker run -it  busybox sh

# 查看容器IP
$ cat /etc/hosts
10.0.5.2	9ddd4a4e455b
```

**etcd3**

```
$ docker run -it  busybox sh

# 查看容器IP
$ cat /etc/hosts
10.0.6.2	cbb0d891f353
```

- 从不同宿主机容器到三台宿主机

```
/ # ping -c3 192.168.2.210
PING 192.168.2.210 (192.168.2.210): 56 data bytes
64 bytes from 192.168.2.210: seq=0 ttl=64 time=0.089 ms
64 bytes from 192.168.2.210: seq=1 ttl=64 time=0.065 ms

/ # ping -c5 192.168.2.211
PING 192.168.2.211 (192.168.2.211): 56 data bytes
64 bytes from 192.168.2.211: seq=0 ttl=63 time=1.712 ms
64 bytes from 192.168.2.211: seq=1 ttl=63 time=0.356 ms
64 bytes from 192.168.2.211: seq=2 ttl=63 time=2.201 ms

/ # ping -c3 192.168.2.212
PING 192.168.2.212 (192.168.2.212): 56 data bytes
64 bytes from 192.168.2.212: seq=0 ttl=63 time=0.467 ms
64 bytes from 192.168.2.212: seq=1 ttl=63 time=0.477 ms
64 bytes from 192.168.2.212: seq=2 ttl=63 time=0.532 ms
```

- 从容器到到跨宿主机容器

```
/ # ping -c3  10.0.5.2
PING 10.0.5.2 (10.0.5.2): 56 data bytes
64 bytes from 10.0.5.2: seq=0 ttl=60 time=0.692 ms
64 bytes from 10.0.5.2: seq=1 ttl=60 time=0.565 ms
64 bytes from 10.0.5.2: seq=2 ttl=60 time=1.135 ms

/ # ping -c3  10.0.6.2
PING 10.0.6.2 (10.0.6.2): 56 data bytes
64 bytes from 10.0.6.2: seq=0 ttl=60 time=0.678 ms
64 bytes from 10.0.6.2: seq=1 ttl=60 time=0.907 ms
64 bytes from 10.0.6.2: seq=2 ttl=60 time=1.272 ms

/ # ping -c3 10.0.2.2
PING 10.0.2.2 (10.0.2.2): 56 data bytes
64 bytes from 10.0.2.2: seq=0 ttl=60 time=0.644 ms
64 bytes from 10.0.2.2: seq=1 ttl=60 time=0.915 ms
64 bytes from 10.0.2.2: seq=2 ttl=60 time=1.032 ms
```

测试容器到到跨宿主机容器遇到一个坑，开始怎么都不通，后找到原因是宿主机`iptables`给阻挡掉了。附：Ubuntu一键清除iptables规则脚本

```
$ cat clear_iptables_rule.sh

#!/bin/bash

iptables -F
iptables -X
iptables -Z
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT
```

### 参考文档


http://www.google.com
http://t.cn/RcnGQ02
http://t.cn/RXVHGpI
http://t.cn/RXfavPG
http://t.cn/RXfEThA
http://t.cn/RXfEmS8
http://t.cn/R5Xgfnx
