---
category: Docker
title: 在内网环境中离线安装Docker
date: 2017-06-19 9:00:00
tags: [Docker,Linux]
abbrlink:
updated:
toc_number: false
---

因为有部分服务器在全内网环境，不能联网安装 `Docker`。这时要在服务器上安装 `Docker` 就只能下载对应安装包，离线安装 `Docker` 需要 `docker-engine`、`docker-engine-selinux`、`libtool-ltdl`这三个软件包。

下面以安装 `Docker 1.12.6` 为例讲讲如何在离线环境中安装 `Docker`，首先我们要下载对应的 `Docker` 软件包，下面的地址是官方提供的软件仓库地址，里面有各个版本的 `Docker` 软件包。

<!-- more -->

```
# CentOS
https://yum.dockerproject.org/repo/main/centos/

# Ubuntu
https://apt.dockerproject.org/repo/pool/main/d/docker-engine/
```

`Docker` 安装需要依赖 `libtool-ltdl` 软件包，`libtool-ltdl`可在`pkgs.org`这个网站搜索下载。

- 在 CentOS 7 下安装

```
$ mkdir docker_install
$ cd docker_install
$ wget https://yum.dockerproject.org/repo/main/centos/7/Packages/docker-engine-1.12.6-1.el7.centos.x86_64.rpm
$ wget https://yum.dockerproject.org/repo/main/centos/7/Packages/docker-engine-selinux-1.12.6-1.el7.centos.noarch.rpm
$ wget http://mirror.centos.org/centos/7/updates/x86_64/Packages/libtool-ltdl-2.4.2-22.el7_3.x86_64.rpm
$ rpm -ivh *.rpm
```


- 在 Ubuntu 14.04 下安装

```
$ mkdir docker_install
$ cd docker_install
$ wget https://apt.dockerproject.org/repo/pool/main/d/docker-engine/docker-engine_1.12.6-0~ubuntu-trusty_amd64.deb
$ wget http://archive.ubuntu.com/ubuntu/pool/main/libt/libtool/libltdl7_2.4.2-1.7ubuntu1_amd64.deb
$ dpkg -i *.deb
```

- 验证 Docker 是否安装成功

```
# 查看 Docker 版本信息
$ docker version
Client:
Version:      1.12.6
API version:  1.24
Go version:   go1.6.4
Git commit:   78d1802
Built:        Tue Jan 10 20:38:45 2017
OS/Arch:      linux/amd64

Server:
Version:      1.12.6
API version:  1.24
Go version:   go1.6.4
Git commit:   78d1802
Built:        Tue Jan 10 20:38:45 2017
OS/Arch:      linux/amd64
```
