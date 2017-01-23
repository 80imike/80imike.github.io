---
title: 开启Google BBR算法提升网络速度
tags:
  - Google
  - Linux
categories: Linux
abbrlink: 64279
date: 2016-12-21 09:00:00
updated:
toc_number:
---

### 什么是BBR

TCP BBR是谷歌出品的TCP拥塞控制算法，BBR目的是要尽量跑满带宽，并且尽量不要有排队的情况。BBR可以起到单边加速TCP连接的效果。替代锐速再合适不过，毕竟免费。

Google提交到Linux主线并发表在ACM queue期刊上的TCP-BBR拥塞控制算法。继承了Google“先在生产环境上部署，再开源和发论文”的研究传统。TCP-BBR已经再YouTube服务器和Google跨数据中心的内部广域网(B4)上部署。由此可见出该算法的前途。

TCP-BBR的目标就是最大化利用网络上瓶颈链路的带宽。一条网络链路就像一条水管，要想最大化利用这条水管，最好的办法就是给这跟水管灌满水。

BBR解决了两个问题：

1. 再有一定丢包率的网络链路上充分利用带宽。非常适合高延迟，高带宽的网络链路。
1. 降低网络链路上的buffer占用率，从而降低延迟。非常适合慢速接入网络的用户。

项目地址:https://github.com/google/bbr

<!-- more -->

### 安装BBR

BBR是内嵌在Linux内核中的，目前Linux Kernel 4.9已加入了该算法，所以安装新版本内核开启BBR即可享用。

* Debian/Ubuntu

下面简单讲述如何在Debian/Ubuntu 64bit系统中升级kernel开启TCP BBR拥塞控制算法。

**下载最新内核**

最新内核查看这里：http://kernel.ubuntu.com/~kernel-ppa/mainline/

```bash
$ cd ~;mkdir linux49; cd linux49
$ wget http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.9/linux-headers-4.9.0-040900-generic_4.9.0-040900.201612111631_amd64.deb
$ wget http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.9/linux-image-4.9.0-040900-generic_4.9.0-040900.201612111631_amd64.deb
$ wget http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.9/linux-headers-4.9.0-040900_4.9.0-040900.201612111631_all.deb
```

**开始安装**

```bash
$ dpkg -i *.deb
```

以上用于64位系统，其它可以自行下载Index of /~kernel-ppa/mainline/v4.9 对应版本。

**删除其余内核(非必需)**

```bash
$ dpkg -l|grep linux-image
$ apt-get remove linux-image-[Tab补全] #删旧内核，在这里，就是把第一个3.13的删掉
```

**更新grub系统引导文件并重启**

```bash
$ update-grub
```

**重启系统并查看内核**

```bash
$ reboot
$ uname -a
```


* Centos/RHEL


通过使用ELRepo源的方式在CentOS中安装最新版kernel。

**CentOS 6**

**下载内核并安装**

```bash
$ rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
$ rpm -Uvh http://www.elrepo.org/elrepo-release-6-6.el6.elrepo.noarch.rpm
$ yum --enablerepo=elrepo-kernel install kernel-ml -y
```

**查看内核是否安装成功**

```bash
$ rpm -qa | grep kernel
```

更新grub系统引导文件并重启

```bash
$ sed -i 's:default=.*:default=0:g' /etc/grub.conf
$ reboot
```

**CentOS 7**

**下载内核并安装**

```bash
$ rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
$ rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-2.el7.elrepo.noarch.rpm
$ yum --enablerepo=elrepo-kernel install kernel-ml  kernel-ml-devel -y
```

**查看内核是否安装成功**

```bash
$ rpm -qa | grep kernel
```

**更新grub系统引导文件并重启**

```bash
$ egrep ^menuentry /etc/grub2.cfg | cut -f 2 -d \' #删除其余内核(非必需)
$ grub2-set-default 0  #default 0表示第一个内核设置为默认运行, 选择最新内核就对了
$ reboot
```

**Google TCP BBR一键安装脚本**

* 适用于Centos6 32位和64位

```bash
$ wget --no-check-certificate https://github.com/52fancy/GooGle-BBR/raw/master/BBR.sh && sh BBR.sh
```

* 适用于Centos 6/7  仅适用64位）

```bash
$ wget -O- http://soft.wellphp.com/scripts/install_bbr_centos.sh | bash
```

### 开启BBR

安装内核后从刚安装的内核启动，然后执行

```bash
$ echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
$ echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
```

保存生效

```bash
$ sysctl -p
```

验证是否安装成功

执行以下命令，如果结果中有bbr则证明你的内核已开启bbr。

```bash
$ sysctl net.ipv4.tcp_available_congestion_control
net.ipv4.tcp_available_congestion_control = bbr cubic reno

$ lsmod | grep bbr
tcp_bbr                20480  0
```

开启BBR后效果图

![](http://o75o1rrhq.bkt.clouddn.com/wp-content/uploads/2016/12/reno_cubic_bbr-1024x520.png)


### 关闭bbr

```bash
$ sed -i '/net\.core\.default_qdisc=fq/d' /etc/sysctl.conf
$ sed -i '/net\.ipv4\.tcp_congestion_control=bbr/d' /etc/sysctl.conf
$ sysctl -p
```

执行完上面的代码，使用`reboot`重启后才能关闭bbr，重启后再用下面的查看bbr状态代码，查看是否关闭了。

```bash
$ lsmod | grep bbr
```

如果结果中没有bbr, 则证明你的内核已关闭bbr

### 参考文档

http://www.google.com
https://zhuanlan.zhihu.com/p/24418274
http://blog.flydust.space/tcp-bbr/
