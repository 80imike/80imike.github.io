
---
category: docker
title: 使用Kubeadm快速部署Kubernetes
date: 2017-03-23 09:00:00
tags: [linux, docker]
abbrlink:
updated:
toc_number: false
---

### Kubernetes是什么？

Kubernetes是Google开源的基于Docker的容器集群管理系统，是谷歌内部大规模集群管理系统Borg的开源版本。Kubernetes基于Borg集群软件模型，其诱人之处在于该模型经过了Google庞大数据中心的校验。

Kubernetes(K8s)是一个真正的平台，提供运行环境，使得复杂要求的应用在上面构建。它通过yaml语言写的配置文件，很简单快速的就能自动通过Docker镜像部署好应用环境，支持应用横向扩展，并且可以组织、编排、管理和迁移这些容器化的应用。

本文主要介绍在Ubuntu 16.04上使用kubeadm搭建一个集群环境。

<!-- more -->

**Kubernetes架构**

![](https://www.hi-linux.com/img/linux/k8s_01.jpg)

**Kubernetes地位**

![](https://www.hi-linux.com/img/linux/k8s_02.png)


K8s的地位如上图所示，优点是有很好的可移植性和可扩展性。关于K8s，这两个重要的性质表现在：

- 可移植性：K8s可以搭建在阿里云、Amazon、Microsoft Azure、Google Cloud上，也可以搭建在任何的公有云和私有云上。


- 可扩展性：K8s在GitHub上托管，截至2017年3月1日有来自全球的1100名贡献者，为它提供了Dashboard、网络构件等扩展工具。


**Kubernetes的核心组件**

Kubernetes将集群中的机器分为一个Master节点和一组Node节点。从kubernetes 1.4开始，各个核心组件也是以容器形式运行在Master的node上。

其中Master节点上运行`kube-apiserver`,`kube-controller-manager`,`kube-scheduler`，这些容器负责整个集群的资源管理、Pod调度、安全控制、弹性伸缩和系统监控。Node节点是集群中的工作节点，运行真正的服务。

Pod是Node节点上的基本单元。Node节点上运行着kubelet进程，还有kube-proxy容器，它们负责Pod的创建、启动、监控、重启、销毁，同时实现负载均衡器。真正需要运行的服务被包装到对应的Pod中，成为Pod中运行的一个容器。

> Kubernetes官网: https://kubernetes.io/
> Kubernetes中文社区: https://www.kubernetes.org.cn/


### 前期环境准备与约束

准备了两台Ubuntu 16.04虚拟机，各项参数如下：

节点机器名|IP地址|CPU|内存
--|---|---|--
dev-master-01|10.211.55.11|2核|2GB
dev-node-01|10.211.55.12|2核|1GB

Kubernetes官网上提到每台机器至少要有1GB内存，不然集群运行之后，留给运行在容器内的应用的内存就很少了。同时要保证所有机器之前的网络是互相连通的。

### 部署Kubernetes Master

安装内容包括:

- docker：容器运行的软件。
- kubelet：kubelet是Kubernets最重要的组件，它要运行在集群上所有的机器，用来执行类似于开启pods和容器。
- kubectl：在集群运行时，控制容器的部件。只需要将其运行在主节点上，但是它将对所有节点都有效。
- Kubeadm：集群的引导程序。

#### 安装Kubernetes相关软件包

由于墙的原因无法直接访问到Google的软件仓库(packages.cloud.google.com)和容器仓库(gcr.io)，解决方法有两种：一是直接配置的Hosts文件，二是使用三方源或转存的容器仓库。这里使用修改Hosts文件的方法。

把下面几行内容加入到hosts文件中


```
$ vim  /etc/hosts

61.91.161.217 gcr.io
61.91.161.217 www.gcr.io
61.91.161.217 packages.cloud.google.com
```

最新可用的Google hosts文件可在这里获取：https://github.com/racaljk/hosts

- 安装kubernetes相关软件包

```
$ curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
$ cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
$ apt-get update
$ apt-get install -y kubelet kubeadm kubectl kubernetes-cni
```

- 安装Docker

直接通过安装脚本一键安装Docker

```
$ curl -sSL http://acs-public-mirror.oss-cn-hangzhou.aliyuncs.com/docker-engine/internet | sh -
```

- 清除可能与kubernetes冲突的设置

关闭 SELinux

```
$ apt install -y selinux-utils
$ setenforce 0
```

清除iptables

避免自定义iptables影响kubernetes服务工作，建议自定义需求通过kubernetes实现。如果满足不了，安装好kubernetes后，再配置自定义iptables。

```
$ iptables -t filter -F
$ iptables -t nat -F
$ iptables -t mangle -F
```

- 准备镜像

下载docker镜像

由于墙的原因，从Google下载相关镜像速度很慢。为了更加顺利的搭建集群，建议优先下载好相应镜像。

Kubernetes-1.5.2所需要的镜像：


```
$ docker pull gcr.io/google_containers/kube-apiserver-amd64:v1.5.4
$ docker pull gcr.io/google_containers/kube-controller-manager-amd64:v1.5.4
$ docker pull gcr.io/google_containers/kube-scheduler-amd64:v1.5.4              
$ docker pull gcr.io/google_containers/kube-proxy-amd64:v1.5.4              
$ docker pull gcr.io/google_containers/kube-apiserver-amd64:v1.5.2              
$ docker pull gcr.io/google_containers/kube-scheduler-amd64:v1.5.2              
$ docker pull gcr.io/google_containers/kube-controller-manager-amd64:v1.5.2
$ docker pull gcr.io/google_containers/etcd-amd64:3.0.14-kubeadm      
$ docker pull gcr.io/google_containers/kubedns-amd64:1.9                 
$ docker pull gcr.io/google_containers/dnsmasq-metrics-amd64:1.0                 
$ docker pull gcr.io/google_containers/kube-dnsmasq-amd64:1.4                 
$ docker pull gcr.io/google_containers/kube-discovery-amd64:1.0                 
$ docker pull gcr.io/google_containers/exechealthz-amd64:1.2                 
$ docker pull gcr.io/google_containers/pause-amd6:3.0                 
$ docker pull gcr.io/google_containers/kubernetes-dashboard-amd64:v1.6.0
$ docker pull quay.io/coreos/flannel:v0.7.0-amd64    
```

#### 部署Kubernetes master

理论上通过kubeadm使用init和join命令即可建立一个集群，这init就是在master节点对集群进行初始化。和k8s 1.4之前的部署方式不同的是kubeadm安装的k8s核心组件都是以容器的形式运行于master node上的。

**初始化master**

使用kubeadm init初始化kubernetes master。


```
$ kubeadm init --use-kubernetes-version=v1.5.2 --pod-network-cidr=10.244.0.0/16
```

说明：kubeadm init并没有为你选择一个默认的Pod network进行安装。这里使用flannel作为Pod network。那么在执行init时，我们必须给init命令带上`--pod-network-cidr=10.244.0.0/16`。

如果有多网卡的，请根据实际情况配置`--api-advertise-addresses=<ip-address>`，单网卡情况可以省略。

```
$ kubeadm init --use-kubernetes-version=v1.5.2 --pod-network-cidr=10.244.0.0/16 --api-advertise-addresses=10.211.55.11
```

实测中发现kubeadm暂时还不支持docker 17.03.0-ce版本，会报以下错误：

```
$ kubeadm init --pod-network-cidr=10.244.0.0/16
[kubeadm] WARNING: kubeadm is in alpha, please do not use it for production clusters.
[preflight] Running pre-flight checks
[preflight] The system verification failed. Printing the output from the verification:
OS: Linux
KERNEL_VERSION: 4.4.0-62-generic
CONFIG_NAMESPACES: enabled
CONFIG_NET_NS: enabled
CONFIG_PID_NS: enabled
CONFIG_IPC_NS: enabled
CONFIG_UTS_NS: enabled
CONFIG_CGROUPS: enabled
CONFIG_CGROUP_CPUACCT: enabled
CONFIG_CGROUP_DEVICE: enabled
CONFIG_CGROUP_FREEZER: enabled
CONFIG_CGROUP_SCHED: enabled
CONFIG_CPUSETS: enabled
CONFIG_MEMCG: enabled
CONFIG_INET: enabled
CONFIG_EXT4_FS: enabled
CONFIG_PROC_FS: enabled
CONFIG_NETFILTER_XT_TARGET_REDIRECT: enabled (as module)
CONFIG_NETFILTER_XT_MATCH_COMMENT: enabled (as module)
CONFIG_OVERLAY_FS: enabled (as module)
CONFIG_AUFS_FS: enabled (as module)
CONFIG_BLK_DEV_DM: enabled
CGROUPS_CPU: enabled
CGROUPS_CPUACCT: enabled
CGROUPS_CPUSET: enabled
CGROUPS_DEVICES: enabled
CGROUPS_FREEZER: enabled
CGROUPS_MEMORY: enabled
DOCKER_VERSION: 17.03.0-ce
[preflight] Some fatal errors occurred:
	unsupported docker version: 17.03.0-ce
[preflight] If you know what you are doing, you can skip pre-flight checks with `--skip-preflight-checks`
```

根据提示加上`--skip-preflight-checks`参数后，继续初始化master。

```
$ kubeadm init --pod-network-cidr=10.244.0.0/16 --skip-preflight-checks
[kubeadm] WARNING: kubeadm is in alpha, please do not use it for production clusters.
[preflight] Skipping pre-flight checks
[preflight] Starting the kubelet service
[init] Using Kubernetes version: v1.5.4
[tokens] Generated token: "e4f68e.6cc8c11c93148cd7"
[certificates] Generated Certificate Authority key and certificate.
[certificates] Generated API Server key and certificate
[certificates] Generated Service Account signing keys
[certificates] Created keys and certificates in "/etc/kubernetes/pki"
[kubeconfig] Wrote KubeConfig file to disk: "/etc/kubernetes/admin.conf"
[kubeconfig] Wrote KubeConfig file to disk: "/etc/kubernetes/kubelet.conf"
[apiclient] Created API client, waiting for the control plane to become ready
[apiclient] All control plane components are healthy after 62.298779 seconds
[apiclient] Waiting for at least one node to register and become ready
[apiclient] First node is ready after 0.508216 seconds
[apiclient] Creating a test deployment
[apiclient] Test deployment succeeded
[token-discovery] Created the kube-discovery deployment, waiting for it to become ready
[token-discovery] kube-discovery is ready after 23.003368 seconds
[addons] Created essential addon: kube-proxy
[addons] Created essential addon: kube-dns

Your Kubernetes master has initialized successfully!

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
    http://kubernetes.io/docs/admin/addons/

You can now join any number of machines by running the following on each node:

kubeadm join --token=e4f68e.6cc8c11c93148cd7 10.211.55.11
```

初始化成功后，检查Kubernetes的核心组件均正常启动。

```
$ ps axu|grep kube
root      2641 10.6  3.8 442928 79672 ?        Ssl  11:39  11:25 /usr/bin/kubelet --kubeconfig=/etc/kubernetes/kubelet.conf --require-kubeconfig=true --pod-manifest-path=/etc/kubernetes/manifests --allow-privileged=true --network-plugin=cni --cni-conf-dir=/etc/cni/net.d --cni-bin-dir=/opt/cni/bin --cluster-dns=10.96.0.10 --cluster-domain=cluster.local
root      2917  0.1  1.3  41268 28316 ?        Ssl  11:40   0:09 kube-scheduler --address=127.0.0.1 --leader-elect --master=127.0.0.1:8080
root      2961  1.2  7.4 187696 151428 ?       Ssl  11:40   1:18 kube-apiserver --insecure-bind-address=127.0.0.1 --admission-control=NamespaceLifecycle,LimitRanger,ServiceAccount,PersistentVolumeLabel,DefaultStorageClass,ResourceQuota --service-cluster-ip-range=10.96.0.0/12 --service-account-key-file=/etc/kubernetes/pki/apiserver-key.pem --client-ca-file=/etc/kubernetes/pki/ca.pem --tls-cert-file=/etc/kubernetes/pki/apiserver.pem --tls-private-key-file=/etc/kubernetes/pki/apiserver-key.pem --token-auth-file=/etc/kubernetes/pki/tokens.csv --secure-port=6443 --allow-privileged --advertise-address=10.211.55.11 --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname --anonymous-auth=false --etcd-servers=http://127.0.0.1:2379
root      3810  1.5  3.0  87448 62936 ?        Ssl  11:56   1:22 kube-controller-manager --address=127.0.0.1 --leader-elect --master=127.0.0.1:8080 --cluster-name=kubernetes --root-ca-file=/etc/kubernetes/pki/ca.pem --service-account-private-key-file=/etc/kubernetes/pki/apiserver-key.pem --cluster-signing-cert-file=/etc/kubernetes/pki/ca.pem --cluster-signing-key-file=/etc/kubernetes/pki/ca-key.pem --insecure-experimental-approve-all-kubelet-csrs-for-group=system:kubelet-bootstrap --allocate-node-cidrs=true --cluster-cidr=10.244.0.0/16
root      4018  0.0  0.2   8136  5412 ?        Ssl  11:56   0:00 /usr/local/bin/kube-discovery
root      5397  0.1  1.3  37788 28504 ?        Ssl  11:56   0:06 kube-proxy --kubeconfig=/run/kubeconfig
root     14658  0.0  0.0  14224   880 pts/0    S+   13:26   0:00 grep --color=auto kube
```

以容器方式启动的各个组件

```
$ docker ps
CONTAINER ID        IMAGE                                                           COMMAND                  CREATED             STATUS              PORTS               NAMES
fe8cb027820d        gcr.io/google_containers/kube-proxy-amd64:v1.5.4                "kube-proxy --kube..."   About an hour ago   Up About an hour                        k8s_kube-proxy.f7c0b53a_kube-proxy-hz20c_kube-system_61d0bb98-0dea-11e7-bc5c-001c4297532a_f9cc7706
9cd5828d28a3        gcr.io/google_containers/pause-amd64:3.0                        "/pause"                 About an hour ago   Up About an hour                        k8s_POD.d8dbe16c_kube-proxy-hz20c_kube-system_61d0bb98-0dea-11e7-bc5c-001c4297532a_28af414a
60b8f173f012        gcr.io/google_containers/kube-discovery-amd64:1.0               "/usr/local/bin/ku..."   About an hour ago   Up About an hour                        k8s_kube-discovery.3779cb59_kube-discovery-1769846148-kqb1x_kube-system_5419f72e-0dea-11e7-bc5c-001c4297532a_463dc1ad
19d3bf10369d        gcr.io/google_containers/pause-amd64:3.0                        "/pause"                 About an hour ago   Up About an hour                        k8s_POD.d8dbe16c_kube-discovery-1769846148-kqb1x_kube-system_5419f72e-0dea-11e7-bc5c-001c4297532a_2c04d6c8
8d65a04af9bd        gcr.io/google_containers/pause-amd64:3.0                        "/pause"                 About an hour ago   Up About an hour                        k8s_dummy.f0681c27_dummy-2088944543-ctnqh_kube-system_53801181-0dea-11e7-bc5c-001c4297532a_6058f6f7
e4680cf8734d        gcr.io/google_containers/pause-amd64:3.0                        "/pause"                 About an hour ago   Up About an hour                        k8s_POD.d8dbe16c_dummy-2088944543-ctnqh_kube-system_53801181-0dea-11e7-bc5c-001c4297532a_95e00970
6d0ef0103edc        gcr.io/google_containers/kube-controller-manager-amd64:v1.5.4   "kube-controller-m..."   About an hour ago   Up About an hour                        k8s_kube-controller-manager.9a35b2e8_kube-controller-manager-dev-master-01_kube-system_04aa781520126ecd226bff8cb5e8f11a_0eef3909
f592f0cd853d        gcr.io/google_containers/kube-apiserver-amd64:v1.5.4            "kube-apiserver --..."   About an hour ago   Up About an hour                        k8s_kube-apiserver.3d6f374_kube-apiserver-dev-master-01_kube-system_c7b047fbcc13d76494cea24a2ad9a1ba_f1d0d4a1
08ced03e0141        gcr.io/google_containers/kube-scheduler-amd64:v1.5.4            "kube-scheduler --..."   About an hour ago   Up About an hour                        k8s_kube-scheduler.1a2dd753_kube-scheduler-dev-master-01_kube-system_1af062e8f950e8085a65134d9d314b76_537f210b
f5f1eb371488        gcr.io/google_containers/etcd-amd64:3.0.14-kubeadm              "etcd --listen-cli..."   About an hour ago   Up About an hour                        k8s_etcd.c323986f_etcd-dev-master-01_kube-system_3a26566bb004c61cd05382212e3f978f_3ffb0064
c43f82a7ef1c        gcr.io/google_containers/pause-amd64:3.0                        "/pause"                 About an hour ago   Up About an hour                        k8s_POD.d8dbe16c_kube-controller-manager-dev-master-01_kube-system_04aa781520126ecd226bff8cb5e8f11a_166b1b6a
e8aeabbf4beb        gcr.io/google_containers/pause-amd64:3.0                        "/pause"                 About an hour ago   Up About an hour                        k8s_POD.d8dbe16c_kube-apiserver-dev-master-01_kube-system_c7b047fbcc13d76494cea24a2ad9a1ba_993bfda3
6a7cbc9f0739        gcr.io/google_containers/pause-amd64:3.0                        "/pause"                 About an hour ago   Up About an hour                        k8s_POD.d8dbe16c_etcd-dev-master-01_kube-system_3a26566bb004c61cd05382212e3f978f_6f7d0263
1c2348c77a9b        gcr.io/google_containers/pause-amd64:3.0                        "/pause"                 About an hour ago   Up About an hour                        k8s_POD.d8dbe16c_kube-scheduler-dev-master-01_kube-system_1af062e8f950e8085a65134d9d314b76_e6907a26
```

不过这些核心组件并不是跑在pod network中的，而是采用了host network。

```
$ kubectl get pod  --all-namespaces -o wide

NAMESPACE     NAME                                    READY     STATUS              RESTARTS   AGE       IP             NODE
kube-system   dummy-2088944543-ctnqh                  1/1       Running             0          1h        10.211.55.11   dev-master-01
kube-system   etcd-dev-master-01                      1/1       Running             1          2h        10.211.55.11   dev-master-01
kube-system   kube-apiserver-dev-master-01            1/1       Running             0          2h        10.211.55.11   dev-master-01
kube-system   kube-controller-manager-dev-master-01   1/1       Running             0          2h        10.211.55.11   dev-master-01
kube-system   kube-discovery-1769846148-kqb1x         1/1       Running             0          1h        10.211.55.11   dev-master-01
kube-system   kube-dns-2924299975-8r4st               0/4       ContainerCreating   0          1h        <none>         dev-master-01
kube-system   kube-proxy-hz20c                        1/1       Running             0          1h        10.211.55.11   dev-master-01
kube-system   kube-scheduler-dev-master-01            1/1       Running             0          2h        10.211.55.11   dev-master-01
```

**安装flannel pod网络**

Kubernetes一共提供五种网络组件，可以根据自己的需要选择。要使用Flannel网络，因此我们需要执行如下安装命令：

```
$ kubectl apply -f  https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

serviceaccount "flannel" created
configmap "kube-flannel-cfg" created
daemonset "kube-flannel-ds" created
```

根据网络状况，安装过程需要一定的时间，最后要确保所有的Pod都处于Running状态。


稍等片刻，我们再来看master node上的cluster信息：

```
$ ps aux|grep kube|grep flannel
root       718  0.0  1.5 252216 32176 ?        Ssl  15:25   0:00 /opt/bin/flanneld --ip-masq --kube-subnet-mgr
root       758  0.0  0.0   8096  1880 ?        Ss   15:25   0:00 /bin/sh -c set -e -x; cp -f /etc/kube-flannel/cni-conf.json /etc/cni/net.d/10-flannel.conf; while true; do sleep 3600; done
```

检查各节点组件运行状态：

```
$ kubectl get pods --all-namespaces

NAMESPACE     NAME                                    READY     STATUS              RESTARTS   AGE
default       kube-flannel-ds-m556b                   2/2       Running             3          2h
kube-system   dummy-2088944543-ctnqh                  1/1       Running             1          3h
kube-system   etcd-dev-master-01                      1/1       Running             2          4h
kube-system   kube-apiserver-dev-master-01            1/1       Running             1          4h
kube-system   kube-controller-manager-dev-master-01   1/1       Running             1          4h
kube-system   kube-discovery-1769846148-cpf2m         1/1       Running             0          8m
kube-system   kube-dns-2924299975-8r4st               4/4       Running             0          3h
kube-system   kube-proxy-hz20c                        1/1       Running             1          3h
kube-system   kube-scheduler-dev-master-01            1/1       Running             1          4h
```

如果你非常想要知道它的状态及详细原因，对应你自己的NameSpace和Name把下面这条命令改一下，就可以看到详细信息了。常见的状态有RunContainerError,CrashLoopBackOff,ContainerCreating。

```
$ kubectl describe -n default  po kube-flannel-ds-m556b
$ kubectl describe -n kube-system po kube-dns-2924299975-8r4st
```

**验证是否部署成功**

```
$ kubectl get nodes
NAME            STATUS         AGE
dev-master-01   Ready,master   5h
```


或者访问http://localhost:8080出现这个也表示ok了。

```
$ curl http://127.0.0.1:8080
{
  "paths": [
    "/api",
    "/api/v1",
    "/apis",
    "/apis/apps",
    "/apis/apps/v1beta1",
    "/apis/authentication.k8s.io",
    "/apis/authentication.k8s.io/v1beta1",
    "/apis/authorization.k8s.io",
    "/apis/authorization.k8s.io/v1beta1",
    "/apis/autoscaling",
    "/apis/autoscaling/v1",
    "/apis/batch",
    "/apis/batch/v1",
    "/apis/batch/v2alpha1",
    "/apis/certificates.k8s.io",
    "/apis/certificates.k8s.io/v1alpha1",
    "/apis/extensions",
    "/apis/extensions/v1beta1",
    "/apis/policy",
    "/apis/policy/v1beta1",
    "/apis/rbac.authorization.k8s.io",
    "/apis/rbac.authorization.k8s.io/v1alpha1",
    "/apis/storage.k8s.io",
    "/apis/storage.k8s.io/v1beta1",
    "/healthz",
    "/healthz/poststarthook/bootstrap-controller",
    "/healthz/poststarthook/extensions/third-party-resources",
    "/healthz/poststarthook/rbac/bootstrap-roles",
    "/logs",
    "/metrics",
    "/swaggerapi/",
    "/ui/",
    "/version"
  ]
```

### 部署Kubernetes node

根据Master上初始化成功后会打印的token，把minion node加入cluster。（注意：这里要保证master node的9898端口在防火墙是打开的）

在minion node上执行

```
$ kubeadm join --token=e4f68e.6cc8c11c93148cd7 10.211.55.11 --skip-preflight-checks

[kubeadm] WARNING: kubeadm is in alpha, please do not use it for production clusters.
[preflight] Skipping pre-flight checks
[tokens] Validating provided token
[discovery] Created cluster info discovery client, requesting info from "http://10.211.55.11:9898/cluster-info/v1/?token-id=e4f68e"
[discovery] Cluster info object received, verifying signature using given token
[discovery] Cluster info signature and contents are valid, will use API endpoints [https://10.211.55.11:6443]
[bootstrap] Trying to connect to endpoint https://10.211.55.11:6443
[bootstrap] Detected server version: v1.5.4
[bootstrap] Successfully established connection with endpoint "https://10.211.55.11:6443"
[csr] Created API client to obtain unique certificate for this node, generating keys and certificate signing request
[csr] Received signed certificate from the API server:
Issuer: CN=kubernetes | Subject: CN=system:node:dev-node-01 | CA: false
Not before: 2017-03-21 09:19:00 +0000 UTC Not After: 2018-03-21 09:19:00 +0000 UTC
[csr] Generating kubelet configuration
[kubeconfig] Wrote KubeConfig file to disk: "/etc/kubernetes/kubelet.conf"

Node join complete:
* Certificate signing request sent to master and response
  received.
* Kubelet informed of new secure connection details.

Run 'kubectl get nodes' on the master to see this machine join.
```

**验证是否加入成功**

加入节点后，可以在master上验证下相关信息。

```
$ kubectl get nodes

NAME            STATUS         AGE
dev-master-01   Ready,master   5h
dev-node-01     Ready          1m
```

上述这样以来基础环境就搭好了。不过只不过是万里长征第一步，折腾才刚刚开始而已。颤抖吧，少年！

### 一些小技巧

- 由于使用kubeadm安装的kubernetes核心组件都是以docker容器的形式运行，如果安装过程出现问题，需要先执行下面的命令清理之前的执行残留后，才能重新开始。

kubeadm会自动检查当前环境是否有上次命令执行的“残留”。如果有，必须清理后再行执行init。我们可以通过”kubeadm reset”来清理环境，以备重来。

```
$ sudo kubeadm reset
[preflight] Running pre-flight checks
[reset] Stopping the kubelet service
[reset] Unmounting mounted directories in "/var/lib/kubelet"
[reset] Removing kubernetes-managed containers
[reset] Deleting contents of stateful directories: [/var/lib/kubelet /etc/cni/net.d /var/lib/etcd]
[reset] Deleting contents of config directories: [/etc/kubernetes/manifests /etc/kubernetes/pki]
[reset] Deleting files: [/etc/kubernetes/admin.conf /etc/kubernetes/kubelet.conf]
```

- 如果容器部署过程中失败，你非常想要知道它的状态及详细原因。可使用如下指令：

```
$ kubectl describe -n default  po kube-flannel-ds-m556b
$ kubectl describe -n kube-system po kube-dns-2924299975-8r4st
```


### 参考文档

http://www.google.com
http://t.cn/RIBS5ji
http://www.jianshu.com/p/a05a2f778324
http://www.jianshu.com/p/602c5bdbbd4d
http://blog.frognew.com/2017/01/install-kubernetes-with-kubeadm.html
https://jicki.me/2016/12/13/kubernetes-1.5.0/
