---
title: 用httping测试WEB页面响应时间
tags:
  - httping
  - Linux
categories: httping
abbrlink: 56953
date: 2016-05-17 09:00:00
updated:
toc_number:
---

httping是一个用来测试 HTTP 请求的连接、发送请求、等待回应的时间。httping与ping类似，不过它不是发送ICMP请求，而是发送HTTP请求。利用httping，我们可以测量出Web服务器跟网络的延迟。

httping项目地址: https://www.vanheusden.com/httping/

![](http://www.hi-linux.com/img/linux/httping.jpg)

<!-- more -->

### httping安装

```
$ apt-get install httping # Debian/Ubuntu
$ yum install httping     # Fedora/CentOS/RHEL(EPEL源)
$ yaourt -S httping       # Arch Linux
$ emerge -av httping      # Funtoo/Gentoo
$ brew install httping    # MAC
```

### httping语法

```
$ httping --help
HTTPing v2.4, (C) 2003-2013 folkert@vanheusden.com
 * SSL support included (-l)
 * ncurses interface with FFT included (-K)
 * TFO (TCP fast open) support included (-F)

 *** where to connect to ***
-g x / --url             URL to ping (e.g. -g http://localhost/)
-h x / --hostname        hostname to ping (e.g. localhost) - use either -g or -h
-p x / --port            portnumber (e.g. 80) - use with -h
-6   / --ipv6            use IPv6 when resolving/connecting
-l   / --use-ssl         connect using SSL. pinging an https URL automatically enables this setting

 *** proxy settings ***
-x x / --proxy           x should be "host:port" which are the network settings of the http/https proxy server. ipv6 ip-address should be "[ip:address]:port"
-E                       fetch proxy settings from environment variables
--proxy-user x           username for authentication against proxy
--proxy-password x       password for authentication against proxy
--proxy-password-file x  read password for proxy authentication from file x
-5                       proxy is a socks5 server
--proxy-buster x         adds "&x=[random value]" to the request URL

 *** timing settings ***
-c x / --count           how many times to ping
-i x / --interval        delay between each ping
-t x / --timeout         timeout (default: 30s)
--ai / --adaptive-interval execute pings at multiples of interval relative to start, automatically enabled in ncurses output mode
-f   / --flood           flood connect (no delays)

 *** HTTP settings ***
-Z   / --no-cache        ask any proxies on the way not to cache the requests
--divert-connect         connect to a different host than in the URL given
--keep-cookies           return the cookies given by the HTTP server in the following request(s)
--no-host-header         do not add "Host:"-line to the request headers
-Q   / --persistent-connections use a persistent connection. adds a 'C' to the output if httping had to reconnect
-I x / --user-agent      use 'x' for the UserAgent header
-R x / --referer         use 'x' for the Referer header
--header                 adds an extra request-header

 *** networking settings ***
--max-mtu                limit the MTU size
--no-tcp-nodelay         do not disable Naggle
--recv-buffer            receive buffer size
--tx-buffer              transmit buffer size
-r   / --resolve-once    resolve hostname only once (useful when pinging roundrobin DNS: also takes the first DNS lookup out of the loop so that the first measurement is also correct)
-W                       do not abort the program if resolving failed: keep retrying
-y x / --bind-to         bind to an ip-address (and thus interface) with an optional port
-F   / --tcp-fast-open   "TCP fast open" (TFO), reduces the latency of TCP connects
--priority               set priority of packets
--tos                    set TOS (type of service)

 *** HTTP authentication ***
-A   / --basic-auth      activate ("basic") authentication
-U x / --username        username for authentication
-P x / --password        password for authentication
-T x                     read the password fom the file 'x' (replacement for -P)

 *** output settings ***
-s   / --show-statuscodes show statuscodes
-S   / --split-time      split measured time in its individual components (resolve, connect, send, etc.
--threshold-red          from what ping value to show the value in red (must be bigger than yellow), only in color mode (-Y)
--threshold-yellow       from what ping value to show the value in yellow
--threshold-show         from what ping value to show the results
--timestamp / --ts       put a timestamp before the measured values, use -v to include the date and -vv to show in microseconds
--aggregate x[,y[,z]]    show an aggregate each x[/y[/z[/etc]]] seconds
-z   / --show-fingerprint show fingerprint (SSL)
-v                       verbose mode

 *** "GET" (instead of HTTP "HEAD") settings ***
-G   / --get-request     do a GET request instead of HEAD (read the contents of the page as well)
-b   / --show-transfer-speed show transfer speed in KB/s (use with -G)
-B   / --show-xfer-speed-compressed like -b but use compression if available
-L x / --data-limit      limit the amount of data transferred (for -b) to 'x' (in bytes)
-X   / --show-kb         show the number of KB transferred (for -b)

 *** output mode settings ***
-q   / --quiet           quiet, only returncode
-m   / --parseable-output give machine parseable output (see also -o and -e)
-M                       json output, cannot be combined with -m
-o rc,rc,... / --ok-result-codes what http results codes indicate 'ok' comma seperated WITHOUT spaces inbetween default is 200, use with -e
-e x / --result-string   string to display when http result code doesn't match
-n warn,crit / --nagios-mode-1 / --nagios-mode-2 Nagios-mode: return 1 when avg. response time >= warn, 2 if >= crit, otherwhise return 0
-N x                     Nagios mode 2: return 0 when all fine, 'x' when anything failes
-C cookie=value / --cookie add a cookie to the request
-Y   / --colors          add colors
-a   / --audible-ping    audible ping

 *** GUI/ncurses mode settings ***
-K   / --ncurses / --gui ncurses/GUI mode
--draw-phase             draw phase (fourier transform) in gui
--slow-log               when the duration is x or more, show ping line in the slow log window (the middle window)
--graph-limit x          do not scale to values above x
-D   / --no-graph        do not show graphs (in ncurses/GUI mode)

-V   / --version         show the version

Example:
	httping Mike-Master-01 -Y -s -Z

Welcome to the new HTTPing version 2.4!

Did you know that with -K you can start a fullscreen GUI version with nice graphs and lots more information? And that you can disable the moving graphs with -D?
```

简单介绍一下几个常用的选项

> -g 要测量的网址
> -l 使用SSL连接
> -c 这个和ping 一样，为请求数量
> -Y 启用颜色输出
> -x host:port(如果是测squid，用-x，不要用-h；和curl的不一样，curl -H指定的是发送的hostname，这个-h是指定给DNS解析的hostname)
> -S 将时间分开成连接和传输两部分显示
> -G GET(默认是HEAD)
> -b 在使用了GET的前提下显示传输速度KB/s
> -B 同-b，不过使用了压缩
> -n a,b 提供给nagios监控用的，当平均响应时间>=a时，返回1；>=b，返回2；默认为0
> -N c 提供给nagios监控用的，一切正常返回0，否则只要有失败的就返回c
> -K 使用图形模式

### httping使用

- 测试http网站

```
$ httping -g http://hi-linux.com  -c 5 -Y
PING hi-linux.com:80 (/):
connected to 23.91.98.188:80 (225 bytes), seq=0 time=391.34 ms 
connected to 23.91.98.188:80 (225 bytes), seq=1 time=456.97 ms 
connected to 23.91.98.188:80 (225 bytes), seq=2 time=472.89 ms 
connected to 23.91.98.188:80 (225 bytes), seq=3 time=289.64 ms 
connected to 23.91.98.188:80 (225 bytes), seq=4 time=180.28 ms 
--- http://hi-linux.com/ ping statistics ---
5 connects, 5 ok, 0.00% failed, time 6799ms
round-trip min/avg/max = 180.3/358.2/472.9 ms
```

- 测试https网站

```
$ httping -g https://hi-linux.com  -c 5 -Y -l                                       
PING hi-linux.com:443 (/):
connected to 23.91.98.188:443 (232 bytes), seq=0 time=3409.36 ms 
connected to 23.91.98.188:443 (232 bytes), seq=1 time=3193.33 ms 
connected to 23.91.98.188:443 (232 bytes), seq=2 time=8279.54 ms 
connected to 23.91.98.188:443 (232 bytes), seq=3 time=1774.22 ms 
connected to 23.91.98.188:443 (232 bytes), seq=4 time=1441.57 ms 
--- https://hi-linux.com/ ping statistics ---
5 connects, 5 ok, 0.00% failed, time 23113ms
round-trip min/avg/max = 1441.6/3619.6/8279.5 ms
```

- 测试使用代理的网站

```
$ httping -x 10.1.2.210:1080 http://www.hi-linux.com/ -SGbs -c 5 
PING www.hi-linux.com:80 (/):
connected to www.hi-linux.com:80 (558 bytes), seq=0 time=   n/a+  0.61+  0.89+1914.14+  0.08=1915.63 ms 200 OK 90KB/s
connected to www.hi-linux.com:80 (558 bytes), seq=1 time=   n/a+  1.21+  2.51+1574.01+  0.09=1577.73 ms 200 OK 80KB/s
connected to www.hi-linux.com:80 (557 bytes), seq=2 time=   n/a+  1.21+  2.44+1396.79+  0.09=1400.44 ms 200 OK 90KB/s
connected to www.hi-linux.com:80 (557 bytes), seq=3 time=   n/a+  1.07+  2.57+4491.80+  0.13=4495.44 ms 200 OK 71KB/s
connected to www.hi-linux.com:80 (558 bytes), seq=4 time=   n/a+  1.08+  0.91+4535.66+  0.13=4537.65 ms 200 OK 22KB/s
--- http://www.hi-linux.com/ ping statistics ---
5 connects, 5 ok, 0.00% failed, time 18944ms
round-trip min/avg/max = 1400.4/2785.4/4537.6 ms
Transfer speed: min/avg/max = 22.674567/71.059180/90.632973 KB
```

httping还支持IPv6、代理、超时、请求头等其他特性，详情可以通过`man httping`查询。值得一提的是httping也有Android版本，有需要有朋友可通过[Google Play](https://play.google.com/store/apps/details?id=com.vanheusden.HTTPing)获取。

### 参考文档

http://www.google.com
https://www.vanheusden.com/httping/
http://blog.sina.com.cn/s/blog_04268f4b0100monk.html
https://linuxtoy.org/archives/httping.html