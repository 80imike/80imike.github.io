---
category: macOS
title: 在iTerm2中使用Zmodem实现快速传输文件
date: 2017-08-01 9:00:00
tags: [macOS,技巧]
abbrlink:
updated:
toc_number: false
---

很多时候我们需要在本机和远端服务器间进行文件传输，通常都是使用 `scp` 命令进行传输。今天我们就来讲讲另一种更简单方便的方法：通过 `Zmodem` 在本地和远端服务器间快速传输文件。

### 什么是Zmodem

`Zmodem` 是针对 `modem` 的一种支持错误校验的文件传输协议。`Zmodem` 是 `Ymodem` 的改进版，后者又是 `Xmodem` 的改进版。`Zmodem` 不仅能传输更大的数据，而且错误率更小。

利用 `Zmodem` 协议，可以在 `modem` 上发送 512 字节的数据块。`Zmodem` 包含一种名为检查点重启的特性，如果通信链接在数据传输过程中中断，能从断点处而不是从开始处恢复传输。

<!-- more -->

### 配置iTerm2支持Zmodem

要让 `iTerm2` 在远端服务器上支持通过 `Zmodem` 协议传输，需要分别在服务端和客户端进行相应配置。网上大多数文档都只提到客户端部分。因为收发方都必须有支持 `Zmodem` 协议的工具，才能进行正常收发。下面我们就来看看是如何进行配置的：

#### 服务端配置

`lrzsz` 软件包是 支持 `Zmodem` 协议的工具包。 其包含的 `rz`、`sz` 命令是通过 `ZModem` 协议在远程服务器和终端机器间上传下载文件的利器。

为了正确通过 `sz`、`rz` 命令传输文件，服务端需要安装 `lrzsz` 软件包的。

- Ubuntu 或 Debian

```
$ apt-get install lrzsz
```

- RHEL 或 CentOS

```
$ yum install lrzsz
```

#### 客户端配置

**安装lrzsz**

和服务器端一样，客户端同样需要安装 `lrzsz` 软件包。这里通过 `Homebrew` 进行 `lrzsz` 软件包安装，如果你还不会使用 `Homebrew`，可参考 「[macOS不可或缺的套件管理器——Homebrew](http://mp.weixin.qq.com/s?__biz=MzI3MTI2NzkxMA==&mid=2247484646&idx=1&sn=f73feedee278c03c6c2d138154f822fb&chksm=eac525cfddb2acd964c163f6020cc1c385abc8f0680cc6086881a8093b73511db31c34e3e3fc#rd)」一文进行了解。

```
$ brew install lrzsz
```

**配置iTerm2**

在全球最大同性交友网站 `Github` 上，已经有人共享了一个叫「ZModem integration for iTerm 2」的项目。我们只需下载其相应脚本，并进行简单配置就可以很容易的在 `iTerm2` 上实现对 `Zmodem` 的支持。

项目地址：https://github.com/mmastrac/iterm2-zmodem

- 下载并安装脚本

```
$ git clone https://github.com/mmastrac/iterm2-zmodem.git
$ cd iterm2-zmodem
$ cp iterm2-recv-zmodem.sh iterm2-send-zmodem.sh  /usr/local/bin/
```

- 配置iTerm2上的触发器

打开 `iTerm2` ，点击 `Preferences` → `Profiles` 选择指定的 `Profile`，这里选 `Default`。然后继续选择 `Advanced` → `Triggers`，并点击 `Edit` 添加两个触发器。

![](https://www.hi-linux.com/img/linux/iterm2-zmodem1.png)

按如下内容添加两个触发器，首先增加 `sz` 指令的触发器：

```
Regular expression: rz waiting to receive.\*\*B0100
Action: Run Silent Coprocess
Parameters: /usr/local/bin/iterm2-send-zmodem.sh
Instant: checked
```

其次增加 `rz` 指令的触发器：

```
Regular expression: \*\*B00000000000000
Action: Run Silent Coprocess
Parameters: /usr/local/bin/iterm2-recv-zmodem.sh
Instant: checked
```

成功增加完成后的效果，类似下图：

![](https://www.hi-linux.com/img/linux/iterm2-zmodem2.png)

配置这两个触发器的作用就是让 `iTerm2` 根据终端上显示的字符通过指定的触发器调用相应的发送和接收脚本。

### 使用Zmodem传输文件

#### 发送文件到远端服务器

- 在远端服务器执行 `rz` 命令
- 本地选择文件传输
- 等待传输指示消失

#### 接收远端服务器的文件

- 在远端服务器执行 `sz filename1 filename2 … filenameN` 命令
- 本地选择目录保存
- 等待传输指示消失

上面详细介绍了如何在 `macOS` 下通过 `Zmodem`快速传输文件的方法，你可能会问没有 `macOS` 的情况下如何破？其实在 `Windows` 下实现更加简单，只需使用一个支持 `Zmodem` 的终端软件就行了，这里推荐 `XShell`。当然服务端的 `lrzsz` 软件包是必不可少的。

### 参考文档

http://www.google.com
https://github.com/mmastrac/iterm2-zmodem
