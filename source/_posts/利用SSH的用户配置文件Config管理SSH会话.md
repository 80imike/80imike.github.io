---
title: 利用SSH的用户配置文件Config管理SSH会话
tags:
  - SSH
  - Linux
categories: SSH
abbrlink: 14346
date: 2017-01-18 09:00:00
updated:
toc_number:
---

通常利用 SSH 连接远程服务器，一般都要输入以下类似命令：

```bash
$ ssh user@hostname -p port
```

如果拥有多个 SSH 账号，在终端里直接 SSH 登陆要记住每个 SSH 账号的参数是件不容易的事，而且比较浪费精力和时间。

还好 SSH 提供一种优雅且灵活的方式来解决这个问题，就是利用 SSH 的用户配置文件Config管理 SSH 会话。

<!-- more -->

### 使用SSH配置文件

SSH 程序可以从以下途径获取配置参数：

> 用户配置文件 (~/.ssh/config)
> 系统配置文件 (/etc/ssh/ssh_config)

配置文件可分为多个配置区段，每个配置区段使用"Host"来区分。我们可以在命令行中输入不同的Host来加载不同的配置段。

**配置项**

下面先介绍一些常用的SSH配置项

- Host 别名
- HostName 主机名
- Port 端口
- User 用户名
- IdentityFile 密钥文件的路径
- IdentitiesOnly 只接受SSH key 登录
- PreferredAuthentications 强制使用Public Key验证

Host

Host配置项标识了一个配置区段。

SSH配置项参数值可以使用通配符：

```bash
'*' 代表 0～n 个非空白字符。
'?' 代表一个非空白字符。
'!' 表示例外通配。
```

我们可以在系统配置文件中看到一个匹配所有 host 的默认配置区段：

```
$ cat /etc/ssh/ssh_config | grep '^Host'
Host *
```

这里有一些默认配置项，我们可以在用户配置文件中覆盖这些默认配置。

GlobalKnownHostsFile

指定一个或多个全局认证主机缓存文件，用来缓存通过认证的远程主机的密钥，多个文件用空格分隔。默认缓存文件为：`/etc/ssh/ssh_known_hosts`, `/etc/ssh/ssh_known_hosts2`。

HostName

指定远程主机名，可以直接使用数字IP地址。如果主机名中包含 ‘%h’ ，则实际使用时会被命令行中的主机名替换。

IdentityFile

指定密钥认证使用的私钥文件路径。默认为`~/.ssh/id_dsa`, `~/.ssh/id_ecdsa`, `~/.ssh/id_ed25519` 或 `~/.ssh/id_rsa` 中的一个。文件名称可以使用以下转义符：

```bash
'%d' 本地用户目录
'%u' 本地用户名称
'%l' 本地主机名
'%h' 远程主机名
'%r' 远程用户名
```

可以指定多个密钥文件，在连接的过程中会依次尝试这些密钥文件。

Port

指定远程主机端口号，默认为22。

User

指定登录用户名。

UserKnownHostsFile

指定一个或多个用户认证主机缓存文件，用来缓存通过认证的远程主机的密钥，多个文件用空格分隔。默认缓存文件为： `~/.ssh/known_hosts`, `~/.ssh/known_hosts2`。

StrictHostKeyChecking

SSH客户端的StrictHostKeyChecking配置指令，`StrictHostKeyChecking=no`时可以实现当第一次连接服务器时自动接受新的公钥。不再有任何警告出现了。

还有更多参数的介绍，可以通过`man ssh_config`查看用户手册。

### 使用示例


- 使用指定别名登录到www.hi-linux.com这台主机。

```bash
Host www
    HostName www.hi-linux.com
    Port 22
    User root
    IdentityFile  ~/.ssh/id_rsa
    IdentitiesOnly yes
```

```
$ ssh www
```

- 不同主机使用同一私钥进行登陆。

```bash
Host github.com git.coding.net
    HostName %h
    Port 22
    User git
    IdentityFile  ~/.ssh/id_rsa_blog
    IdentitiesOnly yes
```

```
$ ssh -T git@git.coding.net
$ ssh -T git@github.com
```

### 参考文档

http://t.cn/RMmO8I9
http://t.cn/RfXzmZw
http://t.cn/RMmWP95
