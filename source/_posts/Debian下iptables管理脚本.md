---
title: Debian/Ubuntu下iptables管理脚本
tags:
  - Linux
  - 技巧
  - debian
  - iptables
  - 工具
categories: Https
abbrlink: 27459
date: 2016-03-15 09:51:54
---
RedHat系列下有比较好用的iptables管理工具，可以像控制服务进程一样来对防火墙进行管理及控制，debian系发行版默认不开启iptables，当然也没有与之相关的能直接管理的工具了。这里推荐两款工具来完成这一工作。

### 一、使用iptables-persistent

#### 安装

```bash
apt-get install iptables-persistent
```
<!-- more -->
#### 指令参考

```bash
/etc/init.d/iptables-persistent
Usage: /etc/init.d/iptables-persistent {start|restart|reload|force-reload|save|flush}

start: loads /etc/iptables/rules.v4，/etc/iptables/rules.v6
restart: convenience start & stop command
reload:reload rules from /etc/iptables/rules.v4，/etc/iptables/rules.v6
force-reload:force-reload rules from /etc/iptables/rules.v4，/etc/iptables/rules.v6
save:saves the current rules to /etc/iptables/rules.v4 and /etc/iptables/rules.v6
flush: flushes iptables completely, and enforces ACCEPT policy
```
#### 示例
```bash
service iptables-persistent start
service iptables-persistent restart
service iptables-persistent reload
service iptables-persistent force-reload
service iptables-persistent save
service iptables-persistent flush
```

### 二、使用iptables-init-debian

>Init script for controlling iptables as a service in a Debian box. Tested in Debian Squeeze, Wheezy and Sid.

This script relies on iptables-save and iptables-restore commands, to save and read the rules in /etc/iptables.rules. Once installed, this file must be created, by saving current rules (save command).

项目主页：<https://github.com/Sirtea/iptables-init-debian>

#### 安装
```bash
wget https://github.com/Sirtea/iptables-init-debian/archive/master.zip -O iptables-init-debian.zip
unzip iptables-init-debian.zip
cd iptables-init-debian-master/
cp iptables /etc/init.d/
update-rc.d iptables defaults #加入开机启动
```

#### 指令参考

```bash
start: loads /etc/iptables.rules
stop: flushes iptables completely, and enforces ACCEPT policy
restart: convenience start & stop command
save: saves the current rules to /etc/iptables.rules
```

#### 示例
```bash
service iptables start
service iptables stop
service iptables restart
service iptables status
```


