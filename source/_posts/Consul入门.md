---
category: Consul
title: Consul入门
date: 2017-05-09 09:00:00
tags: [Docker,Consul]
abbrlink:
updated:
toc_number: false
---

### Consul简介

Consul是HashiCorp公司推出的开源工具，用于实现分布式系统的服务发现与配置。Consul是分布式的、高可用的、 可横向扩展的。它具备以下特性:

- 服务发现: Consul提供了通过DNS或者HTTP接口的方式来注册服务和发现服务。一些外部的服务通过Consul很容易的找到它所依赖的服务。

- 健康检测: Consul的Client提供了健康检查的机制，可以通过用来避免流量被转发到有故障的服务上。

- Key/Value存储: 应用程序可以根据自己的需要使用Consul提供的Key/Value存储。 Consul提供了简单易用的HTTP接口，结合其他工具可以实现动态配置、功能标记、领袖选举等等功能。

- 多数据中心: Consul支持开箱即用的多数据中心. 这意味着用户不需要担心需要建立额外的抽象层让业务扩展到多个区域。

<!-- more -->

**Consul架构**

Consul架构图

![](https://www.consul.io/assets/images/consul-arch-420ce04a.png)

- Consul Cluster由部署和运行了Consul Agent的节点组成。在Cluster中有两种角色:Server和 Client。

- Server和Client的角色和Consul Cluster上运行的应用服务无关, 是基于Consul层面的一种角色划分.

- Consul Server: 用于维护Consul Cluster的状态信息。 官方建议是: 至少要运行3个或者3个以上的Consul Server。 多个server之中需要选举一个leader, 这个选举过程Consul基于Raft协议实现. 多个Server节点上的Consul数据信息保持强一致性。在局域网内与本地客户端通讯，通过广域网与其他数据中心通讯。

- Consul Client: 只维护自身的状态, 并将HTTP和DNS接口请求转发给服务端。

项目官方网址：https://www.consul.io/

### Consul安装

Consul用Golang实现，因此具有天然可移植性(支持 Linux、windows 和macOS)。安装包仅包含一个可执行文件。Consul安装非常简单，只需要下载对应系统的软件包并解压后就可使用。

- Consul安装

这里以Linux系统为例：

```
$ wget https://releases.hashicorp.com/consul/0.8.1/consul_0.8.1_linux_amd64.zip
$ unzip consul_0.8.1_linux_amd64.zip
$ mv consul /usr/local/bin/
```

其它系统版本可在这里下载：https://www.consul.io/downloads.html

- 验证安装

安装Consul后，通过执行consul命令，你可以看到类似的输出：

```
$ consul
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

### 运行Consul代理

Consul是典型的C/S架构，可以运行服务模式或客户模式。

每一个数据中心必须有至少一个服务节点，3到5个服务节点最好。非常不建议只运行一个服务节点，因为在节点失效的情况下数据有极大的丢失风险。

其它的所有节点都运行在客户端模式下，一个客户节点是非常轻量的注册服务进程，用来处理健康检查，转发请求到服务节点等事务，代理必须在集群中的每个节点上运行。

为了简单起见，我们将暂时在开发者模式中启动Consul代理。这个模式可以非常容易快速地启动一个单节点的Consul环境。但是由于并不保存状态，所以不要在生产环境中使用。

```
$ consul agent -dev -bind=0.0.0.0
```

在有多个IP的环境下必须指定IP，否则会报如下类似错误：

```
==> Error starting agent: Failed to get advertise address: Multiple private IPs found. Please configure one.
```

我的环境是多IP的情况，这里就显示指定IP:


```
$ consul agent -dev -bind=192.168.2.210
==> Starting Consul agent...
==> Consul agent running!
           Version: 'v0.8.1'
           Node ID: 'b76ff298-accd-05ff-8c64-5d79d866dfa9'
         Node name: 'dev-master-01'
        Datacenter: 'dc1'
            Server: true (bootstrap: false)
       Client Addr: 127.0.0.1 (HTTP: 8500, HTTPS: -1, DNS: 8600)
      Cluster Addr: 192.168.2.210 (LAN: 8301, WAN: 8302)
    Gossip encrypt: false, RPC-TLS: false, TLS-Incoming: false
             Atlas: <disabled>

==> Log data will now stream in as it occurs:

    2017/05/09 09:57:06 [DEBUG] Using unique ID "b76ff298-accd-05ff-8c64-5d79d866dfa9" from host as node ID
    2017/05/09 09:57:06 [INFO] raft: Initial configuration (index=1): [{Suffrage:Voter ID:192.168.2.210:8300 Address:192.168.2.210:8300}]
    2017/05/09 09:57:06 [INFO] serf: EventMemberJoin: dev-master-01 192.168.2.210
    2017/05/09 09:57:06 [INFO] serf: EventMemberJoin: dev-master-01.dc1 192.168.2.210
    2017/05/09 09:57:06 [INFO] raft: Node at 192.168.2.210:8300 [Follower] entering Follower state (Leader: "")
    2017/05/09 09:57:06 [INFO] consul: Adding LAN server dev-master-01 (Addr: tcp/192.168.2.210:8300) (DC: dc1)
    2017/05/09 09:57:06 [INFO] consul: Handled member-join event for server "dev-master-01.dc1" in area "wan"
    2017/05/09 09:57:13 [ERR] agent: failed to sync remote state: No cluster leader
    2017/05/09 09:57:14 [WARN] raft: Heartbeat timeout from "" reached, starting election
    2017/05/09 09:57:14 [INFO] raft: Node at 192.168.2.210:8300 [Candidate] entering Candidate state in term 2
    2017/05/09 09:57:14 [DEBUG] raft: Votes needed: 1
    2017/05/09 09:57:14 [DEBUG] raft: Vote granted from 192.168.2.210:8300 in term 2. Tally: 1
    2017/05/09 09:57:14 [INFO] raft: Election won. Tally: 1
    2017/05/09 09:57:14 [INFO] raft: Node at 192.168.2.210:8300 [Leader] entering Leader state
    2017/05/09 09:57:14 [INFO] consul: cluster leadership acquired
    2017/05/09 09:57:14 [INFO] consul: New leader elected: dev-master-01
    2017/05/09 09:57:14 [DEBUG] consul: reset tombstone GC to index 3
    2017/05/09 09:57:14 [INFO] consul: member 'dev-master-01' joined, marking health alive
    2017/05/09 09:57:16 [INFO] agent: Synced service 'consul'
    2017/05/09 09:57:16 [DEBUG] agent: Node info in sync

```

从上面Consul代理启动过程中输出的日志信息可以看到代理运行在服务器模式并且声明集群的leadship。另外，本地的成员已经被标记为一个健康的集群成员。

启动consul后，系统会监听如下端口：

```
$ netstat  -tunpea | grep consul
tcp        0      0 192.168.2.210:8300      0.0.0.0:*               LISTEN      0          26525       5058/consul
tcp        0      0 192.168.2.210:8301      0.0.0.0:*               LISTEN      0          26526       5058/consul
tcp        0      0 192.168.2.210:8302      0.0.0.0:*               LISTEN      0          26528       5058/consul
tcp        0      0 127.0.0.1:8500          0.0.0.0:*               LISTEN      0          26530       5058/consul
tcp        0      0 127.0.0.1:8600          0.0.0.0:*               LISTEN      0          26536       5058/consul
tcp        0      0 192.168.2.210:58670     192.168.2.210:8300      ESTABLISHED 0          26952       5058/consul
tcp        0      0 192.168.2.210:8300      192.168.2.210:58670     ESTABLISHED 0          27735       5058/consul
udp        0      0 192.168.2.210:8301      0.0.0.0:*                           0          26527       5058/consul
udp        0      0 192.168.2.210:8302      0.0.0.0:*                           0          26529       5058/consul
udp        0      0 127.0.0.1:8600          0.0.0.0:*                           0          26535       5058/consul
```

#### 查看集群成员

- 使用member命令

在另一个终端中运行下面的指令，就能看到Consul集群所有的节点。

```
$ consul members
Node           Address             Status  Type    Build  Protocol  DC
dev-master-01  192.168.2.210:8301  alive   server  0.8.1  2         dc1
```

输出结果显示了节点名称，运行的地址，健康状态，在集群中的角色，以及一些版本信息。如果查看更详细的信息可通过`-detailed`选项来查看。

```
$ consul members -detailed
Node           Address             Status  Tags
dev-master-01  192.168.2.210:8301  alive   build=0.8.1:'e9ca44d,dc=dc1,id=b76ff298-accd-05ff-8c64-5d79d866dfa9,port=8300,raft_vsn=2,role=consul,vsn=2,vsn_max=3,vsn_min=2,wan_join_port=8302
```

- 使用HTTP API

members命令选项的输出是基于`gossip`协议的并且其内容是最终一致。也就是说，在任何时候你在本地代理看到的内容可能与当前服务器中的状态并不是绝对一致的。

如果需要强一致性的状态信息，使用HTTP API向Consul服务器发送请求：

```
$ curl localhost:8500/v1/catalog/nodes
[
    {
        "ID": "b76ff298-accd-05ff-8c64-5d79d866dfa9",
        "Node": "dev-master-01",
        "Address": "192.168.2.210",
        "TaggedAddresses": {
            "lan": "192.168.2.210",
            "wan": "192.168.2.210"
        },
        "Meta": {},
        "CreateIndex": 5,
        "ModifyIndex": 6
    }
]
```

- 使用DNS API

除了HTTP API，DNS接口也可用被用来查询节点信息。启动服务后，本地的8600一直处于监听状态，可以接受DNS请求。

```
$ netstat  -tunpea | grep consul | grep 8600
tcp        0      0 127.0.0.1:8600          0.0.0.0:*               LISTEN      0          26536       5058/consul
udp        0      0 127.0.0.1:8600          0.0.0.0:*                           0          26535       5058/consul
```

使用dig查看节点IP

```
$ dig @127.0.0.1 -p 8600  dev-master-01.node.consul

; <<>> DiG 9.10.3-P4-Ubuntu <<>> @127.0.0.1 -p 8600 dev-master-01.node.consul
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 63199
;; flags: qr aa rd; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 0
;; WARNING: recursion requested but not available

;; QUESTION SECTION:
;dev-master-01.node.consul.	IN	A

;; ANSWER SECTION:
dev-master-01.node.consul. 0	IN	A	192.168.2.210

;; Query time: 1 msec
;; SERVER: 127.0.0.1#8600(127.0.0.1)
;; WHEN: Tue May 09 10:21:18 CST 2017
;; MSG SIZE  rcvd: 59
```

#### 停止服务

在终端前台运行的情况下，可使用`Ctrl-C`来平滑地停止代理。停止代理后，你可以看到它脱离集群并且关闭的信息。

```
2017/05/09 10:32:13 [DEBUG] manager: Rebalanced 1 servers, next active server is dev-master-01.dc1 (Addr: tcp/192.168.2.210:8300) (DC: dc1)
2017/05/09 10:33:22 [DEBUG] agent: Service 'consul' in sync
2017/05/09 10:33:22 [DEBUG] agent: Node info in sync
^C==> Caught signal: interrupt
2017/05/09 10:34:17 [DEBUG] http: Shutting down http server (127.0.0.1:8500)
2017/05/09 10:34:17 [INFO] agent: requesting shutdown
2017/05/09 10:34:17 [INFO] consul: shutting down server
2017/05/09 10:34:17 [WARN] serf: Shutdown without a Leave
2017/05/09 10:34:17 [ERR] dns: error starting tcp server: accept tcp 127.0.0.1:8600: use of closed network connection
2017/05/09 10:34:17 [WARN] serf: Shutdown without a Leave
2017/05/09 10:34:17 [INFO] manager: shutting down
2017/05/09 10:34:17 [INFO] agent: shutdown complete
```

为了优雅地离开集群，Consul会通知其他的集群成员自己已经脱离了。如果你强制杀死代理的进程，那么其他的集群成员需要侦测节点是否失效。当一个成员离开，它的服务以及健康状态将从目录中移除。当一个成员失效，它的健康会简单地标记为critical，但它并不会被从目录中移除。Consul将自动尝试重新连接到失效的节点，并允许它在某些网络状况下恢复。如果一个代理以服务器模式启动，优雅地离开是非常重要的，因为这可以避免潜在的可用性问题。

#### 启动Web界面

Consul自带一个界面美观，功能强大的，开箱即用的Web界面。通过该界面我们可以查看所有的服务以及节点，查看所有的健康监测及其当前的状态，以及读取和设置键/值数据。

该界面被映射到/ui上，和HTTP API使用相同的端口。默认就是`http://localhost:8500/ui`。

![](https://www.hi-linux.com/img/linux/consul1.png)

如果你要在其它机器上访问，可以加上`-client`参数指定绑定的IP。

```
$ consul agent -dev -bind=192.168.2.210 -client 0.0.0.0
```

### 注册一个服务

服务能够通过提供一个服务定义或者调用适当的HTTP API来注册。

#### 使用配置文件进行服务定义

Consul会加载配置目录中的所有配置文件，配置文件是以`.json`结尾，并且以字典顺序加载。

##### 创建配置文件

```
# 创建配置目录
$ mkdir /etc/consul.d

# 创建一个服务定义配置文件，假设有一个名为web服务，它运行在80端口。
$ echo '{"service": {"name": "web", "tags": ["rails"], "port": 80}}' >/etc/consul.d/web.json
```

##### 用指定配置文件启动服务

```
$ consul agent -dev -bind=192.168.2.210 -config-dir /etc/consul.d/

==> Starting Consul agent...
==> Consul agent running!
           Version: 'v0.8.1'
           Node ID: 'b76ff298-accd-05ff-8c64-5d79d866dfa9'
         Node name: 'dev-master-01'
        Datacenter: 'dc1'
            Server: true (bootstrap: false)
       Client Addr: 127.0.0.1 (HTTP: 8500, HTTPS: -1, DNS: 8600)
      Cluster Addr: 192.168.2.210 (LAN: 8301, WAN: 8302)
    Gossip encrypt: false, RPC-TLS: false, TLS-Incoming: false
             Atlas: <disabled>

==> Log data will now stream in as it occurs:

    2017/05/09 10:43:05 [DEBUG] Using unique ID "b76ff298-accd-05ff-8c64-5d79d866dfa9" from host as node ID
    2017/05/09 10:43:05 [INFO] raft: Initial configuration (index=1): [{Suffrage:Voter ID:192.168.2.210:8300 Address:192.168.2.210:8300}]
    2017/05/09 10:43:05 [INFO] raft: Node at 192.168.2.210:8300 [Follower] entering Follower state (Leader: "")
    2017/05/09 10:43:05 [INFO] serf: EventMemberJoin: dev-master-01 192.168.2.210
    2017/05/09 10:43:05 [INFO] consul: Adding LAN server dev-master-01 (Addr: tcp/192.168.2.210:8300) (DC: dc1)
    2017/05/09 10:43:05 [INFO] serf: EventMemberJoin: dev-master-01.dc1 192.168.2.210
    2017/05/09 10:43:05 [INFO] consul: Handled member-join event for server "dev-master-01.dc1" in area "wan"
    2017/05/09 10:43:11 [WARN] raft: Heartbeat timeout from "" reached, starting election
    2017/05/09 10:43:11 [INFO] raft: Node at 192.168.2.210:8300 [Candidate] entering Candidate state in term 2
    2017/05/09 10:43:11 [DEBUG] raft: Votes needed: 1
    2017/05/09 10:43:11 [DEBUG] raft: Vote granted from 192.168.2.210:8300 in term 2. Tally: 1
    2017/05/09 10:43:11 [INFO] raft: Election won. Tally: 1
    2017/05/09 10:43:11 [INFO] raft: Node at 192.168.2.210:8300 [Leader] entering Leader state
    2017/05/09 10:43:11 [INFO] consul: cluster leadership acquired
    2017/05/09 10:43:11 [DEBUG] consul: reset tombstone GC to index 3
    2017/05/09 10:43:11 [INFO] consul: member 'dev-master-01' joined, marking health alive
    2017/05/09 10:43:11 [INFO] consul: New leader elected: dev-master-01
    2017/05/09 10:43:11 [INFO] agent: Synced service 'consul'
    2017/05/09 10:43:11 [INFO] agent: Synced service 'web'
    2017/05/09 10:43:11 [DEBUG] agent: Node info in sync
```

输出结果中有`Synced service 'web'`，说明定义的服务已经成功注册到服务目录中。如果要注册更多的服务，可以在Consul配置目录中创建多个服务定义文件。

##### 查看服务

一旦代理启动并且服务已经同步，我们就可以使用DNS或者HTTP API来查询服务了。

- 使用DNS API查看

对于DNS API，服务的DNS名称是`NAME.service.consul` 。默认所有的DNS名称都是在consul名称空间下，当然这个是可配置的。service子域名告诉Consul我们正在查询服务，并且NAME就是要查询的服务的名称。

a) 使用DNS API的方式查看服务对应的IP

```
$ dig @127.0.0.1 -p 8600  web.service.consul

; <<>> DiG 9.10.3-P4-Ubuntu <<>> @127.0.0.1 -p 8600 web.service.consul
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 37039
;; flags: qr aa rd; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 0
;; WARNING: recursion requested but not available

;; QUESTION SECTION:
;web.service.consul.		IN	A

;; ANSWER SECTION:
web.service.consul.	0	IN	A	192.168.2.210

;; Query time: 1 msec
;; SERVER: 127.0.0.1#8600(127.0.0.1)
;; WHEN: Tue May 09 10:48:54 CST 2017
;; MSG SIZE  rcvd: 52
```

b) 使用DNS API来获取完整的地址/端口的SRV记录

```
$ dig @127.0.0.1 -p 8600 web.service.consul SRV

; <<>> DiG 9.10.3-P4-Ubuntu <<>> @127.0.0.1 -p 8600 web.service.consul SRV
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 3941
;; flags: qr aa rd; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1
;; WARNING: recursion requested but not available

;; QUESTION SECTION:
;web.service.consul.		IN	SRV

;; ANSWER SECTION:
web.service.consul.	0	IN	SRV	1 1 80 dev-master-01.node.dc1.consul.

;; ADDITIONAL SECTION:
dev-master-01.node.dc1.consul. 0 IN	A	192.168.2.210

;; Query time: 0 msec
;; SERVER: 127.0.0.1#8600(127.0.0.1)
;; WHEN: Tue May 09 10:52:39 CST 2017
;; MSG SIZE  rcvd: 95
```

SRV记录显示了web服务证运行在节点dev-master-01.node.dc1.consul的80端口上。

c) 使用DNS API结合tag来过滤服务

基于标记的服务查询的格式是`TAG.NAME.service.consul`。 这里以查询Consul中所有含"rails"标记的web服务为例：

```
$ dig @127.0.0.1 -p 8600  rails.web.service.consul

; <<>> DiG 9.10.3-P4-Ubuntu <<>> @127.0.0.1 -p 8600 rails.web.service.consul
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 44287
;; flags: qr aa rd; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 0
;; WARNING: recursion requested but not available

;; QUESTION SECTION:
;rails.web.service.consul.	IN	A

;; ANSWER SECTION:
rails.web.service.consul. 0	IN	A	192.168.2.210

;; Query time: 0 msec
;; SERVER: 127.0.0.1#8600(127.0.0.1)
;; WHEN: Tue May 09 10:58:16 CST 2017
;; MSG SIZE  rcvd: 58
```

- 使用HTTP API查看

除了DNS API，HTTP API也可以用于服务查询。

a) 查询指定节点以及指定的服务信息。

```
$ curl http://localhost:8500/v1/catalog/service/web
[
    {
        "ID": "b76ff298-accd-05ff-8c64-5d79d866dfa9",
        "Node": "dev-master-01",
        "Address": "192.168.2.210",
        "TaggedAddresses": {
            "lan": "192.168.2.210",
            "wan": "192.168.2.210"
        },
        "NodeMeta": {},
        "ServiceID": "web",
        "ServiceName": "web",
        "ServiceTags": [
            "rails"
        ],
        "ServiceAddress": "",
        "ServicePort": 80,
        "ServiceEnableTagOverride": false,
        "CreateIndex": 7,
        "ModifyIndex": 7
    }
]
```

b) 查看服务的健康状态

```
$ curl 'http://localhost:8500/v1/health/service/web?passing'

[
    {
        "Node": {
            "ID": "b76ff298-accd-05ff-8c64-5d79d866dfa9",
            "Node": "dev-master-01",
            "Address": "192.168.2.210",
            "TaggedAddresses": {
                "lan": "192.168.2.210",
                "wan": "192.168.2.210"
            },
            "Meta": {},
            "CreateIndex": 5,
            "ModifyIndex": 6
        },
        "Service": {
            "ID": "web",
            "Service": "web",
            "Tags": [
                "rails"
            ],
            "Address": "",
            "Port": 80,
            "EnableTagOverride": false,
            "CreateIndex": 7,
            "ModifyIndex": 7
        },
        "Checks": [
            {
                "Node": "dev-master-01",
                "CheckID": "serfHealth",
                "Name": "Serf Health Status",
                "Status": "passing",
                "Notes": "",
                "Output": "Agent alive and reachable",
                "ServiceID": "",
                "ServiceName": "",
                "CreateIndex": 5,
                "ModifyIndex": 5
            }
        ]
    }
]
```

#### 调用HTTP API进行定义

Consul提供RESTful HTTP API. API可对节点、服务、健康检查、配置等执行CRUD操作(CRUD是指在做计算处理时的增加(Create)、读取查询(Retrieve)、更新(Update)和删除(Delete))。

Consul Endpoint主要支持以下接口:

> 1. acl – 访问控制列表
> 1. agent – Agent控制
> 1. catalog – 管理nodes和services
> 1. coordinate – 网络协同
> 1. event – 用户事件
> 1. health – 管理健康监测
> 1. kv – K/V存储
> 1. query - Prepared Queries
> 1. session – 管理会话
> 1. status – Consul系统状态

- 注册一个服务

建立一个服务定义文件，格式是JSON的。

```
$ vim redis.json

{
  "ID": "redis1",
  "Name": "redis",
  "Tags": [
    "primary",
    "v1"
  ],
  "Address": "127.0.0.1",
  "Port": 8000,
  "EnableTagOverride": false,
  "Check": {
    "DeregisterCriticalServiceAfter": "90m",
    "Script": "/usr/local/bin/check_redis.py",
    "HTTP": "http://localhost:5000/health",
    "Interval": "10s",
    "TTL": "15s"
  }
}
```

通过API接口提交

```
$ curl --request PUT --data @redis.json http://127.0.0.1:8500/v1/agent/service/register
```

查询指定节点以及指定的服务信息。

```
$ curl http://localhost:8500/v1/catalog/service/redis
[
    {
        "ID": "b76ff298-accd-05ff-8c64-5d79d866dfa9",
        "Node": "dev-master-01",
        "Address": "192.168.2.210",
        "TaggedAddresses": {
            "lan": "192.168.2.210",
            "wan": "192.168.2.210"
        },
        "NodeMeta": {},
        "ServiceID": "redis1",
        "ServiceName": "redis",
        "ServiceTags": [
            "primary",
            "v1"
        ],
        "ServiceAddress": "127.0.0.1",
        "ServicePort": 8000,
        "ServiceEnableTagOverride": false,
        "CreateIndex": 182,
        "ModifyIndex": 182
    }
]
```


- 删除一个服务

```
$ curl --request PUT http://127.0.0.1:8500/v1/agent/service/deregister/redis1
```

再次查询指定节点以及指定的服务信息。

```
$ curl http://localhost:8500/v1/catalog/service/redis
[]
```

更多API使用可参考：https://www.consul.io/api/index.html

### 参考文档

http://www.google.com
http://soft.dog/2016/03/18/consul-basic/
https://segmentfault.com/a/1190000005005227
