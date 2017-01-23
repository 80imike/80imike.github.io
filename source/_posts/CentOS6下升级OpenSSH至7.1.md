---
title: CentOS6下升级OpenSSH至7.1
tags:
  - OpenSSH
  - Linux
categories: OpenSSH
abbrlink: 12788
date: 2016-04-13 09:00:00
updated:
toc_number:
---

本文通过编译生成OpenSSH RPM升级OpenSSH至7.1，目前最新版本的OpenSSH版本为7.2p2,这个版本貌似有BUG没能编译成功，故使用7.1p2版本

### 安装编译所需工具
```bash
$ yum -y groupinstall "Development tools"
$ yum -y install pam-devel rpm-build rpmdevtools zlib-devel krb5-devel tcp_wrappers tcp_wrappers-devel tcp_wrappers-libs libX11-devel xmkmf libXt-devel wget
```

### 配置RPM编译环境
```bash
$ cd ~
$ mkdir rpmbuild
$ cd rpmbuild
$ mkdir -pv {BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
```
<!-- more -->
### 升级OpenSSL到最新
```bash
$ yum update openssl openssl-devel
```
### 编译OpenSSH RPM

#### 下载源码包
```bash
$ cd ~/rpmbuild/SOURCES/
$ wget http://openbsd.hk/pub/OpenBSD/OpenSSH/portable/openssh-7.1p2.tar.gz
$ wget http://ftp.riken.jp/Linux/momonga/6/Everything/SOURCES/x11-ssh-askpass-1.2.4.1.tar.gz
```
#### 配置SPEC文件
```bash
$ cd ~/rpmbuild/SPECS
$ tar xfz ../SOURCES/openssh-7.1p2.tar.gz openssh-7.1p2/contrib/redhat/openssh.spec
$ mv openssh-7.1p2/contrib/redhat/openssh.spec openssh-7.1p2.spec
$ rm -rf openssh-7.1p2
$ sed -i -e "s/%define no_gnome_askpass 0/%define no_gnome_askpass 1/g" openssh-7.1p2.spec
$ sed -i -e "s/%define no_x11_askpass 0/%define no_x11_askpass 1/g" openssh-7.1p2.spec
$ sed -i -e "s/BuildPreReq/BuildRequires/g" openssh-7.1p2.spec
```
#### 编译生成RPM
```bash
$ cd ~/rpmbuild/SPECS
$ rpmbuild -bb openssh-7.1p2.spec
```
#### 查看生成的RPM
```bash
$ cd ~/rpmbuild/RPMS/x86_64
$ ls openssh-*
openssh-7.1p2-1.x86_64.rpm  openssh-clients-7.1p2-1.x86_64.rpm  openssh-debuginfo-7.1p2-1.x86_64.rpm  openssh-server-7.1p2-1.x86_64.rpm
```
#### 安装生成的RPM
```bash
$ cd ~/rpmbuild/RPMS/x86_64
yum install openssh-7.1p2-1.x86_64.rpm  openssh-clients-7.1p2-1.x86_64.rpm  openssh-server-7.1p2-1.x86_64.rpm

诊断 openssh-clients-7.1p2-1.x86_64.rpm: openssh-clients-7.1p2-1.x86_64
openssh-clients-7.1p2-1.x86_64.rpm 将作为 openssh-clients-5.3p1-114.el6_7.x86_64 的更新
诊断 openssh-server-7.1p2-1.x86_64.rpm: openssh-server-7.1p2-1.x86_64
openssh-server-7.1p2-1.x86_64.rpm 将作为 openssh-server-5.3p1-114.el6_7.x86_64 的更新
解决依赖关系
--> 执行事务检查
---> Package openssh.x86_64 0:5.3p1-114.el6_7 will be 升级
---> Package openssh.x86_64 0:7.1p2-1 will be an update
---> Package openssh-clients.x86_64 0:5.3p1-114.el6_7 will be 升级
---> Package openssh-clients.x86_64 0:7.1p2-1 will be an update
---> Package openssh-server.x86_64 0:5.3p1-114.el6_7 will be 升级
---> Package openssh-server.x86_64 0:7.1p2-1 will be an update
--> 完成依赖关系计算

依赖关系解决

========================================================================================================================================================================================================================================================================
 软件包                                                            架构                                                     版本                                                      仓库                                                                               大小
========================================================================================================================================================================================================================================================================
正在升级:
 openssh                                                           x86_64                                                   7.1p2-1                                                   /openssh-7.1p2-1.x86_64                                                           1.9 M
 openssh-clients                                                   x86_64                                                   7.1p2-1                                                   /openssh-clients-7.1p2-1.x86_64                                                   2.0 M
 openssh-server                                                    x86_64                                                   7.1p2-1                                                   /openssh-server-7.1p2-1.x86_64                                                    933 k

事务概要
========================================================================================================================================================================================================================================================================
Upgrade       3 Package(s)

总文件大小：4.8 M
确定吗？[y/N]：y
下载软件包：
运行 rpm_check_debug 
执行事务测试
事务测试成功
执行事务
  正在升级   : openssh-7.1p2-1.x86_64                                                                                                                                                                                                                                     1/6 
  正在升级   : openssh-server-7.1p2-1.x86_64                                                                                                                                                                                                                              2/6 
warning: /etc/ssh/sshd_config created as /etc/ssh/sshd_config.rpmnew
  正在升级   : openssh-clients-7.1p2-1.x86_64                                                                                                                                                                                                                             3/6 
  清理       : openssh-clients-5.3p1-114.el6_7.x86_64                                                                                                                                                                                                                     4/6 
  清理       : openssh-server-5.3p1-114.el6_7.x86_64                                                                                                                                                                                                                      5/6 
  清理       : openssh-5.3p1-114.el6_7.x86_64                                                                                                                                                                                                                             6/6 
  Verifying  : openssh-server-7.1p2-1.x86_64                                                                                                                                                                                                                              1/6 
  Verifying  : openssh-clients-7.1p2-1.x86_64                                                                                                                                                                                                                             2/6 
  Verifying  : openssh-7.1p2-1.x86_64                                                                                                                                                                                                                                     3/6 
  Verifying  : openssh-server-5.3p1-114.el6_7.x86_64                                                                                                                                                                                                                      4/6 
  Verifying  : openssh-clients-5.3p1-114.el6_7.x86_64                                                                                                                                                                                                                     5/6 
  Verifying  : openssh-5.3p1-114.el6_7.x86_64                                                                                                                                                                                                                             6/6 

更新完毕:
  openssh.x86_64 0:7.1p2-1                                                            openssh-clients.x86_64 0:7.1p2-1                                                            openssh-server.x86_64 0:7.1p2-1                                                           

完毕！
```

#### 更新SSH配置文件
将配置文件更新为新版本，避免某些参数变更造成无法远程登录
```bash
$ cp /etc/ssh/sshd_config.rpmnew /etc/ssh/sshd_config
```
OpenSSH默认配置不支持ROOT登陆，如需ROOT登陆修改以下配置

将`/etc/ssh/sshd_config`中`#PermitRootLogin prohibit-password`修改为`PermitRootLogin yes`

#### 重启SSH服务
```bash
$ /etc/init.d/sshd restart
```
#### 查看已安装的RPM
```bash
$ rpm -qa | grep openssh
openssh-7.1p2-1.x86_64
openssh-clients-7.1p2-1.x86_64
openssh-server-7.1p2-1.x86_64
```
#### 验证已安装的版本
```bash
$ ssh -V                        
OpenSSH_7.1p2, OpenSSL 1.0.1e-fips 11 Feb 2013
```
**重要！退出之前打开一个新的SSH会话连接到你的服务器，以确保一切正常！如果你有问题，可用以下命令降级到之前版本**
```bash
$ yum downgrade openssh-server openssh-clients openssh
$ cp /etc/ssh/sshd_config.rpmnew /etc/ssh/sshd_config
$ /etc/init.d/sshd restart
```
#### 问题处理

在制作的时候你可能会发现有些依赖包没有，你可以使用yum工具自带的搜索功能，比如，当提示你libxml.h找不到时，你可以使用命令：
```bash
$ yum provides */libxml.h
```

找到对应的包名后，即可以使用以下命令进行安装：
```bash
$ yum install -y rpm-package-name
```

### 参考文档
http://www.google.com
http://thecpaneladmin.com/upgrading-openssh-on-centos-5/
http://www.guoziweb.com/2015/11/26/centos-6-2%E5%8D%87%E7%BA%A7openssh-7-1/