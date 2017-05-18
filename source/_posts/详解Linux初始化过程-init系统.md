---
title: 详解Linux初始化过程-init系统
tags:
  - 技巧
  - Linux
categories: Linux
abbrlink: 45475
date: 2016-06-02 09:00:00
updated:
toc_number:
---

使用官方推荐的Omnibus package方式部署gitlab-ce后，发现默认所有对应服务都是开机启动的,由于想关闭gitlab-ce开机启动。把常用的`/etc/init.d`、`/etc/rc.local`都找了个遍都没发现相关启动脚本。

最后搜索整个etc目录发现了`/etc/init/gitlab-runsvdir.conf`这个文件，看看它的内容：

```
$ cat  /etc/init/gitlab-runsvdir.conf

start on runlevel [2345]
stop on shutdown
respawn
post-stop script
   # To avoid stomping on runsv's owned by a different runsvdir
   # process, kill any runsv process that has been orphaned, and is
   # now owned by init (process 1).
   pkill -HUP -P 1 runsv$
end script
exec /opt/gitlab/embedded/bin/runsvdir-start
```
这下水落石出了，gitlab-ce开机启动是从这里进行的。

注：CentOS6开始转用Upstart代替以往的init.d/rcX.d的线性启动方式。(gitlab-ce使用了Upstart方式管理开机启动)

<!-- more -->

解决这个问题的过程中，发现了以下两篇好文分享给大家！

Linux初始化过程(init系统): http://monklof.com/post/14/
理解Upstart: http://www.mike.org.cn/articles/understand-upstart/

以下是主要部分内容的节选

**Linux初始化过程(init系统)**

这篇文章的目的是希望能从一个全局和细节的角度去介绍Linux系统的初始化启动过程。

主要从三个方面尝试介绍和总结一下这方面的知识：

1. 系统初始化过程简介
1. init系统启动具体过程
1. 工具介绍

**init系统简介**

操作系统启动过程中，linux内核加载完成之后，内核初始化的最后一步就是运行 init 程序。init程序负责在系统启动时运行一些服务程序或脚本，来让一些重要和必要的服务开机就能运行起来。系统基本服务程序如network, crond, iptables等和用户安装服务程序如mysqld, nginx等，都是通过init系统来完成开机启动过程。

linux世界中init系统有许多种类，不同的发行版采用了不同的实现。大多数Linux发行版的init系统是和System V相兼容的，被称为"System V init(sysvinit)"，这是人们最熟悉的init系统。早期Ubuntu也是使用的sysvinit，但是Ubuntu从6.10开始，开始用 Upstart 替换sysvinit，成为Ubuntu新一代init系统。现在也有一些linux发行版如Fedora、Debian也开始或者计划采用 systemd 来作为init系统。

(System V 是Unix众多版本中的一个分支，于1983年首次发布)

在2014年Debian项目决定在未来的版本中使用systemd后，马克·沙特尔沃思(Mark Richard Shuttleworth)宣布Ubuntu将开始计划将自身迁移到systemd，以保持与上游一致。但是到目前为止(ubuntu 14.10)，ubuntu的默认的init系统还是Upstart，Upstart也兼容sysvinit，所以本文主要介绍"System V init"和Upstart这两种init系统。

(Mark Richard，南非，是Canonical公司的老板，Ubuntu这个分支也是他创立的，这个人还自费两千万美元乘坐宇宙飞船在太空中翱翔了10天。)

**System V init**

Ubuntu下，init系统程序位于/sbin/init ，大多数Linux发行版的init程序都位于目录/sbin/或者/bin/之下。

先介绍sysvinit中的一个概念： 运行级别(Run Level) 。它是一个数字，代表系统现在处于什么样的运行模式中，sysvinit根据运行级别来判断需要启动哪些服务。常有的运行级别有：

![](https://www.hi-linux.com/img/linux/runlevel.jpg)

另外，介绍两个重要的文件/目录：

- /etc/inittab中存放了系统启动时的默认运行级别，假设为N。
- /etc/rcN.d/目录之下的程序就是对应N运行级别下的程序，系统进入运行级别N时，会按序依次运行该目录下相应程序完成初始化过程。

(注：这些文件在Ubuntu中应该是只有6.10之前的版本有，6.10之后init系统换成了Upstart)

sysvinit在启动时，就会读取/etc/inittab文件，获得默认的运行级别(假设为N)，然后依次启动/etc/rcN.d/中的相应程序，完成开机的初始化过程。

由于很多程序是需要放在多个运行级别下运行的，所以为了避免冗余，/etc/rcN.d/目录之下放的其实是真正启动程序的软连接，真正的启动程序一般存放于/etc/init.d/之下。例如：

```
$ ls -lh /etc/rc3.d/
total 0
lrwxrwxrwx  1 root root 16 Apr 19  2013 K02puppet -> ../init.d/puppet
lrwxrwxrwx  1 root root 14 Mar 25  2014 K10cups -> ../init.d/cups
lrwxrwxrwx. 1 root root 19 Apr 19  2013 K10saslauthd -> ../init.d/saslauthd
lrwxrwxrwx  1 root root 18 Mar 25  2014 K15svnserve -> ../init.d/svnserve
lrwxrwxrwx  1 root root 16 Dec 12 10:25 K36mysqld -> ../init.d/mysqld
lrwxrwxrwx. 1 root root 20 Apr 19  2013 K50netconsole -> ../init.d/netconsole
lrwxrwxrwx. 1 root root 21 Apr 19  2013 K87restorecond -> ../init.d/restorecond
lrwxrwxrwx  1 root root 15 Mar 25  2014 K89rdisc -> ../init.d/rdisc
lrwxrwxrwx  1 root root 19 Mar 25  2014 K92ip6tables -> ../init.d/ip6tables
lrwxrwxrwx  1 root root 18 Mar 25  2014 K92iptables -> ../init.d/iptables
lrwxrwxrwx  1 root root 17 Jun 16  2014 S01sysstat -> ../init.d/sysstat
lrwxrwxrwx  1 root root 17 Mar 25  2014 S10network -> ../init.d/network
lrwxrwxrwx. 1 root root 16 Apr 19  2013 S11auditd -> ../init.d/auditd
lrwxrwxrwx. 1 root root 21 Apr 19  2013 S11portreserve -> ../init.d/portreserve
lrwxrwxrwx  1 root root 17 Mar 25  2014 S12rsyslog -> ../init.d/rsyslog
lrwxrwxrwx  1 root root 14 Dec 12 10:25 S13sssd -> ../init.d/sssd
```

你可能觉得这些程序(软连接)的命名方式有点奇怪，是的，它很奇怪，但是sysvinit就是用程序的文件名来存储程序的一些简单控制信息。程序文件名的格式为： S/K + NN + NAME。系统进入默认运行级别时，init会杀掉所有以K开头的程序，启动以S开头的程序，按照NN的大小，从低到高开始启动/停止程序。NAME则是程序的名字，也是启动之后进程的名字。Sysvinit通过这种命名，来达到控制启动顺序的目的。

我的机器默认的运行级别是3(Multi-User mode)，所以开机启动的时候会启动或停止 /etc/rc3.d/目录下面的程序。根据前面的规则，进入该运行级别时，这些进程如果在运行的话，会被依次关闭：puppet -> cups/saslauthd -> svnserve等。这些程序会被依次启动：sysstat -> network -> auditd等。

值得特别注意的是其中的/etc/rc.local程序，这是一个可执行shell脚本，不仅仅在运行级别3(Multi-User mode)下有，在级别2(Multi-User mode without networking)和级别5(GUI mode)都会有。所以只要机器正常开机，这个脚本就会自动运行。一般情况下该脚本内容为空，如果你需要将一些程序加入开机自启的话，就将程序命令增加到这个脚本中就可以了。

以上就是sysvinit的初始化过程。

其实上面是一个抽象和简化版的初始过程，更加本质的初始过程是这样的(可跳过)：

1. /etc/inittab文件真正的作用是：描述哪些程序在系统正常启动的时候需要运行。
1. /sbin/init其实只做一件事情：读取/etc/inittab，按配置启动其中的程序。启动/etc/rcN.d/中的程序，并不是/sbin/init做的事情，而是在/etc/inittab中的配置的程序/etc/rc.d/rc(有些系统位于"/etc/rc")来完成这个过程。
1. 典型的/etc/inittab的配置是这样的：

```
      # Level to run in
      id:2:initdefault:

      # Boot-time system configuration/initialization script.
      si::sysinit:/etc/rc.sysinit

      # What to do in single-user mode.
      ~:S:wait:/sbin/sulogin

      # /etc/init.d executes the S and K scripts upon change
      # of runlevel.
      #
      # Runlevel 0 is halt.
      # Runlevel 1 is single-user.
      # Runlevels 2-5 are multi-user.
      # Runlevel 6 is reboot.

      l0:0:wait:/etc/rc 0
      l1:1:wait:/etc/rc 1
      l2:2:wait:/etc/rc 2
      l3:3:wait:/etc/rc 3
      l4:4:wait:/etc/rc 4
      l5:5:wait:/etc/rc 5
      l6:6:wait:/etc/rc 6

      # What to do at the "3 finger salute".
      ca::ctrlaltdel:/sbin/shutdown -t3 -r now

      # Runlevel 2,3: getty on virtual consoles
      # Runlevel   3: mgetty on terminal (ttyS0) and modem (ttyS1)
      1:23:respawn:/sbin/mingetty tty1
      2:23:respawn:/sbin/mingetty tty2
      3:23:respawn:/sbin/mingetty tty3
      4:23:respawn:/sbin/mingetty tty4
      S0:3:respawn:/sbin/agetty ttyS0 9600 vt100-nav
      S1:3:respawn:/sbin/mgetty -x0 -D ttyS1
```

其中这几行的作用就是：在系统进入N运行级别时，执行命令 "/etc/rc.d/rc N"：

```

      l0:0:wait:/etc/rc 0
      l1:1:wait:/etc/rc 1
      l2:2:wait:/etc/rc 2
      l3:3:wait:/etc/rc 3
      l4:4:wait:/etc/rc 4
      l5:5:wait:/etc/rc 5
      l6:6:wait:/etc/rc 6
```

rc 这个程序按照文件命名，按序启动或停止 /etc/rcN.d/ 目录下相应的程序。所以，真正操作/etc/rcN.d/目录下程序的启动和停止的其实是rc，并不是init程序。但是我们任然可以把这个过程归结于"system v init"系统的功能。

关于inittab的详细介绍可以看[这里](http://unixhelp.ed.ac.uk/CGI/man-cgi?inittab+5)

**开机自启服务程序编写**

将一个编好的服务程序(作为守护进程存在，提供服务，比如nginx/sshd)，作为固定服务加入系统中的话，在sysvinit中这样做就好了：

1. 将服务脚本置于/etc/init.d/中。
1. 在相关运行级别创建启动软连接，例如，开机自启的话，在/etc/rc2.d/、/etc/rc3.d/、/etc/rc5.d/中创建启动服务脚本的软连接(命名S开头)。
1. (optional)如果有需要的话，在相关运行级别创建停止服务软连接。

举例来说，假设是你编写了一个nginx的服务，现在要将其添加进系统启动服务中：

1.将服务程序置于/etc/init.d/nginx

2.在/etc/rc2.d/、/etc/rc3.d/、/etc/rc5.d/中创建启动软连接：

``` 
 # ln -s /etc/init.d/nginx /etc/rc2.d/S20nginx
 # ln -s /etc/init.d/nginx /etc/rc3.d/S20nginx
 # ln -s /etc/init.d/nginx /etc/rc5.d/S20nginx
```

3.在/etc/rc0.d/，/etc/rc1.d/，/etc/rc6.d/中，创建停止服务软连接：

```
 # ln -s /etc/init.d/nginx /etc/rc0.d/K20nginx
 # ln -s /etc/init.d/nginx /etc/rc1.d/K20nginx
 # ln -s /etc/init.d/nginx /etc/rc6.d/K20nginx
```

这样，当系统启动的时候，就会启动nginx，而关机、重启的时候，会stop nginx。

**小结**

sysvinit初始化启动过程比较明朗：开机时按序启动/etc/rcN.d/中的以"S"开头的程序。/etc/rcN.d/中的程序大多真正存放于/etc/init.d/目录之下。

**Upstart**

可以看到在sysvinit中，服务是按照顺序来执行的，这很影响效率。另一方面，sysvinit中，服务是预设的，不能实时启动(比如在系统被挂载了一个磁盘的时候自动启动)。而Upstart可以解决这些问题。它是基于事件机制的，可以按需启动服务，性能和很多其他方面都比sysvinit强，所以upstart被后来的Ubuntu等linux发行版采用。

在Upstart中，程序执行单位被称作作业(Job)，所有的init作业都必须放置于目录/etc/init/之下，使用Upstart自己的配置文件来描述Job内容。Upstart启动时，从 /etc/init/ 目录中读取各个Job的配置文件，获取所有Job。然后发出Startup信号，所有监听这个信号的作业会被执行。在作业执行过程中，作业本身也可以自己发出信号，其他监听这个信号的服务接着就会被启动执行。Upstart通过这样的方式来达到异步和实时控制作业的启动执行。

比如在我的博客服务器中(精简)：

```
$ ls -lh /etc/init/
total 356K
(...)
-rw-r--r-- 1 root root  297 Feb  9  2013 cron.conf
-rw-r--r-- 1 root root  489 Nov 11  2013 dbus.conf
-rw-r--r-- 1 root root  273 Nov 19  2010 dmesg.conf
-rw-r--r-- 1 root root 1.4K Apr 11  2014 failsafe.conf
-rw-r--r-- 1 root root  267 Apr 11  2014 flush-early-job-log.conf
-rw-r--r-- 1 root root 1.3K Mar 14  2012 friendly-recovery.conf
-rw-r--r-- 1 root root  284 Jul 23  2013 hostname.conf
-rw-r--r-- 1 root root  557 Apr 16  2014 hwclock.conf
(...)
-rw-r--r-- 1 root root 1.8K Feb 19  2014 mysql.conf
-rw-r--r-- 1 root root 2.5K Mar 20  2014 networking.conf
-rw-r--r-- 1 root root  534 Feb 16  2014 passwd.conf
(...)
-rw-r--r-- 1 root root  661 Apr 11  2014 rc.conf
(...)
-rw-r--r-- 1 root root 1.6K Apr 11  2014 rc-sysinit.conf
```

这些"*.conf"都是作业配置文件，在这个文件中指出作业什么start，什么时候stop，主进程是什么等。

```
xxxx:/etc/init$ ls | xargs grep "startup"
friendly-recovery.conf:emits startup
friendly-recovery.conf:    initctl emit startup
hostname.conf:# This task is run on startup to set the system hostname from /etc/hostname,
hostname.conf:start on startup
kmod.conf:start on (startup
mountall.conf:start on startup
plymouth-ready.conf:start on startup or started plymouth-splash
plymouth-upstart-bridge.conf:start on (startup
udev-fallback-graphics.conf:# We only want this job to happen once per boot, hence 'startup and ...'.
udev-fallback-graphics.conf:start on (startup and 
udev-finish.conf:start on (startup
udevmonitor.conf:start on (startup
udevtrigger.conf:start on (startup
```

作业hostname、kmod、mountall等都会监听startup信号(start on EVENT这个指令表示在EVENT发生时启动该程序)。Startup收集作业配置信息完成后，会发出"startup"信号，这些作业就会被执行了。

你可能想，那其他程序怎么办？

其他程序会监听这些程序发射的事件信号，当该事件发生时，那些程序也会被执行。比如mountall这个job就会发射"filesystem"这些类似的基础事件信号，这个代表着文件系统已经就绪了，很多其他作业(比如networking)都是监听这个信号，这样一级一级传递，启动程序就会被按照事件发生顺序一级一级的启动执行了。

**兼容sysvinit**

最开始我们说到Upstart是兼容sysvinit的，怎么做到的？

在/etc/init/下有两个重要的作业： 作业`rc-sysinit`和`作业 rc`

我们看一下这两个文件内容：

**作业rc-sysinit配置:**

```
XXXX:/etc/init$ cat rc-sysinit.conf 
# rc-sysinit - System V initialisation compatibility
#
# This task runs the old System V-style system initialisation scripts,
# and enters the default runlevel when finished.

description    "System V initialisation compatibility"
author        "Scott James Remnant <scott@netsplit.com>"

start on (filesystem and static-network-up) or failsafe-boot
stop on runlevel

# Default runlevel, this may be overriden on the kernel command-line
# or by faking an old /etc/inittab entry
env DEFAULT_RUNLEVEL=2

emits runlevel

# There can be no previous runlevel here, but there might be old
# information in /var/run/utmp that we pick up, and we don't want
# that.
#
# These override that
env RUNLEVEL=
env PREVLEVEL=

console output
env INIT_VERBOSE

task

script
    # Check for default runlevel in /etc/inittab
    if [ -r /etc/inittab ]
    then
    eval "$(sed -nre 's/^[^#][^:]*:([0-6sS]):initdefault:.*/DEFAULT_RUNLEVEL="\1";/p' /etc/inittab || true)"
    fi

    # Check kernel command-line for typical arguments
    for ARG in $(cat /proc/cmdline)
    do
    case "${ARG}" in
    -b|emergency)
        # Emergency shell
        [ -n "${FROM_SINGLE_USER_MODE}" ] || sulogin
        ;;
    [0123456sS])
        # Override runlevel
        DEFAULT_RUNLEVEL="${ARG}"
        ;;
    -s|single)
        # Single user mode
        [ -n "${FROM_SINGLE_USER_MODE}" ] || DEFAULT_RUNLEVEL=S
        ;;
    esac
    done

    # Run the system initialisation scripts
    [ -n "${FROM_SINGLE_USER_MODE}" ] || /etc/init.d/rcS

    # Switch into the default runlevel
    telinit "${DEFAULT_RUNLEVEL}"
end script
```

**作业rc的配置：**

```
XXXX:/etc/init$ cat rc.conf 
# rc - System V runlevel compatibility
#
# This task runs the old System V-style rc script when changing between
# runlevels.

description    "System V runlevel compatibility"
author        "Scott James Remnant <scott@netsplit.com>"

emits deconfiguring-networking
emits unmounted-remote-filesystems

start on runlevel [0123456]
stop on runlevel [!$RUNLEVEL]

export RUNLEVEL
export PREVLEVEL

console output
env INIT_VERBOSE

task

script
if [ "$RUNLEVEL" = "0" -o "$RUNLEVEL" = "1" -o "$RUNLEVEL" = "6" ]; then
    status plymouth-shutdown 2>/dev/null >/dev/null && start wait-for-state WAITER=rc WAIT_FOR=plymouth-shutdown || :
fi
/etc/init.d/rc $RUNLEVEL
end script
```

你不必看懂每个具体配置细节，只要知道这三个配置指令就可以了：

1. start on EVENT： 在EVENT发生的时候启动该作业
1. stop on EVENT： 在EVENT发生的时候停止改作业
1. script ... end script： 作业运行主程序脚本内容

所以根据以上配置，Upstart兼容sysvinit的过程是这样的：

1. 作业rc-sysinit在收到 "(filesystem and static-network-up) or failsafe-boot" 的信号之后由Upstart启动。一切正常的话，rc-sysinit通过telinit完成运行级别信号的发送。
1. 作业rc在收到运行级别信号之后，由Upstart启动。然后rc通过运行/etc/init.d/rc $RUNLEVEL这个命令， 来完成/etc/rcN.d/下相应程序的启动。

这样，就完成了兼容sysvinit的过程。

所以，在Upstart之下，你可以有2种方式添加系统服务程序：

- 按照System V 规则编写服务，并置于相应位置。
- 编写Upstart作业配置文件，置于 /etc/init/ 目录之下。

**常用工具说明**
这里介绍一下我们常用的service命令到底怎么回事。

语法：

```
   service SCRIPT COMMAND [OPTIONS]
```

这个命令的作用是： 运行一个sysvinit 程序或Upstart作业！，所以其是一个既支持Upstart作业，又支持sysvinit程序的命令。运行时，service首先从/etc/init.d/中去找SCRIPT，如果没找着再去/etc/init/目录下去找同名作业配置文件。然后运行这些程序/作业。

需要注意的是，service命令和/etc/rcN.d/这个目录没有任何关系。

例子：

```
service nginx start # 启动nginx服务
service nginx stop  # 停止nginx服务
service nginx restart # 重启nginx服务
```

在运行时，COMMAND 和 OPTTIONS都会被完整的传递给SCRIPT。故service nginx start其实最终执行的命令是/etc/init.d/nginx start，"start"这个操作，并不是由service来完成，service仅仅是起到一个寻找脚本位置的作用而已！

**总结**

三个目录 =>

- /etc/rcN.d/ 是System V init系统启动时查找的服务程序目录。
- /etc/init.d/ 目录是System V init系统真正的服务程序所在地。
- /etc/init/ 是Upstart系统寻找作业配置文件的地方。

两个文件 =>

- /etc/inittab 是System V init系统的配置文件，其中有设置默认的运行级别。
- /etc/rc.local 是一个用户常用来添加系统启动脚本的地方。

一个命令 =>

- service 是用来操作System V init脚本或Upstart作业的命令接口。

