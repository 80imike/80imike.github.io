---
title: Linux群常见问题整理(二)
tags:
  - Linux
  - 技巧
categories: Linux
abbrlink: 33498
date: 2016-03-15 09:51:54
---

离上次整理的[Linux群常见问题整理(一)]有一段时间了。最近好像群里没多少这种小问题的讨论了。加上最近有不少新的群友加入，忙着整理群成员信息，准备发布[群成员信息统计(Ver1.3)]。迟迟没有总结出第二篇的常见问题整理。

近来有几个网友在QQ上问我一些Linux的问题，解答过程中发现有些同学的基础太差了(这种情况还真的不算少数)，连一些最基本的计算机常识都还很欠缺。是现在教育的失败？是他们对技术的更加浮燥？是他们急攻进利？还是总想找到捷径？或是其它什么？难道在国内这个IT行业技术圈里，真的是越来越浮燥！真的是一代不如一代了！不啰嗦了，入正题吧。呵呵！

Q：Linux系统时钟比物理时钟变快了?(提供人:土猪一号)
A：Linux在驱动AMD+ATI的系统会有一个 bug，使得系统时钟比物理时钟大约整整快一倍。解决这个问题，可以修改 /boot/grub/menu.lst，在kernel命令中加入noapictimer参数。 

如有一kernel命令如下：
```bash
kernel /boot/vmlinuz-2.6.12-10-k7 root=/dev/hda3 ro quiet splash
```
将这行改为
```bash
kernel /boot/vmlinuz-2.6.12-10-k7 root=/dev/hda3 ro noapictimer quiet splash
```
然后再重启即可<!-- more -->

关于APIC

APIC全称是Advanced Programmable Interrupt Controller(高级可编程中断控制器)，对计算机来讲有两个作用：一是管理IRQ的分配，可以把传统的16个IRQ扩展到24个(传统的管理方式叫PIC)，以适应更多的设备。二是管理多CPU(支持多处理器中断管理，中断均匀的分布在所有处理器)。

关于APIC timer

The APIC timer module is an implementation of precise timers for the Linux 2.4 kernels and further. The module provides microsecond precision timers that are programmed with a TSC value.

It is accomplished by using the timer of the local APIC, availaible on P6 processors. 

更多可见<a href="http://www.oberle.org/apic_timer.html" target="_blank">APIC timer Module for Linux</a>

Q：删除文件列表文件中所有的文件(提供人:galf)
A：实现指令如下
```bash
cat file.txt | while read i ;do rm -rf -- "$i";done 
```
注：可处理较特殊的文件

Q:如何提取tar包中的指定文件(提供人:Mike)

A:先查看一下你要的文件的名称(包含路径)：
```bash
tar tzvf foo.tar.gz | grep abc
```
解压单个象这样解压
```bash
tar xzvf foo.tar gz path/to/abc
```
解压多个象这样解压
```bash
tar xzvf foo.tar gz path/to/abc path/to/xyz
```
一个实例，把a.tar中的./b.txt解析出来,注意路径。
```bash
tar -xf a.tar ./b.txt
```
Q：Linux共享内存的查看、释放、修改(提供人:三办门)
A：查看共享内存，使用ipcs命令，不加任何参数时，这条命令会把共享内存/信号量/消息队列的信息都打印出来。如果只想显示共享内存信息，则使用ipcs -m。

要删除共享内存，需要使用ipcrm命令，使用shmid做为参数。shmid在ipcs命令中会有输出。下面的命令可以释放所有已分配的共享内存：
```bash
ipcs -m | awk '$2 ~ /[0-9]+/ {print $2}' | while read s; do sudo ipcrm -m $s; done
```
修改内核共享内存大小

方法一：修改/etc/rc.d/rc.local文件，在文件的前面注释的后面加入以下行：
```bash
echo 134217728>/proc/sys/kernel/shmmax;
```
注：这里的值为内存的一半;如果系统内存是256M，则值为134217728;#如果系统内存是512M，则值为268435456;修改完成以后，重启机器就搞定。

方法二：

永久修改，root用户下
```bash
echo "kernel.shmmax=1073741824">>/etc/sysctl.conf
```
临时修改，root用户下
```bash
sysctl -w kernel.shmmax=1073741824
```
注：kernel.shmmax = 2147483648 #最大单个共享内存段大小。取物理内存大小的一半,单位为字节

<a href="http://ud1121.blog.51cto.com/228311/198808" target="_blank">ipcs命令详解</a>

<a href="http://blog.csdn.net/lh1979/archive/2009/10/12/4660727.aspx" target="_blank">Oracle相关的Linux内核参数设置</a>

Q：LINUX静态路由设置问题(提供人:Mike)
A：RedHat下静态路由设置有三种方式：

方法一：修改eth0.route文件(redhat下的一种新的格式)
```bash
/etc/sysconfig/network-scripts/eth0.route

ADDRESS0=192.168.0.0
NETMASK0=255.255.0.0
GATEWAY0=10.1.1.254

ADDRESS1=172.16.0.0
NETMASK1=255.240.0.0
GATEWAY1=10.1.1.254
```
　方法二：修改route-eth0文件(redhat下的老格式)
```bash
/etc/sysconfig/network-scripts/route-eth0

192.168.0.0/16 via 10.1.1.254
172.16.0.0/12 via 10.1.1.254
```
　方法三：修改static-routes文件
```bash
/etc/sysconfig/static-routes

eth0 net 192.168.0.0 netmask 255.255.0.0 gw 10.1.1.254
```
Debian/Ubuntu静态路由配置

修改route-eth0文件
```bash
/etc/sysconfig/network-scripts/route-eth0

#Append following line
10.0.0.0/8 via 10.9.38.65
```
注：上面几种方法都比在rc.local里面用指令route add或者ip route add要更加好一些。重启网络(service network restart)或者重启网卡(ifdown eth0;ifup eth0)都可以正常工作。