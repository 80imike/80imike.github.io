---
category: Docker
title: 使用Mesos和Marathon管理Docker集群
date: 2017-05-03 09:00:00
tags: [Mesos, Docker]
abbrlink:
updated:
toc_number: false
---

### Mesos简介

Apache Mesos是一个分布式系统的管理软件，对集群的资源进行分配和管理。具体的介绍可参考 「[Apache Mesos入门](https://www.hi-linux.com/posts/54145.html)」一文，这里就不再重复介绍了。

项目地址：https://github.com/mesosphere

### Marathon简介

Marathon按照官方的说法是个基于Mesos的私有PaaS，它实现了Mesos的Framework。Marathon实现了服务发现和负载平衡、为部署提供提供REST API服务、授权和SSL、配置约束等功能。

Marathon支持通过Shell命令和Docker部署应用。提供Web界面、支持cpu/mem、实例数等参数设置，支持单应用的Scale，但不支持复杂的集群定义。Marathon本身是通过Scala实现的。

Marathon能够支持运行长服务，比如Web应用等。Marathon能够原样运行任何Linux二进制发布版本，如Tomcat Play等等。

<!-- more -->

理解Mesos和Marathon之间的关系，如果将Mesos类比为操作系统的内核，负责资源调度。则Marathon可以类比为服务管理系统，比如是init，systemd或upstart等系统，用来管理应用的状态信息。Marathon将应用程序部署为长时间运行的Mesos任务。

![](https://www.hi-linux.com/img/linux/mesos13.png)

Marathon可以让您指定每个应用程序实例需要的资源以及要运行此程序需要多少实例。它可以使用可用的集群资源对失败的任务自动做出响应。

如果某个Mesos Slave当机或应用的某个实例退出、失败，Marathon将会自动启动一个新的实例，来替换掉失败的实例。Marathon也允许用户在部署时指定应用程序彼此间的依赖关系，这样就可以保证某个应用程序实例不会在它依赖的数据库实例启动前启动。

Marathon特性

- 高可用，支持多主节点(主备模式)自动切换。
- 支持多种容器环境。
- 支持有状态服务，如数据库。
- 使用Web管理界面用于配置操作和监控系统状态。
- 约束规则，比如限制任务分布在特定节点。
- 服务发现、负载均衡。
- 支持健康检查，实现容错。
- 支持事件订阅，用于集成到其它系统。
- 运行指标监控接口。
- 完善易用的REST API。

### 安装Mesos和Marathon

**系统环境**

|主机名|IP地址|软件环境|
|---|---|---|
|dev-master-01|192.168.2.210|Mesos Master、Zookeeper、Marathon|
|dev-node-01|192.168.2.211|Mesos Slave、Docker|

我们使用mesosphere提供的安装包进行安装。

**添加软件安装源**

- Ubuntu and Debian系统

```
# 增加证书并设备环境变量
$ apt-key adv --keyserver keyserver.ubuntu.com --recv E56151BF
$ DISTRO=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
$ CODENAME=$(lsb_release -cs)

# 增加仓库
$ echo "deb http://repos.mesosphere.com/${DISTRO} ${CODENAME} main"|sudo tee /etc/apt/sources.list.d/mesosphere.list
$ apt-get -y update
```

- RedHat and CentOS系统

```
$ rpm -Uvh http://repos.mesosphere.com/el/7/noarch/RPMS/mesosphere-el-repo-7-3.noarch.rpm
$ yum -y update
```

> 注：所有安装的机器都需要添加。

#### 安装Master

这里需要在Master上安装Mesos、Marathon、ZooKeeper。

- Ubuntu and Debian系统

```
$ apt-get -y install mesos marathon zookeeperd
```

- RedHat and CentOS系统

```
$ yum install -y mesos marathon mesosphere-zookeeper
```

**ZooKeeper设定**

本次配置的ZooKeeper是单节点。生产环境建议配置ZooKeeper集群，有关ZooKeeper集群安装后面会分享相关文档。

```
$ vim /etc/mesos/zk
zk://dev-master-01:2181/mesos
```

> 注：这里使用的是主机名，记得在各主机的hosts配置下映射关系。

```
$ vim /etc/hosts
192.168.2.210 dev-master-01
192.168.2.211 dev-node-02
```

手动建立management.properties文件

```
$ mkdir -p /usr/lib/jvm/java-9-openjdk-amd64/conf/management/ && touch /usr/lib/jvm/java-9-openjdk-amd64/conf/management/management.properties
```

如果不建立,ZooKeeper不能正确启动。会报以下错误：

```
$ Error: Config file not found: /usr/lib/jvm/java-9-openjdk-amd64/conf/management/management.properties
```

这是一个OpenJDK的巨坑，生产环境建议用Oracle JDK。

配置JAVA环境变量(可选)

```
$ vim /etc/profile.d/zookeeper.sh
export JAVA_HOME=/usr/lib/jvm/java-9-openjdk-amd64/
export JER_HOME=$JAVA_HOME/jre
export CLASSPATH=$JAVA_HOME/lib:$JRE_HOME/lib:$CLASSPATH
export PATH=$JAVA_HOME/bin:$JRE_HOME/bin:$PATH
```

**启动相关服务**

```
$ systemctl start zookeeper
$ systemctl start mesos-master
$ systemctl start marathon
```

验证ZooKeeper是否启动成功

```
$ systemctl status zookeeper
● zookeeper.service - LSB: centralized coordination service
  Loaded: loaded (/etc/init.d/zookeeper; bad; vendor preset: enabled)
  Active: active (running) since Tue 2017-05-02 15:16:59 CST; 4min 34s ago
    Docs: man:systemd-sysv-generator(8)
 Process: 15309 ExecStop=/etc/init.d/zookeeper stop (code=exited, status=0/SUCCESS)
 Process: 15324 ExecStart=/etc/init.d/zookeeper start (code=exited, status=0/SUCCESS)
   Tasks: 26
  Memory: 46.0M
     CPU: 12.041s
  CGroup: /system.slice/zookeeper.service
          └─15336 /usr/bin/java -cp /etc/zookeeper/conf:/usr/share/java/jline.jar:/usr/share/java/log4j-1.2.jar:/usr/share/java/xercesImpl.jar:/usr/share/java/xmlParserAPIs.jar:/usr/share/java/netty.jar:/usr/share/java/slf4j-api.jar:/usr/share/java/slf4j-log4j12.jar:/u

May 02 15:16:59 dev-master-01 systemd[1]: Starting LSB: centralized coordination service...
May 02 15:16:59 dev-master-01 systemd[1]: Started LSB: centralized coordination service.
```

**访问Mesos的Web管理界面**

Mesos安装完毕后，Mesos Master会启动一个Web服务，默认监听在5050端口。通过使用`http://ip:5050/`来访问。如下图所示：

![](https://www.hi-linux.com/img/linux/mesos1.png)

在这个界面里，我们能看到整个集群的资源分配情况和框架的状态。 现在所有资源还是空，也没有任何进程。

**访问Marathon的Web管理界面**

Marathon默认监听在8080端口，通过使用`http://ip:8080/`来访问。如下图所示：

![](https://www.hi-linux.com/img/linux/mesos2.png)

#### 安装Slave

Mesos Master集群要真正能够分配资源并运行任务，还需要向Master注册Slave。Slave的所有配置都在`/etc/mesos-slave`目录中。

这里我们需要Slave上安装Mesos、Docker。

- Ubuntu and Debian系统

```
$ apt-get install -y mesos docker
```

- RedHat and CentOS系统

```
$ yum install -y mesos docker
```

**Docker相关设定**

这里主要需要设置containerizers、executor_registration_timeout参数。设置containerizers参数是为了让Slave支持Docker，默认是用lxc来管理容器的。executor_registration_timeout参数主要是由于Docker任务启动的时候，需要去远程拉取镜像。一般首次拉取时容易超时，这里把超时时间设得长一些，避免超时。

```
$ echo 'docker,mesos' > /etc/mesos-slave/containerizers
$ echo '5mins' > /etc/mesos-slave/executor_registration_timeout
```

**ZooKeeper设定**

```
$ vim /etc/mesos/zk
zk://dev-master-01:2181/mesos
```

> 注：这里使用的是主机名，记得在各主机的hosts配置下映射关系。

```
$ vim /etc/hosts
192.168.2.210 dev-master-01
192.168.2.211 dev-node-02
```

**启动相关服务**

```
$ systemctl start docker
$ systemctl start mesos-slave
```

### 使用Mesos

在MASTER上执行Frameworks测试框架

```
$ MASTER=$(mesos-resolve `cat /etc/mesos/zk`)
$ mesos-execute --master=$MASTER --name="cluster-test" --command="sleep 60"
```

在Frameworks页面刷新，可以查看任务的执行情况。

查看活动的框架

![](https://www.hi-linux.com/img/linux/mesos3.png)

查看活动的任务

![](https://www.hi-linux.com/img/linux/mesos4.png)

点击结束的任务页面，可以看到在哪个Slave上执行的。

![](https://www.hi-linux.com/img/linux/mesos6.png)

![](https://www.hi-linux.com/img/linux/mesos7.png)

### 使用Marathon调用Mesos运行Docker容器

下面通过Marathon调用Mesos来创建一个Nginx镜像的Docker容器。Marathon启动时会读取`/etc/mesos/zk`配置文件，Marathon通过Zookeeper来找到Mesos Master。

**创建应用**

首先准备应用定义文件， 此文件为JSON格式。定义了应用的名称(id)、命令、资源(cpu、内存等)和实例数量等信息。

- 创建应用定义文件

```
$ vim nginx.json
{
  "id":"nginx",
  "cpus":0.2,
  "mem":20.0,
  "instances": 1,
  "constraints": [["hostname", "UNIQUE",""]],
  "container": {
  "type":"DOCKER",
  "docker": {
     "image": "nginx",
     "network": "BRIDGE",
     "portMappings": [
        {"containerPort": 80, "hostPort": 0,"servicePort": 0, "protocol": "tcp" }
      ]
    }
  }
}
```

- 通过Marathon UI创建应用

在Web页面上，点击创建`Create Application`按钮。 弹出操作窗中，切换为JSON模式。

![](https://www.hi-linux.com/img/linux/mesos8.png)

将上一步准备的JSON内容复制到输入框内，点击输入框旁的创建`Create Application`按钮保存配置。 此时新建应用的信息，将出现在Web页面的应用列表。

![](https://www.hi-linux.com/img/linux/mesos10.png)

在`dev-node-01`上查看通过Marathon创建的容器

```
$ docker ps
CONTAINER ID        IMAGE                        COMMAND                  CREATED             STATUS              PORTS                   NAMES
419fd7d23736        nginx                        "nginx -g 'daemon ..."   12 minutes ago      Up 12 minutes       0.0.0.0:31182->80/tcp   mesos-66734014-5647-47e2-9264-b5775128b01d-S0.cf1d01ec-0b7d-4f3f-a407-926794686490
```

现在你就可以通过`http://ip:31182`来访问到nginx了。

![](https://www.hi-linux.com/img/linux/mesos9.png)

- 使用Marathon API操作

Marathon有自己的REST API，为了方便批量化管理，我们通过API的方式来创建一个简单应用。这里我们使用其中的`POST /v2/apps`来创建应用。

**创建JSON文件**

```
$ vim busybox-demo.json

{
  "container": {
    "type": "DOCKER",
    "docker": {
    "image": "busybox"
    }
  },
  "id": "busybox-demo",
  "instances": 2,
  "cpus": 0.5,
  "mem": 128,
  "uris": [],
  "cmd": "while sleep 10; do date -u +%T; done"
}
```
其中的`cmd`字段包含了应用将要执行的命令，`instances`是进程的数量。

**通过API在Marathon上创建任务**

```
# curl -X POST -H "Content-Type: application/json" http://192.168.2.210:8080/v2/apps -d@busybox-demo.json

{"id":"/busybox-demo","cmd":"while sleep 10; do date -u +%T; done","args":null,"user":null,"env":{},"instances":2,"cpus":0.5,"mem":256,"disk":0,"gpus":0,"executor":"","constraints":[],"uris":[],"fetch":[],"storeUrls":[],"backoffSeconds":1,"backoffFactor":1.15,"maxLaunchDelaySeconds":3600,"container":{"type":"DOCKER","volumes":[],"docker":{"image":"busybox","network":null,"portMappings":[],"privileged":false,"parameters":[],"forcePullImage":false}},"healthChecks":[],"readinessChecks":[],"dependencies":[],"upgradeStrategy":{"minimumHealthCapacity":1,"maximumOverCapacity":1},"labels":{},"ipAddress":null,"version":"2017-05-03T03:29:46.941Z","residency":null,"secrets":{},"taskKillGracePeriodSeconds":null,"unreachableStrategy":{"inactiveAfterSeconds":300,"expungeAfterSeconds":600},"killSelection":"YOUNGEST_FIRST","ports":[0],"portDefinitions":[{"port":0,"protocol":"tcp","name":"default","labels":{}}],"requirePorts":false,"tasksStaged":0,"tasksRunning":0,"tasksHealthy":0,"tasksUnhealthy":0,"deployments":[{"id":"2f25526a-7641-4326-bd63-26eb69364838"}],"tasks":[]}
```

在Marathon页面确认容器已经启动

![](https://www.hi-linux.com/img/linux/mesos11.png)

在Mesos页面确认任务正在执行中

![](https://www.hi-linux.com/img/linux/mesos12.png)

在`dev-node-01`节点上确认容器已经启动

```
$ docker ps
CONTAINER ID        IMAGE                        COMMAND                  CREATED             STATUS              PORTS                   NAMES
db72938c7628        busybox                      "/bin/sh -c 'while..."   2 minutes ago       Up 2 minutes                                mesos-66734014-5647-47e2-9264-b5775128b01d-S0.3e6e80a8-51b7-4f23-876b-6deb08671f46
cbeb91ebfeca        busybox                      "/bin/sh -c 'while..."   2 minutes ago       Up 2 minutes                                mesos-66734014-5647-47e2-9264-b5775128b01d-S0.a8cad50d-c0b8-42ef-a986-fb99b6fe4f1b
```

查看容器的日志，确认输出的时间

```
$ docker logs  db72938c7628
03:35:28
03:35:38
03:35:48
03:35:58
03:36:08
```

如果你想创建同样的容器，可以点击上图中的`Scale Application`来体验一下。同样的，你也可以通过Marathon的Web界面来进行容器的创建、扩展和销毁。

![](https://www.hi-linux.com/img/linux/mesos14.png)

通过上面的部署体验，Mesos和Marathon使得Docker集群的管理变得简单方便，为在生产环境部署使用Docker集群提供了可能。

### 参考文档

http://www.google.com
https://github.com/arangodb/dcos-mini-cluster/blob/master/Dockerfile
http://www.cnblogs.com/ee900222/p/docker_2.html
http://www.xuliangwei.com/xubusi/422.html
http://biglittleant.cn/2016/12/18/mesos-marathon-docker/
