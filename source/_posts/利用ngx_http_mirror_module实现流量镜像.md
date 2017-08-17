---
category: Nginx
title: 利用ngx_http_mirror_module实现流量镜像
date: 2017-08-17 9:00:00
tags: [Nginx,技巧]
abbrlink:
updated:
toc_number: false
---

### 背景

最近 Nginx 官网发布了 Nginx 1.13.4，Nginx 1.13.4 中新增了一个 `ngx_http_mirror_module` 模块。通过 mirror 模块，可实现对原始请求创建后台镜像，镜像子请求的输出会被忽略。

利用这一功能我们就可以将线上实时访问流量拷贝至其他环境，基于这些流量可以做版本发布前的预先验证或者进行流量放大后的压测等等。

<!-- more -->

### mirror 模块配置

在这之前与这一功能类似的软件有：[TCPCopy](https://github.com/session-replay-tools/tcpcopy)等，Nginx 自身支持后使用起来就更加方便了。下面我们来看看具体的如何配置：

#### 编译安装 Nginx

mirror 模块在 Nginx 1.13.4中默认是启用的，如果要禁用这个功能可在编译时加上 `--without-http_mirror_module`参数。

```
$ apt-get install libreadline-dev libncurses5-dev libpcre3-dev libssl-dev perl make build-essential
$ wget http://nginx.org/download/nginx-1.13.4.tar.gz
$ tar xzvf nginx-1.13.4.tar.gz
$ cd nginx-1.13.4/
$ ./configure
$ make && make install
```

mirror 模块配置分为两部分：源地址和镜像地址配置。配置位置可以为 Nginx 配置文件的 `http`, `server`, `location`的上下文中，配置示例为：

```
# original配置
location / {
    mirror /mirror;
    mirror_request_body off;
    proxy_pass http://127.0.0.1:9502;
}

# mirror配置
location /mirror {
    internal;
    proxy_pass http://127.0.0.1:8081$request_uri;
    proxy_set_header X-Original-URI $request_uri;
}
```

在这个示例中我们配置了两组后台服务器，`http://127.0.0.1:9502` 指向生产服务器， `http://127.0.0.1:8081`指向测试服务器。用户访问生产服务器的同时，请求会被 Nginx 复制发送给测试服务器，需要注意的一点是 mirror 不会输出 http 返回内容。

####  original 配置说明

- location /

指定了源 uri 为 /

- mirror /mirror   

指定镜像 uri 为 /mirror

- mirror_request_body off | on  

指定是否镜像请求 Body 部分，此选项与`proxy_request_buffering`、`fastcgi_request_buffering`、`scgi_request_buffering`和 `uwsgi_request_buffering`冲突，一旦开启`mirror_request_body`为 on，则请求自动缓存。

- proxy_pass

指定上游 Server 的地址。

#### mirror 配置说明

- internal

指定此 location 只能被内部的请求调用，外部的调用请求会返回 Not found (404)。

- proxy_pass

指定上游 Server 的地址。

- proxy_set_header

设置镜像流量的头部。

#### 验证

![](https://www.hi-linux.com/img/linux/ngx_mirror1.png)

按照上述配置，搭建了上图所示的验证环境，各个模块均部署在本机，由curl发起请求：

```
$ curl 127.0.0.1
```

original 和 mirror 均为上游 Server PHP 脚本，其中 original 返回响应 response to client。 抓包结果如下图:

![](https://www.hi-linux.com/img/linux/ngx_mirror2.png)

分析抓包结果，整个请求流程为：

- curl 向 Nginx 80 端口发起 GET / HTTP 请求。
- Nginx 将请求转发至 upstream 9502 端口的 original PHP 脚本，Nginx 本地端口为 51637。
- nginx 将请求镜像发至 upstream 8081 端口的 mirror PHP 脚本，Nginx 本地端口为 51638。
- original 发送响应 response to client 至 Nginx。
- nginx 将响应转发至 curl，curl 将响应展示到终端。
- mirror将响应发送至nginx，nginx丢弃。

由此可见，在整个流程中 Nginx 将请求转发送至 original 和 mirror，然后等待响应。几乎不会对正常请求造成影响，整个处理过程是完全异步的。

### mirror 模块实现

```
static ngx_int_t
ngx_http_mirror_handler_internal(ngx_http_request_t *r)
{
    ngx_str_t                   *name;
    ngx_uint_t                   i;
    ngx_http_request_t          *sr;
    ngx_http_mirror_loc_conf_t  *mlcf;

    mlcf = ngx_http_get_module_loc_conf(r, ngx_http_mirror_module);

    name = mlcf->mirror->elts;

    for (i = 0; i < mlcf->mirror->nelts; i++) {
        if (ngx_http_subrequest(r, &name[i], &r->args, &sr, NULL,
                                NGX_HTTP_SUBREQUEST_BACKGROUND)
            != NGX_OK)
        {
            return NGX_HTTP_INTERNAL_SERVER_ERROR;
        }

        sr->header_only = 1;
        sr->method = r->method;
        sr->method_name = r->method_name;
    }

    return NGX_DECLINED;
}
```

Nginx 有关 mirror 的代码位于文件 `src/http/modules/ngx_http_mirror_module.c` 文件，上述为文件中的 `ngx_http_mirror_handler_internal` 函数。在开启了 mirror 之后此函数会被执行，可见其内部主要通过 `ngx_http_subrequest` 发起 http 子请求来实现的。

通过代码可见，Nginx 支持配置多个 mirror uri，示例为:

```
location / {
    mirror /mirror;
    mirror /mirror2;
    mirror_request_body off;
    proxy_pass http://127.0.0.1:9502;
}

location /mirror {
    internal;
    proxy_pass http://127.0.0.1:8081$request_uri;
}

location /mirror2 {
    internal;
    proxy_pass http://127.0.0.1:8081$request_uri;
}
```

### 参考文档

http://www.google.com
http://blog.csdn.net/xhjcehust/article/details/77093074
http://nginx.org/en/docs/http/ngx_http_mirror_module.html
