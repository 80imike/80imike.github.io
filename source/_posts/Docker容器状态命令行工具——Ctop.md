---
category: docker
title: Docker容器状态命令行工具——Ctop
date: 2017-03-16 09:00:00
tags: [linux, docker]
abbrlink:
updated:
toc_number: false
---

Ctop是和Linux top展示效果类似的一个容器状态监视工具，Ctop可以动态的显示容器的cpu、内存、网络的使用情况。一共有两个叫Ctop的命令行工具，分别由GO和Python实现。Python实现的版本功能更强大一些。

<!-- more -->

### GO实现版本

官方地址：https://bcicen.github.io/ctop/

**安装**

- Linux

```
$ wget https://github.com/bcicen/ctop/releases/download/v0.5/ctop-0.5-linux-amd64 -O ctop
$ sudo mv ctop /usr/local/bin/
$ sudo chmod +x /usr/local/bin/ctop
```

- OS X

方法一

```
$ brew install ctop
```

方法二

```
$ curl -Lo ctop https://github.com/bcicen/ctop/releases/download/v0.5/ctop-0.5-darwin-amd64
$ sudo mv ctop /usr/local/bin/
$ sudo chmod +x /usr/local/bin/ctop
```

- 通过Docker安装

```
$ docker run -ti --name ctop --rm -v /var/run/docker.sock:/var/run/docker.sock quay.io/vektorlab/ctop:latest
```

**使用**

运行前需要使用`DOCKER_HOST`环境变量配置下需要管理的Docker进程的地址

```
$ export DOCKER_HOST=tcp://127.0.0.1:2375
$ ctop
```

运行效果

![](http://www.hi-linux.com/img/linux/grid.gif)

选项说明

Option | Description
--- | ---
-a	| show active containers only
-f <string> | set an initial filter string
-h	| display help dialog
-i  | invert default colors
-r	| reverse container sort order
-s  | select initial container sort field
-v	| output version information and exit

常用键盘快捷键

Key | Action
--- | ---
a | Toggle display of all (running and non-running) containers
f | Filter displayed containers (`esc` to clear when open)
H | Toggle ctop header
h | Open help dialog
s | Select container sort field
r | Reverse container sort order
q | Quit ctop


### Python实现版本

Python实现的Ctop有如下一些功能：

- 收集cpu，pids，内存和块输入输出的度量值
- 收集元数据，比如任务数，属主、容器技术等相关信息
- 通过任意栏对信息排序
- 按照容器类型进行筛选(docker, lxc, systemd, ...)
- 以树状视图显示信息
- 折叠/展开cgroup树
- 选择并跟踪cgroup/容器
- 选择显示数据刷新的时间窗口
- 暂停刷新数据
- 检测基于systemd、Docker和LXC的容器
- Python >= 2.6 or Python >= 3.0没有外部依赖
- 基于Docker和LXC的容器的高级特性
- 打开/连接shell以进行深度诊断
- 停止/杀死容器类型


官方网址：https://github.com/yadutaf/ctop

**安装**

Ctop Python版本需要`Python 2.6`或其更高版本外（带有内建的光标支持），别无其它外部依赖。推荐使用Python的pip进行安装。

安装pip

```
$ apt-get install python-pip
```

安装ctop

```
$ pip install ctop
```

**使用**

运行

```
$ ctop
```

运行效果

![](http://www.hi-linux.com/img/linux/screenshot.png)

当你进入ctop屏幕，可使用上（↑）和下（↓）箭头键在容器间导航。按q或Ctrl+C退出。

选项说明

```
  Monitor local cgroups as used by Docker, LXC, SystemD, ...

  Usage:
    ctop [--tree] [--refresh=<seconds>] [--columns=<columns>] [--sort-col=<sort-col>] [--follow=<name>] [--fold=<cgroup>, ...] [--type=<container type>, ...]
    ctop (-h | --help)

  Options:
    --tree                 Show tree view by default.
    --fold=<name>          Start with <name> cgroup path folded
    --follow=<name>        Follow/highlight cgroup at path.
    --type=TYPE            Only show containers of this type
    --refresh=<seconds>    Refresh display every <seconds> [default: 1].
    --columns=<columns>    List of optional columns to display. Always includes 'name'. [default: owner,processes,memory,cpu-sys,cpu-user,blkio,cpu-time].
    --sort-col=<sort-col>  Select column to sort by initially. Can be changed dynamically. [default: cpu-user]
    -h --help              Show this screen.
```


常用键盘快捷键

- press `p` to toggle/pause the refresh and select text.
- press `f` to let selected line follow / stay on the same container. Default: Don't follow.
- press `q` or ``Ctrl+C`` to quit.
- press `F5` to toggle tree/list view. Default: list view.
- press `↑` and ``↓`` to navigate between containers.
- press `+` or `-` to toggle child cgroup folding
- click on title line to select sort column / reverse sort order.
- click on any container line to select it.

Additionally, for supported container types (Currently Docker, LXC and OpenVZ):

- press `a` to attach to console output.
- press `e` to open a shell in the container context. Aka 'enter' container.
- press `s` to stop the container (SIGTERM).
- press `k` to kill the container (SIGKILL).
- press `c` to checkpointing the container(OpenVZ only now - run 'vzctl chkpnt CTID')

### 参考文档

http://www.google.com
https://github.com/yadutaf/ctop
https://github.com/bcicen/ctop
