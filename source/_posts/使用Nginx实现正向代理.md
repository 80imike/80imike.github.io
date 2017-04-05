---
category: Nginx
title: 使用Nginx实现正向代理
date: 2017-04-03 09:00:00
tags: [Nginx, 技术]
abbrlink:
updated:
toc_number: false
---

**一、正向代理的概念**


- 正向代理是一个位于客户端和原始服务器(origin　server)之间的服务器，为了从原始服务器取得内容，客户端向代理发送一个请求并指定目标(原始服务器)，然后代理向原始服务器转交请求并将获得的内容返回给客户端。

- 客户端必须要进行一些特别的设置才能使用正向代理。

下面以Nginx为例介绍如何搭建正向代理服务器。

<!-- more -->

**二、Nginx正向代理配置**

```
server {

    resolver 8.8.8.8;
    resolver_timeout 5s;
    listen 81;
    location / {

		allow 192.168.0.0/24;
		deny all;
        proxy_pass $scheme://$host$request_uri;
        proxy_set_header Host $http_host;
		proxy_set_header  X-Real-IP $host;
        proxy_set_header  X-Forwarded-For $host;
		proxy_buffering on;
        proxy_buffer_size 32k;
		proxy_busy_buffers_size 256k;
        proxy_buffers 256 4k;
        proxy_max_temp_file_size 0;
        proxy_connect_timeout 30;
        proxy_cache_valid 200 302 10m;
        proxy_cache_valid 301 1h;
        proxy_cache_valid any 1m;
    }
	
	access_log off;
	#access_log /var/log/nginx/proxy_access.log

}
```

**三、Nginx正向代理配置说明**

- 配置DNS解析IP地址。

比如Google DNS，以及超时时间(5秒)。

```
resolver 8.8.8.8;
resolver_timeout 5s;
```

注意项：

1. 不能有hostname。
2. 必须有resolver, 即dns，即上面的x.x.x.x，换成你们的DNS服务器ip即可。


- 配置正向代理参数

代理参数均是由Nginx变量组成，其中proxy_set_header部分的配置是为了解决如果URL中带"."(点)后Nginx 503错误。

```
proxy_pass $scheme://$host$request_uri;  #$http_host和$request_uri是Nginx系统变量。
proxy_set_header Host $http_host;
```

- 配置缓存大小，关闭磁盘缓存读写减少I/O，以及代理连接超时时间。

```
proxy_buffers 256 4k; #设置用于读取应答（来自被代理服务器）的缓冲区数目和大小，默认情况也为分页大小，根据操作系统的不同可能是4k或者8k。
proxy_max_temp_file_size 0; #当代理缓冲区过大时使用一个临时文件的最大值，如果文件大于这个值，将同步传递请求而不写入磁盘进行缓存。如果这个值设置为零，则禁止使用临时文件。
proxy_connect_timeout 30;
proxy_busy_buffers_size 256k; #高负荷下缓冲大小（proxy_buffers*2）
```

- 配置代理服务器 Http 状态缓存时间。

```
proxy_cache_valid 200 302 10m;
proxy_cache_valid 301 1h;
proxy_cache_valid any 1m;
```
　　
**四、其它**

因为Nginx不支持CONNECT，所以无法正向代理Https网站(如：网上银行，Gmail)。


**五、参考文档**

http://www.google.com
http://crazyming.blog.51cto.com/1048571/564176

