---
category: Docker
title: 在特定环境中安装指定版本的Docker
date: 2017-06-26 9:00:00
tags: [Docker,技巧]
abbrlink:
updated:
toc_number: false
---

通常用官方提供的安装脚本或软件源安装都是安装的比较新 Docker 版本，有时我们需要在一些特定环境的服务器上安装指定版本的 Docker。今天我们就来讲一讲如何安装指定版本的 Docker 。

### 通过手动安装

#### 增加软件安装源

- Ubuntu

导入软件仓库证书

```
$ apt-key adv --keyserver hkp://pgp.mit.edu:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
```

<!-- more -->

新增一个 docker.list 文件，在其中增加对应的软件安装源。

```
# Ubuntu Precise
deb https://apt.dockerproject.org/repo ubuntu-precise main

# Ubuntu Trusty
deb https://apt.dockerproject.org/repo ubuntu-trusty main

# Ubuntu Xenial
deb https://apt.dockerproject.org/repo ubuntu-xenial main
```

以 Ubuntu 16.04 为例：

```
$ vim  /etc/apt/sources.list.d/docker.list

deb https://apt.dockerproject.org/repo ubuntu-xenial main
```

- CentOS

新增一个 docker.repo 文件，在其中增加对应的软件安装源。 这里以 CentOS 7 为例：

```
$ cat >/etc/yum.repos.d/docker.repo <<EOF
[dockerrepo]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/centos/7
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg
EOF
```

#### 更新软件源

- Ubuntu

```
$ apt-get update
```

- CentOS

```
$ yum makecache
```

#### 显示软件源中所有Docker软件包安装信息

- Ubuntu

```
$ apt-cache policy docker-engine

docker-engine:
  Installed: (none)
  Candidate: 17.05.0~ce-0~ubuntu-xenial
  Version table:
     17.05.0~ce-0~ubuntu-xenial 500
        500 https://apt.dockerproject.org/repo ubuntu-xenial/main amd64 Packages
     17.04.0~ce-0~ubuntu-xenial 500
        500 https://apt.dockerproject.org/repo ubuntu-xenial/main amd64 Packages
     17.03.1~ce-0~ubuntu-xenial 500
        500 https://apt.dockerproject.org/repo ubuntu-xenial/main amd64 Packages
     17.03.0~ce-0~ubuntu-xenial 500
        500 https://apt.dockerproject.org/repo ubuntu-xenial/main amd64 Packages
     1.13.1-0~ubuntu-xenial 500
        500 https://apt.dockerproject.org/repo ubuntu-xenial/main amd64 Packages
     1.13.0-0~ubuntu-xenial 500
        500 https://apt.dockerproject.org/repo ubuntu-xenial/main amd64 Packages
     1.12.6-0~ubuntu-xenial 500
        500 https://apt.dockerproject.org/repo ubuntu-xenial/main amd64 Packages
     1.12.5-0~ubuntu-xenial 500
        500 https://apt.dockerproject.org/repo ubuntu-xenial/main amd64 Packages
     1.12.4-0~ubuntu-xenial 500
        500 https://apt.dockerproject.org/repo ubuntu-xenial/main amd64 Packages
     1.12.3-0~xenial 500
        500 https://apt.dockerproject.org/repo ubuntu-xenial/main amd64 Packages
     1.12.2-0~xenial 500
        500 https://apt.dockerproject.org/repo ubuntu-xenial/main amd64 Packages
     1.12.1-0~xenial 500
        500 https://apt.dockerproject.org/repo ubuntu-xenial/main amd64 Packages
     1.12.0-0~xenial 500
        500 https://apt.dockerproject.org/repo ubuntu-xenial/main amd64 Packages
     1.11.2-0~xenial 500
        500 https://apt.dockerproject.org/repo ubuntu-xenial/main amd64 Packages
     1.11.1-0~xenial 500
        500 https://apt.dockerproject.org/repo ubuntu-xenial/main amd64 Packages
     1.11.0-0~xenial 500
        500 https://apt.dockerproject.org/repo ubuntu-xenial/main amd64 Packages
```

- CentOS

```
$ yum provides docker-engine
```

#### 移除其它版本Docker

如果之前存在其它版本的Docker，可以使用以下命令先移出：

- Ubuntu

```
$ apt-get purge docker-engine
```

- CentOS

```
$ yum remove docker-engine
```

#### 安装指定版本Docker

根据实际情况，选定要安装的 Docker 版本进行安装。这里以安装 1.13.1 版本为例：

- Ubuntu

如果 Ubuntu 为 14.04 建议先装上以下两个软件包。

```
$ apt-get install \
    linux-image-extra-$(uname -r) \
    linux-image-extra-virtual
```

```
$ apt-get install docker-engine=1.13.1-0~ubuntu-xenial
```

- CentOS

```
$ yum install docker-engine-1.13.1-1.el7.centos.x86_64
```

#### 验证Docker版本

```
$ docker -v
Docker version 1.13.1, build 092cba3
```

### 通过脚本一键安装

如果觉得手动安装太过复杂，也可以直接使用下面的脚本一键安装：

```
$ curl -sSL https://github.com/gitlawr/install-docker/blob/1.0/<docker-version-you-want>.sh?raw=true | sh
```

或者:

```
$ wget -qO- https://github.com/gitlawr/install-docker/blob/1.0/<docker-version-you-want>.sh?raw=true | sh
```

使用需要的 `Docker` 版本替换以下脚本中的 `<docker-version-you-want>`，目前该脚本支持的 `Docker` 版本：

```
1.10.3
1.11.2
1.12.1
1.12.2
1.12.3
1.12.4
1.12.5
1.12.6
1.13.0
1.13.1
17.03.0
17.03.1
17.04.0
```

> 注：脚本使用 `USTC` 的软件包仓库，已基于 `Ubuntu_Xenial` , `CentOS7`  以及 `Debian_Jessie` 完成测试。脚本会根据 `Linux` 发行版有少许区别，比如 `Ubuntu 16.04` 下不兼容 Docker-1.10.3。

这里以安装 1.13.1 为例：

![](https://www.hi-linux.com/img/linux/docker-spec-install.png)

### 参考文档

http://www.google.com
http://www.cnrancher.com/install-docker/
http://www.cnblogs.com/yanghuahui/p/4874937.html
https://blog.phpgao.com/docker_install_specific_version.html
