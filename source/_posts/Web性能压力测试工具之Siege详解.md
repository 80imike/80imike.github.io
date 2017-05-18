---
title: Web性能压力测试工具之Siege详解
tags:
  - Linux
  - 技巧
  - siege
  - 工具
categories: siege
abbrlink: 50141
date: 2016-03-15 09:51:54
---

>Siege是一款开源的压力测试工具，设计用于评估WEB应用在压力下的承受能力。可以根据配置对一个WEB站点进行多用户的并发访问，记录每个用户所有请求过程的相应时间，并在一定数量的并发访问下重复进行。siege可以从您选择的预置列表中请求随机的URL。所以siege可用于仿真用户请求负载，而ab则不能。但不要使用siege来执行最高性能基准调校测试，这方面ab就准确很多。

Siege官网：<http://www.joedog.org/>
Siege下载：<http://www.joedog.org/pub/siege/siege-latest.tar.gz>

### 一、安装

- 编译安装

```bash
wget http://www.joedog.org/pub/siege/siege-latest.tar.gz
tar -zxvf siege-latest.tar.gz
cd siege-2.72/
./configure
make
make install
```

- 通过包安装

**Debian/Ubuntu**

```bash
apt-get install siege
```

**CentOS**

```bash
yum install siege
```
<!-- more -->
### 二、参数详解：

- 命令行参数说明：

> -C,或–config 在屏幕上打印显示出当前的配置,配置是包括在他的配置文件$HOME/.siegerc中,可以编辑里面的参数,这样每次siege 都会按照它运行.
> -v 运行时能看到详细的运行信息
> -c n,或–concurrent=n 指定并发的用户个数，-c 200指定并发数200。模拟有n个用户在同时访问,n不要设得太大,因为越大,siege 消耗本地机器的资源越多
> -i,–internet 随机访问urls.txt中的url列表项,以此模拟真实的访问情况(随机性),当urls.txt存在是有效。默认为urls.txt列表从上到下来压。
> -d n,–delay=n hit每个url之间的延迟,在0-n之间
> -r n,–reps=n 重复运行测试n次,不能与-t同时存在
> -t n,–time=n 持续时间。即测试持续时间。默认是分钟。例: -t10S,(10秒) -t5M,(5分钟) -t1H,(1小时)
> -l 运行结束,将统计数据保存到日志文件中siege .log,一般位于/usr/local/var/siege .log中,也可在.siegerc中自定义
> -R SIEGERC,–rc=SIEGERC 指定用特定的siege 配置文件来运行,默认的为$HOME/.siegerc
> -f FILE, –file=FILE 指定用特定的urls文件运行siege ,默认为urls.txt,位于siege 安装目录下的etc/urls.txt
> -u URL,–url=URL 测试指定的一个URL,对它进行”siege “,此选项会忽略有关urls文件的设定
> -b 进行压力测试，不进行延时。
> -A, --user-agent="text" 设置请求的User-Agent

- siegerc设定档说明：

> verbose ：要不要显示过程。
> display-id ：显示过程的时候，要不要显示模拟user的id
> show-logfile ：跑完之后要不要显示log资讯
> logging ：要不要log到档案
> logfile ：要log到档案的话，档名是什么
> protocol ：HTTP通讯协定( HTTP/1.1或HTTP/1.0 两者择一)
> connection ：keep-alive表示模拟成persistent connection(写close则反之)
> concurrent ：模拟有几个user来冲
> time ：跑多久之后停止( H=hours, M=minutes, S=seconds)
> reps ：每一个concurrent冲几次。
> file ：多个目的url情形下的url档案位置。
> url ：单一url情形下的指定url
> delay ：非benchmakr行况下，每个模拟user随机延迟0到这个数字(单位：秒)。
> timeout ：socket connection timeout(单位：秒)。
> failures ：socket失败次数(timeouts, connection failures)到达这个数字就停下来。
> internet ：随机从urls.txt抓出url，否则从urls.txt循序。
> benchmark ：跑benchmark模式的话，siege将不会在每个connection间delay,适合拿来做load testing.
> user-agent ：送出的agent识别
> login ：WWW-Authenticate login( login = jdfulmer:topsecret:Admin )(非form based)
> username,password ：也是login用的(非form based)
> Login URL ：每一个模拟user都必需经过的第一个login url( form based)
> proxy-host,proxy-port,proxy-login ：使用proxy的话要填这个。(proxy-login: jeff:secret:corporate)
> follow-location ：redirection support
> zero-data-ok ：接不接受zero-length data
> chunked ：HTTP/1.1需要chunked encoding

### 三、用法举例

```bash
siege -c 300 -r 100 -f url.txt
```

> 说明：-c是并发量，-r是重复次数。url.txt就是一个文本文件，里面是要测试的url,url.txt每行都是一个url。

urls.txt文件是很多行待测试URL的列表以换行符断开,格式为:

```bash
[protocol://]host.domain.com[:port][path/to/file]
```

**url.txt内容:**

```bash
http://192.168.80.166/01.jpg
http://192.168.80.166/02.jpg
http://192.168.80.166/03.jpg
http://192.168.80.166/04.jpg
http://192.168.80.166/05.jpg
http://192.168.80.166/06.jpg
```
**结果说明：**

```bash
** SIEGE 2.72
** Preparing 10 concurrent users for battle.
The server is now under siege..      done.

Transactions:		         300 hits  #已完成的事务总署
Availability:		      100.00 %   #完成的成功率
Elapsed time:		        0.08 secs   #总共使用的时间
Data transferred:	        0.94 MB   #响应中数据的总大小
Response time:		        0.00 secs   #显示网络连接的速度
Transaction rate:	     3750.00 trans/sec  #平均每秒完成的事务数
Throughput:		       11.79 MB/sec  #平均每秒传送的数据量
Concurrency:		        8.50  #实际最高并发链接数
Successful transactions:         300  #成功处理的次数
Failed transactions:	           0    #失败处理的次数
Longest transaction:	        0.01   #最长事务处理的时间
Shortest transaction:	        0.00   #最短事务处理时间
```

### 四、常用的siege命令举例

- 200个并发对www.google.com发送请求100次

```bash
siege -c 200 -r 100 http://www.google.com
```

- 在urls.txt中列出所有的网址

```bash
siege -c 200 -r 100 -f urls.txt
```

- 随机选取urls.txt中列出所有的网址

```bash
siege -c 200 -r 100 -f urls.txt -i
```

- delay=0，更准确的压力测试，而不是功能测试

```bash 
siege -c 200 -r 100 -f urls.txt -i -b
```

- 指定http请求头 文档类型

```bash
siege -H "Content-Type:application/json" -c 200 -r 100 -f urls.txt -i -b
```

### 五、Siege使用的一些总结

- 发送post请求时，url格式为：http://www.xxxx.com/ POST p1=v1&p2=v2
- 如果url中含有空格和中文，要先进行url编码，否则siege发送的请求url不准确
- siege自身感觉也是有瓶颈的，并发数最大也就1000，再提高就会报下面这样的错误

```bash
[error] socket: unable to connect sock.c:222: Operation already in progress socket: connection timed out
```
这样最终导致测试结果怎么都没法超过2W每秒的请求，所以就把siege -c 1000 -r 100 -i -b -f url.txt 放到shell中并发执行

```bash

#!/bin/bash
user_agent="Siege 1.0"
siege_rc="siege.rc"
concurrent=150
repet=200
siege_single_urls="singleurl.txt"
siege_prefix_urls="prefixurl.txt"

for i in {1..10}
do
siege -c $concurrent -r $repet -i -b -f $siege_single_urls -R $siege_rc -A "$user_agent" &;
done
```
