---
category: docker
title: Docker跨主机通信解决方案探讨
date: 2017-04-20 09:00:00
tags: [Kubernetes, docker]
abbrlink:
updated:
toc_number: false
---

Docker容器技术正在被企业应用在越来越多的领域中，比如快速部署环境、简化基础设施的配置流程等等。

当你开始在真实的生产环境使用Docker容器去部署应用系统时，你可能需要用到多个容器部署一套复杂的多层应用系统，其中每个容器部署一个特定的应用系统。

此时可能就会遇到如下问题：有多台宿主机，我们事先不知道会在哪台宿主机上创建容器，如何保证在这些宿主机上创建的容器们可以互相联通？

<!-- more -->

### 关于SDN和容器

作为近年来比较热的一个概念，众所周知SDN是Software Defined Network的缩写，即软件定义网络。但不同的人对SDN有不同的理解。在广义上，只要是你通过软件实现了一个东西，然后那个东西能够灵活地去达到网络上面的部署和伸缩，这就可以被认为是SDN。

**围绕容器的开源的SDN解决方案**

Docker自己的网络方案比较简单，就是每个宿主机上会跑一个非常纯粹的Linux Bridge，这个Bridge可以认为是一个二层的交换机，但它的能力有限，只能做一些简单的学习和转发。然后出来的流量，出网桥的流量会走IPTABLES，做NAT的地址转换，然后靠路由转发去做一个宿主之间的通信。

但是当真正用它的网络模型部署一个比较复杂的业务时，会存在很多问题，比如容器重启之后IP就变了；或者是由于每台宿主机会分配固定的网段，因此同一个容器迁到不同宿主机时，它的IP可能会发生变化，因为它是在不同的网段；同时，NAT的存在会造成两端在通讯时看到对方的地址是不真实的，因为它被NAT过；并且NAT本身也是有性能损耗等。这些问题都对使用Docker自己的网络方案造成了障碍。

由于容器技术给传统的虚拟化网络提出了一些新的挑战，所以围绕Docker产生了很多不同的网络解决方案，以弥补Docker在这些方面的不足。

### 现有的主要Docker网络方案

#### 基于实现方式分类

**隧道方案**

通过隧道，或者说Overlay Networking的方式：

- Weave：UDP广播，本机建立新的BR，通过PCAP互通。
- Open vSwitch(OVS)：基于VxLAN和GRE协议，但是性能方面损失比较严重。
- Flannel：UDP广播，VxLan。

隧道方案在IaaS层的网络中应用也比较多，大家共识是随着节点规模的增长复杂度会提升，而且出了网络问题跟踪起来比较麻烦，大规模集群情况下这是需要考虑的一个点。

**路由方案**

通过路由来实现，比较典型的代表有：

- Calico：基于BGP协议的路由方案，支持很细致的ACL控制，对混合云亲和度比较高。
- Macvlan：从逻辑和Kernel层来看隔离性和性能最优的方案，基于二层隔离，所以需要二层路由器支持，大多数云服务商不支持，所以混合云上比较难以实现。

路由方案一般是从3层或者2层实现隔离和跨主机容器互通的，出了问题也很容易排查。

### 基于网络模型分类

**Docker Libnetwork Container Network Model(CNM)阵营**

- Docker Swarm overlay
- Macvlan & IP network drivers
- Calico
- Contiv（from Cisco）

Docker Libnetwork的优势就是原生，而且和Docker容器生命周期结合紧密；缺点也可以理解为是原生，被Docker“绑架”。

**Container Network Interface(CNI)阵营**

- Kubernetes
- Weave
- Macvlan
- Flannel
- Calico
- Contiv
- Mesos CNI

CNI的优势是兼容其他容器技术(e.g. rkt)及上层编排系统(Kuberneres & Mesos)，而且社区活跃势头迅猛，Kubernetes加上CoreOS主推；缺点是非Docker原生。

从上的可以看出，有一些第三方的网络方案是同时属于两个阵营的。

本文主要介绍了Docker容器平台中的`libnetwork`，`flannel`，`calico`，`weave`这几种跨主机通信方案，并对各个方案的原理进行阐述。

### Libnetwork

Libnetwork是从1.6版本开始将Docker的网络功能从Docker核心代码中分离出去，形成一个单独的库。Libnetwork的目标是定义一个健壮的容器网络模型，提供一个一致的编程接口和应用程序的网络抽象。

Libnetwork通过插件的形式为Docker提供网络功能，使得用户可以根据自己的需求实现自己的Driver来提供不同的网络功能。从1.9版本开始，docker已经实现了基于Libnetwork和libkv库的网络模式-多主机的Overlay网络。

Libnetwork所要实现的网络模型基本是这样的：用户可以创建一个或多个网络(一个网络就是一个网桥或者一个VLAN)，一个容器可以加入一个或多个网络。 同一个网络中容器可以通信，不同网络中的容器隔离。

Libnetwork实现了一个叫做Container Network Model (CNM)的东西，也就是说希望成为容器的标准网络模型、框架。其包含了下面几个概念：

![](https://www.hi-linux.com/img/linux/libnetwork1.jpg)

- Sandbox。Sandbox包含容器网络栈的配置，包括容器接口，路由表，DNS配置等的管理。 linux network namespace是常见的一种sandbox的实现。Sandbox中包含众多网络中的若干Endpoint。

- Endpoint。Neutron中和Endpoint相对的概念应该是VNIC，也就是虚拟机的虚拟网卡（也可以看成是VIF）。Endpoint的常见实现包括veth pair、Openvswitch的internal port。当Sandbox要和外界通信的时候就是通过Endpoint连接到外界的，最简单的情况就是连接到一个Bridge上。

- Network。Network是一组可以互相通信的Endpoints集合，组内endpoint可以相互通讯。不同组内endpoint是不能通迅的，是完全隔离的。常见的实现包括linux bridge,vlan等。

目前已经实现了如下Driver：

- Host：主机网络，只用这种网络的容器会使用主机的网络，这种网络对外界是完全开放的，能够访问到主机，就能访问到容器。

- Bridge：桥接网络，这个Driver就是Docker现有网络Bridge模式的实现。除非创建容器的时候指定网络，不然容器就会默认的使用桥接网络。属于这个网络的容器之间可以相互通信，外界想要访问到这个网络的容器需使用桥接网络。

- Null： Driver的空实现，类似于Docker容器的None模式。使用这种网络的容器会完全隔离。

- Overlay： Overlay驱动可以实现通过vxlan等重叠网络封装技术跨越多个主机的网络，目前Docker已经自带该驱动。

- Remote：Remote驱动包不提供驱动，但提供了融合第三方驱动的接口。

### flannel

Flannel之前的名字是Rudder，它是由CoreOS团队针对Kubernetes设计的一个重载网络工具，它的主要思路是：预先留出一个网段，每个主机使用其中一部分，然后每个容器被分配不同的ip；让所有的容器认为大家在同一个直连的网络，底层通过UDP/VxLAN等进行报文的封装和转发。

Flannel类似于weave、vxlan，提供了一个可配置的虚拟承载网络。Flannel以一个daemon形式运行，负责子网的分配，flannel使用etcd存储、交换网络配置、状态等信息。

**flannel基本原理**

flannel默认使用8285端口作为UDP封装报文的端口，VxLan使用8472端口。

![](https://www.hi-linux.com/img/linux/flannel-01.png)

1. 容器直接使用目标容器的ip访问，默认通过容器内部的eth0发送出去。
1. 报文通过veth pair被发送到vethXXX。
1. vethXXX是直接连接到虚拟交换机docker0的，报文通过虚拟bridge docker0发送出去。
1. 查找路由表，外部容器ip的报文都会转发到flannel0虚拟网卡，这是一个P2P的虚拟网卡，然后报文就被转发到监听在另一端的flanneld。
1. flanneld通过etcd维护了各个节点之间的路由表，把原来的报文UDP封装一层，通过配置的iface发送出去。
1. 报文通过主机之间的网络找到目标主机。
1. 报文继续往上，到传输层，交给监听在8285端口的flanneld程序处理。
1. 数据被解包，然后发送给flannel0虚拟网卡。
1. 查找路由表，发现对应容器的报文要交给docker0。
1. docker0找到连到自己的容器，把报文发送过去。

之前也写了一篇关于flannel的文章，有兴趣可以读一下：「[flannel原理简析及安装](https://www.hi-linux.com/posts/30481.html)」


### Calico

Calico是一个纯3层的数据中心网络方案，而且无缝集成像OpenStack这种IaaS云架构，能够提供可控的VM、容器、裸机之间的IP通信。

它基于BPG协议和Linux自己的路由转发机制，不依赖特殊硬件，没有使用NAT或Tunnel等技术。能够方便的部署在物理服务器、虚拟机或者容器环境下。同时它自带的基于Iptables的ACL管理组件非常灵活，能够满足比较复杂的安全隔离需求。

Calico在每一个计算节点利用Linux Kernel实现了一个高效的vRouter来负责数据转发，而每个vRouter通过BGP协议负责把自己上运行的workload的路由信息像整个Calico网络内传播--小规模部署可以直接互联，大规模下可通过指定的BGP route reflector来完成。

这样保证最终所有的workload之间的数据流量都是通过IP路由的方式完成互联的。

**基本原理**

![](https://www.hi-linux.com/img/linux/calico1.jpg)

Calico的方案如上图所示。它把每个操作系统的协议栈认为是一个路由器，然后把所有的容器认为是连在这个路由器上的网络终端，在路由器之间跑标准的路由协议--BGP的协议，然后让它们自己去学习这个网络拓扑该如何转发。所以Calico方案其实是一个纯三层的方案，也就是说让每台机器的协议栈的三层去确保两个容器，跨主机容器之间的三层连通性。

**Calico架构**

![](https://www.hi-linux.com/img/linux/calico2.png)

结合上面这张图，我们来过一遍Calico的核心组件：

- Felix:Calico Agent，跑在每台需要运行Workload的节点上，主要负责配置路由及ACLS等信息来确保Endpoint的连通状态。
- etcd:分布式键值存储，主要负责网络元数据一致性，确保Calico网络状态的准确性。
- BGP Client（BIRD）: 主要负责把Felix写入Kernel的路由信息分发到当前Calico网络，确保Workload间的通信的有效性。
- BGP Route Reflector（BIRD）：大规模部署时使用，摒弃所有节点互联的mesh模式，通过一个或者多个BGP Route Reflector来完成集中式的路由分发。

每个节点上会运行两个主要的程序，一个是它自己的叫Felix，它会监听ECTD中心的存储，从它获取事件，比如说用户在这台机器上加了一个IP，或者是分配了一个容器等。接着会在这台机器上创建出一个容器，并将其网卡、IP、MAC都设置好，然后在内核的路由表里面写一条，注明这个IP应该到这张网卡。

bird是一个标准的路由程序，它会从内核里面获取哪一些IP的路由发生了变化，然后通过标准BGP的路由协议扩散到整个其他的宿主机上，让外界都知道这个IP在这里，你们路由的时候得到这里来。

由于Calico是一种纯三层的实现，因此可以避免与二层方案相关的数据包封装的操作，中间没有任何的NAT，没有任何的overlay，所以它的转发效率可能是所有方案中最高的，因为它的包直接走原生TCP/IP的协议栈，它的隔离也因为这个栈而变得好做。因为TCP/IP的协议栈提供了一整套的防火墙的规则，所以它可以通过IPTABLES的规则达到比较复杂的隔离逻辑。

**Calico优劣势**

- Calico的优势

1. 网络拓扑直观易懂，平行式扩展，可扩展性强
1. 容器间网络三层隔离，无需要担心arp风暴
1. 基于iptable/linux kernel包转发效率高，损耗低
1. 更容易的编程语言(python)
1. 社区活跃，正式版本较成熟

- Calico的劣势

1. calico仅支持TCP, UDP, ICMP andICMPv6协议，如果你想使用L4协议，你只能选择Flannel,Weave或Docker Overlay Network。
1. Calico没有加密数据路径。 用不可信网络上的Calico建立覆盖网络是不安全的。
1. 没有IP重叠支持。 虽然Calico社区正在开发一个实验功能，将重叠IPv4包放入IPv6包中。 但这只是一个辅助解决方案，并不完全支持技术上的IP重叠。

### Weave

Weave是由Zett.io公司开发的，它能够创建一个虚拟网络，用于连接部署在多台主机上的Docker容器，这样容器就像被接入了同一个网络交换机，那些使用网络的应用程序不必去配置端口映射和链接等信息。

外部设备能够访问Weave网络上的应用程序容器所提供的服务，同时已有的内部系统也能够暴露到应用程序容器上。Weave能够穿透防火墙并运行在部分连接的网络上，另外，Weave的通信支持加密，所以用户可以从一个不受信任的网络连接到主机。

**Weave实现原理**

![](https://www.hi-linux.com/img/linux/weave1.png)

容器的网络通讯都通过route服务和网桥转发。

![](https://www.hi-linux.com/img/linux/weave2.png)

Weave会在主机上创建一个网桥,每一个容器通过veth pair连接到该网桥上，同时网桥上有个Weave router的容器与之连接，该router会通过连接在网桥上的接口来抓取网络包(该接口工作在Promiscuous模式)。

在每一个部署Docker的主机(可能是物理机也可能是虚拟机)上都部署有一个W(即Weave router)，它本身也可以以一个容器的形式部署)。Weave run的时候就可以给每个veth的容器端分配一个ip和相应的掩码。veth的网桥这端就是Weave router容器，并在Weave launch的时候分配好ip和掩码。

Weave网络是由这些weave routers组成的对等端点(peer)构成，每个对等的一端都有自己的名字，其中包括一个可读性好的名字用于表示状态和日志的输出，一个唯一标识符用于运行中相互区别，即使重启Docker主机名字也保持不变，这些名字默认是mac地址。

每个部署了Weave router的主机都需要将TCP和UDP的6783端口的防火墙设置打开，保证Weave router之间控制面流量和数据面流量的通过。控制面由weave routers之间建立的TCP连接构成，通过它进行握手和拓扑关系信息的交换通信。 这个通信可以被配置为加密通信。而数据面由Weave routers之间建立的UDP连接构成，这些连接大部分都会加密。这些连接都是全双工的，并且可以穿越防火墙。

**Weave优劣势**

- Weave优势

1. 支持主机间通信加密。
1. 支持container动态加入或者剥离网络。
1. 支持跨主机多子网通信。

- Weave劣势

1. 只能通过weave launch或者weave connect加入weave网络。

### 各方案对比

- Flannel和overlay方案均使用承载网络，承载网络的优势和劣势都是非常明显。

优势有：对底层网络依赖较少，不管底层是物理网络还是虚拟网络，对层叠网络的配置管理影响较少；配置简单，逻辑清晰，易于理解和学习，非常适用于开发测试等对网络性能要求不高的场景。

劣势主要包括：网络封装是一种传输开销，对网络性能会有影响，不适用于对网络性能要求高的生产场景；由于对底层网络结构缺乏了解，无法做到真正有效的流量工程控制，也会对网络性能产生影响；某些情况下也不能完全做到与下层网络无关，例如隧道封装会对网络的MTU限制产生影响。

- Calico方案因为没有隧道封装的网络开销，会带来相对较高的网络性能。不支持多租户，由于没有封装所有的容器只能通过真实的IP来区分自己，这就要求所有租户的容器统一分配一个地址空间。Calico基于三层转发的原理对物理架构可能会有一定的要求和侵入性。

- weave可以穿透防火墙，安全性较高，流量是被加密的，允许主机连接通过一个不被信任的网络，同样会有承载网络的带来的优缺点。

### 参考文档

http://www.google.com
http://t.cn/RXXC3Vf
http://t.cn/RXXNzkR
http://t.cn/RXXlQD0
http://t.cn/R5un2n0
http://debugo.com/docker-weave/
