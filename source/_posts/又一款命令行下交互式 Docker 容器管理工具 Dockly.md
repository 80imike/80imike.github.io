---
category: Docker
title: 又一款命令行下交互式 Docker 容器管理工具 Dockly
date: 2018-06-19 09:00:00
tags: [Linux, Docker]
abbrlink:
updated:
toc_number: false
---

在不久前给大家推荐过一款命令行下交互式 `Docker` 容器管理工具 [Dry](https://mp.weixin.qq.com/s?__biz=MzI3MTI2NzkxMA==&mid=2247485950&idx=1&sn=fe6639a5c9e7c3950157701c203212b5&chksm=eac528d7ddb2a1c1e8b4984cbf7ed14a0217714c1ce0d7359ac97f97f3f86d9beff53589bdf8#rd)，今天再给大家介绍一款与其类似的 `Docker` 容器管理工具 `Dockly`。

`Dockly` 是一个使用 `Node.js` 编写的开源软件，功能上和 [Dry](https://mp.weixin.qq.com/s?__biz=MzI3MTI2NzkxMA==&mid=2247485950&idx=1&sn=fe6639a5c9e7c3950157701c203212b5&chksm=eac528d7ddb2a1c1e8b4984cbf7ed14a0217714c1ce0d7359ac97f97f3f86d9beff53589bdf8#rd) 类似。`Dockly` 可以很方便的通过 `NPM` 进行安装，并支持在 Linux、macOS 和 Windows 上运行。

项目地址：https://github.com/lirantal/dockly

### 安装 Dockly

由于 `Dockly` 是使用 `Node.js` 开发的， `Dockly` 对 `Node.js` 版本有以下要求: `Node.js` >= 7.6，`NPM` >= 3.6。目前比较流行的几个 Linux 发行版默认仓库中的 `Node.js` 版本都比较低，比如 Ubuntu 16.04 中的  `Node.js` 版本为 4.x。 

在安装 `Dockly` 前，我们首先需要用官方源来安装较新版本的 `Node.js`。这里以 Ubuntu 为例：

```
$ sudo curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
$ sudo apt-get install -y nodejs
```

其它发行版本的安装方法可参考[官方安装文档](https://nodejs.org/en/download/package-manager/)，这里就不再详述了。在完成 `Node.js` 的安装后， 接下来我们只需用 `NPM` 工具就可以很容易的完成 `Dockly` 的安装。

```
$ sudo npm install -g dockly
```

<!-- more -->

### 运行 Dockly

启动 `Dockly` 的方法很简单，只需在命令行下直接运行就可以了。它会通过默认的 Unix Socket 自动连接到本地 `Docker` 守护进程。如果你 `Docker` 的 Unix Socket 不在默认位置，可以使用 `-s` 或 `--socketPath` 参数指定。

```
$ dockly
```

![](https://www.hi-linux.com/img/linux/dockly1.png)

### 使用 Dockly

`Dockly` 默认运行界面会显示所有容器的一些基本信息，比如：容器的 ID、容器的名称、容器所使用的镜像、容器运行的命令、容器的状态等信息。

![](https://www.hi-linux.com/img/linux/dockly2.png)

- 管理 Docker 容器

`Dockly` 对容器管理提供了查看、重启、删除容器等操作。

在选定容器上按下 `i` 键即可查看容器的相关信息。

![](https://www.hi-linux.com/img/linux/dockly4.png)

在选定容器上按下 `m` 键即可对容器进行一些管理。

![](https://www.hi-linux.com/img/linux/dockly5.png)

- 查看 Docker 容器日志

如果你在 `Dockly` 主界面选中的容器上单击回车键，你就可以实时查看该容器的日志。

![](https://www.hi-linux.com/img/linux/dockly3.png)

- 其它操作

`Dockly` 操作主要通过下方提供的快捷菜单来实现，主要有以下这些：

1. 按下 `=` 键即可对当前界面进行刷新。
2. 按下 `l` 键即可快速进入当前容器的 Shell。
3. 按下 `r` 键即可快速重启当前容器。
4. 按下 `s` 键即可快速停止当前容器。
5. 按下 `v` 键即可快速进入查看模式。
6. 按下 `q` 键即可退出 Dockly。
7. 按下 `h` 键即可查询帮助来获得更详细的使用说明。

`Dockly` 虽然目前在整体功能上并没有 `Dry` 强大，但是在命令行下交互式  `Docker` 管理工具上也算给了我们更多一种选择吧。指不定哪一天就发展强大了呢，开源世界一切皆有可能的。有兴趣的同学不妨试一下！

### 参考文档

http://www.google.com
https://github.com/lirantal/dockly