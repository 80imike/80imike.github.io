---
category: docker
title: 基于DNS动态发现方式部署etcd集群
date: 2017-04-14 09:00:00
tags: [etcd, docker]
abbrlink:
updated:
toc_number: false
---

使用discovery的方式来搭建etcd集群方式有两种：`etcd discovery`和`DNS discovery`。在 「[基于已有集群动态发现方式部署etcd集群](https://www.hi-linux.com/posts/19457.html)」一文中讲解了`etcd discovery`这种方式，今天我们就来讲讲`DNS discovery`这种方式的实现。

etcd在基于DNS做服务发现时，实际上是利用DNS的SRV记录不断轮训查询实现的。`DNS SRV`是DNS数据库中支持的一种资源记录的类型，它记录了哪台计算机提供了哪个服务这么一个简单信息。

本文采用`dnsmasq`作为`dns`服务器，关于`dnsmasq`搭建可参考 「[利用Dnsmasq部署DNS服务](https://www.hi-linux.com/posts/30947.html)」。

<!-- more -->

**创建DNS记录**

- 增加DNS SRV记录

```
$ vim /etc/dnsmasq.conf

#增加内容如下

srv-host=_etcd-server._tcp.hi-linux.com,etcd1.hi-linux.com,2380,0,100
srv-host=_etcd-server._tcp.hi-linux.com,etcd2.hi-linux.com,2380,0,100
srv-host=_etcd-server._tcp.hi-linux.com,etcd3.hi-linux.com,2380,0,100
```

- 增加对应的域名解析

```
$ vim /etc/dnsmasq.hosts

#增加内容如下

192.168.2.210 etcd1.hi-linux.com
192.168.2.211 etcd2.hi-linux.com
192.168.2.212 etcd3.hi-linux.com
```

- 重启dnsmasq

```
$ systemctl restart dnsmasq
```

- 测试是否成功

```
# 查询SRV记录

$ dig @192.168.2.210 +noall +answer SRV _etcd-server._tcp.hi-linux.com

_etcd-server._tcp.hi-linux.com.	0 IN	SRV	0 100 2380 etcd2.hi-linux.com.
_etcd-server._tcp.hi-linux.com.	0 IN	SRV	0 100 2380 etcd1.hi-linux.com.
_etcd-server._tcp.hi-linux.com.	0 IN	SRV	0 100 2380 etcd3.hi-linux.com.
```

```
# 查询域名解析结果

$ dig @192.168.2.210 +noall +answer etcd1.hi-linux.com etcd2.hi-linux.com etcd3.hi-linux.com

etcd1.hi-linux.com.	0	IN	A	192.168.2.210
etcd2.hi-linux.com.	0	IN	A	192.168.2.211
etcd3.hi-linux.com.	0	IN	A	192.168.2.212
```

- 修改DNS服务器

Linux系统默认从`/etc/resolv.conf`配置文件读取DNS服务器，为了让etcd能够从`dnsmasq`服务器获取自定义域名解析，要修改三台etcd服务器的`/etc/resolv.conf`文件。

```
# 编辑resolv.conf文件
# 文件内容如下，保证我们自定义的dnsmasq服务器在第一位

$ vim /etc/resolv.conf
nameserver 192.168.2.210
```

**配置etcd**

- 修改etcd配置文件

开启DNS服务发现，主要是删除掉`ETCD_INITIAL_CLUSTER`字段(用于静态服务发现)，并指定`DNS SRV`域名(ETCD_DISCOVERY_SRV)

这里以etcd1节点为例(etcd2、etcd3同理)：

```
$ vim /opt/etcd/config/etcd.conf

ETCD_NAME=etcd1
ETCD_DATA_DIR="/var/lib/etcd/etcd1"
ETCD_LISTEN_PEER_URLS="http://etcd1.hi-linux.com:2380"
ETCD_LISTEN_CLIENT_URLS="http://etcd1.hi-linux.com:2379"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://etcd1.hi-linux.com:2380"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_INITIAL_CLUSTER_TOKEN="hilinux-etcd-cluster"
ETCD_ADVERTISE_CLIENT_URLS="http://etcd1.hi-linux.com:2379,http://etcd1.hi-linux.com:4001"
ETCD_DISCOVERY_SRV="hi-linux.com"
```

- 测试etcd集群

按上面配置好各集群节点后，分别在各节点启动etcd。

```
$ systemctl start etcd
```

启动完成后，执行以下命令查看集群成员：

```
$ etcdctl --endpoints "http://etcd1.hi-linux.com:2379" member list
1da4b0d74a9ecfff: name=etcd2 peerURLs=http://etcd2.hi-linux.com:2380 clientURLs=http://etcd2.hi-linux.com:2379,http://etcd2.hi-linux.com:4001 isLeader=false
7dd139e539054326: name=etcd1 peerURLs=http://etcd1.hi-linux.com:2380 clientURLs=http://etcd1.hi-linux.com:2379,http://etcd1.hi-linux.com:4001 isLeader=true
a12d567c7c7f2e2b: name=etcd3 peerURLs=http://etcd3.hi-linux.com:2380 clientURLs=http://etcd3.hi-linux.com:2379,http://etcd3.hi-linux.com:4001 isLeader=false
```

更多集群使用方法可参考「[通过静态发现方式部署etcd集群](https://www.hi-linux.com/posts/49138.html)」一文。

**参考文档**

http://www.google.com
http://t.cn/RXUCXYD
http://t.cn/RXUCoVR
