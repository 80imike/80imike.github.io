---
title: Docker下使用daocloud/阿里云镜像加速
tags:
  - Docker
  - Linux
categories: Docker
abbrlink: 1421
date: 2016-04-20 09:00:00
updated:
toc_number:
---

在使用docker下载镜像时，在国内使用官方的Docker registry下载时速度很慢，庆幸国内还镜像加速服务。目前支持Docker镜像的有阿里云和DaoCloud两家。本文将详细讲解镜像服务的具体配置方法。

### docker使用阿里云镜像库加速

注册阿里云开发者帐号帐号
https://cr.console.aliyun.com/

登陆后取得专属加速器地址，类似这样`https://xxxxxx.mirror.aliyuncs.com`
<!-- more -->
#### 配置Docker加速器

##### ubuntu

安装或升级Docker

请安装1.6.0以上版本的Docker。 
您可以通过阿里云的镜像仓库下载： mirrors.aliyun.com/help/docker-engine

```
curl -sSL http://acs-public-mirror.oss-cn-hangzhou.aliyuncs.com/docker-engine/internet | sh -
```

配置Docker加速器

您可以使用如下的脚本将mirror的配置添加到docker daemon的启动参数中。
```
echo "DOCKER_OPTS=\"--registry-mirror=https://xxxxxx.mirror.aliyuncs.com\"" | sudo tee -a /etc/default/docker
sudo service docker restart
```

##### centos

安装或升级Docker

请安装1.6.0以上版本的Docker。 

您可以通过阿里云的镜像仓库下载： mirrors.aliyun.com/help/docker-engine

```
curl -sSL http://acs-public-mirror.oss-cn-hangzhou.aliyuncs.com/docker-engine/internet | sh -
```

配置Docker加速器

您可以使用如下的脚本将mirror的配置添加到docker daemon的启动参数中。

```
#系统要求CentOS 7以上、Docker1.9以上
sudo cp -n /lib/systemd/system/docker.service /etc/systemd/system/docker.service
sudo sed -i "s|ExecStart=/usr/bin/docker daemon|ExecStart=/usr/bin/docker daemon --registry-mirror=https://xxxxxx.mirror.aliyuncs.com|g" /etc/systemd/system/docker.service
sudo systemctl daemon-reload
sudo service docker restart
```

##### windows

安装或升级Docker

推荐您安装Docker Toolbox。 

Toolbox的介绍和帮助： http://mirrors.aliyun.com/help/docker-toolbox 
Windows系统的安装文件目录： http://mirrors.aliyun.com/docker-toolbox/windows

快速开始

```
# 创建一台安装有Docker环境的Linux虚拟机，指定机器名称为default，同时配置Docker加速器地址。
docker-machine create --engine-registry-mirror=https://mytfd7zc.mirror.aliyuncs.com -d virtualbox default

# 查看机器的环境配置，并配置到本地。然后通过Docker客户端访问Docker服务。
docker-machine env default
eval "$(docker-machine env default)"
docker info
```

##### macos

安装或升级Docker
推荐您安装Docker Toolbox。 

Toolbox的介绍和帮助： http://mirrors.aliyun.com/help/docker-toolbox 
Mac系统的安装文件目录： http://mirrors.aliyun.com/docker-toolbox/mac

```
# 创建一台安装有Docker环境的Linux虚拟机，指定机器名称为default，同时配置Docker加速器地址。
docker-machine create --engine-registry-mirror=https://mytfd7zc.mirror.aliyuncs.com -d virtualbox default

# 查看机器的环境配置，并配置到本地。然后通过Docker客户端访问Docker服务。
docker-machine env default
eval "$(docker-machine env default)"
docker info
```

### docker使用daocloud镜像库加速

注册daocloud帐号
http://www.daocloud.io/

#### 配置Docker加速器

daocloud与阿里云的方法差不多，daocloud提供两种方式：

##### 加速器2.0配置方法

由于CentOS6内核太旧，Docker和RedHat都不再支持，请升级您的操作系统。需要CentOS7及以上版本。

安装Docker官方的最新发行版

```
curl -sSL https://get.daocloud.io/docker | sh 
sudo chkconfig docker on 
sudo systemctl start docker
```

安装过程结束后，可执行下面命令验证安装结果。如果看到输出 active (running) 就表示安装成功。

```
sudo systemctl status docker
```

安装主机监控程序

运行安装命令

```
curl -sSL https://get.daocloud.io/daomonit/install.sh | sh -s cddd20f6b891c6d7d8fd3adf91b9585d22718c17 
```

##### 加速器1.0配置方法

登陆后取得专属加速器地址，类似这样`http://xxxxxx.m.daocloud.io`

安装或升级Docker

Docker 1.3.2版本以上支持加速器，如果您没有安装Docker或者版本较旧，请安装或升级。

配置Docker加速器

###### CentOS 7

```
sudo cp -n /lib/systemd/system/docker.service /etc/systemd/system/docker.service
sudo sed -i 'N;s|\[Service\]\n|\[Service\]\nEnvironmentFile=-/etc/sysconfig/docker\n|g' /etc/systemd/system/docker.service
sudo sed -i 's|fd://|fd:// $other_args |g' /etc/systemd/system/docker.service
#这里和官方文档有点差异,实测的时候`/etc/sysconfig/docker`文件是不存的,用以下命令新建并配置
echo 'other_args="--registry-mirror=http://xxxxxx.m.daocloud.io"'> /etc/sysconfig/docker
sudo systemctl daemon-reload
sudo service docker restart
```

###### CentOS 6

```
sudo sed -i "s|other_args=\"|other_args=\"--registry-mirror=http://xxxxxx.m.daocloud.io |g" /etc/sysconfig/docker
sudo service docker restart
```

该脚本可以将--registry-mirror加入到你的Docker配置文件/etc/sysconfig/docker中。


### Docker加速器使用

Docker加速器使用时不需要任何额外操作。就像这样下载官方Ubuntu镜像

测试查找ubuntu镜像，并下载一个pull镜像

```
# docker search ubuntu
NAME                              DESCRIPTION                                     STARS     OFFICIAL   AUTOMATED
ubuntu                            Ubuntu is a Debian-based Linux operating s...   3687      [OK]       
ubuntu-upstart                    Upstart is an event-based replacement for ...   61        [OK]       
torusware/speedus-ubuntu          Always updated official Ubuntu docker imag...   25                   [OK]
ubuntu-debootstrap                debootstrap --variant=minbase --components...   24        [OK]       
rastasheep/ubuntu-sshd            Dockerized SSH service, built on top of of...   24                   [OK]
nickistre/ubuntu-lamp             LAMP server on Ubuntu                           6                    [OK]
nickistre/ubuntu-lamp-wordpress   LAMP on Ubuntu with wp-cli installed            5                    [OK]
nuagebec/ubuntu                   Simple always updated Ubuntu docker images...   4                    [OK]
nimmis/ubuntu                     This is a docker images different LTS vers...   4                    [OK]
maxexcloo/ubuntu                  Docker base image built on Ubuntu with Sup...   2                    [OK]
sylvainlasnier/ubuntu             Ubuntu 15.10 root docker images with commo...   2                    [OK]
admiringworm/ubuntu               Base ubuntu images based on the official u...   1                    [OK]
darksheer/ubuntu                  Base Ubuntu Image -- Updated hourly             1                    [OK]
jordi/ubuntu                      Ubuntu Base Image                               1                    [OK]
life360/ubuntu                    Ubuntu is a Debian-based Linux operating s...   0                    [OK]
konstruktoid/ubuntu               Ubuntu base image                               0                    [OK]
webhippie/ubuntu                  Docker images for ubuntu                        0                    [OK]
esycat/ubuntu                     Ubuntu LTS                                      0                    [OK]
lynxtp/ubuntu                     https://github.com/lynxtp/docker-ubuntu         0                    [OK]
rallias/ubuntu                    Ubuntu with the needful                         0                    [OK]
teamrock/ubuntu                   TeamRock's Ubuntu image configured with AW...   0                    [OK]
widerplan/ubuntu                  Our basic Ubuntu images.                        0                    [OK]
ustclug/ubuntu                    ubuntu image for docker with USTC mirror        0                    [OK]
suzlab/ubuntu                     ubuntu                                          0                    [OK]
uvatbc/ubuntu                     Ubuntu images with unprivileged user            0                    [OK]
```
```
# docker pull ubuntu
Using default tag: latest
latest: Pulling from library/ubuntu
759d6771041e: Pull complete 
8836b825667b: Pull complete 
c2f5e51744e6: Pull complete 
a3ed95caeb02: Pull complete 
Digest: sha256:b4dbab2d8029edddfe494f42183de20b7e2e871a424ff16ffe7b15a31f102536
Status: Downloaded newer image for ubuntu:latest
```

查看镜像信息

```
# docker images     
REPOSITORY                              TAG                 IMAGE ID            CREATED             SIZE
ubuntu                                  latest              b72889fa879c        6 days ago          187.9 MB
mysql                                   latest              63a92d0c131d        7 days ago          374 MB
daocloud.io/daocloud/daocloud-toolset   latest              1ca651dfc92a        8 days ago          150.2 MB
nginx                                   latest              82422ac65f7b        2 weeks ago         182.6 MB
java                                    7                   8cb5d3124efe        2 weeks ago         588.1 MB
```