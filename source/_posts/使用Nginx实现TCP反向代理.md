---
category: nginx
title: 使用Nginx实现TCP反向代理
date: 2017-03-13 09:00:00
tags: [linux, nginx]
abbrlink:
updated:
toc_number: false
---

Nginx 在1.9.0版本发布以前如果要想做到基于TCP的代理及负载均衡需要通过打名为 `nginx_tcp_proxy_module` 的第三方patch来实现，该模块的代码托管在github上网址：https://github.com/yaoweibin/nginx_tcp_proxy_module/。

Nginx 从1.9.0开始发布`ngx_stream_core_module`模块，该模块支持tcp代理及负载均衡。

今天我们就要来简单测试一下 Nginx 的 `ngx_stream_core_module` 模块。

<!-- more -->

**安装Nginx并启用模块**

`ngx_stream_core_module`这个模块并不会默认启用，需要在编译时通过指定`--with-stream`参数来激活这个模块。

- 编译安装

```
$ yum -y install proc* openssl* pcre*
$ wget http://nginx.org/download/nginx-1.9.4.tar.gz
$ tar zxvf nginx-1.9.4.tar.gz
$ cd nginx-1.9.4
$ ./configure  --prefix=/etc/nginx --sbin-path=/usr/sbin/nginx --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock --http-client-body-temp-path=/var/cache/nginx/client_temp --http-proxy-temp-path=/var/cache/nginx/proxy_temp --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp --http-scgi-temp-path=/var/cache/nginx/scgi_temp --user=nginx --group=nginx --with-http_ssl_module --with-http_realip_module --with-http_addition_module --with-http_sub_module --with-http_dav_module --with-http_flv_module --with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_random_index_module --with-http_secure_link_module --with-http_stub_status_module --with-http_auth_request_module --with-threads --with-stream --with-stream_ssl_module --with-mail --with-mail_ssl_module --with-file-aio --with-ipv6 --with-http_spdy_module --with-cc-opt='-O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector --param=ssp-buffer-size=4 -m64 -mtune=generic'
$ make
$ make install
```

- 配置stream模块

实例一：测试MYSQL负载均衡

stream模块必需在nginx.conf中配置

```
$ mv nginx.conf{,.bak}
$ vim  /etc/nginx/nginx.conf

worker_processes auto;
events {
    worker_connections  1024;
}
error_log /var/log/nginx_error.log info;

stream {
    upstream mysqld {
        hash $remote_addr consistent;
        server 192.168.1.42:3306 weight=5 max_fails=1 fail_timeout=10s;
        server 192.168.1.43:3306 weight=5 max_fails=1 fail_timeout=10s;
    }

    server {
        listen 3306;
        proxy_connect_timeout 1s;
        proxy_timeout 3s;
        proxy_pass mysqld;
    }

}
```

实例二:实现SSH转发

```
upstream ssh {
        hash $remote_addr consistent;
        server 192.168.1.42:22 weight=5;
   }

server {
    listen 2222;
    proxy_pass ssh;    
   }
```


实例三:官方一个较完整的配置示例


stream模块的配置里还支持类似`server unix:/tmp/backend3.sock;`这样的sock数据交换接口,也可以直接`proxy_pass unix:/tmp/stream.socket;`。

```
worker_processes auto;
error_log /var/log/nginx/error.log info;
events {
    worker_connections  1024;
}

stream {
    upstream backend {
        hash $remote_addr consistent;

        server backend1.example.com:12345 weight=5;
        server 127.0.0.1:12345            max_fails=3 fail_timeout=30s;
        server unix:/tmp/backend3;
    }

    server {
        listen 12345;
        proxy_connect_timeout 1s;
        proxy_timeout 3s;
        proxy_pass backend;
    }

    server {
        listen [::1]:12345;
        proxy_pass unix:/tmp/stream.socket;
    }
}
```

ngx_stream_core_module也同样的支持tcp长连接保持。keepidle是保持时间，keepintvl是间隔时间 ，keepcnt是发送的个数。

`so_keepalive=on|off|[keepidle]:[keepintvl]:[keepcnt]`

**参考文档**

http://www.google.com
http://zhangge.net/5037.html
http://nginx.org/en/docs/stream/ngx_stream_core_module.html
