---
category: nginx
title: 使用Nginx自带Realip模块获取用户真实IP地址
date: 2017-03-10 09:00:00
tags: [linux, nginx]
abbrlink:
updated:
toc_number: false
---

如果你的Web服务器前端有代理服务器或CDN时日志中的`$remote_addr`可能就不是客户端的真实IP了。比较常用的解决方法有以下三几种，本文将主要介绍如何使用Nginx自带realip模块来解决这一问题。

- 使用CDN自定义IP头来获取
- 通过HTTP_X_FORWARDED_FOR获取IP地址
- 使用Nginx自带模块realip获取用户IP地址

<!-- more -->

**使用Nginx自带模块realip获取用户IP地址**

`ngx_realip`模块究竟有什么实际用途呢？为什么我们需要去改写请求的来源地址呢？答案是：当Nginx处理的请求经过了某个HTTP代理服务器的转发时，这个模块就变得特别有用。

当原始的用户请求经过转发之后，Nginx接收到的请求的来源地址无一例外地变成了该代理服务器的IP地址，于是Nginx以及Nginx背后的应用就无法知道原始请求的真实来源。

所以，一般我们会在Nginx之前的代理服务器中把请求的原始来源地址编码进某个特殊的HTTP请求头中，然后再在Nginx中把这个请求头中编码的地址恢复出来。这样Nginx中的后续处理阶段(包括Nginx背后的各种后端应用)就会认为这些请求直接来自那些原始的地址，代理服务器就仿佛不存在一样。ngx_realip模块正是用来处理这个需求的。

**安装realip模块**

realip是Nginx内置模块，需要在编译Nginx时加上`--with-http_realip_module`参数来启用它。

常用的编译参数：

```
$ ./configure  --prefix=/etc/nginx --sbin-path=/usr/sbin/nginx --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock --http-client-body-temp-path=/var/cache/nginx/client_temp --http-proxy-temp-path=/var/cache/nginx/proxy_temp --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp --http-scgi-temp-path=/var/cache/nginx/scgi_temp --user=nginx --group=nginx --with-http_ssl_module --with-http_realip_module --with-http_addition_module --with-http_sub_module --with-http_dav_module --with-http_flv_module --with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_random_index_module --with-http_secure_link_module --with-http_stub_status_module --with-http_auth_request_module --with-threads --with-stream --with-stream_ssl_module --with-mail --with-mail_ssl_module --with-file-aio --with-ipv6 --with-http_spdy_module --with-cc-opt='-O2 -g'
$ make
$ make install
```

**配置示例**

- 配置语法

```
set_real_ip_from 192.168.1.0/24; #真实服务器上一级代理的IP地址或者IP段,可以写多行。
set_real_ip_from 192.168.2.1;
real_ip_header X-Forwarded-For;  #从哪个header头检索出要的IP地址。
real_ip_recursive on; #递归的去除所配置中的可信IP。
```

- 配置实例

```
    server {

        listen       80;
        server_name  www.hi-linux.com;
        access_log  /var/log/nginx/www.hi-linux.com.access.log  main;

        index index.php index.html index.html;
        root /var/www/www.hi-linux.com;

        location /
        {
                root /var/www/www.hi-linux.com;
                set_real_ip_from  192.168.2.0/24;
                set_real_ip_from  128.22.189.11;
                real_ip_header    X-Forwarded-For;
                real_ip_recursive on;

        }
    }
```

这里详细讲下`real_ip_recursive`的用途：递归的去除所配置中的可信IP，排除set_real_ip_from里面出现的IP。如果出现了未出现这些IP段的IP，那么这个IP将被认为是用户的IP。

以上配置为例，服务器获取到以下的IP地址：

```
128.22.189.11
192.168.2.100
222.11.158.67
```

在`real_ip_recursive on`的情况下，`128.22.189.11`、`192.168.2.100`都出现在set_real_ip_from中,仅仅`222.11.158.67`没出现,那么这个IP就被认为是用户的IP地址，并且赋值到`remote_addr`变量。

在`real_ip_recursive off`或者不设置的情况下,`192.168.2.100`出现在了`set_real_ip_from`中会被排除掉，其它的IP地址便认为是用户的ip地址。


**参考文档**

http://www.google.com
http://www.ttlsa.com/nginx/nginx-get-user-real-ip/
http://nginx.org/en/docs/http/ngx_http_realip_module.html
