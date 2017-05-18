---
title: CentOS下实现SFTP CHROOT的几种方法
tags:
  - Linux
  - SFTP
  - 技巧
categories: SFTP
toc_number: false
abbrlink: 15727
date: 2016-03-15 09:51:54
---
### 一、通过MySecureShell实现

#### 什么是MySecureShell

> MySecureShell is a sftp-server developing tool which help to make a ftp server like proftpd but very securised with SSH encryption. This software is highly configurable and very easy to install and use.<!-- more -->

#### 安装MySecureShell

- 配置三方软件源

##### Centos 5

```
$ vim /etc/yum.repos.d/mysecureshell.repo

[mysecureshell]
name=MySecureShell
baseurl=http://mysecureshell.free.fr/repository/index.php/centos/5.5/
enabled=1
gpgcheck=0
```

##### Centos 6

```
$ vim /etc/yum.repos.d/mysecureshell.repo

[mysecureshell]
name=MySecureShell
baseurl=http://mysecureshell.free.fr/repository/index.php/centos/6.4/
enabled=1
gpgcheck=0

```

- 安装MySecureShell

```
$ yum --disablerepo=\* --enablerepo=mysecureshell install mysecureshell
```

#### 配置MySecureShell
```
$ vi  /etc/ssh/sftp_config

主要修改以下几项
LimitConnection         10      #max connection for the server sftp
LimitConnectionByUser   1       #max connection for the account
LimitConnectionByIP     2       #max connection by ip for the account
Home                    /home/$USER     #overrite home of the user but if you want you can use
                                        #environment variable (ie: Home /home/$USER)
```
> LimitConnectionByUser、LimitConnectionByIP、LimitConnection根据需要可适当调大点，不然可能会现连接不上的现像。Home这项如果建用户时指定了主目录且不在缺省的/home下，可以把这项注释掉或修改为用户主目录所在位置。如果用户主目录在/home下可保持不变。

##### 修改用户Shell为MySecureShell
```
$ chsh -s /bin/MySecureShell mike
```

### 二、通过OpenSSH的internal-sftp实现

如果要启用OpenSSH自带的的Chroot功能，OpenSSH版本必需在在4.8p1以上。

#### 检查OpenSSH版本
```
$ rpm -qa|grep openssh

openssh-4.3p2-26.el5
openssh-server-4.3p2-26.el5
openssh-askpass-4.3p2-26.el5
openssh-clients-4.3p2-26.el5
```
由于CentOS5.X自带的OpenSSH版本过低不支持SFTP CHROOT,所以需要先把SSH升级到4.8P1以上。升级可参考：[CentOS下安装OpenSSH 5.8的三种方法](http://www.mike.org.cn/articles/centos-install-openssh/)

#### 创建用于SFTP的用户
```
$ useradd  -d /home/TempUpload/ -M test2
```
#### 配置sshd_config
```
$ vi  /etc/ssh/sshd_config

#注释原本的Subsystem设置
Subsystem	sftp	/usr/libexec/openssh/sftp-server

#启用internal-sftp
Subsystem       sftp    internal-sftp

Match User	test2 
ChrootDirectory /home/TempUpload
ForceCommand	internal-sftp
```
> Match user设定要被chroot的用户，若要设定多个帐号, 帐号间以逗号隔开。例如：Match user userA,userB
> 
> 如果是群组的则将User改为Group后，再接群组名称。例如：Match Group rootedSFTP
>                                                        
> ChrootDirectory设定要chroot的位置，可以加上PATTERNS做区隔。如/home/%u，%u表示用户变量，%h为限制到用户的主目录。更多可见:man sshd_config
                                                       
#### 设定Chroo目录权限
```
$ chown root:root /home/TempUpload
$ chmod 755 /home/TempUpload
```
> 错误的目录权限设定会导致在log中出现"fatal: bad ownership or modes for chroot directory XXXXXX" 的讯息。
> 目录的权限设定有两个要点：
> 1、由ChrootDirectory指定的目录开始一直往上到系统根目录为止的目录拥有者都只能是root
> 2、由ChrootDirectory指定的目录开始一直往上到系统根目录为止都不可以具有群组写入权限


#### 建立SFTP用户登入后可写入的目录
```
$ mkdir /home/TempUpload/Upload
$ chown test2:test2 /home/TempUpload/Upload
```
#### 检查sshd_config內容是否正确
```
$ sshd -T
```
#### 重新启动sshd
```
$ service sshd restart
```
### 三、其它方法

　　还可通过scponly和rssh实现，这两个的原理和MySecureShell差不多，不过这两个必须先做得做一个CHROOT环境，相对比较麻烦些。

　　有兴趣的可以看下下面这些资料：

> RSSH
> <http://www.sky-hosts.com/rsshchroot.html>
> <http://7056824.blog.51cto.com/69854/247666>
> <http://blog.zol.com.cn/1710/article_1709770.html>
> <http://blog.sina.com.cn/s/blog_704836f40100m21o.html>

> ScpOnly
> <http://dev.yidianhulian.com/2011/01/19/how-to-install-scp/>
> <http://dev.firnow.com/course/6_system/linux/Linuxjs/20090824/170790.html>
> <http://www.604f.com/read.php?18>