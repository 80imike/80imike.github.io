---
title: Linux下开启缓存服务NSCD
tags:
  - NSCD
  - Linux
categories: Linux
abbrlink: 9461
date: 2016-06-29 09:00:00
updated:
toc_number:
---

NSCD(Name Service Cache Daemon)是服务缓存守护进程，它为NIS和LDAP等服务提供更快的验证。不管是什么系统，缓存是一项非常重要的技术[或机制]，缓存的主旨就是提高客户端访问速度。

### NSCD安装

- RHEL/CentOS

```
$ yum -y install nscd
```

- Debian/Ubuntu

```
$ apt-get install nscd
```

<!-- more -->

### NSCD命令选项

```
$ nscd  --help
用法： nscd [选项...]
Name Service Cache Daemon.

  -d, --debug                Do not fork and display messages on the current
                             tty
  -f, --config-file=名称     从NAME中读取配置数据
  -g, --statistics           Print current configuration statistics
  -i, --invalidate=TABLE     Invalidate the specified cache
  -K, --shutdown             关闭服务器
  -t, --nthreads=NUMBER      启动 NUMBER 个线程
  -?, --help                 给出该系统求助列表
      --usage                给出简要的用法信息
  -V, --version              打印程序版本号

长选项的强制或可选参数对对应的短选项也是强制或可选的。

For bug reporting instructions, please see:
<http://www.gnu.org/software/libc/bugs.html>.
```

### NSCD配置文件

NSCD配置文件为`/etc/nscd.conf`，NSCD程序在启动的时候会读取`/etc/nscd.conf`文件，每一行指定一个属性和对应的值，或者指定一个服务和对应的值，#表示注释。有效的服务设定是：passwd, group, hosts, services, or netgroup五个。

NSCD配置文件相关参数解释

```
#设置日志文件
logfile debug-file-name

#设置debug记录的级别，默认是0
debug-level value

#程序启动时，等待进去请求的处理线程数，至少5个
threads number

#最大线程数，默认32
max-threads number

#nscd程序以哪个用户运行,如果设置了该选项，nscd将作为该用户运行，而不是作为root。如果每个用户都使用一个单独的缓存(-S参数)，将忽略该选项。
server-user user

#哪个用户可以请求统计用户
stat-user user

#在一个缓存项被删除之前允许使用的次数，默认是5
reload-count unlimited | number

#是否启用偏执模式，启用会导致nscd周期性重启，默认是no
paranoia <yes|no>

#如果启用偏执模式，设置的定期重启nscd的时间间隔，默认是3600秒
restart-interval time

#开启或者关闭服务缓存，默认是no
enable-cache service <yes|no>

#为成功请求的元素设置缓存TTL，单位是秒，值越大缓存命中率越高，降低平均响应时间，但会增加缓存的一致性问题
positive-time-to-live service value

#为失败查询元素设置缓存TTL，单位是秒，应保持小值，减小缓存一致性问题
negative-time-to-live service value

#内部的散列表大小，value应该保持一个素数以达到优化效果。默认值是211
suggested-size service value

#启用或者禁用检查文件是否属于指定的服务，这些文件是/etc/passwd、/etc/group、/etc/hosts、/etc/services、/etc/netgroup等
check-files service <yes|no>

#设置缓存在服务器重启后，仍旧能提供缓存服务，在使用偏执模式时有用，默认是no
persistent service <yes|no>

#为客户端共享nscd数据库在内存中做的映射，使客户端可以直接搜索，而不用每次都查询守护进行，默认是no
shared service <yes|no>

#该数据库的最大大小，单位是bytes，默认是33554432
max-db-size service bytes

#此选项仅使用于passwd和group服务
auto-propagate service <yes|no>
```

### NSCD使用实例

#### 使用NSCD对DNS进行缓存

**DNS缓存在服务器上的作用**

在需要通过域名与外界进行数据交互的时候,dns缓存就派上用场了,它可以减少域名解析的时间,提高效率。例如以下情况

- 使用爬虫采集网络上的页面数据,
- 使用auth2.0协议从其他平台(如微博或QQ)获取用户数据,
- 使用第三方支付接口,
- 使用短信通道下发短信等.


**开启NSCD DNS缓存服务的优点和缺点**

- 优点

1. 本地缓存DNS解析信息，提供解析速度。
1. DNS服务挂了也没有问题，在缓存服务时间范围内，解析依旧正常。
	  
- 缺点

1. DNS解析信息会滞后，如域名解析更改需要手动刷新缓存，NSCD不适合做实时的切换的应用，目前对于依赖DNS切换的服务，建议不要开启DNS缓存。DNS Cache作为普通的DNS解析Cache那是没问题的，如果你使用RDS云服务器，也不建议使用DNS缓存服务。

**配置DNS缓存**

通过编辑`/etc/nscd.conf`文件，在其中增加如下一行可以开启本地DNS Cache

```
enable-cache hosts yes #这个服务除了dns缓存之外还可以缓存passwd,group,servers
```

完整配置如下

```
$ cat /etc/nscd.conf

logfile                 /var/log/nscd.log
threads                 5
max-threads             32
server-user             nscd
debug-level             0
paranoia                no
enable-cache            hosts           yes
enable-cache            passwd          no
enable-cache            group           no
positive-time-to-live   hosts           60
negative-time-to-live   hosts           20
suggested-size          hosts           211
check-files             hosts           yes
persistent              hosts           yes
shared                  hosts           yes
max-db-size             hosts           33554432
```

- 启动NSCD进程

默认该服务在Redhat或Centos下是关闭的，可以通过以下指令开启

```
$ service nscd start
```

加入自启动

```
$ chkconfig nscd on
```

查看进程，如下所示

```
$ ps aux | grep nscd
nscd       1284  0.1  0.3 708056  1580 ?        Ssl  23:37   0:00 /usr/sbin/nscd
```

说明已经正常运行了。

- NSCD服务查看和清除

NSCD缓存DB文件在`/var/db/nscd`下。可以通过`nscd -g`查看统计的信息，这里列出部分：

```
$ nscd -g

nscd 配置：

              0  服务器调试级别
             4s  server runtime
              5  current number of threads
             32  maximum number of threads
              0  number of times clients had to wait
             no  paranoia mode enabled
           3600  restart internal
              5  reload count

... 省略输出信息若干 ...

hosts cache:

            yes  cache is enabled
            yes  cache is persistent
            yes  cache is shared
            211  suggested size
         216064  total data pool size
              0  used data pool size
             60  seconds time to live for positive entries
             20  seconds time to live for negative entries
              0  cache hits on positive entries
              0  cache hits on negative entries
              0  cache misses on positive entries
              0  cache misses on negative entries
              0% cache hit rate
              0  current number of cached values
              0  maximum number of cached values
              0  maximum chain length searched
              0  number of delays on rdlock
              0  number of delays on wrlock
              0  memory allocations failed
            yes  check /etc/hosts for changes

... 省略输出信息若干 ...
```

- 清除指定类型缓存

```
$ nscd -i passwd
$ nscd -i group
$ nscd -i hosts
```

除了上面的方法，重启NSCD服务同样可以达到清理Cache的目的。

### 参考文档

http://www.google.com
http://my.oschina.net/guol/blog/700569