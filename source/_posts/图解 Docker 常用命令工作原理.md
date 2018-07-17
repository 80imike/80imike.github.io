---
category: Docker
title: 图解 Docker 常用命令工作原理
date: 2018-07-08 09:00:00
tags: [Linux, Docker]
abbrlink:
updated:
toc_number: false
---

### Dokcer 常用命令工作原理

- Docker 常用命令工作原理图

![](https://www.hi-linux.com/img/linux/docker-cmd-01.png)

- Image Layer（镜像层）

镜像可以看成是由多个镜像层叠加起来的一个文件系统，镜像层也可以简单理解为一个基本的镜像，而每个镜像层之间通过指针的形式进行叠加。

![](https://www.hi-linux.com/img/linux/docker-cmd-02.png)

根据上图，镜像层的主要组成部分包括镜像层 ID、镜像层指针 「指向父层」、元数据「 Layer Metadata，包含了 Docker 构建和运行的信息和父层的层次信息」。

只读层和读写层「Top Layer」的组成部分基本一致，同时读写层可以转换成只读层「 通过`docker commit` 操作实现」。

<!-- more -->

- Image（镜像，只读层的集合）

镜像是一堆只读层的统一视角，除了最底层没有指向外，每一层都指向它的父层。统一文件系统（ Union File System）技术能够将不同的层整合成一个文件系统，为这些层提供了一个统一的视角，这样就隐藏了多层的存在。在用户的角度看来，只存在一个文件系统。镜像每一层都是不可写的，都是只读层。

![](https://www.hi-linux.com/img/linux/docker-cmd-03.png)

-  Container（容器，一层读写层+多层只读层）

容器和镜像的区别在于容器的最上面一层是读写层「Top Layer」，在这里并没有区分容器是否在运行。

运行状态的容器「Running Container」是由一个可读写的文件系统「静态容器」+ 隔离的进程空间和其中的进程构成的。

 ![](https://www.hi-linux.com/img/linux/docker-cmd-04.png)

隔离的进程空间中的进程可以对该读写层进行增删改，运行状态容器的进程操作都作用在该读写层上。每个容器只能有一个进程隔离空间。

![](https://www.hi-linux.com/img/linux/docker-cmd-05.png)

### Docker 常用命令说明

#### 标识说明

- Image（统一只读文件系统）

![](https://www.hi-linux.com/img/linux/docker-cmd-06.png)

- 静态容器 （未运行的容器，统一可读写文件系统）

![](https://www.hi-linux.com/img/linux/docker-cmd-07.png)

- 动态容器（运行中的容器，进程空间（包括进程）+ 统一可读写文件系统）

![](https://www.hi-linux.com/img/linux/docker-cmd-08.png)

#### 命令说明

##### Docker 生命周期相关命令

- docker create < image-id >

![](https://www.hi-linux.com/img/linux/docker-cmd-09.png)

该命令即为在只读文件系统上添加一层可读写层「Top Layer」，并生成可读写文件系统。该命令状态下容器为静态容器，并没有运行。

- docker start | restart < container-id >        

![](https://www.hi-linux.com/img/linux/docker-cmd-10.png)

该命令即为在可读写文件系统添加一个进程空间和运行的进程，并生成一个动态容器。

> `docker stop` 即为 `docker start` 的逆过程。

- docker run < image-id >

![](https://www.hi-linux.com/img/linux/docker-cmd-11.png)

`docker run` = `docker create` + `docker start`

docker run 流程类似如下：

![](https://www.hi-linux.com/img/linux/docker-cmd-12.png)

- docker stop < container-id >

![](https://www.hi-linux.com/img/linux/docker-cmd-13.png)

该指令向运行中的容器发一个 SIGTERM 信号，然后停止所有的进程。即为 `docker start` 的逆过程。

- docker kill < container-id >

![](https://www.hi-linux.com/img/linux/docker-cmd-14.png)

该指令向容器发送一个不友好的 SIGKILL 信号，相当于快速强制关闭容器。与 `docker stop` 的区别是 `docker stop` 是先发 SIGTERM 信号来清理进程，然后再发 SIGKILL 信号退出，整个进程是正常关闭的。

- docker pause < container-id >

![](https://www.hi-linux.com/img/linux/docker-cmd-15.png)

该指令用作暂停容器中的所有进程，使用 cgroup 的 freezer 顺序暂停容器里的所有进程。

> docker unpause 为其逆过程即恢复所有进程，比较少使用。

- docker commit < container-id >

![](https://www.hi-linux.com/img/linux/docker-cmd-16.png)

![](https://www.hi-linux.com/img/linux/docker-cmd-17.png)

该指令用作把容器的可读写层转化成只读层，即从容器状态「可读写文件系统」变为镜像状态「只读文件系统」，可理解为固化。

- docker build

![](https://www.hi-linux.com/img/linux/docker-cmd-18.png)

![](https://www.hi-linux.com/img/linux/docker-cmd-19.png)

`docker build` = `docker run` 「运行容器 + 进程修改数据」+ `docker commit`「固化数据」，整个过程不断循环直至生成所需镜像。

> 1. 循环一次便会形成一个新的层(新镜像 = 原镜像层 + 已固化的可读写层）
> 2. docker build 过程一般通过 dockerfile 文件来实现。

##### Docker 查询类命令

Docker 可查询的对象有：image、container、image/container 中的数据、系统信息（包括容器数、镜像数及其它）。

- docker images

![](https://www.hi-linux.com/img/linux/docker-cmd-20.png)

该指令用作列出镜像的顶层镜像（以顶层镜像 ID 来表示整个完整镜像），每个顶层镜像下面隐藏多个镜像层。

- docker images -a

![](https://www.hi-linux.com/img/linux/docker-cmd-21.png)

该指令用作列出镜像的所有镜像层。镜像层的排序以每个顶层镜像 ID 为首，依次列出每个镜像下的所有镜像层。

- docker history < image-id >

![](https://www.hi-linux.com/img/linux/docker-cmd-22.png)

该指令列出该镜像 ID 下的所有历史镜像。

- docker ps

![](https://www.hi-linux.com/img/linux/docker-cmd-23.png)

该指令用作列出所有运行中的容器。

- docker ps -a 

![](https://www.hi-linux.com/img/linux/docker-cmd-24.png)

该指令用作列出所有容器，包括静态容器和动态容器。

- docker inspect < container-id > or < image-id >

![](https://www.hi-linux.com/img/linux/docker-cmd-25.png)

该指令用作提取出容器或镜像中最顶层的元数据。

- docker info

该指令用作显示 Docker 系统信息，包括镜像和容器数。

##### Docker 操作类命令

- docker rm < container-id >

![](https://www.hi-linux.com/img/linux/docker-cmd-26.png)

该指令用作移除容器，默认只能对静态容器（非运行状态的）进行移除。如果要移除运行中的容器，需要使用 `-f（force）` 参数，即：`docker rm -f <container-id>`。

- docker rmi < image-id >

![](https://www.hi-linux.com/img/linux/docker-cmd-27.png)

该指令作用与 `docker rm` 类似，用作移除镜像。

- docker exec < running-container-id >

![](https://www.hi-linux.com/img/linux/docker-cmd-28.png)

该指令用于在运行状态的容器中执行一个新的进程。

- docker export < container-id >

![](https://www.hi-linux.com/img/linux/docker-cmd-29.png)

该指令用作持久化一个容器，会创建一个 tar 格式的文件。该文件移除了元数据和不必要的层，将多个层整合成了一个层，只保存了当前统一视角看到的内容。

如果你要持久化一个镜像，可以使用 `docker save` 指令。它与 `docker export` 的区别在于其保留了所有元数据和历史层。

通过 `docker export` 导出的容器再 `docker import` 到 Docker 中后，在 `docker images –tree` 命令只能看到一个镜像。而通过 `docker save` 保存后的镜像则不同，它能够看到这个镜像构建过程中的所有历史层。

`docker export` 和 `docker save` 两者更多的区别可参考「[Docker 的 save 和 export 命令的区别](https://mp.weixin.qq.com/s?__biz=MzI3MTI2NzkxMA==&mid=2247485543&idx=1&sn=93c14014ae4f01bceb5a59520903b21f&chksm=eac5294eddb2a0580673642e0ed35ce638b4f8b5d37ec6991c75f4705bcfdb50b633bd0474d0&mpshare=1&scene=23&srcid=0708ouNaEe7BDhuhCx3jY8fc%23rd)」一文。

> 本文在 「[Docker 常用命令原理图](http://www.huweihuang.com/article/docker/docker-commands-principle/)」的基础上整理和修改。

### 参考文档

http://www.google.com
http://t.cn/RdC2419
http://t.cn/RUfqHh9