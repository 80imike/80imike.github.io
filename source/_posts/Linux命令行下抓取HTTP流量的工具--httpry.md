---
title: Linux命令行下抓取HTTP流量的工具--httpry
tags:
  - httpry
  - Linux
categories: httpry
abbrlink: 46493
date: 2016-05-25 09:00:00
updated:
toc_number:
---
httpry是一个专业的封包嗅探器，用C语言开发的用来用于显示和记录HTTP流量。此工具不会进行自身分析，而是用来捕获、分析、并记录流量。

它可以作为一个后台进程记录实时流量并输出到文件，由于具有轻型和灵活的特性，所以它可以很容易适应不同的应用程序。它不显示原始HTTP传输的数据，而是着重解析和显示相关数据字段的请求和响应行。

**应用场景**

> 查看用户在你的网络上在线浏览的内容
> 检查是否正确的服务器配置
> 在HTTP中使用模式的研究
> 关注危险下载的文件
> 验证HTTP策略在网络上的实施
> 提取的HTTP统计输出保存在捕捉文件

项目地址: http://dumpsterventures.com/jason/httpry/

<!-- more -->

### 安装httpry

#### 通过包安装

- CentOS/RHEL

```
$ yum install epel-release #安装EPEL repo
$ yum install httpry
```

- Debian/Ubuntu

```
$ apt-get install httpry httpry-tools httpry-daemon
```

#### 编译安装 

- 安装依赖包

CentOS/RHEL

```
$ yum install wget gcc make libpcap libpcap-devel
```

Debian/Ubuntu

```
$ apt-get install wget gcc make git libpcap0.8-dev
```

- 编译httpry

创建相关数据目录

```
$ mkdir -p /usr/local/man/man1
$ mkdir -p /usr/man/man1/
```

编译httpry

```
$ wget http://dumpsterventures.com/jason/httpry/httpry-0.1.8.tar.gz
$ tar zvxf httpry-0.1.8.tar.gz
$ cd httpry-0.1.8
$ make
$ make install
$ mkdir /usr/local/share/httpry-0.1.8
$ mv doc scripts $_
```

### httpry用法

```
$ httpry -h

httpry version 0.1.8 -- HTTP logging and information retrieval tool
Copyright (c) 2005-2014 Jason Bittel <jason.bittel@gmail.com>
Usage: httpry [ -dFhpqs ] [-b file ] [ -f format ] [ -i device ] [ -l threshold ]
              [ -m methods ] [ -n count ] [ -o file ] [ -P file ] [ -r file ]
              [ -t seconds] [ -u user ] [ 'expression' ]

   -b file      write HTTP packets to a binary dump file
   -d           run as daemon
   -f format    specify output format string
   -F           force output flush
   -h           print this help information
   -i device    listen on this interface
   -l threshold specify a rps threshold for rate statistics
   -m methods   specify request methods to parse
   -n count     set number of HTTP packets to parse
   -o file      write output to a file
   -p           disable promiscuous mode
   -P file      use custom PID filename when running in daemon mode 
   -q           suppress non-critical output
   -r file      read packets from input file
   -s           run in HTTP requests per second mode
   -t seconds   specify the display interval for rate statistics
   -u user      set process owner
   expression   specify a bpf-style capture filter

Additional information can be found at:
   http://dumpsterventures.com/jason/httpry
```

### httpry使用实例

监听指定的网络接口，并且实时显示捕获到的HTTP请求与响应的包

```
$ httpry -i eth0
httpry version 0.1.8 -- HTTP logging and information retrieval tool
Copyright (c) 2005-2014 Jason Bittel <jason.bittel@gmail.com>
Starting capture on eth0 interface
2016-05-25 13:24:25	192.168.119.100	23.91.98.188	>	GET	hi-linux.com	/2016/05/16/Linux%E5%91%BD%E4%BB%A4%E8%A1%8C%E5%AD%A6%E4%B9%A0%E7%A5%9E%E5%99%A8tldr/	HTTP/1.1	-	-
2016-05-25 13:24:25	23.91.98.188	192.168.119.100	<	-	-	-	HTTP/1.1	200	OK
2016-05-25 13:24:58	192.168.119.100	23.91.98.188	>	HEAD	www.hi-linux.com	/	HTTP/1.0	-	-
2016-05-25 13:24:58	23.91.98.188	192.168.119.100	<	-	-	-	HTTP/1.1	200	OK
2016-05-25 13:24:59	192.168.119.100	23.91.98.188	>	HEAD	www.hi-linux.com	/	HTTP/1.0	-	-
2016-05-25 13:24:59	23.91.98.188	192.168.119.100	<	-	-	-	HTTP/1.1	200	OK
2016-05-25 13:25:00	192.168.119.100	23.91.98.188	>	HEAD	www.hi-linux.com	/	HTTP/1.0	-	-
2016-05-25 13:25:00	23.91.98.188	192.168.119.100	<	-	-	-	HTTP/1.1	200	OK
^CCaught SIGINT, shutting down...
92 packets received, 0 packets dropped, 8 http packets parsed
87.6 packets/min, 7.6 http packets/min
```

使用`-b`或`-o`选项保存数据包。`-b`选项将数据包以二进制文件的形式保存下来，这样可以使用httpry软件打开文件以浏览。另一方面，`-o`选项将数据以可读的字符文件形式保存下来。

以二进制形式保存文件

```
$ httpry -i eth0 -b output.dump
```

浏览所保存的HTTP数据包文件

```
$ httpry -r output.dump
```

注意:不需要根用户权限就可以使用`-r`选项读取数据文件。

将httpry数据以字符文件保存

```
$ httpry -i eth0 -o /tmp/output.txt
```

想监视指定的HTTP方法(如：GET，POST，PUT，HEAD，CONNECT等)，使用`-m`选项

```
$ httpry -i eth0 -m get,head

httpry version 0.1.8 -- HTTP logging and information retrieval tool
Copyright (c) 2005-2014 Jason Bittel <jason.bittel@gmail.com>
Starting capture on eth0 interface
2016-05-25 13:30:57	192.168.119.100	23.91.98.188	>	HEAD	www.hi-linux.com	/	HTTP/1.0	-	-
2016-05-25 13:30:57	23.91.98.188	192.168.119.100	<	-	-	-	HTTP/1.1	200	OK
2016-05-25 13:30:58	192.168.119.100	23.91.98.188	>	HEAD	www.hi-linux.com	/	HTTP/1.0	-	-
2016-05-25 13:30:58	23.91.98.188	192.168.119.100	<	-	-	-	HTTP/1.1	200	OK
2016-05-25 13:30:59	192.168.119.100	23.91.98.188	>	HEAD	www.hi-linux.com	/	HTTP/1.0	-	-
2016-05-25 13:30:59	23.91.98.188	192.168.119.100	<	-	-	-	HTTP/1.1	200	OK
2016-05-25 13:31:09	192.168.119.100	23.91.98.188	>	GET	hi-linux.com	/2016/05/16/Linux%E5%91%BD%E4%BB%A4%E8%A1%8C%E5%AD%A6%E4%B9%A0%E7%A5%9E%E5%99%A8tldr/	HTTP/1.1	-	-
2016-05-25 13:31:09	23.91.98.188	192.168.119.100	<	-	-	-	HTTP/1.1	200	OK
^CCaught SIGINT, shutting down...
130 packets received, 0 packets dropped, 16 http packets parsed
185.7 packets/min, 22.9 http packets/min
```

分析httpry记录

如果是编译安装，有一个perl脚本用来帮助我们分析httpry输出。该脚本在`/usr/local/share/httpry-0.1.8/scripts/`目录下。 该脚本功能有

> hostname : 显示一些列唯一主机名
> find_proxies：检测web代理
> search_terms：查找并计算在搜索服务中输入搜索词
> content_analysis：查找包含特定关键字的URI
> xml_output：以xml格式输出
> log_summary：生成日志摘要
> db_dump：将日志转存到mysql数据库中

在使用这些脚本前，先使用`-o`选项运行一段时间。一旦得到输出，可运行脚本分析

- 产生摘要报表

```
$ cd /usr/local/share/httpry-0.1.8/scripts/
$ perl ./parse_log.pl -p plugins/log_summary.pm  /tmp/output.txt
```

parse_log.pl执行完后，会在`/usr/local/share/httpry-0.1.8/scripts/`目录下生成分析结果文件log_summary.txt。看起来像下面这样

```
$ cat log_summary.txt 

LOG SUMMARY

Generated:      Wed May 25 13:57:40 2016
Total lines:    14
Total run time: 0.0 secs


REQUESTS BY HOUR

  0%   0%   0%   0%   0%   0%   0%   0%   0%   0%   0%   0% 
  |----|----|----|----|----|----|----|----|----|----|----|
 00   01   02   03   04   05   06   07   08   09   10   11  

  0% 100%   0%   0%   0%   0%   0%   0%   0%   0%   0%   0% 
  |----|----|----|----|----|----|----|----|----|----|----|
 12   13   14   15   16   17   18   19   20   21   22   23  


15/5 VISITED HOSTS

2	28.6%	hi-linux.com
2	28.6%	www.hi-linux.com
1	14.3%	www.163.com
1	14.3%	www.qq.com
1	14.3%	www.baidu.com


15/1 TOP TALKERS

7	100.0%	192.168.119.100


15/1 RESPONSE CODES

7	100.0%	200
```

- 产生所有报表

```
$ perl ./parse_log.pl -d plugins /tmp/output.txt
$ ls -l *.txt
```

parse_log.pl执行完后，会在`httpry-0.1.8/scripts`目录下生成一些分析结果文件(*.txt/xml)。


### 参考文档

http://www.google.com
http://www.linux78.com/http-liu-liang-ji-lu-gong-ju-httpry.html
http://www.ttlsa.com/web/how-to-sniff-http-traffic-from-the-command-line-on-linux/
https://github.com/jbittel/httpry






