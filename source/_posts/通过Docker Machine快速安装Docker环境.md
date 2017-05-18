---
title: 通过Docker Machine快速安装Docker环境
tags:
  - Docker
  - Linux
categories: Docker
abbrlink: 46251
date: 2016-05-03 09:00:00
updated:
toc_number:
---

### 什么是Docker Machine

Docker Machine是一个简化安装Docker环境的工具。市场上主流Linux系统版本很多，使用Machine工具就简单很多，一两条命令即可在主流Linux系统上安装Docker环境，用户不用考虑什么操作系统。Docker Machine还具备Docker工具管理虚拟化技术，Generic驱动默认管理LXC容器技术。

Docker Machine 支持多种后端驱动，包括虚拟机、本地主机和云平台等。Docker Machine目前支持的驱动：
<!-- more -->
> amazonec2
> azure
> digitalocean
> exoscale
> generic
> google
> none
> openstack
> rackspace
> softlayer
> virtualbox
> vmwarevcloudair
> vmwarevsphere


### 安装

Docker Machine可以在多种操作系统平台上安装，包括Linux、Mac OS以及 Windows。

#### Linux/Mac OS

在Linux/Mac OS 上的安装十分简单，推荐从官方Release库直接下载编译好的二进制文件即可。

例如在Linux 64位系统上直接下载对应的二进制包

```
$ curl -L https://github.com/docker/machine/releases/download/v0.7.0/docker-machine-`uname -s`-`uname -m` >/usr/local/bin/docker-machine && chmod +x /usr/local/bin/docker-machine
```

#### Windows

Windows下面要复杂一些，首先需要安装msysgit。
msysgit是Windows下的git客户端软件包，会提供类似Linux下的一些基本的工具，例如ssh等。
安装之后，启动msysgit的命令行界面，仍然通过下载二进制包进行安装.

On Windows with git bash

```
$ if [[ ! -d "$HOME/bin" ]]; then mkdir -p "$HOME/bin"; fi && \
curl -L https://github.com/docker/machine/releases/download/v0.7.0/docker-machine-Windows-x86_64.exe > "$HOME/bin/docker-machine.exe" && \
chmod +x "$HOME/bin/docker-machine.exe"
```

完成后，查看版本信息，验证运行正常。

```
$ docker-machine -v
docker-machine version 0.7.0, build a650a40
```

### docker-machine命令

> help  查看帮助信息
> active  查看活动的Docker主机
> config  输出连接的配置信息
> create  创建一个Docker主机
> env  显示连接到某个主机需要的环境变量
> inspect  输出主机更新信息
> ip  获取Docker主机地址
> kill  停止某个Docker主机
> ls  列出所有管理的Docker主机
> regenerate-certs  为某个主机重新成功TLS认证信息
> restart  重启Docker主机
> rm  删除Docker主机
> scp  在Docker主机之间复制文件
> ssh  SSH到主机上执行命令
> start  启动一个主机
> status  查看一个主机状态
> stop  停止一个主机
> upgrade  更新主机Docker版本为最新
> url  获取主机的URL

每个命令又带有不同的参数，查看具体的用法可以通过

```
$ docker-machine <COMMAND> -h
```

### 使用

#### 创建Docker主机实例

这里使用的Docker主机使用的是Ubuntu 14.04(docker-machine 0.7版本不支持CentOS7以下版本)

docker-machine通过ssh免交互登录或指定私钥登录连接到Docker主机，从网上下载并安装docker工具，需要用root权限来安装。

##### 配置root权限

**如果用root用户**

在ubuntu系统下，默认禁止root用户登录系统，因此需要先配置root允许SSH登录系统

允许root ssh登录(docker主机操作)

```
#切换到root用户
$ sudo -i 
#修改此项为允许root登录
$ sed -i -e "s/PermitRootLogin without-password/PermitRootLogin yes/g" /etc/ssh/sshd_config
#重启SSH
$ service ssh restart
按提示设置root用户密码
$ passwd
```

**如果用具有sudo权限的普通用户**

以mike为例

配置为免密码sudo

```
$ vim /etc/sudoers.d/nopasswdsudo 
mike ALL=(ALL) NOPASSWD : ALL
```

注:Ubuntu 14.04下sudo免密码的方法略有不同，具体可参考：[Ubuntu 14.04 sudo免密码的方法](http://imike.me/2016/04/15/Ubuntu%2014.04%20sudo%E5%85%8D%E5%AF%86%E7%A0%81%E7%9A%84%E6%96%B9%E6%B3%95/)

##### 配置ssh免交互登录

首先确保本地主机可以通过user账号的key直接ssh到目标主机。

以root为例

创建密钥对(machine主机操作)

```
$ ssh-keygen -t rsa  #一直回车
$ mv id_rsa.pub authorized_keys
$ chmod 600 authorized_keys
```

免交互root登录系统(machine主机操作)

```
$ ssh-copy-id root@192.168.119.105  #将公钥拷贝到docker主机
$ ssh root@192.168.119.105   #如果不提示密码登录主机说明成功，可以继续下一步了
```


##### 启用visiblepw

machine主机操作

```
$ visudo
Defaults   visiblepw
```

如果不添加这个条，可能报下面的错：

```
Error creating machine: Error running provisioning: Something went wrong running an SSH command!
command : sudo hostname ubuntu && echo "ubuntu" | sudo tee /etc/hostname
err     : exit status 1
output  : sudo: no tty present and no askpass program specified
Sorry, try again.
sudo: no tty present and no askpass program specified
Sorry, try again.
sudo: no tty present and no askpass program specified
Sorry, try again.
sudo: 3 incorrect password attempts
```

##### 使用generic类型的驱动创建Docker主机

创建一台Docker主机，命名为docker-web。

```
$ docker-machine create -d generic --generic-ip-address=192.168.119.105 --generic-ssh-user=mike docker-ubuntu-web
```

注意：Docker Machine安装docker环境中会因网络或其他情况造成安装失败(国内连官网速度很慢),可按下面的方法使用国内镜像源进行安装。

Docker下如何使用国内镜像源可参考[Docker下使用daocloud/阿里云镜像加速](http://www.imike.me/2016/04/20/Docker%E4%B8%8B%E4%BD%BF%E7%94%A8%E9%95%9C%E5%83%8F%E5%8A%A0%E9%80%9F/)一文。

##### 使用daoclound镜像安装

```
$ docker-machine create -d generic --generic-ip-address=192.168.119.105 --generic-ssh-user=mike --engine-registry-mirror http://xxxxxx.m.daocloud.io  docker-ubuntu-web

Running pre-create checks...
Creating machine...
(docker-ubuntu-web) No SSH key specified. Connecting to this machine now and in the future will require the ssh agent to contain the appropriate key.
Waiting for machine to be running, this may take a few minutes...
Detecting operating system of created instance...
Waiting for SSH to be available...
Detecting the provisioner...
Provisioning with ubuntu(upstart)...
Installing Docker...
Copying certs to the local machine directory...
Copying certs to the remote machine...
Setting Docker configuration on the remote daemon...
Checking connection to Docker...
Docker is up and running!
To see how to connect your Docker Client to the Docker Engine running on this virtual machine, run: docker-machine env docker-ubuntu-web
```

参数说明

```
-d  driver  #指定基于什么虚拟化技术的驱动
--generic-ip-address  #指定要安装宿主机的IP，前提是SSH root用户免交互登录或私钥认证。
--generic-ssh-user   #SSH的用户
```

等待数分钟后，docker就安装成功了，可以通过docker命令管理容器了。如果安装失败多尝试两次！

```
$ docker-machine ls
NAME                ACTIVE   DRIVER    STATE     URL                          SWARM   DOCKER    ERRORS
docker-ubuntu-web   -        generic   Running   tcp://192.168.119.105:2376           v1.11.0
```

创建主机成功后，可以通过env命令来让后续操作对象都是目标主机。

```
$ docker-machine env docker-ubuntu-web
```

SSH到docker主机

```
$ docker-machine ssh  docker-ubuntu-web
```

#### 在不使用驱动的情况新增一个主机

我们可以在不使用驱动的情况往Docker增加一台主机，只需要一个URL。它可以使用一个已有机器的别名，所以我们就不需要每次在运行docker命令时输入完整的URL了。

```
$ docker-machine create -d none --url=tcp://192.168.119.105:2376 docker-ubuntu-web
$ docker-machine regenerate-certs docker-ubuntu-web
```

注：进行证书注册时会出现`http://www.dockone.io/question/920`类似错误，造成注册失败并不能正常管理docker主机，此问题暂未解决，如有知道如何解决的大神求留言。

#### 在Docker Machine中使用Mirror服务

**使用daoclound镜像安装**

新建时通过指定`--engine-registry-mirror`参数

```
$ docker-machine create -d generic --generic-ip-address=192.168.119.105 --generic-ssh-user=mike --engine-registry-mirror http://xxxxxx.m.daocloud.io  docker-ubuntu-web
```

**修改已存在docker主机**

以主机名为docker-ubuntu-web的为例

修改`~/.docker/machine/machines/docker-ubuntu-web/config.json`文件，编辑RegistryMirror字段，插入你的镜像地址，然后再重启你就会在`/var/lib/boot2docker/profile`看见一个`--registry-mirror http://xxxxxx.m.daocloud.io`了。

```
$ vim  ~/.docker/machine/machines/docker-ubuntu-web/config.json


"RegistryMirror": [
    "http://xxxxxx.m.daocloud.io"
]
```

### 参考文档

http://www.google.com
https://docs.docker.com/machine/install-machine/
https://docs.docker.com/machine/reference/
http://lizhenliang.blog.51cto.com/7876557/1730028
https://reality0ne.com/docker-machine-mirror/