---
category: Docker
title: 推荐一个命令行下交互式 Docker 容器管理工具 Dry
date: 2018-05-31 09:00:00
tags: [Linux, Docker]
abbrlink:
updated:
toc_number: false
---

### 什么是 Dry

Dry 是一个可管理并监控 Docker 容器和镜像的命令行工具，与 Docker 官方自带的命令行工具相比 Dry 提供了交互式操作界面。

Dry 可以更方便和直观的管理容器相关的信息，包括对应镜像、容器名称、网络、容器中运行的命令及容器状态。如果运行在 Docker Swarm 中，Dry 还会给出 Swarm 集群的各种状态信息。

Dry 不仅可以管理本地 Docker 守护进程，也可以管理远程的 Docker 守护进程。 

- 如果连接本地 Docker 守护进程，Docker 主机显示为 `unix:///var/run/docker.sock`。
- 如果连接远程 Docker 守护进程，Docker 主机显示为 `tcp://IP Address:Port Number` 或 `tcp://Host Name:Port Number`。

项目官方地址：https://github.com/moncho/dry

<!-- more -->

### 安装 Dry

Dry 的安装非常简单，只需使用官方提供的脚本就可以很方便安装在对应的系统上。Dry 目前支持的操作系统有：macOS、Freebsd、Linux、Windows。

```
$ curl -sSf https://moncho.github.io/dry/dryup.sh | sudo sh
$ sudo chmod 755 /usr/local/bin/dry
```

除了使用预编译的二进制包安装外，官方还提供了多种多样的安装方式。比如：mac 下 可使用 brew 进行安装，Arch Linux 下可使用 yaourt 进行安装，具体可能参考[官方文档](https://github.com/moncho/dry#installation)。

### 运行 Dry

直接在命令行下输入 `dry` 命令，便可启动一个 Dry。 Dry 默认会连接本地的 Docker 守护进程：

```
$ dry
```

Dry 默认运行界面会显示容器的一些基本信息，与 `docker ps` 命令相比 Dry 体验上会更加友好。

![](https://www.hi-linux.com/img/linux/docker-dry-01.png)

### Dry 快捷键列表

- 全局命令

Keybinding           | Description
---------------------|---------------------------------------
<kbd>%</kbd>         | filter list
<kbd>F1</kbd>        | sort list
<kbd>F5</kbd>        | refresh list
<kbd>F8</kbd>        | show docker disk usage
<kbd>F9</kbd>        | show last 10 docker events
<kbd>F10</kbd>       | show docker info
<kbd>1</kbd>         | show container list
<kbd>2</kbd>         | show image list
<kbd>3</kbd>         | show network list
<kbd>4</kbd>         | show node list (on Swarm mode)
<kbd>5</kbd>         | show service list (on Swarm mode)
<kbd>ArrowUp</kbd>   | move the cursor one line up
<kbd>ArrowDown</kbd> | move the cursor one line down
<kbd>g</kbd>         | move the cursor to the top
<kbd>G</kbd>         | move the cursor to the bottom
<kbd>q</kbd>         | quit dry


- 容器命令

Keybinding           | Description
---------------------|---------------------------------------
<kbd>Enter</kbd>     | show container command menu
<kbd>F2</kbd>        | toggle on/off showing stopped containers
<kbd>i</kbd>         | inspect
<kbd>l</kbd>         | container logs
<kbd>e</kbd>         | remove
<kbd>s</kbd>         | stats
<kbd>Ctrl+e</kbd>    | remove all stopped containers
<kbd>Ctrl+k</kbd>    | kill
<kbd>Ctrl+r</kbd>    | start/restart
<kbd>Ctrl+t</kbd>    | stop

- 镜像命令

Keybinding           | Description
---------------------|---------------------------------------
<kbd>i</kbd>         | history
<kbd>r</kbd>         | run command in new container
<kbd>Ctrl+d</kbd>    | remove dangling images
<kbd>Ctrl+e</kbd>    | remove image
<kbd>Ctrl+f</kbd>    | remove image (force)
<kbd>Enter</kbd>     | inspect

- 网络命令

Keybinding           | Description
---------------------|---------------------------------------
<kbd>Ctrl+e</kbd>    | remove network
<kbd>Enter</kbd>     | inspect

- 服务命令

Keybinding           | Description
---------------------|---------------------------------------
<kbd>i</kbd>         | inspect service
<kbd>l</kbd>         | service logs
<kbd>Ctrl+r</kbd>    | remove service
<kbd>Ctrl+s</kbd>    | scale service
<kbd>Enter</kbd>     | show service tasks

- 缓冲区操作命令

Keybinding           | Description
---------------------|---------------------------------------
<kbd>ArrowUp</kbd>   | move the cursor one line up
<kbd>ArrowDown</kbd> | move the cursor one line down
<kbd>g</kbd>         | move the cursor to the beginning of the buffer
<kbd>G</kbd>         | move the cursor to the end of the buffer
<kbd>n</kbd>         | after search, move forwards to the next search hit
<kbd>N</kbd>         | after search, move backwards to the previous search hit
<kbd>s</kbd>         | search
<kbd>pg up</kbd>     | move the cursor "screen size" lines up
<kbd>pg down</kbd>   | move the cursor "screen size" lines down


### 监控 Docker 容器

在 Dry 的运行界面中按下 `m` 键即可打开监控模式，与 `docker stats` 命令相比 Dry 具有更加详细并且彩色的输出。Dry 还有一个额外的 NAME 列，方便你很容易的区分容器。

![](https://www.hi-linux.com/img/linux/docker-dry-02.png)

### 管理 Docker 容器

如果你在 Dry 主界面选中的容器上单击回车键，你就可以管理该容器。Dry 对容器管理提供了查看日志、查看/杀死/删除容器、停止/启动/重启容器、查看容器状态及镜像历史记录等操作。

![](https://www.hi-linux.com/img/linux/docker-dry-03.png)

- 查看全部 Docker 容器

在 Dry 主界面按下 `F2` 键即可列出全部容器，包括运行中和已关闭的容器。

![](https://www.hi-linux.com/img/linux/docker-dry-04.png)

- 监控容器资源利用率

在容器管理界面，点击 `Stats+Top` 选项查看指定容器的资源利用率。你也可以按下快捷键 `s` 来打开容器资源利用率界面。

![](https://www.hi-linux.com/img/linux/docker-dry-05.png)

![](https://www.hi-linux.com/img/linux/docker-dry-06.png)

- 查看容器、镜像及本地卷的磁盘使用情况

在 Dry 主界面按下 `F8` 键即可查看容器、镜像及本地卷的磁盘使用情况。该界面明确地给出容器、镜像和卷的总数，哪些处于使用状态，以及整体磁盘使用情况、可回收空间大小的详细信息。

![](https://www.hi-linux.com/img/linux/docker-dry-07.png)

### 管理 Docker 容器镜像

在 Dry 主界面中按下 `2` 键即可列出全部的已下载镜像。

![](https://www.hi-linux.com/img/linux/docker-dry-08.png)

> 如果你想删除一个镜像，只需从界面中选择它，然后按 `Ctrl + E`。对于强制删除，你可以使用 `Ctrl + F`。

### 查看 Docker 网络列表

在 Dry 主界面按下 `3` 键即可查看全部网络及网关。

![](https://www.hi-linux.com/img/linux/docker-dry-09.png)

### 其它操作

- 如果你在使用中需要更多帮助，可按下 `H` 键查询帮助来获得更详细的使用说明。
- 如果你需要对列表项目进行排序，可按下 `F1` 键来实现。
- Dry 也支持 Docker 的 Services、Stacks 管理，你可以在 Dry 主界面中按下 `5` 键或 `6` 键切换到相应管理界面。

### 参考文档

http://www.google.com
https://github.com/moncho/dry
https://linux.cn/article-9615-1.html
https://hackernoon.com/docker-cli-alternative-dry-5e0b0839b3b8