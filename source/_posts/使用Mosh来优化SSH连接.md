---
title: 使用Mosh来优化SSH连接
tags:
  - SSH
  - Linux
categories: SSH
abbrlink: 23118
date: 2016-07-19 09:00:01
updated:
toc_number:
---

### 什么是Mosh

Mosh表示移动Shell(Mobile Shell)，是一个用于从客户端跨互联网连接远程服务器的命令行工具。它能用于SSH连接，但是比Secure Shell功能更多。它是一个类似于SSH而带有更多功能的应用。程序最初由Keith Winstein 编写，用于类Unix的操作系统中，发布于GNU GPL V3协议下。

Mosh最大的特点是基于UDP方式传输，支持在服务端创建一个临时的Key供客户端一次性连接，退出后失效；也支持通过SSH的配置进行认证，但数据传输本身还是自身的UDP方式。

<!-- more -->

另外，Mosh还有两个我觉得非常有用的功能

- 会话的中断不会导致当前正在前端执行的命令中断，相当于你所有的操作都是在screen命令中一样在后台执行。
- 会话在中断过后，不会立刻退出，而是启用一个计时器，当网络恢复后会自动重新连接，同时会延续之前的会话，不会重新开启一个。

#### Mosh的功能

- 它是一个支持漫游的远程终端程序
- 在所有主流的类 Unix 版本中可用，如 Linux、FreeBSD、Solaris、Mac OS X和Android
- 支持不稳定连接
- 支持智能的本地回显
- 支持用户输入的行编辑
- 响应式设计及在 wifi、3G、长距离连接下的鲁棒性
- 在IP改变后保持连接。它使用UDP代替TCP(在SSH中使用)，当连接被重置或者获得新的IP后TCP会超时，但是UDP仍然保持连接
- 在很长的时候之后恢复会话时仍然保持连接
- 没有网络延迟。立即显示用户输入和删除而没有延迟
- 像SSH那样支持一些旧的方式登录
- 包丢失处理机制

### Mosh安装配置

Mosh需要同时在服务器端与客户端上安装，这是一件非常简单的事情。

#### Linux中安装Mosh

- 在Debian、Ubuntu 和Mint 类似的系统中，你可以很容易地用apt-get包管理器安装。

```
$ apt-get update
$ apt-get install mosh
```

- 在基于RHEL/CentOS/Fedora的系统中，要使用yum包管理器安装mosh，你需要打开第三方的EPEL。

```
$ yum update
$ yum install mosh
```

- 在Fedora 22+的版本中，你需要使用dnf包管理器来安装Mosh。

```
$ dnf install mosh
```

#### MAC中安装Mosh

```
$ brew install mosh
$ brew install --HEAD mosh #安装git最新版本
```

**注：目前Mosh的最新版本是1.2.4，这个版本有一个小问题就是不会汇报鼠标事件，如果你在远程的VIM或者tmux等支持鼠标事件的程序中喜欢用滚轮或者触摸屏滚动屏幕的话，可能会有点不习惯。如果不能忍可以自己编译安装Git里的最新版本的Mosh。**


#### 检查Mosh的版本

```
$ mosh --version
mosh 1.2.4
Copyright 2012 Keith Winstein <mosh-devel@mit.edu>
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
```

你可以输入exit来退出Mosh会话。

```
$ exit
```

### Mosh参数说明

Mosh支持很多选项，你可以用下面的方法看到

```
$ mosh --help
Usage: /usr/bin/mosh [options] [--] [user@]host [command...]
        --client=PATH        mosh client on local machine
                                (default: "mosh-client")
        --server=COMMAND     mosh server on remote machine
                                (default: "mosh-server")

        --predict=adaptive      local echo for slower links [default]
-a      --predict=always        use local echo even on fast links
-n      --predict=never         never use local echo
        --predict=experimental  aggressively echo even when incorrect

-p PORT[:PORT2]
        --port=PORT[:PORT2]  server-side UDP port or range

        --ssh=COMMAND        ssh command to run when setting up session
                                (example: "ssh -p 2222")
                                (default: "ssh")

        --no-init            do not send terminal initialization string

        --help               this message
        --version            version and copyright information

Please report bugs to mosh-devel@mit.edu.
Mosh home page: http://mosh.mit.edu
```

### Mosh远程连接

Mosh使用的UDP协议连接的，使用的端口是从60000到61000，如果开启了防火墙服务器上就需要打开相应的UDP端口。一个Mosh连接就会打开一个UDP端口，比如建立两个连接就是60001、60002，以此类推。

假设Mosh使用60001 UDP端口，则在服务器上运行

```
$ iptables -I INPUT -p udp --dport 60001 -j ACCEPT
```

这样就在服务器上打开60001这个UDP端口。当然，最好是把上一条命令写入服务器iptables的规则中，这样不必要每次都手动打开这个端口。

### Mosh的使用

- 使用Mosh登录远程Linux服务器

```
$ mosh USERNAME@IP
```

- 指定开启的端口

客户端进行连接时指定端口并开启端口，默认端口从60001开始开启。接下来就是从客户端连接，如下：

```
# 如果原来连接服务器是采用密码的方式登录，会提示输入密码，如果ssh已经做好了密钥认证，则可以直接连接
$ mosh -p 60001 用户名@ip地址
```

**注：p参数用于指定UDP端口。**

- 采用SSH配置进行认证

假如你的SSH连接设置公钥/私钥连接，比如`ssh hi-linux`即可直接连接服务器而无需输入密码，则mosh命令也可以以`mosh hi-linux`的形式连接，基本上，可以把它当作ssh命令的替换，只不过SSH开的是TCP口，Mosh开的是UDP口。

```
$ mosh mike@hi-linux.com
$ exit
logout
[mosh is exiting.]
```

- 指定服务端SSH开启的端口

假设服务端开始的端口是2222

```
$ mosh --ssh="ssh -p 2222" 用户@服务器IP
```

- 如果私钥不在默认的目录

```
$ mosh --ssh="~/bin/ssh -i ./identity"  用户@服务器IP
```

- 如果服务端修改过SSH的端口，或需要指定单独的SSHKEY，可以通过`--ssh`参数的方式

```
$ mosh --ssh="ssh -i /home/dong.guo/.ssh/oozie -p 2222"
```

- 采用临时Key的方式进行一次性认证

先需要在服务端创建Key，然后客户端通过这个Key进行登录，该Key会在会话结束十分钟后自动失效。

创建一个临时的Key和端口供Client登录

```
$ mosh-server

MOSH CONNECT 60001 hNpGrd5rzRrfP47LQEizJw
mosh-server (mosh 1.2.4)
Copyright 2012 Keith Winstein <mosh-devel@mit.edu>
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
[mosh-server detached, pid = 27290]
```

定义好MOSH_KEY的值

```
$ export MOSH_KEY=hNpGrd5rzRrfP47LQEizJw
```

使用临时Key进行登陆

```
$ mosh-client 192.168.92.128 60001
$ exit
logout
[mosh is exiting.]
```

**注：mosh-client后面只能跟服务器具体的IP地址和临时端口，不支持主机名或域名方式**


### 总结

Mosh是一款在大多数linux发行版的仓库中可以下载的一款小工具。虽然它有一些差异尤其是安全问题和额外的需求，它的功能，比如漫游后保持连接是一个加分点。我的建议是任何一个使用SSH的Linux用户都应该试试这个程序，Mosh值得一试。


**Mosh的优缺点**

- Mosh有额外的需求，比如需要允许UDP 直接连接，这在SSH不需要。
- 动态分配的端口范围是60000-61000。第一个打开的端口是分配好的。每个连接都需要一个端口。
- 默认的端口分配是一个严重的安全问题，尤其是在生产环境中。
- 支持IPv6连接，但是不支持IPv6漫游。
- 不支持回滚。
- 不支持X11转发。
- 不支持ssh-agent转发。

### 参考文档

http://www.google.com
https://mosh.mit.edu/
http://heylinux.com/archives/2955.html
http://blog.szrf215.com/p/4b16d7c218db