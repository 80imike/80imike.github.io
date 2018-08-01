---
category: Kubernetes
title: 浅析从外部访问 Kubernetes 集群中应用的几种方式
date: 2018-07-20 09:00:00
tags: [Linux, Kubernetes]
abbrlink:
updated:
toc_number: false
---

一般情况下，Kubernetes 的 Cluster Network 是属于私有网络，只能在 Cluster Network 内部才能访问部署的应用。那么如何才能将 Kubernetes 集群中的应用暴露到外部网络，为外部用户提供服务呢？本文就来讲一讲从外部网络访问 Kubernetes Cluster 中 Pod 和 Serivce 的几种常用的实现方式。

### Pod 和 Service 的关系

我们首先来了解一下 Kubernetes 中的 Pod 和 Service 的概念以及两者间的关系。

Pod (容器组)，英文中 Pod 是豆荚的意思。从名字的含义可以看出，Pod 是一组有依赖关系的容器。Pod 是 Kubernetes 集群中最基本的资源对象，每个 Pod 由一个或多个业务容器和一个根容器 (Pause 容器) 组成。

Kubernetes 为每个 Pod 分配了唯一的 IP（即：Pod IP），Pod 里的多个容器共享这个 IP。Pod 内的容器除了 IP，还共享相同的网络命名空间、端口、存储卷等，也就是说这些容器之间能通过 Localhost 来通信。Pod 包含的容器都会运行在同一个节点上，也可以同时启动多个相同的 Pod 用于 Failover 或者 Load balance。

Pod 的生命周期是短暂的，Kubernetes 会根据应用的配置对 Pod 进行创建、销毁并根据监控指标进行伸缩扩容。Kubernetes 在创建 Pod 时可以选择集群中的任何一台空闲的节点上进行，因此其网络地址是不固定的。由于 Pod 的这一特点，一般不建议直接通过 Pod 的地址去访问应用。

为了解决访问 Pod 不方便直接访问的问题，Kubernetes 采用了 Service 对 Pod 进行封装。Service 是对后端提供服务的一组 Pod 的抽象，Service 会绑定到一个固定的虚拟 IP上。该虚拟 IP 只在 Kubernetes Cluster 中可见，但其实该虚拟 IP 并不对应一个虚拟或者物理设备，而只是 IPtables 中的规则，然后再通过 IPtables 将服务请求路由到后端的 Pod 中。通过这种方式，可以确保服务消费者可以稳定地访问 Pod 提供的服务，而不用关心 Pod 的创建、删除、迁移等变化以及如何用一组 Pod 来进行负载均衡。

<!-- more -->

实现 Service 这一功能的关键是由 Kubernetes 中的 Kube-Proxy 来完成的。Kube-Proxy 运行在每个节点上，监听 API Server 中服务对象的变化，再通过管理 IPtables 来实现网络的转发。Kube-Proxy 目前支持三种模式：UserSpace、IPtables、IPVS。下面我们来说说这几种模式的异同：

- UserSpace

UserSpace 是让 Kube-Proxy 在用户空间监听一个端口，所有的 Service 都转发到这个端口，然后 Kube-Proxy 在内部应用层对其进行转发。

![](https://www.hi-linux.com/img/linux/k8s-svc1.png)

Kube-Proxy 会为每个 Service 随机监听一个端口 (Proxy Port)，并增加一条 IPtables 规则。从客户端到 ClusterIP:Port 的报文都会被重定向到 Proxy Port，Kube-Proxy 收到报文后，通过 Round Robin (轮询) 或者 Session Affinity（会话亲和力，即同一 Client IP 都走同一链路给同一 Pod 服务）分发给对应的 Pod。

这种方式最大的缺点显然就是 UserSpace 会造成所有报文都走一遍用户态，造成整体性能下降，这种方在 Kubernetes 1.2 以后已经不再使用了。

- IPtables

IPtables 方式完全由 IPtables 来实现，这种方式直接使用 IPtables 来做用户态入口，而真正提供服务的是内核的 Netilter。Kube-Proxy 只作为 Controller，这也是目前默认的方式。

Kube-Proxy 的 IPtables 方式也是支持 Round Robin 和 Session Affinity 特性。

![](https://www.hi-linux.com/img/linux/k8s-svc2.png)

Kube-Proxy 监听 Kubernetes Master 增加和删除 Service 以及 Endpoint 的消息。对于每一个 Service，Kube Proxy 创建相应的 IPtables 规则，并将发送到 Service Cluster IP 的流量转发到 Service 后端提供服务的 Pod 的相应端口上。 

> 注：虽然可以通过 Service 的 Cluster IP 和服务端口访问到后端 Pod 提供的服务，但该 Cluster IP 是 Ping 不通的。其原因是 Cluster IP 只是 IPtables 中的规则，并不对应到一个任何网络设备。IPVS 模式的 Cluster IP 是可以 Ping 通的。

- IPVS

Kubernetes 从 1.8 开始增加了 IPVS 支持，IPVS 相对 IPtables 效率会更高一些。使用 IPVS 模式需要在运行 Kube-Proxy 的节点上安装 `ipvsadm`、`ipset` 工具包和加载 `ip_vs` 内核模块。

当 Kube-Proxy 以 IPVS 代理模式启动时，Kube-Proxy 将验证节点上是否安装了 IPVS 模块，如果未安装，则 Kube-Proxy 将回退到 IPtables 代理模式。

![](https://www.hi-linux.com/img/linux/k8s-svc3.png)

这种模式，Kube-Proxy 会监视 Kubernetes Service 对象 和 Endpoints，调用 Netlink 接口以相应地创建 IPVS 规则并定期与 Kubernetes Service 对象 和 Endpoints 对象同步 IPVS 规则，以确保 IPVS 状态与期望一致。访问服务时，流量将被重定向到其中一个后端 Pod。

与 IPtables 类似，IPVS 基于 Netfilter 的 Hook 功能，但使用哈希表作为底层数据结构并在内核空间中工作。这意味着 IPVS 可以更快地重定向流量，并且在同步代理规则时具有更好的性能。此外，IPVS 为负载均衡算法提供了更多选项，例如：rr (轮询调度)、lc (最小连接数)、dh (目标哈希)、sh (源哈希)、sed (最短期望延迟)、nq(不排队调度)等。

> 注：IPVS 是 LVS 项目的一部分，是一款运行在 Linux Kernel 当中的 4 层负载均衡器，性能异常优秀。使用调优后的内核，可以轻松处理每秒 10 万次以上的转发请求。目前在中大型互联网项目中，IPVS 被广泛的用于承接网站入口处的流量。

了解完 Pod 和 Service 的基本概念后，我们就来具体讲一讲从外部网络访问 Kubernetes Cluster 中 Pod 和 Serivce 的几种常见的实现方式。目前主要包括如下几种：

- hostNetwork
- hostPort
- ClusterIP
- NodePort
- LoadBalancer
- Ingress

### 通过 Pod 暴露

#### hostNetwork: true

这是一种直接定义 Pod 网络的方式。

如果在 Pod 中使用 `hostNetwork:true` 配置的话，在这种 Pod 中运行的应用程序可以直接看到启动 Pod 主机的网络接口。在主机的所有网络接口上都可以访问到该应用程序，以下是使用主机网络的 Pod 的示例定义：

```
apiVersion: v1
kind: Pod
metadata:
  name: nginx-hostnetwork
spec:
  hostNetwork: true
  containers:
    - name: nginx-hostnetwork
      image: nginx:1.7.9
```

部署该 Pod：

```
$ kubectl create  -f nginx-hostnetwork.yml
pod "nginx-hostnetwork" created
```

访问该 Pod 所在主机的 80 端口：

```
$ curl http://$HOST_IP:80
......
<title>Welcome to nginx!</title>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>
......
```

将看到 Nginx 默认的欢迎页面，说明可以正常访问。

注意：每次启动这个 Pod 的时候都可能被调度到不同的节点上，这样所有外部访问 Pod 所在节点主机的 IP 也就是不固定的，而且调度 Pod 的时候还需要考虑是否与宿主机上的端口冲突，因此一般情况下除非您知道需要某个特定应用占用特定宿主机上的特定端口时才使用 `hostNetwork: true` 的方式。

这种 Pod 的网络模式有一个用处就是可以将网络插件包装在 Pod 中，然后部署在每个宿主机上，这样该 Pod 就可以控制该宿主机上的所有网络。

#### hostPort

这也是一种直接定义 Pod 网络的方式。

`hostPort` 是直接将容器的端口与所调度的节点上的端口路由，这样用户就可以通过宿主机的IP加上 `<hostPort>` 来访问 Pod 了，如: `<hostIP>:<hostPort>`。

```
apiVersion: v1
kind: Pod
metadata:
  name: nginx-hostport
spec:
  containers:
    - name: nginx-hostport
      image: nginx:1.7.9
      ports:
        - containerPort: 80
          hostPort: 8088
```

部署该 Pod：

```
$ kubectl create  -f nginx-hostport.yml
pod "nginx-hostport" created
```

访问该 Pod 所在主机的 8088 端口：

```
$ curl http://$HOST_IP:8088
......
<title>Welcome to nginx!</title>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>
......
```

将看到 Nginx 默认的欢迎页面，说明可以正常访问。

这种方式和 `hostNetwork: true` 有同一个缺点，因为 Pod 重新调度的时候该 Pod 被调度到的宿主机可能会变动，这样 `<hostIP>` 就变化了，用户必须自己维护一个 Pod 与所在宿主机的对应关系。

这种网络方式可以用来做 `Ingress Controller`，外部流量都需要通过 Kubenretes 节点宿主机的 80 和 443 端口。

#### Port Forward

这是一种通过 `kubectl port-forward` 指令来实现数据转发的方法。`kubectl port-forward` 命令可以为 Pod 设置端口转发，通过在本机指定监听端口，访问这些端口的请求将会被转发到 Pod 的容器中对应的端口上。

首先，我们来看下 Kubernetes Port Forward 这种方式的工作机制：

![](https://www.hi-linux.com/img/linux/k8s-svc4.png)

使用 Kubectl 创建 Port Forward 后，Kubectl 会主动监听指定的本地端口。

```
$ kubectl port-forward pod-name local-port:container-port
```

当向 Local-Port 建立端口连接并向该端口发送数据时，数据流向会经过以下步骤：

- 数据发往 Kubctl 监听的 Local-Port。
- Kubectl 通过 SPDY 协议将数据发送给 ApiServer。
- ApiServer 与目标节点的 Kubelet 建立连接，并通过 SPDY 协议将数据发送到目标 Pod 的端口上。
- 目标节点的 Kubelet 收到数据后，通过 PIPE（STDIN、STDOUT）与 Socat 通信。
- Socat 将 STDIN 的数据发送给 Pod 内部指定的容器端口，并将返回的数据写入到 STDOUT。
- STDOUT 的数据由 Kubelet 接收并按照相反的路径发送回去。

> 注：SPDY 协议将来可能会被替换为 HTTP/2。

接下来，我们用一个实例来演示如何将本地端口转发到 Pod 中的端口，这里以一个运行了 Nginx 的 Pod 为例： 

```
$ kubectl get pods
NAME                        READY     STATUS    RESTARTS   AGE
nginx                       1/1       Running   2          9d
```

验证 Nginx 服务器监听的端口：

```
$ kubectl get pods nginx --template='{{(index (index .spec.containers 0).ports 0).containerPort}}{{"\n"}}'
80
```

将节点上的 8900 端口转发到 Nginx Pod 的 80 端口：

```
# 执行 Kubectl port-forward 命令的时候需要指定 Pod 名称和端口转发规则。
$ kubectl port-forward nginx 8900:80
Forwarding from 127.0.0.1:8900 -> 80
Forwarding from [::1]:8900 -> 80
```

> 注：需要在所有 Kubernetes 节点上都需要安装 Socat，关于 Socat 更详细介绍可参考：「[Socat 入门教程](https://mp.weixin.qq.com/s?__biz=MzI3MTI2NzkxMA==&mid=2247485897&idx=1&sn=555846ff170ac7799dde353271c06f98&chksm=eac528e0ddb2a1f674ca4f9e99325fbccf26589a76b43594558eeb83ef5f65b64f84a116974c&mpshare=1&scene=23&srcid=0719C3Onveftz5JQH2g6NLTO%23rd)」 。

验证转发是否成功：

```
$ curl http://127.0.0.1:8900
......
<title>Welcome to nginx!</title>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>
......
```

由于这种类型的转发端口是绑定在本地的，这种方式也仅适用于调试服务。

### 通过 Service 暴露

Service 的类型 ( ServiceType ) 决定了 Service 如何对外提供服务。根据类型不同服务可以只在 Kubernetes Cluster 中可见，也可以暴露到 Cluster 外部。Service 目前有三种类型：ClusterIP、NodePort 和 LoadBalancer。

![](https://www.hi-linux.com/img/linux/k8s-svc5.png)

Service 中常见的三种端口的含义：

- port

Service 暴露在 Cluster IP 上的端口，也就是虚拟 IP 要绑定的端口。port 是提供给集群内部客户访问 Service 的入口。

- nodePort

nodePort 是 Kubernetes 提供给集群外部客户访问 Service 的入口。

- targetPort

targetPort 是 Pod 里容器的端口，从 port 和 nodePort 上进入的数据最终会经过 Kube-Proxy 流入到后端 Pod 里容器的端口。如果 targetPort 没有被显式声明，那么会默认转发到 Service 接受请求的端口（和 port 端口的值一样）。

总的来说，port 和 nodePort 都是 Service 的端口，前者暴露给集群内客户访问服务，后者暴露给集群外客户访问服务。从这两个端口到来的数据都需要经过反向代理 Kube-Proxy 流入后端 Pod 里容器的端口，从而到达 Pod 上的容器内。

#### ClusterIP

ClusterIP 是 Service 的缺省类型，这种类型的服务会自动分配一个只能在集群内部可以访问的虚拟 IP，即：ClusterIP。ClusterIP 为你提供一个集群内部其它应用程序可以访问的服务，外部无法访问。ClusterIP 服务的 YAML 类似这样：

```
apiVersion: v1
kind: Service
metadata:  
  name: my-nginx
selector:    
  app: my-nginx
spec:
  type: ClusterIP
  ports:  
  - name: http
    port: 80
    targetPort: 80
    protocol: TCP
```

虽然我们从集群外部不能直接访问一个 ClusterIP 服务，但是你可以使用 Kubernetes Proxy API 来访问它。 

Kubernetes Proxy API 是一种特殊的 API，Kube-APIServer 只是代理这类 API 的 HTTP 请求，然后将请求转发到某个节点上的 Kubelet 进程监听的端口上。最后实际是由该端口上的 REST API 响应请求。

![](https://www.hi-linux.com/img/linux/k8s-svc6.png)

在 Master 节点上创建 Kubernetes API 的代理服务：

```
$ kubectl proxy --port=8080
```

`kubectl proxy` 默认是监听在 127.0.0.1 上的，如果你需要对外提供访问，可使用一些基本的安全机制。

```
$ kubectl proxy --port=8080 --address=192.168.100.211 --accept-hosts='^192\.168\.100\.*'
```

如果需要更多的命令使用帮助，可以使用 `kubectl help proxy`。

现在，你可以使用 Kubernetes Proxy API 进行访问。比如：需要访问一个服务，可以使用 `/api/v1/namespaces/<NAMESPACE>/services/<SERVICE-NAME>/proxy/`。

```
# 适用于 Kubernetes 1.10

$ kubectl get svc
NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)       AGE
kubernetes   ClusterIP   10.254.0.1       <none>        443/TCP       10d
my-nginx     ClusterIP   10.254.154.119   <none>        80/TCP        8d

$ curl http://192.168.100.211:8080/api/v1/namespaces/default/services/my-nginx/proxy/
......
<title>Welcome to nginx!</title>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>
......
```

如果你需要直接访问一个 Pod，可以使用 `/api/v1/namespaces/<NAMESPACE>/pods/<POD-NAME>/proxy/`。

```
# 适用于 Kubernetes 1.10

$ kubectl get pod
NAME                        READY     STATUS    RESTARTS   AGE
my-nginx-86555897f9-5p9c2   1/1       Running   2          8d
my-nginx-86555897f9-ws674   1/1       Running   6          8d

$ curl http://192.168.100.211:8080/api/v1/namespaces/default/pods/my-nginx-86555897f9-ws674/proxy/

......
<title>Welcome to nginx!</title>

<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>
......
```

由于访问 Kubernetes Proxy API 要求使用已授权用户运行 kubectl ，因此不应该使用此方法将你的服务公开到公网上或将其用于生产，这种方法主要还是用于调试服务。

#### NodePort

NodePort 在 Kubenretes 里是一个广泛应用的服务暴露方式。基于 ClusterIP 提供的功能，为 Service 在 Kubernetes 集群的每个节点上绑定一个端口，即 NodePort。集群外部可基于任何一个 `NodeIP:NodePort` 的形式来访问 Service。Service 在每个节点的 NodePort 端口上都是可用的。

![](https://www.hi-linux.com/img/linux/k8s-svc7.png)

NodePort 服务与默认的 ClusterIP 服务在 YAML 定义上有两点区别：首先，type 是 NodePort。其次还有一个称为 nodePort 的参数用来指定在节点上打开哪个端口。 如果你不指定这个端口，它会选择一个随机端口。

```
apiVersion: v1
kind: Pod
metadata:
  name: my-nginx
  labels:
    name: my-nginx
spec:
  containers:
    - name: my-nginx
      image: nginx:1.7.9
      ports:
        - containerPort: 80
```

`nodePort` 值的默认范围是 30000-32767，这个值是可以在 API Server 的配置文件中用 `--service-node-port-range` 来自定义。

```
kind: Service
apiVersion: v1
metadata:
  name: my-nginx
spec:
  type: NodePort
  ports:
    - port: 80
      targetPort: 80
      nodePort: 31000
  selector:
    name: my-nginx
```

NodePort 类型的服务会在所有的 Kubenretes 节点（运行有 Kube-Proxy 的节点）上统一暴露出一个端口对外提供服务，这样集群外就可以使用 Kubernetes 任意一个节点的 IP 加上指定端口（这里定义的是：31000）访问该服务了。Kube-Proxy 会自动将流量以 Round-Robin 的方式转发给该 Service 的每一个 Pod。

NodePort 类型的服务并不影响原来虚拟 IP 的访问方式，内部节点依然可以通过 `VIP:Port` 的方式进行访问。NodePort 这种服务暴露方式也存在一些不足：

- 节点上的每个端口只能有一个服务。
- 如果节点 IP 地址发生更改，则需要相应机制处理该问题。

基于以上原因，NodePort 比较适用的场景为演示程序或临时应用，不建议在生产环境中使用这种方法对外暴露服务。

#### LoadBalancer

LoadBalancer 是基于 NodePort 和云服务供应商提供的外部负载均衡器，通过这个外部负载均衡器将外部请求转发到各个 `NodeIP:NodePort` 以实现对外暴露服务。

![](https://www.hi-linux.com/img/linux/k8s-svc8.png)

`LoadBalancer` 只能在 Service 上定义。LoadBalancer 是一些特定公有云提供的负载均衡器，需要特定的云服务商支持。比如：AWS、Azure、OpenStack 和 GCE (Google Container Engine) 。

```
kind: Service
apiVersion: v1
metadata:
  name: my-nginx
spec:
  type: LoadBalancer
  ports:
    - port: 80
  selector:
    name: my-nginx
```

查看服务：

```
$ kubectl get svc my-nginx
NAME       CLUSTER-IP     EXTERNAL-IP     PORT(S)          AGE
my-nginx   10.97.121.42   10.13.242.236   8086:30051/TCP   39s
```
集群内部可以使用 ClusterIP 加端口来访问服务，如：10.97.121.42:8086。

外部可以用以下两种方式访问该服务：

- 使用任一节点的 IP 加 30051 端口访问该服务。
- 使用 `EXTERNAL-IP` 来访问，这是一个 VIP，是云供应商提供的负载均衡器 IP，如：10.13.242.236:8086。

LoadBalancer 这种方式最大的不足就是每个暴露的服务需要使用一个公有云提供的负载均衡器 IP，这可能会付出比较大的成本代价。

从上面几种 Service 的类型的结论来看，目前 Service 提供的负载均衡功能在使用上有以下限制：

- 只提供 4 层负载均衡，不支持 7 层负载均衡功能，比如：不能按需要的匹配规则自定义转发请求。
- 使用 NodePort 类型的 Service，需要在集群外部部署一个外部的负载均衡器。
- 使用 LoadBalancer 类型的 Service，Kubernetes 必须运行在特定的云服务上。

### 通过 Ingress 暴露

与 Service 不同，Ingress 实际上不是一种服务。相反，它位于多个服务之前，充当集群中的智能路由器或入口点。

`Ingress` 是自 Kubernetes 1.1 版本后引入的资源类型。Ingress 支持将 Service 暴露到 Kubernetes 集群外，同时可以自定义 Service 的访问策略。Ingress 能够把 Service 配置成外网能够访问的 URL，也支持提供按域名访问的虚拟主机功能。例如，通过负载均衡器实现不同的二级域名到不同 Service 的访问。

![](https://www.hi-linux.com/img/linux/k8s-svc9.png)

实际上 `Ingress` 只是一个统称，其由 `Ingress` 和 `Ingress Controller` 两部分组成。`Ingress` 用作将原来需要手动配置的规则抽象成一个 Ingress 对象，使用 YAML 格式的文件来创建和管理。`Ingress Controller` 用作通过与 Kubernetes API 交互，动态的去感知集群中 Ingress 规则变化。

使用 `Ingress` 前必须要先部署 `Ingress Controller`，`Ingress Controller` 是以一种插件的形式提供。`Ingress Controller` 通常是部署在 Kubernetes 之上的 Docker 容器，`Ingress Controller` 的 Docker 镜像里包含一个像 Nginx 或 HAProxy 的负载均衡器和一个 `Ingress Controller`。`Ingress Controller` 会从 Kubernetes 接收所需的 `Ingress` 配置，然后动态生成一个 Nginx 或 HAProxy 配置文件，并重新启动负载均衡器进程以使更改生效。换句话说，`Ingress Controller` 是由 Kubernetes 管理的负载均衡器。

> 注：无论使用何种负载均衡软件（ 比如：Nginx、HAProxy、Traefik等）来实现 Ingress Controller，官方都将其统称为 Ingress Controller。

Kubernetes Ingress 提供了负载均衡器的典型特性：HTTP 路由、粘性会话、SSL 终止、SSL直通、TCP 和 UDP 负载平衡等。

```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: nginx-ingress
spec:
  backend:
    serviceName: my-nginx-other
    servicePort: 8080
  rules:
  - host: foo.mydomain.com
    http:
      paths:
      - backend:
          serviceName: my-nginx-foo
          servicePort: 8080
  - host: mydomain.com
    http:
      paths:
      - path: /bar/*
        backend:
          serviceName: my-nginx-bar
          servicePort: 8080
```

外部可通过 `foo.yourdomain.com` 或者 `mydomain.com/bar/` 两个不同 URL 来访问对应的后端服务，然后 `Ingress Controller` 直接将流量转发给后端 Pod，不需再经过 Kube-Proxy 的转发，这种方式比 LoadBalancer 更高效。

总的来说 Ingress 是一个非常灵活和越来越得到厂商支持的服务暴露方式，包括：Nginx、HAProxy、Traefik、还有各种 Service Mesh，而其它服务暴露方式更适用于服务调试、特殊应用的部署。

### 参考文档

http://www.google.com
http://t.cn/RdskHHt
http://t.cn/RdskYv5
http://t.cn/Rg5BG4h
http://t.cn/R6CD4ak
http://t.cn/Rgcurto
http://t.cn/RgcdjDw
http://t.cn/RgMWBpo
http://t.cn/RgMWFM1
http://t.cn/RgC3uk8