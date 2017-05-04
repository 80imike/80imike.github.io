---
category: Docker
title: 在Mesos上使用Chronos运行计划任务
date: 2017-05-03 09:00:00
tags: [Chronos,Docker]
abbrlink:
updated:
toc_number: false
---

### Chronost简介

Chronos是由Airbnb公司推出的用来替代Cron的开源产品，这是一个用来运行基于容器定时任务的Mesos框架。Chronos可处理依赖性和基于ISO8601的调度，你可以用它来对作业进行编排。支持使用Mesos作为作业执行器，支持和Hadoop进行交互。可定义作业执行完成后的触发器。支持任意长度的依赖链。

由于Chronos以ISO8601时间规范作为定时任务的执行时间配置，所以理解这个时间规范对配置Chronos定时任务至关重要。这里我们就简单看下ISO8601的规则：

- 所有字母都是大写，无论用来做什么的。
- 日期写成2012-02-05或者20120205都OK。
- 时间需要用字母T开始，比如：T08:00:00或者T080000。
- 时间末尾用Z表示UTC时间，用+08:00这种表示在UTC时间基础上偏移的时间(+08:00是中国的时区)
- 字母P表示一段时间，常用于表达执行任务的间隔。比如：P10M表示10个月的时长，而PT10M是10分钟的时长，因为T开头表示的时间，非T开头表示的是日期。
- R表示从A时间到B时间之间，每间隔C时长，执行一次。

更详细的ISO 8601介绍可参考：https://zh.wikipedia.org/zh-hans/ISO_8601

<!-- more -->

**Chronos工作原理**

Chronos以Framework身份接入Mesos，支持Zookeeper选举高可用，同时将所有的定时任务配置存储在Zookeeper里。

Chronos的工作流程描述如下：

1. 从ZK获取全部的任务列表。
1. 以Scheduler身份接入到Mesos，分析任务的执行依赖。
1. 分析出需要立即执行的任务和暂时不需要执行的任务。
1. 将需要立即执行的任务放入执行队列，等待Mesos offer足够的资源。
1. 等待执行队列中的一个任务被执行，再次回到步骤1。

项目地址：https://github.com/mesos/chronos

### 安装Chronos

在安装Chronos前你必须有一个Mesos集群环境，有关Mesos集群搭建你可以参考「[使用Mesos和Marathon管理Docker集群](https://www.hi-linux.com/posts/8141.html)」一文，这里就不再讲述了。

这里是在之前集群环境基础上搭建，所以在`dev-master-01`上安装Chronos。

#### 通过软件包安装

- Ubuntu and Debian系统

```
$ apt-get install chronos
```

- RedHat and CentOS系统

```
$ yum -y install chronos
```

- 启动相关服务

```
$ service chronos start
```

#### 通过Docker安装

由于Ubuntu 16.04不支持包安装，这里直接用官方的Docker镜像运行Chronos。

```
$ docker run -d --name=chronos --net=host -e PORT0=8000 -e PORT1=8001 mesosphere/chronos:latest --zk_hosts zk://dev-master-01:2181/chronos/ --master zk://dev-master-01:2181/mesos/
```

1. 网络模式使用host，这样Docker容器将共享宿主机的网络namespace，这是因为我们需要的仅仅是Docker的执行环境，并不是网络隔离。
1. `zk_hosts`是给Chronos保存任务数据和进行Leader选举的存储目录。
1. Master是Mesos-master的ZK存储地址，这样Chronos才可以找到Master并注册上去。
1. 环境变量PORT0=8000是Chronos的HTTP接口，也是Web UI的地址，PORT1=8001用于Libprocess。

- 验证是否安装成功

查看Docker容器是否正常运行

```
$ docker ps|grep chronos
afb1c37b07d1        mesosphere/chronos:latest    "/chronos/bin/star..."   4 minutes ago       Up 4 minutes                                        chronos
```

查看相应端口是否正常

```
$ netstat -tunlp|grep -E  "8000|8001"
tcp        0      0 0.0.0.0:8001            0.0.0.0:*               LISTEN      5151/java
tcp6       0      0 :::8000                 :::*                    LISTEN      5151/java
```

- 访问Chronos的Web管理界面

Chronos的最新版本是v3.x，它对之前的2.x版本进行了重写，导致目前3.x的Web UI界面极其简陋，仅仅提供了基础的任务启停和配置功能。

Chronos默认是监听在4400端口，这里使用了自定义端口为8000。通过使用`http://ip:8000/`来访问。如下图所示：

![](https://www.hi-linux.com/img/linux/chronos1.png)

### 使用Chronos

- 使用Web界面创建任务

在Chronos页面，点击"ADD JOB--Scheduled"并填入以下相关信息来创建一个任务，如下图：

![](https://www.hi-linux.com/img/linux/chronos2.png)

> Name：Test-Chronos
> Command： sleep 30
> Schedule：R/2017-05-04T03:26:00.000Z/PT24H

注意：时间格式是ISO 8601表示法，时间是UTC时间。如果要加上时区可以这样写：`R/2017-05-04T14:25:00.000+08:00/PT24H`。这样就表示中国时区，+08:00是中国的时区。

在Chronos页面，查看任务执行的情况

![](https://www.hi-linux.com/img/linux/chronos3.png)

在Mesos页面，查看任务执行的情况。

![](https://www.hi-linux.com/img/linux/chronos5.png)

- 使用REST API创建任务

REST API包括Web UI没有提供的功能，如Docker容器信息、时区支持、使用Mesos fetcher来下载文件到任务的工作目录中等。

创建JSON文件

```
$ vim test-chronos-api.json

{
  "schedule": "R/2017-05-04T02:58:00Z/PT24H",
  "name": "Test-Chronos-API",
  "description": "Sleep for 60 seconds and return.",
  "cpus": 0.5,
  "mem": 128,
  "disk": 500,
  "command": "sleep 60"  
}
```

使用curl命令提交到Chronos

```
$ curl -H 'Content-Type: application/json' -X POST -d @test-chronos-api.json http://dev-master-01:8000/v1/scheduler/iso8601
```

在Chronos页面，可以看到任务已创建成功。

![](https://www.hi-linux.com/img/linux/chronos6.png)

在Mesos页面，查看任务执行的情况。

![](https://www.hi-linux.com/img/linux/chronos7.png)

更多API的用法可参考：https://mesos.github.io/chronos/docs/api.html

- 创建基于Docker的任务

Docker容器允许你将代码和它的依赖一起打包成一个镜像，并分发到集群中的任何节点上。这极大地方便了程序的部署。这里用定时输出一个时间的例子来体现这一个过程。

创建JSON文件

```
$ vi test-chronos-docker.json

{
  "schedule": "R/2017-05-04T05:50:00Z/PT24H",
  "name": "Test-Chronos-Docker",
  "container": {
    "type": "DOCKER",
    "image": "busybox",
    "network": "BRIDGE",
    "volumes": [
      {
        "containerPath": "/var/log/",
        "hostPath": "/var/log/",
        "mode": "RW"
      }
    ]
  },
  "cpus": "0.5",
  "mem": "128",
  "fetch": [],
  "command": "while sleep 10; do date -u +%T; done"
}
```

在Chronos上，使用REST API创建任务

```
$ curl -H 'Content-Type: application/json' -X POST -d @test-chronos-docker.json http://dev-master-01:8000/v1/scheduler/iso8601
```

在Chronos页面确认任务已创建成功。

![](https://www.hi-linux.com/img/linux/chronos8.png)


在节点上确认容器启动

```
$ docker ps
CONTAINER ID        IMAGE                        COMMAND                  CREATED              STATUS              PORTS               NAMES
1b60113326de        busybox                      "/bin/sh -c 'while..."   About a minute ago   Up About a minute                       mesos-86e469e1-f0e0-439d-990a-52e897b8075d-S0.dc3dbf69-b415-45db-96ec-91bf8ec12362
```

确认容器是否正确运行

```
$ docker logs 1b6
05:50:12
05:50:22
05:50:32
05:50:42
05:50:52
05:51:02
05:51:12
```

### 参考文档

http://www.google.com
http://t.cn/RcpXPI2
http://qinghua.github.io/mesos-chronos/
http://www.cnblogs.com/ee900222/p/docker_2.html
http://yuerblog.cc/2017/02/14/setup-chronos-on-mesos/
