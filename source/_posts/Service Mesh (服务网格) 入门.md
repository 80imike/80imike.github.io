---
category: 微服务
title: Service Mesh (服务网格) 入门
date: 2018-04-08 09:00:00
tags: [Linux, 微服务]
abbrlink:
updated:
toc_number: false
---

现在最火的后端架构无疑是微服务了，微服务将之前的单体应用拆分成了许多独立的服务应用，每个微服务都是独立的。

微服务基本组件包括服务注册和发现、服务通信和治理、故障熔断恢复、配置、安全、监控等等，这些微服务组件和功能在业界已经深入人心，在各大互联网公司开花结果，业界知名开源的微服务框架有 Netflix OSS、Spring Cloud 及其国内的阿里 Dubbo 等等，各种框架百花齐放。

微服务好处自然很多，但是随着应用的越来越大，微服务暴露出来的问题也就随之而来了，微服务越来越多，管理越来越麻烦。特别是要你部署一套新环境的时候，随之而来的服务发现、负载均衡、Trace跟踪、流量管理、安全认证等等问题。

当然随着微服务的不断发展，微服务的生态的不断完善，新的微服务框架 Service Mesh 的出现就是为了解决这一系列问题。

<!-- more -->

### 什么是 Service Mesh

Service Mesh 是一个非常新的名词，最早是 2016 年由开发 Linkerd 的 Buoyant 公司提出的，伴随着 Linkerd 的传入，Service Mesh 的概念也慢慢进入国内技术社区。

Service Mesh 是一个基础设施层，其独立运行在应用服务之外，提供应用服务之间安全、可靠、高效的通信，并为服务通信实现了微服务运行所需的基本组件功能，包括服务注册发现、负载均衡、故障恢复、监控、权限控制等等。Service Mesh 的中文译为 "服务网格"。

Willian Morgan（Linker 的 CEO）给出的 Service Mesh 定义：

> A service mesh is a dedicated infrastructure layer for handling service-to-service communication. It’s responsible for the reliable delivery of requests through the complex topology of services that comprise a modern, cloud native application. In practice, the service mesh is typically implemented as an array of lightweight network proxies that are deployed alongside application code, without the application needing to be aware.
>
> 服务网格是一个用于处理服务间通信的基础设施层，它负责为构建复杂的云原生应用传递可靠的网络请求。在实践中，服务网格通常实现为一组和应用程序部署在一起的轻量级的网络代理，但对应用程序来说是透明的。

**一个典型的 Service Mesh 部署网络结构图**

![](https://www.hi-linux.com/img/linux/servicemesh1.png)

其中绿色方块为应用服务，蓝色方块为 Sidecar Proxy，应用服务之间通过 Sidecar Proxy 进行通信，整个服务通信形成图中的蓝色网络连线，图中所有蓝色部分就形成了 Service Mesh。

**Service Mesh 的特点**

Service Mesh 有如下几个特点：

- 应用程序间通讯的中间层
- 轻量级网络代理
- 应用程序无感知
- 解耦应用程序的重试/超时、监控、追踪和服务发现

**为什么需要 Service Mesh**

最主要的理由来自于 Service Mesh 在提供微服务框架功能的同时，它是一个独立运行在应用服务之外的模块。这带来的好处就是应用服务不再需要为接入微服务框架而在代码和配置中添加繁多的依赖库和依赖配置项，实现了微服务框架和应用服务之间的解耦，让应用服务代码更加纯粹地去实现自己的业务逻辑，能够更加轻松地接入微服务框架，享受微服务框架带来的各种服务治理功能。

### 理解服务网格

要理解服务网格的概念，就得从服务的部署模型说起。

- 单个服务调用，表现为 sidecar

![](https://www.hi-linux.com/img/linux/servicemesh2.png)

Service Mesh 的部署模型，先看单个的，对于一个简单请求，作为请求发起者的客户端应用实例，会首先用简单方式将请求发送到本地的 Service Mesh 实例。这是两个独立进程，他们之间是远程调用。

Service Mesh 会完成完整的服务间调用流程，如服务发现负载均衡，最后将请求发送给目标服务。这表现为 Sidecar。

提到 Sidecar，在 Kubernetes 中部署的 POD 中也会有一个附加的 Sidecar 容器。

- 部署多个服务，表现为通讯层

![](https://www.hi-linux.com/img/linux/servicemesh3.png)

多个服务调用的情况，在这个图上我们可以看到 Service Mesh 在所有的服务的下面，这一层被称之为服务间通讯专用基础设施层。Service Mesh 会接管整个网络，把所有的请求在服务之间做转发。在这种情况下，我们会看到上面的服务不再负责传递请求的具体逻辑，只负责完成业务处理。服务间通讯的环节就从应用里面剥离出来，呈现出一个抽象层。

- 有大量服务，表现为网络

![](https://www.hi-linux.com/img/linux/servicemesh4.png)

如果有大量的服务，就会表现出来网格。图中左边绿色方格是应用，右边蓝色的方框是 Service Mesh，蓝色之间的线条是表示服务之间的调用关系。Sidecar 之间的连接就会形成一个网络，这个就是服务网格名字的由来。这个时候代理体现出来的就和前面的 Sidecar 不一样了，形成网状。

- 服务网格

首先第一个，服务网格是抽象的，实际上是抽象出了一个基础设施层，在应用之外。其次，功能是实现请求的可靠传递。部署上体现为轻量级的网络代理。最后一个关键词是，对应用程序透明。

![](https://www.hi-linux.com/img/linux/servicemesh5.png)

大家注意看，上面的图中，网络在这种情况下，可能不是特别明显。但是如果把左边的应用程序去掉，现在只呈现出来 Service Mesh 和他们之间的调用，这个时候关系就会特别清晰，就是一个完整的网络。这是 Service Mesh 定义当中一个非常重要的关键点，和 Sidecar 不相同的地方：不再将代理视为单独的组件，而是强调由这些代理连接而形成的网络。在Service Mesh里面非常强调代理连接组成的网络，而不像 Sidecar 那样看待个体。

### Servcie Mesh 的整体集成解决方案

Service Mesh 主要解决的是微服务之间的网络通信交互，随着业务服务增加，整个 Service Mesh 会变得庞大和复杂之后，这个时候需要对 Service Mesh 的管理功能进行抽象出来，从而满足丰富的微服务运营需求。

目前两款流行的 Servcie Mesh 开源软件 Istio 和 Linkerd 都可以直接在 kubernetes 中集成，其中 Linkerd 已经成为 CNCF 成员。

**Linkerd**

Linkerd 是一个用于云原生应用的开源、可扩展的 Servcie Mesh（服务网格）。同时，Linkerd 也是 CNCF（云原生计算基金会）中的组件之一。

Linkerd 的出现是为了解决像 twitter、google 这类超大规模生产系统的复杂性问题。Linkerd 不是通过控制服务之间的通信机制来解决这个问题，而是通过在服务实例之上添加一个抽象层来解决的。

![](https://www.hi-linux.com/img/linux/servicemesh6.png)

Linkerd 负责跨服务通信中最困难、易出错的部分，包括延迟感知、负载均衡、连接池、TLS、仪表盘、请求路由等——这些都会影响应用程序伸缩性、性能和弹性。

Linkerd 作为独立代理运行，无需特定的语言和库支持。应用程序通常会在已知位置运行 Linkerd 实例，然后通过这些实例代理服务调用——即不是直接连接到目标服务，服务连接到它们对应的 Linkerd 实例，并将它们视为目标服务。

在该层上，Linkerd 应用路由规则，与现有服务发现机制通信，对目标实例做负载均衡——与此同时调整通信并报告指标。

通过延迟调用linkerd的机制，应用程序代码与以下内容解耦：

- 生产拓扑
- 服务发现机制
- 负载均衡和连接管理逻辑

应用程序也将从一致的全局流量控制系统中受益。这对于多语言应用程序尤其重要，因为通过库来实现这种一致性是非常困难的。

Linkerd 实例可以作为 sidecar（既为每个应用实体或每个主机部署一个实例）来运行。 由于Linkerd 实例是无状态和独立的，因此它们可以轻松适应现有的部署拓扑。它们可以与各种配置的应用程序代码一起部署，并且基本不需要去协调它们。

**Istio**

Istio 作为 Servcie Mesh 的另一种实现，原理与 linkerd 基本类似。Istio 由 Google、IBM、Lyft Envoy 联手开发，一开始就定位于实现 Service Mesh 模式的微服务框架，在 2017 年 5 月发布 0.1 版本，然后在 10 月发布了 0.2 版本。

一个 Istio Service Mesh 在逻辑上可以分成两大区块：

- 数据区（data plane）：由通信代理组件（Envoy/Linkerd等）和组件之间的网络通信组成。
- 控制区（control plane）：负责对通信代理组件进行管理和配置。

Istio 的架构图如下：

![](https://www.hi-linux.com/img/linux/servicemesh7.png)

在图中可以看到 Istio Service Mesh 的两大区块。

架构图中各个子模块功能如下：

- Envoy：一个使用 C++ 语言开发的高性能通信代理，负责各个应用服务之间通信。
- Pilot：管理和配置 Envoy ，提供服务发现、负载均衡和智能路由，保证弹性服务（服务超时次数、重试、熔断策略）。
- Mixer：信息监控检查。
- Istio-Auth：提供服务和服务、用户和服务之间的认证服务，实现访问控制，解决是谁访问的是哪个 API 的问题。

其中，图中的通信代理组件为 Envoy，这是 Istio 原生引入的，但 Linkerd 也能够集成对接 Istio。

### 参考文档

http://www.google.com
http://t.cn/Rmtvqhf
http://t.cn/Rmt77KA
http://t.cn/RTDWaHt
http://t.cn/RmtcvKz