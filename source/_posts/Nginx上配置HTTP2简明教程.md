---
category: Nginx
title: Nginx上配置HTTP/2简明教程
date: 2017-06-08 9:05:00
tags: [Nginx,Linux]
abbrlink:
updated:
toc_number: false
---

### HTTP/2简介

`HTTP/2`（超文本传输协议第2版，最初命名为 HTTP 2.0），是HTTP协议的的第二个主要版本，使用于万维网。`HTTP/2` 是 HTTP 协议自 1999 年 HTTP 1.1 发布后的首个更新，主要基于 SPDY 协议。它由互联网工程任务组 (IETF) 的 `Hypertext Transfer Protocol Bis` (httpbis) 工作小组进行开发。该组织于2014年12月将 `HTTP/2` 标准提议递交至IESG进行讨论，于2015年2月17日被批准。`HTTP/2` 标准于2015年5月以 `RFC 7540` 正式发表。

**HTTP/2优点**

- 采用二进制格式传输数据，而非文本格式。二进制格式在协议的解析和优化扩展上带来更多的优势和可能。

- 对消息头进行压缩传输，能够节省消息头占用的网络的流量，而 `HTTP 1.1` 每次请求，都会携带大量冗余头信息，浪费了很多带宽资源，头压缩能够很好的解决该问题。

- 多路复用，就是多个请求都是通过一个 TCP 连接并发完成， `HTTP 1.1` 虽然通过 `pipeline` 也能并发请求，但是多个请求之间的响应会被阻塞的，所以 `pipeline` 至今也没有被普及应用，而 `HTTP/2` 做到了真正的并发请求，同时流还支持优先级和流量控制。

- 服务器推送，服务端能够更快的把资源推送给客户端，例如服务端可以主动把 `JS` 和 `CSS` 文件推送给客户端，而不需要客户端解析 HTML 再发送这些请求，当客户端需要的时候，它已经在客户端了。

<!-- more -->

**HTTP/2站点的优势**

- 提升网站访问速度。
- 降低服务器压力。
- 部分替代异步加载的使用。
- 保护网站安全。

**为什么不是HTTP/1.2**

为了实现 HTTP 工作组设定的性能目标，`HTTP/2` 引入了一个新的二进制分帧层，该层无法与之前的 `HTTP/1.x` 服务器和客户端向后兼容，因此协议的主版本提升到 `HTTP/2`。

### 在Nginx上启用HTTP/2

在 Nginx 上 开启 `HTTP/2` 需要 Nginx 1.9.5 以上版本，并且需要 `OpenSSL` 版本在 1.0.2 以上。

因为 `HTTP/2` 不仅需要Web服务器还需要一个扩展支持，目前可以用的有 `ALPN` 和 ` NPN` 两种(Chrome 已经移除了对 `NPN` 的支持)。只有 OpenSSL 1.0.2 以上版本才开始支持 `ALPN` 。

#### 升级OpenSSL

如果你系统的 OpenSSL 版本低于 1.0.2，就必须先升级 OpenSSL 版本。通常 CentOS 系的版本会低一些，需要单独升级。这部分内容就不在本文展开讲了，后面单独写一篇 CentOS 下 OpenSSL 升级的文章。

- 查看OpenSSL版本

我这里的环境是Ubuntu 16.04，系统默认的 OpenSSL 版本是 1.0.2 的。

```
$ openssl version
OpenSSL 1.0.2g  1 Mar 2016
```

#### 安装Nginx

- 下载对应软件包

```
$ cd /root
$ wget http://nginx.org/download/nginx-1.12.0.tar.gz
```

- 编译安装Nginx

```
$ apt-get install libreadline-dev libncurses5-dev libpcre3-dev libssl-dev perl make build-essential
$ tar xzvf nginx-1.12.0.tar.gz
$ cd nginx-1.12.0
$ ./configure --with-http_ssl_module --with-http_v2_module
$ make && make install
```

如果系统 OpenSSL 版本低于 1.0.2，需要通过 `--with-openssl` 参数显示指定高版本 OpenSSL library 源码位置。


- 验证Nginx和编译用到的OpenSSL版本

```
$ ./nginx -V
nginx version: nginx/1.12.0
built by gcc 5.4.0 20160609 (Ubuntu 5.4.0-6ubuntu1~16.04.4)
built with OpenSSL 1.0.2g  1 Mar 2016
TLS SNI support enabled
configure arguments: --with-http_ssl_module --with-http_v2_module
```

#### 修改Nginx配置

配置 Nginx 开启 `HTTP/2` 特别简单，在 `server` 配置段中的 `listen` 后增加 `http2` 即可。

```
$ vim /usr/local/nginx/conf/nginx.conf

server {
  listen 443 ssl http2;
  server_name www.hi-linux.com;
  ...
}
```

重启 Nginx 后，让配置生效。

```
$ cd /usr/local/nginx/sbin
$ ./nginx -s reload
```

注意： `HTTP/2` 得在 HTTPS 下面工作，虽然 `HTTP/2` 本身可以在非 HTTPS 下面工作，但目前还没有浏览器支持！

#### 验证HTTP/2

验证 `HTTP/2` 是否已生效，可通过以下两种方法：

- 打开 `https://tools.keycdn.com/http2-test` 网站，输入域名测试是否正确支持 `HTTP/2` 。

- 在 Chrome 浏览器中输入：: `chrome://net-internals/#http2` 便可以查看 HTTP/2 sessions。

#### 浏览器支持

开启了 `HTTP/2` 以后，低版本浏览器也是可正常访问的！如果客户端不支持 `HTTP/2` Nginx 会自动向下兼容 `HTTP 1.1`。

目前支持 `HTTP/2` 浏览器列表

- Google Chrome、Mozilla Firefox、Microsoft Edge和Opera已支持HTTP/2，并默认启用。

- Internet Explorer自IE 11开始支持HTTP/2，并预设激活。

更详细的浏览器列表可参考：http://caniuse.com/#feat=http2

### 参考文档

http://www.google.com
https://www.phpsong.com/2818.html
https://zh.wikipedia.org/wiki/HTTP/2
https://www.yangrunwei.com/a/41.html
