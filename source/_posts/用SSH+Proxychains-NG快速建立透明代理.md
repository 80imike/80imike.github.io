---
category: ProxyChains
title: 用SSH+Proxychains-NG快速建立透明代理
date: 2017-02-04 09:00:00
tags: [linux, ProxyChains]
updated:
toc_number: false
---

一般机房只有少数对外直接提供服务的机器才能连接上公网，用于内部服务的机器是不能访问公网的。这也是一种比较常见的部署架构，例如阿里云环境。

不过有时用于提供内部服务的机器也有连接上公网的需求，例如更新某个安全补丁。本文将介绍如何通过`SSH`+`Proxychains-NG`快速建立一个透明代理来给内网中的服务器提供上网服务。

实现思路：通过`Proxychains-NG`把内网服务器的请求转发给SSH建立的一个SOCKE服务，然后公网服务器在把这个请求转发出去达到访问公网的目的。

<!-- more -->

Proxychains-ng只需要在内网服务器上安装好，而公网服务器是不需要任何配置的，只要能SSH登陆就可以。

服务器环境说明：

> 公网服务器：192.168.1.8
> 内网服务器：192.168.1.100

###  通过SSH建立SOCKS服务

使用 `ProxyChains-NG` 当然要先有代理，这里是用`ssh -D`连到能访问公网的机器来建立一个SOCKS动态转发代理。具体命令如下：

```bash
$ ssh -Nf -D 20000 mike@192.168.1.8
```

解释：

> -N 不执行命令
> -f 跑到后台执行
> -D 20000 监听 localhost:20000 端口，把本地请求转发给被连接的公网服务器。

###  安装 ProxyChains-NG

**通过源代码安装**

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

### 配置 ProxyChains-NG

修改配置文件，在[ProxyList]配置段中加入代理的地址和端口。

```bash
$ vim /etc/proxychains.conf
[ProxyList]
# add proxy here ...
# meanwile
# defaults set to "tor"
socks4  127.0.0.1 20000
```

这里的代理地址就是上面通过SSH建立SOCKS服务的地址。


### 测试

通过 `proxychains4` 执行命令，即可通过公网服务器的网络访问外网了。

```bash
$ proxychains4 curl http://ip.cn
[proxychains] config file found: /etc/proxychains.conf
[proxychains] preloading /usr/lib/libproxychains4.so
[proxychains] DLL init: proxychains-ng 4.12
[proxychains] Strict chain  ...  127.0.0.1:20000  ...  ip.cn:80  ...  OK
当前 IP：119.85.177.249 来自：重庆市
```

除了curl，使用其它命令行的时候都只要在前面加上`proxychains4`，就都可以通过公网服务器的网络连接上公网了。

这种方式可以在仅仅需要的时候使用，而不需要改变任何服务器的网络配置，非常不错。 更多ProxyChains-NG使用技巧可参考：[通过ProxyChains-NG实现终端下任意应用代理][dc358bf5]

[dc358bf5]: http://www.hi-linux.com/posts/48321.html "通过ProxyChains-NG实现终端下任意应用代理"


### 参考文档

http://www.google.com
http://heylinux.com/archives/2933.html
http://blog.csdn.net/chen3feng/article/details/5774983
