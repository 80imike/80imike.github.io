---
title: 查看Linux系统信息的Web面板psdash
tags:
  - Linux
  - 技巧
  - 工具
categories: Linux
abbrlink: 14968
date: 2016-03-15 09:51:54
---

psdash是一款查看Linux系统信息的web面板，psDash的系统信息的采集也是由psutil完成的。psdash没有提供API，只带了一个基于Flask的web界面，默认每3秒刷新一次数据和界面。

### 安装

- 通过pip安装

```bash
pip install psdash
```
- 通过源码安装

#### 安装依赖环境

```bash
Ubuntu
apt-get install git gcc python-dev python-setuptools

Centos
yum  install python-devel python-setuptools 
```
<!-- more -->
#### 下载psdash源代码后安装:

```bash
cd /var/www/
git clone https://github.com/Jahaja/psdash.git
cd /var/www/psdash
python setup.py install
```

#### 启动psdash：
```bash
psdash --log /var/log/psdash.log --log /var/log/mydb.log
```
> 注：
> 1.log参数后跟的是需监控的日志文件路径，可同时监控多个。
> 2.默认绑定到5000端口。

#### 其它

> Available command-line arguments:
> 
> usage: psdash [-h] [-l path] [-b host] [-p port] [-d]
> 
> psdash 0.2.0 - system information web dashboard
> 
> optional arguments:
>   -h, --help            show this help message and exit
>   -l path, --log path   log files to make available for psdash. This option
>                         can be used multiple times.
>   -b host, --bind host  host to bind to. Defaults to 0.0.0.0 (all interfaces).
>   -p port, --port port  port to listen on. Defaults to 5000.
>   -d, --debug           enables debug mode.

#### 访问

打开浏览器访问 http://ip:5000/

![](https://raw.githubusercontent.com/Jahaja/psdash/master/docs/screenshots/overview.png)


