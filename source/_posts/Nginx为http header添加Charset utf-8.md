---
title: Nginx为设置Charset
tags:
  - Linux
  - Nginx
  - 技巧
categories: Nginx
abbrlink: 50550
date: 2016-03-15 09:51:54
---

LNMPA下的http头信息的Content-Type: text/html没有设置charset=utf-8

```bash
HTTP/1.1 200 OK
Server: nginx/1.0.15
Date: Wed, 23 Oct 2013 08:12:31 GMT
Content-Type: text/html
Connection: keep-alive
Vary: Accept-Encoding
X-Powered-By: InfoMaster/1.1.Alpha1 (Ray)
```

添加方法很简单

修改nginx.conf在http,server,或location下添加<!-- more -->

```bash
vim /etc/nginx/conf/nginx.conf

charset utf-8;
```

使用 curl -IL imike.me 查看如下

```
HTTP/1.1 200 OK
Server: nginx/1.0.15
Date: Wed, 23 Oct 2013 08:19:05 GMT
Content-Type: text/html; charset=utf-8
Connection: keep-alive
Vary: Accept-Encoding
X-Powered-By: InfoMaster/1.1.Alpha1(Ray)
```