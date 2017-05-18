---
title: Linux群常见问题整理(三)
tags:
  - Linux
  - 技巧
categories: Linux
abbrlink: 4728
date: 2016-03-15 09:51:54
---

[Linux群常见问题整理]坚持整理到了第三期，是个不错的开头。自我鼓励下，希望以后能一直坚持下去。哈哈！这次整理的一些小技巧都还是挺实用的。在发布到这里的同时，打算以后在CU上也发一份，把一些有用的知识点分享给更多学习Linux的朋友们。

Q：Linux终端下同时输入ctrl+v,ctrl+n回车后产生乱码？(提供人:Neil)
A：如果终端显示16进制字符E就会出现乱码，只要输入16进制F就能恢复。
```bash
echo -e '\xf'
```
Q：bash中如何取得当前进程的pid(提供人:galf）
A：用$$来取。
```bash
echo $$ 
```
Q：内核升级后重启内核失败的panic kill的问题(提供人:土猪一号)<!-- more -->

重启内核失败的现象如下
```bash
mount: could not find filesystem '/dev/root'
setuproot: moving /dev failed: No such file or directory
setuproot: error mounting /proc: No such file or directory
setuproot: error mounting /sys: No such file or directory
switchroot: mount failed: No such file or directory
Kernel panic - not syncing: Attempted to kill init!
```
A：产生问题的主要原因：是由于无法加载磁盘硬件的模块驱动。解决方式主要是通过make menuconfig中加载sata sici的devices设备模块驱动。常用的驱动模块如下：
```bash
insmod /lib/uhci-hcd.ko 
insmod /lib/ohci-hcd.ko 
insmod /lib/ehci-hcd.ko 
insmod /lib/jbd.ko
insmod /lib/ext3.ko
insmod /lib/scsi_mod.ko
insmod /lib/sd_mod.ko
insmod /lib/libata.ko
insmod /lib/ahci.ko 
```
如果你initrd中已包含了相应的SATA驱动，出现这种现象的原因就可能是因为initrd是旧版本mkinitrd生成的。

解决方法就是加入对旧版sysfs路径的支持，方法如下:

a)、通过make menuconfig选中以下对应的选项
```bash
General setup--> [*] enable deprecated sysfs features to support old userspace tools 
```
b)、修改.config文件

修改.config文件中CONFIG_SYSFS_DEPRECATED_V2
```bash
CONFIG_SYSFS_DEPRECATED_V2=y #默认该选项为not set,被注释掉的。
```
>注:修改这项是因为旧版的mkinitrd及其nash在内核没有CONFIG_SYSFS_DEPRECATED_V2参数时默认使用旧版sysfs路径格式，从而在新内核下无法正确访问/sys内的硬盘信息节点。

Q：如何快速编译内核模块(提供人:枪炮)
A：常用的方法有以下两种：

方法一：

格式：
```bash
make -C $KDIR M=$PWD modules 
```
例子：

如在内核源码树内
```bash
make CONFIG_REISER4_FS=m M=fs/reiser4 modules
```
如在内核源码树外
```bash
make CONFIG_FUSE_FS=m -C /home/blue/linux/linux-2.6.24.3 M=/home/blue/linux/linux-2.6.24.3/drivers/char/mydriver/ modules

或者

make KERNEL_DIR=xxx   M=$PWD modules　　//KERNEL_DIR也是内核源码所在的路径
```
方法二

格式：
```bash
make -C $KDIR SUBDIRS=$PWD modules 
```
例子：

如在内核源码树外
```bash
# cd /home/usb/usb-2.6.21.5/
make -C /usr/src/linux/ SUBDIRS=$PWD modules
```
如在内核源码树内
```bash
make CONFIG_REISER4_FS=m SUBDIRS=fs/reiser4 modules
```
>注：make -C $KDIR用来指定内核源代码的路径。'$KDIR'描述内核源代码的目录。Make会进入实际指定的目录执行,但是完成执行时会返回当前的目录。M=用来告诉kbuild正在构建一个外部模块，M=是外部模块(kbuild文件)所在的目录。和M=选项一样,SUBDIRS=的效果一样，是旧的语法。保证向后兼容的。

Q：kill指令的一些小技巧(提供人:土猪一号,Mike)
A：关闭当前shell下产生的所有进程
```bash
kill -9 0
```
>注：PID  0表同一进程组的进程

关闭大于1所有进程
```bash
kill -9 -1
```
>注：man中的解释
>-1 All processes with pid larger than 1 will be signaled。
>   Kill all processes you can kill。

检查PID是否存在
```bash
kill -0 pid
```
>注：对于信号“0”MAN中的解释：exit code indicates if a signal may be sent

Q：用phpize编译动态扩展模块？

A：phpize命令是用来准备PHP扩展模块的编译环境，通过phpize可以建立php的扩展模块。phpize是属于php-devel包中(档案预设存放于/usr/bin/phpize)。

整个过程和动态编译apache的模块非常相似，类似于apache的apxs

下面是一个例子，扩展模組的源程序位于extname目录中：
```bash
$ cd extname
$ phpize
$ ./configure     
$ make
# make install
```
>注意：如在执行./configure时出现"configure: error: Cannot find php-config. Please use --with-php-config=PATH"时，说明你的配置文件位置可能不在缺省目录(–with-php-config预设在/usr/bin/php-config)。可重下类似以下指令调整：
```bash
./configure --with-php-config=/usr/local/php/bin/php-config
```
这个文件通常是在php安装目录的bin目录下的一个文件名叫做php-config或者php-config5的文件。

然后把该目录下的extname.so复制到你php.ini中的extension_dir指向的目录中，最后需要调整php.ini文件，加入extension=extname.so这一行之后才能使用此扩展库。

重启web服务器,使你的php配置更新。用phpinfo()检查新模块是否生效。

任意建一个PHP页面，加入以下代码：
```bash
<?php phpinfo(); ?>
```
访问这个页面，如果增加了你刚刚添加的模块，基本上就证明OK了。

Q：一个不会kill shell自身的指令(提供人：竹)
A：killall5是SystemV中的一个killall(杀死所有进程)命令.它会向所有进程发送一个信号,但调用killall5命令的shell自身不会被kill(杀掉)。

命令格式
```bash
killall5 -signalnumber
```
Q：什么是dmraid?(提供人:金雕,Mike)

dmraid 全名为设备对应器磁盘阵列(Device Mapper RAID)，利用Linux内核提供的设备对应器（Device Mapper）机制，为多种磁盘阵列设备提供磁盘阵列的设备文件，让用户可以在Red Hat Enterprise Linux系统中使用硬件磁盘阵列设备。

dmraid主要针对BIOS RAID(Fake RAID)。

更详细的资料可见：<a href="http://www.babyface.idv.tw/NetAdmin/11200612dmraid/" target="_blank">dmraid介绍Linux上应用ATA/SATA RAID技术(原文)</a>#需翻墙  
　　　　　　　　　<a href="http://www.php-oa.com/2008/01/31/dmraidjieshaolinuxshangyingyongatasataraidjishu.html" target="_blank">dmraid介绍Linux上应用ATA/SATA RAID技术(转载)</a>#墙内可访问　