---
category: docker
title: 通过MacVLAN实现Docker跨宿主机互联
date: 2017-04-26 09:00:00
tags: [Kubernetes, docker]
abbrlink:
updated:
toc_number: false
---

Docker以前的版本不支持直接配置宿主机所在网段ip并跟其直接互通的功能，当然也可以借助一些第三方工具，如pipework把这些琐碎的过程封装起来。Docker从1.12开始支持了overlay和macvlan网络，macvlan已经可以直接支持了使用宿主机所在网段资源。

**Docker工作原理**

- Macvlan是Linux内核支持的网络接口。要求的Linux内部版本是v3.9–3.19和4.0+。
- 通过为物理网卡创建Macvlan子接口，允许一块物理网卡拥有多个独立的MAC地址和IP地址。虚拟出来的子接口将直接暴露在底层物理网络中。从外界看来，就像是把网线分成多股，分别接到了不同的主机上一样。
- Macvlan有四种工作模式：Private、VEPA、Bridge和Passthru。最常用和默认的模式是Bridge模式。
- 物理网卡收到包后，会根据收到包的目的MAC地址判断这个包需要交给哪个虚拟网卡。

<!-- more -->

![](https://www.hi-linux.com/img/linux/macvlan-workmode-1.png)

- 如果配合Network Namespace 使用，可以构建这样的网络：

![](https://www.hi-linux.com/img/linux/macvlan-workmode-namespace.png)

MacVLAN可以工作在四种模式下：

- VEPA(Virtual Ethernet Port Aggregator)mode：default模式
- Brideg mode
- Private mode
- Passthru mode

VEPA需要接入交换机支持`hairpin mode`。相对而言`Bridge mode`更加常用。

macvlan和overlay网络不同，overlay是global scope类型的网络，而macvlan是local scope。scope指的是网络作用的范围。global类型的网络其作用于一组docker daemon集群，local类型的网络只作用于单一主机。

每台主机创建的macvlan网络是独立的，A机器上创建的macvlan网络并不影响B机器上的网络，但两台主机在网卡配置混杂模式、两台主机上macvlan存在overlap、两个macvlan网络没有分配过同样IP，这三个条件满足时，同样可以实现跨主机通信。

### 环境准备

一共两台机器：两台机器都安装Docker且内核版本>3.9。

|主机名|IP地址|软件环境|
|---|---|---|
|dev-master-01|192.168.2.210|kernel>3.9,Docker|
|dev-node-01|192.168.2.211|kernel>3.9,Docker|

**启用网卡混杂模式**

两台机器设置使用桥接模式,网卡混杂模式开启全部允许。

主机上配置的enp0s5网口或者创建的vlan网口,均需要开启混杂模式。如果不开启混杂模式会导致macvlan网络无法访问外界,具体在不使用vlan时,表现为无法ping通路由,无法ping通同一网络内其他主机。

设置混杂模式可以通过ip或ifconfig指令实现。

- 通过ip指令

设置enp0s5为混杂模式

```
$ ip link set enp0s5  promisc on
```

取消enp0s5的混杂模式

```
$ ip link set enp0s5  promisc off
```

- 通过ifconfig指令

设置enp0s5为混杂模式

```
$ ifconfig enp0s5 promisc
```

取消enp0s5的混杂模式

```
$ ifconfig enp0s5 -promisc
```

验证网卡混杂模式是否设置成功

```
$ ifconfig enp0s5
enp0s5    Link encap:Ethernet  HWaddr 00:1c:42:97:53:2a
          inet addr:192.168.2.210  Bcast:192.168.2.255  Mask:255.255.255.0
          inet6 addr: fe80::21c:42ff:fe97:532a/64 Scope:Link
          UP BROADCAST RUNNING PROMISC MULTICAST  MTU:1500  Metric:1
          RX packets:1059321 errors:0 dropped:145 overruns:0 frame:0
          TX packets:15030 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:785317867 (785.3 MB)  TX bytes:1039141 (1.0 MB)
```


其中`UP BROADCAST RUNNING PROMISC MULTICAST的PROMISC`说明网卡enp0s5已经设置成混杂模式。


### 使用Macvlan构建Docker网络

**创建docker macvlan网络**

两台主机上均使用enp0s5网卡创建一个192.168.2.0网段的macvlan网络。

macvlan驱动实际上是利用的Linux macvlan内核驱动，这意味着这样子运行的容器，网络通讯将会直接送到下层vlan。这是目前最高网络效率的驱动。这里没有NAT，没有端口映射，通讯直接通过VLan送出。

- master主机

**创建macvlan网络**

```
$ docker network create -d macvlan --subnet 192.168.2.0/24 --gateway 192.168.2.1 -o parent=enp0s5 -o macvlan_mode=bridge macnet
0ab39da89dd66238a1e9c75edbb70afa9b09d13dc5f1a041f5dd46c369856225
```

>macvlan是kernel的模块名。
>192.168.2.0/24是宿主机所在网络的网段。
>192.168.2.1是网关。
>enp0s5是宿主机接入192.168.2.0/24的网络设备。


**查看macvlan是否创建成功**

```
$ docker network ls
NETWORK ID          NAME                DRIVER              SCOPE
e13c13e22f73        bridge              bridge              local
a56cfbac20ed        docker_gwbridge     bridge              local
0b703c3d9cb8        host                host                local
abdb4b9f751c        none                null                local
0ab39da89dd6        macnet              macvlan             local
856b6dbf7e83        weave               weavemesh           local
```

**创建两个使用macvlan容器**

创建容器c1

```
$ docker run -id --net macnet --ip 192.168.2.220 --name c1 busybox sh
6120c05c90ae75658f6703a269da453a4c516686144cc53dad027af7410cc93c

# 查看容器IP
$ docker exec c1 ip a

1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue qlen 1
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
30: eth0@if2: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue
    link/ether 02:42:c0:a8:02:dc brd ff:ff:ff:ff:ff:ff
    inet 192.168.2.220/24 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::42:c0ff:fea8:2dc/64 scope link
       valid_lft forever preferred_lft forever

# 查看容器route
$ docker exec c1  route -n

Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         192.168.2.1     0.0.0.0         UG    0      0        0 eth0
192.168.2.0     0.0.0.0         255.255.255.0   U     0      0        0 eth0
```

创建容器c2

```
$ docker run -id --net macnet --ip 192.168.2.221 --name c2 busybox sh
f8bcf7a103ac483fd46ee27ac675b23255bf64ad49c7e70be8785737add1ce06

# 查看容器IP
$ docker exec c2 ip a

1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue qlen 1
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
31: eth0@if2: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue
    link/ether 02:42:c0:a8:02:dd brd ff:ff:ff:ff:ff:ff
    inet 192.168.2.221/24 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::42:c0ff:fea8:2dd/64 scope link
       valid_lft forever preferred_lft forever


# 查看容器route
$ docker exec c2  route -n

Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         192.168.2.1     0.0.0.0         UG    0      0        0 eth0
192.168.2.0     0.0.0.0         255.255.255.0   U     0      0        0 eth0
```

- node主机

**创建macvlan网络**

```
$ docker network create -d macvlan --subnet 192.168.2.0/24 --gateway 192.168.2.1 -o parent=enp0s5 -o macvlan_mode=bridge macnet
ad869482ddc115acf6ee004a500ce7c28386e976c4bb5eccdffaaa1afbcd07e1
```

> macvlan是kernel的模块名。
> 192.168.2.0/24是宿主机所在网络的网段。
> 192.168.2.1是网关。
> enp0s5是宿主机接入192.168.2.0/24的网络设备。

**查看macvlan是否创建成功**

```
$ docker network ls
NETWORK ID          NAME                DRIVER              SCOPE
e13c13e22f73        bridge              bridge              local
a56cfbac20ed        docker_gwbridge     bridge              local
0b703c3d9cb8        host                host                local
2b2067e669d4        macnet              macvlan             local
abdb4b9f751c        none                null                local
856b6dbf7e83        weave               weavemesh           local
```

**创建两个使用macvlan容器**

创建容器c3

```
$ docker run -id --net macnet --ip 192.168.2.222 --name c3 busybox sh
8b6a83f73af9dd54ef24be80bf946f0e10959e48ead12a09514d3c59a287927c


# 查看容器IP
$ docker exec c3 ip a

1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue qlen 1
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
18: eth0@if2: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue
    link/ether 02:42:c0:a8:02:ca brd ff:ff:ff:ff:ff:ff
    inet 192.168.2.222/24 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::42:c0ff:fea8:2ca/64 scope link
       valid_lft forever preferred_lft forever

# 查看容器route
$ docker exec c3  route -n

Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         192.168.2.1     0.0.0.0         UG    0      0        0 eth0
192.168.2.0     0.0.0.0         255.255.255.0   U     0      0        0 eth0
```

创建容器c4

```
$ docker run -id --net macnet --ip 192.168.2.223 --name c4 busybox sh
c7be679190467564023aec1fd908bb7418a55f41ab548d59d77cabf187dc665c


# 查看容器IP
$ docker exec c4 ip a

1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue qlen 1
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
20: eth0@if2: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue
    link/ether 02:42:c0:a8:02:df brd ff:ff:ff:ff:ff:ff
    inet 192.168.2.223/24 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::42:c0ff:fea8:2df/64 scope link
       valid_lft forever preferred_lft forever

# 查看容器route
$ docker exec c4  route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         192.168.2.1     0.0.0.0         UG    0      0        0 eth0
192.168.2.0     0.0.0.0         255.255.255.0   U     0      0        0 eth0
```

**测试网络连通情况**

所有测试在master主机上进行。

- ping网关

```
$ docker exec c1 ping -c 3 192.168.2.1
PING 192.168.2.1 (192.168.2.1): 56 data bytes
64 bytes from 192.168.2.1: seq=0 ttl=255 time=1.594 ms
64 bytes from 192.168.2.1: seq=1 ttl=255 time=0.659 ms
64 bytes from 192.168.2.1: seq=2 ttl=255 time=0.753 ms

--- 192.168.2.1 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.659/1.002/1.594 ms
```

测试结果:通

- 使用容器名ping本主机容器

```
$ docker exec c1 ping -c3 c1
PING c1 (192.168.2.220): 56 data bytes
64 bytes from 192.168.2.220: seq=0 ttl=64 time=0.053 ms
64 bytes from 192.168.2.220: seq=1 ttl=64 time=0.073 ms
64 bytes from 192.168.2.220: seq=2 ttl=64 time=0.048 ms

--- c1 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.048/0.058/0.073 ms
```

测试结果:通

- ping本主机容器

```
$ docker exec c1 ping -c3 192.168.2.220
PING 192.168.2.220 (192.168.2.220): 56 data bytes
64 bytes from 192.168.2.220: seq=0 ttl=64 time=0.069 ms
64 bytes from 192.168.2.220: seq=1 ttl=64 time=0.172 ms
64 bytes from 192.168.2.220: seq=2 ttl=64 time=0.079 ms

--- 192.168.2.220 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.069/0.106/0.172 ms
```

测试结果:通

- ping另一主机容器

```
$ docker exec c1 ping -c2  192.168.2.222
PING 192.168.2.222 (192.168.2.222): 56 data bytes
64 bytes from 192.168.2.222: seq=0 ttl=255 time=0.788 ms
64 bytes from 192.168.2.222: seq=1 ttl=255 time=0.383 ms

--- 192.168.2.222 ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
round-trip min/avg/max = 0.383/0.585/0.788 ms
```

测试结果:通

- 使用容器名ping另一主机容器:

```
$ docker exec c1 ping -c2 c3
ping: bad address 'c3'
```

测试结果:不通

- 本主机ping本主机容器: 不通

```
$ ping -c 2 192.168.2.220
PING 192.168.2.220 (192.168.2.220) 56(84) bytes of data.
From 192.168.2.210 icmp_seq=1 Destination Host Unreachable
From 192.168.2.210 icmp_seq=2 Destination Host Unreachable

--- 192.168.2.220 ping statistics ---
2 packets transmitted, 0 received, +2 errors, 100% packet loss, time 1000ms
```

测试结果:不通

- 本主机ping另一主机容器

```
$ ping -c 2 192.168.2.222
PING 192.168.2.222 (192.168.2.222) 56(84) bytes of data.
64 bytes from 192.168.2.222: icmp_seq=1 ttl=255 time=0.308 ms
64 bytes from 192.168.2.222: icmp_seq=2 ttl=255 time=0.343 ms

--- 192.168.2.222 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1000ms
rtt min/avg/max/mdev = 0.308/0.325/0.343/0.025 ms
```

测试结果:通

- 本主机上容器到另一台宿主IP

```
$ docker exec c2 ping -c 2 192.168.2.211
PING 192.168.2.211 (192.168.2.211): 56 data bytes
64 bytes from 192.168.2.211: seq=0 ttl=64 time=0.494 ms
64 bytes from 192.168.2.211: seq=1 ttl=64 time=0.495 ms

--- 192.168.2.211 ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
round-trip min/avg/max = 0.494/0.494/0.495 ms
```

### 使用Macvlan+VLAN构建Docker网络

**VLAN简介**

VLAN(Virtual Local Area Network)又称虚拟局域网，是指在局域网的基础上，采用网络管理软件构建的可跨越不同网段、不同网络的端到端的逻辑网络。

一个VLAN组成一个逻辑子网，即一个逻辑广播域，它可以覆盖多个网络设备，允许处于不同地理位置的网络用户加入到一个逻辑子网中。使用VLAN功能后，能够将网络分割成多个广播域。

Linux支持在物理网卡上创建vlan子接口。每个vlan子接口属于不同的二层域，所有的vlan子接口拥有相同的MAC地址。这点是和Macvlan子接口不同的地方。

- master主机

**创建VLAN**

```
# 为物理网卡enp0s5创建Macvlan子接口
$ ip link add link enp0s5 name enp0s5.200 type vlan id 200

# 将MACVLAN设备加入到容器的network space
$ ip link list enp0s5.200
33: ip enp0s5.200@enp0s5: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/ether 00:1c:42:97:53:2a brd ff:ff:ff:ff:ff:ff

# 启用enp0s5.200
$ ip link set enp0s5.200 up

$ ip link list enp0s5.200
33: enp0s5.200@enp0s5: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP mode DEFAULT group default qlen 1000
    link/ether 00:1c:42:97:53:2a brd ff:ff:ff:ff:ff:ff

# 设置enp0s5.200为混杂模式
$ ip link set enp0s5.200  promisc on
$ ifconfig enp0s5.200
enp0s5.200 Link encap:Ethernet  HWaddr 00:1c:42:97:53:2a
          inet6 addr: fe80::21c:42ff:fe97:532a/64 Scope:Link
          UP BROADCAST RUNNING PROMISC MULTICAST  MTU:1500  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:8 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:0 (0.0 B)  TX bytes:648 (648.0 B)
```

**设置macvlan的ip和网关**

```
$ ip addr add 192.168.200.10/24 dev enp0s5.200
# 删除原默认路由，否则下面加默认路由时会报错。
$ ip route del default
$ ip route add default via 192.168.200.1 dev enp0s5.200
```

**创建Docker macvlan网络**

```
$ docker network create -d macvlan --subnet=192.168.200.0/24 --gateway=192.168.200.1 -o parent=enp0s5.200 -o macvlan_mode=bridge macvlan200
b2fb555bbcdc1f0b724cc9e76b154630e632184566b9e8bb314cde825ad9ff9d


# 查看macvlan是否创建成功

$ docker network ls
NETWORK ID          NAME                DRIVER              SCOPE
6dc2160d4026        bridge              bridge              local
a56cfbac20ed        docker_gwbridge     bridge              local
0b703c3d9cb8        host                host                local
9282605b5107        macnet              macvlan             local
d129db56fcc1        macvlan200          macvlan             local
abdb4b9f751c        none                null                local
856b6dbf7e83        weave               weavemesh           local
```

**创建两个使用macvlan容器**

创建容器c5

```
$ docker run --net=macvlan200 --ip=192.168.200.100 -id --name c5 busybox sh
28ee719d4784696eff10805f1f9d992b245b7b886b031c1781dbaf4037bbb231
```

创建容器c6

```
$ docker run --net=macvlan200 --ip=192.168.200.101 -id --name c6 busybox sh
7bd2a36e24846b383ab3aca6b9b48227600aed7352956c2c974db1ceb97efb54
```

- node主机

**创建Vlan**

```
# 为物理网卡enp0s5创建Macvlan子接口
$ ip link add link enp0s5 name enp0s5.200 type vlan id 200

# 将MACVLAN设备加入到容器的network space
$ ip link list enp0s5.200
24: enp0s5.200@enp0s5: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/ether 00:1c:42:67:23:07 brd ff:ff:ff:ff:ff:ff

# 启用enp0s5.200
$ ip link set enp0s5.200 up

$ ip link list enp0s5.200
24: enp0s5.200@enp0s5: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP mode DEFAULT group default qlen 1000
    link/ether 00:1c:42:67:23:07 brd ff:ff:ff:ff:ff:ff

# 设置enp0s5.200为混杂模式
$ ip link set enp0s5.200  promisc on
$ ifconfig enp0s5.200
enp0s5.200 Link encap:Ethernet  HWaddr 00:1c:42:67:23:07
          inet6 addr: fe80::21c:42ff:fe67:2307/64 Scope:Link
          UP BROADCAST RUNNING PROMISC MULTICAST  MTU:1500  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:8 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:0 (0.0 B)  TX bytes:648 (648.0 B)
```

**设置macvlan的ip和网关**

```
$ ip addr add 192.168.200.11/24 dev enp0s5.200
# 删除原默认路由，否则下面加默认路由时会报错。
$ ip route del default
$ ip route add default via 192.168.200.1 dev enp0s5.200
```

**创建Docker macvlan网络**

```
$ docker network create -d macvlan --subnet=192.168.200.0/24 --gateway=192.168.200.1 -o parent=enp0s5.200 -o macvlan_mode=bridge macvlan200
b2fb555bbcdc1f0b724cc9e76b154630e632184566b9e8bb314cde825ad9ff9d


# 查看macvlan是否创建成功
$ docker network ls
NETWORK ID          NAME                DRIVER              SCOPE
4886f72179a8        bridge              bridge              local
0b703c3d9cb8        host                host                local
149f5dcc20b3        macnet              macvlan             local
8ee3174430ab        macvlan200          macvlan             local
abdb4b9f751c        none                null                local
bce1daa0a925        weave               weavemesh           local
```

**创建两个使用macvlan容器**

创建容器c7

```
$ docker run --net=macvlan200 --ip=192.168.200.102 -id --name c7 busybox sh
28ee719d4784696eff10805f1f9d992b245b7b886b031c1781dbaf4037bbb231
```

创建容器c8

```
$ docker run --net=macvlan200 --ip=192.168.200.103 -id --name c8 busybox sh
7bd2a36e24846b383ab3aca6b9b48227600aed7352956c2c974db1ceb97efb54
```

### 测试网络连通情况

所有测试在master主机上进行。

- ping网关

```
$ docker exec c5 ping -c2 192.168.200.1

```

测试结果:不通


- ping本地macvlannet地址


```
$ docker exec c5 ping -c2 192.168.200.10
PING 192.168.200.10 (192.168.200.10): 56 data bytes

--- 192.168.200.10 ping statistics ---
2 packets transmitted, 0 packets received, 100% packet loss
```

测试结果:不通


- ping另一个主机的macvlannet地址

```
$ docker exec c5 ping -c2 192.168.200.11

PING 192.168.200.11 (192.168.200.11): 56 data bytes
64 bytes from 192.168.200.11: seq=0 ttl=64 time=0.535 ms
64 bytes from 192.168.200.11: seq=1 ttl=64 time=0.368 ms

--- 192.168.200.11 ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
round-trip min/avg/max = 0.368/0.451/0.535 ms
```

测试结果:通

- ping本主机容器

```
$ docker exec c5 ping -c2 192.168.200.100

PING 192.168.200.100 (192.168.200.100): 56 data bytes
64 bytes from 192.168.200.100: seq=0 ttl=64 time=0.091 ms
64 bytes from 192.168.200.100: seq=1 ttl=64 time=0.046 ms

--- 192.168.200.100 ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
round-trip min/avg/max = 0.046/0.068/0.091 ms
```

测试结果:通

- ping另一主机容器

```
$ docker exec c5 ping -c2 192.168.200.102
PING 192.168.200.102 (192.168.200.102): 56 data bytes
64 bytes from 192.168.200.102: seq=0 ttl=64 time=0.815 ms
64 bytes from 192.168.200.102: seq=1 ttl=64 time=1.051 ms

--- 192.168.200.102 ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
round-trip min/avg/max = 0.815/0.933/1.051 ms
```

测试结果:通


- 使用容器名ping本主机容器

```
$ docker exec c5 ping -c2 c6
PING c6 (192.168.200.101): 56 data bytes
64 bytes from 192.168.200.101: seq=0 ttl=64 time=0.152 ms
64 bytes from 192.168.200.101: seq=1 ttl=64 time=0.108 ms

--- c6 ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
round-trip min/avg/max = 0.108/0.130/0.152 ms
```

测试结果:通


- 使用容器名ping另一主机容器

```
$ docker exec c5 ping -c2 c7
ping: bad address 'c7'
```

测试结果:不通

- ping跨网络主机

```
$ docker exec c5 ping -c2 192.168.200.102
PING 192.168.200.102 (192.168.200.102): 56 data bytes
64 bytes from 192.168.200.102: seq=0 ttl=64 time=0.518 ms
64 bytes from 192.168.200.102: seq=1 ttl=64 time=0.458 ms

--- 192.168.200.102 ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
round-trip min/avg/max = 0.458/0.488/0.518 ms
```

测试结果:通

- 本主机ping本主机容器

```
$ ping 192.168.200.100 -c2
PING 192.168.200.100 (192.168.200.100) 56(84) bytes of data.
From 192.168.200.10 icmp_seq=1 Destination Host Unreachable
From 192.168.200.10 icmp_seq=2 Destination Host Unreachable

--- 192.168.200.100 ping statistics ---
2 packets transmitted, 0 received, +2 errors, 100% packet loss, time 1006ms
pipe 2
```

测试结果:不通

- 本主机ping另一主机容器

```
$ ping 192.168.200.102 -c2
PING 192.168.200.102 (192.168.200.102) 56(84) bytes of data.
64 bytes from 192.168.200.102: icmp_seq=1 ttl=64 time=0.625 ms
64 bytes from 192.168.200.102: icmp_seq=2 ttl=64 time=0.319 ms

--- 192.168.200.102 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 0.319/0.472/0.625/0.153 ms
```

测试结果:通

### 一些问题

- macvlan网络在创建时要指定parent.其中parent仅能使用一次,即eth0在创建一个macvlan网络时使用了,则在创建另一个的时候就无法再使用了。

- 两种模式下都有测试网络不通的情况，不知道是不是虚拟机网络环境问题。理论上应该是通的。待在真实环境验证后才得知。

### 参考文档

http://www.google.com
http://t.cn/RXYNXqK
http://t.cn/RXQU43D
http://hustcat.github.io/docker-macvlan/
