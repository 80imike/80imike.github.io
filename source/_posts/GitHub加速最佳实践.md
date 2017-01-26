---
category: git
title: GitHub加速最佳实践
date: 2017-01-25 09:00:00
tags: [linux, git]
updated:
toc_number: false
---

GitHub，又称世界上最大的同性交友平台(GayHub)。但由于众所周知的原因，GitHub 在没有翻墙的前提下，访问速度就像乌龟在漫步。让追求效率的技术人员痛苦不堪，恨不得肉身翻墙，享受优质互联网服务的同时晒晒太阳，吹吹海风。

熟练的技术人员基本上都使用 Terminal 或者命令行访问 GitHub。那么问题来了，怎么优雅地使用 GitHub 呢？

Git 目前支持的两种协议 `ssh://` 和 `https://`，其代理配置各不相同：`http.proxy`用于 `https://` 协议，`ssh://` 协议的代理需要配置 `ssh` 的 `ProxyCommand` 参数。

### 针对HTTPS 协议(https://)配置代理

配置 git 对 https:// 协议开头的仓库使用 http 代理,可以通过以下两种方法：

- 通过命令行进行设置

**针对所有git服务器设置代理**

```bash
$ git config --global http.proxy http://127.0.0.1:1087
```

**只针对github.com设置代理**

```bash
$ git config --global http.https://github.com.proxy http://127.0.0.1:1087
```

**如果代理需要帐号密码，可按如下格式**

```bash
$ git config --global http.proxy http://proxyuser:proxypwd@proxy.server.com:1087

#proxyuser= 代理的登录用户名
#proxypwd= 代理的登录密码
#proxy.server.com:1087 = 代理的ip（或域名）以及端口
```

- 通过编辑git配置文件

```bash
$ vim  ~/.gitconfig

[http]
	proxy = http://127.0.0.1:1087
```

### 针对SSH 协议(ssh://)配置代理

使用 ssh 的好处就是在 clone 数据,或者提交数据到 github.com 时,不用在输入 github 的帐号密码。

下面是 ssh 的设置,打开 ~/.ssh/config 输入 :

```bash
$ vim ~/.ssh/config

Host github.com *.github.com
    ProxyCommand connect -H 127.0.0.1:1087 %h %p #设置代理
    HostName %h
    Port 22
    User git
    IdentityFile  ~/.ssh/id_rsa # 这里是私钥，不要放成公钥啦
    IdentitiesOnly yes
```

通过`ProxyCommand`命令设置代理，其中的`connect`是一个工具用于进行代理的转换。`connect`通常需要安装，各发行版一般打包后的包名为`proxy-connect`或者`connect-proxy`。

connect项目地址：https://bitbucket.org/gotoh/connect

**安装方式**

Ubuntu

```bash
$ sudo apt-get install connect-proxy
```

Centos

```bash
$ sudo yum install connect-proxy
```

Mac OS X

```bash
$ brew install  connect
```

**测试**

```bash
$ ssh -T git@github.com
Hi username! You ve successfully authenticated, but GitHub does not provide shell access.
```

### 其它小技巧

- 取消当前使用代理

```bash
$ git config --global --unset http.proxy
```

- 查看当前使用代理

```bash
$ git config --global --get http.proxy
```

### 参考文档

http://www.google.com
http://t.cn/RxG4QTv
http://t.cn/RxG4r7O
