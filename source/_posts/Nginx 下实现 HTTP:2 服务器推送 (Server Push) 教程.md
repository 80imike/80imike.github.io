---
category: Linux
title: Nginx 下实现 HTTP/2 服务器推送 (Server Push) 教程
date: 2018-03-12 09:00:00
tags: [Linux, Nginx]
abbrlink:
updated:
toc_number: false
---

Nginx 从 1.13.9 版本开始加入了 HTTP/2 的 Server Push 功能，本文将介绍如何在 Nginx 下实现 HTTP/2 服务器推送 (Server Push) 。这里我们首先用 Docker 搭建一个支持 HTTP/2 的 Server Push 功能的 Nginx 容器并加入 SSL 证书。如果你还不会 Docker，可以先看 「[Docker 入门教程](https://mp.weixin.qq.com/s?__biz=MzI3MTI2NzkxMA==&mid=2247485678&idx=1&sn=6f4f3735b4ad34cc8e5080e9e24846fb&chksm=eac529c7ddb2a0d1a497da48de609b96678cfe417d5a7ddfb66289106b732d0d3fa4ff0e8ec7#rd)」，非常简单。

### 一、HTTP 服务

Nginx 的最大作用，就是搭建一个 Web Server。有了容器，只要一行命令，服务器就架设好了，完全不用配置。

```
$ docker container run \
  -d \
  -p 127.0.0.2:8080:80 \
  --rm \
  --name mynginx \
  nginx
```

上面命令下载并运行官方的 Nginx image，默认是最新版本（latest），当前是 1.13.9。如果本机安装过以前的版本，请删掉重新安装，因为只有 1.13.9 才开始支持 server push。

<!-- more -->

上面命令的各个参数含义如下。

- -d：在后台运行
- -p ：容器的80端口映射到127.0.0.2:8080
- --rm：容器停止运行后，自动删除容器文件
- --name：容器的名字为mynginx

如果没有报错，就可以打开浏览器访问 127.0.0.2:8080 了。正常情况下，显示 Nginx 的欢迎页。

![](https://www.hi-linux.com/img/linux/nginx-http2-serverpush-2.png)

然后，把这个容器终止，由于 `--rm` 参数的作用，容器文件会自动删除。

```
$ docker container stop mynginx
```

### 二、映射网页目录

网页文件都在容器里，没法直接修改，显然很不方便。下一步就是让网页文件所在的目录`/usr/share/nginx/html` 映射到本地。

首先，新建一个目录，并进入该目录。

```
$ mkdir nginx-docker-demo
$ cd nginx-docker-demo
```

然后，新建一个html子目录。

```
$ mkdir html
```

在这个子目录里面，放置一个index.html文件，内容如下。

```
<h1>Hello World</h1>
```

接着，就可以把这个子目录 `html`，映射到容器的网页文件目录 `/usr/share/nginx/html`。

```
$ docker container run \
  -d \
  -p 127.0.0.2:8080:80 \
  --rm \
  --name mynginx \
  --volume "$PWD/html":/usr/share/nginx/html \
  nginx
```

打开浏览器，访问 127.0.0.2:8080，应该就能看到 Hello World 了。

### 三、拷贝配置

修改网页文件还不够，还要修改 Nginx 的配置文件，否则后面没法加 SSL 支持。

首先，把容器里面的 Nginx 配置文件拷贝到本地。

```
$ docker container cp mynginx:/etc/nginx .
```

上面命令的含义是，把 `mynginx` 容器的 `/etc/nginx` 拷贝到当前目录。不要漏掉最后那个点。

执行完成后，当前目录应该多出一个 `nginx` 子目录。然后把这个子目录改名为 `conf`。

```
$ mv nginx conf
```

现在可以把容器终止了。

```
$ docker container stop mynginx
```

### 四、映射配置目录

重新启动一个新的容器，这次不仅映射网页目录，还要映射配置目录。

```
$ docker container run \
  --rm \
  --name mynginx \
  --volume "$PWD/html":/usr/share/nginx/html \
  --volume "$PWD/conf":/etc/nginx \
  -p 127.0.0.2:8080:80 \
  -d \
  nginx
```

上面代码中，`--volume "$PWD/conf":/etc/nginx` 表示把容器的配置目录 `/etc/nginx`，映射到本地的 `conf` 子目录。

浏览器访问 127.0.0.2:8080，如果能够看到网页，就说明本地的配置生效了。这时，可以把这个容器终止。

```
$ docker container stop mynginx
```

### 五、自签名证书

现在要为容器加入 HTTPS 支持，第一件事就是生成私钥和证书。正式的证书需要证书当局（CA）的签名，这里是为了测试，搞一张自签名（self-signed）证书就可以了。

下面，我参考的是 [DigitalOcean](https://www.digitalocean.com/community/tutorials/how-to-create-a-self-signed-ssl-certificate-for-nginx-in-ubuntu-16-04) 的教程。首先，确定你的机器安装了 OpenSSL，然后执行下面的命令。

```
$ sudo openssl req \
  -x509 \
  -nodes \
  -days 365 \
  -newkey rsa:2048 \
  -keyout example.key \
  -out example.crt
```

上面命令的各个参数含义如下。

- req：处理证书签署请求。
- -x509：生成自签名证书。
- -nodes：跳过为证书设置密码的阶段，这样 Nginx 才可以直接打开证书。
- -days 365：证书有效期为一年。
- -newkey rsa:2048：生成一个新的私钥，采用的算法是2048位的 RSA。
- -keyout：新生成的私钥文件为当前目录下的example.key。
- -out：新生成的证书文件为当前目录下的example.crt。

执行后，命令行会跳出一堆问题要你回答，比如你在哪个国家、你的 Email 等等。

![](https://www.hi-linux.com/img/linux/nginx-http2-serverpush-3.png)

其中最重要的一个问题是 Common Name，正常情况下应该填入一个域名，这里可以填 127.0.0.2。

```
Common Name (e.g. server FQDN or YOUR name) []:127.0.0.2
```

回答完问题，当前目录应该会多出两个文件：`example.key` 和 `example.crt`。

`conf` 目录下新建一个子目录 `certs`，把这两个文件放入这个子目录。

```
$ mkdir conf/certs
$ mv example.crt example.key conf/certs
```

### 六、HTTPS 配置

有了私钥和证书，就可以打开 Nginx 的 HTTPS 了。

首先，打开 `conf/conf.d/default.conf` 文件，在结尾添加下面的配置。

```
server {
    listen 443 ssl http2;
    server_name  localhost;

    ssl                      on;
    ssl_certificate          /etc/nginx/certs/example.crt;
    ssl_certificate_key      /etc/nginx/certs/example.key;

    ssl_session_timeout  5m;

    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_protocols SSLv3 TLSv1 TLSv1.1 TLSv1.2;
    ssl_prefer_server_ciphers   on;

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }
}
```

然后，启动一个新的 Nginx 容器。

```
$ docker container run \
  --rm \
  --name mynginx \
  --volume "$PWD/html":/usr/share/nginx/html \
  --volume "$PWD/conf":/etc/nginx \
  -p 127.0.0.2:8080:80 \
  -p 127.0.0.2:8081:443 \
  -d \
  nginx
```

上面命令中，不仅映射了容器的 80 端口，还映射了 443 端口，这是 HTTPS 的专用端口。

打开浏览器，访问 `https://127.0.0.2:8081/` 。因为使用了自签名证书，浏览器会提示不安全。不要去管它，选择继续访问，应该就可以看到 Hello World 了。

至此，Nginx 容器的 HTTPS 支持就做好了。有了这个容器接下来我们就可以来试验 HTTP/2 的 Server Push 功能。

### 七、HTTP/2 服务器推送的原理

HTTP/2 协议的主要目的是提高网页性能。

头信息（header）原来是直接传输文本，现在是压缩后传输。原来是同一个 TCP 连接里面，上一个回应（response）发送完了，服务器才能发送下一个，现在可以多个回应一起发送。

服务器推送（Server Push）是 HTTP/2 协议里面，唯一一个需要开发者自己配置的功能。其他功能都是服务器和浏览器自动实现，不需要开发者关心。

![](https://www.hi-linux.com/img/linux/nginx-http2-serverpush-4.png)

#### 7.1 传统的网页请求方式

下面是一个非常简单的 HTML 网页文件index.html。

```
<!DOCTYPE html>
<html>
<head>
  <link rel="stylesheet" href="style.css">
</head>
<body>
  <h1>hello world</h1>
  <img src="example.png">
</body>
</html>
```

这个网页包含一张样式表 `style.css` 和一个图片文件 `example.png`。为了渲染这个网页，浏览器会发出三个请求。第一个请求是 `index.html`。

```
GET /index.html HTTP/1.1
```

服务器收到这个请求，就把 `index.html` 发送给浏览器。浏览器发现里面包含了样式表和图片，于是再发出两个请求。

```
GET /style.css HTTP/1.1
```

```
GET /example.png HTTP/1.1
```

这就是传统的网页请求方式。它有两个问题，一是至少需要两轮 HTTP 通信，二是收到样式文件之前，网页都会显示一片空白，这个阶段一旦超过2秒，用户体验就会非常不好。

#### 7.2 传统方式的改进

一种解决办法就是把外部资源合并在网页文件里面，减少 HTTP 请求。比如，把样式表的内容写在`<style>` 标签之中，把图片改成 Base64 编码的 [Data URL](https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/Data_URIs)。

另一种方法就是资源的预加载（preload）。网页预先告诉浏览器，立即下载某些资源。比如，上例可以写成下面这样。

```
<link rel="preload" href="/styles.css" as="style">
<link rel="preload" href="/example.png" as="image">
```

对于上例来说，`preload` 命令并没有什么帮助。但是，如果前一个网页就使用这个命令，预加载后一个网页需要的资源，那么用户打开后一个网页时，就会感觉速度飞快。

这两种方法都有缺点。第一种方法虽然减少了 HTTP 请求，但是把不同类型的代码合并在一个文件里，违反了分工原则。第二种方法只是提前了下载时间，并没有减少 HTTP 请求。

#### 7.3 服务器推送的概念

服务器推送（Server Push）指的是，还没有收到浏览器的请求，服务器就把各种资源推送给浏览器。

比如，浏览器只请求了 `index.html`，但是服务器把 `index.html`、`style.css`、`example.png` 全部发送给浏览器。这样的话，只需要一轮 HTTP 通信，浏览器就得到了全部资源，提高了性能。

### 八、配置 Nginx 实现 Server Push

Nginx 从 1.13.9 版开始，支持服务器推送。前面我们已经做好了 Nginx 容器，接着就来体验一下。

首先，进入工作目录，把原来的首页删除。

```
$ cd nginx-docker-demo
$ rm html/index.html
```
然后，新建 `html/index.html` 文件，写入上面的网页源码。

另外，`html` 子目录下面，还要新建两个文件 `example.png` 和 `style.css`。前者可以随便找一张 PNG 图片，后者要在里面写一些样式。

```
h1 {
  color: red;
}
```

最后，打开配置文件 `conf/conf.d/default.conf` ，将 443 端口的部分改成下面的样子。

```
server {
    listen 443 ssl http2;
    server_name  localhost;

    ssl                      on;
    ssl_certificate          /etc/nginx/certs/example.crt;
    ssl_certificate_key      /etc/nginx/certs/example.key;

    ssl_session_timeout  5m;

    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_protocols SSLv3 TLSv1 TLSv1.1 TLSv1.2;
    ssl_prefer_server_ciphers   on;

    location / {
      root   /usr/share/nginx/html;
      index  index.html index.htm;
      http2_push /style.css;
      http2_push /example.png;
    }
}
```

其实就是最后多了两行 `http2_push` 命令。它的意思是，如果用户请求根路径 `/`，就推送`style.css` 和 `example.png`。

现在可以启动容器了。

```
$ docker container run \
  --rm \
  --name mynginx \
  --volume "$PWD/html":/usr/share/nginx/html \
  --volume "$PWD/conf":/etc/nginx \
  -p 127.0.0.2:8080:80 \
  -p 127.0.0.2:8081:443 \
  -d \
  nginx
```

打开浏览器，访问 `https://127.0.0.2:8081` 。浏览器会提示证书不安全，不去管它，继续访问，就能看到网页了。

网页上看不出来服务器推送，必须打开 "开发者工具"，切换到 Network 面板，就可以看到其实只发出了一次请求，`style.css` 和 `example.png` 都是推送过来的。

![](https://www.hi-linux.com/img/linux/nginx-http2-serverpush-5.png)

查看完毕，关闭容器。

```
$ docker container stop mynginx
```

### 九、配置 Apache 实现 Server Push

Apache 也类似，可以在配置文件 `httpd.conf` 或者 `.htaccess` 里面打开服务器推送。

```
<FilesMatch "\index.html$">
    Header add Link "</styles.css>; rel=preload; as=style"
    Header add Link "</example.png>; rel=preload; as=image"
</FilesMatch>
```

### 十、后端实现

上面的服务器推送，需要写在服务器的配置文件里面。这显然很不方便，每次修改都要重启服务，而且应用与服务器的配置不应该混在一起。

服务器推送还有另一个实现方法，就是后端应用产生 HTTP 回应的头信息 `Link` 命令。服务器发现有这个头信息，就会进行服务器推送。

```
Link: </styles.css>; rel=preload; as=style
```

如果要推送多个资源，就写成下面这样。

```
Link: </styles.css>; rel=preload; as=style, </example.png>; rel=preload; as=image
```

可以参考 [Go](https://ops.tips/blog/nginx-http2-server-push/)、[Node](https://blog.risingstack.com/node-js-http-2-push/)、[PHP](https://blog.cloudflare.com/using-http-2-server-push-with-php/) 的实现范例。

这时，Nginx 的配置改成下面这样。

```
server {
    listen 443 ssl http2;

    # ...

    root /var/www/html;

    location = / {
        proxy_pass http://upstream;
        http2_push_preload on;
    }
}
```

如果服务器或者浏览器不支持 HTTP/2，那么浏览器就会按照 preload 来处理这个头信息，预加载指定的资源文件。

事实上，这个头信息就是 preload 标准提出的，它的语法和 `as` 属性的值都写在了[标准](https://w3c.github.io/preload/#as-attribute)里面。

### 十一、缓存问题

服务器推送有一个很麻烦的问题。所要推送的资源文件，如果浏览器已经有缓存，推送就是浪费带宽。即使推送的文件版本更新，浏览器也会优先使用本地缓存。

一种解决办法是，只对第一次访问的用户开启服务器推送。下面是 Nginx 官方给出的示例，根据 Cookie 判断是否为第一次访问。

```
server {
    listen 443 ssl http2 default_server;

    ssl_certificate ssl/certificate.pem;
    ssl_certificate_key ssl/key.pem;

    root /var/www/html;
    http2_push_preload on;

    location = /demo.html {
        add_header Set-Cookie "session=1";
        add_header Link $resources;
    }
}


map $http_cookie $resources {
    "~*session=1" "";
    default "</style.css>; as=style; rel=preload";
}
```

### 十二、性能提升

服务器推送可以提高性能。网上测评的结果是，打开这项功能，比不打开时的 HTTP/2 快了8%，比将资源都嵌入网页的 HTTP/1 快了5%。

![](https://www.hi-linux.com/img/linux/nginx-http2-serverpush-6.png)

可以看到，提升程度也不是特别多，大概是几百毫秒。而且，也不建议一次推送太多资源，这样反而会拖累性能，因为浏览器不得不处理所有推送过来的资源。只推送 CSS 样式表可能是一个比较好的选择。

### 十三、参考链接

- [Tips for deploying nginx(official image) with docker](https://blog.docker.com/2015/04/tips-for-deploying-nginx-official-image-with-docker/), by Mario Ponticello
- [How To Run Nginx in a Docker Container on Ubuntu 14.04](https://www.digitalocean.com/community/tutorials/how-to-run-nginx-in-a-docker-container-on-ubuntu-14-04), by Thomas Taege
- [Official Docker Library docs](https://docs.docker.com/samples/library/nginx/), by Docker
- [How To Create a Self-Signed SSL Certificate for Nginx in Ubuntu 16.04](https://www.digitalocean.com/community/tutorials/how-to-create-a-self-signed-ssl-certificate-for-nginx-in-ubuntu-16-04), by Justin Ellingwood
- [A Comprehensive Guide To HTTP/2 Server Push](https://www.smashingmagazine.com/2017/04/guide-http2-server-push/)，by Jeremy Wagner
- [Introducing HTTP/2 Server Push with NGINX 1.13.9](https://www.nginx.com/blog/nginx-1-13-9-http2-server-push/), by Nginx

> - 来源：阮一峰的网络日志
> - 原文：http://t.cn/REW4m8m
> - 题图：来自谷歌图片搜索
> - 版权：本文版权归原作者所有