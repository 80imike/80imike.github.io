---
title: Systemd入门教程
tags:
  - Systemd
  - Linux
categories: Systemd
abbrlink: 3761
date: 2016-05-27 09:00:00
updated:
toc_number:
---

CentOS 7使用Systemd替换了SysV。Systemd目的是要取代Unix时代以来一直在使用的init系统，兼容SysV和LSB的启动脚本，而且够在进程启动过程中更有效地引导加载服务。

Systemd的特性

> 支持并行化任务
> 同时采用socket式与D-Bus总线式激活服务
> 按需启动守护进程(daemon)
> 利用Linux的cgroups监视进程
> 支持快照和系统恢复
> 维护挂载点和自动挂载点
> 各服务间基于依赖关系进行精密控制

<!-- more -->

### 什么是init系统

在Linux中，init就是initialization(初始化)的缩写。init是一个daemon(后台)进程， 它是Linux系统开机启动(内核加载完毕)后运行的第一个进程，进程号(pid)为1。直到系统关机它才终止运行，也就是说它也是Linux系统关机前运行的最后一个进程。

Linux系统中所有其他进程都是直接或间接由init进程启动的， 因此init进程是其他所有进程的父进程或祖先进程。 因此它可以做许多其他进程不能做的事情，接管其他进程不负责的功能。

正是由于其特殊性， 万一init因为某种原因不能启动，那么Linux系统就再也无法启动其他进程， 系统就会处于`Kernel Panic`状态。

### 什么是Systemd

Systemd是System Management Daemon的简写(在UNIX系统中，后台进程都按照惯例以d结尾，因此当你看到一个进程的名字以d结尾，那它极有可能是一个后台进程)， 它是Linux系统中启动的第一个进程，也就上面所说的init daemon进程。

Systemd的优点是功能强大，使用方便，缺点是体系庞大，非常复杂。事实上，现在还有很多人反对使用Systemd，理由就是它过于复杂，与操作系统的其他部分强耦合，违反`keep simple, keep stupid`的Unix哲学。

**Systemd架构图**

![](http://www.hi-linux.com/img/linux/systemd.png)


### Systemd基本工具

Systemd并不是一个命令，而是一组命令，涉及到系统管理的方方面面。

#### systemd-analyze

systemd-analyze命令用于查看启动耗时。

开机启动过程

Systemd最基本的任务是管理开机启动过程，并提供开机启动的一些信息。

想得到开机启动时间，运行下面命令

```
$ systemd-analyze
```

想得到开机时每一个任务启动的时间，运行下面命令

```
$ systemd-analyze blame
```

想得到更多的启动信息，systemd-analyze 这个命令也可以通过以下命令生成一个描述各个启动任务信息的svg格式图片

```
$ systemd-analyze plot > plot.svg
```

显示瀑布状的启动过程流

```
$ systemd-analyze critical-chain
```

显示指定服务的启动流

```
$ systemd-analyze critical-chain atd.service
```

#### systemctl

检视和控制Systemd的主要命令是systemctl。该命令可用于查看系统状态和管理系统及服务。详见`man 1 systemctl`。

在systemctl参数中添加`-H <用户名>@<主机名>`可以实现对其他机器的远程控制。该过程使用ssh链接。systemadm是Systemd的官方图形前端。

```
# 启动进入救援状态(单用户状态)
$ systemctl rescue

# CPU停止工作
$ systemctl halt

# 重启系统
$ systemctl reboot

# 关闭系统，切断电源
$ systemctl poweroff

# 暂停系统
$ systemctl suspend

# 让系统进入冬眠状态
$ systemctl hibernate

# 让系统进入交互式休眠状态
$ systemctl hybrid-sleep

# 让系统进入进入紧急模式
$ systemctl emergency

# 通过ssh远程控制主机
$ systemctl --host user_name@host_name command
$ systemctl -H user_name@host_name command
```

#### journalctl

Systemd统一管理所有Unit的启动日志。带来的好处就是，可以只用journalctl一个命令，查看所有日志(内核日志和应用日志)。日志的配置文件是`/etc/systemd/journald.conf`。

journalctl功能强大，用法非常多。

```
# 查看所有日志(默认情况下 ，只保存本次启动的日志)
$ journalctl

# 查看内核日志(不显示应用日志)
$ journalctl -k

# 查看系统本次启动的日志
$ journalctl -b
$ journalctl -b -0

# 查看上一次启动的日志(需更改设置)
$ journalctl -b -1
$ journalctl -b caf0524a1d394ce0bdbcff75b94444fe

# 查看指定时间的日志
$ journalctl --since="2012-10-30 18:17:16"
$ journalctl --since "20 min ago"
$ journalctl --since yesterday
$ journalctl --since "2015-01-10" --until "2015-01-11 03:00"
$ journalctl --since 09:00 --until "1 hour ago"
$ journalctl --since=today
$ journalctl --since "2015-06-01 01:00:00"
$ journalctl --since "2015-06-01" --until "2015-06-13 15:00"
$ journalctl --since 09:00 --until "1 hour ago"

# 显示尾部的最新10行日志
$ journalctl -n

# 显示尾部指定行数的日志
$ journalctl -n 20

# 实时滚动显示最新日志
$ journalctl -f

# 查看指定服务的日志
$ journalctl /usr/lib/systemd/systemd

# 查看指定进程的日志
$ journalctl _PID=1

# 查看某个路径的脚本的日志
$ journalctl /usr/bin/bash

# 查看指定用户的日志
$ journalctl _UID=33
$ journalctl _UID=33 --since today

# 查看指定用组的日志
$ journalctl _GID=33

# 查看指定字段的数据
$ journalctl -F _GID

# 查看某个Unit的日志
$ journalctl -u nginx.service
$ journalctl -u nginx.service --since today
$ journalctl -u nginx.service -u postgresql.service --since today

# 实时滚动显示某个 Unit 的最新日志
$ journalctl -u nginx.service -f

# 合并显示多个 Unit 的日志
$ journalctl -u nginx.service -u php-fpm.service --since today

# 查看指定优先级(及其以上级别)的日志，共有8级
# 0: emerg
# 1: alert
# 2: crit
# 3: err
# 4: warning
# 5: notice
# 6: info
# 7: debug

$ journalctl -p err -b

# 日志默认分页输出，--no-pager 改为正常的标准输出
$ journalctl --no-pager

# 以 JSON 格式(单行)输出
$ journalctl -b -u nginx.service -o json

# 以 JSON 格式(多行)输出，可读性更好

format:
      * cat
      * export
      * json
      * json-pretty
      * json-sse
      * short
      * short-iso
      * short-monotonic
      * short-precise
      * verbose

$ journalctl -b -u nginx.service  -o json-pretty

# 显示日志占据的硬盘空间
$ journalctl --disk-usage

# 指定日志文件占据的最大空间
$ journalctl --vacuum-size=1G

# 指定日志文件保存多久
$ journalctl --vacuum-time=1years

# 查看某个应用的日志
$ journalctl /sbin/crond
$ journalctl `which crond`

# 以UTC时间格式显示日志
$ journalctl --utc

# 简洁显示有关启动的日志
$ journalctl --list-boots

# 显示有关内核启动的日志
$ journalctl -k     
```

#### hostnamectl

hostnamectl命令用于查看当前主机的信息。

```
# 显示当前主机的信息
$ hostnamectl

# 设置主机名。
$ hostnamectl set-hostname <hostname>
```

#### localectl

localectl命令用于查看本地化设置。

```
# 查看本地化设置
$ localectl
$ localectl status
$ localectl list-locales
$ localectl list-keymaps

# 设置本地化参数。
$ localectl set-locale LANG=en_GB.utf8
$ localectl set-keymap en_GB
$ localectl set-x11-keymap en_GB
```

#### timedatectl

timedatectl命令用于查看当前时区设置。

```
# 查看当前时区设置
$ timedatectl

# 显示所有可用的时区
$ timedatectl list-timezones                                                                                   

# 显示系统的当前时间和日期
$ timedatectl status

# 设置当前时区
$ timedatectl set-timezone America/New_York
$ timedatectl set-timezone UTC
$ timedatectl set-time YYYY-MM-DD
$ timedatectl set-time HH:MM:SS
$ timedatectl set-time 'YYYY-MM-DD HH:MM:SS'
$ timedatectl set-local-rtc boolean   # yes/no
$ timedatectl set-ntp boolean

# 设置硬件时钟以协调世界时UTC
$ timedatectl | grep local #首先确定你的硬件时钟是否设置为本地时区
$ timedatectl set-local-rtc 1 #将你的硬件时钟设置为本地时区
$ timedatectl set-local-rtc 0 #将你的硬件时钟设置为协调世界时

# 将Linux系统时钟同步到远程NTP服务器
$ timedatectl set-ntp true #自动时间同步到远程NTP服务器
$ timedatectl set-ntp false #禁用NTP时间同步
注意:你必须在系统上安装NTP以实现与NTP服务器的自动时间同步。
```

#### loginctl

loginctl命令用于查看当前登录的用户。

```
# 列出当前session
$ loginctl list-sessions

# 列出当前登录用户
$ loginctl list-users

# 列出显示指定用户的信息
$ loginctl show-user tom
```

#### bootctl

与系统加载相关命令

```
$ bootctl status
$ bootctl update
$ bootctl install
$ bootctl remove
```

#### 其它命令

```
$ busctl
$ machinectl
$ networkctl
$ systemd-cgtop
$ systemd-cgls
```

### Systemd Unit

系统启动过程中，Systemd用Unit来组织那些各种不同的任务， 例如生成网络端口、配置硬件设备、加载存储设备、开启后台服务进程、等等

Systemd要求每一个任务对应一个Unit， 而每一个Unit都需要一个包含必要信息的配置文件，而这些配置文件的语法很简单，这也是Systemd的要实现的目的之一。

Systemd可以管理所有系统资源。不同的资源统称为Unit(单位)。

Unit一共分成12种

> Service unit：系统服务
> Target unit：多个Unit构成的一个组
> Device Unit：硬件设备
> Mount Unit：文件系统的挂载点
> Automount Unit：自动挂载点
> Path Unit：文件或路径
> Scope Unit：不是由Systemd启动的外部进程
> Slice Unit：进程组
> Snapshot Unit：Systemd快照，可以切回某个快照
> Socket Unit：进程间通信的socket
> Swap Unit：swap文件
> Timer Unit：定时器

Systemd通过配置文件的后缀名来判断unit的类型，比如一个service类型的unit的配置文件名通常类似于name.service， 一个mount类型的unit的配置文件名通常类似于name.mount。

```
# 设置开机自启动某服务
$ systemctl enable name.service

# 停止开机自启动某服务
$ systemctl disable name.service

# 屏蔽(让它不能启动)或显示一个或多个服务
$ systemctl mask name.service

# 取消屏蔽(让它不能启动)或显示一个或多个服务
$ systemctl unmask name.service

# 查看Unit配置文件的内容
$ systemctl cat name.service

# 编辑Unit配置文件的内容
$ systemctl edit name.service

# 显示Unit配置文件的内容
$ systemctl show name.service
$ systemctl show name.service -p property

# 查看当前系统的所有Unit
$ systemctl list-units

# 列出所有Unit，包括没有找到配置文件的或者启动失败的
$ systemctl list-units --all

# 列出所有没有运行的Unit
$ systemctl list-units --all --state=inactive
$ systemctl list-units --type service --all --state=inactive

# 列出所有加载失败的Unit
$ systemctl list-units --failed

# 列出所有正在运行的、类型为service的Unit
$ systemctl list-units --type=service

# 列出所有服务
$ systemctl list-unit-files
```

#### Unit的状态

systemctl status命令用于查看系统状态和单个Unit的状态。

```
# 显示系统状态
$ systemctl status

# 显示单个Unit的状态
$ sysystemctl status bluetooth.service

# 显示远程主机的某个 Unit 的状态
$ systemctl -H root@rhel7.example.com status httpd.service
除了status命令，systemctl还提供了三个查询状态的简单方法，主要供脚本内部的判断语句使用。

# 显示某个Unit是否正在运行
$ systemctl is-active application.service

# 显示某个Unit是否处于启动失败状态
$ systemctl is-failed application.service

# 显示某个Unit服务是否建立了启动链接
$ systemctl is-enabled application.service
```

#### Unit管理

对于用户来说，最常用的是下面这些命令，用于启动和停止Unit(主要是 service)。

```
# 立即启动一个服务
$ systemctl start name.service

# 立即停止一个服务
$ systemctl stop name.service

# 重启一个服务
$ systemctl restart name.service

#重新启动一个或多个已经激活的服务
$ systemctl try-restart name.service

# 杀死一个服务的所有子进程
$ systemctl kill name.service

# 重新加载一个服务的配置文件
$ systemctl reload name.service

# 重载所有修改过的配置文件
$ systemctl daemon-reload

# 显示某个Unit的所有底层参数
$ systemctl show httpd.service

# 显示某个Unit的指定属性的值
$ systemctl show -p CPUShares httpd.service

# 设置某个Unit的指定属性
$ systemctl set-property httpd.service CPUShares=500
```

#### Unit依赖关系

Unit之间存在依赖关系：A依赖于B，就意味着Systemd在启动A的时候，同时会去启动B。

列出一个Unit的所有依赖

```
$ systemctl list-dependencies nginx.service
```

上面命令的输出结果之中，有些依赖是Target类型，默认不会展开显示。如果要展开Target，就需要使用`--all`参数。

```
$ systemctl list-dependencies --all nginx.service
```

#### Unit的配置文件

Systemd会自动生成一些`unit`，而这些`unit`并不会存在配置文件，但是它们可以通过systemctl来访问。

每一个Unit都有一个配置文件，告诉Systemd怎么启动这Unit。Systemd默认从目录`/etc/systemd/system/`读取配置文件。但是里面存放的大部分文件都是符号链接，指向目录`/usr/lib/systemd/system/`，真正的配置文件存放在那个目录。

`systemctl enable`命令用于在上面两个目录之间，建立符号链接关系。

```
$ systemctl enable clamd@scan.service
```

等同于

```
$ ln -s '/usr/lib/systemd/system/clamd@scan.service' '/etc/systemd/system/multi-user.target.wants/clamd@scan.service'
```

如果配置文件里面设置了开机启动，`systemctl enable`命令相当于激活开机启动。

与之对应的，`systemctl disable`命令用于在两个目录之间，撤销符号链接关系，相当于撤销开机启动。

```
$ systemctl disable clamd@scan.service
```

配置文件的后缀名，就是该Unit的种类，比如sshd.socket。如果省略，Systemd 默认后缀名为.service，所以sshd会被理解成sshd.service。

注: 如果同一个配置文件名都处于这两个文件夹中， systemd会忽略`/usr/lib/systemd/system/`中的同名配置文件。


##### 配置文件的状态

`systemctl list-unit-files`命令用于列出所有配置文件。

```
# 列出所有配置文件
$ systemctl list-unit-files

# 列出指定类型的配置文件
$ systemctl list-unit-files --type=service
```

这个命令会输出一个列表。

```
$ systemctl list-unit-files

UNIT FILE              STATE
chronyd.service        enabled
clamd@.service         static
clamd@scan.service     disabled
```

这个列表显示每个配置文件的状态，一共有四种。

> enabled：已建立启动链接
> disabled：没建立启动链接
> static：该配置文件没有[Install]部分(无法执行)，只能作为其他配置文件的依赖
> masked：该配置文件被禁止建立启动链接

注意，从配置文件的状态无法看出，该Unit是否正在运行。这必须执行前面提到的`systemctl status`命令。

```
$ systemctl status bluetooth.service
```

一旦修改配置文件，就要让SystemD重新加载配置文件，然后重新启动，否则修改不会生效。

```
$ systemctl daemon-reload
$ systemctl restart httpd.service
```

##### 配置文件的格式

配置文件就是普通的文本文件，可以用文本编辑器打开。

`systemctl cat`命令可以查看配置文件的内容。

```
$ systemctl cat atd.service

[Unit]
Description=ATD daemon

[Service]
Type=forking
ExecStart=/usr/bin/atd

[Install]
WantedBy=multi-user.target
```

从上面的输出可以看到，配置文件分成几个区块。每个区块的第一行，是用方括号表示的区别名，比如[Unit]。注意，配置文件的区块名和字段名，都是大小写敏感的。

每个区块内部是一些等号连接的键值对。

```
[Section]
Directive1=value
Directive2=value

. . .
```

注意:键值对的等号两侧不能有空格。

##### 配置文件的区块

[Unit]区块通常是配置文件的第一个区块，用来定义Unit的元数据，以及配置与其他Unit的关系。它的主要字段如下

> Description：简短描述
> Documentation：文档地址
> Requires：当前 Unit 依赖的其他 Unit，如果它们没有运行，当前 Unit 会启动失败
> Wants：与当前 Unit 配合的其他 Unit，如果它们没有运行，当前 Unit 不会启动失败
> BindsTo：与Requires类似，它指定的 Unit 如果退出，会导致当前 Unit 停止运行
> Before：如果该字段指定的 Unit 也要启动，那么必须在当前 Unit 之后启动
> After：如果该字段指定的 Unit 也要启动，那么必须在当前 Unit 之前启动
> Conflicts：这里指定的 Unit 不能与当前 Unit 同时运行
> Condition...：当前 Unit 运行必须满足的条件，否则不会运行
> Assert...：当前 Unit 运行必须满足的条件，否则会报启动失败

[Install]通常是配置文件的最后一个区块，用来定义如何启动，以及是否开机启动。它的主要字段如下

> WantedBy：它的值是一个或多个 Target，当前 Unit 激活时(enable)符号链接会放入/etc/systemd/system目录下面以 Target 名 + .wants后缀构成的子目录中
> RequiredBy：它的值是一个或多个 Target，当前 Unit 激活时，符号链接会放入/etc/systemd/system目录下面以 Target 名 + .required后缀构成的子目录中
> Alias：当前 Unit 可用于启动的别名
> Also：当前 Unit 激活(enable)时，会被同时激活的其他 Unit

[Service]区块用来 Service 的配置，只有Service类型的Unit才有这个区块。它的主要字段如下

> Type：定义启动时的进程行为。它有以下几种值。
> Type=simple：默认值，执行ExecStart指定的命令，启动主进程
> Type=forking：以 fork 方式从父进程创建子进程，创建后父进程会立即退出
> Type=oneshot：一次性进程，Systemd 会等当前服务退出，再继续往下执行
> Type=dbus：当前服务通过D-Bus启动
> Type=notify：当前服务启动完毕，会通知Systemd，再继续往下执行
> Type=idle：若有其他任务执行完毕，当前服务才会运行
> ExecStart：启动当前服务的命令
> ExecStartPre：启动当前服务之前执行的命令
> ExecStartPost：启动当前服务之后执行的命令
> ExecReload：重启当前服务时执行的命令
> ExecStop：停止当前服务时执行的命令
> ExecStopPost：停止当其服务之后执行的命令
> RestartSec：自动重启当前服务间隔的秒数
> Restart：定义何种情况 Systemd 会自动重启当前服务，可能的值包括always(总是重启)、on-success、on-failure、on-abnormal、on-abort、on-watchdog
> TimeoutSec：定义 Systemd 停止当前服务之前等待的秒数
> Environment：指定环境变量

### Systemd Target

启动计算机的时候，需要启动大量的Unit。如果每一次启动，都要一一写明本次启动需要哪些Unit，显然非常不方便。Systemd的解决方案就是Target。

简单说，Target就是一个Unit组，包含许多相关的Unit 。启动某个Target的时候，Systemd就会启动里面所有的Unit。从这个意义上说，Target这个概念类似于[状态点]，启动某个Target就好比启动到某种状态。

传统的init启动模式里面，有RunLevel的概念，跟Target的作用很类似。不同的是RunLevel是互斥的，不可能多个RunLevel同时启动，但是多个Target可以同时启动。

它与init进程的主要差别如下

- 默认的RunLevel(在/etc/inittab文件设置)现在被默认的 Target 取代，位置是/etc/systemd/system/default.target，通常符号链接到graphical.target(图形界面)或者multi-user.target(多用户命令行)。
- 启动脚本的位置，以前是/etc/init.d目录，符号链接到不同的 RunLevel 目录 (比如/etc/rc3.d、/etc/rc5.d等)，现在则存放在/lib/systemd/system和/etc/systemd/system目录。
- 配置文件的位置，以前init进程的配置文件是/etc/inittab，各种服务的配置文件存放在/etc/sysconfig目录。现在的配置文件主要存放在/lib/systemd目录，在/etc/systemd目录里面的修改可以覆盖原始设置。

Target与传统RunLevel的对应关系如下

```
Traditional runlevel      New target name     Symbolically linked to...

Runlevel 0           |    runlevel0.target -> poweroff.target
Runlevel 1           |    runlevel1.target -> rescue.target
Runlevel 2           |    runlevel2.target -> multi-user.target
Runlevel 3           |    runlevel3.target -> multi-user.target
Runlevel 4           |    runlevel4.target -> multi-user.target
Runlevel 5           |    runlevel5.target -> graphical.target
Runlevel 6           |    runlevel6.target -> reboot.target
```
```
# 查看当前系统的所有Target
$ systemctl list-unit-files --type=target

# 查看一个Target包含的所有Unit
$ systemctl list-dependencies multi-user.target

# 查看启动时的默认Target
$ systemctl get-default

# 设置启动时的默认Target
$ systemctl set-default multi-user.target

# 切换Target时，默认不关闭前一个Target启动的进程，
# systemctl isolate 命令改变这种行为，
# 关闭前一个 Target 里面所有不属于后一个Target 的进程
$ systemctl isolate multi-user.target
```

### 参考文档

http://www.google.com
http://fugangqiang.github.io/blog/post/linux/systemd%E4%BB%8B%E7%BB%8D.html
http://www.ruanyifeng.com/blog/2016/03/systemd-tutorial-commands.html