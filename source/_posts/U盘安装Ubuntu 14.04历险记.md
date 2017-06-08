---
category: Ubuntu
title: U盘安装Ubuntu 14.04历险记
date: 2017-06-08 9:00:00
tags: [Ubuntu,Linux]
abbrlink:
updated:
toc_number: false
---

对于做运维的同学来说U盘装个系统不就是分分钟的事吗，这有什么好说的？U盘安装系统一般就是如下几步：

- 下载系统镜像。
- 通过刻录软件写入U盘。
- 修改BIOS，从U盘引导。
- 喝杯咖啡，愉快的等待安装完成。

通常按操上面的步骤如法炮制都是屡试不爽的，可偏偏通过U盘安装Ubuntu却是问题重重，下面我们就来说说几个U盘安装Ubuntu Server时遇到的问题。

<!-- more -->

**安装过程提示找不到CD-ROM错误**

使用U盘安装Ubuntu Desktop通常不会有问题，但是安装Ubuntu Server的时候却容易出现检查不到光驱(detect and mount CD-ROM)的问题。

进入安装镜像之后选择安装系统，开始一切都很顺利，比如选择语言、地区、时区等等。看上去一切都是那么美好，突然弹出了找不到CD-ROM的错误。

![](https://www.hi-linux.com/img/linux/uinstall1.png)


选择继续之后，提示说这一步安装失败，让我们重新挂载CD-ROM之后再继续。

![](https://www.hi-linux.com/img/linux/uinstall2.png)

可是服务器上真没有光驱，这叫我如何是好呀？是不是很多同学遇到这个错误时，心中都百般无赖！今天就来说说这个错误如何解决吧，是不是马上觉得人生有了希望，哈哈！


在上面的界面上选继续后会出现下面的界面，这个时候选择运行shell，会进入一个Shell界面。

![](https://www.hi-linux.com/img/linux/uinstall3.png)

![](https://www.hi-linux.com/img/linux/uinstall4.png)

在Shell下执行如下指令：

```
# 确定U盘设备名，通常都会是sdb1
$ ls /dev/sd*
# 新建一个用于挂载U盘的目录
$ mkdir uinstall
# 挂载U盘到uinstall目录
$ mount /dev/sdb1 /uinstall
# 挂载U盘中的Ubuntu安装镜像到cdrom目录
$ mount -o loop -t iso9660 /uinstall/ubuntu-14.04.5-server-amd64.iso /cdrom
# 检查cdrom目录下内容是否正确
$ ls /cdrom
# 退出当前Shell
$ exit
```

重新探测并挂载光盘，然后一路继续，通常后面的过程应该是畅通无阻了。

![](https://www.hi-linux.com/img/linux/uinstall5.png)

都说是通常了，如果你运气不好会碰到下面的第二个问题。


**无法进行配置和包管理步骤**

正常情况下安装到这一步的时候会弹出一个窗口提示需要安装什么软件，通常会选择先让系统装好必备的`OpenSSH Server`的。但是这次到这个步骤后，直接弹出了下面的手动选择安装菜单。

![](https://www.hi-linux.com/img/linux/uinstall6.jpg)

不管是[手工选择配置和包管理]还是[选择和安装软件]步骤都会跳出来，进入不了下一步。眼看胜利在望了，却又打回到起点，有没有世界都要崩塌的感觉！既然前面的问题都解决了，没理由不把你从沟里带出来吧。下面说说如何解决：

- 先暂时跳过软件包安装，继续选择安装GRUB引导。

- 在安装GRUB引导后的最终安装环节，不要选继续而是选择退回。

![](https://www.hi-linux.com/img/linux/uinstall7.jpg)

- 再次在手动选择安装菜单中选择[配置和软件包管理]，这回终于能够看到熟悉的安装各种软件包的过程了。

![](https://www.hi-linux.com/img/linux/uinstall8.jpg)


经过九九八十一难后，最终成功的完成了通过U盘来安装Ubuntu Server 14.04。

> 注：以上过程都已经验证过了。由于安装过程中没法截图，以上图片来自网络。前后有点不一致，将究着看嘛。

**附送一个Windows 2012技巧**

- Windows Server 2012 R2在桌面上显示我的电脑等图标

在Windows Server 2012 R2系统中，微软取消了服务器桌面个性化选项。如果要重新调出配置界面，方法如下：

a) 同时按住键盘上的「Windows键」+「R」，呼叫运行对话窗口。在运行中输入`rundll32.exe shell32.dll,Control_RunDLL desk.cpl,,0`后，按确定。(一定要注意命令中的大小写)

![](https://www.hi-linux.com/img/linux/uinstall9.jpg)

b) 在弹出的桌面个性化窗口选择需要在桌面显示的图标。

![](https://www.hi-linux.com/img/linux/uinstall10.jpg)

c) 点击确定，即可在桌面上看到「这台电脑」、「网络」等图标了。　

![](https://www.hi-linux.com/img/linux/uinstall11.jpg)

**参考文档**

http://www.google.com
http://www.candura.us/posts/post-344/
http://www.cnblogs.com/oloroso/p/4665107.html
http://lorysun.blog.51cto.com/1035880/1317770
