---
category: Nginx
title: Nginx 发布支持动态配置的开源 Web 服务器 Nginx Unit
date: 2018-05-11 09:00:00
tags: [Linux, Nginx]
abbrlink:
updated:
toc_number: false
---

Nginx 在 2018 年 4 月 12 时 发布了 Nginx Unit 1.0 正式版。下面我们就来看看 Nginx Unit 有些什么特性。

### 什么是 Nginx Unit

Nginx Unit 是一个开源的、以 Nginx 为基础的、支持多语言的动态 Web 应用服务器，它支持 Python、PHP、Perl、Ruby 和 Go 等多种语言应用程序，可以在不中断服务的情况下完成部署配置更改，并以多种语言运行代码。

Nginx Unit 是一个新的开源项目，由 Igor Sysoev 发起，他说："我想着手开发一款应用服务器，它能够远程动态配置，并且能够从一种语言的应用程序版本动态切换到另一种语言的应用程序。" Igor 认为动态配置和交换无疑是主要问题，人们希望在不中断客户端处理的情况下重新配置服务器。

Nginx Unit 使用 REST API 进行动态配置，它没有静态配置文件。所有配置更改直接在内存中发生，配置更改无需重新加载或服务中断即可生效。

<!-- more -->

![](https://www.hi-linux.com/img/linux/nginx-unit-01.png)

- Nginx Unit 还支持多语言版本，比如用户可以在同一台服务器上同时运行 PHP 5 和 PHP 7 编写的应用程序。未来的 Nginx Unit 版本计划支持包括 Java 在内的其他语言。

- Nginx Unit 可以根据需要启动和扩展应用程序的进程，并在自己的安全沙箱中执行每一个应用程序实例。

- Nginx Unit 通过一个单独的 "路由器" 进程管理和路由所有传入网络通信到应用程序，因此它可以在不中断服务的情况下快速实施配置的更改。

- Nginx Unit 的配置采用了 JSON 格式，因此用户可以手动编辑，而且非常适合脚本编写。

- Nginx Unit 支持多种语言运行时的能力是基于它内部的路由器进程之间的隔离，路由器进程可终止传入的 HTTP 请求，以及应用程序进程的分组，它实现了应用程序运行时并执行应用程序代码。

![](https://www.hi-linux.com/img/linux/nginx-unit-02.png)

路由器进程是持久的，它从不重新启动，意味着配置更新可以无缝地实现，而不会中断服务。每一个应用程序进程都部署在自己的沙箱中（在开发中支持 Linux 控制组 cgroups ），以便 Nginx Unit 为用户代码提供安全的隔离。

### Nginx Unit 下一步计划

Nginx Unit 工程团队在发布 1.0 之后的下一个里程碑的内容主要是 HTTP 成熟度、静态内容服务和其他语言的支持。

Igor 说:"我们计划在单元中添加 SSL 和 HTTP/2 功能，另外，我们计划在配置中支持路由。目前，我们有一个监听端口直接映射到一个应用程序，我们计划使用 URI 和 主机名 等添加路由。另外，我们希望为Unit 增加更多的语言支持，我们正在完成 Ruby 实现，接下来我们将考虑 Node.js 和 Java，Java 将以 Tomcat 兼容的方式添加。"

Nginx Unit 的最终目标是为分布式多语言应用程序创建一个开源平台，该应用程序可以安全、可靠地运行应用程序代码并以最佳的性能运行。该平台将自行管理，具有自动调节功能以满足资源约束条件下的 SLA，以及服务发现和内部负载平衡，以便轻松创建服务网格。

### Nginx Unit 和 Nginx 应用平台

Nginx Unit 平台通常会提供 Nginx 开源的前端层或 Nginx Plus 反向代理，以提供入口控制，边缘负载均衡和安全性。然后可以使用 Nginx 控制器对联合平台（Nginx Unit 和 Nginx 或 Nginx Plus）进行全面管理，以监控、配置和控制整个平台。

![](https://www.hi-linux.com/img/linux/nginx-unit-03.png)

这三个组件：Nginx Plus，Nginx Unit 和 Nginx Controller 组成了 Nginx 应用平台。Nginx 应用平台是一个产品套件，提供负载均衡、缓存、API管理、WAF和应用服务，并具有丰富的管理和控制面板，可简化单片应用、微服务和过渡应用的操作任务。

### 其它相关

如果你需要了解更多一些关于 Nginx Unit 的信息，可直接访问其官网网站：http://unit.nginx.org/

Nginx Unit 的安装部署也是非常简单的，官方文档也对如何在几大流行的 Linux 发行版本上进行部署做了详细讲解。具体可参考：http://unit.nginx.org/installation/

### 参考文档

http://www.google.com
http://t.cn/R3w4elX