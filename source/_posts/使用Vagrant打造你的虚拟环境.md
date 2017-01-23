---
title: 使用Vagrant打造你的虚拟环境
tags:
  - Vagrant
  - 技巧
categories: Vagrant
abbrlink: 4387
date: 2016-03-15 09:51:54
---

Vagrant 是基于 VirtualBox 虚拟机的，通俗的讲，就是用虚拟机的环境运行本地的代码。代码可以在本地直接编辑和调试，你可以在本地浏览器里查看运行中 Web 应用。而这套虚拟机是可以直接导入到其他电脑上的使用的，这样团队其他成员省去了配置时间，更能保证开发环境和生产环境的统一。

Vagrant的强大在于是一个镜像，配置完以后镜像可以放到任何地方去，真正做到了一劳永逸了。

Vagrant的官方网站：<http://www.vagrantup.com/>

Vagrant的一些镜像

这里各种linux都有， 然后按照官方说的，执行这三部，然后一个虚拟机就起来了。

官方镜像：<https://vagrantcloud.com/>
三方镜像：<http://www.vagrantbox.es/>

**注：先要安装VirtualBox和Vagrant**

### 使用Vagrant

```bash
#增加box

#在线方式(#debian就是box的title后面跟vagrant上的virtualbox镜像地址)
$ vagrant box add debian http://ergonlogic.com/files/boxes/debian-current.box 

#本地方式
$ vagrant box add debian 'D:\Vagrant Work\Box\debian73-x86_64-20140116.box'

#初始化
$ vagrant init debian

#启动 
$ vagrant up
```

<!-- more -->

>注意:国内网速访问很慢。这里可以先去<http://www.vagrantbox.es/>下载你需要的镜像，然后把http那行直接换成你本地镜像的路径就ok比较方便和快捷。

### Vagrant常用命令

#### 常用管理命令
```bash
$ vagrant init  #初始化,实质应是创建Vagrantfile文件
$ vagrant up  #启动虚拟机
$ vagrant halt  #关闭虚拟机
$ vagrant reload  #重启虚拟机
$ vagrant ssh  #SSH至虚拟机
$ vagrant status  #查看虚拟机运行状态
$ vagrant destroy  #销毁(删除)当前虚拟机(除Vagrantfile中的配置所有数据都不会保留)
$ vagrant suspend #暂停虚拟机——只是暂停，虚拟机内存等信息将以状态文件的方式保存在本地，可以执行恢复操作后继续使用
$ vagrant resume #恢复虚拟机 —— 与前面的暂停相对应
```
#### box管理

```bash
$ vagrant box list
$ vagrant box add
$ vagrant box remove
```

#### 连接虚拟主机

你会看到终端显示了启动过程，启动完成后，我们就可以用SSH登录虚拟机了，剩下的步骤就是在虚拟机里配置你要运行的各种环境和参数了。

```
#SSH登录
$ vagrant ssh   #ssh的后面可以跟你的title来连接不同的vm主机
```

#### 打包分发

当你配置好开发环境后，退出并关闭虚拟机。在终端里对开发环境进行打包：

```bash
$ vagrant package
```
打包完成后会在当前目录生成一个package.box 的文件，将这个文件传给其他用户，其他用户只要添加这个box并用其初始化自己的开发目录就能得到一个一模一样的开发环境了。

>注：如果网络模式中使用 private_network 的话，在打包之前需要清除一下private_network的设置，避免不必要的错误：
`sudo rm -f /etc/udev/rule.d/70-persistent-net.rules`
制作完成之后直接将box文件拿到其他计算机上配置即可使用。

更多内容请查阅官方文档<http://docs.vagrantup.com/>