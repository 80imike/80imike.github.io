---
title: 用Nginx反向代理机制解决前端跨域问题
tags:
  - Nginx
  - Linux
categories: Nginx
abbrlink: 41743
date: 2016-08-24 09:00:00
updated:
toc_number:
---

### 什么是跨域

跨域请求针对浏览器的同源策略(Same-Origin Policy)而言，指一个网站主动请求另外一个网站的资源(图片、javascript、视频等)。

同源策略要求网站只能有限制的访问外部网站的资源，不合法的请求会被拦截。网站的源由协议、域名、端口三部分组成，有一部分不同就被视为不同源，两个不同的域名即便指向同一个ip地址也是跨域的。网站通过AJAX(发送XMLHttpRequest到其他网站)请求资源是典型的跨域请求，需要外部网站许可才能访问。

同源策略的目的是防止黑客做一些做奸犯科的勾当。比如，一个银行的一个应用允许用户上传网页，如果没有同源策略黑客可以编写一个登陆表单提交到自己的服务器上，得到一个看上去相当高大上的页面。黑客把这个页面通过邮件等发给用户，用户误认为这是某银行的主网页进行登陆，就会泄露自己的用户数据。而因为浏览器的同源策略，黑客无法收到表单数据。

<!-- more -->

更直观的跨域情况见下表

![](http://www.hi-linux.com/img/linux/nginx_sop.png)

### 跨域常见解决方案

跨域解决方案有多种，大多是利用JS Hack。

- document.domain+iframe的设置
- 动态创建script
- 利用iframe和location.hash
- window.name实现的跨域数据传输
- 使用HTML5 postMessage
- 利用flash
- Jquery JSONP
- 跨域资源共享(CORS)
- Nginx反向代理


### Nginx反向代理实现跨域

本文介绍的是通过Nginx反向代理解决跨域，这也是最简单实现跨域的方法。只需要修改Nginx的配置即可解决跨域问题，支持所有浏览器，支持Session，不需要修改任何代码，并且不会影响服务器性能。

我们只需要配置Nginx，在一个服务器上配置多个前缀来转发http/https请求到多个真实的服务器即可。这样这个服务器上所有URL都是相同的域名、协议和端口。因此，对于浏览器来说这些URL都是同源的，没有跨域限制。而实际上这些URL实际上由物理服务器提供服务。这些服务器内的JavaScript可以跨域调用所有这些服务器上的URL。

简单说，Nginx服务器欺骗了浏览器，让它认为这是同源调用，从而解决了浏览器的跨域问题。

下面给出一个Nginx支持跨域的例子，进行具体说明。

> 服务器A(`域名:www.hi-linux.com`)中有一个页面，想请求服务器B(`域名:www.imike.me`)中的api地址(`http://www.imike.me/api`)获取数据。

- Nginx配置

**修改配置文件**

```
server {

    listen 80;
    server_name www.hi-linux.com;
    root /var/www/html;
    autoindex off;
    index index.html index.htm index.php;

    # 将www.hi-linux.com/api的所有请求反向代理到www.imike.me
	
    location ~ ^/api/ {
        proxy_pass http://www.imike.me;
        proxy_redirect          off; 
        proxy_set_header        X-Real-IP       $remote_addr; 
        proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for; 
    }

    location ~ /\.ht {
       deny  all;
    }
}
```

**重启Nginx**

```
/etc/init.d/nginx restart
```

- 修改JS代码中的地址

```
function getID(){ 
		jQuery.get("http://www.hi-linux.com/api/GetData?id=1”, 
		  function (data, textStatus){ 
            this; // 在这里this指向的是Ajax请求的选项配置信息 
            if(textStatus=="success"){ 
            jQuery("#CountNum").html(data); 
            } 
          });  
}
```

- 测试

访问`http://www.hi-linux.com/api/`下的URL都会被代理到`http://www.imike.me/api/`下。

### 参考文档

http://www.google.com
http://www.jbxue.com/article/2187.html
http://blog.jobbole.com/101318/
http://seanlook.com/2015/05/17/nginx-location-rewrite/
http://jooben.blog.51cto.com/253727/438335