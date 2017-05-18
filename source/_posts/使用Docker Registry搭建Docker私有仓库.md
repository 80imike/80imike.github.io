---
title: 使用Docker Registry搭建Docker私有仓库
tags:
  - Docker
  - Linux
categories: Docker
abbrlink: 13369
date: 2016-11-28 09:00:00
updated:
toc_number:
---

有时候使用 Docker Hub 这样的公共仓库可能不方便，并且公司的私有镜像为了业务安全，也不会push到docker hub上，用户可以创建一个本地仓库供私人使用。类似于git 和maven一样，同时节省服务器下载和上传镜像带宽。

### 什么是Docker Registry

Docker Registry由三个部分组成：index，registry，registry client。
可以把Index认为是负责登录、负责认证、负责存储镜像信息和负责对外显示的外部实现，而registry则是负责存储镜像的内部实现，而Registry Client则是docker客户端。

### 安装Docker Registry

Docker版本需要1.6以上

```bash
$ docker --version
Docker version 1.12.3, build 6b644ec
```
<!-- more -->
在本地运行registry（本机ip：192.168.3.79）

```bash
$ docker run -d -v /opt/docker-registry:/var/lib/registry -p 5000:5000 --restart=always --name registry registry
```

Registry服务默认会将上传的镜像保存在容器的/var/lib/registry，我们将主机的/opt/docker-registry目录挂载到该目录，即可实现将镜像保存到主机的/opt/docker-registry/目录了。

如果本地没有下载过docker-registry，则首次会pull registry 运行时会映射路径和端口，以后就可以从/opt/docker-registry下找到私有仓库，这里查看下我本机的镜像

```bash
$ docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
mysql               latest              cd88b71c6c8c        12 days ago         383.4 MB
debian              latest              73e72bf822ca        13 days ago         123 MB
registry            latest              c9bd19d022f6        4 weeks ago         33.3 MB
nginx               latest              a5311a310510        5 weeks ago         181.5 MB
```

从上面信息可以分别看出

* 来自于哪个仓库，比如 debian
* 镜像的标记，比如 latest 最后一个版本
* 它的 ID 号（唯一）
* 创建时间
* 镜像大小

可以看到registry容器已经启动

```bash
$ docker ps -a
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS                  PORTS                    NAMES
131155da6e75        registry            "/entrypoint.sh /etc/"   5 minutes ago       Up 5 minutes            0.0.0.0:5000->5000/tcp   registry
```

访问私有仓库

```bash
$ curl 127.0.0.1:5000/v2/_catalog
{"repositories":[]}
```

因为我们还没有像私有容器提交镜像，所以这里返回空，下面我们提交一个镜像试试，上面可以看到我本地有一个registry的镜像

### PUSH镜像

设置标签到本地的私有镜像

命令格式为

```bash
docker tag IMAGE[:TAG] [REGISTRYHOST/][USERNAME/]NAME[:TAG]
```

```bash
$ docker tag debian 127.0.0.1:5000/debian
$ docker images
REPOSITORY                  TAG                 IMAGE ID            CREATED             SIZE
127.0.0.1:5000/debian       latest              73e72bf822ca        13 days ago         123 MB
debian                      latest              73e72bf822ca        13 days ago         123 MB
registry                    latest              c9bd19d022f6        4 weeks ago         33.3 MB
nginx                       latest              a5311a310510        5 weeks ago         181.5 MB
```

镜像的 ID 唯一标识了镜像，注意到 debian 和 127.0.0.1:5000/debian具有相同的镜像 ID，说明它们实际上是同一镜像。

然后我们将这个镜像push到私有镜像库

```bash
$ docker push 127.0.0.1:5000/debian
The push refers to a repository [127.0.0.1:5000/debian]
fe4c16cbf7a4: Pushed
latest: digest: sha256:c1ce85a0f7126a3b5cbf7c57676b01b37c755b9ff9e2f39ca88181c02b985724 size: 529
```

然后在看下私有仓库中有没有镜像

```bash
$ curl 127.0.0.1:5000/v2/_catalog
{"repositories":["debian"]}
```

可以看到一个叫debian的镜像存在了，其他服务器就可以来下载这个镜像使用了。

### 从其它服务器上面拉取镜像

```bash
$ docker pull 192.168.3.79:5000/debian

$ docker images
REPOSITORY                 TAG                 IMAGE ID            CREATED             SIZE
192.168.3.79:5000/debian   latest              73e72bf822ca        13 days ago         123 MB
```

可能存在的问题

出现无法从私有仓库pull镜像或无法push到私有仓库的问题，类似如下报错。

```bash
$ docker pull 192.168.3.79:5000/debian
Using default tag: latest
Error response from daemon: Get https://192.168.3.79:5000/v1/_ping: http: server gave HTTP response to HTTPS client
```

这是因为我们启动的registry服务不是安全可信赖的。这是我们需要修改docker的配置文件/etc/default/docker，添加下面的内容，

```bash
$ vim /etc/default/docker
DOCKER_OPTS="--insecure-registry 182.168.3.79:5000"
```

然后重启docker后台进程，

```bash
$ sudo service docker restart
```

然后再PULL即可。

### 其它技巧

* 如果本地有很多镜像想批量上传怎么办，可以用这个脚本

```bash
$ wget https://github.com/yeasy/docker_practice/raw/master/_local/push_images.sh
$ chmod a+x push_images.sh
$ dos2unix push_images.sh  #这个脚本换行有点问题，需要先转换成Linux下的换行。
$ ./push_images.sh ubuntu:latest centos:centos7
```

* 将本地更新后的容器，提交到私有仓库

记录容器ID

```bash
$ docker ps
```

将容器更新提交到镜像：

```bash
$ docker commit -m "Add vim"  69e873e0c48e 127.0.0.1:5000/ubuntu
```

Push到私有仓库

```bash
$ docker push 127.0.0.1:5000/ubuntu
```

### 参考文档

http://www.google.com
http://www.jianshu.com/p/58700f2b0730
http://www.cnblogs.com/lienhua34/p/4922130.html
http://t.cn/RLtyuWd
