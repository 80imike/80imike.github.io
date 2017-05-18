---
category: Nginx
title: 通过Nginx反向代理实现IP分流
date: 2017-04-06 09:00:00
tags: [Nginx, linux]
abbrlink:
updated:
toc_number: false
---

通过Nginx做反向代理来实现分流，以减轻服务器的负载和压力是比较常见的一种服务器部署架构。本文将分享一个如何根据来路IP来进行分流的方法。

**根据特定IP来实现分流**

- 将IP地址的最后一段最后一位为0或2或6的转发至hi-linux-01.com来执行，否则转发至hi-linux-02.com来执行。

<!-- more -->

```
upstream hi-linux-01.com {
  server 192.168.1.100:8080;
}

upstream hi-linux-02.com {
  server 192.168.1.200:8080;
}

server {

  listen 80;
  server_name www.hi-linux.com;

  location / {
    if ( $remote_addr ~* ^(.*)\.(.*)\.(.*)\.*[026]$){
         proxy_pass http://hi-linux-01.com;
         break;
        }
        proxy_pass http://hi-linux-02.com;
	}
}
```


- 将IP地址前3段为`112.18.96.*`转发至hi-linux-01.com来执行，否则转发至hi-linux-02.com来执行。

```
upstream hi-linux-01.com {
  server 192.168.1.100:8080;
}

upstream hi-linux-02.com {
  server 192.168.1.200:8080;
}

server {

  listen 80;
  server_name www.hi-linux.com;

  location / {
    if ( $remote_addr ~* ^(112)\.(18)\.(96)\.(.*)$){
         proxy_pass http://hi-linux-01.com;
         break;
        }
        proxy_pass http://hi-linux-02.com;
	}
}
```

**根据指定范围IP来实现分流**

将IP地址的最后一段为1-100的转发至hi-linux-01.com来执行，否则转发至hi-linux-02.com执行。

```
upstream hi-linux-01.com {
  server 192.168.1.100:8080;
}

upstream hi-linux-02.com {
  server 192.168.1.200:8080;
}

server {

  listen 80;
  server_name www.hi-linux.com;


  location /
  {
   if ( $remote_addr ~* ^(.*)\.(.*)\.(.*)\.[1,100]$){
        proxy_pass http://hi-linux-01.com;
        break;
    }
    proxy_pass http://hi-linux-02.com;
  }

}
```

**根据forwarded地址分流**

将IP地址的第1段为212开头的访问转发至hi-linux-01.com来执行，否则转发至hi-linux-02.com执行。


```
upstream hi-linux-01.com {
  server 192.168.1.100:8080;
}

upstream hi-linux-02.com {
  server 192.168.1.200:8080;
}

server {

  listen 80;
  server_name www.hi-linux.com;


  location /
  {
   if ( $http_x_forwarded_for ~* ^(212)\.(.*)\.(.*)\.(.*)$){
        proxy_pass http://hi-linux-01.com;
        break;
    }
    proxy_pass http://hi-linux-02.com;
  }

}
```




**if指令的作用**

if指令会就检查后面表达式的值是否为真(true)。如果为真则执行后面大括号中的内容。

以下是一些条件表达式的常用比较方法：

```
1.变量的完整比较可以使用=或!=操作符
2.部分匹配可以使用~或~*的正则表达式来表示
3.~表示区分大小写
4.~*表示不区分大小写(nginx与Nginx是一样的)
4.!~与!~*是取反操作，也就是不匹配的意思
6.检查文件是否存在使用-f或!-f操作符
7.检查目录是否存在使用-d或!-d操作符
8.检查文件、目录或符号连接是否存在使用-e或!-e操作符
9.检查文件是否可执行使用-x或!-x操作符
10.正则表达式的部分匹配可以使用括号，匹配的部分在后面可以用$1~$9变量代替
```

**参考内容**

http://www.google.com
http://t.cn/8sTtKRB
http://t.cn/RPhvBqP
