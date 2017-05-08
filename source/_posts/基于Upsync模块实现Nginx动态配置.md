---
category: Nginx
title: 基于Upsync模块实现Nginx动态配置
date: 2017-05-08 09:00:00
tags: [技巧,Nginx]
abbrlink:
updated:
toc_number: false
---
Upsync是新浪微博开源的基于Nginx实现动态配置的三方模块。`Nginx-Upsync-Module`的功能是拉取Consul的后端server的列表，并动态更新Nginx的路由信息。此模块不依赖于任何第三方模块。Consul作为Nginx的DB，利用Consul的KV服务，每个Nginx Work进程独立的去拉取各个upstream的配置，并更新各自的路由。

### Upsync模块工作原理

在Nginx的设计中，每一个upstream维护了一张静态路由表，存储了backend的ip、port以及其他的meta信息。每次请求到达后，会依据location检索路由表，然后依据具体的调度算法(如round robin )选择一个backend转发请求。但这张路由表是静态的，如果变更后，则必须reload，经常reload的话这对SLA有较大影响。

为了达到减少reload的目的，大多通过动态更新维护路由表来解决这个问题。通常路由表的维护有Push与Pull两种方式。

<!-- more -->

- Push方案

通过Nginx API向Nginx发出请求,操作简单、便利。

架构图如下

![](http://mmbiz.qpic.cn/mmbiz/8XkvNnTiapOMKPbl0l2HpfVsN8n01PWVicBSiatic0X4QsVYXzQVIXicQR9eW12VgCkUWce26ib1xKNdmBdiaqxVTJaicQ/640?wx_fmt=jpeg&tp=webp&wxfrom=5&wx_lazy=1)

http api除了操作简单、方便，而且实时性好；缺点是有多台Nginx时，不同Nginx路由表的一致性难于保证，如果某一条注册失败，便会造成服务配置的不一致，容错复杂。另外扩容Nginx服务器，需要从其他的Nginx中同步路由表。

- Pull方案

路由表中所有的backend信息(含meta)存储到Consul，所有的Nginx从Consul拉取相关信息。有变更则更新路由表，利用Consul解决一致性问题，同时利用Consul的wait机制解决实时性问题。利用Consul的index进行增量摘取，解决带宽占用问题。

在Consul中，一个K/V对代表一个backend信息，增加一个即视作扩容，减少一个即为缩容。调整meta信息，如权重，也可以达到动态流量调整的目的。

架构图如下：

![](http://mmbiz.qpic.cn/mmbiz/8XkvNnTiapOMKPbl0l2HpfVsN8n01PWVicuJccSbpYT1HKf0a3ZHCTV5coDa9NnKnsLW5kfhsEqIMg1H8qBmhCnw/640?wx_fmt=jpeg&tp=webp&wxfrom=5&wx_lazy=1)

- 基于动态路由的方案实现

Upsync模块使用了第二种模式，通过拉取Consul的后端Server的列表，并动态更新Nginx的路由信息。Upsync模块工作流程图如下：

![](http://static.oschina.net/uploads/space/2016/0311/110607_oLSx_1774694.png)

每个Work进程定时的去Consul拉取相应upstream的配置，若Consul发现对应upstream的值没有变化，便会hang住这个请求五分钟(默认值)。在这五分钟内对此upstream的任何操作，都会立刻返回给Nginx对相应路由进行更新。

upstream变更后，除了更新Nginx的缓存路由信息，还会把本upstream的后端server列表dump到本地，保持本地server信息与consul的一致性。

除了注册／注销后端的server到consul，会更新到Nginx的upstream路由信息外，对后端server属性的修改也会同步到nginx的upstream路由。

Upsync模块支持修改的属性有：weight、max_fails、fail_timeout、down。

1. 修改server的权重可以动态的调整后端的流量。
1. 若想要临时移除server，可以把server的down属性置为1。
1. 若要恢复流量，可重新把down置为0。

每个work进程各自拉取、更新各自的路由表，采用这种方式的原因：

1. 基于Nginx的进程模型，彼此间数据独立、互不干扰。
1. 若采用共享内存，需要提前预分配，灵活性可能受限制，而且还需要读写锁，对性能可能存在潜在的影响。
1. 若采用共享内存，进程间协调去拉取配置，会增加它的复杂性，拉取的稳定性也会受到影响。

Upsync模块高可用性

Nginx的后端列表更新依赖于Consul，但是不强依赖于它，具体表现为：

1. 即使中途Consul意外挂了，也不会影响Nginx的服务，Nginx会沿用最后一次更新的服务列表继续提供服务。
1. 若Consul重新启动提供服务，这个时候Nginx会继续去Consul探测，这个时候Consul的后端服务列表发生了变化，也会及时的更新到Nginx。
1. work进程每次更新都会把后端列表dump到本地，目的是降低对Consul的依赖性，即使在consul不可用时，也可以Reload Nginx。

Nginx启动流程图如下：

![](http://mmbiz.qpic.cn/mmbiz/8XkvNnTiapOMKPbl0l2HpfVsN8n01PWVicibg7gG18fsAMQ6bIOunFMvsXzNhhHHibSt8QyVaOCkfK2LiaunTCf4NrQ/640?wx_fmt=jpeg&tp=webp&wxfrom=5&wx_lazy=1)

Nginx启动时，master进程首先会解析本地的配置文件，解析完成功，接着进行一系列的初始化，之后便会开始work进程的初始化。work初始化时会去Consul拉取配置，进行work进程upstream路由信息的更新，若拉取成功，便直接更新，若拉取失败，便会打开配置的dump后端列表的文件，提取之前dump下来的server信息，进行upstream路由的更新，之后便开始正常的提供服务。

每次去拉取Consul都会设置连接超时，由于Consul在无更新的情况下默认会hang五分钟，所以响应超时配置时间应大于五分钟。大于五分钟之后，Consul依旧没有返回，便直接做超时处理。

### Upsync模块安装

#### 安装Consul

> Consul是HashiCorp公司推出的开源工具，用于实现分布式系统的服务发现与配置。

Upsync最新版本是支持ectd，这里用ectd做为后端存储。有关consule的讲解后面单独来讲。如果你还没有etcd环境，可参考「[etcd使用入门](https://www.hi-linux.com/posts/40915.html)」一文搭建一个。

#### 安装配置Nginx

- 下载对应软件包

这里使用的是Upsync最新版本，目前支持Nginx 1.9+。`nginx-upstream-check-module`是Tengine中的模块，主要用于upstream的健康检查。由于`nginx-upstream-check-module`最新版本只支持1.9.2，所以这里Nginx选用1.9.2。

```
$ cd /root
$ wget 'http://nginx.org/download/nginx-1.9.2.tar.gz'
$ git clone https://github.com/weibocom/nginx-upsync-module
$ git clone https://github.com/xiaokai-wang/nginx_upstream_check_module
```

- 编译安装Nginx

```
$ apt-get install libreadline-dev libncurses5-dev libpcre3-dev libssl-dev perl make build-essential
$ tar xzvf nginx-1.9.2.tar.gz
$ cd nginx-1.9.2
$ patch -p0 < ~/nginx_upstream_check_module/check_1.9.2+.patch
$ ./configure --add-module=/root/nginx_upstream_check_module --add-module=/root/nginx-upsync-module
$ make && make install
```

- 配置Nginx

Nginx会默认安装到`/usr/local/nginx`目录下。

创建用户和相应目录

```
$ useradd -M nginx -s /sbin/nologin
$ mkdir -p /var/log/nginx
$ chown -R nginx.nginx /var/log/nginx
$ mkdir /usr/local/nginx/conf/conf.d
$ mkdir -p /usr/local/nginx/conf/servers
```

修改Nginx主配置文件

```
# 备份原配置文件
$ cd /usr/local/nginx
$ mv conf/nginx.conf conf/nginx.conf.bak

# 修改配置
$ vim /usr/local/nginx/conf/nginx.conf

user  nginx;
worker_processes  5;

error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;

events {
    worker_connections  1024;
}

http {
    include       /usr/local/nginx/conf/mime.types;
    default_type  application/octet-stream;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile        on;
    #tcp_nopush     on;

    keepalive_timeout  65;

    #gzip  on;

    include /usr/local/nginx/conf/conf.d/*.conf;
}
```

创建站点配置文件

```
$ vim /usr/local/nginx/conf/conf.d/site.conf

upstream test {
  # fake server otherwise ngx_http_upstream will report error when startup
  server 127.0.0.1:11111;

  # all backend server will pull from consul when startup and will delete fake server

  # 后端使用consul存储
  # upsync 192.168.2.210:8500/v1/kv/upstreams/test upsync_timeout=6m upsync_interval=500ms upsync_type=consul strong_dependency=off;


  # 后端使用etcd存储
  upsync 192.168.2.210:2379/v2/keys/upstreams/test upsync_timeout=6m

  upsync_interval=500ms upsync_type=etcd strong_dependency=off;
  upsync_dump_path /usr/local/nginx/conf/servers/servers_test.conf;

  #配置健康检查
  check interval=1000 rise=2 fall=2 timeout=3000 type=http default_down=false;
  check_http_send "HEAD / HTTP/1.0\r\n\r\n";
  check_http_expect_alive http_2xx http_3xx;

}

upstream bar {
  server 192.168.2.210:8080 weight=1 fail_timeout=10 max_fails=3;
}

server {
  listen 80;

  location = / {
    proxy_pass http://test;
  }

  location = /bar {  
    proxy_pass http://bar;
  }

  location = /upstream_show {
    upstream_show;
  }

  location = /upstream_status {
    check_status;
    access_log off;
  }
}
```

- 创建Nginx Systemd服务

```
$ vi /lib/systemd/system/nginx.service

[Unit]
Description=The NGINX HTTP and reverse proxy server
Documentation=http://nginx.org/en/docs/
After=syslog.target network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
PIDFile=/var/run/nginx.pid
ExecStartPre=/usr/local/nginx/sbin/nginx -t -c /usr/local/nginx/conf/nginx.conf
ExecStart=/usr/local/nginx/sbin/nginx -c /usr/local/nginx/conf/nginx.conf
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
```

修改权限及加入开机启动

```
$ sudo chmod +x /lib/systemd/system/nginx.service
$ sudo systemctl enable nginx.service
```

现在可以使用下面的指令来管理Nginx服务。

```
$ systemctl start nginx.service
$ systemctl reload nginx.service
$ systemctl restart nginx.service
$ systemctl stop nginx.service
```

- 启动Nginx

```
$ systemctl start nginx.service
```

验证Nginx服务是否正常

```
$ systemctl status  nginx.service
● nginx.service - The NGINX HTTP and reverse proxy server
   Loaded: loaded (/lib/systemd/system/nginx.service; disabled; vendor preset: enabled)
   Active: active (running) since Mon 2017-05-08 10:58:06 CST; 1min 6s ago
     Docs: http://nginx.org/en/docs/
  Process: 22966 ExecStart=/usr/local/nginx/sbin/nginx -c /usr/local/nginx/conf/nginx.conf (code=exited, status=0/SUCCESS)
  Process: 22963 ExecStartPre=/usr/local/nginx/sbin/nginx -t -c /usr/local/nginx/conf/nginx.conf (code=exited, status=0/SUCCESS)
 Main PID: 22971 (nginx)
    Tasks: 6
   Memory: 24.5M
      CPU: 517ms
   CGroup: /system.slice/nginx.service
           ├─22971 nginx: master process /usr/local/nginx/sbin/nginx -c /usr/local/nginx/conf/nginx.con
           ├─22972 nginx: worker process
           ├─22973 nginx: worker process
           ├─22974 nginx: worker process
           ├─22975 nginx: worker process
           └─22976 nginx: worker process

May 08 10:58:06 dev-master-01 systemd[1]: Starting The NGINX HTTP and reverse proxy server...
May 08 10:58:06 dev-master-01 nginx[22963]: nginx: the configuration file /usr/local/nginx/conf/nginx.conf syntax is ok
May 08 10:58:06 dev-master-01 nginx[22963]: nginx: configuration file /usr/local/nginx/conf/nginx.conf test is successful
May 08 10:58:06 dev-master-01 systemd[1]: Started The NGINX HTTP and reverse proxy server.
```

如果要单独查看Nginx服务日志，可以使用以下命令：

```
$ journalctl -f -u nginx.service
```

### 验证Upsync模块

#### 启动一个Web服务

这里在Nginx默认站点目录，用Python启动一个SimpleHTTPServer进行验证。

```
$ cd /usr/local/nginx/html
$ python -m SimpleHTTPServer 8080
```

#### 后端存储增加数据

- 后端存储使用etcd

增加一个后端服务器

```
$ curl -X PUT http://192.168.2.210:2379/v2/keys/upstreams/test/192.168.2.210:8080
```

其它Upstream模块中其它属性的默认值为：`weight=1 max_fails=2 fail_timeout=10 down=0 backup=0;`。如果你要调整这些值，可以用以下命令格式进行提交：

```
$ curl -X PUT -d value="{\"weight\":1, \"max_fails\":2, \"fail_timeout\":10}" http://$etcd_ip:$port/v2/keys/$dir1/$upstream_name/$backend_ip:$backend_port
```

删除一个后端服务器

```
$ curl -X DELETE http://192.168.2.210:2379/v2/keys/upstreams/test/192.168.2.210:8080
```

- 后端存储使用Consul

增加一个后端服务器

```
$ curl -X PUT http://192.168.2.210:8500/v1/kv/upstreams/test/192.168.2.210:8080
```

删除一个后端服务器

```
$ curl -X DELETE http://192.168.2.210:8500/v1/kv/upstreams/test/192.168.2.210:8080
```

#### 测试站点是否正常访问

- 访问站点

![](https://www.hi-linux.com/img/linux/upsync1.png)

页面自动根据`proxy_pass http://test;`成功转到了后端服务器。

- 访问upstream列表

![](https://www.hi-linux.com/img/linux/upsync2.png)

- 访问upstream状态

![](https://www.hi-linux.com/img/linux/upsync3.png)

- 查看添加的后端服务是否被dump到本地

```
$ cat /usr/local/nginx/conf/servers/servers_test.conf
server 192.168.2.210:8080 weight=1 max_fails=2 fail_timeout=10s;
```

### 参考文档

http://www.google.com
http://t.cn/Ra2WfSR
https://my.oschina.net/liucao/blog/470344
http://blog.csdn.net/yueguanghaidao/article/details/52801043
https://www.nginx.com/resources/wiki/start/topics/examples/systemd/
