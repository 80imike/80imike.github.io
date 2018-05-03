---
category: Ubuntu
title: Ubuntu 18.04 LTS (Bionic Beaver) 正式发布，一大波新特性到来!
date: 2018-04-27 09:00:00
tags: [Linux, Ubuntu]
abbrlink:
updated:
toc_number: false
---

Ubuntu 18.04 正式版本已经发布了，代号为「Bionic Beaver，仿生海狸」的 Ubuntu 18.04 版本是基于 Linux 内核的 Ubuntu 操作系统的又一个长期支持版本。

Ubuntu LTS 版本每两年发布一次，而 Ubuntu 18.04 是自 2016 年以来的第一个长期支持版本。Ubuntun 长期支持版本可以获得 Canonical 官方长达五年的技术支持，这意味着在 2023 年之前所有用户都可以放心使用 Ubuntu 18.04 LTS。

Ubuntu 18.04 LTS 被 Canonical 创始人 Mark Shuttleworth 命名为「Bionic Beaver，仿生海狸」，这主要是为了纪念 Ubuntu 人孜孜不倦的辛劳工作。海狸具有充满活力的态度和勤劳的本性，所以此次版本更新周期以这种哺乳动物作为吉祥物进行命名。

我们为什么要升级到 Ubuntu 18.04 LTS 呢？ 接下来我们一起来了解一下 Ubuntu 18.04 的新功能吧！

<!-- more -->

### 桌面版本更新内容

**安全增强**

首先，所有用户都应该定期升级当前的 Ubuntu 版本，以便从最新的安全补丁中受益。（系统更新可能适用于操作系统、驱动程序甚至底层硬件）

值得指出的是，所有操作系统都是如此，无论是基于 Linux、Windows 还是 macOS，定期更新都可以提高您计算机的安全性。

但有一个潜在的安全问题应该注意，与微软的 Windows 10 操作系统类似，Canonical 打算从 Ubuntu 18.04 LTS 开始从用户的计算机收集一些数据。所收集的这些数据并不标示任何用户身份，只是建立计算机硬件、运行的 Ubuntu 版本、位置信息（可选）和一些其它数据的档案。

**「最小安装」选项**

不要将「Minimal Install 」最小化安装选项与 Ubuntu 18.04 最小化版本相混淆，Ubuntu 18.04 Ubiquity 安装程序增加了一个全新的「Minimal Install 」最小化安装选项，它可以将 Ubuntu 压缩为只有 30MB 的 containers/Docker、嵌入式 Linux 环境和其他相关用例，只需使用浏览器和实用程序即可安装最少的桌面环境。

此安装选项可以除去 Thunderbird、Transmission、Rhythmbox、LibreOffice（包括语言包）、Cheese 和 Shotwell 等 80 项功能，在应用程序启动器中只留下 Firefox、Nautilus、Ubuntu 软件和帮助。

**新内核 Linux Kernel 4.15**

Ubuntu 18.04 LTS 还将附带了 Linux Kernel 4.15，其中包含针对 Spectre 和 Meltdown 错误的修复程序。

除了 Specter 和 Meltdown 错误修复之外，Linux Kernel 4.15 还为 Raspberry Pi 7 英寸触摸屏提供原生支持，并支持安全加密虚拟化。

**Ubuntu 首次运行向导**

![](https://www.hi-linux.com/img/linux/ubuntu-1804-1.png)

全新的安装或升级到 Ubuntu 18.04 都将迎来一个名为 「欢迎使用Ubuntu」的全新首次运行向导。

**GNOME正式抵达**

1. GNOME Shell 桌面环境

Ubuntu 18.04 LTS 发布的同时也带来了 GNOME 3.28，由于 GNOME 在 Ubuntu 17.10 中已经取代了 Unity（尽管 Unity 并未完全挂掉），因此 GNOME 也已经成为了 Ubuntu 系统默认的桌面环境。

![](https://www.hi-linux.com/img/linux/ubuntu-1804-2.png)

当然，如果你不喜欢使用 GNOME，其他 Ubuntu 桌面环境也是可用的，如：MATE。

GNOME 正式来到 Ubuntu 18.04 LTS 桌面也标志着新统一风格定制的 GNOME 3.0 桌面在长期支持版本上得到支持，这也是升级到 Ubuntu 18.04 系统一个很好的理由。

2. 更好的通知

![](https://www.hi-linux.com/img/linux/ubuntu-1804-3.png)

这不仅仅是因桌面切换而改变的覆盖布局, Ubuntu 18.04 以不同于 Ubuntu 16.04 LTS的方式处理桌面通知，通知现在显示在屏幕的上方中央。远离桌面时，您也不会错过通知。 所有未处理的通知现在都存储在日历和消息托盘中，以便您不会错过它们。

3. 新的登录和锁定屏幕

GNOME显示管理器（GDM3）接管了来自 LightDM 和 Unity Greeter 的登录和锁定屏幕职责。

![](https://www.hi-linux.com/img/linux/ubuntu-1804-4.png)

登录屏幕与之前差不多相同，不过不在支持远程登录或访客登录功能，并且登录屏幕不可再为每个帐户显示个性化壁纸。

![](https://www.hi-linux.com/img/linux/ubuntu-1804-5.png)

新的锁屏下您可以设置自定义背景墙纸，并在您离开时控制通知内容。

**全新的图标集**

![](https://www.hi-linux.com/img/linux/ubuntu-1804-6.png)

开源图标项目 Suru 已被纳入到 Ubuntu 18.04 LTS 操作系统当中，这些图标最初出现在现已废弃的 Ubuntu Touch 移动操作系统当中。（现在 UBPorts.com 的控制下）

正如 Suru 官网所述，原始的移动应用程序图标已被重新用于与 GNOME 主题图标相对应。基于未发布的 Suru 概念，还添加了文件夹和文件类型图标。 此外，还创建了一个完整的符号图标集，其中有许多基于原始 Suru 系统的图标。

**彩色Emojis**

![](https://www.hi-linux.com/img/linux/ubuntu-1804-7.png)

表情符号在个人 Linux 功能愿望清单中需求度可能不会很高，但不能否认表情符号现在是现代数字通信的一个重要组成部分。包括 Fedora 在内的许多其他流行 Linux 发行版很久以前就获得了对 emoji 的支持，在 Ubuntu 18.04 LTS 正式发布时，Ubuntu 用户也终于可以享受桌面应用程序中对彩色表情符号的开箱即用支持了。

为确保平台之间的一致性， Ubuntu 18.04 LTS 将使用 Noto Color Emoji 字体，该字体支持最新 Unicode 版本中定义的所有表情符号。

最新版本 Android 操作系统中使用了相同的表情符号字体，并且可以在 Noto Emoji GitHub 存储库中找到它的所有源图像。

在 Ubuntu 18.04 LTS 中的 GTK 应用程序中添加表情符号将很简单，因为 Ubuntu 用户将能够唤出可搜索的表情符号选择器，所以无需记住其 Unicode 代码或名称即可轻松输入字形。

**新的「待办事项」应用程序**

「GNOME To Do」这一简单的应用程序已经成为上游 GNOME 核心体验的一部分，它将在 Ubuntu 18.04 LTS 中推出对应的「待办事项」应用程序，以帮助Ubuntu 用户管理个人任务。

「GNOME To Do」的设计目的不是妨碍用户使用，它提供最基本的功能来实现，包括：快速编辑、管理列表，以及使用拖放重新排序任务。 每个任务可以分配不同的优先级和颜色以简化组织，并且「GNOME To Do」还能与 GNOME Online Accounts 集成，允许同步多个在线服务。

**Xorg 显示服务器回归**

![](https://www.hi-linux.com/img/linux/ubuntu-1804-8.png)

在过去几年中，Ubuntu 经历了一段艰难的时期，随着其移动版本的退出以及 Unity 的支持结束。 最大的障碍之一是在 Ubuntu 17.10 中默认切换到了 Wayland 显示服务器。 虽然它继续被指定为未来的显示服务器，但因缺少对 Wayland 应用程序的支持，导致不少用户切换回 Xorg 显示服务器。

因此，Ubuntu 18.04 LTS 将 Xorg 恢复为了默认显示服务器。 但是，通过登录屏幕上的齿轮图标还是可以切换回 Wayland 滴。

**其它一些更新**

- Ubuntu 18.04 目前默认采用的 JRE/JDK 是 OpenJDK 10 。等到 Oracle 在 9 月发布 OpenJDK 11 后，18.04 还将同步更新。
- Ubuntu 18.04 LTS 将 gcc 设为默认的编译应用程序，以更有效地使用地址空间布局随机化（ASLR）。除了少数例外情况外，所有主要软件包都已重新构建，以利用此功能。
- Python 2 不再默认安装。它仍然包含在内，但 Ubuntu 18.04 将是包含 Python 2 的最后一个 LTS 。Python 3 已更新至 3.6 。
- 日历现在支持天气预报。
- 预先安装 spice-vdagent ，以便为 Spice 客户端提供更好的性能。
- gconf 不再默认安装，因为已被 gsettings 取代。
- 其它一些主要软件更新，包括：Firefox 59.0.2、Thunderbird 52、Nautilus 3.26、Totem 3.28、Rhythmbox 3.4.2、Remmina 1.2.0、Shotwell 0.28、LibreOffice 6.1 等。

### 服务器版本更新内容

前面我们总结了 Ubuntu Desktop 版本的更新内容，同样的 Ubuntu Server 版本也有不少更新。我们就来看下服务器版本有哪些变化：

- 采用下一代 subiquity Ubuntu Server Installer
- 弃用 ifupdown
- LXD 3.0
- QEMU 2.11.1
- libvirt 4.0
- DPDK 17.11.x
- Open vSwitch 2.9
- chrony 取代 ntpd 作为推荐的 NTP 协议服务器
- cloud-init 18.2
- curtin 18.1
- MAAS 2.4b2
- SSSD 1.16.x
- Nginx 1.14.0
- PHP 7.2.x
- Apache 2.4.29

更完整更新内容请查阅官方发行说明：https://wiki.ubuntu.com/BionicBeaver/ReleaseNotes

### 参考文档

http://www.google.com
http://t.cn/Rn1UBDO
http://t.cn/RuxueO1
http://t.cn/RuiLBt6