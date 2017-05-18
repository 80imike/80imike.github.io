---
category: docker
title: 使用Weave实现Docker多宿主机互联
date: 2017-04-24 09:00:00
tags: [Kubernetes, docker]
abbrlink:
updated:
toc_number: false
---

Weave是由weaveworks公司开发的解决Docker跨主机网络的解决方案，它能够创建一个虚拟网络，用于连接部署在多台主机上的Docker容器，这样容器就像被接入了同一个网络交换机，那些使用网络的应用程序不必去配置端口映射和链接等信息。

外部设备能够访问Weave网络上的应用程序容器所提供的服务，同时已有的内部系统也能够暴露到应用程序容器上。Weave能够穿透防火墙并运行在部分连接的网络上，另外，Weave的通信支持加密，所以用户可以从一个不受信任的网络连接到主机。

项目地址：https://github.com/weaveworks/weave

<!-- more -->

### Weave实现原理

![](https://www.hi-linux.com/img/linux/weave1.png)

容器的网络通讯都通过route服务和网桥转发。

![](https://www.hi-linux.com/img/linux/weave2.png)

Weave会在主机上创建一个网桥,每一个容器通过`veth pair`连接到该网桥上，同时网桥上有个`Weave router`的容器与之连接，该router会通过连接在网桥上的接口来抓取网络包(该接口工作在Promiscuous模式)。

在每一个部署Docker的主机(可能是物理机也可能是虚拟机)上都部署有一个W(即Weave router)，它本身也可以以一个容器的形式部署。Weave run的时候就可以给每个veth的容器端分配一个ip和相应的掩码。veth的网桥这端就是Weave router容器，并在Weave launch的时候分配好ip和掩码。

Weave网络是由这些weave routers组成的对等端点(peer)构成，每个对等的一端都有自己的名字，其中包括一个可读性好的名字用于表示状态和日志的输出，一个唯一标识符用于运行中相互区别，即使重启Docker主机名字也保持不变，这些名字默认是mac地址。

每个部署了Weave router的主机都需要将TCP和UDP的6783端口的防火墙设置打开，保证Weave router之间控制面流量和数据面流量的通过。控制面由weave routers之间建立的TCP连接构成，通过它进行握手和拓扑关系信息的交换通信。 这个通信可以被配置为加密通信。而数据面由Weave routers之间建立的UDP连接构成，这些连接大部分都会加密。这些连接都是全双工的，并且可以穿越防火墙。

**Weave优劣势**

- Weave优势

1. 支持主机间通信加密。
1. 支持container动态加入或者剥离网络。
1. 支持跨主机多子网通信。

- Weave劣势

1. 只能通过weave launch或者weave connect加入weave网络。

更多Docker跨主机方案可以参考「[Docker跨主机通信解决方案探讨](https://www.hi-linux.com/posts/58668.html)」 一文。

### Weave安装配置

**环境准备**

一共两台机器：两台机器都安装Weave和Docker。

|主机名|IP地址|软件环境|
|---|---|---|
|dev-master-01|192.168.2.210|Weave、Docker|
|dev-node-01|192.168.2.211|Weave、Docker|

**安装Weave**

> 主从节点都需要安装。

Weave不需要集中式的`key-value`存储，所以安装和运行都很简单。直接把Weave二进制文件下载到系统中就可以了。

```
$ curl -L git.io/weave -o /usr/local/bin/weave
$ chmod a+x /usr/local/bin/weave
```

**测试是否安装成功**

```
$ weave version
weave script 1.9.4
weave router 1.9.4
weave proxy  1.9.4
weave plugin 1.9.4
```

`weave version`默认不会下载对应容器，初次运行时会提示容器不存在。你可在运行`weave launch`后在来验证一下。

**初始化Weave网络**

在`dev-master-01`上初始化Weave网络非常的简单，只需运行`weave launch`命令就行了。这条命令是在容器中运行一个`weave router`，需要在每台主机上都启用这个服务。该服务需要三个docker容器来辅助运行,首次运行时会自动下载相关镜像。另外执行`weave launch`之前要保证有`bridge-utils`网桥工具包。

```
$ apt-get install bridge-utils
$ weave launch
```

等命令运行结束后，网络就初始化好了。在这个过程中Weave会下载并运行以下这三个docker容器。

```
$ docker ps
CONTAINER ID        IMAGE                        COMMAND                  CREATED             STATUS              PORTS               NAMES
5e6ad8f3d6a5        weaveworks/plugin:1.9.4      "/home/weave/plugin"     29 seconds ago      Up 29 seconds                           weaveplugin
32826b6869b1        weaveworks/weaveexec:1.9.4   "/home/weave/weave..."   30 seconds ago      Up 29 seconds                           weaveproxy
c2c8367fa831        weaveworks/weave:1.9.4       "/home/weave/weave..."   31 seconds ago      Up 31 seconds                           weave
```
另外还会生成一个名字叫weave的网桥，另一个是Docker默认生成的。

```
$ brctl show
bridge name	bridge id		STP enabled	interfaces
docker0		8000.0242b3b4de11	no
weave		8000.e27709980978	no		vethwe-bridge
```

```
ifconfig weave
weave     Link encap:Ethernet  HWaddr e2:77:09:98:09:78
          inet6 addr: fe80::e077:9ff:fe98:978/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1376  Metric:1
          RX packets:42 errors:0 dropped:0 overruns:0 frame:0
          TX packets:8 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:2640 (2.6 KB)  TX bytes:648 (648.0 B)
```

docker中也会生成一个使用weave的网桥的自定义网络。

```
$ docker network ls
NETWORK ID          NAME                DRIVER              SCOPE
515a6b8ba17d        bridge              bridge              local
0b703c3d9cb8        host                host                local
abdb4b9f751c        none                null                local
71cc68f68786        weave               weavemesh           local
```

 weave的这些数据是保存在每台机器上分配的名为`weavedb`的容器上的，它是一个`data volume`容器，只负责数据的持久化。

```
$ docker ps
40047c1ff6ca weaveworks/weavedb "data-only" 32 minutes ago Created weavedb
```

**连接不同主机**

node主机需要连接到master主机，只需要在`weave launch`后面跟上master主机的ip或者hostname就行了。两台机器就会自动建立集群，并同步所有需要的信息。

主机`dev-node-01`连接到主机`dev-master-01`：

在`dev-node-01`的主机上执行：

```
$ weave launch 192.168.2.210
```

这个命令相当于在本地启动了`weave route`，再通过`weave connect 192.168.2.210`来和192.168.1.201的route容器建立连接。这样weave route就能相互找到remote主机。

同样，当命令运行完，机器上会运行三个weave有关的容器。

```
$ docker ps
CONTAINER ID        IMAGE                        COMMAND                  CREATED             STATUS              PORTS               NAMES
63a397f83e3f        weaveworks/plugin:1.9.4      "/home/weave/plugin"     3 minutes ago       Up 3 minutes                            weaveplugin
e4cb27a9145e        weaveworks/weaveexec:1.9.4   "/home/weave/weave..."   3 minutes ago       Up 3 minutes                            weaveproxy
eef753a60897        weaveworks/weave:1.9.4       "/home/weave/weave..."   3 minutes ago       Up 3 minutes                            weave
```

运行`weave status`，可以查看`weave`的状态信息：

```
$ weave status

        Version: 1.9.4 (up to date; next check at 2017/04/21 13:50:59)

        Service: router
       Protocol: weave 1..2
           Name: 5a:03:e1:1f:10:c3(dev-node-02)
     Encryption: disabled
  PeerDiscovery: enabled
        Targets: 1
    Connections: 1 (1 established)
          Peers: 2 (with 2 established connections)
 TrustedSubnets: none

        Service: ipam
         Status: ready
          Range: 10.32.0.0/12
  DefaultSubnet: 10.32.0.0/12

        Service: dns
         Domain: weave.local.
       Upstream: 8.8.8.8, 223.5.5.5
            TTL: 1
        Entries: 1

        Service: proxy
        Address: unix:///var/run/weave/weave.sock

        Service: plugin
     DriverName: weave
```

### 使用Weave

Weave有三种方式和Docker进行集成，以便运行的容器跑在Weave网络中。

- 使用`weave run`命令直接运行容器。
- 使用`weave env`命令修改`DOKCER_HOST`环境变量的值，使`docker client`和`weave`交互，`weave`和`docker daemon`交互，自动为容器配置网络，对用户透明。
- 使用`weave plugin`，在运行容器的时候使用`--net=weave`参数。

**使用`weave run`命令直接运行容器**

我们在dev-master-01主机上运行一台容器，命名为c1：

```
$ weave run  --name c1 -it busybox sh
```

同样，在dev-node-01主机上运行另外一台容器，命名为c2：

```
$ weave run  --name c2 -it busybox sh
```

从c2上ping c1

```
$ docker exec c2 ping -c 3 c1
PING c1 (10.32.0.1): 56 data bytes
64 bytes from 10.32.0.1: seq=0 ttl=64 time=1.307 ms
64 bytes from 10.32.0.1: seq=1 ttl=64 time=0.600 ms
64 bytes from 10.32.0.1: seq=2 ttl=64 time=0.700 ms
--- c1 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.600/0.869/1.307 ms
```

从c1上ping c2

```
$ docker exec c1 ping -c 3 c2

PING c2 (10.44.0.0): 56 data bytes
64 bytes from 10.44.0.0: seq=0 ttl=64 time=0.401 ms
64 bytes from 10.44.0.0: seq=1 ttl=64 time=0.538 ms
64 bytes from 10.44.0.0: seq=2 ttl=64 time=0.891 ms

--- c2 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.401/0.610/0.891 ms
```

发现网络是联通的，说明weave正确配置，并实现了跨主机的容器通信。

Weave不会修改`docker`现有的网络配置，而是在容器中添加额外的虚拟网卡来搭建自己的网络。

```
/ # ifconfig
eth0      Link encap:Ethernet  HWaddr 02:42:0A:00:02:02
          inet addr:10.0.2.2  Bcast:0.0.0.0  Mask:255.255.255.0
          inet6 addr: fe80::42:aff:fe00:202/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:12 errors:0 dropped:0 overruns:0 frame:0
          TX packets:12 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:874 (874.0 B)  TX bytes:856 (856.0 B)

ethwe     Link encap:Ethernet  HWaddr D6:66:7E:3E:FC:E5
          inet addr:10.32.0.1  Bcast:0.0.0.0  Mask:255.240.0.0
          inet6 addr: fe80::d466:7eff:fe3e:fce5/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1376  Metric:1
          RX packets:26 errors:0 dropped:0 overruns:0 frame:0
          TX packets:18 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:2052 (2.0 KiB)  TX bytes:1404 (1.3 KiB)

lo        Link encap:Local Loopback
          inet addr:127.0.0.1  Mask:255.0.0.0
          inet6 addr: ::1/128 Scope:Host
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)
```

**使用`weave env`命令运行容器**

```
$ eval $(weave env)
$ docker run --name c1 -it busybox sh
$ docker run --name c2 -it busybox sh
```

测试方法和使用`weave run`命令类似，这里就不展开讲了。

**使用`weave plugin`方式运行容器**

```
$ docker run --net=weave --name c1 -it busybox sh

/ # ping -c 3 10.44.0.0
PING 10.44.0.0 (10.44.0.0): 56 data bytes
64 bytes from 10.44.0.0: seq=0 ttl=64 time=0.511 ms
64 bytes from 10.44.0.0: seq=1 ttl=64 time=0.375 ms
64 bytes from 10.44.0.0: seq=2 ttl=64 time=0.703 ms

--- 10.44.0.0 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.375/0.529/0.703 ms
```

```
$ docker run --net=weave --name c2 -it busybox sh

/ # ping -c 3 10.32.0.1
PING 10.32.0.1 (10.32.0.1): 56 data bytes
64 bytes from 10.32.0.1: seq=0 ttl=64 time=0.551 ms
64 bytes from 10.32.0.1: seq=1 ttl=64 time=0.710 ms
64 bytes from 10.32.0.1: seq=2 ttl=64 time=0.556 ms

--- 10.32.0.1 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.551/0.605/0.710 ms
```

默认情况下不会使用weave的DNS，故不能用容器名进行访问。如果要使用容器主机名，可按以下方法：

```
$ docker run --net=weave -h c1.weave.local $(weave dns-args) -ti busybox sh

/ # ping -c3 c2
PING c2 (10.44.0.0): 56 data bytes
64 bytes from 10.44.0.0: seq=0 ttl=64 time=0.472 ms
64 bytes from 10.44.0.0: seq=1 ttl=64 time=0.391 ms
64 bytes from 10.44.0.0: seq=2 ttl=64 time=0.861 ms

--- c2 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.391/0.574/0.861 ms
```

```
$ docker run --net=weave -h c2.weave.local $(weave dns-args) -ti busybox sh

/ # ping c1
PING c1 (10.32.0.1): 56 data bytes
64 bytes from 10.32.0.1: seq=0 ttl=64 time=1.700 ms
64 bytes from 10.32.0.1: seq=1 ttl=64 time=0.784 ms
64 bytes from 10.32.0.1: seq=2 ttl=64 time=0.485 ms
^C
--- c1 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.485/0.989/1.700 ms
/ # ping -c3 c1
PING c1 (10.32.0.1): 56 data bytes
64 bytes from 10.32.0.1: seq=0 ttl=64 time=0.677 ms
64 bytes from 10.32.0.1: seq=1 ttl=64 time=0.405 ms
64 bytes from 10.32.0.1: seq=2 ttl=64 time=0.392 ms

--- c1 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.392/0.491/0.677 ms
```

更多Weave插件使用方法可参考：「[Integrating Docker via the Network Plugin](https://www.weave.works/documentation/net-latest-plugin/)」

### 其它技巧

- ip分配

Weave会保证容器ip都是唯一的，并且自动负责容器ip的分配和回收，你不需要配置任何东西就能得到这个好处。如果对分配有特定需求也是可以自定义分配ip网段的，比如：在阿里云上部署。

weave默认使用的网段是`10.32.0.0/12`，也就是从`10.32.0.0`到`10.47.255.255`。如果这个网段已经被占用，Weave就会报错，这个时候可以使用`--ipalloc-range`参数手动指定`Weave`要使用的网段。

```
$ weave launch --ipalloc-range 10.60.0.0/12
```

- 网络隔离

默认情况下，所有的容器都在同一个子网，不过可以通过`--ipalloc-default-subnet`指定分配的子网(子网必须在可分配网段里)。

```
$ weave launch --ipalloc-default-subnet 10.40.0.0/24 192.168.2.210
```

如果要实现容器网络的隔离，而不是集群中所有容器都能互相访问。Weave可以使用子网实现这个功能，同一个子网的容器互相连通，而不同的子网中容器是隔离的。

当然，一个容器可以在多个子网中，通过和多个网络里的容器互连 。

```
$ eval $(weave env)
$ docker run -e WEAVE_CIDR="net:default net:10.32.0.0/24" --name c6  -ti busybox sh

/ # ifconfig
eth0      Link encap:Ethernet  HWaddr 02:42:0A:00:05:02
          inet addr:10.0.5.2  Bcast:0.0.0.0  Mask:255.255.255.0
          inet6 addr: fe80::42:aff:fe00:502/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:30 errors:0 dropped:0 overruns:0 frame:0
          TX packets:25 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:2162 (2.1 KiB)  TX bytes:1754 (1.7 KiB)

ethwe     Link encap:Ethernet  HWaddr F6:B5:89:16:CB:CD
          inet addr:10.40.0.128  Bcast:0.0.0.0  Mask:255.255.255.0
          inet6 addr: fe80::f4b5:89ff:fe16:cbcd/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1376  Metric:1
          RX packets:190 errors:0 dropped:0 overruns:0 frame:0
          TX packets:182 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:15772 (15.4 KiB)  TX bytes:15124 (14.7 KiB)

lo        Link encap:Local Loopback
          inet addr:127.0.0.1  Mask:255.0.0.0
          inet6 addr: ::1/128 Scope:Host
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:92 errors:0 dropped:0 overruns:0 frame:0
          TX packets:92 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1
          RX bytes:7728 (7.5 KiB)  TX bytes:7728 (7.5 KiB)

```

由于容器c6只允许了自身所在网段和10.32.0.0/24网段，故就只能访问到c1容器和它自身。不在允许网段的容器c2是不能访问的。

```
/ # ping -c3 c1
PING c1 (10.32.0.1): 56 data bytes
64 bytes from 10.32.0.1: seq=0 ttl=64 time=0.411 ms
64 bytes from 10.32.0.1: seq=1 ttl=64 time=0.393 ms
64 bytes from 10.32.0.1: seq=2 ttl=64 time=0.428 ms

--- c1 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.393/0.410/0.428 ms

/ # ping -c3 c6
PING c6 (10.40.0.128): 56 data bytes
64 bytes from 10.40.0.128: seq=0 ttl=64 time=0.051 ms
64 bytes from 10.40.0.128: seq=1 ttl=64 time=0.049 ms
64 bytes from 10.40.0.128: seq=2 ttl=64 time=0.048 ms

--- c6 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.048/0.049/0.051 ms

/ # ping -c3 c2
PING c2 (10.44.0.0): 56 data bytes

--- c2 ping statistics ---
3 packets transmitted, 0 packets received, 100% packet loss
```

注：docker允许同一个机器上的容器互通，为了完全隔离，需要在`docker daemon`启动参数添加上 `--icc=false`。

- 控制ip的值

有时候需要指定容器的ip，以下两种方法可以实现。

方法一：通过设置环境变量

```
$ eval $(weave env)
$ docker run -e WEAVE_CIDR=10.35.1.1/24 --name c3 -it busybox sh

/ # ifconfig
eth0      Link encap:Ethernet  HWaddr 02:42:0A:00:02:02
          inet addr:10.0.2.2  Bcast:0.0.0.0  Mask:255.255.255.0
          inet6 addr: fe80::42:aff:fe00:202/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:7 errors:0 dropped:0 overruns:0 frame:0
          TX packets:7 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:578 (578.0 B)  TX bytes:578 (578.0 B)

ethwe     Link encap:Ethernet  HWaddr A2:FA:CE:EA:C7:C8
          inet addr:10.35.1.1  Bcast:0.0.0.0  Mask:255.255.255.0
          inet6 addr: fe80::a0fa:ceff:feea:c7c8/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1376  Metric:1
          RX packets:7 errors:0 dropped:0 overruns:0 frame:0
          TX packets:8 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:578 (578.0 B)  TX bytes:620 (620.0 B)

lo        Link encap:Local Loopback
          inet addr:127.0.0.1  Mask:255.0.0.0
          inet6 addr: ::1/128 Scope:Host
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)
```


方法二：通过`weave run`命令实现

```
$ weave run 10.36.1.1/24 --name c4 -it busybox sh
$ docker exec -it c4 sh
/ # ifconfig
eth0      Link encap:Ethernet  HWaddr 02:42:0A:00:06:02
          inet addr:10.0.6.2  Bcast:0.0.0.0  Mask:255.255.255.0
          inet6 addr: fe80::42:aff:fe00:602/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:8 errors:0 dropped:0 overruns:0 frame:0
          TX packets:8 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:648 (648.0 B)  TX bytes:648 (648.0 B)

ethwe     Link encap:Ethernet  HWaddr CA:C7:BC:1B:A8:DD
          inet addr:10.36.1.1  Bcast:0.0.0.0  Mask:255.255.255.0
          inet6 addr: fe80::c8c7:bcff:fe1b:a8dd/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1376  Metric:1
          RX packets:8 errors:0 dropped:0 overruns:0 frame:0
          TX packets:9 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:648 (648.0 B)  TX bytes:690 (690.0 B)

lo        Link encap:Local Loopback
          inet addr:127.0.0.1  Mask:255.0.0.0
          inet6 addr: ::1/128 Scope:Host
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)
```

- 动态分配网络

如果在运行容器的时候还不能确定网络，可以使用`-e WEAVE_CIDR=none`参数先不分配网络信息。

```
$ eval $(weave env)
$ docker run -e WEAVE_CIDR=none --name c5 -it busybox sh
/ # ifconfig
eth0      Link encap:Ethernet  HWaddr 02:42:0A:00:02:02
          inet addr:10.0.2.2  Bcast:0.0.0.0  Mask:255.255.255.0
          inet6 addr: fe80::42:aff:fe00:202/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:7 errors:0 dropped:0 overruns:0 frame:0
          TX packets:7 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:578 (578.0 B)  TX bytes:578 (578.0 B)

lo        Link encap:Local Loopback
          inet addr:127.0.0.1  Mask:255.0.0.0
          inet6 addr: ::1/128 Scope:Host
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)

```

使用`weave attach ${container_id}`给运行中的容器分配网络。

```
$ weave attach b1f7a647aee3
10.32.0.1

$ docker exec -it c5 sh
/ # ifconfig
eth0      Link encap:Ethernet  HWaddr 02:42:0A:00:02:02
          inet addr:10.0.2.2  Bcast:0.0.0.0  Mask:255.255.255.0
          inet6 addr: fe80::42:aff:fe00:202/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:8 errors:0 dropped:0 overruns:0 frame:0
          TX packets:8 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:648 (648.0 B)  TX bytes:648 (648.0 B)

ethwe     Link encap:Ethernet  HWaddr 5A:F9:73:7A:C1:1A
          inet addr:10.32.0.1  Bcast:0.0.0.0  Mask:255.240.0.0
          inet6 addr: fe80::58f9:73ff:fe7a:c11a/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1376  Metric:1
          RX packets:8 errors:0 dropped:0 overruns:0 frame:0
          TX packets:9 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:648 (648.0 B)  TX bytes:690 (690.0 B)

lo        Link encap:Local Loopback
          inet addr:127.0.0.1  Mask:255.0.0.0
          inet6 addr: ::1/128 Scope:Host
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)
```


如果要把容器从某个网络中移除，可以使用`weave detach`命令。

```
$ weave detach net:10.32.0.0/24 b1f7a647aee3
10.32.0.1
```

### 常见问题

如果你用虚拟机测试并且多个虚拟机是用同一虚拟机克隆的，所有机器的machine-id会是一样的。就会引起不同主机间连接失败，因为每台主机Weave网桥上的虚拟网卡分配的IP段是一样的。

解决方法如下：

为每台机器重新生成不同的machine-id:

```
$ rm /etc/machine-id /var/lib/dbus/machine-id
$ dbus-uuidgen --ensure
$ systemd-machine-id-setup
$ reboot
```

重新生成后，记得重启才会生效哟。

### 参考文档

http://www.google.com
http://debugo.com/docker-weave/
http://cizixs.com/2016/06/30/weave-network
https://github.com/weaveworks/weave/issues/2451
https://www.weave.works/docs/net/latest/installing-weave/
