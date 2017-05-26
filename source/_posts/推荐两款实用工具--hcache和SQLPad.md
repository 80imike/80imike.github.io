---
category: Linux
title: 推荐两款实用工具——hcache和SQLPad
date: 2017-05-26 9:00:00
tags: [Linux,技巧]
abbrlink:
updated:
toc_number: false
---

### hcache

Linux用户可能经常遇到的一个问题是内存大部分都被Buff和Cache占用了，但是有时候我们想知道到底Cache了些什么内容却没有一个直观好用的工具。今天给你介绍一个可以查看Linux当前缓存了哪些文件的小工具hcache。

hcache是基于pcstat的，pcstat可以查看某个文件是否被缓存和根据进程pid来查看都缓存了哪些文件。hcache在其基础上增加了查看整个操作系统Cache和根据使用Cache大小排序的特性。

项目地址：https://github.com/silenceshell/hcache

<!-- more -->

#### 安装

hcache是使用GO开发的，安装非常简单，开箱即用。

```
$ wget http://7xir15.com1.z0.glb.clouddn.com/hcache
$ chmod +x hcache
$ mv hcache /usr/local/bin/
```

#### 使用

查看使用Cache最多的3个进程。

```
$ hcache --top 3
+----------------------+----------------+------------+-----------+---------+
| Name                 | Size (bytes)   | Pages      | Cached    | Percent |
|----------------------+----------------+------------+-----------+---------|
| /usr/bin/kubelet     | 138647424      | 33850      | 11751     | 034.715 |
| /usr/bin/dockerd     | 39473368       | 9638       | 6574      | 068.209 |
| /usr/lib/snapd/snapd | 18977392       | 4634       | 4505      | 097.216 |
+----------------------+----------------+------------+-----------+---------+
```

默认情况下会显示cache文件的全路径，会比较长。可以使用`--bname`选项来仅显示文件名。

```
$ hcache --top 3 --bname

+---------+----------------+------------+-----------+---------+
| Name    | Size (bytes)   | Pages      | Cached    | Percent |
|---------+----------------+------------+-----------+---------|
| kubelet | 138647424      | 33850      | 11751     | 034.715 |
| dockerd | 39473368       | 9638       | 6574      | 068.209 |
| snapd   | 18977392       | 4634       | 4505      | 097.216 |
+---------+----------------+------------+-----------+---------+
```

查看指定进程的Cache使用情况。

```
$ hcache -pid 1397 -bname
+-----------------------+----------------+------------+-----------+---------+
| Name                  | Size (bytes)   | Pages      | Cached    | Percent |
|-----------------------+----------------+------------+-----------+---------|
| libm-2.23.so          | 1088952        | 266        | 185       | 069.549 |
| libstdc++.so.6.0.21   | 1566440        | 383        | 346       | 090.339 |
| libz.so.1.2.8         | 104824         | 26         | 26        | 100.000 |
| libdl-2.23.so         | 14608          | 4          | 4         | 100.000 |
| libwrap.so.0.7.6      | 36632          | 9          | 9         | 100.000 |
| libaio.so.1.0.1       | 5512           | 2          | 2         | 100.000 |
| libnss_compat-2.23.so | 35688          | 9          | 9         | 100.000 |
| libnsl-2.23.so        | 93128          | 23         | 23        | 100.000 |
| libc-2.23.so          | 1864888        | 456        | 456       | 100.000 |
| libcrypt-2.23.so      | 39224          | 10         | 10        | 100.000 |
| librt-2.23.so         | 31712          | 8          | 8         | 100.000 |
| liblz4.so.1.7.1       | 96360          | 24         | 24        | 100.000 |
| libgcc_s.so.1         | 89696          | 22         | 22        | 100.000 |
| libpthread-2.23.so    | 138696         | 34         | 34        | 100.000 |
| libnss_nis-2.23.so    | 47648          | 12         | 12        | 100.000 |
| libnuma.so.1.0.0      | 43936          | 11         | 11        | 100.000 |
| ld-2.23.so            | 162632         | 40         | 40        | 100.000 |
| mysqld                | 24754056       | 6044       | 4051      | 067.025 |
| libnss_files-2.23.so  | 47600          | 12         | 12        | 100.000 |
+-----------------------+----------------+------------+-----------+---------+
```

另外还可使用指定格式输出，比如：JSON、纯文本。更多使用方法可参考`hcache -h`。

### SQLPad

SQLPad是一个基于Nodejs开发的直接在浏览器运行SQL查询并对结果进行可视化展示工具。SQLPad支持的数据库非常多，比如：MySQL, Postgres, SQL Server, Vertica, Crate, Presto等。

项目地址：http://rickbergfalk.github.io/sqlpad/

#### 安装

- 安装Nodejs

默认软件源里nodejs版本比较老，是4.x的。SQLPad最低需要6.x的，使用官方源安装6.x的nodejs。

Debian/Ubuntu

```
$ curl -sL https://deb.nodesource.com/setup_6.x | bash -
$ apt-get -y install nodejs
```

RHEL/CentOS

```
$ curl --silent --location https://rpm.nodesource.com/setup_6.x | bash -
$ yum install nodejs
```

- 安装SQLPad

```
$ npm install sqlpad -g
```

- 启动SQLPad

```
$ sqlpad

Launching server WITHOUT SSL
Welcome to SqlPad!. Visit http://localhost:80 to get started
```

启动后会显示出访问地址，SQLPad默认绑定在`0.0.0.0:80`。如果想更改可以指定`--ip`和`--port`参数。

#### 使用

用浏览器访问`http://ip:80`页面，注册账号后便可使用。

![](http://www.hi-linux.com/img/linux/sqlpad1.png)

建立一个数据库连接

![](http://www.hi-linux.com/img/linux/sqlpad2.png)

SQLPad支持对表名和字段名的自动提示

![](http://www.hi-linux.com/img/linux/sqlpad3.png)

![](http://www.hi-linux.com/img/linux/sqlpad4.png)

直接根据查询结果生成各种图表

![](http://www.hi-linux.com/img/linux/sqlpad5.png)
![](http://www.hi-linux.com/img/linux/sqlpad6.png)
![](http://www.hi-linux.com/img/linux/sqlpad7.png)

SQLPad功能还是很强大的，还可以将查询结查导出CVS和Excel格式等，快和你的小伙伴用起来吧！

### 参考文档

http://www.google.com
https://nodejs.org/en/download/package-manager/
http://www.datastart.cn/tech/2017/05/20/hcache.html
