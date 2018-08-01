---
category: Kubernetes
title: 图解 Kubernetes 架构
date: 2018-07-10 09:00:00
tags: [Linux, Kubernetes]
abbrlink:
updated:
toc_number: false
---

###  Kubernetes 整体架构图

![](https://www.hi-linux.com/img/linux/k8s-arch1.png)

<!-- more -->

### Kubernetes 各组件介绍

#### Kube-Master「控制节点」

- Kube-Master 的工作流程图

![](https://www.hi-linux.com/img/linux/k8s-arch2.png)

1. Kubecfg 将特定的请求发送给 Kubernetes Client（比如：创建 Pod 的请求）。
2. Kubernetes Client 将请求发送给 API Server。
3. API Server 会根据请求的类型选择用何种 REST API 对请求作出处理（比如：创建 Pod 时 Storage 类型是 Pods 时，其对应的就是 REST Storage API）。
4. REST Storage API 会对请求作相应的处理并将处理的结果存入高可用键值存储系统 Etcd 中。
5. 在 API Server 响应 Kubecfg 的请求后，Scheduler 会根据 Kubernetes Client 获取的集群中运行 Pod 及 Minion / Node 信息将未分发的 Pod 分发到可用的 Minion / Node 节点上。

##### API Server 「资源操作入口」

- API Server 提供了资源对象的唯一操作入口，其它所有组件都必须通过它提供的 API 来操作资源数据。只有 API Server 会与存储通信，其它模块都必须通过 API Server 访问集群状态。

- API Server 作为 Kubernetes 系统的入口，封装了核心对象的增删改查操作。API Server 以 RESTFul 接口方式提供给外部客户和内部组件调用，API Server 再对相关的资源数据（全量查询 + 变化监听）进行操作，以达到实时完成相关的业务功能。

- 以 API Server 为 Kubernetes 入口的设计主要有以下好处：1. 保证了集群状态访问的安全。2. API Server 隔离了集群状态访问和后端存储实现，这样 API Server 状态访问的方式不会因为后端存储技术 Etcd 的改变而改变，让后端存储方式选择更加灵活，方便了整个架构的扩展。

#####  Controller Manager 「内部管理控制中心」

Controller Manager 用于实现 Kubernetes 集群故障检测和恢复的自动化工作。Controller Manager 主要负责执行以下各种控制器：

![](https://www.hi-linux.com/img/linux/k8s-arch3.png)

- Replication Controller

Replication Controller 的作用主要是定期关联 Replication Controller (RC) 和 Pod，以保证集群中一个 RC (一种资源对象) 所关联的 Pod 副本数始终保持为与预设值一致。

- Node Controller

Kubelet 在启动时会通过 API Server 注册自身的节点信息，并定时向 API Server 汇报状态信息。API Server 在接收到信息后将信息更新到 Etcd 中。

Node Controller 通过 API Server 实时获取 Node 的相关信息，实现管理和监控集群中的各个 Node 节点的相关控制功能。

- ResourceQuota Controller

资源配额管理控制器用于确保指定的资源对象在任何时候都不会超量占用系统上物理资源。

- Namespace Controller

用户通过 API Server 可以创建新的 Namespace 并保存在 Etcd 中，Namespace Controller 定时通过 API Server 读取这些 Namespace 信息来操作 Namespace。

比如：Namespace 被 API 标记为优雅删除，则将该 Namespace 状态设置为 Terminating 并保存到 Etcd 中。同时 Namespace Controller 删除该 Namespace 下的 ServiceAccount、RC、Pod 等资源对象。

- Service Account Controller

Service Account Controller (服务账号控制器)，主要在命名空间内管理 ServiceAccount，以保证名为 default 的 ServiceAccount 在每个命名空间中存在。

- Token Controller

Token Controller（令牌控制器）作为 Controller Manager 的一部分，主要用作：监听 serviceAccount 的创建和删除动作以及监听 secret 的添加、删除动作。

- Service Controller

Service Controller 是属于 Kubernetes 集群与外部平台之间的一个接口控制器，Service Controller 主要用作监听 Service 的变化。

比如：创建的是一个 LoadBalancer 类型的 Service，Service Controller 则要确保外部的云平台上对该 Service 对应的 LoadBalancer 实例被创建、删除以及相应的路由转发表被更新。

- Endpoint Controller

Endpoints 表示了一个 Service 对应的所有 Pod 副本的访问地址，而 Endpoints Controller 是负责生成和维护所有 Endpoints 对象的控制器。

Endpoint Controller 负责监听 Service 和对应的 Pod 副本的变化。定期关联 Service 和 Pod (关联信息由 Endpoint 对象维护)，以保证 Service 到 Pod 的映射总是最新的。

##### Scheduler「集群分发调度器」

- Scheduler 主要用于收集和分析当前 Kubernetes 集群中所有 Minion / Node 节点的资源 (包括内存、CPU 等) 负载情况，然后依据资源占用情况分发新建的 Pod 到 Kubernetes 集群中可用的节点。
- Scheduler 会实时监测 Kubernetes 集群中未分发和已分发的所有运行的 Pod。
- Scheduler 会实时监测 Minion / Node 节点信息，由于会频繁查找 Minion/Node 节点，Scheduler 同时会缓存一份最新的信息在本地。
- Scheduler 在分发 Pod 到指定的 Minion / Node 节点后，会把 Pod 相关的信息 Binding 写回 API Server，以方便其它组件使用。

#### Kube-Node「服务节点」

- Kubelet 结构图

![](https://www.hi-linux.com/img/linux/k8s-arch4.png)

##### Kubelet 「节点上的 Pod 管家」

- 负责 Node 节点上 Pod 的创建、修改、监控、删除等全生命周期的管理。
- 定时上报本地 Node 的状态信息给 API Server。
- Kubelet 是 Master API Server 和 Minion / Node 之间的桥梁，接收 Master API Server 分配给它的 Commands 和 Work。
- Kubelet 通过 Kube ApiServer 间接与 Etcd 集群交互来读取集群配置信息。
- Kubelet 在 Node 上做的主要工作具体如下：1. 设置容器的环境变量、给容器绑定 Volume、给容器绑定 Port、根据指定的 Pod 运行一个单一容器、给指定的 Pod 创建 Network 容器。2. 同步 Pod 的状态，从 cAdvisor 获取 Container Info、 Pod Info、 Root Info、 Machine info。3. 在容器中运行命令、杀死容器、删除 Pod 的所有容器。

##### Proxy「负载均衡、路由转发」

- Proxy 是为了解决外部网络能够访问集群中容器提供的应用服务而设计的，Proxy 运行在每个 Minion / Node 上。

- Proxy 提供 TCP / UDP 两种 Sockets 连接方式 。每创建一个 Service，Proxy 就会从 Etcd 获取 Services 和 Endpoints 的配置信息（也可以从 File 获取），然后根据其配置信息在 Minion / Node 上启动一个 Proxy 的进程并监听相应的服务端口。当外部请求发生时，Proxy 会根据 Load Balancer 将请求分发到后端正确的容器处理。

- Proxy 不但解决了同一宿主机相同服务端口冲突的问题，还提供了 Service 转发服务端口对外提供服务的能力。Proxy 后端使用随机、轮循等负载均衡算法进行调度。

##### Kubectl 「集群管理命令行工具集」

- Kubectl 是 Kubernetes 的 客户端的工具。 通过 Kubectl 命令对 API Server 进行操作，API Server 响应并返回对应的命令结果，从而达到对 Kubernetes 集群的管理。

> 本文在 「[Kubernetes 总架构图](http://www.huweihuang.com/article/kubernetes/kubernetes-architecture/)」的基础上整理和修改。

### 参考文档

http://www.google.com
http://t.cn/RdHiHXX
http://t.cn/RdHimG5
http://t.cn/RdHRDq8