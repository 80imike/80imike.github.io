---
category: ProxyChains
title: 通过ProxyChains-NG实现终端下任意应用代理
date: 2017-02-03 09:00:00
tags: [linux, ProxyChains]
updated:
toc_number: false
---

对于技术人员shadowsocks应该不陌生，shadowsocks实质上也是一种socks5代理服务，类似于ssh代理。

与vpn的全局代理不同，shadowsocks仅针对浏览器代理，不能代理应用软件，比如curl、wget等一些命令行软件。如果要让终端下的命令行工具都能支持代理，这时我们就要用上proxychains-ng这款神器了。

<!-- more -->

### 什么是 proxychains-ng

项目主页：https://github.com/rofl0r/proxychains-ng

#### proxychains-ng 介绍

> proxychains ng (new generation) - a preloader which hooks calls to sockets in dynamically linked programs and redirects it through one or more socks/http proxies. continuation of the unmaintained proxychains project.

proxychains-ng是proxychains的加强版，主要有以下功能和不足：

- 支持http/https/socks4/socks5
- 支持认证
- 远端dns查询
- 多种代理模式
- 不支持udp/icmp转发
- 少部分程序和在后台运行的可能无法代理

#### proxychains-ng 原理


简单的说就是这个程序 Hook 了 sockets 相关的操作，让普通程序的 sockets 数据走 SOCKS/HTTP 代理。

其核心就是利用了 LD_PRELOAD 这个环境变量（Mac 上是 DYLD_INSERT_LIBRARIES）。

在 Unix 系统中，如果设置了 LD_PRELOAD 环境变量，那么在程序运行时，动态链接器会先加载该环境变量所指定的动态库。也就是说，这个动态库的加载优先于任何其它的库，包括 libc。

ProxyChains 创建了一个叫 libproxychains4.so（Mac 上是 libproxychains4.dylib）的动态库。里面重写了 connect、close 以及 sendto 等与 socket 相关的函数，通过这些函数发出的数据将会走代理，详细代码可以参考 libproxychains.c。

在主程序里，它会读取配置文件，查找 libproxychains4 所在位置，把这些信息存入环境变量后执行子程序。这样子程序里对 socket 相关的函数调用就会被 Hook 了，对子程序来说，跟代理相关的东西都是透明的。

可以用 printenv 程序来查看增加的环境变量，在 Mac 上输出结果类似于：

```bash
$ proxychains4 printenv

[proxychains] config file found: /usr/local/Cellar/proxychains-ng/4.11/etc/proxychains.conf
[proxychains] preloading /usr/local/Cellar/proxychains-ng/4.11/lib/libproxychains4.dylib
[proxychains] DLL init: proxychains-ng 4.11
...
PROXYCHAINS_CONF_FILE=/usr/local/Cellar/proxychains-ng/4.11/etc/proxychains.conf
DYLD_FORCE_FLAT_NAMESPACE=1
DYLD_INSERT_LIBRARIES=/usr/local/Cellar/proxychains-ng/4.11/lib/libproxychains4.dylib
```

一共设置了三个环境变量，其中 PROXYCHAINS_CONF_FILE 保存的是配置文件路径，DYLD_INSERT_LIBRARIES 保存的是动态库路径，在 Mac 中，必须使DYLD_FORCE_FLAT_NAMESPACE 为 1 才能保证 DYLD_INSERT_LIBRARIES 起作用。

### 安装 proxychains-ng

#### 通过源代码安装

- 下载源码

```bash
$ git clone https://github.com/rofl0r/proxychains-ng
```

- 编译安装

```
$ ./configure --prefix=/usr --sysconfdir=/etc
$ make
$ make install
$ make install-config (安装proxychains.conf配置文件)
```

#### MAC下安装

**关闭 SIP**

macOS 10.11 后下由于开启了 SIP（System Integrity Protection） 会导致命令行下 proxychains 代理的模式失效，如果你要使用 proxychains 这种简单的方法，就需要先关闭 SIP。

具体的关闭方法如下：

- 部分关闭 SIP

> 重启Mac，按住Option键进入启动盘选择模式，再按⌘ + R进入Recovery模式。
> 实用工具（Utilities）-> 终端（Terminal）。
> 输入命令`csrutil enable --without debug`运行。
> 重启进入系统后，终端里输入 csrutil status，结果中如果有 Debugging Restrictions: disabled 则说明关闭成功。


- 完全关闭 SIP

> 重启Mac，按住Option键进入启动盘选择模式，再按⌘ + R进入Recovery模式。
> 实用工具（Utilities）-> 终端（Terminal）。
> 输入命令`csrutil disable`运行。
> 重启进入系统后，终端里输入 csrutil status，结果中如果有 System Integrity Protection status:disabled. 则说明关闭成功。

**安装 Proxychains**

安装好 Homebrew 后，终端中输入

```bash
$ brew install proxychains-ng
```

### 配置 proxychains-ng

proxychains默认配置文件名为`proxychains.conf`。

- 通过源代码编译安装的默认为`/etc/proxychains.conf`。
- Mac下用Homebrew安装的默认为`/usr/local/etc/proxychains.conf`。

proxychains-ng的配置非常简单，只需将代理加入[ProxyList]中即可。

```
$ vim proxychains.conf

quiet_mode
dynamic_chain
chain_len = 1 #round_robin_chain和random_chain使用
proxy_dns
remote_dns_subnet 224
tcp_read_time_out 15000
tcp_connect_time_out 8000
localnet 127.0.0.0/255.0.0.0
localnet 10.0.0.0/255.0.0.0
localnet 172.16.0.0/255.240.0.0
localnet 192.168.0.0/255.255.0.0

[ProxyList]
socks5  127.0.0.1 1086
http    127.0.0.1 1087
```

proxychains-ng支持多种代理模式,默认是选择 strict_chain。

- dynamic_chain ：动态模式,按照代理列表顺序自动选取可用代理
- strict_chain ：严格模式,严格按照代理列表顺序使用代理，所有代理必须可用
- round_robin_chain ：轮询模式，自动跳过不可用代理
- random_chain ：随机模式,随机使用代理

### proxychains-ng 使用

#### proxychains-ng 语法

proxychains用法非常简单，使用格式如下:


```
$ proxychains4 程序 参数
```

#### proxychains-ng 测试

```bash
$ proxychains4 curl ip.cn
```

#### proxychains-ng 优化

**alias**

给proxychains4增加一个别名，在 ~/.zshrc或~/.bashrc末尾加入如下行：

```bash
#   ---------------------------------------
#   proxychain-ng config
#   ---------------------------------------
alias pc='proxychains4'
```

以后就可以类似`$ pc curl http://www.google.com`这样调用proxychains4，简化了输入。

**自动补全**

你输了很长一段命令，然后你突然想使用代理功能，怎么办？

- iTerm中前缀补全

在 `iTerm -> Preferences -> Profiles -> Keys` 中，新建一个快捷键，例如 ⌥ + p ，Action 选择 Send Hex Code，键值为 0x1 0x70 0x63 0x20 0xd，保存生效。

以后命令要代理就直接敲命令，然后 ⌥ + p 即可，这样命令补全也能保留了。


附上 Hex Code 对应表，获取工具为keycodes(http://manytricks.com/keycodes/)

|Hex Code|Key|
|---|---|
|0x1|⌃ + a|
|0x70|p|
|0x63|c|
| 0x20 | [space] |
| 0xd | ↩︎ |

- oh-my-zsh中前缀补全

```bash
$ git clone git@github.com:six-ddc/zsh-proxychains-ng.git ~/.oh-my-zsh/custom/plugins/zsh-proxychains-ng
$ echo "plugins+=(zsh-proxychains-ng)" >> ~/.zshrc
```

使用时按[ESC]-P ，自动添加(去除)`proxychains4 -q`命令前缀，支持 emacs 和 vi mode 。

- 通过代理SHELL实现全局代理

如果你还是觉得每次使用都要输入proxychains4或其别名，比较麻烦。你还可以用proxychains4代理一个shell，在shell中执行的命令就会自动使用代理了。

方法一

手动设置环境变量

```bash
$ export PROXYCHAINS_CONF_FILE=/usr/local/Cellar/proxychains-ng/4.11/etc/proxychains.conf
$ export DYLD_INSERT_LIBRARIES=/usr/local/Cellar/proxychains-ng/4.11/lib/libproxychains4.dylib
$ export DYLD_FORCE_FLAT_NAMESPACE=1
```

方法二

proxychains4直接调用SHELL

BASH

```bash
$ proxychains4  -q /bin/bash
```

ZSH

```bash
$ proxychains4  -q /bin/zsh
```

这样在当前 shell 中运行的所有程序的网络请求都会走代理了。可以把上面的命令加入到用户目录的.bashrc或者.zshrc中,用户登录后自动代理一个shell,这就类似一个全局代理了。在这个SHELL下的所有命令都可以使用代理了。

### 参考文档

http://www.google.com
http://t.cn/R4tiUB1
http://t.cn/Rxg7oJR
http://t.cn/RG1Hbs3
