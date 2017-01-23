---
title: Docker网络详解
tags:
  - Linux
  - Docker
  - 技巧
categories: Docker
abbrlink: 62776
date: 2016-03-15 09:51:54
---

转载自:<http://blog.csdn.net/wsscy2004>

### 一、网络基础

Docker使用linux桥接，在主机虚拟一个docker0网络接口，在主机中运行命令查看：

```bash
#List host bridges
$sudo brctl show
bridge      name    bridge id               STP enabled     interfacesdocker0             8000.000000000000       no

#Show docker0 IP address
$sudo ifconfig docker0
docker0   Link encap:Ethernet  HWaddr xx:xx:xx:xx:xx:xx
          inet addr:172.17.42.1  Bcast:0.0.0.0  Mask:255.255.0.0
```
docker启动一个container时会会根据docker0的网段划分container的IP,docker0是每个container的网关。<!-- more -->


### 二、自定义网络范围

尽管docker在使用linux brigde会找最合适的。但是有时候我们还是需要自己规划。

使用-b=<bridgename>参数设置

```bash
#先关闭docker
$sudo service docker stop

#关闭网桥docker0# 添加自己的网桥bridge0
$sudo ifconfig docker0 down
$sudo brctl addbr bridge0
$sudo ifconfig bridge0 192.168.227.1 netmask 255.255.255.0

#向Docker startup file中添加启动自定义网桥参数
$echo "DOCKER_OPTS=\"-b=bridge0\"" >> /etc/default/docker

#启动Docker
$sudo service docker start

#查看自定义网桥是否启动成功，ip等配置是否正确
$sudo ifconfig bridge0
bridge0   Link encap:Ethernet  HWaddr xx:xx:xx:xx:xx:xx
          inet addr:192.168.227.1  Bcast:192.168.227.255  Mask:255.255.255.0

#启动container
docker run -i -t base /bin/bash

#可以看到Container IP,在网段192.168.227/24内
root@261c272cd7d5:/# ifconfig eth0
eth0      Link encap:Ethernet  HWaddr xx:xx:xx:xx:xx:xx
          inet addr:192.168.227.5  Bcast:192.168.227.255  Mask:255.255.255.0

#bridge0 IP as the default gateway 查看路由信息
root@261c272cd7d5:/# route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         192.168.227.1   0.0.0.0         UG    0      0        0 eth0
192.168.227.0   0.0.0.0         255.255.255.0   U     0      0        0 eth0

#hits CTRL+P then CTRL+Q to detach

#查看网桥信息
$sudo brctl show
bridge      name    bridge id               STP enabled     interfaces
bridge0             8000.fe7c2e0faebd       no              vethAQI2QT
```

### 三、container互通

docker默认是允许container互通，通过-icc=false关闭互通。
一旦关闭了互通，只能通过--link name:alias命令连接指定container.

container互相隔离的情况下，假设我们有一个webapp container,一个redis contianer需要互通。
先启动redis container:

```bash
sudo docker run -d --name redis crosbymichael/redis
```

再启动webapp并联通到redis

```bash
#将redis取别名为db
sudo docker run -t -i --link redis:db --name webapp ubuntu bash
```

在webapp中可以看到db的网络信息：

```bash
$root@4c01db0b339c:/# env

HOSTNAME=4c01db0b339c
DB_NAME=/webapp/db
TERM=xterm
DB_PORT=tcp://172.17.0.8:6379
DB_PORT_6379_TCP=tcp://172.17.0.8:6379
DB_PORT_6379_TCP_PROTO=tcp
DB_PORT_6379_TCP_ADDR=172.17.0.8
DB_PORT_6379_TCP_PORT=6379
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
PWD=/
SHLVL=1
HOME=/
container=lxc
_=/usr/bin/env
root@4c01db0b339c:/#
```

0.11版本以后，--link redis:db的别名，会在/etc/hosts中生成对应的ip映射:

```bash
root@6541a75d44a0:/# cat /etc/hosts
172.17.0.3  6541a75d44a0172.17.0.2  db
```

### 四、什么是vethxxxx

```bash
#查看网桥信息
$sudo brctl show
bridge      name    bridge id               STP enabled     interfaces
docker0             8000.fe7c2e0faebd       no              vethAQI2QT
```
vethxxx是主机与container内部eth0相连的管道。详见ip link和namespaces infrastructure

### 五、更多

pipework可以创建各种复杂的containers互通的场景。详见[here](http://github.com/jpetazzo/pipework)


