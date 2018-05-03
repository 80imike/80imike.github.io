---
category: Docker
title: Docker 下部署 .NET 应用教程
date: 2018-05-03 09:00:00
tags: [Linux, Docker]
abbrlink:
updated:
toc_number: false
---

我们在 「[Ubuntu 下部署 .NET 应用教程](https://www.hi-linux.com/posts/60756.html)」一文中讲解了如何在 Linux 环境下部署 .Net 环境和进行了一个具体应用的部署。

目前将应用部署容器化早已是大趋势，Docker 这样的容器化技术极大地简化了程序的部署工作。不再需要浪费时间在一个服务器上配置你程序所需的环境依赖文件，你只需要创建一个 Docker 镜像，里面包含你程序运行所需的一切，然后在任何 Docker 宿主机上作为容器启动起来就行了。本文就来说说如何在 Docker 环境下部署 .Net 应用。

开始之前，首先你需要在机器上安装好 Docker。Docker 安装也是非常简单的，这里就不再累述了。如果你还不会安装可以搜索公众号上相关文章或者直接参考官方文档：https://docs.docker.com/install/

安装完成后要检验是否安装成功，可以执行：

```
$ docker --version
```

接下来，我们就来看看如何在 Docker 下部署 .Net 应用。Docker 部署应用的方式多种多样，这里我们主要讲如何通过 Dockerfile 和 Docker-Compose 进行部署。

<!-- more -->

###  通过 Dockerfile 进行 .Net 应用部署

Dockerfile 是由一系列命令和参数构成的脚本，一个 Dockerfile 里面包含了构建整个 Docker 映像的完整命令，我们会通过这些命令创建一个适合 .Net 应用部署的新镜像。

这里我们使用 「[Ubuntu 下部署 .NET 应用教程](https://www.hi-linux.com/posts/60756.html)」一文中提到的 NETCoreBBS 项目来演示。编写 Dockerfile 前我们需要做如下一些准备工作：

```
# 建立一个用于 Docker 工作的目录
$ mkdir NETCoreBBS-Docker
# 复制之前编译好的部署代码到 NETCoreBBS-Docker 目录
$ cp -rf NETCoreBBS/src/NetCoreBBS/bin/Debug/netcoreapp2.0/publish/ NETCoreBBS-Docker/
# 切换到 NETCoreBBS-Docker 工作目录
$ cd NETCoreBBS-Docker
```

接下来编写一个适用于 .Net 应用镜像的 Dockerfile。

```
$ vim Dockerfile

FROM microsoft/dotnet:latest
COPY publish /app
WORKDIR /app
EXPOSE 8000/tcp
ENV ASPNETCORE_URLS http://*:8000
ENTRYPOINT ["dotnet", "NetCoreBBS.dll"]
```

这里我们简单说说以上几条 Dockerfile 中的指令的作用：

- FROM microsoft/dotnet:latest

第一个指令必须为 FROM。 此指令用于初始化新的镜像生成阶段，并为剩余指令设置基础映像。 本示例的基础映像是微软发布的 microsoft/dotnet ，这个镜像将确保容器包含运行 `ASP.NET Core` 应用所需的一切基础环境。

- COPY publish /app

复制 publish 目录下编译好的项目源码到 Docker 镜像里的 /app 目录。

- WORKDIR /app

WORKDIR 指令 为 Dockerfile 中的任何 RUN，CMD，ENTRYPOINT，COPY 和 ADD 指令设置工作目录。如果 WORKDIR 不存在它将被创建，Dockerfile 中之后的命令都会在这个 /app 文件夹内执行。

- EXPOSE 8000/tcp

默认情况下，Docker 容器不会暴露任何网络端口到外部。这里通过 EXPOSE 将内部端口映射到外部 8000 端口。

- ENV ASPNETCORE_URLS http://*:8000

ENV 指令将在容器里设置环境变量。ASPNETCORE_URLS 这个变量告诉 `ASP.NET Core` 应该绑定到哪个网卡的哪个端口上。

- ENTRYPOINT ["dotnet", "NetCoreBBS.dll"]

Dockerfile 的最后一行通常都会设置一个入口程序，这里用 `dotnet NetCoreBBS.dll` 命令启动程序。

Dockerfile 编写完成后，我们就可以开始构建镜像了。Docker 是通过 `docker build` 指令执行 Dockerfile 中的一系列命令来完成自动构建镜像的。

```
$ docker build -t aspnetcore .

Sending build context to Docker daemon  214.2MB
Step 1/6 : FROM microsoft/dotnet:latest
 ---> ae53eff0f099
Step 2/6 : COPY publish /app
 ---> 92b10a218e58
Step 3/6 : WORKDIR /app
Removing intermediate container 83c530a6dbf4
 ---> a5ba92f15324
Step 4/6 : EXPOSE 8000/tcp
 ---> Running in 294682400e71
Removing intermediate container 294682400e71
 ---> ef5431fb28d8
Step 5/6 : ENV ASPNETCORE_URLS http://*:8000
 ---> Running in e9cee7648025
Removing intermediate container e9cee7648025
 ---> 89513e3fcc64
Step 6/6 : ENTRYPOINT ["dotnet", "NetCoreBBS.dll"]
 ---> Running in c8e81b5bed09
Removing intermediate container c8e81b5bed09
 ---> e780d5110f71
Successfully built e780d5110f71
Successfully tagged aspnetcore:latest
```

运行 `docker images` 命令可列出全部镜像。

```
$ docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
aspnetcore          latest              e780d5110f71        3 minutes ago       1.78GB
microsoft/dotnet    latest              ae53eff0f099        3 days ago          1.74GB
```

镜像创建完成后，我们就可以通过这个镜像来创建一个运行有 .NET 应用的容器了。

```
$ docker run -it -p 8000:8000 aspnetcore

Hosting environment: Production
Content root path: /app
Now listening on: http://[::]:8000
Application started. Press Ctrl+C to shut down.
```

> -it 参数的作用是让 Docker 以交互模式运行这个容器。当你想要停止这个容器的时候可按 Ctrl+C 结束。


如果你要让容器在后台运行可使用 `-d` 参数：

```
$ docker run -d --name bbs -p 8000:8000 aspnetcore
4946b885d4413bd9243b61d595450dd68ea16052fd81c6e54807c9fea1fb0594

$ docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                    NAMES
4946b885d441        aspnetcore          "dotnet NetCoreBBS.d…"   23 seconds ago      Up 22 seconds       0.0.0.0:8000->8000/tcp   bbs
```

###  通过 Docker-Compose 进行 .Net 应用部署

Docker-Compose 是 Docker 官方提供的编排工具，负责快速的部署分布式应用。Docker-Compose 是通过 docker-compose.yml 配置文件进行应用部署的。

Docker-Compose 并不是 Docker 软件包中自带的工具。要使用 Docker-Compose 需要独立的安装，Docker-Compose 的安装也非常的简单，你可以通过以下指令来完成安装：

```
$ pip install docker-compose
```

通过 Docker-Compose 方式部署容器大大的简化了操作步骤，一共只需要下面两步：

- 编写 docker-compose.yml 文件

```
$ vim docker-compose.yml

dotnet:
  container_name: bbs
  image: microsoft/dotnet:latest
  restart: always
  ports:
    - 8000:8000
  volumes:
    - ./publish:/app/
  environment:
    - ASPNETCORE_URLS http://*:8000
  working_dir: /app
  command: ["dotnet","NetCoreBBS.dll"]
```

配置参数含义和 Dockerfile 中类似，这里就不再累述了。 如果你先更加了解 Dockerfile 或 docker-compose.yml 语法可参考官方文档。

- 启动容器

```
$ docker-compose up -d
Creating bbs ... done

$ docker ps
CONTAINER ID        IMAGE                     COMMAND                  CREATED             STATUS              PORTS                    NAMES
61598d90134c        microsoft/dotnet:latest   "dotnet NetCoreBBS.d…"   15 seconds ago      Up 14 seconds       0.0.0.0:8000->8000/tcp   bbs
```
最后打开浏览器访问 `http://IP:8000/`，成功出现以下页面就表示部署成功了。

![](https://www.hi-linux.com/img/linux/dotnetcore1.png)

到此，我们就演示了如何在 Docker 上搭建了一个完整的 .NET 应用。

### 参考文档

http://www.google.com
http://t.cn/Rn2X39F
https://deepzz.com/post/docker-compose-file.html
https://deepzz.com/post/dockerfile-reference.html