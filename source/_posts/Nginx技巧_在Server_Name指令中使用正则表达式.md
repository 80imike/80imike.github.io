---
title: 'Nginx技巧:在Server_Name指令中使用正则表达式'
tags:
  - Linux
  - Nginx
  - 技巧
categories: Nginx
abbrlink: 54148
date: 2016-03-15 09:51:54
---

#### 一、server_name的匹配顺序

nginx中的server_name指令主要用于配置基于名称虚拟主机，server_name指令在接到请求后的匹配顺序分别为：

1、准确的server_name匹配，例如：

```bash
server {
    listen       80;
    server_name  howtocn.org  www.howtocn.org;
    ...
}
```
<!-- more -->
2、以*通配符开始的字符串：

```bash
server {
    listen       80;
    server_name  *.howtocn.org;
    ...
}
```

3、以*通配符结束的字符串：

```bash
server {
    listen       80;
    server_name  www.*;
    ...
}
```

4、匹配正则表达式：

```bash
server {
    listen       80;
    server_name  ~^(?<www>.+)\.howtocn\.org$;
    ...
}
```
nginx将按照1,2,3,4的顺序对server name进行匹配，只有有一项匹配以后就会停止搜索，所以我们在使用这个指令的时候一定要分清楚它的匹配顺序（类似于location指令）。

server_name指令一项很实用的功能便是可以在使用正则表达式的捕获功能，这样可以尽量精简配置文件，毕竟太长的配置文件日常维护也很不方便。

#### 二、实例

下面是2个具体的应用：

1、在一个server块中配置多个站点

```bash
server
  {
    listen       80;
    server_name  ~^(www\.)?(.+)$;
    index index.php index.html;
    root  /data/wwwsite/$2;
  }
```

站点的主目录应该类似于这样的结构：

```bash
/data/wwwsite/howtocn.org
/data/wwwsite/linuxtone.org
/data/wwwsite/baidu.com
/data/wwwsite/google.com
```

这样就可以只使用一个server块来完成多个站点的配置。

2、在一个server块中为一个站点配置多个二级域名

实际网站目录结构中我们通常会为站点的二级域名独立创建一个目录，同样我们可以使用正则的捕获来实现在一个server块中配置多个二级域名：

```bash
server
  {
    listen       80;
    server_name  ~^(.+)?\.howtocn\.org$;
    index index.html;
    if ($host = howtocn.org){
        rewrite ^ http://www.howtocn.org permanent;
    }
    root  /data/wwwsite/howtocn.org/$1/;
  }
```

站点的目录结构应该如下：

```bash
/data/wwwsite/howtocn.org/www/
/data/wwwsite/howtocn.org/nginx/
```

这样访问`http://www.howtocn.org`时root目录为`/data/wwwsite/howtocn.org/www/`，`http://nginx.howtocn.org`时为`/data/wwwsite/howtocn.org/nginx/`，以此类推。

后面if语句的作用是将howtocn.org的方位重定向到`http://www.howtocn.org`，这样既解决了网站的主目录访问，又可以增加seo中对`http://www.howtocn.org`的域名权重。

 
3、多个正则表达式

如果你在server_name中用了正则，而下面的location字段又使用了正则匹配，这样将无法使用$1，$2这样的引用，解决方法是通过set指令将其赋值给一个命名的变量：

```bash
server
   {
     listen      80;
     server_name ~^(.+)?\.howtocn\.org$;
     set $www_root $1;
     root /data/wwwsite/howtocn.org/$www_root/;
     location ~ .*\.php?$ {
         fastcgi_pass   127.0.0.1:9000;
         fastcgi_index  index.php;
         fastcgi_param  SCRIPT_FILENAME /data/wwwsite/howtocn.org/$fastcgi_script_name;
         include        fastcgi_params;
         }
   }
```

#### 三、参考资料
<http://nginx.org/en/docs/http/server_names.html>
<http://www.howtocn.org/nginx:server_name_how_to>