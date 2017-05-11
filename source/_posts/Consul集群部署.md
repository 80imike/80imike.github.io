---
category: Consul
title: Consul集群部署
date: 2017-05-11 09:00:00
tags: [Docker,Consul]
abbrlink:
updated:
toc_number: false
---

在「[Consul入门](https://www.hi-linux.com/posts/6132.html)」一文中我们对Consul的基本知识点和单节点部署做了一些介绍，今天我们来讲讲Consul集群的部署方法。

### Consul架构说明

![](https://www.hi-linux.com/img/linux/consul-arch.png)

上图是官网提供的一个事例系统图，图中的Server是consul服务端高可用集群，Client是consul客户端。consul客户端不保存数据，客户端将接收到的请求转发给响应的Server端。Server之间通过局域网或广域网通信实现数据一致性。每个Server或Client都是一个consul agent。

<!-- more -->

Consul集群间使用了GOSSIP协议通信和raft一致性算法。上面这张图涉及到了很多术语：

- Agent——agent是一直运行在Consul集群中每个成员上的守护进程。通过运行`consul agent`来启动。agent可以运行在client或者server模式。指定节点作为client或者server是非常简单的，除非有其他agent实例。所有的agent都能运行DNS或者HTTP接口，并负责运行时检查和保持服务同步。

- Client——一个Client是一个转发所有RPC到server的代理。这个client是相对无状态的。client唯一执行的后台活动是加入LAN gossip池。这有一个最低的资源开销并且仅消耗少量的网络带宽。

- Server——一个server是一个有一组扩展功能的代理，这些功能包括参与Raft选举，维护集群状态，响应RPC查询，与其他数据中心交互WAN gossip和转发查询给leader或者远程数据中心。

- DataCenter——虽然数据中心的定义是显而易见的，但是有一些细微的细节必须考虑。例如，在EC2中，多个可用区域被认为组成一个数据中心。我们定义数据中心为一个私有的，低延迟和高带宽的一个网络环境。这不包括访问公共网络，但是对于我们而言，同一个EC2中的多个可用区域可以被认为是一个数据中心的一部分。

- Consensus——一致性，使用Consensus来表明就leader选举和事务的顺序达成一致。为了以容错方式达成一致，一般有超过半数一致则可以认为整体一致。Consul使用Raft实现一致性，进行leader选举，在consul中的使用bootstrap时，可以进行自选，其他server加入进来后bootstrap就可以取消。

- Gossip——Consul建立在Serf的基础之上，它提供了一个用于多播目的的完整的gossip协议。Serf提供成员关系，故障检测和事件广播。Serf是去中心化的服务发现和编制的解决方案，节点失败侦测与发现，具有容错、轻量、高可用的特点。

- LAN Gossip——它包含所有位于同一个局域网或者数据中心的所有节点。

- WAN Gossip——它只包含Server。这些server主要分布在不同的数据中心并且通常通过因特网或者广域网通信。

- RPC——远程过程调用。这是一个允许client请求server的请求/响应机制。

在每个数据中心，client和server是混合的。一般建议有3-5台server。这是基于有故障情况下的可用性和性能之间的权衡结果，因为越多的机器加入达成共识越慢。然而，并不限制client的数量，它们可以很容易的扩展到数千或者数万台。

同一个数据中心的所有节点都必须加入gossip协议。这意味着gossip协议包含一个给定数据中心的所有节点。这服务于几个目的：第一，不需要在client上配置server地址。发现都是自动完成的。第二，检测节点故障的工作不是放在server上，而是分布式的。这是的故障检测相比心跳机制有更高的可扩展性。第三：它用来作为一个消息层来通知事件，比如leader选举发生时。

每个数据中心的server都是Raft节点集合的一部分。这意味着它们一起工作并选出一个leader，一个有额外工作的server。leader负责处理所有的查询和事务。作为一致性协议的一部分，事务也必须被复制到所有其他的节点。因为这一要求，当一个非leader得server收到一个RPC请求时，它将请求转发给集群leader。

server节点也作为WAN gossip Pool的一部分。这个Pool不同于LAN Pool，因为它是为了优化互联网更高的延迟，并且它只包含其他Consul server节点。这个Pool的目的是为了允许数据中心能够以low-touch的方式发现彼此。这使得一个新的数据中心可以很容易的加入现存的WAN gossip。因为server都运行在这个pool中，它也支持跨数据中心请求。当一个server收到来自另一个数据中心的请求时，它随即转发给正确数据中想一个server。该server再转发给本地leader。

这使得数据中心之间只有一个很低的耦合，但是由于故障检测，连接缓存和复用，跨数据中心的请求都是相对快速和可靠的。

### 构建Consul集群

#### 环境准备

- 系统环境

|主机名|IP地址|Consul角色|
|---|---|---|
|dev-master-01|192.168.2.210|Server|
|dev-node-01|192.168.2.211|Server|
|dev-node-02|192.168.2.212|Server|
|dev-node-03|192.168.2.213|Client|

- 建立相应的数据和配置目录

```
$ mkdir -p /opt/consul/web
$ mkdir -p /opt/consul/data
$ mkdir -p /opt/consul/conf
$ mkdir -p /opt/consul/run/
```

- 下载Web-UI(可选)

Consul提供了用于状态监控Web服务器，将Web UI工具下载到`-ui-dir`指定的目录，即可以创建可视化的管理页面。Consul 0.8.2版本已经自带了，不用在单独下载。

```
$ wget https://releases.hashicorp.com/consul/0.8.1/consul_0.8.1_web_ui.zip
$ unzip consul_0.8.1_web_ui.zip -d /opt/consul/web/
```

> 以上几项操作在所有节点上都要进行。

#### 安装Consul

Consul安装非常简单，如果你还没有安装好Consul，可先参考「[Consul入门](https://www.hi-linux.com/posts/6132.html)」一文。

#### Conusl命令行

consul是只有一个命令行应用，就是consul命令。consul命令可以包含agent、members等参数进行使用，下面我们介绍下常用的几个命令：

通过`consul -h`可看到consul所支持的所有子命令。

```
$ consul -h
usage: consul [--version] [--help] <command> [<args>]

Available commands are:
   agent          Runs a Consul agent
   event          Fire a new event
   exec           Executes a command on Consul nodes
   force-leave    Forces a member of the cluster to enter the "left" state
   info           Provides debugging information for operators.
   join           Tell Consul agent to join cluster
   keygen         Generates a new encryption key
   keyring        Manages gossip layer encryption keys
   kv             Interact with the key-value store
   leave          Gracefully leaves the Consul cluster and shuts down
   lock           Execute a command holding a lock
   maint          Controls node or service maintenance mode
   members        Lists the members of a Consul cluster
   monitor        Stream logs from a Consul agent
   operator       Provides cluster-level tools for Consul operators
   reload         Triggers the agent to reload configuration files
   rtt            Estimates network round trip time between nodes
   snapshot       Saves, restores and inspects snapshots of Consul server state
   validate       Validate config files/directories
   version        Prints the Consul version
   watch          Watch for changes in Consul
```

简单说下几个常用指令的用途:

> - agent指令是consul的核心，它运行agent来维护成员的重要信息、运行检查、服务宣布、查询处理等等。
> - event命令提供了一种机制，用来fire自定义的用户事件，这些事件对consul来说是不透明的，但它们可以用来构建自动部署、重启服务或者其他行动的脚本。
> - exec指令提供了一种远程执行机制，比如你要在所有的机器上执行uptime命令，远程执行的工作通过job来指定，存储在KV中。agent使用event系统可以快速的知道有新的job产生，消息是通过gossip协议来传递的，因此消息传递是最佳的，但是并不保证命令的执行。事件通过gossip来驱动，远程执行依赖KV存储系统(就像消息代理一样)。
> - force-leave可以强制consul集群中的成员进入left状态(空闲状态)，记住，即使一个成员处于活跃状态，它仍旧可以再次加入集群中，这个方法的真实目的是强制移除failed的节点。如果failed的节点还是网络的一部分，则consul会周期性的重新链接failed的节点，如果经过一段时间后(默认是72小时)，consul则会宣布停止尝试链接failed的节点。force-leave指令可以快速的把failed节点转换到left状态。
> - info指令提供了各种操作时可以用到的debug信息，对于client和server，info有返回不同的子系统信息，目前有以下几个KV信息：agent(提供agent信息)，consul(提供consul库的信息)，raft(提供raft库的信息)，serf_lan(提供LAN gossip pool),serf_wan(提供WAN gossip pool)。
> - join指令告诉consul agent加入一个已经存在的集群中，一个新的consul agent必须加入一个已经有至少一个成员的集群中，这样它才能加入已经存在的集群中，如果你不加入一个已经存在的集群，则agent是它自身集群的一部分，其他agent则可以加入进来。agent可以加入其他agent多次。如果你想加入多个集群，则可以写多个地址，consul会加入所有的地址。
> - keygen指令生成加密的密钥，可以用在consul agent通讯加密。
> - leave指令触发一个优雅的离开动作并关闭agent，节点离开后不会尝试重新加入集群中。运行在server状态的节点，节点会被优雅的删除，这是很严重的，在某些情况下一个不优雅的离开会影响到集群的可用性。
> - members指令输出consul agent目前所知道的所有的成员以及它们的状态，节点的状态只有alive、left、failed三种状态。
> - monitor指令用来链接运行的agent，并显示日志。monitor会显示最近的日志，并持续的显示日志流，不会自动退出，除非你手动或者远程agent自己退出。
> - reload指令可以重新加载agent的配置文件。SIGHUP指令在重新加载配置文件时使用，任何重新加载的错误都会写在agent的log文件中，并不会打印到屏幕。
> - version指令用作打印consul的版本
> - watch指令提供了一个机制，用来监视实际数据视图的改变(节点列表、成员服务、KV)，如果没有指定进程，当前值会被dump出来。

##### Consul Agent配置说明

在部署Consul集群时，主要用到的是agent指令。这里重点讲一下agent指令的参数，agent有各种各样的配置项可以在命令行或者配置文件进行定义，所有的配置项都是可选择的。存在相同配置定义时，后面定义的配置会合并前面定义的配置，但大多数情况下合并的意思是后面定义的配置会覆盖前面定义的配置。

- 命令行参数

> 1. -advertise：通知展现地址用来改变我们给集群中的其他节点展现的地址，一般情况下-bind地址就是展现地址
> 1. -bootstrap：用来控制一个server是否在bootstrap模式，在一个datacenter中只能有一个server处于bootstrap模式，当一个server处于bootstrap模式时，可以自己选举为raft leader。
> 1. -bootstrap-expect：在一个datacenter中期望提供的server节点数目，当该值提供的时候，consul一直等到达到指定sever数目的时候才会引导整个集群，该标记不能和bootstrap公用。
> 1. -bind：该地址用来在集群内部的通讯，集群内的所有节点到地址都必须是可达的，默认是0.0.0.0。
> 1. -client：consul绑定在哪个client地址上，这个地址提供HTTP、DNS、RPC等服务，默认是127.0.0.1。
> 1. -config-file：明确的指定要加载哪个配置文件
> 1. -config-dir：配置文件目录，里面所有以.json结尾的文件都会被加载
> 1. -data-dir：提供一个目录用来存放agent的状态，所有的agent都需要该目录，该目录必须是稳定的，系统重启后都继续存在。
> 1. -dc：该标记控制agent的datacenter的名称，默认是dc1。
> 1. -encrypt：指定secret key，使consul在通讯时进行加密，key可以通过consul keygen生成，同一个集群中的节点必须使用相同的key。
> 1. -join：加入一个已经启动的agent的ip地址，可以多次指定多个agent的地址。如果consul不能加入任何指定的地址中，则agent会启动失败。默认agent启动时不会加入任何节点。
> 1. -retry-join：和join类似，但是允许你在第一次失败后进行尝试。
> 1. -retry-interval：两次join之间的时间间隔，默认是30s。
> 1. -retry-max：尝试重复join的次数，默认是0，也就是无限次尝试。
> 1. -log-level：consul agent启动后显示的日志信息级别。默认是info，可选：trace、debug、info、warn、err。
> 1. -node：节点在集群中的名称，在一个集群中必须是唯一的，默认是该节点的主机名。
> 1. -protocol：consul使用的协议版本。
> 1. -rejoin：使consul忽略先前的离开，在再次启动后仍旧尝试加入集群中。
> 1. -server：定义agent运行在server模式，每个集群至少有一个server，建议每个集群的server不要超过5个。
> 1. -syslog：开启系统日志功能，只在linux/osx上生效。
> 1. -ui-dir:提供存放web ui资源的路径，该目录必须是可读的。
> 1. -pid-file:提供一个路径来存放pid文件，可以使用该文件进行SIGINT/SIGHUP(关闭/更新)agent。

更多参数说明可参考：https://www.consul.io/docs/agent/options.html

- 配置文件

除了命令行参数外，配置也可以写入文件中。配置文件是json格式的，很容易编写。配置文件不仅被用来设置agent的启动，也可以用来提供健康检测和服务发现的定义。

配置文件详细参数说明:

> 1. acl_datacenter：只用于server，指定的datacenter的权威ACL信息，所有的servers和datacenter必须同意ACL datacenter
> 1. acl_default_policy：默认是allow。
> 1. acl_token：agent会使用这个token和consul server进行请求。
> 1. acl_ttl：控制TTL的cache，默认是30s。
> 1. addresses：一个嵌套对象，可以设置以下key：dns、http、rpc。
> 1. advertise_addr：等同于-advertise。
> 1. bootstrap：等同于-bootstrap。
> 1. bootstrap_expect：等同于-bootstrap-expect。
> 1. bind_addr：等同于-bind。
> 1. ca_file：提供CA文件路径，用来检查客户端或者服务端的链接。
> 1. cert_file：必须和key_file一起。
> 1. client_addr：等同于-client。
> 1. datacenter：等同于-dc。
> 1. data_dir：等同于-data-dir。
> 1. disable_anonymous_signature：在进行更新检查时禁止匿名签名。
> 1. disable_remote_exec：禁止支持远程执行，设置为true，agent会忽视所有进入的远程执行请求。
> 1. disable_update_check：禁止自动检查安全公告和新版本信息。
> 1. dns_config：是一个嵌套对象，可以设置以下参数：allow_stale、max_stale、node_ttl 、service_ttl、enable_truncate。
> 1. domain：默认情况下consul在进行DNS查询时查询的是consul域，可以通过该参数进行修改。
> 1. enable_debug：开启debug模式。
> 1. enable_syslog：等同于-syslog。
> 1. encrypt：等同于-encrypt。
> 1. key_file：提供私钥的路径。
> 1. leave_on_terminate：默认是false，如果为true，当agent收到一个TERM信号的时候，它会发送leave信息到集群中的其他节点上。
> 1. log_level：等同于-log-level。
> 1. node_name:等同于-node。
> 1. ports：这是一个嵌套对象，可以设置以下key：dns(dns地址：8600)、http(http api地址：8500)、rpc(rpc:8400)、serf_lan(lan port:8301)、serf_wan(wan port:8302)、server(server rpc:8300)。
> 1. protocol：等同于-protocol。
> 1. rejoin_after_leave：等同于-rejoin。
> 1. retry_join：等同于-retry-join。
> 1. retry_interval：等同于-retry-interval。
> 1. server：等同于-server。
> 1. server_name：会覆盖TLS CA的node_name，可以用来确认CA name和hostname相匹配。
> 1. skip_leave_on_interrupt：和leave_on_terminate比较类似，不过只影响当前句柄。
> 1. start_join：一个字符数组提供的节点地址会在启动时被加入。
> 1. syslog_facility：当enable_syslog被提供后，该参数控制哪个级别的信息被发送，默认Local0。
> 1. ui_dir：等同于-ui-dir。
> 1. verify_incoming：默认false，如果为true，则所有进入链接都需要使用TLS，需要客户端使用ca_file提供ca文件。只用于consul server端，因为client从来没有进入的链接。
> 1. verify_outgoing：默认false，如果为true，则所有出去链接都需要使用TLS，需要服务端使用ca_file提供ca文件，consul server和client都需要使用，因为两者都有出去的链接。
> 1. watches：watch一个详细名单。

以启动agent为例：

```

# 创建配置文件
$ vim /opt/consul/conf/server.json

{
  "datacenter": "dc1",
  "data_dir": "/opt/consul/data",
  "log_level": "INFO",
  "node_name": "consul-server01",
  "server": true,
  "bootstrap_expect": 1,
  "bind_addr": "192.168.2.210",
  "client_addr": "192.168.2.210",
  "ui_dir": "/opt/consul/web",
  "retry_join": ["192.168.2.210","192.168.2.211","192.168.2.212"],
  "retry_interval": "30s",
  "enable_debug": false,
  "rejoin_after_leave": true,
  "start_join": ["192.168.2.210","192.168.2.211","192.168.2.212"],
  "enable_syslog": true,
  "syslog_facility": "local0"
}

# consul从配置目录加载配置
$ consul agent -config-dir /opt/consul/conf/
# consul从配置文件加载配置
$ consul agent -config-file=server.json
```

#### Consul常用端口说明

> 1. dns - The DNS server, -1 to disable. Default 8600.
> 1. http - The HTTP API, -1 to disable. Default 8500.
> 1. https - The HTTPS API, -1 to disable. Default -1 (disabled).
> 1. rpc - The CLI RPC endpoint. Default 8400.
> 1. serf_lan - The Serf LAN port. Default 8301.
> 1. serf_wan - The Serf WAN port. Default 8302.
> 1. server - Server RPC address. Default 8300.

#### 部署集群

##### 部署Server端

这里我们一共要部署三个Server端，具体如下：

- 在dev-master-01上部署

```
$ consul agent -server -bootstrap -syslog \
    -ui-dir=/opt/consul/web \
    -data-dir=/opt/consul/data \
    -config-dir=/opt/consul/conf \
    -pid-file=/opt/consul/run/consul.pid \
    -client=192.168.2.210 \
    -bind=192.168.2.210 \
    -node=consul-server01 \
    -disable-host-node-id
```

小提示：
> 1. -bootstrap一般只在集群初始化时使用一次。
> 1. 最新版本是内置了Web的，直接使用`-ui`参数启用就行了。

- 在dev-node-01上部署

```
$ consul agent -server -syslog \
    -ui \
    -data-dir=/opt/consul/data \
    -config-dir=/opt/consul/conf \
    -pid-file=/opt/consul/run/consul.pid \
    -client=192.168.2.211 \
    -bind=192.168.2.211 \
    -node=consul-server02 \
    -disable-host-node-id
```

- 在dev-node-02上部署

```
$ consul agent -server -syslog \
    -ui \
    -data-dir=/opt/consul/data \
    -config-dir=/opt/consul/conf \
    -pid-file=/opt/consul/run/consul.pid \
    -client=192.168.2.212 \
    -bind=192.168.2.212 \
    -node=consul-server03 \
    -disable-host-node-id

```

到此我们已经启动了三个Consul Server，这三个Consul Server现在还对彼此没有任何感知。它们都为单节点的集群，每个集群都仅包含一个成员。运行`consul members`来验证下。

由于启动Agent时绑定了IP地址，所以下面需要显示指定IP地址。默认连接地址是`127.0.0.1:8500`。

```
# dev-master-01
$ consul members --http-addr 192.168.2.210:8500
Node             Address             Status  Type    Build  Protocol  DC
consul-server01  192.168.2.210:8301  alive   server  0.8.1  2         dc1

# dev-node-01
$ consul members --http-addr 192.168.2.211:8500
Node             Address             Status  Type    Build  Protocol  DC
consul-server02  192.168.2.211:8301  alive   server  0.8.1  2         dc1

# dev-node-02
$ consul members --http-addr 192.168.2.212:8500
Node             Address             Status  Type    Build  Protocol  DC
consul-server03  192.168.2.212:8301  alive   server  0.8.1  2         dc1
```

- 加入集群

Consul发现机制

- 当一个Consul代理启动后，它并不知道其它节点的存在，它是一个孤立的单节点集群。
- 如果想感知到其它节点的存在，它必须加入到一个现存的集群。
- 要加入到一个现存的集群，它只用加入集群中任意一个现存的成员。
- 当加入一个现存的成员后，会通过成员间的通讯很快发现集群中的其它成员。
- 一个Consul代理可以加入任意一个代理，而不仅仅是服务节点。

为了让三个Server间能互相感知，这里就要让其它二个Server加入同一个集群中。

a) Server02加入Server01

```
$ consul join --http-addr 192.168.2.211:8500 192.168.2.210
```

我的环境是三台链接克隆的虚拟机，会报如下错：

```
* Failed to join 192.168.2.210: Member 'consul-server01' has conflicting node ID 'b76ff298-accd-05ff-8c64-5d79d866dfa9' with this agent's ID
```

大致的意思是uuid冲突了，默认情况下Consul将使用Consul数据目录下node-id文件中的id，可能是虚拟机原因我三台node-id居然是一样的。

解决方法有两种：

一是在启动agent的时候加入`-disable-host-node-id`参数，禁止生成node-id。类似这样：

```
$ consul agent -server -bootstrap -syslog \
    -ui \
    -data-dir=/opt/consul/data \
    -config-dir=/opt/consul/conf \
    -pid-file=/opt/consul/run/consul.pid \
    -client=192.168.2.210 \
    -bind=192.168.2.210 \
    -node=consul-server01 \
    -disable-host-node-id
```

二是可以用`-node-id`生成一个新的node-id，类似这样：

```
$ consul agent -server -bootstrap -syslog \
    -ui-dir=/opt/consul/web \
    -data-dir=/opt/consul/data \
    -config-dir=/opt/consul/conf \
    -pid-file=/opt/consul/run/consul.pid \
    -client=192.168.2.210 \
    -bind=192.168.2.210 \
    -node=consul-server01 \
    -node-id=$(uuidgen | awk '{print tolower($0)}')
```

再次加入集群：

```
$ consul join --http-addr 192.168.2.211:8500 192.168.2.210
Successfully joined cluster by contacting 1 nodes.
```

b) Server03加入Server01

```
$ consul join --http-addr 192.168.2.212:8500 192.168.2.210
Successfully joined cluster by contacting 1 nodes.
```

成功加入Server01节点后，从Server01上日志可以看出leader已选取出来：

```
...
    2017/05/10 13:54:37 [INFO] consul: cluster leadership acquired
    2017/05/10 13:54:37 [INFO] consul: New leader elected: consul-server01
    2017/05/10 13:54:37 [INFO] consul: member 'consul-server01' joined, marking health alive
...
```

此时在`dev-master-01`节点上查看成员状态，彼此都能互识。

```
# dev-master-01
$ consul members --http-addr 192.168.2.210:8500
Node             Address             Status  Type    Build  Protocol  DC
consul-server01  192.168.2.210:8301  alive   server  0.8.1  2         dc1
consul-server02  192.168.2.211:8301  alive   server  0.8.1  2         dc1
consul-server03  192.168.2.212:8301  alive   server  0.8.1  2         dc1
```

通过HTTP API方式查询，在三个节点上任意一个节点执行：

```
# 查询集群leader
$ curl 192.168.2.210:8500/v1/status/leader
"192.168.2.210:8300"

# 查询集群成员
$ curl 192.168.2.210:8500/v1/status/peers
["192.168.2.210:8300","192.168.2.211:8300","192.168.2.212:8300"]
```

通过DNS方式来查询节点信息

查询结构为`NAME.node.consul`和`NAME.node.DATACENTER.consul`。以查询`consul-server01`为例：

```
$ dig @192.168.2.210 -p 8600 consul-server01.node.consul

;; QUESTION SECTION:
;consul-server01.node.consul.	IN	A

;; ANSWER SECTION:
consul-server01.node.consul. 0	IN	A	192.168.2.210

;; Query time: 1 msec
;; SERVER: 192.168.2.210#8600(192.168.2.210)
;; WHEN: Wed May 10 16:54:08 CST 2017
;; MSG SIZE  rcvd: 61

$ dig  @192.168.2.210 -p 8600 consul-server01.node.dc1.consul

;; QUESTION SECTION:
;consul-server01.node.dc1.consul. IN	A

;; ANSWER SECTION:
consul-server01.node.dc1.consul. 0 IN	A	192.168.2.210

;; Query time: 0 msec
;; SERVER: 192.168.2.210#8600(192.168.2.210)
;; WHEN: Wed May 10 16:55:50 CST 2017
;; MSG SIZE  rcvd: 65
```

注意：

- 如果有多个成员，也只用加入一个节点，其它节点会在这个节点加入集群后通过成员间的通讯相互发现。
- 确保所有节点TCP或UDP的8301是开放的，节点间的通讯得依赖这个端口，否则无法加入。
- 确保所有节点TCP的8300是开放的，因为Client向Server的RPC得依赖这个端口，不打开无法同步。

##### 部署Client端

该节点是Client角色，所以我们不指定它启动为服务器模式。

```
# 在dev-node-03上部署
$ consul agent -syslog \
    -data-dir=/opt/consul/data \
    -config-dir=/opt/consul/conf \
    -pid-file=/opt/consul/run/consul.pid \
    -client=192.168.2.213 \
    -bind=192.168.2.213 \
    -join=192.168.2.210 \
    -node=consul-client01 \
    -disable-host-node-id
```

这里启动的时候就会自动加入一个已有集群，因为启动时加入了`-join`参数，该参数可以自动加入一个已知Consul集群。启动Server角色的Agent的也是可以自动加入的，上面手动加入是为了更好的说明整个过程。

```
# 查询集群成员
$ consul members --http-addr 192.168.2.210:8500
Node             Address             Status  Type    Build  Protocol  DC
consul-client01  192.168.2.213:8301  alive   client  0.8.1  2         dc1
consul-server01  192.168.2.210:8301  alive   server  0.8.1  2         dc1
consul-server02  192.168.2.211:8301  alive   server  0.8.1  2         dc1
consul-server03  192.168.2.212:8301  alive   server  0.8.1  2         dc1
```

##### 服务注册

consul进行服务注册提供了两种方式(HTTP API以及配置文件指定)，在这里我们使用配置文件的方式:     

在dev-master-01上的consul配置目录下建立一个服务文件：

```
$ vim /opt/consul/conf/web.json
{"service": {"name": "web", "tags": ["master"], "port": 8080,
"check": {"http": "http://127.0.0.1:8080", "interval": "10s"}}}
```

这个服务文件的大意是：注册了一个名称是web，运行在8080端口的服务。并且义了一个健康检查。  

通过`consul reload`进行热注册

```
$ consul reload --http-addr=192.168.2.210:8500
Configuration reload triggered
```

此时consul会不断的进行报错,因为这里进行了健康检查。

```
$ tail -f  /var/log/consul/consul.log
May 11 11:45:36 dev-master-01 consul[11226]: agent: http request failed 'http://127.0.0.1:8080': Get http://127.0.0.1:8080: dial tcp 127.0.0.1:8080: getsockopt: connection refused
```

用Python启动一个SimpleHTTPServer进行验证。

```
$ python -m SimpleHTTPServer 8080
Serving HTTP on 0.0.0.0 port 8080 ...
```

再次检查consul日志,一切正常。

```
$ tail -f  /var/log/consul/consul.log
May 11 11:50:57 dev-master-01 consul[11226]: agent: Synced check 'service:web'
```

> 注：这里日志是启用了Syslog的情况，所以日志位置在`/var/log/consul/consul.log`。在没有启用Syslog的情况下，默认会直接输出到终端的。有关Syslog日志启用方法本文后面会讲。

##### 服务发现

服务发现也可以通过HTTP API和DNS两种方式进行，所有查询都在Consul Client角色的机器上进行，以验证Client的正常工作情况。这里以DNS查询方式为例：

```
$ dig @192.168.2.213 -p 8600 web.service.consul SRV

;; QUESTION SECTION:
;web.service.consul.		IN	SRV

;; ANSWER SECTION:
web.service.consul.	0	IN	SRV	1 1 8080 consul-server01.node.dc1.consul.

;; ADDITIONAL SECTION:
consul-server01.node.dc1.consul. 0 IN	A	192.168.2.210
```

停掉刚才启动的web服务，再次查询就没有的web服务了。

```
$ ps uax|grep python
root     12764  0.4  0.6  41120 13136 pts/0    S+   12:04   0:00 python -m SimpleHTTPServer 8080
$ kill 12764
$ dig @192.168.2.213 -p 8600 web.service.consul SRV
 ;; QUESTION SECTION:
 ;web.service.consul.		IN	SRV

 ;; AUTHORITY SECTION:
 consul.			0	IN	SOA	ns.consul. postmaster.consul. 1494475592 3600 600 86400 0
```

最后在Consul Web界面看一下成果

![](http://www.hi-linux.com/img/linux/consul_cluster1.png)

##### 脱离集群

可以使用`Ctrl-C`来平滑退出，也可以强行Kill退出。区别是主动告知其它节点自己的离开，和被其它节点标记为失效。这里要注意，在集群中平滑退出是很重要的。

### 一些技巧

#### 给Consul创建Systemd服务

Consul默认是在前台运行的，为了方便管理我们创建一个Systemd服务。

这里以创建一个Consul Server端为例：

- 创建一个用于启动Consul的专有用户

```
$ useradd -M -s /sbin/nologin consul
$ chown -R consul.consul /opt/consul/
```

- 创建配置文件

这个配置文件里面内容是启动Consul Agent的参数。

```
$ vim /etc/default/consul
CONSUL_FLAGS="-server -bootstrap -syslog -ui -data-dir=/opt/consul/data -config-dir=/opt/consul/conf -pid-file=/opt/consul/run/consul.pid -client=192.168.2.210 -bind=192.168.2.210 -node=consul-server01 -disable-host-node-id"
```

- 创建Systemd配置文件

```
$ vim /etc/systemd/system/consul.service

[Unit]
Description=Consul service discovery agent
Requires=network-online.target
After=network-online.target

[Service]
User=consul
Group=consul
EnvironmentFile=-/etc/default/consul
Environment=GOMAXPROCS=2
Restart=on-failure
ExecStartPre=[ -f "/opt/consul/run/consul.pid" ] && /usr/bin/rm -f /opt/consul/run/consul.pid
ExecStartPre=/usr/local/bin/consul configtest -config-dir=/opt/consul/conf
ExecStart=/usr/local/bin/consul agent $CONSUL_FLAGS
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGTERM
TimeoutStopSec=5

[Install]
WantedBy=multi-user.target
```

这时Kill用的`SIGTERM`信号，因为`SIGTERM`信号在集群环境下可以避免leader重选。SIGINT和SIGTERM的区别：

1. SIGINT与字符ctrl+c关联，SIGTERM没有任何控制字符关联。
1. SIGINT只能结束前台进程，SIGTERM则不是。
1. SIGTERM可以被阻塞、处理和忽略。KILL命令的默认不带参数发送的信号就是SIGTERM，SIGTERM可以让程序优雅的退出。

- 启动Consul

```
$ systemctl start consul.service
```

- 验证是否启动成功

```
$ systemctl status  consul.service
● consul.service - Consul service discovery agent
   Loaded: loaded (/etc/systemd/system/consul.service; disabled; vendor preset: enabled)
   Active: active (running) since Thu 2017-05-11 10:50:14 CST; 4s ago
  Process: 8894 ExecStartPre=/usr/local/bin/consul configtest -config-dir=/opt/consul/conf (code=exited, status=0/SUCCESS)
 Main PID: 8902 (consul)
    Tasks: 9
   Memory: 4.7M
      CPU: 154ms
   CGroup: /system.slice/consul.service
           └─8902 /usr/local/bin/consul agent -server -bootstrap -syslog -ui -data-dir=/opt/consul/data -config-dir=/opt/consul/conf -pid-file=/opt/consul/run/consul.pid -client=192.168.2.210 -bind=192.168.2.210 -node=consul-server01 -disable-host-node-id

May 11 10:50:14 dev-master-01 consul[8902]:       Cluster Addr: 192.168.2.210 (LAN: 8301, WAN: 8302)
May 11 10:50:14 dev-master-01 consul[8902]:     Gossip encrypt: false, RPC-TLS: false, TLS-Incoming: false
May 11 10:50:14 dev-master-01 consul[8902]:              Atlas: <disabled>
May 11 10:50:14 dev-master-01 consul[8902]: ==> Log data will now stream in as it occurs:
May 11 10:50:14 dev-master-01 consul[8902]:     2017/05/11 10:50:14 [INFO] raft: Initial configuration (index=1): [{Suffrage:Voter ID:192.168.2.210:8300 Address:192.168.2.210:8300}]
May 11 10:50:14 dev-master-01 consul[8902]:     2017/05/11 10:50:14 [INFO] raft: Node at 192.168.2.210:8300 [Follower] entering Follower state (Leader: "")
May 11 10:50:14 dev-master-01 consul[8902]:     2017/05/11 10:50:14 [INFO] serf: EventMemberJoin: consul-server01 192.168.2.210
May 11 10:50:14 dev-master-01 consul[8902]:     2017/05/11 10:50:14 [INFO] consul: Adding LAN server consul-server01 (Addr: tcp/192.168.2.210:8300) (DC: dc1)
May 11 10:50:14 dev-master-01 consul[8902]:     2017/05/11 10:50:14 [INFO] serf: EventMemberJoin: consul-server01.dc1 192.168.2.210
May 11 10:50:14 dev-master-01 consul[8902]:     2017/05/11 10:50:14 [INFO] consul: Handled member-join event for server "consul-server01.dc1" in area "wan"
```

#### 给Consul配置Syslog日志

Consul默认是把日志输出到前台，为了方便管理我们用Syslog将日志管理起来。

- 创建日志存放目录并赋权

```
$ mkdir -p /var/log/consul/
$ chown -R syslog.syslog /var/log/consul/
```

- 启用系统日志

```
# 创建日志配置文件
$ cat >/etc/rsyslog.d/consul.conf <<EOF
local0.* /var/log/consul/consul.log
EOF

# 修改默认配置文件中的以下内容
$ vim /etc/rsyslog.d/50-default.conf

# 变更前
*.*;auth,authpriv.none          -/var/log/syslog

# 变更后
*.*;auth,authpriv.none,local0.none          -/var/log/syslog

# 重启rsyslog让配置生效。
$ systemctl restart rsyslog

# 创建日志轮循规则
$ cat >/etc/logrotate.d/consul <<EOF
/var/log/consul/*log {
missingok
compress
notifempty
daily
rotate 5
create 0600 root root
}
EOF
```

- 配置Consul

如果要在`consul agent`中启用Syslog日志，一定要在启动时加入`-syslog`参数。类似这样：

```
$ consul agent -server -bootstrap -syslog -ui -data-dir=/opt/consul/data -config-dir=/opt/consul/conf -pid-file=/opt/consul/run/consul.pid -client=192.168.2.210 -bind=192.168.2.210 -node=consul-server01 -disable-host-node-id
```

- 确认Syslog日志生效

重启服务后，就会在相应目录看到日志。

```
$ tail -f  /var/log/consul/consul.log
May 11 11:06:05 dev-master-01 consul[9891]: serf: Failed to re-join any previously known node
May 11 11:06:05 dev-master-01 consul[9891]: consul: Handled member-join event for server "consul-server01.dc1" in area "wan"
May 11 11:06:12 dev-master-01 consul[9891]: agent: failed to sync remote state: No cluster leader
May 11 11:06:13 dev-master-01 consul[9891]: raft: Heartbeat timeout from "" reached, starting election
May 11 11:06:13 dev-master-01 consul[9891]: raft: Node at 192.168.2.210:8300 [Candidate] entering Candidate state in term 4
May 11 11:06:13 dev-master-01 consul[9891]: raft: Election won. Tally: 1
May 11 11:06:13 dev-master-01 consul[9891]: raft: Node at 192.168.2.210:8300 [Leader] entering Leader state
May 11 11:06:13 dev-master-01 consul[9891]: consul: cluster leadership acquired
May 11 11:06:13 dev-master-01 consul[9891]: consul: New leader elected: consul-server01
May 11 11:06:14 dev-master-01 consul[9891]: agent: Synced node info
```

### 参考文档

http://www.google.com
http://liangxiansen.cn/2017/04/06/consul/
https://segmentfault.com/a/1190000005040904
http://soft.dog/2016/03/19/consul-cluster/
https://www.consul.io/docs/agent/options.html
https://github.com/hashicorp/consul/issues/2877
http://d.hatena.ne.jp/Kazuhira/20170115/1484475183
http://blog.sina.com.cn/s/blog_8ea8e9d50102wwlf.html
