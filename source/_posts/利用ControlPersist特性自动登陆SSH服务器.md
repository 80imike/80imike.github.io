---
title: 利用ControlPersist特性自动登陆SSH服务器
tags:
  - OpenSSH
  - Linux
categories: OpenSSH
abbrlink: 39001
date: 2016-04-13 09:00:00
updated:
toc_number:
---
### 背景介绍

很多公司都使用静态密码+动态密码的方式登陆跳板机，某些还会强制一个动态密码只能登陆一次，于是我们面临着等一分钟才能登陆一次跳板机，很不方便。本文介绍一种在本机的设置，免除每次输入密码的方法。

### 实现方法

此功能是利用SSH的ControlPersist特性，SSH版本必须是5.6或以上版本才可使用ControlPersist特性。升级SSH可参考[CentOS6下升级OpenSSH至7.1](http://imike.me/2016/04/13/CentOS6%E4%B8%8B%E5%8D%87%E7%BA%A7OpenSSH%E8%87%B37.1/)一文。

#### 多条连接共享

如果你需要在多个窗口中打开到同一个服务器的连接，而不想每次都输入用户名，密码，或是等待连接建立，那么你可以配置SSH的连接共享选项，在本地打开你的SSH配置文件，通常它们位于~/.ssh/config，然后添加下面2行(ControlMaster配合ControlPath一起使用)

```bash
ControlMaster auto
ControlPath /tmp/ssh_mux_%h_%p_%r
```
<!-- more -->

现在试试断开你与服务器的连接，并建立一条新连接，然后打开一个新窗口，再创建一条连接，你会发现，第二条连接几乎是在瞬间就建立好了。

Windows用户

如果你是Windows用户，很不幸，最流行的开源SSH客户端Putty并不支持这个特性，但是Windows上也有OpenSSH的实现，比如这个[Copssh](https://www.itefix.net/copssh)

文件传输

连接共享不止可以帮助你共享多个SSH连接，如果你需要通过SFTP与服务器传输文件，你会发现，它们使用的依然是同一条连接，如果你使用的Bash，你会发现，你甚至SSH甚至支持Tab对服务器端文件进行自动补全，共享连接选项对于那些需要借助SSH的工具，比如rsync，git等等也同样有效。

#### 长连接

如果你发现自己每条需要连接同一个服务器无数次，那么长连接选项就是为你准备的。

```bash
ControlPersist yes
```

打开之后即使关闭了所有的已连接ssh连接，一段时间内也能无需密码重新连接。

```bash
ControlPersist 4h
```

每次通过SSH与服务器建立连接之后，这条连接将被保持4个小时，即使在你退出服务器之后这条连接依然可以重用，因此，在你下一次(4小时之内)登录服务器时，你会发现连接以闪电般的速度建立完成，这个选项对于通过scp拷贝多个文件提速尤其明显，因为你不在需要为每个文件做单独的认证了。

Compression为压缩选项，打开之后加快数据传输速度。

#### 具体配置方法

此时我们打开ssh客户端/shell命令行，编辑~/.ssh/config文件

```bash
vim ~/.ssh/config

Host *
     ControlPersist yes
     ControlMaster auto
     ControlPath ~/.ssh/%r@%h-%p
     Compression yes
```
	 
如果登陆服务器地址为`web.imike.me`，通常每次都要输入`ssh web.imike.me`这样一长串。优化上面的配置可减少输入，提高效率。如下:

```bash
Host web
      HostName web.imike.me
      ControlPersist yes
      ControlMaster auto
      ControlPath ~/.ssh/%r@%h-%p
      Compression yes
```

这样每次只需输入ssh web即可登陆。大家自行修改HostName和ControlPath字段就可以。

用指定用户名和指定端口登陆，可以使用下面的代替，同理使用`ssh web02`命令登陆。

```bash
Host web02
      HostName 202.202.202.202
      User mike
	  Port 2698
      ControlPersist yes
      ControlMaster auto
      ControlPath ~/.ssh/%r@%h-%p
      Compression yes
```

### 参考文档

http://www.google.com
http://blog.csdn.net/xuanwu_yan/article/details/45666797
