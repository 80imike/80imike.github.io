---
category: Docker
title: 初识 Kata Containers
date: 2018-05-18 09:00:00
tags: [Linux, Docker]
abbrlink:
updated:
toc_number: false
---

### 什么是 Kata Containers 

Kata Containers 是由 OpenStack 基金会管理，但独立于 OpenStack 项目之外的容器项目。它是一个可以使用容器镜像以超轻量级虚机的形式创建容器的运行时工具，Kata Containers 创建的不同容器跑在一个个不同的虚拟机（kernel）上，比起传统容器提供了更好的隔离性和安全性。同时继承了容器快速启动和快速部署等优点。

Kata Containers 整合了 Intel 的 Clear Containers 和 Hyper.sh 的 runV，能够支持不同平台的硬件 (x86-64、arm等)。Kata Containers 符合 OCI (Open Container Initiative) 规范，同时还可以兼容 K8S 的 CRI (Container Runtime Interface) 接口规范。

![](https://www.hi-linux.com/img/linux/kata1.png)

官网地址：https://katacontainers.io/

<!-- more -->

### Kata Containers 架构图

如果大家了解 Docker 技术，就会知道真正启动 Docker 容器的命令工具是 RunC，它是 OCI 运行时规范 (runtime-spec) 的默认实现。

Kata Containers 其实跟 RunC 类似，也是一个符合 OCI 运行时规范的一种实现。不同之处是它给每个 Docker 容器或每个 K8S Pod 增加了一个独立的 Linux 内核 (不共享宿主机的内核)，使容器具有更好的隔离性、安全性。

![](https://www.hi-linux.com/img/linux/kata2.png)

![](https://www.hi-linux.com/img/linux/kata3.png)

### Kata Containers 组件及其功能介绍

Kata Containers 项目目前包含 Runtime、Agent、Proxy、Shim、Kernel等配套组件。目前 Kata Containers 的运行时还没有整合，即 Clear Containers 和 runV 还在独立的组织内。

- Runtime：符合 OCI 规范的容器运行时命令工具，主要用来创建轻量级虚机并通过 Agent 控制虚拟机内容器的生命周期。目前 Kata Containers 还没有一个统一的运行时工具，用户可以选择 Clear Containers 和 runV 中的其中之一。 

- Agent：运行在虚机中的一个运行时代理组件，主要用来执行 Runtime 传给它的指令并在虚机内管理容器的生命周期。 

- Shim：以对接 Docker 为例，这里的 Shim 相当于是 Containerd-Shim 的一个适配，用来处理容器进程的 stdio 和 signals。Shim 可以将 Containerd-Shim 发来的数据流（如：stdin）传给Proxy，然后转交给 Agent。也可以将 Agent 经由 Proxy 发过来的数据流（stdout/stderr）传给 Containerd-Shim，同时也可以传给 Signal 。

- Proxy：主要用来为 Runtime 和 Shim 分配访问 Agent 的控制通道，以及路由 Shim 实例和 Agent 之间的 I/O 数据流。 

- Kernel：Kernel 比较好理解，就是提供一个轻量化虚拟机的 Linux 内核。根据不同的需要提供几个内核选择，最小的内核仅有 4M 多。 

下图为 Kata Containers 各组件之间的关系图：

![](https://www.hi-linux.com/img/linux/kata4.png)

###  Kata Containers 现状以及后续的计划

Kata Containers 项目刚起步，还没有完整的一套组件供用户使用。只是提出了一套完整的架构，但是从架构中可以看到跟 Clear Containers 目前采用的架构基本一致。

在后续的计划中，Kata Containers 将分为三步来实现 Clear Containers 和 RunV 两个项目的融合： 

- 首先，在 Kata Containers 中兼容 Clear Containers 和 RunV 两个运行时。 整体采用 Kata Containers 的架构，Clear Containers 和 runV 两个运行时可以无缝对接 Kata Containers的其他组件，并保证用户可以在两个运行时之间来回切换。
- 其次，将 Clear Containers 和 runV 合并为一个，形成 Kata Containers 自己的 Runtime。
- 最后，废除 Clear Containers 和 runV 的兼容。

### 参考文档

https://www.google.com
http://t.cn/R3p3BuT
http://t.cn/R3pgpjY