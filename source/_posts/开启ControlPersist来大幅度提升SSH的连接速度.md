---
title: 开启ControlPersist来大幅度提升SSH的连接速度
tags:
  - OpenSSH
  - Linux
categories: OpenSSH
toc_number: false
abbrlink: 21998
date: 2016-04-13 09:00:00
updated:
---

背景介绍

Ansible创建ssh通道相对很慢,虽然ansible在同一个task里面是并行的控制多台受控端.但是每一个task都需要和受控端创建ssh通道,非常影响效率。

开启SSH的ControlMaster并持久化socket连接，可以加速Ansible的执行速度，不需要在每次都经历SSH认证，并且只需要修改ssh client就行了。单个服务器可能节约的时间仅在1秒左右，而上百台的服务器就能节省约1分钟左右的时间。

支持这个特性需要比较新的openssh 5.6以上,CentOS6.x默认的版本太旧了并且官方yum仓库中的版本也很旧。

服务器环境

CentOS 6.7 x86_64 Minimal
<!-- more -->

### 1. 编译生成OpenSSH RPM


#### 1.1 安装编译所需工具

```bash
$ sudo yum -y groupinstall "Development tools"
$ sudo yum -y install pam-devel rpm-build rpmdevtools zlib-devel krb5-devel tcp_wrappers tcp_wrappers-devel tcp_wrappers-libs libX11-devel xmkmf libXt-devel
```

#### 1.2 配置RPM编译环境

```bash
$ cd ~
$ mkdir rpmbuild
$ cd rpmbuild
$ mkdir -pv {BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS,TMP}

$ cd ~
$ vim .rpmmacros

%_topdir /root/rpmbuild
%_tmppath /root/rpmbuild/TMP
```

#### 1.3 升级OpenSSL到最新

```bash
$ sudo yum update openssl
```

#### 1.4 编译OpenSSH RPM

##### 1.4.1 下载源码包

```bash
$ cd ~/rpmbuild/SOURCES/
$ wget http://openbsd.hk/pub/OpenBSD/OpenSSH/portable/openssh-6.6p1.tar.gz
$ wget http://ftp.riken.jp/Linux/momonga/6/Everything/SOURCES/x11-ssh-askpass-1.2.4.1.tar.gz
```

##### 1.4.2 配置SPEC文件

```bash
$ cd ~/rpmbuild/SPECS
$ tar xfz ../SOURCES/openssh-6.6p1.tar.gz openssh-6.6p1/contrib/redhat/openssh.spec
$ mv openssh-6.6p1/contrib/redhat/openssh.spec openssh-6.6p1.spec
$ rm -rf openssh-6.6p1
$ sed -i -e "s/%define no_gnome_askpass 0/%define no_gnome_askpass 1/g" openssh-6.6p1.spec
$ sed -i -e "s/%define no_x11_askpass 0/%define no_x11_askpass 1/g" openssh-6.6p1.spec
$ sed -i -e "s/BuildPreReq/BuildRequires/g" openssh-6.6p1.spec
```

##### 1.4.3 编译生成RPM

```bash
$ cd ~/rpmbuild/SPECS
$ rpmbuild -ba openssh-6.6p1.spec
```

##### 1.4.4 查看生成的RPM

```bash
$ cd ~/rpmbuild/RPMS/x86_64
$ ls openssh-*
openssh-6.6p1-1.x86_64.rpm  openssh-clients-6.6p1-1.x86_64.rpm  openssh-debuginfo-6.6p1-1.x86_64.rpm  openssh-server-6.6p1-1.x86_64.rpm
```

##### 1.4.5 安装生成的RPM

```bash
$ cd ~/rpmbuild/RPMS/x86_64
yum install openssh-server-6.6p1-1.x86_64.rpm openssh-6.6p1-1.x86_64.rpm openssh-clients-6.6p1-1.x86_64.rpm

依赖关系解决

========================================================================================================================================================================================================================================================================
 软件包                                                            架构                                                     版本                                                      仓库                                                                               大小
========================================================================================================================================================================================================================================================================
正在升级:
 openssh                                                           x86_64                                                   6.6p1-1                                                   /openssh-6.6p1-1.x86_64                                                           1.7 M
 openssh-clients                                                   x86_64                                                   6.6p1-1                                                   /openssh-clients-6.6p1-1.x86_64                                                   1.8 M
 openssh-server                                                    x86_64                                                   6.6p1-1                                                   /openssh-server-6.6p1-1.x86_64                                                    892 k

事务概要
========================================================================================================================================================================================================================================================================
Upgrade       3 Package(s)

总文件大小：4.4 M
确定吗？[y/N]：y
下载软件包：
运行 rpm_check_debug 
执行事务测试
事务测试成功
执行事务
  正在升级   : openssh-6.6p1-1.x86_64                                                                                                                                                                                                                                     1/6 
  正在升级   : openssh-clients-6.6p1-1.x86_64                                                                                                                                                                                                                             2/6 
  正在升级   : openssh-server-6.6p1-1.x86_64                                                                                                                                                                                                                              3/6 
warning: /etc/ssh/sshd_config created as /etc/ssh/sshd_config.rpmnew
  清理       : openssh-server-5.3p1-112.el6_7.x86_64                                                                                                                                                                                                                      4/6 
  清理       : openssh-clients-5.3p1-112.el6_7.x86_64                                                                                                                                                                                                                     5/6 
  清理       : openssh-5.3p1-112.el6_7.x86_64                                                                                                                                                                                                                             6/6 
  Verifying  : openssh-6.6p1-1.x86_64                                                                                                                                                                                                                                     1/6 
  Verifying  : openssh-clients-6.6p1-1.x86_64                                                                                                                                                                                                                             2/6 
  Verifying  : openssh-server-6.6p1-1.x86_64                                                                                                                                                                                                                              3/6 
  Verifying  : openssh-clients-5.3p1-112.el6_7.x86_64                                                                                                                                                                                                                     4/6 
  Verifying  : openssh-5.3p1-112.el6_7.x86_64                                                                                                                                                                                                                             5/6 
  Verifying  : openssh-server-5.3p1-112.el6_7.x86_64                                                                                                                                                                                                                      6/6 

更新完毕:
  openssh.x86_64 0:6.6p1-1                                                            openssh-clients.x86_64 0:6.6p1-1                                                            openssh-server.x86_64 0:6.6p1-1

完毕！
```

##### 1.4.6 更新SSH配置文件，避免某些参数变更造成无法远程登录

```bash
$ sudo cp /etc/ssh/sshd_config.rpmnew /etc/ssh/sshd_config
$ sudo /etc/init.d/sshd restart
```

##### 1.4.7 查看已安装的RPM

```bash
$ sudo rpm -qa | grep openssh
openssh-clients-6.6p1-1.x86_64
openssh-server-6.6p1-1.x86_64
openssh-6.6p1-1.x86_64
```

### 2. 配置ControlMaster

```bash
$ cd ~
$ vim .ssh/config
Host *
  Compression yes
  ServerAliveInterval 60
  ServerAliveCountMax 5
  ControlMaster auto
  ControlPath ~/.ssh/sockets/%r@%h-%p
  ControlPersist 4h

创建目录用于存放socket文件
mkdir ~/.ssh/sockets
```

### 3. 用cmc工具管理sockets

```bash
$ cd ~
$ sudo yum install http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
$ sudo yum install git
$ git clone https://github.com/ClockworkNet/cmc.git
$ cp cmc/cmc /usr/local/bin
```

### 4. 使用与测试

#### 4.1 查看当前的sockets

```bash
$ cmc -l
No ControlMaster connection sockets found.
```

#### 4.2 统计第一次的执行时间

```bash
$ time ssh root@server02 'hostname -s'
Mike-Slave-01
ssh root@server02 'hostname -s'  0.01s user 0.00s system 14% cpu 0.093 total
```
耗时0.093秒

#### 4.3 查看当前的sockets

```bash
$ cmc -l
server02
  Master running (pid=107064, cmd=ssh: /root/.ssh/sockets/root@server02-22 [mux], start=15:03:46)
  Socket: /root/.ssh/root@server02-22
```

#### 4.4 统计有socket情况下的执行时间

```bash
$ time ssh root@server02 'hostname -s'
Mike-Slave-01
ssh root@server02 'hostname -s'  0.00s user 0.00s system 38% cpu 0.008 total
```

耗时0.008秒

#### 4.5 删除当前所有的sockets

```bash
$ cmc -X
server02 - Closing ControlMaster connection
  Exit request sent.
```

#### 4.6 统计没有socket情况下的执行时间

```bash
$ time ssh root@server02 'hostname -s'
Mike-Slave-01
ssh root@server02 'hostname -s'  0.00s user 0.00s system 9% cpu 0.090 total
```

仍然是0.090秒

#### 4.7 用Ansible验证

未持久化socket前需要1.7秒

```bash
time ansible server02  -m ping                                       
server02 | success >> {
    "changed": false, 
    "ping": "pong"
}

ansible server02 -m ping  0.22s user 0.29s system 29% cpu 1.736 total
```

持久化后375毫秒

```bash
time ansible server02  -m ping
server02 | success >> {
    "changed": false, 
    "ping": "pong"
}

ansible server02 -m ping  0.19s user 0.10s system 78% cpu 0.375 total
```

### 5. 结论

在开启了ControlMaster的持久化之后，SSH在建立了sockets之后，节省了每次验证和创建连接的时间。
在网络状况不是特别理想，尤其是跨互联网的情况下，所带来的性能提升是非常可观的，而即使在局域网内部使用，每台服务器节省1秒左右的时间，同时操作上百台服务器时，节省的时间也是非常可观的，非常值得拥有。

### 6.总结

在应用于线上网络更为复杂的环境中时效果更为明显,在海外美国操作新加坡一次任务从5秒优化到1秒.

### 7.参考资料

http://www.ptudor.net/linux/openssh/
http://jpmens.net/2012/06/22/ssh-controlmaster/
https://github.com/ClockworkNet/cmc
http://www.kisops.com/?p=77
http://heylinux.com/archives/3152.html