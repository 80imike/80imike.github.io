---
title: 如何透过SSH代理穿越跳板机
tags:
  - SSH
  - Linux
categories: SSH
abbrlink: 929
date: 2016-04-26 09:00:00
updated:
toc_number:
---

![](http://www.hi-linux.com/img/linux/ProxyCommand.png)

一般公司为了安全起见，线上服务器都无法直接访问，必须通过一台跳板机来访问。比如要访问机器webserver01，则必须先ssh到跳板机gateway，然后再ssh到webserver01机器。这样做自然可以减少攻击面，但是每次去webserver01机器执行命令，或者上传文件的时候都要两次ssh，对线上的调试和监控效率影响很大。<!-- more -->

### 通过Proxycommand+Netcat

前提条件

- 本机、跳板机、目标机器三者已经做过公钥认证(如果不做密钥认证就会提示分别输入跳板机和目标机器的密码，需要多输入两次密码比较繁琐)
- 跳板机已安装Netcat

安装Netcat

CentOS

```
yum install nc
```

配置本机ssh config

```
vim ~/.ssh/config

Host webserver01					#主机别名，也可写成目标服务器IP，可使用通配符，如：Host 10.208.*
  HostName 192.168.111.102		#目标机域名或IP地址
  User root						#SSH用户名
  Port 22						#SSH端口
  ProxyCommand ssh -q -p 22 root@192.168.119.101 nc %h %p
  IdentityFile ~/.ssh/id_rsa 	#登陆跳板机的私钥所在位置，如默认位置可不用显示指定
```

原理分析

通过ProxyCommand，可以在开启ssh之前执行一个命令打开代理隧道，这个命令`nc %h %p`意为在跳板机上使用nc开启了远程隧道。
ProxyCommand参数中的-q是为了防止和跳板机的ssh连接产生多余的输出，比如不加-q就会导致每次断开连接的时候会多一句`Killed by signal 1.`

### 通过`SSH -W`参数(推荐)

此方法不用跳板机上额外安装NC。

前提条件

- 本机、跳板机、目标机器三者已经做过公钥认证(如果不做密钥认证就会提示分别输入跳板机和目标机器的密码，需要多输入两次密码比较繁琐)


配置本机ssh config

```
vim ~/.ssh/config

Host gateway
  HostName 192.168.119.101
  User root

Host webserver01    				#主机别名，也可写成目标服务器IP，可使用通配符，如：Host 10.208.*
  HostName 192.168.111.102		#目标机域名或IP地址
  User root						#SSH用户名
  Port 22						#SSH端口
  ProxyCommand ssh -q -W %h:%p gateway
  IdentityFile ~/.ssh/id_rsa 	#登陆跳板机的私钥所在位置，如默认位置可不用显示指定

```

原理分析

通过ProxyCommand命令就会先和gateway建立ssh连接，并把这个中间连接当作一个代理使用。
ProxyCommand参数中的-q是为了防止和跳板机的ssh连接产生多余的输出，比如不加-q就会导致每次断开连接的时候会多一句`Killed by signal 1.`


### 测试

在本地机器的命令行输入

```
ssh root@webserver01
```

见证奇迹的时刻来了，SSH会直接登陆到远端WEB服务器。


### 一些高级用法

```
ssh dev "sudo tcpdump -s 0 -U -n -i eth0 not port 22 -w -" | wireshark -k -i -
```

这条命令在远端调用tcpdump抓包，通过管道传回本地，然后让wireshark抓包，就达到了实时抓包的效果了。这比原来的抓包存储到pcap文件中，然后两次scp传回来要快很多。


### 参考文档

http://www.google.com
https://www.robberphex.com/2015/09/426
http://xieminis.me/?p=257
http://feiyang.me/2013/03/ssh-cross-gateway/
