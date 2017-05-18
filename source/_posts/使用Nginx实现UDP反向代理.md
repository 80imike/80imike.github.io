---
category: nginx
title: 使用Nginx实现UDP反向代理
date: 2017-03-28 09:00:00
tags: [linux, nginx]
abbrlink:
updated:
toc_number: false
---

在「[使用Nginx实现TCP反向代理](https://www.hi-linux.com/posts/65232.html)」一文中讲解了如何实现TCP转发功能。今天讲讲怎样实现UDP的反向代理，Nginx从1.9.13起开始发布`ngx_stream_core_module`模块不仅能支持TCP代理及负载均衡,其实也是支持UDP协议的。

**安装Nginx并启用模块**

`ngx_stream_core_module`这个模块并不会默认启用，需要在编译时通过指定`--with-stream`参数来激活这个模块。

<!-- more -->

- 编译安装

```
$ yum -y install proc* openssl* pcre*
$ wget http://nginx.org/download/nginx-1.10.3.tar.gz
$ tar zxvf nginx-1.10.3.tar.gz
$ cd nginx-1.10.3
$ ./configure  --prefix=/etc/nginx --sbin-path=/usr/sbin/nginx --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock --http-client-body-temp-path=/var/cache/nginx/client_temp --http-proxy-temp-path=/var/cache/nginx/proxy_temp --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp --http-scgi-temp-path=/var/cache/nginx/scgi_temp --user=nginx --group=nginx --with-http_ssl_module --with-http_realip_module --with-http_addition_module --with-http_sub_module --with-http_dav_module --with-http_flv_module --with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_random_index_module --with-http_secure_link_module --with-http_stub_status_module --with-http_auth_request_module --with-threads --with-stream --with-stream_ssl_module --with-mail --with-mail_ssl_module --with-file-aio --with-ipv6 --with-http_spdy_module --with-cc-opt='-O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector --param=ssp-buffer-size=4 -m64 -mtune=generic'
$ make
$ make install
```

- 配置stream模块

UDP负载均衡解决了两个关键点：高可用性和横向扩展。UDP设计是不保证端至端传送数据的，因此需要在客户端软件来处理网络级错误和重传机制。

实例：负载均衡DNS

stream模块必需在nginx.conf中配置

```
$ mv nginx.conf{,.bak}
$ vim  /etc/nginx/nginx.conf

worker_processes auto;
error_log /var/log/nginx_error.log info;

events {
    worker_connections  1024;
}

stream {

upstream dns {
  server 192.168.0.1:53;
  server dns.example.com:53;
}

server {
  listen 127.0.0.1:53 udp;
  proxy_responses 1;
  proxy_timeout 20s;
  proxy_pass dns;
}

}
```

**参考文档**

http://www.google.com
http://nginx.org/en/docs/stream/ngx_stream_core_module.html
