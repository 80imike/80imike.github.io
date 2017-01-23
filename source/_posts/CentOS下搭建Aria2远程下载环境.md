---
title: CentOS下搭建Aria2远程下载环境
tags:
  - Aria2
  - Linux
categories: Aria2
abbrlink: 49089
date: 2016-05-09 09:00:02
updated:
toc_number:
---

### 关于Aria2

Aria2是一个基于命令行的开源下载工具，支持多协议、多来源(HTTP/HTTPS、FTP、BitTorrent、Metalink协议等)、多线程的下载。它比axel优秀的地方在于完全支持BitTorrent协议，同时可以作为BitTorrent客户端来下载种子文件,支持Metalink协议,远程控制(通过web端)下载进程。

主要优势如下

> 高速，自动多线程下载；
> 断点续传；
> 轻量占用内存非常少，通常情况平均4~9MB内存占用(官方介绍)；
> 多平台。支援 Win/Linux/OSX/Android 等操作系统下的部署；
> 模块化。分段下载引擎，文件整合速度快；
> 支持RPC界面远程；
> 全面支持BitTorrent协议；
<!-- more -->

Aria2官方项目页面：https://aria2.github.io/

### 安装Aria2

#### 包安装

CentOS

默认Repo里没有Aria2,我们需要添加第三方的yum源。

安装rpmforge源

```
$ wget http://pkgs.repoforge.org/rpmforge-release/rpmforge-release-0.5.3-1.el6.rf.x86_64.rpm
$ rpm -ivh rpmforge-release-0.5.3-1.el6.rf.x86_64.rpm
```

安装Aria2

```
$ yum -y install aria2
```

注:rpmforge源中的版本是1.16.4，版本相对是比较低！


Ubuntu

```
$ sudo apt-get install aria2
```


MAC OS

```
$ brew install aria2
```

#### 编译安装Aria2

依赖环境

Aria2 1.17.1以上版本要求`gcc >= 4.8.3 or clang >= 3.4`

安装clang

```
$ yum install clang   #epel源
```

安装GCC

通过SCL安装GCC

CentOS 6

https://copr.fedoraproject.org/coprs/rhscl/devtoolset-3/

```
$ wget https://copr.fedoraproject.org/coprs/rhscl/devtoolset-3/repo/epel-6/rhscl-devtoolset-3-epel-6.repo   -O /etc/yum.repos.d/rhscl-devtoolset-3-epel-6.repo
$ yum install devtoolset-3-gcc devtoolset-3-gcc-c++ devtoolset-3-binutils devtoolset-3-gcc-gfortran 
$ scl enable devtoolset-3 bash   #启用SCL环境中新版本GCC 
$ gcc --version
```

编译Aria2

```
$ wget https://github.com/aria2/aria2/releases/download/release-1.22.0/aria2-1.22.0.tar.gz
$ tar xzvf aria2-1.22.0.tar.gz
$ cd aria2-1.22.0
$ ./configure
$ make
$ make install
$ man aria2c //查看aria2c manual
```

验证Aria2版本

```
$ aria2c --version                                  
aria2 版本 1.22.0
Copyright (C) 2006, 2015 Tatsuhiro Tsujikawa

本程序为自由软件；您可自由再版或修改它，惟须遵守 GNU 通用公共许可证，
第 2 版或更新版本（依您所愿）的条款，以自由软件基金会发布的版本为准。

我们本着希望有用的态度发行此软件，但 *从未做出任何保证*，甚至不暗示对
于适销性或对某一特定用途的适用性的保证。参见 GNU 通用公共许可证以获取
更多信息。

** 配置 **
已开启的特性: BitTorrent, Firefox3 Cookie, GZip, HTTPS, Message Digest, Metalink, XML-RPC
哈希算法: sha-1, sha-224, sha-256, sha-384, sha-512, md5, adler32
库: zlib/1.2.3 libxml2/2.7.6 sqlite3/3.6.20 OpenSSL/1.0.1e
编译器: gcc 4.9.2 20150212 (Red Hat 4.9.2-6)
  built by   x86_64-pc-linux-gnu
  on         May  6 2016 14:31:52
系统: Linux 2.6.32-573.12.1.el6.x86_64 #1 SMP Tue Dec 15 21:19:08 UTC 2015 x86_64
```

### 配置Aria2

创建配置文件

```
$ mkdir /etc/aria2/
$ vim /etc/aria2/aria2.conf

#用户名
#rpc-user=user
#密码
#rpc-passwd=passwd
#上面的认证方式不建议使用,建议使用下面的token方式
#设置加密的密钥
#rpc-secret=token
#允许rpc
enable-rpc=true
#允许所有来源, web界面跨域权限需要
rpc-allow-origin-all=true
#允许外部访问，false的话只监听本地端口
rpc-listen-all=true
#RPC端口, 仅当默认端口被占用时修改
rpc-listen-port=6800
#最大同时下载数(任务数), 路由建议值: 3
max-concurrent-downloads=5
#断点续传
continue=true
#同服务器连接数
max-connection-per-server=5
#最小文件分片大小, 下载线程数上限取决于能分出多少片, 对于小文件重要
min-split-size=10M
#单文件最大线程数, 路由建议值: 5
split=10
#下载速度限制
max-overall-download-limit=0
#单文件速度限制
max-download-limit=0
#上传速度限制
max-overall-upload-limit=0
#单文件速度限制
max-upload-limit=0
#断开速度过慢的连接
#lowest-speed-limit=0
#验证用，需要1.16.1之后的release版本
#referer=*
#文件保存路径, 默认为当前启动位置
dir=/root/downloads
#文件缓存, 使用内置的文件缓存, 如果你不相信Linux内核文件缓存和磁盘内置缓存时使用, 需要1.16及以上版本
#disk-cache=0
#另一种Linux文件缓存方式, 使用前确保您使用的内核支持此选项, 需要1.15及以上版本(?)
#enable-mmap=true
#文件预分配, 能有效降低文件碎片, 提高磁盘性能. 缺点是预分配时间较长
#所需时间 none < falloc ? trunc << prealloc, falloc和trunc需要文件系统和内核支持
file-allocation=prealloc
```

注意将配置表中保存路径一项`dir=/root/downloads`替换为自己的保存位置。(Windows下类似这样`dir=F:\SoftWare`)

### Aria2的使用

配置完成后，就可以开始使用了。

Aria2有两种模式

#### 命令直接调用

直接在命令行下载`$ aria2c "download.url"`, 下载完成后自动退出,就和wget 的工作方式一样。

##### Aria2命令行使用

使用Aria2下载文件，只需在命令后附加地址即可。如

```
$ aria2c http://www.kernel.org/pub/linux/kernel/v2.6/linux-2.6.22.6.tar.bz2
```

分段下载

利用Aria2的分段下载功能可以加快文件的下载速度，对于下载大文件时特别有用。为了使用aria2的分段下载功能，你需要在命令中指定`-s`选项。如

```
$ aria2c -s 2 http://www.kernel.org/pub/linux/kernel/v2.6/linux-2.6.22.6.tar.bz2
```

这将使用2连接来下载该文件。`-s`后面的参数值介于1~5之间，你可以根据实际情况选择。

断点续传

在命令中使用`-c`选项可以断点续传文件。如

```
$ aria2c -c http://www.kernel.org/pub/linux/kernel/v2.6/linux-2.6.22.6.tar.bz2
```

下载torrent文件

你也可以使用Aria2下载BitTorrent文件。如

```
$ aria2c -o gutsy.torrent http://cdimage.ubuntu.com/daily-live/current/gutsy-desktop-i386.iso.torrent
```

后台下载

```
$ aria2c -D url
$ aria2c --deamon=true url
```

验证文件

```
$ aria2c --checksum=md5=别人提供的md5
```

BT下载

```
$ aria2c /tmp/CentOS-6.3-i386-bin-DVD1to2.torrent
$ aria2c http://mirrors.163.com/centos/6.6/isos/x86_64/CentOS-6.6-x86_64-minimal.torrent
```

列出种子内容

```
$ aria2c -S .torrent
```

下载种子内特定编号的文件

```
$ aria2c --select-file=1,4-7 .torrent
```

此处下载编号为1,4,5,6,7的文件

设置bt端口

```
$ aria2c --listen-port=1234 .torrent
```

设置dht端口

```
$ aria2c --dht-listen-port=1234 .torrent
```

下载需要引用页的文件

```
$ aria2c --referer=referurl url
```

限速下载

```
$ aria2c --max-download-limit=500k url //单个文件
$ aria2c --max-overall-download-limit=500k url //全局
```

下载需要Cookie验证的文件

```
$ aria2c --header='Cookie:cookie名称=cookie内容' url
$ aria2c --load-cookies=cookie文件 url
```

Metalink

```
$ aria2c http://example.org/mylinux.metalink

```
批量下载文本中所有URL

```
$ aria2c -i uris.txt
```

注意：当源地址存在诸如`&`,`*`等shell的特殊字符，请使用单引号或双引号把URI包含起来。

#### RPC Server模式(推荐)

Aria2作为后台常驻程序，监测rpc端口的活动情况，添加并下载文件。完成后继续在后台运行。

涉及到命令输入，力求简化，第二种模式明显更省事。

##### 启动Aria2 RPC模式

**命令行启动**

```
$ aria2c --enable-rpc --rpc-listen-all --rpc-allow-origin-all -c  --dir /root/downloads -D (-D daemon模式,用于后台执行)
```

**配置文件启动(推荐)**

```
$ aria2c --conf-path=<Path>
```
<Path>是指配置文件所在的绝对路径。默认位置是:`$HOME/.aria2/aria2.conf`

依照上述配置一路下来，具体是

```
$ aria2c --conf-path="/etc/aria2.conf" -D  #(-D daemon模式,用于后台执行)
```

这时正确无误的话，Aria2就启动了。

**启动脚本**

为方便管理，创建一个管理脚本。

```
$ vi /etc/init.d/aria2
#!/bin/bash
#
# aria2 - this script starts and stops the aria2 daemon
#
# chkconfig:   - 85 15
# description: Aria2 - Download Manager
# processname: aria2c
# config:      /etc/aria2/aria2.conf
# pidfile:     
 
# Source function library.
. /etc/rc.d/init.d/functions
 
# Source networking configuration.
. /etc/sysconfig/network
 
# Check that networking is up.
[ "$NETWORKING" = "no" ] && exit 0
 
aria2c="/usr/bin/aria2c"
ARIA2C_CONF_FILE="/etc/aria2/aria2.conf"
options=" --conf-path=$ARIA2C_CONF_FILE -D "
 
RETVAL=0
 
start() {
        # code here to start the program
        echo -n "Starting aria2c daemon."
        ${aria2c} ${options}
        RETVAL=$?
        echo
}
 
stop() {
        echo -n "Shutting down aria2c daemon."
        /usr/bin/killall aria2c
        RETVAL=$?
        echo
}
 
status() {
        ID=$(/bin/ps -ef | grep 'aria2c' | grep -v 'grep' | awk '{print $2}')
        if [[ "x$ID" != "x" ]]; then
                echo "Aria2 is running."
        else
                echo "Aria2 is not running."
        fi
}
 
restart() {
        stop
        sleep 3
        start
}
 
case "$1" in
        start)
                start
                ;;
        stop)
                stop
                ;;
        status) 
                status
                ;;
        restart)
                restart
                ;;
        *)
                echo "Usage: service aria2c {start|stop|restart}"
                RETVAL=1                             
esac                                                 
                                                      
exit $RETVAL 
```
 
添加可执行权限

```
$ chmod +x /etc/init.d/aria2
```

启动Aria2

```
$ /etc/init.d/aria2 start
```

### 搭配Aria2 Web UI

Aria2不带GUI界面。了解下载进度会有不便，日常使用需搭配Web UI工具方便查看。

#### webui-aria2

```
$ git clone https://github.com/ziahamza/webui-aria2
$ python -m SimpleHTTPServer 9999 
```

访问这台机器的9999端口就可以了,这里为了方便用python做为WEB服务器，其它任意一种WEB服务器都是可以的。

如果你不想搭建可使用`http://ziahamza.github.io/webui-aria2/`,配置数据是存在本地浏览器的，不需要注册。

注意：需要根据情况设置一下Aria2 RPC的地址，一般为Aria2后台进程运行的ip:port,例如192.168.119.100:6800。

#### YAAW

```
$ git clone https://github.com/binux/yaaw
$ python -m SimpleHTTPServer 9999 #也可以使用Apache
```

访问这台机器的9999端口就可以了,这里为了方便用python做为WEB服务器，其它任意一种WEB服务器都是可以的。

YAAW也有线版本

http://aria2c.com/
http://binux.github.io/yaaw/demo/

注意：需要根据情况设置一下Aria2 RPC的地址，一般为Aria2后台进程运行的ip:port,例如192.168.119.100:6800。


#### Windows下图形版本

Aria2c Remote Control

http://sourceforge.net/projects/aria2cremote/

#### 给jsonrpc加上验证

##### 使用token验证(建议使用)

需要1.18.4以上版本，帐号密码方式将在后续版本中停用！

配置文件

```
# token验证
rpc-secret=secret
```

命令行

使用`--rpc-secret=xxxxxx`选项

启用验证后，使用`http://token:secret@hostname:port/jsonrpc`的地址格式设置secret。

##### 使用密码验证

需要1.15.2以上，1.18.6以下版本
1.18.4新增了`--rpc-secret` ,设置的RPC授权令牌, 取代`--rpc-user`和`--rpc-passwd`选项

配置文件

```
#用户名
rpc-user=username
#密码
rpc-passwd=passwd
```

命令行

使用`--rpc-user=user` `--rpc-passwd=pwd`选项

启用验证后，使用`http://username:passwd@hostname:port/jsonrpc`的地址格式设置密码。 

对于RPC模式来说, 界面和后端是分离的, 只要给后端设置密码即可. 前端认证什么的是毫无意义的。 

### 其它相关

YAAW搭配脚本

迅雷离线(需会员账号)

Chrome Extension: [ThunderLixianAssistant](https://chrome.google.com/webstore/detail/thunderlixianassistant/eehlmkfpnagoieibahhcghphdbjcdmen)
UserScript: [ThunderLixianExporter](https://github.com/binux/ThunderLixianExporter)

旋风离线

UserScript: [XuanFengEx](https://greasyfork.org/scripts/354-xuanfengex)
UserScript: [LixianExporter](https://greasyfork.org/scripts/2398-lixianexporter)

百度网盘

Chrome Extension: [BaiduExporter](https://chrome.google.com/webstore/detail/mjaenbjdjmgolhoafkohbhhbaiedbkno)
Firefox Addons: [BaiduExporter](https://github.com/acgotaku/BaiduExporter)
UserScript: [BaiduPanDownloadHelper](https://greasyfork.org/scripts/294-baidupandownloadhelper)

115网盘

Chrome Extension: [115exporter](https://chrome.google.com/webstore/detail/115exporter/ojafklbojgenkohhdgdjeaepnbjffdjf) 

其他脚本

Chrome Extension

[添加到aria2](https://chrome.google.com/webstore/detail/nimeojfecmndgolmlmjghjmbpdkhhogl)
[Chrome Download Helper](http://git.oschina.net/yky/CDHelper)

### 参考文档

http://www.google.com
http://scateu.me/2015/02/12/aria2c-flashgot-firefox-jsonrpc.html
http://skypegnu1.blog.51cto.com/8991766/1637168
http://aria2c.com/usage.html
http://azeril.me/blog/Aria2.html